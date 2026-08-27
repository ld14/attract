# 018 · Galería de imágenes y videos — Tareas

_Checklist accionable derivada del `plan.md`. Tareas pequeñas y concretas;
marca `[x]` al completarlas._

## Contrato y validador (se hace primero: es lo único testeable sin Pegasus)

- [x] Crear [`ADR-0030`](../../decisions/0030-contrato-gallery-data-json.md) —
      `gallery` extiende el contrato de `data.json` (ADR-0015) **y** el del
      paquete COINDOOR (ADR-0027), que no lo nombraba. `proposed`.
- [ ] `src/attract/doctor.py` — validar `gallery` dentro de `chk_data_contrato`.
      Hecho cuando: `gallery` que no es lista → error; ítem que no es objeto →
      error; `file` que no es string → error; `label` ausente o vacío → error;
      extensión fuera de `.png/.jpg/.jpeg/.webp` y `.mp4/.webm/.mov` → error.
      Todos nombrando el índice (`gallery[2]`), como ya hace `mags[i]`.
- [ ] `src/attract/doctor.py` — existencia en disco, calcada de
      `_chk_manual_doc()`. Hecho cuando: `file` no vacío que no existe en
      `media/<set>/_gallery/` → **error**; `file: ""` → **aviso** con el `label`
      en el mensaje, para que se lea como pendiente y no como rotura. Ojo:
      `chk_data_contrato` hoy solo tiene `falla()` (que es `rep.error`), así que
      el aviso necesita un `avisa()` al lado usando `rep.aviso`
      (`doctor.py:55`, precedente `chk_mags_ref`), y el caso `file: ""` se
      evalúa **antes** que la regla de extensión.
- [ ] Verificar contra el paquete real: instalar
      `files_install/final-fight.coindoor.zip` con `attract import` y correr
      `attract doctor`. Hecho cuando: las ocho piezas declaradas pasan sin
      errores. Es la prueba de que el contrato validado es el que el productor
      emite y no uno inventado — y de paso que el preflight de `import`
      (`instalar.py:109-124`, que llama al mismo `chk_data_contrato`) no empieza
      a rechazar paquetes válidos.

## Fixtures

- [ ] `fixtures/arcade/media/dino/_gallery/` — dos PNG **generados** (~2 KB, con
      su número impreso, misma excepción que las páginas de revista) y el
      `gallery` correspondiente en `data.json` con **tres** piezas: dos con
      archivo y una con `file: ""`. **Sin video**: `fixtures/` no tiene ni un
      archivo de video y no se le suma uno (la pieza `vid` se verifica contra
      `library/`). Así `dino` queda con cinco piezas y cero videos, que es
      además el caso de conteo en cero del subtítulo. Hecho cuando: `make doctor`
      pasa con un AVISO —el de la pieza vacía— y cero errores.
- [ ] Anotar la excepción de fixture no vacío en `CLAUDE.md` §Reglas de trabajo,
      junto a las dos que ya están. Hecho cuando: el bloque de excepciones
      vigentes nombra los PNG de `_gallery/` y por qué (con todo en 0 bytes el
      visor no muestra nada y no hay nada que comprobar).

## Theme

- [ ] `core/Paths.qml` — `galeriaDe(game)` → `<base>_gallery/`, `""` sin base.
      Hecho cuando: es idéntica a `manualDe()` salvo el nombre de la carpeta.
- [ ] `core/GameData.qml` — `galeria` (la composición del ADR-0030, **ya
      resuelta a URLs**, con piezas `{ tipo, src, label }`), `hayGaleria`,
      `galeriaVideos`, `galeriaImagenes`. Hecho cuando: un juego **sin**
      `gallery` igual devuelve sus assets nativos en el orden fijo; un asset
      ausente se saltea sin dejar hueco; un ítem con extensión desconocida se
      descarta en vez de romper (mismo criterio que `gruposCheats` con un grupo
      mal formado); una galería de 1 a N piezas curadas conserva el orden del
      array; y los conteos dan 1 video + 12 imágenes en Final Fight, 1 + 4 en
      Donkey Kong, 1 + 3 en Metal Slug y 0 + 5 en el fixture `dino`.
- [ ] `screens/ExtrasList.qml` — las tres tarjetas pasan a `width: 200` y
      `_anchoSubtitulo` a 13 (ver `plan.md` §Decisiones: tres de 250 chocan con
      la columna derecha según el largo del veredicto). Hecho cuando: la fila
      mide 628 y entra sin tocar `derecha` en un juego con reseña larga.
- [ ] `screens/ExtrasList.qml` — `_subCheats()` gana un tercer nivel más corto
      (`"6 entradas"`). Hecho cuando: con el presupuesto nuevo la tarjeta de
      Hacks no cae a `"Ver detalle"` en los juegos de `library/`. Es daño
      colateral del recorte de ancho, no parte de la galería: sin esto la
      feature empeora una tarjeta que hoy anda.
- [ ] `screens/ExtrasList.qml` — tarjeta "Galería" **primera** en el modelo, con
      glifo `▣` y `_subGaleria()`. Hecho cuando: el detalle
      (`"1 video  ·  5 imágenes"`, separador `"  ·  "` como las otras dos) se
      muestra si entra; si no, cae al resumen `"N piezas"`; el plural sale bien
      en los dos niveles (`"1 video"`, `"3 videos"`, `"1 imagen"`,
      `"5 imágenes"`, `"1 pieza"`, `"13 piezas"`); un conteo en cero no imprime
      su parte (`dino` no dice `"0 videos"`); y sin galería la tarjeta dice
      `"No Disponible"`.
