# Roadmap

_Orden y estado de las features. Cada entrada apunta a su carpeta en `../features/`._

## Hecho ✅

1. **Módulo 0 · `attract doctor`** — validador preflight (encoding, CRLF,
   nombres ilegales en Windows, NFC en nombre y en contenido, basura de
   macOS, assets referenciados que no existen). `src/attract/doctor.py`,
   cubierto por los 19 tests de `tests/test_doctor.py` (9 originales + 10
   de validación de JSON/`mags[].ref`/contrato de `magazine.json`,
   agregados junto con los puntos 8 y 10 abajo).
   _(Implementado antes de adoptar spec/features/ — no tiene carpeta propia.)_
2. **LAB 0.3 completo:** `docs/CONVENCION.md` (las 4 secciones, sin
   placeholders) y **ADR-0002, 0003, 0004** — las tres `accepted`. El
   terreno de diseño para juegos individuales (estructura, campos,
   procedencia, validación, identidad en merged, artefacto vs. fuente,
   cross-platform) está firme.
3. **LAB 0.4:** `docs/baseline.md` medido y consistente.
4. **ADR-0006 a 0009 — las 9 ADR aceptadas, 9/9.** Modelo de datos de
   revistas, frontera del sistema, versión de Pegasus, páginas como
   imágenes. No quedan decisiones de arquitectura pendientes.
5. **Verificaciones 1 y 2 corridas contra Pegasus real:** la cadena de dos
   lecturas de JSON funciona (confirmado, ver ADR-0008) y la contraprueba de
   PDF falla como predecía ADR-0007 ("Theme loading failed"). Un
   `magazine.json` real subido durante la verificación no coincidía con el
   contrato inventado en ADR-0008 → **ADR-0010** lo supersede con el
   contrato ampliado (`type`, `confidence`, `key_id`, flags de review).
   **10 ADR en total, 9 vigentes.**

6. **Verificación técnica de ADR-0004 — confirmada 2026-07-28.** Pegasus
   real, fixture `TEST MULTIFILE` (dos `file:` bajo un mismo `game:`): al
   lanzar, muestra un selector para elegir cuál abrir. Las tres
   verificaciones "bien dummy" de esta sesión están cerradas.
7. **`spec/features/001-synopsis/` — implementada.** Primera feature real
   usando el flujo SDD completo (spec → plan → tasks → código).
   `src/attract/synopsis.py` es el primer módulo que escribe
   `metadata.pegasus.txt` (**ADR-0011**: fuente persistida por campo,
   merge quirúrgico de `summary:`, sin tocar el resto del bloque `game:`).
   11 tests nuevos en `tests/test_synopsis.py`, `attract doctor` sigue en
   OK después de escribir. `docs/CONVENCION.md` §1.4 documenta
   `_synopsis/<set>.json`.
8. **Decisiones abiertas de ADR-0010 — resueltas 2026-07-28.** Fixture de
   `micromania-16/magazine.json` actualizado al contrato completo
   (`key_id`, `type`/`confidence` por artículo, flags de `review`, con un
   segundo artículo `publicidad` que encarna por qué las páginas no son
   consecutivas). Regla de presentación para `name` sucio documentada
   (limpieza mínima: sacar extensión, `-`/`_` → espacio — sin código
   todavía porque el theme de producción no existe). `attract doctor` ahora
   valida que `data.json`/`magazine.json` sean JSON válido
   (`chk_json_valido`, ERROR) y que `mags[].ref` resuelva a una carpeta
   real (`chk_mags_ref`, AVISO — la degradación con `ref` colgado es
   aceptada a propósito, ver `fixtures/arcade/media/sf2ce/`).

9. **ADR-0004 — pendiente de badge por variante, resuelta 2026-07-28.** No
   se agrega nada por ahora: el selector de `file:` es UI nativa de
   Pegasus (ATTRACT no puede customizarlo) y no hay caso real que lo
   necesite. Si aparece, la vía es `x-variantes:` a nivel de `game:` (una
   lista compartida por la ficha, no un dato por archivo).
10. **`attract doctor` valida el contrato completo de `magazine.json` —
    2026-07-28.** `chk_magazine_contrato` (ADR-0010): campos obligatorios,
    tipos, `articles[].confidence` en rango 0.0-1.0, `type` con AVISO (no
    ERROR) si no es uno de los conocidos — el enum no es cerrado. 6 tests
    nuevos. **30 tests en total** (19 `doctor` + 11 `synopsis`).

## Siguiente 🔜

1. **ADR-0011** — verificaciones pendientes: confirmar el formato real de
   entrega del sistema de scraping externo (hoy `_synopsis/<set>.json` es
   un supuesto sin evidencia real, mismo punto de partida que tuvo
   `magazine.json` antes de ADR-0010).
2. **`attract skill`** (M4), **`attract mcp`** (M5), **`attract ingest`**
   (M7) — mencionados como plan en `src/attract/cli.py`, sin spec ni
   código todavía. `attract ingest` (M7) es además donde se retoma la
   pregunta de procedencia (§3 de `CONVENCION.md`) si algún día se
   revisita esa decisión.

## Backlog / ideas 💡

- (vacío por ahora)

> Cada feature nueva se crea como `features/NNN-nombre/` con `spec.md`,
> `plan.md` y `tasks.md` **antes** de tocar código.
