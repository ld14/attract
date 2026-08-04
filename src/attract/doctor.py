"""
attract doctor - validador preflight.

Corre en el Mac ANTES de caminar hasta la maquina Windows.
Cada chequeo existe porque algo se rompio de verdad, o porque va a romperse.

Filosofia: todo lo que Windows rechazaria tiene que fallar aca.
Ningun chequeo necesita IA. Ninguno necesita Windows.
"""

from __future__ import annotations

import json
import re
import sys
import unicodedata
from dataclasses import dataclass, field
from pathlib import Path

# ---------------------------------------------------------------------------
# Reglas de Windows. No son opinables: son del sistema operativo.
# ---------------------------------------------------------------------------

WIN_CHARS_PROHIBIDOS = set('<>:"/\\|?*')

WIN_NOMBRES_RESERVADOS = (
    {"CON", "PRN", "AUX", "NUL"}
    | {f"COM{i}" for i in range(1, 10)}
    | {f"LPT{i}" for i in range(1, 10)}
)

# Basura que macOS siembra y que Pegasus levanta como si fueran juegos
BASURA_MACOS = re.compile(r"^(\._|\.DS_Store$|\.Spotlight-V100$|\.Trashes$)")

EXT_TEXTO = {".txt", ".qml", ".cfg", ".md", ".json", ".yml", ".yaml"}


@dataclass
class Hallazgo:
    nivel: str          # "ERROR" | "AVISO"
    chequeo: str
    ruta: str
    detalle: str


@dataclass
class Reporte:
    hallazgos: list[Hallazgo] = field(default_factory=list)
    archivos_vistos: int = 0
    chequeos_corridos: list[str] = field(default_factory=list)

    def error(self, chequeo: str, ruta, detalle: str) -> None:
        self.hallazgos.append(Hallazgo("ERROR", chequeo, str(ruta), detalle))

    def aviso(self, chequeo: str, ruta, detalle: str) -> None:
        self.hallazgos.append(Hallazgo("AVISO", chequeo, str(ruta), detalle))

    @property
    def errores(self) -> list[Hallazgo]:
        return [h for h in self.hallazgos if h.nivel == "ERROR"]

    @property
    def avisos(self) -> list[Hallazgo]:
        return [h for h in self.hallazgos if h.nivel == "AVISO"]

    @property
    def ok(self) -> bool:
        return not self.errores


# ---------------------------------------------------------------------------
# Chequeos
# ---------------------------------------------------------------------------

def chk_encoding(path: Path, rep: Reporte) -> None:
    """UTF-8 valido. Un solo byte invalido rompe el archivo ENTERO:
    el lector abandona la deteccion y cae a un encoding legacy.
    Ver: el byte 0x93 que arruino 800 lineas de M0."""
    raw = path.read_bytes()
    try:
        raw.decode("utf-8")
    except UnicodeDecodeError as e:
        ctx = raw[max(0, e.start - 30):e.start].decode("utf-8", "replace")
        rep.error(
            "encoding",
            path,
            f"byte invalido 0x{raw[e.start]:02X} en offset {e.start} "
            f"(...{ctx!r}). El archivo entero se va a leer como mojibake.",
        )


def chk_crlf(path: Path, rep: Reporte) -> None:
    """Pegasus prefiere LF. Si git te metio CRLF, revisa .gitattributes."""
    if b"\r\n" in path.read_bytes():
        rep.error("crlf", path, "tiene CRLF. Pegasus espera LF (\\n).")


def chk_nombre_windows(path: Path, rep: Reporte) -> None:
    """macOS acepta casi todo. Windows no.
    Esto NO falla en tu Mac. Solo explota al llegar al gabinete."""
    for parte in path.parts:
        if parte in ("/", "."):
            continue

        malos = sorted(WIN_CHARS_PROHIBIDOS & set(parte))
        if malos:
            rep.error(
                "nombre-windows", path,
                f"'{parte}' usa {' '.join(malos)} - prohibidos en Windows",
            )

        base = parte.split(".")[0].upper()
        if base in WIN_NOMBRES_RESERVADOS:
            rep.error(
                "nombre-windows", path,
                f"'{parte}' es un nombre reservado de Windows",
            )

        if parte.endswith(" ") or parte.endswith("."):
            rep.error(
                "nombre-windows", path,
                f"'{parte}' termina en espacio o punto - ilegal en Windows",
            )


