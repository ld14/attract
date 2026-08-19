# Lo que sabemos del terreno: Pegasus + Qt 5.15

Referencia de **hechos verificados** sobre la plataforma donde corre el theme.
Todo lo que está acá se comprobó abriendo Pegasus, no leyendo documentación —
y donde la documentación decía otra cosa, está anotado.

## Cómo usar este documento

- **Acá van hechos, no decisiones.** Por qué el proyecto eligió una cosa u
  otra vive en `spec/decisions/`. Acá va qué hace la plataforma.
- **Cada hecho apunta a su evidencia.** Si necesitás el razonamiento completo,
  seguí el puntero; no está copiado acá para que no se desincronice.
- **Si algo contradice esto, gana lo que se vea en pantalla.** Este archivo es
  un resumen de mediciones, no una autoridad.

Contexto fijo: Pegasus `alpha16-82-gc3462e68`, **Qt 5.15.10**, macOS para
desarrollo y Windows en el gabinete ([`ADR-0006`](../spec/decisions/0006-version-politica-pegasus.md),
[`ADR-0003`](../spec/decisions/0003-cross-platform.md)).

---

## 1 · Qué módulos existen en este binario

**La lista de dependencias de build declaradas de Pegasus NO es confiable, ni
para afirmar ni para negar.** Es el hallazgo más útil de todos: se probó en las
dos direcciones y falló en las dos.

| Módulo | ¿Está? | Declarado en el build | Evidencia |
|---|---|---|---|
| `QtQuick` 2.x, `QtQuick.Layouts` | sí | sí | todo el theme |
| `QtMultimedia` (5.9) | **sí** | sí | `themes/experimentos/multimedia-loop.qml` |
| `QtGraphicalEffects` (1.0) | **sí** | **no** | `themes/experimentos/graphical-effects.qml` |
| `QtQuick.Pdf` | **no** | no | `themes/experimentos/pdf-qtquick.qml`, [`ADR-0007`](../spec/decisions/0007-paginas-revista-imagenes-no-pdf.md) |
| `Qt5Compat`, `MultiEffect` | no | — | son de Qt 6; acá es Qt 5.15 |

**Si un import no resuelve, Pegasus no carga el theme entero** y muestra
`Theme loading failed :(`. No hay degradación parcial: es todo o nada. Por eso
los experimentos de import se corren **antes** de escribir nada encima.

---

## 2 · La API: las formas reales de los datos

Lo que la documentación no dice, o dice distinto.

### `game.extra` — los campos `x-`

- **Siempre es una lista** (`QStringList`), nunca un string. Incluso
  `x-simple: valor` vuelve como `["valor"]`. No es un `Array` de JS
  (`Array.isArray()` da `false`) pero el acceso por índice funciona.
- Las claves conservan el guión: `extra["con-guion"]`.
- Evidencia: `themes/attract-debug/theme.qml`,
  [`ADR-0001`](../spec/decisions/0001-transporte-datos-ricos.md).

### `game.files` — los archivos lanzables

- Es un **modelo de Qt**: tiene `count` y `get(i)`. `length` da `undefined`.
- **`files[i].path` viene SIN esquema** (`/Users/…/dino.zip`), al revés que
  los assets, que sí traen `file:///`. Esa asimetría es una trampa: un
  `XMLHttpRequest` necesita el esquema.
- **`files[i].name` ya viene sin extensión** (`dino`, no `dino.zip`).
- **`path` no siempre es una ruta de disco.** Un juego del provider de Steam
  devuelve `steam:255710` — un URI sin ninguna barra.
- Un `game:` con varios `file:` es **un** juego con `files.count > 1`, no
  varios juegos ([`ADR-0004`](../spec/decisions/0004-identidad-set-merged.md)).
- Evidencia: `themes/experimentos/rutas-relativas.qml`.

### `game.assets`

- Devuelven URLs **con** esquema (`file:///…`).
- **Pueden ser remotas.** Un juego de Steam devuelve `boxFront` como
  `https://shared.akamai.steamstatic.com/…`. En un gabinete offline eso nunca
  carga, así que la única señal confiable de que un asset sirve es
  `Image.Error`, no que el string esté lleno.
