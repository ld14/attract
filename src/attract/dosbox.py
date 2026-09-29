"""Resuelve arranques DOS sin ejecutar programas ni consultar la red."""

from __future__ import annotations

import hashlib
import re
import sys
from dataclasses import dataclass
from pathlib import Path, PurePosixPath

from attract import doctor
from attract.dosbox_motores import MOTORES
from attract.dosbox_profiles import PERFILES

BASE = {"cpu_cycles": 3000, "sbtype": "sbpro2", "sound_env": False}
SBTYPES = {"sb1", "sb2", "sbpro1", "sbpro2", "sb16", "none"}
EJECUTABLE_DOS = re.compile(r"^[A-Za-z0-9_!#$~.-]{1,8}\.(exe|com|bat)$", re.I)
UTILIDAD = re.compile(r"^(install|setup|config|uninst|unins|patch|readme|dosbox)|_trn", re.I)
# Programas de utilidad de DOS genericos que suelen quedar sueltos en
# distribuciones de juegos viejos (compresores, drivers) - nunca son el
# juego en si, pase lo que pase con el titulo. Nombre exacto, no prefijo:
# a diferencia de UTILIDAD, ARJ/LHA no son parte del nombre de ningun juego.
UTILIDADES_CONOCIDAS = {
    "PKARC", "PKXARC", "PKPAK", "PKZIP", "PKUNZIP", "ARJ", "LHA", "LHARC",
    "ARC", "ZIP2EXE", "UNZIP", "MOUSE", "DOSKEY", "SHARE",
}
IMAGEN_EXT = {".img", ".ima", ".iso", ".cue"}
TIPOS_IMAGEN = {"floppy", "cdrom"}


class DosboxError(ValueError):
    pass


@dataclass
class Preparacion:
    config: str | None
    launch: str | None
    informe: dict


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def validar_declaracion(game: dict) -> None:
    if "dosbox" not in game:
        return
    datos = game["dosbox"]
    if game.get("system") != "msdos" or game.get("tratamiento") != "descomprimir":
        raise DosboxError("dosbox requiere system msdos y tratamiento descomprimir")
    if not isinstance(datos, dict) or not datos.get("executable"):
        raise DosboxError("dosbox requiere un objeto con executable relativo al juego")

    imagenes = datos.get("imagenes")
    claves_imagen = {"imagenes", "tipo_imagen"} if imagenes is not None else set()
    extras = set(datos) - {"executable", *BASE, *claves_imagen}
    if extras:
        raise DosboxError(f"opciones dosbox desconocidas: {sorted(extras)}")

    if imagenes is not None:
        # ADR-0034: el ejecutable vive DENTRO de la imagen (floppy/CD), no en
        # el arbol extraido - no se puede verificar su existencia sin un
        # parser de FAT12/ISO9660, que este proyecto no tiene (stdlib-only).
        if not isinstance(imagenes, list) or not imagenes or not all(isinstance(i, str) for i in imagenes):
            raise DosboxError("dosbox.imagenes debe ser una lista de rutas no vacia")
        for ruta in imagenes:
            rep = doctor.Reporte()
            doctor.chk_ruta_relativa(ruta, rep)
            if rep.errores:
                raise DosboxError(f"dosbox.imagenes: {rep.errores[0].detalle}")
            if PurePosixPath(ruta).suffix.lower() not in IMAGEN_EXT:
                raise DosboxError(f"dosbox.imagenes: extension no reconocida en '{ruta}'")
        if datos.get("tipo_imagen") not in TIPOS_IMAGEN:
            raise DosboxError(f"dosbox.tipo_imagen debe ser uno de {sorted(TIPOS_IMAGEN)}")
        if not EJECUTABLE_DOS.fullmatch(PurePosixPath(datos["executable"]).name):
            raise DosboxError("dosbox.executable requiere nombre DOS 8.3 .exe/.com/.bat")
    else:
        rep = doctor.Reporte()
        doctor.chk_ruta_relativa(datos["executable"], rep)
        if rep.errores:
            raise DosboxError("dosbox.executable: " + rep.errores[0].detalle)
        if not EJECUTABLE_DOS.fullmatch(PurePosixPath(datos["executable"]).name):
            raise DosboxError("dosbox.executable requiere nombre DOS 8.3 .exe/.com/.bat")

    cycles = datos.get("cpu_cycles", BASE["cpu_cycles"])
    if type(cycles) is not int or not 100 <= cycles <= 200000:
        raise DosboxError("dosbox.cpu_cycles debe ser entero entre 100 y 200000")
    sbtype = datos.get("sbtype", BASE["sbtype"])
    if not isinstance(sbtype, str) or sbtype not in SBTYPES:
        raise DosboxError("dosbox.sbtype no soportado")
    if type(datos.get("sound_env", False)) is not bool:
        raise DosboxError("dosbox.sound_env debe ser booleano")


