"""
attract doctor - validador preflight.

Corre en el Mac ANTES de caminar hasta la maquina Windows.
Cada chequeo existe porque algo se rompio de verdad, o porque va a romperse.

Filosofia: todo lo que Windows rechazaria tiene que fallar aca.
Ningun chequeo necesita IA. Ninguno necesita Windows.
"""

from __future__ import annotations

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
    rep.chequeos_corridos = [n for n, _, _ in CHEQUEOS_UNIVERSALES] + ["metadata"]

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
