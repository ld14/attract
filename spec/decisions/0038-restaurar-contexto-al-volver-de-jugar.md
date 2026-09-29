---
id: 0038
title: "Al volver de JUGAR se restaura todo el contexto de navegación, no solo la guía"
status: accepted
date: "2026-09-28"
supersedes: null
superseded-by: null
tags: [frontend]
---

# 0038 — Restaurar plataforma + juego + detalle + guía, no solo la guía

## Contexto

La spec [`028-theme-como-se-juega`](../features/028-theme-como-se-juega/spec.md)
pide: *"JUGAR desde la guía lanza el juego; al volver, la guía de ese juego
está abierta"* (criterio de aceptación heredado de la spec 027 original).

**Hecho medido, no supuesto** (experimento
`themes/experimentos/recarga-tras-juego.qml`, corrido en el gabinete el
2026-09-28, resultado completo en el propio archivo): **Pegasus recarga el
theme entero al volver de un juego** — el QML se destruye y se crea de
nuevo, ninguna property sobrevive. Metodología: reset de `api.memory`,
lanzar un juego una vez, confirmar que el contador de `Component.onCompleted`
pasó de `undefined` a `1`. Y una clave escrita justo antes de `game.launch()`
sí sobrevive esa recarga, leída correctamente al volver.

Con esto confirmado, la pregunta que queda abierta no es *cómo* (ya se sabe:
`api.memory`, escribir antes de `game.launch()`, leer en
`Component.onCompleted`), sino **qué** se restaura. Y ahí aparece un problema
real de navegación:

- El theme arranca siempre en el **selector de plataforma**
  ([`026-selector-plataforma`](../features/026-selector-plataforma/spec.md)),
  que hoy no guarda nada en `api.memory` — ni la plataforma elegida, ni la
  posición en la librería.
- Si solo se restaura "la guía abierta" (sin plataforma/juego/detalle), volver
  de JUGAR deja al jugador en el **selector de plataforma**, con la guía de
  un juego que no está en pantalla — un estado inconsistente, no solo
  incómodo.
- JUGAR desde el detalle es exactamente el camino que dispara esto: es la
  única forma de llegar a `game.launch()` con una guía abierta encima.

## Decisión

**Al volver de JUGAR se restaura la cadena completa de navegación**: qué
plataforma estaba elegida, en qué juego estaba parada la librería, que el
detalle estaba abierto, y si la guía (u otro overlay abierto desde ella,
según el criterio de cierre de la spec 028) estaba encima.

Justo antes de cada `game.launch()` (el único punto de salida real del
theme, `theme.qml:573` hoy), se escribe en `api.memory` una única clave de
contexto:

```json
{
  "coleccion": "arcade | msdos | null (TODAS)",
  "set": "x-set o file del juego",
  "detalleAbierto": true,
  "guiaAbierta": true
}
```

En `Component.onCompleted` del theme raíz, si esta clave existe: se salta el
selector de plataforma, se posiciona el catálogo en `set`, se abre el
detalle, y si `guiaAbierta` es verdadero se abre el overlay de la guía
encima — en ese orden, porque cada paso depende del anterior (no se puede
abrir el detalle sin saber en qué colección buscar el juego). La clave se
borra (`api.memory.unset`) apenas se termina de restaurar, para que un
`Component.onCompleted` posterior que no viene de jugar (por ejemplo, elegir
"ATTRACT" de nuevo desde el menú de Pegasus) no reabra un contexto viejo.

## Alternativas consideradas

### A · Restaurar solo la guía (el mínimo que pedía la spec original)

- A favor: menos estado que guardar, menos superficie para que algo salga
  mal en la restauración.
- En contra: dispara el estado inconsistente de arriba — guía de un juego
  flotando sobre el selector de plataforma, sin el juego ni el detalle
  debajo.
- **Descartada porque:** no es realmente "más simple", es "incompleta": el
  criterio de aceptación exige que la guía esté abierta y sea la de *ese*
  juego — eso ya implica el detalle de *ese* juego, que ya implica su
  colección. Guardar solo la guía sin lo demás no ahorra trabajo, produce un
  estado que ninguna pantalla sabe dibujar.

### B · Que el selector de plataforma sea quien no se destruya, en vez de guardar en `api.memory`

- A favor: si el selector sobreviviera al `game.launch()`, no haría falta
  serializar nada.
- En contra: ya está medido que **no sobrevive nada** — Pegasus recrea el
  theme entero, no una pantalla particular.
- **Descartada porque:** es la misma alternativa que ya evaluó y descartó
  [`ADR-0036`](0036-guia-tres-capas.md) implícitamente al asumir recarga; el
  experimento de 2026-09-28 lo confirma como hecho medido, no como supuesto.

## Consecuencias

**Positivas**

- El jugador nunca vuelve de una partida a una pantalla que no reconoce.
- Un solo mecanismo (`api.memory`, una clave, un ciclo escribir-antes /
  leer-después) cubre plataforma + juego + detalle + guía, en vez de cuatro
  mecanismos de restauración independientes.
- La clave se autolimpia: no hay estado viejo que sobreviva a una sesión de
  Pegasus donde nadie jugó nada.

**Coste asumido**

- **El selector de plataforma (026) tiene que aprender a arrancar "saltado"**
  cuando la clave de contexto existe — hoy no lo hace, y es un cambio de
  responsabilidad cruzado entre dos features (026 y 028), no contenido en
  una sola.
- **Un crash de MAME/DOSBox a mitad de partida** deja la clave escrita sin
  que nadie la lea de vuelta hasta la próxima vez que se relance algo — no
  es un bug, es el mismo comportamiento que ya tiene `api.memory` con
  cualquier otra clave, pero vale decirlo: la restauración depende de que
  Pegasus efectivamente recargue el theme al volver, que es el camino
  medido, no el de un crash del lado del emulador (sin medir).

**Qué habría que revisar si esto se replantea**

- Si aparece una razón para NO restaurar la plataforma/detalle (por ejemplo,
  que el autor prefiera volver siempre a "TODAS" tras jugar) — hoy no hay
  ese pedido, pero si aparece, esta ADR se reabre porque cambia qué guarda
  la clave, no solo cómo se restaura.
- Si Pegasus cambia de versión y deja de recargar el theme al volver — la
  clave de contexto pasaría a sobrar (una property normal alcanzaría), y
  este ADR quedaría superseded por uno que lo simplifique.

## Referencias

- `themes/experimentos/recarga-tras-juego.qml` — el experimento y su
  `#RESULTADO OBSERVADO` (2026-09-28), evidencia de que Pegasus recarga el
  theme y de que `api.memory` sobrevive la recarga.
- [`ADR-0036`](0036-guia-tres-capas.md) — decisión 11 original ("guía
  abierta al volver"), que este ADR completa con el mecanismo medido y el
  alcance real de qué se restaura.
- [`spec/features/026-selector-plataforma/`](../features/026-selector-plataforma/spec.md) —
  la feature cuyo arranque tiene que aprender a saltarse.
- [`spec/features/028-theme-como-se-juega/`](../features/028-theme-como-se-juega/spec.md) —
  la feature que dispara `game.launch()` desde la guía y necesita esta
  restauración para su criterio de aceptación.
