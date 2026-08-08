# 008 · Overlay de ayuda — Spec

**Estado:** especificada, sin implementar.

## Qué hace

Un overlay **"Cómo cargar un juego nuevo"**, de dos columnas (nav de 8 pasos
+ contenido), accesible con un ícono "?" junto al reloj en la barra
superior — visible en **Librería y Detalle**. Explica en lenguaje simple
dónde va el ROM, las imágenes, el video, la revista, los datos del juego, la
sinopsis y cómo validar, con el mismo componente reutilizable en cualquier
pantalla (no duplicado).

## Por qué

Recrea, en QML, un diseño de referencia de alta fidelidad ya provisto:
[`design_handoff_help/README.md`](../../../design_handoff_help/README.md) +
[`Pegasus Game Detail.dc.html`](../../../design_handoff_help/Pegasus%20Game%20Detail.dc.html)
(el estado `helpOpen` del prototipo). Colores, tipografía y layout son
**finales**, tomados del prototipo (líneas 456-495 del `.dc.html`).

Reemplaza un intento anterior sin spec visual (revertido) que no coincidía
con lo esperado.

**Contenido, ampliado a pedido (2026-08-04):** el texto de los 8 pasos parte
del prototipo (líneas 796-809 del `.dc.html`) pero el prototipo explica el
criterio y omite el dato más operativo — el nombre **exacto** de cada
archivo y la ruta **exacta** de cada carpeta (nunca decía, por ejemplo, que
el archivo se llama literalmente `data.json`). Se sumaron bullets y bloques
de código con esos datos, citando `docs/guides/cargar-un-juego-nuevo.md` y
`docs/CONVENCION.md` — sin tocar el texto original del handoff, solo
completando lo que un operador necesita para que el sistema reconozca lo que
cargó, no solo entender la idea general.

## Contenido (8 pasos, texto literal del prototipo)

1. **El ROM** — dónde va, `python -m attract.ingest library/arcade/dino.zip
   library/arcade`.
2. **Las imágenes** — `boxFront`/`marquee`/`poster`/`video.mp4` sueltos,
   cadena de fallback.
3. **El video** — mismo lugar, opcional.
4. **La revista** — carpeta compartida, referenciada por `ref`, no copiada.
5. **Datos del juego** — accent, trucos, reseña, manual — todo opcional.
6. **Sinopsis** — archivo aparte, se aplica con `python -m attract.synopsis
   dino library/arcade`.
7. **Validar todo** — `make doctor-lib`.
8. **Si algo falla** — leer el mensaje del validador.

## Criterios de aceptación

- [ ] El ícono "?" (30×30, junto al reloj/año) abre el overlay desde
      Librería y desde Detalle, mismo componente.
- [ ] Nav de 8 pasos a la izquierda; click en cualquiera salta directo a
      ese paso (no solo secuencial).
- [ ] Columna derecha muestra título del paso, intro, callouts con `▸`, y
      bloque de código monospace cuando el paso lo tiene.
- [ ] `‹ Anterior`/`Siguiente ›` atenuados y no interactivos en el primer y
      último paso respectivamente.
- [ ] Izquierda/Derecha navega entre pasos con el overlay abierto.
- [ ] Escape/Backspace cierra y devuelve el foco a la pantalla de origen
      (Librería o Detalle, la que lo abrió).
- [ ] Layout legible sin recortes a 1280×720.

## Fuera de alcance

- **Atajo de teclado/gamepad para abrir.** El prototipo (`onKey`, líneas
  816-843 del `.dc.html`) solo abre con click en el ícono. Se respeta tal
  cual — quien carga juegos ya está frente a un teclado/mouse corriendo
  comandos. Si se pide después, es un cambio acotado sobre el mismo overlay.
- **Editar contenido desde el theme.** Es de solo lectura, como el resto.
- **Buscar/filtrar dentro de la ayuda.**

## Riesgos

- **`design_handoff_help/` no tiene `support.js`** (el runtime que resuelve
  el templating del prototipo) — no renderiza interactivo en un navegador.
  No bloquea: el HTML/CSS estático y la clase `Component` con todo el
  estado están completos en el archivo y son la fuente real.
- **Contenido puede desincronizarse de `docs/guides/cargar-un-juego-
  nuevo.md`.** Mismo criterio que la versión anterior: audiencias y niveles
  de detalle distintos a propósito.
