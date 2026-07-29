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
| [0010](0010-contrato-magazine-json-extendido.md) | Contrato de `magazine.json` extendido con evidencia real (supersede 0008) | accepted | 2026-07-28 |
| [0011](0011-fuente-synopsis-regeneracion-campo.md) | `attract synopsis` escribe desde una fuente persistida, no parchea el artefacto a mano | accepted | 2026-07-28 |
| [0012](0012-mcp-dependencia-opcional-acotada.md) | `attract mcp` usa el SDK oficial `mcp` como dependencia opcional, acotada | accepted | 2026-07-29 |
| [0013](0013-accent-por-juego.md) | El accent de cada juego se declara a mano en su `data.json` | accepted | 2026-07-29 |
| [0014](0014-manual-digitalizado.md) | El manual digitalizado vive en `media/<set>/_manual/`, declarado en `data.json` | accepted | 2026-07-29 |
| [0015](0015-contrato-data-json.md) | Contrato completo de `data.json`, con nombres de campo explícitos | accepted | 2026-07-29 |
| [0016](0016-canvas-fijo-escalado.md) | El theme se dibuja en un canvas fijo de 1280×720 y se escala entero | accepted | 2026-07-29 |
| [0017](0017-providers-pegasus.md) | Los providers de Pegasus que no son de ATTRACT se apagan por config, no se filtran en el theme | accepted | 2026-07-29 |

**17 ADR en total, 16 vigentes** (0008 quedó superseded por 0010 — no se
edita, se reemplaza). El razonamiento original de 0006-0009 está en
[`docs/decisiones/2026-07-23.md`](../../docs/decisiones/2026-07-23.md), que
puede archivarse ahora que su contenido vive formalizado acá. 0010 salió de
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
