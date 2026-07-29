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

- [ ] `themes/attract/theme.cfg` + `qmldir` + `theme.qml` mínimo (un
      rectángulo) + `Theme.qml` singleton con dos colores.
- [ ] Instalar y abrir Pegasus. Hecho cuando: carga sin "Theme loading
      failed", es decir **un theme de Pegasus soporta subcarpetas y
      singletons vía `qmldir`**. Si no: aplanar el árbol y reemplazar los
      singletons por un `QtObject` con `id` en `theme.qml` (ver `plan.md`).
- [ ] `Makefile`: `make theme` → `themes/attract/`, `make theme-debug` →
      `themes/attract-debug/`. El de debug **no se toca ni se borra**: es la
      evidencia de ADR-0001 y el archivo sobre el que se copian los
      experimentos.

## 2 · Cimientos

- [ ] `Theme.qml` — colores base, radios, sombras, espaciado (handoff §Design
      Tokens), `FontLoader` de las tres familias con fallback al sistema, y
      los helpers `mix(a,b,t)` / `alpha(c,a)` que reemplazan `color-mix()` y
      los `rgba()` del CSS.
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

- [ ] `Background.qml` — las tres capas del handoff + overlay CRT. Scanlines
      con `Image` de 1×8px en `fillMode: Image.Tile` y la `y` animada.
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
