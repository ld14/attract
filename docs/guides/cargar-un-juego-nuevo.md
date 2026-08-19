# Cargar un juego nuevo

<!-- GUÍA: docs/ es para el usuario final. Nada de decisiones técnicas ni
razonamiento de arquitectura: eso vive en spec/. -->

Manual operativo: qué archivo va en qué carpeta, con qué nombre, cuando llega
un juego nuevo (o material nuevo para uno que ya está). Si necesitás **por
qué** una regla es así, cada sección enlaza al ADR o a `docs/CONVENCION.md`
correspondiente — esto no lo repite, lo aplica.

## Antes de empezar

- `make setup` ya corrido una vez en esta máquina (`docs/SETUP.md`).
- `mame` en el `PATH` — probalo con `mame -listxml sf2ce`, funciona con cero
  ROMs instaladas.
- `make doctor` en verde antes de tocar nada, para partir de una librería
  sana.

Todos los comandos de abajo asumen que corrés desde la raíz del repo, con
`PYTHONPATH=src` (lo exporta el `Makefile`; si corrés `python -m attract...`
a mano, exportalo vos).

## 1 · El ROM

Cada sistema (Arcade, NES, …) es una carpeta de primer nivel en `library/`,
con su propio `metadata.pegasus.txt` — **tiene que existir antes** de
ingestar, `attract ingest` no crea sistemas nuevos, solo agrega juegos a uno
que ya existe.

El ROM va donde `mame` lo espera a él, no ATTRACT — `attract ingest` no copia
ni mueve el archivo, solo lo identifica.

```bash
python -m attract.ingest library/arcade/dino.zip library/arcade
```

Esto:

1. Corre `mame -listxml dino` y exige que resuelva a **exactamente una**
   máquina jugable (ni cero, ni más de una — familia con varios clones
   jugables es un caso no soportado todavía).
2. Agrega un bloque `game:` nuevo a `library/arcade/metadata.pegasus.txt`
   (título, `file:`, `developer:`/`release:` si `mame` los trae, `x-set:`).
3. Crea `library/arcade/media/dino/` vacía.

El identificador del juego (el nombre de la carpeta en `media/`) es el
nombre del `.zip` sin extensión — nunca el título de presentación. Ver
`docs/CONVENCION.md` §1.2 para los tres casos (archivo único / romset MAME /
carpeta con varios archivos sueltos) y las restricciones de nombre que
`attract doctor` valida (nada de `< > : " / \ | ? *`, sin terminar en
espacio o punto, todo en NFC).

**Falla explícito, no a medias**, si: el set ya tiene un bloque `game:`
(no edita, solo crea), `mame` no lo reconoce, o `mame` no está en el
`PATH`. Nada se escribe si algo de esto pasa.

## 2 · Las imágenes

Van planas dentro de `library/<sistema>/media/<juego>/`, sin subcarpetas por
tipo — Pegasus las auto-descubre por nombre de archivo:

```
library/arcade/media/dino/
├─ boxFront.jpg
├─ marquee.png
├─ poster.png
└─ video.mp4
```

La carátula (`cover` en pantalla) sigue esta cadena de fallback si falta
alguna (`docs/CONVENCION.md` §2.2):

```
boxFront → poster → marquee → genérico
```

No hace falta completar los cuatro. Un juego sin ninguna imagen sigue siendo
**válido** — el caso principal del proyecto es justo ese (ver el juego
`mok` del banco de pruebas, que solo tiene `marquee`/`poster`).

## 3 · El video

`library/<sistema>/media/<juego>/video.mp4`, mismo nivel plano que las
imágenes. Si falta, la pantalla no queda con un hueco: muestra el `cover`
(con su propia cadena de fallback de arriba) como si fuera un video pausado.

## 4 · La revista

ATTRACT **consume** revistas ya escaneadas y clasificadas — no las produce.
Alguien (hoy una persona, a futuro un subsistema externo) te entrega una
carpeta con `magazine.json` + páginas ya hechas; vos la dejás en su lugar y
la referenciás desde el juego. No armes `magazine.json` a mano — si no
tenés uno, no hay revista para ese juego todavía, y eso es un estado válido.

```
library/_magazines/micromania-34/        ← al lado de arcade/, NO adentro
├─ magazine.json
├─ cover.jpg                             ← la tapa va en la raíz
└─ pages/
   ├─ p001.jpg
   ├─ p002.jpg
   └─ …
```

- **`_magazines/` va en la raíz de la librería**, hermana de `arcade/`,
  `nes/`, `pc/` — no adentro de ninguna. Una revista habla de juegos de
  varios sistemas a la vez, así que meterla en uno obligaría a copiarla en
  todos ([`ADR-0024`](../../spec/decisions/0024-contrato-magazine-json-v2.md)).
- El guión bajo es a propósito: separa la carpeta de revistas de las de
  sistema.
- **Las páginas van en `pages/`; la tapa no.** Es la forma que produce el
  subsistema de escaneo, y el theme la busca siempre ahí.
