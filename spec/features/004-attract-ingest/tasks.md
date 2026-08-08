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

## ✅ `release: <solo año>` — cerrado 2026-07-29

_Era el último punto abierto de la feature. Se respondió en Pegasus real, con
los dos casos al lado y sin escribir código nuevo: el harness de
`themes/attract-debug/` dumpea `releaseYear`, y `game_dirs.txt` apuntaba a los
dos metadata a la vez._

| Juego | `release:` en el metadata | `releaseYear` en Pegasus |
|---|---|---|
| `library/arcade` → The Maze of the Kings | `2002` (solo el año) | **2002** |
| `fixtures/arcade` → The Maze of the Kings | `2002-03-06` (fecha completa) | **2002** |

**Pegasus acepta el año pelado.** `construir_bloque` no necesita ningún
ajuste: escribir `release: <año>` cuando `-listxml` solo da el año era la
decisión correcta, y no hay que inventar un `01-01` para completar la fecha.

**Hallazgo de rebote:** cuando no hay `release:`, `releaseYear` vuelve `0` —
la misma colisión que `rating` (no se distingue "sin dato" de "año cero", ver
`docs/CONVENCION.md` §2.3). No afecta a `ingest`, que nunca escribe un año que
no tenga; sí afecta al theme, que tiene que tratar el `0` como "Sin
Información". Anotado en `spec/features/005-theme-base/`.

**Con esto la feature 004 no tiene ningún pendiente.**

## ✅ Integración contra `mame` real — cerrada 2026-07-29

_El autor instaló MAME (vanilla 0.288) en su Mac. Con eso desaparece la
advertencia que encabezaba `plan.md` §Riesgos: hasta acá **todo** el módulo
estaba probado contra XML sintético o contra una salida pegada a mano._

- [x] `attract ingest` corrido de punta a punta contra el binario, sobre
      una copia de los fixtures (los fixtures reales quedaron intactos).
      Resultado: bloque escrito correcto, bloques existentes sin tocar,
      `media/1943/` creada, `attract doctor` en 0 errores sobre el
      resultado.

      ```
      game: 1943: The Battle of Midway (Euro)
      file: 1943.zip
      developer: Capcom
      release: 1987
      x-set: 1943
      ```

- [x] **Segundo caso real de basura de región** pegada al título:
      `(Euro)`, igual que el `(World 920513)` de sf2ce. Dos ejemplos
      independientes confirman que no es una rareza de un set — la
      decisión de dejarlo crudo (§Fuera de alcance) se sostiene.
- [x] **Confirmado por qué el módulo es testeable con fixtures de 0
      bytes:** `-listxml` lee la base de datos interna de MAME, no el
      archivo. `1943.zip` vacío se identifica igual.
- [x] 3 tests de integración nuevos, con `skipif` cuando no hay `mame` en
      el `PATH` — mismo criterio que `test_mcp_server.py` con el SDK
      `mcp`. Verificado que en una máquina pelada la suite sigue pasando
      (`11 passed, 3 skipped`).
- [x] **Arreglado `test_mame_no_instalado_falla_explicito`.** Afirmaba que
      `mame` no estaba instalado y se invirtió en cuanto apareció el
      binario. Ahora fuerza la ausencia (`PATH` a un directorio vacío) en
      vez de asumirla; sigue ejercitando el `FileNotFoundError` real de
      `subprocess`, sin mock.

## Cierre

- [x] `PYTHONPATH=src python3 -m pytest tests/ -q` en verde (72 tests: 38
      `doctor` + 11 `synopsis` + 9 `mcp` + 14 `ingest`; cuántos se saltean
      depende del entorno — 2 `mcp` si el SDK `mcp` no está instalado, más
      los `ingest` que dependen de `mame` si no está en el PATH).
- [x] `attract doctor` sobre todo el repo en 0 errores.
- [x] Verificación de arriba corrida contra `mame` real — cerrada
      2026-07-29 (ver sección de arriba). Solo queda el punto menor de
      `release: <año>` en Pegasus real, no bloqueante.
- [x] Movido `004-attract-ingest` a "Hecho (con verificación pendiente)"
      en `../../constitution/roadmap.md`.
