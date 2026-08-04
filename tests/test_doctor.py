"""Tests del doctor. Cada uno reproduce un bug que paso de verdad."""
import json
import unicodedata
from pathlib import Path

import pytest

from attract.doctor import revisar


def chequeos(rep):
    return {h.chequeo for h in rep.errores}


def test_fixtures_limpios_pasan():
    rep = revisar(Path(__file__).parent.parent / "fixtures")
    assert rep.ok, [h.detalle for h in rep.errores]


def test_byte_invalido(tmp_path):
    # El bug real: 0x93 suelto donde iba C3 93. Un byte, archivo entero roto.
    (tmp_path / "metadata.pegasus.txt").write_bytes(b"game: M\x93DULO\n")
    assert "encoding" in chequeos(revisar(tmp_path))


def test_crlf(tmp_path):
    (tmp_path / "metadata.pegasus.txt").write_bytes(b"game: X\r\n")
    assert "crlf" in chequeos(revisar(tmp_path))


def test_dos_puntos_en_nombre(tmp_path):
    # Street Fighter II: Champion Edition -> ilegal en Windows, OK en macOS
    d = tmp_path / "Street Fighter II: Champion Edition"
    d.mkdir()
    (d / "x.zip").write_bytes(b"")
    assert "nombre-windows" in chequeos(revisar(tmp_path))


def test_nombre_reservado(tmp_path):
    (tmp_path / "AUX.zip").write_bytes(b"")
    assert "nombre-windows" in chequeos(revisar(tmp_path))


def test_nfd_en_nombre(tmp_path):
    d = tmp_path / unicodedata.normalize("NFD", "Micromanía")
    d.mkdir()
    (d / "p.jpg").write_bytes(b"")
    assert "nfc-nombre" in chequeos(revisar(tmp_path))


def test_nfd_en_contenido(tmp_path):
    # git NO te salva aca: la ruta dentro del archivo es texto, no un nombre.
    ruta = unicodedata.normalize("NFD", "media/Micromanía/p.jpg")
    (tmp_path / "metadata.pegasus.txt").write_text(
        f"game: X\nassets.boxFront: {ruta}\n", encoding="utf-8"
    )
    assert "nfc-contenido" in chequeos(revisar(tmp_path))


def test_basura_macos(tmp_path):
    (tmp_path / "._mok.zip").write_bytes(b"")
    assert "basura-macos" in chequeos(revisar(tmp_path))


def test_asset_faltante(tmp_path):
    (tmp_path / "metadata.pegasus.txt").write_text(
        "game: X\nassets.boxFront: media/no-existe.jpg\n", encoding="utf-8"
    )
    assert "asset-faltante" in chequeos(revisar(tmp_path))


def test_data_json_invalido(tmp_path):
    d = tmp_path / "media" / "x"
    d.mkdir(parents=True)
    (d / "data.json").write_text('{"mags": [},', encoding="utf-8")
    assert "json-invalido" in chequeos(revisar(tmp_path))


def test_magazine_json_invalido(tmp_path):
    d = tmp_path / "media" / "_magazines" / "rev-1"
    d.mkdir(parents=True)
    (d / "magazine.json").write_text("{no es json", encoding="utf-8")
    assert "json-invalido" in chequeos(revisar(tmp_path))


def test_mags_ref_faltante_es_aviso_no_error(tmp_path):
    # Degradacion soportada a proposito (ADR-0008): no bloquea el viaje a
    # Windows, pero attract doctor la tiene que notar.
    d = tmp_path / "media" / "x"
    d.mkdir(parents=True)
    (d / "data.json").write_text('{"mags": [{"ref": "no-existe"}]}', encoding="utf-8")

    rep = revisar(tmp_path)
    assert rep.ok  # no es error
    assert "mags-ref-faltante" in {h.chequeo for h in rep.avisos}


def test_mags_ref_existente_no_avisa(tmp_path):
    (tmp_path / "media" / "_magazines" / "rev-1").mkdir(parents=True)
    d = tmp_path / "media" / "x"
    d.mkdir(parents=True)
    (d / "data.json").write_text('{"mags": [{"ref": "rev-1"}]}', encoding="utf-8")

    rep = revisar(tmp_path)
    assert "mags-ref-faltante" not in {h.chequeo for h in rep.avisos}


# --- contrato de magazine.json (ADR-0010) ---------------------------------

def _magazine_valida(**overrides):
    base = {
        "name": "PC JUEGOS",
        "issue": "32",
        "year": 1993,
        "color": "#7d2fb8",
        "cover": "cover.jpg",
        "key_id": "pc-juegos-032",
        "pages": ["p001.jpg", "p002.jpg"],
        "articles": [
            {
                "type": "review",
                "game": "mario",
                "title": "Super Mario",
                "startPage": 1,
                "pages": [1],
                "confidence": 0.9,
                "cheats": True,
                "walkthrough": False,
                "tips": True,
            }
        ],
    }
    base.update(overrides)
    return base


