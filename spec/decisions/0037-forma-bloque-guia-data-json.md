---
id: 0037
title: "Forma del bloque editorial `guia` en data.json: capas 1+2, sin salida ni botón físico"
status: accepted
date: "2026-09-28"
supersedes: null
superseded-by: null
tags: [data, frontend]
---

# 0037 — `guia`: el bloque editorial de "Cómo se juega"

## Contexto

[`ADR-0036`](0036-guia-tres-capas.md) decidió **separar** la guía "Cómo se
juega" en tres capas con dueños distintos, y dejó la forma exacta del bloque
editorial (capas 1 y 2, las que produce COINDOOR) para cuando el piloto de
datos ([`spec/features/027-como-se-juega/piloto/`](../features/027-como-se-juega/piloto/))
mostrara con qué datos reales hay que trabajar. Mismo patrón que
[`ADR-0023`](0023-manual-multiple-con-pestanas.md) (manual) y
[`ADR-0030`](0030-contrato-gallery-data-json.md) (gallery): primero se mira
lo que el productor ya tiene, después se fija el contrato.

**Lo que el piloto (2026-09-28) mostró sobre 6 juegos reales:**

- COINDOOR **ya recolecta** capas 1+2 para arcade, en `cabinet.button_list`
  (`backend/api/schemas.py:119-130`), poblado desde `buttons_colors` de
  ArcadeDB: `{ "control": "P1_BUTTON1", "action": "Jab Punch", "color":
  "Blue" }`. Los nombres de campo (`control`, `action`, `color`) ya están en
  inglés y ya son los que este ADR necesita — no hay que inventar un
  vocabulario nuevo, hay que **adoptar el que ya existe**.
- Ese dato **no llega al paquete exportado** hoy
  (`backend/bundle/seleccion.py::_tabla()` no incluye `cabinet`) — confirmado
  leyendo el código, no supuesto.
- El texto libre generado (`summary`) **no es confiable sin revisión**: 2 de
  6 juegos del piloto (Pacman, Shuffleshot) tenían sinopsis con errores de
  fondo (un botón inventado; una descripción de otro juego entero). El
  `cabinet` de los mismos dos juegos, en cambio, era correcto en los tres
  casos donde estaba poblado. La confiabilidad no es uniforme dentro del
  mismo `game.json`: depende del campo, no del juego.
- **La salida no puede venir de COINDOOR.** Ya lo dice ADR-0036 y lo repite
  la spec 027 (§Fuera de alcance: "Unificar el vocabulario de botones con los
  trucos" no aplica acá, pero **"Cómo salir" sí es explícito** en la spec como
  parte del panel) — pero la tecla de salida depende del emulador **y de la
  configuración de esta máquina** (MAME: `Esc`, por `confirm_quit` en
  `mame.ini`; DOSBox: confirmado `Ctrl+F9` para config sin `mapperfile`, ver
  `piloto/prehistorik.md`). COINDOOR no conoce el gabinete ni su config
  local — no puede tener razón sobre esto, así que no se le pide.
- **`FieldProvenance` de COINDOOR no viaja al export** (`ADR-0002` de
  COINDOOR, `spec/decisions/0002-procedencia-interna.md` en ese repo,
  `accepted`). El borrador original de este proyecto (`docs/como-se-juega.md`
  §5) pedía "procedencia por grupo" en el paquete — choca directo con esa
  decisión ya tomada del lado de COINDOOR. Este ADR no le pide a COINDOOR que
  reabra su 0002; diseña el contrato para funcionar **sin** eso.

## Decisión

**`data.json` gana un bloque opcional `guia`**, con esta forma:

```json
"guia": {
  "objetivo": "string, 1-2 frases",

  "acciones": [
    { "control": "P1_BUTTON1", "action": "Jab Punch", "color": "Blue" }
  ],

  "primerosPasos": ["string", "..."],
  "reglasEsenciales": ["string", "..."],

  "multijugador": {
    "modo": "individual | cooperativo | versus",
    "jugadores": "number"
  },

  "perifericos": ["joy | trackball | dial | paddle | lightgun | mouse | keyboard"],

  "fuentes": [
    { "tipo": "arcadedb | web | manual", "url": "string?", "fecha": "YYYY-MM-DD", "version": "string?" }
  ],

  "revision": "borrador | revisado"
}
```

