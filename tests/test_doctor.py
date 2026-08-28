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
    d = tmp_path / "_magazines" / "rev-1"
    d.mkdir(parents=True)
    (d / "magazine.json").write_text("{no es json", encoding="utf-8")
    assert "json-invalido" in chequeos(revisar(tmp_path))


def test_mags_ref_faltante_es_aviso_no_error(tmp_path):
    # Degradacion soportada a proposito (ADR-0008): no bloquea el viaje a
    # Windows, pero attract doctor la tiene que notar.
    d = tmp_path / "arcade" / "media" / "x"
    d.mkdir(parents=True)
    (d / "data.json").write_text('{"mags": [{"ref": "no-existe"}]}', encoding="utf-8")

    rep = revisar(tmp_path)
    assert rep.ok  # no es error
    assert "mags-ref-faltante" in {h.chequeo for h in rep.avisos}


def test_mags_ref_existente_no_avisa(tmp_path):
    # La revista vive en <raiz>/_magazines/, fuera del arbol del sistema
    # (ADR-0024): la misma revista cubre juegos de arcade, NES y PC.
    (tmp_path / "_magazines" / "rev-1").mkdir(parents=True)
    d = tmp_path / "arcade" / "media" / "x"
    d.mkdir(parents=True)
    (d / "data.json").write_text('{"mags": [{"ref": "rev-1"}]}', encoding="utf-8")

    rep = revisar(tmp_path)
    assert "mags-ref-faltante" not in {h.chequeo for h in rep.avisos}


def test_mags_ref_no_se_resuelve_dentro_del_sistema(tmp_path):
    # El layout viejo (ADR-0010): la revista adentro de media/. Tiene que
    # avisar igual, o mover una libreria de la forma vieja pasaria en silencio.
    (tmp_path / "arcade" / "media" / "_magazines" / "rev-1").mkdir(parents=True)
    d = tmp_path / "arcade" / "media" / "x"
    d.mkdir(parents=True)
    (d / "data.json").write_text('{"mags": [{"ref": "rev-1"}]}', encoding="utf-8")

    rep = revisar(tmp_path)
    assert "mags-ref-faltante" in {h.chequeo for h in rep.avisos}


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
    """La revista, con sus assets en el disco (ADR-0024): cover en la raiz,
    paginas en pages/. Se crean los archivos que `datos` declara para que
    chk_magazine_assets no dispare y tape lo que cada test quiere medir."""
    d = tmp_path / "_magazines" / "rev-1"
    (d / "pages").mkdir(parents=True)
    (d / "magazine.json").write_text(json.dumps(datos), encoding="utf-8")

    cover = datos.get("cover")
    if isinstance(cover, str) and cover.strip():
        (d / cover).write_bytes(b"")
    for p in datos.get("pages") or []:
        if isinstance(p, str):
            (d / "pages" / p).write_bytes(b"")


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


# --- cheats con grupos de nombre libre (ADR-0020) -------------------------
#
# El bug que estos cubren, visto el 2026-08-09: un data.json con claves
# inventadas ("secrets", "two_player", "service") pasaba doctor en VERDE y el
# theme no mostraba ni una de esas entradas. Ahora la clave es libre, pero la
# FORMA se valida.

def test_cheats_grupo_con_nombre_libre_es_valido(tmp_path):
    _escribir_data(tmp_path, {
        "cheats": {
            "secretos": [{"name": "Dragon rojo", "input": "Aparece en la fase 3"}],
            "dos_jugadores": [{"name": "Revivir", "input": "Bajarle la vida en el bonus"}],
        }
    })
    assert revisar(tmp_path).ok


def test_cheats_grupo_con_label_explicito_es_valido(tmp_path):
    _escribir_data(tmp_path, {
        "cheats": {
            "servicio": {
                "label": "Menu de servicio",
                "items": [{"name": "Free Play", "input": "FREE PLAY = ON"}],
            }
        }
    })
    assert revisar(tmp_path).ok


def test_cheats_objeto_sin_items_es_error(tmp_path):
    _escribir_data(tmp_path, {"cheats": {"servicio": {"label": "Solo titulo"}}})
    assert "data-contrato" in chequeos(revisar(tmp_path))


