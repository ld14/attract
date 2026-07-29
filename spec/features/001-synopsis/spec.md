# 001 · Synopsis generado — Spec

**Estado:** implementada

## Qué hace

`attract synopsis <set>` toma un synopsis ya producido por un **sistema de
scraping externo** (ATTRACT no lo genera, lo consume — ver
[`ADR-0011`](../../decisions/0011-fuente-synopsis-regeneracion-campo.md)) y
lo hace aparecer en la pantalla del gabinete: lo escribe en el campo
`summary:` (campo nativo de Pegasus, ver `docs/CONVENCION.md` §2.1) del
`game:` correspondiente en `metadata.pegasus.txt`.

El texto sale de una fuente persistida por juego
(`library/<sistema>/_synopsis/<set>.json`), no de un argumento de CLI —
así queda rastreable y el comando es re-ejecutable sin duplicar trabajo.
Escribir es un **merge de un solo campo**: solo se toca la línea `summary:`
del bloque `game:`; todo lo demás en ese bloque (`developer`, `genre`,
`file:`, `assets.*`, `x-*`) queda intacto.

## Por qué

Es la primera vez que algo en ATTRACT escribe `metadata.pegasus.txt`
programáticamente — hasta ahora `doctor` solo valida. Resuelve una carencia
real: la enorme mayoría de los juegos de la librería nunca van a tener un
synopsis escrito a mano (ver `mission.md`, "el caso principal es el juego
pelado"), y ahora hay un sistema externo que sí los produce — falta la pieza
que los hace llegar a la pantalla. También es el ejercicio central de los
módulos M1-M2 del bootcamp.

## Criterios de aceptación

- [x] Dado un `set` con fuente en `library/<sistema>/_synopsis/<set>.json`
      y una entrada `game:` ya existente en `metadata.pegasus.txt`,
      `attract synopsis <set>` escribe/actualiza la línea `summary:` de ese
      bloque con el texto de la fuente.
- [x] El resto del bloque `game:` (todas las demás líneas) queda idéntico,
      byte a byte, antes y después de correr el comando.
- [x] Correr el comando dos veces seguidas con la misma fuente produce el
      mismo archivo — idempotente, no duplica ni desordena líneas.
- [x] `attract doctor` sigue pasando sin errores después de escribir
      (UTF-8, NFC, LF — mismos chequeos que ya existen).
- [x] Si no existe fuente para ese `set`, el comando no escribe nada y
      termina con un mensaje explícito, no con un archivo vacío o
      silenciosamente sin cambios.
- [x] Si el `set` no tiene un bloque `game:` en `metadata.pegasus.txt`
      (juego no ingresado todavía), falla explícito — no crea un bloque
      nuevo (eso es responsabilidad de otra feature, ver Fuera de alcance).

## Fuera de alcance

- **Generar o scrapear el texto del synopsis** — lo hace el sistema externo;
  ver [`ADR-0011`](../../decisions/0011-fuente-synopsis-regeneracion-campo.md).
- **Crear un `game:` nuevo en `metadata.pegasus.txt`** — esta feature solo
  actualiza el campo `summary:` de un juego que ya existe. Ingesta de juegos
  nuevos es `attract ingest` (M7).
- **Migrar el resto de los campos a un modelo de fuente** — decisión
  descartada por ahora en ADR-0011, opción B.
- **Validar que el texto sea fácticamente correcto** — ATTRACT confía en la
  fuente externa; no hay verificación de contenido más allá de encoding.
