# 025 · Selector de plataforma — Plan

_Cómo se implementa lo descrito en `spec.md`. Respeta `constitution/`._

## Enfoque

El selector es una pantalla más, no un modo aparte: entra en `screens/` y se
rutea desde `theme.qml` con el mismo patrón que `library` y `detail`. El corte de
capas es el de 005: `core/` resuelve plataformas, assets y videos; `ui/` dibuja
átomos sin saber de dónde salen; la pantalla compone.

Dos cosas sí son nuevas y justifican módulos propios: **los datos por plataforma**
(las colecciones de Pegasus no traen acento, abreviatura, logo ni emblema) y **la
cadena de videos aleatorios** (elegir juego con video, reproducir, encadenar otro).

El catálogo filtrado **no se escribe de cero**: es `screens/LibraryScreen.qml` con
un filtro de colección y un par de agregados en la cabecera. Si la pantalla actual
no admite el filtro sin cirugía, se extrae el rail a un componente y las dos lo
usan; no se duplica la grilla.

## Árbol

```
themes/attract/
├─ core/
│  ├─ Platforms.qml        (nuevo)  api.collections + TODAS + data.json de plataforma
│  └─ PlatformVideos.qml   (nuevo)  juegos con media/video.mp4 y elección aleatoria
├─ ui/
│  ├─ DissolvePanel.qml    (nuevo)  panel que se funde con el fondo por sus 4 bordes
│  └─ KeyLegendRow.qml     (nuevo)  la fila de pills de teclas del pie
└─ screens/
   └─ PlatformSelectScreen.qml (nuevo)  el carrusel
```

`ui/Background.qml`, `ui/CrtOverlay.qml`, `ui/CoverImage.qml`, `ui/Chip.qml`,
`ui/FocusRing.qml` y `Tokens.qml` se reusan tal cual.

## Implementación

1. `core/Platforms.qml` — expone `lista`: `TODAS` en el índice 0 más una entrada
   por `api.collections`. Cada entrada: `nombre`, `abrev`, `dir`, `conteo`,
   `acento`, `logo`, `emblema`, `coleccion`. Lee
   `library/_platforms/<dir>/data.json` con `XMLHttpRequest` + `try/catch` y
   cachea por `dir` (mismo patrón y mismas tres reglas que `core/GameData.qml`:
   404 no es error, JSON corrupto no crashea, cache para no repetir la lectura al
   pasar el foco).
2. `core/PlatformVideos.qml` — para la plataforma enfocada, arma la lista de
   juegos cuyo `media/video.mp4` existe (rutas vía `core/Paths.qml`) y expone
   `siguiente()` que devuelve uno al azar distinto del actual. Sin lista, expone
   `vacio: true`.
3. `ui/DissolvePanel.qml` — contenedor que funde su contenido con el fondo por los
   cuatro bordes, sin marco ni esquinas: un `Canvas` con gradiente radial
   (`transparent 52% → rgba(7,8,13,.75) 84% → #07080d 100%`) más el equivalente
   del doble `inset box-shadow`. Es la pieza que hace que el video no tenga canto.
4. `ui/KeyLegendRow.qml` — recibe una lista `[{tecla, etiqueta}]` y el acento.
   Reemplaza el rótulo de tecla por el configurado (ajuste de teclado 2026-09-15).
5. `screens/PlatformSelectScreen.qml` — `FocusScope`. Sostiene `idx`, `videoActual`
   y el reloj. Compone: barra superior, panel de video (`DissolvePanel` +
   `MediaPlayer`/`VideoOutput`), emblema, columna de texto con el hueco reservado
   de `440×248`, flechas y leyenda. Todas las medidas son las del handoff.
6. `screens/LibraryScreen.qml` — acepta `plataforma` (o `null` para TODAS) y
   filtra. Cabecera: botón `◄ PLATAFORMAS`, `CATÁLOGO · <AB>`, subtítulo de
   conteo y pill `FILTRO · <AB>` / `SIN FILTRO`. Estado vacío nuevo cuando la
   colección tiene cero juegos.
7. `theme.qml` — `screen` pasa a `"platforms" | "library" | "detail"`, con
   `"platforms"` como estado inicial, y guarda la plataforma elegida para que el
   regreso desde el catálogo conserve el foco.

## Decisiones

- **`library/_platforms/<dir>/` como fuente de logo, emblema y acento** en vez de
  meterlos en el theme — el arte con copyright no va al repo (`CLAUDE.md`), y el
  prefijo `_` es la marca existente de "esto no es una colección de juegos", que
  es la regla que usa `scripts/reset-pegasus.sh`. Tiene alternativas con peso
  (tabla de acentos en `Tokens.qml`; `assets/` dentro del theme): si se elige otra,
  extraer a un ADR.
- **El acento de plataforma baja como propiedad**, igual que el de juego
  (ADR-0013). El singleton `Theme` no lo conoce.
- **`oklch()` se convierte a hex en `core/`**, no en la UI — Qt 5.15 no lo tiene y
  el diseño lo usa solo para generar una familia de acentos coherente.
- **Sin máscaras sobre el video.** El prototipo probó `mask-image` y
  `mask-composite` y deja una línea de 1px en el canto de la capa acelerada del
  video. El fundido se hace con un degradado pintado **encima** (`DissolvePanel`).
  Vale también para `OpacityMask` de Qt: no se usa acá.
- **El video va al fondo del z-order** de la pantalla y con `pointer-events`
  deshabilitado: es ambiental, el foco del joystick nunca se para sobre él (mismo
  criterio que 017).
- **El hueco del video se reserva aunque no haya video** — `440×248` fijos, para
  que el nombre de la plataforma no salte de posición al cambiar de plataforma.
  Diverge del criterio de 017 (donde el hero no reserva espacio) a propósito: acá
  el nombre está **debajo** del panel, no al lado.
- **`TODAS` es una pseudo-plataforma, no una colección** — vive solo en
  `core/Platforms.qml`, no se le inventa un `dir` ni una carpeta en `library/`.
- **Se reusa `LibraryScreen` con filtro** en vez de escribir una grilla nueva —
  la tarjeta, la cadena de carátula y el foco ya están resueltos y verificados
  contra Pegasus real.
- **`api.keys` para aceptar/cancelar, flechas crudas** — igual que 005: con
  `Qt.Key_Return` el gabinete no responde al joystick.

## Riesgos

- **Cirugía en `LibraryScreen`.** Si el filtro no entra limpio, el rail se extrae
  a un componente compartido. Se mitiga haciendo el filtro lo primero y
  verificando la librería completa antes de escribir el selector: si la pantalla
  vieja se rompe, se ve de inmediato y no al final.
- **Encadenar videos puede tartamudear** en el gabinete si cada clip abre un
  `MediaPlayer` nuevo. Se mitiga reusando una sola instancia y solo cambiando
  `source`. Si igual salta, el fallback es un clip por plataforma en loop.
- **Plataformas sin assets** son el caso normal al principio, no el borde. Cada
  elemento opcional se dibuja solo si existe; la pantalla tiene que verse
  terminada con **cero** assets cargados. Se verifica contra `fixtures/` antes que
  contra `library/`.
- **Fidelidad medida a ojo**, como en 005: abrir el prototipo
  (`design_handoff_platform_select/Preselector Plataforma.dc.html`) y Pegasus al
  lado. El canvas fijo 1280×720 (ADR-0016) es lo que hace que la comparación
  tenga sentido.
