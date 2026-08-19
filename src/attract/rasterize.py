"""
attract rasterize - convierte el PDF del manual a las paginas que hojea el
visor del theme.

POR QUE EXISTE (ADR-0022): Pegasus no puede dibujar un PDF - ADR-0007 lo midio
contra el binario real, `import QtQuick.Pdf` ni deja cargar el theme. Lo que si
existe, desde la feature 006, es un visor paginado adentro de Pegasus que come
`manual.pages[]`. O sea que no falta un visor: falta que alguien genere las
paginas. Mientras eso sea trabajo manual, un manual largo no se convierte nunca
y la unica forma de leerlo es abrir el PDF AFUERA (ADR-0021), que en el gabinete
se lleva el foco y no lo devuelve.

`manual` es una LISTA de documentos (ADR-0023): un juego puede declarar mas de
un manual (de uso, de servicio, otro idioma). Con UN documento, todo se
comporta igual que antes de esa ADR - mismos nombres, misma carpeta, sin
argumento de mas. Con DOS O MAS, cada uno rasteriza a su PROPIO subdirectorio
(`_manual/manual-<indice>/`) porque de otro modo dos documentos con sus propias
paginas p001.png colisionarian escribiendo el mismo archivo.

LA FRONTERA DE ESTE MODULO, que es su decision de diseño principal: todo lo que
puede tener un bug -el zero-padding, el orden, no pisar las otras claves del
data.json- vive en funciones PURAS de stdlib, testeables sin instalar nada.
PyMuPDF entra por _render() y por ningun otro lado, con import perezoso adentro
de la funcion. Por eso `pytest tests/` sigue pasando en una maquina limpia:
se saltea un solo test, no el archivo entero. Mismo patron que ADR-0012 fijo
para `mcp`.

Es `import pymupdf`, no `import fitz`: el alias fitz esta deprecado y avisa por
stderr al importarlo (medido con 1.28.2, 2026-08-09).

Filosofia, heredada de synopsis.py: fallar explicito, nunca escritura parcial.
Las paginas se renderizan a un temporal y recien al final se mueven - un PDF que
se rompe en la pagina 40 no puede dejar 39 sueltas y un data.json mintiendo.
"""

from __future__ import annotations

import json
import re
import shutil
import sys
import tempfile
from pathlib import Path

# Los archivos que este comando considera SUYOS y por lo tanto puede borrar al
# regenerar. Deliberadamente angosto: `p` + digitos + extension de imagen. Un
# escaneo que alguien dejo ahi con otro nombre no se toca nunca.
_RE_PAGINA = re.compile(r"^p\d+\.(png|jpg|jpeg)$", re.IGNORECASE)

DPI_DEFAULT = 150


class RasterizeError(Exception):
    """Error explicito - se corta antes de escribir nada a medias."""


# ---------------------------------------------------------------------------
# Puro: stdlib, sin PyMuPDF, sin disco
# ---------------------------------------------------------------------------

def nombres(total: int, ext: str = ".png") -> list[str]:
    """['p001.png', 'p002.png', ...] para `total` paginas.

    Los ceros a la izquierda no son cosmetica (ADR-0007): el theme ordena las
    paginas alfabeticamente, asi que sin padding la 10 se meteria entre la 1 y
    la 2. El ancho crece con el total, de tres digitos en adelante - tres cubre
    hasta 999 y es lo que usan los fixtures y las revistas.
    """
    if total < 1:
        raise RasterizeError(f"el PDF no tiene paginas (total={total})")
    ancho = max(3, len(str(total)))
    return [f"p{i:0{ancho}d}{ext}" for i in range(1, total + 1)]


