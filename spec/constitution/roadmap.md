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
11. **`spec/features/002-attract-skill/` — implementada.** M4 del
    bootcamp. `.claude/skills/attract/SKILL.md`: le dice a un agente
    cuándo correr `attract doctor` (algo cambió en `fixtures/`/`library/`)
    y `attract synopsis` (apareció `_synopsis/<set>.json`), más las reglas
    duras que podría romper sin saberlo (ADR-0002, `library/` fuera de
    git). Sin código nuevo — el entregable es el `SKILL.md`. Queda
    pendiente verificar que la `description` dispare sola en una sesión
    nueva (no se puede confirmar desde la misma sesión donde se escribió).
12. **`spec/features/003-attract-mcp/` — implementada.** M5 del bootcamp.
    `attract mcp` levanta un servidor MCP por stdio con dos tools
    (`attract_doctor`, `attract_synopsis`) que llaman directo a la lógica
    ya existente. **ADR-0012**: primera dependencia externa del proyecto
    (`mcp`, SDK oficial) — opcional y acotada, import perezoso solo dentro
    de `mcp_server.py`; `doctor`/`synopsis`/`cli` siguen funcionando sin
    el paquete instalado, confirmado con un test que lo bloquea vía
    `sys.modules`. 8 tests nuevos. **38 tests en total** (19 `doctor` + 11
    `synopsis` + 8 `mcp`).
13. **`spec/features/004-attract-ingest/` — implementada.** M7 del
    bootcamp, el último módulo planeado en `cli.py`. `attract ingest
    <rom.zip>` es el primer comando que **crea** un `game:` nuevo (no
    edita uno existente): identifica el set con `mame -listxml` (stdlib
    `xml.etree.ElementTree`, sin romper el límite duro), exige
    exactamente una máquina jugable — cero o más de una falla explícito,
    sin adivinar (el caso ">1" reabre la verificación pendiente de
    ADR-0004 si aparece de verdad). Crea `media/<set>/` vacía. 10 tests
    nuevos, todos contra un XML **sintético** (no hay `mame` en este
    sandbox) salvo uno que sí corre contra la ausencia real del binario.
    Con esto los cuatro módulos planeados originalmente en `cli.py` (M4,
    M5, M7 + `doctor`/`synopsis` de M0-M2) están implementados.
14. **`003-attract-mcp` — roundtrip de protocolo real, cerrado
    2026-07-29.** Se intentó instalar `mame` vía `apt` en este sandbox —
    no hay acceso root, no se pudo. En cambio sí se pudo cerrar algo real:
    un cliente MCP oficial (`mcp.client.stdio` + `ClientSession`) hablando
    el protocolo completo — `initialize` → `list_tools` → `call_tool` —
    contra `python -m attract.mcp_server` como subproceso de verdad, no
    contra las funciones internas mockeadas. Nuevo test
    `test_roundtrip_protocolo_real_via_stdio`. **49 tests en total.**
    Sigue sin ser Claude Desktop/Claude Code — ver `Siguiente` punto 2.
15. **`004-attract-ingest` — forma del XML confirmada contra `mame` real,
    2026-07-29.** El autor corrió `mame -listxml sf2ce` (mame vanilla
    0.288) en su Mac y pegó la salida completa en el chat — evidencia
    real, no una suposición. Confirmado: el `DOCTYPE` con subset interno
    no rompe `ET.fromstring`, `<description>`/`<year>`/`<manufacturer>`
    son los tags correctos, `runnable="no"` filtra bien. **Hallazgo
    nuevo:** el título real trae basura de región pegada de verdad
    (`"... (World 920513)"`) — decidido dejarlo crudo, sin limpieza por
    regex (ver `spec.md` §Fuera de alcance, que ya lo anticipaba). Nuevo
    test `test_forma_real_confirmada_2026_07_29` con el XML real como
    evidencia permanente. **50 tests en total** (19 `doctor` + 11
    `synopsis` + 9 `mcp` + 11 `ingest`). Sigue abierto un punto menor: si
    Pegasus acepta `release: <solo año>` en pantalla — necesita el
    gabinete, no solo el parser.
16. **ADR-0011 — verificación de formato diferida a propósito,
    2026-07-29.** El autor va a generar `_synopsis/<set>.json` con un
    proceso externo propio; hasta que ese proceso exista, no hay nada
    real contra qué verificar. Se agregó `fixtures/arcade/_synopsis/
    sf2ce.json` como segundo ejemplo del contrato mínimo (`{"summary":
    "..."}`), junto al `mok.json` que ya existía — sin pretender que esto
    cierra la verificación pendiente de la ADR, que sigue abierta.
17. **`002-attract-skill` — disparo confirmado, 2026-07-29.** El autor
    corrió una sesión real de Claude Code (sin el contexto de esta
    conversación) y probó los cuatro casos de `tasks.md` §Validación en
    una sola corrida: el skill cargó solo, corrió `make doctor` y
    `attract synopsis mok` sin que se lo pidieran, reportó un ERROR real
    (byte inválido) sin intentar adivinarle un arreglo, y mencionó un
    AVISO sin bloquearse. Los 6/6 criterios de aceptación de `spec.md`
    quedan cumplidos. **Con esto no queda ninguna verificación pendiente
    en todo el proyecto que dependa de este agente — solo el punto menor
    de `release:`/Pegasus de abajo, que necesita el gabinete.**

## Siguiente 🔜

1. **`004-attract-ingest`** — punto menor: confirmar en el gabinete real
   si Pegasus acepta `release: <solo año>` en pantalla. No bloqueante,
   ajuste de una línea si hace falta.
2. **`003-attract-mcp`** — probar contra **Claude Desktop o Claude Code**
   de verdad (`mcp.json` real, tools visibles en la UI). El protocolo en
   sí ya está verificado de punta a punta (ver punto 14 de "Hecho"); lo
   que falta es específicamente la experiencia con un cliente de
   escritorio, que necesita tu máquina.

## Backlog / ideas 💡

- **Procedencia IA vs. manual** (§3 de `CONVENCION.md`) — decidido no
  distinguir, campo `x-procedencia` dejado por si se reconsidera. No hay
  disparador concreto todavía para revisitarlo.
- **ADR-0011, formato real de `_synopsis/<set>.json`** — diferido hasta
  que el proceso externo de scraping del autor exista de verdad (ver
  punto 16 de "Hecho"). No es bloqueante para nada del resto del proyecto.

> Cada feature nueva se crea como `features/NNN-nombre/` con `spec.md`,
> `plan.md` y `tasks.md` **antes** de tocar código.
