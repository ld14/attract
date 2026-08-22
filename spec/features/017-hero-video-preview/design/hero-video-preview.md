# Especificación: preview de gameplay en el Hero — Pegasus Home

Ajuste sobre la pantalla Home: cuando el usuario se posiciona sobre un juego que tiene video de gameplay, el video se reproduce **contiguo al título y la descripción**, integrado orgánicamente al diseño existente (no un modal, no un reemplazo del hero).

## Comportamiento

### Cuándo aparece
- Solo si el juego actualmente enfocado tiene video disponible (`media/video.mp4` en su carpeta, ver spec de estructura de directorios).
- Solo en la pantalla Browse (no en Detalle, no en Buscar, no con overlays abiertos).
- Si el juego no tiene video, el hero se ve **exactamente igual que hoy** — no se reserva espacio vacío, no aparece placeholder.

### Delay de arranque (crítico para que se sienta orgánico)
No arranca instantáneamente al enfocar. Espera **~650ms** sobre el mismo juego antes de mostrarse. Esto evita que el panel parpadee cuando el usuario navega rápido por el estante pasando por 10 juegos en 2 segundos.

- Al cambiar el juego enfocado: cancelar el timer pendiente, ocultar el preview inmediatamente, y rearmar el timer de 650ms para el juego nuevo.
- Si el usuario se va antes de que se cumpla el delay, el video nunca llega a mostrarse.

### Transición de entrada
Cuando se cumple el delay, el panel entra con:
- **Fade** de opacidad 0 → 1.
- **Slide** horizontal sutil: `translateX(-16px)` → `0`.
- **Scale** sutil: `0.97` → `1`.
- Duración ~450ms, easing `cubic-bezier(.2,.7,.2,1)` para el movimiento y `ease` para la opacidad.

### Reproducción
- `autoplay`, **`muted` siempre**, **`loop` infinito**, `playsinline`.
- ⚠️ **Punto de falla conocido**: setear `muted` y `loop` de forma **imperativa sobre el elemento** (`el.muted = true; el.loop = true;`) antes de llamar a `play()`. En algunos frameworks los atributos booleanos declarativos no se propagan al elemento real y el resultado es un video que suena y que se congela en el último frame al terminar. Verificar en runtime que ambas propiedades leen `true`.
- Sin controles visibles (es ambiente, no un reproductor). El usuario no lo pausa ni le sube el volumen desde el hero — para eso está la pantalla de Detalle.

## Layout

- Posición: **a la derecha del bloque de texto del hero**, alineado al tope del hero (misma línea vertical que arranca el título).
- Ancho: **568px** sobre el canvas de diseño de 1280×720, relación **16:9** (≈320px de alto).
- Borde izquierdo del panel: `left: 664px` (arranca justo después del bloque de texto del hero, que ocupa `left:48px` + `width:600px`).
- El borde derecho del panel queda alineado con el margen derecho del contenido (1232px), consistente con el resto de la grilla.

### Superposición con los estantes de juegos
Por su altura, el panel **se extiende por debajo de la primera fila de tarjetas de juegos**. Eso es intencional y correcto, pero debe resolverse visualmente así:

1. **Z-order**: el preview va **por debajo** de los estantes (z-index menor). Las tarjetas de juego pasan por encima del video, nunca al revés.
2. **Máscara de disolución**: el panel NO termina en un borde recto con esquinas redondeadas — eso genera un canto marcado y feo cruzando las tarjetas. En su lugar, aplicar una **máscara vertical** que lo desvanece progresivamente hacia abajo:
   - 0%–46%: totalmente opaco
   - 68%: ~55% de opacidad
   - 84%: ~14% de opacidad
   - 96%–100%: completamente transparente
3. **Sin borde ni sombra dura**: al usar la máscara, NO aplicar anillo de acento (`box-shadow 0 0 0 1px`) ni sombra proyectada — se verían cortados por la máscara y arruinarían el efecto. El panel se integra al fondo por disolución, no por marco.

### Capas internas del panel (de atrás hacia adelante)
1. El `<video>`, `object-fit: cover`, llenando el frame.
2. Degradé lateral: de transparente (58%) a `rgba(6,7,12,.5)` en el borde izquierdo — funde el video con el bloque de texto del hero para que no haya un corte vertical duro entre la descripción y la imagen.
3. Degradé inferior: de transparente (56%) a `rgba(6,7,12,.72)` abajo — refuerza la disolución de la máscara y oscurece la zona donde se cruzan las tarjetas, mejorando la legibilidad de estas.
4. Badge **"● GAMEPLAY"**: arriba a la izquierda, pill con fondo `rgba(7,8,12,.62)` + blur, tipografía monoespaciada 9px, letter-spacing amplio, con un punto de 5px en el color de acento del juego que **parpadea** (animación de opacidad 1 → 0.2 → 1, ~1.6s, loop infinito).

## Color
El punto del badge usa el **color de acento del juego enfocado** (el mismo que ya tiñe la tarjeta enfocada, el botón "VER DETALLE" y el glow del hero) — se actualiza junto con el resto de la UI al cambiar de juego.

## Interacción
`pointer-events: none` en todo el panel — es puramente ambiental, no captura clicks ni interfiere con la navegación por mando. El foco del joystick nunca se para sobre el video.

## Nota de implementación en QML
- El delay es un `Timer` de 650ms con `repeat: false`, reiniciado en el `onCurrentIndexChanged` del estante enfocado.
- La reproducción es un `MediaPlayer` + `VideoOutput` (Qt Multimedia), con `loops: MediaPlayer.Infinite` y `audioOutput` nulo o volumen 0.
- La máscara de disolución se logra con `MultiEffect` (`maskEnabled: true`, `maskSource` = un gradiente vertical) o con `OpacityMask` de Qt5Compat.GraphicalEffects.
- El z-order se resuelve simplemente declarando el preview **antes** que el contenedor de estantes en el árbol, o con `z: 9` vs `z: 12`.
