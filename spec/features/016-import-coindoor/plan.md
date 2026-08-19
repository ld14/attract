# 016 · Import de paquete COINDOOR — Plan

_Cómo se implementa lo descrito en `spec.md`. Debe respetar la `constitution/`._

## Enfoque

Un módulo nuevo, `src/attract/instalar.py`, con la misma forma que
`ingest.py`/`synopsis.py`: parsear y validar todo el paquete en memoria
primero, escribir recién al final, en un solo tramo, si todo pasó. No hay
orquestación de otros comandos (`ingest`/`synopsis`/`rasterize`/`mags`) —
sería exactamente el patrón que `015-carga-guiada/plan.md` ya descartó
("un comando que encadena varios escritores no puede fallar a la mitad sin
dejar estado inconsistente"). `attract import` es un escritor más, no un
orquestador.

Reusa deliberadamente:
- `synopsis.parsear_bloques` / `identificar_set` / `escribir` /
  `mergear_summary` / `_lineas_summary` — el parser de `metadata.pegasus.txt`
  que ya existe, para encontrar o crear el bloque y para el campo `summary`
  multilínea.
- **`doctor.py` entero, sin modificarlo.** Decisión cerrada (reemplaza la
  duda que dejó abierta la primera versión de este plan): en vez de extraer
  o duplicar `chk_data_contrato`, `instalar.py` arma un **staging** —
  un directorio temporal con la misma forma que va a tener
  `media/<set>/` una vez instalado (`data.json` junto a `_manual/*`, exactamente
  como espera `_chk_manual_doc`) — y corre `doctor.chk_encoding`,
  `doctor.chk_json_valido`, `doctor.chk_data_contrato` y
  `doctor.chk_nombre_windows` **tal cual existen hoy**, apuntando al
  staging. `chk_mags_ref` queda **afuera** del preflight a propósito:
  resuelve `_magazines/` con `magazines_root_de()`, que asume la posición
  real del archivo dentro de `<raiz>/<sistema>/media/<set>/data.json` — un
  staging aislado no tiene esa posición. Se resuelve solo: el
  `attract doctor` que corre el propio flujo de carga después de instalar
  (criterio de aceptación de `spec.md`) ya lo cubre, contra la ubicación
  real.

## Implementación

Todo en un módulo nuevo, `src/attract/instalar.py`. Firma completa:

```python
class InstalarError(Exception): ...

@dataclass
class Paquete:
    game: dict                      # game.json parseado
    stage_media: Path                # directorio temporal = futuro media/<set>/
                                      # (incluye data.json, assets, _manual/*)

def leer_paquete(zip_path: Path) -> Paquete: ...
def aplicar(paquete: Paquete, raiz: Path) -> str: ...   # devuelve el set_id
def main(argv: list[str] | None = None) -> int: ...
```

1. **`leer_paquete(zip_path) -> Paquete`** — de solo lectura sobre el
   filesystem real, escribe únicamente en un `tempfile.mkdtemp()`:
   1. Abrir el zip con `zipfile.ZipFile`. Para cada `ZipInfo`: si es
      directorio (`name.endswith("/")`), saltear. Si no, exigir que el
      nombre sea exactamente `"game.json"`, `"data.json"`, o empiece con
      `"media/"`; y que ningún componente de `Path(nombre).parts` sea `".."`
      ni el nombre sea absoluto. Cualquier otra cosa → `InstalarError`
      inmediato, **sin extraer nada todavía** (recorrer `zf.namelist()`
      entero antes de escribir un solo byte).
   2. Recién con la lista completa validada: por cada miembro, leer con
      `zf.read(info)` (nunca `extractall`/`extract` — evita que zipfile
      interprete bits de permiso/symlink del zip) y escribirlo a mano con
      `Path.write_bytes()`. Normalizar el nombre destino con
      `unicodedata.normalize("NFC", ...)` antes de escribir (mismo criterio
      NFC que el resto del proyecto). `game.json` va a
      `<tmp>/game.json`; `data.json` y todo lo que empiece con `media/` va a
      `<tmp>/media/<resto-del-nombre-sin-el-prefijo-media/>` (o sea,
      `media/boxFront.png` → `<tmp>/media/boxFront.png`,
      `media/_manual/manual.pdf` → `<tmp>/media/_manual/manual.pdf`,
      `data.json` (el del root del zip) → `<tmp>/media/data.json`). Este
      reordenamiento es la clave: `<tmp>/media/` queda con la MISMA forma
      que `media/<set>/` va a tener una vez instalado.
   3. Parsear `<tmp>/game.json`. Si falta o no es JSON válido → error. Exigir
      `schema_version in {"1"}`, y `system`/`set`/`title` presentes y string
      no vacío.
   4. `rep = doctor.Reporte()`. Si existe `<tmp>/media/data.json`:
      `doctor.chk_encoding(ese_path, rep)`,
      `doctor.chk_json_valido(ese_path, rep)`,
      `doctor.chk_data_contrato(ese_path, rep)`. Además,
      `doctor.chk_nombre_windows(p, rep)` para cada archivo bajo `<tmp>/media/`
      (incluido `_manual/*`) y para `<tmp>/game.json`.
   5. Si `rep.errores` no está vacío: `shutil.rmtree(tmp)`, levantar
      `InstalarError` con los mensajes (`h.detalle` de cada `Hallazgo`,
      unidos con `\n`). Los avisos (`rep.avisos`) no bloquean — se pueden
      imprimir a stdout como referencia, igual que hace `attract doctor`.
   6. Devolver `Paquete(game=<dict de game.json>, stage_media=<tmp>/media)`.

2. **`aplicar(paquete, raiz) -> str`** — recién acá se escribe en la
   librería real. Orden elegido para minimizar daño si el proceso se corta a
   mitad (ver `Riesgos`): **assets → `data.json` → bloque `game:`**.
   1. `sistema_root = raiz / paquete.game["system"]`; exigir que
      `sistema_root / "metadata.pegasus.txt"` **ya exista** — si no, error
      explícito ("correr `attract carga`/crear el sistema primero: fuera de
      alcance de este comando", ver `spec.md` §Fuera de alcance). Este
      comando nunca crea una colección nueva.
   2. `set_id = paquete.game["set"]`; `media_dir = sistema_root / "media" / set_id`.
      `media_dir.mkdir(parents=True, exist_ok=True)`.
   3. Copiar todo `paquete.stage_media/*` **excepto** `data.json` a
      `media_dir/`, sobrescribiendo (`shutil.copy2`, recorriendo con
      `rglob("*")` para incluir `_manual/`). Por cada archivo copiado que
      queda **directo** en `media_dir/` (no dentro de `_manual/` — esos no
      son assets de Pegasus, son documentos) juntar un par
      `(clave, ruta_relativa)` con `clave = archivo.stem` (nombre sin
      extensión) y `ruta_relativa = f"media/{set_id}/{archivo.name}"` — se
      usan en el paso 5 para escribir las líneas `assets.<clave>:` (ADR-0027
      §`media/`: "el nombre de archivo, sin extensión, es la clave").
   4. `data.json`: si `(paquete.stage_media / "data.json").exists()`, leer su
      contenido (`nuevo`); si no, `nuevo = {}`. Si `"mags" not in nuevo` y
      `(media_dir / "data.json").exists()`, leer el `data.json` YA instalado
      y, si tiene `"mags"`, copiarlo a `nuevo["mags"]` antes de escribir —
      la única excepción al "todo se pisa siempre" (ADR-0027). Escribir
      `nuevo` en `media_dir / "data.json"` (mismo formato que ya usa
      `magazines.agregar_ref`: `json.dump(..., ensure_ascii=False, indent=2)`
      + salto de línea final, `newline="\n"`).
   5. Bloque `game:`: leer `sistema_root/metadata.pegasus.txt`,
      `bloques = parsear_bloques(texto)`. Buscar
      `identificar_set(b) == set_id` entre los `es_game`.
      - Si existe → merge quirúrgico: por cada campo presente en
        `paquete.game` de esta lista —`developer`, `publisher`, `genre`,
        `players`, `release`— reemplazar (o insertar después de `file:`) la
        línea `<campo>: <valor>` (nueva función `mergear_campo_simple(bloque,
        clave, valor) -> Bloque`, mismo patrón de líneas que
        `synopsis.mergear_summary` pero de una sola línea, sin el caso
        multilínea). `format` se mergea igual pero a la clave `x-formato`.
        `summary`, si viene, se mergea con `synopsis.mergear_summary`
        (reuso directo, ya soporta multilínea). Además, por cada par
        `(clave, ruta_relativa)` del paso 3 (assets copiados): mergear la
        línea `assets.<clave>: <ruta_relativa>` con `mergear_campo_simple`
        (la clave de la línea es literalmente `f"assets.{clave}"`).
      - Si NO existe → crear bloque nuevo (nueva función
        `construir_bloque_declarado(game: dict, assets: list[tuple[str,str]])
        -> Bloque`, mismo espíritu que `ingest.construir_bloque` pero sin
        `mame`): líneas `game:`, `file:` (de `game["file"]` o
        `f"{set_id}.zip"` si falta), developer/publisher/genre/players/release
        si están, una línea `assets.<clave>: <ruta_relativa>` por cada par de
        `assets`, `x-set: <set_id>`, `x-formato: <format>` si está,
        `x-procedencia: declarada` (ADR-0026, **siempre**, sin condición —
        es la marca de que este bloque no pasó por `mame -listxml`), y
        `summary` al final vía `synopsis._lineas_summary` si viene. Append a
        `bloques`.
      - `metadata_path.write_text(escribir(bloques), encoding="utf-8",
        newline="\n")`.
   6. Devolver `set_id`.

3. **`main(argv)`** — mismo esqueleto que `ingest.main`/`synopsis.main`:
   `attract import <paquete.zip> [<raiz>]` (default `raiz = Path(".")`),
   `-h`/`--help` imprime uso, captura `InstalarError` → stderr + `return 2`,
   éxito → `print(f"OK - '{set_id}' instalado en {raiz}")` + `return 0`.

4. `src/attract/cli.py` — importar `instalar`, agregar
   `"import": instalar.main` a `COMANDOS`, agregar la línea de ayuda.

## Decisiones

- **Escritor atómico propio, no orquestador de comandos existentes** — ver
  `spec/features/015-carga-guiada/plan.md` §Decisiones, mismo criterio.
- **Reusar el contrato de `data.json` sin traducir, y el parser de
  `metadata.pegasus.txt` de `synopsis.py`** — ver
  [`ADR-0027`](../../decisions/0027-contrato-paquete-import-coindoor.md).
- **Staging temporal + `doctor.py` sin modificar, en vez de extraer o
  duplicar `chk_data_contrato`** — cero cambios en un módulo que ya tiene
  tests propios; el preflight de `instalar.py` corre literalmente las mismas
  funciones que correría `attract doctor` después de instalar, así que no
  hay forma de que las dos validaciones diverjan con el tiempo.
- **El sistema/colección tiene que existir antes de importar** —
  `attract import` nunca crea `<sistema>/metadata.pegasus.txt` desde cero.
  Mismo alcance que ya fijó `015-carga-guiada/spec.md` ("crear la carpeta del
  sistema... son dos acciones de una línea, viven fuera del repo").
- **Identidad declarada cuando el `set` no existe** — ver
  [`ADR-0026`](../../decisions/0026-identidad-declarada-sin-mame.md).
- **Zip-slip guard antes de extraer nada** — sin alternativas reales
  (es una medida de seguridad, no una elección de diseño); documentado en
  ADR-0027 como parte del contrato, no como decisión aparte.
- **Módulo se llama `instalar.py`, comando se llama `import`** — mismo
  patrón que ya existe (`magazines.py` ↔ comando `mags`); `import` es
  palabra reservada de Python, no puede ser nombre de módulo.

## Riesgos

- **Escritura no verdaderamente atómica a nivel de sistema de archivos** —
  entre escribir `metadata.pegasus.txt`, `data.json` y copiar `media/*` hay
  una ventana donde un corte de proceso deja estado a medias. Se mitiga
  escribiendo en el orden que menos daño hace si se corta (assets primero,
  `data.json` después, `metadata.pegasus.txt` al final — un bloque `game:`
  a medio escribir es el peor caso, así que va último) y documentando que
  `attract doctor` es la red de seguridad para detectarlo, igual que para
  cualquier otra escritura manual interrumpida.
- **Identidad declarada sin verificar** (heredado de ADR-0026) — se mitiga
  con `x-procedencia: declarada`, visible para auditoría; no hay mitigación
  técnica más fuerte, es una decisión aceptada.
