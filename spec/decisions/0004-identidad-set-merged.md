---
id: 0004
title: "Identidad de un juego en un set merged: una página, múltiples versiones lanzables"
status: accepted
date: "2026-07-28"
supersedes: null
superseded-by: null
tags: [data, backend]
---

# 0004 — Identidad de un juego en un set merged

## Contexto

El set es **MAME 0.288 merged**: el parent y todos sus clones pueden vivir en
el mismo zip. Un `.zip` **no es necesariamente un juego: puede ser una
familia** (parent + revisiones regionales + revisiones de versión).

Y el problema es simétrico:

```
sf2ce.zip  ->  1 archivo, potencialmente N juegos  (merged puede colapsar la familia)
mok.zip    ->  3 archivos, 1 juego                  (zip 1.15KB + CHD 132MB + BIOS naomigd)
```

Pegasus asume **un archivo = una cosa lanzable**. Merged rompe la asunción por
los dos extremos. Y `media/<archivo-sin-extensión>/` agrupa los assets por
familia: una carátula para todos los clones (ver `docs/CONVENCION.md` §1.3).

Probablemente la decisión más consecuente de M0: de esta depende cómo se
nombra todo.

**Verificación hecha en el LAB 0.2, importante para el contexto:** contra la
librería real del autor, `sf2ce.zip` resultó ser **1 solo juego jugable, sin
clones embebidos** (`mame -listxml sf2ce | grep '<machine name' | grep -v
'runnable="no"'` devuelve una sola línea). El caso "N juegos en 1 archivo" no
está confirmado con evidencia propia todavía — es un caso hipotético de un
merged set completo (family pack), no algo que el banco de pruebas actual
demuestre. La decisión de todos modos se diseña para soportarlo, porque puede
aparecer el día que se baje un pack más completo.

## Decisión

**Una sola página de información por familia de juego, con las versiones/
regiones/revisiones disponibles como opciones de lanzamiento dentro de esa
misma página** — no una entrada separada por cada clon.

Mecanismo: un solo bloque `game:` con **múltiples líneas `file:`**, una por
cada variante disponible (ej. USA, Japón, revisión B). Pegasus soporta
múltiples `file:` bajo un mismo `game:` — es el mecanismo pensado para
juegos multi-disco. La identidad del juego (carpeta `media/<juego>/`, todos
los datos ricos: sinopsis, cover, video, reseña) es **una sola**, la de la
familia; las variantes lanzables no duplican esa información.

La identidad de carpeta sigue la regla ya fijada en `docs/CONVENCION.md`
§1.2: el nombre del **set parent** que reporta `mame -listxml` (o, si no hay
distinción clara de parent, el set que se usa como referencia principal).

## Alternativas consideradas

### A · Solo parents

- A favor: simple — una entrada, ningún mecanismo especial de selección.
- En contra: pierde por completo la posibilidad de lanzar el clon específico.
  SF2 CE está en el banco de pruebas *justamente* porque es el clon que
  rompe la notación de combos — si solo se muestra el parent, ese caso de
  prueba deja de existir.
- **Descartada porque:** el objetivo no es ocultar los clones, es evitar
  duplicar la ficha de información mientras se sigue pudiendo lanzar
  cualquier variante.

### B · Un `game:` por set, apuntando al mismo zip

- A favor: cada clon visible individualmente, con su propio nombre en el
  menú.
- En contra: exactamente el problema que motivó esta decisión — duplica toda
  la información rica (sinopsis, reseña, cover, video) en cada entrada,
  aunque el contenido real (la nota de revista, el puntaje) sea sobre el
  mismo juego con solo el puerto/región cambiada.
- **Descartada porque:** genera la duplicación de datos que se quiere evitar.

### C · El zip deja de ser el `file:`

- A favor: desacopla la identidad de un archivo físico concreto, máxima
  flexibilidad.
- En contra: la opción más compleja de implementar — requeriría lógica
  propia para resolver qué archivo(s) corresponden a un juego, en vez de
  apoyarse en algo nativo de Pegasus.
