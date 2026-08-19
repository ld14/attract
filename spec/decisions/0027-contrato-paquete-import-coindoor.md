---
id: 0027
title: "Contrato del paquete que COINDOOR exporta y attract import instala"
status: accepted
date: "2026-08-18"
supersedes: null
superseded-by: null
tags: [backend, data, proceso]
---

# 0027 — Contrato de paquete de import COINDOOR → ATTRACT

## Contexto

COINDOOR (`https://github.com/ld14/COINDOOR.git`) es una app externa, de
formularios, para cargar todo lo que un juego necesita antes de aparecer en
pantalla — hoy eso se hace editando `metadata.pegasus.txt` y `data.json` a
mano. La idea es que COINDOOR exporte un zip y ATTRACT lo decodifique e
instale en `library/<sistema>/`.

Hace falta fijar el contrato exacto del zip por dos razones:

1. Es la especificación que se le entrega a Claude Code trabajando en el
   repo COINDOOR — sin un contrato escrito, cada sesión ahí inventa una forma
   distinta.
2. `attract import` (lado ATTRACT) necesita saber exactamente qué esperar
   para poder "fallar explícito, nunca escritura parcial", la misma filosofía
   que ya siguen `ingest.py` y `synopsis.py`.

Restricción de diseño que ya fijó `spec/features/015-carga-guiada/plan.md`:
**"un comando que encadena varios escritores no puede fallar a la mitad sin
dejar estado inconsistente"** — por eso se descartó ahí un `attract load`
orquestador de `ingest`+`synopsis`+`rasterize`+`mags`. `attract import` no
es ese orquestador: es UN escritor nuevo, con su propia garantía atómica,
que no llama a los otros comandos — el mismo patrón que ya usa `ingest.py`
(crea bloque + carpeta en una sola operación validada de punta a punta antes
de escribir nada).

## Decisión

El zip tiene esta forma, un juego por paquete:

```
game.json
data.json
media/
  boxFront.png, marquee.png, poster.png, video.mp4, ...   ← flat
  _manual/
    manual.pdf, servicio.pdf, ...                          ← flat, nombres únicos
```

### `game.json` — identidad y campos nativos

```json
{
  "schema_version": "1",
  "system": "arcade",
  "set": "sf2ce",
  "file": "sf2ce.zip",
  "title": "Street Fighter II: Champion Edition",
  "developer": "Capcom",
  "publisher": "Capcom",
  "genre": "Fighting",
  "players": 2,
  "release": "1992-04-10",
  "summary": "...",
  "format": "PCB",
  "file_format": "zip"
}
```

Obligatorios: `schema_version`, `system`, `set`, `title` — el mínimo que
necesita existir un `game:` válido (`docs/CONVENCION.md` §2.1). El resto,
opcional, igual que el resto del contrato del proyecto.

- `format` → mapea a `x-formato`: formato **físico** del medio original
  (Arcade, GD-ROM, PCB, Cartucho, Diskette, CD, DVD). Es lo que el theme
  muestra como badge.
- `file_format` → mapea a `x-formato-archivo`: formato de **archivo** del
  ROM (zip, chd, iso, etc.). Informativo, no se muestra en el badge.

### `data.json` — el contrato que ya existe, sin traducir

Exactamente el contrato de [`ADR-0015`](0015-contrato-data-json.md) +
[`ADR-0020`](0020-cheats-grupos-libres.md) +
[`ADR-0023`](0023-manual-multiple-con-pestanas.md): `accent`, `accent2`,
`mags`, `manual` (lista), `cheats`, `review`. Cero forma nueva — ya está
validado por `attract doctor` (`chk_data_contrato`), traducirlo a una forma
"COINDOOR" agregaría una capa que se puede desincronizar del contrato real
sin que nada lo note.

`mags[]` normalmente va vacío o solo con `ref` (si el humano en COINDOOR ya
sabe en qué revista escaneada aparece el juego). El campo `article` —el slug
editorial que resuelve la página exacta— lo sigue escribiendo únicamente
`attract mags` ([`ADR-0025`](0025-link-revista-juego-difuso.md)). Orden de
trabajo esperado: `attract import` primero, `attract mags --apply` después.

