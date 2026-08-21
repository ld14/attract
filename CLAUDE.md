# ATTRACT

## Qué es esto

Fábrica de metadata y assets para un frontend Pegasus de máquina recreativa:
cae una ROM, ATTRACT arma la estructura de archivos, la pantalla se genera
sola con lo que haya (ingesta incremental, no curación masiva). También es
el proyecto del Módulo 0 de un bootcamp — varios docs son plantillas que el
autor completa en vivo (ver §Documentación pendiente).

## Método de trabajo

Este proyecto usa **Spec Driven Development**: primero la spec, luego el plan,
luego las tareas, y solo entonces el código. Ver `spec/README.md`.

**La constitución manda.** Si una feature choca con `spec/constitution/`, se
replantea la feature, no la constitución.

**Decisiones de arquitectura (ADRs) viven en `spec/decisions/`** (0001-0025,
21 vigentes — 0008 superseded por 0010, 0016 por 0019, 0015 por 0020,
0010 por 0024; formato con frontmatter — ver
`spec/decisions/_TEMPLATE.md`). Se crean con `/new-adr`.

**Los handoffs de sesión viven en `docs/decisiones/AAAA-MM-DD.md`.** Son la red
de seguridad entre "lo pensamos" y "está en un ADR": contienen decisiones válidas
pero todavía no formalizadas. Trátalos como fuente de verdad provisional y
cítalos, pero recuerda que el destino de su contenido es un ADR.

## Comandos

| Acción | Comando |
|---|---|
| Setup | `make setup` (git config + venv + verificación) |
| Tests | `make test` (pytest, 184 tests) |
| Doctor (fixtures) | `make doctor` |
| Doctor (librería real) | `make doctor-lib` |
| Linkear revistas ↔ juegos | `attract mags library` (dry-run) / `--apply` (ADR-0025) |
| Instalar paquete COINDOOR | `attract import <paquete.zip> [ruta]` (ADR-0027) |
| Instalar theme | `make theme` (producción) / `make theme-debug` (harness ADR-0001) |
| Servidor MCP | `make mcp` (necesita `pip install mcp`, ver ADR-0012) |
| Vaciar Pegasus (carga desde cero) | `make reset-pegasus` (destructivo, pide confirmación) / `DRY=1 bash scripts/reset-pegasus.sh` |

No hay build ni lint configurados. `PYTHONPATH=src` lo exporta el Makefile.

## Mapa del repo

| Ruta | Qué es |
|---|---|
| `src/attract/` | CLI Python: `doctor` (validador), `synopsis` (primer escritor de `metadata.pegasus.txt`), `mcp` (servidor MCP, M5), `ingest` (crea `game:` nuevo vía `mame -listxml`, M7), `instalar` (importa paquete COINDOOR, ADR-0027), `rasterize` (PDF del manual → páginas, ADR-0022), `magazines` (linkea revistas con juegos, ADR-0025) |
| `.claude/skills/attract/` | Claude Skill de proyecto: le dice a un agente cuándo correr `doctor`/`synopsis` (M4, `spec/features/002-attract-skill/`) |
| `tests/` | 184 tests (66 `doctor` + 14 `synopsis` + 9 `mcp` + 14 `ingest` + 41 `rasterize` + 28 `magazines` + 12 `instalar`), cada uno reproduce un bug real o un caso del contrato |
| `fixtures/` | ROMs falsas de 0 bytes + `_magazines/` (cuatro revistas de mentira, en la **raíz** de `fixtures/` — ADR-0024). Portables y versionables |
| `library/` | Librería real del autor. NO va a git |
| `themes/attract/` | **Theme de producción** (feature 005). `Tokens.qml` (singleton `Theme`), `core/` (datos y rutas), `ui/` (dibuja), `screens/`, `overlays/`. Ver `spec/features/005-theme-base/plan.md` |
| `themes/attract-debug/` | Harness de debug: dumpea `game.extra`. Es la evidencia viva de ADR-0001 — no lo reemplaces, agregá al lado |
| `themes/experimentos/` | Pruebas de una sola pregunta, archivadas con su resultado. `make theme` no las instala |
| `scripts/` | Mantenimiento del entorno local, no del código. `reset-pegasus.sh` vacía Pegasus para una carga desde cero |
| `docs/` | SETUP, CONVENCION (plantilla), baseline, mapeo |
| `docs/plataforma-pegasus.md` | **Hechos verificados de Pegasus/Qt 5.15**, cada uno con su evidencia. Leelo antes de tocar el theme: la documentación oficial no siempre coincide con el binario |
| `docs/decisiones/` | Handoffs de sesión: decidido pero sin ADR todavía |
| `spec/constitution/` | Reglas estables: misión, stack, roadmap |
| `spec/decisions/` | ADRs. 0001-0025, 21 vigentes (0008 superseded por 0010, 0016 por 0019, 0015 por 0020, 0010 por 0024) |
| `spec/features/NNN-*/` | spec + plan + tasks por feature. `001`-`006` implementadas; `007-theme-trucos` es la que falta |
| `themes/attract/` (feature 005-006) | Librería, detalle, video, carrusel de revistas y visor de documentos. Verificado contra Pegasus real |

