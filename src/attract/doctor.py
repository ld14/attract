"""
attract doctor - validador preflight.

Corre en el Mac ANTES de caminar hasta la maquina Windows.
Cada chequeo existe porque algo se rompio de verdad, o porque va a romperse.

Filosofia: todo lo que Windows rechazaria tiene que fallar aca.
Ningun chequeo necesita IA. Ninguno necesita Windows.
"""

from __future__ import annotations

import json
import re
import sys
import unicodedata
from dataclasses import dataclass, field
from pathlib import Path

# ---------------------------------------------------------------------------
# Reglas de Windows. No son opinables: son del sistema operativo.
# ---------------------------------------------------------------------------

WIN_CHARS_PROHIBIDOS = set('<>:"/\\|?*')

WIN_NOMBRES_RESERVADOS = (
    {"CON", "PRN", "AUX", "NUL"}
    | {f"COM{i}" for i in range(1, 10)}
    | {f"LPT{i}" for i in range(1, 10)}
)

# Basura que macOS siembra y que Pegasus levanta como si fueran juegos
BASURA_MACOS = re.compile(r"^(\._|\.DS_Store$|\.Spotlight-V100$|\.Trashes$)")

EXT_TEXTO = {".txt", ".qml", ".cfg", ".md", ".json", ".yml", ".yaml"}


@dataclass
class Hallazgo:
    nivel: str          # "ERROR" | "AVISO"
    chequeo: str
    ruta: str
    detalle: str


@dataclass
class Reporte:
    hallazgos: list[Hallazgo] = field(default_factory=list)
    archivos_vistos: int = 0
    chequeos_corridos: list[str] = field(default_factory=list)

    def error(self, chequeo: str, ruta, detalle: str) -> None:
        self.hallazgos.append(Hallazgo("ERROR", chequeo, str(ruta), detalle))

    def aviso(self, chequeo: str, ruta, detalle: str) -> None:
        self.hallazgos.append(Hallazgo("AVISO", chequeo, str(ruta), detalle))

    @property
    def errores(self) -> list[Hallazgo]:
        return [h for h in self.hallazgos if h.nivel == "ERROR"]

    @property
    def avisos(self) -> list[Hallazgo]:
        return [h for h in self.hallazgos if h.nivel == "AVISO"]

    @property
    def ok(self) -> bool:
        return not self.errores


# ---------------------------------------------------------------------------
# Chequeos
# ---------------------------------------------------------------------------

def chk_encoding(path: Path, rep: Reporte) -> None:
    """UTF-8 valido. Un solo byte invalido rompe el archivo ENTERO:
    el lector abandona la deteccion y cae a un encoding legacy.
    Ver: el byte 0x93 que arruino 800 lineas de M0."""
    raw = path.read_bytes()
    try:
        raw.decode("utf-8")
    except UnicodeDecodeError as e:
        ctx = raw[max(0, e.start - 30):e.start].decode("utf-8", "replace")
        rep.error(
            "encoding",
            path,
            f"byte invalido 0x{raw[e.start]:02X} en offset {e.start} "
            f"(...{ctx!r}). El archivo entero se va a leer como mojibake.",
        )


def chk_crlf(path: Path, rep: Reporte) -> None:
    """Pegasus prefiere LF. Si git te metio CRLF, revisa .gitattributes."""
    if b"\r\n" in path.read_bytes():
        rep.error("crlf", path, "tiene CRLF. Pegasus espera LF (\\n).")


