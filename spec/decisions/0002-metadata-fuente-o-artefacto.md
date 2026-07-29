---
id: 0002
title: "La metadata es artefacto de build, no fuente editable"
status: accepted
date: "2026-07-28"
supersedes: null
superseded-by: null
tags: [data, build]
---

# 0002 — ¿La metadata es fuente o artefacto de build?

## Contexto

`launch:` acepta exactamente un comando y no tiene condicionales por
plataforma. Y los comandos no se parecen en nada:

```
macOS:   open /Applications/RetroArch.app --args -L "core.dylib" "{file.path}"
Windows: C:\RetroArch\retroarch.exe -L C:\RetroArch\cores\core.dll {file.path}
```

No existe un `metadata.pegasus.txt` que sirva en los dos lados sin editarlo.

Si la metadata es un **artefacto de build**, el `launch:` pasa de ser un dato
fijo a ser una decisión de renderizado por plataforma — y da el gancho
natural para normalizar a NFC y sanitizar nombres al emitir, en un solo
lugar, una sola vez.

Si es **fuente**, se edita a mano y hace falta mantener una copia por
plataforma sincronizada manualmente — y [`ADR-0005`](0005-runtime-mame-vanilla.md)
(misma versión de MAME en las dos máquinas) se vuelve más caro de sostener,
porque cualquier desincronización entre las dos copias no se detecta sola.

## Decisión

**Es artefacto de build.** `metadata.pegasus.txt` nunca se edita a mano ni
se versiona como fuente — lo genera un comando (`attract build` o similar,
todavía sin implementar) a partir de otra fuente de datos, con un
`--target {macos,windows}` que decide el `launch:` correspondiente y aplica
NFC/sanitización al emitir.

Esto **ya es la práctica de facto** del proyecto, sin estar formalizada
hasta esta ADR:

- `.gitignore` ya excluye `*.pegasus.txt` del repo, con excepción explícita
  para `docs/**/*.pegasus.txt` y `fixtures/**/*.pegasus.txt` — que son
  **entradas de test escritas a mano**, no artefactos reales (simulan lo que
  un build futuro produciría, para poder correr `attract doctor` sin que
  exista el build todavía).
- `docs/SETUP.md` ya trata el archivo como algo que no viaja como fuente
  editable entre las dos máquinas.

Esta ADR no define el formato de la fuente real (de dónde sale el `title`,
el `x-formato`, etc. antes de compilarse a `.pegasus.txt`) — eso es diseño
de un módulo futuro (`attract build` / `attract ingest`, M7). Lo que fija
acá es el principio: **el archivo `.pegasus.txt` no es donde vive la
verdad, es donde se la imprime.**

## Alternativas consideradas

### Fuente editable a mano, una copia por plataforma

- A favor: cero indirección — lo que ves en el archivo es lo que corre.
- En contra: dos copias que hay que mantener sincronizadas manualmente para
  siempre. Cualquier cambio (agregar un juego, corregir un dato) hay que
  aplicarlo dos veces, y una desincronización no se detecta hasta que algo
  falla en una de las dos máquinas.
- **Descartada porque:** viola el mismo criterio que ya protege ADR-0005
  (una sola fuente de verdad entre Mac y Windows) — acá el riesgo es
  metadata desincronizada en vez de `-listxml` desincronizado, pero es el
  mismo problema de fondo.

### Fuente única con `launch:` condicional por plataforma

- A favor: seguiría siendo "fuente", sin build step.
- En contra: el formato de Pegasus no soporta condicionales dentro de
  `launch:` — no es una opción real, es inventar una sintaxis propia que
  Pegasus no entendería.
- **Descartada porque:** técnicamente inviable contra el formato real de
  Pegasus.

## Consecuencias

**Positivas**

- Una sola fuente de verdad real (todavía sin definir su formato exacto),
  compilada a la salida correcta por plataforma — mismo principio que
  ADR-0005 aplicado a datos en vez de a runtime.
- Normalización (NFC, sanitización de nombres) ocurre en un solo lugar al
  emitir, no repetida a mano en cada archivo.
- Los fixtures y ejemplos de `docs/` quedan claramente marcados como
  entradas de test, no como el artefacto real — sin ambigüedad de cuál es
  cuál.

**Coste asumido**

- Existe una dependencia de un build step que **todavía no está
  implementado** (`src/attract/` hoy solo tiene `doctor`). Hasta que exista,
  cualquier metadata real se sigue escribiendo a mano como si fuera fuente,
  aunque conceptualmente ya se trate como artefacto.
- El formato de la fuente real queda sin definir — es deuda de diseño
  explícita que se pasa a un módulo futuro, no una laguna accidental.

**Qué habría que revisar si esto se replantea**

- Si en algún punto se decide que mantener un build step cuesta más que
  mantener dos copias sincronizadas a mano (por ejemplo, si el proyecto
  nunca crece más allá del banco de 5 juegos), reabrir con ese dato
  concreto.

## Referencias

- Modelo de formato a imitar: [`0005-runtime-mame-vanilla.md`](0005-runtime-mame-vanilla.md).
- `docs/SETUP.md` §3.1 "Qué viaja y qué no".
- `.gitignore`, regla de `*.pegasus.txt` con excepciones de `docs/` y
  `fixtures/`.
- `spec/constitution/tech-stack.md` §Límites duros (ya declaraba esto como
  práctica de facto antes de esta ADR).
