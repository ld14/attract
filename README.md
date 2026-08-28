# ATTRACT

Fábrica de metadata y assets para un frontend Pegasus de máquina recreativa.

**Estado:** el CLI y el theme de producción están escritos y corriendo contra
Pegasus real. 30 ADR, 18 features, 206 tests. Nació como Módulo 0 de un
bootcamp y se quedó como el software que carga la máquina.

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

**Para cargar un juego** (ROM, imágenes, video, revista): leé
[`docs/guides/cargar-un-juego-nuevo.md`](docs/guides/cargar-un-juego-nuevo.md) —
el manual del día a día, distinto de `SETUP.md` que es instalación de máquina.

```bash
make setup       # config de git (precomposeUnicode)
make check-git   # verificá que quedó
make doctor      # el validador contra los fixtures
make test        # 206 tests, cada uno reproduce un bug real o un caso del contrato
make theme       # instala el theme de producción en Pegasus (make theme-debug para el harness)
```

## El CLI

Un solo comando, `attract`, con siete subcomandos. Todos operan sobre una
librería en disco; ninguno pide red.

| Subcomando | Qué hace | ADR |
|---|---|---|
| `attract doctor <ruta>` | Valida la librería. Todo lo que Windows rechazaría falla acá, en el Mac | [`0003`](spec/decisions/0003-cross-platform.md) |
| `attract ingest <rom.zip>` | Crea un `game:` nuevo, con la identidad que da `mame -listxml` | [`0004`](spec/decisions/0004-identidad-set-merged.md) |
| `attract synopsis <set>` | Escribe el `summary:` desde `_synopsis/<set>.json`, sin tocar el resto del bloque | [`0011`](spec/decisions/0011-fuente-synopsis-regeneracion-campo.md) |
| `attract import <paquete.zip>` | Instala un paquete COINDOOR entero. Si falla a mitad de camino, revierte | [`0027`](spec/decisions/0027-contrato-paquete-import-coindoor.md) · [`0028`](spec/decisions/0028-rollback-transaccional-import.md) |
| `attract rasterize <set>` | Convierte el PDF del manual de ese juego a páginas `p001.jpg…` | [`0022`](spec/decisions/0022-rasterizar-pdf-a-paginas.md) |
| `attract mags <ruta>` | Linkea revistas con juegos por coincidencia difusa. Dry-run por defecto | [`0025`](spec/decisions/0025-link-revista-juego-difuso.md) |
| `attract mcp` | Sirve `doctor` y `synopsis` como tools MCP por stdio | [`0012`](spec/decisions/0012-mcp-dependencia-opcional-acotada.md) |

**`doctor` es la frontera.** El Mac deja pasar NFD, `:` en nombres y basura
`._*`; el gabinete no. Todo chequeo cross-platform vive ahí, nunca en un
script aparte.

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
| [0010](spec/decisions/0010-contrato-magazine-json-extendido.md) | 🔁 superseded por 0024 | Contrato `magazine.json` extendido con evidencia real |
| [0011](spec/decisions/0011-fuente-synopsis-regeneracion-campo.md) | ✅ **aceptada** | `attract synopsis` escribe desde una fuente, merge de un solo campo |
| [0012](spec/decisions/0012-mcp-dependencia-opcional-acotada.md) | ✅ **aceptada** | `attract mcp` usa el SDK `mcp` como dependencia opcional, acotada |
| [0013](spec/decisions/0013-accent-por-juego.md) | ✅ **aceptada** | El accent de cada juego se declara a mano en su `data.json` |
| [0014](spec/decisions/0014-manual-digitalizado.md) | ✅ **aceptada** | Manual digitalizado en `media/<set>/_manual/`, declarado en `data.json` |
| [0015](spec/decisions/0015-contrato-data-json.md) | 🔁 superseded por 0020 | Contrato completo de `data.json`, con nombres de campo explícitos |
| [0016](spec/decisions/0016-canvas-fijo-escalado.md) | 🔁 superseded por 0019 | El theme se dibuja en un canvas fijo de 1280×720 y se escala entero |
| [0017](spec/decisions/0017-providers-pegasus.md) | ✅ **aceptada** | Los providers de Pegasus que no son de ATTRACT se apagan por config |
| [0018](spec/decisions/0018-launch-ruta-absoluta.md) | ✅ **aceptada** | `launch:` usa la ruta absoluta del emulador, resuelta por máquina |
| [0019](spec/decisions/0019-canvas-cover-no-letterbox.md) | 🧪 propuesta | El lienzo crece en el eje que sobra, sin recortar ni dejar barras (supersede 0016) |
| [0020](spec/decisions/0020-cheats-grupos-libres.md) | 🧪 propuesta | `cheats` acepta grupos con nombre libre (supersede 0015) |
| [0021](spec/decisions/0021-manual-pdf-app-del-sistema.md) | ✅ **aceptada** | El PDF del manual se entrega al SO con `Qt.openUrlExternally` |
| [0022](spec/decisions/0022-rasterizar-pdf-a-paginas.md) | ✅ **aceptada** | `attract rasterize` convierte el PDF a páginas, con `pymupdf` opcional |
| [0023](spec/decisions/0023-manual-multiple-con-pestanas.md) | ✅ **aceptada** | `manual` pasa de objeto a lista, con pestañas en el visor |
| [0024](spec/decisions/0024-contrato-magazine-json-v2.md) | ✅ **aceptada** | `magazine.json` v2: carpeta global, `pages/`, `startPage` impreso (supersede 0010) |
| [0025](spec/decisions/0025-link-revista-juego-difuso.md) | ✅ **aceptada** | Linkear revista y juego por coincidencia difusa, proponiendo antes de escribir |
| [0026](spec/decisions/0026-identidad-declarada-sin-mame.md) | ✅ **aceptada** | Un `game:` puede crearse con identidad declarada a mano, sin `mame -listxml` |
| [0027](spec/decisions/0027-contrato-paquete-import-coindoor.md) | ✅ **aceptada** | Contrato del paquete que COINDOOR exporta y `attract import` instala |
| [0028](spec/decisions/0028-rollback-transaccional-import.md) | 🧪 propuesta | `attract import` revierte todo lo escrito si falla a mitad de camino |
| [0029](spec/decisions/0029-player-nuevo-por-video.md) | 🧪 propuesta | Un `MediaPlayer` + `VideoOutput` nuevo por cada archivo de video |
| [0030](spec/decisions/0030-contrato-gallery-data-json.md) | 🧪 propuesta | La galería son los assets nativos + las piezas de `_gallery/` declaradas en `gallery` |