def chk_nombre_windows(path: Path, rep: Reporte) -> None:
    """macOS acepta casi todo. Windows no.
    Esto NO falla en tu Mac. Solo explota al llegar al gabinete."""
    for parte in path.parts:
        if parte in ("/", "."):
            continue

        malos = sorted(WIN_CHARS_PROHIBIDOS & set(parte))
        if malos:
            rep.error(
                "nombre-windows", path,
                f"'{parte}' usa {' '.join(malos)} - prohibidos en Windows",
            )

        base = parte.split(".")[0].upper()
        if base in WIN_NOMBRES_RESERVADOS:
            rep.error(
                "nombre-windows", path,
                f"'{parte}' es un nombre reservado de Windows",
            )

        if parte.endswith(" ") or parte.endswith("."):
            rep.error(
                "nombre-windows", path,
                f"'{parte}' termina en espacio o punto - ilegal en Windows",
            )


def chk_nfc_nombre(path: Path, rep: Reporte) -> None:
    """macOS descompone (NFD), Windows precompone (NFC).
    'MICROMANIA' con tilde son 10 chars en Windows y 11 en macOS.
    git lo arregla con core.precomposeUnicode... pero solo en los NOMBRES."""
    s = str(path)
    if s != unicodedata.normalize("NFC", s):
        rep.error(
            "nfc-nombre", path,
            "el nombre esta en NFD (descompuesto). En Windows no va a matchear. "
            "Verifica: git config core.precomposeUnicode",
        )


def chk_basura_macos(path: Path, rep: Reporte) -> None:
    """Pegasus escanea por extension. '._mok.zip' termina en .zip."""
    if BASURA_MACOS.match(path.name):
        rep.error(
            "basura-macos", path,
            "archivo de macOS. Si llega al gabinete, Pegasus lo puede "
            "levantar como juego fantasma.",
        )


def chk_metadata(path: Path, rep: Reporte) -> None:
    """Chequeos especificos de metadata.pegasus.txt."""
    texto = path.read_text(encoding="utf-8")

    for n, linea in enumerate(texto.splitlines(), 1):
        if not linea.strip() or linea.lstrip().startswith("#"):
            continue

        # --- NFC en el CONTENIDO ---
        # git NO te salva aca: la ruta escrita adentro del archivo es texto,
        # no un nombre del indice. Si tu generador la emitio en NFD, queda NFD.
        if linea != unicodedata.normalize("NFC", linea):
            rep.error(
                "nfc-contenido", f"{path}:{n}",
                f"linea en NFD: {linea.strip()[:60]!r}. "
                "En Windows no va a resolver el archivo. Normaliza al emitir.",
            )

        # --- separadores ---
        if linea.startswith("assets.") and "\\" in linea:
            rep.aviso(
                "separador", f"{path}:{n}",
                "usa '\\'. Windows acepta '/' tambien - usa '/' en todos lados.",
            )

        # --- los assets apuntan a algo real ---
        m = re.match(r"^(assets\.[a-zA-Z_]+)\s*:\s*(.+)$", linea)
        if m:
            valor = m.group(2).strip()
            if not valor.startswith(("http://", "https://")):
                destino = (path.parent / valor).resolve()
                if not destino.exists():
                    rep.error(
                        "asset-faltante", f"{path}:{n}",
                        f"{m.group(1)} apunta a '{valor}' y no existe",
                    )


def chk_json_valido(path: Path, rep: Reporte) -> None:
    """data.json y magazine.json tienen que ser JSON sintacticamente valido.
    Hoy un JSON roto pasa el doctor sin aviso y explota recien en el theme
    (docs/CONVENCION.md #4.4, "falta")."""
    try:
        json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        rep.error("json-invalido", path, f"JSON invalido: {e}")


def magazines_root_de(data_json: Path) -> Path:
    """<raiz>/_magazines/ a partir de un data.json.

    Las revistas no cuelgan de ningun sistema (ADR-0024): la misma revista
    cubre juegos de arcade, NES y PC, asi que vive un nivel arriba de las
    colecciones. La convencion es fija:

        <raiz>/<sistema>/media/<set>/data.json  ->  <raiz>/_magazines/

    Son 4 niveles. Se resuelve desde el data.json y no desde la raiz del
    escaneo, asi que `attract doctor library` y `attract doctor library/arcade`
    dan lo mismo. Si la ruta es mas corta que la convencion (un data.json
    suelto), se devuelve lo que haya: el llamador ya reporta que no existe.
    """
    padres = data_json.parents
    return (padres[3] if len(padres) > 3 else padres[-1]) / "_magazines"


