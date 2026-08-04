# 006 · Video, revistas y visor de documentos — Tareas

_Checklist accionable derivada del `plan.md`._

## 0 · Fixtures, antes que el código

Las páginas de revista y de manual de `fixtures/` pesan **0 bytes**, así que el
visor no tendría contra qué probarse. Es el mismo agujero que tuvo la cadena de
carátula en la 005 y se resuelve igual.

- [x] **Hecho 2026-08-03.** 13 PNG generados con stdlib (`zlib` + `struct` +
      una fuente de dígitos de 5×7 dibujada a mano, porque no hay forma de
      escribir texto en una imagen sin dependencias): las 8 páginas de
      `_magazines/micromania-16/`, su `cover`, y las 4 de `sf2ce/_manual/`.
      **28 KB en total**, ~2 KB cada una.
- [x] Los contratos apuntan a los archivos nuevos: `magazine.json` (`cover` y
      `pages[]`) y `sf2ce/data.json` (`manual.pages[]`) pasan de `.jpg` a
      `.png`. Los `.jpg` de 0 bytes se borran: dos archivos por página
      confunden.
- [x] Excepción anotada en `CLAUDE.md`, al lado de las dos que ya estaban.

## 1 · Datos

- [x] `core/MagazineData.qml` — escrito. XHR de `magazine.json`, expone
      `pages`, `articles`, `estado`, `displayName`, `colorMarca` y las urls ya
      resueltas. Reusa `core/DataCache.js`, que acá importa más que en
      `GameData`: una misma revista cubre **varios** juegos, así que el mismo
      archivo se pide desde fichas distintas.
- [x] `articuloDe` / `inicioDe` / `paginasDe` — **la conversión 1-based →
      0-based pasa acá y en ningún otro lado**, con clamp a los extremos.
      Verificada la aritmética contra el fixture: `startPage 3 → índice 2`,
      `pages [3,4,5,7,8] → [2,3,4,6,7]`, y los fuera de rango se clampean o se
      descartan en vez de romper.
- [x] `core/DocModel.qml` — normaliza revista y manual a una sola lista de
      urls. Es la pieza que hace que el visor sea **uno solo**: recibe un
      modelo y no sabe cuál de los dos le tocó.

## 2 · Video

- [x] `screens/VideoPanel.qml` — escrito. `MediaPlayer` + `VideoOutput`
      (`PreserveAspectCrop`) sobre la carátula, viñeta, pill `● GAMEPLAY` con
      el latido de 1.6s, y el transporte completo.
- [x] Transporte: play/pausa, volumen en pasos de 0.2, `ui/MedidorVolumen.qml`
      de 5 barras, mute. Subir el volumen desmutea y desmutear con el volumen
      en cero lo sube — es lo que espera cualquiera que aprieta esos botones.
- [x] **Se revela por FOCO, no por hover.** El `translateY` de 8px del diseño
      se conserva; el hover no, porque no existe en el gabinete.
- [x] **`source: ""` al desactivarse** (`encendido: root.visible`). No alcanza
      con pausar: hay que soltar el archivo.
- [x] **Arranca en mute.**
- [x] **Nada colgado de `onStopped`.**
- [x] Sin `assets.video` se ve la carátula con su cadena de fallback, no un
      color-wash: es mejor dato y ya lo teníamos.
- [x] **Regla de navegación nueva, generalizada:** el handoff pide revelar los
      controles "por foco de D-pad" pero no dice cómo llegar ahí sin romper el
      recorrido. Queda: **izquierda/derecha mueve ENTRE targets, arriba/abajo
      actúa DENTRO del target enfocado.** Eso le da al carrusel su
      comportamiento sin un caso especial —pasar de página *es* actuar dentro
      de un carrusel— y hace alcanzables los controles del video.
      Orden: `[JUGAR] → [video] → [Hacks] → [Manual]`, con JUGAR primero
      aunque el video esté más arriba en pantalla: al entrar se enfoca la
      acción principal, no un control secundario.

