# Handoff: Preselector de plataforma (Pegasus / theme ATTRACT)

## Overview

Pantalla previa a la librería: el usuario elige **una plataforma** (o "TODAS") y
a partir de ahí el catálogo de juegos queda filtrado por esa plataforma. Es un
carrusel de una plataforma a la vez, a pantalla completa, navegable con
mando/teclado: cada plataforma muestra su **nombre**, su **conteo de ítems**, su
**logo**, una **imagen emblema** a la derecha y un **video de gameplay aleatorio**
de juegos de esa plataforma reproduciéndose por detrás de todo.

Al aceptar se abre el **catálogo filtrado**; con `B` se vuelve al selector.

## About the Design Files

Los archivos de este bundle son **referencias de diseño hechas en HTML** —
prototipos que muestran el aspecto y el comportamiento buscados, **no código de
producción para copiar**. La tarea es **recrear este diseño en el entorno que ya
tiene el proyecto**: `themes/attract/` (QML, Qt 5.15 / Pegasus), respetando sus
capas (`core/` datos, `ui/` dibuja, `screens/` compone), su singleton `Theme`
(`Tokens.qml`) y sus ADRs.

Archivos incluidos:

| Archivo | Qué es |
|---|---|
| `Preselector Plataforma.dc.html` | El prototipo. Se abre directo en el navegador. |
| `support.js`, `image-slot.js` | Runtime del prototipo y el componente de hueco de imagen. **No se portan**: existen para que el HTML corra. |
| `spec.md`, `plan.md`, `tasks.md` | Borradores listos para `spec/features/025-selector-plataforma/`. |

**Assets:** el logo, el emblema y el video usados en el prototipo son arte con
copyright cargado a mano. No van al repo (regla de `CLAUDE.md`: el arte real va
en `library/`, nunca en `fixtures/`). El prototipo los deja como huecos
arrastrables; la implementación los lee del disco (§Assets).

## Fidelity

**Hi-fi.** Colores, tipografías, tamaños y posiciones son finales sobre el canvas
de diseño de **1280×720** (ADR-0016: canvas fijo escalado). Todas las medidas de
abajo son literales de ese canvas.

## Screens / Views

### 1 · Selector de plataforma (pantalla principal)

**Propósito:** elegir la plataforma cuyo catálogo se va a explorar.

**Layout**

Canvas `1280×720`, fondo `#06070c`, escalado con `scale()` y
`transform-origin: center` para caber en la ventana (igual que el theme actual).

Capas de atrás hacia adelante:

| # | Capa | Detalle |
|---|---|---|
| 1 | Fondo ambiente | `radial-gradient(135% 105% at 74% 4%, <accent> 0%, transparent 44%)` + `linear-gradient(180deg,#0a0c12,#06070c)`, opacidad `.5`, transición `.5s` al cambiar de plataforma |
| 2 | Scanlines | franja `rgba(255,255,255,.055)` 1px + 2px transparente (período 3px), opacidad `.1`, `mix-blend-mode: screen`, deriva vertical infinita (`background-position 0 → 6px`, 1.6s lineal) |
| 3 | Viñeta inferior | `linear-gradient(180deg, transparent 52%, rgba(3,4,8,.72) 100%)` |
| 4 | Barra superior | `z:10`, ver abajo |
| 5 | Escenario del hero | `z:2`, `inset:0`, fondo `#0a0c12` (contiene scrims, video, emblema, textos y flechas) |
| 6 | Catálogo filtrado | `z:40`, solo cuando está abierto |
| 7 | Overlay CRT | `z:80` (el que ya existe en `ui/CrtOverlay.qml`) |
| 8 | Leyenda de teclas | `z:90` |

**Barra superior** — `padding: 22px 48px 0`, `display:flex`, `align-items:center`, `gap:18px`

