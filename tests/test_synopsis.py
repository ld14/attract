"""Tests de attract synopsis. Ver spec/features/001-synopsis/."""
from pathlib import Path

import pytest

from attract.doctor import revisar
from attract.synopsis import (
    SynopsisError,
    aplicar,
    escribir,
    identificar_set,
    leer_fuente,
    mergear_summary,
    parsear_bloques,
)

FIXTURES = Path(__file__).parent.parent / "fixtures" / "arcade"


def _copiar_fixtures(tmp_path):
    import shutil

    destino = tmp_path / "arcade"
    shutil.copytree(FIXTURES, destino)
    return destino


# --- caso feliz: multilinea previa (mok, contra el fixture real) ----------

def test_reemplaza_summary_multilinea_existente(tmp_path):
    raiz = _copiar_fixtures(tmp_path)
    metadata_path = raiz / "metadata.pegasus.txt"
    original = metadata_path.read_text(encoding="utf-8")

    nuevo = leer_fuente(raiz, "mok")
    aplicar(metadata_path, "mok", nuevo)

    resultado = metadata_path.read_text(encoding="utf-8")
    assert nuevo in resultado
    assert "cazando tesoros" in resultado  # texto nuevo
    assert "se rearma en cada partida" not in resultado  # texto viejo, sin restos
    # nada mas del bloque cambio
    assert "developer: Hitmaker" in resultado
    assert "x-procedencia: manual" in resultado
    # el resto del archivo (otros bloques) esta intacto
    assert original.split("game: Street Fighter")[1] == resultado.split("game: Street Fighter")[1]


# --- caso feliz: insertar donde no habia summary: previo -------------------

def test_inserta_summary_nuevo_despues_de_file(tmp_path):
    metadata_path = tmp_path / "metadata.pegasus.txt"
    metadata_path.write_text(
        "game: X\nfile: x.zip\nx-set: x\ndeveloper: Alguien\n",
        encoding="utf-8",
    )
    (tmp_path / "_synopsis").mkdir()
    (tmp_path / "_synopsis" / "x.json").write_text(
        '{"summary": "Un juego de prueba."}', encoding="utf-8"
    )

    texto = leer_fuente(tmp_path, "x")
    aplicar(metadata_path, "x", texto)

    lineas = metadata_path.read_text(encoding="utf-8").splitlines()
    assert lineas == [
        "game: X",
        "file: x.zip",
        "summary: Un juego de prueba.",
        "x-set: x",
        "developer: Alguien",
    ]


# --- idempotencia ------------------------------------------------------

def test_idempotente(tmp_path):
    raiz = _copiar_fixtures(tmp_path)
    metadata_path = raiz / "metadata.pegasus.txt"

    nuevo = leer_fuente(raiz, "mok")
    aplicar(metadata_path, "mok", nuevo)
    primera = metadata_path.read_text(encoding="utf-8")

    aplicar(metadata_path, "mok", nuevo)
    segunda = metadata_path.read_text(encoding="utf-8")

    assert primera == segunda


# --- roundtrip sin merges: no-op ----------------------------------------

def test_parsear_y_escribir_sin_merge_es_noop():
    texto = (FIXTURES / "metadata.pegasus.txt").read_text(encoding="utf-8")
    bloques = parsear_bloques(texto)
    assert escribir(bloques) == texto


# --- identidad por x-set o file: ----------------------------------------

def test_identifica_por_x_set_y_por_file():
    texto = (FIXTURES / "metadata.pegasus.txt").read_text(encoding="utf-8")
    bloques = [b for b in parsear_bloques(texto) if b.es_game]
    sets = [identificar_set(b) for b in bloques]
    assert "mok" in sets
    assert "sf2ce" in sets
    assert "dino" in sets  # EXPERIMENTO no tiene x-set, cae a file: dino.zip


# --- casos limite / de fallo --------------------------------------------

def test_fuente_ausente(tmp_path):
    with pytest.raises(SynopsisError, match="no existe fuente"):
        leer_fuente(tmp_path, "no-existe")


def test_fuente_sin_campo_summary(tmp_path):
    (tmp_path / "_synopsis").mkdir()
    (tmp_path / "_synopsis" / "x.json").write_text("{}", encoding="utf-8")
    with pytest.raises(SynopsisError, match="falta 'summary'"):
        leer_fuente(tmp_path, "x")


def test_fuente_json_invalido(tmp_path):
    (tmp_path / "_synopsis").mkdir()
    (tmp_path / "_synopsis" / "x.json").write_text("{no es json", encoding="utf-8")
    with pytest.raises(SynopsisError, match="JSON invalido"):
        leer_fuente(tmp_path, "x")


def test_set_inexistente_no_crea_bloque(tmp_path):
    metadata_path = tmp_path / "metadata.pegasus.txt"
    metadata_path.write_text("game: X\nfile: x.zip\n", encoding="utf-8")
    with pytest.raises(SynopsisError, match="no se encontro"):
        aplicar(metadata_path, "no-existe", "texto")
    # no se toco el archivo
    assert metadata_path.read_text(encoding="utf-8") == "game: X\nfile: x.zip\n"


def test_bloque_sin_file_falla_explicito():
    from attract.synopsis import Bloque

    b = Bloque(lineas=["game: X", "developer: Y"], es_game=True)
    with pytest.raises(SynopsisError, match="no hay donde insertar"):
        mergear_summary(b, "texto")


# --- invariante: doctor sigue en OK despues de escribir -------------------

def test_doctor_sigue_ok_despues_de_escribir(tmp_path):
    raiz = _copiar_fixtures(tmp_path)
    metadata_path = raiz / "metadata.pegasus.txt"

    for set_id in ("mok",):
        nuevo = leer_fuente(raiz, set_id)
        aplicar(metadata_path, set_id, nuevo)

    rep = revisar(raiz)
    assert rep.ok, [h.detalle for h in rep.errores]
