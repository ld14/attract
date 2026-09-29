# Cómo se juega — plan de trabajo

Guía breve por juego, accesible desde "Contenido extra" del detalle, para que
una persona sin experiencia sepa **qué hacer, qué apretar, cómo empezar y cómo
salir** sin que nadie le explique.

| | |
|---|---|
| Spec | [`027-como-se-juega`](../spec/features/027-como-se-juega/spec.md) (datos) + [`028-theme-como-se-juega`](../spec/features/028-theme-como-se-juega/spec.md) (theme) — aprobadas |
| ADR | [`0036`](../spec/decisions/0036-guia-tres-capas.md), [`0037`](../spec/decisions/0037-forma-bloque-guia-data-json.md), [`0038`](../spec/decisions/0038-restaurar-contexto-al-volver-de-jugar.md) — accepted |
| Handoff | [`decisiones/2026-09-24.md`](decisiones/2026-09-24.md) |
| Estado | Etapas A-E cerradas (2026-09-24/29). Feature partida en [027](../features/027-como-se-juega/spec.md) (datos) y [028](../features/028-theme-como-se-juega/spec.md) (theme), ambas con plan/tasks, código implementado y 338 tests en verde. F1 (verificación en Pegasus real) en curso: tarjetas y ADR-0038 confirmados con Pacman, falta el resto del checklist de `028/tasks.md` §Cierre. F2 (medición física) sigue bloqueada por el panel final, no instalado |

**Condición de éxito:** cada instrucción de la guía es útil y tiene fuente, y
cada botón físico que señala hace lo que la pantalla promete. Si no se puede
garantizar lo segundo, la guía muestra la entrada lógica ("botón 2") y no
señala ningún botón del panel.

Este documento sale de una propuesta de trabajo del 2026-09-24 y de las 20
dudas que se respondieron contra el estado real del repo y del gabinete. Es el
plan vigente: la propuesta original queda superada donde este documento la
contradice (ver §2.2).

---

## 1 · Principios que no se negocian

- **Enriquecimiento incremental.** Un juego sin guía sigue siendo válido y
  jugable; sumarla después no obliga a reinstalar nada.
- **Nada inventado.** Ni acciones de botones, ni combinaciones de salida, ni
  modo cooperativo deducido de la cantidad de jugadores, ni reglas. Cada grupo
  de datos lleva su fuente y su estado de revisión.
- **Tres capas separadas** ([ADR-0036](../spec/decisions/0036-guia-tres-capas.md)):
  1. qué hace el jugador en el juego (*saltar*);
  2. qué entrada lógica del emulador lo dispara (*botón 2 del jugador 1*);
  3. qué control físico del panel genera esa entrada (*fila superior, columna 2*).
- **Offline.** La guía lee datos ya preparados: sin web, sin IA y sin consultas
  remotas al abrirse.
- **Límites del proyecto intactos.** Pegasus como frontend, datos ricos fuera
  de `metadata.pegasus.txt`, stdlib-only, `library/` fuera de git, reglas de
  fixtures, sin tocar los docs plantilla del bootcamp.

---

## 2 · Decisiones del 2026-09-24

### 2.1 · Respuestas

| # | Tema | Decisión |
|---|---|---|
| 1 | Máquina | Esta PC (Windows, `D:\Juegos\attract`) **es el gabinete** |
| 2 | Panel | **Final:** 2 × (stick + 8 botones en arco), Start y Coin por jugador, 2 flippers laterales, teclado y mouse fijos. **Hoy:** 1 stick + 8 botones del jugador 1; el resto está comprado y sin instalar |
| 2f | Para qué panel se diseña | Para el **panel final**. La prueba botón por botón espera a que esté instalado; contenido e investigación avanzan igual |
| 3 | Mapeo en MAME | **Global** (`default.cfg` o `ctrlr/`), con `cfg/<sistema>.cfg` solo como excepción |
| 4 | Salida | La salida oficial es **la tecla del teclado de cada emulador**. No se configura combinación en el panel |
| 5 | Mouse | Fijo en el gabinete, como el teclado |
| 6 | Muestra del piloto | Juegos de Pegasus. Si falta una categoría, el autor importa candidatos con COINDOOR |
| 7 | Bosquejo | Solo referencia de ubicación y orden. Se respeta el diseño actual de las tarjetas |
| 8 | Layout | "Cómo se juega" primera, en **una fila de 4 tarjetas compactas** (sin subtítulo) |
| 8b | Conteos y "No Disponible" | En **una línea debajo de la fila**, con el detalle de la tarjeta enfocada |
| 9 | COINDOOR | Se le **piden** cambios con un documento preciso. ATTRACT lo lee, no lo modifica |
| 9b | ArcadeDB | Investigar el origen y las condiciones de `buttons_colors` antes de usarlo |
| 10 | Juego sin guía propia | La tarjeta **siempre abre**: ayuda general del gabinete y del emulador + "Sin guía específica para este juego" |
| 11 | Jugar desde la guía | Al volver del juego, **la guía aparece abierta** como estaba |
| 12 | Manual desde la guía | Solo si tiene **páginas**. El que es solo PDF queda en su tarjeta |
| 13 | Guía y trucos | **Independientes** en la v1 (sin vocabulario unificado) |
| 14 | Correcciones de la guía | **Siempre en COINDOOR.** Reimportar pisa, como hoy (ADR-0027) |
| 15 | Perfil físico | **Versionado en el repo** |
| 16 | Identidad | Técnica, se resuelve en la spec: el slug de la librería ubica los datos; el sistema de MAME (del `file:`) es la clave para `cfg/` y `-listxml`; la guía declara a qué sistemas aplica |
| 17 | `CONVENCION.md` | No se toca. El contrato vive en el ADR, la spec y la guía de carga |
| 18 | Material del piloto | Mixto: referencias versionadas en la feature, fragmentos literales en `library/` |
| 19 | Fuentes web | Permitidas, con URL, fecha de consulta y versión cubierta |
| 20 | Prueba con persona nueva | No hay quién. Queda como **limitación declarada** |

### 2.2 · Qué cambia respecto de la propuesta

- **DOS no es "incompatible con el gabinete".** Con teclado y mouse fijos, la
  guía nombra teclas y mouse como controles normales. Lo que sí tiene que decir
  es que la palanca no funciona en esos juegos (ver §3.1).
