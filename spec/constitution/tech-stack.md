# Tech stack y convenciones

## Tecnologías

| Capa | Tecnología | Versión | ADR |
|---|---|---|---|
| Lenguaje / runtime | Python, stdlib puro (sin dependencias) | ≥ 3.10 | — |
| Frontend del gabinete | Pegasus Frontend (theme en QML) | — | [`0006`](../decisions/0006-version-politica-pegasus.md) |
| Emulador / fuente de identidad | MAME vanilla | 0.288+ (Mac y Windows deben coincidir) | [`0005`](../decisions/0005-runtime-mame-vanilla.md) |
| ROMs | MAME merged set | 0.288 | [`0004`](../decisions/0004-identidad-set-merged.md) |
| Tests | pytest | — | — |
| Lint / format | <PENDIENTE: no hay configurado. ¿Se agrega?> | — | — |

## Archivos / módulos clave

| Ruta | Responsabilidad |
|---|---|
| `src/attract/cli.py` | Entry point. Dispatch de subcomandos: `doctor`, `synopsis`, `mcp`, `ingest`, `import`, `rasterize`, `mags` |
| `src/attract/doctor.py` | Validador preflight: todo lo que Windows rechazaría debe fallar en el Mac |
| `src/attract/synopsis.py` | Primer módulo que **escribe** `metadata.pegasus.txt` — merge quirúrgico del campo `summary:` desde `_synopsis/<set>.json` (ADR-0011) |
| `src/attract/mcp_server.py` | Servidor MCP (M5) — tools `attract_doctor`/`attract_synopsis`. Una de las dos dependencias externas del proyecto, opcional e import perezoso (ADR-0012) |
| `src/attract/ingest.py` | Primer módulo que **crea** un `game:` nuevo (M7) — identidad vía `mame -listxml` (stdlib `xml.etree.ElementTree`) |
| `src/attract/instalar.py` | Importa paquetes COINDOOR (ADR-0027) — valida en staging con `doctor.py`, instala assets/data/bloque en la librería. Revierte todo lo escrito si falla a mitad de camino (ADR-0028) |
| `src/attract/rasterize.py` | Convierte el PDF del manual a páginas `p001.jpg…` (ADR-0022). Segunda y última dependencia externa: `pymupdf`, opcional e import perezoso |
| `src/attract/magazines.py` | `attract mags` — linkea revistas con juegos por coincidencia difusa (`difflib`, umbral 0.85) y escribe `mags[]`. Dry-run por defecto (ADR-0025) |
| `tests/test_doctor.py` | 79 tests, cada uno reproduce un bug real ya visto o un caso del contrato |
| `tests/test_synopsis.py` | 14 tests: merge de campo, idempotencia, casos límite/fallo |
| `tests/test_mcp_server.py` | 9 tests: aislamiento sin `mcp` instalado, lógica de las tools, registro contra el SDK real (se saltea si `mcp` no está) |
| `tests/test_ingest.py` | 14 tests: 10 contra XML sintético, 1 contra la ausencia real del binario (PATH vacío) y 3 de integración contra el `mame` instalado (se saltean si no hay) |
| `tests/test_instalar.py` | 19 tests: caso feliz (set nuevo/existente), paquete mínimo, path traversal, campos faltantes, data.json inválido, reimportación idempotente, preservación de mags, sistema inexistente, rollback transaccional |
| `tests/test_rasterize.py` | 41 tests: contrato de páginas, PDF ausente/corrupto, aislamiento sin `pymupdf` instalado |
| `tests/test_magazines.py` | 30 tests: umbral de coincidencia difusa, dry-run vs. `--apply`, merge idempotente sobre `mags[]` |
| `fixtures/` | ROMs falsas de 0 bytes + `metadata.pegasus.txt` de ejemplo, para validar el doctor sin la librería real |
| `library/` | Librería real del autor (ROMs, CHDs, assets). Nunca se commitea |
| `themes/attract/` | Theme de producción (features 005-009, 017-018). Tres capas según quién sabe de qué: `core/` datos y rutas, `ui/` dibuja, `screens/`+`overlays/` componen. Un solo singleton (`Theme`, el archivo es `Tokens.qml` — ver su encabezado) |
| `themes/attract-debug/` | Theme QML de debug: harness del Bloque 3, dumpea `game.extra`. Es la evidencia viva de ADR-0001 — no se pisa |
| `themes/experimentos/` | Pruebas de una sola pregunta, archivadas con su resultado. No las instala `make theme` |
| `docs/plataforma-pegasus.md` | Hechos verificados de Pegasus/Qt, consolidados con puntero a su evidencia. No duplica los ADR: ahí van decisiones, acá qué hace la plataforma |
| `spec/decisions/` | Decisiones de arquitectura. 0001-0030, 26 vigentes (0008 superseded por 0010, 0016 por 0019, 0015 por 0020, 0010 por 0024) |
| `spec/features/001-synopsis/` | Primera feature con spec/plan/tasks — `attract synopsis`, implementada |
| `spec/features/002-attract-skill/` | `.claude/skills/attract/SKILL.md`, implementada |
| `spec/features/003-attract-mcp/` | Servidor MCP, implementada |
| `spec/features/004-attract-ingest/` | `attract ingest`, implementada y verificada contra `mame` real |
| `spec/features/005-theme-base/` | Theme de producción: librería y detalle. Implementada y verificada |
| `spec/features/006-theme-documentos/` | Video, carrusel de revistas y visor paginado. Implementada y verificada |
| `spec/features/007-theme-trucos/` | Tokenizer de inputs (`core/InputTokens.js`) y overlay de trucos. Implementada |
| `spec/features/008-theme-ayuda/` | Overlay "Cómo cargar un juego nuevo". Implementada |
| `spec/features/009-theme-estantes/` | Librería con estantes, orden y filtro. Implementada |
| `spec/features/012-manual-pdf/` a `014-manual-multiple/` | Manual: PDF al SO (ADR-0021), `attract rasterize` (ADR-0022), varios manuales con pestañas (ADR-0023). Implementadas |
| `spec/features/015-carga-guiada/` | Carga guiada de un juego. **Especificada, sin código** — la única sin implementar |
| `spec/features/016-import-coindoor/` | `attract import`. Implementada |
| `spec/features/017-hero-video-preview/` | Preview de gameplay en el hero de Home. Implementada, falta la verificación visual |
| `spec/features/018-theme-galeria/` | Galería de piezas multimedia a pantalla completa (ADR-0030). Implementada, falta la verificación visual |

