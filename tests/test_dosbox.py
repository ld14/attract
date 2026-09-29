"""Tests del resolvedor DOSBox (ADR-0032). Ver spec/features/025-dosbox-import/.

Cada test construye su propio arbol de archivos sinteticos en tmp_path -
sin ROMs ni ejecutables reales, sin depender de la libreria del autor.
"""
from pathlib import Path

import pytest

from attract import dosbox
from attract.dosbox import DosboxError, comando_launch, preparar, sha256, validar_declaracion


def _game(**overrides) -> dict:
    base = {"schema_version": "1", "system": "msdos", "set": "juego", "title": "Juego"}
    base.update(overrides)
    return base


# ---------------------------------------------------------------------------
# validar_declaracion
# ---------------------------------------------------------------------------

def test_sin_dosbox_no_valida_nada():
    validar_declaracion({"system": "arcade"})  # no explota


def test_dosbox_en_sistema_distinto_falla():
    game = _game(system="arcade", tratamiento="descomprimir", dosbox={"executable": "A.EXE"})
    with pytest.raises(DosboxError, match="requiere system msdos"):
        validar_declaracion(game)


def test_dosbox_sin_tratamiento_descomprimir_falla():
    game = _game(tratamiento="copiar", dosbox={"executable": "A.EXE"})
    with pytest.raises(DosboxError, match="requiere system msdos"):
        validar_declaracion(game)


def test_dosbox_sin_executable_falla():
    game = _game(tratamiento="descomprimir", dosbox={})
    with pytest.raises(DosboxError, match="objeto con executable"):
        validar_declaracion(game)


def test_dosbox_opcion_desconocida_falla():
    game = _game(tratamiento="descomprimir",
                  dosbox={"executable": "A.EXE", "musica": "si"})
    with pytest.raises(DosboxError, match="opciones dosbox desconocidas"):
        validar_declaracion(game)


@pytest.mark.parametrize("ruta", ["../fuera/A.EXE", "/abs/A.EXE", "sub\\A.EXE", "C:/A.EXE"])
def test_dosbox_executable_ruta_insegura_falla(ruta):
    game = _game(tratamiento="descomprimir", dosbox={"executable": ruta})
    with pytest.raises(DosboxError):
        validar_declaracion(game)


def test_dosbox_executable_no_8_3_falla():
    game = _game(tratamiento="descomprimir", dosbox={"executable": "UNNOMBREDEMASIADOLARGO.EXE"})
    with pytest.raises(DosboxError, match="nombre DOS 8.3"):
        validar_declaracion(game)


def test_dosbox_executable_extension_no_dos_falla():
    game = _game(tratamiento="descomprimir", dosbox={"executable": "DATA.DAT"})
    with pytest.raises(DosboxError, match="nombre DOS 8.3"):
        validar_declaracion(game)


@pytest.mark.parametrize("cycles", [99, 200001, "3000", True])
def test_dosbox_cpu_cycles_invalido_falla(cycles):
    game = _game(tratamiento="descomprimir",
                  dosbox={"executable": "A.EXE", "cpu_cycles": cycles})
    with pytest.raises(DosboxError, match="cpu_cycles"):
        validar_declaracion(game)


def test_dosbox_sbtype_invalido_falla():
    game = _game(tratamiento="descomprimir",
                  dosbox={"executable": "A.EXE", "sbtype": "soundblaster9000"})
    with pytest.raises(DosboxError, match="sbtype no soportado"):
        validar_declaracion(game)


def test_dosbox_sound_env_no_booleano_falla():
    game = _game(tratamiento="descomprimir",
                  dosbox={"executable": "A.EXE", "sound_env": "si"})
    with pytest.raises(DosboxError, match="sound_env debe ser booleano"):
        validar_declaracion(game)


def test_dosbox_declaracion_completa_valida():
    game = _game(tratamiento="descomprimir", dosbox={
        "executable": "A.EXE", "cpu_cycles": 5000, "sbtype": "sb16", "sound_env": True,
    })
    validar_declaracion(game)  # no explota