def chk_mags_ref(path: Path, rep: Reporte) -> None:
    """mags[].ref de un data.json deberia apuntar a una carpeta real en
    <raiz>/_magazines/<ref>/. Es AVISO, no ERROR: la degradacion con un ref
    colgado es un caso soportado a proposito (ver fixtures/arcade/media/sf2ce/,
    ADR-0008) - no bloquea el viaje a Windows, pero vale la pena que se note."""
    try:
        datos = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return  # ya lo reporto chk_json_valido

    if not isinstance(datos, dict):
        return

    for mag in datos.get("mags") or []:
        ref = mag.get("ref") if isinstance(mag, dict) else None
        if not ref:
            continue
        destino = magazines_root_de(path) / ref
        if not destino.is_dir():
            rep.aviso(
                "mags-ref-faltante", path,
                f"mags[].ref='{ref}' -> {destino} no existe (degradacion esperada, no error)",
            )


HEX_COLOR = re.compile(r"^#[0-9a-fA-F]{6}$")

# Las seis fijadas en docs/CONVENCION.md #2.1 nota 3, en minuscula y sin
# tildes: las etiquetas que se ven en pantalla las pone el theme, no los datos.
REVIEW_CATS_CONOCIDAS = {
    "originalidad", "graficos", "adiccion",
    "sonido", "dificultad", "animacion",
}


def _chk_manual_doc(doc, i: int, path: Path, falla) -> None:
    """Un elemento de la lista `manual` (ADR-0023). Misma forma que el
    `manual` objeto de antes de esta ADR: `pages`/`file`, al menos uno."""
    prefijo = f"manual[{i}]"

    if not isinstance(doc, dict):
        falla(prefijo, "tiene que ser un objeto")
        return
    if "pages" not in doc and "file" not in doc:
        falla(prefijo, "tiene que traer 'pages', 'file', o las dos")
        return

    if "pages" in doc:
        pages = doc["pages"]
        if not isinstance(pages, list) or not all(isinstance(p, str) for p in pages):
            falla(f"{prefijo}.pages", "si esta, lista de strings")
        else:
            # Una pagina declarada que no esta en el disco deja un hueco en el
            # visor. Se chequea aca y no en el theme porque el theme no puede
            # hacer nada al respecto a esa altura.
            for nombre in pages:
                if not (path.parent / "_manual" / nombre).is_file():
                    falla(
                        f"{prefijo}.pages",
                        f"'{nombre}' no existe en {path.parent / '_manual'}",
                    )

    if "file" in doc:
        pdf = doc["file"]
        if not isinstance(pdf, str) or not pdf.strip():
            falla(f"{prefijo}.file", "si esta, string no vacio")
        elif "/" in pdf or "\\" in pdf:
            # Es un NOMBRE de archivo dentro de _manual/, no una ruta. Sin
            # separadores no hay traversal posible, y ademas el theme lo
            # concatena a media/<set>/_manual/ tal cual.
            falla(f"{prefijo}.file", f"tiene que ser un nombre suelto, sin rutas: {pdf!r}")
        elif not pdf.lower().endswith(".pdf"):
            # El theme se lo pasa al sistema operativo sin mirarlo: la
            # extension es lo unico que decide con que se abre.
            falla(f"{prefijo}.file", f"tiene que terminar en '.pdf', llego {pdf!r}")
        elif not (path.parent / "_manual" / pdf).is_file():
            falla(f"{prefijo}.file", f"'{pdf}' no existe en {path.parent / '_manual'}")


