# 018 · Galería de imágenes y videos — Plan

_Cómo se implementa lo descrito en `spec.md`. Debe respetar la `constitution/`._

## Enfoque

Casi todo esto ya existe en el theme y se **reusa por forma, no por herencia**.
La anatomía del modal —encabezado con contador, escenario centrado, flechas ‹ ›,
riel de miniaturas, leyenda propia al pie— es exactamente la de
[`overlays/DocumentViewer.qml`](../../../themes/attract/overlays/DocumentViewer.qml),
y de ahí se copia la **estructura de anclajes**, que es la parte que ya costó
sangre (el `pie` anclado a `leyenda.top` y la leyenda anclada al borde real de la
pantalla, para no armar un binding loop).

Pero **no es el mismo visor**. `DocModel` existe para que revista y manual sean
UN solo visor, y el motivo es que las dos son la misma cosa: una lista ordenada
de imágenes. Una galería con video no lo es. Meterle un tercer `tipo` a `DocModel`
obligaría a `DocumentViewer` a cargar zoom, paneo, pestañas y PDF —nada de lo cual
la galería usa— y a ramificar el escenario por tipo de pieza. Va como overlay
propio, con el mismo mecanismo `Loader` que ya usan trucos, ayuda y el visor.

El resto de la feature es cableado chico en piezas que ya tienen el patrón hecho:
`GameData` ya normaliza `manual`, `Paths` ya arma `_manual/`, `ExtrasList` ya
dibuja tarjetas con subtítulo recortado, `doctor` ya valida el contrato de
`data.json` y ya chequea que las páginas del manual existan en disco.

## Implementación

1. `themes/attract/core/Paths.qml` — `galeriaDe(game)` → `media/<set>/_gallery/`.
   Tres líneas, calcadas de `manualDe()`.
2. `themes/attract/core/GameData.qml` — `galeria`: **la composición** de
   ADR-0030, ya **resuelta a URLs** y con la forma de pieza fijada acá y en
   ningún otro lado: `{ tipo: "img"|"vid", src: <url o "">, label: <string> }`.
   `GameData` ya recibe `paths`, así que resuelve lo curado con
   `paths.galeriaDe(game)` y toma los nativos de `game.assets[...]`, que ya son
   URLs — mismo reparto que `core/DocModel.qml:93` con las páginas del manual.
   El `file` del contrato solo existe adentro de `GameData`; de ahí para afuera
   la pieza viaja como `src`. La composición sigue el orden de
   ADR-0030 (`video → screenshot → gallery[] → boxFront → poster → marquee`),
   salteando lo ausente y poniéndole a cada nativo su label fijo. Más
   `hayGaleria`, `galeriaVideos` y `galeriaImagenes` para el subtítulo. Es el
   único lugar que conoce ese orden — mismo criterio que `ui/CoverImage.qml` con
   la cadena de carátula. El tipo sale de la extensión, con las dos listas
   explícitas del ADR.
3. `themes/attract/screens/ExtrasList.qml` — tercera tarjeta, **primera del
   modelo** (ver §Riesgos). Glifo `▣`, etiqueta "Galería", y `_subGaleria()` con
   los dos niveles de `_acortar()` que ya usa `_subCheats`: detalle
   `"1 video  ·  5 imágenes"`, resumen `"6 piezas"`. Además el ancho de la
   tarjeta baja de **250 a 200** y `_anchoSubtitulo` de **22 a 13**, porque tres
   tarjetas de 250 no entran (ver §Decisiones y §Riesgos). Ese recorte le pega
   también a `_subCheats`: su resumen actual (`"6 entradas · 2 grupos"`, 21
   caracteres) deja de entrar, así que necesita un tercer nivel más corto
   (`"6 entradas"`) o cae a `"Ver detalle"` en casi todos los juegos.
4. `themes/attract/screens/DetailScreen.qml` — `_targets: 5 → 6`, las ramas de
   aceptar pasan a `3 = galeria`, `4 = cheats`, `5 = manual`, y el botón de
   volver cambia su texto a `"BIBLIOTECA"`.
5. `themes/attract/overlays/GalleryOverlay.qml` — **nuevo**. Recibe
   `piezas` (la lista ya resuelta a URLs), `titulo`, `accent` y `fondo` —este
   último es el que desenfoca detrás, igual que `CheatsOverlay` y
   `DocumentViewer`, que reciben `fondo: detalle`—; emite `cerrar()`.
   Encabezado (chip VIDEO/IMAGEN + label + título del juego + contador + ✕),
   escenario con `Loader` por pieza, flechas solo si `total > 1`, riel
   `ListView` horizontal, y su propia leyenda al pie.
