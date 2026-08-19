---
id: 0016
title: "El theme se dibuja en un canvas fijo de 1280x720 y se escala entero"
status: superseded
date: "2026-07-29"
supersedes: null
superseded-by: 0019
tags: [frontend]
---

# 0016 — Canvas fijo de 1280×720, escalado entero

## Contexto

El diseño de referencia está autorado en un lienzo fijo de **1280×720** y el
prototipo lo escala entero para llenar la ventana
(`transform: scale(min(w/1280, h/720))`, centrado —
`docs/mockup-referencia.html` línea 942). El handoff lo señala y deja la
decisión abierta: *"en QML, usar un `Item` de 1280×720 con un `scale`, o
diseñar a la resolución nativa de Pegasus y usar anchors — decisión del
equipo, pero preservar las proporciones del lienzo fijo"*
(`design_handoff_game_detail/README.md` §Stage scaling).

Hay que elegir antes de escribir el primer componente, porque afecta a cómo se
escribe **cada** medida del theme: o son constantes, o son fracciones del
padre. Cambiar de opinión después es reescribir el layout entero.

Dos datos del proyecto acotan la decisión:

- El handoff declara la fidelidad como **"high-fidelity … final … recreate
  pixel-for-pixel where QML allows"**. No es un mockup indicativo.
- El destino es **un gabinete arcade dedicado, con una pantalla de resolución
  fija**. No es una app que corre en monitores arbitrarios; la ventana en el
  Mac de desarrollo es el único caso donde el tamaño varía de verdad.

## Decisión

El theme se dibuja dentro de un `Item` de **1280×720 exactos** y ese Item se
escala uniformemente para encajar en la ventana, centrado:

```qml
Item {
    width: 1280
    height: 720
    anchors.centerIn: parent
    scale: Math.min(parent.width / 1280, parent.height / 720)
    // transformOrigin: Item.Center es el default
}
```

Todas las medidas de adentro son **constantes en píxeles**, tomadas
directamente del diseño: `width: 148`, `spacing: 16`, `font.pixelSize: 30`.
Ningún componente calcula su tamaño como fracción del padre.

Consecuencia práctica bienvenida: los `clamp(44px, 6.4vw, 104px)` del CSS
—que existen justamente porque el ancho del navegador es variable— colapsan a
un número fijo. Con el lienzo fijo, `clamp()` no tiene nada que resolver.

## Alternativas consideradas

### A · Layout relativo con anchors y proporciones

Diseñar contra el tamaño real de la ventana de Pegasus, con anchors, `Layouts`
y medidas expresadas como fracción del padre.

- A favor: es la forma idiomática de escribir QML y la que mejor aguanta
  pantallas de relaciones de aspecto distintas; el texto no se pixela al
  escalar hacia arriba.
- En contra: obliga a **re-derivar a mano cada una de las medidas del
  diseño**. El handoff especifica cientos de constantes (tarjetas de 148×166,
  pasos de carrusel de 143px, hojas de 560×760, gutters de 48px, una escala de
  radios de 12 valores). Convertir cada una en una fracción es inventar un
  denominador por medida, y cada denominador inventado es una oportunidad de
  perder la proporción que el handoff declara final. La fidelidad se erosiona
  de a un componente por vez, y el error no se nota hasta comparar contra el
  prototipo lado a lado.
- **Descartada porque:** paga en fidelidad —el requisito explícito del
  handoff— para comprar flexibilidad de resolución, que es justo lo que un
  gabinete de pantalla fija no necesita.

### B · Escalar el canvas pero permitir que el alto crezca (canvas de ancho fijo)

Fijar 1280 de ancho y dejar que el alto se estire con la ventana.

- A favor: aprovecha pantallas más altas sin barras negras.
- En contra: la mitad del diseño está anclada al **borde inferior** (el rail
  de carátulas, el carrusel de revistas con su `margin-top:auto`, las tarjetas
  de CONTENIDO EXTRA). Con el alto variable, esos bloques flotan a distancias
  distintas del contenido de arriba y las composiciones que el diseño fija
  —cuánto respira el hero sobre el rail— dejan de ser las autoradas.
- **Descartada porque:** rompe exactamente los anclajes al borde inferior en
  los que se apoya la composición, a cambio de aprovechar un espacio que en el
  gabinete no existe (la pantalla es 16:9).

## Consecuencias

**Positivas**

- Fidelidad exacta: cada medida del theme es la medida del diseño, sin
  traducción. Comparar el theme contra el prototipo es comparar dos cosas que
  deberían coincidir píxel a píxel.
- Se escribe mucho menos: no hay aritmética de proporciones en ningún binding.
- La ventana del Mac de desarrollo y la pantalla del gabinete muestran
  **exactamente la misma composición**, a escalas distintas. Un problema visual
  visto en el Mac es reproducible en el gabinete y viceversa — el mismo
  criterio de paridad Mac/gabinete que ya rige para MAME
  ([`ADR-0005`](0005-runtime-mame-vanilla.md)) y para Pegasus
  ([`ADR-0006`](0006-version-politica-pegasus.md)).
- Un solo lugar donde tocar si el gabinete resulta no ser 16:9.

**Coste asumido**

- **En pantallas que no son 16:9 hay barras negras.** Aceptado: el gabinete es
  16:9 y en el Mac es una ventana de desarrollo.
- **El texto se rasteriza a 1280×720 y después se escala.** En una pantalla
  4K, el texto va a verse levemente más blando que si se hubiera dibujado a la
  resolución nativa. Es el coste real de esta decisión, y en un gabinete a
  1080p (escala 1.5×) es difícil de notar. Si el gabinete terminara siendo 4K
  y el texto molestara de verdad, la salida no es rehacer el layout: es subir
  el lienzo a 1920×1080 y multiplicar las constantes por 1.5 — un cambio
  mecánico, no un rediseño.
- Todo lo que dependa del tamaño de la pantalla (nada hoy) tendría que mirar
  el lienzo, no la ventana.

**Qué habría que revisar si esto se replantea**

- Que la pantalla del gabinete no sea 16:9.
- Que el theme tenga que correr en algo que no sea el gabinete ni el Mac de
  desarrollo (una TV, un handheld) — ahí la flexibilidad de la alternativa A
  empieza a valer lo que cuesta.
- Que el texto escalado se vea mal de verdad en la pantalla final. Se mide
  mirándola, no discutiéndolo.

## Referencias

- `design_handoff_game_detail/README.md` §Stage scaling — la decisión que el
  handoff deja explícitamente al equipo, y §Fidelity, que la condiciona.
- `docs/mockup-referencia.html` línea 942 (`stageStyle`) y 638 (`_fit()`) — el
  escalado del prototipo, que esta decisión replica.
- [`ADR-0006`](0006-version-politica-pegasus.md) — Qt 5.15 y la paridad
  Mac/gabinete.
