# Especificación: Galería de imágenes y videos — Pantalla de Detalle de Juego

Agrega una galería multimedia por juego al detalle: se accede desde una **tarjeta en CONTENIDO EXTRA** (junto a Hacks y Manual digitalizado) y se abre como **modal a pantalla completa**. No es una tira de miniaturas inline en la pantalla de detalle — se probó y ensucia la composición; el acceso es un botón, el contenido vive en el modal.

## 1. Tarjeta de acceso (en CONTENIDO EXTRA)

Es una tarjeta más de la fila de contenido extra, visualmente **idéntica en estructura a las tarjetas existentes** (Hacks / Manual digitalizado): misma altura, mismo padding (`16px 18px`), mismo radio (12px), mismo borde (`1px rgba(255,255,255,.1)`), mismo fondo (`rgba(255,255,255,.03)`), misma chevron "›" a la derecha, mismo `min-width` (230px).

- **Ícono** (recuadro 50×50, radio 12px, fondo `color-mix(acento 15%)`, borde `color-mix(acento 38%)`): dos rectángulos superpuestos en línea de acento simulando "foto + video" — un rectángulo trasero (22×16, borde 2px acento, opacidad .55) desplazado arriba-izquierda, y un rectángulo frontal (24×18, borde 2px acento, fondo oscuro) desplazado abajo-derecha con un **triángulo de play** de acento centrado dentro.
- **Título**: "Galería" (Chakra Petch 600, 15px).
- **Subtítulo**: conteo desglosado por tipo, en mono 10px — `"1 video · 5 imágenes"`. Pluralización correcta en español, **con acento en "imágenes"**.
- **Estado de foco** (joystick/hover): igual que las otras tarjetas — borde en color de acento, fondo `rgba(255,255,255,.07)`, `translateY(-3px)` y sombra `0 14px 34px rgba(0,0,0,.4)`.
- **Visibilidad condicional**: la tarjeta solo existe si el juego tiene al menos una pieza de galería. Si no tiene, no aparece (igual que Hacks/Manual cuando faltan) — nunca un placeholder vacío ni una tarjeta deshabilitada.

### ⚠️ Colisión de nombres a resolver
El botón de volver, arriba a la izquierda de la pantalla, dice **"◄ GALERÍA"** y significa "volver a la grilla de juegos". La tarjeta nueva también se llama **"Galería"**. Son dos destinos distintos con el mismo nombre en la misma pantalla. **Decidir uno de los dos** antes de implementar: renombrar la tarjeta a "Capturas" o "Multimedia", o renombrar el botón de volver (ej. "◄ BIBLIOTECA"). No dejar ambos como "Galería".

## 2. Modelo de datos

> **Esta sección quedó vieja.** El contrato real es el que COINDOOR ya emite:
> `{ file, label }` (no `{ k, src, label }`), los archivos van en
> `media/<set>/_gallery/` (no `media/gallery/`), el tipo sale de la extensión y
> la galería suma además los assets nativos del juego. Ver
> [`ADR-0030`](../spec/decisions/0030-contrato-gallery-data-json.md). Lo que
> sigue se conserva porque el resto del documento lo referencia, pero no es lo
> que se implementa.

Cada juego tiene un array `gallery` (opcional). Cada ítem:

```
{ k: 'vid' | 'img',   // tipo de pieza
  src: string,        // ruta al archivo; puede venir vacío
  label: string }     // descripción corta, ej. "Pantalla de título"
```

- El orden del array **es** el orden de la galería (no reordenar por tipo).
- `src` vacío es un estado válido y esperado: significa "esta pieza está declarada pero el archivo todavía no se consiguió" → se renderiza como placeholder (ver sección 4).
- Convención de carpetas sugerida, consistente con el resto del proyecto: `media/gallery/` dentro de la carpeta del juego, con los videos junto a las imágenes y el orden definido en `game.json`.

## 3. Modal (lightbox) — layout

Overlay a pantalla completa por encima del contenido de detalle, **por debajo** del overlay de ayuda. Fondo `rgba(3,4,7,.93)` con blur de 14px. Tres bandas verticales:

### Header (`flex:none`, padding `22px 30px 14px`)
- Izquierda: chip de tipo — **"VIDEO"** o **"IMAGEN"** (mono 10px, letter-spacing amplio, fondo `color-mix(acento 20%)`, borde `color-mix(acento 45%)`, texto en acento) + a su derecha el `label` de la pieza (Chakra Petch 600, 17px) con el **título del juego** debajo en mono 10px gris.
- Derecha: contador **"3 / 6"** (mono 12px) + botón cerrar "✕" (40×40, radio 9px, borde `rgba(255,255,255,.16)`).