## Comandos

| Acción | Comando |
|---|---|
| Instalar | `make setup` (venv + `pip install pytest`) |
| Tests | `make test` |
| Doctor (fixtures) | `make doctor` |
| Doctor (librería real) | `make doctor-lib` |
| Instalar theme | `make theme` (producción) / `make theme-debug` (harness) |
| Linkear revistas ↔ juegos | `attract mags library` (dry-run) / `--apply` |
| Instalar paquete COINDOOR | `attract import <paquete.zip> [ruta]` |
| Vaciar Pegasus | `make reset-pegasus` (destructivo) / `DRY=1 bash scripts/reset-pegasus.sh` |
| Lint | <PENDIENTE: no configurado> |

## Modelo de datos / dominio

Formato nativo de Pegasus: `metadata.pegasus.txt` (texto plano, `campo: valor`,
UTF-8/NFC/LF obligatorio — ver §Límites duros). Estructura real, verificada en
`fixtures/arcade/metadata.pegasus.txt` y ADR-0001:

```
metadata.pegasus.txt
├── collection: <nombre>        # una colección por archivo (ej. "Arcade")
├── shortname / launch:         # cómo se invoca el emulador
└── game: <título>              # un bloque por juego (o por familia, ver merged)
    ├── file: <rom.zip>
    ├── developer / publisher / genre / players / release / summary
    ├── assets.<nombre>: <ruta> # auto-descubierto por Pegasus en media/<archivo-sin-ext>/
    └── x-<campo>: <valor>      # custom field → llega al theme como game.extra.<campo>,
                                 # SIEMPRE una lista (QStringList), nunca un string
                                 # (ver ADR-0001, "Resultado del experimento Bloque 3")
```

