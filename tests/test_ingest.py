"""Tests de attract ingest. Ver spec/features/004-attract-ingest/.

La mayoria de los tests mockean subprocess.run con XML SINTETICO, basado en
conocimiento general del formato.

test_mame_no_instalado_falla_explicito no mockea subprocess: corre el
codigo de verdad contra un PATH vacio. Antes se apoyaba en que el sandbox
donde se escribio no tenia mame instalado - y en cuanto el autor lo
instalo en su Mac (2026-07-29, v0.288), el test empezo a fallar. Un test
que depende de que una herramienta NO exista se invierte solo al cambiar
de maquina, que es justo lo contrario de lo que tiene que hacer un test.
Ahora fuerza la ausencia en vez de asumirla, y da igual en que maquina
corra.

test_forma_real_confirmada_2026_07_29 es distinto: usa XML_SF2CE_REAL, la
salida LITERAL de `mame -listxml sf2ce` (mame vanilla 0.288) que el autor
corrio en su Mac y pego en el chat - no es una suposicion. Confirma: el
DOCTYPE con subset interno no rompe ET.fromstring, los tags <description>/
<year>/<manufacturer> son los que se asumian, runnable="no" filtra bien, y
el titulo real trae basura de region pegada ("Street Fighter II': Champion
Edition (World 920513)") - se decidio dejarlo crudo, ver construir_bloque.
"""
import shutil
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

# Salida REAL de `mame -listxml sf2ce` (mame vanilla 0.288), pegada por el
# autor 2026-07-29. Recortada (sin <rom>/<dipswitch>/etc: el parser de
# ingest.py solo mira description/year/manufacturer/runnable, el resto no
# cambia el resultado) pero el DOCTYPE con subset interno se dejo COMPLETO
# a proposito - eso es justo lo que habia que confirmar que no rompe
# ET.fromstring.
XML_SF2CE_REAL = """<?xml version="1.0"?>
<!DOCTYPE mame [
<!ELEMENT mame (machine+)>
	<!ATTLIST mame build CDATA #IMPLIED>
	<!ATTLIST mame debug (yes|no) "no">
	<!ATTLIST mame mameconfig CDATA #REQUIRED>
	<!ELEMENT machine (description, year?, manufacturer?)>
		<!ATTLIST machine name CDATA #REQUIRED>
		<!ATTLIST machine sourcefile CDATA #IMPLIED>
		<!ATTLIST machine runnable (yes|no) "yes">
		<!ELEMENT description (#PCDATA)>
		<!ELEMENT year (#PCDATA)>
		<!ELEMENT manufacturer (#PCDATA)>
]>
<mame build="0.288 (unknown)" debug="no" mameconfig="10">
	<machine name="sf2ce" sourcefile="capcom/cps1.cpp">
		<description>Street Fighter II': Champion Edition (World 920513)</description>
		<year>1992</year>
		<manufacturer>Capcom</manufacturer>
		<driver status="good" emulation="good" savestate="supported"/>
	</machine>
	<machine name="generic_latch_8" sourcefile="devices/machine/gen_latch.cpp" isdevice="yes" runnable="no">
		<description>Generic 8-bit latch</description>
	</machine>
	<machine name="z80" sourcefile="devices/cpu/z80/z80.cpp" isdevice="yes" runnable="no">
		<description>Zilog Z80</description>
	</machine>
</mame>
"""


def _mock_run(stdout, returncode=0):
    def _fake(*a, **kw):
        return subprocess.CompletedProcess(a, returncode, stdout=stdout, stderr="")
    return _fake


# --- mame no esta en el PATH (real, sin mockear subprocess) ----------------

def test_mame_no_instalado_falla_explicito(tmp_path, monkeypatch):
    # PATH apuntando a un directorio vacio: mame no se encuentra por mas que
    # este instalado en la maquina. Se ejercita el FileNotFoundError real de
    # subprocess, no un mock - que es el punto de este test.
    monkeypatch.setenv("PATH", str(tmp_path))
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


# --- forma real, confirmada 2026-07-29 contra mame vanilla 0.288 real -----

