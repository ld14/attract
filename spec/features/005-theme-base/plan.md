# 005 · Theme de producción, base — Plan

_Cómo se implementa lo descrito en `spec.md`. Respeta `constitution/`._

## Enfoque

El prototipo es un solo archivo de 999 líneas con toda la lógica en una clase
y todos los estilos como strings de CSS inline. Traducirlo literal a QML daría
un `theme.qml` inmantenible.

El corte es en tres capas, y la regla que las separa es **quién sabe de qué**:

- **`core/`** sabe de datos y de rutas, no dibuja nada.
- **`ui/`** dibuja, no sabe de dónde salen los datos.
- **`screens/` y `overlays/`** componen las otras dos.

`Theme.qml` (singleton) es el equivalente de las variables CSS del prototipo:
los colores base, los radios, las sombras y las fuentes en un solo lugar. El
`accent`, en cambio, **no** vive ahí — es por juego (ADR-0013), así que baja
como propiedad desde la pantalla hasta cada átomo.

## Árbol

```
themes/attract/
├─ theme.cfg
├─ qmldir                       declara el UNICO singleton: Theme -> Tokens.qml
├─ theme.qml                    canvas 1280x720 escalado + estado + ruteo de foco
├─ Tokens.qml         (sing.)   tokens + FontLoader. Expuesto como `Theme`
├─ fonts/                       .ttf (los baja el autor, ver fonts/README.md)
├─ core/
│  ├─ Paths.qml                media/<set>/ y media/_magazines/<ref>/ en runtime
│  └─ GameData.qml             XHR de data.json -> accent, review, cheats, manual, mags
├─ ui/
│  ├─ Background.qml           3 capas + CRT
│  ├─ CoverImage.qml           cadena de fallback 2.2 + placeholder accent
│  ├─ Chip.qml  GlassButton.qml  AccentButton.qml  SectionLabel.qml  FocusRing.qml
├─ screens/
│  ├─ LibraryScreen.qml
│  └─ DetailScreen.qml
│     ├─ ReviewCard.qml
│     └─ ExtrasList.qml
└─ overlays/
   └─ LaunchOverlay.qml
```

En 006 se agregan `VideoPanel.qml`, `MagazineCarousel.qml`,
`core/MagazineData.qml` y `overlays/DocumentViewer.qml`; en 007,
`core/InputTokens.js`, `ui/InputTokenRow.qml` y `overlays/CheatsOverlay.qml`.
El árbol está pensado para que entren sin mover nada.

## Implementación

### 1. Esqueleto — se hace primero y se prueba antes de seguir

`theme.cfg`, `qmldir`, un `theme.qml` que solo dibuja un rectángulo, y un
`Theme.qml` singleton con dos colores. Se instala y se abre Pegasus.

Esto responde el cuarto riesgo del `spec.md` (¿subcarpetas y singletons?)
gastando diez minutos en vez de descubrirlo con el theme entero escrito. Si
falla: aplanar el árbol y reemplazar los singletons por un `QtObject` con `id`
declarado una vez en `theme.qml`. El resto del plan no cambia.

### 2. `Theme.qml` — tokens

Colores base, escala de radios, sombras y espaciado del handoff §Design
Tokens. `FontLoader` para las tres familias, con la familia del sistema como
fallback si el `.ttf` no está.

Un helper `mix(a, b, t)` con `Qt.rgba()` para reemplazar los `color-mix()` del
CSS, y `alpha(c, a)` para los `rgba(255,255,255,.06)` que el diseño usa por
todos lados.

### 3. `core/Paths.qml` — rutas en runtime, cero hardcodeo

`baseDe(game)` → `media/<set>/`, y `magazineDe(ref)` →
`media/_magazines/<ref>/`. El set sale de `game.extra["set"][0]` con fallback
al basename del archivo (el bloque `EXPERIMENTO` del fixture no tiene `x-set`,
y hay que cubrirlo).

**La vía concreta la decide el experimento `rutas-relativas.qml`.** Este
módulo existe justamente para que esa decisión quede en un archivo de veinte
líneas y no repartida por todo el theme.

### 4. `core/GameData.qml` — el `data.json`

Un componente no visual con `property var game`; cuando cambia, dispara el
`XMLHttpRequest` y expone `accent`, `accent2`, `review`, `cheats`, `manual`,
`mags` y un `estado` (`cargando` / `listo` / `sin-datos`).

Tres reglas que no son opcionales:

- **404 no es un error.** Un juego sin `data.json` es válido (fixture `mok`).
  Cae a `sin-datos` y cada bloque muestra su mensaje de §2.3.
- **JSON corrupto tampoco crashea.** `try/catch` alrededor del `JSON.parse`;
  se degrada igual que un 404. `attract doctor` ya lo detecta antes
  (`chk_json_valido`), pero el theme no puede confiar en que alguien lo corrió.
- **Cache por set**, para no repetir la petición cada vez que el foco pasa por
  el mismo juego en el rail.

La técnica (`XMLHttpRequest` sobre `file://` + `JSON.parse`) ya está
verificada contra Pegasus real, encadenada dos veces
(`themes/experimentos/json-chain-test.qml`). Lo único nuevo acá es la ruta.

### 5. `ui/` — los átomos

`CoverImage` encapsula la cadena de fallback de `CONVENCION.md` §2.2
(`boxFront → poster → marquee → color-wash con accent`) usando
`onStatusChanged` para saltar al siguiente cuando uno falla. Es el único lugar
del theme que conoce esa cadena.

`Background` son las tres capas del handoff. Las scanlines van con un `Image`
de 1×8px en `fillMode: Image.Tile` con la `y` animada — más barato que un
shader y no necesita `QtGraphicalEffects`.