def chk_data_contrato(path: Path, rep: Reporte) -> None:
    """Valida el contrato de data.json mas alla de sintaxis JSON (ADR-0015).

    TODOS los campos son opcionales: un juego sin data.json, o con uno que
    solo trae 'mags', es valido. Lo que se valida es la forma de lo que SI
    esta - un accent mal escrito no rompe el archivo, deja al juego sin color
    y no se nota hasta mirar el gabinete."""
    try:
        datos = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return  # ya lo reporto chk_json_valido

    if not isinstance(datos, dict):
        rep.error("data-contrato", path, "se esperaba un objeto JSON")
        return

    def falla(campo: str, motivo: str) -> None:
        rep.error("data-contrato", path, f"'{campo}': {motivo}")

    # --- accent / accent2 (ADR-0013) ---
    for campo in ("accent", "accent2"):
        val = datos.get(campo)
        if val is None:
            continue
        if not isinstance(val, str) or not HEX_COLOR.match(val):
            falla(campo, f"tiene que ser un hex '#rrggbb', llego {val!r}")

    # --- mags: la lista de referencias. Que el ref EXISTA lo mira chk_mags_ref ---
    #
    # `article` es OPCIONAL: el slug de `articles[].game` que trata sobre este
    # juego (ADR-0025). Lo escribe `attract mags` porque el slug editorial de
    # la revista ("golden-axe") no es el set de Pegasus ("goldnaxe"), y sin el
    # el theme no puede encontrar la nota. Si falta, el theme busca por el set,
    # que es lo correcto cuando los dos coinciden.
    mags = datos.get("mags")
    if mags is not None:
        if not isinstance(mags, list):
            falla("mags", "tiene que ser una lista")
        else:
            for i, mag in enumerate(mags):
                if not isinstance(mag, dict) or not isinstance(mag.get("ref"), str) or not mag["ref"].strip():
                    falla(f"mags[{i}]", "tiene que ser un objeto con 'ref' string no vacio")
                    continue
                art = mag.get("article")
                if art is not None and (not isinstance(art, str) or not art.strip()):
                    falla(f"mags[{i}].article", "si esta presente tiene que ser string no vacio")

    # --- manual (ADR-0014/0021, lista de documentos por ADR-0023) ---
    #
    # `manual` es una LISTA de documentos, no un objeto - un juego real puede
    # tener mas de uno (manual de uso, de servicio, otro idioma; "multivariado",
    # sin un par cerrado de categorias). Cada documento tiene la forma que
    # `manual` tenia antes de ADR-0023, y ademas puede traer `label`:
    #
    #     "pages": ["p001.png", ...]   paginas escaneadas, las hojea el visor
    #     "file":  "manual.pdf"        el PDF, lo abre la app del sistema
    #     "label": "Manual de uso"     obligatorio solo si hay mas de un documento
    #
    # Un objeto suelto (la forma vieja, pre-0023) es error explicito y no se
    # interpreta - dos formas validas para lo mismo es peor que un mensaje claro
    # con la migracion de una linea (envolver en `[...]`).
    manual = datos.get("manual")
    if manual is not None:
        if isinstance(manual, dict):
            falla(
                "manual",
                "tiene que ser una lista de documentos, no un objeto suelto "
                "(ADR-0023) - envolvelo en []",
            )
        elif not isinstance(manual, list) or not manual:
            falla("manual", "tiene que ser una lista no vacia de documentos")
        else:
            labels_vistos: set[str] = set()
            for i, doc in enumerate(manual):
                _chk_manual_doc(doc, i, path, falla)
                if len(manual) > 1 and isinstance(doc, dict):
                    label = doc.get("label")
                    if not isinstance(label, str) or not label.strip():
                        falla(f"manual[{i}].label", "obligatorio si hay mas de un documento")
                    elif label.strip() in labels_vistos:
                        falla(f"manual[{i}].label", f"repetido: {label.strip()!r}")
                    else:
                        labels_vistos.add(label.strip())

    # --- cheats (ADR-0020, extiende ADR-0015) ---
    #
    # El nombre del grupo es LIBRE: ya no se validan solo "combos" y "codes".
    # Cada grupo puede venir de dos formas, y las dos se validan igual por
    # dentro:
    #
    #     "combos":   [ {name, input} ]
    #     "secretos": { "label": "...", "items": [ {name, input} ] }
    #
    # Que la clave sea libre NO significa que cualquier cosa pase: el modo de
    # falla que esto evita es el que se vio el 2026-08-09 — 8 entradas
    # escritas bajo claves que nadie leia, con doctor en verde y la pantalla
    # sin mostrarlas. Ahora una forma que el theme no sabe dibujar falla acá.
    cheats = datos.get("cheats")
    if cheats is not None:
        if not isinstance(cheats, dict):
            falla("cheats", "tiene que ser un objeto")
        else:
            for grupo, valor in cheats.items():
                if isinstance(valor, list):
                    items = valor
                elif isinstance(valor, dict):
                    if "items" not in valor:
                        falla(f"cheats.{grupo}", "objeto sin 'items'")
                        continue
                    items = valor["items"]
                    if not isinstance(items, list):
                        falla(f"cheats.{grupo}.items", "tiene que ser una lista")
                        continue
                    etiqueta = valor.get("label")
                    if etiqueta is not None and (
                        not isinstance(etiqueta, str) or not etiqueta.strip()
                    ):
                        falla(f"cheats.{grupo}.label", "si esta, string no vacio")
                else:
                    falla(
                        f"cheats.{grupo}",
                        "tiene que ser una lista, o un objeto con 'items'",
                    )
                    continue

                for i, item in enumerate(items):
                    prefijo = f"cheats.{grupo}[{i}]"
                    if not isinstance(item, dict):
                        falla(prefijo, "tiene que ser un objeto")
                        continue
                    for campo in ("name", "input"):
                        if not isinstance(item.get(campo), str) or not item[campo].strip():
                            falla(f"{prefijo}.{campo}", "obligatorio, string no vacio")

    # --- review (ADR-0015 + CONVENCION #2.1 nota 3) ---
    review = datos.get("review")
    if review is not None:
        if not isinstance(review, dict):
            falla("review", "tiene que ser un objeto o null")
            return

        score = review.get("score")
        if score is not None and not _numero_0_100(score):
            falla("review.score", f"tiene que ser un number entre 0 y 100, llego {score!r}")

        if review.get("verdict") is not None and not isinstance(review["verdict"], str):
            falla("review.verdict", "si esta presente tiene que ser string")

        cats = review.get("cats")
        if cats is not None:
            if not isinstance(cats, dict):
                # Objeto, no lista de pares: es lo que permite expresar una
                # resena parcial sin ambiguedad (ADR-0015).
                falla("review.cats", "tiene que ser un objeto {categoria: valor}")
            else:
                for clave, val in cats.items():
                    if clave not in REVIEW_CATS_CONOCIDAS:
                        rep.aviso(
                            "data-contrato", path,
                            f"review.cats['{clave}'] no es de las seis conocidas "
                            f"({', '.join(sorted(REVIEW_CATS_CONOCIDAS))}) - "
                            "el theme la va a ignorar",
                        )
                        continue
                    if not _numero_0_100(val):
                        falla(
                            f"review.cats['{clave}']",
                            f"tiene que ser un number entre 0 y 100, llego {val!r}",
                        )


