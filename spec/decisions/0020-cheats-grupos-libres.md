---
id: 0020
title: "cheats acepta grupos con nombre libre y el estilo lo decide el contenido"
status: proposed
date: "2026-08-09"
supersedes: 0015
superseded-by: null
tags: [data, frontend]
---

# 0020 — `cheats` con grupos de nombre libre

## Contexto

[`ADR-0015`](0015-contrato-data-json.md) fijó el contrato de `data.json` y,
dentro de él, `cheats` con **exactamente dos** listas:

```json
"cheats": {
  "combos": [ { "name": "...", "input": "..." } ],
  "codes":  [ { "name": "...", "input": "..." } ]
}
```

Esa forma salió del prototipo HTML, que tenía esas dos secciones dibujadas.
No salió de mirar cómo son los trucos reales de un juego.

**El caso que la rompió, 2026-08-09.** Cargando Golden Axe, el autor escribió
ocho entradas más agrupadas como `secrets`, `two_player` y `service`. El
resultado fue el peor modo de falla posible:

- El theme **ignoró las ocho en silencio** — sólo lee `combos` y `codes`.
- `attract doctor` dio **verde**: valida los grupos que conoce, no rechaza
  los que no.
- La única forma de darse cuenta era abrir Pegasus y contar las entradas.