def _indice(raiz: Path) -> dict[str, Path]:
    return {p.relative_to(raiz).as_posix().casefold(): p
            for p in raiz.rglob("*") if p.is_file()}


def _conocidos(raiz: Path, archivos: dict[str, Path]) -> list[tuple[dict, Path]]:
    matches = []
    hashes: dict[Path, str] = {}
    for perfil in PERFILES:
        for path in archivos.values():
            if path.name.casefold() != perfil["executable"].casefold():
                continue
            for name, esperado in perfil["files"].items():
                rel = (path.parent.relative_to(raiz) / name).as_posix().casefold()
                p = archivos.get(rel)
                if p is None:
                    break
                if p not in hashes:
                    hashes[p] = sha256(p)
                if hashes[p] != esperado:
                    break
            else:
                matches.append((perfil, path))
    return matches


def _detectar_motor(archivos: dict[str, Path]) -> tuple[dict, Path] | None:
    """Busca, por carpeta, la firma de archivos de un motor conocido
    (ADR-0033). Nunca parsea ni ejecuta binarios - solo nombres de archivo."""
    por_carpeta: dict[Path, set[str]] = {}
    for path in archivos.values():
        por_carpeta.setdefault(path.parent, set()).add(path.name.upper())
    for motor in MOTORES:
        for carpeta, nombres in por_carpeta.items():
            if not motor["requeridos"] <= nombres:
                continue
            if not any(n.startswith(pref) for pref in motor["prefijos"] for n in nombres):
                continue
            return motor, carpeta
    return None


def comando_launch() -> str:
    binary = "dosbox.exe" if sys.platform == "win32" else "dosbox"
    return (
        f'"{{file.path}}/../../../emulators/dosbox-staging/{binary}" '
        '--working-dir "{file.path}" --nolocalconf --conf "{file.path}/dosbox.conf"'
    )


def generar_config(subdir: str, executable: str | None, settings: dict) -> str:
    lineas = [
        "# Generado por ATTRACT. Rutas relativas a la carpeta del juego.",
        "# Base inicial; el informe distingue perfil probado y provisional.",
        "[sdl]", "fullscreen = true", "", "[dosbox]",
        "machine = svga_s3", "memsize = 16", "", "[cpu]", "core = auto",
        f"cpu_cycles = {settings['cpu_cycles']}", "", "[sblaster]",
        f"sbtype = {settings['sbtype']}", "sbbase = 220", "irq = 7", "dma = 1",
        "", "[joystick]", "joysticktype = disabled", "", "[autoexec]", "@echo off",
    ]
    if executable is None:
        lineas += ["echo ATTRACT: arranque pendiente de revision.",
                   "echo Revisar media/SET/_dosbox.json y declarar dosbox.executable.",
                   "pause", "exit"]
    else:
        lineas += [f'mount c "{subdir}"', "c:"]
        if settings["sound_env"]:
            lineas.append("set SOUND=C:\\")
        lineas += [("call " if executable.lower().endswith(".bat") else "") + executable,
                   "exit"]
    return "\n".join(lineas) + "\n"


def generar_config_imagen(imagenes: list[str], tipo: str, executable: str, settings: dict) -> str:
    """Config con arranque por `imgmount` en vez de `mount` de directorio.

    El ejecutable no se verifica contra ningun archivo real: vive dentro de
    la imagen, que no se monta durante el import (ADR-0034)."""
    lineas = [
        "# Generado por ATTRACT. Arranque por imagen de disco declarada.",
        "# El ejecutable no se pudo verificar: esta dentro de la imagen.",
        "[sdl]", "fullscreen = true", "", "[dosbox]",
        "machine = svga_s3", "memsize = 16", "", "[cpu]", "core = auto",
        f"cpu_cycles = {settings['cpu_cycles']}", "", "[sblaster]",
        f"sbtype = {settings['sbtype']}", "sbbase = 220", "irq = 7", "dma = 1",
        "", "[joystick]", "joysticktype = disabled", "", "[autoexec]", "@echo off",
    ]
    letra = "a" if tipo == "floppy" else "d"
    tipo_imgmount = "floppy" if tipo == "floppy" else "iso"
    imgs = " ".join(f'"{i}"' for i in imagenes)
    lineas.append(f"imgmount {letra} {imgs} -t {tipo_imgmount}")
    lineas.append(f"{letra}:")
    if settings["sound_env"]:
        lineas.append("set SOUND=C:\\")
    lineas += [("call " if executable.lower().endswith(".bat") else "") + executable, "exit"]
    return "\n".join(lineas) + "\n"


