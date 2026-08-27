---
id: 0030
title: "La galería se compone de los assets nativos del juego más las piezas curadas de `_gallery/`, declaradas como `gallery` en `data.json`"
status: proposed
date: "2026-08-27"
supersedes: null
superseded-by: null
tags: [data, frontend]
---

# 0030 — `gallery`: assets nativos + piezas curadas

## Contexto

La feature [`018-theme-galeria`](../features/018-theme-galeria/spec.md) agrega una
galería de imágenes y videos por juego al detalle. Hoy el detalle muestra **un
solo** medio —el video de gameplay del panel de carátula, feature 006— y todo lo
demás que el juego ya tiene queda sin dónde mirarse entero.

**Este ADR se escribió dos veces.** La primera versión inventó un contrato
(`{k, src, label}`) sin mirar los paquetes que COINDOOR ya produce. Al abrirlos
resultó que **el contrato ya existía y era otro**. Lo que sigue documenta el
real, verificado el 2026-08-27 sobre los ocho paquetes de `files_install/`.

### Lo que COINDOOR ya emite

`final-fight.coindoor.zip` —el único de los ocho con galería, y el más reciente—
trae `media/_gallery/` con ocho archivos y **declara las ocho** en su
`data.json`. El array es de largo libre: **de 1 a N piezas**, y este extracto
muestra las tres primeras:

```json
"gallery": [
  { "file": "g001.png", "label": "Panel de control" },
  { "file": "g002.png", "label": "Placa PCB" },
  { "file": "g003.png", "label": "Gabinete" },
  ...
  { "file": "g010.jpg", "label": "url-10" }
]
```

Tres hechos que salen de ahí, no de una preferencia:

- La clave es **`file`**, no `src` — el mismo nombre que ya usa `manual[].file`
  ([`ADR-0021`](0021-manual-pdf-app-del-sistema.md)).
- **No hay campo de tipo.** El tipo sale de la extensión.
- **No hay ningún video dentro de `_gallery/`.** Los ocho paquetes traen el video
  como asset nativo (`media/video.mp4`), fuera de la carpeta.

### Lo que el sistema ya hace, sin haberlo diseñado

`attract import` **ya instala `_gallery/` correctamente**: copia el subárbol
`media/` entero preservando la ruta relativa (`src/attract/instalar.py:155`), así
que `media/_gallery/g001.png` aterriza en `media/<set>/_gallery/g001.png`. Salió
gratis, por la forma en que estaba escrito el copiado, no por una decisión.

### Lo que está ciego

`attract doctor` **no valida `gallery` ni `_gallery/`** (cero coincidencias en
`src/`): un `file` que no existe pasa en verde. Y
[`ADR-0027`](0027-contrato-paquete-import-coindoor.md), que fija el contrato del
paquete, **no menciona ninguna de las dos cosas** — el productor emite un campo
que el contrato del paquete no nombra.

### Los assets nativos que hay

Verificado sobre los ocho paquetes: `boxFront`, `logo`, `marquee`, `poster`,
`screenshot`, `video`. **No todos los juegos tienen todos** — Metal Slug no trae
`marquee`.

## Decisión

**La galería de un juego se compone de dos fuentes**, en este orden:

```
1. video          (asset nativo)          → "Gameplay"
2. screenshot     (asset nativo)          → "Captura"
3. gallery[]      (curado, orden del array, labels escritos a mano)
4. boxFront       (asset nativo)          → "Carátula"
5. poster         (asset nativo)          → "Póster"
6. marquee        (asset nativo)          → "Marquesina"
```

Primero lo que muestra el juego en movimiento, después lo curado, y al final el
arte de empaque y gabinete. Un asset ausente **se saltea**, no deja hueco.
`logo` queda afuera a propósito: es un recurso de interfaz (el título en PNG con
transparencia), no contenido que alguien quiera mirar a pantalla completa.

