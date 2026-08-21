"""Tests de attract import. Ver spec/features/016-import-coindoor/.

Los zips se construyen en memoria (helpers), sin archivos binarios en el repo.
"""
import json
import zipfile
from pathlib import Path

import pytest

from attract.instalar import InstalarError, aplicar, leer_paquete, main


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _zip_paquete(tmp_path: Path, archivos: dict[str, bytes], nombre="paquete.zip") -> Path:
    zip_path = tmp_path / nombre
    with zipfile.ZipFile(zip_path, "w") as zf:
        for nombre_interno, contenido in archivos.items():
            zf.writestr(nombre_interno, contenido)
    return zip_path


def _libreria_minima(tmp_path: Path, sistema="arcade") -> Path:
    raiz = tmp_path / "libreria"
    sistema_dir = raiz / sistema
    sistema_dir.mkdir(parents=True)
    (sistema_dir / "metadata.pegasus.txt").write_text(
        f"collection: {sistema.title()}\nshortname: {sistema}\nlaunch: /usr/bin/mame\n",
        encoding="utf-8", newline="\n",
    )
    return raiz


def _game_json_minimo(**overrides) -> str:
    base = {
        "schema_version": "1",
        "system": "arcade",
        "set": "sf2ce",
        "title": "Street Fighter II",
    }
    base.update(overrides)
    return json.dumps(base, ensure_ascii=False)


def _game_json_completo() -> str:
    return json.dumps({
        "schema_version": "1",
        "system": "arcade",
        "set": "sf2ce",
        "title": "Street Fighter II",
        "developer": "Capcom",
        "publisher": "Capcom",
        "genre": "Fighting",
        "players": 2,
        "release": "1992",
        "format": "PCB",
        "summary": "Juego de peleas clasico.",
    }, ensure_ascii=False)


def _data_json_minimo() -> str:
    return json.dumps({"accent": "#ff0000"}, ensure_ascii=False)


# ---------------------------------------------------------------------------
# 1. Caso feliz: set nuevo, paquete completo
# ---------------------------------------------------------------------------

def test_caso_feliz_set_nuevo(tmp_path):
    raiz = _libreria_minima(tmp_path)
    zip_path = _zip_paquete(tmp_path, {
        "game.json": _game_json_completo().encode(),
        "data.json": _data_json_minimo().encode(),
        "media/boxFront.png": b"\x89PNG fake",
    })

    set_id = leer_paquete(zip_path)
    resultado = aplicar(set_id, raiz)

    assert resultado == "sf2ce"

    metadata = (raiz / "arcade" / "metadata.pegasus.txt").read_text(encoding="utf-8")
    assert "game: Street Fighter II" in metadata
    assert "x-set: sf2ce" in metadata
    assert "x-procedencia: declarada" in metadata
    assert "developer: Capcom" in metadata
    assert "assets.boxFront: media/sf2ce/boxFront.png" in metadata
    assert "summary:" in metadata

    data = json.loads((raiz / "arcade" / "media" / "sf2ce" / "data.json").read_text())
    assert data["accent"] == "#ff0000"


# ---------------------------------------------------------------------------
# 2. Caso feliz: set ya existente (merge)
# ---------------------------------------------------------------------------

def test_caso_feliz_set_ya_existente(tmp_path):
    raiz = _libreria_minima(tmp_path)
    metadata = raiz / "arcade" / "metadata.pegasus.txt"
    metadata.write_text(
        "collection: Arcade\nshortname: arcade\nlaunch: /usr/bin/mame\n"
        "\n"
        "game: Street Fighter II\n"
        "file: sf2ce.zip\n"
        "developer: Capcom (viejo)\n"
        "x-set: sf2ce\n",
        encoding="utf-8", newline="\n",
    )

    zip_path = _zip_paquete(tmp_path, {
        "game.json": _game_json_completo().encode(),
    })

    paq = leer_paquete(zip_path)
    aplicar(paq, raiz)

    texto = metadata.read_text(encoding="utf-8")
    assert "developer: Capcom" in texto
    assert "file: sf2ce.zip" in texto
    assert "x-set: sf2ce" in texto
    assert "developer: Capcom (viejo)" not in texto


