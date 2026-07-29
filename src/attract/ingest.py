"""
attract ingest - primer modulo que CREA un bloque game: nuevo.

Cae una ROM, ATTRACT le pregunta a mame -listxml quien es (identidad real,
no inventada) y arma la entrada en metadata.pegasus.txt + la carpeta
media/<set>/. Si no puede identificarla con certeza (mame no reconoce el
set, o el set resulta ser mas de una maquina jugable - el caso hipotetico
de ADR-0004 nunca confirmado con evidencia propia), no agrega nada.

xml.etree.ElementTree es stdlib: ingest no rompe el limite duro (a
diferencia de attract mcp, ver ADR-0012).

Forma del XML confirmada 2026-07-29 contra mame vanilla 0.288 real (el
autor corrio "mame -listxml sf2ce" en su Mac): el DOCTYPE con subset
interno no rompe el parseo, <description>/<year>/<manufacturer> son los
tags correctos, runnable="no" filtra bien los devices. Ver
tests/test_ingest.py::test_forma_real_confirmada_2026_07_29 para la
evidencia literal. Sigue sin confirmar en esta sesion: si Pegasus acepta
"release: <solo el año>" en pantalla - eso necesita el gabinete, no solo
el parser (ver spec/features/004-attract-ingest/tasks.md).

Tambien confirmado con datos reales: el <description> de mame puede traer
basura de region/revision pegada al titulo (ej. "... (World 920513)").
Decision (2026-07-29): se deja crudo, construir_bloque no intenta
limpiarlo - mismo criterio que el resto del modulo, no adivina.

Filosofia: fallar explicito, nunca escritura parcial ni silenciosa.
"""

from __future__ import annotations

import subprocess
import sys
import unicodedata
import xml.etree.ElementTree as ET
from pathlib import Path

from attract.synopsis import Bloque, escribir, identificar_set, parsear_bloques


class IngestError(Exception):
    """Error explicito - se corta antes de escribir nada a medias."""


# ---------------------------------------------------------------------------
# Identidad via mame -listxml
# ---------------------------------------------------------------------------

def listar_maquinas_jugables(set_id: str) -> list[dict]:
    """Corre mame -listxml <set_id> y devuelve las maquinas jugables (sin
    runnable="no" - ese atributo marca CPUs/sonido/memoria, no juegos,
    filtro verificado en el LAB 0.2 contra una libreria real)."""
    try:
        resultado = subprocess.run(
            ["mame", "-listxml", set_id],
            capture_output=True,
            text=True,
            timeout=30,
        )
    except FileNotFoundError as e:
        raise IngestError(
            "mame no esta en el PATH - no se puede identificar nada sin el"
        ) from e
    except subprocess.TimeoutExpired as e:
        raise IngestError(f"mame -listxml {set_id} no respondio a tiempo") from e

    try:
        raiz = ET.fromstring(resultado.stdout)
    except ET.ParseError as e:
        raise IngestError(
            f"mame -listxml {set_id} no devolvio XML valido: {e}"
        ) from e

    maquinas = []
    for m in raiz.findall("machine"):
        if m.get("runnable") == "no":
            continue
        maquinas.append(
            {
                "name": m.get("name"),
                "description": m.findtext("description"),
                "year": m.findtext("year"),
                "manufacturer": m.findtext("manufacturer"),
            }
        )
    return maquinas


def identificar(set_id: str) -> dict:
    """Exige EXACTAMENTE una maquina jugable. Cero o mas de una -> falla
    explicito, no adivina."""
    maquinas = listar_maquinas_jugables(set_id)

    if len(maquinas) == 0:
        raise IngestError(
            f"'{set_id}' no matchea ninguna maquina jugable en mame - "
            "set no reconocido"
        )
    if len(maquinas) > 1:
        nombres = ", ".join(m["name"] for m in maquinas)
        raise IngestError(
            f"'{set_id}' tiene {len(maquinas)} maquinas jugables ({nombres}) "
            "- caso no soportado todavia (ver ADR-0004, 'conseguir o "
            "simular un archivo con mas de un juego jugable de verdad')"
        )
    return maquinas[0]


# ---------------------------------------------------------------------------
# Construccion del bloque nuevo
# ---------------------------------------------------------------------------

def construir_bloque(info: dict, file_name: str, set_id: str) -> Bloque:
    """Arma el bloque game: a partir de lo que -listxml haya dado. No
    inventa nada que -listxml no traiga (sin developer/release si
    manufacturer/year faltan)."""
    titulo = info.get("description") or set_id
    lineas = [
        f"game: {unicodedata.normalize('NFC', titulo)}",
        f"file: {file_name}",
    ]

    if info.get("manufacturer"):
        lineas.append(
            f"developer: {unicodedata.normalize('NFC', info['manufacturer'])}"
        )
    if info.get("year"):
        # Solo el año - -listxml no da mes/dia, no se fabrica una fecha.
        lineas.append(f"release: {info['year']}")

    lineas.append(f"x-set: {set_id}")
    return Bloque(lineas=lineas, es_game=True)


# ---------------------------------------------------------------------------
# Flujo completo
# ---------------------------------------------------------------------------

def aplicar(metadata_path: Path, sistema_root: Path, rom_path: Path) -> str:
    """Ingesta rom_path en metadata_path. Devuelve el set_id usado.
    Falla explicito (IngestError) sin tocar el archivo si:
    - el set ya tiene bloque game:
    - mame no identifica exactamente una maquina jugable
    """
    set_id = rom_path.stem

    original = metadata_path.read_text(encoding="utf-8")
    bloques = parsear_bloques(original)

    for b in bloques:
        if b.es_game and identificar_set(b) == set_id:
            raise IngestError(
                f"'{set_id}' ya tiene un bloque game: en {metadata_path} - "
                "attract ingest no edita, solo crea nuevos"
            )

    info = identificar(set_id)  # levanta IngestError si no hay exactamente 1
    nuevo = construir_bloque(info, rom_path.name, set_id)

    bloques.append(nuevo)
    nuevo_texto = escribir(bloques)
    with metadata_path.open("w", encoding="utf-8", newline="\n") as f:
        f.write(nuevo_texto)

    media_dir = sistema_root / "media" / set_id
    media_dir.mkdir(parents=True, exist_ok=True)

    return set_id


def main(argv: list[str] | None = None) -> int:
    argv = argv if argv is not None else sys.argv[1:]

    if not argv or argv[0] in ("-h", "--help"):
        print("uso: attract ingest <rom.zip> [ruta]")
        print()
        print("  Identifica <rom.zip> con mame -listxml, agrega un bloque")
        print("  game: nuevo a <ruta>/metadata.pegasus.txt y crea")
        print("  <ruta>/media/<set>/ vacia. No edita bloques existentes.")
        return 0

    rom_path = Path(argv[0])
    raiz = Path(argv[1]) if len(argv) > 1 else Path(".")
    metadata_path = raiz / "metadata.pegasus.txt"

    if not metadata_path.exists():
        print(f"error: no existe {metadata_path}", file=sys.stderr)
        return 2

    try:
        set_id = aplicar(metadata_path, raiz, rom_path)
    except IngestError as e:
        print(f"error: {e}", file=sys.stderr)
        return 2

    print(f"OK - '{set_id}' agregado a {metadata_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
