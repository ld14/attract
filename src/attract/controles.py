"""
attract controles - genera la correspondencia entre los controles logicos de
cada juego y la posicion fisica del panel de ESTE gabinete
(ADR-0036, ADR-0037, spec/features/027-como-se-juega/).

Combina el perfil versionado (themes/attract/core/gabinete.json) con la
configuracion REAL de MAME/DOSBox de esta maquina, y escribe un artefacto
derivado por coleccion: library/<coleccion>/_controles.json. Nunca escribe
configuracion de MAME ni de DOSBox, solo lee.

Un control queda VERIFICADO solo si la cadena se resuelve entera Y el perfil
trae esa posicion como MEDIDA. Hoy el perfil no tiene ninguna posicion
medida (panel en transicion, la medicion es la Etapa F) - por eso, hasta que
eso cambie, ningun control sale verificado. Es el comportamiento correcto,
no un bug: la guia muestra la entrada logica ("boton 2 del jugador 1") y
ningun diagrama sugiere una posicion que no se confirmo (docs/como-se-juega.md,
"Condicion de exito").

La huella se calcula sobre las ENTRADAS NORMALIZADAS (puertos remapeados,
valores de mame.ini/dosbox.conf que afectan la entrada, version de MAME,
revision del perfil) - nunca sobre los archivos crudos. MAME reescribe el
.cfg de cada juego al cerrarlo (contador de creditos, mezclador de audio):
si la huella fuera del archivo entero, `attract doctor` avisaria "vencida"
despues de cada partida.

Dry-run por defecto, igual que `attract mags`: sin --apply no escribe nada.
"""
from __future__ import annotations

import hashlib
import json
import re
import subprocess
import sys
import xml.etree.ElementTree as ET
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path

from attract.synopsis import identificar_set, parsear_bloques


class ControlesError(Exception):
    """Una fuente no esta disponible en esta maquina (perfil, mame, metadata),
    o un dato no se pudo interpretar. Se corta antes de escribir nada a medias."""


# ---------------------------------------------------------------------------
# Perfil (themes/attract/core/gabinete.json)
# ---------------------------------------------------------------------------

def leer_perfil(theme_root: Path) -> dict:
    ruta = theme_root / "core" / "gabinete.json"
    try:
        texto = ruta.read_text(encoding="utf-8")
    except FileNotFoundError as e:
        raise ControlesError(f"no existe el perfil del gabinete: {ruta}") from e
    try:
        perfil = json.loads(texto)
    except json.JSONDecodeError as e:
        raise ControlesError(f"perfil corrupto: {ruta}: {e}") from e
    if not isinstance(perfil, dict):
        raise ControlesError(f"perfil invalido: {ruta} no es un objeto JSON")
    return perfil


# ---------------------------------------------------------------------------
# launch: -> que emulador es y donde esta
# ---------------------------------------------------------------------------

_LAUNCH_RUTA = re.compile(r'"([^"]+\.exe)"')


def launch_de_coleccion(metadata_texto: str) -> str | None:
    """La linea launch: de cabecera de un metadata.pegasus.txt (antes del
    primer game:), tal cual esta escrita."""
    for linea in metadata_texto.splitlines():
        if linea.startswith("game:"):
            break
        if linea.startswith("launch:"):
            return linea[len("launch:"):].strip()
    return None


def emulador_de_launch(launch: str) -> Path | None:
    """Primera ruta entre comillas de launch: (ADR-0018: ruta absoluta,
    resuelta por maquina). None si no hay ninguna - un launch: sin corregir
    (ver docs/como-se-juega.md #8) no tiene comillas."""
    m = _LAUNCH_RUTA.search(launch)
    return Path(m.group(1)) if m else None


def tipo_emulador(launch: str) -> str:
    """'mame' | 'dosbox' | 'desconocido', por el nombre del ejecutable en
    launch: - mismo criterio con el que el resto del proyecto ya distingue
    las dos plataformas (dosbox.py genera dosbox.conf solo para msdos)."""
    bajo = launch.lower()
    if "mame" in bajo:
        return "mame"
    if "dosbox" in bajo:
        return "dosbox"
    return "desconocido"


# ---------------------------------------------------------------------------
# MAME: -listxml
# ---------------------------------------------------------------------------

