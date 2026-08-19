---
id: 0021
title: "El PDF del manual se entrega al sistema operativo con Qt.openUrlExternally"
status: accepted
date: "2026-08-09"
supersedes: null
superseded-by: null
tags: [frontend, data]
---

# 0021 — El PDF del manual se entrega al SO, no se dibuja en el theme

## Contexto

El manual digitalizado ya funciona: `data.json → manual.pages[]` lista imágenes
en `media/<set>/_manual/` y `overlays/DocumentViewer.qml` las hojea
([`ADR-0014`](0014-manual-digitalizado.md)). Ese diseño existe porque
[`ADR-0007`](0007-paginas-revista-imagenes-no-pdf.md) probó contra Pegasus real
que **renderizar un PDF adentro del theme es imposible**: `import QtQuick.Pdf`
ni siquiera deja cargar el theme (`themes/experimentos/pdf-qtquick.qml`).

**Esta decisión no reabre ADR-0007.** 0007 prohíbe *dibujar* un PDF adentro de
Pegasus y sigue vigente sin excepciones. Lo que se decide acá es lo contrario:
**no dibujarlo nunca, y en cambio pasárselo al sistema operativo** para que lo
abra la aplicación que el usuario ya tiene asociada. El theme no aprende nada de
PDF; aprende a soltarlo.

Lo que fuerza a decidir: un manual escaneado nace como PDF. Hoy el único camino
es rasterizarlo a mano página por página — un coste que ADR-0014 asume
explícitamente, pero que deja a todo manual no convertido **invisible en la
pantalla**. La tarjeta "Manual digitalizado" dice "No Disponible" aunque el PDF
esté ahí, al lado de la carátula.

Dos restricciones acotan el espacio antes de empezar:

