---
id: 0026
title: "Un game: puede crearse con identidad declarada a mano, sin mame -listxml"
status: accepted
date: "2026-08-18"
supersedes: null
superseded-by: null
tags: [backend, data]
---

# 0026 — Identidad declarada sin `mame -listxml`

## Contexto

`attract ingest` (M7, [`ADR-0004`](0004-identidad-set-merged.md)) exige
identificar el set con `mame -listxml` antes de crear un bloque `game:` —
cero o más de una máquina jugable falla explícito, nunca adivina. Esa regla
solo cubre **arcade**: es la única forma que ATTRACT tiene hoy de crear un
juego nuevo.

Dos necesidades reales chocan con ese límite:

1. **Sistemas no-MAME** (NES, PC, cualquier colección futura) no tienen
   `mame -listxml` — `spec/features/015-carga-guiada/` ya lo detectó y dejó
   la tarea de `ingest --titulo` **bloqueada** hasta que exista este ADR
   (`tasks.md`: *"Crear el ADR de identidad declarada para sistemas no-MAME...
   Bloquea la tarea de `--titulo`"*).
2. **COINDOOR**, la app externa de carga de datos
   (`spec/features/016-import-coindoor/`), es un formulario que un humano
   llena — título, desarrollador, género — y exporta un paquete. No hay
   ningún XML de MAME de por medio: la identidad la escribe una persona en un
   formulario, igual que hoy la escribe a mano en `metadata.pegasus.txt`
   antes de que exista ninguna herramienta.

Las dos son la misma pregunta con dos disparadores distintos. Resolverla dos
veces (un criterio para `ingest --titulo`, otro para `attract import`) es el
tipo de decisión duplicada que el proyecto ya evita en otros lados (`CLAUDE.md`
§8).

## Decisión

Un bloque `game:` puede crearse **sin verificar contra `mame -listxml`**,
siempre que la identidad venga **declarada explícitamente** por quien la
escribe (persona o herramienta que la persona operó) — nunca inferida ni
adivinada por ATTRACT. El bloque creado así lleva:

```
x-procedencia: declarada
```

Reusa el campo que `docs/CONVENCION.md` §3.1 ya documenta como existente en
los fixtures (`x-procedencia: manual`) pero que hoy no lee nadie — este ADR
le da el primer lector implícito (una persona auditando la librería) y fija
el valor `declarada` para este caso puntual, distinto de `manual` (que en los
fixtures viejos no distinguía nada, ver §3.1). No se inventa un campo nuevo.

**No hay verificación de que el `set`/`file` declarado corresponda a un
romset real.** Es el mismo riesgo que `CONVENCION.md` §3.1 ya acepta para
cualquier campo sin distinguir procedencia — "el reproceso más reciente gana,
sin excepción" (§3.3) — este ADR no sube el estándar de verificación del
proyecto, solo documenta que para identidad **declarada** nunca hubo uno.

Dos consumidores de esta decisión, cada uno con su propio ADR/feature de
implementación:

- `ingest --titulo <título> [--dev ...] [--genero ...] ...` — salta
  `mame -listxml` cuando se pasa `--titulo`. Ver
  [`015-carga-guiada`](../features/015-carga-guiada/plan.md).
- `attract import <paquete.zip>` — crea el bloque desde `game.json` si el
  `set` no existe todavía. Ver
  [`016-import-coindoor`](../features/016-import-coindoor/plan.md) y
  [`ADR-0027`](0027-contrato-paquete-import-coindoor.md).

## Alternativas consideradas

### A · Catálogo de identidad (No-Intro / TOSEC)

Verificar el archivo declarado contra una base de datos de checksums
conocidos para sistemas no-MAME, igual que MAME hace con arcade.

- A favor: mismo nivel de garantía que arcade, cero identidad inventada.
- En contra: No-Intro/TOSEC no son una dependencia que el proyecto tenga hoy
  — habría que descargar y mantener bases de datos por sistema, offline,
  actualizadas a mano (el gabinete no tiene red, [`ADR-0005`](0005-runtime-mame-vanilla.md)).
  Es una responsabilidad nueva y grande para un problema que hoy es "dejar
  cargar NES".
- **Descartada porque:** el costo es desproporcionado al problema. Si en el
  futuro la librería crece lo suficiente como para que la identidad
  incorrecta sea un problema medido (no hipotético), esto se reabre.

### B · Provider externo de Pegasus resuelve la identidad

Delegar en un provider de Pegasus (es2, logiqx) que ya sabe leer catálogos de
otros sistemas.

- A favor: cero código nuevo en ATTRACT.
- En contra: [`ADR-0017`](0017-providers-pegasus.md) ya decidió que los
  providers que no son de ATTRACT se **apagan**, precisamente porque mezclan
  la librería con lo que Pegasus encuentra de Steam/otros. Reactivar uno para
  resolver identidad reabre ese problema para volver a cerrarlo.
- **Descartada porque:** contradice una decisión vigente sin una razón nueva
  que la justifique.

### C · No permitir crear identidad sin MAME, nunca

Mantener el límite actual: solo arcade puede tener juegos, todo lo demás
espera a que exista una fuente verificable.

- A favor: cero riesgo de identidad incorrecta, cero código nuevo.
- En contra: bloquea NES/PC/cualquier sistema futuro indefinidamente, y
  bloquea COINDOOR — la app entera pierde su propósito si no puede crear un
  juego que no fue ingresado antes por otro camino.
- **Descartada porque:** el pedido explícito de esta sesión (COINDOOR) y el
  hueco ya detectado en 015 son evidencia de que el límite actual no alcanza,
  no una preferencia.

## Consecuencias

**Positivas**

- Desbloquea `spec/features/015-carga-guiada/tasks.md` (`ingest --titulo`) y
  `spec/features/016-import-coindoor/` con una sola decisión, no dos que
  podrían terminar en criterios distintos.
- `x-procedencia: declarada` deja rastro legible para quien audite la
  librería más adelante — no resuelve el riesgo, pero lo hace visible.

**Coste asumido**

- Ningún chequeo automático detecta un `set`/`file` declarado que no
  corresponda a un romset real. El síntoma, si ocurre, es un juego que no
  arranca en el gabinete — mismo modo de falla que cualquier `file:` mal
  escrito a mano hoy.
- Dos caminos para crear un `game:` (MAME-verificado y declarado) en vez de
  uno. `attract doctor` no puede ni debe distinguirlos — validar identidad
  declarada está fuera de lo que "todo lo que Windows rechazaría" puede
  cubrir.

**Qué habría que revisar si esto se replantea**

- Si aparece un caso real de identidad declarada incorrecta que cause daño
  medible (no solo un juego que no arranca) — ahí la Alternativa A vuelve a
  la mesa con evidencia real en vez de hipotética.

## Referencias

- [`ADR-0004`](0004-identidad-set-merged.md) — identidad verificada vía MAME,
  el estándar que este ADR no reemplaza, solo complementa para los casos que
  MAME no cubre.
- [`ADR-0017`](0017-providers-pegasus.md) — por qué se descartó la
  Alternativa B.
- `docs/CONVENCION.md` §3.1 y §3.3 — el modelo de riesgo de procedencia que
  este ADR hereda, no inventa.
- [`spec/features/015-carga-guiada/`](../features/015-carga-guiada/) — de
  donde salió la pregunta originalmente, con la tarea bloqueada que este ADR
  desbloquea.
- [`spec/features/016-import-coindoor/`](../features/016-import-coindoor/) —
  el segundo consumidor, que motivó cerrar esto ahora en vez de dejarlo
  bloqueado.
