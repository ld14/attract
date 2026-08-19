# Fixtures de revistas

Datos **inventados**. No son escaneos reales: son el mínimo necesario para que el
theme y el doctor tengan un `magazine.json` que masticar sin depender de que el
subsistema de revistas exista.

Ver [`docs/decisiones/2026-07-23.md`](../../docs/decisiones/2026-07-23.md),
puntos 5 y 6: ATTRACT es **consumidor** del contrato, no productor. Este directorio
es exactamente lo que el punto 6 dice que alcanza para desarrollar y testear
ATTRACT entero — un `magazine.json` escrito a mano.

## Dónde vive esta carpeta, y por qué acá

`_magazines/` cuelga de la **raíz de `fixtures/`**, hermana de `arcade/` — no de
`arcade/media/`, que es donde estaba hasta
[`ADR-0024`](../../spec/decisions/0024-contrato-magazine-json-v2.md). Una revista
habla de juegos de varios sistemas a la vez, así que vivir adentro de uno
obligaría a copiarla en todos. El theme la resuelve como
`<dir-colección>/../_magazines/<ref>/`.

Cada revista tiene la misma forma que produce el subsistema de escaneo:

```
micromania-16/
├─ magazine.json
├─ cover.png        ← la tapa va en la raíz
└─ pages/
   └─ p001.png …    ← las páginas van acá
```

## Qué caso cubre cada uno

| Fixture | Caso |
|---|---|
| `micromania-16/` | Revista completa y bien formada, contrato de **ADR-0024** (con `key_id`, `type`, `confidence`, flags de review). Dos artículos: uno `review` de `dino` con páginas **no consecutivas** (3,4,5,7,8, cortada justo por el segundo artículo) y un `publicidad` en la página 6 sin `game`/`title` — el caso que motiva la no-consecutividad, encarnado literalmente |
| `arcade/media/dino/data.json` | Juego que referencia una revista que **sí** existe |
| `arcade/media/sf2ce/data.json` | Juego cuyo `mags[].ref` apunta a una revista **inexistente** → degradación |
| `arcade/media/mok/` | Juego **sin** `data.json` → degradación (juego pelado) |

Los tres últimos son los fixtures de las verificaciones pendientes del handoff.

## Convención de nombre de página

`p001.png`, con ceros a la izquierda, para que el orden alfabético sea el orden
real de la revista.

**Las cuatro revistas arrancan en `p001`**, y eso las hace incapaces de
distinguir las dos lecturas posibles de `startPage` — con la página 1 presente,
"índice del array" y "número de página impresa" dan lo mismo. Por eso el bug de
ADR-0024 solo apareció con una revista real, que arranca en `p002` porque su
página 1 es la tapa. Si se agrega un fixture nuevo, uno que arranque en `p002`
paga solo: es el único que cubre esa diferencia.

Las imágenes tienen el **número impreso grande** (~2 KB cada una, generadas). El
número es el punto: sin él no se puede verificar que hojear avance, que
`startPage` abra donde debe, ni que una miniatura salte a la página correcta.

## Nombre con acento, a propósito

`"name": "MICROMANÍA"` lleva tilde deliberadamente: es el caso de ida y vuelta
UTF-8/NFC que ADR-0001 dejó como verificación pendiente.