- **Un import que no resuelve mata el theme entero**, no degrada
  (`docs/plataforma-pegasus.md` §1: "Si un import no resuelve, Pegasus no carga
  el theme entero"). Cualquier mecanismo que necesite un módulo nuevo se juega
  la pantalla completa, no una función.
- **Windows es la máquina de producción** y macOS la de desarrollo
  ([`ADR-0003`](0003-cross-platform.md)). Un mecanismo que funcione en uno solo
  no sirve.

## Decisión

El `data.json` de un juego puede declarar el PDF de su manual, junto a las
páginas y en la misma carpeta:

```json
{ "manual": { "pages": ["p001.png", "p002.png"], "file": "sf2ce-manual.pdf" } }
```

`file` es **opcional** y es un nombre de archivo **relativo a
`media/<set>/_manual/`** — sin subdirectorios, sin `..`, sin rutas absolutas.
`pages` pasa a ser opcional cuando hay `file`. Los tres estados son válidos:
solo `pages` (lo de hoy), solo `file`, y ambos.

**El theme lo abre con `Qt.openUrlExternally(url)`**, y nada más. Esa función es
parte del objeto global `Qt` de QtQml: **no necesita ningún `import`**, o sea
que no puede provocar el "Theme loading failed" que mató a `QtQuick.Pdf`. Por
debajo es `QDesktopServices::openUrl`, que resuelve a `ShellExecuteW` en Windows
y `LSOpenCFURLRef` en macOS — exactamente la semántica "abrilo con lo que el
usuario tenga". El theme **no nombra ningún visor**: ni Preview, ni Acrobat, ni
Edge. Devuelve `bool`, y ese bool es el único canal de error que existe.

La ruta se arma en `core/Paths.qml`, que sigue siendo el único lugar del theme
que arma rutas, reusando `manualDe()` y `conEsquema()` (que ya resuelve el
`C:/…` de Windows). El nombre de archivo se pasa por `encodeURIComponent()`
antes de concatenarlo; el directorio no, porque ya trae el esquema y las barras.
La medición mostró que en macOS las dos formas abren, así que **la codificada se
elige por ser la canónica, no porque esté medido que haga falta** — y la corrida
de Windows todavía no existe.

**Antes de abrir, el theme avisa.** Se mide (ver §Verificaciones) que el visor
abre por delante y **Pegasus pierde el foco**, sin ninguna API para
recuperarlo. El aviso reusa `overlays/LaunchOverlay.qml` y dice que el manual se
abre fuera de ATTRACT. No arregla el foco — no hay nada en el theme que pueda
hacerlo — pero convierte una sorpresa en una decisión de quien aprieta el botón.

Igual que con las revistas ([`ADR-0009`](0009-frontera-produccion-consumo-revistas.md))
y con las páginas de manual (ADR-0014), **ATTRACT es consumidor de este
contrato, no productor**: rasterizar o generar PDFs queda fuera de alcance.

## Alternativas consideradas

### A · Que lance Pegasus, con un `launch:` en `metadata.pegasus.txt`

Darle al PDF una entrada propia y dejar que `game.launch()` haga el trabajo, que
es el único lanzador que la API de Pegasus expone.

- A favor: usa el mecanismo que Pegasus ya tiene y que está verificado —
  `game.launch()` es lo único que este proyecto sabe con certeza que lanza algo.
- En contra: **exige una entrada de juego por cada manual.** Eso es una
  colección nueva, una pantalla nueva y una navegación nueva, que es exactamente
  lo que este cambio no puede hacer: el manual tiene que seguir siendo una
  tarjeta de CONTENIDO EXTRA. Además `metadata.pegasus.txt` es artefacto de
  build ([`ADR-0002`](0002-metadata-fuente-o-artefacto.md)) y **no admite un
  `launch:` por sistema operativo** (`docs/plataforma-pegasus.md` §Launch), así
  que el mismo archivo tendría que servir a `open` y a `start`.
- **Descartada porque:** convierte un botón dentro del detalle en una colección
  de primera clase — cambia el modelo de datos y la experiencia entera para
  agregar una acción.

### B · Que lo abra Python, con `subprocess`

`attract` ya es una CLI que corre en las dos máquinas y podría llamar a `open` o
`start` con la ruta.

- A favor: `subprocess` es stdlib, y ahí sí hay tests de verdad, sin depender de
  abrir Pegasus a mano.
- En contra: **ATTRACT no está corriendo cuando el usuario está mirando la
  pantalla.** Es una herramienta de build que se ejecuta antes; el gabinete
  arranca Pegasus solo. No hay ningún canal theme → Python: el theme lee
  archivos con `XMLHttpRequest` y nada más (ADR-0001).
- **Descartada porque:** no existe el momento en que ese código podría
  ejecutarse. Habría que inventar un proceso residente y un protocolo entre los
  dos, que es infraestructura nueva para una acción de un botón.

### C · `QProcess`, `Qt.labs.platform` o `QtQuick.Dialogs`

Los tres dan formas más ricas de hablar con el sistema (código de salida real,
diálogos nativos, control del proceso hijo).

- A favor: `QProcess` daría lo que `Qt.openUrlExternally` no da — saber si el
  visor arrancó de verdad, y no solo si el SO aceptó el pedido.
- En contra: **los tres necesitan un `import`**, y en este binario un import que
  no resuelve no degrada: no carga el theme (`docs/plataforma-pegasus.md` §1,
  medido con `QtQuick.Pdf`). Ninguno de los tres está verificado acá. Además
  `QProcess` obligaría a elegir el comando por sistema operativo y a construirlo
  con la ruta adentro — o sea, exactamente el problema de quoting e inyección
  que `openUrlExternally` no tiene, porque recibe una URL y no una línea de
  comando.
- **Descartada porque:** se apuesta la pantalla completa a cambio de un dato de
  diagnóstico. El mismo riesgo que ya se cobró una vez con `QtQuick.Pdf`.

### D · Convención implícita de nombre, sin campo nuevo

Que el theme busque `media/<set>/_manual/manual.pdf` y lo ofrezca si está.

- A favor: cero cambios en el contrato de `data.json` y cero validación nueva en
  `doctor`.
- En contra: **el theme no puede saber si un archivo existe.** Su única
  herramienta de disco es `XMLHttpRequest`, así que "averiguar si está" sería
  descargar el PDF entero para tirarlo. Y una convención de nombres que no está
  escrita rompe en silencio en cuanto un escaneo no la cumple.
- **Descartada porque:** es el mismo motivo por el que ADR-0014 rechazó
  `x-manual: 12` — un dato implícito no le dice al visor qué archivo abrir. Que
  la decisión anterior ya haya tropezado con esto es la razón de no repetirlo.

## Consecuencias

**Positivas**

- **Cero dependencias nuevas y cero riesgo de carga.** Sin `import`, el peor
  caso es una función que devuelve `false` — no un theme que no abre.
- **No se acopla a ningún visor.** El usuario abre el PDF con lo que ya usa; el
  theme nunca nombra a Preview, Acrobat ni Edge.
- **Sin shell y sin concatenar comandos.** La API recibe una URL, así que no hay
  quoting que hacer mal ni inyección posible con metadata que un humano edita a
  mano.
- **Cero pantallas nuevas.** El PDF entra por la tarjeta que ya existe. Un juego
  con páginas escaneadas sigue abriendo el visor igual que hoy.
- Un manual que solo existe como PDF deja de ser invisible sin pagar antes la
  rasterización que ADR-0014 asumía como único camino.

**Coste asumido**

- **No hay forma de saber si el visor arrancó de verdad.** `openUrlExternally`
  informa que el SO aceptó el pedido, no que algo se abrió. Es el mismo límite
  que ya tiene `game.launch()`, donde "un fallo se loguea y punto"
  (`overlays/LaunchOverlay.qml` L12-22). La consecuencia práctica: el aviso de
  error solo cubre el caso en que el SO rechaza, no el caso en que acepta y no
  pasa nada.
- **Pegasus pierde el foco, y en el gabinete eso es un viaje de ida.** Medido:
  con Pegasus fullscreen el visor abre **por delante** (o sea, el usuario sí ve
  que algo pasó — el riesgo que se temía era el contrario) pero **el foco se va
  y no vuelve solo**. No hay API de foco ni de ventanas en Pegasus, así que el
  theme no puede recuperarlo. En el Mac se resuelve con `cmd-tab`; **el gabinete
  tiene solo joystick y botones**, y un joystick no cambia de ventana ni cierra
  una aplicación. Quien abre el PDF en el gabinete se queda en el visor.
  Se asume a sabiendas, con el aviso previo como única compensación desde el
  theme. **La mitigación de verdad vive fuera de ATTRACT:** mapear `Alt+F4` (o
  `Alt+Tab`) a una combinación de botones en el encoder del joystick. Es
  configuración del gabinete, no código de este repo, y por eso no se resuelve
  acá — pero sin ella la feature es una trampa en producción.
- Un PDF declarado y borrado del disco no se detecta hasta que alguien lo
  aprieta. `attract doctor` lo agarra antes, pero solo si se corre.
- Dos maneras de leer el mismo manual (páginas adentro, PDF afuera) es una
  superficie más para mantener coherente.

**Qué habría que revisar si esto se replantea**

- Que `Qt.openUrlExternally` devuelva `true` sin abrir nada de forma sistemática
  en Windows: ahí el aviso de error es decorativo y hay que decirlo en la
  pantalla o sacarlo.
- **Que el gabinete no consiga nunca una forma de volver a Pegasus.** Es el
  riesgo vivo de esta decisión. Si al probarlo en producción se ve que el
  jugador queda atrapado en el visor y el encoder no puede mandar `Alt+F4`,
  entonces la salida ya no es un aviso más claro: es no ofrecer el PDF donde no
  hay retorno, o volver a rasterizar a imágenes.
- Que Pegasus retome desarrollo y exponga foco o lanzamiento genérico — ahí la
  alternativa A deja de exigir una colección nueva.
- Que aparezcan otros formatos (EPUB, CBZ, CHM). No cambian nada de esto:
  `openUrlExternally` es indiferente al formato, y lo único a decidir sería si
  `file` se generaliza o convive con hermanos.

## Verificaciones pendientes

- [x] **Confirmado 2026-08-09 en macOS** (Pegasus alpha16-82-gc3462e68) —
      corrido `themes/experimentos/abrir-url-externa.qml`.
      `Qt.openUrlExternally` **existe y abre de verdad**. Los cinco casos:
      PDF simple `true` y abre · ruta inexistente **`false`** · espacios+acento
      crudo `true` · codificado `true` · url vacía `false`.
      El hallazgo que justificaba la corrida es el segundo: **hay canal de
      error**, así que el aviso de fallo del plan es real y no decorativo.
      Las dos formas de la ruta abren en macOS, así que la medición **no**
      decide entre cruda y codificada — se elige la codificada por canónica.
      Y un hallazgo que no se buscaba: el visor abre **por delante**, no detrás
      (mejor que el riesgo previsto), pero **Pegasus pierde el foco** y no hay
      forma de recuperarlo desde el theme. Ver §Coste asumido.
- [ ] **Pendiente: la corrida en el gabinete Windows.** `ShellExecuteW` es un
      camino distinto de `LSOpenCFURLRef` y [`ADR-0003`](0003-cross-platform.md)
      no permite dar por buena una sola máquina. Falta medir los cinco casos,
      si la forma codificada abre, y cómo se comporta el foco ahí.
- [ ] Confirmar que cerrar el visor de PDF no cierra ni cuelga Pegasus.

## Referencias

- [`ADR-0007`](0007-paginas-revista-imagenes-no-pdf.md) — prohíbe *renderizar*
  PDF adentro del theme. **Sigue vigente**: este ADR entrega el PDF afuera, no
  lo dibuja.
- [`ADR-0014`](0014-manual-digitalizado.md) — la ubicación y el contrato que
  este ADR extiende con `file`.
- [`ADR-0015`](0015-contrato-data-json.md) — el contrato de `data.json` donde
  vive `manual`.
- [`ADR-0009`](0009-frontera-produccion-consumo-revistas.md) — el mismo reparto
  productor/consumidor: ATTRACT no produce el PDF.
- [`ADR-0003`](0003-cross-platform.md) — por qué no alcanza con verificarlo en
  el Mac.
- `themes/experimentos/abrir-url-externa.qml` — el experimento que decide.
- `themes/experimentos/pdf-qtquick.qml` — la contraprueba de ADR-0007, y el
  precedente de que un import equivocado tumba el theme entero.
- `docs/plataforma-pegasus.md` §1 (imports todo-o-nada) y §Launch
  (`game.launch()` sin señal de éxito).
- `spec/features/012-manual-pdf/` — la feature que implementa esta decisión.
