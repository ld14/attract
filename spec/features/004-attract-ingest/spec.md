# 004 · `attract ingest` — Spec

**Estado:** implementada (verificación contra `mame` real pendiente — ver
`tasks.md`)

## Qué hace

`attract ingest <sistema> <rom.zip>` toma un archivo de ROM que todavía no
tiene entrada en `metadata.pegasus.txt`, usa `mame -listxml <set>` para
sacar su identidad real (título, año, fabricante — lo que el binario sepa,
no lo que alguien tipee a mano), y agrega un bloque `game:` nuevo con esos
datos más los defaults seguros ya establecidos en `docs/CONVENCION.md`
para todo lo que `-listxml` no puede darnos (jugadores → default `1`,
género → sin dato, "Sin Información").

Es el primer módulo que **crea** un bloque `game:` — `synopsis` (feature
001) explícitamente dejó esto fuera de su alcance. También crea la carpeta
`media/<set>/` vacía (assets se agregan después, a mano o con otro
enriquecimiento — este comando no busca cover ni video).

Si `mame -listxml` no puede identificar el archivo con exactamente una
máquina jugable, **no agrega nada** — mismo criterio que `doctor` y
`synopsis`: no adivinar, fallar explícito.

## Por qué

Es el corazón de la misión del proyecto (`mission.md`): "cae una ROM,
ATTRACT arma la estructura de archivos". Hasta ahora todo el banco de
pruebas se armó a mano en los fixtures — este es el primer comando que
hace ese trabajo de verdad. M7 del bootcamp.

## ⚠️ Sobre `mame -listxml`: sin verificar en esta sesión

Este sandbox **no tiene MAME instalado** — no hay forma de correr
`mame -listxml` acá y confirmar la forma exacta del XML. Todo lo que sigue
sobre qué tags trae (`<description>`, `<year>`, `<manufacturer>`) es
conocimiento general del formato de MAME, **no evidencia verificada en
esta sesión** — mismo tipo de honestidad que ya aplicamos con
`_synopsis/<set>.json` (ADR-0011): el contrato puede necesitar un
ADR-superseded el día que se corra contra el binario real y algo no
coincida. Ver `tasks.md` — hay una verificación pendiente marcada
explícitamente para correr en tu Mac.

Lo que sí está verificado (LAB 0.2, esta sesión): el filtro para quedarse
solo con máquinas jugables es
`mame -listxml <set> | grep '<machine name' | grep -v 'runnable="no"'`
— los dispositivos internos (CPU, sonido, memoria) no llevan ese filtro,
solo las máquinas reales.

## Criterios de aceptación

- [x] Dado un `<rom.zip>` cuyo `mame -listxml <set>` devuelve **exactamente
      una** máquina jugable, `attract ingest` agrega un bloque `game:`
      nuevo a `metadata.pegasus.txt` con `file:`, `title` (de
      `<description>`), `developer` (de `<manufacturer>`, si está),
      `release` (de `<year>`, si está), `x-set: <set>`. **Probado contra
      XML sintético, no contra `mame` real — ver `tasks.md`.**
- [x] Crea `media/<set>/` (carpeta vacía) si no existe.
- [x] Si `<set>` ya tiene un bloque `game:` en `metadata.pegasus.txt`, no
      duplica — falla explícito.
- [x] Si `mame -listxml <set>` devuelve **cero** máquinas jugables, falla
      explícito, no agrega nada.
- [x] Si devuelve **más de una** máquina jugable, falla explícito con un
      mensaje que lo diga — no intenta adivinar cuál usar.
- [x] Si el binario `mame` no está en el `PATH`, falla explícito — probado
      contra la ausencia real de `mame` en este sandbox, no mockeado.
- [x] `attract doctor` sigue pasando después de ingestar.

## Fuera de alcance

- Buscar o generar assets (cover, video, marquee) — sigue siendo trabajo
  manual o de otro módulo futuro.
- `genre` — MAME `-listxml` históricamente no lo incluye (viene de
  `catver.ini`, un archivo aparte que no forma parte del `-listxml`
  estándar); queda en su default de `docs/CONVENCION.md` ("Sin
  Información") hasta que exista una fuente real.
- Limpiar el `title` de tags de región/revisión que a veces trae
  `<description>` (ej. `"(Japan 920513)"`) — se usa tal cual viene del
  binario. Si en la práctica ensucia mucho la pantalla, es una feature
  aparte, no un parche silencioso acá.
- El caso "un archivo, múltiples juegos jugables de verdad" — falla
  explícito en vez de intentar resolverlo (ver Criterios de aceptación).
- Escanear una carpeta completa buscando ROMs nuevas — este comando toma
  un archivo puntual por vez.