def test_cheats_grupo_de_tipo_invalido_es_error(tmp_path):
    """Un grupo que no es lista ni objeto no lo puede dibujar nadie."""
    _escribir_data(tmp_path, {"cheats": {"secretos": "un string suelto"}})
    assert "data-contrato" in chequeos(revisar(tmp_path))


def test_cheats_entrada_incompleta_en_grupo_libre_es_error(tmp_path):
    """La validacion de {name, input} vale para CUALQUIER grupo, no solo
    para combos/codes."""
    _escribir_data(tmp_path, {"cheats": {"secretos": [{"name": "Sin input"}]}})
    assert "data-contrato" in chequeos(revisar(tmp_path))


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
    _escribir_data(tmp_path, {"manual": [{"pages": ["p001.jpg"]}]})
    assert "data-contrato" in chequeos(revisar(tmp_path))


def test_manual_con_paginas_reales_no_reporta(tmp_path):
    d = _escribir_data(tmp_path, {"manual": [{"pages": ["p001.jpg", "p002.jpg"]}]})
    (d / "_manual").mkdir()
    (d / "_manual" / "p001.jpg").write_bytes(b"")
    (d / "_manual" / "p002.jpg").write_bytes(b"")
    assert revisar(tmp_path).ok


# --- manual.file: el PDF que abre la app del sistema (ADR-0021) ------------
#
# `_con_manual` recibe UN documento (la forma de un elemento de la lista) y lo
# envuelve en `[...]` - asi los tests de mas abajo siguen probando exactamente
# lo que probaban antes de que `manual` pasara a lista (ADR-0023), sin tener
# que reescribir cada llamada.

def _con_manual(tmp_path, documento, archivos=()):
    """data.json con `manual: [documento]` y los archivos que existan en _manual/."""
    d = _escribir_data(tmp_path, {"manual": [documento]})
    (d / "_manual").mkdir()
    for nombre in archivos:
        (d / "_manual" / nombre).write_bytes(b"")
    return d


def test_manual_solo_con_pdf_es_valido(tmp_path):
    # El caso que motiva ADR-0021: un manual que existe SOLO como PDF, sin
    # rasterizar. Antes era invisible en la pantalla.
    _con_manual(tmp_path, {"file": "manual.pdf"}, ["manual.pdf"])
    assert revisar(tmp_path).ok


def test_manual_con_paginas_y_pdf_es_valido(tmp_path):
    _con_manual(
        tmp_path,
        {"pages": ["p001.jpg"], "file": "manual.pdf"},
        ["p001.jpg", "manual.pdf"],
    )
    assert revisar(tmp_path).ok


def test_manual_sin_pages_ni_file_es_error(tmp_path):
    # Declara un manual y no dice donde esta. Con `pages: []` en cambio SI es
    # valido: es la degradacion explicita de ADR-0014 ("No Disponible").
    _con_manual(tmp_path, {})
    assert "data-contrato" in chequeos(revisar(tmp_path))


def test_manual_pages_vacio_sigue_siendo_valido(tmp_path):
    # Invariante: agregar `file` no rompio la degradacion que ya existia.
    _con_manual(tmp_path, {"pages": []})
    assert revisar(tmp_path).ok


def test_manual_file_que_no_existe_es_error(tmp_path):
    # Mismo criterio que las paginas: el theme no puede chequear si un archivo
    # existe (su unica herramienta de disco es XMLHttpRequest), asi que si esto
    # no falla aca, falla apretando el boton en el gabinete.
    _con_manual(tmp_path, {"file": "manual.pdf"})
    assert "data-contrato" in chequeos(revisar(tmp_path))


def test_manual_file_con_ruta_es_error(tmp_path):
    # Es un nombre suelto dentro de _manual/, no una ruta. El theme lo concatena
    # tal cual y se lo pasa al sistema operativo.
    _con_manual(tmp_path, {"file": "../../otro.pdf"}, ["manual.pdf"])
    assert "data-contrato" in chequeos(revisar(tmp_path))


def test_manual_file_con_separador_windows_es_error(tmp_path):
    _con_manual(tmp_path, {"file": "sub\\manual.pdf"}, ["manual.pdf"])
    assert "data-contrato" in chequeos(revisar(tmp_path))


