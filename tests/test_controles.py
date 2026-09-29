"""Tests de `attract controles` (spec/features/027-como-se-juega/).

La mayoria son unitarios contra texto sintetico (ningun binario real hace
falta). Al final hay un puñado de integracion contra el MAME 0.288 real de
esta maquina (library/_mame32/mame.exe) - se saltean si no esta, igual
criterio que `sin_mame` de test_ingest.py, pero resuelto por RUTA y no por
PATH: `ingest.py` llama a "mame" pelado y en este gabinete no esta en el
PATH (docs/como-se-juega.md #8) - `controles.py` existe justamente para no
repetir ese error, y sus tests lo verifican contra el binario de verdad.
"""
import json
import subprocess
import tempfile
import xml.etree.ElementTree as ET
from pathlib import Path

import pytest

from attract.controles import (
    ControlesError,
    calcular_huella,
    calcular_huella_actual,
    controles_declarados,
    emulador_de_launch,
    escribir_artefacto,
    generar_coleccion,
    launch_de_coleccion,
    leer_cfg_ports,
    leer_perfil,
    mame_ini_valores,
    resolver_dosbox,
    tipo_emulador,
)
from attract.doctor import revisar


def _escribir(path: Path, texto: str) -> None:
    """write_text forzando LF: en Windows, newline=None traduce '\\n' a
    '\\r\\n' al escribir, y chk_crlf del doctor rechaza eso."""
    path.write_text(texto, encoding="utf-8", newline="\n")


# ---------------------------------------------------------------------------
# launch: -> emulador
# ---------------------------------------------------------------------------

def test_launch_de_coleccion_toma_la_linea_de_cabecera():
    texto = 'collection: Arcade\nlaunch: "C:/mame/mame.exe" "{file.path}"\n\ngame: X\nfile: x.zip\n'
    assert launch_de_coleccion(texto) == '"C:/mame/mame.exe" "{file.path}"'


def test_launch_de_coleccion_ausente_da_none():
    assert launch_de_coleccion("collection: Arcade\n\ngame: X\nfile: x.zip\n") is None


def test_emulador_de_launch_extrae_primera_ruta_con_comillas():
    launch = '"D:/Juegos/attract/library/_mame32/mame.exe" "{file.path}"'
    assert emulador_de_launch(launch) == Path("D:/Juegos/attract/library/_mame32/mame.exe")


def test_emulador_de_launch_sin_comillas_da_none():
    # El bug real de docs/como-se-juega.md #8: launch: sin comilla de
    # apertura. Sin comillas no hay ruta que extraer con certeza.
    launch = "D:/Juegos/attract/library/_mame32/mame.exe {file.path}"
    assert emulador_de_launch(launch) is None


@pytest.mark.parametrize("launch,esperado", [
    ('"C:/mame/mame.exe" "{file.path}"', "mame"),
    ('"C:/dosbox-staging/dosbox.exe" --conf "{file.path}/dosbox.conf"', "dosbox"),
    ('"C:/algo/otro.exe" "{file.path}"', "desconocido"),
])
def test_tipo_emulador(launch, esperado):
    assert tipo_emulador(launch) == esperado


# ---------------------------------------------------------------------------
# .cfg de MAME
# ---------------------------------------------------------------------------

CFG_SIMPSONS = """<?xml version="1.0"?>
<mameconfig version="10">
    <system name="simpsons">
        <input>
            <port tag=":COIN" type="COIN1" mask="1" defvalue="1">
                <newseq type="standard">
                    JOYCODE_1_BUTTON7
                </newseq>
            </port>
            <port tag=":P1" type="P1_BUTTON1" mask="16" defvalue="16">
                <newseq type="standard">
                    JOYCODE_1_BUTTON5
                </newseq>
            </port>
        </input>
    </system>
</mameconfig>
"""