def _numero_0_100(v) -> bool:
    return isinstance(v, (int, float)) and not isinstance(v, bool) and 0 <= v <= 100


MAGAZINE_TYPES_CONOCIDOS = {
    "publicidad", "indice", "índice", "review", "noticia",
    "entrevista", "especial", "hardware", "preview",
    "guia", "guía",
}

_NUMERO_PAGINA = re.compile(r"(\d+)")


def numeros_de_pagina(pages) -> set[int]:
    """Los numeros de pagina IMPRESA que declara pages[], sacados del nombre
    de cada archivo: "p046.jpg" -> 46 (ADR-0024).

    No es 1..len(pages). Una revista real arranca en "p002.jpg" -la pagina 1
    es la tapa y vive aparte en cover.jpg- asi que contar posiciones corre
    todo un lugar y hace que la ultima pagina parezca fuera de rango.
    """
    out = set()
    for p in pages:
        if not isinstance(p, str):
            continue
        m = _NUMERO_PAGINA.search(p)
        if m:
            out.add(int(m.group(1)))
    return out


def chk_magazine_contrato(path: Path, rep: Reporte) -> None:
    """Valida el contrato de magazine.json mas alla de sintaxis JSON:
    campos obligatorios, tipos, rango de confidence (ADR-0024)."""
    try:
        datos = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return  # ya lo reporto chk_json_valido

    if not isinstance(datos, dict):
        rep.error("magazine-contrato", path, "se esperaba un objeto JSON")
        return

    def falla(campo: str, motivo: str) -> None:
        rep.error("magazine-contrato", path, f"'{campo}': {motivo}")

    if not isinstance(datos.get("name"), str) or not datos["name"].strip():
        falla("name", "obligatorio, string no vacio")
    if not isinstance(datos.get("cover"), str) or not datos["cover"].strip():
        falla("cover", "obligatorio, string no vacio")
    if not isinstance(datos.get("key_id"), str) or not datos["key_id"].strip():
        falla("key_id", "obligatorio, string no vacio")

    pages = datos.get("pages")
    if not isinstance(pages, list) or not all(isinstance(p, str) for p in pages):
        falla("pages", "obligatorio, lista de strings")

    for campo_opc in ("issue", "color"):
        val = datos.get(campo_opc)
        if val is not None and not isinstance(val, str):
            falla(campo_opc, "tiene que ser string o null")

    year = datos.get("year")
    if year is not None and not (isinstance(year, int) and not isinstance(year, bool)):
        falla("year", "tiene que ser number o null")

    articles = datos.get("articles")
    if not isinstance(articles, list):
        falla("articles", "obligatorio, lista")
        return

    # Los NUMEROS DE PAGINA IMPRESA que la revista realmente tiene, sacados
    # del nombre de cada archivo (ADR-0024). No es 1..len(pages): una revista
    # real arranca en "p002.jpg" porque la pagina 1 es la tapa y vive aparte
    # en cover.jpg, asi que contar posiciones da un corrimiento y falsos
    # "fuera de rango" al final. Si pages estaba mal ya se reporto arriba;
    # aca queda vacio para no encadenar errores confusos.
    numeros = numeros_de_pagina(pages) if isinstance(pages, list) else set()
    rango = f"{min(numeros)} a {max(numeros)}" if numeros else "(sin paginas)"

    for i, art in enumerate(articles):
        prefijo = f"articles[{i}]"
        if not isinstance(art, dict):
            rep.error("magazine-contrato", path, f"{prefijo}: tiene que ser un objeto")
            continue

        tipo = art.get("type")
        if not isinstance(tipo, str) or not tipo.strip():
            rep.error(
                "magazine-contrato", path,
                f"{prefijo}.type: obligatorio, string no vacio",
            )
        elif tipo not in MAGAZINE_TYPES_CONOCIDOS:
            rep.aviso(
                "magazine-contrato", path,
                f"{prefijo}.type='{tipo}' no es de los conocidos "
                f"({', '.join(sorted(MAGAZINE_TYPES_CONOCIDOS))}) - "
                "el enum no es cerrado (ADR-0024), puede ser valido igual",
            )

        for campo_str_opc in ("game", "title"):
            val = art.get(campo_str_opc)
            if val is not None and not isinstance(val, str):
                rep.error(
                    "magazine-contrato", path,
                    f"{prefijo}.{campo_str_opc}: si esta presente tiene que ser string",
                )

        # startPage y articles[].pages apuntan a una pagina que la revista
        # tiene que TENER. Un articulo que apunta a una pagina inexistente
        # pasaba el validador y se veia recien en el visor del theme, que es
        # el peor lugar para enterarse.
        sp = art.get("startPage")
        if not isinstance(sp, int) or isinstance(sp, bool):
            rep.error(
                "magazine-contrato", path,
                f"{prefijo}.startPage: obligatorio, number",
            )
        elif numeros and sp not in numeros:
            rep.error(
                "magazine-contrato", path,
                f"{prefijo}.startPage={sp} no es una pagina de esta revista: "
                f"pages[] va de {rango}",
            )

        art_pages = art.get("pages")
        if not isinstance(art_pages, list) or not all(
            isinstance(p, int) and not isinstance(p, bool) for p in art_pages
        ):
            rep.error(
                "magazine-contrato", path,
                f"{prefijo}.pages: obligatorio, lista de numbers",
            )
        elif numeros:
            fuera = [n for n in art_pages if n not in numeros]
            if fuera:
                rep.error(
                    "magazine-contrato", path,
                    f"{prefijo}.pages apunta a paginas que esta revista no "
                    f"tiene: {fuera} (pages[] va de {rango})",
                )

        conf = art.get("confidence")
        if (
            not isinstance(conf, (int, float))
            or isinstance(conf, bool)
            or not (0.0 <= conf <= 1.0)
        ):
            rep.error(
                "magazine-contrato", path,
                f"{prefijo}.confidence: obligatorio, number entre 0.0 y 1.0",
            )

        for flag in ("cheats", "walkthrough", "tips"):
            if flag in art and not isinstance(art[flag], bool):
                rep.error(
                    "magazine-contrato", path,
                    f"{prefijo}.{flag}: si esta presente tiene que ser boolean",
                )


