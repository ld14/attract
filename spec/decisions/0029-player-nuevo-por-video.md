---
id: 0029
title: "Un `MediaPlayer` + `VideoOutput` nuevo por cada archivo de video"
status: proposed
date: 2026-08-22
supersedes: null
superseded-by: null
tags: [frontend]
---

# 0029 — Un `MediaPlayer` + `VideoOutput` nuevo por cada archivo de video

## Contexto

El preview de gameplay del hero (feature 017) reproduce el video del juego
enfocado y cambia de archivo cada vez que el foco se mueve por el estante. La
forma obvia —y la que llevaba `screens/VideoPanel.qml` desde la feature 006— es
un `MediaPlayer` declarativo con `source` colgado de un binding: cambia el
juego, cambia la fuente, el mismo player carga el archivo nuevo.

Contra Pegasus real (Qt 5.15.10, macOS, backend AVFoundation) eso falla de
forma **intermitente**: el panel aparece vacío con el video "cargado". Y falla
callado, que es lo peor de todo:

- `status` queda en `Buffered`, como si todo estuviera bien.
- `playbackState` queda en `PlayingState` y `position` **avanza**, incluso
  reenganchando el loop al llegar al final.
- No hay `onError`, no hay warning de QML, no hay nada en el log de Pegasus.

El síntoma engaña dos veces más. Es intermitente —el mismo archivo que acaba de
fallar anda a la vuelta siguiente— y **volver a pararse sobre el mismo juego lo
arregla a veces**, que es lo que reportó el autor y lo que mandó la
investigación en la dirección equivocada durante media noche.

La causa se aisló el 2026-08-22 dibujando `VideoOutput.sourceRect` en pantalla y
leyéndolo de una grabación, 36 cuadros a 1 por segundo:

| foco | `sourceRect` cargado | el del archivo | resultado |
|---|---|---|---|
| Street Fighter II | 490x360 | 384x224 | panel vacío |
| Metal Slug | 480x360 | 490x360 | panel vacío |
| Metal Slug | 384x224 | 490x360 | panel vacío |
| Metal Slug | 490x360 | 490x360 | anda |

**El `VideoOutput` se queda con la geometría del video anterior.** Su superficie
no se reinicia con el formato del medio nuevo, así que no llega un solo cuadro
aunque el player reproduzca. Reusar el player entre archivos es lo que dispara
esa carrera.

La restricción de fondo es que **no se puede parchear el binario**: Pegasus se
usa tal como se distribuye ([`ADR-0006`](0006-version-politica-pegasus.md)), y
Qt 5.15 es un límite duro ([`ADR-0006`](0006-version-politica-pegasus.md),
`spec/constitution/tech-stack.md`). Lo único que se puede cambiar es cómo el
theme usa la API.

## Decisión

El preview del hero **construye un par `MediaPlayer` + `VideoOutput` nuevo por
cada archivo** y destruye el anterior: un `Loader` cuyo `sourceComponent` pasa
por `null` antes de volver a asignarse. Un par nuevo no puede heredar el formato
de nadie.

La fuente la escribe **solo** el `Timer` de 650 ms, en una propiedad
`videoActual`. Eso separa dos cosas que antes estaban atadas: *ocultar el panel*
(inmediato, en cada cambio de foco) y *soltar el archivo* (cuando el foco se
queda quieto, o cuando el panel se apaga).

`screens/VideoPanel.qml` —el reproductor del detalle— **no cambia**: ahí el
juego no cambia mientras la pantalla está abierta, así que su player nunca se
reusa para un segundo archivo y la carrera no existe.

## Alternativas consideradas

### Reasignar `VideoOutput.source` después de arrancar

Detectar el arranque de la reproducción y volver a enganchar la salida al player
(`source = null; source = player`) para forzar a Qt a rehacer la superficie.

- A favor: dos líneas, sin tocar la estructura del componente.
- En contra: es una reparación a posteriori, no evita el daño.
- **Descartada porque:** se probó (300 ms después de encender el panel) y **no
  recupera la superficie** — el panel siguió saliendo vacío, verificado con
  `grabToImage`. Y además se ve: reasignar la salida deja un cuadro en blanco,
  o sea un destello visible en cada juego. Empeoró el síntoma sin arreglarlo.