def test_forma_real_confirmada_2026_07_29():
    """XML_SF2CE_REAL es la salida literal que el autor corrio en su Mac,
    no una suposicion. Confirma tres cosas a la vez: el DOCTYPE con subset
    interno no rompe el parseo, los tags son los que ingest.py esperaba, y
    runnable="no" filtra los devices (quedan 3 <machine>, 1 jugable)."""
    with patch("subprocess.run", side_effect=_mock_run(XML_SF2CE_REAL)):
        maquinas = listar_maquinas_jugables("sf2ce")

    assert len(maquinas) == 1
    assert maquinas[0] == {
        "name": "sf2ce",
        "description": "Street Fighter II': Champion Edition (World 920513)",
        "year": "1992",
        "manufacturer": "Capcom",
    }

    # el titulo real trae basura de region pegada - decision (2026-07-29):
    # se deja crudo, construir_bloque no intenta limpiarlo (mismo criterio
    # que ya usaba: "no inventa nada que -listxml no traiga", limpiar con
    # una regex seria "adivinar" en el sentido que el proyecto evita).
    bloque = construir_bloque(maquinas[0], "sf2ce.zip", "sf2ce")
    assert bloque.lineas == [
        "game: Street Fighter II': Champion Edition (World 920513)",
        "file: sf2ce.zip",
        "developer: Capcom",
        "release: 1992",
        "x-set: sf2ce",
    ]


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


# --- integracion contra el mame real de la maquina -------------------------
#
# Se saltea si no hay mame en el PATH, mismo criterio que test_mcp_server.py
# con el SDK mcp: `pytest tests/` sigue pasando en una maquina pelada. La
# diferencia con todo lo de arriba es que aca NO hay mock - corre el binario
# de verdad y parsea su salida de verdad.
#
# Este test no existia porque hasta el 2026-07-29 no habia mame en ninguna
# maquina donde se corriera la suite. El autor lo instalo (vanilla 0.288) y
# con eso el ultimo agujero honesto de 004-attract-ingest se puede cerrar:
# hasta ahora TODO el modulo estaba probado contra XML sintetico o contra una
# salida pegada a mano en el chat.

sin_mame = pytest.mark.skipif(
    shutil.which("mame") is None,
    reason="mame no esta instalado en esta maquina",
)


@sin_mame
def test_integracion_mame_real_identifica_un_set_conocido():
    maquinas = listar_maquinas_jugables("1943")
    assert len(maquinas) == 1, [m["name"] for m in maquinas]
    assert maquinas[0]["name"] == "1943"
    # -listxml lee la base de datos interna de mame, no el archivo: por eso
    # ingest se puede probar con fixtures de 0 bytes (CLAUDE.md).
    assert maquinas[0]["year"] == "1987"
    assert "Capcom" in maquinas[0]["manufacturer"]


@sin_mame
def test_integracion_mame_real_set_inexistente_falla_explicito():
    with pytest.raises(IngestError):
        identificar("no-existe-este-set-en-mame")


@sin_mame
def test_integracion_aplicar_punta_a_punta_con_mame_real(tmp_path):
    (tmp_path / "metadata.pegasus.txt").write_text(
        "collection: Arcade\n\ngame: Otro\nfile: otro.zip\n", encoding="utf-8"
    )
    rom = tmp_path / "1943.zip"
    rom.write_bytes(b"")

    aplicar(tmp_path / "metadata.pegasus.txt", tmp_path, rom)

    texto = (tmp_path / "metadata.pegasus.txt").read_text(encoding="utf-8")
    assert "x-set: 1943" in texto
    assert "release: 1987" in texto
    assert "developer: Capcom" in texto
    assert "game: Otro" in texto        # no piso lo que ya estaba
    assert (tmp_path / "media" / "1943").is_dir()

    # El titulo real trae basura de region pegada, igual que el
    # "(World 920513)" de sf2ce. Se deja crudo a proposito (spec.md
    # #Fuera de alcance) - este assert existe para que si algun dia alguien
    # agrega limpieza por regex, se entere de que rompe una decision.
    assert "1943: The Battle of Midway" in texto
