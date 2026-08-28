# 017 · Preview de gameplay en el hero de Home

**Estado:** implementada (`a966831`). Falta la verificación visual contra
Pegasus real — ver `tasks.md` §Verificación.

_El diseño de referencia está en [`design/hero-video-preview.md`](design/hero-video-preview.md)._

## Qué hace

Cuando el juego enfocado en Home tiene video de gameplay, aparece un panel de
video ambiental a la derecha del bloque de texto del hero — contiguo al título
y la sinopsis, no encima ni en lugar de ellos. Arranca solo tras ~650ms de
quietud sobre el mismo juego, se reproduce en loop **con audio al 30%** y se
disuelve hacia abajo por debajo de la primera fila de tarjetas.

El audio entra en la revision del 2026-08-22 y reemplaza al silencio con el
que la feature se escribio. La condicion que lo hace vivible: el volumen
cuelga de que el panel este visible, asi que suena lo que se ve y nada mas.

No es un reproductor: no tiene controles, no recibe foco y no captura clics.
Los controles de transporte siguen siendo cosa del detalle
([`screens/VideoPanel.qml`](../../../themes/attract/screens/VideoPanel.qml),
feature 006).

## Por qué

El hero de Home ocupa 600px de los 1280 del lienzo y el resto está vacío: un
juego enfocado se cuenta hoy solo con texto. El video ya existe en la librería
(`game.assets.video`) y hasta ahora había que entrar al detalle para verlo. El
efecto que se busca es que el gabinete "respire" solo — que quedarse quieto
sobre un juego lo muestre en movimiento, sin que nadie apriete nada.

## Criterios de aceptación

- [ ] Dado un juego **sin** video, cuando se enfoca, entonces el hero se ve
      **idéntico a hoy**: sin hueco reservado, sin placeholder, sin panel.
- [ ] Dado un recorrido rápido por 10 juegos en ~2s, cuando se navega, entonces
      **no aparece ni un solo cuadro de video** — el panel nunca parpadea.
- [ ] Dado un juego con video, cuando pasan ~650ms sin mover el foco, entonces
      el panel entra con fade + desplazamiento desde la izquierda + escala,
      y **sin mostrar un rectángulo negro antes** de que haya imagen.
- [ ] Dado el panel visible, cuando se mueve el foco a otro juego, entonces
      **desaparece en el acto** — sin fade de salida. El diseño dice "ocultar
      inmediatamente" y hay un motivo: la fuente se suelta en el mismo tick, así
      que un fade de salida no funde el video, funde un panel ya vacío.
- [ ] Dado el panel visible, cuando el video llega al final, entonces
      reengancha solo y **sigue sonando al 30%** (`loops` verificable en
      runtime, no asumido).
- [ ] Dado un video sonando, cuando el foco se mueve a otro juego, entonces
      **el audio se corta con la imagen** — no sigue sonando el juego
      anterior mientras el panel esta oculto.
- [ ] Dado el panel visible, entonces el video **llena el panel sin deformarse
      ni dejar franjas** (`object-fit: cover` del diseño). Cierra de paso la
      incógnita de `PreserveAspectCrop` que `docs/plataforma-pegasus.md` §5
      dejó abierta: se sabe que llena, no si recorta o estira.
- [ ] Dado el panel visible, entonces el badge dice **`● GAMEPLAY`** con el
      punto teñido del accent del juego y latiendo, y ese color **cambia junto
      con el resto de la UI** al cambiar de juego.
- [ ] Dado el panel visible, cuando cruza la primera fila de tarjetas, entonces
      las tarjetas se dibujan **encima** y el panel se disuelve hacia abajo:
      sin borde, sin sombra proyectada y sin canto recto.
- [ ] Dado cualquier recorrido con el mando por Home, cuando se navega, entonces
      el foco **nunca** se para sobre el panel.
- [ ] Dado que se abre el detalle, un overlay o el visor, entonces el panel
      suelta el decoder (`source: ""`), no solo se oculta.

## Fuera de alcance

- **Controles de transporte, volumen y mute** — el preview suena al 30% fijo;
  regularlo o silenciarlo es el panel del detalle
  (feature [006-theme-documentos](../006-theme-documentos/spec.md)).
- **Elegir o generar el video.** El panel consume `game.assets.video` tal como
  lo entrega Pegasus; que exista es responsabilidad de la ingesta.
- **Preview en las otras pantallas.** Buscar (feature 010) y el detalle tienen
  sus propias reglas; esto es solo Home.
- **Precarga o caché de decoders.** Un juego a la vez, decoder liberado al
  moverse.
