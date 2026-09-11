"""Limite Bash/PowerShell: espacios y errores sin tocar Pegasus real."""
import os
import subprocess
from pathlib import Path

import pytest

from test_configure_pegasus_macos import BASH, ruta_bash


pytestmark = pytest.mark.skipif(BASH is None, reason="requiere Bash")
ROOT = Path(__file__).parents[1]


@pytest.mark.parametrize("launcher", ["configure-pegasus-wsl.sh", "install-coindoor-wsl.sh"])
def test_rutas_con_espacios_y_error_de_powershell(tmp_path, launcher):
    library = tmp_path / "mis juegos"
    library.mkdir()
    archive = tmp_path / "mi paquete.zip"
    archive.touch()
    # Funciones exportadas simulan la interoperabilidad, incluyendo codigo 7.
    harness = r'''
wslpath() { printf 'WIN:%s\n' "$3"; }
powershell.exe() { printf '<%s>\n' "$@"; return 7; }
exec() { "$@"; }
export -f wslpath powershell.exe exec
bash "$@"
'''
    args = [ruta_bash(library)]
    if launcher.startswith("install"):
        args.insert(0, ruta_bash(archive))
    result = subprocess.run(
        [BASH, "-c", harness, "test", ruta_bash(ROOT / launcher), *args],
        capture_output=True, text=True,
        env={**os.environ, "MSYS_NO_PATHCONV": "1"},
    )
    assert result.returncode == 7, result.stderr
    assert f"<WIN:{ruta_bash(library)}>" in result.stdout
    if launcher.startswith("install"):
        assert f"<WIN:{ruta_bash(archive)}>" in result.stdout
    else:
        assert "<-LibraryRoot>" in result.stdout


def test_configurador_rechaza_libreria_ausente(tmp_path):
    result = subprocess.run(
        [BASH, "-c", 'wslpath() { :; }; powershell.exe() { exit 99; }; export -f wslpath powershell.exe; bash "$@"',
         "test", ruta_bash(ROOT / "configure-pegasus-wsl.sh"), ruta_bash(tmp_path / "ausente")],
        capture_output=True, text=True,
    )
    assert result.returncode == 1
    assert "no existe la libreria" in result.stderr
