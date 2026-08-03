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
| `src/attract/cli.py` | Entry point. Dispatch de subcomandos: `doctor`, `synopsis`, `mcp`, `ingest` |
| `src/attract/doctor.py` | Validador preflight: todo lo que Windows rechazaría debe fallar en el Mac |
| `src/attract/synopsis.py` | Primer módulo que **escribe** `metadata.pegasus.txt` — merge quirúrgico del campo `summary:` desde `_synopsis/<set>.json` (ADR-0011) |
| `src/attract/mcp_server.py` | Servidor MCP (M5) — tools `attract_doctor`/`attract_synopsis`. Única dependencia externa del proyecto, opcional e import perezoso (ADR-0012) |
| `src/attract/ingest.py` | Primer módulo que **crea** un `game:` nuevo (M7) — identidad vía `mame -listxml` (stdlib `xml.etree.ElementTree`) |
| `tests/test_doctor.py` | 34 tests, cada uno reproduce un bug real ya visto o un caso del contrato |
| `tests/test_synopsis.py` | 11 tests: merge de campo, idempotencia, casos límite/fallo |
| `tests/test_mcp_server.py` | 8 tests: aislamiento sin `mcp` instalado, lógica de las tools, registro contra el SDK real (se saltea si `mcp` no está) |
| `tests/test_ingest.py` | 14 tests: 10 contra XML sintético, 1 contra la ausencia real del binario (PATH vacío) y 3 de integración contra el `mame` instalado (se saltean si no hay) |
| `fixtures/` | ROMs falsas de 0 bytes + `metadata.pegasus.txt` de ejemplo, para validar el doctor sin la librería real |
| `library/` | Librería real del autor (ROMs, CHDs, assets). Nunca se commitea |
| `themes/attract/` | Theme de producción (feature 005). Tres capas según quién sabe de qué: `core/` datos y rutas, `ui/` dibuja, `screens/`+`overlays/` componen. Un solo singleton (`Theme`, el archivo es `Tokens.qml` — ver su encabezado) |
| `themes/attract-debug/` | Theme QML de debug: harness del Bloque 3, dumpea `game.extra`. Es la evidencia viva de ADR-0001 — no se pisa |
| `themes/experimentos/` | Pruebas de una sola pregunta, archivadas con su resultado. No las instala `make theme` |
| `spec/decisions/` | Decisiones de arquitectura. 0001-0017, 16 vigentes (0008 superseded por 0010) |
| `spec/features/001-synopsis/` | Primera feature con spec/plan/tasks — `attract synopsis`, implementada |
| `spec/features/002-attract-skill/` | `.claude/skills/attract/SKILL.md`, implementada |
| `spec/features/003-attract-mcp/` | Servidor MCP, implementada |
| `spec/features/004-attract-ingest/` | `attract ingest`, implementada (verificación contra `mame` real pendiente) |

## Comandos

| Acción | Comando |
|---|---|
| Instalar | `make setup` (venv + `pip install pytest`) |
| Tests | `make test` |
| Doctor (fixtures) | `make doctor` |
| Doctor (librería real) | `make doctor-lib` |
| Instalar theme | `make theme` (producción) / `make theme-debug` (harness) |
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
media/
├─ _magazines/<rev>-<n>/    # la revista, UNA sola vez
│  ├─ magazine.json         # name, issue?, year?, color?, cover, key_id, pages[], articles[]
│  ├─ cover.jpg
│  └─ p001.jpg … pNNN.jpg   # todas las páginas, ceros a la izquierda
└─ <set>/
   ├─ boxFront.jpg …        # assets nativos, auto-descubiertos por Pegasus
   ├─ data.json             # accent, cheats, review, manual + mags: [{ref: "<rev>-<n>"}]
   └─ _manual/              # páginas del manual escaneado, si hay
      └─ p001.jpg … pNNN.jpg
```

Contrato completo de `data.json` en
[`ADR-0015`](../decisions/0015-contrato-data-json.md) (accepted): todos los
campos opcionales, nombres completos (`{name, input}`, no `{n, i}`),
`review.cats` como objeto de seis claves fijas para poder expresar reseñas
parciales.

El juego **referencia** la revista, no la contiene: una revista cubre varios
juegos, y duplicar el escaneo en cada uno es el error que esto evita. Qué páginas
son la nota de cada juego vive en `magazine.json → articles[]`, buscando por
`game == "<set>"`. Una sola fuente de verdad ([`ADR-0010`](../decisions/0010-contrato-magazine-json-extendido.md), accepted — el contrato original era [`ADR-0008`](../decisions/0008-modelo-datos-revistas.md), superseded).

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
- Convención formal de campos/estructura de carpetas: **pendiente**, se escribe
  en `docs/CONVENCION.md` (es un ejercicio del bootcamp, no la completes vos).

## Límites duros

- **Sin dependencias externas** en `src/attract/` — es deliberado (`doctor`
  corre con cualquier Python ≥3.10, sin instalar nada). **Excepción
  acotada:** `attract mcp` usa el SDK `mcp` (PyPI) con import perezoso,
  aislado a ese módulo — `doctor`/`synopsis`/la CLI base siguen sin
  instalar nada ([`ADR-0012`](../decisions/0012-mcp-dependencia-opcional-acotada.md), accepted).
- **`library/` nunca va al repo** — pesa y no aporta (ver `.gitignore`/README).
- **`*.pegasus.txt` es artefacto de build, no fuente** — nunca se edita a
  mano ni se versiona como fuente ([`ADR-0002`](../decisions/0002-metadata-fuente-o-artefacto.md),
  accepted). Excepción: los de `docs/` y `fixtures/` son entradas de test
  escritas a mano, no artefactos reales.
- **Mac y Windows deben correr exactamente la misma versión de MAME** — si no,
  hay dos `-listxml` distintos y bugs recién visibles en semana 8 ([`ADR-0005`](../decisions/0005-runtime-mame-vanilla.md)).
- **UTF-8, NFC y LF son obligatorios** en todo archivo de texto — un solo byte
  inválido rompe el archivo entero para el parser de Pegasus (`chk_encoding`
  en `doctor.py`).
- **Los datos ricos NO van en `metadata.pegasus.txt`** — van en un `data.json`
  externo junto a los assets del juego, que el theme lee con `XMLHttpRequest`
  ([`ADR-0001`](../decisions/0001-transporte-datos-ricos.md), accepted). Descartado:
  JSON embebido en campos `x-` y listas paralelas.
- **Una revista no pertenece a un juego** — es una entidad propia en
  `media/_magazines/<id>/`; los juegos la referencian por `ref`, no la copian
  ([`ADR-0010`](../decisions/0010-contrato-magazine-json-extendido.md), accepted,
  supersede a [`ADR-0008`](../decisions/0008-modelo-datos-revistas.md));
  contrato encarnado en `fixtures/arcade/media/`.
- **Las páginas de revista son imágenes, nunca PDF** — Pegasus es Qt 5.15 sin
  soporte de PDF ([`ADR-0007`](../decisions/0007-paginas-revista-imagenes-no-pdf.md), accepted).
  Lo mismo vale para las páginas de manual
  ([`ADR-0014`](../decisions/0014-manual-digitalizado.md), accepted): viven en
  `media/<set>/_manual/`, declaradas en `data.json` con la misma forma que
  `magazine.json → pages[]`, para que el visor consuma un solo modelo.
  Descartado: `x-manual` (rompe ADR-0001 y un número de páginas no da rutas) y
  el manual como entidad propia tipo `_magazines/` (una revista cubre varios
  juegos, un manual no — no hay duplicación que evitar).
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
