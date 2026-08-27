# Roadmap

_Orden y estado de las features. Cada entrada apunta a su carpeta en `../features/`._

## Hecho ✅

1. **Módulo 0 · `attract doctor`** — validador preflight (encoding, CRLF,
   nombres ilegales en Windows, NFC en nombre y en contenido, basura de
   macOS, assets referenciados que no existen). `src/attract/doctor.py`,
   cubierto por los 19 tests de `tests/test_doctor.py` (9 originales + 10
   de validación de JSON/`mags[].ref`/contrato de `magazine.json`,
   agregados junto con los puntos 8 y 10 abajo).
   _(Implementado antes de adoptar spec/features/ — no tiene carpeta propia.)_
2. **LAB 0.3 completo:** `docs/CONVENCION.md` (las 4 secciones, sin
   placeholders) y **ADR-0002, 0003, 0004** — las tres `accepted`. El
   terreno de diseño para juegos individuales (estructura, campos,
   procedencia, validación, identidad en merged, artefacto vs. fuente,
   cross-platform) está firme.
3. **LAB 0.4:** `docs/baseline.md` medido y consistente.
4. **ADR-0006 a 0009 — las 9 ADR aceptadas, 9/9.** Modelo de datos de
   revistas, frontera del sistema, versión de Pegasus, páginas como
   imágenes. No quedan decisiones de arquitectura pendientes.
5. **Verificaciones 1 y 2 corridas contra Pegasus real:** la cadena de dos
   lecturas de JSON funciona (confirmado, ver ADR-0008) y la contraprueba de
   PDF falla como predecía ADR-0007 ("Theme loading failed"). Un
   `magazine.json` real subido durante la verificación no coincidía con el
   contrato inventado en ADR-0008 → **ADR-0010** lo supersede con el
   contrato ampliado (`type`, `confidence`, `key_id`, flags de review).
   **10 ADR en total, 9 vigentes.**

6. **Verificación técnica de ADR-0004 — confirmada 2026-07-28.** Pegasus
   real, fixture `TEST MULTIFILE` (dos `file:` bajo un mismo `game:`): al
   lanzar, muestra un selector para elegir cuál abrir. Las tres
   verificaciones "bien dummy" de esta sesión están cerradas.
7. **`spec/features/001-synopsis/` — implementada.** Primera feature real
   usando el flujo SDD completo (spec → plan → tasks → código).
   `src/attract/synopsis.py` es el primer módulo que escribe
   `metadata.pegasus.txt` (**ADR-0011**: fuente persistida por campo,
   merge quirúrgico de `summary:`, sin tocar el resto del bloque `game:`).
   11 tests nuevos en `tests/test_synopsis.py`, `attract doctor` sigue en
   OK después de escribir. `docs/CONVENCION.md` §1.4 documenta
   `_synopsis/<set>.json`.
8. **Decisiones abiertas de ADR-0010 — resueltas 2026-07-28.** Fixture de
   `micromania-16/magazine.json` actualizado al contrato completo
   (`key_id`, `type`/`confidence` por artículo, flags de `review`, con un
   segundo artículo `publicidad` que encarna por qué las páginas no son
   consecutivas). Regla de presentación para `name` sucio documentada
   (limpieza mínima: sacar extensión, `-`/`_` → espacio — sin código
   todavía porque el theme de producción no existe). `attract doctor` ahora
   valida que `data.json`/`magazine.json` sean JSON válido
   (`chk_json_valido`, ERROR) y que `mags[].ref` resuelva a una carpeta
   real (`chk_mags_ref`, AVISO — la degradación con `ref` colgado es
   aceptada a propósito, ver `fixtures/arcade/media/sf2ce/`).

9. **ADR-0004 — pendiente de badge por variante, resuelta 2026-07-28.** No
   se agrega nada por ahora: el selector de `file:` es UI nativa de
   Pegasus (ATTRACT no puede customizarlo) y no hay caso real que lo
   necesite. Si aparece, la vía es `x-variantes:` a nivel de `game:` (una
   lista compartida por la ficha, no un dato por archivo).
