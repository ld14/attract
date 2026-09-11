"""Instalacion y reparacion reales a traves del launcher PowerShell."""
import json
import shutil
import subprocess
import zipfile
from pathlib import Path

import pytest


POWERSHELL = shutil.which("powershell.exe")
ROOT = Path(__file__).parents[1]
pytestmark = pytest.mark.skipif(POWERSHELL is None, reason="requiere Windows PowerShell")


def test_instala_y_repara_desde_powershell_con_espacios(tmp_path):
    archive = tmp_path / "mi paquete.zip"
    library = tmp_path / "mis juegos"
    with zipfile.ZipFile(archive, "w") as bundle:
        bundle.writestr("game.json", json.dumps({
            "schema_version": "1", "system": "msdos", "set": "demo",
            "title": "Demo", "file": "demo.zip", "tratamiento": "copiar",
        }))
        bundle.writestr("media/demo.zip", b"")
    command = [POWERSHELL, "-NoProfile", "-ExecutionPolicy", "Bypass", "-File",
               str(ROOT / "install-coindoor.ps1"), str(archive), str(library)]
    first = subprocess.run(command, input="s\n", capture_output=True, text=True)
    assert first.returncode == 0, first.stdout + first.stderr
    metadata = library / "msdos/metadata.pegasus.txt"
    assert metadata.read_text(encoding="utf-8").startswith("collection: Msdos\n")
    assert (library / "msdos/demo.zip").exists()
    assert "configure-pegasus-wsl.sh" in first.stdout
    metadata.write_text("game: Demo\nfile: demo.zip\nx-set: demo\n", encoding="utf-8")
    second = subprocess.run(command, input="", capture_output=True, text=True)
    assert second.returncode == 0, second.stdout + second.stderr
    assert metadata.read_text(encoding="utf-8").startswith("collection: Msdos\n")
    assert metadata.read_text(encoding="utf-8").count("game: Demo") == 1
