# Fixtures de revistas

Datos **inventados**. No son escaneos reales: son el mínimo necesario para que el
theme y el doctor tengan un `magazine.json` que masticar sin depender de que el
subsistema de revistas exista.

Ver [`docs/decisiones/2026-07-23.md`](../../../../docs/decisiones/2026-07-23.md),
puntos 5 y 6: ATTRACT es **consumidor** del contrato, no productor. Este directorio
es exactamente lo que el punto 6 dice que alcanza para desarrollar y testear
ATTRACT entero — un `magazine.json` escrito a mano.

## Qué caso cubre cada uno

| Fixture | Caso |
|---|---|
| `micromania-16/` | Revista completa y bien formada, contrato de **ADR-0010** (con `key_id`, `type`, `confidence`, flags de review). Dos artículos: uno `review` de `dino` con páginas **no consecutivas** (3,4,5,7,8, cortada justo por el segundo artículo) y un `publicidad` en la página 6 sin `game`/`title` — el caso que motiva la no-consecutividad, encarnado literalmente |
| `media/dino/data.json` | Juego que referencia una revista que **sí** existe |
| `media/sf2ce/data.json` | Juego cuyo `mags[].ref` apunta a una revista **inexistente** → degradación |
| `media/mok/` | Juego **sin** `data.json` → degradación (juego pelado) |

Los tres últimos son los fixtures de las verificaciones pendientes del handoff.

## Convención de nombre de página

`p001.jpg`, con ceros a la izquierda, para que el orden alfabético sea el orden
real de la revista. Está en la lista de pendientes del handoff formalizarlo en
`docs/CONVENCION.md`; acá va aplicado para no bloquear.

Las imágenes son de **0 bytes**, igual que las ROMs de `fixtures/`. Para validar
estructura no hace falta un escaneo de verdad.

## Nombre con acento, a propósito

`"name": "MICROMANÍA"` lleva tilde deliberadamente: es el caso de ida y vuelta
UTF-8/NFC que ADR-0001 dejó como verificación pendiente.