10. **`attract doctor` valida el contrato completo de `magazine.json` —
    2026-07-28.** `chk_magazine_contrato` (ADR-0010): campos obligatorios,
    tipos, `articles[].confidence` en rango 0.0-1.0, `type` con AVISO (no
    ERROR) si no es uno de los conocidos — el enum no es cerrado. 6 tests
    nuevos. **30 tests en total** (19 `doctor` + 11 `synopsis`).
11. **`spec/features/002-attract-skill/` — implementada.** M4 del
    bootcamp. `.claude/skills/attract/SKILL.md`: le dice a un agente
    cuándo correr `attract doctor` (algo cambió en `fixtures/`/`library/`)
    y `attract synopsis` (apareció `_synopsis/<set>.json`), más las reglas
    duras que podría romper sin saberlo (ADR-0002, `library/` fuera de
    git). Sin código nuevo — el entregable es el `SKILL.md`. Queda
    pendiente verificar que la `description` dispare sola en una sesión
    nueva (no se puede confirmar desde la misma sesión donde se escribió).
12. **`spec/features/003-attract-mcp/` — implementada.** M5 del bootcamp.
    `attract mcp` levanta un servidor MCP por stdio con dos tools
    (`attract_doctor`, `attract_synopsis`) que llaman directo a la lógica
    ya existente. **ADR-0012**: primera dependencia externa del proyecto
    (`mcp`, SDK oficial) — opcional y acotada, import perezoso solo dentro
    de `mcp_server.py`; `doctor`/`synopsis`/`cli` siguen funcionando sin
    el paquete instalado, confirmado con un test que lo bloquea vía
    `sys.modules`. 8 tests nuevos. **38 tests en total** (19 `doctor` + 11
    `synopsis` + 8 `mcp`).
13. **`spec/features/004-attract-ingest/` — implementada.** M7 del
    bootcamp, el último módulo planeado en `cli.py`. `attract ingest
    <rom.zip>` es el primer comando que **crea** un `game:` nuevo (no
    edita uno existente): identifica el set con `mame -listxml` (stdlib
    `xml.etree.ElementTree`, sin romper el límite duro), exige
    exactamente una máquina jugable — cero o más de una falla explícito,
    sin adivinar (el caso ">1" reabre la verificación pendiente de
    ADR-0004 si aparece de verdad). Crea `media/<set>/` vacía. 10 tests
    nuevos, todos contra un XML **sintético** (no hay `mame` en este
    sandbox) salvo uno que sí corre contra la ausencia real del binario.
    Con esto los cuatro módulos planeados originalmente en `cli.py` (M4,
    M5, M7 + `doctor`/`synopsis` de M0-M2) están implementados.
14. **`003-attract-mcp` — roundtrip de protocolo real, cerrado
    2026-07-29.** Se intentó instalar `mame` vía `apt` en este sandbox —
    no hay acceso root, no se pudo. En cambio sí se pudo cerrar algo real:
    un cliente MCP oficial (`mcp.client.stdio` + `ClientSession`) hablando
    el protocolo completo — `initialize` → `list_tools` → `call_tool` —
    contra `python -m attract.mcp_server` como subproceso de verdad, no
    contra las funciones internas mockeadas. Nuevo test
    `test_roundtrip_protocolo_real_via_stdio`. **49 tests en total.**
    Sigue sin ser Claude Desktop/Claude Code — ver `Siguiente` punto 2.