# ---------------------------------------------------------------------------
# preparar() - sin dosbox.conf previo
# ---------------------------------------------------------------------------

def test_preparar_sin_candidatos_deja_pendiente(tmp_path):
    (tmp_path / "LEEME.TXT").write_bytes(b"nada ejecutable aca")
    prep = preparar(tmp_path, _game())
    assert prep.informe["status"] == "pendiente"
    assert prep.informe["candidates"] == []
    assert "arranque pendiente" in prep.config
    assert "executable" not in prep.informe


def test_preparar_un_candidato_unico_es_provisional(tmp_path):
    (tmp_path / "GAME1.EXE").write_bytes(b"exe falso")
    prep = preparar(tmp_path, _game())
    assert prep.informe["status"] == "provisional"
    assert prep.informe["executable"] == "GAME1.EXE"
    assert prep.informe["executable_sha256"] == sha256(tmp_path / "GAME1.EXE")
    assert "mount c" in prep.config
    assert "GAME1.EXE" in prep.config
    assert prep.launch == comando_launch()


def test_preparar_varios_candidatos_queda_ambiguo(tmp_path):
    (tmp_path / "GAME1.EXE").write_bytes(b"a")
    (tmp_path / "GAME2.EXE").write_bytes(b"b")
    prep = preparar(tmp_path, _game())
    assert prep.informe["status"] == "pendiente"
    assert sorted(prep.informe["candidates"]) == ["GAME1.EXE", "GAME2.EXE"]
    assert "arranque pendiente" in prep.config


def test_preparar_ignora_instaladores_como_candidatos(tmp_path):
    (tmp_path / "SETUP.EXE").write_bytes(b"instalador")
    (tmp_path / "INSTALL.BAT").write_bytes(b"instalador")
    (tmp_path / "README.EXE").write_bytes(b"no es el juego")
    prep = preparar(tmp_path, _game())
    assert prep.informe["status"] == "pendiente"
    assert prep.informe["candidates"] == []


def test_preparar_ignora_utilidades_dos_conocidas(tmp_path):
    """PKARC.COM (compresor de DOS de los 80) queda en muchisimos juegos
    viejos sin ser el juego - caso real: Out Run, 2026-09-17."""
    (tmp_path / "OUTRUN.EXE").write_bytes(b"el juego real")
    (tmp_path / "PKARC.COM").write_bytes(b"compresor generico de DOS")
    prep = preparar(tmp_path, _game())
    assert prep.informe["status"] == "provisional"
    assert prep.informe["executable"] == "OUTRUN.EXE"


def test_preparar_bat_ambiguo_no_se_autoelige(tmp_path):
    """Un unico .BAT no se elige solo: podria ejecutar cualquier cosa."""
    (tmp_path / "GAME1.BAT").write_bytes(b"call algo.exe")
    prep = preparar(tmp_path, _game())
    assert prep.informe["status"] == "pendiente"
    assert prep.informe["candidates"] == ["GAME1.BAT"]


def test_preparar_declarado_usa_ese_ejecutable(tmp_path):
    (tmp_path / "GAME1.EXE").write_bytes(b"el correcto")
    (tmp_path / "OTRO.EXE").write_bytes(b"no elegido")
    game = _game(tratamiento="descomprimir",
                  dosbox={"executable": "GAME1.EXE", "cpu_cycles": 8000})
    prep = preparar(tmp_path, game)
    assert prep.informe["status"] == "declarado"
    assert prep.informe["executable"] == "GAME1.EXE"
    assert prep.informe["settings"]["cpu_cycles"] == 8000


def test_preparar_declarado_ausente_falla(tmp_path):
    game = _game(tratamiento="descomprimir", dosbox={"executable": "NOESTA.EXE"})
    with pytest.raises(DosboxError, match="ejecutable DOS declarado ausente"):
        preparar(tmp_path, game)


def test_preparar_sound_env_sin_drv_falla(tmp_path):
    (tmp_path / "GAME1.EXE").write_bytes(b"exe")
    game = _game(tratamiento="descomprimir",
                  dosbox={"executable": "GAME1.EXE", "sound_env": True})
    with pytest.raises(DosboxError, match="CT-VOICE.DRV"):
        preparar(tmp_path, game)


