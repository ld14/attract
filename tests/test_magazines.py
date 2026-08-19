"""Tests de `attract mags` (ADR-0025).

Los numeros de los tests de matching son los MEDIDOS contra `micromania-34`,
no inventados: `golden-axe` vs el set `goldnaxe` da 0.94 y el falso candidato
mas alto de esa revista da 0.43. Si alguien toca la normalizacion o cambia de
algoritmo, estos tests dicen si el margen sigue existiendo.
"""
import json

import pytest

from attract.magazines import (
    UMBRAL_DEFECTO,
    agregar_ref,
    juegos_instalados,
    main,
    mejor_match,
    normalizar,
    slugs_de_revista,
)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

METADATA = """collection: Arcade
launch: mame {file.basename}

game: Golden Axe (set 6, US) (8751 317-123A)
file: goldnaxe.zip
x-set: goldnaxe

game: The Maze of the Kings
file: mok.zip
"""


def _libreria(tmp_path, metadata=METADATA):
    sistema = tmp_path / "arcade"
    sistema.mkdir()
    (sistema / "metadata.pegasus.txt").write_text(metadata, encoding="utf-8")
    return tmp_path


def _revista(raiz, ref, articles):
    d = raiz / "_magazines" / ref
    d.mkdir(parents=True)
    (d / "magazine.json").write_text(
        json.dumps({"name": ref, "cover": "cover.jpg", "key_id": ref,
                    "pages": ["p001.jpg"], "articles": articles}),
        encoding="utf-8",
    )
    return d


# ---------------------------------------------------------------------------
# normalizar
# ---------------------------------------------------------------------------

def test_normalizar_saca_todo_lo_que_no_sea_alfanumerico():
    assert normalizar("Golden Axe (set 6, US)") == "goldenaxeset6us"
    assert normalizar("golden-axe") == "goldenaxe"


def test_normalizar_no_alcanza_para_matchear():
    # EL motivo por el que este modulo usa difflib y no comparacion exacta:
    # al set de MAME le falta una `e`. Si esto alguna vez da True, el matching
    # difuso dejo de hacer falta.
    assert normalizar("golden-axe") != normalizar("goldnaxe")


# ---------------------------------------------------------------------------
# Lectura del disco
# ---------------------------------------------------------------------------

def test_juegos_instalados_lee_set_y_titulo(tmp_path):
    juegos = juegos_instalados(_libreria(tmp_path))
    assert {j.set_id for j in juegos} == {"goldnaxe", "mok"}

    golden = next(j for j in juegos if j.set_id == "goldnaxe")
    assert golden.titulo == "Golden Axe (set 6, US) (8751 317-123A)"
    assert golden.data_json == tmp_path / "arcade" / "media" / "goldnaxe" / "data.json"


def test_set_sale_del_file_cuando_no_hay_x_set(tmp_path):
    # ADR-0004: x-set si esta, si no el file: sin extension. `mok` no declara
    # x-set en el fixture de arriba.
    juegos = juegos_instalados(_libreria(tmp_path))
    assert next(j for j in juegos if j.set_id == "mok").titulo == "The Maze of the Kings"


def test_slugs_ignora_articulos_sin_game(tmp_path):
    # Publicidad e indice no tratan sobre un juego puntual: es parte del
    # contrato (ADR-0024), no un dato faltante.
    d = _revista(tmp_path, "rev-1", [
        {"type": "publicidad", "startPage": 1, "pages": [1], "confidence": 0.9},
        {"type": "review", "game": "golden-axe", "startPage": 1, "pages": [1],
         "confidence": 0.9},
    ])
    assert slugs_de_revista(d / "magazine.json") == ["golden-axe"]


def test_slugs_no_repite(tmp_path):
    # Un juego con dos articulos en la misma revista es un solo ref.
    d = _revista(tmp_path, "rev-1", [
        {"type": "review", "game": "golden-axe", "startPage": 1, "pages": [1],
         "confidence": 0.9},
        {"type": "guía", "game": "golden-axe", "startPage": 1, "pages": [1],
         "confidence": 0.9},
    ])
    assert slugs_de_revista(d / "magazine.json") == ["golden-axe"]


def test_slugs_de_magazine_roto_no_explota(tmp_path):
    d = tmp_path / "_magazines" / "rota"
    d.mkdir(parents=True)
    (d / "magazine.json").write_text("{no es json", encoding="utf-8")
    assert slugs_de_revista(d / "magazine.json") == []


