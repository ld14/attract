"""Tests del doctor. Cada uno reproduce un bug que paso de verdad."""
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
