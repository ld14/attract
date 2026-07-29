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
