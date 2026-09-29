# 028 · Cómo se juega — theme — Tareas

_Checklist accionable derivada del `plan.md`. Tareas pequeñas y concretas;
marca `[x]` al completarlas._

## 0 · Documentos

- [x] `spec.md`/`plan.md` desde la spec 027 original, partidos por decisión
      del autor (2026-09-28).
- [x] Roadmap: 028 anotada (ver `spec/constitution/roadmap.md`).

## 1 · Datos (`core/`)

- [x] `core/Gabinete.qml` — mismo patrón que GameData (XHR + tres estados,
      no XHR síncrono sin verificar), URL fija con `Qt.resolvedUrl`. Expone
      `jugadores`/`flippers`/`perifericos`/`salida` y
      `algunaPosicionMedida` (siempre `false` hoy — el interruptor que usa
      `ControlDiagram` para no intentar resolver posiciones que la Etapa F
      todavía no midió).
- [x] `core/Paths.qml` — `controlesDe(game)`. 404 no es error, mismo
      criterio que `plataformaDe`.
- [x] `core/Correspondencia.qml` — nuevo (no estaba nombrado así en
      `plan.md`): lee `_controles.json` por colección, recorta la entrada
      del juego enfocado. Expone `controlesDeclarados` (MAME, granularidad
      de `-listxml`) y `salidaJuego`/`joysticktype` (DOSBox, ya resuelto por
      juego).
- [x] `core/GameData.qml` — `guia`/`hayGuia`/`guiaObjetivo`/`guiaAcciones`/
      `guiaPrimerosPasos` (tope 3)/`guiaReglasEsenciales` (tope 3)/
      `guiaMultijugadorModo`/`guiaMultijugadorJugadores`/`guiaPerifericos`.
      Un `guia.multijugador.modo` desconocido degrada a `"individual"` acá
      mismo (AVISO del lado de `doctor`, no ERROR).

## 2 · `ExtrasList` y foco

- [x] Cuarta tarjeta "Cómo se juega", primera, `hay: true` fijo (siempre
      abre) y sin la columna de subtítulo que tenían las otras tres.
- [x] Subtítulo compartido debajo de la fila (`_subtituloDe(root.foco)`):
      "Guía propia"/"Ayuda general" para la tarjeta nueva, las tres
      funciones de subtítulo anteriores intactas para las otras.
- [x] `DetailScreen.qml`: `_targets` a 8, `abrirExtra("guia")` en foco 3 sin
      condición de `hay*` (siempre dispara), galería/hacks/manual/favoritos
      corridos a 4/5/6/7. `onFocoChanged` (scroll a fondo del carrusel de
      revistas) actualizado de foco 6 a 7.

## 3 · Diagrama y overlay

- [x] `core/ControlDiagram.js` (nuevo, no estaba en el plan original) +
      `ui/ControlDiagram.qml` — la clasificación "sin uso"/"acción
      desconocida" se extrajo a un módulo JS puro, mismo criterio que
      `InputTokens.js`: es la lógica más fácil de romper sin que se note en
      una captura. **17 tests en `tests/test_control_diagram.cjs`**,
      incluidos los casos reales de SFA2 (6 botones, nada sin uso) y Pacman
      (0 botones, cualquier acción declarada es inconsistente).
- [x] Distinción visual: botón sin acción → círculo apagado + "Sin uso"
      (`Theme.textFaint`); acción con `control` fuera de rango → fila roja
      aparte con "· acción desconocida". Los dos casos ya tienen test node
      dedicado; falta la comparación visual en Pegasus (ver Cierre).
- [x] `overlays/GuideOverlay.qml` — título, diagrama, objetivo, primeros
      pasos, reglas esenciales, "cómo salir", JUGAR + accesos a Hacks/Manual
      (Manual solo si `hayManualPaginas`). Sin `guia` propia muestra el
      objetivo genérico + el aviso "Sin guía específica para este juego" —
      el panel abre igual.
      **Bug real (2026-09-29):** "CÓMO SALIR" salía en blanco con Pacman.
      `_teclaSalida` era una `readonly property string` con un bloque de
      cálculo — se reescribió como función (`_teclaSalidaCalculada()`) con
      `try/catch` y un texto de resguardo más explícito. La causa exacta no
      quedó confirmada por log (coincidió con el bug de contexto viejo de
      abajo, y dejó de reproducirse después de las dos correcciones juntas).