def resolver_indice(datos: dict, label: str | None) -> int:
    """Que elemento de `manual[]` le toca a esta corrida (ADR-0023).

    Sin `label`: valido solo si hay UN documento (ergo, sin ambiguedad posible)
    - es el caso de siempre, sin argumento de mas. Con dos o mas, hace falta
    decir cual, y el error lista los labels para no obligar a abrir el
    data.json a mano.
    """
    manual = datos.get("manual")
    if not isinstance(manual, list) or not manual:
        raise RasterizeError(
            "el data.json no declara 'manual' (tiene que ser una lista no vacia,"
            " ver ADR-0023)"
        )

    if label is None:
        if len(manual) > 1:
            labels = ", ".join(repr(d.get("label", "?")) for d in manual)
            raise RasterizeError(
                f"este juego tiene {len(manual)} manuales - decime cual:\n"
                f"       attract rasterize <set> <label>\n"
                f"       labels disponibles: {labels}"
            )
        return 0

    for i, doc in enumerate(manual):
        if isinstance(doc, dict) and doc.get("label") == label:
            return i

    labels = ", ".join(repr(d.get("label", "?")) for d in manual)
    raise RasterizeError(f"no hay un manual con label {label!r} - disponibles: {labels}")


def dir_documento(manual_dir: Path, idx: int, total: int) -> Path:
    """Donde van las paginas de ESTE documento, dentro de `_manual/`.

    Con un solo documento es `_manual/` mismo - cero migracion, sf2ce sigue con
    `p001.png` sin subcarpeta. Con dos o mas, cada uno a su propio
    `manual-<indice>/`: sin esto, dos documentos con paginas propias
    colisionarian los dos escribiendo `p001.png` en el mismo lugar.
    """
    return manual_dir if total <= 1 else manual_dir / f"manual-{idx}"


def paginas_a_data(datos: dict, idx: int, pages: list[str]) -> dict:
    """El data.json con `manual[idx].pages` reemplazado y TODO lo demas
    intacto - el resto de `manual[idx]` (incluido `label`/`file`) y los DEMAS
    documentos de la lista.

    Es la funcion que mas importa del modulo, y el modo de falla que evita no es
    un JSON invalido -eso se ve enseguida- sino una clave que desaparece en
    silencio: `accent`, `cheats`, `review`, o el `pages` de OTRO documento,
    perdidos en un juego, que nadie nota hasta abrir el gabinete. Por eso
    devuelve una copia y no muta la entrada.

    `manual[idx].file` sobrevive a proposito: el PDF no se borra al rasterizar.
    Sigue siendo el fallback de ADR-0021 y la unica version con texto
    seleccionable.
    """
    if not isinstance(datos, dict):
        raise RasterizeError("data.json: se esperaba un objeto JSON")

    salida = json.loads(json.dumps(datos))     # copia honda, sin importar copy
    manual = salida.get("manual")
    if not isinstance(manual, list) or not (0 <= idx < len(manual)):
        raise RasterizeError("data.json: 'manual' invalido para el indice pedido")

    manual[idx]["pages"] = list(pages)
    return salida


def pdf_declarado(datos: dict, idx: int) -> str:
    """El nombre del PDF de `manual[idx].file` (ADR-0021).

    La entrada de este comando es el contrato de la feature 012: un solo campo
    sirve para abrir el PDF afuera y para rasterizarlo. No se acepta una ruta
    por argumento porque entonces habria dos formas de decir donde esta el
    manual, y `attract doctor` solo sabe validar una.
    """
    manual = datos.get("manual")
    if not isinstance(manual, list) or not (0 <= idx < len(manual)):
        raise RasterizeError("data.json: 'manual' invalido para el indice pedido")

    doc = manual[idx]
    nombre = doc.get("file") if isinstance(doc, dict) else None
    if not isinstance(nombre, str) or not nombre.strip():
        raise RasterizeError(
            "ese documento no declara 'file' - agregalo apuntando al PDF dentro"
            ' de _manual/, por ejemplo:  {"file": "manual.pdf"}'
        )
    return nombre.strip()