- Evidencia: `themes/attract/ui/CoverImage.qml`, `005/tasks.md`.

### Campos nativos con valores centinela

- **`releaseYear` vuelve `0`** cuando no hay `release:`. No distingue "sin
  dato" de "año cero".
- **`rating` vuelve `0.0`** por default. Misma colisión — por eso el bloque de
  reseña **no lo lee** y usa `data.json → review`, que sí puede ser `null` de
  verdad (`docs/CONVENCION.md` §2.3).
- **`players` vuelve `1`** por default. Acá la colisión se acepta: un `1` en
  un juego retro casi nunca es una mentira dañina.

### `api.allGames`

- **No es la librería de ATTRACT.** Es la unión de lo que encontraron **todos**
  los providers activos de Pegasus (Steam, es2, logiqx, skraper…). Un juego que
  entra por otro provider no tiene `x-set`, ni `data.json`, ni carpeta de
  colección.
- Se resuelve apagando los providers, no filtrando en el theme
  ([`ADR-0017`](../spec/decisions/0017-providers-pegasus.md)).

### `api.keys` — los botones del mando

Existen **ocho** predicados, y los ocho responden en este binario. El mapeo a
teclas y a botones lo decide `settings.txt`, que vive fuera del repo: el theme
usa siempre `api.keys.*`, nunca una tecla literal.

| Predicado | Botón | Tecla por default | Uso en el theme |
|---|---|---|---|
| `isAccept` | A | `Return`/`Enter` | acción primaria |
| `isCancel` | B | `Esc`/`Backspace` | volver / cerrar |
| `isDetails` | X | **`I`** | panel de orden (009) |
| `isFilters` | Y | **`F`** | abrir Buscar (010) |
| `isPrevPage` / `isNextPage` | L1 / R1 | `Q`,`A` / `E`,`D` | libres |
| `isPageUp` / `isPageDown` | L2 / R2 | `Fn`+`↑`/`↓` | libres |

- **Ninguno se superpone**: cada tecla prende exactamente uno.
- **No hay `isMenu`.** `keys.menu` (`F1`/Start) existe en `settings.txt` y es
  **invisible** para el theme: no prende ningún predicado. Una función que
  necesite botón propio no puede colgarse de ahí.
- **Las letras `a d q e f i` no son teclas libres**: disparan predicados. Una
  pantalla que escriba con el teclado físico (Buscar) tiene que preguntar solo
  `isCancel` y tratar el resto como texto.
- **`isCancel` (Escape/B) está RESERVADA por Pegasus por encima del theme**:
  es la tecla con la que el usuario sale del theme o abre el menú propio de
  Pegasus. Si un `Keys.onPressed` la acepta (`event.accepted = true`) sin
  hacer nada visible con ella —el caso típico es tratarla igual que "subir de
  foco" y aceptarla también cuando ya no hay a dónde subir—, el evento se
  consume ahí y nunca llega a Pegasus: Escape queda "bloqueada" para todo lo
  que no sea este theme. La regla: **aceptar `isCancel` solo en la rama que
  hace algo real con ella** (cerrar un overlay, volver a la pantalla
  anterior), nunca como parte de una condición combinada con otra tecla que sí
  siempre tiene acción. Bug real visto en Pegasus el 2026-08-09,
  `screens/BrowseScreen.qml`.
- Evidencia: `themes/experimentos/teclas-xy.qml` §RESULTADO OBSERVADO.

### Lanzar

- Solo existe `game.launch()`. **El comando resuelto no está expuesto.**
- **No hay ninguna señal de éxito ni de fallo**: la documentación dice que un
  fallo "se loguea" y punto. Cualquier overlay de "iniciando" necesita su
  propia salida o se cuelga para siempre.
- `metadata.pegasus.txt` soporta `launch`/`command`, `workdir`/`cwd`, las
  variables `{file.*}` y `{env.*}`. **No hay `launch:` por sistema operativo.**
- Evidencia: `themes/attract/overlays/LaunchOverlay.qml`,
  [`ADR-0018`](../spec/decisions/0018-launch-ruta-absoluta.md).

### Abrir algo con la app del sistema

