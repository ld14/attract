---
id: 0003
title: "Estrategia cross-platform: git como puente, doctor como frontera"
status: accepted
date: "2026-07-28"
supersedes: null
superseded-by: null
tags: [infra, proceso]
---

# 0003 — Estrategia cross-platform macOS (dev) → Windows (prod)

## Contexto

Desarrollo en Mac, ejecución en Windows, las dos máquinas reales.

El costo no es el traslado: es el **ciclo**. Si los errores se descubren del
otro lado, se deja de probar.

Irreductibles (solo Windows): reproducción de video (DirectShow, puede
necesitar códecs), `launch:`, performance en el hardware del gabinete.

Todo lo demás es automatizable en el Mac — ver `src/attract/doctor.py`.

Definir: transporte (git), qué va y qué no al repo, cuándo se viaja al
gabinete.

## Decisión

**Git es el único puente.** `git push` en el Mac, `git pull` en Windows —
nada más. Se cruza a Windows solo **después** de que `make doctor` y
`make test` pasan en el Mac, nunca antes.

**Qué viaja por git:**

```
✅  src/  docs/  spec/  tests/  themes/  fixtures/  Makefile  .gitattributes
❌  library/**       ← ROMs, CHDs, assets reales. Pesan y no aportan
❌  *.pegasus.txt    ← artefacto de build (ADR-0002), no se copia a mano
```

El repo entero pesa unos pocos MB — un `git push` normal, sin Git LFS ni
nada especial. (Incluye una excepción a propósito: `fixtures/arcade/sf2ce.zip`
es un romset real de ~3.5 MB, para poder correr `mame -listxml` contra él de
verdad — ver `CLAUDE.md` §Reglas de trabajo.)

**Qué NO se puede verificar en el Mac, solo en Windows** (los irreductibles):

- Que el video reproduzca de verdad (DirectShow puede necesitar códecs que
  no existen en el Mac).
- Que el comando de `launch:` realmente abra el emulador correcto.
- FPS y performance en el hardware físico del gabinete.

Todo lo demás — encoding, nombres ilegales, NFC, estructura de archivos,
assets referenciados que no existen — se prueba en el Mac con `attract
doctor`, sin necesitar cruzar. Esa es la ingeniería de fondo: **no viajar**
es la optimización, no el traslado en sí.

## Alternativas consideradas

### Compartir carpeta en red / sincronización en vivo (Dropbox, SMB, etc.)

- A favor: cambios visibles al instante en ambas máquinas, sin paso manual.
- En contra: sin control de versión — un archivo a medio escribir en el Mac
  puede aparecer roto en Windows a mitad de guardado; no hay forma de volver
  atrás si algo se corrompe.
- **Descartada porque:** git ya resuelve esto (atomicidad de commits,
  historial, revertir) sin costo adicional — no hay ninguna ventaja real de
  la sincronización en vivo que compense perder eso.

### Probar todo en Windows directamente, sin `doctor` en el Mac

- A favor: cero trabajo de mantener un validador aparte.
- En contra: es exactamente el escenario que dispara el costo real
  ("el costo no es el traslado, es el ciclo") — cada iteración de prueba
  exige cruzar, y a la décima vez del día se deja de probar.
- **Descartada porque:** mata la velocidad de iteración, que es el problema
  que esta ADR existe para resolver.

## Consecuencias

**Positivas**

- El repo es liviano y portable — clonarlo no exige mover ROMs ni CHDs.
- La mayoría de los bugs (encoding, nombres, estructura) se detectan en el
  Mac, sin cruzar nunca a Windows.
- Git da historial y reversión gratis, sin necesitar herramientas extra.

**Coste asumido**

- Los irreductibles (video, `launch:`, performance) solo se descubren en
  Windows — no hay forma de eliminar ese cruce por completo, solo minimizar
  cuántas veces hace falta.
- Exige disciplina: no saltarse `make doctor`/`make test` "porque total lo
  pruebo directo en Windows" — si se rompe esa disciplina, se pierde la
  ventaja completa de esta estrategia.

**Qué habría que revisar si esto se replantea**

- Si el ciclo Mac→Windows deja de ser viable (por ejemplo, si se pasa a
  desarrollar directo en Windows, o el gabinete deja de ser una máquina
  separada), esta ADR pierde sentido — ya no habría "cross" que resolver.

## Referencias

- `docs/SETUP.md` §3 "El puente" y §4 "El ciclo diario" — describen el flujo
  real, ahora formalizado acá.
- `docs/SETUP.md` §5 "Verificación final" — checklist que ya opera bajo este
  contrato.
- [`0002-metadata-fuente-o-artefacto.md`](0002-metadata-fuente-o-artefacto.md)
  — por qué `*.pegasus.txt` no viaja por git.
- [`0005-runtime-mame-vanilla.md`](0005-runtime-mame-vanilla.md) — modelo de
  formato a imitar.