- [x] DOS: `_palancaDeshabilitada` (de `Correspondencia.joysticktype`) y
      mención de teclado/mouse cuando `guiaPerifericos` los declara.
- [x] Periférico no disponible: `_perifericosFaltantes` cruza
      `guia.perifericos` contra `Gabinete.perifericoInstalado()` y lo
      muestra como requisito en rojo — el diagrama nunca dibuja un control
      de movimiento para esos casos (los patrones `TRACKBALL/DIAL/PADDLE/
      LIGHTGUN` se excluyen explícitamente de la grilla de botones).

## 4 · Cerrar y volver (foco + ADR-0038)

- [x] Cerrar la guía (`Esc`/`✕`) deja `root.foco` sin tocar — vuelve a
      quedar en el índice de "Cómo se juega" porque `DetailScreen.foco` no
      se modifica al abrir/cerrar un overlay hijo.
- [x] `volverAGuiaAlCerrar` (theme.qml): un solo booleano compartido entre
      Hacks (`cerrarTrucos()`) y Manual (`cerrarVisor()`), tal como preveía
      el riesgo del `plan.md`.
- [x] `lanzar(game)` escribe `api.memory["como-se-juega-contexto"]`
      (colección, set, `detalleAbierto`, `guiaAbierta`, `escritoEn`) justo
      antes de `game.launch()`; `Component.onCompleted` la lee una vez, la
      pisa con `set(clave, null)` y restaura `catalogo.coleccion` +
      `root.juegoDetalle` + `root.pantalla` + `guia.active` buscando el
      juego con `Paths.setDe` sobre `api.allGames`. Una ventana de 30
      minutos (`escritoEn`) descarta una clave vieja sin restaurar nada.
      **Hallazgo real (2026-09-29, `docs/plataforma-pegasus.md`):**
      `api.memory.unset()` no sobrevivía a un cierre de Pegasus —la clave
      volvía con su valor viejo en la siguiente apertura, sin importar qué
      hiciera el jugador en el medio (cerrar la guía, ir a Home, con o sin
      jugar)—, así que se dejó de usar `unset()` para esto y se reemplazó
      por `set(clave, null)`, que sí se sostuvo. También se probó (sin
      poder confirmarlo) un `Connections` a `Qt.application.aboutToQuit`
      para borrar la clave al cerrar Pegasus del todo; el resultado fue
      igual con o sin ese handler, así que la ventana de 30 minutos sigue
      siendo la única red de seguridad real.
- [x] El selector de plataforma (026) salta solo: `root.pantalla` es la
      misma propiedad reactiva que ya decide qué pantalla mostrar, así que
      ponerla en `"detail"` en `Component.onCompleted` alcanza — no hizo
      falta tocar `PlatformSelectScreen.qml`.
      **Limitación conocida, no resuelta:** `selector.indice` (qué
      plataforma queda resaltada si el jugador vuelve al selector después)
      no se sincroniza con la colección restaurada. No rompe nada, solo
      puede mostrar una plataforma distinta marcada la primera vez que se
      abre el selector tras volver de jugar.
- [x] **Confirmado en el gabinete real, 2026-09-29:** JUGAR desde la guía de
      Pacman, salir con Esc (confirmado también que Esc es la tecla real de
      MAME — Ctrl+F9 es de DOSBox, no aplica a arcade), y al volver la guía
      de Pacman reapareció abierta. Repetido además el caso "cerrar sin
      jugar" (salir de la guía, ir a Home, cerrar Pegasus) para confirmar
      que YA NO queda una clave vieja secuestrando la próxima apertura.

## 5 · Robustez

- [x] `guia` roto o ausente no rompe nada: `GameData` ya degrada TODO
      `data.json` si el JSON no parsea (criterio ya aceptado en ADR-0036,
      "coste asumido" — no es nuevo de esta feature), y `hayGuia: false`
      cuando `guia` no es un objeto.
- [x] Reimportar no toca el perfil ni el artefacto: ninguno de los dos vive
      dentro de `media/<set>/`, así que `attract import`
      (`instalar.py`, ya cubierto por sus propios tests) no tiene ninguna
      ruta que pueda escribirlos ni borrarlos.

## Verificación de código (hecha, sin Pegasus)

- `qmllint` (verificador de sintaxis) sin errores en los 9 archivos nuevos/
  modificados y en el resto del theme (`find themes/attract -name "*.qml" |
  xargs qmllint`, limpio).