- Las páginas llevan ceros a la izquierda (`p001.jpg`, no `p1.jpg`) para
  que el orden alfabético sea el orden real de lectura.
- **Una revista cubre varios juegos** — se deja **una sola vez** en
  `_magazines/`, nunca copiada dentro de cada juego que aparece en ella.

### Linkearla con los juegos

No hace falta editar el `data.json` de cada juego a mano. `attract mags` lee
los `articles[].game` de la revista y los matchea contra los juegos
instalados ([`ADR-0025`](../../spec/decisions/0025-link-revista-juego-difuso.md)):

```
$ attract mags library

  micromania-34
    golden-axe                    -> goldnaxe     0.94  set
    battle-squadron               -  (sin juego instalado, mejor 0.29)
    …

  20 slugs, 1 con juego instalado (umbral 0.85)
  Nada escrito - correlo con --apply para aplicar.
```

El matching es **difuso** a propósito: el slug de la revista (`golden-axe`)
no coincide con el set de MAME (`goldnaxe`). Por eso propone antes de
escribir — mirá el reporte y recién después corré `attract mags library
--apply`, que mergea el `ref` en el `mags[]` de cada juego conservando todo
lo demás del `data.json`. Correrlo dos veces no duplica nada, así que podés
volver a correrlo cada vez que sumes una ROM.

Si preferís hacerlo a mano, es una línea en el `data.json` del juego:

```json
{ "mags": [ { "ref": "micromania-34", "article": "golden-axe" } ] }
```

`article` es el `articles[].game` de la revista que trata sobre este juego, y
es **lo que hace que el visor abra en la nota** y no en la página 1. Es
opcional: si falta, el theme busca el artículo por el nombre del set — que
alcanza cuando la revista usa el mismo identificador que Pegasus, pero no
cuando usa un slug editorial (`golden-axe` contra el set `goldnaxe`). Por eso
`attract mags` lo escribe siempre.

Si el `ref` apunta a una carpeta que no existe, no rompe nada — es un
**aviso**, no un error: el juego se degrada mostrando "Sin cobertura en
revistas" en vez de fallar (`attract doctor`, `chk_mags_ref`).

## 5 · Datos ricos propios del juego (`data.json`)

`library/<sistema>/media/<juego>/data.json` — todo lo que le pertenece solo
a ese juego: color de acento, trucos, reseña, referencia a revista(s),
manual digitalizado. **Todos los campos son opcionales**; un juego sin este
archivo es válido, solo menos enriquecido (contrato completo:
[`ADR-0015`](../../spec/decisions/0015-contrato-data-json.md)).

```json
{
  "accent": "#ffb020",
  "accent2": "#4d3608",

  "mags": [ { "ref": "micromania-16" } ],

  "manual": { "pages": ["p001.jpg", "p002.jpg"] },

  "cheats": {
    "combos":   [ { "name": "Patada giratoria", "input": "↓ ↘ → + K" } ],
    "codes":    [ { "name": "Modo 3 jugadores", "input": "En el test menu: PLAYERS 3" } ],
    "secretos": [ { "name": "Dragón rojo", "input": "Aparece en la fase 3" } ]
  },

  "review": {
    "score": 94,
    "verdict": "string opcional",
    "cats": {
      "originalidad": 90, "graficos": 88, "adiccion": 92,
      "sonido": 85, "dificultad": 70, "animacion": 91
    }
  }
}
```

Notas que importan al cargar:

- `review.cats` no hace falta completo — una reseña puede traer solo
  `score` (reseña parcial, cada categoría faltante se muestra `"-"`).
  `review` ausente o `null` (no un objeto vacío) es "no hay reseña".
- Si hay manual digitalizado, las páginas van en
  `library/<sistema>/media/<juego>/_manual/p001.jpg…` (mismo patrón de
  ceros a la izquierda que las revistas) y se listan en
  `manual.pages[]` — ver [`ADR-0014`](../../spec/decisions/0014-manual-digitalizado.md).
- `accent`/`accent2` son hex `#rrggbb` de 6 dígitos — `attract doctor`
  rechaza formas cortas tipo `#fb0`.

### Los grupos de `cheats` son libres

`combos` y `codes` no son las únicas claves posibles: podés inventar los
grupos que el juego necesite (`secretos`, `dos_jugadores`, `servicio`…) y
todos se muestran ([`ADR-0020`](../../spec/decisions/0020-cheats-grupos-libres.md)).
El título de la sección sale del nombre de la clave, en mayúsculas y sin
guiones bajos: `dos_jugadores` → `DOS JUGADORES`.

Si querés un título que la clave no puede dar, usá la forma larga:

```json
"cheats": {
  "servicio": {
    "label": "Menú de servicio de la placa",
    "items": [ { "name": "Free Play", "input": "FREE PLAY = ON" } ]
  }
}
```

**Cada entrada se dibuja sola según su contenido**, no según el grupo: una
secuencia corta de botones (`← ← + ATAQUE`) sale como tarjeta con las teclas
dibujadas; una instrucción escrita sale como renglón con ★. Un mismo grupo
puede mezclar las dos.

