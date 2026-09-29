"""Tests del perfil fisico del gabinete (themes/attract/core/gabinete.json).

No es parte de `doctor`: doctor recibe una biblioteca, y el perfil vive en
el theme, no en la biblioteca (spec/features/027-como-se-juega/plan.md)."""
import json
from pathlib import Path

from attract.doctor import GUIA_PERIFERICOS_CONOCIDOS

RUTA = Path(__file__).parent.parent / "themes" / "attract" / "core" / "gabinete.json"


def _cargar() -> dict:
    return json.loads(RUTA.read_text(encoding="utf-8"))


def test_es_json_valido():
    _cargar()


def test_tiene_los_campos_obligatorios():
    perfil = _cargar()
    for campo in ("revision", "jugadores", "flippers", "perifericos", "salida"):
        assert campo in perfil


def test_dos_jugadores_con_ocho_botones_cada_uno():
    perfil = _cargar()
    assert len(perfil["jugadores"]) == 2
    for jugador in perfil["jugadores"]:
        assert len(jugador["botones"]) == 8
        for boton in jugador["botones"]:
            assert "posicion" in boton
            assert "medido" in boton


def test_estado_de_hoy_jugador_1_instalado_jugador_2_no():
    perfil = _cargar()
    j1, j2 = perfil["jugadores"]
    assert j1["numero"] == 1 and j1["instalado"] is True
    assert j2["numero"] == 2 and j2["instalado"] is False


def test_ningun_boton_esta_medido_todavia():
    # Panel en transicion (Etapa F sin correr, docs/como-se-juega.md). Si
    # esto cambia algun dia sera porque de verdad se midio el panel final -
    # y ese cambio tiene que ser deliberado, no un default que se filtro.
    perfil = _cargar()
    for jugador in perfil["jugadores"]:
        for boton in jugador["botones"]:
            assert boton["medido"] is False


def test_vocabulario_de_perifericos_coincide_con_adr_0037():
    perfil = _cargar()
    claves = set(perfil["perifericos"])
    # Todas las claves del perfil tienen que ser perifericos que ADR-0037
    # reconoce - si no, el cruce guia.perifericos <-> perfil se rompe en
    # silencio (una comparacion de strings que nunca matchea).
    assert claves <= GUIA_PERIFERICOS_CONOCIDOS


def test_salida_trae_mame_y_dosbox():
    perfil = _cargar()
    assert "mame" in perfil["salida"]
    assert "dosbox" in perfil["salida"]
    assert perfil["salida"]["dosbox"]["porDefecto"]["tecla"] == "Ctrl+F9"


def test_excepciones_dosbox_declaran_motivo():
    perfil = _cargar()
    excepciones = perfil["salida"]["dosbox"]["excepciones"]
    assert excepciones  # al menos una: FIFA o Monkey Island
    for datos in excepciones.values():
        assert "motivo" in datos and datos["motivo"].strip()