def chk_magazine_assets(path: Path, rep: Reporte) -> None:
    """Cada entrada de pages[] y el cover tienen que existir en el disco.

    Las paginas viven en <rev>/pages/ y el cover en la raiz de la revista
    (ADR-0024). Un nombre que no resuelve no rompe nada en el validador ni
    tira ninguna excepcion: el sintoma es una pagina en blanco en el visor,
    que es el peor lugar para enterarse. Por eso es ERROR y no aviso - es
    exactamente la clase de cosa que doctor existe para adelantar.

    Se reportan hasta 5 paginas faltantes y despues el conteo: una revista
    con la carpeta pages/ mal armada tiene TODAS mal, y 63 lineas iguales
    tapan el resto del reporte.
    """
    try:
        datos = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return  # ya lo reporto chk_json_valido

    if not isinstance(datos, dict):
        return

    rev = path.parent

    cover = datos.get("cover")
    if isinstance(cover, str) and cover.strip() and not (rev / cover).is_file():
        rep.error("magazine-assets", path, f"cover '{cover}' no existe en {rev}")

    pages = datos.get("pages")
    if not isinstance(pages, list):
        return  # ya lo reporto chk_magazine_contrato

    faltan = [p for p in pages if isinstance(p, str) and not (rev / "pages" / p).is_file()]
    if not faltan:
        return

    for nombre in faltan[:5]:
        rep.error(
            "magazine-assets", path,
            f"pages[] declara '{nombre}' pero no existe {rev / 'pages' / nombre}",
        )
    if len(faltan) > 5:
        rep.error(
            "magazine-assets", path,
            f"...y {len(faltan) - 5} paginas mas ({len(faltan)} de {len(pages)} faltan). "
            "Las paginas van en <revista>/pages/ (ADR-0024)",
        )


