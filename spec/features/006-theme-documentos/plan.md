# 006 · Video, revistas y visor de documentos — Plan

_Cómo se implementa lo descrito en `spec.md`. Respeta `constitution/`._

## Enfoque

Tres piezas que parecen tres features y son dos y media: el visor de documentos
se come al manual y a las revistas con **un solo modelo de páginas**, que es
justo la razón por la que [`ADR-0014`](../../decisions/0014-manual-digitalizado.md)
le dio a `manual.pages[]` la misma forma que a `magazine.json → pages[]`.

El corte respeta el de la 005 — `core/` sabe de datos, `ui/` dibuja,
`screens/`+`overlays/` componen:

```
core/
├─ MagazineData.qml      XHR de magazine.json -> pages[], articles[], displayName
└─ DocModel.qml          normaliza revista Y manual a UNA lista de paginas
ui/
└─ MedidorVolumen.qml    las 5 barras del transporte
screens/
├─ VideoPanel.qml        MediaPlayer + VideoOutput + transporte
└─ MagazineCarousel.qml  las tapas, dos a la vez
overlays/
└─ DocumentViewer.qml    el visor, compartido
```

`DocumentViewer` **no sabe** si le pasaron una revista o un manual: recibe un
`DocModel` y lo dibuja. Toda la diferencia vive en cómo se arma ese modelo.

## Implementación

### 1. Fixtures primero, otra vez

Las páginas de `fixtures/` pesan 0 bytes, así que el visor no tendría contra
qué probarse — exactamente el agujero que tuvo la cadena de carátula en la 005.
Se resuelve igual: **PNG generados con stdlib**, uno por página, **con el
número impreso bien grande**. Sin número no se puede verificar que hojear
avance, que `startPage` abra donde debe, ni que las miniaturas salten bien.

Van en `fixtures/` (versionados, ~2 KB cada uno) y se anotan como excepción en
`CLAUDE.md`, al lado de las dos que ya están.

### 2. `core/MagazineData.qml`

Mismo patrón que `GameData`: se le pone un `ref`, dispara el XHR, expone
`pages`, `articles`, `estado` y `displayName`. Reusa `core/DataCache.js` — el
caché compartido ya existe y una revista la miran varias tarjetas.

`displayName` implementa la regla ya cerrada en ADR-0010: sacar la extensión de
`name` (`"se-micro80.pdf"` → `"se micro80"`), `-`/`_` → espacio, y anteponer
`Nº<issue> (<year>)` cuando existan. **No se persiste nada**, es presentación
(ADR-0009).

`articuloDe(set)` busca en `articles[]` el que tenga `game === set`. Si no hay,
el visor abre en la página 1: la revista existe igual.

### 3. `core/DocModel.qml`

La pieza que hace que el visor sea uno solo:

| Entrada | `paginas` | `inicio` | `destacadas` |
|---|---|---|---|
| revista | `magazine.pages` con la base de `_magazines/<ref>/` | `articulo.startPage` | `articulo.pages` |
| manual | `manual.pages` con la base de `_manual/` | 1 | vacío |

Los índices que entran son **1-based** (`spec.md`); adentro se normalizan a
0-based una sola vez, en la frontera. Mezclar las dos convenciones en el mismo
archivo es de donde salen los off-by-one.

### 4. `screens/VideoPanel.qml`

`MediaPlayer` + `VideoOutput` con `PreserveAspectCrop`. Encima, la carátula
como fondo: sin `assets.video` el panel muestra la carátula, nunca un hueco
(`CONVENCION.md` §2.1 nota 2).

Tres cosas que no son negociables:

- **El transporte se revela por FOCO, no por hover.** El gabinete no tiene
  mouse; el handoff lo pide explícitamente.
- **`source: ""` al desactivarse.** Sin esto el gabinete acumula decoders al
  entrar y salir de fichas.
- **Arranca en mute.** Un gabinete que se pone a sonar solo al mover el foco es
  insoportable.

