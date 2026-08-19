"""
attract mags - linkea cada revista con los juegos instalados que aparecen en
ella (ADR-0025).

POR QUE EXISTE: la relacion revista-juego se declara en las dos puntas y en
archivos distintos. La revista dice de que juegos habla
(`magazine.json -> articles[].game`); el juego dice en que revistas aparece
(`data.json -> mags[{ref}]`, ADR-0001). La primera punta la escribe el
subsistema de escaneo (ADR-0009); la segunda se escribia a mano. Con
`micromania-34` -20 articulos con `game`- eso son hasta 20 `data.json` que
abrir para agregar el mismo `ref`.

EL PROBLEMA DURO es que los dos lados no usan el mismo identificador:

    revista:  "golden-axe"   <- slug editorial del generador
    Pegasus:  "goldnaxe"     <- set de MAME (ADR-0004)

No es formato. Normalizar da "goldenaxe" contra "goldnaxe": al set le falta
una `e`, porque los nombres de set de MAME son abreviaturas historicas de 8
caracteres (`sf2ce`, `mok`, `goldnaxe`), no slugs derivados del titulo.
Ninguna regla deterministica los une, asi que se compara con `difflib`
(stdlib - no toca el limite de dependencias de tech-stack.md).

EL UMBRAL no es una suposicion. Medido con los 20 slugs de `micromania-34`
contra los sets instalados: el match correcto da 0.94 y el falso candidato mas
alto 0.43. Un orden de magnitud de separacion; 0.85 cae holgado en el medio.

LA FRONTERA: este modulo NUNCA sobrescribe. Sin `--apply` no toca ningun
archivo, solo reporta. Con `--apply` mergea el `ref` en `mags[]` conservando
todo lo demas del `data.json`, que es un archivo escrito a mano y sigue
siendo de su autor. Correrlo dos veces no duplica nada.
"""
import difflib
import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path

from attract.synopsis import identificar_set, parsear_bloques

UMBRAL_DEFECTO = 0.85

_NO_ALFANUM = re.compile(r"[^a-z0-9]+")


def normalizar(s: str) -> str:
    """Minusculas y solo alfanumericos: "Golden Axe (set 6, US)" -> golden axe
    sin espacios ni parentesis. Es el piso comun sobre el que compara difflib,
    no el match en si."""
    return _NO_ALFANUM.sub("", s.lower())


# ---------------------------------------------------------------------------
# Lo que hay en el disco
# ---------------------------------------------------------------------------

@dataclass(frozen=True)
class Juego:
    """Un juego instalado, con las dos formas de nombrarlo que sirven para
    matchear: el set (ADR-0004) y el titulo del bloque `game:`."""
    set_id: str
    titulo: str
    sistema: Path       # <raiz>/<sistema>/

    @property
    def data_json(self) -> Path:
        return self.sistema / "media" / self.set_id / "data.json"


@dataclass
class Match:
    slug: str
    juego: Juego | None
    ratio: float
    via: str            # "set" | "titulo" | ""


def juegos_instalados(raiz: Path) -> list[Juego]:
    """Todos los juegos de todos los sistemas de la libreria.

    Reusa el parser de `attract synopsis` en vez de escribir un segundo
    lector de metadata.pegasus.txt: es el mismo formato y ya tiene resuelto
    lo unico dificil (que el set sale de x-set o del file: sin extension).
    """
    juegos: list[Juego] = []
    for metadata in sorted(raiz.glob("*/metadata.pegasus.txt")):
        texto = metadata.read_text(encoding="utf-8")
        for bloque in parsear_bloques(texto):
            if not bloque.es_game:
                continue
            set_id = identificar_set(bloque)
            if not set_id:
                continue
            titulo = bloque.lineas[0][len("game:"):].strip()
            juegos.append(Juego(set_id=set_id, titulo=titulo, sistema=metadata.parent))
    return juegos


def slugs_de_revista(magazine_json: Path) -> list[str]:
    """Los `articles[].game` de una revista, sin repetir y en orden estable.

    Los articulos sin `game` (publicidad, indice, noticias generales) no
    tratan sobre un juego puntual y se ignoran - es parte del contrato
    (ADR-0024), no un dato faltante.
    """
    try:
        datos = json.loads(magazine_json.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, UnicodeDecodeError):
        return []
    if not isinstance(datos, dict):
        return []

    vistos: dict[str, None] = {}
    for art in datos.get("articles") or []:
        if isinstance(art, dict):
            g = art.get("game")
            if isinstance(g, str) and g.strip():
                vistos.setdefault(g.strip(), None)
    return list(vistos)


# ---------------------------------------------------------------------------
# Matching
# ---------------------------------------------------------------------------

def mejor_match(slug: str, juegos: list[Juego], umbral: float) -> Match:
    """El juego instalado que mejor se parece a `slug`, o None.

    Se compara contra DOS candidatos por juego -el set y el titulo- porque
    ninguno gana siempre: "golden-axe" se parece al set `goldnaxe` (0.94) y
    no tanto al titulo completo con la variante de MAME pegada atras
    ("Golden Axe (set 6, US) (8751 317-123A)", 0.51).
    """
    objetivo = normalizar(slug)
    mejor = Match(slug=slug, juego=None, ratio=0.0, via="")

    for juego in juegos:
        for candidato, via in ((juego.set_id, "set"), (juego.titulo, "titulo")):
            r = difflib.SequenceMatcher(None, objetivo, normalizar(candidato)).ratio()
            if r > mejor.ratio:
                mejor = Match(slug=slug, juego=juego, ratio=r, via=via)

    if mejor.ratio < umbral:
        # Se conserva el ratio y el candidato: el reporte los muestra igual,
        # que es como se ajusta el umbral con evidencia en vez de a ojo.
        return Match(slug=slug, juego=None, ratio=mejor.ratio, via=mejor.via)
    return mejor