# ---------------------------------------------------------------------------
# Matching
# ---------------------------------------------------------------------------

def test_golden_axe_matchea_goldnaxe(tmp_path):
    juegos = juegos_instalados(_libreria(tmp_path))
    m = mejor_match("golden-axe", juegos, UMBRAL_DEFECTO)
    assert m.juego is not None
    assert m.juego.set_id == "goldnaxe"
    assert m.ratio > 0.9
    assert m.via == "set"


@pytest.mark.parametrize("slug", [
    "voodoo-nightmare", "colony", "zelda-ii-the-adventure-of-link",
    "battle-squadron", "dr-mario", "car-vup",
])
def test_los_otros_slugs_de_micromania_34_no_matchean(tmp_path, slug):
    # Los 20 slugs de la revista real contra los 2 sets instalados: solo uno
    # tiene que pasar. Estos son los que mas cerca quedaron.
    juegos = juegos_instalados(_libreria(tmp_path))
    assert mejor_match(slug, juegos, UMBRAL_DEFECTO).juego is None


def test_sin_match_igual_reporta_el_mejor_candidato(tmp_path):
    # El ratio se conserva aunque no llegue al umbral: es como se ajusta el
    # umbral con evidencia en vez de a ojo.
    juegos = juegos_instalados(_libreria(tmp_path))
    m = mejor_match("voodoo-nightmare", juegos, UMBRAL_DEFECTO)
    assert m.juego is None
    assert 0 < m.ratio < UMBRAL_DEFECTO


def test_umbral_bajo_deja_pasar_basura(tmp_path):
    # No es una feature, es la razon por la que el default es 0.85 y por la
    # que --apply no es el modo por defecto.
    juegos = juegos_instalados(_libreria(tmp_path))
    assert mejor_match("voodoo-nightmare", juegos, 0.3).juego is not None


def test_matchea_por_titulo_cuando_el_set_no_se_parece(tmp_path):
    # `mok` no se parece a nada; el titulo si.
    juegos = juegos_instalados(_libreria(tmp_path))
    m = mejor_match("the-maze-of-the-kings", juegos, UMBRAL_DEFECTO)
    assert m.juego is not None
    assert m.juego.set_id == "mok"
    assert m.via == "titulo"


# ---------------------------------------------------------------------------
# Escritura
# ---------------------------------------------------------------------------

def test_agregar_ref_conserva_todo_lo_demas(tmp_path):
    # data.json lo escribe una persona: esta herramienta es duena de `mags`
    # y de nada mas.
    dj = tmp_path / "data.json"
    original = {
        "accent": "#d4a017",
        "review": {"score": 88, "cats": {"graficos": 85}},
        "cheats": {"combos": [{"name": "Magia", "input": "MAGIA"}]},
        "manual": [{"file": "manual.pdf", "pages": ["p001.png"]}],
    }
    dj.write_text(json.dumps(original), encoding="utf-8")

    assert agregar_ref(dj, "micromania-34") is True

    datos = json.loads(dj.read_text(encoding="utf-8"))
    assert datos["mags"] == [{"ref": "micromania-34"}]
    for clave, valor in original.items():
        assert datos[clave] == valor


def test_agregar_ref_escribe_el_slug_del_articulo(tmp_path):
    # Sin esto el theme no puede encontrar la nota: compara contra el set
    # (`goldnaxe`) y el articulo dice `golden-axe` (ADR-0025).
    dj = tmp_path / "data.json"
    assert agregar_ref(dj, "micromania-34", "golden-axe") is True
    assert json.loads(dj.read_text(encoding="utf-8"))["mags"] == [
        {"ref": "micromania-34", "article": "golden-axe"},
    ]


def test_agregar_ref_no_pisa_un_article_corregido_a_mano(tmp_path):
    # El ref ya esta: no se toca la entrada, aunque el slug difiera. Una
    # correccion manual gana sobre el match difuso.
    dj = tmp_path / "data.json"
    dj.write_text(json.dumps({"mags": [{"ref": "rev", "article": "a-mano"}]}),
                  encoding="utf-8")

    assert agregar_ref(dj, "rev", "el-difuso") is False
    assert json.loads(dj.read_text(encoding="utf-8"))["mags"] == [
        {"ref": "rev", "article": "a-mano"},
    ]


