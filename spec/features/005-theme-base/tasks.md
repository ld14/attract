# 005 · Theme de producción, base — Tareas

_Checklist accionable derivada del `plan.md`._

## 0 · Desbloquear (va primero, todo lo demás depende de esto)

Los tres experimentos ya están escritos en `themes/experimentos/`. Falta
correrlos contra Pegasus real y anotar el `RESULTADO OBSERVADO` en el
encabezado de cada archivo — el mismo patrón que usaron `pdf-qtquick.qml` y
`json-chain-test.qml`.

- [ ] **`rutas-relativas.qml`** — ¿existe `game.files`? ¿qué forma tiene?
      Hecho cuando: sabemos, para los 4 juegos del fixture, qué vía resuelve
      `media/<set>/` sin hardcodear. **Bloquea `Paths.qml`.**
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
- [ ] `core/Paths.qml` — `baseDe(game)` y `magazineDe(ref)`, con el set desde
      `x-set` y fallback al basename. Hecho cuando: devuelve la ruta correcta
      para los 4 juegos del fixture, incluido el bloque `EXPERIMENTO` que no
      tiene `x-set`, **y no hay una sola ruta absoluta en el theme**.
- [ ] `core/GameData.qml` — XHR de `data.json`, expone `accent`/`accent2`/
      `review`/`cheats`/`manual`/`mags` + `estado`. Hecho cuando: `mok` (sin
      archivo) cae a `sin-datos` sin crashear, un JSON corrupto también, y el
      set ya leído no se vuelve a pedir.

## 3 · Átomos (`ui/`)

- [x] `Background.qml` — las tres capas del handoff + overlay CRT. Los
      gradientes radiales y horizontales van con `Canvas` (`Rectangle` solo
      hace verticales en QtQuick 2.0), y las scanlines con un `Canvas` pintado
      **una sola vez** animando la `y` — no hay repintado por frame. Todo con
      `QtQuick 2.0`: si el experimento de `QtGraphicalEffects` falla, este
      archivo no cambia una línea. Las tres aproximaciones a CSS quedaron
      anotadas en el encabezado, como pide el handoff.
- [ ] `CoverImage.qml` — cadena `boxFront → poster → marquee → color-wash con
      accent`, saltando con `onStatusChanged`. Hecho cuando: `mok` (sin
      `boxFront`) muestra su `poster`, y un juego sin ningún asset muestra el
      color-wash, no un hueco. **Es el único lugar del theme que conoce la
      cadena de §2.2.**
- [ ] `Chip.qml`, `GlassButton.qml`, `AccentButton.qml`, `SectionLabel.qml`,
      `FocusRing.qml` — cada uno recibe `accent` como propiedad; ninguno lo
      busca en el singleton.

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
