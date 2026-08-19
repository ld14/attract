"""
attract synopsis - primer modulo que ESCRIBE metadata.pegasus.txt.

ATTRACT no genera synopsis: los consume de un sistema de scraping externo
(ver ADR-0011, spec/features/001-synopsis/). Este modulo lee la fuente
persistida por juego (library/<sistema>/_synopsis/<set>.json) y hace un
merge quirurgico del campo summary: en el bloque game: correspondiente -
ninguna otra linea del archivo se toca.

Filosofia: fallar explicito, nunca escritura parcial ni silenciosa.
"""

from __future__ import annotations

import json
import re
import sys
import unicodedata
from dataclasses import dataclass
from pathlib import Path

_RE_X_SET = re.compile(r"^x-set:\s*(.+)$")
_RE_FILE = re.compile(r"^file:\s*(.+)$")
_RE_SUMMARY = re.compile(r"^summary:\s*")
_RE_CLAVE = re.compile(r"^[a-zA-Z0-9_.-]+:")


class SynopsisError(Exception):
    """Error explicito - se corta antes de escribir nada a medias."""


@dataclass
class Bloque:
    lineas: list[str]
    es_game: bool = False


# ---------------------------------------------------------------------------
# Fuente (lo que dejo el sistema de scraping externo)
# ---------------------------------------------------------------------------

def leer_fuente(sistema_root: Path, set_id: str) -> str:
    """library/<sistema>/_synopsis/<set>.json -> texto de 'summary'.

    Levanta SynopsisError si no existe, no es JSON valido, o no tiene un
    campo 'summary' (string no vacio). Nunca devuelve None silenciosamente.
    """
    path = sistema_root / "_synopsis" / f"{set_id}.json"
    if not path.exists():
        raise SynopsisError(f"no existe fuente para '{set_id}': {path}")

    try:
        datos = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        raise SynopsisError(f"{path}: JSON invalido - {e}") from e

    if not isinstance(datos, dict):
        raise SynopsisError(f"{path}: se esperaba un objeto JSON")

    summary = datos.get("summary")
    if not isinstance(summary, str) or not summary.strip():
        raise SynopsisError(f"{path}: falta 'summary' (string no vacio)")

    return summary.strip()


# ---------------------------------------------------------------------------
# Parser de bloques - suficiente para el merge, no un parser completo
# ---------------------------------------------------------------------------

def parsear_bloques(texto: str) -> list[Bloque]:
    """Separa metadata.pegasus.txt en bloques: header (antes del primer
    'game:', es_game=False) + un bloque por 'game:'. Strip trailing blank
    lines de cada bloque para que escribir las regenere consistentemente."""
    lineas = texto.split("\n")
    bloques: list[Bloque] = []
    actual: list[str] = []
    es_game_actual = False

    for linea in lineas:
        if linea.startswith("game:"):
            if actual:
                while actual and actual[-1] == "":
                    actual.pop()
                bloques.append(Bloque(lineas=actual, es_game=es_game_actual))
            actual = [linea]
            es_game_actual = True
        else:
            actual.append(linea)
    if actual:
        while actual and actual[-1] == "":
            actual.pop()
        bloques.append(Bloque(lineas=actual, es_game=es_game_actual))

    return bloques


def identificar_set(bloque: Bloque) -> str | None:
    """x-set: si esta presente, si no file: sin extension (ADR-0004)."""
    x_set = None
    file_stem = None
    for linea in bloque.lineas:
        m = _RE_X_SET.match(linea)
        if m and x_set is None:
            x_set = m.group(1).strip()
        m2 = _RE_FILE.match(linea)
        if m2 and file_stem is None:
            file_stem = Path(m2.group(1).strip()).stem
    return x_set or file_stem