Datos ricos que **no** viven en `metadata.pegasus.txt` (ADR-0001):

```
<raíz-librería>/
├─ _magazines/<rev>-<n>/    # la revista, UNA sola vez, FUERA de todo sistema
│  ├─ magazine.json         # name, issue?, year?, color?, cover, key_id, pages[], articles[]
│  ├─ cover.jpg             # la tapa, en la raíz de la revista
│  └─ pages/                # las páginas van acá (ADR-0024)
│     └─ p001.jpg … pNNN.jpg
└─ <sistema>/               # arcade/, nes/, pc/ …
   ├─ metadata.pegasus.txt
   └─ media/<set>/
      ├─ boxFront.jpg …     # assets nativos, auto-descubiertos por Pegasus
      ├─ data.json          # accent, cheats, review, manual: [{label?,pages?,file?}],
      │                     # mags: [{ref: "<rev>-<n>"}], gallery: [{file,type,label?}]
      ├─ _manual/           # páginas del/los manual(es), PLANO (no lleva pages/)
      │  └─ p001.jpg … pNNN.jpg
      └─ _gallery/          # piezas curadas de la galería (ADR-0030), declaradas en `gallery`
         └─ g001.png · clip.mp4 …
```

Contrato completo de `data.json` en
[`ADR-0015`](../decisions/0015-contrato-data-json.md) (accepted): todos los
campos opcionales, nombres completos (`{name, input}`, no `{n, i}`),
`review.cats` como objeto de seis claves fijas para poder expresar reseñas
parciales.

El juego **referencia** la revista, no la contiene: una revista cubre varios
juegos —y de **varios sistemas**, por eso `_magazines/` cuelga de la raíz de la
librería y no del árbol de ninguno— y duplicar el escaneo en cada uno es el
error que esto evita. Qué páginas son la nota de cada juego vive en
`magazine.json → articles[]`, buscando por `game == "<set>"`. Una sola fuente de
verdad ([`ADR-0024`](../decisions/0024-contrato-magazine-json-v2.md), accepted —
supersede a [`ADR-0010`](../decisions/0010-contrato-magazine-json-extendido.md),
que a su vez superseded a [`ADR-0008`](../decisions/0008-modelo-datos-revistas.md)).

`articles[].game` es un **slug editorial** del generador (`golden-axe`), no el
set de MAME (`goldnaxe`). `attract mags` los une por coincidencia difusa y
escribe el `mags[]` de cada juego
([`ADR-0025`](../decisions/0025-link-revista-juego-difuso.md), accepted).

`startPage` y `articles[].pages` son **números de página impresa**, que se
resuelven buscando `p{NNN}` dentro de `pages[]` — no son índices sobre el array:
una revista real arranca en `p002.jpg` porque la página 1 es la tapa.

Con un set **merged**, un `.zip` puede ser una familia de máquinas (parents +
clones), no un juego — identidad real la da `mame -listxml`, no el filesystem
([`ADR-0004`](../decisions/0004-identidad-set-merged.md), accepted: una sola
página de información por familia, variantes como `file:` múltiples).

## Convenciones

- Comentarios y mensajes de commit en español, informal, sin tildes en el código
  (`no`, `codigo`) pero SÍ con tildes en markdown/docs.
- Tests en `tests/`, un archivo por módulo (`test_doctor.py` ↔ `doctor.py`),
  nombrados por el bug que reproducen, no por la función que cubren.
- Todo chequeo cross-Mac/Windows nuevo se agrega a `CHEQUEOS_UNIVERSALES` en
  `doctor.py`, no como script aparte.
- `.gitattributes` fuerza LF en texto y `binary` en assets — no tocar sin razón.
- Convención formal de campos/estructura de carpetas: escrita en
  `docs/CONVENCION.md` (§1 estructura, §2 campos, §3 procedencia, §4 validación).
  Es un ejercicio del bootcamp: se amplía cuando aparece un campo nuevo, no se
  reescribe.

## Límites duros

