---
id: 0025
title: "Linkear revista y juego por coincidencia difusa, proponiendo antes de escribir"
status: accepted
date: "2026-08-10"
supersedes: null
superseded-by: null
tags: [backend, data, proceso]
---

# 0025 — Link revista→juego por coincidencia difusa

## Contexto

Una revista declara de qué juegos habla en `magazine.json → articles[].game`.
Un juego declara en qué revistas aparece en `data.json → mags[{ref}]`
([`ADR-0001`](0001-transporte-datos-ricos.md)). Las dos puntas de la misma
relación se escriben en archivos distintos, y hasta hoy la segunda se
escribía **a mano**.

`micromania-34` tiene 20 artículos con `game`. Cargar una sola revista
significa abrir hasta 20 `data.json` y agregar el mismo `ref` en cada uno,
sabiendo además cuáles de esos 20 juegos están efectivamente instalados. Eso
es exactamente el trabajo que ATTRACT existe para evitar: *"cae una ROM, la
pantalla se genera sola con lo que haya"*.

El obstáculo es que **los dos lados no usan el mismo identificador**:

| | identificador | ejemplo |
|---|---|---|
| revista | slug editorial del generador | `golden-axe` |
| Pegasus | set de MAME ([`ADR-0004`](0004-identidad-set-merged.md)) | `goldnaxe` |

No es un problema de formato. Normalizar (minúsculas, sacar guiones) da
`goldenaxe` contra `goldnaxe`: al set de MAME le falta una `e`, porque los
nombres de set de MAME son abreviaturas históricas de 8 caracteres, no
slugs derivados del título. Ninguna regla determinística los une.

## Decisión

Un comando nuevo, `attract mags`, recorre las revistas de
`<raíz>/_magazines/`, matchea cada `articles[].game` contra los sets
instalados por **coincidencia difusa**, y mergea el `ref` en el `data.json`
de cada juego que matchee.

**Coincidencia difusa con `difflib.SequenceMatcher`** (stdlib — no toca el
límite de dependencias de `spec/constitution/tech-stack.md`). El slug
normalizado se compara contra dos candidatos por juego —el **set** y el
**título** de `metadata.pegasus.txt`— y se toma el mejor ratio. Umbral
**0.85**.

El umbral no es una suposición. Medido contra la revista real, los 20 slugs
de `micromania-34` contra los 2 sets instalados:

```
golden-axe        → goldnaxe   0.94  ← el único match
voodoo-nightmare  → goldnaxe   0.43  ← el falso candidato más alto
colony            → goldnaxe   0.43
zelda-ii-…        → mok        0.43
```

Un orden de magnitud de separación entre la señal y el ruido. 0.85 cae
holgadamente en el medio.

**Propone antes de escribir.** Sin `--apply` el comando no toca ningún
archivo: imprime cada slug con su mejor candidato y su ratio, incluidos los
que no llegaron al umbral. Con `--apply`, el `data.json` se **mergea**: se
lee, se agrega la entrada si falta, se reescribe conservando todo lo demás.
Nunca se sobrescribe. Correrlo dos veces no duplica nada.

**Se escribe el slug resuelto, no solo el `ref`:**

```json
"mags": [ { "ref": "micromania-34", "article": "golden-axe" } ]
```

`article` es el `articles[].game` que trata sobre este juego. Sin él el
problema queda resuelto a medias: la revista aparece en el carrusel y abre,
pero el theme no puede encontrar **la nota** — `MagazineData.articuloDe()`
compara contra el set que conoce (`goldnaxe`) y el artículo dice `golden-axe`,
así que devuelve `null` y el visor abre en la página 1 en vez de en la 46.

Es el mismo mismatch, en el otro extremo del recorrido. Se resuelve
escribiéndolo en vez de repetir el matching difuso en QML: la heurística vive
en **un solo lugar**, y lo que queda escrito es un match que una persona ya
revisó en el dry-run. `article` es **opcional** — sin él el theme busca por el
set, que es lo correcto justamente cuando los dos coinciden (todos los
fixtures). Si el `ref` ya está, la entrada no se toca aunque el slug difiera:
una corrección a mano le gana al match difuso.

## Alternativas consideradas

### Alias explícito en `data.json` (`"magSlugs": ["golden-axe"]`)

- A favor: cero heurística, cero falsos positivos, el contrato queda
  determinístico y auditable.
- En contra: hay que anotar cada juego a mano, que es literalmente el trabajo
  que se quiere eliminar. Y el alias hay que escribirlo **antes** de saber
  qué revistas van a aparecer, así que en la práctica se escribe después de
  cargar cada revista — el mismo esfuerzo, con un campo más que mantener.
- **Descartada porque:** no resuelve el problema, lo renombra. Queda
  disponible como escape si algún día aparece un juego que el matching no
  puede resolver.

### Comparación exacta sobre slugs normalizados

