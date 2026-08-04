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

- [ ] `core/MagazineData.qml` — XHR de `magazine.json`, expone `pages`,
      `articles`, `estado` y `displayName`. Reusa `core/DataCache.js`.
      Hecho cuando: `micromania-16` carga, el `ref` colgado de `sf2ce` cae en
      `sin-datos` sin crashear, y `displayName` limpia un `name` sucio
      (`"se-micro80.pdf"` → `"se micro80"`) según la regla de ADR-0010.
- [ ] `MagazineData.articuloDe(set)` — busca por `game === set`. Sin artículo,
      el visor abre en la página 1: la revista existe igual.
- [ ] `core/DocModel.qml` — normaliza revista y manual a una sola lista.
      **Los índices 1-based del contrato se convierten a 0-based UNA vez, acá.**
      Mezclar las dos convenciones es de donde salen los off-by-one.

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

- [ ] `chk_magazine_contrato`: `startPage` y cada valor de `articles[].pages`
      dentro de `1..pages.length`. Hoy un artículo fuera de rango pasa el
      validador y explota recién en el visor.
- [ ] Tests en `tests/test_doctor.py`, nombrados por el bug que reproducen.

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