def test_leer_cfg_ports_parsea_remapeo_real(tmp_path):
    # Mismo contenido que library/_mame32/cfg/simpsons.cfg (piloto 027).
    cfg = tmp_path / "simpsons.cfg"
    _escribir(cfg, CFG_SIMPSONS)
    ports = leer_cfg_ports(cfg)
    assert ports == {"COIN1": "JOYCODE_1_BUTTON7", "P1_BUTTON1": "JOYCODE_1_BUTTON5"}


def test_leer_cfg_ports_archivo_ausente_da_vacio(tmp_path):
    # "Un .cfg ausente vale lo mismo que uno sin <input>" (spec 027).
    assert leer_cfg_ports(tmp_path / "no-existe.cfg") == {}


def test_leer_cfg_ports_default_sin_input_da_vacio(tmp_path):
    # Caso real de esta maquina: default.cfg solo tiene <mixer>.
    cfg = tmp_path / "default.cfg"
    _escribir(
        cfg,
        '<?xml version="1.0"?><mameconfig version="10">'
        "<system name=\"default\"><mixer/></system></mameconfig>",
    )
    assert leer_cfg_ports(cfg) == {}


def test_mame_ini_valores_extrae_solo_las_claves_pedidas(tmp_path):
    ini = tmp_path / "mame.ini"
    _escribir(
        ini,
        "# comentario\njoystick_map               auto\n"
        "joystickprovider          auto\nconfirm_quit              0\n",
    )
    vals = mame_ini_valores(ini, {"joystick_map", "joystickprovider"})
    assert vals == {"joystick_map": "auto", "joystickprovider": "auto"}


def test_mame_ini_valores_archivo_ausente_da_vacio(tmp_path):
    assert mame_ini_valores(tmp_path / "no-existe.ini", {"ctrlr"}) == {}


# ---------------------------------------------------------------------------
# -listxml (contra XML sintetico, sin mame)
# ---------------------------------------------------------------------------

XML_PACMAN = """<mame>
  <machine name="pacman" runnable="yes">
    <input players="2" coins="2">
      <control type="joy" player="1" ways="4"/>
      <control type="joy" player="2" ways="4"/>
    </input>
  </machine>
</mame>"""

XML_SFA2 = """<mame>
  <machine name="sfa2" runnable="yes">
    <input players="2" coins="2">
      <control type="joy" player="1" buttons="6" ways="8"/>
      <control type="joy" player="2" buttons="6" ways="8"/>
    </input>
  </machine>
</mame>"""

XML_SIN_MAQUINA_JUGABLE = """<mame>
  <machine name="93c46" runnable="no">
    <input players="0"/>
  </machine>
</mame>"""


def test_controles_declarados_pacman_sin_botones():
    # Confirmado a mano en el piloto (2026-09-28): pacman no tiene ningun
    # boton, solo dos joysticks de 4 direcciones.
    declarados = controles_declarados(ET.fromstring(XML_PACMAN))
    assert len(declarados) == 2
    assert all(c["type"] == "joy" and c["buttons"] is None for c in declarados)


def test_controles_declarados_sfa2_seis_botones():
    declarados = controles_declarados(ET.fromstring(XML_SFA2))
    assert declarados[0] == {"type": "joy", "player": "1", "buttons": "6", "ways": "8"}


def test_controles_declarados_sin_maquina_jugable_da_vacio():
    assert controles_declarados(ET.fromstring(XML_SIN_MAQUINA_JUGABLE)) == []


# ---------------------------------------------------------------------------
# DOSBox
# ---------------------------------------------------------------------------

def test_resolver_dosbox_config_generada_sin_mapperfile(tmp_path):
    _escribir(tmp_path / "dosbox.conf", "[joystick]\njoysticktype = disabled\n")
    info = resolver_dosbox(tmp_path)
    assert info == {"joysticktype": "disabled", "mapperfilePropio": False}


