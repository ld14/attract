---
id: 0023
title: "Un juego puede declarar varios manuales; manual pasa de objeto a lista, con pestañas en el visor"
status: accepted
date: "2026-08-09"
supersedes: null
superseded-by: null
tags: [data, frontend]
---

# 0023 — Más de un manual por juego

## Contexto

El contrato de `manual` en `data.json` es hoy un **objeto singular**
([`ADR-0014`](0014-manual-digitalizado.md), extendido con `file` por
[`ADR-0021`](0021-manual-pdf-app-del-sistema.md)):

```json
{ "manual": { "pages": ["p001.png", "..."], "file": "manual.pdf" } }
```

Confirmado como caso real, no hipotético: **un juego puede tener más de un
manual** — el caso concreto que se dio es "multivariado", sin una sola forma
fija (puede ser manual de uso + manual de servicio, dos idiomas, dos
revisiones — no hay un par cerrado de categorías). El contrato actual no tiene
dónde poner un segundo documento.

**El mecanismo para elegir entre varios documentos ya existe en el theme, y ya
está probado contra Pegasus real**, para el mismo problema en revistas:
`overlays/DocumentViewer.qml` tiene una fila de pestañas (`revistas: []`,
`cambiarRevista(i)`, visible solo `revistas.length > 1`) que cambia de revista
sin cerrar el visor (feature 006). No hace falta inventar una UI de selección
nueva: hace falta generalizar una que funciona.

Restricciones que siguen vigentes y no se reabren:

