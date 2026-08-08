# Handoff: Pegasus Retro Launcher — Ayuda / Manual ("Cómo cargar un juego nuevo")

## Overview
Un overlay de ayuda dummy-friendly, accesible desde un ícono "?" junto al reloj en la barra superior (visible en Librería y Detalle). Explica en lenguaje simple cómo cargar un juego nuevo al cabinet, en 8 pasos navegables.

## About the Design File
El archivo adjunto es un **diseño de referencia en HTML/CSS/JS** (prototipo de alta fidelidad), no código QML. La tarea es **recrear este mismo diseño en QML** dentro del theme de Pegasus Frontend.

## Fidelity
**Alta fidelidad.** Colores, tipografía, layout y transiciones son finales. Donde QtQuick no pueda igualar un efecto CSS (ej. `backdrop-filter: blur`), aproximar con `FastBlur`/`MultiEffect` y marcar la diferencia en un comentario.

## Tipografía y colores (tokens globales del theme)
- Fuentes: `Chakra Petch` (700), `Sora` (400/500/600), `JetBrains Mono` (400/500/700) — Google Fonts, bundlear localmente para uso offline.
- Fondo overlay: `rgba(5,6,9,.9)` + blur 14px sobre el resto de la pantalla.
- Panel: gradiente `#0e1118 → #0a0c11`, borde `rgba(255,255,255,.1)`, radio 16px, sombra `0 40px 100px rgba(0,0,0,.6)`.
- Acento: color dinámico por juego/plataforma (`--accent`), usado en el paso activo, el título de cada paso y el botón "Siguiente".

## Trigger
Botón "?" — 30×30px, radio 8px, borde sutil, fondo glass — ubicado en la barra superior junto al reloj (extremo derecho), en toda pantalla donde exista esa barra (Librería, Detalle).

## Layout del overlay
Modal centrado, `min(880px,92vw)` de ancho, máx 86vh de alto, dividido en dos columnas:

**Columna izquierda (220px, fondo sutil, borde derecho):**
- Título "GUÍA RÁPIDA" (mono, 10px, letter-spacing .16em, gris).
- Lista vertical de 8 botones de paso ("1. El ROM", "2. Las imágenes", … "8. Si algo falla"). El paso activo se resalta con fondo en el color de acento y texto oscuro; los demás son transparentes con texto gris. Click en cualquiera salta directo a ese paso.

**Columna derecha (flex, contenido del paso actual):**
- Header: título del overlay ("Cómo cargar un juego nuevo") + "Paso N de 8" (mono, gris) — a la izquierda; botón ✕ de cerrar — a la derecha. Separado por un borde inferior.
- Body (scrollable):
  - Título del paso (Chakra Petch 700, 22px, color de acento).
  - Párrafo introductorio en lenguaje simple (Sora 15px/1.6, gris claro).
  - Lista de "callouts" — cada uno una tarjeta (fondo `rgba(255,255,255,.03)`, borde sutil, radio 10px) con un ícono "▸" en color de acento + el texto del tip (Sora 14px/1.55).
  - Si el paso tiene un comando/código de ejemplo: un bloque monospace sobre fondo oscuro (`#0a0c11`), texto verde clarito (`#8fd6a8`), `white-space:pre-wrap`.
- Footer: botones "‹ Anterior" / "Siguiente ›" — deshabilitados/atenuados en el primer/último paso respectivamente.

## Contenido (8 pasos — adaptado a lenguaje no técnico)
1. **El ROM** — dónde va el archivo del juego; el sistema (arcade/, nes/, …) ya debe existir; reglas de nombre de carpeta.
2. **Las imágenes** — boxFront/marquee/poster/video.mp4 sueltos en la carpeta de medios del juego; orden de fallback si falta alguna.
3. **El video** — mismo lugar, `video.mp4`, opcional (si falta, se muestra la carátula).
4. **Revistas de la época** — los escaneos viven en una carpeta compartida (no duplicada por juego); el juego solo la referencia; opcional.
5. **Datos del juego** — un archivo de metadata por juego con colores de acento, combos/trucos, nota de la crítica, manual; todos los campos opcionales; páginas de manual con numeración con ceros a la izquierda.
6. **Sinopsis** — archivo de texto aparte, se aplica con un comando, no se escribe a mano en el juego.
7. **Validar todo** — comando de verificación antes de considerar el juego "cargado".
8. **Si algo falla** — leer primero el mensaje del validador; indica el archivo/regla exacta.

## Interacciones
- Click en el ícono "?" abre el overlay.
- Flechas Izquierda/Derecha (o A/D) navegan entre pasos mientras está abierto.
- Escape / Backspace cierra el overlay.
- El overlay es el mismo componente en cualquier pantalla — un `Loader`/`Popup` QML reutilizable, no duplicado por pantalla.

## Archivo
- `Pegasus Game Detail.dc.html` — prototipo completo; la sección de Ayuda es el estado `helpOpen`. Abrir en navegador, click en el ícono "?" (junto al reloj, arriba a la derecha) para verla.