def test_resolver_dosbox_con_mapperfile_propio(tmp_path):
    # Caso real: FIFA / Monkey Island (config de pack).
    _escribir(
        tmp_path / "dosbox.conf",
        "[sdl]\nmapperfile = mapper-ECE.map\n\n[joystick]\njoysticktype = auto\n",
    )
    info = resolver_dosbox(tmp_path)
    assert info == {"joysticktype": "auto", "mapperfilePropio": True}


def test_resolver_dosbox_sin_conf_no_falla(tmp_path):
    assert resolver_dosbox(tmp_path) == {"joysticktype": None, "mapperfilePropio": False}


def test_resolver_dosbox_encoding_no_utf8_no_falla(tmp_path):
    # Caso real: library/msdos/monkey-island/dosbox.conf (config "de pack",
    # comentarios en Windows-1252, ".conf" fuera de EXT_TEXTO de doctor.py
    # asi que nunca lo atrapa chk_encoding). Lo que hace falta parsear es
    # ASCII puro y tiene que seguir leyendose bien.
    conf = tmp_path / "dosbox.conf"
    crudo = (
        "[autoexec]\r\n"
        "# L\xedneas en espa\xf1ol con acentos\r\n"
        "\r\n[joystick]\r\njoysticktype = auto\r\n"
    ).encode("cp1252")
    conf.write_bytes(crudo)
    assert resolver_dosbox(tmp_path) == {"joysticktype": "auto", "mapperfilePropio": False}


# ---------------------------------------------------------------------------
# Huella
# ---------------------------------------------------------------------------

def test_huella_es_estable():
    payload = {"a": 1, "b": [1, 2, 3]}
    assert calcular_huella(payload) == calcular_huella(dict(payload))


def test_huella_cambia_si_cambia_el_contenido():
    assert calcular_huella({"a": 1}) != calcular_huella({"a": 2})


def test_huella_no_ve_contadores_de_creditos_ni_mezclador():
    # Es la garantia central de la spec 027: MAME reescribe <counters>/<mixer>
    # al cerrar el juego, y eso NO puede entrar al payload de la huella. Este
    # test verifica el contrato de mas alto nivel: dos .cfg que solo difieren
    # en esos dos tags dan el mismo resultado de leer_cfg_ports (que es lo
    # unico que entra a la huella).
    base = CFG_SIMPSONS
    con_contador = base.replace(
        "<input>", '<counters><coins index="0" number="99"/></counters><input>'
    )
    with tempfile.TemporaryDirectory() as d:
        a = Path(d) / "a.cfg"
        b = Path(d) / "b.cfg"
        _escribir(a, base)
        _escribir(b, con_contador)
        assert leer_cfg_ports(a) == leer_cfg_ports(b)


# ---------------------------------------------------------------------------
# Perfil
# ---------------------------------------------------------------------------

def test_leer_perfil_ausente_es_controles_error(tmp_path):
    with pytest.raises(ControlesError):
        leer_perfil(tmp_path)


def test_leer_perfil_corrupto_es_controles_error(tmp_path):
    (tmp_path / "core").mkdir()
    _escribir(tmp_path / "core" / "gabinete.json", "{no valido")
    with pytest.raises(ControlesError):
        leer_perfil(tmp_path)


def test_leer_perfil_real_del_theme():
    theme_root = Path(__file__).parent.parent / "themes" / "attract"
    perfil = leer_perfil(theme_root)
    assert perfil["revision"] == 1
    assert len(perfil["jugadores"]) == 2


# ---------------------------------------------------------------------------
# generar_coleccion: casos sin binario (errores explicitos, dry-run)
# ---------------------------------------------------------------------------

