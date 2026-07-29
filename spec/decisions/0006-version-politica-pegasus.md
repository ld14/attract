---
id: 0006
title: "Frontend: seguir con Pegasus, versión fijada e idéntica en ambas máquinas"
status: accepted
date: "2026-07-28"
supersedes: null
superseded-by: null
tags: [infra, frontend]
---

# 0006 — Versión y política de Pegasus

## Contexto

Pegasus es el frontend elegido para el gabinete. A diferencia de MAME
([`ADR-0005`](0005-runtime-mame-vanilla.md)), nunca se había formalizado una
política de versión ni se había confirmado que seguir con Pegasus siga
siendo la decisión correcta, más allá de que ya se venía usando.

**Hallazgos verificados (no supuestos):**

- Build actual del autor: `Pegasus alpha16-82-gc3462e68`, macOS, Qt 5.15.10.
- El repo oficial (`github.com/mmatyas/pegasus-frontend`) confirma: el
  último release es "Weekly release #38, 2024" — 5 de octubre de 2024. No
  hay nada más nuevo. La build actual no está desactualizada: es
  prácticamente lo último que existe.
- Pegasus está etiquetado `qt5` en GitHub. No hay port a Qt6 completo (hay
  un issue abierto, #1167, sin resolver).
- No existe ningún fork de Pegasus con desarrollo activo en 2025-2026.
- La alternativa más comparable en customización + cross-platform es
  **Attract-Mode Plus** (scripting Squirrel, muy activo, release 3.2.3 de
  abril 2026), pero implicaría reescribir la UI en otro lenguaje.

## Decisión

**Seguir con Pegasus.** Se le aplica la misma regla que a MAME en
ADR-0005: **versión fijada e idéntica en el Mac y en el gabinete.**

El motivo de seguir con Pegasus en vez de migrar a Attract-Mode Plus: el
costo de aprendizaje ya pagado en Pegasus, más su API estable (justamente
por estar congelado, no cambia debajo de los pies del proyecto), pesan más
que el riesgo de que no reciba mantenimiento futuro.

**Riesgo aceptado explícitamente:** al ser un proyecto sin desarrollo
activo, cualquier bug que se encuentre **no se arregla upstream** — hay que
rodearlo desde ATTRACT o el theme. Para un gabinete offline dedicado a una
sola tarea, este riesgo se considera aceptable.

## Alternativas consideradas

### Attract-Mode Plus

- A favor: desarrollo muy activo (release 3.2.3, abril 2026), scripting en
  Squirrel, cross-platform.
- En contra: implica reescribir toda la UI existente en otro lenguaje de
  scripting — se pierde el trabajo ya invertido en el theme de Pegasus
  (QML), incluido el harness de debug de `themes/attract-debug/`.
- **Descartada porque:** el costo de reescritura no se justifica frente al
  costo de simplemente aceptar que Pegasus no recibe actualizaciones — la
  API estable de un proyecto congelado es, en este caso, una ventaja tanto
  como una desventaja.

### Migrar a un fork de Pegasus más activo

- A favor: mantendría la base QML ya conocida.
- En contra: no existe tal fork — se investigó explícitamente y no hay
  ninguno con desarrollo activo en 2025-2026.
- **Descartada porque:** no es una opción real, no existe.

## Consecuencias

**Positivas**

- Cero costo de migración — se sigue construyendo sobre lo ya hecho
  (`themes/attract-debug/`, la evidencia de ADR-0001).
- API estable y predecible: al no recibir actualizaciones, el
  comportamiento de Pegasus no va a cambiar debajo del proyecto sin aviso.
- Mismo patrón que ADR-0005 (MAME) aplicado al frontend: una sola fuente de
  verdad sobre qué versión corre, en las dos máquinas.

**Coste asumido**

- Cualquier bug de Pegasus que se descubra queda sin arreglo posible
  upstream — hay que documentarlo y rodearlo (mismo espíritu que
  `attract doctor`: todo lo que se pueda anticipar, se anticipa).
- Sin roadmap de features nuevas de parte de Pegasus — cualquier
  funcionalidad que falte, la tiene que aportar el theme (QML) o ATTRACT.
- Exige la misma disciplina operativa que MAME: versión fijada, actualizada
  deliberadamente en ambas máquinas a la vez, nunca por separado.

**Qué habría que revisar si esto se replantea**

- Si Pegasus retoma desarrollo activo (señal: un release después de
  octubre 2024), reevaluar si conviene actualizar y a qué versión.
- Si aparece un fork con desarrollo activo real, comparar contra el costo
  ya hundido en la base actual antes de migrar.
- Si el proyecto crece más allá de un gabinete personal (por ejemplo, se
  vuelve multi-usuario o necesita features que Pegasus estructuralmente no
  puede dar), el cálculo de costo-beneficio de Attract-Mode Plus cambia.

## Referencias

- `docs/decisiones/2026-07-23.md` punto 4 — investigación original.
- [`0005-runtime-mame-vanilla.md`](0005-runtime-mame-vanilla.md) — modelo de
  formato y del mismo criterio aplicado a MAME.
- `github.com/mmatyas/pegasus-frontend`, issue #1167 (port a Qt6, abierto).