6. `themes/attract/theme.qml` — `Loader { id: galeria }` al lado de `trucos`, la
   rama `tipo === "galeria"` en `onAbrirExtra`, y `!galeria.active` sumado al
   `focus` del detalle. Las piezas llegan ya resueltas desde
   `detalle.datosDelJuego.galeria`, igual que `CheatsOverlay` recibe
   `datos: detalle.datosDelJuego`: ningún componente de `overlays/` concatena
   rutas, y `theme.qml` tampoco tiene que armarlas.
7. `src/attract/doctor.py` — `gallery` dentro de `chk_data_contrato`, con la
   verificación de existencia calcada de `_chk_manual_doc()`. Dos detalles que
   no son obvios: hace falta un `avisa()` al lado del `falla()` que ya tiene la
   función (`rep.aviso` existe, `doctor.py:55`, precedente `chk_mags_ref`), y el
   `file: ""` se evalúa **antes** que la regla de extensión — si no, un declarado
   sin archivo cae en "extensión desconocida" y sale como error en vez de aviso.
8. `fixtures/arcade/media/dino/` — `_gallery/` con dos imágenes generadas y
   **una pieza con `file: ""`**, más el `gallery` correspondiente en `data.json`.
   La pieza vacía es la que hace observable §7; sin ella el placeholder no se
   puede verificar nunca. **La galería de `dino` no tiene video**: en `fixtures/`
   no hay un solo archivo de video, y el bloque `game: EXPERIMENTO` de
   `metadata.pegasus.txt` no declara ningún asset. `dino` queda con carátula,
   marquesina y las tres curadas — cinco piezas, cero videos, que es además el
   caso "conteo en cero" del subtítulo. La pieza `vid` y ADR-0029 se verifican
   contra `library/` (Final Fight), no contra el fixture: sumar un mp4 a
   `fixtures/` sería una tercera excepción a la regla de los 0 bytes para
   verificar algo que la librería real ya permite verificar.

## Decisiones

- **La tarjeta se llama "Galería" y el botón de volver pasa a "◄ BIBLIOTECA"** —
  resuelve la colisión de §1 del diseño de referencia. Se renombra el botón
  porque es el que tiene el nombre equivocado: esa pantalla se llama `libreria`
  en `theme.qml`, su componente es `BrowseScreen` y el roadmap la nombra
  "Librería". "Galería" queda para lo que el usuario entiende por galería.
  Descartado renombrar la tarjeta a "Capturas" (miente cuando hay video) o a
  "Multimedia" (palabra que no aparece en ningún otro lado del proyecto).
- **La tarjeta está siempre, aunque el juego no tenga galería** — CONVENCION #2.3
  le gana a §1 del diseño de referencia, que la pedía condicional. Es la misma
  divergencia consciente que `ExtrasList.qml` ya documenta en su encabezado, y
  tiene un segundo beneficio acá: el ciclo de foco del detalle queda de largo
  **fijo** (6 targets siempre) en vez de variar entre 3 y 6 según el juego, que
  es justo la clase de estado que §5 marca como fuente de bug.
- **El contrato es el que COINDOOR ya emite, no uno nuevo** — `{ file, label }`,
  tipo por extensión, archivos en `_gallery/`. Verificado sobre
  `files_install/final-fight.coindoor.zip` el 2026-08-27. La primera versión del
  ADR-0030 inventó `{ k, src, label }` sin abrir los paquetes; se corrigió contra
  el dato real. Ver [`ADR-0030`](../../decisions/0030-contrato-gallery-data-json.md).
- **Los assets nativos se suman a las piezas curadas**, en el orden fijo del
  ADR-0030. Sin eso, 7 de los 8 paquetes reales tendrían la tarjeta apagada:
  solo Final Fight trae `_gallery/`. Costo aceptado a ojo abierto: `boxFront`,
  `poster` y `marquee` ya se ven en la columna derecha del detalle.
