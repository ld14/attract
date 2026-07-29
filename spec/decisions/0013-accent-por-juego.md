---
id: 0013
title: "El accent de cada juego se declara a mano en su data.json"
status: accepted
date: "2026-07-29"
supersedes: null
superseded-by: null
tags: [frontend, data]
---

# 0013 — El accent de cada juego se declara a mano en su `data.json`

## Contexto

El diseño de referencia (`design_handoff_game_detail/`) tiene como efecto
central el **theming dinámico por juego**: cada juego tiene un par de colores
—`accent` (brillante) y `accent2` (oscuro, para gradientes)— y ese par manda
sobre casi todo lo que se ve en pantalla:

- anillos de foco y resplandor de la tarjeta enfocada
- el botón JUGAR y su sombra de color
- borde y texto de la pestaña/chip activo
- las barras de progreso del bloque NOTA DE LA CRÍTICA
- el marco HUD y los glifos de dirección del overlay de trucos
- el brillo radial del fondo, arriba a la derecha
- el color-wash de la carátula cuando no hay imagen real

Al mover el foco en la librería, la pantalla entera cambia de color. Sin eso,
todas las fichas se ven iguales — es el punto que separa este diseño de una
grilla genérica, y el handoff lo declara explícitamente como token global
(§Global Design Tokens, "per-game dynamic theming").

**El problema:** el prototipo tiene 8 juegos con los colores elegidos a mano
en el código (`accent:'#3ad17a'`, `docs/mockup-referencia.html` líneas
592-622). El modelo de datos real de ATTRACT **no tiene ese campo en ningún
lado** — no está en `metadata.pegasus.txt`, ni en `data.json`, ni en
`docs/CONVENCION.md` §2.1. Y la librería real del autor no son 8 juegos.

**Restricción dura descubierta al evaluar las opciones:** derivar el color de
la carátula en runtime —que es la solución obvia y la que usan los frontends
modernos— **es imposible acá**. Leer los píxeles de una imagen desde QML
requiere código C++, y el binario de Pegasus está congelado desde octubre de
2024 sin desarrollo activo ([`ADR-0006`](0006-version-politica-pegasus.md)):
no se puede recompilar ni extender. No es una preferencia de diseño, es una
limitación de la plataforma elegida.

## Decisión

El par de colores se declara **por juego, a mano**, en el `data.json` que ya
existe junto a sus assets:

```json
{
  "accent":  "#3ad17a",
  "accent2": "#0c3d22"
}
```

Ubicación y transporte: los de siempre
([`ADR-0001`](0001-transporte-datos-ricos.md)) — `media/<set>/data.json`,
leído por el theme con `XMLHttpRequest`. No se agrega ningún campo `x-` nuevo
al `metadata.pegasus.txt`.

**Degradación:** si un juego no tiene `accent`, el theme cae a un par neutro
propio en vez de romperse. Esto es consistente con `docs/CONVENCION.md` §2.3
("ningún bloque desaparece"): la pantalla se ve, apagada pero completa. Un
juego sin colores es un juego a medio enriquecer, no un juego roto.

**El coste se asume explícitamente:** cada juego nuevo necesita que un humano
le elija dos colores, o se queda neutro. Esto va en tensión con el criterio
rector de ADR-0001 (*enriquecimiento progresivo barato*), y la tensión se
acepta a propósito: el accent no es un dato que exista "allá afuera" para
scrapear —como la sinopsis o el año—, es una **decisión estética por juego**.
Que la tome una persona no es una ineficiencia del proceso, es el proceso.

## Alternativas consideradas

### A · Tabla por colección en el theme, con override opcional por juego

Un accent por colección (`Arcade` naranja, `NES` rojo, `Amiga` verde…)
definido en el theme; un juego puede pisarlo poniendo `accent` en su
`data.json`.

- A favor: coste cero por juego nuevo — hereda el color de su colección sin
  que nadie toque nada. Respeta el criterio rector de ADR-0001 al pie de la
  letra. Permite el mismo control fino donde importe.
- En contra: la pantalla cambia de color al cambiar de **colección**, no al
  cambiar de juego. Recorrer 40 arcades es recorrer 40 pantallas del mismo
  color. El efecto que el handoff describe —que cada juego tenga identidad
  visual propia— desaparece salvo en los juegos que alguien decidió pisar a
  mano, que son justo los que igual habría que elegir a mano.