def _escribir_magazine(tmp_path, datos):
    d = tmp_path / "media" / "_magazines" / "rev-1"
    d.mkdir(parents=True)
    (d / "magazine.json").write_text(json.dumps(datos), encoding="utf-8")


def test_magazine_valida_no_reporta_nada(tmp_path):
    _escribir_magazine(tmp_path, _magazine_valida())
    rep = revisar(tmp_path)
    assert rep.ok
    assert "magazine-contrato" not in {h.chequeo for h in rep.hallazgos}


def test_magazine_sin_campo_obligatorio_es_error(tmp_path):
    datos = _magazine_valida()
    del datos["key_id"]
    _escribir_magazine(tmp_path, datos)
    assert "magazine-contrato" in chequeos(revisar(tmp_path))


def test_magazine_confidence_fuera_de_rango_es_error(tmp_path):
    datos = _magazine_valida()
    datos["articles"][0]["confidence"] = 1.5
    _escribir_magazine(tmp_path, datos)
    assert "magazine-contrato" in chequeos(revisar(tmp_path))


def test_magazine_articulo_sin_game_ni_title_es_valido(tmp_path):
    # publicidad, indice, etc. no tratan sobre un juego puntual (ADR-0010)
    datos = _magazine_valida()
    datos["articles"][0] = {
        "type": "publicidad",
        "startPage": 2,
        "pages": [2],
        "confidence": 0.99,
    }
    _escribir_magazine(tmp_path, datos)
    rep = revisar(tmp_path)
    assert rep.ok
    assert "magazine-contrato" not in {h.chequeo for h in rep.hallazgos}


def test_magazine_type_desconocido_es_aviso_no_error(tmp_path):
    datos = _magazine_valida()
    datos["articles"][0]["type"] = "tipo-nuevo-no-catalogado"
    _escribir_magazine(tmp_path, datos)
    rep = revisar(tmp_path)
    assert rep.ok  # no es error, el enum no es cerrado
    assert "magazine-contrato" in {h.chequeo for h in rep.avisos}


def test_magazine_review_flag_con_tipo_incorrecto_es_error(tmp_path):
    datos = _magazine_valida()
    datos["articles"][0]["cheats"] = "si"  # deberia ser boolean
    _escribir_magazine(tmp_path, datos)
    assert "magazine-contrato" in chequeos(revisar(tmp_path))


# --- contrato de data.json (ADR-0015) -------------------------------------

def _escribir_data(tmp_path, datos, set_id="x"):
    d = tmp_path / "media" / set_id
    d.mkdir(parents=True, exist_ok=True)
    (d / "data.json").write_text(json.dumps(datos), encoding="utf-8")
    return d


def test_data_json_vacio_es_valido(tmp_path):
    # Todos los campos son opcionales (ADR-0015). Un data.json que solo trae
    # mags es tan valido como uno completo.
    _escribir_data(tmp_path, {})
    rep = revisar(tmp_path)
    assert rep.ok
    assert "data-contrato" not in {h.chequeo for h in rep.hallazgos}


def test_accent_no_hex_es_error(tmp_path):
    # "verde" escrito a mano deja al juego sin color y no se nota hasta el
    # gabinete: es justo lo que el doctor existe para atrapar en el Mac.
    _escribir_data(tmp_path, {"accent": "verde"})
    assert "data-contrato" in chequeos(revisar(tmp_path))


def test_accent_hex_de_3_digitos_es_error(tmp_path):
    # CSS acepta #fb0; QML no lo interpreta igual. Se exige #rrggbb completo.
    _escribir_data(tmp_path, {"accent": "#fb0"})
    assert "data-contrato" in chequeos(revisar(tmp_path))


def test_accent_hex_valido_no_reporta(tmp_path):
    _escribir_data(tmp_path, {"accent": "#ffb020", "accent2": "#4d3608"})
    assert revisar(tmp_path).ok


def test_cheats_con_claves_abreviadas_es_error(tmp_path):
    # El prototipo usaba {n, i}; ADR-0015 fijo {name, input}. Sin este chequeo
    # un data.json copiado del mockup pasa y el overlay sale vacio.
    _escribir_data(tmp_path, {"cheats": {"combos": [{"n": "Patada", "i": "K"}]}})
    assert "data-contrato" in chequeos(revisar(tmp_path))


def test_cheats_bien_formados_no_reportan(tmp_path):
    _escribir_data(tmp_path, {
        "cheats": {
            "combos": [{"name": "Patada", "input": "↓ ↘ → + K"}],
            "codes": [{"name": "Vidas", "input": "↑ ↑ ↓ ↓ START"}],
        }
    })
    assert revisar(tmp_path).ok


