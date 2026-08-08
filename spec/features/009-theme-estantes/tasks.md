# 009 · Librería con estantes — Tareas

_Checklist accionable derivada del `plan.md`._

## 0 · El portón: medir antes de escribir

- [x] `themes/experimentos/teclas-xy.qml` — dumpea, por cada evento, qué
      predicados de `api.keys` prenden y qué trae `event.text`.
- [x] `themes/experimentos/estantes-perf.qml` — `ListView` anidados con 1200
      entradas: mide `toVarArray()`, el armado de claves, los cuatro
      ordenamientos, y el pico de delegates vivos.
- [x] `themes/experimentos/memoria.qml` — dos corridas con ⌘Q en el medio.
      Es de la feature `010`, se mide ahora para no reabrir Pegasus dos
      veces.
- [x] **`teclas-xy` corrido contra Pegasus real (2026-08-05).** Los ocho
      predicados existen y disparan, ninguno se superpone: `I`→`isDetails`,
      `F`→`isFilters`, `Enter`→`isAccept`, `Esc`→`isCancel`. **El portón
      está abierto: la 009 va como está planificada.**
- [x] Hallazgos anotados en `docs/plataforma-pegasus.md` §2 (`api.keys`) y
      §3 (las flechas con `KeypadModifier` en macOS; una `property` no puede
      empezar con mayúscula — el theme entero no carga).
- [x] **`estantes-perf` corrido (2026-08-05).** Virtualiza: pico de 47
      delegates con 4 estantes × 1200. El foco anidado se comporta solo (el
      `ListView` horizontal deja pasar las verticales). Ordenar cuesta 16 ms
      en el peor caso — y la lectura de propiedades resultó ser 2 de esos 16,
      no el costo dominante que se predijo: los otros 14 son `localeCompare`.
      El array de claves se mantiene (es gratis) pero deja de ser una
      optimización crítica.
- [ ] **Divergencia adoptada:** cada estante recuerda su propia columna, en
      vez del `col` global del prototipo. Sale gratis en QML y es lo que hace
      cualquier librería tipo Netflix. Reemplaza el criterio de aceptación
      "conservando una columna válida" del `spec.md`.
- [x] **`memoria` corrido (2026-08-05).** `api.memory` persiste al ⌘Q y
      conserva el tipo: un `number` vuelve `number` y un `Array` vuelve
      `Array`. La fase `010` guarda el array crudo, sin `JSON.stringify`.
- [x] Los tres experimentos anotados en `docs/plataforma-pegasus.md` §2
      (`api.keys`, `api.memory`) y §3 (dos trampas nuevas de QML).

## 1 · Piezas compartidas

- [ ] `core/Teclas.qml` — `esA/esB/esX/esY` + `direccion`. Hecho cuando:
      `theme.qml` lo instancia y lo baja a las pantallas como `paths`.
- [ ] `core/Catalog.qml` — claves calculadas una vez, `estantes` recalculado
      solo por pestaña/criterio/dirección/filtro. Hecho cuando: cambiar de
      criterio no vuelve a leer propiedades de los 1200 juegos.
- [ ] Estantes según `.dc.html:495-511`: CONTINUAR JUGANDO (`playCount > 0`
      por `lastPlayed` desc, se omite si está vacío), MÁS JUGADOS (top 12
      con ranking), hasta 2 géneros con ≥3 juegos, CATÁLOGO. **Conteos
      reales** — el prototipo miente en los dos ("TOP 50" con 12 ítems, y la
      tabla `gtot` inventada).

## 2 · Pantalla

- [ ] `screens/Shelf.qml` — foco horizontal en la **2ª** ranura
      (`preferredHighlightBegin: 148+16`, `ApplyRange`; el rail viejo usaba
      la 3ª). Chip `⇅ {criterio}` solo en CATÁLOGO.
- [ ] `screens/BrowseScreen.qml` — barra (logo, 2 pestañas con conteo real,
      reloj cada 20s, `?`), hero del juego enfocado, `ListView` vertical de
      estantes. Borra `screens/LibraryScreen.qml`.
- [ ] Foco: ▲ desde el primer estante vuelve a la barra; ▼/`A` desde la
      barra baja a los estantes; `B` desde los estantes vuelve a la barra.
- [ ] `screens/GameCard.qml` — `ui/CoverImage.qml` de fondo, `AccentWash` de
      fallback, overlay oscuro inferior, chips de plataforma, año, ranking
      (solo MÁS JUGADOS) y barra de `playTime` (solo CONTINUAR JUGANDO).
