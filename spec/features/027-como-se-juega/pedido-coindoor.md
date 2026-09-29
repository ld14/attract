# Pedido a COINDOOR — bloque `guia` de "Cómo se juega"

_Para quien trabaje del lado de COINDOOR. ATTRACT no modifica ese repo
(regla de ambos `CLAUDE.md`); este documento es el pedido preciso que
`docs/como-se-juega.md` §5 dejó en borrador, ya cerrado contra el contrato
real de [ADR-0037](../../decisions/0037-forma-bloque-guia-data-json.md) y
contra lo que el piloto de datos (`piloto/`) encontró en el código de
COINDOOR el 2026-09-27/28._

## Qué exportar

Un bloque `guia` opcional dentro de `data.json`, con la forma exacta de
[ADR-0037](../../decisions/0037-forma-bloque-guia-data-json.md):

```json
"guia": {
  "objetivo": "string, 1-2 frases",
  "acciones": [ { "control": "P1_BUTTON1", "action": "Jab Punch", "color": "Blue" } ],
  "primerosPasos": ["string", "..."],
  "reglasEsenciales": ["string", "..."],
  "multijugador": { "modo": "individual | cooperativo | versus", "jugadores": 2 },
  "perifericos": ["joy | trackball | dial | paddle | lightgun | mouse | keyboard"],
  "fuentes": [ { "tipo": "arcadedb | web | manual", "url": "string?", "fecha": "YYYY-MM-DD", "version": "string?" } ],
  "revision": "borrador | revisado"
}
```

**Nunca** un botón físico, una posición del panel, ni una tecla de salida —
eso lo resuelve ATTRACT localmente (perfil del gabinete + configuración real
de esta máquina), y COINDOOR no tiene cómo saberlo.

## Lo que ya tienen, cablearlo, no rehacerlo

`backend/api/schemas.py:119-130` (`CabinetInfo.button_list`, poblado desde
`buttons_colors` de ArcadeDB) **ya es** `guia.acciones` — mismos tres campos,
mismos nombres (`control`, `action`, `color`). Confirmado leyendo
`backend/services/arcadedb.py:438-465` y `backend/lib/providers/arcadedb/parser.py:61-75`:
el dato es correcto en los tres arcades del piloto donde estaba poblado
(Street Fighter Alpha 2, The Simpsons, Shuffleshot), y el propio parser ya
descarta las entradas sin acción (`P1_COIN:White:`) — el panel físico, no un
control con sentido en el juego.

**Lo único que falta es agregar `cabinet.button_list` a la tabla de export**
(`backend/bundle/seleccion.py::_tabla()`, que hoy no lo incluye) y
renombrarlo a `acciones` en la salida. Es el ítem más barato de este pedido:
el dato ya existe, solo no viaja.

## Lo que hay que sumar de cero

Ninguno de estos existe hoy en COINDOOR, según lo que el piloto encontró:

- `objetivo` — probablemente ya tienen algo parecido en `texts.sinopsis`;
  **no reusarlo sin revisar**: 2 de los 6 juegos del piloto (Pacman,
  Shuffleshot) tenían ese texto con errores de fondo (un botón inventado en
  uno, una descripción de otro juego entero en el otro — detalle en
  `piloto/pacman.md` y `piloto/shufshot.md`). El `objetivo` de la guía tiene
  que poder revisarse aparte de la sinopsis general, o el mismo problema se
  repite acá.
- `primerosPasos`, `reglasEsenciales`, `multijugador.modo`, `perifericos` —
  no salen de ArcadeDB ni de `-listxml`. El piloto tuvo que **asumir**
  `multijugador.modo` por género en más de un caso, que es justo lo que este
  campo existe para evitar.
- `fuentes`/`revision` a nivel de bloque — ver más abajo por qué no es por
  campo.

## Un bug encontrado al usar `attract controles` contra la librería real (2026-09-29)

**`manifest["set"]` no es el romset real de MAME — es `safe_id(identity.title)`,
siempre.** Confirmado en el código:

- `backend/bundle/manifest.py:26`: `"set": str(game.get("id", ""))`.
- `backend/store/juegos.py`: `id=safe_id(payload.identity.title)`, calculado
  al crear el juego y nunca reconciliado con el romset real, ni siquiera
  cuando `identitySource == "mame"` (o sea, cuando ArcadeDB/MAME ya
  identificaron el juego de verdad).

**Consecuencia medida:** de 5 arcades importados con este pedido, 3 quedaron
con `x-set:` equivocado en `metadata.pegasus.txt` —
`street-fighter-alpha-2` en vez de `sfa2`, `mortal-kombat-2` en vez de `mk2`,
`the-simpsons` en vez de `simpsons`. Los otros 2 (`pacman`, `shufshot`)
funcionan de casualidad: su slug de título coincide con su romset. Con el
`set` equivocado, `attract controles` (027) no puede correr `-listxml`
contra esos 3 juegos — es un romset que no existe.

**Pedido:** cuando `identitySource == "mame"`, `manifest["set"]` tiene que
ser el romset real que identificó ArcadeDB/MAME, no `safe_id(title)`. El
`id` interno de COINDOOR (para nombrar carpetas, URLs, etc.) puede seguir
siendo el slug — este pedido es solo sobre qué valor viaja en el campo
`set` del manifiesto exportado.

`spec/decisions/0026-identidad-declarada-sin-mame.md` (de este repo, ATTRACT)
acepta a propósito el riesgo de no verificar que el `set` declarado
corresponda a un romset real — pero ese ADR asumía un dato *declarado a
mano* por una persona, no un slug de título calculado automáticamente
cuando el romset real ya se conoce. No hace falta que COINDOOR reabra nada
de ese lado; alcanza con que el campo `set` lleve el dato que ya tienen.

## Un choque que no se puede pedir que se resuelva acá

El borrador original (`docs/como-se-juega.md` §5) pedía "llevar la
procedencia de cada grupo hasta el paquete", usando `FieldProvenance` — que
existe en COINDOOR (`backend/api/schemas.py:111-116`) pero **no viaja al
export**, por decisión propia de COINDOOR
(`spec/decisions/0002-procedencia-interna.md`, `accepted`, ese repo).

Este pedido **no** pide reabrir esa decisión. El contrato de ADR-0037 ya
está diseñado para funcionar sin eso: `fuentes`/`revision` son un solo campo
por bloque, no por grupo. Si en algún momento deciden que sí quieren exportar
procedencia por campo de todos modos, sumarla es compatible hacia atrás —
pero no es parte de este pedido.

## Política de import (sin cambios de este lado)

- Un paquete sin `guia` se instala igual — sigue siendo válido.
- Reimportar pisa `guia` completo, mismo criterio que el resto del paquete
  ([`ADR-0027`](../../decisions/0027-contrato-paquete-import-coindoor.md)).
- El perfil físico y el artefacto de correspondencia son locales de ATTRACT
  y nunca viajan en el paquete — no hay nada que pedirle a COINDOOR sobre
  eso.

## Evidencia citada

- `piloto/conclusion.md` — la síntesis completa del piloto de 6 juegos.
- `piloto/pacman.md`, `piloto/shufshot.md` — los dos casos de sinopsis con
  error, con la cita textual de lo que decían y de lo que `-listxml`/
  `cabinet` confirmaron en su lugar.
- `piloto/the-simpsons.md`, `piloto/sfa2.md` — los dos casos donde
  `cabinet.button_list` coincidió exactamente con `-listxml`.