- Cuadrado de acento: `13×13`, radio `3px`, `background: <accent>`, `box-shadow: 0 0 14px <accent>`.
- Wordmark `SHINBOX ARCADE`: Chakra Petch 700, `15px`, `letter-spacing:.16em`; la palabra `ARCADE` en `#6a7081` peso 500.
- Etiqueta `PRESELECTOR DE PLATAFORMA`: JetBrains Mono `10px`, `ls .16em`, `#6a7081`, `padding-left:16px`, `border-left:1px solid rgba(255,255,255,.12)`.
- **Logo de la plataforma**: caja `104×30`, `opacity:.9`, imagen `fit: contain`, alineada a la izquierda. **Solo se dibuja si la plataforma tiene logo**; si no, no se reserva espacio.
- Spacer flexible.
- Total global: JetBrains Mono `11px`, `ls .08em`, `#8a90a0`. Texto: `"<N> JUEGOS · <M> PLATAFORMAS"` (excluye la pseudo-plataforma TODAS).
- Reloj: JetBrains Mono `12px`, `#7c8294`, `ls .08em`, `padding-left:14px`, `border-left:1px solid rgba(255,255,255,.12)`. Formato `HH:MM`, refresco cada 20s.

**Scrims del hero** (dentro de la capa 5, por encima del fondo y por debajo de todo lo demás)

- Horizontal: `linear-gradient(90deg, rgba(6,7,12,.97) 0%, rgba(6,7,12,.9) 30%, rgba(6,7,12,.28) 46%, transparent 58%)`.
- Vertical: `linear-gradient(0deg, rgba(4,5,10,.85) 0%, transparent 42%)` + `linear-gradient(180deg, rgba(4,5,10,.85) 0%, transparent 22%)`.

**Panel de video** — `left:72px`, `top:190px`, `440×248` (16:9)

- `<video>` a `object-fit: cover`, `inset:0`, sin controles.
- Encima, un **overlay de disolución** que funde los cuatro bordes con el fondo,
  sin marco ni esquinas: `inset:-1px`, `box-shadow: inset 0 0 30px 14px #07080d, inset 0 0 78px 34px rgba(7,8,13,.9)` + `background: radial-gradient(118% 122% at 50% 50%, transparent 52%, rgba(7,8,13,.75) 84%, #07080d 100%)`.
- **Va por debajo de todo**: el emblema, los textos, las flechas, la barra y la
  leyenda se dibujan encima. No tapa ningún dato.
- ⚠️ Nota de implementación importante (se descubrió en el prototipo): **no usar
  máscaras** (`mask-image` / `OpacityMask`) sobre el video. La capa acelerada del
  video deja una línea fina de 1px en el canto de la máscara. El degradado
  interior de arriba resuelve el fundido sin ese artefacto.

**Emblema de la plataforma** — caja `left:38%`, `right:0`, `top:0`, `bottom:0`

- Imagen `fit: contain`, alineada `right center`.
- Fundido con el fondo por máscara doble (en QML: gradiente radial pintado en `Canvas` encima, igual criterio que el video): radial `120% 118% at 68% 46%` opaco hasta 52%, `.55` al 78%, transparente al 100%; y lateral `linear-gradient(90deg, transparent 0%, #000 16%)` — el emblema nunca llega con borde duro al borde izquierdo.

**Columna de contenido** — `left:0`, `top:0`, `bottom:0`, `width:58%`, `padding:0 72px`, centrada vertical, `pointer-events:none`

1. Hueco reservado del video: `440×248`, `margin-bottom:14px` (mantiene el nombre por debajo del video sin solaparlo).
2. Nombre de la plataforma: **Chakra Petch 700 itálica, `52px`**, `line-height:.96`, `letter-spacing:-.01em`, `max-width:600px`, `text-shadow: 0 8px 40px rgba(0,0,0,.6)`.
3. Línea de conteo: `margin-top:10px`, rombo de `7×7` en `<accent>` rotado 45°, texto JetBrains Mono `14px`, `ls .08em`, `#c2c6d2`. Texto:
   `"<N> ÍTEMS · PLATAFORMA <i> DE <M>"`, o `"SIN ÍTEMS · …"` con cero juegos,
   o `"<N> ÍTEMS · <M> PLATAFORMAS"` en TODAS.

**Flechas** — `40×120`, radio `9px`, `top:50%` con `margin-top:-60px`, a `18px` de cada borde

- Normal: `border:1px solid rgba(255,255,255,.1)`, `background: rgba(10,12,18,.5)`, glifo `◄`/`►` JetBrains Mono `15px`, `#aeb3c0`.
- Hover/foco: `background: rgba(255,255,255,.1)`, `color:#e9ebf2`.