def test_manual_file_sin_extension_pdf_es_error(tmp_path):
    # La extension es lo unico que decide con que aplicacion abre el SO.
    _con_manual(tmp_path, {"file": "manual"}, ["manual"])
    assert "data-contrato" in chequeos(revisar(tmp_path))


def test_manual_file_pdf_en_mayusculas_es_valido(tmp_path):
    # Windows no distingue mayusculas y es la maquina de produccion (ADR-0003).
    _con_manual(tmp_path, {"file": "MANUAL.PDF"}, ["MANUAL.PDF"])
    assert revisar(tmp_path).ok


def test_manual_file_vacio_es_error(tmp_path):
    _con_manual(tmp_path, {"file": "   "})
    assert "data-contrato" in chequeos(revisar(tmp_path))


# --- manual como lista de documentos, con label (ADR-0023) -----------------

def test_manual_objeto_suelto_es_error(tmp_path):
    # La forma vieja, pre-0023. No se interpreta como lista de uno: error
    # explicito con la migracion (envolver en []).
    _escribir_data(tmp_path, {"manual": {"file": "manual.pdf"}})
    assert "data-contrato" in chequeos(revisar(tmp_path))


def test_manual_lista_vacia_es_error(tmp_path):
    _escribir_data(tmp_path, {"manual": []})
    assert "data-contrato" in chequeos(revisar(tmp_path))


def test_manual_un_documento_sin_label_es_valido(tmp_path):
    # Cero migracion: un solo documento sigue sin necesitar label (sf2ce).
    d = _escribir_data(tmp_path, {"manual": [{"file": "manual.pdf"}]})
    (d / "_manual").mkdir()
    (d / "_manual" / "manual.pdf").write_bytes(b"")
    assert revisar(tmp_path).ok


def test_manual_dos_documentos_con_label_es_valido(tmp_path):
    d = _escribir_data(tmp_path, {
        "manual": [
            {"label": "Manual de uso", "file": "uso.pdf"},
            {"label": "Manual de servicio", "file": "servicio.pdf"},
        ]
    })
    (d / "_manual").mkdir()
    (d / "_manual" / "uso.pdf").write_bytes(b"")
    (d / "_manual" / "servicio.pdf").write_bytes(b"")
    assert revisar(tmp_path).ok


def test_manual_dos_documentos_uno_sin_label_es_error(tmp_path):
    d = _escribir_data(tmp_path, {
        "manual": [
            {"label": "Manual de uso", "file": "uso.pdf"},
            {"file": "servicio.pdf"},
        ]
    })
    (d / "_manual").mkdir()
    (d / "_manual" / "uso.pdf").write_bytes(b"")
    (d / "_manual" / "servicio.pdf").write_bytes(b"")
    assert "data-contrato" in chequeos(revisar(tmp_path))


def test_manual_labels_repetidos_es_error(tmp_path):
    # Si no, `rasterize <set> <label>` seria ambiguo: no sabria cual de los dos.
    d = _escribir_data(tmp_path, {
        "manual": [
            {"label": "Manual", "file": "a.pdf"},
            {"label": "Manual", "file": "b.pdf"},
        ]
    })
    (d / "_manual").mkdir()
    (d / "_manual" / "a.pdf").write_bytes(b"")
    (d / "_manual" / "b.pdf").write_bytes(b"")
    assert "data-contrato" in chequeos(revisar(tmp_path))


def test_manual_un_elemento_no_dict_es_error(tmp_path):
    _escribir_data(tmp_path, {"manual": ["no es un objeto"]})
    assert "data-contrato" in chequeos(revisar(tmp_path))


def test_mags_sin_ref_es_error(tmp_path):
    # Distinto de mags-ref-faltante (que es AVISO): aca la entrada esta mal
    # formada, no apunta a nada. Sin ref no hay degradacion posible.
    _escribir_data(tmp_path, {"mags": [{"nombre": "micromania-16"}]})
    assert "data-contrato" in chequeos(revisar(tmp_path))


# --- startPage como numero de pagina impresa (ADR-0024) -------------------