Y una que ya sabemos y hay que no olvidar: **no colgar nada de `onStopped`**,
que no se dispara en un loop continuo (`docs/plataforma-pegasus.md` §2).

### 5. `screens/MagazineCarousel.qml`

Viewport de 178px de alto con dos tapas de 133×178, deslizando en pasos de
143px (133 + 10 de gap). Flechas solo con más de dos revistas, fila de puntos y
contador `1–2 / N`.

La tapa es una `Image` de `cover` de la revista. **Si no carga, se muestra que
esa revista no está** — no se dibuja una tapa falsa. El `ref` colgado de
`sf2ce` es el fixture de ese caso.

Arriba/abajo pasan la página del carrusel **solo cuando el carrusel tiene el
foco**; si no, mueven el foco. Sale del prototipo (`detailTargets`).

### 6. `overlays/DocumentViewer.qml`

Scrim con `FastBlur` — ahora se puede, el experimento lo confirmó. Es donde el
blur más se iba a notar.

- **Hoja** de 560×760 (revista) o 540×760 (manual), máximo 88% del alto.
- **Miniaturas** abajo, una por página, con las del artículo marcadas en accent.
- **Pestañas** arriba cuando el juego tiene más de una revista.
- **Zoom** en 4 pasos (1, 1.4, 1.85, 2.4) y **paneo con D-pad**, no solo mouse.

Rendimiento, que acá sí importa:

- `sourceSize` atado al zoom: a 2.4× hace falta más resolución, no la misma
  imagen estirada.
- Precarga **±1 página**. Ni todas ni ninguna.
- `asynchronous: true`: una página grande no puede congelar la navegación.

### 7. `attract doctor`

Chequeo nuevo en `chk_magazine_contrato`: `startPage` y cada valor de
`articles[].pages` dentro de `1..pages.length`. Hoy un artículo que apunte
fuera de rango pasa el validador y explota recién en el visor.

## Decisiones

- **Un solo visor para revista y manual.** Es el motivo por el que ADR-0014 le
  dio a `manual.pages[]` la forma de `magazine.pages[]`. Dos visores serían dos
  implementaciones de zoom, paneo y miniaturas que hay que mantener iguales.
- **El visor recorre la revista ENTERA**, no solo las páginas del artículo. Es
  el requisito de `docs/decisiones/2026-07-23.md` §5, y lo que justifica que la
  revista sea una entidad propia y no un adjunto del juego.
- **Las páginas del artículo se marcan en las miniaturas.** No estaba en el
  diseño; sale gratis de `articles[].pages` y es la única pista visual de por
  qué el visor abrió donde abrió.
- **`articles[].type` se usa.** Una `publicidad` no se anuncia como si fuera
  una nota. El enum no es cerrado (ADR-0010), así que un tipo desconocido se
  trata como genérico, no como error.
- **Nada de páginas falsas.** Una página que no carga se muestra como lo que
  es. El prototipo dibujaba tapas y reseñas de mentira porque no tenía escaneos;
  nosotros sí, y el handoff prohíbe que un placeholder llegue a producción.
- **Los índices se normalizan en la frontera.** 1-based afuera (el contrato),
  0-based adentro. Una sola conversión, en `DocModel`.

## Riesgos

- **`loops` en Windows.** Es lo único que la 005 dejó sin verificar en el
  gabinete y lo que más varía entre backends. Si falla, el arreglo es
  reenganchar a mano mirando la posición — la señal ya está identificada.
- **El zoom con `sourceSize` recarga la imagen.** Puede verse un parpadeo al
  cambiar de paso. Si molesta, la salida es mantener la resolución del zoom
  máximo y escalar hacia abajo, a costa de memoria. Medir antes.
- **Un `Loader` con el visor adentro se lleva el foco**, y el detalle debe
  recuperarlo al cerrarse. Ya funciona así con `LaunchOverlay`; el patrón está
  probado.