15. **`004-attract-ingest` — forma del XML confirmada contra `mame` real,
    2026-07-29.** El autor corrió `mame -listxml sf2ce` (mame vanilla
    0.288) en su Mac y pegó la salida completa en el chat — evidencia
    real, no una suposición. Confirmado: el `DOCTYPE` con subset interno
    no rompe `ET.fromstring`, `<description>`/`<year>`/`<manufacturer>`
    son los tags correctos, `runnable="no"` filtra bien. **Hallazgo
    nuevo:** el título real trae basura de región pegada de verdad
    (`"... (World 920513)"`) — decidido dejarlo crudo, sin limpieza por
    regex (ver `spec.md` §Fuera de alcance, que ya lo anticipaba). Nuevo
    test `test_forma_real_confirmada_2026_07_29` con el XML real como
    evidencia permanente. **50 tests en total** (19 `doctor` + 11
    `synopsis` + 9 `mcp` + 11 `ingest`). Sigue abierto un punto menor: si
    Pegasus acepta `release: <solo año>` en pantalla — necesita el
    gabinete, no solo el parser.
16. **ADR-0011 — verificación de formato diferida a propósito,
    2026-07-29.** El autor va a generar `_synopsis/<set>.json` con un
    proceso externo propio; hasta que ese proceso exista, no hay nada
    real contra qué verificar. Se agregó `fixtures/arcade/_synopsis/
    sf2ce.json` como segundo ejemplo del contrato mínimo (`{"summary":
    "..."}`), junto al `mok.json` que ya existía — sin pretender que esto
    cierra la verificación pendiente de la ADR, que sigue abierta.
17. **`002-attract-skill` — disparo confirmado, 2026-07-29.** El autor
    corrió una sesión real de Claude Code (sin el contexto de esta
    conversación) y probó los cuatro casos de `tasks.md` §Validación en
    una sola corrida: el skill cargó solo, corrió `make doctor` y
    `attract synopsis mok` sin que se lo pidieran, reportó un ERROR real
    (byte inválido) sin intentar adivinarle un arreglo, y mencionó un
    AVISO sin bloquearse. Los 6/6 criterios de aceptación de `spec.md`
    quedan cumplidos. **Con esto no queda ninguna verificación pendiente
    en todo el proyecto que dependa de este agente — solo el punto menor
    de `release:`/Pegasus de abajo, que necesita el gabinete.**
18. **Terreno de diseño del theme, 2026-07-29 — ADR-0013 a 0016 y el
    contrato de `data.json` cerrado con código.** Leer el diseño de
    referencia (`design_handoff_game_detail/`) contra lo ya decidido
    destapó que el handoff daba por existentes campos que nunca se
    definieron (`accent`, `x-manual`) y pedía formas que chocaban con
    límites duros vigentes. Se cerró antes de escribir theme, no durante:
    **ADR-0013** (accent a mano por juego; derivar de la carátula quedó
    descartado por **imposible** — QML 5.15 no lee píxeles sin C++ y
    Pegasus es un binario congelado), **ADR-0014** (manual en
    `media/<set>/_manual/`, con la misma forma que `magazine.json.pages[]`
    para que el visor consuma un solo modelo), **ADR-0015** (contrato
    completo de `data.json`) y **ADR-0016** (canvas fijo 1280×720).
    **16 ADR en total, 15 vigentes.**

    Las verificaciones pendientes de ADR-0015 se cerraron en la misma
    sesión, no se dejaron declaradas: `chk_data_contrato` en `doctor.py`
    (accent hex, forma de `cheats`, `review.score`/`cats` en rango,
    categorías desconocidas como AVISO, páginas de manual que existan en
    el disco, y la forma de `mags[]` — que hasta ahora nadie validaba:
    `chk_mags_ref` miraba que el `ref` existiera, no que la entrada
    tuviera uno). Fixtures ampliados para encarnar el contrato repartido
    entre dos sets, cada uno con un trabajo distinto: `dino` suma accent y
    `cheats` con notación de lucha real (para que el tokenizer de la 007
    tenga contra qué probarse), `sf2ce` suma accent y un `_manual/` de 4
    páginas de 0 bytes conservando su `ref` colgado, y `mok` sigue sin
    `data.json`. **15 tests nuevos.**

    También quedaron escritos —y **sin correr**— los tres experimentos que
    bloquean el código del theme, y `spec/features/005-theme-base/` con
    spec, plan y tareas. Ver `Siguiente` punto 0.
