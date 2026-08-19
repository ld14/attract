"""Tests de attract rasterize. Ver spec/features/013-rasterize-manual/,
spec/features/014-manual-multiple/ y ADR-0022/ADR-0023.

`pymupdf` es una dependencia OPCIONAL (ADR-0022), asi que casi todo lo de
aca se prueba SIN ella: los nombres, el parcheo del data.json y los caminos
de error son stdlib puro. Solo el test de punta a punta usa
pytest.importorskip, para que `pytest tests/` siga pasando en una maquina
limpia - la garantia que motiva la ADR.

Mismo reparto que test_mcp_server.py.
"""
import json
import subprocess
import sys
from pathlib import Path

import pytest

from attract.rasterize import (
    RasterizeError,
    aplicar,
    dir_documento,
    nombres,
    paginas_a_data,
    paginas_existentes,
    pdf_declarado,
    resolver_indice,
)

SRC = Path(__file__).parent.parent / "src"


def _media(tmp_path, datos, archivos=()):
    """media/<set>/ con su data.json y lo que haya en _manual/."""
    d = tmp_path / "media" / "sf2ce"
    (d / "_manual").mkdir(parents=True)
    d.joinpath("data.json").write_text(
        json.dumps(datos, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )
    for nombre in archivos:
        (d / "_manual" / nombre).write_bytes(b"")
    return d


# --- nombres(): el zero-padding no es cosmetica ---------------------------

def test_nombres_padding_de_tres():
    assert nombres(3) == ["p001.png", "p002.png", "p003.png"]


def test_nombres_crece_a_cuatro_digitos():
    n = nombres(1000)
    assert n[0] == "p0001.png" and n[-1] == "p1000.png"


def test_nombres_999_sigue_en_tres():
    n = nombres(999)
    assert n[0] == "p001.png" and n[-1] == "p999.png"


def test_nombres_orden_alfabetico_es_el_orden_real():
    # El motivo entero del padding (ADR-0007): el theme ordena por nombre.
    for total in (9, 10, 11, 100, 101, 1000):
        n = nombres(total)
        assert sorted(n) == n, total


def test_nombres_pdf_vacio_es_error():
    with pytest.raises(RasterizeError):
        nombres(0)


# --- resolver_indice(): cual documento le toca a esta corrida (ADR-0023) --

def test_resolver_indice_un_documento_sin_label():
    assert resolver_indice({"manual": [{"file": "m.pdf"}]}, None) == 0


def test_resolver_indice_dos_documentos_sin_label_es_error():
    datos = {"manual": [{"label": "Uso", "file": "a.pdf"}, {"label": "Servicio", "file": "b.pdf"}]}
    with pytest.raises(RasterizeError, match="2 manuales"):
        resolver_indice(datos, None)


def test_resolver_indice_dos_documentos_con_label():
    datos = {"manual": [{"label": "Uso", "file": "a.pdf"}, {"label": "Servicio", "file": "b.pdf"}]}
    assert resolver_indice(datos, "Servicio") == 1


def test_resolver_indice_label_que_no_existe_es_error():
    datos = {"manual": [{"label": "Uso", "file": "a.pdf"}]}
    with pytest.raises(RasterizeError, match="no hay un manual"):
        resolver_indice(datos, "Servicio")


def test_resolver_indice_sin_manual_es_error():
    with pytest.raises(RasterizeError):
        resolver_indice({}, None)


def test_resolver_indice_manual_objeto_suelto_es_error():
    # La forma vieja, pre-0023 - no se interpreta, error explicito.
    with pytest.raises(RasterizeError):
        resolver_indice({"manual": {"file": "m.pdf"}}, None)


# --- dir_documento(): un subdirectorio por documento cuando hay mas de uno -

def test_dir_documento_un_solo_documento_es_la_raiz(tmp_path):
    # Cero migracion: con un documento, sigue en _manual/ sin subcarpeta.
    assert dir_documento(tmp_path, 0, 1) == tmp_path


def test_dir_documento_varios_usa_subcarpeta_por_indice(tmp_path):
    # Sin esto, dos documentos con su propio p001.png se pisarian entre si.
    assert dir_documento(tmp_path, 0, 2) == tmp_path / "manual-0"
    assert dir_documento(tmp_path, 1, 2) == tmp_path / "manual-1"


# --- paginas_a_data(): el test que mas importa ----------------------------

def test_paginas_a_data_no_pierde_ninguna_clave():
    # El modo de falla temido no es un JSON roto -eso se ve enseguida- sino una
    # clave que desaparece en silencio y no se nota hasta abrir el gabinete.
    datos = {
        "accent": "#ff5a3c",
        "accent2": "#4d150b",
        "mags": [{"ref": "hobby-consolas-01"}],
        "cheats": {"combos": [{"name": "Hadouken", "input": "↓ ↘ → P"}]},
        "review": {"score": 94, "cats": {"graficos": 92}},
        "manual": [{"file": "manual.pdf"}],
    }
    salida = paginas_a_data(datos, 0, ["p001.png"])

    for clave in ("accent", "accent2", "mags", "cheats", "review"):
        assert salida[clave] == datos[clave], clave


def test_paginas_a_data_conserva_manual_file():
    # El PDF no se borra al rasterizar: sigue siendo el fallback de ADR-0021.
    salida = paginas_a_data({"manual": [{"file": "manual.pdf"}]}, 0, ["p001.png"])
    assert salida["manual"][0]["file"] == "manual.pdf"
    assert salida["manual"][0]["pages"] == ["p001.png"]


def test_paginas_a_data_no_toca_los_otros_documentos():
    # El invariante central de la 014: rasterizar un documento no pisa a los
    # demas de la lista - ni sus paginas, ni su label, ni su file.
    datos = {
        "manual": [
            {"label": "Uso", "file": "a.pdf", "pages": ["viejo.png"]},
            {"label": "Servicio", "file": "b.pdf"},
        ]
    }
    salida = paginas_a_data(datos, 1, ["manual-1/p001.png"])

    assert salida["manual"][0] == datos["manual"][0]
    assert salida["manual"][1]["pages"] == ["manual-1/p001.png"]
    assert salida["manual"][1]["file"] == "b.pdf"
    assert salida["manual"][1]["label"] == "Servicio"


def test_paginas_a_data_no_muta_la_entrada():
    datos = {"manual": [{"file": "manual.pdf"}]}
    paginas_a_data(datos, 0, ["p001.png"])
    assert "pages" not in datos["manual"][0]


def test_paginas_a_data_reemplaza_las_paginas_viejas():
    datos = {"manual": [{"file": "m.pdf", "pages": ["viejo1.png", "viejo2.png"]}]}
    salida = paginas_a_data(datos, 0, ["p001.png"])
    assert salida["manual"][0]["pages"] == ["p001.png"]


def test_paginas_a_data_sin_manual_es_error():
    with pytest.raises(RasterizeError):
        paginas_a_data({"accent": "#ffffff"}, 0, ["p001.png"])


def test_paginas_a_data_indice_fuera_de_rango_es_error():
    with pytest.raises(RasterizeError):
        paginas_a_data({"manual": [{"file": "a.pdf"}]}, 5, ["p001.png"])


# --- pdf_declarado(): la entrada es el contrato de la 012/023 -------------

def test_pdf_declarado_lee_manual_file():
    assert pdf_declarado({"manual": [{"file": "manual.pdf"}]}, 0) == "manual.pdf"


def test_pdf_declarado_del_documento_correcto():
    datos = {"manual": [{"file": "a.pdf"}, {"file": "b.pdf"}]}
    assert pdf_declarado(datos, 1) == "b.pdf"


def test_pdf_declarado_sin_file_explica_que_falta():
    with pytest.raises(RasterizeError, match="'file'"):
        pdf_declarado({"manual": [{"pages": ["p001.png"]}]}, 0)


def test_pdf_declarado_sin_manual_es_error():
    with pytest.raises(RasterizeError):
        pdf_declarado({}, 0)


# --- paginas_existentes(): solo reconoce lo que este comando genera -------

def test_paginas_existentes_ignora_lo_que_no_genero_el_comando(tmp_path):
    d = _media(
        tmp_path,
        {"manual": [{"file": "manual.pdf"}]},
        ["p001.png", "p002.png", "manual.pdf", "escaneo-suelto.png"],
    )
    # manual.pdf y el escaneo con nombre propio NO son nuestros: no se borran.
    assert paginas_existentes(d / "_manual") == ["p001.png", "p002.png"]


def test_paginas_existentes_dir_que_no_existe(tmp_path):
    assert paginas_existentes(tmp_path / "no-existe") == []


# --- aplicar(): errores, todos antes de tocar el disco --------------------

def test_aplicar_sin_data_json_es_error(tmp_path):
    (tmp_path / "media" / "sf2ce").mkdir(parents=True)
    with pytest.raises(RasterizeError, match="data.json"):
        aplicar(tmp_path / "media" / "sf2ce")


def test_aplicar_data_json_roto_es_error(tmp_path):
    d = tmp_path / "media" / "sf2ce"
    d.mkdir(parents=True)
    (d / "data.json").write_text("{ esto no es json", encoding="utf-8")
    with pytest.raises(RasterizeError, match="JSON invalido"):
        aplicar(d)


def test_aplicar_pdf_declarado_que_no_existe_es_error(tmp_path):
    d = _media(tmp_path, {"manual": [{"file": "manual.pdf"}]})
    with pytest.raises(RasterizeError, match="no existe el PDF"):
        aplicar(d)


def test_aplicar_sin_force_no_toca_nada(tmp_path):
    datos = {"manual": [{"file": "manual.pdf", "pages": ["p001.png"]}]}
    d = _media(tmp_path, datos, ["manual.pdf", "p001.png"])
    antes = (d / "data.json").read_text(encoding="utf-8")

    assert aplicar(d) == []
    assert (d / "data.json").read_text(encoding="utf-8") == antes


def test_aplicar_dos_documentos_sin_label_es_error(tmp_path):
    d = _media(
        tmp_path,
        {"manual": [{"label": "Uso", "file": "a.pdf"}, {"label": "Servicio", "file": "b.pdf"}]},
        ["a.pdf", "b.pdf"],
    )
    with pytest.raises(RasterizeError, match="2 manuales"):
        aplicar(d)


# --- punta a punta: lo unico que necesita PyMuPDF -------------------------

def _pdf_de(paginas: int) -> bytes:
    pymupdf = pytest.importorskip(
        "pymupdf", reason="pymupdf es una dependencia opcional (ADR-0022)"
    )
    doc = pymupdf.open()
    for i in range(paginas):
        doc.new_page().insert_text((72, 72), f"PAGINA {i + 1}")
    datos = doc.tobytes()
    doc.close()
    return datos


def test_rasteriza_de_punta_a_punta(tmp_path):
    datos = {"accent": "#ff5a3c", "manual": [{"file": "manual.pdf"}]}
    d = _media(tmp_path, datos)
    (d / "_manual" / "manual.pdf").write_bytes(_pdf_de(3))

    generadas = aplicar(d)

    assert generadas == ["p001.png", "p002.png", "p003.png"]
    for nombre in generadas:
        assert (d / "_manual" / nombre).stat().st_size > 0

    escrito = json.loads((d / "data.json").read_text(encoding="utf-8"))
    assert escrito["manual"][0]["pages"] == generadas
    assert escrito["manual"][0]["file"] == "manual.pdf"
    assert escrito["accent"] == "#ff5a3c"


def test_rasterizar_dos_veces_da_lo_mismo(tmp_path):
    d = _media(tmp_path, {"manual": [{"file": "manual.pdf"}]})
    (d / "_manual" / "manual.pdf").write_bytes(_pdf_de(2))

    aplicar(d)
    primera = (d / "data.json").read_text(encoding="utf-8")
    aplicar(d, force=True)

    assert (d / "data.json").read_text(encoding="utf-8") == primera
    assert paginas_existentes(d / "_manual") == ["p001.png", "p002.png"]


def test_force_borra_las_paginas_sobrantes_de_la_corrida_anterior(tmp_path):
    # Un manual re-escaneado con MENOS paginas. Sin esto quedan fantasmas que
    # nadie declara y que el visor nunca muestra.
    d = _media(
        tmp_path,
        {"manual": [{"file": "manual.pdf"}]},
        ["p001.png", "p002.png", "p003.png", "p004.png"],
    )
    (d / "_manual" / "manual.pdf").write_bytes(_pdf_de(2))

    aplicar(d, force=True)

    assert paginas_existentes(d / "_manual") == ["p001.png", "p002.png"]


def test_pdf_ilegible_no_deja_nada_a_medias(tmp_path):
    d = _media(tmp_path, {"manual": [{"file": "manual.pdf"}]})
    (d / "_manual" / "manual.pdf").write_bytes(b"esto no es un PDF")
    antes = (d / "data.json").read_text(encoding="utf-8")

    with pytest.raises(RasterizeError):
        aplicar(d)

    assert paginas_existentes(d / "_manual") == []
    assert (d / "data.json").read_text(encoding="utf-8") == antes


def test_el_data_json_escrito_pasa_doctor(tmp_path):
    # La integracion que importa: lo que este comando escribe tiene que ser
    # valido para el validador, no solo JSON bien formado.
    from attract.doctor import revisar

    d = _media(tmp_path, {"accent": "#ff5a3c", "manual": [{"file": "manual.pdf"}]})
    (d / "_manual" / "manual.pdf").write_bytes(_pdf_de(2))
    aplicar(d)

    assert revisar(tmp_path).ok


def test_dos_documentos_de_punta_a_punta_no_colisionan(tmp_path):
    # El caso real que motivo ADR-0023: dos documentos, cada uno con sus
    # propias paginas p001.png, en el MISMO _manual/. Sin dir_documento() el
    # segundo pisaria al primero.
    datos = {
        "manual": [
            {"label": "Manual de uso", "file": "uso.pdf"},
            {"label": "Manual de servicio", "file": "servicio.pdf"},
        ]
    }
    d = _media(tmp_path, datos)
    (d / "_manual" / "uso.pdf").write_bytes(_pdf_de(3))
    (d / "_manual" / "servicio.pdf").write_bytes(_pdf_de(2))

    gen_uso = aplicar(d, label="Manual de uso")
    gen_servicio = aplicar(d, label="Manual de servicio")

    # Con DOS documentos, los DOS van a subcarpeta propia (manual-<indice>/) -
    # no solo el segundo. Sin esto, "un solo documento es la raiz" (indice 0
    # con total=1) se confundiria con "el primero de varios" (indice 0, total=2).
    assert gen_uso == ["manual-0/p001.png", "manual-0/p002.png", "manual-0/p003.png"]
    assert gen_servicio == ["manual-1/p001.png", "manual-1/p002.png"]
    for nombre in gen_uso:
        assert (d / "_manual" / nombre).stat().st_size > 0
    for nombre in gen_servicio:
        assert (d / "_manual" / nombre).stat().st_size > 0

    escrito = json.loads((d / "data.json").read_text(encoding="utf-8"))
    assert escrito["manual"][0]["pages"] == gen_uso
    assert escrito["manual"][1]["pages"] == gen_servicio
    assert revisar_ok(tmp_path)


def revisar_ok(raiz: Path) -> bool:
    from attract.doctor import revisar

    return revisar(raiz).ok


# --- aislamiento: los modulos stdlib-only no arrastran pymupdf ------------
# Subproceso aparte, bloqueando 'pymupdf' en sys.modules ANTES de importar
# nada de attract - confirma que ningun import a nivel de modulo se filtra,
# este o no instalado en esta maquina. Mismo patron que test_mcp_server.

_SCRIPT_SIN_PYMUPDF = """
import sys
sys.modules["pymupdf"] = None
import attract.doctor
import attract.synopsis
import attract.ingest
import attract.cli
import attract.rasterize
print("IMPORTS_OK")
r = attract.rasterize.main(["sf2ce"])
print("MAIN_EXIT", r)
"""


def _correr_sin_pymupdf():
    return subprocess.run(
        [sys.executable, "-c", _SCRIPT_SIN_PYMUPDF],
        cwd=SRC.parent,
        env={"PYTHONPATH": str(SRC), "PATH": "/usr/bin:/bin"},
        capture_output=True,
        text=True,
        timeout=15,
    )


def test_modulos_importan_sin_pymupdf_instalado():
    resultado = _correr_sin_pymupdf()
    assert "IMPORTS_OK" in resultado.stdout, resultado.stderr
    assert "MAIN_EXIT 2" in resultado.stdout, resultado.stdout


def test_rasterize_sin_paquete_dice_como_instalarlo(tmp_path):
    # El mensaje llega al usuario recien cuando hay un PDF de verdad que abrir,
    # asi que se prueba la funcion directo con el import bloqueado.
    d = _media(tmp_path, {"manual": [{"file": "manual.pdf"}]})
    (d / "_manual" / "manual.pdf").write_bytes(b"%PDF-1.4\n")

    import attract.rasterize as r

    sys.modules["pymupdf"] = None
    try:
        with pytest.raises(RasterizeError, match="pip install pymupdf"):
            r.aplicar(d)
    finally:
        del sys.modules["pymupdf"]


# --- CLI: la ambiguedad label/ruta se resuelve mirando el disco -----------

def test_cli_un_argumento_extra_que_es_directorio_es_ruta(tmp_path):
    d = _media(tmp_path, {"manual": [{"file": "manual.pdf"}]})
    (d / "_manual" / "manual.pdf").write_bytes(b"%PDF-1.4\n")

    import attract.rasterize as r

    sys.modules["pymupdf"] = None
    try:
        # Si "ruta" no se interpretara como directorio, buscaria el set en
        # ./media/sf2ce (relativo a cwd) y fallaria con "no existe data.json"
        # en vez de con el mensaje de PyMuPDF - la prueba de que SI lo resolvio
        # como ruta es que el error es el de siempre, no uno de set inexistente.
        codigo = r.main(["sf2ce", str(tmp_path)])
        assert codigo == 2
    finally:
        del sys.modules["pymupdf"]


def test_cli_un_argumento_extra_que_no_es_directorio_es_label(tmp_path, monkeypatch):
    monkeypatch.chdir(tmp_path)
    d = _media(Path("."), {"manual": [{"label": "Uso", "file": "manual.pdf"}]})
    (d / "_manual" / "manual.pdf").write_bytes(b"%PDF-1.4\n")

    import attract.rasterize as r

    sys.modules["pymupdf"] = None
    try:
        # "Uso" no existe como directorio: se interpreta como label. Si el set
        # no se hubiera resuelto (label mal interpretado como ruta), aplicar()
        # fallaria mucho antes, con "no existe data.json".
        codigo = r.main(["sf2ce", "Uso"])
        assert codigo == 2      # llega hasta pedir pymupdf: la ruta/label se resolvieron bien
    finally:
        del sys.modules["pymupdf"]