Ocho decisiones de forma, no solo la lista de campos:

### 1. `acciones` reusa el vocabulario de `cabinet.button_list` de COINDOOR

Mismos tres campos, mismos nombres (`control`, `action`, `color`). **No** se
inventa `{name, input}` como en `cheats` — ese vocabulario es de trucos
(entrada de teclado → efecto), y acá la clave (`control`) ya es un token
técnico de MAME (`P1_BUTTON1`), no una secuencia de teclas. Reusar el nombre
que COINDOOR ya usa internamente es lo que hace que "cablear `cabinet` al
export" (pedido en `piloto/conclusion.md` §3) sea un mapeo directo, no una
traducción.

`color` es **opcional y describe el gabinete original de ese juego**, no el
de ATTRACT — el theme no lo usa para pintar nada del panel propio (eso es
capa 3, y no lo tiene declarado). Se conserva porque es gratis y puede
ilustrar el diagrama de referencia del juego original.

### 2. Nunca hay un campo de posición física ni de tecla de salida

Ninguna clave de este bloque puede nombrar `JOYCODE_*`, una posición del
panel o una tecla de teclado del emulador. Es el límite que fija ADR-0036
decisión 1 ("nunca nombra un botón físico") y decisión 4 ("de acá sale la
ayuda general... del perfil"), y es la razón de que `salida` **no** sea un
campo de `guia`: sale del perfil físico + la config del emulador en esta
máquina, que `data.json` no puede conocer.

### 3. `primerosPasos` y `reglasEsenciales` van con tope de 3, sin campo que lo declare

El tope es una regla de UI (`spec/features/028-theme-como-se-juega/spec.md`),
no del contrato: `doctor` no rechaza una lista de 5 elementos, el theme
corta en 3. Precedente: `manual`/`gallery` tampoco declaran su propio límite
de presentación en el contrato, lo hace el componente que dibuja.

### 4. `multijugador.modo` es un campo nuevo que ni `-listxml` ni ArcadeDB dan gratis

El piloto lo confirma: `-listxml` da `players="N"`, nunca si es cooperativo
o versus. Tuvo que **asumirse por género** en más de un expediente del
piloto (`piloto/pacman.md`, `piloto/shufshot.md`) — que es exactamente el
tipo de dato que este contrato existe para declarar en vez de adivinar en
el theme.

### 5. `perifericos` usa el mismo vocabulario de tipo de control que `-listxml`

`joy`, `trackball`, `dial`, `paddle`, `lightgun`, más `mouse`/`keyboard` para
DOS (que no tiene `-listxml`). Es intencional: el comando de correspondencia
de la Etapa D (`spec/features/027-como-se-juega/plan.md`) puede comparar
este campo contra `<control type="...">` de `-listxml` sin traducir
vocabularios — el mismo cruce que ya encontró el caso de Shuffleshot a mano
en el piloto se vuelve una comparación de strings.

### 6. `fuentes` es una lista simple, sin procedencia por campo

Un solo lugar para citar de dónde salió **el bloque entero** (URL, fecha,
versión cubierta — el mismo formato que ya pide §1 de `docs/como-se-juega.md`,
"Fuentes web: permitidas, con URL, fecha de consulta y versión cubierta").
**No** hay un `fuentes` por campo (`objetivo.fuente`, `acciones[].fuente`…)
porque eso necesitaría que COINDOOR exporte `FieldProvenance`, y su propio
ADR-0002 dice que no viaja al export. Ver Alternativas, opción C.

### 7. `revision` es un string único para todo el bloque, no por grupo

Mismo motivo que el punto 6: sin procedencia por campo del lado de COINDOOR,
un estado de revisión por grupo sería un campo que nadie puede llenar con
la verdad. Con un solo `revision` para todo el bloque, "borrador" cubre
"todavía no lo miró un humano" y "revisado" cubre "alguien lo leyó y lo dejó
pasar" — que es lo mínimo verificable con lo que COINDOOR puede dar hoy.

### 8. Ausente es un juego sin guía propia, no un error

Igual que `manual`/`gallery`/`cheats`: `guia` ausente es válido. El theme
muestra la ayuda general del gabinete y el aviso "Sin guía específica para
este juego" (criterio de aceptación de
[`spec/features/028-theme-como-se-juega/spec.md`](../features/028-theme-como-se-juega/spec.md)).

