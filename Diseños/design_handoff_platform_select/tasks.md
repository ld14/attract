# 025 · Selector de plataforma — Tareas

_Checklist accionable derivada del `plan.md`._

## 1 · Datos (`core/`)

- [ ] `core/Platforms.qml` — `lista` con `TODAS` + una entrada por
      `api.collections`. Hecho cuando: con los fixtures instalados, la lista tiene
      `api.collections.count + 1` entradas y la 0 es `TODAS`.
- [ ] `core/Platforms.qml` — lectura de `library/_platforms/<dir>/data.json`
      (`XMLHttpRequest` + `try/catch` + cache por `dir`). Hecho cuando: un
      `data.json` ausente y uno corrupto dan acento por defecto sin romper la
      pantalla, y una segunda pasada del foco no repite la lectura.
- [ ] Conversión de acentos `oklch(0.74 0.16 h)` → hex en `core/`. Hecho cuando:
      los diez acentos del handoff se ven iguales que en el prototipo.
- [ ] `core/PlatformVideos.qml` — lista de juegos con `media/video.mp4` y
      `siguiente()` aleatorio sin repetir el actual. Hecho cuando: con una
      plataforma de 3 videos, diez llamadas devuelven los 3 y nunca el actual;
      con 0 videos expone `vacio: true`.

## 2 · Átomos (`ui/`)

- [ ] `ui/DissolvePanel.qml` — fundido por los 4 bordes con `Canvas`, sin marco.
      Hecho cuando: sobre un video en movimiento **no** se ve ninguna línea de 1px
      en ningún borde (es el bug que motivó descartar las máscaras).
- [ ] `ui/KeyLegendRow.qml` — pills de tecla + etiqueta, con el acento recibido y
      los rótulos de teclas configuradas. Hecho cuando: las cuatro entradas del
      selector y las tres del catálogo se dibujan con las medidas del handoff.

## 3 · Pantalla (`screens/`)

- [ ] `screens/PlatformSelectScreen.qml` — barra superior (wordmark, etiqueta,
      logo opcional 104×30, total, reloj). Hecho cuando: sin `logo.png` no queda
      hueco ni espacio reservado.
- [ ] Panel de video `440×248` en `left:72 top:190`, por **debajo** de emblema,
      textos, flechas, barra, leyenda y catálogo. Hecho cuando: en una plataforma
      con video, ningún texto queda tapado ni atenuado.
- [ ] `MediaPlayer` + `VideoOutput` en cadena aleatoria, `muted`/`loop` seteados
      imperativamente. Hecho cuando: se verifica en runtime que ambas propiedades
      leen `true`, no se oye audio, y al terminar un clip arranca otro juego.
- [ ] Emblema `left:38% → right:0`, `contain`, alineado a la derecha, fundido por
      radial + lateral. Hecho cuando: no hay canto duro contra la columna de texto.
- [ ] Columna de texto: hueco reservado `440×248` + `margin-bottom:14`, nombre
      Chakra Petch itálica 52px, línea de conteo a `10px`. Hecho cuando: el nombre
      **no** se mueve entre una plataforma con video y una sin video.
- [ ] Flechas `40×120` clickeables + navegación `←`/`→` con wrap circular. Hecho
      cuando: `→` en la última vuelve a la primera.
- [ ] `X` salta a plataforma aleatoria; `api.keys.isAccept` abre el catálogo;
      `api.keys.isCancel` sale. Hecho cuando: responde al joystick del gabinete,
      no solo al teclado.

## 4 · Catálogo filtrado

- [ ] `screens/LibraryScreen.qml` acepta `plataforma` y filtra. Hecho cuando: con
      una plataforma elegida no aparece ningún juego de otra.
- [ ] Cabecera: `◄ PLATAFORMAS`, `CATÁLOGO · <AB>`, subtítulo de conteo, pill
      `FILTRO · <AB>` / `SIN FILTRO`. Hecho cuando: en TODAS dice `SIN FILTRO` y
      cada tarjeta muestra su propia plataforma en el badge.
- [ ] Estado vacío con `library/<dir>/<carpeta-juego>/` y `make doctor-lib`. Hecho
      cuando: una colección de cero juegos muestra el panel y no una grilla vacía.
- [ ] Volver conserva la plataforma enfocada. Hecho cuando: entrar en la 5.ª
      plataforma, abrir y cancelar deja el foco en la 5.ª.

## 5 · Ruteo

- [ ] `theme.qml` — `screen: "platforms" | "library" | "detail"`, inicial
      `"platforms"`, y la plataforma elegida guardada en el nivel de `theme.qml`.
      Hecho cuando: Pegasus abre en el selector y el CRT (`z:80`) sigue por encima
      de todo, incluido el catálogo.

## Tests / verificación

- [ ] Caso feliz: fixtures instalados → carrusel completo, acepta, filtra, vuelve.
- [ ] Caso límite: **cero** assets de plataforma cargados → la pantalla se ve
      terminada (sin logo, sin emblema, sin video, sin huecos visibles).
- [ ] Caso límite: plataforma de 0 juegos → estado vacío.
- [ ] Caso de fallo: `data.json` de plataforma corrupto → acento por defecto,
      pantalla completa, nada a medio pintar.
- [ ] Invariante: ninguna capa de video queda por encima de texto o de un dato.
- [ ] Comparación a ojo contra
      `design_handoff_platform_select/Preselector Plataforma.dc.html` al 100%.

## Cierre

- [ ] Validar contra todos los criterios de aceptación de `spec.md`.
- [ ] ADR si la fuente de los assets de plataforma (`library/_platforms/`) se
      resuelve distinto de lo planeado.
- [ ] Actualizar `docs/CONVENCION.md` si `library/_platforms/` entra como
      estructura oficial, y `spec/constitution/roadmap.md` al cerrar.
- [ ] `make theme` y verificación contra Pegasus real (no solo en el harness).