def mame_listxml(mame_exe: Path, set_id: str) -> ET.Element:
    try:
        resultado = subprocess.run(
            [str(mame_exe), "-listxml", set_id],
            capture_output=True,
            text=True,
            timeout=30,
        )
    except OSError as e:
        # FileNotFoundError (no existe) y WinError 193 (existe pero no es un
        # ejecutable Windows valido) son el mismo caso para este comando:
        # la fuente no esta disponible en esta maquina.
        raise ControlesError(f"no se pudo ejecutar {mame_exe}: {e}") from e
    except subprocess.TimeoutExpired as e:
        raise ControlesError(f"{mame_exe} -listxml {set_id} no respondio a tiempo") from e
    try:
        return ET.fromstring(resultado.stdout)
    except ET.ParseError as e:
        raise ControlesError(f"{mame_exe} -listxml {set_id} no devolvio XML valido: {e}") from e


def controles_declarados(raiz_xml: ET.Element) -> list[dict]:
    """Los <control> del <input> de la primera maquina jugable. Vacio si el
    juego no declara ningun control (ej. Pacman: solo joystick, sin
    buttons) - confirmado en el piloto contra mame real, 2026-09-27."""
    for machine in raiz_xml.findall("machine"):
        if machine.get("runnable") == "no":
            continue
        input_el = machine.find("input")
        if input_el is None:
            return []
        return [
            {
                "type": c.get("type"),
                "player": c.get("player"),
                "buttons": c.get("buttons"),
                "ways": c.get("ways"),
            }
            for c in input_el.findall("control")
        ]
    return []


_MAME_VERSION = re.compile(r"MAME\s+v?([\d.]+)")


def mame_version(mame_exe: Path) -> str | None:
    try:
        resultado = subprocess.run(
            [str(mame_exe), "-help"], capture_output=True, text=True, timeout=15,
        )
    except (OSError, subprocess.TimeoutExpired):
        return None
    m = _MAME_VERSION.search(resultado.stdout or "")
    return m.group(1) if m else None


# ---------------------------------------------------------------------------
# MAME: .cfg (default.cfg, ctrlr/*.cfg, cfg/<sistema>.cfg)
# ---------------------------------------------------------------------------

_PORT = re.compile(
    r'<port\s+tag="[^"]*"\s+type="([^"]+)"[^>]*>\s*<newseq[^>]*>\s*([^<]*?)\s*</newseq>',
    re.DOTALL,
)


def leer_cfg_ports(cfg_path: Path) -> dict[str, str]:
    """{tipo_de_puerto: newseq} de un .cfg de MAME. {} si el archivo no
    existe - "un .cfg ausente vale lo mismo que uno sin <input>" (spec 027).
    No falla con XML invalido: default.cfg puede no tener <input> en
    absoluto y sigue siendo un .cfg valido (caso real de esta maquina)."""
    try:
        texto = cfg_path.read_text(encoding="utf-8")
    except FileNotFoundError:
        return {}
    return {tipo: newseq.strip() for tipo, newseq in _PORT.findall(texto)}


def mame_ini_valores(mame_ini: Path, claves: set[str]) -> dict[str, str]:
    """Valores de las claves pedidas en mame.ini ("clave   valor" por
    linea). {} si el archivo no existe."""
    out: dict[str, str] = {}
    try:
        texto = mame_ini.read_text(encoding="utf-8")
    except FileNotFoundError:
        return out
    for linea in texto.splitlines():
        linea = linea.strip()
        if not linea or linea.startswith("#"):
            continue
        partes = linea.split(None, 1)
        if len(partes) == 2 and partes[0] in claves:
            out[partes[0]] = partes[1].strip()
    return out


# ---------------------------------------------------------------------------
# DOSBox: las tres capas (primaria, del juego, mapperfile)
# ---------------------------------------------------------------------------

def resolver_dosbox(carpeta_juego: Path) -> dict:
    """Si la palanca esta deshabilitada y si el juego trae un mapperfile
    propio (excepcion a la tecla de salida por defecto del perfil, riesgo
    de "config de DOSBox en capas" de plan.md). Sin dosbox.conf, joystick
    None y sin excepcion - mismo criterio que un .cfg ausente de MAME."""
    conf = carpeta_juego / "dosbox.conf"
    try:
        texto = conf.read_text(encoding="utf-8")
    except FileNotFoundError:
        return {"joysticktype": None, "mapperfilePropio": False}
    except UnicodeDecodeError:
        # Caso real (library/msdos/monkey-island/dosbox.conf, 2026-09-29):
        # un dosbox.conf "de pack" con comentarios en Windows-1252, no
        # UTF-8 (".conf" ni siquiera esta en EXT_TEXTO de doctor.py, asi
        # que chk_encoding nunca lo vio). Lo que hace falta parsear
        # (joysticktype, mapperfile) es ASCII puro; errors="replace" deja
        # eso intacto y solo estropea los comentarios acentuados.
        texto = conf.read_text(encoding="utf-8", errors="replace")

    m = re.search(r"joysticktype\s*=\s*(\S+)", texto)
    joystick = m.group(1) if m else None
    tiene_mapperfile = bool(re.search(r"^\s*mapperfile\s*=", texto, re.MULTILINE))
    return {"joysticktype": joystick, "mapperfilePropio": tiene_mapperfile}