## 3 · Carrusel

- [x] `screens/MagazineCarousel.qml` — escrito. Viewport de 178, dos tapas de
      133×178, pasos de 143px, contador `1–2 / N`, puntos (pastilla ancha para
      las visibles), flechas solo con más de dos.
- [x] El nombre sale de `displayName`.
- [x] **Una tapa que no carga muestra que esa revista no está.** El prototipo
      inventaba una tapa entera con cabecera y código de barras en CSS; una
      tapa falsa miente sobre qué hay escaneado.
- [x] Arriba/abajo pasan página **solo con el carrusel enfocado**.
- [x] Orden final: `[JUGAR] → [video] → [carrusel] → [Hacks] → [Manual]`.

## 4 · Visor

- [x] `overlays/DocumentViewer.qml` — escrito. Scrim con `FastBlur` sobre el
      detalle (que se deja **visible** detrás justamente para que el desenfoque
      tenga qué desenfocar), hoja de 560×760 / 540×760.
- [x] Abre en `startPage` del artículo y **recorre la revista entera**.
      **Divergencia deliberada del handoff**, que decía abrir en la tapa: el
      prototipo no tenía el concepto de artículo y por eso no podía hacer otra
      cosa.
- [x] Miniaturas con las páginas del artículo **marcadas**, en borde y número.
- [x] Pestañas con más de una revista.
- [x] Zoom en 4 pasos y **paneo vertical con D-pad**. Solo vertical, y con
      motivo: a 2.4× una hoja de 560 mide 1344 sobre un lienzo de 1280 —
      horizontalmente casi no sobra nada. Lo que se sale de pantalla es el alto
      (760 → 1824). Un paneo horizontal sería un control que no mueve nada.
- [x] `sourceSize` atado al zoom, precarga **±1** invisible, `asynchronous`.
- [x] Una página que no carga se muestra como lo que es, con su número.
- [x] Cambiar de página **recentra el paneo**: quedar perdido a mitad de la
      hoja anterior desorienta.

## 5 · Doctor

- [x] **Hecho.** `chk_magazine_contrato` valida que `startPage` y cada valor de
      `articles[].pages` caigan en `1..pages.length`. Antes un artículo fuera
      de rango pasaba el validador y explotaba recién en el visor, que es el
      peor lugar para enterarse.
- [x] 4 tests nuevos, incluido el de los **límites** (1 y el total son válidos)
      — es el caso que rompe un chequeo de rango mal escrito — y el de
      `startPage: 0`, que es el error probable de quien asuma que los índices
      son offsets de array.

## 6 · Verificación contra Pegasus real

| Caso | Fixture | Qué tiene que pasar |
|---|---|---|
| Artículo del juego | `dino` → `micromania-16` | Abre en la **3**, se hojean las 8, las del artículo (3,4,5,7,8) marcadas |
| Página salteada | la 6 es `publicidad` | Se puede hojear a la 6: el visor recorre la revista entera |
| `ref` colgado | `sf2ce` | El carrusel dice que la revista no está. **Sin crash** |
| Manual | `sf2ce` → `_manual/` | El **mismo** visor, 4 páginas |
| Sin nada | `mok` | Los dos bloques con su mensaje de §2.3 |
| Video | `library/preview` → `dino` | Loopea; el transporte responde; en mute al abrir |
| Sin video | el resto | Carátula en el panel, sin hueco |

## 7 · Cierre

- [x] `make test` (72) y `make doctor` en verde.
- [x] Anotado en `docs/plataforma-pegasus.md`: la cuarta repetición de la
      trampa de layout, y la de mezclar dos estados en una variable.
- [ ] Mover `006` a "Hecho" en `../../constitution/roadmap.md` y actualizar el
      mapa del repo.
- [ ] **Lo que sigue sin verificarse en el gabinete (Windows)**: `loops` de
      QtMultimedia es el candidato más probable a comportarse distinto. Dejarlo
      anotado, no darlo por hecho.