**Leyenda de teclas** — `left:0 right:0 bottom:0`, `padding:16px 48px 20px`, `gap:26px`, fondo `linear-gradient(0deg, rgba(4,5,10,.9), transparent)`

Cada ítem: pill de tecla (JetBrains Mono `10px` 700, texto `#07080c`, fondo `<accent>`, `padding:3px 8px`, radio `5px`) + etiqueta (JetBrains Mono `11px`, `#9aa0b0`).
En el selector: `◄ ►` CAMBIAR PLATAFORMA · `A` VER LIBRERÍA · `X` ALEATORIO · `B` VOLVER.
En el catálogo: `◄ ►` MOVER FOCO · `A` ABRIR JUEGO · `B` PLATAFORMAS.

### 2 · Catálogo filtrado

**Propósito:** ver y elegir juegos, ya filtrados por la plataforma elegida.

- Contenedor: `inset:0`, `z:40`, `background: rgba(5,6,10,.95)`, `backdrop-filter: blur(14px)` (en Qt 5.15: rectángulo translúcido plano, igual que el resto del theme), `padding: 26px 48px 0`.
- Cabecera (`gap:16px`): botón `◄ PLATAFORMAS` (JetBrains Mono `12px`, `ls .06em`, `#c7cbd6`, borde `rgba(255,255,255,.16)`, fondo `rgba(255,255,255,.05)`, radio `8px`, `padding: 8px 14px 8px 11px`, con pill de tecla `B`), título `CATÁLOGO · <AB>` (Chakra Petch 700 `20px`, `ls .04em`), subtítulo `mostrando <n> de <N>` (JetBrains Mono `10px`, `#5b6173`), spacer, y pill de filtro a la derecha: `FILTRO · <AB>` o `SIN FILTRO` en TODAS (JetBrains Mono `9px`, `ls .1em`, color `<accent>`, borde `<accent>` al 30% mezclado con `rgba(255,255,255,.08)`, radio `20px`, `padding:3px 9px`).
- Grilla: `margin-top:24px`, `grid-template-columns: repeat(7, 148px)`, `gap: 18px 16px`, alineada a la izquierda.
- Tarjeta: `148×166`, radio `10px`, `overflow:hidden`.
  - Enfocada: `opacity:1`, `transform: translateY(-10px) scale(1.04)`, `border:1px solid <accent>`, `box-shadow: 0 14px 30px rgba(0,0,0,.55), 0 0 22px <accent> 45%`.
  - Sin foco: `opacity:.66`, sin transform, `border:1px solid rgba(255,255,255,.08)`, `box-shadow: 0 10px 24px rgba(0,0,0,.4)`.
  - Transición `.16s` en transform, opacidad y sombra.
  - Scrim inferior: `linear-gradient(0deg, rgba(4,5,10,.92), rgba(4,5,10,.2) 52%, transparent)`.
  - Año: arriba a la derecha (`top:8px right:9px`), JetBrains Mono `9px`, `rgba(255,255,255,.62)`.
  - Badge de plataforma: JetBrains Mono `8px`, texto `rgba(255,255,255,.85)`, fondo `rgba(0,0,0,.45)`, borde `rgba(255,255,255,.22)`, radio `3px`, `padding:1px 4px`. En TODAS muestra la plataforma **de cada juego**; filtrado, la misma para todos.
  - Título: Chakra Petch 700 `12.5px`, `line-height:1.08`, mayúsculas, `ls .01em`.
  - **La carátula sale de la cadena de `CONVENCION.md` §2.2** (`boxFront → poster → marquee → color-wash con accent`), es decir `ui/CoverImage.qml`. El color-wash del prototipo es solo el último eslabón.
- **Estado vacío** (plataforma con ruta montada y cero juegos): panel `border:1px dashed rgba(255,255,255,.14)`, radio `12px`, `padding:26px 28px`, `max-width:620px`. Título `SIN JUEGOS EN ESTA PLATAFORMA` (Chakra Petch 700 `17px`, `ls .03em`) y cuerpo JetBrains Mono `11.5px`, `line-height:1.7`, `#8a90a0`, con las rutas en `#8fd6a8`:
  `library/<dir>/<carpeta-juego>/` y `make doctor-lib`.

## Interactions & Behavior