`manual[].pages` va **ausente** — COINDOOR entrega el PDF crudo en
`media/_manual/`, nunca páginas rasterizadas. Rasterizar sigue siendo
`attract rasterize`, un paso explícito y aparte
([`ADR-0022`](0022-rasterizar-pdf-a-paginas.md): "nadie lo corre solo",
depende de `pymupdf`, que `attract import` no puede importar sin romper el
límite de dos únicas dependencias opcionales de `tech-stack.md`).

### `media/` — flat, mismo criterio que la librería real

El nombre de archivo (sin extensión) es la clave del asset:
`boxFront.png` → `assets.boxFront`. Mismo criterio que ya usan los fixtures
a mano (`fixtures/arcade/metadata.pegasus.txt`). `attract import` escribe una
línea `assets.<clave>: media/<set>/<archivo>` por archivo copiado — no hay
lista cerrada de claves válidas: una clave que Pegasus no reconozca
simplemente no hace nada, mismo criterio abierto que ya usa `magazine.json →
articles[].type` (ADR-0024, AVISO no ERROR para valores desconocidos).

Los PDF de `_manual/` van **flat**, con nombres únicos elegidos por
COINDOOR — `doctor.py::_chk_manual_doc` ya resuelve `manual[].file` como un
nombre de archivo dentro de `_manual/`, no una ruta, así que dos documentos
solo pueden convivir si sus nombres no chocan.

### Instalación (`attract import <paquete.zip> [ruta]`)

1. **Zip-slip guard primero.** Todo miembro del zip se valida contra los
   prefijos permitidos (`game.json`, `data.json`, `media/...`) antes de
   extraer nada. Cualquier `..`, ruta absoluta o symlink → falla explícito,
   cero escritura. No hay precedente en el repo (`ingest`/`synopsis` no
   extraen zips) — se documenta como decisión de seguridad, no una opción a
   discutir.
2. **Validar todo en memoria** — `schema_version` soportada, campos
   obligatorios de `game.json`, forma de `data.json` — antes de tocar disco.
3. Si `<sistema>/metadata.pegasus.txt` ya tiene un bloque `game:` con ese
   `set` (creado antes por `attract ingest` vía MAME): **merge quirúrgico**
   de los campos de `game.json` sobre ese bloque, sin tocar `file:`/`x-set:`.
   Si no existe: **se crea**, vía [`ADR-0026`](0026-identidad-declarada-sin-mame.md)
   (`x-procedencia: declarada`).