- [ ] `screens/DetailScreen.qml` — `_targets: 6`, ramas de aceptar en 3/4/5,
      `ExtrasList.foco` **sin cambios** (`root.foco - 3`), y el botón de volver
      con `texto: "BIBLIOTECA"`. Hecho cuando: aceptar sobre cada una de las tres
      tarjetas abre la suya. Depende de: la tarea de `ExtrasList`.
- [ ] `overlays/GalleryOverlay.qml` — el modal. Hecho cuando: dibuja encabezado
      (chip `VIDEO`/`IMAGEN` + `label` + título del juego + `"3 / 6"` + ✕),
      escenario, flechas ‹ › **solo con `total > 1`**, riel y leyenda propia;
      desenfoca el `fondo` que recibe, como `CheatsOverlay`; y `Keys` cubre ◄ ►
      con wrap aritmético y `isCancel` para cerrar.
- [ ] `overlays/GalleryOverlay.qml` — los tres renders de pieza. Hecho cuando:
      `img` con archivo entra completa sin recorte; `vid` con archivo reproduce
      **con controles**, dentro de un `Loader` con `MediaPlayer` + `VideoOutput`
      propios (ADR-0029); y `src: ""` cae al placeholder rayado 16:9 **sin que
      se construya ningún componente con `source`** (§7).
- [ ] `overlays/GalleryOverlay.qml` — anclajes del pie. Hecho cuando: el riel
      se ancla a `leyenda.top` y la leyenda al borde real de la pantalla, sin
      ningún número de clearance escrito a mano (§3).
- [ ] `theme.qml` — `Loader { id: galeria }`, la rama `"galeria"` en
      `onAbrirExtra`, `piezas: detalle.datosDelJuego.galeria` y
      `fondo: detalle` (mismo cableado que `trucos`), y `!galeria.active` en el
      `focus` del detalle. Hecho cuando: con el modal arriba, ◄ ► no mueve el
      foco del detalle de abajo.

## Verificación (necesita Pegasus corriendo — `make theme`)

- [ ] Recorrer el detalle de `dino` con ◄ ►: el orden es
      `[JUGAR] → [video] → [carrusel] → [Galería] → [Hacks] → [Manual]`, y
      aceptar sobre Hacks abre **Hacks**.
- [ ] Abrir la galería: la leyenda dice `◄ ► Imagen / video   B / Esc Cerrar`
      y nada más.
- [ ] Mirar el riel con el modal abierto: ninguna miniatura queda tapada por la
      leyenda.
- [ ] Pasar por las cinco piezas de `dino` con ◄ ► y verificar el **wrap** en
      las dos direcciones. La pieza vacía muestra el placeholder; la marquesina
      de 0 bytes cae al mismo placeholder sin cortar el recorrido.
- [ ] La pieza `vid` se verifica en `library/`, no en el fixture: abrir la
      galería de **Final Fight** y llegar a su video (muestra imagen y tiene
      controles), después salir, abrir la de **otro juego** y llegar al suyo —
      los dos muestran imagen (ADR-0029). En Final Fight, además, el riel tiene
      las trece piezas y el contador llega a `13 / 13`.
- [ ] Revisar el log de Pegasus después de abrir y cerrar la galería tres veces:
      **cero errores de carga de recurso** (§7) y cero paneles de video vacíos
      (ADR-0029). El `updateVideoFrame called without AVPlayerLayer` es ruido
      conocido y no cuenta (`docs/plataforma-pegasus.md` §QtMultimedia).
- [ ] Mirar la fila de CONTENIDO EXTRA en un juego con **reseña larga**: las tres
      tarjetas entran y ninguna pisa la columna derecha (`plan.md` §Decisiones).
- [ ] Abrir el detalle de un juego **sin** galería: la tarjeta está, apagada,
      dice "No Disponible" y aceptarla no hace nada.

## Cierre

- [ ] Validar contra todos los criterios de aceptación de `spec.md`.
- [ ] `make test` en verde (los tests nuevos de `gallery` en
      `tests/test_doctor.py`: contrato, archivo faltante, `src: ""` como aviso).
- [ ] `make doctor` y `make doctor-lib` sin errores nuevos.
- [ ] Documentar `gallery` en `docs/CONVENCION.md` §1 (la tabla de campos) y en
      §2.3 (qué muestra la tarjeta sin galería).
- [ ] Sumar `_gallery/` al bloque de estructura de `media/<set>/` en
      `spec/constitution/tech-stack.md` (~línea 86, donde ya están `data.json` y
      `_manual/`), al pasar el ADR-0030 a `accepted`.
- [ ] Actualizar el índice de ADRs de `CLAUDE.md` (dice "0001-0025, 21
      vigentes"; van hasta 0030). Es una línea y ya se está tocando ese archivo
      por la excepción de fixtures.
- [ ] Avisar a COINDOOR de los `label` de basura: `final-fight.coindoor.zip`
      trae `"label": "url-10"` en la última pieza, un placeholder filtrado del
      scraping. `doctor` puede exigir que no esté vacío, no que diga algo.
- [ ] Mover la feature a "Hecho" en `../../constitution/roadmap.md`.