# ---------------------------------------------------------------------------
# 3. Paquete minimo: solo game.json con los 4 obligatorios
# ---------------------------------------------------------------------------

def test_paquete_minimo_solo_obligatorios(tmp_path):
    raiz = _libreria_minima(tmp_path)
    zip_path = _zip_paquete(tmp_path, {
        "game.json": _game_json_minimo().encode(),
    })

    paq = leer_paquete(zip_path)
    set_id = aplicar(paq, raiz)

    assert set_id == "sf2ce"
    metadata = (raiz / "arcade" / "metadata.pegasus.txt").read_text(encoding="utf-8")
    assert "game: Street Fighter II" in metadata
    assert "x-procedencia: declarada" in metadata
    assert not any(l.startswith("developer:") for l in metadata.splitlines()
                   if "game:" not in l)


# ---------------------------------------------------------------------------
# 4. Zip con miembro "../fuera.txt" -> InstalarError, nada escrito
# ---------------------------------------------------------------------------

def test_zip_path_traversal_falla(tmp_path):
    raiz = _libreria_minima(tmp_path)
    antes = sorted(raiz.rglob("*"))

    zip_path = _zip_paquete(tmp_path, {
        "game.json": _game_json_minimo().encode(),
        "../fuera.txt": b"peligro",
    })

    with pytest.raises(InstalarError, match="miembro de zip no permitido"):
        leer_paquete(zip_path)

    despues = sorted(raiz.rglob("*"))
    assert antes == despues


# ---------------------------------------------------------------------------
# 5. game.json sin set -> InstalarError
# ---------------------------------------------------------------------------

def test_game_json_sin_set_falla(tmp_path):
    zip_path = _zip_paquete(tmp_path, {
        "game.json": _game_json_minimo(set="").encode(),
    })

    with pytest.raises(InstalarError, match="faltan campos obligatorios"):
        leer_paquete(zip_path)


# ---------------------------------------------------------------------------
# 6. data.json con manual como objeto suelto -> InstalarError
# ---------------------------------------------------------------------------

def test_data_json_manual_objeto_suelto_falla(tmp_path):
    data_mal = json.dumps({"manual": {"file": "manual.pdf"}}).encode()
    zip_path = _zip_paquete(tmp_path, {
        "game.json": _game_json_minimo().encode(),
        "data.json": data_mal,
    })

    with pytest.raises(InstalarError, match="tiene que ser una lista de documentos"):
        leer_paquete(zip_path)


# ---------------------------------------------------------------------------
# 7. Reimportar el mismo zip dos veces -> resultado identico
# ---------------------------------------------------------------------------

def test_reimportacion_idempotente(tmp_path):
    raiz = _libreria_minima(tmp_path)
    zip_path = _zip_paquete(tmp_path, {
        "game.json": _game_json_completo().encode(),
        "data.json": _data_json_minimo().encode(),
        "media/boxFront.png": b"\x89PNG fake",
    })

    paq1 = leer_paquete(zip_path)
    aplicar(paq1, raiz)
    metadata_1 = (raiz / "arcade" / "metadata.pegasus.txt").read_bytes()
    data_1 = (raiz / "arcade" / "media" / "sf2ce" / "data.json").read_bytes()

    paq2 = leer_paquete(zip_path)
    aplicar(paq2, raiz)
    metadata_2 = (raiz / "arcade" / "metadata.pegasus.txt").read_bytes()
    data_2 = (raiz / "arcade" / "media" / "sf2ce" / "data.json").read_bytes()

    assert metadata_1 == metadata_2
    assert data_1 == data_2


# ---------------------------------------------------------------------------
# 8. mags[] preexistente sobrevive a reimport sin mags en el paquete
# ---------------------------------------------------------------------------