**El contrato de `gallery`** es el que COINDOOR ya emite:

| Campo | Regla |
|---|---|
| `gallery` | Lista de **1 a N** piezas, en el orden en que se muestran. Ausente y lista vacía son lo mismo: el juego no tiene piezas curadas |
| `file` | Nombre de archivo dentro de `media/<set>/_gallery/`. No es una ruta. `""` es un estado declarado válido |
| `label` | String no vacío. Se muestra en el encabezado del modal y dentro del placeholder |

**El tipo sale de la extensión**, con listas explícitas y sin adivinar:

- `.png` `.jpg` `.jpeg` `.webp` → imagen
- `.mp4` `.webm` `.mov` → video
- cualquier otra → **error de `doctor`**, y el theme la saltea

`attract doctor` valida la forma, que cada `file` no vacío exista en `_gallery/`
(**error** si no), y la extensión. Un `file: ""` sale como **aviso**.

Esto **extiende** a [`ADR-0015`](0015-contrato-data-json.md) (el contrato de
`data.json`) y a [`ADR-0027`](0027-contrato-paquete-import-coindoor.md) (el
contrato del paquete), sin reemplazar a ninguno — igual que
[`ADR-0023`](0023-manual-multiple-con-pestanas.md) hizo con `manual`.

## Alternativas consideradas

### A · Que la galería sea **solo** `_gallery/`, sin los assets nativos

- A favor: el contrato más simple de todos, cero duplicación, y la galería es
  exactamente lo que alguien curó.
- En contra: deja afuera todo lo que el juego ya tiene.
- **Descartada porque:** de los ocho paquetes reales, **siete no tienen
  `_gallery/`**. La tarjeta quedaría en "No Disponible" en 7 de 8 juegos, y el
  video de gameplay —que todos tienen— seguiría accesible solo desde el panel de
  carátula. La galería nacería vacía en casi toda la librería.

### B · Que la galería sea **solo** los assets nativos de Pegasus

- A favor: cero contrato nuevo, cero validación nueva, Pegasus los autodescubre.
- En contra: son de a uno por tipo, sin etiqueta ni orden propio.
- **Descartada porque:** no hay forma de declarar diez capturas ni de rotularlas.
  El espacio de nombres de assets es de Pegasus, así que `assets.captura2` es
  inventarle un nombre a algo que no es nuestro. **Nota:** esta alternativa está
  descartada como *fuente única*, pero **adoptada como fuente adicional** — es la
  mitad de la decisión de arriba.

### C · Un archivo aparte, `gallery.json`, junto a `data.json`

- A favor: no toca el contrato de `data.json`.
- En contra: sería la tercera lectura XHR por juego.
- **Descartada porque:** duplicaría el mecanismo entero de `core/GameData.qml`
  —cache compartido, protección contra respuestas desordenadas, degradación a
  "sin-datos"— por dos campos. Y COINDOOR **ya emite `gallery` dentro de
  `data.json`**: mover el campo obligaría a cambiar el productor para no ganar
  nada. `magazine.json` sí vive aparte, pero por un motivo que acá no aplica: la
  revista es una entidad **compartida entre juegos**
  ([`ADR-0024`](0024-contrato-magazine-json-v2.md)).

### D · Reusar `manual[]` declarando la galería como un documento más

- A favor: cero contrato nuevo, y el visor de documentos ya hojea con miniaturas,
  contador y flechas.
- En contra: `pages[]` son strings sueltos, sin tipo ni etiqueta.
- **Descartada porque:** no puede llevar un video ni una etiqueta por página, y
  `DocumentViewer` está construido para **leer texto escaneado** (zoom de seis
  pasos, paneo, barra de progreso para cientos de páginas). Nada de eso sirve
  para mirar una captura, y meter video obligaría a ramificar por tipo un
  componente de 660 líneas que hoy no sabe que existen los tipos. Además
  [`ADR-0023`](0023-manual-multiple-con-pestanas.md) ya le dio a `manual` la
  semántica de "documentos con pestañas".

