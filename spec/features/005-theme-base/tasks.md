# 005 · Theme de producción, base — Tareas

_Checklist accionable derivada del `plan.md`._

## 0 · Desbloquear (va primero, todo lo demás depende de esto)

Los tres experimentos ya están escritos en `themes/experimentos/`. Falta
correrlos contra Pegasus real y anotar el `RESULTADO OBSERVADO` en el
encabezado de cada archivo — el mismo patrón que usaron `pdf-qtquick.qml` y
`json-chain-test.qml`.

- [x] **`rutas-relativas.qml` — cerrado 2026-08-02.** La Vía 1 funciona:
      `files[0].path` da la ruta absoluta de la ROM y de ahí sale el
      directorio de la colección. Tres cosas que no eran obvias y que
      cambiaron cómo se escribió `Paths.qml`:
      1. **`path` viene SIN esquema** (`/Users/…/dino.zip`), al revés que los
         assets, que sí traen `file:///`. Esa asimetría es una trampa: el
         `XMLHttpRequest` necesita el esquema, así que se agrega en un solo
         lugar.
      2. **`files[0].name` ya viene sin extensión** (`dino`, no `dino.zip`).
         El fallback del set para juegos sin `x-set` sale directo de ahí, sin
         parsear nada.
      3. **Un juego de Steam devuelve `steam:255710`** — un URI sin ninguna
         barra, no una ruta. `Paths` lo detecta y devuelve `""`, que es la
         degradación de §2.3, no una ruta inválida.
- [ ] **`graphical-effects.qml`** — ¿resuelve `import QtGraphicalEffects 1.0`?
      Hecho cuando: sabemos cuál de los tres desenlaces del encabezado pasó.
      **Bloquea las sombras, el glow y el blur de todo el theme.**
- [ ] **`multimedia-loop.qml`** — bloquea la 006, no esta. Se corre igual de
      paso, contra `library/` (los fixtures son de 0 bytes, no hay `.mp4`).
- [ ] Bajar los `.ttf` de Chakra Petch, Sora y JetBrains Mono a
      `themes/attract/fonts/`. El gabinete es offline: no se pueden pedir en
      runtime. Sin esto el theme carga igual, con las fuentes del sistema.

## 1 · Esqueleto (y la pregunta que responde)

- [x] `themes/attract/theme.cfg` + `qmldir` + `theme.qml` + `Tokens.qml`
      (singleton, expuesto como `Theme`) + `ui/Background.qml`. El esqueleto
      ejercita **las dos** cosas que hay que confirmar a la vez: el singleton
      de la raíz vía `qmldir` y el `import "ui"` de una subcarpeta. Si solo
      probara una, no responde la pregunta.
- [x] **Hallazgo, resuelto en el momento: el singleton no puede llamarse
      `Theme.qml`.** Pegasus exige `theme.qml` como entrada del theme, y en
      macOS y Windows el filesystem es case-insensitive — son **el mismo
      archivo**. Se comprobó a lo bruto: un `echo > theme.qml` borró el
      contenido de `Theme.qml`, sin un error, sin un aviso. El archivo pasa a
      llamarse `Tokens.qml` y el `qmldir` lo expone como `Theme`, así que en
      el código no cambia nada (`Theme.screen` sigue siendo `Theme.screen`).
      **No se agrega un chequeo a `attract doctor`:** en un filesystem
      case-insensitive el par colisionante no puede existir, así que no hay
      nada que detectar en el Mac ni en el gabinete; solo se vería en Linux, y
      el proyecto no tiene ninguna máquina Linux (ADR-0003). Un chequeo que
      nunca dispara es peor que el comentario que quedó en `Tokens.qml`.
- [x] **Decisión de diseño que salió de acá: un solo singleton.** `Paths` y
      `GameData` quedan como componentes normales, no singletons — un
      singleton en subcarpeta necesita su propio `qmldir` y es el mecanismo
      del que menos se sabe contra este binario. Se usa el que hace falta y no
      se apuesta al otro.
- [x] **Confirmado contra Pegasus real, 2026-07-29.** Cargó de una, sin
      bisección: **un theme de Pegasus SÍ soporta un singleton vía `qmldir` y
      un `import` de subcarpeta.** El panel reportó `singleton Theme (qmldir):
      OK`, `import "ui" (subcarpeta): OK`, lienzo 1280×720 escalado a 1.125
      en una ventana de 1440×900 (o sea el escalado de ADR-0016 funciona), y
      `fuentes: DEL SISTEMA` — correcto, los `.ttf` todavía no están.
      **Con esto el árbol de `plan.md` queda habilitado tal como está: no hace
      falta aplanarlo ni sacar el singleton.**
