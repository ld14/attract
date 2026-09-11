import shutil
import subprocess
from pathlib import Path

import pytest


POWERSHELL = shutil.which("powershell.exe")
SCRIPT = Path(__file__).parents[1] / "scripts" / "configure-pegasus-windows.ps1"
pytestmark = pytest.mark.skipif(POWERSHELL is None, reason="requiere Windows PowerShell")


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
    return subprocess.run(
        [
            POWERSHELL,
            "-NoProfile",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            str(SCRIPT),
            "-ProjectRoot",
            str(proyecto),
            "-SkipLaunch",
            "-SkipProcessControl",
            *argumentos,
        ],
        capture_output=True,
        text=True,
        check=False,
    )


def test_fallback_backups_e_idempotencia(tmp_path: Path) -> None:
    proyecto = proyecto_minimo(tmp_path)
    config = tmp_path / "config"
    escribir(config / "settings.txt", "providers.steam.enabled: true\ncustom.keep: yes\n")
    escribir(config / "game_dirs.txt", "C:\\old\\games\n")
    escribir(config / "themes" / "attract" / "sentinel.txt", "anterior")

    primera = ejecutar(proyecto, "-ConfigDirectory", str(config))
    assert primera.returncode == 0, primera.stderr
    settings_primera = (config / "settings.txt").read_bytes()
    assert not settings_primera.startswith(b"\xef\xbb\xbf")
    texto_primera = settings_primera.decode("utf-8")
    assert "general.theme: themes/attract/\n" in texto_primera
    assert "providers.steam.enabled: false\n" in texto_primera
    assert "custom.keep: yes\n" in texto_primera
    assert (config / "game_dirs.txt").read_text(encoding="utf-8").strip() == str(
        proyecto / "fixtures" / "arcade"
    )

    segunda = ejecutar(proyecto, "-ConfigDirectory", str(config))
    assert segunda.returncode == 0, segunda.stderr
    assert (config / "settings.txt").read_bytes() == settings_primera
    assert [ruta.name for ruta in (config / "themes").iterdir()] == ["attract"]
    assert len(list((config / "backups" / "themes").glob("attract.bak-*"))) == 2
    assert len(list(config.glob("settings.txt.bak-*"))) == 2


def test_detecta_library_y_config_portable(tmp_path: Path) -> None:
    proyecto = proyecto_minimo(tmp_path, con_library=True)
    pegasus = tmp_path / "Pegasus" / "pegasus-fe.exe"
    escribir(pegasus)
    escribir(pegasus.parent / "portable.txt")

    resultado = ejecutar(proyecto, "-PegasusExe", str(pegasus))

    assert resultado.returncode == 0, resultado.stderr
    game_dirs = pegasus.parent / "config" / "game_dirs.txt"
    assert game_dirs.read_text(encoding="utf-8").strip() == str(
        proyecto / "library" / "arcade"
    )


def test_ruta_explicita_invalida_no_escribe(tmp_path: Path) -> None:
    proyecto = proyecto_minimo(tmp_path)
    invalida = tmp_path / "sin-metadata"
    invalida.mkdir()
    config = tmp_path / "config-invalida"

    resultado = ejecutar(
        proyecto,
        "-ConfigDirectory",
        str(config),
        "-GameDirectory",
        str(invalida),
    )

    assert resultado.returncode != 0
    assert not config.exists()


def test_juego_sin_coleccion_falla_antes_de_configurar(tmp_path):
    proyecto = proyecto_minimo(tmp_path, con_library=True)
    escribir(proyecto / "library/arcade/metadata.pegasus.txt", "game: Elvira\nfile: elvira\n")
    config = tmp_path / "config"
    resultado = ejecutar(proyecto, "-ConfigDirectory", str(config))
    assert resultado.returncode != 0
    assert "collection:" in resultado.stderr
    assert not config.exists()


def test_library_externa_con_espacios(tmp_path):
    proyecto = proyecto_minimo(tmp_path)
    library = tmp_path / "mis juegos"
    escribir(library / "msdos/metadata.pegasus.txt", "collection: Msdos\n\ngame: Elvira\nfile: elvira\n")
    config = tmp_path / "config"
    resultado = ejecutar(proyecto, "-ConfigDirectory", str(config), "-LibraryRoot", str(library))
    assert resultado.returncode == 0, resultado.stderr
    assert (config / "game_dirs.txt").read_text(encoding="utf-8").strip() == str(library / "msdos")