- **Descartada porque:** ahorra un trabajo que en la práctica hay que hacer
  igual para los juegos que importan, y a cambio apaga el efecto principal
  del diseño en todos los demás.

### B · Derivar el accent de la carátula en runtime

Muestrear el color dominante de `assets.boxFront` y usarlo como accent.

- A favor: coste cero por juego y theming realmente por juego — lo mejor de
  las dos opciones anteriores. Es lo que hacen los frontends modernos.
- En contra: —
- **Descartada porque:** **es técnicamente imposible en esta plataforma.**
  QML de Qt 5.15 no puede leer los píxeles de una `Image`; hace falta un
  `QQuickImageProvider` o equivalente en C++, y Pegasus es un binario
  congelado que no se puede extender (ADR-0006). No es un "sería caro": no
  hay camino. Si algún día Pegasus dejara de estar congelado o se migrara a
  otro frontend, esta es la primera opción a reabrir.

### C · Un solo accent fijo para todo el theme

El prototipo ya trae ese modo (`accentMode: 'cyan'`, línea 794).

- A favor: cero datos nuevos, cero mantenimiento, cero decisiones estéticas.
- En contra: se pierde el theming dinámico entero, que el handoff lista como
  token global del diseño y no como un adorno opcional.
- **Descartada porque:** tira el efecto más visible del diseño para ahorrar
  dos campos en un archivo JSON que ya existe y que ya hay que editar para
  cargar reseñas y trucos.

## Consecuencias

**Positivas**

- Fidelidad máxima al diseño de referencia, que es lo que el handoff pide
  ("high-fidelity", colores "final").
- Un solo lugar donde mirar: el `accent` de un juego está en el mismo archivo
  que su reseña y sus trucos, no repartido entre el theme y los datos.
- No agrega ningún campo al `metadata.pegasus.txt` — respeta el límite duro
  de ADR-0001 sin excepciones.
- Cambiar el color de un juego es editar un archivo y reabrir la pantalla:
  no hay que recompilar ni tocar el theme.

**Coste asumido**

- **Trabajo manual recurrente:** cada juego nuevo necesita que alguien le
  elija dos colores. Un juego sin `accent` se ve neutro — no roto, pero
  visiblemente menos trabajado que sus vecinos.
- Dos colores que tienen que combinar entre sí (`accent2` es el oscuro del
  gradiente). Elegir mal el par se ve peor que no elegir nada.
- El theme necesita un par neutro por defecto que se vea decente, porque va a
  usarse de verdad — no es una rama muerta.
- `attract doctor` tiene que validar que sean hex válidos, o un `"verde"`
  escrito a mano rompe el color en silencio (queda pendiente en
  [`ADR-0015`](0015-contrato-data-json.md)).

**Qué habría que revisar si esto se replantea**

- Que Pegasus deje de estar congelado, o que se migre a un frontend
  extensible: la alternativa B pasa de imposible a preferible de inmediato.
- Que la librería crezca lo suficiente como para que elegir colores a mano
  se vuelva el cuello de botella de la ingesta. Si eso pasa, el camino no es
  volver a la alternativa A sino generar el par en la ingesta con alguna
  heurística **fuera** del theme (donde sí hay Python y sí se pueden leer
  píxeles), persistiéndolo en el `data.json` — el contrato de este ADR no
  cambiaría.

## Referencias

- `design_handoff_game_detail/README.md` §Global Design Tokens — el accent
  como token de diseño, con los pares de ejemplo del prototipo.
- `docs/mockup-referencia.html` líneas 592-622 (los 8 juegos con sus pares) y
  781-786 (`coverBg()`, cómo se usa el par en el gradiente de carátula).
- [`ADR-0001`](0001-transporte-datos-ricos.md) — dónde vive `data.json` y por
  qué los datos ricos no van en el metadata.
- [`ADR-0006`](0006-version-politica-pegasus.md) — Pegasus congelado, Qt 5.15,
  no extensible: la razón por la que la alternativa B es imposible.
- `docs/CONVENCION.md` §2.3 — la regla de degradación que sigue el caso "sin
  accent".