def test_review_score_fuera_de_rango_es_error(tmp_path):
    _escribir_data(tmp_path, {"review": {"score": 940}})
    assert "data-contrato" in chequeos(revisar(tmp_path))


def test_review_solo_con_score_es_valido(tmp_path):
    # Resena parcial: es el caso del fixture de dino, no un fixture a medias
    # (CONVENCION #2.1 nota 3).
    _escribir_data(tmp_path, {"review": {"score": 94}})
    assert revisar(tmp_path).ok


def test_review_cats_como_lista_de_pares_es_error(tmp_path):
    # La forma del prototipo. Con lista no se puede expresar "esta categoria
    # no tiene dato" sin ambiguedad; por eso ADR-0015 la hizo objeto.
    _escribir_data(tmp_path, {"review": {"score": 94, "cats": [["GRAFICOS", 92]]}})
    assert "data-contrato" in chequeos(revisar(tmp_path))


def test_review_cats_parcial_es_valido(tmp_path):
    # Dos categorias cargadas y cuatro sin dato: soportado a proposito.
    _escribir_data(tmp_path, {"review": {"cats": {"graficos": 92, "sonido": 90}}})
    assert revisar(tmp_path).ok


def test_review_cat_desconocida_es_aviso_no_error(tmp_path):
    _escribir_data(tmp_path, {"review": {"cats": {"jugabilidad": 88}}})
    rep = revisar(tmp_path)
    assert rep.ok  # el theme la ignora, no rompe nada
    assert "data-contrato" in {h.chequeo for h in rep.avisos}


def test_review_cat_fuera_de_rango_es_error(tmp_path):
    _escribir_data(tmp_path, {"review": {"cats": {"graficos": 192}}})
    assert "data-contrato" in chequeos(revisar(tmp_path))


def test_manual_con_pagina_que_no_existe_es_error(tmp_path):
    # Una pagina declarada y ausente deja un hueco en el visor, y a esa altura
    # el theme no puede hacer nada (ADR-0014).
    _escribir_data(tmp_path, {"manual": {"pages": ["p001.jpg"]}})
    assert "data-contrato" in chequeos(revisar(tmp_path))


def test_manual_con_paginas_reales_no_reporta(tmp_path):
    d = _escribir_data(tmp_path, {"manual": {"pages": ["p001.jpg", "p002.jpg"]}})
    (d / "_manual").mkdir()
    (d / "_manual" / "p001.jpg").write_bytes(b"")
    (d / "_manual" / "p002.jpg").write_bytes(b"")
    assert revisar(tmp_path).ok


def test_mags_sin_ref_es_error(tmp_path):
    # Distinto de mags-ref-faltante (que es AVISO): aca la entrada esta mal
    # formada, no apunta a nada. Sin ref no hay degradacion posible.
    _escribir_data(tmp_path, {"mags": [{"nombre": "micromania-16"}]})
    assert "data-contrato" in chequeos(revisar(tmp_path))


# --- indices de articles[] en rango (006) ---------------------------------

def test_startpage_fuera_de_rango_es_error(tmp_path):
    # Una revista de 2 paginas con un articulo que abre en la 5. Hasta la 006
    # esto pasaba el validador y explotaba recien en el visor del theme.
    datos = _magazine_valida()
    datos["pages"] = ["p001.jpg", "p002.jpg"]
    datos["articles"][0]["startPage"] = 5
    datos["articles"][0]["pages"] = [1]
    _escribir_magazine(tmp_path, datos)
    assert "magazine-contrato" in chequeos(revisar(tmp_path))


def test_startpage_cero_es_error(tmp_path):
    # Los indices son 1-BASED: el 0 no existe. Es el error probable de quien
    # asuma que son offsets de array.
    datos = _magazine_valida()
    datos["articles"][0]["startPage"] = 0
    _escribir_magazine(tmp_path, datos)
    assert "magazine-contrato" in chequeos(revisar(tmp_path))


def test_articles_pages_fuera_de_rango_es_error(tmp_path):
    datos = _magazine_valida()
    datos["pages"] = ["p001.jpg", "p002.jpg"]
    datos["articles"][0]["startPage"] = 1
    datos["articles"][0]["pages"] = [1, 7]
    _escribir_magazine(tmp_path, datos)
    assert "magazine-contrato" in chequeos(revisar(tmp_path))


def test_indices_en_el_limite_son_validos(tmp_path):
    # 1 y el total son los dos extremos VALIDOS. Es el caso que un chequeo de
    # rango mal escrito rompe.
    datos = _magazine_valida()
    datos["pages"] = ["p001.jpg", "p002.jpg", "p003.jpg"]
    datos["articles"][0]["startPage"] = 3
    datos["articles"][0]["pages"] = [1, 3]
    _escribir_magazine(tmp_path, datos)
    assert revisar(tmp_path).ok