- **Descartada porque:** el mecanismo nativo de múltiples `file:` bajo un
  mismo `game:` (opción elegida) ya resuelve el problema sin necesitar
  romper la relación `file:` → archivo real.

## Consecuencias

**Positivas**

- Cero duplicación de datos ricos entre variantes del mismo juego — una
  sinopsis, una reseña, un cover, aunque haya 3 regiones distintas.
- El banco de pruebas se sigue cumpliendo: SF2 CE es lanzable como variante
  específica, no se pierde como caso de prueba.
- Escala bien al caso hipotético de un merged set completo con muchos
  clones: agregar una región nueva es agregar una línea `file:`, no una
  ficha entera.

**Coste asumido**

- ~~Depende de que Pegasus realmente ofrezca un selector al lanzar un juego
  con múltiples `file:`~~ — **confirmado 2026-07-28**, sí lo ofrece (ver
  Verificaciones pendientes). Riesgo cerrado.
- ~~La identidad de carpeta queda atada al set parent — si algún día se
  necesita mostrar un badge por variante, no está resuelto acá~~ —
  **resuelto 2026-07-28**, ver Verificaciones pendientes.

**Qué habría que revisar si esto se replantea**

- Si se confirma que Pegasus NO permite elegir entre `file:` múltiples (los
  trata como discos secuenciales de una sola partida), esta decisión queda
  invalidada y hay que volver a la opción B o C.
- Si aparece un caso real (no hipotético) de un archivo con múltiples juegos
  jugables de verdad (a diferencia de `sf2ce.zip`, que resultó ser uno solo),
  usarlo para confirmar que el mecanismo elegido cubre ese caso en la
  práctica, no solo en el papel.

## Verificaciones pendientes

- [x] **Confirmado 2026-07-28** — contra Pegasus real, un `game:` con dos
      `file:` (fixture `TEST MULTIFILE`, `multifile-a.zip` / `multifile-b.zip`
      en `fixtures/arcade/metadata.pegasus.txt`) muestra un selector al
      lanzar, preguntando cuál de los dos archivos abrir. Confirma la opción
      elegida: Pegasus sí ofrece "elegí una versión", no las trata como
      discos secuenciales de una misma partida. El costo asumido de la
      sección anterior queda resuelto a favor.
- [ ] Conseguir o simular un archivo con más de un juego jugable de verdad
      (el banco actual no tiene ninguno) para probar el caso real, no solo
      el hipotético.
- [x] **Resuelto 2026-07-28** — no se agrega ningún dato nuevo por variante
      por ahora. Dos motivos: (1) el selector que aparece al lanzar es UI
      **nativa de Pegasus** (confirmado en la verificación de arriba), no
      del theme — ATTRACT no puede inyectarle un badge custom aunque
      quisiera, ya diferencia cada `file:` por su nombre de archivo, que
      alcanza para elegir sin ambigüedad; (2) no hay ningún caso real en el
      banco de pruebas que lo necesite todavía — `sf2ce`, el único con
      potencial de variantes, resultó ser un solo juego jugable (LAB 0.2).
      Si en el futuro hace falta mostrar variantes en la **ficha** (la
      página única de familia, no el selector — ej. "disponible en: USA,
      Japón"), la opción es un campo `x-variantes:` a nivel de `game:`
      (una lista compartida, no un dato por archivo) — no rompe "una sola
      ficha por familia" porque sigue siendo un solo valor por bloque, no
      uno por `file:`. No se implementa ahora por falta de caso real.

## Referencias

- `docs/CONVENCION.md` §1.2 (regla de nombrado de carpeta) y §1.3 (assets
  agrupados por familia con merged).
- Verificación del LAB 0.2: `docs/mapeo-mockup-pegasus.md` §`file: con
  merged` — resultado real contra la librería del autor.
- Modelo de formato a imitar: [`0005-runtime-mame-vanilla.md`](0005-runtime-mame-vanilla.md).
