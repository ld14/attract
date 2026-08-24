"""
attract import - instala un paquete COINDOOR (ADR-0027) en la libreria.

Recibe un zip con game.json, data.json y media/. Valida todo en un
staging temporal (reusando doctor.py sin modificarlo), y recien despues
escribe en la libreria real: assets, data.json y bloque game: en ese
orden. Si algo falla despues de la primera escritura, se revierte todo
(ver _Deshacer): o el juego queda instalado entero, o no queda nada.

Filosofia: fallar explicito, nunca escritura parcial ni silenciosa.
"""

from __future__ import annotations

import json
import re
import shutil
import sys
import tempfile
import unicodedata
import zipfile
from dataclasses import dataclass
from pathlib import Path

from attract import doctor
from attract.synopsis import (
    Bloque,
    _lineas_summary,
    escribir,
    identificar_set,
    mergear_summary,
    parsear_bloques,
)

SCHEMA_VERSIONS_SOPORTADAS = {"1"}
CAMPOS_OBLIGATORIOS_GAME = ("schema_version", "system", "set", "title")
FORMATOS_CONOCIDOS = {"Arcade", "GD-ROM", "PCB", "Cartucho", "Diskette", "CD", "DVD"}
TRATAMIENTOS_VALIDOS = {"copiar", "descomprimir"}


class InstalarError(Exception):
    """Error explicito - se corta antes de escribir nada a medias."""


@dataclass
class Paquete:
    game: dict
    stage_media: Path   # <tmp>/media - misma forma que tendra media/<set>/


# ---------------------------------------------------------------------------
# Validacion de miembros del zip (zip-slip guard)
# ---------------------------------------------------------------------------

def _validar_miembro(nombre: str) -> None:
    if nombre.endswith("/"):
        return  # entrada de directorio, se ignora
    permitido = (
        nombre in ("game.json", "data.json")
        or nombre.startswith("media/")
        or nombre.startswith("juego/")
    )
    partes = Path(nombre).parts
    if not permitido or ".." in partes or Path(nombre).is_absolute():
        raise InstalarError(f"miembro de zip no permitido: '{nombre}'")


# ---------------------------------------------------------------------------
# Lectura del paquete (solo staging, sin tocar la libreria real)
# ---------------------------------------------------------------------------

def _leer_game_json(path: Path) -> dict:
    if not path.exists():
        raise InstalarError("el paquete no tiene game.json")
    try:
        datos = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        raise InstalarError(f"game.json: JSON invalido - {e}") from e
    if not isinstance(datos, dict):
        raise InstalarError("game.json: se esperaba un objeto JSON")

    faltantes = [c for c in CAMPOS_OBLIGATORIOS_GAME
                 if not str(datos.get(c) or "").strip()]
    if faltantes:
        raise InstalarError(f"game.json: faltan campos obligatorios: {faltantes}")

    if datos["schema_version"] not in SCHEMA_VERSIONS_SOPORTADAS:
        raise InstalarError(
            f"game.json: schema_version '{datos['schema_version']}' no soportada "
            f"(soportadas: {sorted(SCHEMA_VERSIONS_SOPORTADAS)})"
        )

    fmt = datos.get("format")
    if fmt and fmt not in FORMATOS_CONOCIDOS:
        raise InstalarError(
            f"game.json: format '{fmt}' no es un formato fisico conocido "
            f"(conocidos: {sorted(FORMATOS_CONOCIDOS)})"
        )

    trat = datos.get("tratamiento")
    if trat and trat not in TRATAMIENTOS_VALIDOS:
        raise InstalarError(
            f"game.json: tratamiento '{trat}' no valido "
            f"(validos: {sorted(TRATAMIENTOS_VALIDOS)})"
        )
    return datos


