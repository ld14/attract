# Handoff: Pegasus Retro Launcher — Home (Librería + Búsqueda + Detalle)

## Overview
Pantalla principal del launcher: navegación por estantes tipo "Netflix/Steam Big Picture" sobre 1200+ juegos, búsqueda con teclado en pantalla, orden/selección combinados (letra, año, nota, jugados), detalle de juego con selector de plataforma/edición, y un overlay de ayuda "Cómo cargar un juego nuevo". Pensada 100% para mando/joystick, con mouse y teclado físico como alternativas.

## Sobre los archivos
El archivo adjunto es un **diseño de referencia hecho en HTML/CSS/JS** (entorno de prototipado), NO es código QML. La tarea es **recrear este diseño en Pegasus Frontend** (QML + JavaScript sobre Qt Quick), usando el objeto `api`, el formato de metadata (incluyendo campos custom `x-`), y los componentes QML (`GridView`/`ListView`/`PathView`, `Flickable`, `Image`) equivalentes a los layouts descriptos abajo.

## Fidelidad
**Alta fidelidad.** Colores, tipografía, proporciones y microinteracciones (estados de foco, transiciones, animaciones) son finales — replicarlas lo más fielmente posible en QML. Donde Qt Quick no pueda igualar un efecto CSS exacto (`backdrop-filter blur`, `color-mix()`, `clip-path`), aproximar con `FastBlur`/`MultiEffect`, colores precalculados, y `Shape`, marcando la diferencia en un comentario de código.

## Escala de datos
El catálogo maneja **1200+ juegos** reales. El diseño NO pagina con "cargar más" — todos los estantes muestran el conteo real, y el renderizado usa **windowing** (solo se montan ~9-12 tarjetas visibles por fila + buffer, no las 1200 de golpe). En QML esto es directamente el comportamiento nativo de `ListView`/`GridView` con `cacheBuffer`, así que es más simple que en el prototipo web — no hace falta replicar el windowing manual, solo asegurarse de usar componentes virtualizados y nunca instanciar todas las tarjetas de una vez.

## Tokens globales
**Tipografía:** `Chakra Petch` (headers, 600/700), `Sora` (cuerpo, 300–800), `JetBrains Mono` (labels/HUD/mono, 400/500/700) — Google Fonts, bundlear localmente para uso offline en el cabinet.

**Colores base:** fondo `#04050a`/`#06070c`; texto primario `#e9ebf2`; texto secundario `#8a90a0`/`#6a7081`/`#aeb3c0`. Superficies tipo "glass HUD": `rgba(255,255,255,.03–.07)` con bordes `rgba(255,255,255,.08–.18)`.

**Acento dinámico por juego:** cada juego tiene un color `acc` (hex) que tiñe: card de foco, botón JUGAR, chips activos, barras de progreso, glow de foco. Se resuelve en runtime desde la metadata del juego — no hardcodeado.

**Radios:** 6–12px en paneles/cards, full-round en chips/pills. **Sombras:** ambient suave `0 10-24px 24-44px rgba(0,0,0,.4-.55)`; glow de acento `0 0 8-32px {acc}` en foco/hover.

**Escala fija:** todo el diseño se autoría en un canvas de **1280×720** y se escala uniformemente (`scale(min(w/1280,h/720))`, centrado) para llenar cualquier resolución real. En QML, o bien fijar el diseño a esa proporción con anchors relativos, o envolver la UI en un `Item` 1280×720 con `transform: Scale` — decisión del equipo, pero preservando las proporciones.

---

## Pantalla 1 — Browse (Librería)

**Fondo ambiente (todas las pantallas):** radial glow del color de acento arriba-derecha sobre gradiente vertical oscuro (~50% opacidad) + textura de scanlines sutil animada (drift vertical, blend screen, ~10% opacidad) + vignette inferior para legibilidad.

### Top bar (fija, `padding:22px 48px 0`)
- **Logo**: cuadrado 13px con glow del acento + wordmark "SHINBOX ARCADE" (Chakra Petch 700).
- **Tabs de filtro**: "TODOS" / "FAVORITOS" (pills, activo = fondo sólido del acento + glow; conteo real de juegos en mono debajo del nombre).
- **Control combinado ORDEN/SELECCIÓN** (ver sección dedicada abajo).
- **Botón BUSCAR**: pill con ícono de lupa + label "BUSCAR" + chip de atajo **`Y`**.
- **Reloj** (HH:MM, actualiza cada 20s).
- **Botón de ayuda "?"**: cuadrado 30×30, abre el overlay de ayuda (ver Pantalla 4).

