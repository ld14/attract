# 026 · Selector de plataforma — Tareas

## 0 · Documentos

- [x] `spec.md`, `plan.md`, `tasks.md` desde el handoff, corregidos contra el theme real.
- [x] ADR-0035: assets de plataforma en `library/<coleccion>/_platform/` (antes
      `library/_platforms/<dir>/`; cambiado a pedido del autor el 2026-09-22).
- [x] Roadmap: 026 en curso.

## 1 · Datos (`core/`)

- [x] `Platforms.js` — lista, dir, data.json tolerante, siguiente video. Hecho
      cuando: `node --test tests/test_platforms.cjs` pasa.
- [x] `Catalog.coleccion` filtra el pool; `buscar()` lo ignora. Hecho cuando: el
      test muestra estantes y conteos solo de esa colección, y los `.cjs`
      existentes siguen verdes.
- [x] Revisión de las fases 0-1 aplicada: `_pool` recibe la colección por argumento,
      `clave` en cada plataforma (`null` en TODAS), `Object.create(null)` para los
      nombres, la ruta de los assets la arma `Paths.plataformaDe`.
- [x] ~~Verificar en Pegasus si aparece una colección con 0 juegos.~~ No aplica:
      `Platforms.lista` sale de los juegos, así que una plataforma vacía no puede
      existir. Solo vuelve si algún día se lee `api.collections`.
- [x] `PlatformData.qml` — lectura con cache (`DataCache.js`, por url). En
      qmlscene: con `data.json` da acento, nombre y abreviatura; sin él, neutro.
      Falta en Pegasus: corrupto → neutro, y que volver a enfocar no relea.

## 2 · Ruteo y Home filtrado

- [x] `theme.qml` con `"platforms"` inicial; el selector nunca se destruye y su
      `indice` es lo que se conserva. Falta en Pegasus: abre en el selector y el
      CRT sigue arriba de todo.
- [x] `BrowseScreen`: pill `◄ FILTRO · <AB>` / `◄ SIN FILTRO` como primer lugar de
      la barra → selector. `B` sin cambios (decisión del autor, 2026-09-22). En
      qmlscene: 2.ª plataforma → Home → pill → selector deja el foco en la 2.ª.
      Falta en Pegasus: con el mando, y el click.
- [ ] Home con `TODAS` idéntico al de antes de la feature (salvo la pill).

## 3 · Selector visual

- [x] Fuentes `ChakraPetch-BoldItalic` y `JetBrainsMono-Bold` + `FontLoader` en
      `Tokens.qml`. En qmlscene la itálica real carga.
- [x] Barra superior. En qmlscene: sin `logo.png` no queda hueco; con él, 104×30.
- [x] Columna de texto anclada al hueco 440×248 fijo, no al centro.
- [x] Emblema con fundido radial + lateral por alfa (`ShaderEffect`). En Pegasus
      con arte real: sin segundo negro ni costura alrededor de la imagen.
- [x] Flechas clickeables, `←`/`→` con vuelta, `X` a una distinta, `A` acepta.
      Falta en Pegasus: que responda al joystick, no solo al teclado.

## 4 · Video

- [x] `DissolvePanel` (Canvas encima, sin máscara). En Pegasus: funde los cuatro
      bordes y `PreserveAspectCrop` llena el panel (en qmlscene 5.9 no: salía
      encajado). Falta: mirar en movimiento que no aparezca una línea de 1 px.
- [x] Cadena aleatoria muda, un par `MediaPlayer` + `VideoOutput` nuevo por clip
      (ADR-0029). En qmlscene: `muted=true`, `loops=1`, y al llegar al final arranca
      otro juego de la misma plataforma. En Pegasus: `muted=true`, `loops=1`,
      reproduce, pasa a otro al cumplir el tope de 1 minuto y al terminar el clip
      (`EndOfMedia` llega; anotado en `docs/plataforma-pegasus.md`). Falta:
      `sourceRect` contra la resolución de cada clip.

## Cierre

- [ ] `make theme` y Pegasus real con `fixtures/` (cero assets) y `library/`.
- [ ] Comparar a ojo con `Diseños/design_handoff_platform_select/Preselector Plataforma.dc.html`.
- [ ] Validar cada criterio de `spec.md`; roadmap a Hecho; CLAUDE.md al día.
- [ ] Anotar para el autor: `library/<coleccion>/_platform/` tiene que entrar en `docs/CONVENCION.md`.
- [ ] Anotar en `docs/plataforma-pegasus.md` lo que se mida: `EndOfMedia` con
      `loops: 1`, `shortName` sin `shortname:` en el metadata, y si `files[0].path`
      de un `file:` que es carpeta (DOS) trae barra final.

## Evidencia

2026-09-22 · `node tests/test_platforms.cjs`: 8 pruebas contra las funciones
reales de `Platforms.js` y `Catalog.qml` (lista con TODAS, juego en dos
colecciones, filtro en todos los estantes y conteos, Buscar lo ignora, rutas de
`_platforms/`, `data.json` corrupto, cadena de videos). Los otros tres `.cjs`
siguen verdes (`test_favorites` ahora declara `coleccion` y `Platforms` en su
contexto). `make test`: 273 passed, 10 skipped. Nada verificado todavía en Pegasus.

2026-09-22 · Fases 2-4. `node tests/test_platforms.cjs`: 15 pruebas. El fixture
ahora arma los cuatro tipos de estante (antes solo CATÁLOGO), `_armar` se prueba
con la colección por argumento, y se suman `clave`, nombres heredados, `undefined`,
colección inexistente, `Paths.plataformaDe` (Windows, macOS, Steam), carrusel y
textos. `make test`: 273 passed, 10 skipped. `qmllint` sin errores.

