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
library/arcade/media/_magazines/micromania-16/
├─ magazine.json
├─ cover.jpg
├─ p001.jpg
├─ p002.jpg
└─ …
```

- El guión bajo en `_magazines/` es a propósito: separa la carpeta de
  revistas de las carpetas de juego.
- Las páginas llevan ceros a la izquierda (`p001.jpg`, no `p1.jpg`) para
  que el orden alfabético sea el orden real de lectura.
- **Una revista cubre varios juegos** — se deja **una sola vez** en
  `_magazines/`, nunca copiada dentro de cada juego que aparece en ella.

El juego la referencia desde su propio `data.json` (siguiente sección), sin
copiar ninguna página:

```json
{ "mags": [ { "ref": "micromania-16" } ] }
```

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
    "combos": [ { "name": "Patada giratoria", "input": "↓ ↘ → + K" } ],
    "codes":  [ { "name": "Modo 3 jugadores", "input": "En el test menu: PLAYERS 3" } ]
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

## 8 · Si tocaste el theme

No hace falta para cargar un juego normal — el theme lee `library/` en
runtime, no necesita reinstalarse. Solo corré esto si modificaste algo
dentro de `themes/attract/`:

```bash
make theme         # producción
make theme-debug   # harness de debug (ADR-0001)
```

## Si algo falla

Ver [`docs/troubleshooting.md`](../troubleshooting.md). Si el síntoma no
está ahí, `make doctor-lib` casi siempre dice qué archivo y qué regla —
empezá por ese mensaje literal.