### Evitar el teardown: pasar de un video al siguiente sin apagón

La primera hipótesis fue que el culpable era el `source: ""` intermedio que el
componente hacía en cada movimiento del foco (un teardown completo del backend
por cada juego recorrido). Se cambió para ir de un archivo al otro con un solo
`setMedia`.

- A favor: menos churn en el backend, y de hecho eliminó del log todas las
  advertencias `updateVideoFrame called without AVPlayerLayer`.
- En contra: no toca la causa.
- **Descartada porque:** el bug siguió apareciendo con la misma frecuencia. El
  `setMedia` directo también deja la geometría vieja — el problema es reusar el
  player, no cómo se lo apaga. Sirvió para descartar la pista falsa del
  `AVPlayerLayer`, que resultó ser ruido (ver `docs/plataforma-pegasus.md` §2).

### Mantener el subárbol renderizado durante la carga

Qt no dibuja un subárbol con opacidad cero, y toda la carga del video ocurre con
el panel en `opacity: 0`. La hipótesis era que AVFoundation necesitaba la
superficie viva en el momento de enganchar.

- A favor: un solo carácter de cambio (`opacity: activo ? 1 : 0.003`), invisible
  para el ojo.
- En contra: un valor mágico difícil de defender en una revisión.
- **Descartada porque:** se probó y no cambia nada. La superficie del
  `VideoOutput` no depende de que el item se dibuje.

### Compartir un único player entre el hero y el detalle

Un solo `MediaPlayer` para todo el theme, con dos `VideoOutput` colgados.

- A favor: un decoder en lugar de dos.
- **Descartada porque:** ya estaba descartado por medición previa: dos
  `VideoOutput` **no pueden** compartir un `MediaPlayer` — el primero se queda
  el renderer y el resto quedan vacíos, sin error y sin warning
  (`docs/plataforma-pegasus.md` §2, 2026-08-21). Va en dirección contraria a
  esta decisión.

## Consecuencias

**Positivas**

- El panel muestra el video **siempre**, no "casi siempre". Para un gabinete que
  corre solo, un fallo intermitente y silencioso no es un defecto cosmético: es
  el modo en que la pantalla se rompe sin que nadie se entere.
- Destruir el par al apagarse el panel refuerza la regla 2 de `VideoPanel.qml`
  (soltar el archivo, no pausar): ahora no queda ni el player.
- `VideoOutput.sourceRect` queda documentado como la señal de detección: si no
  coincide con la resolución del archivo cargado, no va a haber imagen. Es lo
  único observable que delata esta clase de fallo.

**Coste asumido**

- Un `MediaPlayer` se crea y se destruye por cada juego donde el foco se
  detiene más de 650 ms. El delay ya acota la frecuencia: recorrer un estante
  rápido no crea ninguno.
- Todo lo que use el player tiene que tolerar `null` — entre un video y el
  siguiente no existe. `arrancar()` recibe el player explícito porque cuando
  llega la primera señal de `status` el `Loader` todavía puede no haber
  publicado su `item`.
- El video del juego anterior sigue decodificando, invisible, hasta 650 ms más.

**Qué habría que revisar si esto se replantea**

- Que `VideoOutput.sourceRect` coincida con la resolución real del archivo
  recién cargado, reusando el player. Si en una versión futura de Pegasus/Qt
  eso pasa a cumplirse siempre, el `Loader` sobra y el componente vuelve a un
  `MediaPlayer` declarativo.
- Si aparece un segundo lugar del theme que cambie de video sin cambiar de
  pantalla, esta decisión aplica ahí también.

## Referencias

- `themes/attract/screens/HeroVideoPreview.qml` §reproduccion — la
  implementación, con la tabla de medición y las alternativas descartadas al
  lado del código.
- `docs/plataforma-pegasus.md` §2 (QtMultimedia) — los tres hechos que dejó esta
  sesión: el player reusado y la geometría vieja, que
  `updateVideoFrame called without AVPlayerLayer` es ruido, y que
  `ShaderEffect.status` reporta `Error` con el log vacío mientras dibuja bien.
- `spec/features/017-hero-video-preview/` — la feature donde apareció.
- [`ADR-0006`](0006-version-politica-pegasus.md) — Pegasus se usa tal como se
  distribuye; el binario no se parchea.
