# Especificación: control ORDEN/SELECCIÓN — Botón 3 y popover de valor (AÑO / LETRA)

Este documento detalla exactamente cómo debe verse y comportarse el **tercer botón** del control de catálogo cuando el modo es SELECCIÓN, y el **popover de grilla** que despliega. Ver capturas de referencia adjuntas: `year-picker-reference.png` (criterio AÑO) y `letter-picker-reference.png` (criterio LETRA).

## Barra de controles (fila superior, siempre visible)
Tres botones pill en fila, alineados a la derecha, con `gap` entre ellos (~8-10px):

1. **Botón de modo** — texto "SELECCIÓN" (o "ORDEN" si ese es el modo activo). Cuando el modo es SELECCIÓN, este botón queda **resaltado en el color de acento del juego enfocado**: borde sólido en el color de acento, texto en el color de acento, fondo transparente/muy sutil (no relleno sólido). Radio de borde: pill completo (border-radius ~20-24px, altura ~40px).
2. **Botón de criterio** — texto "AÑO" o "LETRA" según el criterio activo. Mismo tamaño que el botón de modo. Estado neutro (no resaltado): borde gris tenue (`rgba(255,255,255,.18)`), texto blanco/gris claro, fondo oscuro semitransparente. Al clickear cicla entre LETRA/AÑO (los dos únicos criterios válidos en modo Selección).
3. **Botón "cerrar/colapsar" (−)** — botón cuadrado (no pill), mismo alto que los otros dos (~40×40px), ícono de guión "−" centrado, borde en el color de acento (siempre, incluso si el botón de modo no está resaltado), fondo transparente. Es el botón que **abre/cierra el popover de grilla** (toggle) — cuando el popover está abierto muestra "−", cuando está cerrado podría mostrar "+" o el valor elegido (ver nota de estado abajo).

Todos los botones comparten: tipografía monoespaciada (JetBrains Mono), texto en mayúsculas, letter-spacing amplio (~0.08-0.1em), tamaño de fuente ~13-14px.

## Popover de grilla (desplegado, debajo de los tres botones, alineado al borde derecho)
Contenedor:
- Fondo oscuro sólido casi opaco (`rgba(8,10,16,.95-.98)`), con una textura de scanlines/ruido sutil de fondo consistente con el resto de la UI (no un fondo liso).
- Borde de 1-1.5px en el **color de acento** del juego enfocado (verde en el ejemplo de letras, rosa/magenta en el ejemplo de años) — el borde entero del popover, no solo un detalle.
- Bordes redondeados (~14-16px).
- Sombra de elevación fuerte hacia abajo (`0 20-30px 50-60px rgba(0,0,0,.5-.6)`).
- Ancho: lo suficiente para contener **exactamente 7 columnas** de celdas con su gap, sin recortar ni dejar sobrante.
- Alto: fijo, mostrando **5 filas completas** de celdas; si hay más filas (como en el caso de AÑO, que puede llegar a 2020+), el contenido interno hace scroll vertical dentro del popover — el popover en sí NO crece más allá de esa altura máxima. Debe incluirse una **scrollbar visible** (delgada, en la esquina inferior derecha, discreta pero perceptible) cuando el contenido excede el alto visible — ver el pequeño indicador de scroll en la esquina inferior derecha de la referencia de AÑO.

## Grilla de celdas — **7 columnas fijas, siempre**, tanto para LETRA como para AÑO
Esto es un punto crítico de consistencia: a diferencia de una versión anterior que usaba anchos de celda distintos por criterio, **ambas grillas (letras y años) usan exactamente la misma estructura de 7 columnas**, incluyendo el mismo tamaño de celda, mismo gap, y misma alineación — así el popover se ve idéntico en proporción sin importar el criterio activo.

- Letras: A-Z (26 letras) → 7 columnas × 4 filas completas (28 celdas), últimas 2 celdas de la fila final vacías/sin renderizar (grilla termina en Z, fila incompleta al final, alineada a la izquierda).
- Años: rango continuo desde 1978 hasta el año más reciente del catálogo → 7 columnas × N filas, con scroll si excede 5 filas visibles.

### Celda individual
- Forma: rectángulo con esquinas redondeadas (~10-12px de radio) — notablemente más redondeada que un chip cuadrado, pero no una píldora completa.
- Tamaño: cuadrado o levemente rectangular, uniforme en todas las celdas de la grilla (mismo width/height para letras y para años — no ajustar el ancho al contenido).
- Fondo en reposo: gris oscuro casi negro (`#14161c` aprox.), ligeramente más claro que el fondo del popover, dándole textura de "botón físico".
- Borde en reposo: ninguno o extremadamente sutil.
- Texto: monoespaciado, color gris claro/blanco suave (no blanco puro) en reposo, tamaño ~14-15px, negrita media.
- **Gap entre celdas**: uniforme en ambas direcciones (fila y columna), consistente con el resto del diseño (~8-10px).

### Estado seleccionado (valor actualmente elegido, si lo hay)
Aunque no se ve un valor seleccionado resaltado en ninguna de las dos capturas de referencia (ambas muestran el popover recién abierto, sin selección), debe mantenerse el comportamiento ya implementado: la celda que coincide con el filtro activo se resalta con fondo sólido en el color de acento y texto oscuro (`#07080c`), más un glow sutil (`0 0 10px {acento}`).

### Estado foco (navegación por joystick/teclado, sin mouse)
La celda con foco de teclado/mando (no necesariamente la seleccionada) debe distinguirse con un anillo o borde en el color de acento, para que la navegación direccional dentro de la grilla sea visible sin necesitar mouse.

## Comportamiento
- Al clickear una celda: se fija ese valor exacto como filtro (letra o año), el popover se cierra, y la vista salta a los estantes con el catálogo ya filtrado (comportamiento ya especificado en `sort-select-spec.md` — este documento NO reemplaza esa spec, la complementa visualmente).
- El popover se abre/cierra con el botón "−"/"+"; también debe poder cerrarse con click fuera del popover o con `Escape`/B.
- Navegación por mando dentro del popover: `◄ ► ▲ ▼` mueve el foco celda por celda respetando las 7 columnas (bajar una fila = +7 en el índice); `Enter`/A confirma la celda enfocada (mismo efecto que click); `Escape`/B cierra el popover sin cambiar el filtro.

## Resumen de lo que cambia respecto a la implementación previa
1. Grilla unificada a **7 columnas fijas** para ambos criterios (antes el año usaba menos columnas con celdas más anchas).
2. Popover con **borde de color de acento** completo (antes tenía borde gris genérico).
3. Altura de popover limitada a **5 filas visibles** con scroll interno + scrollbar visible para AÑO (rango 1978→actual, potencialmente 45+ celdas).
4. Botón de modo (SELECCIÓN/ORDEN) debe **resaltarse en el color de acento** cuando el modo activo es SELECCIÓN, no solo el botón de criterio.
5. El botón "−" es un botón cuadrado dedicado a colapsar/expandir el popover, siempre con borde de acento, separado visualmente de los otros dos botones pill.