- **Las tres tarjetas pasan de 250 a 200px de ancho, y el subtítulo de la
  galería cuenta piezas** — es una consecuencia medida, no una preferencia.
  `extras` arranca en x=376 (`gutter 48 + izquierda 280 + 48`) y la columna
  `derecha` en x=1042; tres tarjetas de 250 con `spacing: 14` terminan en 1154,
  y `ReviewCard` con un veredicto largo baja hasta y≈620 contra un `extras` que
  arranca en y≈557 con el canvas de 720. O sea que **el choque depende del largo
  de la reseña del juego**: aparece en unos juegos y en otros no, que es la peor
  forma de un bug de layout. Con 200px la fila mide 628 y entra con margen en los
  634 disponibles. El costo es el presupuesto de texto: `_anchoSubtitulo` es
  proporcional al ancho (250px → 22 caracteres), así que baja a ~13 y el desglose
  `"1 video  ·  12 imágenes"` deja de entrar. Por eso el subtítulo de la galería
  es `"N piezas"` en la práctica, con el desglose como primer nivel de
  `_acortar()` para las galerías chicas. Descartado envolver la fila en dos
  renglones (cambia la forma de CONTENIDO EXTRA y come el `bottomMargin: 72`) y
  descartado dejar 250 y esperar que no choque.
- **Overlay propio en vez de un tercer `tipo` de `DocModel`** — ver §Enfoque.
- **Un `MediaPlayer` + `VideoOutput` nuevo por pieza de video, dentro de un
  `Loader`** — no es una preferencia, es
  [`ADR-0029`](../../decisions/0029-player-nuevo-por-video.md): un player reusado
  entre archivos deja la superficie con la geometría del video anterior y el panel
  sale vacío, sin error y con `status` en `Buffered`. El `Loader` cubre además el
  requisito de §7 (ver §Riesgos).
- **El modal dibuja su propia leyenda**, como ya hace `DocumentViewer`. Es la
  traducción a QML de §6: el bug del prototipo (una cadena de ramas donde la
  genérica de detalle gana) **no puede ocurrir acá**, porque `DetailScreen` no
  tiene barra de leyenda — la única `Leyenda` del theme vive en `BrowseScreen` y
  es fija. El requisito sobrevive igual: la leyenda del modal nombra ◄ ► y B/Esc
  y nada más, por la misma regla de `ui/Leyenda.qml` (una leyenda que miente es
  peor que no tenerla).
- **`gallery` extiende el contrato de `data.json`** → ADR nuevo, como
  [`ADR-0020`](../../decisions/0020-cheats-grupos-libres.md) hizo con `cheats`.
  [`ADR-0015`](../../decisions/0015-contrato-data-json.md) no se edita.

## Riesgos

- **§5 — los índices de foco se corren.** Se mitiga poniendo la tarjeta de
  galería **primera en el modelo de `ExtrasList`**: así `foco: root.foco - 3`
  sigue valiendo tal cual y solo se mueven `_targets` y las tres ramas de
  aceptar de `DetailScreen`. Si igual se cuela, el criterio de aceptación
  "aceptar sobre Hacks abre Hacks" lo caza en la primera pasada por Pegasus.
- **§7 — `source` evaluado vacío durante la construcción.** Se mitiga con
  `Loader { active: pieza.src !== "" }`: sin archivo el componente **no se
  construye**, así que no hay ningún `Image.source` ni `MediaPlayer.source` que
  pueda evaluar a vacío. Es el mismo mecanismo que ya exige ADR-0029 por otro
  motivo, así que no es cableado nuevo. Si igual pasa, se ve en el log de
  Pegasus como error de carga de recurso.
- **§3 — la leyenda pinta encima del riel.** Se mitiga por **anclaje**, no por
  un padding de 58px: el riel se ancla a `leyenda.top` y la leyenda al borde
  real de la pantalla, exactamente como `pie` y `leyenda` en `DocumentViewer`
  (que llegaron a esa forma por este mismo bug, reportado el 2026-08-09). Un
  número fijo vuelve a romperse en cuanto cambia el alto de la leyenda; un
  anclaje no.
- **Una galería con muchas piezas desborda el riel.** El riel es un `ListView`
  con `highlightRangeMode`, igual que la tira de `DocumentViewer`: scrollea y
  sigue la pieza actual. No hace falta la barra de progreso de documentos largos
  —una galería de 40 piezas no es un caso real— pero el mecanismo es el mismo si
  algún día lo fuera.
- **Un video de galería suena encima del video del panel de carátula.** Es más
  probable de lo que parecía: con el modal arriba el detalle **sigue `enabled` y
  visible**, porque `theme.qml:168-170` solo lo apaga con la ayuda
  (`visible: ... && !ayuda.active`, `enabled: visible`). Lo único que pierde es
  el `focus`, igual que con trucos y el visor. O sea que el `VideoPanel` sigue
  reproduciendo debajo. Juega a favor que el panel arranca en mute a propósito;
  si aun así el ruido aparece, la salida es apagar `VideoPanel.encendido`
  mientras el modal está activo — una línea. No se hace antes porque el mute lo
  vuelve un problema de consumo, no de audio, y eso todavía no se midió.