Captura en **qmlscene (Qt 5.9.7 de anaconda), no en Pegasus**: el theme real con
un `api` de mentira (juegos `QtObject`, dos colecciones, dos clips reales de
`library/msdos/media/`) y `grabToImage`. Vale para layout y lógica; no vale para
fuentes del sistema, backend de video ni teclado físico. Hay que agregar
`import "."` a `theme.qml` para que Qt 5.9 resuelva el singleton `Theme` (solo en
la copia del harness; Pegasus 5.15 lo resuelve sin eso, verificado desde 005).

2026-09-22 · Assets movidos de `library/_platforms/<dir>/` a
`library/<coleccion>/_platform/` a pedido del autor (ADR-0035 corregido antes
de su primer commit). `Paths.plataformaDe` ya no sube un nivel ni usa
`dirDesdeRuta`, que se borró. `node tests/test_platforms.cjs`: 15 pruebas, la de
rutas con el caso DOS (`file:` que es carpeta). `qmllint` sin errores.

2026-09-22 · **Primera verificación en Pegasus real** (Qt 5.15.10, Windows, la
librería de `library/msdos/` con `_platform/logo.png` y `emblema.png`). Captura
con una sonda temporal en la copia instalada (`grabToImage` sobre `stage`,
Timer cada 2.5 s), porque `CopyFromScreen` de GDI no ve la superficie OpenGL de
Pegasus a pantalla completa: devuelve el splash. Tres bugs que qmlscene no mostró:

- **El selector arrancaba sin video.** `programarVideo()` leía `videos` dentro de
  `onPlataformaChanged`, cuando el binding todavía tenía la lista anterior (vacía
  al arrancar). Es la trampa que `HeroVideoPreview.reiniciar()` ya documenta.
  Ahora el timer se arma siempre y `videos` se lee al disparar.
- **El video era un rectángulo duro.** El panel arranca con opacidad 0 y el
  `requestPaint()` del `DissolvePanel` llegaba con el Canvas invisible, que no
  pinta ni encola (`plataforma-pegasus.md` §3). Repinta en `onVisibleChanged` y
  `onAvailableChanged`. Medido: el canto izquierdo pasa de 6 a 16 en ~90 px en
  vez de saltar.
- **Costura vertical en el borde del fundido del emblema**: pintaba (9,10,16)
  sobre una zona que vale (6,7,12). Ahora usa el color del scrim.

Y "1 PLATAFORMAS" → singular (`Platforms.cuenta`, con test).

2026-09-22 · **Tope de 1 minuto por juego** (pedido del autor). `topeClip`
(60 000 ms) cuenta desde el primer `play()` del clip; al cumplirse, o al llegar
`EndOfMedia` si el clip es más corto, pasa a otro juego al azar. `loops` queda
siempre en 1: con un solo video, vuelve a empezar el mismo. Medido en Pegasus
con una sonda temporal: con el tope bajado a 5 s, cuatro clips seguidos de
~5 s cada uno (Elvira → Out of This World → OutRun → Lemmings); con el tope en
60 s y `seek()` a 1.5 s del final, Twilight 2000 pasó solo a Golden Axe. Es la
primera medición de `EndOfMedia` en este binario: anotada en
`docs/plataforma-pegasus.md` §QtMultimedia.

2026-09-22 · **Dos negros alrededor del emblema** (captura del autor). El PNG es
transparente (24 % con alfa 0); el segundo tono lo pintaba el Canvas del fundido,
que ponía un negro fijo encima de un fondo que cambia con la altura: a y=150,
fondo (8,10,15) contra (6,7,12) pintado, con costura en x≈870 de 1920. Ahora un
`ShaderEffect` le baja el alfa al emblema con la máscara del diseño (radial
120%×118% en 68%/46% × lateral 0→16%) y no pinta nada. Medido en Pegasus: a
y=100 el fondo queda en (8,10,15) de punta a punta, sin salto.

2026-09-22 · **Varios emblemas por plataforma** (pedido del autor):
`emblema.png` y `emblema_1.png`, `emblema_2.png`, … buscados por nombre hasta el
primer número que falte (QML no lista carpetas). Uno al azar por visita, distinto
del último mostrado. Test node del orden de búsqueda (16 pruebas). Medido en
Pegasus con dos PNG sintéticos temporales en `library/msdos/_platform/` (ya
borrados): encontró 3, y tres visitas seguidas a Msdos mostraron
`emblema_1` → `emblema_2` → `emblema`.

2026-09-22 · Numeración de emblemas a **dos dígitos** (pedido del autor):
`emblema_01.png` … `emblema_99.png`, tope 99. `emblema_1.png` sin cero ya no se
toma. Tests actualizados.

2026-09-23 · **El video del selector suena** (pedido del autor; el handoff lo
pedía mudo). Volumen 0.3 lineal, el mismo que `HeroVideoPreview`, y `S` lo
silencia. El estado dejó de ser de `BrowseScreen`: vive en `theme.qml` y lo
comparten las dos pantallas, que avisan con `alternarSonido()`. La leyenda del
selector suma `S`. Medido en Pegasus: `volume=0.3 muted=false` al arrancar, y al
cambiar la perilla pasa a `0/true` y vuelve, sin reiniciar el clip.

2026-09-23 · La leyenda decía `A` · VER LIBRERÍA, y con teclado esa tecla no
hace nada: la A del prototipo es el botón del mando. `keys.accept` en el
gabinete es `D,Return,Enter,GamepadA` (`settings.txt`). Ahora dice
`↵` · SELECCIONAR, que sirve para el teclado y para el mando.
