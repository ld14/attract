# 026 · Selector de plataforma — Plan

_Cómo se implementa lo descrito en `spec.md`. Respeta `constitution/`._

## Enfoque

El selector es una pantalla más de `theme.qml`, con el mismo patrón que
`library` y `detail`. El catálogo filtrado **no es código nuevo**: es
`BrowseScreen` con `Catalog` filtrado por colección. `Catalog` sigue siendo el
único dueño de `api.allGames`; las plataformas salen de las claves que ya carga.

## Árbol

```
themes/attract/
├─ core/
│  ├─ Catalog.qml           (mod)   `coleccion` (null = TODAS) filtra el pool; `plataformas`
│  ├─ Platforms.js          (nuevo) funciones puras: lista, data.json, video, carrusel, textos
│  ├─ Paths.qml             (mod)   `plataformaDe(game)`: la única que arma la ruta de `_platform/`
│  └─ PlatformData.qml      (nuevo) lee `<coleccion>/_platform/data.json` (XHR + DataCache.js)
├─ ui/DissolvePanel.qml     (nuevo) fundido de 4 bordes pintado encima, sin máscaras
├─ screens/
│  ├─ PlatformSelectScreen.qml (nuevo) el carrusel
│  └─ BrowseScreen.qml      (mod)   pill de plataforma en la barra → `volverPlataformas`
├─ fonts/                   (+2)    ChakraPetch-BoldItalic, JetBrainsMono-Bold (OFL)
└─ theme.qml                (mod)   pantalla "platforms" | "library" | "detail"
```

Se reusan tal cual: `ui/Leyenda.qml`, `core/Teclas.qml`, `ui/Background.qml`,
`ui/CrtOverlay.qml`, `core/DataCache.js`, `Paths.dirColeccionDe()`. `Tokens.qml` suma
`accentTodas` y los dos `FontLoader` nuevos.

## Implementación

1. `Catalog.qml` — cada clave guarda `colecciones` (nombres de `g.collections`) y
   `video` (`assets.video`). `_pool()` descarta lo que no está en `coleccion`.
   `plataformas` = `Platforms.lista(...)`: TODAS + una por colección, con `clave`
   (lo que se asigna a `coleccion`: `null` en TODAS), nombre, conteo, juego de
   muestra (de su ruta sale la carpeta `_platform/`) y juegos con video. `_pool(pest, filt, col)` recibe
   la colección por argumento, como la pestaña y el filtro. `buscar()` no la mira.
2. `Platforms.js` — sin QML, testeable con node: `lista()`,
   `leerDatos(texto)` (JSON tolerante → `{accent, abrev, nombre}` o defaults),
   `siguiente(videos, actual, azar)`, `mover()`/`alAzar()` del carrusel y los
   textos de barra, conteo y pill.
3. `PlatformData.qml` — ruta `Paths.plataformaDe(muestra)` =
   `dirColeccionDe(muestra) + "_platform/"`, al lado de `media/`; vale igual
   para `library/` y `fixtures/`. 404 no es error; cache por url en `DataCache.js`.
   Emblemas: busca `emblema.png`, `emblema_01.png`, … `emblema_99.png` por nombre
   (`Platforms.nombreEmblema` / `siguienteEmblema`) hasta el primer número que
   falte, cachea la lista por carpeta y elige uno al azar en cada visita, sin
   repetir el último mostrado (también al volver desde Home).
4. `theme.qml` — `pantalla` arranca en `"platforms"`. El selector nunca se destruye:
   su `indice` (un int, no el `currentIndex` de una vista) es lo que se conserva al
   volver. Aceptar fija `catalogo.coleccion = p.clave` y pasa a `"library"`.
5. `BrowseScreen.qml` — **`B` queda como hoy** (sube a la barra; desde la barra no
   la toma y llega a Pegasus). Se vuelve al selector con una pill `◄ FILTRO · <AB>` /
   `◄ SIN FILTRO` en la barra, que es el primer lugar de su foco (foco + `A` o
   click). La leyenda de Home no cambia.
