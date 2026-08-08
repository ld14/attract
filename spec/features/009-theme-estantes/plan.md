# 009 · Librería con estantes — Plan

_Cómo se implementa lo descrito en `spec.md`. Respeta `constitution/`._

## Enfoque

Dos piezas nuevas de `core/` cargan con todo lo que hoy no tiene dueño, y
las pantallas quedan tontas:

- **`core/Catalog.qml`** es el único que ordena, filtra y arma estantes.
  Nadie más toca `api.allGames`. La razón no es purismo: ordenar 1200 juegos
  significa leer propiedades de 1200 `QObject`s, y si esa lectura queda
  repartida entre delegates se repite por frame sin que nadie lo note.
- **`core/Teclas.qml`** traduce el evento crudo a `esA/esB/esX/esY` y a una
  dirección. Se instancia una vez en `theme.qml` y baja por propiedad,
  **igual que `Paths`** y por el mismo motivo (ver el encabezado de
  `core/Paths.qml`: un singleton en subcarpeta necesita su propio `qmldir` y
  es el mecanismo del que menos se sabe contra este binario).

Lo que **no** se hace: un router global de input. El prototipo tiene un
`onKey(e)` con un `if` por estado (`.dc.html:567-618`) y el encabezado de
`theme.qml` ya explica por qué acá no: cada `FocusScope` maneja sus teclas y
el que está activo se lleva el foco. `Teclas` es un traductor, no un
despachador — no sabe qué pantalla está arriba y no debe saberlo.

El `region: 'tabs' | 'shelves'` del prototipo desaparece como variable: son
dos `FocusScope`, y "cambiar de región" es mover el foco.

## Implementación

1. `core/Teclas.qml` — `esA/esB/esX/esY(event)` sobre
   `api.keys.isAccept/isCancel/isDetails/isFilters`, más
   `direccion(event)` → `"izq"|"der"|"arriba"|"abajo"|""`. Nada más.
2. `core/Catalog.qml` — `toVarArray()` una vez + un array paralelo de claves
   primitivas (`orden`, `anio`, `nota`, `jugadas`, `ultima`, `genero`,
   `fav`) calculado **una sola vez**; expone `estantes` y recalcula solo
   cuando cambia pestaña, criterio, dirección o filtro.
3. `screens/Shelf.qml` — header (etiqueta + conteo real + chip `⇅` solo en
   CATÁLOGO) + `ListView` horizontal de `GameCard`.
4. `screens/BrowseScreen.qml` — barra + hero + `ListView` vertical de
   `Shelf`. Reemplaza a `LibraryScreen.qml`, que se borra.
5. `overlays/SortPanel.qml` — criterio, dirección, grilla de 26 letras o de
   años (1978 → el más nuevo del catálogo), y la fila AYUDA.
6. `ui/Leyenda.qml` — la barra inferior; cada pantalla publica su `[{k,l}]`.
7. `screens/GameCard.qml` — pasa a mostrar la carátula real con
   `ui/CoverImage.qml`; el `AccentWash` actual queda de último eslabón.

## 8 · Control ORDEN/SELECCIÓN — `design_handoff_home/sort-select-spec.md`

Sumado el 2026-08-09. Es la especificación completa del control de la barra
—modos, los 4 criterios, cómo cambia el tercer botón según modo+criterio, el
popover de valor, el atajo `X`, el efecto sobre el estante CATÁLOGO y su
tabla de combinaciones— y **reemplaza** el diseño anterior de este mismo
control (el "Decisiones" de abajo, tachado, documenta qué cambió y por qué).

Implementado tal cual el spec describe:

- **`core/Catalog.qml`** gana un `modo` real (0 Orden, 1 Selección) con
  `alternarModo()` aplicando las reglas de reseteo del §Botón 1 (criterio
  cae a LETRA si era NOTA/JUGADOS al entrar a Selección; el filtro se limpia
  siempre al volver a Orden), `ciclarCriterio()` acotado al set del modo
  actual (§Botón 2 / atajo `X`), y `elegirValor()` para el popover
  (§Botón 3 · Selección), que emite `filtroAplicado()` para el
  §Reseteo de navegación.
