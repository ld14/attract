"""Tests de attract import. Ver spec/features/016-import-coindoor/.

Los zips se construyen en memoria (helpers), sin archivos binarios en el repo.
"""
import json
import zipfile
from pathlib import Path

import pytest

from attract.instalar import InstalarError, aplicar, leer_paquete, main


@pytest.fixture(autouse=True)
def aislar_config_pegasus(tmp_path, monkeypatch):
    # Ningun test debe registrar librerias temporales en el Pegasus del usuario.
    monkeypatch.setattr("attract.instalar._GAME_DIRS", tmp_path / "config" / "game_dirs.txt")


@pytest.mark.parametrize("cabecera", ["", "collection: \n", "# sin cabecera\n"])
def test_reimportar_repara_coleccion_sin_perder_juegos(tmp_path, cabecera):
    raiz = _libreria_minima(tmp_path)
    metadata = raiz / "arcade" / "metadata.pegasus.txt"
    metadata.write_text(cabecera + "\ngame: Otro\nfile: otro.zip\nx-set: otro\n", encoding="utf-8")
    zip_path = _zip_paquete(tmp_path, {"game.json": _game_json_minimo().encode()})
    paquete = leer_paquete(zip_path)
    aplicar(paquete, raiz)
    primera = metadata.read_bytes()
    assert primera.startswith(b"collection: Arcade\n")
    assert b"game: Otro\nfile: otro.zip" in primera
    assert primera.count(b"collection:") == 1
    aplicar(paquete, raiz)
    assert metadata.read_bytes() == primera


def test_reimportar_conserva_nombre_coleccion(tmp_path):
    raiz = _libreria_minima(tmp_path)
    metadata = raiz / "arcade" / "metadata.pegasus.txt"
    metadata.write_text("collection: Mis favoritos\nlaunch: /emulador\n", encoding="utf-8")
    paquete = leer_paquete(_zip_paquete(tmp_path, {"game.json": _game_json_minimo().encode()}))
    aplicar(paquete, raiz)
    assert metadata.read_text(encoding="utf-8").startswith("collection: Mis favoritos\nlaunch: /emulador\n")


def test_sin_registro_macos_no_escribe_config(tmp_path, monkeypatch):
    monkeypatch.setattr("attract.instalar._GAME_DIRS", None)
    paquete = leer_paquete(_zip_paquete(tmp_path, {"game.json": _game_json_minimo().encode()}))
    aplicar(paquete, tmp_path / "library", confirmar=True)
    assert not (tmp_path / "config").exists()


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

    # y el file: apunta al directorio extraido, no al zip que ya no esta:
    # Pegasus verifica que exista y si no descarta la coleccion entera
    metadata = (raiz / "arcade" / "metadata.pegasus.txt").read_text(encoding="utf-8")
    assert "file: sf2ce\n" in metadata
    assert "file: sf2ce.zip" not in metadata
    assert (raiz / "arcade" / "sf2ce").exists()


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


# ---------------------------------------------------------------------------
# 18. fallo despues de escribir -> rollback: instalacion nueva no deja nada
# ---------------------------------------------------------------------------

def _libreria_con_bloque_roto(tmp_path) -> Path:
    """Bloque de sf2ce sin linea `file:`: el merge falla en el paso 5, ya
    con assets y data.json escritos. Es el caso que dejaba media a medias."""
    raiz = _libreria_minima(tmp_path)
    meta = raiz / "arcade" / "metadata.pegasus.txt"
    meta.write_text(
        meta.read_text(encoding="utf-8")
        + "\ngame: Street Fighter II\nx-set: sf2ce\n",
        encoding="utf-8", newline="\n",
    )
    return raiz


def test_rollback_borra_lo_que_creo(tmp_path):
    raiz = _libreria_con_bloque_roto(tmp_path)
    meta = raiz / "arcade" / "metadata.pegasus.txt"
    antes_meta = meta.read_text(encoding="utf-8")

    zip_path = _zip_paquete(tmp_path, {
        "game.json": _game_json_minimo(developer="Capcom").encode(),
        "media/boxFront.png": b"\x89PNG fake",
        "data.json": b'{"trucos": []}',
    })

    paq = leer_paquete(zip_path)
    with pytest.raises(InstalarError, match="sin linea file:"):
        aplicar(paq, raiz)

    assert not (raiz / "arcade" / "media").exists()
    assert meta.read_text(encoding="utf-8") == antes_meta


# ---------------------------------------------------------------------------
# 19. DOSBox (ADR-0032): generacion de config/launch/informe al importar msdos
# ---------------------------------------------------------------------------

def _zip_msdos(tmp_path, archivos_exe: dict[str, bytes], *, dosbox_decl=None,
               nombre="paquete.zip") -> Path:
    import io
    rom_zip_io = io.BytesIO()
    with zipfile.ZipFile(rom_zip_io, "w") as zf:
        for n, contenido in archivos_exe.items():
            zf.writestr(n, contenido)

    game = _game_json_minimo(system="msdos", set="dosgame", tratamiento="descomprimir",
                              file="dosgame.zip")
    if dosbox_decl is not None:
        datos = json.loads(game)
        datos["dosbox"] = dosbox_decl
        game = json.dumps(datos, ensure_ascii=False)

    return _zip_paquete(tmp_path, {
        "game.json": game.encode(),
        "media/dosgame.zip": rom_zip_io.getvalue(),
    }, nombre=nombre)