def chk_nfc_nombre(path: Path, rep: Reporte) -> None:
    """macOS descompone (NFD), Windows precompone (NFC).
    'MICROMANIA' con tilde son 10 chars en Windows y 11 en macOS.
    git lo arregla con core.precomposeUnicode... pero solo en los NOMBRES."""
    s = str(path)
    if s != unicodedata.normalize("NFC", s):
        rep.error(
            "nfc-nombre", path,
            "el nombre esta en NFD (descompuesto). En Windows no va a matchear. "
            "Verifica: git config core.precomposeUnicode",
        )


def chk_basura_macos(path: Path, rep: Reporte) -> None:
    """Pegasus escanea por extension. '._mok.zip' termina en .zip."""
    if BASURA_MACOS.match(path.name):
        rep.error(
            "basura-macos", path,
            "archivo de macOS. Si llega al gabinete, Pegasus lo puede "
            "levantar como juego fantasma.",
        )


def chk_metadata(path: Path, rep: Reporte) -> None:
    """Chequeos especificos de metadata.pegasus.txt."""
    texto = path.read_text(encoding="utf-8")

    for n, linea in enumerate(texto.splitlines(), 1):
        if not linea.strip() or linea.lstrip().startswith("#"):
            continue

        # --- NFC en el CONTENIDO ---
        # git NO te salva aca: la ruta escrita adentro del archivo es texto,
        # no un nombre del indice. Si tu generador la emitio en NFD, queda NFD.
        if linea != unicodedata.normalize("NFC", linea):
            rep.error(
                "nfc-contenido", f"{path}:{n}",
                f"linea en NFD: {linea.strip()[:60]!r}. "
                "En Windows no va a resolver el archivo. Normaliza al emitir.",
            )

        # --- separadores ---
        if linea.startswith("assets.") and "\\" in linea:
            rep.aviso(
                "separador", f"{path}:{n}",
                "usa '\\'. Windows acepta '/' tambien - usa '/' en todos lados.",
            )

        # --- los assets apuntan a algo real ---
        m = re.match(r"^(assets\.[a-zA-Z_]+)\s*:\s*(.+)$", linea)
        if m:
            valor = m.group(2).strip()
            if not valor.startswith(("http://", "https://")):
                destino = (path.parent / valor).resolve()
                if not destino.exists():
                    rep.error(
                        "asset-faltante", f"{path}:{n}",
                        f"{m.group(1)} apunta a '{valor}' y no existe",
                    )


def chk_json_valido(path: Path, rep: Reporte) -> None:
    """data.json y magazine.json tienen que ser JSON sintacticamente valido.
    Hoy un JSON roto pasa el doctor sin aviso y explota recien en el theme
    (docs/CONVENCION.md #4.4, "falta")."""
    try:
        json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        rep.error("json-invalido", path, f"JSON invalido: {e}")


def chk_mags_ref(path: Path, rep: Reporte) -> None:
    """mags[].ref de un data.json deberia apuntar a una carpeta real en
    media/_magazines/<ref>/. Es AVISO, no ERROR: la degradacion con un ref
    colgado es un caso soportado a proposito (ver fixtures/arcade/media/sf2ce/,
    ADR-0008) - no bloquea el viaje a Windows, pero vale la pena que se note."""
    try:
        datos = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return  # ya lo reporto chk_json_valido

    if not isinstance(datos, dict):
        return

    for mag in datos.get("mags") or []:
        ref = mag.get("ref") if isinstance(mag, dict) else None
        if not ref:
            continue
        # data.json vive en media/<juego>/data.json; las revistas en media/_magazines/<ref>/
        destino = path.parent.parent / "_magazines" / ref
        if not destino.is_dir():
            rep.aviso(
                "mags-ref-faltante", path,
                f"mags[].ref='{ref}' -> {destino} no existe (degradacion esperada, no error)",
            )


HEX_COLOR = re.compile(r"^#[0-9a-fA-F]{6}$")

# Las seis fijadas en docs/CONVENCION.md #2.1 nota 3, en minuscula y sin
# tildes: las etiquetas que se ven en pantalla las pone el theme, no los datos.
REVIEW_CATS_CONOCIDAS = {
    "originalidad", "graficos", "adiccion",
    "sonido", "dificultad", "animacion",
}


