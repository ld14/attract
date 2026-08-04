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

- [ ] `screens/VideoPanel.qml` — `MediaPlayer` + `VideoOutput`
      (`PreserveAspectCrop`), con la carátula de fondo.
- [ ] Transporte: play/pausa, volumen en pasos de 0.2, `ui/MedidorVolumen.qml`
      de 5 barras, mute.
- [ ] **Se revela por FOCO, no por hover** — el gabinete no tiene mouse.
- [ ] **`source: ""` al desactivarse.** Hecho cuando: entrar y salir del
      detalle veinte veces no degrada nada.
- [ ] **Arranca en mute.** Un gabinete que suena solo al mover el foco es
      insoportable.
- [ ] **Nada colgado de `onStopped`** — no se dispara en un loop continuo
      (`docs/plataforma-pegasus.md` §2).
- [ ] Sin `assets.video`, el panel muestra la carátula y no un hueco
      (`CONVENCION.md` §2.1 nota 2).

## 3 · Carrusel

- [ ] `screens/MagazineCarousel.qml` — viewport de 178, dos tapas de 133×178,
      pasos de 143px, contador `1–2 / N`, puntos, y flechas solo con más de dos.
- [ ] El nombre sale de `displayName`, no de `name` crudo.
- [ ] Una tapa que no carga muestra **que esa revista no está**. No se dibuja
      una tapa falsa. Fixture: el `ref` colgado de `sf2ce`.
- [ ] Arriba/abajo pasan página **solo con el carrusel enfocado**; si no,
      mueven el foco entre los targets del detalle.
- [ ] El carrusel entra en el orden de foco del detalle, entre JUGAR y los
      extras: `[JUGAR] → [carrusel] → [Hacks] → [Manual]`.

## 4 · Visor

- [ ] `overlays/DocumentViewer.qml` — scrim con `FastBlur` (confirmado
      disponible), hoja de 560×760 / 540×760 al 88% del alto máximo.
- [ ] Abre en `startPage` del artículo del juego y **recorre la revista
      entera** — el requisito de `docs/decisiones/2026-07-23.md` §5.
- [ ] Miniaturas abajo, con las páginas del artículo **marcadas en accent**.
- [ ] Pestañas arriba con más de una revista, para cambiar sin salir.
- [ ] Zoom en 4 pasos (1, 1.4, 1.85, 2.4) y **paneo con D-pad**, no solo mouse.
- [ ] Rendimiento: `sourceSize` atado al zoom, precarga **±1**,
      `asynchronous: true`.
- [ ] Una página que no carga no rompe el visor.
- [ ] Escape/B cierra y devuelve el foco al detalle.

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

- [ ] `make test` y `make doctor` en verde.
- [ ] Anotar en `docs/plataforma-pegasus.md` lo que se aprenda de nuevo.
- [ ] Mover `006` a "Hecho" en `../../constitution/roadmap.md` y actualizar el
      mapa del repo.
- [ ] **Lo que sigue sin verificarse en el gabinete (Windows)**: `loops` de
      QtMultimedia es el candidato más probable a comportarse distinto. Dejarlo
      anotado, no darlo por hecho.