4. **Todo se pisa siempre** al reimportar — mismo criterio que
   `docs/CONVENCION.md` §3.3 ("el reproceso más reciente gana, sin
   excepción"). Evita diseñar una política de merge campo por campo nueva.
5. **Excepción puntual: `data.json → mags[]`.** Si el paquete no trae `mags`,
   se conserva lo que ya hubiera en disco — para no borrar lo que
   `attract mags` haya escrito después de un import anterior. Mismo criterio
   conservador que `magazines.py::agregar_ref`.
6. Copiar `media/*` (assets + `_manual/*`) a `media/<set>/`, sobrescribiendo.
7. Recién ahí se escribe a disco — pasos 1-2 son de solo lectura.

## Alternativas consideradas

### A · Lote multi-juego por zip

Un `manifest.json` con N juegos + N revistas en un mismo paquete.

- A favor: menos overhead para cargar una sesión de trabajo con varios
  juegos de una vez.
- En contra: el importer y la validación se complican (fallar a la mitad de
  un lote dejaría algunos juegos instalados y otros no), y revisar un paquete
  antes de instalarlo es más difícil cuanto más grande es.
- **Descartada porque:** decisión explícita del usuario — un juego por zip es
  más simple de generar, revisar e instalar, y un error en un juego no
  arrastra a otros. Si el volumen real lo justifica, se reabre con evidencia
  de cuánto duele cargar de a uno.

### B · Incluir `_magazines/` en el paquete

Que COINDOOR también empaquete el escaneo completo de una revista.

- A favor: un solo flujo de carga cubre juego + revista.
- En contra: le suma a COINDOOR una responsabilidad que hoy tiene un
  subsistema aparte ([`ADR-0009`](0009-frontera-produccion-consumo-revistas.md)),
  y duplicaría esa responsabilidad en dos sistemas productores.
- **Descartada porque:** decisión explícita del usuario — COINDOOR solo
  referencia (`mags[{ref}]`) revistas que ya existen en la librería,
  respetando la frontera que ADR-0009 ya trazó.

### C · Traducir `data.json` a una forma propia de COINDOOR

Que el paquete use nombres de campo distintos, más simples para un
formulario, y `attract import` los traduzca al contrato real.

- A favor: el formulario de COINDOOR podría tener nombres más amigables sin
  atarse al contrato interno de ATTRACT.
- En contra: dos contratos para la misma información, uno de los cuales
  (`data.json`) ya está validado por `doctor` y consumido por el theme. La
  traducción es una tercera fuente de bugs — se puede desincronizar sin que
  ningún chequeo existente lo note.
- **Descartada porque:** viola `CLAUDE.md` §8 (buscar consistencia, reusar
  antes que inventar). El costo de que el formulario de COINDOOR use
  internamente los mismos nombres es cero para ATTRACT.

### D · Auto-rasterizar el manual durante el import

Que `attract import` llame a la lógica de `rasterize.py` si el paquete trae
un PDF, para no dejar el manual sin páginas.

- A favor: menos pasos manuales después de importar.
- En contra: `rasterize` depende de `pymupdf`
  ([`ADR-0022`](0022-rasterizar-pdf-a-paginas.md)), una de las dos únicas
  excepciones acotadas al límite stdlib-only. Encadenarla dentro de `import`
  la vuelve una dependencia de facto del flujo de carga, no ya "opcional,
  import perezoso, nadie lo corre solo".
- **Descartada porque:** rompe el patrón explícito que `tech-stack.md`
  §Límites duros fija para las dos dependencias opcionales del proyecto.

## Consecuencias

**Positivas**

- Reusa el contrato de `data.json` y las validaciones de `doctor.py` tal
  cual — cero cambios necesarios en `doctor.py` para que un juego importado
  se valide igual que uno cargado a mano.
- Un solo escritor atómico, coherente con el resto del proyecto
  (`ingest.py`, `synopsis.py`): "fallar explícito, nunca escritura parcial".
- El documento hermano `docs/contrato-paquete-coindoor.md` es la
  especificación exacta y autocontenida que se le entrega a Claude Code en el
  repo COINDOOR.

**Coste asumido**

- Zip-slip guard es código nuevo sin precedente en el repo — hay que
  probarlo explícitamente (path traversal, symlink, ruta absoluta).
- Reimportar pisa todo lo que el paquete trae, incluido lo que alguien pudo
  haber corregido a mano en el `data.json` instalado — mismo riesgo que
  `CONVENCION.md` §3.3 ya acepta para cualquier reproceso, no uno nuevo.

**Qué habría que revisar si esto se replantea**

- Si el volumen de carga real hace que "un juego por zip" sea la fricción
  dominante — ahí la Alternativa A se reabre con evidencia.
- Si `data.json` crece tanto que conviene partirlo (la misma señal que ya
  anotó ADR-0015 §Alternativa B) — el contrato de este paquete cambiaría en
  simultáneo, no antes.

## Referencias

- [`ADR-0026`](0026-identidad-declarada-sin-mame.md) — cómo se crea el
  bloque `game:` cuando el `set` todavía no existe.
- [`ADR-0015`](0015-contrato-data-json.md),
  [`ADR-0020`](0020-cheats-grupos-libres.md),
  [`ADR-0023`](0023-manual-multiple-con-pestanas.md) — el contrato de
  `data.json` que este paquete reusa sin traducir.
- [`ADR-0022`](0022-rasterizar-pdf-a-paginas.md) — por qué el import no
  rasteriza.
- [`ADR-0025`](0025-link-revista-juego-difuso.md) — por qué `mags[].article`
  no lo escribe este comando.
- [`spec/features/015-carga-guiada/plan.md`](../features/015-carga-guiada/plan.md)
  — el principio "read-only en vez de orquestador" que este ADR respeta.
- [`spec/features/016-import-coindoor/`](../features/016-import-coindoor/) —
  la feature que implementa este contrato.
- `docs/contrato-paquete-coindoor.md` — versión autocontenida de este
  contrato, para el repo COINDOOR.