### Control ORDEN / SELECCIÓN
Combo de 2 modos que comparten criterio (LETRA / AÑO / NOTA / JUGADOS):
- **Modo ORDEN** (default): el criterio se cicla con click; para LETRA y AÑO aparece un botón de dirección (▲/▼) que invierte A→Z/Z→A o menor→mayor/mayor→menor año. NOTA y JUGADOS siempre ordenan de mejor a peor.
- **Modo SELECCIÓN**: el criterio se limita a LETRA/AÑO; aparece un chip de "valor" (muestra la letra/año elegido o "—") que al clickearse abre un popover — grilla de 26 letras o de años (desde 1978 hasta el año más nuevo del catálogo) — y **filtra** el catálogo a esa letra/año puntual exacto.
- Un chip "✕ LETRA C" / "✕ AÑO 1992" aparece cuando hay un filtro activo, para limpiarlo.
- El nombre del estante "CATÁLOGO" refleja el filtro activo (ej. "CATÁLOGO · LETRA C").
- Atajo de teclado: **`X`** cicla el criterio (equivalente al click en el botón).

### Hero (arriba a la izquierda, sobre el fondo ambiente)
Refleja el juego actualmente enfocado en los estantes:
- Chips de plataformas disponibles (hasta 4) + "N EDICIONES" si son más de una.
- Título grande (Chakra Petch 700, `clamp(36px,4.6vw,62px)`).
- Línea de metadata: género (acento) · año · jugadores · nota (chip con diamante).
- Sinopsis (máx 2 líneas, clamp).
- CTA "VER DETALLE" (chip de acento) + atajo **`A`** + nota de plataformas si aplica.

### Estantes (scroll vertical entre estantes, horizontal dentro de cada uno)
Tipos de estante, en este orden, generados dinámicamente según el pool filtrado (tab + filtro activo):
1. **CONTINUAR JUGANDO** — juegos con progreso > 0, ordenados por fecha de agregado reciente. Solo aparece si hay al menos uno.
2. **MÁS JUGADOS** — top 12 por cantidad de partidas, con **ranking numerado** (01, 02, 03…) superpuesto en la esquina de cada carátula.
3. **Hasta 2 estantes por género** — los géneros con ≥3 juegos en el pool actual, ordenados por cantidad de títulos.
4. **CATÁLOGO** — todos los juegos del pool actual, respetando el orden/filtro activo (chip "⇅ {criterio}" visible en el header del estante).

Cada tarjeta (148×166px): carátula de fondo (portada real del juego si existe, si no un gradiente de color placeholder), overlay oscuro inferior, chips de plataforma (esquina), año (esquina superior), título (Chakra Petch 700 uppercase), barra de progreso (solo en "Continuar jugando"). **Foco**: la tarjeta enfocada se eleva (`translateY(-12px) scale(1.05)`), gana opacidad completa y un anillo + glow en su propio color de acento; las demás del estante enfocado quedan a 62% opacidad, las de otros estantes a 50%.

### Navegación (teclado/joystick)
- **Región "tabs"**: `◄ ►` cambia de tab; `▼`/Enter baja a los estantes.
- **Región "shelves"**: `◄ ►` mueve el foco entre tarjetas (una por vez); `▲ ▼` cambia de estante (▲ desde el primer estante vuelve a "tabs"); `Enter`/`A` abre el detalle de la tarjeta enfocada; `Escape`/`B` vuelve a "tabs".
- Atajos globales en Browse: **`Y`** abre Buscar, **`X`** cicla el criterio de orden/selección.
- Leyenda inferior (siempre visible, oculta durante transiciones de "launching"): recuerda los controles activos según la región actual.

---

## Pantalla 2 — Buscar (overlay full-screen, blur del fondo)

- **Header**: ícono de lupa + campo de búsqueda tipo terminal (texto grande + cursor parpadeante) + contador de resultados + botón "CERRAR" (atajo **`B`**/Escape).
- **Columna izquierda — teclado en pantalla**: grilla QWERTY-like de A-Z + 0-9 + espacio/borrar, navegable con `◄►▲▼`, `Enter`/`A` escribe el carácter enfocado. El teclado físico también funciona directo (tipeo directo mapea al query).
- **Columna derecha — resultados**: sin query, muestra "búsquedas recientes"; con query, resultados fuzzy (coincidencia exacta > subsecuencia > coincidencia de género) en grilla de 3 columnas, cada resultado con miniatura de portada + título + metadata. `►` desde el teclado pasa el foco a resultados; `Enter`/`A` sobre un resultado abre su detalle.
- Mensaje de "sin coincidencias" cuando corresponde (nunca un estado vacío sin feedback).

---

## Pantalla 3 — Detalle de juego