### E · Un campo `k` explícito por pieza en vez de inferir por extensión

- A favor: el tipo queda declarado y no depende de una convención de nombres;
  un archivo mal nombrado no se renderiza mal.
- En contra: es un campo más que alguien tiene que escribir bien.
- **Descartada porque:** **COINDOOR no lo emite**, y agregarlo obligaría a
  cambiar el productor y a migrar los paquetes ya generados. La extensión alcanza
  para decidir sin ambigüedad, y el caso que `k` protegería —un `.png` que en
  realidad es un video— no existe. Si algún día el productor emite `k`, sumarlo
  es compatible hacia atrás: se usa si está, se infiere si no.

### F · Omitir la pieza cuando no hay archivo, en vez de aceptar `file: ""`

- A favor: contrato más estricto, `file` siempre apunta a algo, y `doctor` no
  necesita distinguir aviso de error.
- En contra: no hay dónde anotar lo que falta.
- **Descartada porque:** el camino de "pieza sin imagen" **es alcanzable igual**,
  se declare o no. `ui/CoverImage.qml` documenta el caso medido el 2026-08-02: un
  asset puede existir en el metadata y **no cargar** (un juego de Steam devuelve
  `boxFront` como URL remota, y el gabinete está offline). O sea que el
  placeholder hay que dibujarlo de todos modos. Aceptando `file: ""` ese mismo
  camino sirve además para declarar lo que falta conseguir, y el hueco se vuelve
  visible en vez de invisible. El precedente de tratarlo como aviso y no como
  error es `chk_mags_ref` (`fixtures/arcade/media/sf2ce/`).

### G · `file` como ruta relativa libre en vez de un nombre dentro de `_gallery/`

- A favor: permitiría reusar un archivo que ya está en otro lado sin copiarlo.
- En contra: abre la puerta a salir de la carpeta del juego.
- **Descartada porque:** obligaría a `doctor` a resolver `../` y a decidir si una
  ruta que escapa de `media/<set>/` es válida — dos preguntas nuevas para ahorrar
  una copia que en un gabinete offline no molesta. Con nombre plano, la
  verificación es el mismo `is_file()` que ya usa `_chk_manual_doc()`. Precedente
  exacto: [`ADR-0014`](0014-manual-digitalizado.md), repetido por el `file:` del
  PDF en [`ADR-0021`](0021-manual-pdf-app-del-sistema.md).

## Consecuencias

**Positivas**

- **Ningún juego de la librería queda con la galería vacía.** El piso lo pone
  Metal Slug con **cuatro** piezas (video, captura, carátula y póster: no trae
  marquesina, y `logo` no cuenta); los otros seis sin `_gallery/` dan cinco; y
  Final Fight, el único con piezas curadas, da trece (5 nativas + 8 curadas).
  Contado sobre los ocho `.coindoor.zip` el 2026-08-27.
- **El productor no se toca.** El contrato es el que COINDOOR ya emite, así que
  los paquetes generados hasta hoy siguen siendo válidos.
- `attract import` no necesita cambios: ya instala `_gallery/`.
- **Pero `attract import` sí cambia de comportamiento, sin tocarle una línea.**
  Su preflight comparte el validador (`instalar.py:109-124` llama a
  `doctor.chk_data_contrato` sobre el stage), así que un paquete cuyo `gallery`
  declare un archivo que no está, o una extensión desconocida, pasa a ser
  **rechazado** y revertido entero. Es lo que se quiere —un paquete roto no
  entra a la librería— y funciona porque el preflight corre después de escribir
  el stage, con `_gallery/` ya en disco. Vale decirlo porque el efecto no se ve
  en ningún diff de `instalar.py`.
