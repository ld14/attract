# Especificación: textura de fondo (scanlines + vignette CRT) — Pegasus Home

Falta esta textura en la implementación real: son **capas CSS puramente visuales, superpuestas al fondo**, sin contenido — fáciles de perder al portar a QML porque no son "un componente", son overlays sutiles.

## Capa 1 — Ambient backdrop (glow de color + gradiente vertical) — SIEMPRE presente
Va primero, detrás de todo:
- Un **radial-gradient** centrado arriba a la derecha (~74% horizontal, 4% vertical), con el color de acento del juego actualmente enfocado, que se desvanece a transparente al 44% del radio. Opacidad total de la capa ~0.5. Debe **transicionar suavemente** (~0.5-0.6s) cuando cambia el juego enfocado (y por lo tanto el color).
- Debajo de ese radial, un **linear-gradient vertical** de negro-azulado oscuro (`#0a0c12` arriba → `#06070c` abajo), que le da profundidad al fondo general.

## Capa 2 — Scanlines animadas — SIEMPRE presente (independiente del toggle CRT)
Esta es la textura que se está perdiendo. Un `repeating-linear-gradient` **horizontal** (líneas paralelas horizontales, dirección 180deg) que simula líneas de escaneo de un tubo CRT:
- Patrón: franja de `rgba(255,255,255,.05)` de 2px, seguida de transparente de 6px (repite cada 8px total).
- `mix-blend-mode: screen` (se combina aditivamente con lo que está debajo, no lo oscurece).
- Opacidad de la capa completa: ~0.12 (muy sutil, es textura, no un patrón visible a simple vista).
- **Animada**: la posición de fondo se desplaza verticalmente en loop infinito (`background-position` de `0 0` a `0 240px`), duración ~7s, `linear`, infinito — un drift lento y continuo, no un parpadeo.
- Cubre el 100% del área de la pantalla (`inset:0`), en capa separada de las scanlines del toggle CRT (ver Capa 4).

## Capa 3 — Vignette de legibilidad — SIEMPRE presente
Un `linear-gradient` vertical con 4 paradas que oscurece arriba y abajo dejando el centro más despejado, para que el texto sobre el fondo sea legible sin tapar el arte:
- 0%: oscuro medio (`rgba(6,7,12,.55)`)
- 26%: más despejado (`rgba(6,7,12,.2)`)
- 62%: oscureciendo de nuevo (`rgba(6,7,12,.78)`)
- 100%: casi opaco (`rgba(6,7,12,.97)`)

## Capa 4 — CRT overlay — Toggle opcional (prop `crtScanlines`, default ON)
Capa adicional, por encima de TODO (z-index alto, por ejemplo el tope de la pila de capas), solo cuando el toggle está activo:
- `repeating-linear-gradient` horizontal más denso que la Capa 2: franja `rgba(0,0,0,.15)` de 1px + transparente de 2px (repite cada 3px) — simula líneas de escaneo mucho más finas y oscuras, el efecto clásico "pantalla CRT" encima de todo.
- Combinado con un `radial-gradient` de viñeta: transparente en el 68% central, oscureciendo a `rgba(0,0,0,.4)` en los bordes — oscurece las esquinas como un tubo real.
- `mix-blend-mode: multiply`.
- `pointer-events: none` (puramente decorativo, no bloquea clicks).

## Orden de capas (de atrás hacia adelante)
1. Ambient backdrop (glow + gradiente vertical)
2. Scanlines animadas (drift infinito)
3. Vignette de legibilidad
4. — contenido real de la UI (hero, estantes, controles) —
5. CRT overlay (si está activo el toggle) — por encima de absolutamente todo, incluyendo popovers y overlays de búsqueda/detalle/ayuda.

## Por qué importa
Sin la Capa 2 (scanlines animadas) el fondo se ve plano y estático — es la textura que le da la sensación de "pantalla vieja viva" incluso con el toggle CRT apagado. Sin la Capa 1 (glow de acento) el fondo no reacciona al juego enfocado y pierde la identidad de color dinámica que tiene el resto del diseño.

## Nota de implementación en QML
Las 4 capas son `Rectangle`/`Item` full-size con gradientes (`LinearGradient`/`RadialGradient` de Qt Quick Shapes o `MultiEffect`), apiladas por z-order, sin interacción — no requieren lógica, solo reproducir los valores de color/opacidad/blend indicados arriba. La animación de drift de la Capa 2 es un `NumberAnimation` en loop sobre el offset vertical del gradiente (o, más simple en Qt Quick, un `ShaderEffect`/`Image` tileable con `y` animado dentro de un `Item` con `clip: true`).
