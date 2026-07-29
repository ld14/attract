"""Tests de attract mcp. Ver spec/features/003-attract-mcp/ y ADR-0012.

`mcp` es una dependencia OPCIONAL (ADR-0012) - los tests que la necesitan
usan pytest.importorskip, para que `pytest tests/` siga pasando en una
maquina sin `mcp` instalado (justo la garantia que motiva esta ADR).
"""
import shutil
import subprocess
import sys
from pathlib import Path

import pytest

FIXTURES = Path(__file__).parent.parent / "fixtures" / "arcade"
SRC = Path(__file__).parent.parent / "src"


# --- aislamiento: doctor/synopsis/cli no dependen de mcp -------------------
# Se corre en un subproceso aparte, bloqueando 'mcp' via sys.modules ANTES
# de importar nada de attract - as{i} confirma que ningun import a nivel de
# modulo se filtra, sin importar si mcp esta instalado en esta maquina.

_SCRIPT_SIN_MCP = """
import sys
sys.modules["mcp"] = None
import attract.doctor
import attract.synopsis
import attract.cli
import attract.mcp_server
print("IMPORTS_OK")
r = attract.mcp_server.main([])
print("MAIN_EXIT", r)
"""


def test_modulos_importan_sin_mcp_instalado():
    resultado = subprocess.run(
        [sys.executable, "-c", _SCRIPT_SIN_MCP],
        cwd=SRC.parent,
        env={"PYTHONPATH": str(SRC), "PATH": "/usr/bin:/bin"},
        capture_output=True,
        text=True,
        timeout=15,
    )
    assert "IMPORTS_OK" in resultado.stdout, resultado.stderr
    assert "MAIN_EXIT 2" in resultado.stdout, resultado.stdout


def test_mcp_main_sin_paquete_dice_como_instalarlo():
    resultado = subprocess.run(
        [sys.executable, "-c", _SCRIPT_SIN_MCP],
        cwd=SRC.parent,
        env={"PYTHONPATH": str(SRC), "PATH": "/usr/bin:/bin"},
        capture_output=True,
        text=True,
        timeout=15,
    )
    assert "pip install mcp" in resultado.stderr


def test_cli_tiene_el_comando_mcp_registrado():
    # cli.COMANDOS se arma al importar el modulo - no requiere mcp instalado
    # para EXISTIR como entrada, solo para invocarse de verdad.
    from attract import cli

    assert "mcp" in cli.COMANDOS


# --- logica de las tools, sin pasar por el protocolo MCP -------------------
# _run_doctor / _run_synopsis son funciones planas: no requieren el SDK mcp
# instalado, solo se importan sin ejecutar _construir_app().

from attract.mcp_server import _run_doctor, _run_synopsis  # noqa: E402


def _copiar_fixtures(tmp_path):
    destino = tmp_path / "arcade"
    shutil.copytree(FIXTURES, destino)
    return destino


def test_run_doctor_devuelve_dict_estructurado():
    r = _run_doctor(str(FIXTURES))
    assert r["ok"] is True
    assert r["archivos_vistos"] > 0
    assert isinstance(r["errores"], list)
    assert isinstance(r["avisos"], list)
    assert any(a["chequeo"] == "mags-ref-faltante" for a in r["avisos"])


def test_run_synopsis_caso_feliz(tmp_path):
    raiz = _copiar_fixtures(tmp_path)
    r = _run_synopsis("mok", str(raiz))
    assert r["ok"] is True
    assert "arqueólogos" in r["summary"] or "arqueologos" in r["summary"]

    contenido = (raiz / "metadata.pegasus.txt").read_text(encoding="utf-8")
    assert r["summary"] in contenido


def test_run_synopsis_sin_fuente_no_rompe():
    r = _run_synopsis("no-existe-este-set", str(FIXTURES))
    assert r["ok"] is False
    assert "no existe fuente" in r["error"]


def test_run_synopsis_sin_metadata_pegasus_txt(tmp_path):
    r = _run_synopsis("x", str(tmp_path))
    assert r["ok"] is False
    assert "no existe" in r["error"]


# --- registro de tools contra el SDK real, si esta instalado ---------------

def test_construir_app_registra_las_dos_tools():
    pytest.importorskip("mcp", reason="mcp es una dependencia opcional (ADR-0012)")
    import asyncio

    from attract.mcp_server import _construir_app

    app = _construir_app()
    tools = asyncio.run(app.list_tools())
    nombres = {t.name for t in tools}
    assert nombres == {"attract_doctor", "attract_synopsis"}
