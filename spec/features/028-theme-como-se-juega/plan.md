# 028 · Cómo se juega — theme — Plan

_Cómo se implementa lo descrito en `spec.md`. Respeta `constitution/`._

## Enfoque

Dos piezas nuevas más cambios acotados a lo que ya existe. **No se toca la
frontera de responsabilidad**: `core/GameData.qml` sigue siendo el único que
parsea `data.json` (le suma `guia`, degradando a "sin guía" igual que ya
degrada el resto); `core/Paths.qml` suma las rutas del perfil y del
artefacto; el theme no interpreta ninguna configuración de MAME/DOSBox — eso
ya lo resolvió [027](../027-como-se-juega/spec.md).

`screens/ExtrasList.qml` ya existe con tres tarjetas (Galería, Hacks,
Manual): gana una cuarta **primera**, sin duplicar el componente. El
subtítulo por tarjeta (hoy adentro de cada una) se saca y pasa a una única
línea compartida debajo de la fila — decisión 8b de
`docs/como-se-juega.md`, que además dice explícitamente "se respeta el
diseño actual de las tarjetas" (decisión 7): el bosquejo del handoff original
es solo referencia de orden, el chrome visual (ícono, foco que levanta 3px)
es el que ya está construido. **El ancho de 200px de esta sección quedó
en 145px** tras la verificación en Pegasus real (2026-09-29): con cuatro
tarjetas de 200px la fila pisaba la columna derecha. El tamaño final
(145×45px) y todo el historial de ajuste están en
[`tasks.md`](tasks.md) §2 y §Cierre — esta sección conserva el motivo
original (por qué el subtítulo se comparte), no las medidas.

## Árbol

```
themes/attract/
├─ core/
│  ├─ GameData.qml         (mod) `guia` normalizado igual que `gruposCheats`/`galeria`
│  ├─ Paths.qml             (mod) `perfilGabinete()` (dentro del theme) y
│  │                              `controlesDe(coleccion)` (artefacto en library/)
│  └─ Gabinete.qml          (nuevo) lee `core/gabinete.json` (import estático,
│                                  no XHR: vive DENTRO del theme, siempre
│                                  presente, no depende de la librería)
├─ screens/
│  ├─ ExtrasList.qml        (mod) 4 tarjetas, subtítulo compartido
│  └─ DetailScreen.qml      (mod) `_targets` 7→8, nuevo índice de foco
├─ overlays/
│  └─ GuideOverlay.qml      (nuevo) título, diagrama, objetivo, primeros
│                                  pasos, reglas, salida, JUGAR/VOLVER,
│                                  accesos a Hacks/Manual
├─ ui/
│  └─ ControlDiagram.qml    (nuevo) `Rectangle`+`Text`+`Repeater`, sin
│                                  `QtQuick.Shapes`
└─ theme.qml                (mod) Loader `guia`, hook de ADR-0038 en `lanzar()`
   y en el arranque
```

## Implementación

1. `core/Gabinete.qml` — singleton-como (mismo patrón de import estático que
   `Tokens.qml`, no XHR): expone `jugadores`, `perifericos`, `salida` tal
   como los define `themes/attract/core/gabinete.json` (027). Sirve incluso
   si `attract controles` nunca corrió — es lo que permite la ayuda general
   y el diagrama sin correspondencia verificada.
2. `core/Paths.qml` — `controlesDe(coleccion)` arma la ruta de
   `_controles.json` con el mismo patrón que `dirColeccionDe`. 404 no es
   error (mismo criterio que `PlatformData.qml`): sin artefacto, todo
   control se trata como no verificado.
3. `core/GameData.qml` — `guia` normalizado a partir de `data.json.guia`
   (ADR-0037), con degradación total si el bloque no parsea (mismo
   criterio que el resto del archivo: un JSON roto apaga TODO `data.json`,
   no solo `guia` — es un costo ya asumido y documentado en ADR-0036).
