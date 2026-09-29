---
id: 0035
title: "Leer logo, emblema y acento de cada plataforma desde library/<coleccion>/_platform/"
status: accepted
date: 2026-09-22
supersedes: null
superseded-by: null
tags: [frontend, data]
---

# 0035 — Assets de plataforma en `library/<coleccion>/_platform/`

## Contexto

El selector de plataforma (feature 026) muestra por plataforma un logo, una
imagen emblema y un color de acento. Las colecciones de Pegasus no traen nada
de eso: solo nombre y juegos. Logo y emblema son arte con copyright, así que
no pueden ir al repo (`CLAUDE.md`), y cada elemento tiene que ser opcional
porque al principio ninguna plataforma va a tener assets cargados.

## Decisión

Cada plataforma lee sus assets de una subcarpeta `_platform/` **dentro de la
carpeta de su colección**, al lado de `media/` y de `metadata.pegasus.txt`:
`library/msdos/_platform/{logo.png, emblema.png, data.json}`, con `data.json` =
`{ "accent": "#rrggbb", "abrev": "...", "nombre": "..." }`. Todo opcional. La
carpeta de la colección sale de la ruta de sus juegos (`Paths.dirColeccionDe`).

Puede haber **varios emblemas**: `emblema.png` y `emblema_01.png`,
`emblema_02.png`, … hasta `emblema_99.png` (dos dígitos). En cada visita a la plataforma se muestra uno al azar. Como el
theme no puede listar una carpeta, los busca por nombre en ese orden hasta el
primer número que falte: un hueco corta la serie.

## Alternativas consideradas

### Carpeta hermana `library/_platforms/<dir>/`

- A favor: `scripts/reset-pegasus.sh` conserva todo lo que empieza con `_` en
  `library/`, así que los assets sobreviven a una carga desde cero.
- En contra: separa de su colección los datos de una plataforma, y obliga a
  derivar `<dir>` del último segmento de la ruta. La carpeta hermana tampoco
  existe hasta que alguien la crea, y para el autor no era obvio dónde iba.
- **Descartada porque:** el autor prefiere tener todo lo de una plataforma en
  su carpeta (decisión del 2026-09-22), y acepta el costo del reset (abajo).

### Tabla de acentos en `Tokens.qml` y assets en `themes/attract/assets/`

- A favor: sin lecturas de disco; todo junto al theme.
- En contra: el logo y el emblema son arte con copyright y el theme se versiona;
  sumar una plataforma obligaría a editar el theme.
- **Descartada porque:** mete arte con copyright en git y ata datos de la
  librería al código del theme.

### Campos nuevos en la cabecera `collection:` de `metadata.pegasus.txt`

- A favor: Pegasus ya lee ese archivo.
- En contra: nadie verificó que este binario exponga al theme imágenes o campos
  propios de una colección, y el archivo lo regenera ATTRACT (ADR-0002): el dato
  tendría que vivir en otra fuente igual, como la sinopsis (ADR-0011).
- **Descartada porque:** sin un experimento que muestre que el theme puede
  leerlos, es apostar a una API que no se midió; y aun si existiera, haría falta
  una fuente persistida aparte, que es lo que esta decisión ya es.

## Consecuencias

**Positivas**

- Todo lo de una plataforma queda junto: juegos, `media/` y `_platform/`.
- El arte queda fuera de git, como el resto del arte de `library/`.
- El prefijo `_` marca "no es un juego", igual que `_manual/` y `_gallery/`.
- La misma regla sirve para `library/` y `fixtures/`, y para los juegos de DOS
  cuyo `file:` es una carpeta.

**Coste asumido**

- **`make reset-pegasus` manda `_platform/` a la papelera con la colección.** El
  script mueve cada colección entera; los assets se recuperan de la papelera o
  se vuelven a copiar.
- Una lectura de `data.json` por plataforma (con cache), y cargar los assets a mano.
- Buscar los emblemas lee cada PNG una vez por sesión (se cachea la lista), y
  la numeración tiene que ser corrida.
- `docs/CONVENCION.md` tiene que documentar la carpeta (ejercicio del autor).

**Qué habría que revisar si esto se replantea**

- Si perder `_platform/` en un reset molesta en la práctica: ahí conviene que
  `reset-pegasus.sh` la preserve, o volver a la carpeta hermana.
- Si una colección se reparte en varias carpetas de `game_dirs.txt`: los assets
  se leen de la carpeta del primer juego.
- Si Pegasus empieza a exponer assets de colección al theme.

## Referencias

- [Feature 026](../features/026-selector-plataforma/spec.md)
- [ADR-0002](0002-metadata-fuente-o-artefacto.md), [ADR-0011](0011-fuente-synopsis-regeneracion-campo.md), [ADR-0013](0013-accent-por-juego.md)
- `scripts/reset-pegasus.sh`
- `Diseños/design_handoff_platform_select/README.md` §Assets (proponía `library/_platforms/`)