def test_preparar_sound_env_con_drv_ok(tmp_path):
    (tmp_path / "GAME1.EXE").write_bytes(b"exe")
    (tmp_path / "CT-VOICE.DRV").write_bytes(b"driver")
    game = _game(tratamiento="descomprimir",
                  dosbox={"executable": "GAME1.EXE", "sound_env": True})
    prep = preparar(tmp_path, game)
    assert "SOUND=C:\\" in prep.config


# ---------------------------------------------------------------------------
# preparar() - perfil conocido (PERFILES), via monkeypatch
# ---------------------------------------------------------------------------

def _perfil_de_prueba(tmp_path: Path) -> dict:
    (tmp_path / "GAME1.EXE").write_bytes(b"contenido del ejecutable")
    (tmp_path / "DATA.CFG").write_bytes(b"contenido del dato")
    return {
        "id": "juego-de-prueba-v1",
        "executable": "GAME1.EXE",
        "files": {
            "GAME1.EXE": sha256(tmp_path / "GAME1.EXE"),
            "DATA.CFG": sha256(tmp_path / "DATA.CFG"),
        },
        "settings": {"cpu_cycles": 9000, "sbtype": "sb16", "sound_env": False},
        "emulator_version": "0.83.0",
        "evidence": {"date": "2026-09-16", "scope": "solo esta copia"},
        "sources": ["https://vogons.org/ejemplo"],
    }


def test_preparar_perfil_conocido_matchea_por_hash(tmp_path, monkeypatch):
    perfil = _perfil_de_prueba(tmp_path)
    monkeypatch.setattr(dosbox, "PERFILES", (perfil,))

    prep = preparar(tmp_path, _game())

    assert prep.informe["status"] == "perfil-conocido"
    assert prep.informe["profile"] == "juego-de-prueba-v1"
    assert prep.informe["settings"]["cpu_cycles"] == 9000
    assert prep.informe["sources"] == ["https://vogons.org/ejemplo"]
    # perfil conocido no lleva el aviso de "sin prueba de jugabilidad"
    assert not any("sin prueba de jugabilidad" in w for w in prep.informe["warnings"])


def test_preparar_perfil_conocido_no_matchea_si_cambia_un_archivo(tmp_path, monkeypatch):
    """Mismo nombre de ejecutable, contenido distinto: no es la misma copia."""
    perfil = _perfil_de_prueba(tmp_path)
    monkeypatch.setattr(dosbox, "PERFILES", (perfil,))
    (tmp_path / "DATA.CFG").write_bytes(b"contenido DISTINTO")

    prep = preparar(tmp_path, _game())

    assert prep.informe["status"] == "provisional"
    assert prep.informe["profile"] is None


def test_preparar_perfil_conocido_no_matchea_si_falta_acompanante(tmp_path, monkeypatch):
    perfil = _perfil_de_prueba(tmp_path)
    monkeypatch.setattr(dosbox, "PERFILES", (perfil,))
    (tmp_path / "DATA.CFG").unlink()

    prep = preparar(tmp_path, _game())

    assert prep.informe["status"] == "provisional"


# ---------------------------------------------------------------------------
# preparar() - dosbox.conf ya existente (reimportacion)
# ---------------------------------------------------------------------------

def test_preparar_conf_existente_sin_conservar_es_aportado(tmp_path):
    (tmp_path / "dosbox.conf").write_text("; del paquete\n", encoding="utf-8")
    prep = preparar(tmp_path, _game())
    assert prep.informe["status"] == "aportado"
    assert prep.config is None
    assert prep.launch == comando_launch()


def test_preparar_conf_existente_con_conservar_no_toca_launch(tmp_path):
    (tmp_path / "dosbox.conf").write_text("; local del usuario\n", encoding="utf-8")
    prep = preparar(tmp_path, _game(), conservar=True)
    assert prep.informe["status"] == "conservado"
    assert prep.config is None
    assert prep.launch is None


# ---------------------------------------------------------------------------
# imagenes de disco declaradas (ADR-0034)
# ---------------------------------------------------------------------------

