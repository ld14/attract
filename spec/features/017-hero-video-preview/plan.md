# 017 · Preview de gameplay en el hero — Plan

_Cómo se implementa lo descrito en `spec.md`. Debe respetar la `constitution/`._

## Enfoque

Un componente nuevo, `screens/HeroVideoPreview.qml`, hermano de `heroBox` dentro
de `BrowseScreen`. No toca el hero ni los estantes: se ancla al margen derecho y
al tope del hero, y ocupa el espacio que hoy está vacío.

Va en `screens/` y no en `ui/` porque compone datos (`game.assets.video`) con
dibujo — misma categoría que `VideoPanel.qml`, por la regla de "quién sabe de
qué" de la [feature 005](../005-theme-base/plan.md).

El componente es **dueño de su propio arranque**: el debounce de 650ms vive
adentro, no en la pantalla. `BrowseScreen` solo le pasa el juego enfocado, el
accent y un `encendido`. Así el único acoplamiento con la pantalla es el que ya
existe para todo lo demás.

### El diseño está escrito en CSS y este binario es Qt 5.15

Tres indicaciones de [`design/hero-video-preview.md`](design/hero-video-preview.md)
no aplican tal cual y se traducen:

| El diseño dice | Acá |
|---|---|
| `MultiEffect` / `Qt5Compat.GraphicalEffects` (§Nota de implementación) | **No existen** — son Qt 6 (ADR-0006, `docs/plataforma-pegasus.md` §1). Va `OpacityMask` de `QtGraphicalEffects 1.0`, el mismo que ya usa `screens/GameCard.qml` |
| `onCurrentIndexChanged` del estante enfocado | Se perdería el salto **entre** estantes. El gancho es `root.juego` de `BrowseScreen`, que cubre los dos casos |
| Degradé lateral (capa 2 del panel) | `Rectangle` en Qt 5 solo hace gradientes **verticales** (`plataforma-pegasus.md` §3). Se resuelve rotando -90 un Rectangle con los lados intercambiados |
| `pointer-events: none` | No tiene equivalente ni hace falta: sin `MouseArea`, sin `focus` y fuera de todo `Keys.onPressed`, no hay forma de que reciba nada |

## Implementación

> **Estado al 2026-08-21:** el paso 1 corrió y **la máscara funciona** —
> `OpacityMask` enmascara un `VideoOutput` y el video se sigue actualizando
> adentro. El plan B queda descartado y los pasos 2 y 3, que se habían escrito
> antes de medir, dejan de ser provisionales. Lo que falta es la verificación
> visual de la feature completa en Home, no la de la técnica.
>
> Se salteó el orden 1 → 2 → 3 una vez y salió bien por suerte, no por criterio:
> el orden sigue siendo el correcto.

1. `themes/experimentos/video-opacitymask.qml` — **primero**. Mide si
   `OpacityMask` enmascara un `VideoOutput` que vive dentro de un
   `Item { visible: false }`, y si el resultado se sigue actualizando por cuadro
   o queda congelado. De eso depende toda la disolución. El archivo trae el plan
   B al lado (panel C) para poder comparar sin escribir un segundo experimento.
2. `themes/attract/screens/HeroVideoPreview.qml` — el panel. `MediaPlayer` +
   `VideoOutput`, las cuatro capas del diseño dentro de un `Item` invisible, la
   máscara de disolución, el `Timer` de 650ms y la animación de entrada.
3. `themes/attract/screens/BrowseScreen.qml` — una instancia, declarada
   **entre `heroBox` y `estantes`**.

### Geometría

`anchors.right` con `rightMargin: Theme.gutter`, `width: 568`, `height: 320`
(16:9), `top` alineado al de `heroBox`.

Anclado a la derecha y **no** con el `left: 664` literal del diseño: por
[ADR-0019](../../decisions/0019-canvas-cover-no-letterbox.md) el lienzo puede
ser más ancho que 1280, y en ese caso un `x` fijo despegaría el panel del margen
de contenido. Anclado, queda siempre a ras — que es lo que el diseño pide — y en
1280 da exactamente los 664. Es además lo que ya hace `estantes`.

### El delay de 650ms

`Timer` de `repeat: false` reiniciado desde `onGameChanged`. Al cambiar de juego
el panel se oculta **de inmediato** y suelta el decoder por el binding de
`source`; recién a los 650ms se vuelve a asignar la fuente.

Es el primer debounce del theme: los dos `Timer` existentes (el reloj de la
barra y el autocierre de `LaunchOverlay`) son otra cosa.

### `loop` imperativo, volumen declarativo

`autoPlay: false` y una función `arrancar()` que fija `loops` **antes** de
llamar a `play()`. Los bindings declarativos ya funcionan en QML
—`VideoPanel.qml` lo prueba desde la feature 006— pero el orden explícito es
verificable y el declarativo no: `arrancar()` termina comprobando en runtime que
`loops` quedó puesto, y avisa por `console.warn` si no.

