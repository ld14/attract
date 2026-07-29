# 002 · Claude Skill de ATTRACT — Plan

_Cómo se implementa lo descrito en `spec.md`._

## Enfoque

Sin código: el entregable es un único archivo markdown,
`.claude/skills/attract/SKILL.md`, siguiendo el formato ya usado por el
resto del ecosistema de skills (frontmatter `name`/`description` +
instrucciones en el body). La `description` hace todo el trabajo de
disparo — un agente la lee para decidir si el skill aplica, nunca lee el
body a menos que ya haya decidido invocarlo — así que tiene que traer
disparadores concretos en español, no una descripción genérica.

## Implementación

1. `.claude/skills/attract/SKILL.md`:
   - Frontmatter: `name: attract`, `description` con los dos disparadores
     de `spec.md` en lenguaje natural (frases que Luis realmente diría:
     "agregué un juego nuevo", "ya tengo el synopsis de X", "revisá la
     librería").
   - Sección "Cuándo correr `doctor`": el disparador 1, comando exacto,
     qué hacer con ERROR vs. AVISO.
   - Sección "Cuándo correr `synopsis`": el disparador 2, comando exacto
     (`attract synopsis <set> <ruta-sistema>`), qué pasa si no hay fuente
     todavía (no es un error del skill, es el estado normal de la mayoría
     de los juegos — no todos van a tener synopsis).
   - Sección "Reglas duras": enlaza `CLAUDE.md` y las ADRs relevantes
     (0002 metadata es artefacto, `library/` fuera de git) para que el
     agente no las viole por no saber que existen.
2. `tests/.gitkeep` u otro mecanismo de test no aplica — no hay código que
   testear. La validación es manual: instalar el skill y confirmar que un
   agente lo dispara en los dos casos de `spec.md`.

## Decisiones

- **Un solo skill para `doctor` + `synopsis`, no dos separados** — ambos
  comparten el mismo contexto (recién se tocó la librería) y un agente que
  necesita uno probablemente necesita enterarse del otro también. Separarlos
  duplicaría la sección de "reglas duras" sin aportar nada.
- **Skill de proyecto (`.claude/skills/`), no plugin redistribuible** — el
  skill referencia rutas y comandos específicos de este repo
  (`fixtures/arcade`, `attract doctor`), no tiene sentido fuera de él.
- **Sin subcomando CLI** — decidido explícitamente en `spec.md`, fuera de
  alcance.

## Riesgos

- **La `description` no dispara cuando debería** (el agente no la lee
  fuera de contexto correcto) — se mitiga escribiendo disparadores
  literales, cercanos a como Luis habla, no paráfrasis técnica. Si en la
  práctica no dispara, es un problema de redacción de la `description`,
  se ajusta sin tocar el resto del skill.