def test_startpage_a_pagina_inexistente_es_error(tmp_path):
    # Una revista de 2 paginas con un articulo que abre en la 5. Sin este
    # chequeo pasaba el validador y se veia recien en el visor del theme.
    datos = _magazine_valida()
    datos["pages"] = ["p001.jpg", "p002.jpg"]
    datos["articles"][0]["startPage"] = 5
    datos["articles"][0]["pages"] = [1]
    _escribir_magazine(tmp_path, datos)
    assert "magazine-contrato" in chequeos(revisar(tmp_path))


def test_startpage_cero_es_error(tmp_path):
    # No hay ningun archivo "p000", asi que el 0 nunca resuelve. Es el error
    # probable de quien asuma que startPage es un offset de array.
    datos = _magazine_valida()
    datos["articles"][0]["startPage"] = 0
    _escribir_magazine(tmp_path, datos)
    assert "magazine-contrato" in chequeos(revisar(tmp_path))


def test_articles_pages_a_pagina_inexistente_es_error(tmp_path):
    datos = _magazine_valida()
    datos["pages"] = ["p001.jpg", "p002.jpg"]
    datos["articles"][0]["startPage"] = 1
    datos["articles"][0]["pages"] = [1, 7]
    _escribir_magazine(tmp_path, datos)
    assert "magazine-contrato" in chequeos(revisar(tmp_path))


def test_paginas_en_el_limite_son_validas(tmp_path):
    # La primera y la ultima son los dos extremos VALIDOS. Es el caso que un
    # chequeo de rango mal escrito rompe.
    datos = _magazine_valida()
    datos["pages"] = ["p001.jpg", "p002.jpg", "p003.jpg"]
    datos["articles"][0]["startPage"] = 3
    datos["articles"][0]["pages"] = [1, 3]
    _escribir_magazine(tmp_path, datos)
    assert revisar(tmp_path).ok


def test_revista_que_no_arranca_en_p001_no_es_error(tmp_path):
    # EL bug de ADR-0024, con los numeros de micromania-34 en miniatura:
    # pages[] arranca en p002 porque la pagina 1 es la tapa, y el ultimo
    # articulo apunta a la ULTIMA pagina impresa. Contando posiciones eso da
    # "fuera de rango" (4 paginas, indice 5); por numero de archivo es valido.
    datos = _magazine_valida()
    datos["pages"] = ["p002.jpg", "p003.jpg", "p004.jpg", "p005.jpg"]
    datos["articles"][0]["startPage"] = 5
    datos["articles"][0]["pages"] = [5]
    _escribir_magazine(tmp_path, datos)
    assert revisar(tmp_path).ok


# --- assets de la revista en el disco (ADR-0024) ---------------------------

def test_pagina_declarada_que_no_existe_es_error(tmp_path):
    # El sintoma de esto era una pagina en blanco en el visor, sin ningun
    # error en ningun lado.
    datos = _magazine_valida()
    _escribir_magazine(tmp_path, datos)
    (tmp_path / "_magazines" / "rev-1" / "pages" / "p002.jpg").unlink()
    assert "magazine-assets" in chequeos(revisar(tmp_path))


def test_paginas_sueltas_sin_carpeta_pages_es_error(tmp_path):
    # El layout viejo: las paginas en la raiz de la revista. Tienen que ir en
    # pages/ (ADR-0024) o el theme no las encuentra.
    d = tmp_path / "_magazines" / "rev-1"
    d.mkdir(parents=True)
    datos = _magazine_valida()
    (d / "magazine.json").write_text(json.dumps(datos), encoding="utf-8")
    (d / "cover.jpg").write_bytes(b"")
    for p in datos["pages"]:
        (d / p).write_bytes(b"")

    assert "magazine-assets" in chequeos(revisar(tmp_path))


def test_cover_que_no_existe_es_error(tmp_path):
    datos = _magazine_valida()
    _escribir_magazine(tmp_path, datos)
    (tmp_path / "_magazines" / "rev-1" / "cover.jpg").unlink()
    assert "magazine-assets" in chequeos(revisar(tmp_path))


def test_guia_es_un_type_conocido(tmp_path):
    # El generador real lo emite; hasta ADR-0024 daba aviso.
    datos = _magazine_valida()
    datos["articles"][0]["type"] = "guía"
    _escribir_magazine(tmp_path, datos)
    assert revisar(tmp_path).ok


