# 016 · Import de paquete COINDOOR — Tareas

_Checklist accionable derivada del `plan.md`. Tareas pequeñas y concretas;
marca `[x]` al completarlas._

## Antes de tocar código

- [x] `ADR-0026` (identidad declarada sin `mame -listxml`) — creado,
      `accepted`.
- [x] `ADR-0027` (contrato del paquete) — creado, `accepted`.

## Implementación

Diseño cerrado en `plan.md` §Implementación — seguirlo al pie de la letra,
no re-derivar. Ver también `guia-ejecucion.md` en esta misma carpeta (paso a
paso con snippets, pensada para un agente sin el resto del contexto de esta
sesión).

- [x] `src/attract/instalar.py::leer_paquete` — zip-slip guard (recorrer
      `namelist()` completo ANTES de escribir un byte), extracción manual con
      `zf.read()` (nunca `extractall`), normalización NFC de nombres,
      staging en `tempfile.mkdtemp()` con `<tmp>/media/` = forma final de
      `media/<set>/`. Hecho cuando: un zip con `../etc/passwd` como nombre de
      miembro falla explícito sin escribir ningún archivo.
- [x] `src/attract/instalar.py::leer_paquete` — preflight de `data.json`
      llamando **sin modificar** `doctor.chk_encoding`, `doctor.chk_json_valido`,
      `doctor.chk_data_contrato`, `doctor.chk_nombre_windows` contra el
      staging (`doctor.Reporte()`, revisar `.errores`). **No** llamar
      `chk_mags_ref` acá (ver `plan.md` §Enfoque, por qué). Hecho cuando: un
      `data.json` con `cheats` mal formado falla en `leer_paquete` con el
      mismo mensaje que daría `attract doctor` sobre el mismo archivo.
- [x] `src/attract/instalar.py::mergear_campo_simple(bloque, clave, valor)`
      — una línea, análoga a `synopsis.mergear_summary` pero sin el caso
      multilínea. Hecho cuando: reemplaza una línea existente y también sabe
      insertar una que no estaba, después de `file:`.
- [x] `src/attract/instalar.py::construir_bloque_declarado(game: dict,
      assets: list[tuple[str, str]]) -> Bloque` — mismo espíritu que
      `ingest.construir_bloque`, sin `mame`, siempre agrega
      `x-procedencia: declarada` (ADR-0026). Hecho cuando: un `game.json`
      mínimo (solo obligatorios, `assets=[]`) genera un bloque válido para
      `attract doctor`.
- [x] `src/attract/instalar.py::aplicar` — orquesta lo anterior en el orden
      assets → `data.json` → bloque `game:` (ver `plan.md` §Riesgos), exige
      que `<sistema>/metadata.pegasus.txt` ya exista. Hecho cuando: importar
      sobre un `set` ya ingestado por MAME no toca `file:`/`x-set:`; importar
      sobre un `set` nuevo lo crea con `x-procedencia: declarada`; importar
      con `system` inexistente falla sin crear nada.
- [x] `src/attract/instalar.py::aplicar` — escritura de `data.json`
      preservando `mags[]` existente si el paquete no trae uno. Hecho cuando:
      reimportar sin `mags` en el paquete no borra un `mags[]` que
      `attract mags --apply` haya escrito antes.
- [x] `src/attract/instalar.py::aplicar` — por cada asset copiado directo a
      `media_dir/` (no `_manual/`), mergear una línea `assets.<clave>:
      media/<set>/<archivo>` en el bloque (clave = nombre sin extensión, sin
      lista cerrada — ADR-0027). Hecho cuando: `boxFront.png` genera
      `assets.boxFront: media/<set>/boxFront.png` y un nombre no reconocido
      por Pegasus se copia y se linkea igual, sin error.
- [x] `src/attract/cli.py` — registrar `"import": instalar.main` en
      `COMANDOS` y en el texto de `--help`. Hecho cuando:
      `attract import <paquete.zip> <ruta>` corre desde la CLI.

## Tests

- [x] Caso feliz: paquete completo (identidad + assets + data.json + manual)
      sobre un `set` nuevo → bloque creado, `attract doctor` en verde.
- [x] Caso feliz: mismo paquete sobre un `set` ya ingestado por MAME → merge,
      `file:`/`x-set:` sin cambios.
- [x] Caso límite: paquete sin `manual/` ni assets, solo `game.json` mínimo
      (`system`/`set`/`title`) → juego válido pero desnudo (CONVENCION §4.3).
- [x] Caso de fallo: zip con path traversal → error explícito, `git status`
      (o equivalente en el árbol de test) sin cambios.
- [x] Caso de fallo: `game.json` sin `set` → error explícito, cero escritura.
- [x] Caso de fallo: `data.json` con `manual` como objeto suelto (forma
      pre-ADR-0023) → error explícito, mismo mensaje que `doctor`.
- [x] Invariante: reimportar el mismo paquete dos veces dos veces produce el
      mismo árbol de archivos (bytes idénticos donde aplica).
- [x] Invariante: `mags[]` preexistente sobrevive a un reimport sin `mags` en
      el paquete nuevo.
- [x] Caso de fallo: `system` cuyo `metadata.pegasus.txt` no existe → error
      explícito, cero escritura (ni siquiera crea la carpeta).
- [x] Caso feliz: un asset `boxFront.png` en el paquete genera
      `assets.boxFront: media/<set>/boxFront.png` en el bloque.

## Cierre

- [x] Validar contra todos los criterios de aceptación de `spec.md`.
- [x] `spec/features/015-carga-guiada/tasks.md` — confirmar que la tarea de
      `ingest --titulo` ya no dice "bloquea", apunta a ADR-0026 (hecho en
      esta misma sesión, verificar que sigue así).
- [x] `CLAUDE.md` — agregar `import` a la tabla de comandos y `instalar.py`
      al mapa de `src/attract/`.
- [x] `spec/constitution/tech-stack.md` — agregar `instalar.py` a la tabla de
      archivos/módulos clave.
- [x] Mover la feature a "Hecho" en `../../constitution/roadmap.md`.
- [x] Actualizar `docs/contrato-paquete-coindoor.md` si algo cambió respecto
      al ADR durante la implementación (no debería — el ADR se escribió
      antes que el código).
