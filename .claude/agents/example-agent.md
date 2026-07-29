---
name: example-agent
description: <Cuándo usar este agente. Específico y con disparadores concretos — este texto es lo ÚNICO que Claude lee para decidir si invocarlo. Ej: "Analiza un artículo extraído de una revista y devuelve sus claims estructurados. Dispara con 'analiza este artículo', 'extrae los datos de estas páginas'.">
tools: Read, Grep, Glob
model: sonnet
---

<!--
GUÍA — RENOMBRA ESTE ARCHIVO O BÓRRALO
Cada .md de .claude/agents/ es un subagente y necesita frontmatter con `name` y
`description`. NO pongas READMEs ni documentación en esta carpeta: Claude Code
intentará cargarlos como agentes.
`tools` opcional (si se omite hereda todas); limitarlo lo hace más predecible.
`model`: sonnet | opus | haiku.
-->

Eres <rol>. Tu única responsabilidad es <alcance acotado>.

## Proceso

1. <Paso>
2. <Paso>

## Reglas

- <Restricción dura>
- No hagas <cosa fuera de alcance>. Si hace falta, repórtalo y para.

## Salida

Devuelve exactamente:

```
<formato esperado>
```
