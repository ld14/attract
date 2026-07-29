---
id: 0014
title: "El manual digitalizado vive en media/<set>/_manual/, declarado en data.json"
status: accepted
date: "2026-07-29"
supersedes: null
superseded-by: null
tags: [data, frontend]
---

# 0014 — El manual digitalizado vive en `media/<set>/_manual/`

## Contexto

El diseño de referencia tiene, entre las tarjetas de CONTENIDO EXTRA del
detalle, una entrada **"Manual digitalizado · {n} págs"** que abre el mismo
visor paginado que las revistas
(`design_handoff_game_detail/README.md` §2 y §3).

El manual **no existe en ninguna parte del modelo de datos de ATTRACT**. El
handoff afirma que mapea a "the project's already-planned `x-manual` field",
pero eso no es cierto: `x-manual` no aparece en ningún fixture, ningún ADR,
ningún test ni en `docs/CONVENCION.md`. Es una suposición del handoff sobre
un campo que nunca se definió. `CONVENCION.md` §2.1 lo lista como
`data.json / x-` — es decir, sin decidir.

Hay que decidirlo antes de poder implementar el visor, porque el visor
necesita saber **qué archivos abrir**, no solo cuántos son.

Dos restricciones ya cerradas acotan el espacio:

- **Las páginas son imágenes, jamás PDF**
  ([`ADR-0007`](0007-paginas-revista-imagenes-no-pdf.md), confirmada contra
  Pegasus real: `themes/experimentos/pdf-qtquick.qml` ni siquiera deja cargar
  el theme). Un manual escaneado es un PDF en la vida real, así que alguien
  tiene que convertirlo a imágenes — igual que con las revistas.
- **Los datos ricos no van en `metadata.pegasus.txt`**
  ([`ADR-0001`](0001-transporte-datos-ricos.md), límite duro de
  `spec/constitution/tech-stack.md`).

## Decisión

Las páginas del manual son imágenes que viven en una subcarpeta de la carpeta
del propio juego, y se declaran en su `data.json`:

```
media/
└─ <set>/
   ├─ boxFront.jpg          ← assets nativos, auto-descubiertos por Pegasus
   ├─ data.json             ← declara el manual (entre otras cosas)
   └─ _manual/
      ├─ p001.jpg
      └─ p002.jpg …
```

```json
{ "manual": { "pages": ["p001.jpg", "p002.jpg", "..."] } }
```

**`manual.pages[]` tiene deliberadamente la misma forma que
`magazine.json → pages[]`** ([`ADR-0010`](0010-contrato-magazine-json-extendido.md)):
una lista ordenada de nombres de archivo, con ceros a la izquierda para que el
orden alfabético coincida con el orden real. Esa simetría es el punto: el
visor de documentos consume **un solo modelo de páginas** y no necesita saber
si está mostrando una revista o un manual. El handoff ya pedía que fuera un
visor compartido; esto es lo que lo hace posible sin una capa de traducción.

El prefijo `_` en `_manual/` sigue la convención ya usada por `_magazines/` y
`_synopsis/`: separa lo que es una colección de páginas de lo que son assets
nativos que Pegasus auto-descubre en `media/<set>/`.

**Sin `manual` en el `data.json`, o con `pages: []`**, la tarjeta de CONTENIDO
EXTRA muestra `"No Disponible"` según `docs/CONVENCION.md` §2.3 — no
desaparece.

**Igual que con las revistas** ([`ADR-0009`](0009-frontera-produccion-consumo-revistas.md)),
ATTRACT es **consumidor** de este contrato, no productor: escanear el manual y
convertirlo a imágenes por página lo hace un humano hoy y un subsistema
mañana. El visor no sabe ni le importa quién generó los archivos, solo que
respeten el contrato.

## Alternativas consideradas

### A · `x-manual: <n>` en `metadata.pegasus.txt`

Lo que el handoff pide literalmente.

- A favor: un solo campo, sin archivos nuevos; el theme lo lee de
  `game.extra["manual"][0]` sin ninguna petición extra.