Es exactamente lo que la filosofía del proyecto quiere evitar ("todo lo que
Windows rechazaría tiene que fallar en el Mac"), con el agravante de que acá
nada "falla": simplemente no se ve.

Y el fondo del problema no es que falten dos o tres claves más: es que
**cuántos grupos tiene un juego, y cómo se llaman, no lo sabe el contrato**.
Un beat 'em up tiene combos; un arcade de placa tiene menú de servicio; un
juego de dos jugadores tiene trucos cooperativos. Fijar la lista por
adelantado garantiza volver a chocar contra esto.

## Decisión

**El nombre del grupo es libre.** `cheats` es un objeto donde cada clave es
un grupo, y su valor puede tomar dos formas:

```json
"cheats": {
  "combos": [ { "name": "...", "input": "..." } ],

  "secretos": {
    "label": "Secretos del juego",
    "items": [ { "name": "...", "input": "..." } ]
  }
}
```

- **Lista directa** — el título sale de la clave: `dos_jugadores` se muestra
  como `DOS JUGADORES`. `combos` y `codes` conservan los títulos que ya
  tenían (`▶ COMBOS`, `★ CÓDIGOS SECRETOS`) para no cambiar lo existente.
- **Objeto con `label` e `items`** — cuando el título tiene que decir algo
  que el nombre de la clave no puede.

Todo lo demás del contrato de ADR-0015 (`accent`, `mags`, `manual`, `review`,
y la forma `{name, input}` de cada entrada) **queda igual**.

**El estilo visual lo decide el CONTENIDO, no el grupo.** Cada entrada se
dibuja como tarjeta con teclas o como renglón en prosa según lo que diga
`core/InputTokens.js:esSecuencia()`: hay botones reconocibles y la prosa que
los acompaña es corta → secuencia; si no → instrucción escrita. Un mismo
grupo puede mezclar las dos, que es como vienen los trucos de verdad.

**`attract doctor` valida la forma, no el nombre.** Un grupo que no sea lista
ni objeto con `items`, o una entrada sin `name`/`input`, sigue siendo error —
en **cualquier** grupo, no sólo en los dos que antes estaban fijos.

## Alternativas consideradas

### A · Dejar el contrato como estaba y documentar mejor

Explicar en la guía que `codes` es el cajón de todo lo que no es un combo.

- A favor: cero código nuevo; el usuario mete todo en `codes` y se ve.
- En contra: obliga a aplanar información que tiene estructura. Ocho trucos
  de tres naturalezas distintas en una sola lista es peor de leer en
  pantalla, y el autor pierde la agrupación que ya había hecho.
- **Descartada porque:** el pedido explícito fue lo contrario ("debería
  poder aceptar cualquier tipo de campo que llegue"), y porque la
  documentación no arregla el modo de falla silencioso — sólo lo explica.

### B · Ampliar la lista fija con los grupos que aparecieron

Agregar `secrets`, `two_player`, `service` al contrato.

- A favor: cambio mínimo, sigue siendo validable contra una lista cerrada.
- En contra: no resuelve nada. El próximo juego trae un grupo que tampoco
  está, y hay que volver a tocar el contrato, el theme y el validador. Ya
  pasó una vez con estos tres.
- **Descartada porque:** trata el síntoma. El contrato no puede saber de
  antemano cómo se agrupan los trucos de un juego que todavía no se cargó.

### C · Grupos libres, pero declarando el estilo por grupo

Que cada grupo dijera cómo dibujarse (`"estilo": "secuencia" | "prosa"`).

- A favor: explícito, sin heurística; el autor controla el resultado.
- En contra: un campo más para escribir a mano en cada grupo, y **no alcanza**
  — dentro de un mismo grupo conviven un combo corto y una explicación de
  tres renglones (pasó en el propio `data.json` de Golden Axe: `combos`
  tenía tres secuencias y un "MAGIA (según las pociones acumuladas)").
- **Descartada porque:** el estilo es una propiedad de la ENTRADA, no del
  grupo. Ponerlo en el grupo obliga a elegir mal para alguna de sus
  entradas.

### D · Detectar el estilo con una heurística sobre el texto crudo

Buscar flechas o signos `+` en el string con una expresión regular.

- A favor: no necesita el tokenizer.
- En contra: duplica —peor, con otra lógica— algo que el tokenizer ya sabe
  hacer bien; y una regex sobre texto libre se equivoca con "En la selección
  de personaje: mantener ← + ↓ y pulsar A + C + START", que tiene flechas y
  signos pero es claramente una instrucción.
- **Descartada porque:** `core/InputTokens.js` ya distingue un botón de una
  palabra, y es la única pieza del theme verificable sin abrir Pegasus. La
  decisión se apoya en sus tokens tipados, no en adivinar sobre el string.

## Consecuencias

**Positivas**

- El contenido manda sobre el contrato: un juego puede agrupar sus trucos
  como tengan sentido para ese juego.
- **El modo de falla silencioso desaparece.** Una forma que el theme no sabe
  dibujar ahora falla en `doctor`, en el Mac, antes del gabinete.
- Retrocompatible: los `data.json` que ya existen con `combos`/`codes` siguen
  funcionando igual y viéndose igual, sin tocarlos.
- El overlay pasó de dos bloques fijos duplicados a un `Repeater` sobre
  grupos — menos código y sin la sección "CÓDIGOS SECRETOS" hardcodeada.

**Coste asumido**

- **La heurística puede errarle.** Una entrada corta con botones que en
  realidad es una instrucción se va a dibujar como secuencia. El corte está
  en 24 caracteres de prosa (`MAX_PROSA_SECUENCIA`), lejos de los dos casos
  reales medidos, pero es un número elegido — no una verdad.
- **El título derivado de la clave es tosco**: `dos_jugadores` sale como
  `DOS JUGADORES`. Para algo más cuidado hay que usar la forma con `label`,
  que es más verbosa de escribir.
- Un grupo con muchas entradas ya no se detalla en la tarjeta del detalle:
  a partir de tres grupos el subtítulo resume ("18 entradas · 4 grupos").

**Qué habría que revisar si esto se replantea**

- Si aparecen entradas donde la detección automática se equivoca seguido —
  ahí `esSecuencia()` deja de ser un ayudante y pasa a ser un estorbo, y la
  salida es la Alternativa C pero **por entrada**, no por grupo.
- Si los nombres de grupo empiezan a repetirse entre juegos con distinta
  grafía (`secretos` / `secrets` / `Secretos`), conviene una lista de
  sinónimos conocidos para unificar el título — sin volver a cerrar el
  contrato.

## Referencias

- [`ADR-0015`](0015-contrato-data-json.md) — el contrato que este ADR
  supersede. Todo lo que no es `cheats` sigue exactamente igual.
- `themes/attract/core/InputTokens.js` — `esSecuencia()` y su verificación
  en `themes/experimentos/verificar-tokens.js`, con los casos reales de
  Golden Axe.
- `themes/attract/core/GameData.qml` — `gruposCheats`, donde las dos formas
  se aplanan a una sola.
- Caso que lo originó: `library/arcade/media/goldnaxe/data.json`, 2026-08-09.
