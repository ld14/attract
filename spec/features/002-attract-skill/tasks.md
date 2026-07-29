# 002 · Claude Skill de ATTRACT — Tareas

_Checklist accionable derivada del `plan.md`._

## Implementación

- [x] Escribir `.claude/skills/attract/SKILL.md` con frontmatter
      `name`/`description` (disparadores concretos en español) y las tres
      secciones de `plan.md` (cuándo `doctor`, cuándo `synopsis`, reglas
      duras). Hecho cuando: el archivo existe y cada sección tiene el
      comando exacto a correr, no una paráfrasis. `attract doctor` sobre
      `.claude/` da OK (encoding/NFC/CRLF limpios).
- [x] Sacado `.claude/skills/.gitkeep` — ya no hace falta, la carpeta tiene
      contenido real (`attract/SKILL.md`).

## Validación — confirmada 2026-07-29, sesión nueva de Claude Code

_Corrida por el autor en una sesión real de Claude Code, sin el contexto
de la conversación donde se escribió el `SKILL.md` — es la prueba real de
que la `description` dispara sola, no una expectativa de quien lo escribió._

- [x] Caso feliz 1: "agregué un juego nuevo a fixtures/arcade, fijate si
      quedó bien" → el agente cargó el skill (`Skill(attract) Successfully
      loaded skill`) y corrió `make doctor` sin que se lo pidieran
      explícito. Confirmado.
- [x] Caso feliz 2: "ya tengo el synopsis de mok" → corrió
      `attract synopsis mok` y `doctor` después, sin pedírselo. Confirmado.
- [x] Caso límite ERROR: archivo con byte inválido (`0x93`) en
      `fixtures/arcade/` → el agente corrió `doctor`, reportó el ERROR
      exacto (byte inválido, mojibake en Windows) y preguntó si el archivo
      era intencional en vez de "arreglarlo" adivinando. Confirmado.
- [x] Caso límite AVISO: en el caso feliz 1, `doctor` devolvió 1 aviso
      (`mags-ref-faltante`) — el agente lo mencionó explícitamente
      ("degradación esperada y documentada, no es cosa tuya, no tocar") y
      siguió sin bloquearse. Confirmado de yapa, no hizo falta un caso
      aparte.

## Cierre

- [x] Validar contra los criterios de aceptación de `spec.md` — 6 de 6
      cumplidos, incluido el disparo real (arriba).
- [x] Movido `002-attract-skill` a "Hecho, sin salvedades" en
      `../../constitution/roadmap.md`.
