---
id: 0015
title: "Contrato completo de data.json, con nombres de campo explícitos"
status: superseded
date: "2026-07-29"
supersedes: null
superseded-by: 0020
tags: [data, frontend]
---

# 0015 — Contrato completo de `data.json`

## Contexto

[`ADR-0001`](0001-transporte-datos-ricos.md) decidió **dónde** viven los datos
ricos (`media/<set>/data.json`, leído con `XMLHttpRequest`) y **por qué** no
van en el `metadata.pegasus.txt`. Pero nunca especificó **qué forma tienen
adentro**. Lo único que quedó escrito fue un boceto del contexto:

    mags:   [{name, pages, color, img}]
    cheats: { combos:[{n, i}], codes:[{n, i}] }
    review: { score, cats:[[label, val] x6], verdict }

De esos tres, uno ya **quedó obsoleto**: `mags` dejó de embeber la revista y
pasó a ser una referencia (`[{ref}]`), corregido en el propio ADR-0001 y
formalizado en [`ADR-0010`](0010-contrato-magazine-json-extendido.md). Los
otros dos —`cheats` y `review`— siguen exactamente como estaban: un boceto
copiado del prototipo HTML, con nombres de campo abreviados (`n`, `i`) que
nadie decidió, nunca encarnados en un fixture, y que `attract doctor` no
valida. Hoy el doctor solo chequea que el archivo sea JSON válido
(`chk_json_valido`) y que `mags[].ref` resuelva a una carpeta real
(`chk_mags_ref`).

Escribir el theme de producción obliga a cerrar esto: el theme lee estos
campos y tiene que saber exactamente qué esperar. Y dos decisiones tomadas
recién —[`ADR-0013`](0013-accent-por-juego.md) (accent) y
[`ADR-0014`](0014-manual-digitalizado.md) (manual)— agregan campos nuevos al
mismo archivo. Es el momento de escribir el contrato entero de una vez, con
el mismo criterio con el que ADR-0010 escribió el de `magazine.json`.

## Decisión

`media/<set>/data.json` tiene esta forma. **Todos los campos de primer nivel
son opcionales** — un juego sin `data.json` es un juego válido, solo menos
enriquecido, y cada bloque ausente se resuelve según `docs/CONVENCION.md`
§2.3.

```json
{
  "accent":  "string (hex #rrggbb)",
  "accent2": "string (hex #rrggbb)",

  "mags": [
    { "ref": "string (nombre de carpeta bajo media/_magazines/)" }
  ],

  "manual": {
    "pages": ["p001.jpg", "..."]
  },

  "cheats": {
    "combos": [ { "name": "string", "input": "string" } ],
    "codes":  [ { "name": "string", "input": "string" } ]
  },

  "review": {
    "score":   "number (0-100)",
    "verdict": "string",
    "cats": {
      "originalidad": "number (0-100)",
      "graficos":     "number (0-100)",
      "adiccion":     "number (0-100)",
      "sonido":       "number (0-100)",
      "dificultad":   "number (0-100)",
      "animacion":    "number (0-100)"
    }
  }
}
```

Las tres decisiones de forma que este ADR fija, más allá de listar los campos:

### 1. Nombres completos, no abreviaturas

`{name, input}` en vez de `{n, i}`. Las abreviaturas eran taquigrafía interna
del prototipo HTML, donde el objeto se escribía a mano en la misma línea que
se consumía. Acá el archivo lo edita una persona meses después, y el resto de
los contratos del proyecto ya usa nombres completos (`startPage`,
`confidence`, `key_id` en `magazine.json`). Un solo estilo en todo el
proyecto.

### 2. `review.cats` es un objeto, no una lista de pares

El prototipo usa `cats: [["ORIGINALIDAD", 88], ...]`. Acá es un objeto con
seis claves fijas, en minúscula y sin tildes (las etiquetas visibles las pone
el theme, no los datos).