19. **`004-attract-ingest` — cerrado contra `mame` real, 2026-07-29.** El
    autor instaló MAME en su Mac (vanilla 0.288) y con eso desapareció el
    último agujero honesto del módulo: hasta acá **todo** `ingest` estaba
    probado contra XML sintético o contra una salida pegada a mano en el
    chat, cosa que el `plan.md` de la feature declaraba explícitamente
    como hipótesis, no evidencia.

    Corrido de punta a punta contra el binario: `attract ingest 1943.zip`
    identifica el set, escribe el bloque (`game: 1943: The Battle of
    Midway (Euro)`, `developer: Capcom`, `release: 1987`, `x-set: 1943`),
    no toca los bloques que ya estaban, crea `media/1943/` y deja el
    archivo en 0 errores de `attract doctor`. Segundo caso real de basura
    de región pegada al título (`(Euro)`, como el `(World 920513)` de
    sf2ce) — confirma la decisión de dejarlo crudo. Y confirma algo que
    hace testeable a todo el módulo: `-listxml` lee la base interna de
    MAME, **no el archivo**, así que un `.zip` de 0 bytes alcanza.

    **3 tests de integración nuevos**, salteados con `skipif` cuando no
    hay `mame` en el `PATH` — mismo criterio que `test_mcp_server.py` con
    el SDK `mcp`: en una máquina pelada la suite sigue pasando
    (verificado: `11 passed, 3 skipped`).

    **Arreglado de paso:** `test_mame_no_instalado_falla_explicito`
    afirmaba que `mame` **no** estaba instalado —se escribió en un sandbox
    donde no lo estaba— y se invirtió en cuanto apareció el binario. Un
    test que depende de que una herramienta no exista se rompe solo al
    cambiar de máquina. Ahora **fuerza** la ausencia (`PATH` a un
    directorio vacío) en vez de asumirla, y sigue ejercitando el
    `FileNotFoundError` real de `subprocess`, sin mock. **68 tests en
    total** (34 `doctor` + 11 `synopsis` + 9 `mcp` + 14 `ingest`) — conteo
    de ese momento; hoy son 72 (`doctor` creció a 38), ver más abajo.

24. **`spec/features/016-import-coindoor/` — implementada.** `attract
    import <paquete.zip>` instala un paquete COINDOOR (ADR-0027) en la
    librería: valida el zip en un staging temporal reusando `doctor.py`
    sin modificarlo, escribe assets → `data.json` → bloque `game:` en ese
    orden (minimiza daño si se corta). Bloque nuevo lleva `x-procedencia:
    declarada` (ADR-0026). Preserva `mags[]` existente si el paquete no
    trae uno. `src/attract/instalar.py` (12 tests nuevos en
    `tests/test_instalar.py`). **184 tests en total.**

20. **`004-attract-ingest` cerrada del todo, y el esqueleto del theme
    verificado — 2026-07-29.** Dos cosas en una sola sesión de Pegasus real,
    sin escribir código nuevo para ninguna: el harness de
    `themes/attract-debug/` ya dumpeaba lo necesario y `game_dirs.txt`
    apuntaba a los dos metadata a la vez.

    **El último pendiente de 004 cae:** `releaseYear` devuelve `2002` tanto
    desde `release: 2002` (solo el año, `library/arcade`) como desde
    `release: 2002-03-06` (fecha completa, `fixtures/arcade`). Pegasus acepta
    el año pelado; `construir_bloque` no se toca. **La feature 004 no tiene
    ningún pendiente.**

    **El esqueleto del theme carga** y con eso queda confirmado que un theme
    de Pegasus soporta subcarpetas y un singleton vía `qmldir` — el árbol de
    `005/plan.md` va tal como está. De ahí salieron cuatro hallazgos más y
    **ADR-0017** (ver punto 19 y `005/tasks.md` §1).

    **Tres hallazgos del harness que le importan al theme:**
    1. **Los assets no siempre son `file://`.** Un juego que entra por el
       provider de Steam devuelve `boxFront` como URL remota
       (`https://shared.akamai.steamstatic.com/…/header.jpg?t=…`). Mata el
       plan B de `Paths.qml` (derivar el directorio de un asset) y, en un
       gabinete offline, esa imagen nunca carga. Refuerza ADR-0017.
    2. **Los dos fixtures que faltaban se complementan a propósito:**
       `EXPERIMENTO` no tiene `x-set` pero sí assets; `TEST MULTIFILE` tiene
       `x-set` pero ningún asset. Cada uno rompe una de las dos vías, así que
       ninguna alcanza sola — queda probado que hace falta `files[0].path`.
    3. **`releaseYear` vuelve `0` cuando no hay `release:`** — misma colisión
       que `rating`: no se distingue "sin dato" de "año cero". El theme tiene
       que tratar el `0` como "Sin Información" (`CONVENCION.md` §2.3). Y
       `rating: 0.8500000238418579` confirma que la precisión de float ya
       queda resuelta con `Math.round(rating * 100)`.