def test_dosbox_imagenes_sin_tipo_imagen_falla():
    game = _game(tratamiento="descomprimir", dosbox={
        "executable": "GAME.EXE", "imagenes": ["disk1.img"],
    })
    with pytest.raises(DosboxError, match="tipo_imagen"):
        validar_declaracion(game)


def test_dosbox_imagenes_tipo_invalido_falla():
    game = _game(tratamiento="descomprimir", dosbox={
        "executable": "GAME.EXE", "imagenes": ["disk1.img"], "tipo_imagen": "casete",
    })
    with pytest.raises(DosboxError, match="tipo_imagen"):
        validar_declaracion(game)


def test_dosbox_imagenes_vacia_falla():
    game = _game(tratamiento="descomprimir", dosbox={
        "executable": "GAME.EXE", "imagenes": [], "tipo_imagen": "floppy",
    })
    with pytest.raises(DosboxError, match="lista de rutas no vacia"):
        validar_declaracion(game)


def test_dosbox_imagenes_extension_no_reconocida_falla():
    game = _game(tratamiento="descomprimir", dosbox={
        "executable": "GAME.EXE", "imagenes": ["disk1.zip"], "tipo_imagen": "floppy",
    })
    with pytest.raises(DosboxError, match="extension no reconocida"):
        validar_declaracion(game)


def test_dosbox_imagenes_ruta_insegura_falla():
    game = _game(tratamiento="descomprimir", dosbox={
        "executable": "GAME.EXE", "imagenes": ["../fuera.img"], "tipo_imagen": "floppy",
    })
    with pytest.raises(DosboxError):
        validar_declaracion(game)


def test_dosbox_imagenes_declaracion_completa_valida():
    game = _game(tratamiento="descomprimir", dosbox={
        "executable": "GAME.EXE", "imagenes": ["disk1.img", "disk2.img"], "tipo_imagen": "floppy",
    })
    validar_declaracion(game)  # no explota


def test_preparar_imagenes_floppy_genera_imgmount(tmp_path):
    (tmp_path / "disk1.img").write_bytes(b"\x00" * 100)
    (tmp_path / "disk2.img").write_bytes(b"\x00" * 100)
    game = _game(tratamiento="descomprimir", dosbox={
        "executable": "MONKEY.EXE", "imagenes": ["disk1.img", "disk2.img"], "tipo_imagen": "floppy",
    })

    prep = preparar(tmp_path, game)

    assert prep.informe["status"] == "declarado"
    assert prep.informe["images"] == ["disk1.img", "disk2.img"]
    assert prep.informe["image_type"] == "floppy"
    assert prep.informe["verification"] == "no verificable: ejecutable dentro de una imagen sin montar"
    assert 'imgmount a "disk1.img" "disk2.img" -t floppy' in prep.config
    assert "a:" in prep.config.splitlines()
    assert "MONKEY.EXE" in prep.config


def test_preparar_imagenes_cdrom_genera_imgmount(tmp_path):
    (tmp_path / "game.iso").write_bytes(b"\x00" * 100)
    game = _game(tratamiento="descomprimir", dosbox={
        "executable": "START.EXE", "imagenes": ["game.iso"], "tipo_imagen": "cdrom",
    })

    prep = preparar(tmp_path, game)

    assert 'imgmount d "game.iso" -t iso' in prep.config
    assert "d:" in prep.config.splitlines()


def test_preparar_imagen_declarada_ausente_falla(tmp_path):
    game = _game(tratamiento="descomprimir", dosbox={
        "executable": "MONKEY.EXE", "imagenes": ["noesta.img"], "tipo_imagen": "floppy",
    })
    with pytest.raises(DosboxError, match="imagen declarada ausente"):
        preparar(tmp_path, game)