## Validación en `attract doctor`

Se agrega a `chk_data_contrato` (`src/attract/doctor.py`), mismo patrón que
`cheats`/`gallery`:

| Chequeo | Nivel |
|---|---|
| `guia` no es objeto | ERROR |
| `objetivo` presente y es string no vacío | ERROR |
| `acciones[]` cada entrada tiene `control` y `action` (string, no vacíos); `color` es opcional | ERROR |
| `primerosPasos`/`reglasEsenciales` son listas de strings | ERROR |
| `multijugador.modo` es uno de los tres valores conocidos | AVISO (no cierra el paso, degrada a "individual") |
| `multijugador.jugadores` es entero ≥ 1 | ERROR |
| `perifericos[]` son strings del vocabulario conocido | AVISO |
| `fuentes[]` cada entrada tiene `tipo` y `fecha` | ERROR |
| `revision` es `"borrador"` o `"revisado"` | AVISO (degrada a `"borrador"`) |
| clave de primer nivel dentro de `guia` desconocida | AVISO |

Criterio ERROR/AVISO igual que siempre: rompe la pantalla o deja sin dato
crítico → ERROR; se degrada solo y sigue siendo útil → AVISO. Es el mismo
aviso por claves desconocidas que pide `docs/como-se-juega.md` §4.D, para no
repetir el modo de falla de [`ADR-0020`](0020-cheats-grupos-libres.md).

## Alternativas consideradas

### A · Copiar `cabinet` tal cual, con sus nombres actuales (`button_list`, no `acciones`)

- A favor: cero traducción, el productor cambia una sola línea (agregarlo a
  `_tabla()` de export).
- En contra: `cabinet` en COINDOOR también trae `resolution`/`orientation`,
  que son datos de **ese** gabinete arcade original (el de 1996, el de
  1997…), no del propio ni de la guía. Exportar el objeto entero mezclaría
  "cómo era el mueble original" con "qué hace el jugador".
- **Descartada porque:** solo `button_list` es capa 1+2 (acción del jugador +
  entrada lógica). `resolution`/`orientation` son datos de gabinete físico
  ajeno — justo lo que ADR-0036 separa. Se toma la parte que corresponde
  (renombrada `acciones` porque "un botón" ya no es la única capa 3 posible
  — ver periféricos), se descarta el resto.

### B · Un array de grupos de nombre libre, como `cheats` (ADR-0020)

- A favor: consistencia con el otro bloque de contenido libre del theme.
- En contra: la guía no tiene la misma variabilidad estructural que los
  trucos. Los 6 juegos del piloto necesitaron exactamente los mismos 7
  campos, ninguno necesitó un grupo que los demás no tuvieran.
- **Descartada porque:** ADR-0020 resuelve un problema real (grupos que
  varían por juego); acá no hay ese problema — hay un contrato fijo que
  cubrió los 6 casos de la muestra sin necesitar extensión. Abrir la puerta
  a grupos libres para un problema que no apareció es complejidad sin pago.

### C · Procedencia por campo, pidiéndole a COINDOOR que reabra su ADR-0002

- A favor: es literalmente lo que pedía el borrador original (`docs/como-se-juega.md`
  §5) y lo que haría el contrato más simétrico con `provenance` interno de
  COINDOOR.
- En contra: depende de una decisión que no es de este proyecto. COINDOOR ya
  decidió, con sus propias alternativas descartadas, que la procedencia es
  interna. Pedirle que la reabra es pedirle que reescriba su arquitectura
  para un campo que ninguno de los 6 juegos del piloto necesitó mostrar por
  grupo.
