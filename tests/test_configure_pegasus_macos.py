from __future__ import annotations

import os
import shutil
import subprocess
from pathlib import Path

import pytest


def encontrar_bash() -> str | None:
    if os.name == "nt":
        git_bash = Path("C:/Program Files/Git/bin/bash.exe")
        if git_bash.is_file():
            return str(git_bash)
    return shutil.which("bash")


BASH = encontrar_bash()
SCRIPT = Path(__file__).parents[1] / "scripts" / "configure-pegasus-macos.sh"
pytestmark = pytest.mark.skipif(BASH is None, reason="requiere Bash")


def test_juego_sin_coleccion_falla_antes_de_configurar(tmp_path):
    proyecto = proyecto_minimo(tmp_path, con_library=True)
    escribir(proyecto / "library/arcade/metadata.pegasus.txt", "game: Elvira\nfile: elvira\n")
    config = tmp_path / "config"
    resultado = ejecutar(proyecto, "--config-directory", str(config))
    assert resultado.returncode != 0
    assert "collection:" in resultado.stderr
    assert not config.exists()


def ruta_bash(path: Path) -> str:
    if os.name != "nt":
        return str(path)
    windows = str(path.resolve()).replace("\\", "/")
    assert len(windows) >= 3 and windows[1:3] == ":/"
    return f"/{windows[0].lower()}{windows[2:]}"


def escribir(path: Path, contenido: str = "") -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(contenido, encoding="utf-8")


def proyecto_minimo(tmp_path: Path, con_library: bool = False) -> Path:
    proyecto = tmp_path / "project"
    escribir(proyecto / "themes" / "attract" / "theme.cfg", "name: ATTRACT\n")
    escribir(proyecto / "themes" / "attract" / "theme.qml", "import QtQuick 2.0\nItem {}\n")
    escribir(
        proyecto / "fixtures" / "arcade" / "metadata.pegasus.txt",
        "collection: Fixture\n\ngame: Fixture\nfile: fixture.zip\n",
    )
    (proyecto / "library").mkdir(parents=True)
    if con_library:
        escribir(
            proyecto / "library" / "arcade" / "metadata.pegasus.txt",
            "collection: Arcade\n\ngame: Demo\nfile: demo.zip\n",
        )
    return proyecto


def ejecutar(proyecto: Path, *argumentos: str) -> subprocess.CompletedProcess[str]:
    convertidos = [ruta_bash(Path(valor)) if indice % 2 == 1 else valor for indice, valor in enumerate(argumentos)]
    return subprocess.run(
        [
            BASH,
            ruta_bash(SCRIPT),
            "--project-root",
            ruta_bash(proyecto),
            "--skip-launch",
            "--skip-process-control",
            *convertidos,
        ],
        capture_output=True,
        text=True,
        check=False,
    )


def test_macos_fallback_backups_e_idempotencia(tmp_path: Path) -> None:
    proyecto = proyecto_minimo(tmp_path)
    config = tmp_path / "config"
    escribir(config / "settings.txt", "providers.steam.enabled: true\ncustom.keep: yes\n")
    escribir(config / "game_dirs.txt", "/old/games\n")
    escribir(config / "themes" / "attract" / "sentinel.txt", "anterior")

    primera = ejecutar(proyecto, "--config-directory", str(config))
    assert primera.returncode == 0, primera.stderr
    settings_primera = (config / "settings.txt").read_bytes()
    assert not settings_primera.startswith(b"\xef\xbb\xbf")
    assert b"providers.steam.enabled: false\n" in settings_primera
    assert b"custom.keep: yes\n" in settings_primera
    assert (config / "game_dirs.txt").read_text(encoding="utf-8").strip() == ruta_bash(
        proyecto / "fixtures" / "arcade"
    )

    segunda = ejecutar(proyecto, "--config-directory", str(config))
    assert segunda.returncode == 0, segunda.stderr
    assert (config / "settings.txt").read_bytes() == settings_primera
    assert [ruta.name for ruta in (config / "themes").iterdir()] == ["attract"]
    assert len(list((config / "backups" / "themes").glob("attract.bak-*"))) == 2


def test_macos_detecta_library_y_config_portable(tmp_path: Path) -> None:
    proyecto = proyecto_minimo(tmp_path, con_library=True)
    app = tmp_path / "Pegasus.app"
    ejecutable = app / "Contents" / "MacOS" / "pegasus-fe"
    escribir(ejecutable)
    escribir(ejecutable.parent / "portable.txt")

    resultado = ejecutar(proyecto, "--pegasus-app", str(app))

    assert resultado.returncode == 0, resultado.stderr
    game_dirs = ejecutable.parent / "config" / "game_dirs.txt"
    assert game_dirs.read_text(encoding="utf-8").strip() == ruta_bash(
        proyecto / "library" / "arcade"
    )


def test_macos_invalida_y_dry_run_no_escriben(tmp_path: Path) -> None:
    proyecto = proyecto_minimo(tmp_path)
    invalida = tmp_path / "sin-metadata"
    invalida.mkdir()
    config_invalida = tmp_path / "config-invalida"

    invalido = ejecutar(
        proyecto,
        "--config-directory",
        str(config_invalida),
        "--game-directory",
        str(invalida),
    )
    assert invalido.returncode != 0
    assert not config_invalida.exists()

    config_dry = tmp_path / "config-dry"
    dry = ejecutar(
        proyecto,
        "--config-directory",
        str(config_dry),
        "--dry-run",
    )
    assert dry.returncode == 0, dry.stderr
    assert not config_dry.exists()