- [x] **Bug de fidelidad encontrado en esa misma corrida y arreglado.** El
      glow del fondo se derramaba sobre media pantalla en vez de quedar arriba
      a la derecha. El CSS pide `radial-gradient(130% 100% at 72% 8%, ...)` y
      ese `130% 100%` es una **elipse**; `createRadialGradient` solo hace
      círculos, así que el glow se extendía ~765px hacia abajo en vez de ~330.
      Se arregla escalando el contexto del `Canvas` en `y` antes de pintar.
      Es exactamente el tipo de cosa que no se ve leyendo el CSS y sí se ve
      en pantalla — el motivo de que esta tarea exista antes de las pantallas.
- [x] **Tres hallazgos más de la misma corrida**, que salieron de que el panel
      reportara 6 juegos donde los metadata declaran 5:
      1. **`api.allGames` NO es la librería de ATTRACT.** El sexto juego era
         _Cities: Skylines_, de la librería de Steam del autor — Pegasus tenía
         cinco providers activos. Un juego que entra por otro provider no
         tiene `x-set`, ni `data.json`, ni carpeta de colección. Resuelto en
         [`ADR-0017`](../../decisions/0017-providers-pegasus.md): se apagan
         por config, el theme no filtra.
      2. **ADR-0004 se sostiene, y la sospecha previa era falsa.** Se
         sospechaba que `allGames` contaba un juego por cada `file:`, lo que
         habría mostrado el mismo juego repetido en el rail. `TEST MULTIFILE`
         reportó `[files: 2]` — **un** juego con dos archivos, tal como
         decidió ADR-0004. No hay nada que replantear.
      3. **`game.files` existe y tiene `.count`.** Es medio experimento 1
         resuelto de rebote: lo que falta confirmar es si `files.get(0).path`
         da la ruta absoluta de la ROM, que es de donde `Paths` va a derivar
         `media/<set>/`. Anotado en el encabezado del experimento.
      Los dos _The Maze of the Kings_ no son un bug: `game_dirs.txt` apunta a
      `fixtures/arcade` y a `library/arcade`, los dos declaran
      `collection: Arcade` (Pegasus las fusiona) y cada uno tiene su propio
      `mok.zip`. Se deja así a propósito mientras se desarrolla: es un caso
      real de dos colecciones fusionadas que conviene tener a la vista, y el
      theme **no** debe intentar deduplicar — no tiene con qué saber cuál es
      el bueno.
- [x] `Makefile`: `make theme` → `themes/attract/`, `make theme-debug` →
      `themes/attract-debug/`. El de debug **no se toca ni se borra**: es la
      evidencia de ADR-0001 y el archivo sobre el que se copian los
      experimentos.

## 2 · Cimientos

- [x] `Tokens.qml` — colores base, radios, sombras, espaciado (handoff §Design
      Tokens), `FontLoader` de las tres familias con fallback al sistema, y
      los helpers `mix(a,b,t)` / `alpha(c,a)` que reemplazan `color-mix()` y
      los `rgba()` del CSS. Más `accentDe()`/`accent2De()`, que centralizan la
      degradación de ADR-0013 en un solo lugar. `fonts/README.md` dice qué
      `.ttf` bajar y qué pasa si faltan (el theme carga igual, con las fuentes
      del sistema, y el panel de diagnóstico lo dice en pantalla).
- [ ] `theme.qml` — canvas de 1280×720 con
      `scale: Math.min(w/1280, h/720)`, centrado (ADR-0016). Estado: `screen`,
      `selected`, `launching`. Overlays en `Loader { active: ... }`.
- [x] `core/Paths.qml` — escrito. `setDe`, `baseDe`, `dataJsonDe`,
      `magazineDe`/`magazineJsonDe` y `manualDe`. Es el único lugar del theme
      que arma una ruta, y **no hay una sola ruta absoluta en todo el theme**:
      con esto se paga la deuda que arrastran los dos experimentos viejos, que
      hardcodean la ruta al Mac del autor y rompen ADR-0003.
      **El plan B (derivar de un asset) no quedó como fallback: está
      descartado**, con tres casos medidos que lo rompen — asset con URL
      remota, `TEST MULTIFILE` sin ningún asset, y el juego de
      `library/arcade` tampoco.
