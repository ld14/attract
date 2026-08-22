# 017 · Preview de gameplay en el hero — Tareas

_Checklist accionable derivada del `plan.md`._

> **La técnica está medida y el código está escrito; falta ver la feature en
> Home.** El experimento cerró en verde (2026-08-21): `OpacityMask` enmascara un
> `VideoOutput` y el video sigue vivo adentro. Lo que queda es la verificación
> visual del panel dentro de la pantalla real, abajo.

## Medición previa

- [x] Escribir `themes/experimentos/video-opacitymask.qml` — tres paneles:
      control sin máscara, `OpacityMask` sobre `VideoOutput`, y el plan B con
      gradiente. Hecho cuando: instala sobre `attract-debug/theme.qml` y carga
      sin `Theme loading failed`.
- [x] ~~Primera corrida (2026-08-21)~~ — **inválida, no midió nada.** Los tres
      `VideoOutput` colgaban de un solo `MediaPlayer` y en QtMultimedia 5 eso
      deja sin cuadros a todos menos al primero: los paneles B **y C** salieron
      vacíos, y C ni usa máscara. Corregido con un player por panel. El hallazgo
      colateral (dos `VideoOutput` no comparten player) ya está en
      `docs/plataforma-pegasus.md` §2.
- [x] Segunda corrida (2026-08-21) — ✅ **la máscara funciona.** El panel B
      muestra el video y lo disuelve hacia abajo; el panel C, sin máscara,
      termina en un canto recto. Los tres paneles van por el mismo cuadro de
      partida, así que el de adentro de la máscara **no está congelado**.
      Punto 3 (gradiente lateral rotado) quedó **sin resolver**: el video de
      prueba es letterbox sobre negro y un velo del 50% de `#06070c` sobre negro
      no se ve. Se cierra mirando el hero real, donde detrás hay `AccentWash`.
- [x] Decidir máscara vs. plan B — **máscara**. Plan B descartado; anotado en
      `plan.md` §Implementación.
- [x] Agregar el hecho a `docs/plataforma-pegasus.md` §2 · La API, subsección
      `QtMultimedia`: `OpacityMask` sobre `VideoOutput` funciona y no congela.
      Va junto al hallazgo colateral de la primera corrida.
- [x] Volver a correr `make theme-debug` — la copia del experimento había
      pisado el harness de ADR-0001. Restaurado.

## Implementación

- [x] Escribir `themes/attract/screens/HeroVideoPreview.qml` — el panel
      completo. Se escribió antes de la medición, pero la medición lo
      convalidó: ya no es provisional.
- [x] Cablear en `themes/attract/screens/BrowseScreen.qml` — una instancia
      **entre `heroBox` y `estantes`**, con un comentario diciendo que el orden
      de declaración es funcional.
- [x] Reconciliar el componente con el resultado del experimento — salió la
      máscara, así que `capas` + `OpacityMask` se quedan como están. El
      comentario de `HeroVideoPreview.qml` ya no advierte que falta medir: cita
      la medición del 2026-08-21 y la condición que la sostiene (un
      `MediaPlayer` propio por `VideoOutput`).

## Verificación en Pegasus

_No hay tests automáticos de QML: los 184 del repo son de `src/attract/`. Cada
cambio de un `.qml` instalado exige `make theme`, ⌘Q y reabrir
(`plataforma-pegasus.md` §4)._

> **Bug encontrado y corregido en la primera corrida (2026-08-21).** El panel
> parpadeaba y el video no arrancaba nunca: `arrancar()` colgaba de
> `onSourceChanged`, que llega con `status: Loading`, y ahí `play()` se acepta y
> se descarta en silencio — `PlayingState` por 1ms y de vuelta a `StoppedState`.
> El panel entraba con ese milisegundo y salía seco. El `plan.md` §"Entrada
> gatillada por reproducción" tenía la intención correcta pero la propiedad
> equivocada: `playbackState` no mide carga, `status` sí. `arrancar()` pasó a
> `onStatusChanged`, gatillado en `Loaded` **o** `Buffered` — los dos, porque la
> segunda carga en adelante se saltea `Loaded`. Los tres hechos de plataforma
> quedaron en `docs/plataforma-pegasus.md` §2.
>
> **Material de prueba (2026-08-22).** La librería real tiene **un** juego con
> video, y con uno solo el criterio principal no se puede probar: pasar por
> juegos sin video ejercita `hayVideo`, no el debounce. Se armó
> `library/preview/` —la colección desechable que `CLAUDE.md` ya prevé— con
> cuatro juegos contiguos que comparten el mismo `video.mp4` y un quinto **sin**
> video. Es material desechable, no parte de la feature: se borra con
> `rm -rf library/preview` más sacar su línea de `game_dirs.txt`.

