---
id: 0011
title: "attract synopsis escribe desde una fuente persistida, no parchea el artefacto a mano"
status: accepted
date: "2026-07-28"
supersedes: null
superseded-by: null
tags: [data, backend]
---

# 0011 — `attract synopsis` escribe desde una fuente persistida

## Contexto

`attract synopsis` (spec [`001-synopsis`](../features/001-synopsis/spec.md))
tiene que hacer que un synopsis, producido por un sistema de scraping
**externo** a ATTRACT, termine visible en la pantalla del gabinete — es
decir, en el campo `summary:` del `game:` correspondiente en
`metadata.pegasus.txt`.

Pero `metadata.pegasus.txt` es **artefacto de build, no fuente**
([`ADR-0002`](0002-metadata-fuente-o-artefacto.md), accepted): "nunca se
edita a mano ni se versiona como fuente". El problema es que hoy **nada lo
genera programáticamente todavía** — todo su contenido (en fixtures/docs, la
excepción explícita) está escrito a mano. No existe ningún modelo de
"fuente" del que ATTRACT pueda generar el archivo.

Escribir el synopsis tiene que resolver esto sin dos extremos: sin volver a
editar el artefacto a mano (rompe ADR-0002 en la práctica, aunque lo escriba
un script en vez de un humano — el problema es que no queda rastro de dónde
salió el texto), y sin tener que migrar **todos** los campos existentes
(`developer`, `genre`, `file:`, `assets.*`, `x-*`) a un modelo de fuente de
una sola vez — eso es un problema mucho más grande que esta feature, y hoy
nadie más los escribe programáticamente.

## Decisión

Se crea una **fuente persistida, un archivo por juego, solo para el campo
`synopsis`**: `library/<sistema>/_synopsis/<set>.json`, contrato mínimo:

```json
{ "summary": "texto que produjo el sistema externo de scraping" }
```

Ahí es donde cae el resultado del scraping externo. **ATTRACT no scrapea, no
genera texto — lo consume**, mismo criterio de frontera que
[`ADR-0009`](0009-frontera-produccion-consumo-revistas.md) aplicó a las
revistas.

`attract synopsis <set>` lee esa fuente y hace un **merge campo a campo**
contra el `game:` correspondiente en `metadata.pegasus.txt`: si ya existe una
línea `summary:` la reemplaza, si no existe la inserta, y **el resto del
bloque `game:` queda intacto, byte a byte** — no se toca `developer`,
`genre`, `file:`, `assets.*`, `x-*`, nada más.

Es regeneración **del campo**, no del archivo entero: correr el comando dos
veces seguidas con la misma fuente da exactamente el mismo resultado
(idempotente). El campo `summary` deja de poder "vivir solo en la cabeza de
quien lo escribió" — siempre sale de un archivo rastreable.

## Alternativas consideradas

### A · Parche libre por CLI, sin fuente persistida

`attract synopsis <set> "texto..."` — el texto se pasa como argumento y se
escribe directo, sin quedar un archivo del que salió.

- A favor: cero archivos nuevos, la forma más simple posible de implementar.
- En contra: no es rastreable ni re-ejecutable — perdés el texto si no lo
  guardaste en otro lado. Vuelve a la situación que ADR-0002 quiere evitar:
  el `summary` vive solo dentro del artefacto, sin fuente.
- **Descartada porque:** el usuario pidió explícitamente que el scraping sea
  responsabilidad de un sistema externo — eso implica que ese sistema
  necesita un lugar fijo donde dejar su resultado, no un argumento de CLI
  que alguien tipea a mano cada vez.

### B · Fuente completa + regeneración total del archivo

Migrar **todos** los campos (no solo `summary`) a un modelo de fuente, y
regenerar `metadata.pegasus.txt` entero desde ahí cada vez.

- A favor: cumple ADR-0002 al pie de la letra — el artefacto nunca tiene
  nada que no venga de una fuente, para ningún campo.
- En contra: requiere migrar `developer`, `genre`, `players`, `file:`,
  `assets.*`, `x-*` — todo lo que hoy está escrito a mano en la librería
  real — antes de poder generar nada. Mucho más trabajo que M1-M2, y sin
  necesidad real todavía: hoy nada más escribe esos campos
  programáticamente.
- **Descartada por ahora porque:** el problema que hay que resolver hoy es
  un campo (`summary`), no el pipeline completo. Si en el futuro
  (`attract ingest`, M7) hace falta generar el archivo completo, se retoma
  esta decisión ahí — con más evidencia real de qué campos necesitan fuente.

## Consecuencias

**Positivas**

- `summary` queda siempre rastreable a un archivo fuente concreto —
  reproducible, no "se escribió una vez y se perdió el origen".
- Idempotente: correr `attract synopsis` de nuevo con la misma fuente no
  cambia nada.
- No colisiona con campos que hoy se siguen escribiendo a mano — el merge es
  quirúrgico, solo toca `summary:`.
- Mismo patrón de frontera que ya funcionó para revistas (ADR-0009):
  consumir, no producir.

**Coste asumido**

- El resto de `metadata.pegasus.txt` sigue sin fuente real — ADR-0002 queda
  parcialmente cumplido (solo para `summary`), no del todo. Documentado acá,
  no resuelto.
- El formato exacto de `library/<sistema>/_synopsis/<set>.json` es un
  **supuesto sin evidencia real** todavía — no hay ningún archivo real del
  sistema de scraping externo para contrastarlo (mismo punto de partida que
  tuvo `magazine.json` en ADR-0008, antes de que apareciera uno real y
  motivara ADR-0010). Puede necesitar su propio ADR-superseded el día que
  aparezca un archivo real.

**Qué habría que revisar si esto se replantea**

- Si aparece necesidad real de más campos programáticos (no solo
  `synopsis`), reabrir con la opción B.
- Si el sistema externo de scraping termina entregando algo con forma
  distinta a `{"summary": "..."}`, esta ADR se supersede (mismo patrón que
  0008 → 0010).

## Verificaciones pendientes

- [ ] Confirmar formato real de entrega del sistema de scraping externo
      (nombre de archivo, carpeta, encoding) — hoy es un supuesto razonable,
      no verificado.
- [ ] Confirmar que el merge campo a campo no rompe NFC/UTF-8/LF —
      `attract doctor` tiene que seguir pasando después de escribir.

## Referencias

- [`0002-metadata-fuente-o-artefacto.md`](0002-metadata-fuente-o-artefacto.md)
  — por qué el artefacto nunca se edita a mano.
- [`0009-frontera-produccion-consumo-revistas.md`](0009-frontera-produccion-consumo-revistas.md)
  — mismo criterio de frontera aplicado antes, a otro tipo de dato.
- [`0008-modelo-datos-revistas.md`](0008-modelo-datos-revistas.md) /
  [`0010-contrato-magazine-json-extendido.md`](0010-contrato-magazine-json-extendido.md)
  — precedente de "contrato inventado sin evidencia real, corregido después".
- [`../features/001-synopsis/spec.md`](../features/001-synopsis/spec.md).
