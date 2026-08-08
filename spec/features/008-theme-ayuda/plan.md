# 008 · Overlay de ayuda — Plan

_Cómo se implementa lo descrito en `spec.md`. Respeta `constitution/`._

## Enfoque

Mismo mecanismo `Loader`-sobre-fondo-borroneado que `overlays/
CheatsOverlay.qml` (007) y `overlays/DocumentViewer.qml` (006), no
`QtQuick.Controls.Popup` — el theme no importa `QtQuick.Controls` en ningún
archivo; todo corre sobre `QtQuick 2.0`/`QtGraphicalEffects 1.0` a propósito
(ver comentario de `ui/Seccion.qml` sobre por qué se evita todo lo que no
esté verificado contra este binario de Pegasus). `Popup` sería una
superficie nueva sin precedente; `Loader` ya resuelve exactamente esto.

**Diferencia con los overlays existentes:** el contenido es fijo (igual que
el intento anterior) pero el layout es de **dos columnas**, no una lista
scrolleable de secciones — nav de pasos + panel de contenido. Y se abre
desde **dos pantallas**, no solo Librería.

```
overlays/HelpOverlay.qml      panel de dos columnas + los 8 pasos
screens/LibraryScreen.qml     icono "?" junto al reloj (editado)
screens/DetailScreen.qml      icono "?" junto a colección/año (editado)
theme.qml                     Loader + fondo dinamico segun pantalla (editado)
```

## Implementación

### 1. `overlays/HelpOverlay.qml` (nuevo)

Valores tomados de `design_handoff_help/Pegasus Game Detail.dc.html:456-495`:

- `FastBlur` + scrim `rgba(5,6,9,.9)` sobre `fondo` (patrón ya usado).
- Panel: `width: Math.min(880, parent.width*0.92)`, `height: Math.min(
  parent.height*0.86, contenido natural)`, gradiente `#0e1118→#0a0c11`,
  borde `rgba(255,255,255,.1)`, radio 16, sombra grande. Sin escuadras HUD
  ni scanlines — ese lenguaje visual es de `CheatsOverlay`/tablero de
  arcade, este overlay es un manual, más limpio (fiel al prototipo).
- **Columna izquierda** (`width: 220`, fondo `rgba(255,255,255,.03)`, borde
  derecho `rgba(255,255,255,.08)`): título "GUÍA RÁPIDA" (mono 10px,
  letterspacing .16em, `#6a7081`) + `Repeater` de 8 botones
  (`readonly property var pasos`). Activo: fondo `accent`, texto `#07080c`
  bold. Inactivo: transparente, `#aeb3c0`. `onClicked` fija `helpIdx = i`
  directo.
- **Columna derecha** (`flex`, `ColumnLayout`-like con anchors):
  - Header: título "Cómo cargar un juego nuevo" + "Paso N de 8" (mono 11px
    `#6a7081`) a la izquierda; botón `✕` (`Boton`, 36×36 radio 9) a la
    derecha. Borde inferior `rgba(255,255,255,.08)`.
  - Body en `Flickable`: título del paso (Chakra Petch 700 22px, color
    `accent`), intro (Sora 15px/1.6, `#c4c8d4`), `Repeater` de tarjetas
    callout (`▸` accent + Sora 14px/1.55 `#dfe3ec`, fondo
    `rgba(255,255,255,.03)`, borde `rgba(255,255,255,.07)`, radio 10), y si
    `pasos[helpIdx].codigo !== ""` un bloque mono `#0a0c11`/borde/radio10,
    texto `#8fd6a8`, `wrapMode: Text.WordWrap`.
  - Footer: `‹ Anterior`/`Siguiente ›`, `opacity: .35` + sin `MouseArea`
    activa en los extremos (`helpIdx === 0` / `helpIdx === pasos.length-1`).
- `readonly property var pasos: [...]` — los 8 objetos, texto copiado
  **literal** de `design_handoff_help/...html:796-809` (ya en español,
  terminado). No se redacta de nuevo.
- Props: `accent`, `fondo` (Item a desenfocar).
- `Keys.onPressed`: `Qt.Key_Right`/`Qt.Key_Left` mueven `helpIdx` (clamp
  0..7, sin wrap — el prototipo los deshabilita en los extremos, no cicla);
  `api.keys.isCancel` cierra.

### 2. `screens/LibraryScreen.qml`

- `signal abrirAyuda()`.
- `Boton { texto:""; glifo:"?"; variant:"glass"; implicitWidth:30;
  implicitHeight:30; onActivado: root.abrirAyuda() }` en el `Row` derecho de
  `barra`, después del reloj.
- **No** se suma al ciclo `accion` (JUGAR/VER DETALLE) — decisión de
  `spec.md` §Fuera de alcance: el prototipo abre esto solo con click.

### 3. `screens/DetailScreen.qml`

- Mismo `signal abrirAyuda()`.
- Mismo `Boton`, agregado al `Row`/`Item` de `barra` a la derecha del texto
  de colección/año (línea 61-76) — hoy ese texto está solo anclado a
  `right: parent.right`; pasa a compartir un `Row` con el nuevo botón.
- No se suma al ciclo `foco` (0..4 de targets) — mismo criterio que arriba.

### 4. `theme.qml`

- `Loader id: ayuda`, mismo patrón que `trucos`:
  ```qml
  sourceComponent: HelpOverlay {
      accent: root.accent
      fondo: root.pantalla === "detail" ? detalle : libreria
      focus: true
      onCerrar: ayuda.active = false
  }
  ```
- `libreria.onAbrirAyuda` y `detalle.onAbrirAyuda` → `ayuda.active = true`.
- Sumar `&& !ayuda.active` a `visible`/`focus` de **ambas** pantallas
  (`libreria` y `detalle`) — el intento anterior solo lo hacía en Librería.

## Decisiones

- **Sin escuadras HUD ni scanlines.** Ese lenguaje es específico del
  overlay de trucos ("tablero de comandos de arcade"); el prototipo de
  ayuda es un panel limpio de dos columnas, sin esa estética. Copiar el
  lenguaje visual de trucos sería inventar, no seguir la spec.
- **`fondo` cambia según `root.pantalla`.** Mismo patrón que `root.accent`
  ya usa (línea 42-43 de `theme.qml`) para resolver "depende de dónde
  estemos parados" sin duplicar el `Loader`.
- **Sin atajo de teclado para abrir, con atajo para cerrar y navegar.** Es
  exactamente lo que hace el prototipo (`onKey`) — no más, no menos.

## Riesgos

- **`Flickable` + footer con altura variable.** El body tiene contenido de
  longitud distinta por paso (algunos sin bullets ni código, como el paso 3
  y el 8) — el panel no debe saltar de tamaño de forma brusca entre pasos.
  Se fija `height` del panel al abrir (no recalcula por paso) para evitar
  ese salto; se verifica en pantalla.
- **El ícono `?` en la barra de `DetailScreen` reordena layout existente**
  (el texto de colección/año hoy ancla `right: parent.right` solo). Cambio
  chico pero hay que revisar que no se superponga con `GALERIA` a la
  izquierda en anchos raros.