El motivo es concreto y no estético: `docs/CONVENCION.md` §2.1 nota 3 exige
soportar **reseñas parciales** — algunas categorías evaluadas y otras no, con
las que faltan mostrando `"-"`. Con un objeto, "falta" es *la clave no está*:
inequívoco. Con una lista de pares hay que elegir entre un `null` en la
posición, una lista más corta (¿cuál falta?) o mantener el orden por
convención implícita — tres formas de romperse en silencio. El objeto también
saca el orden de los datos y lo deja donde corresponde: en el theme.

Las seis categorías no se inventan acá, ya estaban fijadas en
`docs/CONVENCION.md` §2.1 nota 3.

### 3. Dos niveles de "sin dato", no uno

Se explicita lo que §2.3 ya decidió, porque afecta al contrato:

- `review` ausente o `null` → **no hay reseña**. El bloque NOTA DE LA CRÍTICA
  se muestra entero con `"Sin Información"`.
- `review` presente pero con `cats` incompleto (o sin `cats`, o solo con
  `score`) → **hay reseña parcial**. Se muestra lo que hay; cada categoría
  faltante muestra `"-"`.

El fixture `media/dino/data.json` ya encarna el segundo caso: tiene
`{"review": {"score": 94}}` y nada más. No es un fixture incompleto, es el
caso de reseña parcial.

### Validación en `attract doctor`

El contrato no vale nada si nadie lo chequea. Se agregan a
`CHEQUEOS_UNIVERSALES` de `src/attract/doctor.py` (nunca en un script aparte
— regla de `CLAUDE.md`):

| Chequeo | Nivel |
|---|---|
| `accent`/`accent2` son hex `#rrggbb` válidos | ERROR |
| `cheats.combos[]`/`codes[]` tienen `name` e `input`, ambos string | ERROR |
| `review.score` es número en 0-100 | ERROR |
| `review.cats` solo usa las seis claves conocidas | AVISO |
| `review.cats[*]` son números en 0-100 | ERROR |
| cada archivo de `manual.pages[]` existe en `media/<set>/_manual/` | ERROR |

El criterio de ERROR vs AVISO es el mismo que ya usa `chk_magazine_contrato`
(ADR-0010): rompe la pantalla → ERROR; es raro pero se degrada solo → AVISO.
Una clave desconocida en `cats` no rompe nada (el theme la ignora), un hex
inválido sí deja el juego sin color.

## Alternativas consideradas

### A · Dejar `cheats`/`review` como los bocetó ADR-0001 (`{n, i}`, `cats` como pares)

- A favor: cero decisiones nuevas; es literalmente lo que ya está escrito en
  el contexto de ADR-0001, y el tokenizer del prototipo ya consume esa forma.
- En contra: los nombres abreviados chocan con el resto de los contratos del
  proyecto, y `cats` como lista de pares no puede expresar "esta categoría no
  tiene dato" sin ambigüedad — que es un requisito explícito de
  `CONVENCION.md` §2.1 nota 3, no un caso hipotético.
- **Descartada porque:** hereda una taquigrafía de prototipo como si fuera
  una decisión, y una de sus dos formas no soporta un caso que la convención
  ya declaró obligatorio. El coste de cambiarla es cero hoy (ningún fixture
  ni código la usa todavía) y crece con cada juego que se cargue.

### B · Un archivo por tipo de dato (`cheats.json`, `review.json`, …)

- A favor: cada dato se agrega o se borra por separado; un JSON corrupto
  afecta a un solo bloque en vez de a todos los datos ricos del juego.
- En contra: multiplica por cuatro las peticiones `XMLHttpRequest` por juego
  y los estados de carga que el theme tiene que manejar, para separar cosas
  que en la práctica se editan juntas.
- **Descartada porque:** ADR-0001 ya asumió "una request asíncrona por juego"
  como coste conocido; esto lo cuadruplica sin resolver ningún problema real
  observado. El aislamiento que promete ya lo da el archivo por juego: un
  `data.json` roto afecta a UN juego, no a la colección.

## Consecuencias

**Positivas**

- El theme sabe exactamente qué esperar; ya no hay que inferir la forma del
  prototipo HTML.
- `attract doctor` puede fallar en el Mac por un `data.json` mal escrito, en
  vez de que se descubra mirando la pantalla del gabinete — que es la
  filosofía del doctor.
