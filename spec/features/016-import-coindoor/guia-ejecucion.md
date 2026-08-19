# 016 · Import de paquete COINDOOR — Guía de ejecución

Documento para un agente que va a implementar esta feature **sin** el
contexto de la sesión donde se diseñó. Autocontenido en el sentido de "no
hace falta releer la conversación" — sí asume acceso al repo ATTRACT y a los
archivos que enlaza. Seguí el orden: cada paso depende del anterior.

Antes de tocar nada, leé (en este orden, son cortos):
1. `CLAUDE.md` (raíz del repo) — cómo se trabaja acá: spec antes que código,
   cambios mínimos, autoverificación.
2. `spec/decisions/0026-identidad-declarada-sin-mame.md`
3. `spec/decisions/0027-contrato-paquete-import-coindoor.md`
4. `spec/features/016-import-coindoor/spec.md` y `plan.md` (ya tienen el
   diseño completo — esta guía es la versión "hacé esto, en este orden, así
   se verifica", no repite el diseño, lo ejecuta).

No hay ambigüedad de diseño pendiente: las decisiones de forma ya están
tomadas en `plan.md`. Si en el camino aparece algo que el plan no cubre,
pará y preguntá antes de decidir por tu cuenta — no inventes contrato nuevo
(regla del proyecto, `CLAUDE.md` §15).

## Paso 0 · Confirmar el estado del repo

```bash
cd /Users/familyhouse/workplace/attract
git status
make test   # deberían pasar 172 tests, ninguno tocado por esta feature todavía
```

Si `git status` muestra cambios sin commitear que no reconocés, parate y
preguntá — no asumas que son tuyos para pisar.

## Paso 1 · Crear `src/attract/instalar.py`

Estructura completa del módulo, en este orden (mirar `synopsis.py` e
`ingest.py` como referencia de estilo — mismo docstring de módulo con
"Filosofia: fallar explicito, nunca escritura parcial ni silenciosa.",
comentarios sin tildes en el código):

```python
"""
attract import - instala un paquete COINDOOR (ADR-0027) en la libreria.

[completar con la explicacion corta del contrato, misma forma que el
docstring de ingest.py/synopsis.py - no copiar el ADR entero, apuntar a el]
"""
from __future__ import annotations

import json
import shutil
import sys
import tempfile
import unicodedata
import zipfile
from dataclasses import dataclass
from pathlib import Path

from attract import doctor
from attract.synopsis import (
    Bloque,
    _lineas_summary,
    escribir,
    identificar_set,
    mergear_summary,
    parsear_bloques,
)

SCHEMA_VERSIONS_SOPORTADAS = {"1"}
CAMPOS_OBLIGATORIOS_GAME = ("schema_version", "system", "set", "title")


class InstalarError(Exception):
    """Error explicito - se corta antes de escribir nada a medias."""


@dataclass
class Paquete:
    game: dict
    stage_media: Path   # <tmp>/media - misma forma que tendra media/<set>/
```

**Ojo con `_lineas_summary` y `mergear_summary`**: son funciones de
`synopsis.py` sin `_` protector en el nombre exportado más allá de
`_lineas_summary` (que sí lleva guión bajo — es privada por convención pero
Python no lo impide; importarla igual, es el mismo criterio que ya usa
`magazines.py` importando de `synopsis.py`). Si al escribir el código el
linter/import se queja, verificar el nombre exacto abriendo
`src/attract/synopsis.py` — no asumir.

### 1.1 · `leer_paquete`

```python
def _validar_miembro(nombre: str) -> None:
    if nombre.endswith("/"):
        return  # entrada de directorio, se ignora
    permitido = nombre in ("game.json", "data.json") or nombre.startswith("media/")
    partes = Path(nombre).parts
    if not permitido or ".." in partes or Path(nombre).is_absolute():
        raise InstalarError(f"miembro de zip no permitido: '{nombre}'")


def leer_paquete(zip_path: Path) -> Paquete:
    if not zip_path.exists():
        raise InstalarError(f"no existe {zip_path}")

    with zipfile.ZipFile(zip_path) as zf:
        nombres = zf.namelist()
        for nombre in nombres:
            _validar_miembro(nombre)   # recorre TODO antes de escribir nada

        tmp = Path(tempfile.mkdtemp(prefix="attract-import-"))
        try:
            media_dir = tmp / "media"
            media_dir.mkdir()

            for nombre in nombres:
                if nombre.endswith("/"):
                    continue
                contenido = zf.read(nombre)
                if nombre == "game.json":
                    destino = tmp / "game.json"
                elif nombre == "data.json":
                    destino = media_dir / "data.json"
                else:
                    # nombre empieza con "media/" (ya validado)
                    resto = nombre[len("media/"):]
                    resto_nfc = "/".join(
                        unicodedata.normalize("NFC", p) for p in resto.split("/")
                    )
                    destino = media_dir / resto_nfc

                destino.parent.mkdir(parents=True, exist_ok=True)
                destino.write_bytes(contenido)

            game = _leer_game_json(tmp / "game.json")
            _preflight_data_json(media_dir)

            return Paquete(game=game, stage_media=media_dir)
        except Exception:
            shutil.rmtree(tmp, ignore_errors=True)
            raise
```

`_leer_game_json`:

```python
def _leer_game_json(path: Path) -> dict:
    if not path.exists():
        raise InstalarError("el paquete no tiene game.json")
    try:
        datos = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        raise InstalarError(f"game.json: JSON invalido - {e}") from e
    if not isinstance(datos, dict):
        raise InstalarError("game.json: se esperaba un objeto JSON")

    faltantes = [c for c in CAMPOS_OBLIGATORIOS_GAME
                 if not str(datos.get(c) or "").strip()]
    if faltantes:
        raise InstalarError(f"game.json: faltan campos obligatorios: {faltantes}")

    if datos["schema_version"] not in SCHEMA_VERSIONS_SOPORTADAS:
        raise InstalarError(
            f"game.json: schema_version '{datos['schema_version']}' no soportada "
            f"(soportadas: {sorted(SCHEMA_VERSIONS_SOPORTADAS)})"
        )
    return datos
```

`_preflight_data_json` — **esta es la pieza central del diseño**: reusa
`doctor.py` tal cual existe, sin tocarlo. Leer primero
`src/attract/doctor.py` para confirmar las firmas exactas de `Reporte`,
`chk_encoding`, `chk_json_valido`, `chk_data_contrato`, `chk_nombre_windows`
(ya las citamos abajo, pero **confirmá contra el archivo real** antes de
escribir esto — si cambiaron de firma desde que se escribió este documento,
seguí lo que dice el código, no esta guía):

```python
def _preflight_data_json(media_dir: Path) -> None:
    rep = doctor.Reporte()

    data_json = media_dir / "data.json"
    if data_json.exists():
        doctor.chk_encoding(data_json, rep)
        doctor.chk_json_valido(data_json, rep)
        doctor.chk_data_contrato(data_json, rep)
        # NO se llama chk_mags_ref aca - ver plan.md #Enfoque

    for p in media_dir.rglob("*"):
        if p.is_file():
            doctor.chk_nombre_windows(p, rep)

    if rep.errores:
        detalle = "\n".join(f"  - {h.detalle}" for h in rep.errores)
        raise InstalarError(f"paquete invalido:\n{detalle}")
```

Verificar en el código real de `doctor.py` si `chk_nombre_windows` espera
una ruta relativa o absoluta, y si valida también el nombre del propio
archivo `data.json`/directorio `media` (que van a ser siempre válidos, no
debería importar, pero confirmá que no tira falsos positivos sobre el path
del `tempfile`, que puede tener caracteres del sistema que Windows sí
prohibiría en teoría — si eso pasa, filtrar `chk_nombre_windows` para que
solo mire `p.relative_to(media_dir)`, no el path absoluto completo).

### 1.2 · Merge/creación del bloque

```python
import re

_RE_CAMPO = re.compile(r"^([a-zA-Z0-9_.-]+):\s*")
_RE_FILE = re.compile(r"^file:\s*(.+)$")


def mergear_campo_simple(bloque: Bloque, clave: str, valor: str) -> Bloque:
    """Reemplaza (o inserta despues de file:) una linea `clave: valor`
    de una sola linea. Analoga a synopsis.mergear_summary pero sin el
    caso multilinea - assets.*, developer, genre, etc nunca lo necesitan."""
    valor = unicodedata.normalize("NFC", str(valor))
    lineas = bloque.lineas
    nuevas: list[str] = []
    idx_file: int | None = None
    insertado = False

    for linea in lineas:
        m = _RE_CAMPO.match(linea)
        if m and m.group(1) == clave:
            nuevas.append(f"{clave}: {valor}")
            insertado = True
            continue
        nuevas.append(linea)
        if _RE_FILE.match(linea) and idx_file is None:
            idx_file = len(nuevas) - 1

    if not insertado:
        if idx_file is None:
            raise InstalarError(f"bloque game: sin linea file: - no hay donde insertar {clave}:")
        nuevas.insert(idx_file + 1, f"{clave}: {valor}")

    return Bloque(lineas=nuevas, es_game=bloque.es_game)


def construir_bloque_declarado(game: dict, assets: list[tuple[str, str]]) -> Bloque:
    """Crea un bloque game: nuevo a partir de identidad DECLARADA (ADR-0026),
    sin pasar por mame -listxml. Mismo espiritu que ingest.construir_bloque."""
    set_id = game["set"]
    archivo = game.get("file") or f"{set_id}.zip"

    lineas = [
        f"game: {unicodedata.normalize('NFC', game['title'])}",
        f"file: {archivo}",
    ]
    for campo_json, campo_txt in (
        ("developer", "developer"),
        ("publisher", "publisher"),
        ("genre", "genre"),
        ("players", "players"),
        ("release", "release"),
    ):
        if game.get(campo_json) not in (None, ""):
            lineas.append(f"{campo_txt}: {unicodedata.normalize('NFC', str(game[campo_json]))}")

    for clave, ruta in assets:
        lineas.append(f"assets.{clave}: {ruta}")

    lineas.append(f"x-set: {set_id}")
    if game.get("format"):
        lineas.append(f"x-formato: {unicodedata.normalize('NFC', str(game['format']))}")
    lineas.append("x-procedencia: declarada")

    if game.get("summary"):
        lineas.extend(_lineas_summary(str(game["summary"])))

    return Bloque(lineas=lineas, es_game=True)
```

### 1.3 · `aplicar`

```python
_CAMPOS_SIMPLES = ("developer", "publisher", "genre", "players", "release")


def aplicar(paquete: Paquete, raiz: Path) -> str:
    game = paquete.game
    set_id = game["set"]
    sistema_root = raiz / game["system"]
    metadata_path = sistema_root / "metadata.pegasus.txt"

    if not metadata_path.exists():
        raise InstalarError(
            f"no existe {metadata_path} - attract import no crea sistemas "
            "nuevos, crear la coleccion primero (ver spec.md #Fuera de alcance)"
        )

    media_dir = sistema_root / "media" / set_id
    media_dir.mkdir(parents=True, exist_ok=True)

    # 1. assets (todo lo que NO es data.json), juntando (clave, ruta) de paso
    assets: list[tuple[str, str]] = []
    for origen in paquete.stage_media.rglob("*"):
        if not origen.is_file():
            continue
        rel = origen.relative_to(paquete.stage_media)
        if rel.name == "data.json" and rel.parent == Path("."):
            continue
        destino = media_dir / rel
        destino.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(origen, destino)
        if rel.parent == Path("."):   # directo en media/<set>/, no en _manual/
            assets.append((origen.stem, f"media/{set_id}/{origen.name}"))

    # 2. data.json, preservando mags[] existente si el paquete no trae uno
    origen_data = paquete.stage_media / "data.json"
    nuevo = json.loads(origen_data.read_text(encoding="utf-8")) if origen_data.exists() else {}
    destino_data = media_dir / "data.json"
    if "mags" not in nuevo and destino_data.exists():
        try:
            existente = json.loads(destino_data.read_text(encoding="utf-8"))
            if isinstance(existente, dict) and "mags" in existente:
                nuevo["mags"] = existente["mags"]
        except json.JSONDecodeError:
            pass   # el archivo instalado ya estaba roto, no es este comando el que arregla eso
    with destino_data.open("w", encoding="utf-8", newline="\n") as f:
        json.dump(nuevo, f, ensure_ascii=False, indent=2)
        f.write("\n")

    # 3. bloque game:
    texto = metadata_path.read_text(encoding="utf-8")
    bloques = parsear_bloques(texto)
    idx = next(
        (i for i, b in enumerate(bloques) if b.es_game and identificar_set(b) == set_id),
        None,
    )

    if idx is not None:
        b = bloques[idx]
        for campo in _CAMPOS_SIMPLES:
            if game.get(campo) not in (None, ""):
                b = mergear_campo_simple(b, campo, game[campo])
        if game.get("format"):
            b = mergear_campo_simple(b, "x-formato", game["format"])
        for clave, ruta in assets:
            b = mergear_campo_simple(b, f"assets.{clave}", ruta)
        if game.get("summary"):
            b = mergear_summary(b, str(game["summary"]))
        bloques[idx] = b
    else:
        bloques.append(construir_bloque_declarado(game, assets))

    metadata_path.write_text(escribir(bloques), encoding="utf-8", newline="\n")

    return set_id
```

**Revisar el orden de escritura contra `plan.md` §Riesgos antes de dar esto
por terminado**: el plan pide assets → `data.json` → bloque `game:`, que es
el orden en que está escrito arriba. No lo reordenes sin releer por qué.

### 1.4 · `main`

Copiar el esqueleto de `ingest.main`/`synopsis.main` (mismo archivo,
`src/attract/ingest.py` al final) y adaptar:

```python
def main(argv: list[str] | None = None) -> int:
    argv = argv if argv is not None else sys.argv[1:]

    if not argv or argv[0] in ("-h", "--help"):
        print("uso: attract import <paquete.zip> [ruta]")
        print()
        print("  Instala un paquete COINDOOR (ADR-0027) en <ruta>/<sistema>/.")
        print("  El sistema tiene que existir ya (metadata.pegasus.txt presente).")
        return 0

    zip_path = Path(argv[0])
    raiz = Path(argv[1]) if len(argv) > 1 else Path(".")

    try:
        paquete = leer_paquete(zip_path)
        set_id = aplicar(paquete, raiz)
    except InstalarError as e:
        print(f"error: {e}", file=sys.stderr)
        return 2
    finally:
        if "paquete" in dir() and paquete.stage_media.exists():
            shutil.rmtree(paquete.stage_media.parent, ignore_errors=True)

    print(f"OK - '{set_id}' instalado en {raiz}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
```

Ojo: `"paquete" in dir()` es una forma rebuscada de chequear si la variable
existe; más limpio inicializar `paquete = None` antes del `try` y chequear
`if paquete is not None`. Usar el patrón que `ingest.py`/`synopsis.py` ya
usan para errores — si ellos no tienen un `finally` de limpieza (no lo
tienen, no crean temporales), está bien que este módulo sea el primero en
necesitarlo; no copies un patrón que no aplica.

## Paso 2 · Cablear `cli.py`

En `src/attract/cli.py`:
1. Agregar `instalar` al `from attract import ...` de la línea 19.
2. Agregar `"import": instalar.main,` a `COMANDOS`.
3. Agregar la línea de ayuda en el bloque `if len(sys.argv) < 2 ...`:
   ```
   print("  import <paquete.zip> [ruta]        instala un paquete COINDOOR (ADR-0027)")
   ```

Verificar: `PYTHONPATH=src python -m attract.cli import --help` imprime el
uso sin error.

## Paso 3 · Tests — `tests/test_instalar.py`

Mirar `tests/test_ingest.py` y `tests/test_synopsis.py` como referencia de
estructura (fixtures con `tmp_path`, nombres de test que describen el bug o
caso que reproducen, no la función que cubren — regla de
`spec/constitution/tech-stack.md` §Convenciones).

**No agregar un `.zip` binario al repo.** Construir los zips de prueba en el
propio test, en memoria, con un helper:

```python
import zipfile
from pathlib import Path

def _zip_paquete(tmp_path: Path, archivos: dict[str, bytes], nombre="paquete.zip") -> Path:
    zip_path = tmp_path / nombre
    with zipfile.ZipFile(zip_path, "w") as zf:
        for nombre_interno, contenido in archivos.items():
            zf.writestr(nombre_interno, contenido)
    return zip_path
```

Y un helper para armar una libreria minima de prueba (un `<sistema>/metadata.pegasus.txt`
vacio con cabecera, para los tests que necesitan que el sistema ya exista):

```python
def _libreria_minima(tmp_path: Path, sistema="arcade") -> Path:
    raiz = tmp_path / "libreria"
    sistema_dir = raiz / sistema
    sistema_dir.mkdir(parents=True)
    (sistema_dir / "metadata.pegasus.txt").write_text(
        f"collection: {sistema.title()}\nshortname: {sistema}\nlaunch: /usr/bin/mame\n",
        encoding="utf-8", newline="\n",
    )
    return raiz
```

Casos a cubrir (calcados de `tasks.md` §Tests, no reinventar la lista, solo
implementarla):

1. Caso feliz, `set` nuevo → bloque creado con `x-procedencia: declarada`,
   `assets.boxFront:` presente, `attract doctor` (importar `doctor.main` o
   llamar a las funciones de chequeo directo) da 0 errores sobre el
   resultado.
2. Caso feliz, `set` ya existente (armar a mano un bloque previo en el
   fixture de metadata con `x-set: <set>` y sin `x-procedencia`) → después de
   importar, `file:`/`x-set:` sin cambios, `developer:` actualizado.
3. Paquete mínimo (solo `game.json` con los 4 obligatorios) → juego válido
   desnudo.
4. Zip con miembro `"../fuera.txt"` → `InstalarError`, y confirmar que no se
   creó nada en `raiz` (comparar `list(raiz.rglob("*"))` antes/después).
5. `game.json` sin `set` → `InstalarError` antes de tocar `raiz`.
6. `data.json` con `"manual": {...}` (objeto, no lista) → `InstalarError` con
   un mensaje que contenga el texto que ya usa `doctor.chk_data_contrato`
   para ese caso (buscarlo en `doctor.py`, no inventarlo).
7. Reimportar el mismo zip dos veces → segundo resultado en disco idéntico
   al primero (comparar contenido de `metadata.pegasus.txt` y `data.json`
   byte a byte).
8. `data.json` instalado con `mags: [{"ref": "x"}]`, reimportar con un
   paquete cuyo `data.json` no trae `mags` → el `mags[]` sigue ahí después.
9. `system` cuyo `metadata.pegasus.txt` no existe → `InstalarError`, y la
   carpeta `raiz/<sistema>/` no se creó (o si se creó por el `mkdir` de
   `media_dir`, ESO ES UN BUG del orden de operaciones — la validación de
   "el sistema existe" tiene que ir antes de cualquier `mkdir`).

Correr: `PYTHONPATH=src python -m pytest tests/test_instalar.py -v`

## Paso 4 · Suite completa + doctor

```bash
make test          # los 172 anteriores + los nuevos de test_instalar.py, todo en verde
make doctor        # fixtures/ sigue en verde, esta feature no las toca
```

Si `make test` rompe algo fuera de `test_instalar.py`, **no** es un test
viejo mal escrito por defecto — investigar primero si `instalar.py` importó
algo de `doctor.py`/`synopsis.py` de una forma que cambió su comportamiento
(no debería, son funciones puras que solo se llaman, no se tocan).

## Paso 5 · Smoke test manual (opcional pero recomendado)

```bash
cd /Users/familyhouse/workplace/attract
python3 - <<'EOF'
import zipfile, json, tempfile
from pathlib import Path

tmp = Path(tempfile.mkdtemp())
zip_path = tmp / "sf2ce-nuevo.zip"
with zipfile.ZipFile(zip_path, "w") as zf:
    zf.writestr("game.json", json.dumps({
        "schema_version": "1", "system": "arcade", "set": "sf2ce-nuevo",
        "title": "Street Fighter II Nuevo (smoke test)", "developer": "Capcom",
    }))
print(zip_path)
EOF
# copiar la ruta que imprime y correr:
PYTHONPATH=src python -m attract.cli import <esa-ruta> fixtures/arcade
PYTHONPATH=src python -m attract.cli doctor fixtures/arcade
# limpiar despues: git checkout -- fixtures/arcade/metadata.pegasus.txt
#                   rm -rf fixtures/arcade/media/sf2ce-nuevo
```

**No dejes este cambio en `fixtures/` commiteado** — es solo para ver el
comando funcionar contra datos reales del repo antes de cerrar la feature.
Revertir con `git checkout -- fixtures/arcade/metadata.pegasus.txt` y borrar
la carpeta `media/sf2ce-nuevo/` que haya creado.

## Paso 6 · Cierre (checklist de `tasks.md` §Cierre)

En este orden:

1. Todos los criterios de `spec.md` verificados (release por release, no de
   memoria — releerlos y tildar mentalmente cada uno contra lo que se probó).
2. `CLAUDE.md` — agregar fila a la tabla de comandos:
   `| Instalar paquete COINDOOR | attract import <paquete.zip> [ruta] |`
   y agregar `instalar.py` a la tabla del mapa de `src/attract/` (una fila
   más, mismo formato que las existentes).
3. `spec/constitution/tech-stack.md` — agregar `src/attract/instalar.py` a
   la tabla "Archivos / módulos clave" y `tests/test_instalar.py` a la de
   tests, con la cuenta de tests actualizada.
4. `spec/constitution/roadmap.md` — mover `016-import-coindoor` a "Hecho",
   siguiendo el formato de las entradas anteriores (número, título en
   negrita, 2-3 líneas de qué se hizo y qué confirma).
5. Marcar todos los checkboxes de `tasks.md` en esta carpeta.
6. `git status` — revisar que solo cambiaron los archivos esperados
   (`src/attract/instalar.py`, `src/attract/cli.py`, `tests/test_instalar.py`,
   `CLAUDE.md`, `spec/constitution/tech-stack.md`,
   `spec/constitution/roadmap.md`, los `.md` de `spec/features/016-*` con
   checkboxes tildados). Si `fixtures/` aparece modificado, es el smoke test
   del Paso 5 sin revertir — arreglarlo antes de seguir.
7. **No hacer commit sin que el usuario lo pida explícitamente** — dejar
   todo listo, working tree limpio salvo lo que corresponde a esta feature,
   y reportar qué se hizo. Esta regla es de `CLAUDE.md` del harness, no de
   este proyecto puntual, pero aplica igual.

## Si algo no cierra

Si en cualquier paso el diseño de `plan.md` no alcanza para decidir algo
concreto (una firma de función no calza, un test revela un caso que el plan
no previó), **no lo resuelvas inventando sobre la marcha**: es exactamente
el tipo de decisión que en este proyecto va a un ADR si tiene alternativas
reales, o a una nota en `plan.md` si es una convención sin alternativas. Dejá
constancia en `tasks.md` (una línea nueva bajo la tarea afectada) de qué
encontraste y qué falta decidir, y parate ahí en vez de seguir con una
suposición.
