---
id: 0017
title: "Los providers de Pegasus que no son de ATTRACT se apagan por config, no se filtran en el theme"
status: accepted
date: "2026-07-29"
supersedes: null
superseded-by: null
tags: [frontend, infra]
---

# 0017 — Providers de Pegasus: se apagan, no se filtran

## Contexto

Al correr el esqueleto del theme contra Pegasus real (feature 005, tarea 1)
apareció algo que no estaba en ninguna suposición del proyecto: el panel de
diagnóstico reportó **6 juegos donde los `metadata.pegasus.txt` declaran 5**.

El sexto era **Cities: Skylines**, que no está en ningún metadata de ATTRACT.
Sale de la librería de Steam del autor. `~/Library/Preferences/pegasus-frontend/settings.txt`
tenía cinco providers activos:

```
providers.pegasus_media.enabled: true
providers.steam.enabled: true
providers.es2.enabled: true
providers.logiqx.enabled: true
providers.skraper.enabled: true
```

**El hallazgo real, más allá del juego puntual:** `api.allGames` **no es "la
librería de ATTRACT"**. Es la unión de todo lo que Pegasus encontró con todos
sus providers. Un juego que entra por Steam:

- no tiene `x-set`, así que `Paths` no puede derivar `media/<set>/`
- no tiene `data.json`, así que no tiene accent (ADR-0013), reseña ni trucos
- no vive en un directorio de colección de ATTRACT

Si `LibraryScreen` itera `api.allGames` a secas, lo va a mostrar. Hay que
decidir qué se hace con eso antes de escribir esa pantalla.

## Decisión

**Los providers que no son de ATTRACT se apagan en la configuración de
Pegasus.** El theme itera `api.allGames` tal cual, sin filtro propio — que es
lo idiomático en un theme de Pegasus.

Se aplica la misma regla que ya rige para MAME
([`ADR-0005`](0005-runtime-mame-vanilla.md)) y para Pegasus
([`ADR-0006`](0006-version-politica-pegasus.md)): **la configuración de
providers es idéntica en el Mac de desarrollo y en el gabinete.** Si no, el
Mac muestra una librería y el gabinete otra, y las diferencias aparecen recién
cuando ya no hay a quién preguntarle.

**Lo que esta decisión NO relaja:** el theme sigue obligado a degradar sin
romperse ante un juego sin `x-set`, sin `data.json` o sin assets
(`docs/CONVENCION.md` §2.3). Eso ya era obligatorio, ya tiene fixtures que lo
encarnan (`EXPERIMENTO` no tiene `x-set`; `media/mok/` no tiene `data.json`) y
no se toca. La decisión es sobre **qué se lista**, no sobre qué tan robusto es
el theme al listarlo.

## Alternativas consideradas

### A · El theme filtra: solo muestra las colecciones que ATTRACT declara

- A favor: funciona con cualquier configuración de Pegasus, sin depender de que
  alguien haya tocado un setting. El theme se vuelve autosuficiente.
- En contra: es código nuevo que hay que mantener, y su **modo de falla es el
  peor de los dos**. Si mañana se agrega una colección y no entra en el
  criterio del filtro, el juego **desaparece sin decir nada** — un juego
  invisible es mucho peor que un juego de más, porque nadie lo va a extrañar
  hasta que lo busque. Apagar un provider falla del lado seguro: como mucho se
  ve algo que no se quería, y se ve.
- **Descartada porque:** paga con código y con un modo de falla silencioso algo
  que Pegasus ya resuelve con un setting.

### B · Mostrar todo, degradando

- A favor: máxima compatibilidad con cómo funciona Pegasus; cero config, cero
  código.
- En contra: el gabinete mezcla PC y arcade, y las fichas de los juegos que
  entran por otros providers quedan a medio llenar — accent neutro, sin
  reseña, sin revistas, sin trucos. `mission.md` es explícita: esto es una
  **máquina recreativa** dedicada.
- **Descartada porque:** la pantalla de detalle está diseñada alrededor de
  datos que un juego de Steam nunca va a tener. No es un problema técnico, es
  que no es lo que el gabinete es.

## Consecuencias

**Positivas**

- Cero código: no hay filtro que escribir, mantener ni testear.
- `LibraryScreen` puede iterar `api.allGames` directo, que es lo idiomático.
- Reversible en un click si algún día se quieren juegos de PC en el gabinete.

**Coste asumido**

- **Mueve un requisito a configuración.** Un Pegasus recién instalado trae los
  providers en `true` por default, así que un gabinete nuevo (o una
  reinstalación) empieza mal hasta que alguien lo corrige. Es exactamente el
  mismo coste que ya se aceptó con la versión de MAME.
- La config de Pegasus no vive en el repo (está en `~/Library/Preferences/`),
  así que esto no se puede validar con `attract doctor` como el resto de las
  reglas del proyecto. Queda como paso manual documentado.

**Qué habría que revisar si esto se replantea**

- Que el gabinete deje de ser dedicado a arcade/retro y se quiera que muestre
  juegos de PC de verdad. Ahí la alternativa B pasa a ser la correcta.
- Que aparezca una segunda persona configurando gabinetes, donde depender de
  un setting manual deja de ser razonable — ahí el filtro de la alternativa A
  empieza a valer lo que cuesta.

## Referencias

- Corrida del esqueleto del theme contra Pegasus real, 2026-07-29:
  `spec/features/005-theme-base/tasks.md` §1.
- [`ADR-0005`](0005-runtime-mame-vanilla.md) y
  [`ADR-0006`](0006-version-politica-pegasus.md) — la misma regla de paridad
  entre el Mac y el gabinete, aplicada a MAME y a Pegasus.
- `docs/CONVENCION.md` §2.3 — la degradación que esta decisión **no** relaja.
- `spec/constitution/mission.md` — el gabinete es una máquina recreativa
  dedicada.