def paginas_existentes(destino_dir: Path) -> list[str]:
    """Las paginas ya generadas que hay en el subdirectorio de ESTE documento,
    ordenadas. `destino_dir` es lo que devuelve `dir_documento()`."""
    if not destino_dir.is_dir():
        return []
    return sorted(p.name for p in destino_dir.iterdir() if _RE_PAGINA.match(p.name))


# ---------------------------------------------------------------------------
# La unica parte que necesita PyMuPDF
# ---------------------------------------------------------------------------

def _render(pdf_path: Path, destino: Path, dpi: int) -> list[str]:
    """Renderiza el PDF a `destino` (un temporal) y devuelve los nombres.

    Import perezoso: si PyMuPDF no esta, `attract doctor`, `synopsis` e `ingest`
    tienen que seguir corriendo igual (ADR-0012, ADR-0022). El mensaje dice que
    instalar; un ModuleNotFoundError crudo no ayuda a nadie.
    """
    try:
        import pymupdf
    except ImportError as e:
        raise RasterizeError(
            "falta PyMuPDF, que es una dependencia OPCIONAL del proyecto\n"
            "       (ADR-0022 - doctor, synopsis e ingest no la necesitan).\n"
            "       Instalala con:  pip install pymupdf"
        ) from e

    try:
        doc = pymupdf.open(pdf_path)
    except Exception as e:                      # pymupdf tira tipos propios
        raise RasterizeError(f"{pdf_path}: no se pudo abrir el PDF - {e}") from e

    try:
        nombres_pag = nombres(doc.page_count)
        for i, nombre in enumerate(nombres_pag):
            try:
                doc[i].get_pixmap(dpi=dpi).save(destino / nombre)
            except Exception as e:
                raise RasterizeError(
                    f"{pdf_path}: fallo al renderizar la pagina {i + 1} - {e}"
                ) from e
    finally:
        doc.close()

    return nombres_pag


# ---------------------------------------------------------------------------
# Flujo completo
# ---------------------------------------------------------------------------