- [ ] **Verificar `Paths` en Pegasus.** El panel de diagnóstico ahora lista,
      por cada juego, el `set` y la `base` que resuelve — es el chequeo, ya
      que en QML no hay framework de tests. Hecho cuando, con `game_dirs`
      apuntando a los dos directorios:

      | Juego | `set` esperado | `base` esperada |
      |---|---|---|
      | `EXPERIMENTO` (dino) | `dino` — por basename, no tiene `x-set` | `…/fixtures/arcade/media/dino/` |
      | `sf2ce`, los dos `mok` | por `x-set` | `…/media/<set>/` |
      | `TEST MULTIFILE` | `test-multifile` | `…/media/test-multifile/` aunque no tenga **ningún** asset |
      | Cualquiera de Steam | `steam:NNNNN` | **vacía** — `path` es un URI, no una ruta. Degradar acá es lo correcto |
- [x] `core/GameData.qml` — escrito. XHR de `data.json`, expone
      `accent`/`accent2`/`review`/`cheats`/`manual`/`mags`, el `estado`, los
      flags `hayRevistas`/`hayCheats`/`hayManual`/`hayReview` y `catDe()` para
      los dos niveles de "sin dato" de §2.3. El `accent` pasa por
      `Theme.accentDe()`, así que la degradación de ADR-0013 vive en un solo
      lugar.

      **Tercera regla, que no estaba en el plan y sí hacía falta: las
      respuestas pueden llegar desordenadas.** Mover el foco rápido por el rail
      dispara una petición por juego, y la del juego 3 puede llegar después de
      la del 5 — la ficha mostraría los datos del juego equivocado. Es un bug
      silencioso y difícil de reproducir a mano. Cada respuesta se compara
      contra la URL vigente antes de aplicarse, y la petición anterior se
      aborta al empezar una nueva.
- [ ] **Verificar `GameData` en Pegasus** (mismo panel, misma pasada que
      `Paths`). Recorriendo los juegos con ← →, el fondo cambia de color con
      el accent real de cada `data.json`. Hecho cuando:

      | Juego | Esperado |
      |---|---|
      | `EXPERIMENTO` (dino) | `listo`, accent `#ffb020` de `data.json`, 1 revista, 4 combos + 2 trucos, review con `score=94` y las seis categorías en `-` (reseña parcial) |
      | `sf2ce` | `listo`, accent `#ff5a3c`, 1 revista con el `ref` colgado, manual de 4 págs, sin cheats, sin review |
      | `mok` (fixtures y library) | `sin-datos` — no tienen `data.json`. Accent neutro. **Sin crash** |
      | `TEST MULTIFILE` | `sin-datos` con la base bien resuelta, aunque no tenga ningún asset |
      | Cualquiera de Steam | `sin-datos` con base vacía |

## 3 · Átomos (`ui/`)

- [x] `Background.qml` — las tres capas del handoff + overlay CRT. Los
      gradientes radiales y horizontales van con `Canvas` (`Rectangle` solo
      hace verticales en QtQuick 2.0), y las scanlines con un `Canvas` pintado
      **una sola vez** animando la `y` — no hay repintado por frame. Todo con
      `QtQuick 2.0`: si el experimento de `QtGraphicalEffects` falla, este
      archivo no cambia una línea. Las tres aproximaciones a CSS quedaron
      anotadas en el encabezado, como pide el handoff.
- [x] `CoverImage.qml` — escrito. Cadena `boxFront → poster → marquee →
      color-wash con accent`, saltando con `onStatusChanged`. **Es el único
      lugar del theme que conoce la cadena de §2.2.**
      Se salta por `Image.Error` y **no** chequeando si el string está vacío,
      por algo medido: un asset puede existir en el metadata y no cargar — un
      juego de Steam devuelve `boxFront` como URL remota, y en un gabinete
      offline eso nunca llega. `Image.Error` es la única señal confiable.
      Lleva `asynchronous: true` (una URL remota no puede congelar la UI) y
      `sourceSize` (un escaneo real dibujado en una tarjeta de 148×166 no
      tiene por qué decodificarse entero en memoria, por tarjeta).
- [x] `Boton.qml` (`variant: "accent" | "glass"`), `Chip.qml`,
      `SectionLabel.qml`, `FocusRing.qml` — cada uno recibe `accent` como
      propiedad; ninguno lo busca en el singleton. Los dos botones del plan
      quedaron en un archivo: diferían en dos colores y nada más.
      `Chip` centraliza el `"Sin Información"` de §2.3 para que no se olvide
      en una pantalla.