- **Sin dependencias externas** en `src/attract/` — es deliberado (`doctor`
  corre con cualquier Python ≥3.10, sin instalar nada). **Hay exactamente DOS
  excepciones acotadas**, las dos opcionales, las dos con import perezoso
  adentro de la función y aisladas a un solo módulo:
  - `attract mcp` usa el SDK `mcp` (PyPI)
    ([`ADR-0012`](../decisions/0012-mcp-dependencia-opcional-acotada.md), accepted).
  - `attract rasterize` usa `pymupdf` para convertir el PDF del manual a páginas
    ([`ADR-0022`](../decisions/0022-rasterizar-pdf-a-paginas.md), accepted).
    Se importa como `import pymupdf`, **no** `import fitz` — ese alias está
    deprecado y avisa por stderr.

  `doctor`/`synopsis`/`ingest`/la CLI base siguen sin instalar nada, y hay un
  test por dependencia que lo verifica bloqueando el módulo en un subproceso.
  `make setup` no instala ninguna de las dos.

  **Dos excepciones son una política; una tercera significa que este límite ya
  no describe el proyecto y hay que reescribirlo, no parcharlo otra vez.**
- **`library/` nunca va al repo** — pesa y no aporta (ver `.gitignore`/README).
- **`*.pegasus.txt` es artefacto de build, no fuente** — nunca se edita a
  mano ni se versiona como fuente ([`ADR-0002`](../decisions/0002-metadata-fuente-o-artefacto.md),
  accepted). Excepción: los de `docs/` y `fixtures/` son entradas de test
  escritas a mano, no artefactos reales.
- **El `launch:` lleva la ruta ABSOLUTA del emulador**, resuelta por máquina
  ([`ADR-0018`](../decisions/0018-launch-ruta-absoluta.md), accepted). Una app
  de GUI en macOS no hereda el PATH del shell, y el gabinete arranca Pegasus
  solo: con `mame` pelado no lo encuentra. No rompe cross-platform porque el
  metadata es artefacto de build y no va a git (ADR-0002). **Excepción: los de
  `fixtures/` se quedan con `mame` pelado** — son entradas de test versionadas
  que nunca se lanzan. Descartado: `{env.VAR}` (mismo problema una capa más
  abajo), arrancar desde una terminal (el gabinete no tiene), symlink en el
  PATH mínimo (SIP lo impide).
- **Mac y Windows deben correr exactamente la misma versión de MAME** — si no,
  hay dos `-listxml` distintos y bugs recién visibles en semana 8 ([`ADR-0005`](../decisions/0005-runtime-mame-vanilla.md)).
- **UTF-8, NFC y LF son obligatorios** en todo archivo de texto — un solo byte
  inválido rompe el archivo entero para el parser de Pegasus (`chk_encoding`
  en `doctor.py`).
- **Los datos ricos NO van en `metadata.pegasus.txt`** — van en un `data.json`
  externo junto a los assets del juego, que el theme lee con `XMLHttpRequest`
  ([`ADR-0001`](../decisions/0001-transporte-datos-ricos.md), accepted). Descartado:
  JSON embebido en campos `x-` y listas paralelas.
- **Una revista no pertenece a un juego, ni a un sistema** — es una entidad
  propia en `<raíz-librería>/_magazines/<id>/`, fuera del árbol de cualquier
  sistema; los juegos la referencian por `ref`, no la copian
  ([`ADR-0024`](../decisions/0024-contrato-magazine-json-v2.md), accepted,
  supersede a [`ADR-0010`](../decisions/0010-contrato-magazine-json-extendido.md));
  contrato encarnado en `fixtures/_magazines/`. Descartado: normalizar el
  `magazine.json` entrante al contrato viejo (viola ADR-0009 y hay que rehacerlo
  con cada regeneración) y compartir la carpeta con symlinks (no sobreviven al
  viaje a Windows).
- **Las páginas de revista son imágenes, nunca PDF** — Pegasus es Qt 5.15 sin
  soporte de PDF ([`ADR-0007`](../decisions/0007-paginas-revista-imagenes-no-pdf.md), accepted).
  Lo mismo vale para las páginas de manual
  ([`ADR-0014`](../decisions/0014-manual-digitalizado.md), accepted): viven en
  `media/<set>/_manual/`, declaradas en `data.json` con la misma forma que
  `magazine.json → pages[]`, para que el visor consuma un solo modelo.
  Descartado: `x-manual` (rompe ADR-0001 y un número de páginas no da rutas) y
  el manual como entidad propia tipo `_magazines/` (una revista cubre varios
  juegos, un manual no — no hay duplicación que evitar).