6. `PlatformSelectScreen.qml` — barra (wordmark, etiqueta, logo opcional 104×30,
   total, reloj de 20 s), video 440×248 en 72/190, emblema desde 38 %, columna de
   texto con el hueco del video **siempre** reservado, flechas 40×120, leyenda.
7. Video — **un par `MediaPlayer` + `VideoOutput` nuevo por cada clip**, en un
   `Loader` que pasa por `null` (ADR-0029: este es el "segundo lugar que cambia
   de video sin cambiar de pantalla" que el ADR anticipa). Mismo patrón que
   `HeroVideoPreview.qml`: `videoActual` lo escribe un solo lugar, `muted` y
   loops imperativo (017), todo tolera player `null`. `muted`/`volume` quedan
   declarativos y cuelgan de `silenciado`, que baja de `theme.qml` y es la misma
   perilla que la de Home (tecla `S`): fijarlos a mano cortaría el binding y `S`
   dejaría de hacer efecto. Al terminar un clip o al
   cumplir `topeClip` (60 s, contados desde el primer `play()`), el que llegue
   primero, `Platforms.siguiente()`; con un solo video, el mismo desde el
   principio. Un clip que falla no se reintenta si es el único. Al salir de la
   pantalla se destruye el par.

## Decisiones

- **Assets de plataforma en `library/<coleccion>/_platform/`** — ADR-0035. Un
  `make reset-pegasus` los manda a la papelera con la colección.
- **Catálogo = Home filtrado**, no la grilla del prototipo: conserva estantes,
  orden, filas (ADR-0031) y búsqueda sin duplicar tarjeta ni foco.
- **Selector raíz; `B` en el selector no lo toma el theme.** Una leyenda que nombra
  una tecla muerta miente (ver encabezado de `ui/Leyenda.qml`), y comerse Escape
  deja a Pegasus sin su tecla (bug del 2026-08-09, `BrowseScreen.qml`).
- **`B` en Home no vuelve al selector** (decisión del autor, 2026-09-22): se
  conserva "B sube a la barra". La vuelta es la pill de la barra.
- **El acento baja por propiedad** (ADR-0013); `data.json` lo trae en hex. Sin
  conversión `oklch` en runtime: los hues del prototipo eran de relleno.
- **Sin máscara sobre el video**: el prototipo mostró una línea de 1 px en el
  canto de la capa acelerada. Su fundido se pinta encima (`DissolvePanel`), y
  sirve porque esa zona es casi negra pareja por el scrim.
- **El emblema sí se enmascara, por alfa** (`ShaderEffect`, misma técnica que
  `HeroVideoPreview.qml`). Pintarle fondo encima fue la primera versión y dejó
  dos negros en Pegasus: el fondo cambia con la altura y ningún color fijo
  coincide. La máscara es la del diseño, relativa a la caja.
- **El fondo con acento es el `Background` de siempre**, no el escenario opaco
  `#0a0c12` del prototipo, que tapaba el glow que el mismo diseño pide transicionar.
- **La columna de texto se ancla al hueco del video**, no al centro de la
  pantalla: con `justify-content:center` un nombre de dos renglones subía el
  bloque entero y el video con él.
- **El hueco del video se reserva siempre**: el nombre está debajo del panel.
- **`TODAS` no es una colección**: vive solo en `Platforms.js`, sin carpeta `_platform/`.
- **El sonido es uno solo para el theme** (decisión del autor, 2026-09-22): el
  estado vive en `theme.qml` y lo comparten Home y el selector; las pantallas
  avisan con `alternarSonido()` en vez de escribirlo.
- **`api.keys` para aceptar/cancelar**, flechas crudas, igual que 005.

## Riesgos

- **Filtro en `Catalog`**: toca el binding de todos los estantes. Se hace
  primero, con test node, y se verifica Home sin filtro antes de seguir.
- **Reusar el player deja el panel vacío en silencio** (ADR-0029, geometría del
  video anterior). Por eso un par nuevo por clip; se detecta mirando
  `VideoOutput.sourceRect` contra la resolución del archivo. Si crear un par por
  clip hace saltar el encadenado, el fallback es un clip por plataforma en loop.
- **Plataformas sin assets son el caso normal**: se verifica contra `fixtures/`
  (cero assets) antes que contra `library/`.
