# 002 · Claude Skill de ATTRACT — Spec

**Estado:** implementada y verificada — disparo confirmado 2026-07-29 en
una sesión real de Claude Code (ver `tasks.md` §Validación).

## Qué hace

Un Claude Skill de proyecto (`.claude/skills/attract/SKILL.md`) que le dice
a un agente de IA trabajando en este repo (Claude Code, Cowork) **cuándo y
cómo** correr `attract doctor` y `attract synopsis` — sin que el humano
tenga que acordarse de pedirlo cada vez.

No es código nuevo: `doctor` y `synopsis` ya existen y funcionan por CLI
(`src/attract/`). El skill es la capa de instrucciones que conecta "qué
acabo de cambiar en la librería" con "qué comando corresponde correr", el
mismo trabajo que hasta ahora hacía Luis a mano.

Dos disparadores concretos:

1. Se tocó algo bajo `fixtures/`/`library/` (juego nuevo, asset nuevo,
   `data.json`/`magazine.json`/`metadata.pegasus.txt` editado) → correr
   `attract doctor` antes de dar el cambio por terminado.
2. Apareció o cambió `_synopsis/<set>.json` para un juego que ya existe en
   `metadata.pegasus.txt` → correr `attract synopsis <set>`.

## Por qué

Es el módulo M4 del bootcamp: primera vez que ATTRACT se empaqueta para que
un **agente** (no solo un humano por CLI) lo use correctamente sin
supervisión línea por línea. Reduce el mismo riesgo que motivó `doctor` en
primer lugar — un cambio que se ve bien en el Mac pero rompe en Windows —
pero ahora aplicado a que un agente no se "olvide" de correr la validación
después de tocar la librería.

## Criterios de aceptación

- [x] `.claude/skills/attract/SKILL.md` existe, con frontmatter `name` y
      `description` — la `description` es la única señal que un agente usa
      para decidir si invocarlo, tiene que traer disparadores concretos en
      español (no genéricos tipo "ayuda con ATTRACT").
- [x] El body instruye explícitamente los dos disparadores de arriba, con
      el comando exacto a correr en cada caso (`make doctor` /
      `PYTHONPATH=src python3 -m attract.doctor <ruta>`, `attract synopsis
      <set> <ruta>`).
- [x] Instruye qué hacer si `doctor` reporta ERROR (no está listo, corregir
      antes de seguir) vs. AVISO (no bloquea, pero se menciona).
- [x] Enlaza las reglas duras que un agente podría violar sin saberlo:
      `*.pegasus.txt` no se edita a mano salvo fixtures/docs (ADR-0002),
      `library/` nunca va a git.
- [x] Redactado en la misma convención que `.claude/agents/example-agent.md`
      ya establece para este repo (frontmatter + secciones cortas).
- [x] **Verificado 2026-07-29:** la `description` dispara el skill sola
      en una sesión real de Claude Code, sin el contexto de esta
      conversación — ver `tasks.md` §Validación, los cuatro casos
      (2 felices + 2 límite) confirmados en una sola corrida real.

## Fuera de alcance

- Un subcomando `attract skill` en la CLI — no hace falta código Python,
  el entregable es el `SKILL.md`.
- Empaquetar el skill para redistribuirlo fuera de este repo — es un skill
  de proyecto, no un plugin general.
- `attract mcp` (M5) — mismo objetivo con otro protocolo, feature aparte.