| Entrada | En el selector | En el catálogo |
|---|---|---|
| `←` / `→` | plataforma anterior / siguiente, con wrap circular | mueve el foco ±1 |
| `↑` / `↓` | — | mueve el foco ±7 (una fila), con clamp en los extremos |
| `A` / Enter (`api.keys.isAccept`) | abre el catálogo de la plataforma, foco en el primer juego | abre el juego |
| `B` / Esc / Backspace (`api.keys.isCancel`) | sale del selector (destino: lo que el theme ya tenga como raíz) | vuelve al selector, conservando la plataforma |
| `X` | salta a una plataforma aleatoria | — |

- Click en las flechas `◄`/`►` equivale a `←`/`→` (el mando es la entrada primaria, pero el prototipo es clickeable).
- El cambio de plataforma **no anima el layout**: solo transiciona el color de acento del fondo (`.5s`). El nombre y el conteo cambian en seco.
- El video arranca **atenuado por detrás** y no pide foco nunca (`pointer-events:none`).
- El acento de la plataforma tiñe: el cuadrado del wordmark, el glow del fondo, el rombo del conteo, las pills de teclas, la pill de filtro y el borde/glow de la tarjeta enfocada.

### Video de fondo

- `autoplay`, **`muted` siempre**, `loop`, `playsinline`, sin controles. En QML:
  `MediaPlayer` + `VideoOutput`, `loops: MediaPlayer.Infinite`, volumen 0.
- ⚠️ Setear `muted` y `loop` **imperativamente** antes de reproducir (mismo punto
  de falla documentado en `spec/features/017-hero-video-preview/design/hero-video-preview.md`).
- **Aleatorio por plataforma**: al entrar en una plataforma se elige al azar un
  juego de esa plataforma que tenga `media/video.mp4` y se reproduce; al terminar
  (o cada N segundos, ver `plan.md`) se pasa a otro juego al azar — encadenado,
  no un solo clip en loop eterno.
- Si la plataforma no tiene **ningún** video, el panel no se dibuja: el hueco
  reservado de `440×248` se mantiene (el nombre no salta de posición) y se ve
  solo el fondo.
- El video **nunca** se superpone al emblema ni a los textos: el emblema empieza
  en `38%` (≈486px) y el panel termina en `512px`; el solape de ~26px queda
  resuelto porque el video va por debajo y su borde derecho está disuelto.

## State Management

Estado del selector (equivalente en QML: propiedades en `screens/PlatformSelectScreen.qml`):

| Estado | Tipo | Qué es |
|---|---|---|
| `idx` | int | índice de la plataforma enfocada (0 = TODAS) |
| `grid` | bool | catálogo filtrado abierto |
| `g` | int | índice del juego enfocado en la grilla |
| `clock` | string | `HH:MM`, timer de 20s |
| `videoActual` | objeto | juego cuyo video se está reproduciendo (o `null`) |

Transiciones: `←/→` → `idx`; `A` → `grid=true, g=0`; `B` → `grid=false`;
`X` → `idx` aleatorio. Al cambiar `idx`: recalcular acento, conteo, assets y
elegir nuevo video.

**Datos que hacen falta** (los provee `core/`, no la pantalla):

- Lista de plataformas: **`api.collections`** de Pegasus, más la pseudo-plataforma
  `TODAS` en el índice 0 (no es una colección: es "sin filtro").
- Por plataforma: `nombre` (`collection.name`), `abreviatura`, `dir` (carpeta en
  `library/`), `conteo` (`collection.games.count`), `favoritos`, `acento`,
  `logo`, `emblema`, y la lista de juegos con video.
- Juegos filtrados: `collection.games`. En TODAS, la unión (`api.allGames`).

## Design Tokens

**Colores**

| Token | Valor |
|---|---|
| Fondo página | `#04050a` |
| Fondo escenario | `#06070c` |
| Fondo hero | `#0a0c12` |
| Fondo overlay catálogo | `rgba(5,6,10,.95)` |
| Tinta principal | `#e9ebf2` |
| Tinta secundaria | `#c2c6d2` |
| Tinta terciaria | `#aeb3c0` |
| Tinta atenuada | `#8a90a0` |
| Tinta débil | `#6a7081` |
| Tinta mínima | `#5b6173` |
| Reloj | `#7c8294` |
| Ruta / código | `#8fd6a8` |
| Negro del video | `#07080d` |
| Borde sutil | `rgba(255,255,255,.1)` |
| Borde medio | `rgba(255,255,255,.16)` |
| Superficie glass | `rgba(255,255,255,.05)` |
| **Acento (por plataforma)** | `oklch(0.74 0.16 <hue>)` |