def test_mags_preexistente_sobrevive(tmp_path):
    raiz = _libreria_minima(tmp_path)

    # instalar primero con data.json sin mags
    zip1 = _zip_paquete(tmp_path, {
        "game.json": _game_json_minimo().encode(),
        "data.json": json.dumps({"accent": "#000000"}).encode(),
    }, nombre="primero.zip")
    paq1 = leer_paquete(zip1)
    aplicar(paq1, raiz)

    # meter mags a mano (simula attract mags --apply)
    data_path = raiz / "arcade" / "media" / "sf2ce" / "data.json"
    d = json.loads(data_path.read_text())
    d["mags"] = [{"ref": "micromania-16"}]
    data_path.write_text(json.dumps(d, ensure_ascii=False, indent=2), encoding="utf-8")

    # reimportar sin mags en el paquete
    zip2 = _zip_paquete(tmp_path, {
        "game.json": _game_json_minimo().encode(),
        "data.json": json.dumps({"accent": "#111111"}).encode(),
    }, nombre="segundo.zip")
    paq2 = leer_paquete(zip2)
    aplicar(paq2, raiz)

    data_final = json.loads(data_path.read_text())
    assert data_final["mags"] == [{"ref": "micromania-16"}]
    assert data_final["accent"] == "#111111"


# ---------------------------------------------------------------------------
# 9. system sin metadata.pegasus.txt -> InstalarError, nada creado
# ---------------------------------------------------------------------------

def test_sistema_sin_metadata_falla(tmp_path):
    raiz = tmp_path / "libreria"
    (raiz / "arcade").mkdir(parents=True)

    zip_path = _zip_paquete(tmp_path, {
        "game.json": _game_json_minimo().encode(),
    })

    paq = leer_paquete(zip_path)

    antes = sorted(raiz.rglob("*"))
    with pytest.raises(InstalarError, match="coleccion no creada"):
        aplicar(paq, raiz, confirmar=False)
    despues = sorted(raiz.rglob("*"))
    assert antes == despues


# ---------------------------------------------------------------------------
# 10. asset boxFront.png genera assets.boxFront: en el bloque
# ---------------------------------------------------------------------------

def test_asset_genera_linea_assets(tmp_path):
    raiz = _libreria_minima(tmp_path)
    zip_path = _zip_paquete(tmp_path, {
        "game.json": _game_json_minimo().encode(),
        "media/boxFront.png": b"\x89PNG fake",
    })

    paq = leer_paquete(zip_path)
    aplicar(paq, raiz)

    metadata = (raiz / "arcade" / "metadata.pegasus.txt").read_text(encoding="utf-8")
    assert "assets.boxFront: media/sf2ce/boxFront.png" in metadata


# ---------------------------------------------------------------------------
# 11. Caso fallo: game.json sin system -> InstalarError
# ---------------------------------------------------------------------------

def test_game_json_sin_system_falla(tmp_path):
    zip_path = _zip_paquete(tmp_path, {
        "game.json": _game_json_minimo(system="").encode(),
    })

    with pytest.raises(InstalarError, match="faltan campos obligatorios"):
        leer_paquete(zip_path)


# ---------------------------------------------------------------------------
# 12. Cli: main() imprime ayuda
# ---------------------------------------------------------------------------

def test_main_ayuda(capsys):
    ret = main(["--help"])
    assert ret == 0
    out = capsys.readouterr().out
    assert "attract import" in out


# ---------------------------------------------------------------------------
# 13. tratamiento: copiar -> copia el zip a la raiz del sistema
# ---------------------------------------------------------------------------

