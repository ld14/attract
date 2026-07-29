# 001 · Synopsis generado — Plan

_Cómo se implementa lo descrito en `spec.md`. Respeta `constitution/` y
[`ADR-0011`](../../decisions/0011-fuente-synopsis-regeneracion-campo.md)._

## Enfoque

`metadata.pegasus.txt` no tiene hoy ningún parser estructurado — `doctor.py`
lo trata como texto plano línea a línea. Para hacer un merge de campo
seguro, `attract synopsis` necesita reconocer los **bloques** `game:` (dónde
empieza y termina cada uno) sin tocar el resto del archivo byte a byte. Se
implementa como un módulo nuevo, separado de `doctor.py` (que es
deliberadamente solo-lectura): `doctor` valida, `synopsis` es el primer
módulo que escribe. La identidad del juego para matchear `<set>` reusa la
misma señal que ya usan los fixtures: `x-set:` si está presente, si no el
nombre de `file:` sin extensión (ver ADR-0004).

## Implementación

1. `src/attract/synopsis.py` — módulo nuevo:
   - `leer_fuente(root, sistema, set_id) -> str | None` — lee
     `library/<sistema>/_synopsis/<set_id>.json`, valida que tenga `summary`
     (string, no vacío), devuelve el texto o `None` si no existe/es
     inválido.
   - `parsear_bloques(texto: str) -> list[Bloque]` — separa el archivo en
     bloques `game:` (cada uno con sus líneas crudas, sin perder nada) más
     el header (`collection:`, `shortname:`, `launch:`) antes del primer
     `game:`.
   - `identificar_set(bloque: Bloque) -> str | None` — `x-set:` si existe,
     si no `file:` sin extensión.
   - `mergear_summary(bloque: Bloque, texto_nuevo: str) -> Bloque` — quita
     la línea `summary:` existente y sus líneas de continuación (indentadas)
     si las hay, inserta la nueva `summary:` justo después de `file:`.
     Normaliza a NFC antes de insertar (mismo criterio que `chk_metadata`
     en `doctor.py`).
   - `escribir(path: Path, bloques: list[Bloque]) -> None` — reserializa el
     archivo completo (header + bloques, cada uno en su posición original),
     siempre con `\n`, nunca `\r\n`.
2. `src/attract/cli.py` — agregar `"synopsis": synopsis.main` a `COMANDOS`.
3. Reusa `unicodedata.normalize("NFC", ...)` de `doctor.py` — no se
   reimplementa, se importa.

## Decisiones

- **Fuente persistida por campo, merge quirúrgico, no regeneración total**
  — ver [`ADR-0011`](../../decisions/0011-fuente-synopsis-regeneracion-campo.md).
- **Identidad por `x-set:` o `file:` sin extensión** — mismo criterio que ya
  usan los fixtures existentes (`mok`, `sf2ce`, `test-multifile`); no hace
  falta `mame -listxml` para esto, ya está resuelto por ADR-0004.
- **Módulo separado de `doctor.py`** — `doctor` es y sigue siendo
  solo-lectura; mezclar un módulo que escribe complicaría razonar sobre qué
  puede tocar el archivo real.
- **Reserializar el archivo entero en cada corrida** (no un patch de texto
  con `sed`-like) — más simple de razonar y testear que edición in-place por
  offsets de byte, y el resultado es el mismo (idempotente) porque
  `parsear_bloques` conserva todas las líneas no tocadas tal cual.

## Riesgos

- **El formato de `_synopsis/<set>.json` es un supuesto, no evidencia real**
  (ver ADR-0011, Verificaciones pendientes) — se mitiga con `leer_fuente`
  validando explícitamente la forma esperada y fallando claro si no
  matchea, en vez de asumir silenciosamente. Si el sistema externo real
  entrega algo distinto, se ajusta ahí sin tocar el resto del pipeline.
- **Un juego con el mismo `x-set:` repetido en dos bloques** (no debería
  pasar, pero no hay chequeo hoy) — `identificar_set` matchearía el primero
  que encuentre; se agrega un chequeo explícito en los tests (ver
  `tasks.md`) para que el comportamiento sea determinístico y no silencioso.
