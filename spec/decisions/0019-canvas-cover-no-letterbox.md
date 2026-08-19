---
id: 0019
title: "El lienzo crece en el eje que sobra en vez de recortar o dejar barras"
status: proposed
date: "2026-08-09"
supersedes: 0016
superseded-by: null
tags: [frontend]
---

# 0019 — El lienzo crece en el eje que sobra

## Contexto

[`ADR-0016`](0016-canvas-fijo-escalado.md) fijó el lienzo en 1280×720 y lo
escala con `scale: Math.min(w/1280, h/720)`, centrado — la técnica del
prototipo de referencia. En cualquier ventana que no sea exactamente 16:9,
esa fórmula dibuja **barras negras** arriba/abajo o a los costados.

El ADR-0016 documentaba esto como costo aceptado ("el gabinete es 16:9 y en
el Mac es una ventana de desarrollo"). Pedido explícito el 2026-08-09, con
captura anotada: ese espacio se percibe como desperdiciado y se pide que el
theme llene la pantalla.

**El dato que reencuadró todo el problema, medido el 2026-08-09:** la
pantalla del Mac de desarrollo es **16:10**, no 16:9 — la captura es de
2880×1800, que da 1.6 exacto (16:9 sería 1.778). Es la proporción estándar
de los MacBook, y significa que el desarrollo **nunca** ocurre en la
proporción del lienzo. No es una ventana mal maximizada que se pueda
acomodar: es la pantalla.

Eso invalida la premisa compartida de las tres fórmulas que se probaron
antes (ver §Alternativas): las tres discuten **cómo encajar un rectángulo de
1280×720 en otro rectángulo de proporción distinta**, y con proporciones
distintas ese problema no tiene solución buena — o sobra espacio, o falta
contenido, o se deforma.

## Decisión

El `scale` vuelve a ser `MIN` —nunca recorta, nunca deforma— pero el `Item`
del lienzo **se dimensiona para cubrir la ventana entera en unidades de
lienzo**, en vez de quedarse clavado en 1280×720:

```qml
Item {
    id: stage
    readonly property real escala: Math.min(parent.width / 1280,
                                            parent.height / 720)
    width: parent.width / escala      // >= 1280
    height: parent.height / escala    // >= 720
    anchors.centerIn: parent
    scale: escala
}
```

Uno de los dos ejes da exactamente la medida del diseño y el otro da **más**
— nunca menos, que es lo que garantiza que el diseño autorado siempre entre
completo. En la pantalla 16:10 del Mac eso da 1280×800: los 720 del diseño
más 80px de aire real, que los bloques ya anclados a los bordes (barra
arriba, leyenda abajo, banda de estantes) reparten solos.

**Lo que esto NO cambia, y es lo que mantiene vivo el corazón de ADR-0016:**
cada medida de adentro sigue siendo la constante en píxeles del diseño
(tarjeta 148×166, gutter 48, tipografías). No se re-derivó **ninguna** a
fracción del padre — que era justamente el costo que ADR-0016 rechazaba en
su Alternativa A. Lo único que cambia es cuánto espacio hay alrededor de esas
constantes.

## Alternativas consideradas

### A · Mantener `scale(MIN)` (letterbox) — el ADR-0016 vigente

- A favor: nunca recorta contenido; todo el diseño autorado siempre está
  visible completo.
- En contra: en una pantalla 16:10 (la del Mac de desarrollo) deja barras
  negras arriba y abajo, siempre — no es un caso de borde, es todos los días.
- **Descartada porque:** ese espacio muerto es exactamente lo que se pidió
  eliminar, y en 16:10 no hay forma de acomodar la ventana para evitarlo.

### B · Escalar X e Y por separado (estirar para llenar exacto)

`transform: Scale { xScale: w/1280; yScale: h/720 }` en vez de una sola
`scale` uniforme.

- A favor: llena la ventana exacto, sin recortar ni un píxel del diseño.
- En contra: deforma todo lo que no sea la proporción 16:9 exacta —
  círculos se vuelven óvalos, el texto se ve estirado o aplastado según el
  eje. Es el defecto clásico de "imagen mal ajustada" de una TV vieja.
- **Descartada porque:** distorsionar la forma de cada elemento (carátulas,
  chips, tipografía) es peor que cualquiera de las otras opciones —
  confirmado explícitamente al elegir.

### C · `scale(MAX)` — cubrir recortando los bordes

Mantener el lienzo clavado en 1280×720 y escalarlo con `max()` en vez de
`min()`, para que cubra la ventana y el eje que sobra quede fuera.

- A favor: llena la pantalla siempre, sin deformar nada (un solo `scale`
  uniforme).
- En contra: **recorta contenido de verdad.** Verificado contra Pegasus real
  en la pantalla 16:10 del Mac: se comía el borde izquierdo (el chip
  `ARCADE`, la primera letra del título, la primera tarjeta de cada estante)
  y el derecho (el botón `?` de la barra).
- **Descartada porque:** perder controles interactivos fuera de pantalla es
  peor que cualquier espacio sobrante — y en 16:10 el recorte es permanente,
  no una condición de borde.

### D · `scale(MIN(1, MAX(...)))` — cubrir pero con techo en 1

Intento intermedio: cubrir como en C, pero sin agrandar nunca más allá del
tamaño de diseño.

- A favor: evita que el contenido se magnifique en una ventana grande.
- En contra: el techo también impide usar la resolución de una pantalla del
  aspecto correcto y mayor tamaño — dejando margen parejo en las cuatro
  puntas, sin resolver el problema original.
- **Descartada porque:** ataca el síntoma ("se ve grande") en vez de la
  causa (la proporción no coincide). Verificado contra Pegasus real: seguía
  desperdiciando pantalla.

## Consecuencias

**Positivas**

- **Ni barras negras ni espacio muerto ni recorte ni deformación**, en
  ninguna proporción de pantalla. Es la primera de las opciones evaluadas que
  no paga con ninguna de esas cuatro monedas.
- Las medidas del diseño siguen siendo constantes en píxeles, sin re-derivar
  ninguna a fracción del padre — el punto central de ADR-0016 sigue en pie.
- **En una pantalla 16:9 el resultado es idéntico al de ADR-0016**: ahí
  `w/1280 === h/720`, así que el lienzo da exactamente 1280×720 y no crece
  por ningún lado. El gabinete real no ve ninguna diferencia.

**Coste asumido**

- **La composición ya no es idéntica píxel a píxel al prototipo en pantallas
  que no sean 16:9.** En 16:10 hay 80px más de alto para repartir: los
  bloques anclados a los bordes quedan más separados entre sí que en el
  diseño autorado. Es una diferencia de *espaciado*, no de tamaño ni de
  proporción de ningún elemento — pero es una diferencia real contra el
  prototipo, y hay que saberlo antes de comparar los dos lado a lado.
- **Los bloques que NO están anclados a un borde no se benefician del espacio
  extra**: se quedan donde el diseño los puso. Si en 16:10 queda un hueco
  raro en el medio de alguna pantalla, la salida es anclar ese bloque, no
  volver a tocar el `scale`.

**Qué habría que revisar si esto se replantea**

- Si aparece una pantalla con una proporción mucho más extrema (21:9
  ultrawide, o vertical): ahí el espacio extra deja de ser "aire" y pasa a
  ser un hueco que el diseño no contempla, y habría que decidir qué bloque lo
  ocupa.
- Si el gabinete final resultara no ser 16:9 — ahí el espacio extra pasa a
  verse en **producción** y no solo en desarrollo, y hay que mirar la
  composición contra la pantalla real antes de aceptar este ADR en firme.

## Referencias

- [`ADR-0016`](0016-canvas-fijo-escalado.md) — la decisión que este ADR
  supersede. Su núcleo sigue vigente: lienzo de referencia 1280×720 y
  medidas constantes en píxeles. Lo que cambia es que el `Item` ya no está
  clavado en ese tamaño, sino que crece en el eje que sobra.
- `themes/attract/theme.qml` — el `Item` `stage` donde se aplica.
- Medición que reencuadró el problema: captura de 2880×1800 (16:10) del Mac
  de desarrollo, 2026-08-09.
