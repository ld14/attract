# Decisiones de arquitectura (ADRs)

Registro de decisiones técnicas **con las alternativas que se descartaron**.

## Por qué existe

El código dice *qué* hace. El ADR dice *por qué no hace otra cosa*. Sin él, dentro
de seis meses alguien —tú, o Claude— vuelve a proponer justo lo que ya descartaste.

## Reglas

- **Un ADR por decisión.** Numerado, secuencial, un número nunca se reutiliza.
- **Los ADRs no se editan.** Si cambias de opinión, creas uno nuevo y marcas el
  anterior con `superseded-by: NNNN`. Esa inmutabilidad es lo que les da valor:
  un ADR editado es documentación; un ADR superseded es historia.
- **Solo va aquí lo que tuvo alternativas reales.** Si no descartaste nada, es
  una convención: va en `../constitution/`.
- **Al aceptarse**, la conclusión sube a `../constitution/` (y si descarta algo,
  a §Límites duros de `tech-stack.md`). El ADR conserva el *porqué*.
- **Si una decisión se revierte durante la implementación**, es un ADR — no un
  párrafo añadido al `plan.md` de la feature.

## Crear uno

```
/new-adr <título de la decisión>
```

## Índice

| # | Título | Estado | Fecha |
|---|---|---|---|
| [0001](0001-transporte-datos-ricos.md) | Transporte de datos ricos al theme vía data.json externo | accepted | 2026-07-17 |
| [0002](0002-metadata-fuente-o-artefacto.md) | La metadata es artefacto de build, no fuente | accepted | 2026-07-28 |
| [0003](0003-cross-platform.md) | Estrategia cross-platform: git como puente, doctor como frontera | accepted | 2026-07-28 |
| [0004](0004-identidad-set-merged.md) | Identidad de un juego en un set merged | accepted | 2026-07-28 |
| [0005](0005-runtime-mame-vanilla.md) | Runtime de emulación: MAME vanilla | accepted | 2026-07-17 |
| [0006](0006-version-politica-pegasus.md) | Frontend: seguir con Pegasus, versión fijada e idéntica en ambas máquinas | accepted | 2026-07-28 |
| [0007](0007-paginas-revista-imagenes-no-pdf.md) | Páginas de revista: imágenes, nunca PDF embebido | accepted | 2026-07-23 |
| [0008](0008-modelo-datos-revistas.md) | Revistas como entidad de primera clase, referenciadas por los juegos | superseded by 0010 | 2026-07-23 |
| [0009](0009-frontera-produccion-consumo-revistas.md) | Frontera del sistema: ATTRACT consume revistas, no las produce | accepted | 2026-07-23 |
| [0010](0010-contrato-magazine-json-extendido.md) | Contrato de `magazine.json` extendido con evidencia real (supersede 0008) | 🔁 superseded por 0024 | 2026-07-28 |
| [0011](0011-fuente-synopsis-regeneracion-campo.md) | `attract synopsis` escribe desde una fuente persistida, no parchea el artefacto a mano | accepted | 2026-07-28 |
| [0012](0012-mcp-dependencia-opcional-acotada.md) | `attract mcp` usa el SDK oficial `mcp` como dependencia opcional, acotada | accepted | 2026-07-29 |
| [0013](0013-accent-por-juego.md) | El accent de cada juego se declara a mano en su `data.json` | accepted | 2026-07-29 |
| [0014](0014-manual-digitalizado.md) | El manual digitalizado vive en `media/<set>/_manual/`, declarado en `data.json` | accepted | 2026-07-29 |
| [0015](0015-contrato-data-json.md) | Contrato completo de `data.json`, con nombres de campo explícitos | 🔁 superseded por 0020 | 2026-07-29 |
| [0016](0016-canvas-fijo-escalado.md) | El theme se dibuja en un canvas fijo de 1280×720 y se escala entero | 🔁 superseded por 0019 | 2026-07-29 |
| [0017](0017-providers-pegasus.md) | Los providers de Pegasus que no son de ATTRACT se apagan por config, no se filtran en el theme | accepted | 2026-07-29 |
| [0018](0018-launch-ruta-absoluta.md) | El `launch:` usa la ruta absoluta del emulador, resuelta por máquina | accepted | 2026-08-03 |
| [0019](0019-canvas-cover-no-letterbox.md) | El lienzo crece en el eje que sobra en vez de recortar o dejar barras | proposed | 2026-08-09 |
| [0020](0020-cheats-grupos-libres.md) | `cheats` acepta grupos con nombre libre y el estilo lo decide el contenido | proposed | 2026-08-09 |
| [0021](0021-manual-pdf-app-del-sistema.md) | El PDF del manual se entrega al sistema operativo con `Qt.openUrlExternally` | accepted | 2026-08-09 |
| [0022](0022-rasterizar-pdf-a-paginas.md) | `attract rasterize` convierte el PDF del manual a páginas, con PyMuPDF opcional | accepted | 2026-08-09 |
| [0023](0023-manual-multiple-con-pestanas.md) | Un juego puede declarar varios manuales; `manual` pasa de objeto a lista, con pestañas en el visor | accepted | 2026-08-09 |
| [0024](0024-contrato-magazine-json-v2.md) | Contrato de `magazine.json` v2: carpeta global, páginas en `pages/` y `startPage` como número impreso (supersede 0010) | accepted | 2026-08-10 |
| [0025](0025-link-revista-juego-difuso.md) | Linkear revista y juego por coincidencia difusa, proponiendo antes de escribir | accepted | 2026-08-10 |
| [0026](0026-identidad-declarada-sin-mame.md) | Un `game:` puede crearse con identidad declarada a mano, sin `mame -listxml` | accepted | 2026-08-18 |
| [0027](0027-contrato-paquete-import-coindoor.md) | Contrato del paquete que COINDOOR exporta y `attract import` instala | accepted | 2026-08-18 |
| [0028](0028-rollback-transaccional-import.md) | `attract import` revierte todo lo escrito si falla a mitad de camino | proposed | 2026-08-22 |
| [0029](0029-player-nuevo-por-video.md) | Un `MediaPlayer` + `VideoOutput` nuevo por cada archivo de video | proposed | 2026-08-22 |
| [0030](0030-contrato-gallery-data-json.md) | La galería se compone de los assets nativos del juego más las piezas curadas de `_gallery/`, declaradas como `gallery` en `data.json` | proposed | 2026-08-27 |

