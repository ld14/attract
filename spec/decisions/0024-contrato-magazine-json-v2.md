---
id: 0024
title: "Contrato de magazine.json v2: carpeta global, páginas en pages/ y startPage como número impreso (supersede 0010)"
status: accepted
date: "2026-08-10"
supersedes: 0010
superseded-by: null
tags: [data, backend, frontend]
---

# 0024 — Contrato de `magazine.json` v2

## Contexto

[`ADR-0010`](0010-contrato-magazine-json-extendido.md) amplió el contrato de
`magazine.json` a partir del primer archivo real (`se-micro80.pdf`, 71
páginas). Ese archivo se usó para deducir la **forma interna de
`articles[]`**, pero nunca se montó su carpeta completa contra el theme: los
fixtures se escribieron a mano y el theme se verificó contra ellos.

El 2026-08-10 se cargó la primera revista real **completa** —
`micromania-34`, 63 páginas, producida por el subsistema de
[`ADR-0009`](0009-frontera-produccion-consumo-revistas.md)— y aparecieron
tres desajustes que los fixtures no podían revelar, porque los fixtures los
escribimos nosotros con el contrato ya en la mano.

### 1. Una revista cruza sistemas, pero la carpeta cuelga de uno

`micromania-34` tiene artículos de Golden Axe (arcade), Dr. Mario (NES) y
The Secret of Monkey Island (PC). ADR-0008 puso la carpeta en
`<sistema>/media/_magazines/<id>/` y ADR-0010 lo dejó explícitamente sin
cambiar. Con esa ruta, cubrir los tres sistemas obliga a **copiar la revista
entera tres veces**: en este caso ~80 MB de páginas más 25 MB del PDF de
origen, por sistema.