- **Descartada por ahora:** el contrato de este ADR funciona sin eso (un
  `fuentes`/`revision` por bloque entero). Si en el futuro COINDOOR decide
  exportar `FieldProvenance` de todos modos, sumar procedencia por campo es
  compatible hacia atrás — no rompe nada de lo que este ADR fija hoy.

## Consecuencias

**Positivas**

- El campo que más caro sale de automatizar (`acciones`, capas 1+2) es
  literalmente gratis: COINDOOR ya lo tiene, solo falta que lo exporte.
- El cruce `-listxml` × `perifericos` es una comparación de strings, sin
  traducción de vocabularios — confirmado factible a mano en el piloto
  (caso Shuffleshot).
- `attract doctor` puede rechazar un bloque de guía mal formado antes de que
  llegue al gabinete, incluidas claves de primer nivel desconocidas.
- Un juego sin `guia` sigue siendo válido — enriquecimiento incremental
  (principio §1 de `docs/como-se-juega.md`).

**Coste asumido**

- **Sin procedencia por campo.** Si `objetivo` está mal pero `acciones` está
  bien (el caso real de Pacman y Shuffleshot en el piloto), el `revision`
  único no distingue cuál de los dos hay que revisar — hay que leer el
  bloque entero para saberlo.
- **`perifericos` es un vocabulario cerrado y puede quedarse corto.** Un
  periférico que MAME reconozca y esta lista no nombre entra como AVISO,
  no ERROR, para no bloquear el juego — pero tampoco se detecta como
  "requisito ausente" hasta que se agregue a la lista.
- **La sinopsis (`objetivo`) sigue siendo texto libre generado, sin
  chequeo de contenido posible.** `doctor` valida forma (string no vacío),
  nunca que sea verdad. El caso Shuffleshot ("Shuffleship", un juego
  distinto) pasaría este validador en verde. Mitigación: revisión editorial
  en COINDOOR antes de marcar `revision: "revisado"`, no un chequeo
  automático — no hay chequeo automático posible para "esto describe el
  juego correcto".

**Qué habría que revisar si esto se replantea**

- Si COINDOOR exporta `FieldProvenance` de todos modos (reabre su
  ADR-0002): ahí vale sumar procedencia por campo, compatible hacia atrás.
- Si aparece un periférico real que la lista cerrada no cubre: se amplía el
  vocabulario, no se abre a texto libre (perdería el cruce barato con
  `-listxml`).
- Si `perifericos` termina necesitando más de un tipo por control (un mismo
  juego con trackball Y botones, como Shuffleshot) y hiciera falta declarar
  **cuál** acción usa cuál periférico: hoy `acciones[].control` ya lo dice
  implícitamente (`P1_TRACKBALL_X` vs `P1_BUTTON1`), así que no hace falta
  un campo nuevo — pero si el theme necesitara agruparlos explícitamente,
  ahí se reabre.

## Referencias

- [`ADR-0036`](0036-guia-tres-capas.md) — la decisión de las tres capas que
  este ADR completa con la forma exacta de la capa editorial.
- [`ADR-0020`](0020-cheats-grupos-libres.md) — el precedente de grupos
  libres, evaluado y descartado en la Alternativa B.
- [`ADR-0030`](0030-contrato-gallery-data-json.md) — mismo método: mirar lo
  que el productor ya emite antes de fijar el contrato.
- `spec/features/027-como-se-juega/piloto/` — los 6 expedientes, la matriz y
  la conclusión que fundamentan cada decisión de forma de este ADR.
- `D:\Juegos\COINDOOR\backend\api\schemas.py:119-130` — `CabinetButton`/
  `CabinetInfo`, el vocabulario que este ADR adopta.
- `D:\Juegos\COINDOOR\backend\bundle\seleccion.py::_tabla()` — confirma que
  `cabinet` no viaja al export hoy.
- `D:\Juegos\COINDOOR\spec\decisions\0002-procedencia-interna.md` — el ADR
  de COINDOOR que hace descartar la Alternativa C.
- `spec/features/027-como-se-juega/pedido-coindoor.md` — el pedido preciso
  a COINDOOR que sale de este contrato.