#### Marcá los botones con `[corchetes]`

En una instrucción escrita en castellano, poné entre corchetes lo que sea un
botón. **Todo lo que quede afuera es texto, siempre**:

```json
{ "name": "9 créditos",
  "input": "En la selección: mantener [←] + [↓] y pulsar [A] + [START]" }
```

Sin los corchetes, la `a` y la `y` sueltas del castellano se dibujaban como
teclas A e Y en medio de la frase. Con corchetes eso no puede pasar.

Dentro de los corchetes va **un** botón, y se dibuja aunque no sea de los
conocidos: `[C]` sale como tecla igual. Un `input` **sin** corchetes usa la
notación de siempre (`↓ ↘ → + P`), así que los archivos que ya existen
siguen funcionando sin tocarlos.

Lo que **sí** valida `doctor` en cualquier grupo: que sea una lista (o un
objeto con `items`), y que cada entrada tenga `name` e `input` no vacíos.

## 6 · Sinopsis

Distinto de `data.json`: `library/<sistema>/_synopsis/<juego>.json` (junto a
`metadata.pegasus.txt`, no dentro de `media/`), con un solo campo:

```json
{ "summary": "texto de la sinopsis" }
```

Igual que las revistas, ATTRACT no la genera — la recibe de un sistema de
scraping externo ([`ADR-0011`](../../spec/decisions/0011-fuente-synopsis-regeneracion-campo.md)).
Con el archivo en su lugar:

```bash
python -m attract.synopsis dino library/arcade
```

Escribe el campo nativo `summary:` en el bloque `game:` correspondiente,
sin tocar ninguna otra línea del bloque.

**Dejar el `.json` NO alcanza — este comando no es opcional.** Pegasus lee el
`summary:` de `metadata.pegasus.txt`, nunca el archivo de `_synopsis/`:

```
_synopsis/dino.json  ──(attract synopsis)──>  metadata.pegasus.txt
    (la fuente)                                (lo que Pegasus lee)
```

Es la misma relación fuente/artefacto de
[`ADR-0002`](../../spec/decisions/0002-metadata-fuente-o-artefacto.md). Sin
correr el comando, el JSON puede estar perfecto y la pantalla igual muestra
"Sin Informacion" — es el tropiezo más común al cargar un juego. Y si más
adelante editás el texto del `.json`, hay que volver a correrlo.

## 7 · Validar todo

```bash
make doctor-lib
```

Corre `attract doctor` contra `library/` (real) con el criterio más estricto
(`--target windows`, porque Windows es la máquina de producción). Reporta
errores y avisos con la ruta exacta del archivo. Dos ejes independientes
(`docs/CONVENCION.md` §4):

- **VÁLIDA** = no rompe nada técnico (nombres legales en Windows, sin bytes
  inválidos, JSON bien formado, `assets.*` apuntando a archivos reales).
  Un juego recién ingestado sin ninguna imagen ya es válido.
- **COMPLETA** = tiene además cover, video, reseña, sinopsis, etc.

Un juego pelado (sin imágenes, sin video, sin reseña) tiene que dar
**siempre válido** — si `make doctor-lib` marca error en un juego así, algo
en el nombre de carpeta/archivo está mal, no en la falta de contenido.

### El error de `.DS_Store`, que va a pasar seguido

```text
[ERROR] basura-macos
    arcade/media/goldnaxe/.DS_Store
```

No lo creaste vos ni `ingest`: Finder escribe un `.DS_Store` en cada carpeta
que abrís en el explorador. Se borran y listo:

```bash
find library -name ".DS_Store" -type f -delete
```

Es **error y no aviso** a propósito: Pegasus escanea por extensión, y el
primo de este archivo (`._algo.zip`) termina en `.zip` y aparece como juego
fantasma en la colección. En el gabinete no hay quién lo diagnostique.

Van a volver a aparecer cada vez que navegues esas carpetas en Finder — no
es que el borrado "no funcionó".

## 8 · Si tocaste el theme

No hace falta para cargar un juego normal — el theme lee `library/` en
runtime, no necesita reinstalarse. Solo corré esto si modificaste algo
dentro de `themes/attract/`:

```bash
make theme         # producción
make theme-debug   # harness de debug (ADR-0001)
```

## Si algo falla

Los tres síntomas más comunes, en orden de frecuencia:

| Síntoma | Causa |
|---|---|
| La sinopsis no se ve, aunque el `.json` esté bien | Falta correr `attract synopsis` (§6) — el `.json` es la fuente, no lo que Pegasus lee |
| Cargaste todo y no aparece nada nuevo | Pegasus lee la librería **al arrancar**: ⌘Q y volver a abrir, no alcanza con volver al menú |
| `[ERROR] basura-macos` | `.DS_Store` de Finder (§7) |

Para el resto, ver [`docs/troubleshooting.md`](../troubleshooting.md). Si el
síntoma no está ahí, `make doctor-lib` casi siempre dice qué archivo y qué
regla — empezá por ese mensaje literal.