# ---------------------------------------------------------------------------
# Huella
# ---------------------------------------------------------------------------

def calcular_huella(payload: dict) -> str:
    canonico = json.dumps(payload, sort_keys=True, ensure_ascii=False)
    return "sha256:" + hashlib.sha256(canonico.encode("utf-8")).hexdigest()


# ---------------------------------------------------------------------------
# Generacion del artefacto
# ---------------------------------------------------------------------------

def _theme_root_de(raiz: Path) -> Path:
    """El theme vive al lado de la libreria en el repo (library/ y
    themes/attract/ son hermanos) - misma convencion que ya usan
    make doctor/make doctor-lib para ubicar la libreria."""
    return raiz.parent / "themes" / "attract"


def generar_coleccion(raiz: Path, coleccion: str, theme_root: Path | None = None) -> dict:
    """Arma el artefacto completo de una coleccion. No escribe nada -
    escribir_artefacto() hace eso, y solo si se le pide."""
    theme_root = theme_root or _theme_root_de(raiz)
    perfil = leer_perfil(theme_root)

    coleccion_dir = raiz / coleccion
    metadata_path = coleccion_dir / "metadata.pegasus.txt"
    try:
        texto = metadata_path.read_text(encoding="utf-8")
    except FileNotFoundError as e:
        raise ControlesError(f"no existe {metadata_path}") from e

    launch = launch_de_coleccion(texto)
    if not launch:
        raise ControlesError(f"{metadata_path} no tiene linea launch:")

    tipo = tipo_emulador(launch)
    juegos = [b for b in parsear_bloques(texto) if b.es_game]

    por_juego: dict[str, dict] = {}
    huella_payload: dict = {
        "revisionPerfil": perfil.get("revision"),
        "tipo": tipo,
        "porJuego": {},
    }

    if tipo == "mame":
        mame_exe = emulador_de_launch(launch)
        if mame_exe is None or not mame_exe.is_file():
            raise ControlesError(
                f"no se encontro el ejecutable de MAME a partir de launch: {launch!r}"
            )
        mame_dir = mame_exe.parent
        ver = mame_version(mame_exe)
        ini_vals = mame_ini_valores(mame_dir / "mame.ini", {"joystick_map", "joystickprovider", "ctrlr"})
        ports_default = leer_cfg_ports(mame_dir / "cfg" / "default.cfg")
        ports_ctrlr: dict[str, str] = {}
        if ini_vals.get("ctrlr"):
            ports_ctrlr = leer_cfg_ports(mame_dir / "ctrlr" / f"{ini_vals['ctrlr']}.cfg")

        for b in juegos:
            set_id = identificar_set(b)
            if not set_id:
                continue
            try:
                xml_raiz = mame_listxml(mame_exe, set_id)
                declarados = controles_declarados(xml_raiz)
            except ControlesError as e:
                por_juego[set_id] = {"error": str(e)}
                continue

            ports_juego = leer_cfg_ports(mame_dir / "cfg" / f"{set_id}.cfg")
            por_juego[set_id] = {
                "sistema": "mame",
                "controlesDeclarados": declarados,
                "remapeoJuego": ports_juego,
                "controles": [
                    {**d, "verificado": False,
                     "motivo": "posicion fisica no medida en el perfil (Etapa F)"}
                    for d in declarados
                ],
            }
            huella_payload["porJuego"][set_id] = {
                "declarados": declarados,
                "remapeoJuego": sorted(ports_juego.items()),
            }

        huella_payload.update({
            "mameVersion": ver,
            "mameIni": sorted(ini_vals.items()),
            "portsDefault": sorted(ports_default.items()),
            "portsCtrlr": sorted(ports_ctrlr.items()),
        })

    elif tipo == "dosbox":
        for b in juegos:
            set_id = identificar_set(b)
            if not set_id:
                continue
            info = resolver_dosbox(coleccion_dir / set_id)
            salida_perfil = (perfil.get("salida") or {}).get("dosbox") or {}
            excepcion = (salida_perfil.get("excepciones") or {}).get(set_id)

            # Un mapperfile propio SIEMPRE deja la tecla sin confirmar, haya
            # o no una entrada de excepcion para este juego puntual en el
            # perfil - la entrada solo aporta el motivo documentado, no es
            # lo que decide si hay que dudar (spec 027, riesgo "config de
            # DOSBox en capas").
            if info["mapperfilePropio"]:
                motivo = (
                    excepcion["motivo"] if excepcion
                    else "mapperfile propio, sin excepcion declarada en el perfil"
                )
                salida = {"tecla": None, "verificado": False, "motivo": motivo}
            else:
                salida = {
                    "tecla": (salida_perfil.get("porDefecto") or {}).get("tecla"),
                    "verificado": True,
                    "motivo": None,
                }

            por_juego[set_id] = {
                "sistema": "dosbox",
                "joysticktype": info["joysticktype"],
                "mapperfilePropio": info["mapperfilePropio"],
                "salida": salida,
            }
            huella_payload["porJuego"][set_id] = info

    else:
        raise ControlesError(
            f"no se pudo determinar el emulador de {metadata_path} a partir de launch: {launch!r}"
        )

    return {
        "revisionPerfil": perfil.get("revision"),
        "tipo": tipo,
        "generadoEn": datetime.now(timezone.utc).isoformat(),
        "huella": calcular_huella(huella_payload),
        "porJuego": por_juego,
    }