21. **`006-theme-documentos` — implementada y verificada, 2026-08-03.** Video
    de gameplay, carrusel de revistas y visor de documentos paginado. Con esto
    el theme hace todo lo que el diseño de referencia pide, salvo el overlay
    de trucos (feature 007).

    **Lo que le da sentido a todo el modelo de datos de revistas**, y que el
    prototipo no podía hacer porque no tenía el concepto de artículo: se entra
    **directo a la nota** del juego, pero el modelo son **todas** las páginas
    de la revista. La nota es la puerta de entrada, no un límite. Verificado:
    `dino` abre `micromania-16` en la página 3, con las páginas del artículo
    (3,4,5,7,8) marcadas en las miniaturas y la 6 —que es publicidad— no.

    **Un solo visor para revistas y manual.** No sabe cuál de los dos le
    tocó: recibe un modelo de `core/DocModel` y dibuja páginas. Es la decisión
    de [`ADR-0014`](../decisions/0014-manual-digitalizado.md) —darle a
    `manual.pages[]` la forma de `magazine.pages[]`— cobrándose sola: un solo
    zoom, un solo paneo, una sola tira de miniaturas.

    **Se cerró una ambigüedad de ADR-0010:** `startPage` es un índice
    **1-based** sobre `pages[]`. No es preferencia, se deduce del fixture, y
    pasó a ser chequeo de `attract doctor` — antes un artículo fuera de rango
    pasaba el validador y explotaba recién en el visor.

    **Regla de navegación nueva**, que el handoff pedía sin resolver:
    *izquierda/derecha mueve entre targets, arriba/abajo actúa dentro del
    target enfocado*. Es una generalización de lo que el prototipo ya hacía
    como caso especial para el carrusel; escrita como regla, el carrusel deja
    de ser una excepción y los controles del video se vuelven alcanzables sin
    agregar nada.

    **Los fixtures crecieron para poder verificar:** 4 revistas donde cada una
    cubre un camino distinto del contrato (sin `color`, `name` sucio, sin
    artículo sobre el juego), y 30 páginas generadas **con el número impreso**
    — sin número no se puede comprobar que hojear avance ni que `startPage`
    abra donde debe. Entre eso y las páginas del manual, ~70 KB.

    **Dos bugs, los dos encontrados por el autor mirando la pantalla:** el
    carrusel chocando con JUGAR —cuarta repetición de la misma trampa de
    layout, que por eso subió a `docs/plataforma-pegasus.md`— y la última
    revista inalcanzable, que no era un off-by-one sino dos estados metidos en
    una misma variable.

