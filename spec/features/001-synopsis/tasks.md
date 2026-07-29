# 001 · Synopsis generado — Tareas

_Checklist accionable derivada del `plan.md`._

## Implementación

- [x] `src/attract/synopsis.py::leer_fuente` — lee
      `library/<sistema>/_synopsis/<set>.json`. Hecho cuando: devuelve el
      string de `summary` si el archivo existe y es válido, y levanta
      `SynopsisError` explícito (no `None` silencioso) si no existe, no es
      JSON válido, o le falta `summary`.
- [x] `src/attract/synopsis.py::parsear_bloques` — separa
      `metadata.pegasus.txt` en header + bloques `game:`. Hecho cuando:
      reserializar sin ningún merge (`escribir(parsear_bloques(texto))`)
      produce byte a byte el mismo archivo de entrada. Cubierto por
      `test_parsear_y_escribir_sin_merge_es_noop`.
- [x] `src/attract/synopsis.py::identificar_set` — resuelve `x-set:` o
      `file:` sin extensión. Hecho cuando: matchea correctamente los
      bloques de `fixtures/arcade/metadata.pegasus.txt` (`mok`, `sf2ce`,
      `dino` vía `file:`, `test-multifile`). Cubierto por
      `test_identifica_por_x_set_y_por_file`.
- [x] `src/attract/synopsis.py::mergear_summary` — reemplaza o inserta
      `summary:` (+ continuación si la había). Hecho cuando: en el bloque de
      `mok` (que ya tenía un `summary:` multilínea), reemplaza las líneas
      viejas completas, sin dejar restos. Cubierto por
      `test_reemplaza_summary_multilinea_existente`.
- [x] `src/attract/synopsis.py::main` — cablea el flujo completo:
      `attract synopsis <set>` → `leer_fuente` → ubicar bloque por
      `identificar_set` → `mergear_summary` → `escribir`. Verificado con
      smoke test manual contra `fixtures/arcade/` (ver historial de la
      sesión) además de los tests automatizados de `aplicar()`.
- [x] `src/attract/cli.py` — agregado `synopsis` a `COMANDOS` y al texto de
      `--help`.

## Tests (`tests/test_synopsis.py`) — 11 tests, todos en verde

- [x] Caso feliz: fuente con `summary` válido, bloque existente sin
      `summary:` previo → se inserta después de `file:`, resto del bloque
      sin cambios. (`test_inserta_summary_nuevo_despues_de_file`)
- [x] Caso feliz: bloque con `summary:` multilínea previo (fixture `mok`) →
      se reemplaza completo, sin restos.
      (`test_reemplaza_summary_multilinea_existente`)
- [x] Idempotencia: correr dos veces seguidas con la misma fuente produce
      el mismo archivo la segunda vez que la primera. (`test_idempotente`)
- [x] Caso límite: no existe `_synopsis/<set>.json` → `SynopsisError`
      explícito. (`test_fuente_ausente`)
- [x] Caso límite: existe el archivo pero sin campo `summary` → error
      explícito, no `KeyError` crudo ni escritura parcial.
      (`test_fuente_sin_campo_summary`, `test_fuente_json_invalido`)
- [x] Caso de fallo: `<set>` no matchea ningún bloque `game:` → error
      explícito, no crea un bloque nuevo, archivo sin tocar.
      (`test_set_inexistente_no_crea_bloque`)
- [x] Invariante: después de escribir, `attract doctor` sobre
      `fixtures/arcade/` sigue en OK. (`test_doctor_sigue_ok_despues_de_escribir`)
- [x] Invariante: reserializar sin merges es un no-op — mismo archivo byte
      a byte. (`test_parsear_y_escribir_sin_merge_es_noop`)
- [x] Extra: bloque `game:` sin línea `file:` → falla explícito en vez de
      insertar en un lugar arbitrario. (`test_bloque_sin_file_falla_explicito`)

## Cierre

- [x] Validar contra todos los criterios de aceptación de `spec.md` — los 6
      quedaron `[x]`.
- [x] `PYTHONPATH=src python3 -m pytest tests/ -q` en verde (20/20: 9
      `doctor` + 11 `synopsis`).
- [x] `make doctor` en verde sobre `fixtures/arcade/` después de correr
      `attract synopsis` contra un fixture real (`mok`).
- [x] Fixture de prueba creado: `fixtures/arcade/_synopsis/mok.json` —
      mismo nivel que `metadata.pegasus.txt`, sigue la equivalencia
      `library/<sistema>/` ↔ `fixtures/<sistema>/` ya establecida en
      `CONVENCION.md` §1.1. El resto de los casos usan `tmp_path`, mismo
      estilo que `tests/test_doctor.py`.
- [x] Movido `001-synopsis` a "Hecho" en `../../constitution/roadmap.md`.
- [x] `docs/CONVENCION.md` §1.4 actualizado para mencionar `_synopsis/`.