# ---------------------------------------------------------------------------
# Runner
# ---------------------------------------------------------------------------

CHEQUEOS_UNIVERSALES = [
    ("encoding",       chk_encoding,      True),
    ("crlf",           chk_crlf,          True),
    ("nombre-windows", chk_nombre_windows, False),
    ("nfc-nombre",     chk_nfc_nombre,    False),
    ("basura-macos",   chk_basura_macos,  False),
]


def revisar(raiz: Path, target: str = "windows") -> Reporte:
    rep = Reporte()
    rep.chequeos_corridos = [n for n, _, _ in CHEQUEOS_UNIVERSALES] + [
        "metadata", "json-valido", "mags-ref", "magazine-contrato",
        "magazine-assets", "data-contrato",
    ]

    if not raiz.exists():
        rep.error("ruta", raiz, "no existe")
        return rep

    for path in sorted(raiz.rglob("*")):
        if any(p in path.parts for p in (".git", ".venv", "__pycache__", ".pytest_cache", "node_modules")):
            continue
        if not path.is_file():
            continue

        rep.archivos_vistos += 1
        rel = path.relative_to(raiz)

        for _, fn, solo_texto in CHEQUEOS_UNIVERSALES:
            if solo_texto and path.suffix.lower() not in EXT_TEXTO:
                continue
            try:
                fn(rel if fn in (chk_nombre_windows, chk_nfc_nombre, chk_basura_macos) else path, rep)
            except Exception as e:  # noqa: BLE001
                rep.aviso("interno", path, f"{fn.__name__}: {e}")

        if path.name.endswith(".pegasus.txt"):
            try:
                chk_metadata(path, rep)
            except UnicodeDecodeError:
                pass  # ya lo reporto chk_encoding

        if path.name in ("data.json", "magazine.json"):
            try:
                chk_json_valido(path, rep)
            except UnicodeDecodeError:
                pass  # ya lo reporto chk_encoding

        if path.name == "data.json":
            try:
                chk_mags_ref(path, rep)
                chk_data_contrato(path, rep)
            except UnicodeDecodeError:
                pass  # ya lo reporto chk_encoding

        if path.name == "magazine.json":
            try:
                chk_magazine_contrato(path, rep)
                chk_magazine_assets(path, rep)
            except UnicodeDecodeError:
                pass  # ya lo reporto chk_encoding

    return rep