- [ ] `ui/Leyenda.qml` + la lista por región. La de estantes incluye `B`,
      que el prototipo implementa y no anuncia.

## 3 · Control ORDEN/SELECCIÓN — `design_handoff_home/sort-select-spec.md`

Sumado el 2026-08-09; reemplaza esta sección entera (ver plan.md §8, el
"Decisiones" tachado explica qué cambió). Antes: un panel único abierto por
`X` con criterio+dirección+grilla juntos. Ahora: tres botones reales y
siempre visibles en la barra, navegables con foco direccional + `A`, y un
popover que es solo la grilla.

- [x] `core/Catalog.qml` — `modo` (Orden/Selección), `alternarModo()` con las
      reglas de reseteo del §Botón 1, `criteriosDisponibles` acotado por
      modo, `ciclarCriterio()` (Botón 2 / atajo `X`), `elegirValor()` con la
      señal `filtroAplicado()` (§Reseteo de navegación).
- [x] El estante CATÁLOGO usa `poolCatalogo` aparte del `pool` de los otros
      tres — el filtro de Selección es puntual de CATÁLOGO, no reduce
      CONTINUAR JUGANDO/MÁS JUGADOS/géneros (§Efecto sobre el catálogo).
      Los tres casos (Orden / Selección con filtro / Selección sin filtro)
      colapsan a una sola fórmula porque `poolCatalogo` ya vale `pool` sin
      filtrar en los dos casos que no filtran.
- [x] `screens/BrowseScreen.qml` — Botón 1 (MODO, toggle real), Botón 2
      (CRITERIO, cicla con click o `X`), Botón 3 contextual (dirección ▲▼ en
      Orden+Letra/Año, botón de VALOR en Selección, invisible en
      Orden+Nota/Jugados), chip "✕ LETRA C"/"✕ AÑO 1992". Foco: un solo
      índice plano sobre pestañas + estos controles (no dos regiones), `A`
      sobre una pestaña sigue bajando a los estantes (comportamiento previo
      de la región "tabs", no lo pisa el spec nuevo).
- [x] `overlays/SortPanel.qml` — achicado a **solo** la grilla de 26 letras o
      de años (1978 → el más nuevo del catálogo). Se abre desde el Botón 3 en
      modo Selección, no desde `X`. `A` elige, `B`/`X` cierra sin elegir.
- [x] El chip "✕ LETRA C" en la barra limpia el filtro (sin disparar el
      reseteo de navegación — eso es solo al ELEGIR un valor nuevo), y el
      estante dice "CATÁLOGO · LETRA C".
- [x] Al elegir un valor en el popover, el foco salta al estante CATÁLOGO,
      columna 0 (§Reseteo de navegación), vía `Qt.callLater` por si el
      delegate nuevo no existe todavía en el mismo tick.
- [x] **Bug real, reportado 2026-08-09**: `ciclarCriterio()` (Botón 2 / `X`)
      cambiaba el criterio pero nunca revisaba si el `filtro` activo seguía
      siendo compatible — ciclar de LETRA a AÑO con un filtro de letra
      puesto dejaba la grilla, el botón de valor y el sufijo del estante
      contando historias distintas. Corregido en `core/Catalog.qml`: mismo
      principio que ya aplicaba `alternarModo()`, ahora también en el ciclo.
- [x] **UX real, reportado 2026-08-09**: cambiar criterio/dirección/modo
      solo se veía si el usuario ya estaba parado en el estante CATÁLOGO —
      el dato cambiaba bien (correcto según §Efecto sobre el catálogo), pero
      pasaba desapercibido desde cualquier otro estante. Se agregó una
      vista previa que desplaza `estantes.currentIndex` a CATÁLOGO en cada
      cambio, SIN robarle el foco a la barra (el usuario sigue pudiendo
      tocar otros controles sin perder su lugar) — distinto del salto de
      foco completo que sí pide el spec al elegir un valor.
- [ ] Ordenar por NOTA con `rating` en `0.0`: los sin dato van al final y se
      ve que no hay dato, no un orden aparentemente roto.

### 3.1 · Rediseño visual — `design_handoff_home/year-letter-picker-spec.md`

Sumado el 2026-08-09. Complementa (no reemplaza) §3: la lógica de
filtrado/orden es la misma, esto es solo cómo se ve el Botón 3 y su
popover.