El **volumen es la excepción y va al revés**: `volume: root.activo ? 0.3 : 0`,
binding y no asignación. Fijarlo a mano en `arrancar()` cortaría el binding y el
panel seguiría sonando después de ocultarse — el player del juego anterior vive
hasta 650ms más (ver [`ADR-0029`](../../decisions/0029-player-nuevo-por-video.md)).
Acá la garantía que importa no es "arranca puesto" sino "se calla cuando
desaparece", y eso solo lo sostiene un binding.

(Revisión del 2026-08-22: la feature se escribió muda; ahora suena al 30%.)

Nada colgado de `onStopped`: no se dispara nunca en un loop infinito
(`plataforma-pegasus.md` §2, medido).

### Entrada gatillada por reproducción, no por el Timer

La opacidad se ata a `playbackState === PlayingState`, no a que el Timer haya
disparado. Si se atara al Timer, los ~200ms de buffering se verían como un
rectángulo negro haciendo fade-in — que es exactamente lo que el delay de 650ms
existe para evitar.

## Decisiones

- **La entrada se anima, la salida no** — los tres `Behavior` (opacidad, escala
  y `Translate.x`) llevan `enabled: root.activo`, así que corren de ida y no de
  vuelta. Es lo que pide el diseño (§Delay de arranque: "ocultar el preview
  inmediatamente"), pero acá además es correctitud: `reiniciar()` suelta la
  fuente en el mismo tick, así que un fade de salida no funde el video sino un
  `VideoOutput` ya vacío — el mismo rectángulo que el criterio de la entrada
  prohíbe, al revés. Cortar seco deja además la próxima entrada arrancando
  siempre desde `0.97` / `-16` exactos. La alternativa —aguantar la fuente hasta
  el final del fade— parte `reiniciar()` en dos pasos y le agrega estado al
  componente para ganar 450ms de animación que nadie pidió.

- **Máscara de alfa real en vez de un gradiente al color del fondo** — el fondo
  de Home no es un color plano (`ui/AccentWash.qml` lo tiñe con el accent del
  juego), así que un gradiente opaco se vería como una banda oscura en vez de
  una disolución. El costo es depender de `OpacityMask` sobre `VideoOutput`, que
  es lo que mide el experimento.
- **El z-order sale del orden de declaración, no de un `z:`** — ningún
  componente del theme usa `z` explícito y no hace falta empezar por acá: el
  panel declarado antes que `estantes` ya queda debajo de las tarjetas.
- **El debounce vive en el componente, no en la pantalla** — `BrowseScreen` ya
  tiene 45KB y cuatro `Connections`; el arranque del panel es asunto del panel.
- **Sin blur en el badge** (`backdrop-filter` del diseño) — `FastBlur` dentro de
  una capa enmascarada complica el árbol para un efecto de 22px de alto. Va el
  fondo plano que ya usa `VideoPanel.qml`. Se agrega si al verlo se nota.
- **El popover de orden NO apaga el video** — deja Home `visible` y solo
  `enabled: false`, coherente con su propia decisión de no llevar scrim ("Home
  se sigue viendo detrás"). Los overlays modales sí lo apagan.

## Riesgos

- **`OpacityMask` sobre `VideoOutput`** — lo cierra el experimento antes de
  escribir el componente. Si falla, plan B: disolver con un gradiente a
  `Theme.screen` (panel C del experimento). Se ve peor, pero no depende de la
  GPU.
- **Congelado en vez de negro** — el modo de falla peor del punto anterior: sale
  enmascarado pero quieto en el primer cuadro, y una captura no lo distingue.
  Por eso el experimento se mira en movimiento, no en screenshot.
- **Dos decoders vivos** — al abrir el detalle, `encendido: false` corta el de
  Home antes de que arranque el de `VideoPanel`, pero el solapamiento de un
  frame existe. Se mitiga con la regla ya conocida (`source: ""`, no pausar) y
  se verifica entrando y saliendo del detalle ~15 veces.
- **`root.juego` parpadeando a `null` solo** — sale de
  `estantes.currentItem`, y un `ListView` puede reciclar el delegate actual sin
  que el usuario toque nada. Si eso pasa, `juego` va a `null` y vuelve al mismo
  juego: el panel se reinicia y el video arranca de cero **estando quieto**, que
  es lo contrario de lo que la feature promete. No se puede descartar leyendo el
  código; se verifica quedándose quieto y mirando.

- **Churn de decoder navegando lento** — quedarse 700ms en cada juego abre y
  cierra un decoder por juego. No hay forma barata de medirlo sin el gabinete;
  si aparece, el ajuste es subir el delay, no cachear.
- **`loops` en Windows** — sigue siendo el riesgo abierto de la feature 006
  (`plataforma-pegasus.md` §5). Esta feature lo hereda, no lo agrava.
