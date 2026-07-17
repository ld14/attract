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
trampa de la versión de MAME, que puede romper ADR-005 sin avisar.

```bash
make setup       # config de git (precomposeUnicode)
make check-git   # verificá que quedó
make doctor      # el validador contra los fixtures
make test        # 9 tests, cada uno reproduce un bug real
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
| [001](adr/001-transporte-datos-ricos.md) | 🔴 pendiente | Transporte de datos ricos al theme |
| [002](adr/002-metadata-fuente-o-artefacto.md) | 🔴 pendiente | ¿Metadata es fuente o artefacto de build? |
| [003](adr/003-cross-platform.md) | 🔴 pendiente | Estrategia macOS → Windows |
| [004](adr/004-identidad-set-merged.md) | 🔴 pendiente | Identidad en un set merged |
| [005](adr/005-runtime-mame-vanilla.md) | ✅ **aceptada** | **Runtime: MAME vanilla 0.288** |

ADR-005 está escrita y sirve de modelo. Las otras cuatro las escribís en el LAB 0.3.

## Stack

| | |
|---|---|
| Frontend | Pegasus (QML) |
| Runtime | **MAME vanilla 0.288** — mismo binario en Mac y Windows (ADR-005) |
| ROMs | MAME 0.288 **merged** |
| Dev | macOS · Prod | Windows |

## Estructura

```
docs/       SETUP.md ← empezá acá · CONVENCION.md ← el documento central
            baseline · mapeo · mockup
adr/        las decisiones. 005 escrita, 001-004 tuyas
src/        attract doctor (funciona). El resto llega con los módulos
themes/     attract-debug ← el experimento del Bloque 3
fixtures/   ROMs falsas de 0 bytes. Portables, versionables, suficientes
library/    tu librería real. NO va al repo
tests/      9 tests. Cada uno reproduce un bug que pasó de verdad
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