- A favor: trivial de implementar y de explicar.
- En contra: **no funciona**. `golden-axe` normaliza a `goldenaxe` y el set
  es `goldnaxe`. Los nombres de set de MAME son abreviaturas históricas
  (`sf2ce`, `mok`, `goldnaxe`), no derivaciones del título.
- **Descartada porque:** falla en el primer caso real que se probó.

### Escribir los matches sin confirmación

- A favor: menos fricción, un solo comando y listo.
- En contra: el matching es heurístico. Las familias de MAME con muchos sets
  (`sf2ce`, `sf2ceua`, `sf2cej`…) tienen títulos casi idénticos, y un match
  al set equivocado se escribiría en silencio en un archivo versionado.
- **Descartada porque:** un falso positivo silencioso en `data.json` es más
  caro de detectar que el segundo comando que cuesta evitarlo. El dry-run por
  defecto no impide automatizar: `--apply` sigue siendo un solo flag.

### Consumir `game_hints.json` además de `articles[]`

La carpeta de la revista trae un `game_hints.json` con `game` + `startPage` +
plataformas.

- A favor: trae plataforma y editor, que podrían afinar el matching.
- En contra: en `micromania-34` sus 15 entradas son un **subconjunto** de los
  20 `articles[].game`. No aporta ningún juego nuevo, y no está en el
  contrato de [`ADR-0024`](0024-contrato-magazine-json-v2.md).
- **Descartada porque:** es una segunda fuente para el mismo dato sin
  cobertura adicional. Si el matching por slug resulta insuficiente, la
  plataforma de `game_hints.json` es la primera pista a mirar para desempatar.

## Consecuencias

**Positivas**

- Cargar una revista pasa de editar N `data.json` a correr un comando. La
  relación se deriva del dato que el generador ya produjo.
- El reporte muestra también los juegos **no instalados** que la revista
  cubre, así que funciona como lista de qué vale la pena conseguir.
- Al ser un merge idempotente, se puede correr después de cada ROM nueva sin
  pensar: un juego que se instala hoy queda linkeado a las revistas que ya
  estaban cargadas.
- Reusa el parser de `metadata.pegasus.txt` que `attract synopsis` ya tiene
  (`parsear_bloques`, `identificar_set`), sin un segundo parser que mantener.

**Coste asumido**

- Un umbral difuso es un número elegido con la evidencia disponible hoy: dos
  sets instalados y una revista. Con una librería grande el margen entre
  señal y ruido se achica, y el dry-run pasa de conveniencia a necesidad.
- El matching no distingue entre sets de la misma familia. Para `sf2ce` y sus
  variantes la decisión la sigue tomando un humano leyendo el reporte.
- `data.json` es un archivo escrito a mano que ahora también escribe una
  herramienta. El merge conservador lo hace seguro, pero deja de ser fuente
  100% manual.

**Qué habría que revisar si esto se replantea**

- Si aparecen falsos positivos por encima de 0.85, el camino no es bajar la
  confianza en el umbral sino sumar una señal: la plataforma de
  `game_hints.json`, o el año de la revista contra el `release:` del juego.
- Si el generador algún día emite el set de MAME en vez de un slug editorial,
  todo esto se reduce a una comparación exacta y el ADR se supersede.

## Verificaciones pendientes

- [x] **Resuelto 2026-08-10** — `attract mags library` propone
      `golden-axe → goldnaxe` (0.94, vía set) y nada más, sin escribir.
      `--apply` dos veces seguidas deja una sola entrada en `mags[]` y
      conserva `accent`, `review`, `cheats` y `manual` del `data.json`.
- [x] **Resuelto 2026-08-10, y de acá salió el campo `article`** — con solo el
      `ref` escrito, el autor abrió Pegasus y la revista cargaba bien pero el
      visor no se posicionaba en la nota de Golden Axe: abría en la página 1.
      `articuloDe()` comparaba el set (`goldnaxe`) contra `articles[].game`
      (`golden-axe`) y devolvía `null`. El mismo mismatch de slug que motiva
      esta ADR, en el otro extremo del recorrido — y la prueba de que
      resolverlo solo del lado del `ref` dejaba el problema a medias.
- [ ] Con el `article` escrito: abrir la revista sobre Golden Axe cae en
      `p046.jpg` y las miniaturas destacan 46/47/48.

## Referencias

- [`0024-contrato-magazine-json-v2.md`](0024-contrato-magazine-json-v2.md) —
  la estructura de la que se leen los slugs.
- [`0004-identidad-set-merged.md`](0004-identidad-set-merged.md) — de dónde
  sale el identificador del lado de Pegasus.
- [`0001-transporte-datos-ricos.md`](0001-transporte-datos-ricos.md) —
  `mags[{ref}]`, el campo que este comando escribe.
- `library/_magazines/micromania-34/` — los 20 slugs con los que se midió el
  umbral.