def _preflight_data_json(media_dir: Path) -> None:
    rep = doctor.Reporte()

    data_json = media_dir / "data.json"
    if data_json.exists():
        doctor.chk_encoding(data_json, rep)
        doctor.chk_json_valido(data_json, rep)
        doctor.chk_data_contrato(data_json, rep)

    for p in media_dir.rglob("*"):
        if p.is_file():
            doctor.chk_nombre_windows(p.relative_to(media_dir), rep)

    if rep.errores:
        detalle = "\n".join(f"  - {h.detalle}" for h in rep.errores)
        raise InstalarError(f"paquete invalido:\n{detalle}")


def leer_paquete(zip_path: Path) -> Paquete:
    if not zip_path.exists():
        raise InstalarError(f"no existe {zip_path}")

    with zipfile.ZipFile(zip_path) as zf:
        nombres = zf.namelist()
        for nombre in nombres:
            _validar_miembro(nombre)   # recorre TODO antes de escribir nada

        tmp = Path(tempfile.mkdtemp(prefix="attract-import-"))
        try:
            media_dir = tmp / "media"
            media_dir.mkdir()

            for nombre in nombres:
                if nombre.endswith("/"):
                    continue
                contenido = zf.read(nombre)
                if nombre == "game.json":
                    destino = tmp / "game.json"
                elif nombre == "data.json":
                    destino = media_dir / "data.json"
                elif nombre.startswith("juego/"):
                    rom_name = Path(nombre).name
                    rom_nfc = unicodedata.normalize("NFC", rom_name)
                    destino = media_dir / rom_nfc
                else:
                    # nombre empieza con "media/" (ya validado)
                    resto = nombre[len("media/"):]
                    resto_nfc = "/".join(
                        unicodedata.normalize("NFC", p) for p in resto.split("/")
                    )
                    destino = media_dir / resto_nfc

                destino.parent.mkdir(parents=True, exist_ok=True)
                destino.write_bytes(contenido)

            game = _leer_game_json(tmp / "game.json")
            _preflight_data_json(media_dir)

            return Paquete(game=game, stage_media=media_dir)
        except Exception:
            shutil.rmtree(tmp, ignore_errors=True)
            raise


# ---------------------------------------------------------------------------
# Merge / creacion de bloques
# ---------------------------------------------------------------------------

_RE_CAMPO = re.compile(r"^([a-zA-Z0-9_.-]+):\s*")
_RE_FILE = re.compile(r"^file:\s*(.+)$")


def mergear_campo_simple(bloque: Bloque, clave: str, valor: str) -> Bloque:
    """Reemplaza (o inserta despues de file:) una linea `clave: valor`
    de una sola linea. Analoga a synopsis.mergear_summary pero sin el
    caso multilinea - assets.*, developer, genre, etc nunca lo necesitan."""
    valor = unicodedata.normalize("NFC", str(valor))
    lineas = bloque.lineas
    nuevas: list[str] = []
    idx_file: int | None = None
    insertado = False

    for linea in lineas:
        m = _RE_CAMPO.match(linea)
        if m and m.group(1) == clave:
            nuevas.append(f"{clave}: {valor}")
            insertado = True
            continue
        nuevas.append(linea)
        if _RE_FILE.match(linea) and idx_file is None:
            idx_file = len(nuevas) - 1

    if not insertado:
        if idx_file is None:
            raise InstalarError(f"bloque game: sin linea file: - no hay donde insertar {clave}:")
        nuevas.insert(idx_file + 1, f"{clave}: {valor}")

    return Bloque(lineas=nuevas, es_game=bloque.es_game)