def preparar(raiz: Path, game: dict, *, conservar: bool = False) -> Preparacion:
    validar_declaracion(game)
    informe = {"schema_version": "1", "emulator": "dosbox-staging",
               "status": "pendiente", "profile": None, "sources": [],
               "verification": "no ejecutado durante import", "warnings": []}
    if (raiz / "dosbox.conf").exists():
        informe["status"] = "conservado" if conservar else "aportado"
        informe["warnings"].append("Configuracion existente conservada; no se certifica su compatibilidad.")
        return Preparacion(None, None if conservar else comando_launch(), informe)

    archivos = _indice(raiz)
    conocidos = _conocidos(raiz, archivos)
    declarado = game.get("dosbox")
    settings = dict(BASE)
    elegido = None
    if declarado and declarado.get("imagenes") is not None:
        rutas = declarado["imagenes"]
        faltantes = [r for r in rutas if archivos.get(r.casefold()) is None]
        if faltantes:
            raise DosboxError(f"imagen declarada ausente: {faltantes[0]}")
        settings.update({k: v for k, v in declarado.items() if k in BASE})
        informe.update(
            status="declarado", images=list(rutas), image_type=declarado["tipo_imagen"],
            executable=declarado["executable"], settings=settings,
            verification="no verificable: ejecutable dentro de una imagen sin montar",
        )
        config = generar_config_imagen(rutas, declarado["tipo_imagen"], declarado["executable"], settings)
        return Preparacion(config, comando_launch(), informe)
    if declarado:
        elegido = archivos.get(declarado["executable"].casefold())
        if elegido is None:
            raise DosboxError(f"ejecutable DOS declarado ausente: {declarado['executable']}")
        settings.update({k: v for k, v in declarado.items() if k in BASE})
        informe["status"] = "declarado"
    elif len(conocidos) == 1:
        perfil, elegido = conocidos[0]
        settings.update(perfil["settings"])
        informe.update(status="perfil-conocido", profile=perfil["id"],
                       sources=perfil["sources"], evidence=perfil["evidence"],
                       tested_emulator_version=perfil["emulator_version"])
    else:
        candidatos = [p for p in archivos.values()
                      if EJECUTABLE_DOS.fullmatch(p.name) and not UTILIDAD.search(p.stem)
                      and p.stem.upper() not in UTILIDADES_CONOCIDAS]
        motor_match = _detectar_motor(archivos)
        if motor_match is not None:
            motor, carpeta_motor = motor_match
            candidatos_motor = [p for p in candidatos if p.parent == carpeta_motor]
            if len(candidatos_motor) == 1 and candidatos_motor[0].suffix.lower() in {".exe", ".com"}:
                elegido = candidatos_motor[0]
                settings.update(motor["settings"])
                informe.update(status="motor-detectado", profile=motor["id"],
                               sources=motor["sources"], evidence=motor["evidence"])
                informe["warnings"].append(
                    f"Config por motor detectado ({motor['nombre']}), no por copia "
                    "verificada - confirmar jugabilidad."
                )
        if elegido is None:
            informe["candidates"] = [p.relative_to(raiz).as_posix() for p in sorted(candidatos)]
            # No ejecutar automaticamente un BAT sin inspeccion de sus comandos.
            if len(candidatos) == 1 and candidatos[0].suffix.lower() in {".exe", ".com"}:
                elegido = candidatos[0]
                informe["status"] = "provisional"
            else:
                informe["warnings"].append("No hay un unico arranque DOS; declarar executable o completar la instalacion.")
                imagenes_sueltas = [p for p in archivos.values() if p.suffix.lower() in IMAGEN_EXT]
                if imagenes_sueltas:
                    informe["warnings"].append(
                        "Se encontraron imagenes de disco (.img/.iso/.cue): no se puede "
                        "enumerar su contenido sin montarlas. Declarar dosbox.imagenes, "
                        "dosbox.tipo_imagen y dosbox.executable."
                    )
    if elegido:
        rel = elegido.relative_to(raiz)
        rep = doctor.Reporte()
        doctor.chk_ruta_relativa(rel.as_posix(), rep)
        if rep.errores:
            raise DosboxError(rep.errores[0].detalle)
        if settings["sound_env"] and not any(p.name.lower() == "ct-voice.drv"
                                             for p in elegido.parent.iterdir()):
            raise DosboxError("sound_env requiere CT-VOICE.DRV junto al ejecutable")
        informe.update(executable=rel.as_posix(), executable_sha256=sha256(elegido),
                       settings=settings)
        if informe["status"] != "perfil-conocido":
            informe["warnings"].append("Configuracion sin prueba de jugabilidad; ajustar sonido, velocidad y controles.")
        config = generar_config(rel.parent.as_posix(), elegido.name, settings)
    else:
        config = generar_config(".", None, settings)
    return Preparacion(config, comando_launch(), informe)