def test_tratamiento_copiar(tmp_path):
    raiz = _libreria_minima(tmp_path)
    rom_data = b"PK fake rom content"
    zip_path = _zip_paquete(tmp_path, {
        "game.json": _game_json_minimo(file="sf2ce.zip", tratamiento="copiar").encode(),
        "media/sf2ce.zip": rom_data,
        "media/boxFront.png": b"\x89PNG fake",
    })

    paq = leer_paquete(zip_path)
    aplicar(paq, raiz)

    rom_destino = raiz / "arcade" / "sf2ce.zip"
    assert rom_destino.exists()
    assert rom_destino.read_bytes() == rom_data

    # el ROM NO se copia como asset
    metadata = (raiz / "arcade" / "metadata.pegasus.txt").read_text(encoding="utf-8")
    assert "assets.sf2ce:" not in metadata
    assert "assets.boxFront: media/sf2ce/boxFront.png" in metadata


# ---------------------------------------------------------------------------
# 14. tratamiento: descomprimir -> extrae el zip a <set>/
# ---------------------------------------------------------------------------

def test_tratamiento_descomprimir(tmp_path):
    raiz = _libreria_minima(tmp_path)
    # crear un zip interno con un archivo
    import io
    rom_zip_io = io.BytesIO()
    with zipfile.ZipFile(rom_zip_io, "w") as zf:
        zf.writestr("game1.rom", b"\x00ROM content")
        zf.writestr("game2.rom", b"\x01ROM content")
    rom_data = rom_zip_io.getvalue()

    zip_path = _zip_paquete(tmp_path, {
        "game.json": _game_json_minimo(file="sf2ce.zip", tratamiento="descomprimir").encode(),
        "media/sf2ce.zip": rom_data,
    })

    paq = leer_paquete(zip_path)
    aplicar(paq, raiz)

    extracted = raiz / "arcade" / "sf2ce"
    assert extracted.is_dir()
    assert (extracted / "game1.rom").read_bytes() == b"\x00ROM content"
    assert (extracted / "game2.rom").read_bytes() == b"\x01ROM content"

    # el ROM NO se copia como asset
    assert not (raiz / "arcade" / "sf2ce.zip").exists()


# ---------------------------------------------------------------------------
# 15. tratamiento con archivo ROM ausente -> InstalarError
# ---------------------------------------------------------------------------

def test_tratamiento_sin_archivo_rom_falla(tmp_path):
    raiz = _libreria_minima(tmp_path)
    zip_path = _zip_paquete(tmp_path, {
        "game.json": _game_json_minimo(file="sf2ce.zip", tratamiento="copiar").encode(),
        # no se incluye sf2ce.zip
    })

    paq = leer_paquete(zip_path)
    with pytest.raises(InstalarError, match="no se encontro"):
        aplicar(paq, raiz)


# ---------------------------------------------------------------------------
# 16. tratamiento con valor invalido -> InstalarError
# ---------------------------------------------------------------------------

def test_tratamiento_valor_invalido_falla(tmp_path):
    zip_path = _zip_paquete(tmp_path, {
        "game.json": _game_json_minimo(tratamiento="borrar").encode(),
    })

    with pytest.raises(InstalarError, match="tratamiento 'borrar' no valido"):
        leer_paquete(zip_path)


# ---------------------------------------------------------------------------
# 17. sin tratamiento -> backward compatible, ROM se copia como asset
# ---------------------------------------------------------------------------

def test_sin_tratamiento_backward_compatible(tmp_path):
    raiz = _libreria_minima(tmp_path)
    zip_path = _zip_paquete(tmp_path, {
        "game.json": _game_json_minimo(file="sf2ce.zip").encode(),
        "media/sf2ce.zip": b"\x50\x4B fake",
        "media/boxFront.png": b"\x89PNG fake",
    })

    paq = leer_paquete(zip_path)
    aplicar(paq, raiz)

    # sin tratamiento, el ROM se copia como asset normal
    assert (raiz / "arcade" / "media" / "sf2ce" / "sf2ce.zip").exists()
    metadata = (raiz / "arcade" / "metadata.pegasus.txt").read_text(encoding="utf-8")
    assert "assets.sf2ce: media/sf2ce/sf2ce.zip" in metadata