22. **Primera revista real completa, y el contrato v2 que destapó —
    2026-08-10.** Se cargó `micromania-34` (63 páginas, 20 artículos con
    `game`) y aparecieron tres cosas que los fixtures no podían revelar,
    porque los fixtures los escribimos nosotros con el contrato ya en la mano:

    - **Las páginas viven en `pages/`**, no sueltas en la carpeta de la
      revista. El theme armaba `<rev>/p002.jpg` y las 63 daban 404: el visor
      abría vacío sin un solo error en ningún lado.
    - **`startPage` es el número de página impresa, no un índice.** `pages[]`
      arranca en `p002.jpg` porque la página 1 es la tapa y vive en
      `cover.jpg`, así que la resta `startPage - 1` corría todo un lugar y al
      final de la revista daba un `startPage=64` "fuera de rango" sobre 63
      elementos — que era el validador teniendo razón bajo un contrato
      equivocado.
    - **Una revista cruza sistemas.** `micromania-34` cubre Golden Axe
      (arcade), Dr. Mario (NES) y Monkey Island (PC); con la carpeta adentro
      de `<sistema>/media/` había que copiar ~105 MB por sistema.

    [`ADR-0024`](../decisions/0024-contrato-magazine-json-v2.md) supersede a
    0010 con los tres cambios, adaptando **el consumidor** y no el archivo del
    generador (ADR-0009). `_magazines/` pasó a la raíz de la librería, el
    theme resuelve `../_magazines/` y prefija `pages/` en un solo lugar, y
    tanto el theme como `doctor` resuelven las páginas **buscando el archivo**
    `p{NNN}` en vez de contar posiciones — más robusto que la aritmética que
    reemplaza, porque no asume dónde arranca la revista ni que la numeración
    sea continua. Verificado antes de mover: las cuatro revistas de `fixtures/`
    arrancan en `p001` y dan **índices idénticos** con las dos reglas, así que
    nada de lo que ya funcionaba cambió.

    Chequeo nuevo, `chk_magazine_assets`: cada página y el `cover` tienen que
    existir en el disco. Es exactamente el bug de arriba, cuyo único síntoma
    era una pantalla en blanco.

23. **`attract mags` — el link revista→juego dejó de ser manual, 2026-08-10.**
    La otra punta del problema: la revista dice de qué juegos habla
    (`articles[].game`) y el juego dice en qué revistas aparece (`mags[{ref}]`),
    pero los dos lados usan identificadores distintos — slug editorial
    (`golden-axe`) contra set de MAME (`goldnaxe`). No es formato: normalizar da
    `goldenaxe`, al set le falta una `e` porque los nombres de MAME son
    abreviaturas históricas, no derivaciones del título.

    [`ADR-0025`](../decisions/0025-link-revista-juego-difuso.md): coincidencia
    difusa con `difflib` (stdlib, no toca el límite de dependencias) contra el
    set **y** el título, umbral 0.85. El número salió de medir, no de suponer:
    los 20 slugs de `micromania-34` contra los sets instalados dan 0.94 al
    match correcto y 0.43 al falso candidato más alto. Dry-run por defecto y
    merge idempotente sobre `mags[]` — `data.json` lo escribe una persona y
    esta herramienta es dueña de un solo campo.

## Siguiente 🔜

0. **El theme de producción — `005` / `006` / `007`.** Es el trabajo grande
   que sigue, y el primero de todo el proyecto que es _frontend_. Sale de
   leer el diseño de referencia (`design_handoff_game_detail/`, idéntico a
   `docs/mockup-referencia.html`) contra lo ya decidido. El handoff daba por
   existentes campos que nunca se definieron (`accent`, `x-manual`) y pedía
   formas que chocaban con límites duros vigentes; eso se cerró primero, en
   **ADR-0013 a 0016** (accent por juego, manual digitalizado, contrato
   completo de `data.json`, canvas fijo 1280×720) y **ADR-0017**, que salió
   de correr el esqueleto contra Pegasus real. **17 ADR, 16 vigentes.**

   - **`005-theme-base`** — en curso. Esqueleto hecho y **verificado contra
     Pegasus real**: subcarpetas y singleton vía `qmldir` funcionan, el árbol
     del plan va tal como está. Faltan `Paths`, `GameData`, los átomos
     restantes y las dos pantallas.
   - **`006-theme-documentos`** — implementada y verificada (ver punto 22).
   - **`007-theme-trucos`** — **especificada** (spec + plan + tasks). Tokenizer
     de inputs y overlay de trucos & combos. Es la última: con ella, todo lo
     que el handoff describe queda implementado.

     Tiene una particularidad que ordena su plan: **el tokenizer es la única
     pieza del theme que se puede verificar sin abrir Pegasus**, porque es una
     función pura de string a lista de tokens. Y es justo donde un error cuesta
     ver a ojo — que `PP` salga como dos botones en vez de uno no salta en una
     captura. Por eso la gramática vive en un archivo aparte, sin UI.

   **Ya no hay experimentos bloqueando:** los cuatro corrieron contra Pegasus
   real (ver punto 21 de "Hecho"). Lo que queda de la 005 son dos cosas que
   necesitan tu mano, ninguna bloqueante: bajar los `.ttf` a
   `themes/attract/fonts/` (hoy el theme corre con Helvetica y Courier, y va
   a verse bastante distinto) y la comparación final contra el prototipo
   abierto al lado, que se hace contra `library/preview/` porque tiene
   carátulas reales.

