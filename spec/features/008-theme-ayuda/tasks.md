# 008 · Overlay de ayuda — Tareas

_Checklist accionable derivada del `plan.md`._

## 1 · El overlay

- [x] `overlays/HelpOverlay.qml` — panel de dos columnas, `min(880, 92%
      ancho)` × hasta 86% del alto, gradiente/borde/sombra del prototipo.
- [x] Columna izquierda: "GUÍA RÁPIDA" + 8 botones de paso, activo
      resaltado con accent, click salta directo a ese `helpIdx`.
- [x] Columna derecha: header (título + "Paso N de 8" + cerrar), body
      scrolleable (título del paso, intro, callouts `▸`, bloque de código
      condicional), footer (`‹ Anterior`/`Siguiente ›` atenuados en los
      extremos).
- [x] `readonly property var pasos` — los 8 objetos con texto **literal**
      de `design_handoff_help/Pegasus Game Detail.dc.html:796-809`.
- [x] `Keys.onPressed`: Izquierda/Derecha mueven `helpIdx` (clamp, sin
      wrap), `api.keys.isCancel` cierra.
- [x] Sin escuadras HUD ni scanlines (eso es de `CheatsOverlay`, no de este
      overlay).

## 2 · Disparadores

- [x] `LibraryScreen.qml`: `signal abrirAyuda()` + `Boton` `?` (30×30,
      glass) junto al reloj. No se suma al ciclo `accion`.
- [x] `DetailScreen.qml`: mismo `signal abrirAyuda()` + mismo `Boton`,
      junto al texto de colección/año. No se suma al ciclo `foco`.

## 3 · `theme.qml`

- [x] `Loader id: ayuda`, `fondo: root.pantalla === "detail" ? detalle :
      libreria`.
- [x] `libreria.onAbrirAyuda` y `detalle.onAbrirAyuda` → `ayuda.active =
      true`.
- [x] `&& !ayuda.active` sumado a `visible`/`focus` de **ambas** pantallas.

## 4 · Verificación contra Pegasus real

**Pendiente — necesita el gabinete o el Mac con Pegasus corriendo.**

| Caso | Qué tiene que pasar |
|---|---|
| Disparador en Librería | Click en `?` junto al reloj abre el overlay |
| Disparador en Detalle | Click en `?` junto a colección/año abre el **mismo** componente |
| Nav de pasos | Click en cualquiera de los 8 salta directo, no solo secuencial |
| Navegación con flechas | Izquierda/Derecha mueve `helpIdx` con el overlay abierto, sin ciclar en los extremos |
| Footer | `‹ Anterior`/`Siguiente ›` atenuados y no clicables en paso 1 y paso 8 |
| Contenido variable | Pasos sin bullets/código (3 y 8) no rompen el layout ni saltan de tamaño |
| Cierre | Escape/Backspace cierra y devuelve el foco a la pantalla que lo abrió |
| Layout | Legible sin recortes a 1280×720, comparado contra las medidas del prototipo |
| No invade el foco existente | El ciclo `accion` de Librería y `foco` de Detalle siguen intactos (el ícono no es un target de gamepad) |

## 5 · Cierre

- [x] `make test` y `make doctor` en verde (70 passed/2 skipped, 0 errores).
- [ ] Mover `008` a "Hecho" en `../../constitution/roadmap.md` — recién
      cuando §4 esté verificado.
- [ ] Anotar en `docs/plataforma-pegasus.md` cualquier hallazgo nuevo.