Eso contradice el motivo por el que la revista es una entidad aparte y se
referencia por `ref` en vez de copiarse dentro de cada juego
([`ADR-0001`](0001-transporte-datos-ricos.md) §"Por qué `mags` es referencia
y no copia"). La relación muchos-a-muchos no se detiene en el borde de un
sistema, y la estructura de carpetas sí lo hacía.

### 2. Las páginas viven en una subcarpeta `pages/`

El generador deja esta estructura:

```
micromania-34/
├─ magazine.json
├─ cover.jpg
├─ source.pdf          ← el PDF de origen
├─ game_hints.json     ← índice auxiliar del generador
└─ pages/
   ├─ p002.jpg
   └─ …
```

Pero `magazine.json → pages[]` trae el nombre **pelado** (`"p002.jpg"`), sin
el `pages/`. El theme armaba `<rev>/ + p002.jpg` y las 63 páginas daban 404:
el visor abría vacío sin ningún error visible.

### 3. `startPage` es el número de página **impresa**, no un índice

ADR-0010 mostró el ejemplo `"pages": ["p002.jpg", "..."]` sin definir cómo
se resuelve `startPage`. La spec de la feature 006 cerró la duda a favor de
"índice 1-based sobre `pages[]`", razonando sobre el fixture
`micromania-16` — que tiene 8 páginas numeradas `p001`…`p008`, donde las dos
interpretaciones coinciden y por lo tanto no distinguen nada.

En la revista real no coinciden. `pages[]` **arranca en `p002.jpg`**: la
página 1 es la tapa y vive aparte en `cover.jpg`. Entonces:

```
pages[0]  = p002.jpg
pages[44] = p046.jpg   ← el artículo de Golden Axe
pages[45] = p047.jpg   ← donde el theme abría, con startPage 46
```

Una página corrida en todos los artículos. Y al final de la revista deja de
ser un corrimiento y pasa a ser un error duro: hay un artículo con
`startPage: 64` (la página impresa 64, archivo `p064.jpg`, que existe) sobre
una lista de 63 elementos. `attract doctor` lo reportaba así:

```
articles[44].startPage=64 fuera de rango: pages[] tiene 63 paginas,
el indice va de 1 a 63
```

El validador tenía razón bajo el contrato viejo, y el contrato viejo estaba
mal: `64` no es un índice fuera de rango, es un número de página que existe.

## Decisión

Se **supersede** ADR-0010 con tres cambios. El resto del contrato —
`name`, `issue`, `year`, `color`, `cover`, `key_id`, y toda la forma interna
de `articles[]` con `type`/`confidence`/flags de reseña— queda **igual**.

### 1. La revista vive en `<raíz-librería>/_magazines/<id>/`

Fuera del árbol de cualquier sistema, hermana de las colecciones:

```
library/
├─ _magazines/
│  └─ micromania-34/
├─ arcade/
│  └─ media/goldnaxe/data.json   → mags: [{ref: "micromania-34"}]
├─ nes/
└─ pc/
```

Los tres sistemas referencian la misma carpeta. El theme la resuelve como
`<dir-colección>/../_magazines/<ref>/`, un solo nivel arriba del directorio
que Pegasus tiene en `game_dirs.txt`.

### 2. Las páginas se buscan **siempre** en `<rev>/pages/`

`pages[]` sigue trayendo el nombre pelado; el prefijo lo pone el consumidor,
en un solo lugar. `cover` **no** lleva el prefijo: la tapa vive en la raíz de
la revista.

Esto vale también para los fixtures, que se normalizan a la misma forma. Un
solo camino de resolución, sin fallback al layout plano.

### 3. `startPage` y `articles[].pages` son números de página **impresa**

Se resuelven **buscando el archivo** `p{NNN}` dentro de `pages[]`, no
contando posiciones:

```
startPage: 46  →  buscar "p046" en pages[]  →  índice 44  →  pages/p046.jpg
```

Un número que no aparece en `pages[]` es un `-1`, que el theme degrada a la
primera página en vez de romper. `attract doctor` valida contra el **conjunto
de números de archivo observados**, no contra `1..len(pages)`.

La regla es más robusta que la aritmética que reemplaza: no asume nada sobre
en qué página arranca `pages[]` ni sobre que la numeración sea continua.

## Alternativas consideradas

### Que ATTRACT normalice el `magazine.json` entrante al contrato viejo

Un comando que aplane `pages/` un nivel arriba y reescriba cada `startPage`
restándole el offset de arranque.

- A favor: el theme y el validador no se tocan. Todo el ajuste queda en un
  solo comando de ingesta.
- En contra: ATTRACT pasa a **modificar** un archivo que no produce, que es
  exactamente la frontera que ADR-0009 trazó. Y no es una conversión de una
  sola vez: cada vez que el subsistema regenere la revista (mejor OCR, nueva
  clasificación) hay que volver a correr la normalización, o la revista queda
  rota en silencio hasta que alguien la abre.
- **Descartada porque:** viola ADR-0009 y convierte un cambio de lectura en
  una obligación de mantenimiento permanente. El precedente de ADR-0010 ya
  fijó el criterio: *"el contrato tiene que reflejar la realidad, no una
  suposición temprana"*.

### Que el generador emita `"pages/p002.jpg"` en `pages[]`

- A favor: cero cambios en el consumidor; la ruta viaja dentro del dato.
- En contra: el generador está fuera del alcance de ATTRACT (ADR-0009) y no
  hay forma de pedirle un cambio hoy. Además metería una decisión de layout
  de disco adentro del contrato de datos, que es justo lo que hace difícil
  moverlo después.
- **Descartada porque:** no es una decisión que ATTRACT pueda tomar, y
  esperar a que otro sistema cambie bloquea la carga de revistas reales.

### Mantener `media/_magazines/` y compartir con symlinks

- A favor: cambio cero en el theme y en el validador.
- En contra: los symlinks no sobreviven al copiado a Windows, que es el
  destino real del gabinete ([`ADR-0003`](0003-cross-platform.md)). La
  librería viaja como árbol de archivos.
- **Descartada porque:** rompe en la única plataforma que importa para
  producción, y `attract doctor` existe precisamente para que eso falle en el
  Mac antes de viajar.

### Búsqueda hacia arriba de `_magazines/` (probar `../`, `../../`, …)

- A favor: tolera cualquier profundidad de anidado de las colecciones.
- En contra: N peticiones fallidas por juego contra `file://`, y una regla
  que no se puede explicar en una línea en `docs/CONVENCION.md`.
- **Descartada porque:** paga complejidad y latencia por una flexibilidad que
  nadie pidió; la convención de un nivel alcanza para la estructura que el
  proyecto ya usa.

## Consecuencias

**Positivas**

- Una revista se copia **una sola vez**, sin importar cuántos sistemas cubra.
  Con `micromania-34` sobre tres sistemas, ~210 MB ahorrados.
- El theme lee el `magazine.json` tal como el generador lo dejó. Regenerar
  una revista no exige ningún paso intermedio.
- La resolución por número de archivo no depende de dónde arranque `pages[]`,
  así que tolera revistas con páginas faltantes o numeración discontinua —
  algo que un escaneo real produce sin avisar.
- `attract doctor` gana un chequeo que antes no existía: que cada entrada de
  `pages[]` y el `cover` resuelvan a un archivo real. El síntoma de este bug
  era una pantalla en blanco, el peor lugar para enterarse.

**Coste asumido**

- Los cuatro fixtures de `_magazines/` se mueven a `fixtures/_magazines/` y
  sus páginas a `pages/`. Verificado antes de mover: las cuatro arrancan en
  `p001`, así que la regla nueva les da **índices idénticos** a la vieja
  (`hobby-consolas-01` 4→3, `micromania-16` 3,6→2,5, `pcjuegos-32` 2→1,
  `se-micro80` 1→0). Ningún comportamiento observable cambia salvo el de
  `micromania-34`, que hoy está roto.
- La ruta `../_magazines/` asume que la colección es hija directa de la raíz
  de la librería. Es la estructura que el proyecto ya usa en `fixtures/` y
  `library/`, y queda escrita en `docs/CONVENCION.md`.
- `source.pdf` y `game_hints.json` conviven en la carpeta de la revista sin
  que nada los consuma. No se borran: son del generador, no nuestros.

**Qué habría que revisar si esto se replantea**

- Si aparece una revista cuyas páginas **no** estén en `pages/`, o cuyo
  `startPage` no se corresponda con el número del archivo, quiere decir que
  el generador cambió de forma otra vez y este ADR se vuelve a superseder —
  no se edita, y no se agrega un fallback que soporte las dos formas.
- Si alguien necesita montar una colección que no sea hija directa de la raíz
  de la librería, la convención de un nivel deja de alcanzar y hay que
  reabrir la alternativa de la ruta configurable.

## Verificaciones pendientes

- [ ] Con la revista real en Pegasus: el carrusel muestra la tapa de
      `micromania-34`, abrir sobre Golden Axe cae en `p046.jpg` (el número
      impreso es visible en el escaneo), las miniaturas destacan 46/47/48 y
      las 63 páginas hojean sin ninguna en blanco.
- [ ] Que las cuatro revistas de `fixtures/` se comporten exactamente igual
      que antes del cambio.
- [ ] Que el manual (`media/<set>/_manual/`, layout **plano**, ADR-0014) siga
      abriendo bien: comparte `DocumentViewer` y `DocModel` con la revista,
      así que es la regresión más probable del prefijo `pages/`.

## Referencias

- [`0010-contrato-magazine-json-extendido.md`](0010-contrato-magazine-json-extendido.md)
  — ADR superseded por esta.
- [`0009-frontera-produccion-consumo-revistas.md`](0009-frontera-produccion-consumo-revistas.md)
  — por qué el archivo del generador no se toca.
- [`0001-transporte-datos-ricos.md`](0001-transporte-datos-ricos.md) — por qué
  la revista se referencia y no se copia.
- [`0025-link-revista-juego-difuso.md`](0025-link-revista-juego-difuso.md) —
  cómo se llena `mags[]` a partir de esta estructura.
- `library/_magazines/micromania-34/` — la revista real que motivó este ADR
  (63 páginas, 20 artículos con `game`).