def chk_data_contrato(path: Path, rep: Reporte) -> None:
    """Valida el contrato de data.json mas alla de sintaxis JSON (ADR-0015).

    TODOS los campos son opcionales: un juego sin data.json, o con uno que
    solo trae 'mags', es valido. Lo que se valida es la forma de lo que SI
    esta - un accent mal escrito no rompe el archivo, deja al juego sin color
    y no se nota hasta mirar el gabinete."""
    try:
        datos = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return  # ya lo reporto chk_json_valido

    if not isinstance(datos, dict):
        rep.error("data-contrato", path, "se esperaba un objeto JSON")
        return

    def falla(campo: str, motivo: str) -> None:
        rep.error("data-contrato", path, f"'{campo}': {motivo}")

    # --- accent / accent2 (ADR-0013) ---
    for campo in ("accent", "accent2"):
        val = datos.get(campo)
        if val is None:
            continue
        if not isinstance(val, str) or not HEX_COLOR.match(val):
            falla(campo, f"tiene que ser un hex '#rrggbb', llego {val!r}")

    # --- mags: la lista de referencias. Que el ref EXISTA lo mira chk_mags_ref ---
    mags = datos.get("mags")
    if mags is not None:
        if not isinstance(mags, list):
            falla("mags", "tiene que ser una lista")
        else:
            for i, mag in enumerate(mags):
                if not isinstance(mag, dict) or not isinstance(mag.get("ref"), str) or not mag["ref"].strip():
                    falla(f"mags[{i}]", "tiene que ser un objeto con 'ref' string no vacio")

    # --- manual (ADR-0014) ---
    manual = datos.get("manual")
    if manual is not None:
        if not isinstance(manual, dict):
            falla("manual", "tiene que ser un objeto")
        else:
            pages = manual.get("pages")
            if not isinstance(pages, list) or not all(isinstance(p, str) for p in pages):
                falla("manual.pages", "obligatorio si hay manual, lista de strings")
            else:
                # Una pagina declarada que no esta en el disco deja un hueco en
                # el visor. Se chequea aca y no en el theme porque el theme no
                # puede hacer nada al respecto a esa altura.
                for nombre in pages:
                    if not (path.parent / "_manual" / nombre).is_file():
                        falla(
                            "manual.pages",
                            f"'{nombre}' no existe en {path.parent / '_manual'}",
                        )

    # --- cheats (ADR-0015) ---
    cheats = datos.get("cheats")
    if cheats is not None:
        if not isinstance(cheats, dict):
            falla("cheats", "tiene que ser un objeto")
        else:
            for grupo in ("combos", "codes"):
                items = cheats.get(grupo)
                if items is None:
                    continue
                if not isinstance(items, list):
                    falla(f"cheats.{grupo}", "tiene que ser una lista")
                    continue
                for i, item in enumerate(items):
                    prefijo = f"cheats.{grupo}[{i}]"
                    if not isinstance(item, dict):
                        falla(prefijo, "tiene que ser un objeto")
                        continue
                    for campo in ("name", "input"):
                        if not isinstance(item.get(campo), str) or not item[campo].strip():
                            falla(f"{prefijo}.{campo}", "obligatorio, string no vacio")

    # --- review (ADR-0015 + CONVENCION #2.1 nota 3) ---
    review = datos.get("review")
    if review is not None:
        if not isinstance(review, dict):
            falla("review", "tiene que ser un objeto o null")
            return

        score = review.get("score")
        if score is not None and not _numero_0_100(score):
            falla("review.score", f"tiene que ser un number entre 0 y 100, llego {score!r}")

        if review.get("verdict") is not None and not isinstance(review["verdict"], str):
            falla("review.verdict", "si esta presente tiene que ser string")

        cats = review.get("cats")
        if cats is not None:
            if not isinstance(cats, dict):
                # Objeto, no lista de pares: es lo que permite expresar una
                # resena parcial sin ambiguedad (ADR-0015).
                falla("review.cats", "tiene que ser un objeto {categoria: valor}")
            else:
                for clave, val in cats.items():
                    if clave not in REVIEW_CATS_CONOCIDAS:
                        rep.aviso(
                            "data-contrato", path,
                            f"review.cats['{clave}'] no es de las seis conocidas "
                            f"({', '.join(sorted(REVIEW_CATS_CONOCIDAS))}) - "
                            "el theme la va a ignorar",
                        )
                        continue
                    if not _numero_0_100(val):
                        falla(
                            f"review.cats['{clave}']",
                            f"tiene que ser un number entre 0 y 100, llego {val!r}",
                        )


def _numero_0_100(v) -> bool:
    return isinstance(v, (int, float)) and not isinstance(v, bool) and 0 <= v <= 100


MAGAZINE_TYPES_CONOCIDOS = {
    "publicidad", "indice", "índice", "review", "noticia",
    "entrevista", "especial", "hardware", "preview",
}