- **`008-theme-ayuda`** — código escrito contra un diseño de referencia de
  alta fidelidad (`design_handoff_help/`), sin verificar contra Pegasus real
  todavía. Overlay "Cómo cargar un juego nuevo" de dos columnas (nav de 8
  pasos + contenido), disparado con un ícono `?` junto al reloj/año en
  Librería y Detalle — mismo componente en las dos pantallas, mismo
  mecanismo `Loader` que `007-theme-trucos`. Ver
  `spec/features/008-theme-ayuda/tasks.md` §4 para lo que falta chequear
  con el gabinete o el Mac con Pegasus corriendo.

- **`009-theme-estantes` / `010-theme-buscar` / `011-theme-ediciones`** —
  especificada la primera, las otras dos solo nombradas. Salen de un handoff
  **nuevo** (`design_handoff_home/`) para la pantalla principal: librería con
  estantes tipo Netflix sobre 1200+ juegos, orden/filtro por
  letra/año/nota/jugados, búsqueda con teclado en pantalla, y selector de
  plataforma/edición en el detalle. No es un retoque visual: reemplaza la
  estructura de navegación entera de la librería.

  **El prototipo de este handoff tampoco se puede renderizar** — le falta
  `support.js`, igual que el anterior (`docs/plataforma-pegasus.md` §5). La
  fuente 1:1 es el `<script type="text/x-dc">` del `.dc.html`, que trae la
  máquina de estados completa.

  Tres decisiones tomadas al especificarla: las ediciones se agrupan por
  `sortBy` (necesita ADR propio, feature `011`), el `DetailScreen` existente
  se **extiende** en vez de reemplazarse por el del handoff —conserva video,
  revistas, trucos y reseña, que este handoff no tiene—, y el control de
  orden pasa a un panel navegable en `X`, porque en el prototipo es
  clickeable puro y en un gabinete sin mouse no existe.

  **Bloqueada por tres experimentos** (`teclas-xy`, `estantes-perf`,
  `memoria`, en `themes/experimentos/`), escritos y sin correr. El primero es
  el portón: si `api.keys.isDetails`/`isFilters` no disparan en este binario,
  no hay acceso al orden y la feature cambia de forma.

- **`017-hero-video-preview`** — **escrita e instalada; falta mirarla en
  Pegasus.** Preview de gameplay ambiental en el hero de Home: aparece a los
  650ms de quietud sobre un juego con video, se disuelve por debajo de las
  tarjetas y no recibe foco. Reusa lo que ya dejó la `006` (`MediaPlayer` en
  loop, `source: ""` para soltar el decoder, nada colgado de `onStopped`).

  **Ya no hay experimento bloqueando**: `themes/experimentos/video-opacitymask.qml`
  corrió el 2026-08-21 y `OpacityMask` **sí** enmascara un `VideoOutput` sin
  congelarlo, así que la disolución va por máscara real y el plan B queda
  descartado. De paso dejó un hecho que vale para todo el theme: **dos
  `VideoOutput` no pueden compartir un `MediaPlayer`**
  (`docs/plataforma-pegasus.md` §2).

  Lo que falta es la verificación visual
  (`spec/features/017-hero-video-preview/tasks.md` §Verificación). Para el
  criterio principal —recorrer diez juegos sin que el panel parpadee— hacía
  falta **más de un video en `library/`**. Ya no es un bloqueo: al 2026-08-27 hay
  **ocho**, uno por cada paquete COINDOOR instalado. Lo que falta es sentarse a
  mirarlo.