def _fixture_theme(tmp_path) -> Path:
    theme_root = tmp_path / "themes" / "attract"
    (theme_root / "core").mkdir(parents=True)
    perfil = {
        "revision": 7,
        "jugadores": [],
        "flippers": {"cantidad": 2, "instalado": False},
        "perifericos": {"keyboard": {"instalado": True}, "mouse": {"instalado": True}},
        "salida": {
            "mame": {"tecla": "Esc"},
            "dosbox": {"porDefecto": {"tecla": "Ctrl+F9"}, "excepciones": {}},
        },
    }
    _escribir(theme_root / "core" / "gabinete.json", json.dumps(perfil))
    return tmp_path


def test_generar_coleccion_sin_metadata_es_controles_error(tmp_path):
    raiz = _fixture_theme(tmp_path) / "library"
    raiz.mkdir()
    with pytest.raises(ControlesError):
        generar_coleccion(raiz, "arcade")


def test_generar_coleccion_sin_launch_es_controles_error(tmp_path):
    raiz = _fixture_theme(tmp_path) / "library"
    coleccion = raiz / "arcade"
    coleccion.mkdir(parents=True)
    _escribir(coleccion / "metadata.pegasus.txt", "collection: Arcade\n\ngame: X\nfile: x.zip\n")
    with pytest.raises(ControlesError):
        generar_coleccion(raiz, "arcade")


def test_generar_coleccion_dosbox_no_necesita_binario(tmp_path):
    raiz = _fixture_theme(tmp_path) / "library"
    coleccion = raiz / "msdos"
    juego = coleccion / "prehistorik"
    juego.mkdir(parents=True)
    _escribir(
        coleccion / "metadata.pegasus.txt",
        'collection: Msdos\nlaunch: "C:/dosbox/dosbox.exe" --conf "{file.path}/dosbox.conf"\n\n'
        "game: Prehistorik\nfile: prehistorik\n",
    )
    _escribir(juego / "dosbox.conf", "[joystick]\njoysticktype = disabled\n")

    artefacto = generar_coleccion(raiz, "msdos")
    assert artefacto["tipo"] == "dosbox"
    assert artefacto["porJuego"]["prehistorik"]["salida"]["verificado"] is True
    assert artefacto["porJuego"]["prehistorik"]["salida"]["tecla"] == "Ctrl+F9"


def test_generar_coleccion_dosbox_con_mapperfile_sin_excepcion_no_verificado(tmp_path):
    raiz = _fixture_theme(tmp_path) / "library"
    coleccion = raiz / "msdos"
    juego = coleccion / "un-juego-random"
    juego.mkdir(parents=True)
    _escribir(
        coleccion / "metadata.pegasus.txt",
        'collection: Msdos\nlaunch: "C:/dosbox/dosbox.exe" --conf "{file.path}/dosbox.conf"\n\n'
        "game: Un Juego Random\nfile: un-juego-random\n",
    )
    _escribir(
        juego / "dosbox.conf",
        "[sdl]\nmapperfile = mapper-custom.map\n\n[joystick]\njoysticktype = auto\n",
    )

    artefacto = generar_coleccion(raiz, "msdos")
    salida = artefacto["porJuego"]["un-juego-random"]["salida"]
    # Mapperfile propio SIEMPRE deja la tecla sin confirmar, exista o no una
    # entrada de excepcion para este juego puntual en el perfil.
    assert salida["verificado"] is False
    assert salida["tecla"] is None


def test_escribir_artefacto_dry_run_no_toca_disco(tmp_path):
    raiz = _fixture_theme(tmp_path) / "library"
    coleccion = raiz / "msdos"
    coleccion.mkdir(parents=True)
    _escribir(
        coleccion / "metadata.pegasus.txt",
        'collection: Msdos\nlaunch: "C:/dosbox/dosbox.exe" --conf "{file.path}/dosbox.conf"\n',
    )
    generar_coleccion(raiz, "msdos")  # dry-run: no escribe nada por si solo
    assert not (coleccion / "_controles.json").exists()


