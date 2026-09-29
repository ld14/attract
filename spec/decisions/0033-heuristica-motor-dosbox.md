---
id: 0033
title: "Aplicar config de DOSBox por motor detectado cuando no hay perfil ni declaración"
status: accepted
date: "2026-09-16"
supersedes: null
superseded-by: null
tags: [backend, data]
---

# 0033 — Heurística de motor para DOSBox

## Contexto

`ADR-0032` deja un juego MS-DOS sin perfil conocido ni `dosbox` declarado en
la base genérica `BASE` (`cpu_cycles: 3000`, sin más criterio), marcado
`provisional`, esperando que alguien lo juegue y ajuste `dosbox.conf` a mano.
El usuario no quiere ese ajuste manual como paso obligado: quiere que la
config de partida sea la mejor posible desde la investigación, aceptando que
"mejor" no significa "verificada jugando".

`ADR-0032` ya había descartado "aplicar una configuración por título o
género" — el piloto de Prehistorik encontró un lanzador de Loom escondido
con el mismo nombre de archivo, y una copia Amiga del mismo título. Reabrir
esa alternativa exige decir qué cambió: acá no se agrupa por **título** ni
por **género** (categorías de producto, no verificables desde los archivos),
sino por **motor técnico**, identificado por la presencia de sus archivos de
datos característicos (`WORDS.TOK`+`OBJECT`+`VOL.*` para Sierra AGI,
`RESOURCE.MAP`+`RESOURCE.0XX` para Sierra SCI) — una señal que si está,
identifica el motor con certeza, sin importar el título o la edición.

## Decisión

Cuando no hay `dosbox` declarado ni perfil conocido por hash, el resolver
busca en el árbol extraído la firma de archivos de un motor catalogado
(`dosbox_motores.py`). Si matchea y hay un único ejecutable DOS sin ambigüedad
en esa misma carpeta, aplica la config investigada para ese motor y marca
`status: motor-detectado` — un escalón de confianza explícitamente **menor**
que `perfil-conocido` (no hay copia verificada, solo motor) pero mayor que
`provisional` (no hay ningún criterio). El campo `sources` del informe queda
igual de trazable que en un perfil por hash.

Solo se catalogan motores cuya firma de archivos sea inequívoca. **SCUMM
(LucasArts) queda explícitamente afuera**: ScummVM mismo necesita extraer
strings de versión del binario para diferenciar variantes porque las
extensiones (`.LFL`, `.000`/`.001`, `.LEC`) se repiten entre engines/versiones
distintas — una firma por archivo sola arriesga falso positivo, y aplicar mal
una config sin que nadie la revise es peor que `provisional`.

## Alternativas consideradas

### Aplicar una config por título o género (la que ADR-0032 ya descartó)

- A favor: cubre cualquier juego con poco código.
- En contra: el título no identifica la copia ni el motor; confunde
  ediciones y programas ajenos, como mostró el hallazgo de Loom dentro de
  Prehistorik.
- **Descartada porque:** el motor sí es una propiedad técnica verificable
  desde los archivos, el título no. Motor ≠ título/género.

### Parsear el binario para identificar el motor con precisión (incluir SCUMM)

- A favor: cubre más juegos, incluida la mitad de la librería actual
  (Monkey Island 1 y 2, Indiana Jones).
- En contra: reimplementar lo que hace ScummVM (extracción de strings de
  versión con fuerza bruta de XOR) es un proyecto en sí mismo, y el proyecto
  es stdlib-only a propósito.
- **Descartada por ahora porque:** el costo no está justificado todavía;
  esos juegos siguen cayendo a `provisional`, que es el comportamiento de
  hoy — no es una regresión, es no-cobertura explícita.

### Consultar VOGONS/PCGamingWiki en vivo durante el import

- **Descartada** por el mismo motivo que en ADR-0032: no reproducible,
  depende de red.

## Consecuencias

**Positivas**

- Un juego AGI/SCI nuevo sin perfil ni declaración llega con una config
  investigada en vez de la base genérica plana, sin que nadie tenga que
  jugarlo ni ajustarlo primero.
- El mecanismo de detección es aditivo: no cambia el orden de prioridad
  existente (declarado > perfil-conocido > esto > provisional > pendiente).

**Coste asumido**

- Los valores de `cpu_cycles: 6000` para AGI/SCI salen de una sola fuente
  comunitaria (un hilo de GOG específico para packs Sierra), no de pruebas
  propias — puede no ser óptimo para todos los títulos de cada familia
  (títulos tardíos de SCI como KQ6/KQ7 documentados con necesidades de
  memoria mayores, que este esquema todavía no soporta declarar).
- SCUMM, la familia más representada en la librería actual, queda sin
  cobertura.

**Qué habría que revisar si esto se replantea**

- Si alguien encuentra o construye una firma de archivo confiable para
  distinguir variantes de SCUMM sin parsear el binario.
- Si `cpu_cycles: 6000` resulta mal para algún título AGI/SCI real: no se
  corrige el catálogo a ciegas, se anota el caso y se decide si el motor
  necesita sub-familias (por año, por VGA vs EGA).

## Referencias

- [Feature 025](../features/025-dosbox-import/spec.md)
- [ADR-0032](0032-perfiles-dosbox-import.md)
- [docs/decisiones/2026-09-16.md](../../docs/decisiones/2026-09-16.md)
- [Tip SCI/AGI en foro de GOG](https://www.gog.com/forum/kings_quest_series/a_tip_for_the_sci_agi_games_in_this_and_other_sierra_packs)
- [DOSBox Staging — CPU](https://www.dosbox-staging.org/0.83/manual/system/cpu/)