def test_preparar_no_confunde_bin_de_datos_con_imagen(tmp_path):
    """Memlist.bin (Out of This World) es un archivo de datos del juego, no
    una imagen de CD - .bin no esta en IMAGEN_EXT (solo .cue lo delata)."""
    (tmp_path / "World.exe").write_bytes(b"exe")
    (tmp_path / "Memlist.bin").write_bytes(b"datos del juego, no una imagen")

    prep = preparar(tmp_path, _game())

    assert prep.informe["status"] == "provisional"
    assert not any("imagenes de disco" in w for w in prep.informe["warnings"])


def test_preparar_imagenes_sueltas_sin_declarar_avisa(tmp_path):
    (tmp_path / "disk1.img").write_bytes(b"\x00" * 100)
    (tmp_path / "disk2.img").write_bytes(b"\x00" * 100)

    prep = preparar(tmp_path, _game())

    assert prep.informe["status"] == "pendiente"
    assert any("imagenes de disco" in w for w in prep.informe["warnings"])


# ---------------------------------------------------------------------------
# preparar() - motor detectado por firma de archivos (ADR-0033)
# ---------------------------------------------------------------------------

def test_preparar_detecta_motor_agi(tmp_path):
    (tmp_path / "KQ4.EXE").write_bytes(b"interprete")
    (tmp_path / "WORDS.TOK").write_bytes(b"vocabulario")
    (tmp_path / "OBJECT").write_bytes(b"objetos")
    (tmp_path / "VOL.0").write_bytes(b"recursos")

    prep = preparar(tmp_path, _game())

    assert prep.informe["status"] == "motor-detectado"
    assert prep.informe["profile"] == "sierra-agi"
    assert prep.informe["settings"]["cpu_cycles"] == 6000
    assert prep.informe["executable"] == "KQ4.EXE"
    assert any("motor detectado" in w for w in prep.informe["warnings"])


def test_preparar_detecta_motor_sci(tmp_path):
    (tmp_path / "SIERRA.EXE").write_bytes(b"interprete")
    (tmp_path / "RESOURCE.MAP").write_bytes(b"mapa")
    (tmp_path / "RESOURCE.001").write_bytes(b"recursos")

    prep = preparar(tmp_path, _game())

    assert prep.informe["status"] == "motor-detectado"
    assert prep.informe["profile"] == "sierra-sci"


def test_preparar_motor_sin_marcador_completo_no_matchea(tmp_path):
    """Falta OBJECT: no es la firma completa de AGI, cae a provisional."""
    (tmp_path / "KQ4.EXE").write_bytes(b"interprete")
    (tmp_path / "WORDS.TOK").write_bytes(b"vocabulario")
    (tmp_path / "VOL.0").write_bytes(b"recursos")

    prep = preparar(tmp_path, _game())

    assert prep.informe["status"] == "provisional"


def test_preparar_motor_detectado_pero_varios_ejecutables_no_elige(tmp_path):
    (tmp_path / "KQ4.EXE").write_bytes(b"interprete")
    (tmp_path / "OTRO.EXE").write_bytes(b"no es el interprete")
    (tmp_path / "WORDS.TOK").write_bytes(b"vocabulario")
    (tmp_path / "OBJECT").write_bytes(b"objetos")
    (tmp_path / "VOL.0").write_bytes(b"recursos")

    prep = preparar(tmp_path, _game())

    assert prep.informe["status"] == "pendiente"


def test_preparar_perfil_conocido_tiene_prioridad_sobre_motor(tmp_path, monkeypatch):
    """Un perfil por hash exacto pesa mas que la sola firma de motor."""
    perfil = _perfil_de_prueba(tmp_path)
    monkeypatch.setattr(dosbox, "PERFILES", (perfil,))
    (tmp_path / "WORDS.TOK").write_bytes(b"vocabulario")
    (tmp_path / "OBJECT").write_bytes(b"objetos")
    (tmp_path / "VOL.0").write_bytes(b"recursos")

    prep = preparar(tmp_path, _game())

    assert prep.informe["status"] == "perfil-conocido"


# ---------------------------------------------------------------------------
# comando_launch
# ---------------------------------------------------------------------------

def test_comando_launch_referencia_emulador_embebido():
    launch = comando_launch()
    assert "emulators/dosbox-staging" in launch
    assert "--working-dir" in launch
    assert "--nolocalconf" in launch