- [x] MODO se resalta en el color de acento cuando el modo activo es
      SELECCIÓN — CRITERIO se queda neutro siempre (el spec es explícito en
      que no es simétrico). **Revertido el tamaño/tipografía literal del
      spec** (pill 40px mono con tracking ancho): clasheaba contra el resto
      de la barra (BUSCAR, "?", pestañas — radio 8/30px/Chakra Petch en todo
      el theme). El resaltado de MODO reusa `variant:"accent"` de
      `Boton.qml`, el mismo mecanismo que ya prueba la pestaña activa —
      consistencia con el theme entero gana por sobre el pixel literal de un
      componente nuevo.
- [x] El Botón 3 en modo Selección pasa a ser un **toggle "−/+"**, borde de
      acento SIEMPRE visible (a diferencia del resto de los botones de la
      barra, que solo lo muestran al enfocarse) — reemplaza al botón que
      mostraba el valor elegido como su propio texto. `−` con el popover
      abierto, `+` cerrado, 30×30/radio 8 como el resto de la fila.
      `BrowseScreen.popoverOrdenAbierto` sincronizado desde `theme.qml` en
      los tres caminos de cierre (B/X adentro, click afuera, elegir un
      valor) más el propio botón.
- [x] `overlays/SortPanel.qml` — grilla a **7 columnas fijas siempre**
      (antes año usaba menos columnas con celdas más anchas), celda
      44×40 radio 11, popover con borde completo en el color de acento,
      alto limitado a 5 filas visibles con scroll interno + scrollbar
      propia (`Flickable.visibleArea`, sin `QtQuick.Controls` — no hay
      experimento que confirme ese módulo en este binario).
- [ ] **Sin medir todavía**: `DropShadow` del popover es una instancia única
      (existe solo mientras el popover está abierto), no un costo por
      delegate — pero no se verificó contra Pegasus real.
- [ ] ponytail sin resolver: el glow sutil de la celda elegida
      (`§Estado seleccionado`) no se implementó — el spec mismo aclara que
      no se ve en ninguna de las dos capturas de referencia.
- [x] **Bug real, reportado y corregido 2026-08-09 (dos rondas)**: primero
      `theme.qml:182` tenía `SortPanel { catalogo: catalogo }` — dentro de
      `Loader.sourceComponent` ese texto se autorreferencia en vez de leer el
      `id` de afuera (`Binding loop detected`, ver `docs/plataforma-pegasus.md`
      §3), así que la grilla se veía vacía. Arreglado con un alias
      (`catalogoInstancia`/`teclasInstancia`). Después, con la grilla ya
      poblada, el popover tapaba la Home ENTERA en vez de flotar sobre
      ella: `libreria.visible` tenía `&& !orden.active`, igual que los
      modales de verdad (ayuda/trucos/visor) — pero este es un popover sin
      scrim (spec explícito), Home tiene que seguir dibujada detrás.
      Separado: `visible` ya no depende de `orden.active`, `enabled`/`focus`
      sí (Home se ve pero no reacciona al teclado mientras el popover está
      abierto).

## 4 · Verificación contra Pegasus real

| Caso | Qué tiene que pasar |
|---|---|
| Estantes | Los cuatro tipos aparecen con conteos reales; CONTINUAR JUGANDO se omite si nadie jugó |
| Foco vertical | ▲▼ cambia de estante y la columna queda dentro de rango en el estante nuevo |
| Foco horizontal | La tarjeta enfocada queda en la 2ª ranura, salvo en los extremos del estante |
| Panel `X` | Se abre, se recorre entero con flechas, `A` aplica, `B` cancela sin dejar filtro |
| Filtro | "CATÁLOGO · LETRA C" con el conteo real; el chip ✕ lo limpia |
| Degradación | Juego sin `data.json`, sin carátula y sin año se dibuja igual (§2.3) |
| 1200 juegos | Recorrer el CATÁLOGO de punta a punta no pasa de ~20 tarjetas vivas ni tironea |
| Leyenda | Fija (decisión de producto 2026-08-08, diverge del prototipo): siempre "◄►▲▼ Navegar · A Detalle · X Orden · Y Buscar" |
| Lo que ya andaba | Detalle, visor, trucos y ayuda siguen abriéndose y devolviendo el foco |

## 5 · Cierre

- [ ] `make test` y `make doctor` en verde.
- [ ] Anotar en `docs/plataforma-pegasus.md` lo que salga de §0 (los
      predicados de `api.keys` y los números de perf son hechos de
      plataforma, no decisiones).
- [ ] Mover `009` a "Hecho" en `../../constitution/roadmap.md`.