# --- gallery (ADR-0030, extiende ADR-0015) --------------------------------
#
# Cada pieza tiene la forma { file, label } que COINDOOR ya emite.
# El tipo sale de la extension, no de un campo.

def _escribir_gallery(tmp_path, gallery, set_id="x"):
    """data.json con `gallery` y los archivos que existan en _gallery/."""
    d = tmp_path / "media" / set_id
    d.mkdir(parents=True, exist_ok=True)
    (d / "data.json").write_text(json.dumps({"gallery": gallery}), encoding="utf-8")
    return d


def test_gallery_vacio_es_valido(tmp_path):
    _escribir_gallery(tmp_path, [])
    rep = revisar(tmp_path)
    assert rep.ok


def test_gallery_sin_campo_es_valido(tmp_path):
    d = tmp_path / "media" / "x"
    d.mkdir(parents=True)
    (d / "data.json").write_text("{}", encoding="utf-8")
    assert revisar(tmp_path).ok


def test_gallery_como_string_es_error(tmp_path):
    _escribir_gallery(tmp_path, "no es una lista")
    assert "data-contrato" in chequeos(revisar(tmp_path))


def test_gallery_item_no_dict_es_error(tmp_path):
    _escribir_gallery(tmp_path, ["no es un objeto"])
    assert "data-contrato" in chequeos(revisar(tmp_path))


def test_gallery_file_no_string_es_error(tmp_path):
    _escribir_gallery(tmp_path, [{"file": 123, "label": "Foto"}])
    assert "data-contrato" in chequeos(revisar(tmp_path))


def test_gallery_label_ausente_es_error(tmp_path):
    _escribir_gallery(tmp_path, [{"file": "g001.png"}])
    assert "data-contrato" in chequeos(revisar(tmp_path))


def test_gallery_label_vacio_es_error(tmp_path):
    _escribir_gallery(tmp_path, [{"file": "g001.png", "label": "   "}])
    assert "data-contrato" in chequeos(revisar(tmp_path))


def test_gallery_extension_desconocida_es_error(tmp_path):
    _escribir_gallery(tmp_path, [{"file": "g001.bmp", "label": "Foto"}])
    assert "data-contrato" in chequeos(revisar(tmp_path))


def test_gallery_archivo_que_no_existe_es_error(tmp_path):
    _escribir_gallery(tmp_path, [{"file": "g001.png", "label": "Foto"}])
    assert "data-contrato" in chequeos(revisar(tmp_path))


def test_gallery_file_vacio_es_aviso_no_error(tmp_path):
    # file: "" es un estado declarado valido (pendiente de conseguir).
    rep = revisar(_escribir_gallery(tmp_path, [{"file": "", "label": "Pendiente"}]))
    assert rep.ok
    assert "data-contrato" in {h.chequeo for h in rep.avisos}


def test_gallery_piezas_validas_no_reportan(tmp_path):
    d = _escribir_gallery(tmp_path, [
        {"file": "g001.png", "label": "Panel de control"},
        {"file": "g002.jpg", "label": "Placa PCB"},
        {"file": "g003.mp4", "label": "Gameplay"},
    ])
    (d / "_gallery").mkdir()
    (d / "_gallery" / "g001.png").write_bytes(b"")
    (d / "_gallery" / "g002.jpg").write_bytes(b"")
    (d / "_gallery" / "g003.mp4").write_bytes(b"")
    assert revisar(tmp_path).ok


def test_gallery_extension_en_mayusculas_es_valida(tmp_path):
    d = _escribir_gallery(tmp_path, [{"file": "G001.PNG", "label": "Foto"}])
    (d / "_gallery").mkdir()
    (d / "_gallery" / "G001.PNG").write_bytes(b"")
    assert revisar(tmp_path).ok


def test_gallery_mezcla_archivo_y_vacio_es_valido(tmp_path):
    d = _escribir_gallery(tmp_path, [
        {"file": "g001.png", "label": "Foto real"},
        {"file": "", "label": "Pendiente"},
    ])
    (d / "_gallery").mkdir()
    (d / "_gallery" / "g001.png").write_bytes(b"")
    rep = revisar(tmp_path)
    assert rep.ok
    assert "data-contrato" in {h.chequeo for h in rep.avisos}
