---
id: 0001
title: "Transporte de datos ricos al theme vía data.json externo"
status: accepted
date: 2026-07-17
supersedes: null
superseded-by: null
tags: [data, frontend]
---

# 0001 — Transporte de datos ricos al theme vía data.json externo

## Contexto

El mockup necesita estructuras anidadas por juego:

    mags:   [{name, pages, color, img}]
    cheats: { combos:[{n, i}], codes:[{n, i}] }
    review: { score, cats:[[label, val] x6], verdict }

**Ajuste 2026-07-23:** una revista no pertenece a un solo juego — la misma
revista cubre notas de varios juegos en páginas distintas. Si las páginas
vivieran dentro de la carpeta de cada juego, el escaneo se duplicaría tantas
veces como juegos cubra. Esto saca a `mags` del `data.json` embebido y lo
convierte en una referencia (ver Decisión). `cheats` y `review` no cambian:
siguen siendo datos propios de un solo juego, sin este problema de duplicación.

Pegasus expone los campos custom vía `x-` como `game.extra.<nombre>`.

**Resultado del experimento (Bloque 3):**
`game.extra.X` NO es un string, como afirma la documentación. Es SIEMPRE una
lista (un `QStringList` envuelto por Qt). Incluso `x-simple: valor` vuelve como
`["valor"]`. No es un `Array` de JS (`Array.isArray()` da false), pero el
acceso por índice `[0]` funciona. Las claves con guión se preservan literales:
`extra["con-guion"]`.

**Resultado del experimento (opción C):**
Un theme QML SÍ puede leer un archivo `.json` externo con `XMLHttpRequest`
sobre una ruta `file://`. Verificado en Pegasus: el archivo se lee, se parsea,
y se accede a estructura de dos niveles (`datos.mags[0].name`) sin problemas.

## Decisión

Los datos ricos (`mags`, `cheats`, `review`) viven en un **archivo `.json`
aparte por juego**, junto a los assets del juego. En `metadata.pegasus.txt` no
va ninguno de estos datos; a lo sumo, un puntero.

`mags` NO embebe páginas ni metadata de la revista: es una lista de
referencias a una revista, que vive como entidad separada (contrato completo
pendiente de ADR propio — referenciado como "ADR-0008" en la versión anterior
de este documento; ese ADR todavía no existe en `spec/decisions/`, ver
`spec/constitution/roadmap.md`). `cheats` y `review` sí van embebidos
completos, porque son propios de un solo juego.

Estructura:

    media/
    ├─ _magazines/
    │  └─ pcjuegos-32/
    │     ├─ magazine.json   ← contrato completo (ADR pendiente), incluye páginas y notas
    │     └─ p001.jpg ... p100.jpg
    │
    └─ <set>/
       ├─ boxFront.jpg       ← assets nativos (auto-descubiertos por Pegasus)
       ├─ video.mp4
       └─ data.json          ← { mags: [{ref}], cheats, review }

El theme lee `data.json` con `XMLHttpRequest` y lo parsea con `JSON.parse`.
Para mostrar una revista, encadena una segunda lectura: saca el `ref` de
`mags[]` y carga el `magazine.json` correspondiente (verificación pendiente,
no corrida — ver §Verificaciones pendientes).

**Criterio rector:** el **enriquecimiento progresivo barato**. Agregar datos
ricos a un juego seis meses después tiene que costar lo mismo que agregar una
carátula: dropear/editar un archivo sin tocar código ni el metadata central.
Los assets nativos de Pegasus (carátula, video, marquee) ya tienen esta
propiedad porque se auto-descubren; la opción C la extiende a los datos ricos.

**Por qué `mags` es referencia y no copia (ajuste 2026-07-23):** el mismo
criterio aplica al revés — conseguir una revista nueva tiene que enriquecer
automáticamente a TODOS los juegos que ya la referencian, sin tocar cada
`data.json`. Embeber la revista en cada juego que cubre rompe esto: la misma
revista se copiaría en cada juego, y una corrección (ej. página mal asignada)
habría que aplicarla en N lugares.

## Alternativas consideradas

### A · JSON embebido en un campo `x-`

- A favor: una sola fuente de verdad, sin archivos satélite.
- En contra: agregar un scan obliga a editar JSON minificado a mano dentro de
  `metadata.pegasus.txt`, y un error de sintaxis rompe el campo entero en
  silencio.
- **Descartada porque:** rompe el enriquecimiento progresivo, que es el
  criterio rector.

### B · Listas paralelas (`x-mag-names`, `x-mag-pages`...)

- A favor: aprovecha que `extra` ya es una lista nativa; elegante para un solo
  nivel de anidamiento.
- En contra: los combos tienen dos niveles (`cheats.combos[].n`) y la
  correlación por índice entre listas paralelas es frágil — si a una revista
  le falta el color, todo se desalinea en silencio.
- **Descartada porque:** no soporta estructura de dos niveles sin volverse
  ilegible y frágil.

## Consecuencias

**Positivas**

- Enriquecimiento progresivo barato: sumar datos ricos es editar/dropear un
  archivo.
- Soporta cualquier profundidad de anidamiento (verificado: dos niveles).
- El `metadata.pegasus.txt` queda limpio y legible.
- Un error de sintaxis en un `data.json` afecta a UN juego, no a toda la
  colección.
- El archivo es diffeable y versionable en git de forma legible.

**Coste asumido**

- Dos fuentes de verdad por juego: `metadata.pegasus.txt` (campos nativos) y
  `data.json` (datos ricos). Hay que mantenerlos coherentes — en la práctica
  el generador de ATTRACT centraliza esto, no depende de disciplina manual.
- El theme depende de lectura de archivos en runtime (`XMLHttpRequest` +
  `file://`). Si Pegasus cambiara su política de seguridad en una versión
  futura, se rompe.
- Una request HTTP asíncrona por juego para cargar los datos ricos: hay que
  manejar el estado de carga en el theme.
- El theme queda acoplado al patrón "leer `data.json` con XHR"; migrar a otro
  transporte obliga a tocarlo. La convención de ubicación
  (`media/<set>/data.json`) queda fijada: cambiarla obliga a mover archivos en
  toda la librería.

**Qué habría que revisar si esto se replantea**

- Pegasus deja de permitir `XMLHttpRequest` sobre `file://` en una versión
  futura.
- El theme no logra degradar con elegancia cuando `data.json` falta o está
  corrupto (mostrar el juego sin datos ricos, no crashear) — sigue sin
  verificarse.

## Verificaciones pendientes

- [ ] Confirmar que el theme degrada bien cuando `data.json` no existe
      (mostrar el juego igual, sin datos ricos, sin crashear).
- [ ] Confirmar que un `data.json` con acentos (MICROMANÍA) sobrevive el ida y
      vuelta en NFC.
- [ ] Definir en `docs/CONVENCION.md` el nombre y ubicación exactos del
      archivo.
- [ ] Verificar el comportamiento con rutas relativas vs. absolutas en el XHR
      (el experimento usó ruta absoluta hardcodeada — ver `themes/attract-debug/theme.qml`).
- [ ] Encadenar DOS lecturas de JSON en el theme: `data.json` del juego → sacar
      `ref` → cargar `magazine.json` correspondiente (probado un JSON externo
      suelto; falta la cadena).
- [ ] Confirmar que el theme degrada bien si `mags[].ref` apunta a una revista
      que no existe.

## Referencias

- Experimento Bloque 3 / opción C, corrido contra `themes/attract-debug/`.
- Ajuste 2026-07-23 documentado en [`docs/decisiones/2026-07-23.md`](../../docs/decisiones/archivadas/2026-07-23.md).