def escribir_artefacto(raiz: Path, coleccion: str, artefacto: dict) -> Path:
    destino = raiz / coleccion / "_controles.json"
    with destino.open("w", encoding="utf-8", newline="\n") as f:
        json.dump(artefacto, f, ensure_ascii=False, indent=2)
        f.write("\n")
    return destino


def calcular_huella_actual(raiz: Path, coleccion: str) -> str | None:
    """La huella que TENDRIA hoy la coleccion, para que `doctor` la compare
    contra la guardada en _controles.json. None si las fuentes no estan
    disponibles en esta maquina (no es un error: se saltea, ver spec 027)."""
    try:
        return generar_coleccion(raiz, coleccion)["huella"]
    except ControlesError:
        return None


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main(argv: list[str] | None = None) -> int:
    argv = list(argv if argv is not None else sys.argv[1:])

    if argv and argv[0] in ("-h", "--help"):
        print("uso: attract controles <coleccion> [ruta] [--apply]")
        print()
        print("  Combina themes/attract/core/gabinete.json con la config real de")
        print("  MAME/DOSBox de esta maquina y escribe")
        print("  <ruta>/<coleccion>/_controles.json.")
        print()
        print("  Sin --apply no escribe nada: solo reporta que haria.")
        print("  No escribe ninguna configuracion de MAME ni de DOSBox, solo lee.")
        return 0

    aplicar = "--apply" in argv
    if aplicar:
        argv.remove("--apply")

    if not argv:
        print("error: falta <coleccion>", file=sys.stderr)
        return 2

    coleccion = argv[0]
    raiz = Path(argv[1]) if len(argv) > 1 else Path(".")

    try:
        artefacto = generar_coleccion(raiz, coleccion)
    except ControlesError as e:
        print(f"error: {e}", file=sys.stderr)
        return 2

    print()
    print(f"  {coleccion}  ({artefacto['tipo']})")
    verificados = 0
    total = 0
    for set_id, datos in artefacto["porJuego"].items():
        if "error" in datos:
            print(f"    {set_id:20} ERROR: {datos['error']}")
            continue
        if datos.get("sistema") == "dosbox":
            salida = datos["salida"]
            joy = datos["joysticktype"] or "sin config"
            v = "verificado" if salida["verificado"] else "sin verificar"
            print(f"    {set_id:20} joystick={joy:10} salida={salida['tecla'] or '?':10} ({v})")
            total += 1
            verificados += 1 if salida["verificado"] else 0
            continue
        controles = datos.get("controles") or []
        total += len(controles)
        verificados += sum(1 for c in controles if c.get("verificado"))
        print(f"    {set_id:20} {len(controles)} controles declarados")
    print()
    print(f"  {verificados}/{total} verificados contra el perfil")

    if aplicar:
        destino = escribir_artefacto(raiz, coleccion, artefacto)
        print(f"  escrito: {destino}")
    else:
        print("  Nada escrito - correlo con --apply para aplicar.")
    print()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
