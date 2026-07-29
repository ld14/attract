# ATTRACT

Fábrica de metadata y assets para un frontend Pegasus de máquina recreativa.

**Estado:** `v0.0` · Módulo 0 del Bootcamp.

## Qué hace ATTRACT

Cae una ROM → ATTRACT arma la estructura de archivos → la pantalla se genera sola,
**con lo que haya**.

No es curación masiva. Es **ingesta incremental con enriquecimiento progresivo**:
un juego entra pelado y la pantalla funciona; seis meses después aparece un scan de
Micromanía, lo dropeás en la carpeta, y la pantalla lo levanta.

**El caso principal es el juego pelado.** De los miles, la enorme mayoría va a vivir
sin scans, sin manual y sin combos, para siempre. Striker es la excepción.

## Arrancar

**Primera vez:** leé [`docs/SETUP.md`](docs/SETUP.md) — arma las dos máquinas y tiene la
trampa de la versión de MAME, que puede romper ADR-0005 sin avisar.

```bash
make setup       # config de git (precomposeUnicode)
make check-git   # verificá que quedó
make doctor      # el validador contra los fixtures
make test        # 49 tests, cada uno reproduce un bug real o un caso del contrato
make theme       # instala el theme de debug en Pegasus
```

## El banco de pruebas

Cinco juegos. Cada uno rompe algo distinto. Más no agrega aprendizaje.

| # | Rol | Juego | Qué rompe |
|---|---|---|---|
| 1 | El completo | **Striker** (Amiga/DOS, 1992) | Nada — es la referencia validada |
| 2 | **El desnudo** | **The Maze of the Kings** (`mok`, NAOMI GD-ROM, 2002) | Todos los campos ricos en null. Y **un juego ≠ un archivo** |
| 3 | El de peleas | **Street Fighter II: CE** (`sf2ce`) | La notación de combos. Y `:` en el título |
| 4 | El ambiguo | **Cadillacs and Dinosaurs** (`dino`) | Título ≠ nombre de ROM |
| 5 | Otra consola + homónimo | **TMNT** (NES, 1989) | Otro DAT · dos juegos distintos, un título |

**Regla:** toda decisión se valida contra el #1 **y** contra el #2.
Si solo funciona con Striker, no funciona.

## Decisiones

| ADR | Estado | Decisión |
|---|---|---|
| [0001](spec/decisions/0001-transporte-datos-ricos.md) | ✅ **aceptada** | Transporte de datos ricos al theme |
| [0002](spec/decisions/0002-metadata-fuente-o-artefacto.md) | ✅ **aceptada** | Metadata es artefacto de build, no fuente |
| [0003](spec/decisions/0003-cross-platform.md) | ✅ **aceptada** | Estrategia macOS → Windows |
| [0004](spec/decisions/0004-identidad-set-merged.md) | ✅ **aceptada** | Identidad en un set merged |
| [0005](spec/decisions/0005-runtime-mame-vanilla.md) | ✅ **aceptada** | **Runtime: MAME vanilla 0.288** |
| [0006](spec/decisions/0006-version-politica-pegasus.md) | ✅ **aceptada** | Frontend: Pegasus, versión fijada |
| [0007](spec/decisions/0007-paginas-revista-imagenes-no-pdf.md) | ✅ **aceptada** | Páginas de revista: imágenes, no PDF |
| [0008](spec/decisions/0008-modelo-datos-revistas.md) | 🔁 superseded por 0010 | Revistas como entidad de primera clase |
| [0009](spec/decisions/0009-frontera-produccion-consumo-revistas.md) | ✅ **aceptada** | Frontera: ATTRACT consume revistas, no las produce |
| [0010](spec/decisions/0010-contrato-magazine-json-extendido.md) | ✅ **aceptada** | Contrato `magazine.json` extendido con evidencia real |
| [0011](spec/decisions/0011-fuente-synopsis-regeneracion-campo.md) | ✅ **aceptada** | `attract synopsis` escribe desde una fuente, merge de un solo campo |
| [0012](spec/decisions/0012-mcp-dependencia-opcional-acotada.md) | ✅ **aceptada** | `attract mcp` usa el SDK `mcp` como dependencia opcional, acotada |

**12 ADR, 11 vigentes.** 0010 salió de verificar la 0008 contra un
`magazine.json` real, que traía más campos de los que se habían inventado
para el fixture. 0011 salió de especificar la primera feature real
(`attract synopsis`, `spec/features/001-synopsis/`) y decidir cómo escribe
`metadata.pegasus.txt` sin romper ADR-0002. 0012 salió de especificar
`attract mcp` (M5) y decidir cómo convive un SDK externo con el límite
stdlib-only. Ver [`spec/decisions/README.md`](spec/decisions/README.md).

## Stack

| | |
|---|---|
| Frontend | Pegasus (QML) |
| Runtime | **MAME vanilla 0.288** — mismo binario en Mac y Windows (ADR-0005) |
| ROMs | MAME 0.288 **merged** |
| Dev | macOS · Prod | Windows |
| Dependencias | stdlib-only, excepción única: `mcp` (opcional, solo para `attract mcp`, ADR-0012) |

## Estructura

```
docs/       SETUP.md ← empezá acá · CONVENCION.md ← el documento central
            baseline · mapeo · mockup · decisiones/ ← handoffs de sesión
spec/       constitution (misión, stack, roadmap) + decisions (12 ADR, 11
            vigentes) + features (001 a 004, las 4 implementadas)
src/        attract doctor + synopsis + mcp + ingest (los 4 módulos planeados en cli.py)
.claude/    skills/attract/ ← le dice a un agente cuándo correr doctor/synopsis
themes/     attract-debug ← el harness del Bloque 3 · experimentos/ ← pruebas cerradas
fixtures/   ROMs falsas de 0 bytes + una revista de mentira. Portables, suficientes
library/    tu librería real. NO va al repo
tests/      49 tests. Cada uno reproduce un bug real o un caso del contrato
```

## Lo que ya aprendimos a los golpes

- **Un byte inválido no rompe una línea: rompe el archivo entero.** La detección de
  encoding es todo-o-nada. Un `0x93` suelto y Pegasus te lee la colección en mojibake.
- **macOS no te avisa.** NFD, `:` en nombres, `._*` — nada de eso falla en el Mac.
  Explota en el gabinete. Por eso existe `attract doctor`.
- **git te cubre los nombres, no el contenido.** `core.precomposeUnicode` normaliza
  los nombres de archivo. La ruta escrita *dentro* del metadata es texto: la normalizás vos.
- **La documentación miente a veces. El binario, no.** La API de Pegasus dice que
  `game.extra.X` es un string; el parser en C++ guarda un `QStringList`. Averigualo.
- **Una fuente oficial también miente.** El anuncio de MAMEdev sobre migrar a Rust es
  una broma de April Fools. Casi tomamos una decisión correcta por una razón falsa.

## Licencia
Privado.
