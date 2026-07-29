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

**11 ADR en total, 10 vigentes** (0008 quedó superseded por 0010 — no se
edita, se reemplaza). El razonamiento original de 0006-0009 está en
[`docs/decisiones/2026-07-23.md`](../../docs/decisiones/2026-07-23.md), que
puede archivarse ahora que su contenido vive formalizado acá. 0010 salió de
una verificación de esta misma sesión, no del handoff original — un
`magazine.json` real no coincidía con el contrato inventado en 0008. 0011
salió de especificar la primera feature real (`001-synopsis`,
`spec/features/`): cómo escribe ATTRACT en `metadata.pegasus.txt` por
primera vez sin romper ADR-0002.