- **`Qt.openUrlExternally(url)` existe y funciona.** Es global de QtQml: **no
  necesita `import`**, así que no puede provocar el "Theme loading failed" de §1.
  Por debajo es `QDesktopServices::openUrl` — `LSOpenCFURLRef` en macOS,
  `ShellExecuteW` en Windows.
- **Devuelve `false` con una ruta inexistente**, y `false` con una url vacía. A
  diferencia de `game.launch()`, **acá sí hay canal de error** — aunque un `true`
  sigue significando "el SO aceptó el pedido", no "el visor arrancó".
- **Espacios y acentos abren en macOS con y sin `encodeURIComponent`.** No está
  medido en Windows; el theme codifica el nombre por ser la forma canónica.
- **Con Pegasus en fullscreen, la ventana externa abre POR DELANTE y Pegasus
  pierde el foco.** No hay ninguna API de foco ni de ventanas en Pegasus para
  recuperarlo. En un gabinete sin teclado eso es un viaje de ida.
- Sin medir: **todo el comportamiento en Windows**.
- Evidencia: `themes/experimentos/abrir-url-externa.qml` (2026-08-09, macOS),
  [`ADR-0021`](../spec/decisions/0021-manual-pdf-app-del-sistema.md).

### `api.memory` — la única persistencia del theme

- Existe, con `get` / `set` / `has` / `unset`, y **sobrevive a cerrar y
  reabrir Pegasus** (⌘Q, no solo cambiar de theme).
- **`set()` conserva el tipo.** Un `number` vuelve `number`; un `Array` de
  strings vuelve un `Array` de verdad (`Array.isArray()` da `true`). No hace
  falta `JSON.stringify` — al revés que `game.extra`, que siempre envuelve en
  lista.
- Sin medir: objetos anidados, y qué pasa con un corte de luz en vez de una
  salida limpia.
- Evidencia: `themes/experimentos/memoria.qml`.

### Leer archivos desde el theme

- `XMLHttpRequest` sobre `file://` **funciona**, y encadenado dos veces
  también (leer un JSON, sacar una ref, leer otro).
- Con `file://` el `status` llega **`0`** aunque haya salido bien.
- Evidencia: `themes/experimentos/json-chain-test.qml`,
  [`ADR-0001`](../spec/decisions/0001-transporte-datos-ricos.md).

### QtMultimedia

- `loops: MediaPlayer.Infinite` **reengancha solo**.
- **`onStopped` NO se dispara nunca** en un loop continuo. Un contador colgado
  de ahí se queda en cero mientras el video loopea perfecto. Si hace falta
  detectar el reenganche, la señal es que **la posición retroceda**.
- Evidencia: `themes/experimentos/multimedia-loop.qml`.

---

## 3 · Trampas de QML que ya nos mordieron

Cinco bugs de la misma familia, todos encontrados **mirando la pantalla**
y ninguno leyendo el código. La regla que dejan:

> Si estás escribiendo una resta de píxeles para ubicar algo, o peleándole al
> sistema de layout, va a funcionar hasta que cambie algo que no controlás.

| Trampa | Qué pasó | Dónde |
|---|---|---|
| **Un binding sobre `y` dentro de un positioner** | `Column`/`Row` posicionan escribiendo la `y` de sus hijos. El binding pelea y gana: el botón saltaba encima de la carátula. Se veía bien en 3 de 4 capturas. El "lift" va por `transform: Translate`, que no participa del layout | `ui/Boton.qml` |
| **Altos calculados a mano** | Un espaciador de `parent.height - 14 - 44`, donde `44` asumía tres renglones de título. Al cambiar la fuente dejó de ser cierto y el texto se salió | `screens/GameCard.qml` |
| **Crecer hacia arriba sin tope** | El hero anclado abajo creció más que el espacio disponible y se metió en la barra. La solución es que un bloque ceda calculando cuánto entra, no fijar constantes | `screens/BrowseScreen.qml` |
| **Dos bloques anclados a bordes opuestos** | El carrusel anclado al fondo crecía hacia arriba; la columna crecía hacia abajo. Cada uno correcto por su cuenta, cruzándose por diez píxeles. Se arregla metiéndolos en el **mismo** positioner con un espaciador calculado en un solo lugar y con piso | `screens/DetailScreen.qml` |
| **Un hijo de `Row` cuyo ancho depende del `Row`** | Un `Row` calcula su ancho **a partir del de sus hijos**. Un hijo con `width: parent.width - 240` cierra el círculo: QML no lo resuelve y dibuja **todo encimado en la misma coordenada**. Se arregla anclando contra un contenedor de ancho propio, no contra el positioner | `overlays/CheatsOverlay.qml` |