def test_escribir_artefacto_apply_escribe(tmp_path):
    raiz = _fixture_theme(tmp_path) / "library"
    coleccion = raiz / "msdos"
    coleccion.mkdir(parents=True)
    _escribir(
        coleccion / "metadata.pegasus.txt",
        'collection: Msdos\nlaunch: "C:/dosbox/dosbox.exe" --conf "{file.path}/dosbox.conf"\n',
    )
    artefacto = generar_coleccion(raiz, "msdos")
    destino = escribir_artefacto(raiz, "msdos", artefacto)
    assert destino.is_file()
    assert json.loads(destino.read_text(encoding="utf-8"))["huella"] == artefacto["huella"]


# ---------------------------------------------------------------------------
# Integracion con doctor: correspondencia vencida
# ---------------------------------------------------------------------------

def test_correspondencia_sin_artefacto_no_avisa_nada(tmp_path):
    raiz = _fixture_theme(tmp_path) / "library"
    (raiz / "msdos").mkdir(parents=True)
    rep = revisar(raiz)
    assert "correspondencia-vencida" not in {h.chequeo for h in rep.avisos}


def test_correspondencia_sin_perfil_se_saltea_sin_fallar(tmp_path):
    # raiz sin themes/attract al lado: calcular_huella_actual no puede
    # recalcular, y el chequeo se saltea en silencio (no es un ERROR).
    raiz = tmp_path / "library"
    coleccion = raiz / "msdos"
    coleccion.mkdir(parents=True)
    _escribir(coleccion / "_controles.json", json.dumps({"huella": "sha256:lo-que-sea"}))
    rep = revisar(raiz)
    assert rep.ok
    assert "correspondencia-vencida" not in {h.chequeo for h in rep.avisos}


def test_correspondencia_huella_desactualizada_avisa(tmp_path):
    raiz = _fixture_theme(tmp_path) / "library"
    coleccion = raiz / "msdos"
    coleccion.mkdir(parents=True)
    _escribir(
        coleccion / "metadata.pegasus.txt",
        'collection: Msdos\nlaunch: "C:/dosbox/dosbox.exe" --conf "{file.path}/dosbox.conf"\n',
    )
    _escribir(
        coleccion / "_controles.json",
        json.dumps({"huella": "sha256:esto-no-va-a-coincidir-nunca"}),
    )
    rep = revisar(raiz)
    assert rep.ok  # AVISO, no ERROR - no es compatibilidad cross-platform
    assert "correspondencia-vencida" in {h.chequeo for h in rep.avisos}


def test_correspondencia_huella_al_dia_no_avisa(tmp_path):
    raiz = _fixture_theme(tmp_path) / "library"
    coleccion = raiz / "msdos"
    coleccion.mkdir(parents=True)
    _escribir(
        coleccion / "metadata.pegasus.txt",
        'collection: Msdos\nlaunch: "C:/dosbox/dosbox.exe" --conf "{file.path}/dosbox.conf"\n',
    )
    huella_real = calcular_huella_actual(raiz, "msdos")
    assert huella_real is not None
    _escribir(coleccion / "_controles.json", json.dumps({"huella": huella_real}))
    rep = revisar(raiz)
    assert "correspondencia-vencida" not in {h.chequeo for h in rep.avisos}


