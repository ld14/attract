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

## Validación — pendiente, necesita una sesión nueva

_No puedo marcar estos yo mismo: los escribí en esta misma conversación,
así que ya sé qué se supone que tienen que disparar — no es una prueba
real de si la `description` dispara sola. Necesita correrse en una sesión
distinta, sin este contexto._

- [ ] Caso feliz 1: describir un cambio en `fixtures/` (ej. "agregué un
      juego nuevo a fixtures/arcade") a un agente con el skill instalado —
      tiene que correr `attract doctor` sin que se lo pidan explícitamente.
- [ ] Caso feliz 2: describir que apareció un `_synopsis/<set>.json` — el
      agente tiene que correr `attract synopsis <set>`.
- [ ] Caso límite: `doctor` devuelve ERROR — el agente tiene que reportarlo
      y no seguir como si nada, no "arreglarlo" adivinando qué falta.
- [ ] Caso límite: `doctor` devuelve solo AVISO — el agente sigue, pero lo
      menciona.

## Cierre

- [x] Validar contra los criterios de aceptación de `spec.md` — 5 de 6
      cumplidos, el sexto (disparo real) queda para la validación de
      arriba.
- [x] Movido `002-attract-skill` a "Hecho" en
      `../../constitution/roadmap.md` (con la salvedad de la verificación
      de disparo, igual que se hizo con las verificaciones "bien dummy"
      de Pegasus).