def aplicar(
    media_dir: Path, label: str | None = None, dpi: int = DPI_DEFAULT, force: bool = False
) -> list[str]:
    """media/<set>/ -> rasteriza el documento (`label`, o el unico si no hay
    ambiguedad) y actualiza su data.json.

    Devuelve los nombres generados (relativos a `_manual/`, con el prefijo de
    subcarpeta si corresponde), o [] si no habia nada que hacer porque ya
    estaban las paginas y no se paso --force.
    """
    data_path = media_dir / "data.json"
    if not data_path.is_file():
        raise RasterizeError(f"no existe {data_path}")

    try:
        datos = json.loads(data_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        raise RasterizeError(f"{data_path}: JSON invalido - {e}") from e

    idx = resolver_indice(datos, label)
    total_docs = len(datos["manual"])
    nombre_pdf = pdf_declarado(datos, idx)

    manual_dir = media_dir / "_manual"
    pdf_path = manual_dir / nombre_pdf
    if not pdf_path.is_file():
        raise RasterizeError(f"no existe el PDF declarado: {pdf_path}")

    destino_dir = dir_documento(manual_dir, idx, total_docs)
    prefijo = "" if destino_dir == manual_dir else f"{destino_dir.name}/"

    # Rasterizar es caro y pisa lo que ya estaba: el default es no hacer nada.
    ya_estan = paginas_existentes(destino_dir)
    declaradas = datos["manual"][idx].get("pages") or []
    if (ya_estan or declaradas) and not force:
        return []

    destino_dir.mkdir(parents=True, exist_ok=True)

    # El temporal va DENTRO del directorio de destino para que el move final
    # sea en el mismo sistema de archivos: un rename, no una copia byte a byte
    # de cientos de MB.
    with tempfile.TemporaryDirectory(dir=destino_dir) as tmp:
        tmpdir = Path(tmp)
        generadas = _render(pdf_path, tmpdir, dpi)

        # Recien aca, con TODAS las paginas nuevas ya en disco, se borran las
        # viejas. Si el render fallo a mitad, no se toco nada.
        for viejo in ya_estan:
            (destino_dir / viejo).unlink(missing_ok=True)

        for nombre in generadas:
            shutil.move(str(tmpdir / nombre), str(destino_dir / nombre))

    pages_relativas = [prefijo + nombre for nombre in generadas]
    nuevos_datos = paginas_a_data(datos, idx, pages_relativas)
    texto = json.dumps(nuevos_datos, indent=2, ensure_ascii=False) + "\n"
    with data_path.open("w", encoding="utf-8", newline="\n") as f:
        f.write(texto)

    return pages_relativas


def main(argv: list[str] | None = None) -> int:
    argv = argv if argv is not None else sys.argv[1:]

    if not argv or argv[0] in ("-h", "--help"):
        print("uso: attract rasterize <set> [label] [ruta] [--dpi N] [--force]")
        print()
        print("  Convierte el PDF declarado en manual[].file (ADR-0021/0023) a")
        print("  las paginas que hojea el visor del theme, dentro de")
        print("  <ruta>/media/<set>/_manual/, y escribe manual[].pages en el")
        print("  data.json de ese juego. El PDF NO se borra.")
        print()
        print("  Un juego con UN solo manual no necesita <label>. Con mas de")
        print("  uno (ADR-0023), hace falta decir cual: attract rasterize sf2ce")
        print('  "Manual de servicio". El segundo posicional se interpreta como')
        print("  ruta si existe como directorio; si no, como label.")
        print()
        print(f"  --dpi N    resolucion de salida (default {DPI_DEFAULT})")
        print("  --force    regenera aunque ya haya paginas")
        print()
        print("  Necesita PyMuPDF:  pip install pymupdf   (opcional, ADR-0022)")
        return 0

    posicionales: list[str] = []
    dpi = DPI_DEFAULT
    force = False

    i = 0
    while i < len(argv):
        arg = argv[i]
        if arg == "--force":
            force = True
        elif arg == "--dpi":
            i += 1
            if i >= len(argv):
                print("error: --dpi necesita un numero", file=sys.stderr)
                return 2
            try:
                dpi = int(argv[i])
            except ValueError:
                print(f"error: --dpi invalido: {argv[i]!r}", file=sys.stderr)
                return 2
            if dpi < 1:
                print("error: --dpi tiene que ser mayor que cero", file=sys.stderr)
                return 2
        elif arg.startswith("-"):
            print(f"error: opcion desconocida: {arg}", file=sys.stderr)
            return 2
        else:
            posicionales.append(arg)
        i += 1

    if not posicionales:
        print("error: falta el <set>", file=sys.stderr)
        return 2

    set_id = posicionales[0]
    resto = posicionales[1:]

    # <set> [label] [ruta] - el resto se resuelve por posicion, con UNA
    # ambiguedad: un solo argumento extra puede ser label o ruta. Se decide
    # mirando el disco, no adivinando: si existe como directorio, es ruta (el
    # caso de siempre, un solo documento); si no, es label.
    label: str | None = None
    raiz = Path(".")
    if len(resto) == 1:
        if Path(resto[0]).is_dir():
            raiz = Path(resto[0])
        else:
            label = resto[0]
    elif len(resto) == 2:
        label, raiz = resto[0], Path(resto[1])
    elif len(resto) > 2:
        print("error: demasiados argumentos - uso: rasterize <set> [label] [ruta]", file=sys.stderr)
        return 2

    media_dir = raiz / "media" / set_id

    try:
        generadas = aplicar(media_dir, label=label, dpi=dpi, force=force)
    except RasterizeError as e:
        print(f"error: {e}", file=sys.stderr)
        return 2

    if not generadas:
        print(f"OK - '{set_id}' ya tiene paginas, no se toco nada (usa --force)")
        return 0

    print(f"OK - {len(generadas)} paginas en {media_dir / '_manual'} a {dpi} DPI")
    print(f"     manual.pages actualizado en {media_dir / 'data.json'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
