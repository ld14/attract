"""Tests de attract ingest. Ver spec/features/004-attract-ingest/.

IMPORTANTE: no hay mame instalado en este sandbox. Los tests que necesitan
la forma del XML mockean subprocess.run con un XML SINTETICO basado en
conocimiento general del formato de mame -listxml, NO verificado contra un
binario real (ver spec.md, "Sobre mame -listxml: sin verificar en esta
sesion"). El unico test que corre contra el mame real de esta maquina es
test_mame_no_instalado_falla_explicito - y da el resultado esperado
precisamente PORQUE mame no esta instalado aca.
"""
import subprocess
from pathlib import Path
from unittest.mock import patch

import pytest

from attract.ingest import (
    IngestError,
    aplicar,
    construir_bloque,
    identificar,
    listar_maquinas_jugables,
)

# XML sintetico, forma basada en conocimiento general del esquema de MAME,
# no capturado de un binario real en esta sesion.
XML_SF2CE = """<?xml version="1.0"?>
<mame build="0.288">
<machine name="sf2ce" sourcefile="capcom/cps1.cpp">
    <description>Street Fighter II' - Champion Edition (Japan 920513)</description>
    <year>1992</year>
    <manufacturer>Capcom</manufacturer>
</machine>
<machine name="z80" sourcefile="devices/cpu/z80/z80.cpp" isdevice="yes" runnable="no">
    <description>Zilog Z80</description>
</machine>
</mame>
"""

XML_SIN_MACHINES = """<?xml version="1.0"?>
<mame build="0.288">
</mame>
"""

XML_DOS_JUGABLES = """<?xml version="1.0"?>
<mame build="0.288">
<machine name="setA" sourcefile="x.cpp">
    <description>Set A</description>
</machine>
<machine name="setB" sourcefile="x.cpp">
    <description>Set B</description>
</machine>
</mame>
"""


def _mock_run(stdout, returncode=0):
    def _fake(*a, **kw):
        return subprocess.CompletedProcess(a, returncode, stdout=stdout, stderr="")
    return _fake


# --- mame no esta instalado (real, sin mockear) ----------------------------

def test_mame_no_instalado_falla_explicito():
    with pytest.raises(IngestError, match="no esta en el PATH"):
        listar_maquinas_jugables("sf2ce")


# --- parseo del XML (mockeado, ver advertencia arriba del archivo) --------

def test_lista_maquinas_filtra_runnable_no():
    with patch("subprocess.run", side_effect=_mock_run(XML_SF2CE)):
        maquinas = listar_maquinas_jugables("sf2ce")
    assert len(maquinas) == 1
    assert maquinas[0]["name"] == "sf2ce"
    assert maquinas[0]["manufacturer"] == "Capcom"
    assert maquinas[0]["year"] == "1992"


def test_identificar_cero_maquinas_falla():
    with patch("subprocess.run", side_effect=_mock_run(XML_SIN_MACHINES)):
        with pytest.raises(IngestError, match="no reconocido"):
            identificar("setinexistente")


def test_identificar_mas_de_una_maquina_falla():
    with patch("subprocess.run", side_effect=_mock_run(XML_DOS_JUGABLES)):
        with pytest.raises(IngestError, match="ADR-0004"):
            identificar("setA")


def test_xml_invalido_falla_explicito():
    with patch("subprocess.run", side_effect=_mock_run("esto no es xml <<<")):
        with pytest.raises(IngestError, match="XML valido"):
            listar_maquinas_jugables("x")


# --- construir_bloque: no inventa datos que -listxml no dio ---------------

def test_construir_bloque_completo():
    info = {"description": "Street Fighter II' - CE", "year": "1992", "manufacturer": "Capcom"}
    b = construir_bloque(info, "sf2ce.zip", "sf2ce")
    assert b.lineas == [
        "game: Street Fighter II' - CE",
        "file: sf2ce.zip",
        "developer: Capcom",
        "release: 1992",
        "x-set: sf2ce",
    ]


def test_construir_bloque_sin_year_ni_manufacturer():
    info = {"description": "Algo", "year": None, "manufacturer": None}
    b = construir_bloque(info, "algo.zip", "algo")
    assert b.lineas == ["game: Algo", "file: algo.zip", "x-set: algo"]
    assert not any(l.startswith("developer:") for l in b.lineas)
    assert not any(l.startswith("release:") for l in b.lineas)


# --- aplicar: flujo completo, contra un metadata.pegasus.txt real --------

def _metadata_minimo(tmp_path):
    p = tmp_path / "metadata.pegasus.txt"
    p.write_text(
        "collection: Arcade\n"
        "shortname: arcad\n"
        "launch: mame {file.basename}\n"
        "\n"
        "game: Ya Existe\n"
        "file: existente.zip\n"
        "x-set: existente\n",
        encoding="utf-8",
    )
    return p


def test_aplicar_agrega_bloque_nuevo(tmp_path):
    metadata_path = _metadata_minimo(tmp_path)
    with patch("subprocess.run", side_effect=_mock_run(XML_SF2CE)):
        set_id = aplicar(metadata_path, tmp_path, Path("sf2ce.zip"))

    assert set_id == "sf2ce"
    contenido = metadata_path.read_text(encoding="utf-8")
    assert "game: Street Fighter II' - Champion Edition (Japan 920513)" in contenido
    assert "x-set: sf2ce" in contenido
    # lo que ya estaba, intacto
    assert "game: Ya Existe" in contenido
    assert "x-set: existente" in contenido
    # carpeta de media creada
    assert (tmp_path / "media" / "sf2ce").is_dir()


def test_aplicar_no_duplica_set_existente(tmp_path):
    metadata_path = _metadata_minimo(tmp_path)
    original = metadata_path.read_text(encoding="utf-8")

    with pytest.raises(IngestError, match="ya tiene un bloque"):
        aplicar(metadata_path, tmp_path, Path("existente.zip"))

    # no se toco el archivo
    assert metadata_path.read_text(encoding="utf-8") == original


def test_aplicar_mame_no_reconoce_no_escribe_nada(tmp_path):
    metadata_path = _metadata_minimo(tmp_path)
    original = metadata_path.read_text(encoding="utf-8")

    with patch("subprocess.run", side_effect=_mock_run(XML_SIN_MACHINES)):
        with pytest.raises(IngestError):
            aplicar(metadata_path, tmp_path, Path("no-existe.zip"))

    assert metadata_path.read_text(encoding="utf-8") == original
    assert not (tmp_path / "media" / "no-existe").exists()