def chk_magazine_contrato(path: Path, rep: Reporte) -> None:
    """Valida el contrato de magazine.json mas alla de sintaxis JSON:
    campos obligatorios, tipos, rango de confidence (ADR-0010)."""
    try:
        datos = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return  # ya lo reporto chk_json_valido

    if not isinstance(datos, dict):
        rep.error("magazine-contrato", path, "se esperaba un objeto JSON")
        return

    def falla(campo: str, motivo: str) -> None:
        rep.error("magazine-contrato", path, f"'{campo}': {motivo}")

    if not isinstance(datos.get("name"), str) or not datos["name"].strip():
        falla("name", "obligatorio, string no vacio")
    if not isinstance(datos.get("cover"), str) or not datos["cover"].strip():
        falla("cover", "obligatorio, string no vacio")
    if not isinstance(datos.get("key_id"), str) or not datos["key_id"].strip():
        falla("key_id", "obligatorio, string no vacio")

    pages = datos.get("pages")
    if not isinstance(pages, list) or not all(isinstance(p, str) for p in pages):
        falla("pages", "obligatorio, lista de strings")

    for campo_opc in ("issue", "color"):
        val = datos.get(campo_opc)
        if val is not None and not isinstance(val, str):
            falla(campo_opc, "tiene que ser string o null")

    year = datos.get("year")
    if year is not None and not (isinstance(year, int) and not isinstance(year, bool)):
        falla("year", "tiene que ser number o null")

    articles = datos.get("articles")
    if not isinstance(articles, list):
        falla("articles", "obligatorio, lista")
        return

    # Cuantas paginas tiene la revista, para chequear que los articulos no
    # apunten afuera. Si pages estaba mal ya se reporto arriba; aca se usa 0
    # para no encadenar errores confusos.
    total_paginas = len(pages) if isinstance(pages, list) else 0

    for i, art in enumerate(articles):
        prefijo = f"articles[{i}]"
        if not isinstance(art, dict):
            rep.error("magazine-contrato", path, f"{prefijo}: tiene que ser un objeto")
            continue

        tipo = art.get("type")
        if not isinstance(tipo, str) or not tipo.strip():
            rep.error(
                "magazine-contrato", path,
                f"{prefijo}.type: obligatorio, string no vacio",
            )
        elif tipo not in MAGAZINE_TYPES_CONOCIDOS:
            rep.aviso(
                "magazine-contrato", path,
                f"{prefijo}.type='{tipo}' no es de los conocidos "
                f"({', '.join(sorted(MAGAZINE_TYPES_CONOCIDOS))}) - "
                "el enum no es cerrado (ADR-0010), puede ser valido igual",
            )

        for campo_str_opc in ("game", "title"):
            val = art.get(campo_str_opc)
            if val is not None and not isinstance(val, str):
                rep.error(
                    "magazine-contrato", path,
                    f"{prefijo}.{campo_str_opc}: si esta presente tiene que ser string",
                )

        # startPage y articles[].pages son indices 1-BASED sobre pages[].
        # No es una interpretacion: se deduce del contrato. Un articulo que
        # apunte fuera de rango hoy pasaba el validador y explotaba recien en
        # el visor del theme, que es el peor lugar para enterarse.
        # Ver spec/features/006-theme-documentos/spec.md.
        sp = art.get("startPage")
        if not isinstance(sp, int) or isinstance(sp, bool):
            rep.error(
                "magazine-contrato", path,
                f"{prefijo}.startPage: obligatorio, number",
            )
        elif total_paginas and not (1 <= sp <= total_paginas):
            rep.error(
                "magazine-contrato", path,
                f"{prefijo}.startPage={sp} fuera de rango: pages[] tiene "
                f"{total_paginas} paginas, el indice va de 1 a {total_paginas}",
            )

        art_pages = art.get("pages")
        if not isinstance(art_pages, list) or not all(
            isinstance(p, int) and not isinstance(p, bool) for p in art_pages
        ):
            rep.error(
                "magazine-contrato", path,
                f"{prefijo}.pages: obligatorio, lista de numbers",
            )
        elif total_paginas:
            fuera = [n for n in art_pages if not (1 <= n <= total_paginas)]
            if fuera:
                rep.error(
                    "magazine-contrato", path,
                    f"{prefijo}.pages tiene indices fuera de rango: {fuera} "
                    f"(pages[] tiene {total_paginas} paginas, van de 1 a "
                    f"{total_paginas})",
                )

        conf = art.get("confidence")
        if (
            not isinstance(conf, (int, float))
            or isinstance(conf, bool)
            or not (0.0 <= conf <= 1.0)
        ):
            rep.error(
                "magazine-contrato", path,
                f"{prefijo}.confidence: obligatorio, number entre 0.0 y 1.0",
            )

        for flag in ("cheats", "walkthrough", "tips"):
            if flag in art and not isinstance(art[flag], bool):
                rep.error(
                    "magazine-contrato", path,
                    f"{prefijo}.{flag}: si esta presente tiene que ser boolean",
                )