**Las cinco son la misma frase, y por eso está escrita acá y no solo en un
comentario:** cuando el layout lo calcula uno en vez de dejárselo al sistema,
funciona hasta que cambia algo que no controlaba — el orden de resolución de
los bindings, la fuente, el largo de un título, el alto de una tapa. Ninguna
de las cinco se vio leyendo el código; las cinco salieron de mirar la
pantalla.

**El corolario que sirve para revisar código**, y que costó las cinco veces:
antes de escribir `width:` o `height:` en función de `parent`, preguntarse
**quién le da el tamaño al padre**. Si el padre es un `Row`, `Column`, `Flow`
o `Grid` **sin tamaño explícito**, lo toma de sus hijos y la dependencia es
circular. Si tiene `width` propio (o anchors a los dos lados), no lo es.

Y qué positioner escribe qué, que es lo que decide si un `anchors` en un hijo
es idioma o pelea:

| Positioner | Escribe | Se le puede anclar al hijo |
|---|---|---|
| `Row` | solo `x` | sí, el eje vertical (`verticalCenter`, `top`, `bottom`) |
| `Column` | solo `y` | sí, el eje horizontal |
| `Flow`, `Grid` | `x` **e** `y` | **no**, ningún eje |

### `Loader.sourceComponent` inline + un nombre de propiedad que choca con un `id` de afuera

**`Loader { sourceComponent: Tipo { prop: prop } }` puede autorreferenciarse
en vez de leer el `id` de afuera, si `Tipo` tiene una propiedad propia con
ESE MISMO nombre.** `sourceComponent` con un objeto inline lo envuelve en un
`Component` implícito, y ahí adentro el nombre de la propiedad del tipo
cargado le gana al `id` del documento exterior — se genera un binding loop
silencioso (`QML Tipo: Binding loop detected for property "prop"`, visible
solo en `lastrun.log`, nunca en pantalla como error) y la propiedad se queda
en su valor por default para siempre.

Pasó con `theme.qml:182`: `SortPanel { catalogo: catalogo }` — mismo texto
que `BrowseScreen { catalogo: catalogo }`, que sí funciona porque es un hijo
directo (sin `Loader` de por medio), no envuelto en un `Component`. La
diferencia no se ve mirando el código de ninguno de los dos archivos por
separado — solo se ve en el log. **Se arregla evitando el choque de
nombres**: un alias en el documento exterior con OTRO nombre
(`readonly property var catalogoInstancia: catalogo`) y referenciar ese
alias, no el `id` a secas, dentro del `sourceComponent`. Medido el
2026-08-09.

### Una trampa que no es de layout pero se le parece

**Mezclar dos estados en una variable.** El carrusel de revistas usaba
`indice` para "cuál está elegida" y "desde cuál se muestra" a la vez. Tienen
topes distintos —la selección llega a `total-1`, el scroll se topa en
`total-2` para que siempre se vean dos tapas— así que la última revista
quedaba visible pero **inalcanzable**. No es un off-by-one: es que eran dos
cosas.

### Y una trampa que no es de layout

**`Theme.qml` y `theme.qml` son el mismo archivo** en macOS y Windows
(filesystems case-insensitive). Pegasus exige `theme.qml` como entrada, así que
un singleton no puede llamarse `Theme.qml`: crear uno **pisa al otro en
silencio**. El `qmldir` permite exponerlo con otro nombre — el archivo se llama
`Tokens.qml` y en el código se sigue escribiendo `Theme.algo`.

**En macOS las flechas comunes llegan con `KeypadModifier`.** `Key_Up`
(`0x1000013`) viene con `event.modifiers === 536870912` (`0x20000000`), no con
`NoModifier`. Un `if` que exija "flecha sin modificadores" no dispara nunca en
el Mac. `Fn`+`↑`/`↓` es otra cosa distinta y sí da `Key_PageUp`/`Key_PageDown`.
Medido el 2026-08-05 con `themes/experimentos/teclas-xy.qml`.