def imprimir(rep: Reporte, raiz: Path, target: str) -> None:
    print()
    print(f"  attract doctor --target {target}")
    print(f"  {raiz}")
    print("  " + "-" * 62)
    print(f"  {rep.archivos_vistos} archivos revisados")
    print(f"  chequeos: {', '.join(rep.chequeos_corridos)}")
    print()

    if not rep.hallazgos:
        print("  OK - nada que reportar. Podes ir al gabinete.")
        print()
        return

    por_chequeo: dict[str, list[Hallazgo]] = {}
    for h in rep.hallazgos:
        por_chequeo.setdefault(h.chequeo, []).append(h)

    for chequeo, hs in por_chequeo.items():
        marca = "ERROR" if hs[0].nivel == "ERROR" else "AVISO"
        print(f"  [{marca}] {chequeo}  ({len(hs)})")
        for h in hs[:8]:
            print(f"      {h.ruta}")
            print(f"        {h.detalle}")
        if len(hs) > 8:
            print(f"      ... y {len(hs) - 8} mas")
        print()

    print("  " + "-" * 62)
    print(f"  {len(rep.errores)} errores, {len(rep.avisos)} avisos")
    if rep.errores:
        print("  NO viajes a Windows todavia.")
    print()


def main(argv: list[str] | None = None) -> int:
    argv = argv if argv is not None else sys.argv[1:]

    raiz = Path(".")
    target = "windows"
    args = list(argv)
    while args:
        a = args.pop(0)
        if a == "--target":
            target = args.pop(0) if args else "windows"
        elif not a.startswith("-"):
            raiz = Path(a)

    rep = revisar(raiz.resolve(), target)
    imprimir(rep, raiz.resolve(), target)
    return 0 if rep.ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