# ---------------------------------------------------------------------------
# Runner
# ---------------------------------------------------------------------------

CHEQUEOS_UNIVERSALES = [
    ("encoding",       chk_encoding,      True),
    ("crlf",           chk_crlf,          True),
    ("nombre-windows", chk_nombre_windows, False),
    ("nfc-nombre",     chk_nfc_nombre,    False),
    ("basura-macos",   chk_basura_macos,  False),
]


def revisar(raiz: Path, target: str = "windows") -> Reporte:
    rep = Reporte()
    rep.chequeos_corridos = [n for n, _, _ in CHEQUEOS_UNIVERSALES] + [
        "metadata", "json-valido", "mags-ref", "magazine-contrato", "data-contrato",
    ]

    if not raiz.exists():
        rep.error("ruta", raiz, "no existe")
        return rep

    for path in sorted(raiz.rglob("*")):
        if any(p in path.parts for p in (".git", ".venv", "__pycache__", ".pytest_cache", "node_modules")):
            continue
        if not path.is_file():
            continue

        rep.archivos_vistos += 1
        rel = path.relative_to(raiz)

        for _, fn, solo_texto in CHEQUEOS_UNIVERSALES:
            if solo_texto and path.suffix.lower() not in EXT_TEXTO:
                continue
            try:
                fn(rel if fn in (chk_nombre_windows, chk_nfc_nombre, chk_basura_macos) else path, rep)
            except Exception as e:  # noqa: BLE001
                rep.aviso("interno", path, f"{fn.__name__}: {e}")

        if path.name.endswith(".pegasus.txt"):
            try:
                chk_metadata(path, rep)
            except UnicodeDecodeError:
                pass  # ya lo reporto chk_encoding

        if path.name in ("data.json", "magazine.json"):
            try:
                chk_json_valido(path, rep)
            except UnicodeDecodeError:
                pass  # ya lo reporto chk_encoding

        if path.name == "data.json":
            try:
                chk_mags_ref(path, rep)
                chk_data_contrato(path, rep)
            except UnicodeDecodeError:
                pass  # ya lo reporto chk_encoding

        if path.name == "magazine.json":
            try:
                chk_magazine_contrato(path, rep)
            except UnicodeDecodeError:
                pass  # ya lo reporto chk_encoding

    return rep


def imprimir(rep: Reporte, raiz: Path, target: str) -> None:
    print()
    print(f"  attract doctor --target {target}")
    print(f"  {raiz}")
    print("  " + "-" * 62)
    print(f"  {rep.archivos_vistos} archivos revisados")
    print(f"  chequeos: {', '.join(rep.chequeos_corridos)}")
    print()

    if not rep.hallazgos:
        print("  OK - nada que reportar. Podes ir al gabinete.")
        print()
        return

    por_chequeo: dict[str, list[Hallazgo]] = {}
    for h in rep.hallazgos:
        por_chequeo.setdefault(h.chequeo, []).append(h)

    for chequeo, hs in por_chequeo.items():
        marca = "ERROR" if hs[0].nivel == "ERROR" else "AVISO"
        print(f"  [{marca}] {chequeo}  ({len(hs)})")
        for h in hs[:8]:
            print(f"      {h.ruta}")
            print(f"        {h.detalle}")
        if len(hs) > 8:
            print(f"      ... y {len(hs) - 8} mas")
        print()

    print("  " + "-" * 62)
    print(f"  {len(rep.errores)} errores, {len(rep.avisos)} avisos")
    if rep.errores:
        print("  NO viajes a Windows todavia.")
    print()


def main(argv: list[str] | None = None) -> int:
    argv = argv if argv is not None else sys.argv[1:]

    raiz = Path(".")
    target = "windows"
    args = list(argv)
    while args:
        a = args.pop(0)
        if a == "--target":
            target = args.pop(0) if args else "windows"
        elif not a.startswith("-"):
            raiz = Path(a)

    rep = revisar(raiz.resolve(), target)
    imprimir(rep, raiz.resolve(), target)
    return 0 if rep.ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