def test_agregar_ref_es_idempotente(tmp_path):
    dj = tmp_path / "data.json"
    dj.write_text('{"accent": "#d4a017"}', encoding="utf-8")

    assert agregar_ref(dj, "micromania-34") is True
    assert agregar_ref(dj, "micromania-34") is False

    assert json.loads(dj.read_text(encoding="utf-8"))["mags"] == [{"ref": "micromania-34"}]


def test_agregar_ref_suma_a_los_que_ya_estaban(tmp_path):
    dj = tmp_path / "data.json"
    dj.write_text('{"mags": [{"ref": "micromania-16"}]}', encoding="utf-8")

    assert agregar_ref(dj, "micromania-34") is True
    assert json.loads(dj.read_text(encoding="utf-8"))["mags"] == [
        {"ref": "micromania-16"}, {"ref": "micromania-34"},
    ]


def test_agregar_ref_crea_el_data_json_si_no_existe(tmp_path):
    dj = tmp_path / "media" / "goldnaxe" / "data.json"
    assert agregar_ref(dj, "micromania-34") is True
    assert json.loads(dj.read_text(encoding="utf-8")) == {"mags": [{"ref": "micromania-34"}]}


def test_agregar_ref_no_pisa_un_json_roto(tmp_path):
    dj = tmp_path / "data.json"
    dj.write_text("{no es json", encoding="utf-8")

    assert agregar_ref(dj, "micromania-34") is False
    assert dj.read_text(encoding="utf-8") == "{no es json"


def test_agregar_ref_escribe_utf8_sin_escapar(tmp_path):
    # El theme lee esto con XMLHttpRequest; los \uXXXX pasarian igual, pero el
    # archivo lo abre una persona (ADR-0013).
    dj = tmp_path / "data.json"
    dj.write_text('{"cheats": {"combos": [{"name": "Patada giratoria \\u00f1"}]}}',
                  encoding="utf-8")
    agregar_ref(dj, "rev")
    assert "ñ" in dj.read_text(encoding="utf-8")


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def test_dry_run_no_escribe_nada(tmp_path):
    raiz = _libreria(tmp_path)
    _revista(raiz, "micromania-34", [
        {"type": "guía", "game": "golden-axe", "startPage": 1, "pages": [1],
         "confidence": 1},
    ])

    assert main([str(raiz)]) == 0
    assert not (raiz / "arcade" / "media" / "goldnaxe" / "data.json").exists()


def test_apply_escribe_el_ref(tmp_path):
    raiz = _libreria(tmp_path)
    _revista(raiz, "micromania-34", [
        {"type": "guía", "game": "golden-axe", "startPage": 1, "pages": [1],
         "confidence": 1},
        {"type": "review", "game": "battle-squadron", "startPage": 1, "pages": [1],
         "confidence": 1},
    ])

    assert main([str(raiz), "--apply"]) == 0

    dj = raiz / "arcade" / "media" / "goldnaxe" / "data.json"
    # El slug va escrito: es lo que el theme usa para encontrar la nota.
    assert json.loads(dj.read_text(encoding="utf-8"))["mags"] == [
        {"ref": "micromania-34", "article": "golden-axe"},
    ]
    # battle-squadron no esta instalado: no se inventa una carpeta para el
    assert not (raiz / "arcade" / "media" / "battle-squadron").exists()


def test_apply_dos_veces_no_duplica(tmp_path):
    raiz = _libreria(tmp_path)
    _revista(raiz, "micromania-34", [
        {"type": "guía", "game": "golden-axe", "startPage": 1, "pages": [1],
         "confidence": 1},
    ])

    main([str(raiz), "--apply"])
    main([str(raiz), "--apply"])

    dj = raiz / "arcade" / "media" / "goldnaxe" / "data.json"
    assert json.loads(dj.read_text(encoding="utf-8"))["mags"] == [
        {"ref": "micromania-34", "article": "golden-axe"},
    ]


def test_sin_carpeta_magazines_falla_claro(tmp_path, capsys):
    assert main([str(_libreria(tmp_path))]) == 2
    assert "_magazines" in capsys.readouterr().err


def test_umbral_invalido_falla(tmp_path):
    raiz = _libreria(tmp_path)
    _revista(raiz, "rev", [])
    assert main([str(raiz), "--umbral", "asi-no"]) == 2
