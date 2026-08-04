# 007 · Trucos & combos — Plan

_Cómo se implementa lo descrito en `spec.md`. Respeta `constitution/`._

## Enfoque

La feature es chica pero tiene una pieza que conviene aislar: **el tokenizer es
lógica pura y se puede verificar sin abrir Pegasus.**

Todo lo demás del theme se verifica mirando la pantalla, porque es layout. El
tokenizer no: es una función de string a lista de tokens. Esa es la diferencia
que ordena el plan.

```
core/InputTokens.js        el tokenizer. Sin UI, sin QML, funcion pura
ui/InputTokenRow.qml       dibuja una lista de tokens. Sin logica de parseo
overlays/CheatsOverlay.qml el panel
```

El corte no es decorativo: **la gramática vive en un solo archivo y se puede
probar con `node` o a mano**, sin depender de una captura de pantalla.

## Implementación

### 1. Fixtures: la mitad de la gramática no tiene datos

Los combos de los fixtures cubren direcciones, `+`, `P`/`K`/`PP`, prosa y
`START`. **No cubren los botones de cara (`✕○△□`) ni los gatillos (`L1`/`R2`)**
— o sea los cuatro colores por convención y un tipo entero de token.

Se agrega a `library/preview/media/dino/data.json` un par de combos con esa
notación. Va en `preview` y no en `fixtures` porque es un juego de arcade: un
combo con botones de PlayStation ahí sería inventar un dato falso, y los
fixtures encarnan contratos, no ejemplos de relleno.

Mismo criterio que las páginas numeradas de la 006: sin dato no hay
verificación.

### 2. `core/InputTokens.js`

Una función `partir(texto, variante)` que devuelve
`[{tipo, valor, color}]`. Nada más.

El orden de las reglas **es** la gramática, y hay que respetarlo:

1. `+` → separador
2. Toda la palabra son flechas → dirección
3. Toda la palabra son símbolos de cara → botón de cara (con su color)
4. `^[LR][123]$` → gatillo
5. `^[PK]{1,3}$` → botón de arcade (`P` rojo, `K` azul)
6. En la variante `codigo`, además: `A/B/X/Y/Z`, `START`, `SELECT` → keycap
7. Cualquier otra cosa → prosa

**Las palabras de prosa consecutivas se fusionan en un solo token.** Sin eso,
`"acercate y toca P dos veces"` daría siete tokens de texto que se dibujarían
con espacios raros entre sí. Es lo que hace el prototipo y hay que portarlo.

Se porta **casi literal** de `docs/mockup-referencia.html:670-714`, pero
devolviendo tokens tipados en vez de strings de CSS. El prototipo mezclaba
parseo y estilo en la misma función; acá se separan.

### 3. `ui/InputTokenRow.qml`

Un `Flow` que mapea `tipo` → delegate. No parsea nada: recibe la lista ya
hecha. Envuelve, porque una secuencia larga no entra en una línea.

Los tamaños salen del handoff: 36×36 las direcciones, 34×34 los botones,
pastilla para los gatillos.

### 4. `overlays/CheatsOverlay.qml`

Panel centrado de `min(900, ancho)` por máximo 88% del alto. Estética de
tablero de comandos: borde teñido con el accent, scanlines, y las cuatro
escuadras HUD en las esquinas — lo mismo que ya hace `ReviewCard`, así que el
patrón está probado.

- Cabecera: título, `{juego} · LISTA DE COMANDOS`, chip `P1`, botón de cerrar.
- Cuerpo scrolleable: sección **COMBOS** y sección **CÓDIGOS SECRETOS**, cada
  una con su regla y su contador.
- Pie: `— PRESIONÁ B PARA VOLVER —`.

### 5. Verificación del tokenizer, sin Pegasus

Un archivo con casos de entrada y salida esperada, corrido con `node` si está,
o con una reimplementación mínima en Python si no. **No entra a `tests/`**: ese
directorio es de pytest y prueba `src/attract/`, que es Python. Mezclar ahí una
prueba de JavaScript rompería `make test` en una máquina sin node.

Va como archivo aparte que se corre a mano, documentado en `tasks.md`.

## Decisiones

- **El tokenizer no sabe dibujar y la fila no sabe parsear.** Es lo que
  permite verificar la gramática sin abrir Pegasus — y la gramática es la
  parte de esta feature donde un error es difícil de ver a ojo.
- **Las secciones vacías se ocultan, y acá §2.3 NO aplica.** La regla de "ningún
  bloque desaparece" existe para que la estructura de una **pantalla** sea
  estable y el ojo encuentre las cosas en el mismo lugar. Este es un overlay
  que se abre a pedido y solo cuando hay contenido: mostrar
  `CÓDIGOS SECRETOS · 00 SECRETOS · No Disponible` no informa nada que el
  usuario no sepa —pidió ver los trucos y los está viendo— y agrega ruido a
  una lista. La tarjeta *Hacks* del detalle, que **sí** es parte de una
  pantalla, sigue mostrándose siempre con su mensaje.
- **Lo que no se reconoce se muestra como prosa, no se adivina.** `data.json`
  guarda `input` como string libre (ADR-0015); nada obliga a usar esta
  notación. Intentar inferir que `"QCF+P"` es un cuarto de círculo sería
  heurística frágil — el mismo criterio con el que `ingest` no limpia la
  basura de región de los títulos.
- **Los colores de los botones de cara son del handoff, no elegidos.** Son la
  convención de PlayStation y por eso se reconocen. Cambiarlos rompería lo
  único que hace legible el bloque de un vistazo.

## Riesgos

- **Los glifos pueden no estar en las fuentes.** `↖↗↘↙` y `✕○△□` en Chakra
  Petch y Sora: si faltan, Qt sustituye por otra fuente y se ven desalineados o
  de otro tamaño. Se mira en pantalla; si pasa, la salida es dibujar la flecha
  con `Canvas` en vez de usar el glifo.
- **El `Flow` con muchos tokens.** Una secuencia larga envuelve, y el diseño no
  dice qué pasa si ocupa tres líneas dentro de una tarjeta de altura fija. Se
  deja que la tarjeta crezca; si se ve mal, se limita.