- El estante CATÁLOGO usa **dos pools**, no uno: el filtro de Selección es
  puntual de CATÁLOGO (§Efecto sobre el catálogo no menciona que CONTINUAR
  JUGANDO, MÁS JUGADOS ni los géneros se reduzcan) — los otros tres estantes
  siguen leyendo el pool sin filtrar.
- **`screens/BrowseScreen.qml`** dibuja los tres botones reales (MODO,
  CRITERIO, el contextual Botón 3) más el chip de filtro, todos navegables
  con foco direccional + `A` — el spec lo pide explícito ("como cualquier
  botón enfocable", §Atajo de teclado/joystick), así que la barra pasa a
  tener un único índice de foco plano sobre pestañas + estos controles, en
  vez de dos regiones separadas.
- **`overlays/SortPanel.qml`** se achica a **solo la grilla** de letras/años
  — el popover real del prototipo (`:784`) no incluye criterio ni dirección,
  esos ahora son botones propios y siempre visibles en la barra.

## Decisiones

- **Carátula real en la tarjeta, en vez del wash de color** — lo pide el
  handoff nuevo (`README.md` §Estantes) y revierte la decisión que documenta
  hoy el encabezado de `GameCard.qml`, tomada contra el mockup anterior. El
  wash no se borra: es el fallback cuando no hay carátula, que con
  `fixtures/` en 0 bytes es el caso más común.
- ~~**Panel de orden en `X`, en vez de los cuatro controles clickeables del
  prototipo** — el toggle de modo, la dirección y el popover de letras son
  `onClick` puros (`.dc.html:59-76`), y con el popover abierto solo responde
  Escape (`:571`). En un gabinete sin mouse, SELECCIÓN y el salto por letra
  no existen. Un botón que abre una superficie navegable preserva la función
  1:1 y cambia el gesto.~~ — **superada por §8**: `sort-select-spec.md`
  aclara que estos controles se navegan con foco direccional + `A` "como
  cualquier botón enfocable", no son `onClick` puro sin alternativa de
  mando. La premisa de este ítem (gamepad sin acceso) no es cierta y el
  panel unificado dejó de existir; el atajo `X` pasa a ciclar el criterio
  directo, igual que el click del Botón 2 en el prototipo.
- **`ListView` anidados, no `PathView`** — `PathView` no da un salto a
  índice limpio ni la misma virtualización. `GridView` queda reservado para
  los resultados de Buscar (010).
- **La barra de CONTINUAR JUGANDO mide `playTime`, no progreso** — Pegasus
  no expone nada parecido a `prog`; `playCount`, `playTime` y `lastPlayed`
  sí, y son read-only. Se anota en el código para que nadie la lea como
  "porcentaje del juego completado".
- **Dos pestañas (TODOS / FAVORITOS)** — es lo que define el README; las
  cuatro que dibuja hoy `LibraryScreen` son del mockup anterior.

## Riesgos

- **`api.keys.isDetails`/`isFilters` podrían no disparar en este binario.**
  Es el portón: sin `X` no hay acceso al orden. Se mide antes de escribir
  nada con `themes/experimentos/teclas-xy.qml`. Si falla, el plan B es mover
  el panel a los gatillos (`isNextPage`/`isPrevPage`) y hacer navegable la
  barra superior.
- **Foco anidado: el `ListView` de adentro podría comerse las flechas
  verticales.** Se mide con `themes/experimentos/estantes-perf.qml`. Si
  pasa, la salida es manejar las cuatro direcciones en el `FocusScope` de
  `BrowseScreen` y que los `ListView` no tomen foco propio.
- **Ordenar por NOTA no significa nada hasta que el pipeline escriba
  `rating:`.** `rating` vuelve `0.0` por default y no distingue "sin dato"
  (`docs/plataforma-pegasus.md` §2). Degrada —los `0` van al final— pero hay
  que decirlo en pantalla, no dejar un orden que parece roto.
- **Un juego puede aparecer en cuatro estantes a la vez**, y cada tarjeta
  trae su `GameData`. Lo sostiene el cache compartido (`core/DataCache.js`):
  la segunda aparición no vuelve a pedir el archivo.