Acentos usados en el prototipo (hue en grados): TODAS 195 · GBA 285 · GBC 150 ·
GC 240 · NES 20 · PS2 195 · PSP 60 · SNES 330 · WII 100 · SWITCH 170.
En Qt 5.15 no hay `oklch()`: convertir a hex en `core/` (tabla) o con un helper,
y exponerlo como `acento` de la plataforma.

**Tipografía** (las tres familias ya están en `themes/attract/fonts/`)

| Uso | Familia | Tamaño / peso |
|---|---|---|
| Nombre de plataforma | Chakra Petch itálica | `52px` / 700, lh .96, ls -.01em |
| Wordmark | Chakra Petch | `15px` / 700, ls .16em |
| Título catálogo | Chakra Petch | `20px` / 700, ls .04em |
| Título tarjeta | Chakra Petch | `12.5px` / 700, mayúsculas |
| Título estado vacío | Chakra Petch | `17px` / 700, ls .03em |
| Conteo | JetBrains Mono | `14px`, ls .08em |
| Reloj | JetBrains Mono | `12px`, ls .08em |
| Botón / total | JetBrains Mono | `11–12px` |
| Leyenda | JetBrains Mono | `10–11px` |
| Etiquetas mínimas | JetBrains Mono | `8–10px`, ls .1–.16em |
| Cuerpo general | Sora | 400 |

**Espaciado** — padding de barra `22px 48px`; padding de columna `0 72px`;
padding de catálogo `26px 48px 0`; gaps `10 / 11 / 14 / 16 / 18 / 22 / 26`.

**Radios** — `3` (cuadrado de acento) · `5` (pill de tecla) · `8` (botón) ·
`9` (flecha) · `10` (tarjeta) · `12` (panel vacío) · `20` (pill de filtro).

**Sombras** — glow de acento `0 0 14px <accent>`; tarjeta enfocada
`0 14px 30px rgba(0,0,0,.55), 0 0 22px <accent>`; tarjeta normal
`0 10px 24px rgba(0,0,0,.4)`; disolución del video (arriba, §Panel de video).

**Medidas fijas** — canvas `1280×720`; video `440×248`; logo `104×30`;
emblema desde `38%`; columna de texto `58%`; flechas `40×120`;
tarjeta `148×166`; grilla `7` columnas.

## Assets

Ninguno va al repositorio: son arte con copyright (regla de `CLAUDE.md`).
La implementación los lee del disco, y cada uno es **opcional** — si falta, el
elemento simplemente no se dibuja.

Estructura propuesta (ver `plan.md` §Decisiones; el prefijo `_` marca lo que no
es una colección de juegos):

```
library/_platforms/<dir>/
├─ logo.png        → caja 104×30 de la barra superior
├─ emblema.png     → imagen grande de la derecha
└─ data.json       → { "accent": "#rrggbb", "abrev": "SWITCH", "nombre": "Nintendo Switch" }
```

Los videos **no** son un asset nuevo: salen de `media/video.mp4` de los juegos ya
cargados (misma fuente que la feature 017).

En el prototipo estos tres huecos son `<image-slot>` arrastrables, con el arte de
prueba del autor (un PNG de personaje, el logo de Switch y un mp4). Ese arte no
está en el bundle.

## Files

- `Preselector Plataforma.dc.html` — el prototipo completo (selector + catálogo + estado vacío).
- `support.js`, `image-slot.js` — runtime del prototipo (no se portan).
- `spec.md` / `plan.md` / `tasks.md` — borradores para `spec/features/025-selector-plataforma/`.

## Cómo seguir (flujo del repo)

1. Copiar `spec.md`, `plan.md` y `tasks.md` a `spec/features/025-selector-plataforma/`.
2. Cerrar el `spec.md` con el autor antes de tocar QML (SDD: spec → plan → tasks → código).
3. Implementar según `plan.md`, verificando contra Pegasus real con `make theme`.
4. Si alguna decisión de `plan.md` §Decisiones tuvo alternativas con peso (p. ej. la fuente de los assets de plataforma), extraerla a un ADR con `/new-adr`.
