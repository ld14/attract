# 004 · `attract ingest` — Spec

**Estado:** implementada, forma del XML confirmada contra `mame` real
2026-07-29 (ver `tasks.md` — queda un punto menor: si Pegasus acepta
`release: <solo año>` en pantalla, eso necesita el gabinete).

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

## ✅ Sobre `mame -listxml`: confirmado 2026-07-29

Este sandbox no tiene MAME instalado (se intentó `apt-get install mame`;
sin acceso root, no se pudo). Pero el autor corrió `mame -listxml sf2ce`
en su Mac (mame vanilla 0.288) y pegó la salida completa acá — evidencia
real, no una suposición. Confirmado contra ese XML literal
(`tests/test_ingest.py::XML_SF2CE_REAL` /
`test_forma_real_confirmada_2026_07_29`):

- El `<!DOCTYPE mame [...]>` con subset interno (declaraciones `<!ELEMENT>`/
  `<!ATTLIST>`) precede a `<mame>` y **no rompe** `ET.fromstring` — dudaba
  esto explícitamente, quedó descartado como riesgo.
- `<description>`, `<year>`, `<manufacturer>` son los tags reales, tal
  como se había asumido.
- `runnable="no"` filtra bien: de 3 `<machine>` en el XML real (1 jugable +
  2 devices), `listar_maquinas_jugables` devuelve solo la jugable.
- **Hallazgo nuevo:** `<description>` trae basura de región/revisión
  pegada de verdad — `"Street Fighter II': Champion Edition (World
  920513)"`, no es un caso hipotético. Decisión (2026-07-29, confirma lo
  que "Fuera de alcance" ya anticipaba): se deja crudo, ver esa sección.

Lo que sí está verificado desde antes (LAB 0.2): el filtro para quedarse
solo con máquinas jugables es
`mame -listxml <set> | grep '<machine name' | grep -v 'runnable="no"'`.

**Sigue sin confirmar:** si Pegasus, en pantalla, acepta `release: 1992`
(solo el año, sin mes/día — el único `release:` que había en los fixtures
antes de esto era `2002-03-06`, fecha completa). Este punto necesita el
gabinete real, no solo el parser — `attract doctor` ya lo acepta sin
quejarse, pero eso no confirma que Pegasus lo muestre bien.

## Criterios de aceptación

- [x] Dado un `<rom.zip>` cuyo `mame -listxml <set>` devuelve **exactamente
      una** máquina jugable, `attract ingest` agrega un bloque `game:`
      nuevo a `metadata.pegasus.txt` con `file:`, `title` (de
      `<description>`), `developer` (de `<manufacturer>`, si está),
      `release` (de `<year>`, si está), `x-set: <set>`. **Confirmado
      contra la salida real de `mame -listxml sf2ce` — ver arriba.**
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