# ---------------------------------------------------------------------------
# Escritura
# ---------------------------------------------------------------------------

def agregar_ref(data_json: Path, ref: str, article: str = "") -> bool:
    """Mergea {"ref": ref, "article": slug} en mags[] del data.json.
    Devuelve si escribio.

    POR QUE VA TAMBIEN EL SLUG: el theme necesita saber CUAL articulo de la
    revista trata sobre este juego, y `articles[].game` viene con el slug
    editorial (`golden-axe`) mientras que el theme solo conoce el set de
    Pegasus (`goldnaxe`). Si no se escribe, el theme tendria que repetir el
    matching difuso en QML - dos heuristicas que pueden discrepar. Se escribe
    lo que ESTE comando resolvio, que ademas es un match que una persona ya
    reviso en el dry-run.

    MERGE, NUNCA OVERWRITE: `data.json` lo escribe una persona (accent,
    cheats, review, manual...) y esta herramienta solo es duena del campo
    `mags`. Si el ref ya esta, no lo toca -aunque el `article` difiera- para
    no pisar una correccion hecha a mano. Correrlo dos veces tiene que dar lo
    mismo que correrlo una.
    """
    if data_json.exists():
        try:
            datos = json.loads(data_json.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            return False        # no se pisa un archivo que no se pudo leer
        if not isinstance(datos, dict):
            return False
    else:
        datos = {}

    mags = datos.get("mags")
    if not isinstance(mags, list):
        mags = []

    if any(isinstance(m, dict) and m.get("ref") == ref for m in mags):
        return False

    entrada = {"ref": ref}
    if article:
        entrada["article"] = article
    mags.append(entrada)
    datos["mags"] = mags

    data_json.parent.mkdir(parents=True, exist_ok=True)
    with data_json.open("w", encoding="utf-8", newline="\n") as f:
        json.dump(datos, f, ensure_ascii=False, indent=2)
        f.write("\n")
    return True


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main(argv: list[str] | None = None) -> int:
    argv = list(argv if argv is not None else sys.argv[1:])

    if argv and argv[0] in ("-h", "--help"):
        print("uso: attract mags [ruta] [--apply] [--umbral N]")
        print()
        print("  Recorre <ruta>/_magazines/*/magazine.json, matchea sus")
        print("  articles[].game contra los juegos instalados por coincidencia")
        print("  difusa, y mergea el ref en el data.json de cada uno.")
        print()
        print("  Sin --apply no escribe nada: solo reporta que haria.")
        print(f"  --umbral por defecto: {UMBRAL_DEFECTO} (ADR-0025)")
        return 0

    aplicar = "--apply" in argv
    if aplicar:
        argv.remove("--apply")

    umbral = UMBRAL_DEFECTO
    if "--umbral" in argv:
        i = argv.index("--umbral")
        if i + 1 >= len(argv):
            print("error: --umbral necesita un numero", file=sys.stderr)
            return 2
        try:
            umbral = float(argv[i + 1])
        except ValueError:
            print(f"error: --umbral invalido: {argv[i + 1]}", file=sys.stderr)
            return 2
        del argv[i:i + 2]

    raiz = Path(argv[0]) if argv else Path(".")
    revistas_dir = raiz / "_magazines"

    if not revistas_dir.is_dir():
        print(f"error: no existe {revistas_dir}", file=sys.stderr)
        print("  Las revistas van en <raiz>/_magazines/ (ADR-0024).", file=sys.stderr)
        return 2

    juegos = juegos_instalados(raiz)
    if not juegos:
        print(f"error: no se encontro ningun juego en {raiz}/*/metadata.pegasus.txt",
              file=sys.stderr)
        return 2

    total_slugs = 0
    total_match = 0
    total_escrito = 0

    print()
    for magazine_json in sorted(revistas_dir.glob("*/magazine.json")):
        ref = magazine_json.parent.name
        slugs = slugs_de_revista(magazine_json)
        if not slugs:
            continue

        print(f"  {ref}")
        for slug in slugs:
            total_slugs += 1
            m = mejor_match(slug, juegos, umbral)

            if m.juego is None:
                print(f"    {slug:38} -  (sin juego instalado, mejor {m.ratio:.2f})")
                continue

            total_match += 1
            nota = ""
            if aplicar and agregar_ref(m.juego.data_json, ref, slug):
                total_escrito += 1
                nota = "  escrito"
            print(f"    {slug:38} -> {m.juego.set_id:12} "
                  f"{m.ratio:.2f}  {m.via:6}{nota}")
        print()

    print("  " + "-" * 62)
    print(f"  {total_slugs} slugs, {total_match} con juego instalado "
          f"(umbral {umbral})")
    if aplicar:
        print(f"  {total_escrito} data.json actualizados")
    else:
        print("  Nada escrito - correlo con --apply para aplicar.")
    print()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