- [ ] **Verificar los átomos en Pegasus** (misma pasada que `Paths` y
      `GameData`). El panel dibuja una `CoverImage` del juego enfocado, dos
      `Chip` (AÑO desde `releaseYear`, FORMATO desde `x-formato`) y los dos
      `Boton`, con **▲ ▼** para mover el foco entre ellos. Hecho cuando,
      recorriendo los juegos:

      | Juego | Eslabón de la cadena que tiene que verse |
      |---|---|
      | `EXPERIMENTO` (dino) | imagen — tiene `boxFront` |
      | `mok` (fixtures) | imagen — **no** tiene `boxFront`, cae a `poster` |
      | `TEST MULTIFILE` | color-wash con el accent — no tiene ningún asset |
      | Cualquiera de Steam | color-wash — la URL remota no carga sin internet |

      Y los chips: `AÑO` en `"Sin Información"` donde `releaseYear` es `0`,
      `FORMATO` con `PCB`/`GD-ROM` desde `x-formato` — nunca desde
      `mediaFor()`, que se equivoca en 4 de 5 (`docs/mapeo-mockup-pegasus.md`).

## 4 · Librería

- [ ] `screens/LibraryScreen.qml` — barra superior (wordmark, pills de filtro
      **decorativas**, reloj que se actualiza cada 20s), hero (eyebrow,
      título, sinopsis, botones, contador `NN / NN`) y el rail de carátulas.
- [ ] Foco: flechas izquierda/derecha mueven de a uno; el rail sigue al foco
      manteniendo la tarjeta enfocada tercera desde la izquierda. La enfocada
      se eleva y toma su accent; las demás quedan al 50%.
- [ ] Enter/A: si la tarjeta ya está enfocada, abre el detalle; si no, solo la
      enfoca. Es el patrón TV del handoff — **no** se entra de una.
- [ ] `overlays/LaunchOverlay.qml` — scrim, spinner en accent, "INICIANDO" y
      el título. La línea del comando de lanzamiento sale de Pegasus o no se
      muestra; **no se inventa un `retroarch -L core.dll` como el prototipo**.

## 5 · Detalle

- [ ] `screens/DetailScreen.qml` — barra superior con "◄ GALERÍA", columna
      izquierda (panel de carátula + botón JUGAR) y columna de información
      (título, chips, box art + badge, sinopsis).
- [ ] Badge de formato desde `x-formato`. Hecho cuando: `mok` muestra
      `GD-ROM` y `sf2ce` muestra `PCB` — que es justo donde `mediaFor()` del
      prototipo se equivoca (`docs/mapeo-mockup-pegasus.md`).
- [ ] `ReviewCard.qml` — los dos niveles de §2.3. Hecho cuando: `mok` (sin
      `data.json`) muestra el bloque entero en "Sin Información", y `dino`
      (`{"review": {"score": 94}}`) muestra el 94 con las seis categorías en
      `"-"`.
- [ ] `ExtrasList.qml` — tarjetas de CONTENIDO EXTRA. En 005 solo puede
      aparecer la del manual; sin extras, `"No Disponible"`. **Ningún bloque
      desaparece** (§2.3 le gana al handoff — anotarlo como divergencia
      consciente en el componente).
- [ ] El panel de carátula queda listo para recibir el video de la 006 sin
      rehacer el layout.
- [ ] Foco: `[JUGAR] → [extras]` con izquierda/derecha; Escape/B vuelve a la
      librería.

## 6 · Cierre

- [ ] Los 7 casos de la tabla de `spec.md` §"Contra qué se verifica",
      corridos contra `fixtures/` en Pegasus real.
- [ ] Comparar la librería y el detalle contra
      `design_handoff_game_detail/Pegasus Game Detail.dc.html` abierto al
      lado, y anotar las diferencias que queden. Es a ojo: no hay forma
      automática, y el canvas fijo (ADR-0016) existe para que la comparación
      tenga sentido.
- [ ] Anotar en `plan.md` qué aproximaciones a CSS hicieron falta de verdad,
      una vez que el experimento de `QtGraphicalEffects` haya respondido.
- [ ] `make test` y `make doctor` en verde.
- [ ] Mover `005-theme-base` a "Hecho" en `../../constitution/roadmap.md`, y
      agregar `themes/attract/` al mapa de `CLAUDE.md` y a
      `../../constitution/tech-stack.md`.
