# 004 · `attract ingest` — Tareas

_Checklist accionable derivada del `plan.md`._

## Implementación

- [x] `src/attract/ingest.py::listar_maquinas_jugables` — corre
      `mame -listxml <set>`, filtra `runnable="no"`. Hecho cuando: contra
      un XML sintético con una jugable + un device, devuelve solo la
      jugable.
- [x] `src/attract/ingest.py::identificar` — exige exactamente 1 máquina.
      Hecho cuando: 0 y >1 fallan explícito con mensajes distintos.
- [x] `src/attract/ingest.py::construir_bloque` — arma el bloque nuevo sin
      inventar `developer:`/`release:` si `-listxml` no los dio.
- [x] `src/attract/ingest.py::aplicar` — orquesta todo, reusa
      `synopsis.parsear_bloques`/`escribir`/`identificar_set`. Hecho
      cuando: agrega al final sin tocar bloques existentes, crea
      `media/<set>/`.
- [x] `src/attract/cli.py` — agregado `"ingest"` a `COMANDOS` y al
      `--help`.

## Tests (`tests/test_ingest.py`) — 11 tests

- [x] `mame` no instalado → `IngestError` explícito. **Este test corre
      contra el `mame` real de este sandbox** (no hay uno instalado) — es
      el único test de todo el archivo que no depende del XML sintético.
- [x] Filtra `runnable="no"` correctamente.
- [x] 0 máquinas jugables → falla explícito ("no reconocido").
- [x] Más de 1 máquina jugable → falla explícito, menciona ADR-0004.
- [x] XML inválido → falla explícito, no traceback crudo.
- [x] `construir_bloque` completo (con year/manufacturer) y sin ellos —
      confirma que no inventa campos.
- [x] `aplicar` caso feliz: agrega el bloque, no toca lo existente, crea
      `media/<set>/`.
- [x] `aplicar` con set ya existente: falla, archivo sin tocar.
- [x] `aplicar` con set no reconocido por mame: falla, archivo sin tocar,
      no crea `media/<set>/`.

## ✅ Verificación de la forma del XML — cerrada 2026-07-29

_Confirmada con evidencia real: el autor corrió `mame -listxml sf2ce`
(mame vanilla 0.288) en su Mac y pegó la salida completa. Se probó
literalmente contra el código de `ingest.py`
(`tests/test_ingest.py::test_forma_real_confirmada_2026_07_29`)._

Resultado:

- `<description>`, `<year>`, `<manufacturer>`, `runnable="no"` — todo
  confirmado, tal como se había asumido.
- El `<!DOCTYPE mame [...]>` con subset interno no rompe `ET.fromstring`.
- El título real trae basura de región de verdad:
  `"Street Fighter II': Champion Edition (World 920513)"`. Decisión: se
  deja crudo (ver spec.md §Fuera de alcance) — no se agrega limpieza por
  regex, mismo criterio de "no inventar/adivinar" que ya usaba el resto
  del módulo.

**Único punto que sigue abierto — necesita el gabinete, no solo el
parser:** si Pegasus acepta `release: 1992` (solo el año) en pantalla sin
rechistar. `attract doctor` ya lo acepta. Si alguna vez cargás esto en el
gabinete de verdad, fijate y contame — si Pegasus lo rechaza, es un ajuste
de una línea en `construir_bloque`, no una decisión de arquitectura.

## Cierre

- [x] `PYTHONPATH=src python3 -m pytest tests/ -q` en verde (50/50: 19
      `doctor` + 11 `synopsis` + 9 `mcp` + 11 `ingest`).
- [x] `attract doctor` sobre todo el repo en 0 errores.
- [x] Verificación de arriba corrida contra `mame` real — cerrada
      2026-07-29 (ver sección de arriba). Solo queda el punto menor de
      `release: <año>` en Pegasus real, no bloqueante.
- [x] Movido `004-attract-ingest` a "Hecho (con verificación pendiente)"
      en `../../constitution/roadmap.md`.