- **`018-theme-galeria`** — **especificada** (spec + plan + tasks), sin código.
  Galería de imágenes y videos por juego en el detalle: una tarjeta más en
  CONTENIDO EXTRA que abre un modal a pantalla completa con visor, flechas,
  contador y riel de miniaturas.

  **La galería se compone de dos fuentes** ([`ADR-0030`](../decisions/0030-contrato-gallery-data-json.md)):
  los assets nativos del juego (`video`, `screenshot`, `boxFront`, `poster`,
  `marquee`) más las piezas curadas que COINDOOR deja en `media/<set>/_gallery/`
  y declara en `gallery`. Ese contrato **ya existía y nadie lo había
  documentado**: `final-fight.coindoor.zip` lo emite, `attract import` ya lo
  instala (`instalar.py:155` copia el subárbol `media/` entero), `doctor` no lo
  valida y ADR-0027 no lo nombraba. La feature lo consume y lo valida; el
  productor no se toca.

  Sale de un prototipo HTML que **ya se corrió** (`docs/gallery-spec.md`), así
  que llega con cuatro modos de falla medidos, no supuestos: `source` evaluado
  vacío durante la construcción del componente, la leyenda mostrando los atajos
  del detalle adentro del modal, la leyenda pintando encima del riel, y los
  índices de foco de Hacks/Manual corridos al insertar la tarjeta en el ciclo.
  Cada uno tiene su mitigación en `spec/features/018-theme-galeria/plan.md`
  §Riesgos y su criterio de aceptación en el `spec.md`.

  Tres decisiones tomadas al especificarla: el botón de volver del detalle pasa a
  **"◄ BIBLIOTECA"** (chocaba con la tarjeta nueva, y el nombre equivocado era el
  del botón — esa pantalla se llama `libreria` en todo el código), y la tarjeta
  **está siempre** aunque el juego no tenga galería, porque CONVENCION #2.3 le
  gana al diseño de referencia, que la pedía condicional. Lo segundo además deja
  el ciclo de foco de largo fijo, que es lo que evita el cuarto bug de arriba.
  La tercera es de layout y sale de medir, no de gusto: **las tres tarjetas de
  CONTENIDO EXTRA bajan de 250 a 200px**, porque tres de 250 chocan con la
  columna derecha del detalle según el largo del veredicto de la reseña. El
  costo es que el subtítulo achica su presupuesto de texto, así que el de la
  galería cuenta piezas (`"13 piezas"`) y el de Hacks necesita un nivel más
  corto para no caer a `"Ver detalle"`.

1. **`003-attract-mcp`** — probar contra **Claude Desktop o Claude Code**
   de verdad (`mcp.json` real, tools visibles en la UI). El protocolo en
   sí ya está verificado de punta a punta (ver punto 14 de "Hecho"); lo
   que falta es específicamente la experiencia con un cliente de
   escritorio, que necesita tu máquina.

## Backlog / ideas 💡

- **Procedencia IA vs. manual** (§3 de `CONVENCION.md`) — decidido no
  distinguir, campo `x-procedencia` dejado por si se reconsidera. No hay
  disparador concreto todavía para revisitarlo.
- **ADR-0011, formato real de `_synopsis/<set>.json`** — diferido hasta
  que el proceso externo de scraping del autor exista de verdad (ver
  punto 16 de "Hecho"). No es bloqueante para nada del resto del proyecto.

> Cada feature nueva se crea como `features/NNN-nombre/` con `spec.md`,
> `plan.md` y `tasks.md` **antes** de tocar código.