def _lineas_summary(texto: str) -> list[str]:
    """El texto como `summary:` + sus continuaciones INDENTADAS.

    Un summary de una sola linea da una sola linea, como siempre. Uno con
    saltos da la primera en `summary: ...` y el resto indentadas con dos
    espacios, que es como metadata.pegasus.txt marca "esto sigue siendo el
    valor anterior, no una clave nueva" - el mismo formato que esta funcion
    ya sabia LEER mas abajo (el while que saltea continuaciones) pero no
    escribia.

    Sin esto, un summary multilinea rompe el bloque: cada renglon a partir
    del segundo queda al ras, Pegasus corta el valor en el primero y todo lo
    que sigue (incluidos developer:/release:/x-set:) queda fuera de
    contrato. Bug real: un synopsis con formato markdown, 2026-08-09.

    Las lineas en blanco del texto original se emiten como dos espacios
    pelados: una linea REALMENTE vacia terminaria el valor igual que una sin
    indentar.
    """
    renglones = texto.split("\n")
    salida = [f"summary: {renglones[0]}"]
    for r in renglones[1:]:
        salida.append(f"  {r}" if r.strip() else "  ")
    return salida


def mergear_summary(bloque: Bloque, texto_nuevo: str) -> Bloque:
    """Reemplaza (o inserta) la linea summary: y su continuacion indentada,
    si la habia. Ninguna otra linea del bloque cambia."""
    texto_nuevo = unicodedata.normalize("NFC", texto_nuevo)
    lineas = bloque.lineas
    nuevas: list[str] = []
    idx_file: int | None = None
    insertado = False

    i = 0
    while i < len(lineas):
        linea = lineas[i]
        if _RE_SUMMARY.match(linea):
            i += 1
            while (
                i < len(lineas)
                and lineas[i].startswith(("  ", "\t"))
                and not _RE_CLAVE.match(lineas[i].lstrip())
            ):
                i += 1
            nuevas.extend(_lineas_summary(texto_nuevo))
            insertado = True
            continue

        nuevas.append(linea)
        if _RE_FILE.match(linea) and idx_file is None:
            idx_file = len(nuevas) - 1
        i += 1

    if not insertado:
        if idx_file is None:
            raise SynopsisError(
                "bloque game: sin linea file: - no hay donde insertar summary:"
            )
        nuevas[idx_file + 1 : idx_file + 1] = _lineas_summary(texto_nuevo)

    return Bloque(lineas=nuevas, es_game=bloque.es_game)


def escribir(bloques: list[Bloque]) -> str:
    lineas: list[str] = []
    for i, b in enumerate(bloques):
        if i > 0:
            lineas.append("")
        lineas.extend(b.lineas)
    return "\n".join(lineas) + "\n"


# ---------------------------------------------------------------------------
# Flujo completo
# ---------------------------------------------------------------------------

def aplicar(metadata_path: Path, set_id: str, texto_nuevo: str) -> None:
    original = metadata_path.read_text(encoding="utf-8")
    bloques = parsear_bloques(original)

    idx_objetivo = None
    for i, b in enumerate(bloques):
        if b.es_game and identificar_set(b) == set_id:
            idx_objetivo = i
            break

    if idx_objetivo is None:
        raise SynopsisError(
            f"no se encontro game: con set '{set_id}' en {metadata_path}"
        )

    bloques[idx_objetivo] = mergear_summary(bloques[idx_objetivo], texto_nuevo)
    nuevo_texto = escribir(bloques)
    with metadata_path.open("w", encoding="utf-8", newline="\n") as f:
        f.write(nuevo_texto)


def main(argv: list[str] | None = None) -> int:
    argv = argv if argv is not None else sys.argv[1:]

    if not argv or argv[0] in ("-h", "--help"):
        print("uso: attract synopsis <set> [ruta]")
        print()
        print("  Lee <ruta>/_synopsis/<set>.json (campo 'summary', puesto ahi")
        print("  por un sistema de scraping externo - ver ADR-0011) y lo")
        print("  escribe en <ruta>/metadata.pegasus.txt, sin tocar nada mas")
        print("  del bloque game: correspondiente.")
        return 0

    set_id = argv[0]
    raiz = Path(argv[1]) if len(argv) > 1 else Path(".")
    metadata_path = raiz / "metadata.pegasus.txt"

    if not metadata_path.exists():
        print(f"error: no existe {metadata_path}", file=sys.stderr)
        return 2

    try:
        texto_nuevo = leer_fuente(raiz, set_id)
        aplicar(metadata_path, set_id, texto_nuevo)
    except SynopsisError as e:
        print(f"error: {e}", file=sys.stderr)
        return 2

    print(f"OK - summary de '{set_id}' actualizado en {metadata_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