- El manual sigue siendo del juego, no una entidad compartida tipo
  `_magazines/` — ADR-0014 ya distinguió ese caso ("una revista cubre varios
  juegos, un manual no") y sigue siendo cierto con varios manuales: los varios
  siguen siendo del mismo juego.
- Las páginas siguen siendo imágenes, nunca PDF adentro del theme (ADR-0007).
- El PDF sigue abriéndose afuera con `Qt.openUrlExternally` cuando no hay
  páginas rasterizadas (ADR-0021), y `attract rasterize` sigue siendo el
  camino para no salir nunca de Pegasus (ADR-0022) — los dos ahora operan por
  documento, no por juego.

## Decisión

`manual` pasa de **objeto** a **lista de documentos**. Cada documento tiene la
misma forma que el `manual` de hoy, más un `label` escrito a mano:

```json
{
  "manual": [
    { "label": "Manual de uso",     "pages": ["p001.png", "..."], "file": "uso.pdf" },
    { "label": "Manual de servicio", "file": "servicio.pdf" }
  ]
}
```

**`label` es obligatorio solo si hay más de un documento.** Con un solo
elemento, `label` es opcional y no se muestra — es el caso de hoy, sin
pestaña, exactamente como se ve ahora. Esto es deliberado: **no hay migración
de datos que hacer**. El `manual` de hoy, envuelto en una lista de un
elemento, sigue siendo válido tal cual (`sf2ce`, `goldnaxe` no cambian).

`label` es texto escrito a mano, **no** inferido de una convención de nombre
(`manual.es.pdf` → "Español"). Mismo motivo que rechazó `x-manual` en
ADR-0014: una convención implícita rompe en silencio en cuanto un archivo no
la sigue, y "multivariado" significa que no hay un conjunto cerrado de
convenciones para cubrir.

**El visor gana pestañas de manual, generalizando las de revista.** Hoy
`DocumentViewer` recibe `revistas: [{etiqueta, color}]` — un prop con nombre
de dominio para un mecanismo que es genérico ("varios documentos del mismo
tipo, elegí cuál"). Se renombra a `pestanas: [{etiqueta, color}]` /
`cambiarPestana(i)`, y `theme.qml` decide qué le pasa según qué se abrió: las
revistas del juego, o los manuales del juego. **Nunca las dos filas a la vez**
— abrir el manual y abrir una revista son acciones distintas que no conviven
en pantalla, así que una sola fila de pestañas alcanza.

`ExtrasList` no cambia de forma: la tarjeta "Manual digitalizado" sigue siendo
una, y su subtítulo pasa a contar documentos en vez de páginas cuando hay más
de uno (`"2 manuales"` en vez de `"26 págs · PDF"`). La selección entre ellos
vive **adentro** del visor, no en la tarjeta — mismo criterio que las
revistas, que tampoco listan tapas en CONTENIDO EXTRA.

`attract rasterize` gana un segundo argumento posicional para elegir **cuál**
documento convertir cuando hay más de uno: `attract rasterize <set> <label>`.
Con un solo documento sigue funcionando sin el segundo argumento, igual que
hoy.

## Alternativas consideradas

### A · Convención de nombre en vez de `label` a mano

`manual.es.pdf`, `manual.service.pdf` — inferir el rótulo del nombre de
archivo.

- A favor: menos que escribir en `data.json`.
- En contra: "multivariado" quiere decir que no hay un conjunto cerrado de
  sufijos que cubra todos los casos reales (idioma, tipo de manual, revisión,
  y combinaciones). Cualquier convención fija se queda corta tarde o
  temprano, y romper en silencio es peor que escribir una palabra de más.
- **Descartada porque:** es el mismo argumento que ya usó ADR-0014 contra
  `x-manual` — una convención implícita no declarada rompe en cuanto la
  realidad no calza con lo que se imaginó.

### B · Una tarjeta de CONTENIDO EXTRA por manual

En vez de pestañas adentro del visor, una tarjeta "Manual de uso" y otra
"Manual de servicio" en la fila de extras.

- A favor: la selección es visible antes de entrar al visor, sin un paso
  intermedio.
- En contra: la fila de CONTENIDO EXTRA es de **dos** elementos fijos (Hacks,
  Manual) desde que existe (`screens/ExtrasList.qml`), y esto la vuelve de
  tamaño variable — con tres o cuatro manuales, la fila crece sin límite y
  empuja el layout. Es exactamente el tipo de "nueva sección visual" que el
  diseño de referencia no contempla.
- **Descartada porque:** las pestañas ya resuelven "elegir entre varios
  documentos del mismo tipo" sin tocar el layout fijo, y ya están construidas
  y probadas para revistas.

### C · Mantener `manual` objeto y agregar `manuals` (plural) aparte

Dos campos: `manual` para el caso simple, `manuals[]` para el caso múltiple.

- A favor: cero cambios para `sf2ce` y `goldnaxe`, no hace falta envolver nada
  en una lista.
- En contra: dos formas de decir lo mismo es una fuente de bugs — `doctor`,
  `GameData.qml` y `rasterize` tendrían que saber cuál de los dos mirar, y
  quedaría la pregunta de qué pasa si un `data.json` tiene los dos.
- **Descartada porque:** el caso de un solo elemento en una lista de uno
  (`manual: [{...}]`) ya no necesita esa migración — es tan simple como el
  objeto de hoy, sin el costo de dos contratos paralelos.

## Consecuencias

**Positivas**

- **Cero migración de datos.** `sf2ce` y `goldnaxe` siguen válidos: un
  documento sin `label` sigue mostrándose exactamente igual que hoy.
- Reusa un mecanismo ya construido y ya probado contra Pegasus real
  (pestañas de revista, feature 006) en vez de diseñar una selección nueva.
- La tarjeta de CONTENIDO EXTRA no crece: sigue siendo un elemento fijo,
  cumpliendo la regla original de "no crear una sección nueva" del pedido que
  dio origen a esta feature.
- `rasterize` por documento significa que un manual de servicio de 4 páginas
  no obliga a rasterizar el manual de uso de 30 si todavía no hace falta.

**Coste asumido**

- `manual` cambia de tipo (objeto → lista) en el contrato de `data.json`.
  Todo el código que lo lee — `doctor.py`, `GameData.qml`, `DocModel.qml`,
  `rasterize.py` — tiene que aceptar la forma nueva. No hay compatibilidad con
  la forma objeto vieja: se reemplaza, no se soporta doble.
- El prop `revistas`/`cambiarRevista` del visor se renombra a
  `pestanas`/`cambiarPestana` — cualquier código que lo referencie por el
  nombre viejo deja de compilar. Es un cambio interno del theme, no del
  contrato de datos, así que no rompe ningún `data.json` existente.
- Con dos o más documentos sin `label`, `doctor` tiene que rechazarlo — si no,
  la pestaña queda sin texto y el usuario no puede distinguir cuál es cuál.

**Qué habría que revisar si esto se replantea**

- Que aparezca un juego con tantos manuales que las pestañas no entren en el
  ancho fijo del visor (1280px) — ahí hace falta scroll horizontal en la fila
  de pestañas, que hoy no existe ni para revistas.
- Que el mismo documento deba aparecer asociado a más de un juego (un manual
  de placa compartida entre dos juegos de la misma placa base) — eso reabre
  la pregunta que ADR-0014 ya cerró para el caso de uno solo: si empieza a
  doler la duplicación, el manual pasa a entidad propia como `_magazines/`.

## Verificaciones pendientes

- [x] **Confirmado 2026-08-09** — implementado y con `make test` en verde
      (136 passed). Dos hallazgos que no estaban en el diseño original:
      1. **Colisión de nombres.** Dos documentos rasterizando los dos a
         `_manual/p001.png` se pisarían entre sí. Se resolvió con un
         subdirectorio por documento (`_manual/manual-<índice>/`) cuando hay
         más de uno — con uno solo sigue en la raíz, sin subcarpeta.
      2. **La puerta de entrada no puede saltar directo al PDF cuando hay más
         de un documento**, aunque el activo por defecto no tenga páginas: si
         lo hiciera, un juego que declaró primero su manual de servicio
         (solo-PDF) quedaría sin forma de llegar a las pestañas del resto.
- [ ] QA visual contra Pegasus real: `sf2ce` (un documento) sin cambios de
      comportamiento; `dino` (dos documentos, uno con páginas y otro solo-PDF)
      con pestañas, sin saltar al PDF al entrar, y `X ABRIR PDF` apareciendo
      solo cuando corresponde al documento activo.

## Referencias

- [`ADR-0014`](0014-manual-digitalizado.md) — el contrato que esto reemplaza,
  y el argumento contra la convención implícita que esta decisión reusa.
- [`ADR-0021`](0021-manual-pdf-app-del-sistema.md) — abrir el PDF afuera,
  ahora por documento.
- [`ADR-0022`](0022-rasterizar-pdf-a-paginas.md) — `attract rasterize`, ahora
  con un segundo argumento para elegir el documento.
- `themes/attract/overlays/DocumentViewer.qml` — las pestañas de revista que
  se generalizan.
- `spec/features/006-theme-documentos/` — donde se construyó y probó el
  mecanismo de pestañas por primera vez.
- `spec/features/014-manual-multiple/` — la feature que implementa esto.