El resto (`Chip`, `GlassButton`, `AccentButton`, `SectionLabel`, `FocusRing`)
son envoltorios finos sobre `Rectangle`/`Text` con las constantes del diseño.
Cada uno recibe `accent` como propiedad; ninguno lo busca por su cuenta.

### 6. `screens/` y el estado

`theme.qml` sostiene `screen` (`"library"` | `"detail"`), `selected` y
`launching`. Las dos pantallas son `FocusScope`; los overlays van en
`Loader { active: ... }` para no costar nada cerrados.

**No se porta el `onKey(e)` global del prototipo** (líneas 752-778). En QML el
foco lo resuelve el árbol: cada `FocusScope` maneja sus teclas y el overlay
activo se lleva el foco al cargarse. Menos estado y ningún bug de "la tecla se
la comió la pantalla de atrás".

`ReviewCard` implementa los dos niveles de "sin dato" de §2.3. `ExtrasList`
muestra las tarjetas de CONTENIDO EXTRA; en 005 solo puede aparecer la del
manual (la de trucos llega con 007), y `"No Disponible"` cuando no hay
ninguna.

### 7. `Makefile`

`make theme` pasa a instalar `themes/attract/`. Se agrega `make theme-debug`
para `themes/attract-debug/`, que sigue haciendo falta: es la evidencia de
ADR-0001 y el archivo sobre el que se copian los experimentos.

## Decisiones

- **Canvas fijo 1280×720** — [`ADR-0016`](../../decisions/0016-canvas-fijo-escalado.md).
  Todas las medidas son constantes del diseño; los `clamp()` colapsan a un
  número.
- **`api.keys`, no `Qt.Key` crudo** — `api.keys.isAccept(event)`, `isCancel`,
  `isDetails`. Es lo que mapea el gamepad; con `Qt.Key_Return` el gabinete no
  responde al joystick. Las flechas izquierda/derecha sí van crudas, no tienen
  equivalente en `api.keys` (igual que en `themes/attract-debug/theme.qml:76`).
- **El badge de formato se arma desde `x-formato`, no desde `mediaFor()`** —
  ya decidido en `docs/mapeo-mockup-pegasus.md`: `mediaFor()` mira la
  colección, no el juego, y se equivoca en 4 de 5. Es texto, no un ícono por
  medio.
- **Los bloques nunca desaparecen** — `CONVENCION.md` §2.3 le gana al handoff,
  que pedía omitirlos. Va anotado como divergencia consciente en el
  componente, no se "arregla" el handoff.
- **El `accent` baja como propiedad, no está en el singleton** — es un dato
  por juego (ADR-0013). Un átomo que lo leyera de `Theme` sería un átomo que
  se equivoca en cuanto haya dos accents en pantalla a la vez.
- **Un solo singleton, y en la raíz: `Theme`.** `Paths` y `GameData` quedan
  como componentes normales (`Paths` se instancia una vez en `theme.qml` con
  un `id`; `GameData` se instancia por pantalla, que es lo que necesita igual
  porque se liga a un juego puntual). Motivo: un singleton en una subcarpeta
  necesita su propio `qmldir` y es el mecanismo del que menos se sabe contra
  este binario. Se usa el que hace falta y no se apuesta al otro.
- **El archivo del singleton se llama `Tokens.qml`, no `Theme.qml`** — y se
  expone como `Theme` desde el `qmldir`. Pegasus exige `theme.qml` como
  entrada, y en macOS y Windows el filesystem es case-insensitive: `Theme.qml`
  y `theme.qml` son **el mismo archivo**. Verificado a lo bruto durante la
  implementación: un `echo > theme.qml` borró el contenido de `Theme.qml`.
  Esto **no** se convierte en un chequeo de `attract doctor`: en un filesystem
  case-insensitive el par colisionante no puede existir, así que no hay nada
  que detectar en el Mac ni en el gabinete — solo se vería en Linux, y el
  proyecto no tiene ninguna máquina Linux (ADR-0003). Vive como comentario en
  el encabezado de `Tokens.qml`, que es donde alguien lo va a buscar.
- **Aproximaciones a CSS que Qt 5.15 no tiene**, cada una con su comentario:
  `backdrop-filter` → rectángulo translúcido plano; `color-mix()` →
  `Theme.mix()`; `conic-gradient` → se deja solo el radial + linear (~95%
  visual); `mix-blend-mode` → `opacity`.
- **Sin dependencias nuevas.** Solo `QtQuick`, `QtQuick.Layouts` y —si el
  experimento lo habilita— `QtGraphicalEffects`, que es parte de Qt 5.15, no
  un paquete de terceros. El límite duro de dependencias aplica a
  `src/attract/`, pero el criterio vale igual acá: el gabinete es offline y
  Pegasus no se puede recompilar (ADR-0006).

## Riesgos

- **Los tres experimentos sin correr** (ver `spec.md` §Riesgos). El de rutas
  bloquea `Paths.qml`, que bloquea `GameData.qml`, que bloquea la mitad de las
  dos pantallas. Es el primero de la lista de `tasks.md` por eso.
- **Subcarpetas y singletons en un theme de Pegasus** — se responde en el
  paso 1, con el esqueleto vacío. Salida documentada arriba.
- **Rendimiento del rail.** El prototipo escala y anima ocho tarjetas; la
  librería real tiene cientos. Si `Row` + `Repeater` no alcanza, la salida es
  `ListView` con `orientation: ListView.Horizontal`, que recicla delegates. No
  se optimiza antes de medir, pero el layout se escribe de forma que cambiarlo
  no arrastre el resto.
- **Fidelidad medida a ojo.** No hay forma de diffear el theme contra el
  prototipo automáticamente. La verificación es abrir los dos al lado y
  comparar — por eso el canvas fijo (ADR-0016) importa: hace que la
  comparación tenga sentido.