def test_correspondencia_jugar_no_vence_la_huella_remapear_si(tmp_path):
    # El criterio de aceptacion mas importante de la spec 027: reescribir
    # <counters>/<mixer> (lo que hace MAME al cerrar el juego) no vence la
    # huella; remapear <input> si.
    raiz = _fixture_theme(tmp_path) / "library"
    coleccion = raiz / "arcade"
    mame_dir = raiz.parent / "mame"
    (mame_dir / "cfg").mkdir(parents=True)
    mame_exe = mame_dir / "mame.exe"
    mame_exe.write_bytes(b"")  # no se ejecuta en este test (no hay juegos que listar)

    coleccion.mkdir(parents=True)
    _escribir(
        coleccion / "metadata.pegasus.txt",
        f'collection: Arcade\nlaunch: "{mame_exe}" "{{file.path}}"\n',
    )

    _escribir(
        mame_dir / "cfg" / "default.cfg",
        '<?xml version="1.0"?><mameconfig version="10">'
        '<system name="default"><counters><coins index="0" number="5"/></counters>'
        "</system></mameconfig>",
    )
    huella_antes = generar_coleccion(raiz, "arcade")["huella"]

    # "Jugar" = MAME reescribe el contador de creditos, sin tocar <input>.
    _escribir(
        mame_dir / "cfg" / "default.cfg",
        '<?xml version="1.0"?><mameconfig version="10">'
        '<system name="default"><counters><coins index="0" number="9999"/></counters>'
        "</system></mameconfig>",
    )
    huella_despues_de_jugar = generar_coleccion(raiz, "arcade")["huella"]
    assert huella_antes == huella_despues_de_jugar

    # "Remapear" = un <input> nuevo en default.cfg.
    _escribir(
        mame_dir / "cfg" / "default.cfg",
        '<?xml version="1.0"?><mameconfig version="10">'
        '<system name="default"><input><port tag=":P1" type="P1_BUTTON1" mask="1" defvalue="1">'
        "<newseq>JOYCODE_1_BUTTON3</newseq></port></input></system></mameconfig>",
    )
    huella_despues_de_remapear = generar_coleccion(raiz, "arcade")["huella"]
    assert huella_despues_de_remapear != huella_antes


# ---------------------------------------------------------------------------
# Integracion contra el MAME 0.288 real de esta maquina
# ---------------------------------------------------------------------------
#
# ingest.py llama a "mame" pelado y en este gabinete no esta en el PATH
# (docs/como-se-juega.md #8) - por eso su `sin_mame` (shutil.which) siempre
# se saltea aca. `controles.py` resuelve el ejecutable por RUTA (desde
# launch:), asi que estos tests SI corren en esta maquina.

_MAME_REAL = Path(__file__).parent.parent / "library" / "_mame32" / "mame.exe"

sin_mame_real = pytest.mark.skipif(
    not _MAME_REAL.is_file(),
    reason="library/_mame32/mame.exe no esta en esta maquina",
)


@sin_mame_real
def test_integracion_mame_version_real():
    from attract.controles import mame_version
    assert mame_version(_MAME_REAL) == "0.288"


@sin_mame_real
def test_integracion_listxml_pacman_real_sin_botones():
    xml_raiz = ET.fromstring(
        subprocess.run(
            [str(_MAME_REAL), "-listxml", "pacman"],
            capture_output=True, text=True, timeout=30,
        ).stdout
    )
    declarados = controles_declarados(xml_raiz)
    assert all(c["buttons"] is None for c in declarados)


@sin_mame_real
def test_integracion_mame_ini_real_confirm_quit_cero():
    ini = _MAME_REAL.parent / "mame.ini"
    vals = mame_ini_valores(ini, {"confirm_quit"})
    assert vals.get("confirm_quit") == "0"


@sin_mame_real
def test_integracion_default_cfg_real_sin_input():
    cfg = _MAME_REAL.parent / "cfg" / "default.cfg"
    assert leer_cfg_ports(cfg) == {}


@sin_mame_real
def test_integracion_simpsons_cfg_real_si_existe():
    cfg = _MAME_REAL.parent / "cfg" / "simpsons.cfg"
    if not cfg.is_file():
        pytest.skip("simpsons.cfg no esta en esta maquina")
    ports = leer_cfg_ports(cfg)
    assert ports.get("P1_BUTTON1") == "JOYCODE_1_BUTTON5"
    assert ports.get("P1_BUTTON2") == "JOYCODE_1_BUTTON1"
    assert ports.get("START1") == "JOYCODE_1_BUTTON6"
    assert ports.get("COIN1") == "JOYCODE_1_BUTTON7"