def test_msdos_genera_conf_launch_e_informe(tmp_path):
    raiz = _libreria_minima(tmp_path, sistema="msdos")
    zip_path = _zip_msdos(tmp_path, {"GAME1.EXE": b"exe falso"})

    paq = leer_paquete(zip_path)
    aplicar(paq, raiz)

    juego_dir = raiz / "msdos" / "dosgame"
    assert (juego_dir / "dosbox.conf").exists()
    assert "GAME1.EXE" in (juego_dir / "dosbox.conf").read_text(encoding="utf-8")

    informe = json.loads((raiz / "msdos" / "media" / "dosgame" / "_dosbox.json").read_text())
    assert informe["status"] == "provisional"
    assert informe["executable"] == "GAME1.EXE"

    metadata = (raiz / "msdos" / "metadata.pegasus.txt").read_text(encoding="utf-8")
    assert "launch: " in metadata
    assert "emulators/dosbox-staging" in metadata


def test_msdos_declaracion_invalida_falla_en_preflight(tmp_path):
    """dosbox con system distinto de msdos falla ANTES de tocar la libreria."""
    zip_path = _zip_paquete(tmp_path, {
        "game.json": _game_json_minimo(dosbox={"executable": "A.EXE"}).encode(),
    })
    with pytest.raises(InstalarError, match="game.json:"):
        leer_paquete(zip_path)


def test_msdos_ejecutable_declarado_ausente_no_deja_instalacion_parcial(tmp_path):
    raiz = _libreria_minima(tmp_path, sistema="msdos")
    zip_path = _zip_msdos(tmp_path, {"GAME1.EXE": b"exe"},
                           dosbox_decl={"executable": "NOESTA.EXE"})

    paq = leer_paquete(zip_path)
    with pytest.raises(InstalarError, match="ejecutable DOS declarado ausente"):
        aplicar(paq, raiz)

    # rollback completo: ni siquiera el directorio media/dosgame queda
    assert not (raiz / "msdos" / "media" / "dosgame").exists()
    assert not (raiz / "msdos" / "dosgame").exists()
    metadata = (raiz / "msdos" / "metadata.pegasus.txt").read_text(encoding="utf-8")
    assert "game:" not in metadata


def test_msdos_reimportar_conserva_dosbox_conf_local(tmp_path):
    raiz = _libreria_minima(tmp_path, sistema="msdos")
    zip_path = _zip_msdos(tmp_path, {"GAME1.EXE": b"exe falso"})

    paq1 = leer_paquete(zip_path)
    aplicar(paq1, raiz)

    conf_path = raiz / "msdos" / "dosgame" / "dosbox.conf"
    texto_editado = conf_path.read_text(encoding="utf-8") + "; ajustado a mano\n"
    conf_path.write_text(texto_editado, encoding="utf-8")

    paq2 = leer_paquete(zip_path)
    aplicar(paq2, raiz)

    assert conf_path.read_text(encoding="utf-8") == texto_editado

    informe = json.loads((raiz / "msdos" / "media" / "dosgame" / "_dosbox.json").read_text())
    assert informe["status"] == "conservado"

    metadata = (raiz / "msdos" / "metadata.pegasus.txt").read_text(encoding="utf-8")
    bloque_juego = metadata.split("game:", 1)[1]
    assert bloque_juego.count("launch:") == 1


def test_msdos_multiples_candidatos_queda_pendiente_pero_instala(tmp_path):
    raiz = _libreria_minima(tmp_path, sistema="msdos")
    zip_path = _zip_msdos(tmp_path, {"GAME1.EXE": b"a", "GAME2.EXE": b"b"})

    paq = leer_paquete(zip_path)
    set_id = aplicar(paq, raiz)  # no explota: import nunca bloquea por esto

    assert set_id == "dosgame"
    informe = json.loads((raiz / "msdos" / "media" / "dosgame" / "_dosbox.json").read_text())
    assert informe["status"] == "pendiente"
    assert sorted(informe["candidates"]) == ["GAME1.EXE", "GAME2.EXE"]

    conf = (raiz / "msdos" / "dosgame" / "dosbox.conf").read_text(encoding="utf-8")
    assert "arranque pendiente" in conf


def test_rollback_restaura_lo_que_piso(tmp_path):
    """Reinstalar encima de un juego ya cargado: si falla, vuelve el viejo."""
    raiz = _libreria_con_bloque_roto(tmp_path)
    media = raiz / "arcade" / "media" / "sf2ce"
    media.mkdir(parents=True)
    (media / "boxFront.png").write_bytes(b"VIEJO")
    (media / "data.json").write_text('{"mags": ["m1"]}', encoding="utf-8")

    zip_path = _zip_paquete(tmp_path, {
        "game.json": _game_json_minimo().encode(),
        "media/boxFront.png": b"NUEVO",
        "media/logo.png": b"\x89PNG fake",
        "data.json": b'{"trucos": []}',
    })

    paq = leer_paquete(zip_path)
    with pytest.raises(InstalarError, match="sin linea file:"):
        aplicar(paq, raiz)

    assert (media / "boxFront.png").read_bytes() == b"VIEJO"
    assert (media / "data.json").read_text(encoding="utf-8") == '{"mags": ["m1"]}'
    assert not (media / "logo.png").exists()