- En contra: dos problemas independientes, cada uno alcanza para descartarla.
  Primero, **rompe el límite duro de ADR-0001** — los datos ricos no van en
  el metadata, y ese metadata además es artefacto de build, no fuente
  ([`ADR-0002`](0002-metadata-fuente-o-artefacto.md)). Segundo, y más
  concreto: **un número de páginas no dice qué archivos abrir.** El visor
  necesita rutas. Con `x-manual: 12` habría que inventar una convención
  implícita de nombres (¿`p001.jpg`? ¿`.png`? ¿desde 0 o desde 1?) que no
  está escrita en ningún lado y que rompe en silencio en cuanto un escaneo
  no la cumple.
- **Descartada porque:** viola un límite duro vigente y, aun ignorando eso,
  no transporta el dato que el visor realmente necesita.

### B · Entidad propia en `media/_manuals/<set>/manual.json`

Simétrica a `_magazines/`: el manual como entidad de primera clase, con su
propio JSON, referenciada por `ref` desde el `data.json` del juego.

- A favor: máxima simetría con el modelo de revistas ya existente; un solo
  patrón mental para "colección de páginas escaneadas".
- En contra: agrega un `ref` que resolver y una segunda lectura de JSON
  encadenada, a cambio de nada.
- **Descartada porque:** la razón concreta que justificó separar las revistas
  **no aplica a un manual.** Las revistas se separaron porque *una revista
  cubre varios juegos* y guardarla dentro de cada uno duplicaría el escaneo
  N veces (ADR-0010, y el razonamiento original en
  `docs/decisiones/2026-07-23.md` §5). Un manual pertenece a **un solo
  juego** — no hay duplicación que evitar. Copiar la estructura sin copiar el
  problema que la motivaba es simetría decorativa: paga el coste (indirección,
  un XHR más, una carpeta más que mantener) sin cobrar el beneficio.

## Consecuencias

**Positivas**

- El visor de documentos consume un solo modelo de páginas para revistas y
  manuales. Un componente, no dos.
- El manual viaja con el juego: mover o borrar `media/<set>/` se lleva todo
  lo del juego, sin referencias colgadas en otra carpeta.
- Una sola lectura de JSON (el `data.json` que el theme ya carga igual), sin
  cadena de dos como en las revistas.
- Respeta ADR-0001 y ADR-0007 sin excepciones ni casos especiales.

**Coste asumido**

- Convertir un PDF de manual a imágenes por página es trabajo manual hoy,
  igual que con las revistas (ADR-0007 ya asumía este coste para revistas;
  esto lo extiende a manuales).
- Si dos juegos compartieran manual (una compilación, un mismo juego en dos
  colecciones), el escaneo se duplicaría. Se acepta: es un caso raro, y el
  día que aparezca de verdad la salida es un ADR nuevo que lo mueva a
  entidad propia — no adelantarse hoy a un problema que no existe.
- `data.json` puede declarar páginas que no están en el disco. `attract
  doctor` tiene que chequearlo (queda pendiente en
  [`ADR-0015`](0015-contrato-data-json.md)).

**Qué habría que revisar si esto se replantea**

- Que aparezca un manual real compartido por más de un juego — ahí la
  alternativa B pasa a tener el mismo motivo que tuvieron las revistas.
- Que el número de páginas de un manual haga inviable listarlas todas en el
  `data.json` (un manual de 200 páginas son 200 strings). Si molesta, la
  salida es permitir un patrón (`"pages": "p###.jpg", "count": 200`), no
  cambiar de ubicación.

## Referencias

- `design_handoff_game_detail/README.md` §2 (tarjeta "Manual digitalizado") y
  §3 (visor compartido con las revistas).
- [`ADR-0007`](0007-paginas-revista-imagenes-no-pdf.md) — páginas como
  imágenes, con la contraprueba de PDF corrida contra Pegasus real.
- [`ADR-0010`](0010-contrato-magazine-json-extendido.md) — la forma de
  `pages[]` que este ADR replica a propósito.
- [`ADR-0009`](0009-frontera-produccion-consumo-revistas.md) — el mismo
  reparto productor/consumidor, aplicado acá a los manuales.
- `docs/CONVENCION.md` §2.1, fila `manual` — el `data.json / x-` sin decidir
  que este ADR cierra.