- `node --test` de los 5 `.cjs` existentes + el nuevo: **todos verdes**.
- `pytest`: 338 passed, 10 skipped (sin cambios de este lado, es la 027).
- Theme reinstalado en `%LOCALAPPDATA%\pegasus-frontend\themes\attract`
  (equivalente a `make theme`).

## Cierre

- [ ] **Parcial: verificación visual en Pegasus real (2026-09-29).**
      `qmllint` es solo verificador de sintaxis (no resuelve tipos ni
      imports) — no reemplazaba abrir Pegasus, y ya se abrió: la fila de
      tarjetas y ADR-0038 quedaron confirmados (ver el checklist mínimo
      abajo). Falta el resto del checklist con `fixtures/` (guía completa
      en `dino`, ausente en `mok`) y el recorrido de foco completo.
- [ ] Validar cada criterio de `spec.md` contra Pegasus real — hecho para
      el de la fila de tarjetas y el de restaurar contexto (ADR-0038),
      falta el resto.
- [ ] Comparar contra el bosquejo de referencia solo para orden/ubicación
      (decisión 7).
- [x] Roadmap: `spec/constitution/roadmap.md` actualizado (2026-09-29) con
      el detalle de qué se verificó y qué falta — no pasa a "Hecho" hasta
      que el checklist mínimo de abajo cierre entero.
- [ ] `CLAUDE.md`/`AGENTS.md`: mapa del repo y conteo de tests, con permiso
      del autor.

### Checklist mínimo para la verificación en Pegasus

- [x] **La fila de 4 tarjetas entra sin pisar la columna derecha.** No entraba:
      confirmado en Pegasus real (2026-09-29, detalle de Pacman) que 4
      tarjetas de 200px (842px de fila) pisaban la columna de FORMATO/reseña
      — el presupuesto real del hueco es ~634px (`izquierda.right+48` hasta
      `derecha.left-32`, y `ExtrasList` no tiene anchor a la derecha que lo
      frene). Tarjetas a 145px + spacing 10 (fila de 610px): icono 38px
      (antes 50), márgenes 14/10/10 (antes 18/14/16), etiqueta con `width`
      fijo + `elide: Text.ElideRight` de resguardo. La tarjeta de la guía
      pasa a decir "Guía" en vez de "Cómo se juega" (no entra a este ancho
      sin elidir) — el overlay conserva el título completo adentro.

      **Ronda de ajuste de alto, confirmada en Pegasus real (2026-09-29):**
      66px → 56px → 28px (mitad, probado y descartado por poco margen con
      el ícono) → 40px → **45px (confirmado)** — elegido comparándolo contra
      el botón "MARCAR" de la columna derecha (`ui/Boton.qml`,
      `implicitHeight: 40` fijo), así que las tarjetas quedan un toque más
      altas que ese botón, no exactas. Medidas finales: 145×45px, ícono
      20×20, fuente del glifo 11px, chevron 13px, márgenes 10/8/8.
- [x] "Cómo se juega" abre con Enter/click aunque el juego no tenga `guia`.
      **Confirmado (2026-09-29):** Pacman, de `library/` real, no tiene
      bloque `guia` y la tarjeta abrió igual con la ayuda general.
- [ ] Con `dino` (fixture): objetivo, 3 acciones, 3 primeros pasos, 3 reglas,
      multijugador cooperativo/3 jugadores se ven completos.
- [ ] Con `library/arcade/media/pacman` (0 botones reales): el diagrama no
      dibuja ninguna fila de botones y no queda vacío ni roto.
- [ ] Con `library/arcade/media/simpsons` (tiene `guia`... **no todavía**:
      falta que COINDOOR la exporte o escribirla a mano en `library/` — ver
      nota abajo).
- [ ] Recorrido de foco completo JUGAR→…→Favoritos→JUGAR sin saltos.
- [ ] Abrir Hacks desde la guía, cerrar, confirmar que vuelve a la guía (no
      al detalle desnudo).

**Nota importante para el autor:** ninguno de los 6 juegos reales de
`library/` tiene todavía un bloque `guia` en su `data.json` — eso lo produce
COINDOOR (pedido en `027/pedido-coindoor.md`, sin implementar del otro
lado todavía). Hasta que eso exista, la verificación con juegos reales solo
puede probar el camino "sin guía propia" (ayuda general). El camino "con
guía completa" se prueba hoy solo con el fixture `dino`.
