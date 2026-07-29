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
| `src/attract/cli.py` | Entry point. Dispatch de subcomandos: `doctor`, `synopsis` |
| `src/attract/doctor.py` | Validador preflight: todo lo que Windows rechazaría debe fallar en el Mac |
| `src/attract/synopsis.py` | Primer módulo que **escribe** `metadata.pegasus.txt` — merge quirúrgico del campo `summary:` desde `_synopsis/<set>.json` (ADR-0011) |
| `tests/test_doctor.py` | 19 tests, cada uno reproduce un bug real ya visto |
| `tests/test_synopsis.py` | 11 tests: merge de campo, idempotencia, casos límite/fallo |
| `fixtures/` | ROMs falsas de 0 bytes + `metadata.pegasus.txt` de ejemplo, para validar el doctor sin la librería real |
| `library/` | Librería real del autor (ROMs, CHDs, assets). Nunca se commitea |
| `themes/attract-debug/` | Theme QML de debug: harness del Bloque 3, dumpea `game.extra`. Es la evidencia viva de ADR-0001 — no se pisa |
| `themes/experimentos/` | Pruebas de una sola pregunta, archivadas con su resultado. No las instala `make theme` |
| `spec/decisions/` | Decisiones de arquitectura. 0001-0011, 10 vigentes (0008 superseded por 0010) |
| `spec/features/001-synopsis/` | Primera feature con spec/plan/tasks — `attract synopsis`, implementada |

## Comandos

| Acción | Comando |
|---|---|
| Instalar | `make setup` (venv + `pip install pytest`) |
| Tests | `make test` |
| Doctor (fixtures) | `make doctor` |
| Doctor (librería real) | `make doctor-lib` |
| Instalar theme | `make theme` |
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
   └─ data.json             # cheats, review + mags: [{ref: "<rev>-<n>"}]
```

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
  corre con cualquier Python ≥3.10, sin instalar nada).
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
- **Pegasus sigue siendo el frontend**, versión fijada e idéntica en ambas
  máquinas, mismo criterio que MAME
  ([`ADR-0006`](../decisions/0006-version-politica-pegasus.md), accepted).
- **Identidad en set merged y estrategia cross-platform** ya decididas
  ([`ADR-0004`](../decisions/0004-identidad-set-merged.md) y
  [`ADR-0003`](../decisions/0003-cross-platform.md), ambas accepted).