- **Top bar**: botón "◄ VOLVER" (atajo **`B`**/Escape) + género · año en color de acento.
- **Columna izquierda (300px)**: portada grande (imagen real o placeholder), botón "▶ JUGAR EN {PLATAFORMA}" (atajo **`A`**) con glow de acento, texto de formato físico ("Diskette"/"CD-ROM"/"Cartucho" + cantidad de ediciones).
- **Columna derecha**: título grande, chips de metadata (año/género/jugadores/desarrolladora) + chip de nota, sinopsis, y — pegado abajo — el selector de **ediciones/plataformas** ("ELEGÍ PLATAFORMA" si hay más de una, "PLATAFORMA" si solo una): una tarjeta por plataforma disponible, con ícono + nombre + formato físico; la plataforma seleccionada actualiza el botón JUGAR y el texto de formato.
- **Navegación**: `◄ ►` cambia la plataforma/edición seleccionada; `Enter`/`A` lanza el juego en esa plataforma; `Escape`/`B` vuelve a Browse.

---

## Pantalla 4 — Ayuda / Manual ("Cómo cargar un juego nuevo")

Overlay accedido desde el ícono "?" de la top bar (visible en Browse y Detalle). Modal de dos columnas:
- **Rail izquierdo (220px)**: lista de 8 pasos navegables, el activo resaltado en el color de acento.
- **Panel derecho**: título del paso + intro en lenguaje simple + bullets de tips prácticos + bloque de código/comando cuando aplica + navegación "‹ Anterior / Siguiente ›".
- **Contenido** (debe incluir las rutas y nombres de archivo EXACTOS que Pegasus espera — no simplificar a lenguaje vago):
  1. El ROM — `library/<sistema>/<carpeta-juego>/<archivo-rom>`, el sistema ya debe existir, nombre de carpeta = zip sin extensión.
  2. Las imágenes — `media/boxFront.jpg`, `marquee.png`, `poster.png`, `video.mp4`, todas opcionales, con orden de fallback para la carátula.
  3. El video de gameplay — mismo `media/video.mp4`.
  4. Revistas de la época — carpeta compartida `library/_shared/magazines/<id-revista>/`, referenciada por `ref` en `game.json`.
  5. `game.json` — accent/accent2, cheats (combos/códigos), reseña, manual; todo opcional; páginas de manual con ceros a la izquierda (`p001.jpg`).
  6. `synopsis.txt` — archivo de texto aparte, aplicado con comando.
  7. Validación — `make doctor-lib` antes de dar un juego por cargado.
  8. Troubleshooting — leer el mensaje exacto del validador.
- **Navegación**: `◄ ►` cambia de paso; `Escape`/`B` cierra.

---

## Mapa completo de atajos de teclado/joystick (implementar tal cual)

| Tecla / Botón | Contexto | Acción |
|---|---|---|
| `◄ ► ▲ ▼` | Browse (tabs) | Cambiar tab / bajar a estantes |
| `◄ ► ▲ ▼` | Browse (shelves) | Mover foco entre tarjetas / cambiar de estante |
| `A` / Enter | Cualquier pantalla | Acción primaria: abrir detalle, jugar, confirmar selección |
| `B` / Escape / Backspace | Cualquier pantalla | Volver / cerrar overlay |
| `X` | Browse | Ciclar criterio de orden (LETRA/AÑO/NOTA/JUGADOS) |
| `Y` | Browse | Abrir Buscar |
| `◄ ►` | Detalle | Cambiar plataforma/edición seleccionada |
| `◄ ► ▲ ▼` | Buscar (teclado en pantalla) | Mover foco entre teclas; `►` desde el borde derecho pasa a resultados |
| `◄ ► ▲ ▼` | Buscar (resultados) | Mover foco entre resultados (grilla 3 columnas); `◄` desde la primera columna vuelve al teclado |
| `◄ ►` | Ayuda | Cambiar de paso |
| Tipeo directo (teclado físico) | Buscar | Escribe directo en el query sin pasar por el teclado en pantalla |

La leyenda inferior en Browse/Detalle/Buscar debe mostrarse siempre, reflejando dinámicamente los atajos válidos para la región/pantalla activa (no una lista estática) — así el jugador siempre sabe qué botones responden.

## Datos / Metadata requerida por juego
Más allá de los campos estándar de Pegasus: `accent`/`accent2` (hex), lista de `plat` (plataformas/ediciones, cada una mapeada a un formato físico: Diskette/CD-ROM/Cartucho/etc. según años y sistema), `plays` (contador de partidas), `prog` (progreso de partida en curso, 0 si no aplica), `fav` (favorito), `added` (timestamp/orden de agregado para "continuar jugando"), `r` (nota 0-100), portada (imagen real). Todo opcional salvo lo estrictamente necesario para listar el juego — la UI debe degradar con gracia (placeholders, secciones ocultas) cuando falte un campo.

## Archivo
- `Pegasus Home.dc.html` — prototipo interactivo completo (Browse + Buscar + Detalle + Ayuda). Abrir en navegador; funciona con teclado (mapa de atajos de arriba), mouse, y toque.
