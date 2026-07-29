---
id: 0008
title: "Revistas como entidad de primera clase, referenciadas por los juegos"
status: superseded
date: "2026-07-23"
supersedes: null
superseded-by: 0010
tags: [data, backend]
---

# 0008 — Modelo de datos de revistas: entidad de primera clase

## Contexto

Una revista **no pertenece a un solo juego**. Una misma revista (ej. PC
Juegos Nº32) puede tener notas de varios juegos en páginas distintas — Mario
en la página 15, Day of the Tentacle en las páginas 16-20. Si las páginas se
guardan "dentro" de la carpeta de cada juego que cubre, la revista entera se
duplica tantas veces como juegos mencione.

Requisito adicional que definió la forma final: el usuario tiene que poder
abrir el visor **desde la página de un juego** (entra directo en la nota de
ese juego) pero **luego poder hojear la revista completa**, no quedar
limitado a esa nota — la nota es la puerta de entrada, no un límite.

## Decisión

Las revistas son una **entidad separada** de los juegos, con su propia
carpeta e identidad en `media/_magazines/<revista>-<número>/`. Los juegos la
**referencian**, no la contienen. Relación muchos-a-muchos: una revista
cubre muchos juegos, un juego puede aparecer en muchas revistas.

**Estructura de carpetas:**

```
media/
├─ _magazines/                    ← las revistas, cada una UNA sola vez
│  └─ <revista>-<número>/
│     ├─ magazine.json            ← el contrato completo (ver abajo)
│     ├─ cover.jpg
│     └─ p001.jpg … pNNN.jpg      ← TODAS las páginas del escaneo, en orden
│
└─ <juego>/                       ← carpeta = set de MAME, no título
   ├─ boxFront.jpg, video.mp4…    ← assets nativos, auto-descubiertos
   └─ data.json                   ← REFERENCIA a revistas, no las contiene
```

**Formato de `magazine.json`:**

```json
{
  "name": "PC JUEGOS",
  "issue": "32",
  "year": 1993,
  "color": "#7d2fb8",
  "cover": "cover.jpg",
  "pages": ["p001.jpg", "p002.jpg", "..."],
  "articles": [
    { "game": "mario", "title": "Super Mario", "startPage": 15, "pages": [15] },
    { "game": "dott",  "title": "Day of the Tentacle", "startPage": 16, "pages": [16, 17, 18, 19, 20] }
  ]
}
```

- `pages` (nivel revista) = TODAS las páginas del escaneo, en orden — lo que
  el visor recorre cuando el usuario hojea la revista entera.
- `articles[].pages` = lista de números sueltos, **no un rango**, porque una
  nota puede estar en páginas no consecutivas (cortada por publicidad, etc.).
  Ver `fixtures/arcade/media/_magazines/micromania-16/magazine.json`, que
  cubre exactamente este caso: `[3, 4, 5, 7, 8]`.
- `articles[].startPage` = dónde abre el visor cuando se entra desde ese
  juego — explícito, no inferido, para que el pipeline no tenga que adivinar.

**Formato de `data.json` de un juego (referencia, no copia):**

```json
{ "mags": [ { "ref": "micromania-16" } ] }
```

El juego no repite sus páginas — ya están en `magazine.json → articles[]`,
buscando por `game == "<set>"`. Una sola fuente de verdad.

## Alternativas consideradas

### A · Páginas embebidas dentro de la carpeta de cada juego

- A favor: sin indirección — todo lo que necesita un juego está en su propia
  carpeta, sin ir a buscar a otro lado.
- En contra: una revista que cubre 5 juegos se duplica 5 veces. Conseguir
  una revista nueva no enriquece nada automáticamente, hay que copiarla a
  mano en cada carpeta que corresponda.
- **Descartada porque:** duplica el escaneo tantas veces como juegos cubra,
  exactamente el problema que origina esta decisión.

### B · Lista paralela (ej. `magazines.json` global con un array plano)

- A favor: un solo archivo central, fácil de listar todas las revistas.
- En contra: no soporta la estructura de dos niveles que necesitan los
  combos (revista → artículos → páginas sueltas no consecutivas) sin
  anidar de todos modos: termina siendo la misma estructura pero en un
  único archivo gigante en vez de uno por revista.
- **Descartada porque:** no aporta nada sobre la opción elegida y concentra
  todo en un archivo que crece sin límite con cada revista nueva.

## Consecuencias

**Positivas**

- Cero duplicación de escaneos — una revista vive una sola vez, sin importar
  cuántos juegos cubra.
- Conseguir una revista nueva enriquece automáticamente a todos los juegos
  que ya la referencian, sin tocar sus carpetas.
- Permite a futuro una sección "explorar revistas" en el frontend, porque la
  revista existe como entidad navegable por sí misma, no solo como anexo de
  un juego.
- El contrato ya está encarnado en fixtures reales, no en un ejemplo de
  documentación: `fixtures/arcade/media/_magazines/micromania-16/` con
  páginas no consecutivas, `dino/data.json` referenciándola, y
  `sf2ce/data.json` con un `ref` a una revista inexistente a propósito, para
  el caso de degradación.

**Coste asumido**

- El theme tiene que encadenar **dos** lecturas de JSON: leer el `data.json`
  del juego, sacar el `ref`, y recién ahí cargar el `magazine.json`
  correspondiente. Más complejidad que leer un solo archivo.
- Hay una relación muchos-a-muchos real que mantener consistente: si se
  borra o renombra una revista, hay que revisar qué juegos la referencian
  para no dejar `ref` colgados (aunque el sistema debe degradar bien si
  pasa, ver Verificaciones pendientes).

**Qué habría que revisar si esto se replantea**

- Si en la práctica ninguna revista termina cubriendo más de un juego (el
  caso que motiva toda la decisión no se da nunca), la indirección de dos
  archivos deja de pagarse y valdría volver a la opción A.

## Verificaciones pendientes

- [x] **Confirmado 2026-07-28** — el theme encadena las dos lecturas de JSON
      (`data.json` del juego → `magazine.json` de la revista) sin problema.
      Verificado contra Pegasus real con `themes/experimentos/json-chain-test.qml`.
      La técnica de `XMLHttpRequest` + `JSON.parse` de ADR-0001 funciona
      igual la segunda vez, encadenada a partir del resultado de la primera.
- [ ] Confirmar que el theme degrada bien si `data.json` no existe (juego
      sin revista) — fixture listo: `media/mok/` no tiene `data.json`.
- [ ] Confirmar que el theme degrada bien si `mags[].ref` apunta a una
      revista que no existe — fixture listo: `media/sf2ce/data.json`
      referencia `"revista-que-no-existe"`.
- [ ] `attract doctor` no valida todavía que `mags[].ref` resuelva a una
      carpeta real en `_magazines/` (ver `docs/CONVENCION.md` §4.4, "falta").

## Referencias

- `docs/decisiones/2026-07-23.md` punto 5 — razonamiento completo original.
- `docs/CONVENCION.md` §1.3 y §1.4 — dónde viven los assets y los datos
  ricos, ya asumen esta estructura.
- `fixtures/arcade/media/_magazines/README.md` — qué caso cubre cada
  fixture.
- [`0001-transporte-datos-ricos.md`](0001-transporte-datos-ricos.md) — por
  qué `data.json` es externo y se lee con `XMLHttpRequest`.
- [`0009-frontera-produccion-consumo-revistas.md`](0009-frontera-produccion-consumo-revistas.md)
  — qué NO es responsabilidad de ATTRACT dentro de este modelo.