**30 ADR, 26 vigentes.** 0010 salió de verificar la 0008 contra un
`magazine.json` real, que traía más campos de los que se habían inventado
para el fixture. 0011 salió de especificar la primera feature real
(`attract synopsis`, `spec/features/001-synopsis/`) y decidir cómo escribe
`metadata.pegasus.txt` sin romper ADR-0002. 0012 salió de especificar
`attract mcp` (M5) y decidir cómo convive un SDK externo con el límite
stdlib-only. 0013-0018 salieron de diseñar y construir el theme de
producción (`005-theme-base`, `006-theme-documentos`, `007-theme-trucos`,
`008-theme-ayuda`, `009-theme-estantes`) contra el handoff de diseño real.

**0021-0025 salieron de cargar material real**: el primer manual en PDF y la
primera revista completa (`micromania-34`, 63 páginas) rompieron contratos que
solo se habían verificado contra fixtures escritos por nosotros. **0026-0028**
salieron de `attract import` y del paquete que COINDOOR exporta. **0029-0030**
salieron del theme: un `VideoOutput` que arrastraba la geometría del video
anterior, y la galería de piezas multimedia. Ver
[`spec/decisions/README.md`](spec/decisions/README.md).

## Stack

| | |
|---|---|
| Frontend | Pegasus (QML) |
| Runtime | **MAME vanilla 0.288** — mismo binario en Mac y Windows (ADR-0005) |
| ROMs | MAME 0.288 **merged** |
| Dev | macOS · Prod | Windows |
| Dependencias | stdlib-only, **dos** excepciones opcionales y acotadas: `mcp` (solo `attract mcp`, ADR-0012) y `pymupdf` (solo `attract rasterize`, ADR-0022) |

## Estructura

```
docs/       SETUP.md ← empezá acá · CONVENCION.md ← el documento central
            guides/cargar-un-juego-nuevo.md ← manual del día a día
            baseline · mapeo · mockup · plataforma-pegasus.md · decisiones/ ← handoffs de sesión
spec/       constitution (misión, stack, roadmap) + decisions (30 ADR, 26
            vigentes) + features (001 a 018, theme de producción incluido)
src/        attract doctor + synopsis + mcp + ingest + import + rasterize + mags
.claude/    skills/attract/ ← le dice a un agente cuándo correr doctor/synopsis
themes/     attract ← theme de producción (005-009, 017-018) · attract-debug ← harness del Bloque 3 · experimentos/ ← pruebas cerradas
fixtures/   ROMs falsas de 0 bytes + revistas, manuales y galería de mentira. Portables, suficientes
library/    tu librería real. NO va al repo
tests/      206 tests. Cada uno reproduce un bug real o un caso del contrato
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
- **Cuando el log no alcanza, que la pantalla se dibuje su propio diagnóstico.**
  Un panel de video quedaba vacío de a ratos: `status` en `Buffered`, `position`
  avanzando, cero warnings, y se "arreglaba" solo al volver al mismo juego. No lo
  explicó ninguna traza — lo explicó pintar el estado del reproductor **adentro**
  de la pantalla y leerlo de una grabación, cuadro por cuadro
  ([`ADR-0029`](spec/decisions/0029-player-nuevo-por-video.md)).

## Licencia
Privado.