- Un solo estilo de nombres en todos los contratos del proyecto.
- Las reseñas parciales quedan expresables sin ambigüedad.

**Coste asumido**

- Los fixtures actuales quedan por debajo de este contrato: ninguno tiene
  `accent`, `cheats` ni `manual`. Hay que ampliarlos (ver §Verificaciones
  pendientes) — sin eso el theme no tiene contra qué probarse.
- El tokenizer de trucos se porta del prototipo, que consume `{n, i}`: hay
  que renombrar al portarlo. Es un cambio mecánico y se hace una sola vez.
- Seis claves de categoría fijas: agregar una séptima categoría en el futuro
  toca el contrato, el doctor y el theme.

**Qué habría que revisar si esto se replantea**

- Que aparezca una fuente real de reseñas (equivalente al subsistema de
  revistas de [`ADR-0009`](0009-frontera-produccion-consumo-revistas.md)) que
  produzca otras categorías o otra escala. Ahí este ADR se supersede con el
  contrato real, exactamente como ADR-0010 supersedió a 0008 cuando apareció
  un `magazine.json` de verdad.
- Que `data.json` acumule tantos campos que convenga partirlo — recién ahí la
  alternativa B tiene un motivo concreto.

## Verificaciones pendientes

- [x] **Resuelto 2026-07-29** — fixtures ampliados para encarnar el contrato,
      no solo declararlo, repartido entre dos sets para que cada uno siga
      teniendo un trabajo distinto: `media/dino/data.json` suma
      `accent`/`accent2` y `cheats` (combos con notación de lucha —flechas,
      `+`, `P`/`K`, `PP`— y uno de prosa libre, para que el tokenizer de la
      feature 007 tenga contra qué probarse desde el día uno) sobre los `mags`
      y la `review` parcial que ya tenía; `media/sf2ce/data.json` suma
      `accent`/`accent2` y un `manual` con `_manual/p001-p004.jpg` de 0 bytes,
      conservando su `mags[].ref` colgado a propósito. `media/mok/` sigue
      **sin** `data.json`, que es su caso. Mismo criterio que ADR-0010.
- [x] **Resuelto 2026-07-29** — `chk_data_contrato` en `src/attract/doctor.py`
      (agregado a `CHEQUEOS_UNIVERSALES` vía el runner, no como script
      aparte). Cubre los seis chequeos de la tabla de arriba más la forma de
      `mags[]`, que hasta ahora no validaba nadie: `chk_mags_ref` chequea que
      el `ref` **exista** (AVISO), pero no que la entrada **tenga** un `ref`
      (ERROR — sin `ref` no hay ni degradación posible). 15 tests nuevos en
      `tests/test_doctor.py`, tres de ellos escritos contra errores que este
      contrato hace probables: un `cheats` copiado del prototipo con las
      claves viejas `{n, i}`, un `review.cats` como lista de pares, y un
      `accent` de tres dígitos (`#fb0`, que CSS acepta y QML no).
- [ ] Confirmar contra Pegasus real que un `data.json` con acentos
      (`"verdict"` con tildes) sobrevive el ida y vuelta en NFC — hereda la
      verificación pendiente de ADR-0001.

## Referencias

- [`ADR-0001`](0001-transporte-datos-ricos.md) — dónde vive `data.json` y el
  boceto de forma que este ADR reemplaza por un contrato.
- [`ADR-0010`](0010-contrato-magazine-json-extendido.md) — el precedente:
  contrato completo de `magazine.json`, validado por el doctor.
- [`ADR-0013`](0013-accent-por-juego.md) — por qué `accent` es un campo de
  este archivo.
- [`ADR-0014`](0014-manual-digitalizado.md) — por qué `manual` es un campo de
  este archivo y por qué `pages[]` tiene esta forma.
- `docs/CONVENCION.md` §2.1 nota 3 (las seis categorías) y §2.3 (los dos
  niveles de "sin dato").
- `docs/mockup-referencia.html` líneas 596 y 624-633 — la forma abreviada del
  prototipo, descartada en la alternativa A.