4. `screens/ExtrasList.qml` — el `Repeater` de tarjetas gana un cuarto
   elemento primero (`tipo: "guia"`, sin `sub` — decisión 8: "sin
   subtítulo"). El subtítulo por tarjeta se saca del `Column` de cada
   tarjeta y se reemplaza por un `Text` compartido debajo de la `Row`, que
   muestra `_subDe(root.foco)` — la misma lógica de acortado
   (`_subGaleria`/`_subCheats`/`_subManual`, más una nueva para `guia`) pero
   evaluada una sola vez, para la tarjeta enfocada. Con foco `-1` (nada
   enfocado) no se muestra nada, igual que hoy.
5. `screens/DetailScreen.qml` — `_targets` pasa de 7 a 8. Orden de foco:
   `[JUGAR, video, carrusel, Cómo-se-juega, Galería, Hacks, Manual,
   Favoritos]` → índices 0-7. `ExtrasList.foco` sigue siendo `root.foco - 3`
   (el offset no cambia, porque Cómo-se-juega entra en el mismo lugar que
   antes ocupaba el primer índice del `Repeater`). `abrirExtra("guia")` en
   `foco === 3`, corriendo una posición los demás (`galeria`→4, `cheats`→5,
   `manual`→6, favoritos→7).
6. `ui/ControlDiagram.qml` — recibe la lista de `acciones` (de `guia`) y el
   artefacto de correspondencia (de `Paths.controlesDe`), y por cada acción
   dibuja: si hay un control verificado, una posición resaltada del layout
   del perfil (`Repeater` sobre `Gabinete.jugadores[].botones`); si no,
   texto plano ("botón 2 del jugador 1"). "Sin uso" (posición que no
   corresponde a ninguna acción declarada) y "acción desconocida" (control
   lógico sin traducción conocida) se dibujan con dos estilos distintos
   (color/ícono), nunca el mismo estado visual para los dos casos.
7. `overlays/GuideOverlay.qml` — mismo patrón que `CheatsOverlay`/
   `GalleryOverlay` (recibe `datos`, `titulo`, `accent`, `fondo`, `focus`,
   emite `onCerrar`). Sin `guia` en `datos`, dibuja la ayuda general
   (`Gabinete.salida`, crédito/start genéricos) más el aviso "Sin guía
   específica para este juego" — la tarjeta **siempre** abre, nunca queda
   deshabilitada como Galería/Hacks/Manual sin contenido.
   - JUGAR dentro del overlay llama a `root.lanzar(game)` (el mismo punto
     de `theme.qml:573` que ya usa el botón JUGAR del detalle) — no un
     lanzamiento paralelo.
   - Accesos a Hacks/Manual: emiten `abrirHacksDesdeGuia()`/
     `abrirManualDesdeGuia()` en vez de activar el Loader directo, para que
     `theme.qml` sepa volver a la guía al cerrarlos (ver punto 8).
8. `theme.qml` —
   - Nuevo `Loader { id: guia; sourceComponent: GuideOverlay { ... } }`,
     mismo lugar que los demás overlays de contenido extra.
   - `onAbrirExtra`: `else if (tipo === "guia") guia.active = true;`
   - `property bool volverAGuiaAlCerrar: false` — lo ponen en `true` los
     handlers de `abrirHacksDesdeGuia`/`abrirManualDesdeGuia` antes de
     activar `trucos`/`visor`, y lo leen `onCerrar` de esos dos Loaders:
     si es `true`, reactivan `guia.active = true` en vez de solo cerrar. La
     tecla que cierra (`isCancel`) no dispara nada en la pantalla de abajo
     porque el `Loader` que se cierra sigue teniendo el foco hasta que
     termina su propio `onCerrar` — mismo mecanismo que ya evita el bug
     documentado en `docs/plataforma-pegasus.md` (Escape "comido" por
     Pegasus).
   - **ADR-0038**: `function lanzar(game)` escribe en `api.memory` la clave
     de contexto (colección, set, `detalleAbierto`, `guiaAbierta`) justo
     antes de `game.launch()`. `Component.onCompleted` del `theme.qml` raíz
     lee esa clave: si existe, salta el selector de plataforma
     ([026](../026-selector-plataforma/spec.md) gana el enganche), abre el
     detalle en el `set` guardado, y si `guiaAbierta` activa `guia.active`.
     Borra la clave apenas termina de restaurar.

## Decisiones

- **Restaurar todo el contexto, no solo la guía** — decisión del autor,
  2026-09-28. Ver [ADR-0038](../../decisions/0038-restaurar-contexto-al-volver-de-jugar.md).
- **El diagrama es `Rectangle`+`Text`+`Repeater`, nunca `QtQuick.Shapes`** —
  un `import` que no resuelve tumba el theme entero
  (`docs/plataforma-pegasus.md` §1), y el resto del theme ya evita imports
  nuevos por el mismo motivo.
- **El subtítulo compartido reemplaza al subtítulo por tarjeta** (decisión
  8b) — motivo medido, no estético: con 4 tarjetas de 200px + spacing 14 la
  fila mide 828px; el ancho disponible es el mismo que con 3
  (`ExtrasList.qml` ya documenta que 3×250 pisaba la columna derecha). Sin
  hueco para un subtítulo propio por tarjeta a ese ancho, se comparte una
  sola línea, que además es lo que pide `docs/como-se-juega.md`
  explícitamente. (El ancho final terminó en 145px, no 200 — ver la nota de
  la sección "Enfoque" — pero el motivo resuelto acá no cambió con eso.)
- **`Gabinete.qml` es import estático, no XHR** — el perfil vive dentro del
  theme (decisión de 027), así que no hace falta tolerar 404 ni cache: está
  siempre, igual que `Tokens.qml`.
- **JUGAR desde la guía reusa `root.lanzar()`**, no un segundo camino de
  lanzamiento — evita divergencia con el overlay de "lanzando" que ya cubre
  ese caso (`LaunchOverlay.qml`).

## Riesgos

- **El offset de foco entre `DetailScreen` y `ExtrasList` es fácil de
  romper** al insertar la cuarta tarjeta primero: se verifica con un test
  manual de recorrido completo (JUGAR→…→Favoritos→JUGAR) antes de dar por
  cerrada la Etapa E.
- **`volverAGuiaAlCerrar` es un solo booleano compartido** entre Hacks y
  Manual: si algún día se pudiera abrir Hacks Y Manual encadenados desde la
  guía (no lo pide la spec), un solo booleano no alcanzaría. Con el alcance
  actual (uno u otro, nunca los dos a la vez) es suficiente.
- **`ControlDiagram` sin ningún control verificado** (el estado de hoy,
  Etapa F sin correr) tiene que verse **completo e informativo igual** —
  todo texto plano, cero posiciones resaltadas. Se verifica contra
  `fixtures/` antes que contra `library/`, mismo criterio que 026.