def construir_bloque_declarado(
    game: dict, assets: list[tuple[str, str]], archivo: str | None = None
) -> Bloque:
    """Crea un bloque game: nuevo a partir de identidad DECLARADA (ADR-0026),
    sin pasar por mame -listxml. Mismo espiritu que ingest.construir_bloque.

    `archivo` es lo que va en `file:`: donde quedo el juego en la libreria,
    que no siempre es el nombre que traia el paquete (ver _aplicar paso 3)."""
    set_id = game["set"]
    archivo = archivo or game.get("file") or f"{set_id}.zip"

    lineas = [
        f"game: {unicodedata.normalize('NFC', game['title'])}",
        f"file: {archivo}",
    ]
    for campo_json, campo_txt in (
        ("developer", "developer"),
        ("publisher", "publisher"),
        ("genre", "genre"),
        ("players", "players"),
        ("release", "release"),
    ):
        if game.get(campo_json) not in (None, ""):
            lineas.append(f"{campo_txt}: {unicodedata.normalize('NFC', str(game[campo_json]))}")

    for clave, ruta in assets:
        lineas.append(f"assets.{clave}: {ruta}")

    lineas.append(f"x-set: {set_id}")
    if game.get("format"):
        lineas.append(f"x-formato: {unicodedata.normalize('NFC', str(game['format']))}")
    if game.get("file_format"):
        lineas.append(f"x-formato-archivo: {unicodedata.normalize('NFC', str(game['file_format']))}")
    lineas.append("x-procedencia: declarada")

    if game.get("summary"):
        lineas.extend(_lineas_summary(str(game["summary"])))

    return Bloque(lineas=lineas, es_game=True)


# ---------------------------------------------------------------------------
# Aplicacion a la libreria real
# ---------------------------------------------------------------------------

_GAME_DIRS = Path.home() / "Library" / "Preferences" / "pegasus-frontend" / "game_dirs.txt"

_CAMPOS_SIMPLES = ("developer", "publisher", "genre", "players", "release")


def _borrar(path: Path) -> None:
    if path.is_dir() and not path.is_symlink():
        shutil.rmtree(path)
    elif path.exists() or path.is_symlink():
        path.unlink()


class _Deshacer:
    """Registro de lo que toca aplicar(), para revertirlo si algo falla.

    Regla de uso: llamar `antes_de_escribir(p)` ANTES de crear o pisar `p`.
    Lo que no existia se borra; lo que existia se respalda y se restaura.
    Se aplica en orden inverso, asi el ultimo cambio se deshace primero.
    """

    def __init__(self) -> None:
        self._acciones: list[tuple[str, Path, Path | None]] = []
        self._backups: Path | None = None

    def borrar_luego(self, path: Path) -> None:
        self._acciones.append(("borrar", path, None))

    def antes_de_escribir(self, path: Path) -> None:
        if not path.exists():
            self.borrar_luego(path)
            return
        if self._backups is None:
            self._backups = Path(tempfile.mkdtemp(prefix="attract-rollback-"))
        copia = self._backups / str(len(self._acciones))
        # ponytail: respalda el directorio entero (media/<set>/ que se
        # reinstala, ROM ya descomprimido). Si algun dia pesa, ir por archivo.
        if path.is_dir():
            shutil.copytree(path, copia, symlinks=True)
        else:
            shutil.copy2(path, copia)
        self._acciones.append(("restaurar", path, copia))

    def deshacer(self) -> None:
        for accion, path, copia in reversed(self._acciones):
            try:
                _borrar(path)
                if accion == "restaurar":
                    if copia.is_dir():
                        shutil.copytree(copia, path, symlinks=True)
                    else:
                        shutil.copy2(copia, path)
            except OSError as e:
                print(f"aviso: no se pudo revertir {path}: {e}", file=sys.stderr)
        if self._acciones:
            print(
                f"rollback: {len(self._acciones)} cambios revertidos",
                file=sys.stderr,
            )
        self._acciones.clear()

    def limpiar(self) -> None:
        if self._backups is not None:
            shutil.rmtree(self._backups, ignore_errors=True)
            self._backups = None


def _crear_dir(path: Path, undo: _Deshacer) -> None:
    """mkdir -p registrando para rollback solo el tramo que no existia."""
    if path.exists():
        return
    faltante = path
    while not faltante.parent.exists():
        faltante = faltante.parent
    undo.borrar_luego(faltante)
    path.mkdir(parents=True)