**30 ADR en total, 26 vigentes** (0008 quedó superseded por 0010, 0016 por
0019, 0015 por 0020 y 0010 por 0024 — no se editan, se reemplazan). El razonamiento original de 0006-0009
está en
[`docs/decisiones/archivadas/2026-07-23.md`](../../docs/decisiones/archivadas/2026-07-23.md), ya
archivado: su contenido vive formalizado acá. 0010 salió de
una verificación de esta misma sesión, no del handoff original — un
`magazine.json` real no coincidía con el contrato inventado en 0008. 0011
salió de especificar la primera feature real (`001-synopsis`,
`spec/features/`): cómo escribe ATTRACT en `metadata.pegasus.txt` por
primera vez sin romper ADR-0002. 0012 salió de especificar M5
(`attract mcp`): acota el límite stdlib-only para una dependencia opcional
en vez de descartarlo o reimplementar el protocolo MCP a mano.

**0013-0017 son el primer bloque de decisiones de *frontend* del proyecto.**
0013-0016 salieron de leer el diseño de referencia
(`design_handoff_game_detail/`) contra lo ya decidido: el handoff daba por
existentes campos que nunca se definieron (`accent`, `x-manual`) y pedía
formas que chocaban con límites duros vigentes. Los cuatro cierran ese hueco
antes de escribir el theme de producción, no durante.

**0017 salió distinto: de correr el esqueleto del theme contra Pegasus real**
(`spec/features/005-theme-base/tasks.md` §1). El panel de diagnóstico reportó
6 juegos donde los metadata declaran 5, y el sexto venía de la librería de
Steam del autor — o sea que `api.allGames` no es la librería de ATTRACT, es
todo lo que Pegasus encontró con todos sus providers. Es el tipo de cosa que
no aparece leyendo documentación, solo abriendo el programa.

**0018 también salió de abrir el programa**, y de un error que no tenía nada
que ver con el theme: `Could not launch 'mame'` estando MAME instalado. Una
app de GUI en macOS no hereda el PATH del shell, y el gabinete arranca Pegasus
solo. La salida no fue un mecanismo nuevo sino usar una decisión que ya estaba
tomada: el metadata es artefacto de build (ADR-0002), así que la ruta absoluta
del emulador puede ser distinta en cada máquina sin romper nada.

**0024-0025 salieron de cargar la primera revista real completa**
(`micromania-34`, 63 páginas). 0010 había deducido la forma de `articles[]` de
un `magazine.json` real, pero su carpeta nunca se montó contra el theme: los
fixtures los escribimos nosotros con el contrato ya en la mano, así que no
podían revelar que las páginas viven en `pages/` ni que `startPage` es el
número impreso y no un índice. Es el mismo patrón que 0017 y 0018 — la
evidencia apareció al abrir el programa con datos que no habíamos fabricado.
0025 salió del problema que la revista real dejó al descubierto en la otra
punta: su slug editorial (`golden-axe`) no coincide con el set de MAME
(`goldnaxe`), y ninguna normalización determinística los une.

**0029 es el caso extremo de ese mismo patrón**: no salió de abrir el programa
sino de *grabarlo*. El fallo era intermitente, silencioso —`status` en
`Buffered`, `position` avanzando, cero warnings— y encima se "arreglaba" solo al
volver a pararse sobre el mismo juego, así que ninguna traza puntual lo
explicaba. Hizo falta dibujar el estado del reproductor **dentro de la pantalla**
y leerlo de una grabación cuadro por cuadro para ver que el `VideoOutput`
arrastraba la geometría del video anterior. La lección que deja no es sobre
video: cuando el instrumento (el log) no llega a disco a tiempo o mide la cosa
equivocada, el theme puede dibujar su propio diagnóstico y `grabToImage` puede
guardarlo en un archivo.