- **La salida es una tecla, no un botón del panel.** Simplifica la parte más
  riesgosa de la guía.
- **Sin choque con ADR-0027.** El contenido editorial viene de COINDOOR y se
  pisa al reimportar; la correspondencia física vive aparte y el import no la
  toca.
- **ADR-0021 pesa menos.** Asumía un gabinete solo con joystick, donde abrir un
  PDF afuera era un viaje de ida. Con teclado fijo se vuelve con Alt+F4. El ADR
  sigue vigente.
- **El layout se aparta del bosquejo:** fila compacta en vez de grilla 2×2.
  Motivo: la grilla le quitaba ~78 px a la sinopsis, y la sinopsis achica la
  letra cuando no entra (`fontSizeMode: Text.Fit`).
- **Dos reglas de la propuesta se relajan a propósito:** la muestra puede sumar
  juegos importados, y la prueba con una persona nueva no es criterio de
  aceptación.

---

## 3 · Inventario del gabinete

La propuesta pide separar lo **observado** de lo **declarado**.

### 3.1 · Observado (2026-09-24, en esta máquina)

**Entrada**

- Una sola placa de arcade: `VID_0079&PID_0006` "Generic USB Joystick"
  (DragonRise, tipo Zero Delay; hasta 12 botones).
- Teclado y mouse Dell (`413C:301D`) y un mouse Genius (`0458:0186`).
- ViGEmBus (Nefarius) instalado, sin mando virtual activo.
- Registrados pero desconectados: un receptor Xbox 360 inalámbrico y un mando
  de NVIDIA.

**Pantalla**

- 1920×1080, 16:9 exacto (MSI, ~60×33 cm). Con ADR-0019 el lienzo queda en
  1280×720 justo, sin espacio sobrante.

**MAME**

- Versión 0.288, en `library/_mame32`.
- `cfg/default.cfg` no tiene `<input>`: no hay remapeo global.
- Hay `.cfg` por juego que remapean a `JOYCODE_1_*` de forma **inconsistente**.
  Son remapeos a mano para el panel provisorio, que todavía no tiene Start ni
  Coin dedicados:
  - `simpsons`: P1_BUTTON1 → BUTTON5, P1_BUTTON2 → BUTTON1, START1 → BUTTON6,
    COIN1 → BUTTON7;
  - `finalb`: P1_BUTTON1 → BUTTON1, P1_BUTTON2 → BUTTON2.
- `sfa2` y `mk2`, los dos arcade que ve Pegasus, **no** tienen `.cfg`: usan los
  valores por defecto.
- `cfg/` tiene 13 `.cfg` por juego. Salvo `simpsons` y `finalb`, son de juegos
  que Pegasus no muestra.
- **MAME reescribe el `.cfg` del juego al cerrarlo**, aunque nadie remapee:
  `simpsons.cfg` guarda el contador de créditos (`<counters>`) y el mezclador
  (`<mixer>`, con el id del dispositivo de audio). `sfa2` y `mk2` van a tener
  su `.cfg` la primera vez que alguien los cierre.
- `mame.ini`: `joystickprovider auto` (de él depende cómo se numeran los
  `JOYCODE`), `ctrlr` vacío (los de `ctrlr/` son los de fábrica) y
  `confirm_quit 0` (Esc sale sin preguntar).