- El theme no aprende ningún mecanismo nuevo: `GameData` compone la lista igual
  que ya normaliza `manuales` y `gruposCheats`, y `Paths.galeriaDe()` es
  `manualDe()` con otro nombre de carpeta.
- Un `label` es opcional en la práctica para los nativos (los pone el theme) y
  obligatorio para lo curado, que es donde aporta.

**Coste asumido**

- **La galería repite lo que la columna derecha del detalle ya muestra.**
  `boxFront` se ve en la ficha y otra vez en la galería; `poster` y `marquee` son
  además el fallback de la carátula (`ui/CoverImage.qml`). Es una decisión
  tomada a ojo abierto: se prefiere una galería completa a una sin repeticiones.
- **Duplicación posible.** Si COINDOOR alguna vez pone en `_gallery/` la misma
  imagen que ya es un asset nativo, aparece dos veces. No se puede deduplicar de
  forma confiable —nombres distintos, mismo contenido— y comparar bytes por
  pieza al abrir la ficha no se paga.
- **El orden de los nativos lo fija este ADR, no el dato.** Nadie puede reordenar
  "Carátula antes que Captura" sin cambiar código. Lo curado sí conserva su
  orden.
- **Un `label` de basura pasa igual.** Final Fight trae `"label": "url-10"`, un
  placeholder filtrado del scraping. `doctor` puede exigir que el `label` no esté
  vacío, pero no puede saber que dice cualquier cosa. Es un problema de datos del
  productor, no del contrato.

**Qué habría que revisar si esto se replantea**

- **Que aparezca un video dentro de `_gallery/`.** Hoy no pasa en ningún paquete;
  el contrato ya lo soporta (`.mp4` infiere video), pero sería la señal de que el
  productor cambió de idea sobre dónde vive el video, y de que "video primero"
  como orden fijo deja de tener sentido.
- **Que la repetición moleste al verla.** El costo de arriba es una apuesta. Si
  al mirarla en el gabinete la galería se siente redundante, la salida barata es
  sacar `boxFront`/`poster`/`marquee` de la composición — una lista en un solo
  lugar, sin tocar el contrato ni el productor.
- **Que una galería real pase de ~40 piezas.** Ahí el riel de miniaturas
  necesitaría lo que `DocumentViewer` ya tuvo que agregar para documentos largos
  (barra de posición relativa y salto grande), y la alternativa D merece
  releerse.
- **Que haga falta compartir piezas entre juegos** — el mismo video para dos
  ediciones. Ahí `_gallery/` por juego duplica archivos y la salida sería una
  carpeta global, como `_magazines/` (ADR-0024).

## Referencias

- `files_install/final-fight.coindoor.zip` — el paquete que fija el contrato
  real. Los otros siete de `files_install/` son la evidencia de que `_gallery/`
  es opcional y de que los nativos están siempre.
- [`spec/features/018-theme-galeria/`](../features/018-theme-galeria/spec.md) —
  la feature que fuerza la decisión.
- [`docs/gallery-spec.md`](../../docs/gallery-spec.md) — diseño de referencia,
  escrito contra un prototipo HTML ya corrido. §4 es el render de la pieza sin
  archivo.
- `src/attract/instalar.py:155` — el copiado que ya instala `_gallery/`.
- [`ADR-0027`](0027-contrato-paquete-import-coindoor.md) — el contrato del
  paquete, que este ADR extiende con `_gallery/` y `gallery`.
- [`ADR-0015`](0015-contrato-data-json.md) y
  [`ADR-0020`](0020-cheats-grupos-libres.md) — el contrato de `data.json`.
- [`ADR-0014`](0014-manual-digitalizado.md) — el precedente de `_manual/`.
- [`ADR-0029`](0029-player-nuevo-por-video.md) — por qué la pieza de video
  necesita su propio `MediaPlayer`.
- `ui/CoverImage.qml` — el caso medido de un asset que existe y no carga, que es
  el que hace alcanzable el placeholder.