def _registrar_en_game_dirs(ruta: Path, undo: _Deshacer) -> None:
    """Agrega la ruta a game_dirs.txt si no esta."""
    _GAME_DIRS.parent.mkdir(parents=True, exist_ok=True)
    lineas = _GAME_DIRS.read_text(encoding="utf-8").splitlines() if _GAME_DIRS.exists() else []
    if str(ruta) not in lineas:
        undo.antes_de_escribir(_GAME_DIRS)
        with _GAME_DIRS.open("a", encoding="utf-8") as f:
            f.write(f"{ruta}\n")


def aplicar(paquete: Paquete, raiz: Path, confirmar=None) -> str:
    """Instala el paquete. Si algo falla a mitad de camino revierte todo lo
    escrito: nunca queda un juego cargado a medias."""
    undo = _Deshacer()
    try:
        return _aplicar(paquete, raiz, confirmar, undo)
    except BaseException:
        undo.deshacer()
        raise
    finally:
        undo.limpiar()


def _aplicar(paquete: Paquete, raiz: Path, confirmar, undo: _Deshacer) -> str:
    game = paquete.game
    set_id = game["set"]
    sistema_root = raiz / game["system"]
    metadata_path = sistema_root / "metadata.pegasus.txt"

    if not metadata_path.exists():
        if confirmar is None:
            resp = input(
                f"no existe {sistema_root} - creo la coleccion "
                f"'{game['system']}'? [s/N] "
            )
            confirmado = resp.strip().lower() in ("s", "si", "sí", "y", "yes")
        else:
            confirmado = confirmar

        if not confirmado:
            raise InstalarError(
                f"no existe {metadata_path} - coleccion no creada"
            )

        _crear_dir(sistema_root, undo)
        undo.antes_de_escribir(metadata_path)
        metadata_path.write_text(
            f"collection: {game['system'].title()}\n",
            encoding="utf-8", newline="\n",
        )
        _registrar_en_game_dirs(sistema_root.resolve(), undo)

    media_dir = sistema_root / "media" / set_id
    _crear_dir(media_dir, undo)

    # 1. resolver ROM: archivo que matchea game["file"] en el staging
    archivo_rom = game.get("file") or f"{set_id}.zip"
    rom_staging = paquete.stage_media / archivo_rom
    rom_existe = rom_staging.exists() and rom_staging.is_file()

    # fallback: si file no esta en game.json y el default no existe,
    # buscar un unico .zip en el staging que no sea data.json
    if not rom_existe and "file" not in game:
        zips = [
            p for p in paquete.stage_media.iterdir()
            if p.suffix == ".zip" and p.name != "data.json"
        ]
        if len(zips) == 1:
            rom_staging = zips[0]
            rom_existe = True
            archivo_rom = zips[0].name
            game["file"] = archivo_rom

    tratamiento = game.get("tratamiento")

    if tratamiento and not rom_existe:
        raise InstalarError(
            f"tratamiento '{tratamiento}' pero no se encontro "
            f"'{archivo_rom}' en el paquete"
        )

    # 2. assets (todo lo que NO es data.json NI el ROM cuando hay tratamiento)
    assets: list[tuple[str, str]] = []
    for origen in paquete.stage_media.rglob("*"):
        if not origen.is_file():
            continue
        rel = origen.relative_to(paquete.stage_media)
        if rel.name == "data.json" and rel.parent == Path("."):
            continue
        if tratamiento and rel.name == archivo_rom and rel.parent == Path("."):
            continue   # el ROM se maneja aparte
        destino = media_dir / rel
        _crear_dir(destino.parent, undo)
        undo.antes_de_escribir(destino)
        shutil.copy2(origen, destino)
        if rel.parent == Path("."):   # directo en media/<set>/, no en _manual/
            assets.append((origen.stem, f"media/{set_id}/{origen.name}"))

    # 3. tratamiento del ROM
    if rom_existe and tratamiento == "copiar":
        destino_rom = sistema_root / archivo_rom
        undo.antes_de_escribir(destino_rom)
        shutil.copy2(rom_staging, destino_rom)
    elif rom_existe and tratamiento == "descomprimir":
        destino_extract = sistema_root / set_id
        undo.antes_de_escribir(destino_extract)
        with zipfile.ZipFile(rom_staging) as zf:
            zf.extractall(destino_extract)

    # `file:` apunta a donde quedo el juego en la libreria, no al nombre que
    # traia el paquete: con "descomprimir" el zip ya no existe ahi, y Pegasus
    # (general.verify-files) descarta el juego -y con el la coleccion entera-.
    archivo_juego = set_id if tratamiento == "descomprimir" else archivo_rom

    # 4. data.json, preservando mags[] existente si el paquete no trae uno
    origen_data = paquete.stage_media / "data.json"
    nuevo = json.loads(origen_data.read_text(encoding="utf-8")) if origen_data.exists() else {}
    destino_data = media_dir / "data.json"
    if "mags" not in nuevo and destino_data.exists():
        try:
            existente = json.loads(destino_data.read_text(encoding="utf-8"))
            if isinstance(existente, dict) and "mags" in existente:
                nuevo["mags"] = existente["mags"]
        except json.JSONDecodeError:
            pass   # el archivo instalado ya estaba roto, no es este comando el que arregla eso
    undo.antes_de_escribir(destino_data)
    with destino_data.open("w", encoding="utf-8", newline="\n") as f:
        json.dump(nuevo, f, ensure_ascii=False, indent=2)
        f.write("\n")

    # 5. bloque game:
    texto = metadata_path.read_text(encoding="utf-8")
    bloques = parsear_bloques(texto)
    idx = next(
        (i for i, b in enumerate(bloques) if b.es_game and identificar_set(b) == set_id),
        None,
    )

    if idx is not None:
        b = bloques[idx]
        if tratamiento:   # sin tratamiento el ROM no se toca: no sabemos donde esta
            b = mergear_campo_simple(b, "file", archivo_juego)
        for campo in _CAMPOS_SIMPLES:
            if game.get(campo) not in (None, ""):
                b = mergear_campo_simple(b, campo, game[campo])
        if game.get("format"):
            b = mergear_campo_simple(b, "x-formato", game["format"])
        if game.get("file_format"):
            b = mergear_campo_simple(b, "x-formato-archivo", game["file_format"])
        for clave, ruta in assets:
            b = mergear_campo_simple(b, f"assets.{clave}", ruta)
        if game.get("summary"):
            b = mergear_summary(b, str(game["summary"]))
        bloques[idx] = b
    else:
        bloques.append(construir_bloque_declarado(game, assets, archivo_juego))

    undo.antes_de_escribir(metadata_path)
    metadata_path.write_text(escribir(bloques), encoding="utf-8", newline="\n")

    return set_id


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main(argv: list[str] | None = None) -> int:
    argv = argv if argv is not None else sys.argv[1:]

    if not argv or argv[0] in ("-h", "--help"):
        print("uso: attract import [--yes] <paquete.zip> [ruta]")
        print()
        print("  Instala un paquete COINDOOR (ADR-0027) en <ruta>/<sistema>/.")
        print("  Si la coleccion no existe, la crea (pide confirmacion).")
        print()
        print("  --yes  crea la coleccion sin preguntar")
        return 0

    si = "--yes" in argv
    if si:
        argv = [a for a in argv if a != "--yes"]

    zip_path = Path(argv[0])
    raiz = Path(argv[1]) if len(argv) > 1 else Path(".")
    confirmar = si if si else None

    paquete = None
    try:
        paquete = leer_paquete(zip_path)
        set_id = aplicar(paquete, raiz, confirmar=confirmar)
    except InstalarError as e:
        print(f"error: {e}", file=sys.stderr)
        return 2
    finally:
        if paquete is not None and paquete.stage_media.exists():
            shutil.rmtree(paquete.stage_media.parent, ignore_errors=True)

    print(f"OK - '{set_id}' instalado en {raiz}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