- **El límite de ADR-0007 es RENDERIZAR, no tener.** El theme no dibuja un PDF
  jamás, pero sí puede **entregárselo al sistema operativo** para que lo abra la
  app del usuario ([`ADR-0021`](../decisions/0021-manual-pdf-app-del-sistema.md),
  accepted): `manual.file` en `data.json` y `Qt.openUrlExternally()`, que es
  global de QtQml y no necesita `import`. Medido contra Pegasus real el
  2026-08-09 (`themes/experimentos/abrir-url-externa.qml`). **Leer "nunca PDF" y
  borrar esto es el error a evitar**: son dos cosas distintas. Descartado:
  `launch:` de un pseudo-juego (obliga a una colección nueva), `subprocess` de
  Python (ATTRACT no corre mientras Pegasus está abierto) y `QProcess` /
  `Qt.labs.platform` (necesitan un `import`, y un import que no resuelve tumba
  el theme entero). **Coste asumido:** el visor abre por delante pero Pegasus
  pierde el foco, y en el gabinete —solo joystick— no hay forma de volver; la
  mitigación real es mapear `Alt+F4` en el encoder, fuera de este repo.
- **`manual` es una LISTA de documentos, no un objeto** — un juego puede
  declarar más de un manual (de uso, de servicio, otro idioma —
  ["ADR-0023"](../decisions/0023-manual-multiple-con-pestanas.md), accepted).
  Cada elemento tiene la forma de siempre (`pages`/`file`) más un `label`
  **obligatorio solo si hay más de un documento**; con uno solo, sin `label`,
  se ve exactamente igual que antes de esta ADR — no hay migración de datos
  real, solo envolver en `[...]`. El visor reusa las pestañas de revista
  (`DocumentViewer.pestanas`, antes `revistas`) para elegir entre documentos;
  nunca conviven las dos filas. `attract rasterize` opera por documento
  (`<set> [label]`) y cada uno con más de uno rasteriza a su propio
  `_manual/manual-<índice>/` para no colisionar nombres de página.
- **El `accent` de cada juego se declara a mano** en su `data.json`
  ([`ADR-0013`](../decisions/0013-accent-por-juego.md), accepted). Descartado:
  tabla por colección (apaga el theming por juego, que es el efecto central
  del diseño) y derivar el color de la carátula — **imposible**, QML de Qt 5.15
  no lee píxeles sin C++ y Pegasus es un binario congelado (ADR-0006).
- **`api.allGames` NO es la librería de ATTRACT** — es todo lo que Pegasus
  encontró con **todos** sus providers activos (Steam, es2, logiqx, skraper…).
  Los que no son de ATTRACT se apagan en la configuración de Pegasus, y esa
  configuración es **idéntica en el Mac y en el gabinete**, mismo criterio que
  MAME y Pegasus ([`ADR-0017`](../decisions/0017-providers-pegasus.md),
  accepted). Descartado: filtrar en el theme — su modo de falla es un juego
  invisible, que es peor que un juego de más.
- **El theme se dibuja en un canvas fijo de 1280×720 y se escala entero**
  ([`ADR-0016`](../decisions/0016-canvas-fijo-escalado.md), accepted): todas
  las medidas son constantes en píxeles, tomadas del diseño. Descartado: layout
  relativo con anchors (obliga a re-derivar cientos de constantes y erosiona la
  fidelidad, que el handoff declara final) — el gabinete tiene resolución fija.
- **Pegasus sigue siendo el frontend**, versión fijada e idéntica en ambas
  máquinas, mismo criterio que MAME
  ([`ADR-0006`](../decisions/0006-version-politica-pegasus.md), accepted).
- **Identidad en set merged y estrategia cross-platform** ya decididas
  ([`ADR-0004`](../decisions/0004-identidad-set-merged.md) y
  [`ADR-0003`](../decisions/0003-cross-platform.md), ambas accepted).