- [x] **Sin video** — cerrado por inspección. El binding es
      `(encendido && mostrar && hayVideo) ? game.assets.video : ""`: con
      `hayVideo` en false la fuente queda en `""` pase lo que pase con el timer,
      y sin fuente `playbackState` nunca llega a `Playing`, así que `activo` no
      se enciende. No hay panel ni hueco que reservar. El log del 2026-08-22 lo
      acompaña (`Preview Sin Video | video: no`, sin asignación de fuente).
- [x] **Sin parpadeo** (log, 2026-08-22) — el criterio de aceptación principal.
      En el recorrido `Cuatro → Dos → Sin Video → Tres` hay **tres cambios de
      juego seguidos sin una sola asignación de fuente con ruta**: el timer de
      650ms no llegó a completarse en ninguno, o sea que se cruzaron más rápido
      que eso y **no se decodificó ni un cuadro**.

      Honestidad sobre el alcance: fueron 3 juegos, no los 10 del enunciado, y
      la instrumentación de esa corrida ya no llevaba timestamps, así que el
      "~2s" no está medido — lo que está probado es la implicación que importa
      (cruce más rápido que el debounce ⇒ cero cuadros), y esa no depende del
      número de juegos.
- [x] **Arranque limpio** (log, 2026-08-21): `status 2 → 3 → 6` y recién ahí
      `playbackState: 1`. `activo` pasa a true con la media ya `Buffered`, así
      que no hay rectángulo negro previo. Falta confirmar a ojo el
      fade + slide + escala.
- [x] **Salida seca** (log, 2026-08-21): `gameChanged` y `activo: false` en el
      **mismo milisegundo**; `source` a vacía 36ms después. Sin fade de salida.
- [ ] **Encuadre**: el video llena el panel sin franjas **y sin deformarse**.
      Mirar algo con círculos o texto en pantalla, que es donde se nota si
      `PreserveAspectCrop` estira en vez de recortar — la incógnita que
      `plataforma-pegasus.md` §5 dejó abierta. Anotar el resultado ahí.
- [ ] **Degradé lateral** (lo que el experimento no pudo cerrar): el borde
      izquierdo del panel tiene que verse oscurecido contra el `AccentWash`, sin
      corte vertical duro entre la sinopsis y el video. Si no se nota, la
      rotación de -90 del `Rectangle` está mal y hay que ir al `Canvas`.
- [ ] **Cruce con las tarjetas**: pasan por encima y el panel se disuelve; sin
      canto recto, sin borde, sin sombra.
- [x] **Loop y silencio** (log, 2026-08-21): tres reenganches a 15.31 / 15.18 /
      15.18s contra un archivo de 15.05s. En los tres `playbackState` no se
      movió de `PlayingState` — el loop **no** hace parpadear al panel. Cero
      `HeroVideoPreview: muted/loops...` en todo el log.
- [x] **Quieto de verdad** (log, 2026-08-21): **49s** sobre el mismo juego sin
      un solo `gameChanged`. El riesgo de `estantes.currentItem` parpadeando a
      `null` (ver `plan.md` §Riesgos) **no se materializa**; queda descartado
      para Home con este catálogo.
- [ ] **Badge**: dice `● GAMEPLAY`, el punto late y está teñido con el accent
      del juego; cambiar de juego le cambia el color.
- [ ] **Popover de orden**: abrirlo **no** apaga el video — Home se sigue
      viendo detrás. Es la única excepción de `encendido` y es a propósito.
      _Sin verificar. La instrumentación se sacó el 2026-08-22 con el material
      de prueba; para cerrarlo hay que volver a poner un `console.log` en
      `onEncendidoChanged` y mirar que abrir el popover NO lo dispare._
- [x] **Foco** — cerrado por inspección, que acá es **más fuerte** que el
      recorrido con el mando: un barrido manual puede no pasar por un camino,
      esto no. `HeroVideoPreview.qml` no declara ni un `MouseArea`, ni
      `focus:`, ni `Keys.`, ni `FocusScope` (los únicos matches del grep caen
      dentro del comentario que lo afirma), y en `BrowseScreen.qml` se instancia
      **sin `id`**, así que ninguna cadena de `KeyNavigation` puede nombrarlo.
- [ ] **Decoder**: entrar y salir del detalle ~15 veces sin degradación.
- [ ] Correrlo también en el gabinete (ADR-0003): el riesgo de `loops` entre
      backends es el que la feature 006 dejó abierto.

## Cierre

- [ ] Validar contra todos los criterios de aceptación de `spec.md`.
- [x] ~~ADR por el plan B~~ — no aplica: el experimento salió a favor de la
      máscara, así que no se revierte nada.
- [x] Actualizar la entrada de `../../constitution/roadmap.md` — decía que el
      componente no estaba escrito y que el experimento bloqueaba la feature.
- [ ] Mover la feature a "Hecho" en `../../constitution/roadmap.md`.