### Stage (`flex:1`, centrado)
- La pieza actual, centrada, con `max-width:100%; max-height:100%`, radio 12px, sombra `0 26px 70px rgba(0,0,0,.6)` + anillo `0 0 0 1px rgba(255,255,255,.08)`.
- **Flechas de navegación** "‹" y "›": círculos de 52px, `rgba(10,11,16,.7)` con blur, borde `rgba(255,255,255,.18)`, posicionados absolutos a 22px de cada borde, centrados verticalmente. **Solo se muestran si hay más de una pieza.**

### Rail de miniaturas (`flex:none`, centrado, gap 8px)
- Una miniatura por pieza, 74px de ancho, relación 16:9, radio 6px. Click salta directo a esa pieza.
- Pieza actual: borde 2px en color de acento + glow `0 0 14px color-mix(acento 55%)`, opacidad plena.
- Piezas no actuales: borde 1px `rgba(255,255,255,.12)`, opacidad .6.
- Las miniaturas de video llevan un "▶" pequeño centrado sobre un velo `rgba(4,5,9,.4)`; las de imagen, su número de orden (mono 7px) en la esquina superior izquierda.
- **Padding inferior de ~58px** en el contenedor del rail: es la clearance obligatoria para que la barra de leyenda (fija, ~46px, `position:absolute; z-index` superior al modal) no pinte encima de las miniaturas. Sin esa reserva los chips de la leyenda se superponen al rail — bug verificado.

## 4. Render de cada tipo de pieza

- **Video con archivo disponible**: `<video>` en loop, **con controles nativos visibles** (a diferencia del preview ambiente del hero, acá el usuario sí controla reproducción y volumen), autoplay al abrir.
- **Imagen con archivo disponible**: la imagen, `object-fit` respetando proporción, sin recorte.
- **Pieza sin archivo (`src` vacío)**: placeholder de 16:9 (ancho `min(64vw,880px)`) con fondo de rayas diagonales (`repeating-linear-gradient(135deg,#191c24 0 7px,#141720 7px 14px)`), borde punteado `rgba(255,255,255,.16)`, y dos líneas centradas en mono: `"CAPTURA · {label}"` y, más chica y gris, `"soltá acá la imagen real del juego"`. Es intencional que se vea como un hueco declarado, no como un error.

## 5. Navegación (mando / teclado / mouse)

| Input | Acción |
|---|---|
| `◄ ►` / `A`,`D` | Pieza anterior / siguiente (**con wrap**: de la última vuelve a la primera) |
| `Escape` / `Backspace` / `B` | Cerrar el modal |
| Click en flecha ‹ › | Pieza anterior / siguiente |
| Click en miniatura del rail | Salta directo a esa pieza |
| Click en la tarjeta / `Enter`,`A` sobre ella | Abre el modal en la pieza 0 |

- La tarjeta de galería entra en el **ciclo de foco direccional** del detalle, en la posición: `[JUGAR] → [carrusel de revistas] → [GALERÍA] → [Hacks] → [Manual]`. Los índices de foco de las tarjetas posteriores deben correrse en consecuencia — es la fuente de bug más probable al integrar.
- Mientras el modal está abierto, **captura los inputs**: `◄ ►` no debe seguir cambiando de sección del detalle por debajo.

## 6. Barra de leyenda (atajos en pantalla)

La barra inferior de atajos es contextual y **necesita una rama nueva para la galería**. Con el modal abierto debe mostrar exactamente:

```
◄ ►  Imagen / video     B / Esc  Cerrar
```

⚠️ Bug verificado si se omite: la barra sigue mostrando los atajos del detalle ("◄► Secciones · A/⏎ Abrir · B/Esc Volver · START Jugar"), que son **falsos** en ese contexto — ◄► cambia de pieza, no de sección, y A/START no hacen nada. La rama de la galería debe evaluarse **antes** que la rama genérica de "pantalla de detalle".

## 7. Nota de implementación (fuente de bug conocida)

En el prototipo, bindear `src` del `<video>` mediante interpolación de template provocaba que el navegador intentara cargar el texto literal del placeholder como una ruta, generando un error de recurso en consola. La solución fue **no bindear `src` declarativamente**: renderizar el `<video>` solo cuando existe una URL resuelta y asignar `el.src` de forma imperativa (junto con `loop`, `controls` y `play()`).

El equivalente en QML: no atar `MediaPlayer.source` a una expresión que pueda evaluar a vacío/indefinido durante la construcción del componente — usar un guard (`source: url !== "" ? url : ""` con el `MediaPlayer` dentro de un `Loader` activo solo cuando hay archivo). Mismo criterio para `Image.source`.

Otros puntos QML:
- El rail es un `ListView` horizontal (`orientation: ListView.Horizontal`), la navegación con wrap es aritmética modular sobre `currentIndex`.
- El modal es un `Popup`/`Item` full-screen con `focus: true` y `Keys.onLeftPressed`/`onRightPressed`/`onEscapePressed` propios, para garantizar la captura de inputs de la sección 5.