## Reglas de trabajo

- Antes de proponer arquitectura, lee `spec/constitution/tech-stack.md`
  (en especial §Límites duros) y el índice de `spec/decisions/`.
- No propongas nada listado como descartado en un ADR sin decir explícitamente
  qué ha cambiado para reabrirlo.
- Decisión con alternativas descartadas → `/new-adr` (crea el archivo en
  `spec/decisions/` con el formato de `_TEMPLATE.md`).
- Los ADRs no se editan: se supersedan con uno nuevo (`superseded-by` en el
  frontmatter).
- Todo lo que Windows rechazaría tiene que fallar en el Mac — es la filosofía
  de `attract doctor` (`src/attract/doctor.py`). Nuevo chequeo de compatibilidad
  cross-platform → agregarlo ahí, no en un script aparte.
- `library/` nunca se commitea. `*.pegasus.txt` es artefacto de build, no fuente
  ([`ADR-0002`](spec/decisions/0002-metadata-fuente-o-artefacto.md), accepted).
  Excepción: los de `fixtures/` y `docs/` son entradas de test escritas a
  mano, sí van al repo.
- Los fixtures son **de 0 bytes a propósito, salvo excepción explícita**.
  Para validar estructura no hace falta un CHD de 132 MB ni un escaneo real.
  Fixture nuevo → archivo vacío. Si se agrega otra excepción, anotarla acá.

  Excepciones vigentes:
  - `fixtures/arcade/sf2ce.zip` es un romset real (~3.5 MB), para poder correr
    `mame -listxml` contra él y verificar cosas como el conteo de sets de una
    familia — un zip de 0 bytes no sirve para eso.
  - `media/dino/boxFront.png` y `media/mok/poster.png` son PNG **generados**
    (~2 KB cada uno, colores planos con un patrón diagonal obviamente
    sintético). Con todo en 0 bytes, `Image` siempre da `Error` y la cadena de
    carátula de `CONVENCION.md` §2.2 siempre termina en el último eslabón: no
    hay forma de distinguir "cargó `boxFront`" de "cargó el color-wash".
    Estos dos hacen observables los tres eslabones — `dino` tiene `boxFront`
    (eslabón 1), `mok` **no** lo tiene y cae a `poster` (eslabón 2), `sf2ce`
    queda en 0 bytes (eslabón 3). No son arte y no pretenden serlo.
  - Las **páginas y tapas** de las cuatro revistas de `fixtures/_magazines/`
    (páginas en `<revista>/pages/`, tapa en la raíz — ADR-0024) y las de
    `sf2ce/_manual/` (plano, sin `pages/`) son
    PNG generados (~2 KB cada uno) **con el número impreso grande**. El número
    es el punto: sin él no se puede verificar que hojear avance, que
    `startPage` abra donde debe, ni que una miniatura salte a la página
    correcta. Con todo en 0 bytes el visor no muestra nada y no hay nada que
    comprobar.

    Las cuatro arrancan en `p001`, y por eso **no** distinguen las dos
    lecturas posibles de `startPage` (índice vs. número impreso): dan lo mismo.
    Ese fue el punto ciego que dejó pasar el bug de ADR-0024 hasta que llegó
    una revista real que arranca en `p002`. Un fixture nuevo que arranque en
    `p002` paga solo.
- **Las carátulas de verdad van en `library/`, nunca en `fixtures/`.** Son
  arte con copyright y `fixtures/` se versiona. `library/preview/` es una
  colección desechable para mirar el theme con arte real y compararlo contra
  el diseño de referencia; se borra con `rm -rf library/preview` más sacar su
  línea de `game_dirs.txt` de Pegasus.
- **Dentro de `library/` y `fixtures/`, el prefijo `_` marca lo que no es una
  colección de juegos** (`_magazines/`, `_synopsis/`). No es cosmético: es la
  regla que usa `scripts/reset-pegasus.sh` para decidir qué borrar y qué
  conservar. Colección nueva → sin prefijo. Datos que acompañan a los juegos
  pero no son juegos → con `_`.
- **Pegasus reescribe su config al salir.** Editar `game_dirs.txt`,
  `favorites.txt` o `settings.txt` con Pegasus abierto no sirve: al cerrarse
  pisa el archivo con lo que tenía en memoria. Cerralo primero.

## Fuera de alcance sin preguntar

- Añadir dependencias nuevas (el proyecto es stdlib-only a propósito, con
  **dos** excepciones acotadas y opcionales: `mcp` para `attract mcp`
  ([`ADR-0012`](spec/decisions/0012-mcp-dependencia-opcional-acotada.md)) y
  `pymupdf` para `attract rasterize`
  ([`ADR-0022`](spec/decisions/0022-rasterizar-pdf-a-paginas.md)) — cualquier
  otra sigue necesitando preguntar primero, y una tercera obliga a reescribir
  el límite duro en vez de parcharlo otra vez)
- Completar los docs plantilla del bootcamp (`CONVENCION.md`, `baseline.md`,
  `mapeo-mockup-pegasus.md`) — son ejercicios del autor, no tareas de Claude
- Cambios en CI/CD o infraestructura