- **Confirmado contra `docs/MAME.pdf`** (el manual oficial que trae el propio
  binario, `library/_mame32/docs/MAME.pdf`) el 2026-09-27 (A3), sin tocar el
  gabinete:
  - `joystick_map` (línea 138 de `mame.ini`, *Core Input Options*) y
    `joystickprovider` (línea 238, *OSD Input Options*) son dos opciones
    **distintas** y las dos dicen `auto` — fácil de confundir.
    `joystickprovider` decide qué API lee el joystick (en Windows: `winhybrid`,
    `dinput`, `xinput`, `sdlgame`, `sdljoy`, `none`); el manual documenta
    `winhybrid` como el que "típicamente da la mejor experiencia en Windows"
    (§5.1, *Table 5*).
  - Sin `<input>` en `default.cfg`, **no hay un único "default" de MAME
    0.288**: cada driver trae su propia asignación por defecto (§12.5.5,
    *Player positions*). Las posiciones de jugador se renumeran recorriendo el
    árbol de dispositivos en profundidad, avanzando "última posición vista + 1"
    por dispositivo — relevante para juegos con subdispositivos (slots).
  - `<mapdevice>` (§7.7–7.8, *Stable Controller IDs*) **solo funciona dentro de
    un archivo de `-ctrlr`**; el manual dice explícitamente que se ignora en
    `default.cfg` y en los `cfg/<sistema>.cfg` por juego. Empareja
    dispositivos por (sub)cadena de su ID de sistema operativo (visible en el
    menú Input Devices → Copy Device ID, o en el log con `-verbose`:
    `Input: Adding joystick #N: ...`) y les asigna un `JOYCODE_N` estable.
    Encaja con la decisión 3 (mapeo global en `default.cfg` **o** `ctrlr/`):
    estabilizar las dos placas idénticas es trabajo de un `ctrlr/*.cfg`, no de
    `default.cfg`.
  - **Sigue sin resolverse sin hardware:** si Windows/MAME reportan un ID de
    dispositivo que de verdad distinga las dos placas `VID_0079&PID_0006`
    idénticas. Los ejemplos del manual solo muestran dispositivos con VID/PID
    distintos (dos pistolas) o XInput (que Windows ya nombra "XInput Player
    1/2" por sí solo); para DirectInput con VID/PID literalmente iguales no
    hay garantía documentada. Se mide en la Etapa F, con las dos placas
    conectadas y `-verbose`.

**DOSBox**

- 17 de los 19 `dosbox.conf` tienen `joysticktype = disabled`, porque así lo
  escribe el generador (`src/attract/dosbox.py:158,185`). FIFA y Monkey Island
  (confs de pack) tienen `auto`.
- **La config del juego no es la única.** El `launch:` pasa `--nolocalconf
  --conf` pero no `--noprimaryconf`, así que debajo queda una config primaria.
  Hay dos candidatas, y cuál carga se mide en A2:
  - `%LOCALAPPDATA%\DOSBox\dosbox-staging.conf` (`joysticktype = auto`,
    `mapperfile = mapper-sdl2-0.83.0.map`);
  - `emulators/dosbox-staging/dosbox-staging.conf`.
- FIFA y Monkey Island traen su propio `mapperfile` (`mapper-ECE.map`,
  `mapper-SVN.map`): la tecla de salida puede no ser la misma en todos los
  juegos.
- **✅ A2 confirmado por el autor (2026-09-27), lanzando un juego DOS normal
  (config generada, sin `mapperfile` propio):** la tecla de salida es
  **Ctrl+F9**. Es el atajo "de fábrica" de DOSBox Staging (`mapper-sdl2-*`),
  lo que sugiere que la config primaria (`%LOCALAPPDATA%\DOSBox\dosbox-staging.conf`)
  es la que efectivamente carga, o al menos que no la pisa nada antes.
  **Sigue sin confirmar** para FIFA y Monkey Island, que traen su propio
  `mapperfile` y podrían rebindear esa tecla — se prueba por separado si
  alguno de los dos entra a la muestra del piloto (A6).

**Pegasus y entorno**

- Solo está instalado el theme `attract` (`general.theme: themes/attract/`).
  `attract-debug` **no**.
- `game_dirs.txt` carga `library\msdos` y `library\arcade`. `fixtures/` **no**.
- **No hay `make`** en esta máquina, ni en Git Bash ni en PowerShell. El venv
  está en `.venv/Scripts/` (Python 3.14, pytest 9.1), no en `.venv/bin/`, que
  es lo que busca el Makefile.

**Librería**

- Pegasus muestra 2 juegos arcade (Street Fighter Alpha 2 y Mortal Kombat II,
  los dos de lucha) y 17 de MS-DOS.
- `library/_mame32/roms` tiene 16.490 zips que Pegasus no muestra.
- No hay ningún `_manual/` ni `_magazines/` en `library/`: manuales y revistas
  solo se pueden verificar contra `fixtures/`.

**ArcadeDB / `buttons_colors`** — origen confirmado el 2026-09-27 (A4)

- Fuente: `adb.arcadeitalia.net/service_scraper.php`. El propio cliente de
  COINDOOR (`backend/lib/providers/arcadedb/cliente.py:26-33`) trae la
  atribución exigida por los términos del servicio: "Datos de Arcade Database
  (motoschifo) — adb.arcadeitalia.net · Historia (C) arcade-history.com". No
  hay una página de términos separada citada en el código más allá de esa
  atribución en pantalla.
- Formato real: `P1_BUTTON1:Red:Attack;P1_COIN:White:;...` — control lógico,
  color físico del botón **tal como lo pintó el fabricante del gabinete
  original de ese juego**, y nombre de la acción. El color es un dato de ESE
  gabinete, no del propio: no sirve para pintar el panel de acá sin decirlo
  así.
- Condición de uso ya aplicada por el propio parser: descarta controles sin
  acción (`P1_COIN:White:`), que es la forma en que ArcadeDB separa "esto es
  el panel físico" de "esto tiene sentido para el jugador" — hoy ya nunca
  afirma un botón físico.

**COINDOOR** (`D:\Juegos\COINDOOR`) — confirmado leyendo código el 2026-09-27
(A5, solo lectura: `CLAUDE.md`/`AGENTS.md`, `backend/store/juegos.py`,
`backend/services/arcadedb.py`, `backend/services/export.py`,
`backend/store/exports.py`, `backend/bundle/seleccion.py`,
`backend/api/schemas.py`)

- Ya trae de ArcadeDB `buttons_colors` (`P1_BUTTON1:Red:Attack`), cantidad de
  botones y tipo de control, con procedencia por campo (`FieldProvenance`).
- Nada de eso figura en el contrato del paquete (ADR-0027).
- El dato vive en `StoredGame.cabinet` (`backend/api/schemas.py:125-130,166`):
  `resolution`, `orientation`, `controls`, `buttons` (cantidad) y
  `button_list: [{control, color, action}]` — exactamente capas 1 (`action`) y
  2 (`control`, el token lógico de MAME tipo `P1_BUTTON1`). Nunca un botón
  físico.
- Lo llena `ArcadeDbPrecargaService._escribir_cabinet`
  (`backend/services/arcadedb.py:438-465`), y solo si `cabinet.resolution` o
  `cabinet.controls` todavía están vacíos: no pisa una edición manual.
- **Pero `cabinet` no está en el contrato de export.**
  `backend/bundle/seleccion.py::_tabla()` enumera todo lo que el diálogo de
  export ofrece (identidad, imágenes, videos, textos, review, cheats, accent,
  accent2, manual, galería, juego) y `cabinet` no está. Hoy se guarda en el
  `game.json` de COINDOOR y no sale de ahí: nunca llega al `data.json` de
  ATTRACT. El pedido a COINDOOR (§5) no parte de cero: es cablear algo que ya
  se junta pero se descarta, y sumarle lo que falta (primeros pasos, reglas,
  salida, multijugador, periféricos).
- **Choque con `ADR-0002` de COINDOOR**
  (`spec/decisions/0002-procedencia-interna.md`, `accepted`): "la procedencia
  de cada campo es interna y no viaja al export". El pedido de este documento
  (§5: "llevar la procedencia de cada grupo hasta el paquete") lo contradice
  directamente. Si se sostiene el pedido, hace falta un ADR nuevo en COINDOOR
  que supere al 0002 para este bloque — no alcanza con pedirlo en el texto de
  §5.

### 3.2 · Declarado por el autor

- **Panel final:** 2 jugadores; cada uno con stick y 8 botones en arco
  (plantilla Vewlix de slagcoin: dos filas de 4, la columna más cercana al stick
  más baja).
- **Botones de sistema:** Start P1, Start P2, Coin P1 y Coin P2 dedicados; dos
  botones grandes laterales tipo flipper. No hay botón dedicado para salir.
- **Hoy:** solo stick y 8 botones del jugador 1. La segunda placa, igual a la
  primera, y todos los botones de sistema están comprados y sin instalar.
- **Teclado y mouse** siempre presentes, conviviendo con el panel.
- **Salida oficial:** la tecla del teclado de cada emulador.

### 3.3 · Identificadores físicos

Cada botón se nombra por su **posición**, no por el número que manda la placa:
fila superior o inferior, columna 1 a 4 contando desde el stick. Los botones de
sistema tienen nombre propio (Start P1, Coin P1…).

El número de botón que reporta el dispositivo **no** se asume igual a la
posición, y **no** se asume que las dos placas idénticas conserven su orden
entre reinicios. Las dos cosas se miden en la Etapa F.

### 3.4 · Incertidumbres concretas después de A1–A6 (2026-09-27/28)

Quedan pendientes, cada una con un paso claro para cerrarla:

- ~~**A1**~~ **✅ confirmado (2026-09-28), en el gabinete real:** Pegasus
  **sí** recarga el theme entero al volver de un juego (recreó el QML: el
  contador de `Component.onCompleted` pasó de `undefined`, recién reseteado,
  a `1` después de un solo lanzamiento), y la clave escrita justo antes de
  `game.launch()` sobrevivió esa recarga. Cierra la decisión 11: la guía
  escribe en `api.memory` antes de lanzar y se reabre leyendo esa clave en
  `Component.onCompleted`. Detalle y metodología en el
  `#RESULTADO OBSERVADO` de `themes/experimentos/recarga-tras-juego.qml`.
- ~~**A2**~~ **✅ confirmado (2026-09-27): Ctrl+F9**, para un DOS con config
  generada. Sigue abierto solo para FIFA y Monkey Island (`mapperfile` propio).
- ~~**A6**~~ **✅ cerrado (2026-09-28):** Pacman (A), The Simpsons (C) y
  Shuffleshot (D) importados con COINDOOR y verificados contra `-listxml` —
  ver §4.A. **Pendiente nuevo, no de hardware:** corregir en COINDOOR las
  sinopsis erróneas de Pacman (le atribuye un botón que no existe) y
  Shuffleshot (describe un juego distinto) antes de usarlas en la Etapa B.
- **Orden estable de las dos placas idénticas** (§3.1 MAME): si Windows/MAME
  exponen un ID de dispositivo que las distinga. Se mide en la Etapa F con las
  dos placas conectadas y `-verbose`.
- **Choque `ADR-0002` de COINDOOR contra el §5 de este documento** ("llevar la
  procedencia... hasta el paquete"): sin resolver. Si se sostiene el pedido,
  hace falta un ADR nuevo en COINDOOR que lo supere, no alcanza con pedirlo en
  el texto.

---

## 4 · Plan por etapas

### 0 · Precondiciones

Se cumplen antes de la Etapa A, no de la D: A, C y G escriben en archivos que
hoy tienen cambios sin commitear.

- **El autor commitea o guarda aparte lo pendiente:**
  - la 025 y la 026 (ADRs 0032-0035, `dosbox.py`, el selector de plataforma);
  - sus cambios en `docs/plataforma-pegasus.md`, `spec/decisions/README.md`,
    `spec/constitution/roadmap.md`, `docs/guides/cargar-un-juego-nuevo.md`,
    `src/attract/` y el theme.

  **Sin `emulators/`**: son binarios sin trackear.
- **Se crea la rama `feat/027-como-se-juega`** desde ahí, con permiso del
  autor. Todo lo que sigue, desde A, va en esa rama.
- ~~**El autor corrige el `launch:` de arcade**~~ **✅ corregido (2026-09-27):**
  le faltaba la comilla de apertura antes de la ruta de `mame.exe`
  (`library/arcade/metadata.pegasus.txt:3`). Ningún comando de ATTRACT escribe
  esa línea, así que el arreglo queda firme hasta que se edite a mano de
  nuevo.
- **Comandos sin `make`** (ver §3.1), desde Git Bash:

| En vez de | Correr |
|---|---|
| `make test` | `PYTHONPATH=src .venv/Scripts/python.exe -m pytest tests/ -q` |
| `make doctor` / `make doctor-lib` | `PYTHONPATH=src .venv/Scripts/python.exe -m attract.doctor fixtures --target windows` (o `library`) |
| `make theme` | `rm -rf "$LOCALAPPDATA/pegasus-frontend/themes/attract"` y después `cp -R themes/attract "$LOCALAPPDATA/pegasus-frontend/themes/"` |
| `make theme-debug` | `cp -R themes/attract-debug "$LOCALAPPDATA/pegasus-frontend/themes/"` |

Los tests de lógica JS del theme se corren aparte: `node tests/<archivo>.cjs`.

### A · Descubrimiento

**Orden:** A2 antes que A1. Para salir de un juego DOS hay que saber la tecla,
y el arcade depende de que el `launch:` ya esté corregido.

**A1 · Experimento de una sola pregunta:**
`themes/experimentos/recarga-tras-juego.qml`, con el formato de `memoria.qml`.

- ¿Pegasus **recarga el theme** al volver de un juego? Si lo recarga, "guía
  abierta al volver" (decisión 11) se guarda en `api.memory`.
- Mide dos cosas:
  - un contador de cargas en `api.memory`, que sube en cada
    `Component.onCompleted`;
  - una clave escrita **justo antes** de `game.launch()` y leída al volver. Es
    el mecanismo exacto de la decisión 11.
- Cómo se corre (lo hace el autor):
  1. instalar `attract-debug` (hoy no está) y copiar el experimento sobre su
     `theme.qml`;
  2. elegir ATTRACT Debug desde el menú de Pegasus;
  3. lanzar un juego DOS y salir con la tecla que confirmó A2, o un arcade si
     el `launch:` ya está corregido;
  4. anotar el resultado, borrar las claves (`unset`) y volver al theme
     ATTRACT.

  **✅ Confirmado 2026-09-28** — ver §3.4. Pegasus recarga el theme al
  volver de un juego, y la clave escrita antes de `game.launch()` sobrevive.
  Metodología completa en el `#RESULTADO OBSERVADO` del propio archivo.

**Verificaciones sin cambiar nada:**

- **A2 · Salida de DOSBox Staging.** No alcanza con la documentación:
  - medir qué config primaria carga de verdad (§3.1);
  - revisar qué hace el `mapperfile` de cada juego, porque la salida puede
    cambiar según el juego.

  La confirma el autor lanzando un juego.

  **✅ Confirmado 2026-09-27: Ctrl+F9**, para un DOS con config generada — ver
  §3.1 DOSBox. FIFA y Monkey Island (mapperfile propio) quedan para cuando
  entren a la muestra (A6).
- **A3 · Qué manda cada botón por defecto en MAME 0.288**, con joystick y sin
  `.cfg`. Sale de la documentación o del código de MAME: `-listxml` solo dice
  qué entradas tiene un juego. Registrar además:
  - `joystickprovider auto`, del que depende la numeración de los `JOYCODE`;
  - qué reescribe MAME en el `.cfg` al cerrar un juego, porque eso define cómo
    se calcula la huella en D;
  - si `<mapdevice>` (IDs de control estables) sirve para fijar el orden de dos
    placas con el mismo `VID/PID`.

  **✅ Avanzada 2026-09-27** contra `docs/MAME.pdf` — ver §3.1 MAME. Lo único
  que sigue abierto (necesita las dos placas conectadas) va en §3.4.
- **A4 · `buttons_colors` de ArcadeDB:** origen y condiciones de uso, con URL
  y fecha.

  **✅ Avanzada 2026-09-27** — ver §3.1 "ArcadeDB / `buttons_colors`".
- **A5 · COINDOOR, solo lectura:**
  - primero su `CLAUDE.md` y su `AGENTS.md`;
  - después `backend/store/juegos.py`, `backend/services/arcadedb.py` y el
    exportador (`backend/services/export.py`, `backend/store/exports.py`).

  Sin grep recursivo desde la raíz: se cuelga en `games/` y `node_modules`.

  **✅ Avanzada 2026-09-27** — ver §3.1 "COINDOOR". Se leyó también
  `backend/bundle/seleccion.py` y `backend/api/schemas.py` para confirmar la
  forma exacta del dato y si viaja al export (no viaja). Hallazgo relevante
  para C: choque con `ADR-0002` de COINDOOR, anotado en §3.4.

**A6 · Muestra del piloto: 6 juegos**

| Categoría | Juego | De dónde |
|---|---|---|
| B · Lucha con 6 botones | Street Fighter Alpha 2 | Pegasus |
| E · DOS de teclado | Prehistorik | Pegasus |
| E · DOS de mouse | Uno con conf generada, p. ej. Monkey Island 2 u Oh No! More Lemmings | Pegasus |
| A · Arcade de pocos botones | ~~Candidato a proponer~~ **Pacman** | Importado con COINDOOR |
| C · Cooperativo | The Simpsons (ya tiene `.cfg`, evidencia de uso) | Importado con COINDOOR |
| D · Periférico o control especial | ~~Un juego de trackball o dial~~ **Shuffleshot** | Importado con COINDOOR |

Monkey Island no representa bien al juego de mouse. Su conf es de pack (§8),
con `joysticktype = auto` y `mapperfile` propio: justo lo que la guía mide. Si
entra a la muestra, entra como caso borde declarado.

**✅ A6 cerrado (2026-09-28).** Los tres importados con COINDOOR quedaron en
`library/arcade/`, y se verificaron contra `mame.exe -listxml` (sin
hardware, autoritativo):

- **Shuffleshot → D:** `<control type="trackball" player="1" buttons="2">` ×2
  jugadores. Trackball real, encaja con la categoría.
- **The Simpsons → C:** `<input players="4">`, `type="joy"` de 2 botones y 8
  direcciones ×4. Cooperativo confirmado, además del `.cfg` de uso previo.
- **Pacman → A:** ⚠️ **dato erróneo detectado.** El `summary` importado dice
  "el control se realiza con un joystick y un botón de acción", pero
  `-listxml pacman` muestra `<input players="2"><control type="joy".../>`
  **sin ningún botón** — el Pac-Man de gabinete original nunca tuvo botón.
  Además, el `summary` de **Shuffleshot** describe una nave espacial
  disparando en niveles con un tablero de fichas — un juego totalmente
  distinto al shuffleboard que dice el `genre` y que confirma `-listxml`.
  Ambas sinopsis parecen mal generadas o cruzadas con las de otro juego.
  **No se tocó `library/`** (decisión 14: la guía se corrige solo en
  COINDOOR, reimportar pisa) — conviene corregir o regenerar esas dos
  sinopsis en COINDOOR antes de apoyarse en ellas para la Etapa B, para no
  arrancar el piloto con datos ya errados.

**Salida:**

- §3 actualizado con lo observado;
- un hecho nuevo en `docs/plataforma-pegasus.md` (A1);
- la muestra confirmada;
- una lista de incertidumbres concretas.

### B · Piloto de datos

- Un expediente por juego con: título, plataforma, identificador exacto,
  variante, emulador y versión, fuentes, objetivo, controles originales,
  entradas técnicas, mapeo local, inicio, salida, multijugador, periféricos,
  desconocidos, conflictos y trabajo manual.
- **Matriz por campo:** extraído automáticamente / documentado / comprobado en
  el gabinete / pendiente / en conflicto, más el tiempo que llevó cada guía.
- **Dónde vive:** referencias (URL, fecha, página, sección) versionadas en
  `spec/features/027-como-se-juega/piloto/`. Los fragmentos literales, si hacen
  falta, van en `library/_piloto-como-se-juega/`, que no va a git.

**Salida:** 6 expedientes, la matriz y una conclusión: qué fuentes integrar,
qué se automatiza, qué tiene que aportar COINDOOR y qué hace ATTRACT.

**✅ Hecha (2026-09-28).** Los 6 expedientes, la matriz y la conclusión están
en `spec/features/027-como-se-juega/piloto/` (`sfa2.md`, `pacman.md`,
`the-simpsons.md`, `shufshot.md`, `prehistorik.md`,
`oh-no-more-lemmings.md`, `matriz.md`, `conclusion.md`). Resumen de una
línea: la cadena `-listxml` + `cabinet` de COINDOOR funciona bien para
arcade y ya detecta datos rotos con solo cruzarlos (así se encontraron los
dos conflictos de §4.A); el texto libre (`summary`) necesita revisión
editorial; DOS no tiene ninguna fuente automática de capa 1.

**⏸ Pausa:** el autor lee `piloto/conclusion.md` antes de pasar a C.

### C · Especificación

- Cerrar la spec 027 con lo que mostró el piloto.
- Escribir `plan.md` y `tasks.md`.
- **ADR-0036 a `accepted`:** cambia solo el `status`. Es un metadato del ciclo
  de vida, como el `superseded-by` que las reglas mandan completar. Si el
  piloto cambia el contenido, va un ADR nuevo que lo supersede.
- **Un ADR nuevo para la forma del bloque de guía**, como tuvieron `manual`
  (0023) y `gallery` (0030).
- Al aceptar un ADR, su conclusión sube a `spec/constitution/tech-stack.md`
  **en ese momento**, no en G (regla de `spec/decisions/README.md`).
- Agregar la entrada de 027 en el roadmap.
- Escribir el pedido preciso a COINDOOR (§5).
- **Decidir tres cuestiones abiertas:**
  1. **Partir o no la feature.**
     - Propuesta: 027 queda para el contrato, el perfil, el comando y
       `doctor`, todo verificable con pytest; 028, para el theme.
     - Precedente: el manual se partió en 012, 013 y 014.
  2. **Rutas del perfil y del artefacto.**
     - Perfil: dentro del theme. `make theme` lo instala en las dos máquinas y
       el theme lo lee sin conocer el repo. Lleva un campo `revision`, que el
       artefacto copia.
     - Artefacto: uno por colección, `library/<coleccion>/_controles.json`.
       Cada colección tiene un solo emulador, el theme llega con
       `Paths.dirColeccionDe`, y `reset-pegasus` lo borra junto con la
       colección, que es lo correcto porque es derivado.
  3. **Qué se restaura al volver de un juego.**
     - El theme arranca en el selector de plataforma y hoy no guarda nada en
       `api.memory`.
     - Restaurar "solo la guía" obliga a restaurar también la plataforma, el
       juego y el detalle.
     - JUGAR desde el detalle volvería al selector, así que hay que decidir si
       también se restaura.
     - Afecta al selector de la 026.

**Salida:** spec, plan y tareas implementables, sin ambigüedad sobre quién es
dueño de cada dato.

**✅ Etapa C cerrada (2026-09-28).** Las tres cuestiones, decididas por el
autor:

1. **Partir la feature:** sí. [`027-como-se-juega`](../features/027-como-se-juega/spec.md)
   quedó para el contrato, el perfil, el comando y `doctor`;
   [`028-theme-como-se-juega`](../features/028-theme-como-se-juega/spec.md),
   para el theme. Cada una con su `spec.md`/`plan.md`/`tasks.md`.
2. **Rutas:** confirmada la propuesta — perfil dentro del theme
   (`themes/attract/core/gabinete.json`), artefacto por colección
   (`library/<coleccion>/_controles.json`). Forma exacta de los dos en
   `027/plan.md` §Decisiones.
3. **Qué se restaura:** todo el contexto (plataforma, juego, detalle y
   guía), no solo la guía — [`ADR-0038`](../decisions/0038-restaurar-contexto-al-volver-de-jugar.md).

Además: [`ADR-0036`](../decisions/0036-guia-tres-capas.md) a `accepted`;
[`ADR-0037`](../decisions/0037-forma-bloque-guia-data-json.md) fija la forma
exacta del bloque `guia` (adopta el vocabulario que COINDOOR ya usa en
`cabinet.button_list`, confirmado en el piloto); roadmap actualizado; pedido
a COINDOOR escrito en
[`027/pedido-coindoor.md`](../features/027-como-se-juega/pedido-coindoor.md),
ya con la brecha exacta (`cabinet` no viaja al export) y el choque con su
`ADR-0002` explicitados, no solo pedidos a ciegas.

**⏸ Pausa:** ya no hace falta — las tres cuestiones están decididas. Sigue
la Etapa D (código), que no requiere hardware ni pausas del autor salvo para
revisar el resultado.

### D · Contratos y preparación

_El detalle accionable de esta etapa vive ahora en
[`027/plan.md`](../features/027-como-se-juega/plan.md) y
[`027/tasks.md`](../features/027-como-se-juega/tasks.md) — lo que sigue acá
es el contexto original, no la fuente de verdad de qué falta marcar `[x]`._

- **`doctor` valida el bloque de guía** dentro de `chk_data_contrato`, con el
  mismo patrón que `cheats` y `gallery`. También avisa por claves de primer
  nivel desconocidas. Hoy no lo hace: un bloque mal nombrado pasaría en verde,
  el mismo modo de falla que describe ADR-0020.
  - El aviso por claves desconocidas es **AVISO**, no error: el preflight de
    `attract import` solo corta con errores.
  - La clave de la guía se registra en el mismo cambio, para que `fixtures/`
    no se llene de avisos.
- **Archivo de perfil físico versionado.** Lo valida un pytest, no `doctor`:
  `doctor` recibe una librería y el perfil no está en ella.
- **Comando stdlib que genera la correspondencia local**, en dry-run por
  defecto como `mags`:
  - saca las rutas de MAME del `launch:` y de `mame.ini`, no de un
    `library/_mame32/` fijo: en el Mac, MAME vive en otro lado;
  - la tabla de valores por defecto de MAME 0.288 (A3) es un dato versionado,
    atado a esa versión;
  - solo mira los sistemas que están en la metadata, y en el dry-run marca cada
    `<input>` por juego como excepción;
  - un control queda **verificado** solo con la cadena completa y su posición
    medida en el perfil.
- **La huella** se calcula sobre las entradas normalizadas, no sobre los
  archivos (ver §3.1, MAME):
  - los `<port>`/`<newseq>` ordenados y el `ctrlr` efectivo;
  - las claves de `mame.ini` y de DOSBox que afectan la entrada;
  - la versión de MAME y la `revision` del perfil.

  Un `.cfg` ausente vale lo mismo que uno sin `<input>`.
- **`doctor` avisa si la correspondencia está vencida.** Es una función propia,
  que `revisar()` llama al encontrar el artefacto, igual que hace con
  `data.json`.
  - **No** va en `CHEQUEOS_UNIVERSALES`: esa lista es de compatibilidad entre
    plataformas, y esto es estado local de la máquina.
  - Se saltea si las fuentes no existen en esa máquina.
- **Fixtures:**
  - un bloque de guía sintético en `dino`; `mok` queda sin guía;
  - un artefacto escrito a mano, para ver el camino "verificado".

  Son entradas de test en texto: no son una excepción a la regla de los 0
  bytes.
- **Las guías reales no se escriben a mano en `library/`** (decisión 14). D y E
  se prueban con `fixtures/`. JUGAR desde la guía se prueba con un juego de
  `library/` sin guía, porque la tarjeta siempre abre.
- `attract import` no cambia de política: un paquete sin guía sigue siendo
  válido, y uno con guía la pisa.
- **Límites:**
  - no se escribe en la configuración de MAME ni de DOSBox, solo se lee;
  - sin dependencias nuevas;
  - el mapeo global de MAME (decisión 3) lo configura el autor al instalar el
    panel, fuera del repo.

**Salida:** datos que el theme puede leer y reportes claros.

**✅ Etapa D cerrada (2026-09-29).** Todo lo de arriba, implementado y
verificado con `pytest` (sin abrir Pegasus): `_chk_guia_bloque` en
`doctor.py`, `themes/attract/core/gabinete.json` como perfil físico,
`src/attract/controles.py` (comando `attract controles`, dry-run por
defecto) y `chk_correspondencia_vencida`. Verificado además contra la
librería real del autor, no solo contra `fixtures/`: ver el detalle en
[`027/tasks.md`](../features/027-como-se-juega/tasks.md) §Hallazgos
(el bug de `x-set:` equivocado en 3 juegos de COINDOOR, y el agregado de
`.conf` a `EXT_TEXTO`).

### E · Frontend

_El detalle accionable de esta etapa vive ahora en
[`028/plan.md`](../features/028-theme-como-se-juega/plan.md) y
[`028/tasks.md`](../features/028-theme-como-se-juega/tasks.md)._

- `ExtrasList`: fila compacta de 4 tarjetas y línea de detalle debajo.
- Overlay de la guía: título, diagrama, objetivo, primeros pasos, reglas,
  salida, Jugar, Volver, y accesos a Hacks y al Manual.
- Nuevo orden de foco: JUGAR → video → carrusel → Cómo se juega → Galería →
  Hacks → Manual → Favoritos.
- Al cerrar Hacks o Manual abiertos desde la guía se vuelve a la guía.
- Al volver de un juego se restaura lo que haya decidido C. Si A1 confirma que
  el theme se recarga, se escribe en `api.memory` justo antes de
  `game.launch()`.
- El diagrama se dibuja en QML desde el perfil, solo con `Rectangle`, `Text` y
  `Repeater`. `QtQuick.Shapes` sería un `import` nuevo, y un import que no
  resuelve tumba el theme entero. Sin assets nuevos ni excepciones a la regla
  de fixtures.
- `B` se acepta solo en la rama que lo usa (`docs/plataforma-pegasus.md`,
  `isCancel` reservada por Pegasus).

**⏸ Pausa:** para probar con `fixtures/`, el autor lo suma a `game_dirs.txt`
con Pegasus cerrado, y lo saca al terminar.

**Salida:** la guía usable en Pegasus.

**✅ Etapa E cerrada (2026-09-29).** Las piezas de arriba, escritas y
verificadas con `qmllint` (sintaxis) y `node --test`
(`core/ControlDiagram.js`). El mecanismo de restaurar contexto (ADR-0038)
usa `api.memory.set(clave, null)` para borrar la clave, no `unset()` — ver
el hallazgo de plataforma en `docs/plataforma-pegasus.md` §`api.memory`.
Detalle completo en [`028/tasks.md`](../features/028-theme-como-se-juega/tasks.md).

### F · Verificación

**F1 · Software, ahora:**

- Tests de contrato, de resolución y de import (pytest), y `node tests/*.cjs`.
- `doctor` sobre `fixtures` y sobre `library`, y el comando en dry-run.
- Pegasus real a 1920×1080: juego con guía, juego sin guía, textos largos,
  foco, convivencia con el carrusel de revistas (en `fixtures/`), volver desde
  Hacks y Manual, y JUGAR desde la guía.

  **En curso (2026-09-29):** confirmado en el gabinete real que la fila de
  4 tarjetas no pisa la columna derecha (145×45px), y que ADR-0038
  funciona con Pacman — JUGAR desde la guía, `Esc` para salir, la guía
  reaparece abierta al volver; también el caso "cerrar sin jugar" sin que
  quede una clave vieja secuestrando la próxima apertura. Falta todavía:
  el fixture `dino` con guía completa, el diagrama de 0 botones de Pacman,
  el recorrido de foco completo JUGAR→…→Favoritos, y volver a la guía tras
  cerrar Hacks abierto desde ahí. Checklist exacto en
  [`028/tasks.md`](../features/028-theme-como-se-juega/tasks.md) §Cierre.

**F2 · Físico, con el panel final instalado:**

- **No es criterio de aceptación.** Sin el panel medido, la guía muestra
  entradas lógicas, que es lo correcto. La feature puede cerrarse con F1.
- Antes de medir, el autor configura el mapeo global de MAME y revisa los
  `.cfg` provisorios (`simpsons`, `finalb`). Si quedan, el comando los toma
  como excepciones legítimas.
- Prueba botón por botón, por ejemplo con `joy.cpl`: apretar cada posición y
  anotar el número.
- Orden de las dos placas idénticas tras varios reinicios.
- Lo medido se anota en el perfil y se regenera la correspondencia.

**Salida:** evidencia y lista de limitaciones. Ninguna asignación incorrecta
se presenta como confirmada.

### G · Cierre

- [x] **✅ (2026-09-29)** Sección en `docs/guides/cargar-un-juego-nuevo.md`:
      §5 documenta el bloque `guia` de `data.json` (no se escribe a mano,
      lo produce COINDOOR) y el nuevo §9 documenta `attract controles` —
      cuándo correrlo y qué hacer cuando cambia el panel.
- [x] **✅ (2026-09-29)** Procedimiento para actualizar el perfil cuando
      cambia el panel y regenerar la correspondencia: mismo §9.
- [x] **✅ (2026-09-29)** Limitaciones, roadmap y estado de la feature:
      `spec/constitution/roadmap.md` (027/028, con el detalle de qué se
      verificó en Pegasus real y qué sigue pendiente).
- [x] **✅ (2026-09-29)** `spec/constitution/tech-stack.md`: filas de
      `controles.py`, `Gabinete.qml`, `Correspondencia.qml`,
      `ControlDiagram.js`/`.qml`, `GuideOverlay.qml`, `gabinete.json` y los
      tests nuevos.
- [ ] `CLAUDE.md` y su espejo `AGENTS.md`: mapa del repo y conteo de tests,
      con permiso del autor — **sigue sin ese permiso, no tocado**.

### Pausas que necesitan al autor

1. **Precondiciones (§4.0):** commitear lo pendiente, autorizar la rama y
   corregir el `launch:` de arcade.
2. **A1:** instalar `attract-debug`, cambiar de theme, correr el experimento y
   volver a ATTRACT.
3. **A2:** confirmar la tecla de salida lanzando un juego DOS.
4. **A6:** importar los candidatos con COINDOOR.
5. **Después de B:** leer la conclusión del piloto.
6. **C:** aprobar la spec y el plan, y decidir las tres cuestiones abiertas.
7. **E y F1:** sumar `fixtures/` a `game_dirs.txt` (y sacarlo después) y
   probar en Pegasus.
8. **F2:** instalar el panel, configurar el mapeo global de MAME, limpiar los
   `.cfg` provisorios y medir.
9. **Commits:** solo si los pide.

---

## 5 · Pedido a COINDOOR (borrador)

La forma exacta se fija después del piloto. Lo que ya se sabe que hace falta:

- **Exportar un bloque de guía** dentro del `data.json` del paquete, con:
  objetivo, acciones con su nombre original, entradas lógicas, primeros pasos,
  reglas esenciales, multijugador, requisitos de periféricos, fuentes y estado
  de revisión por grupo.
- **Poder editar la guía** en COINDOOR, no solo importarla de ArcadeDB: es el
  único lugar donde se corrige (decisión 14).
- **No afirmar nunca un botón físico del gabinete.** COINDOOR no conoce el
  panel ni su configuración.
- **Llevar la procedencia de cada grupo** hasta el paquete.
  `FieldProvenance` ya existe en COINDOOR.
- **Un paquete sin bloque de guía sigue siendo válido.**

---

## 6 · Riesgos y limitaciones conocidas

- **Placas idénticas.** Mismo `VID/PID`: Windows y MAME pueden intercambiar
  qué placa es `JOYCODE_1` y cuál `JOYCODE_2`. Hasta medirlo, nada del
  jugador 2 se muestra como confirmado. Mitigación a evaluar en A3:
  `<mapdevice>` de MAME.
- **Una huella que se vence sola.** MAME reescribe el `.cfg` al cerrar cada
  juego (contador de créditos y mezclador). Si la huella fuera de los archivos
  enteros, `doctor` marcaría la correspondencia vencida después de cada
  partida. Mitigación: huella de las entradas normalizadas (§4.D).
- **Config de DOSBox en capas.** Config primaria, conf del juego y
  `mapperfile`. Si el comando lee solo el `dosbox.conf`, puede anunciar mal la
  tecla de salida o el estado de la palanca. Mitigación: A2 mide cuál carga, y
  el comando lee las tres.
- **Remapeos provisorios tomados como excepciones.** Los `.cfg` de hoy son del
  panel provisorio (§3.1). Si siguen ahí al instalar el panel final, el comando
  los reporta como excepciones legítimas de la decisión 3. Mitigación: el
  dry-run los marca, y se revisan antes de F2.
- **Remapeos fuera de ATTRACT.** El theme no detecta un remapeo hecho desde el
  menú de MAME. Lo detecta `doctor` por la huella, y la guía puede quedar
  desactualizada hasta que se regenere la correspondencia.
- **Panel en transición.** Todo lo que se verifique con el panel de hoy se
  vence al instalar el nuevo; por eso la prueba física espera (decisión 2f).
- **DOS sin palanca.** El generador escribe `joysticktype = disabled`.
  Habilitarlo es otro trabajo; la guía lo dice tal cual.
- **ArcadeDB sin procedencia confirmada.** No se adopta `buttons_colors` como
  fuente hasta conocer su origen (§8.4 de la propuesta).
- **Sin prueba con una persona nueva.** La meta de "entender en ~15 segundos"
  queda como hipótesis de diseño sin medir.

---

## 7 · Fuera de alcance de la v1

- Ayuda durante la partida (overlay dentro del emulador).
- Remapear controles desde la guía.
- Guías de estrategia y duplicar lo que ya está en Hacks.
- Unificar el vocabulario de botones con los trucos.
- Habilitar el joystick en DOSBox.
- Una combinación de salida en el panel.
- Uso de los flippers: están en el perfil, pero ningún juego de la muestra los
  necesita.
- Editar la guía dentro de ATTRACT.
- Scraping masivo o promesa de cobertura universal.

---

## 8 · Hallazgos laterales (fuera de esta feature)

- El `launch:` de `library/arcade/metadata.pegasus.txt` tiene una comilla
  desbalanceada (`mame.exe" "{file.path}"`, sin la de apertura). Ahora es una
  precondición (§4.0): sin corregirlo no se puede medir A1 ni "Jugar".
- `src/attract/ingest.py` llama a `mame` sin ruta, y en esta máquina `mame` no
  está en el PATH: `attract ingest` no funciona en el gabinete (ADR-0018 ya lo
  resolvió para el `launch:`, no para el ingest).
- El Makefile no funciona en Windows tal como está: no hay `make`, y busca el
  venv en `.venv/bin/`, pero en Windows está en `.venv/Scripts/`.
- `spec/constitution/tech-stack.md`, `CLAUDE.md` y `AGENTS.md` están
  desactualizados: dicen "0001-0030" y tech-stack cita ADR-0015 como
  `accepted`.
- ADR-0019, 0020 y 0028-0030 siguen en `proposed` con el código ya escrito.
- `library/msdos/monkey-island/dosbox.conf` es un conf de pack: arranca un
  menú DOS que junta Monkey Island 1 y 2, aunque en la librería son dos
  entradas separadas.