**Una `property` no puede empezar con mayúscula.** `readonly property int MAX:
12` no compila: `Property names cannot begin with an upper case letter`. En
JavaScript sí se puede —`core/InputTokens.js` tiene `var FLECHAS`— así que la
costumbre de escribir las constantes en mayúscula cruza mal la frontera entre
los `.js` y los `.qml`. Y el castigo es el máximo que hay: **el theme entero no
carga**, con la misma pantalla de `Theme loading failed :(` que un import que
no resuelve (§1). Medido el 2026-08-05 con `themes/experimentos/teclas-xy.qml`.

### Cosas de CSS que Qt Quick 5.15 no tiene

| CSS | Qué se hizo |
|---|---|
| `radial-gradient` | `Canvas` (`Rectangle` solo hace gradientes verticales). **Ojo:** `130% 100%` es una **elipse**; `createRadialGradient` solo hace círculos, hay que escalar el contexto |
| `conic-gradient` | No existe, ni en `Rectangle` ni en `Canvas`. Se dejó afuera |
| `mix-blend-mode` | Sin equivalente. Se aproxima con `opacity` |
| `clamp(min, val, max)` | Con el lienzo fijo colapsa a un número — **pero el `min` es un piso real**, no decoración. Se recupera con `fontSizeMode: Text.Fit` + `minimumPixelSize` |
| `backdrop-filter: blur` | `FastBlur` (existe, ver §1) |

---

## 4 · El entorno, no el código

- **Una app de GUI en macOS no hereda el PATH del shell.** Arranca con
  `/usr/bin:/bin:/usr/sbin:/sbin` (`getconf PATH`), y `/usr/local/bin` no está
  ahí. Por eso Pegasus no encontraba `mame`. Las variables de entorno tienen el
  mismo problema, así que `{env.VAR}` tampoco salva
  ([`ADR-0018`](../spec/decisions/0018-launch-ruta-absoluta.md)).
- **Pegasus verifica que los archivos existan** (`general.verify-files: true`)
  y descarta los juegos cuyo `file:` no esté. Un `.zip` de 0 bytes alcanza para
  que aparezcan.
- **La config vive fuera del repo**, en
  `~/Library/Preferences/pegasus-frontend/`: `game_dirs.txt`, `settings.txt`
  (providers, theme, teclas). `attract doctor` no puede validar nada de eso.
- **Los themes se leen al arrancar.** Cambiar un `.qml` instalado exige cerrar
  Pegasus del todo (⌘Q) y volver a abrirlo.
- **`mame -listxml` lee la base de datos interna de MAME, no el archivo.** Por
  eso `attract ingest` se puede probar con ROMs de 0 bytes.

---

## 5 · Lo que sigue sin saberse

- **Nada de esto se verificó en el gabinete (Windows).** Todo se midió en el
  Mac. Lo que más riesgo tiene de comportarse distinto es `loops` de
  QtMultimedia, que históricamente varía entre backends de plataforma — y desde
  el 2026-08-09 se le suma `Qt.openUrlExternally`, que en Windows va por
  `ShellExecuteW` en vez de `LSOpenCFURLRef`.
- **Cómo se vuelve a Pegasus desde una ventana externa en el gabinete.** El foco
  se pierde y no hay API para recuperarlo; con joystick solo no hay `Alt+Tab`.
  Falta probar si el encoder puede mandar `Alt+F4`.
- Si `PreserveAspectCrop` **recorta** o **estira**: se vio que llena el panel
  sin franjas negras, falta distinguir cuál de las dos.
- El prototipo del handoff **no se puede renderizar**: le falta el
  `support.js` que trae su runtime, así que la comparación visual contra el
  diseño sigue pendiente.

---

## Referencias

- Experimentos con su resultado anotado: `themes/experimentos/`.
- Bitácora de verificación por feature: `spec/features/NNN-*/tasks.md`.
- Decisiones y sus alternativas descartadas: `spec/decisions/`.
- Documentación oficial: `pegasus-frontend.org/docs/themes/api` y
  `…/docs/user-guide/meta-files`.
