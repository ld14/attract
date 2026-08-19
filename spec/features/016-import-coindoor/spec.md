# 016 · Import de paquete COINDOOR

**Estado:** implementada   <!-- borrador | aprobada | en curso | implementada -->

## Qué hace

**Recibe** un zip generado por COINDOOR (app externa de carga de datos,
`https://github.com/ld14/COINDOOR.git`) con la información de un juego:
identidad, metadata, assets y manual. **Produce** el juego instalado en
`library/<sistema>/` — bloque `game:` en `metadata.pegasus.txt`, `data.json`,
assets en `media/<set>/` y el/los PDF de manual en `media/<set>/_manual/` —
o falla explícito sin escribir nada si el paquete no es válido.

Un comando nuevo: `attract import <paquete.zip> [ruta]`.

**No** produce contenido ni encadena otros comandos de ATTRACT. Rasterizar el
manual sigue siendo [`attract rasterize`](../013-rasterize-manual/spec.md);
linkear revistas sigue siendo `attract mags`
([`ADR-0025`](../../decisions/0025-link-revista-juego-difuso.md)); reportar
completitud sigue siendo [`attract carga`](../015-carga-guiada/spec.md) —
esta feature solo instala lo que el paquete trae.

## Por qué

Hoy cargar un juego significa editar `metadata.pegasus.txt` y `data.json` a
mano, archivo por archivo. COINDOOR reemplaza esa edición manual con un
formulario; para que sirva de algo, ATTRACT necesita un lado que decodifique
lo que ese formulario produce. El contrato exacto del paquete —qué archivos,
qué nombres, qué forma de JSON— está fijado en
[`ADR-0027`](../../decisions/0027-contrato-paquete-import-coindoor.md), junto
con [`ADR-0026`](../../decisions/0026-identidad-declarada-sin-mame.md) (cómo
se crea un `game:` sin `mame -listxml`, necesario porque COINDOOR puede
cargar sistemas que MAME no cubre).

## Criterios de aceptación

- [ ] Dado un paquete válido para un `set` que **no existe** todavía en
      `metadata.pegasus.txt`, `attract import` crea el bloque `game:` completo
      (`x-procedencia: declarada`, ADR-0026) más `data.json` y los assets.
- [ ] Dado un paquete válido para un `set` que **ya existe** (creado antes por
      `attract ingest` vía MAME), `attract import` mergea los campos de
      `game.json` sobre el bloque existente sin tocar `file:`/`x-set:`.
- [ ] Dado un `data.json` ya instalado con `mags[]` (escrito por
      `attract mags` después de un import anterior) y un paquete nuevo que
      **no** trae `mags`, el `mags[]` existente se conserva.
- [ ] Dado un zip con un miembro que intenta escribir fuera de
      `media/<set>/` (`../`, ruta absoluta, symlink), `attract import` falla
      explícito y no escribe **nada** — ni el bloque, ni `data.json`, ni un
      solo asset.
- [ ] Dado un `game.json` sin `system`, `set` o `title`, falla explícito antes
      de tocar disco.
- [ ] Dado un `data.json` que no cumple el contrato de ADR-0015/0020/0023
      (ej. `cheats` con una entrada sin `input`), falla explícito antes de
      tocar disco — mismas reglas que ya valida `attract doctor`, aplicadas
      aquí como preflight.
- [ ] Dado un `manual/*.pdf` en el paquete, se copia a `media/<set>/_manual/`
      y `data.json → manual[].file` apunta a él — sin `pages[]`: rasterizar
      sigue siendo un paso aparte.
- [ ] Reimportar el mismo paquete dos veces da el mismo resultado en disco
      (idempotente).
- [ ] Después de un import exitoso, `attract doctor` sobre esa librería no
      reporta ningún error nuevo atribuible al juego importado.
- [ ] Dado un `system` cuyo `<sistema>/metadata.pegasus.txt` no existe,
      `attract import` falla explícito sin crear nada.

## Fuera de alcance

- **Crear un sistema/colección nuevo.** `attract import` exige que
  `<sistema>/metadata.pegasus.txt` ya exista (con su `collection:`/
  `shortname:`/`launch:`); si no existe, falla explícito. Crear la carpeta y
  la cabecera es una acción manual de una línea, fuera del repo — mismo
  alcance que ya fijó `015-carga-guiada/spec.md`.
- Rasterizar el manual — eso es
  [`013-rasterize-manual`](../013-rasterize-manual/spec.md).
- Linkear revistas (`mags[].article`) — eso es `attract mags`
  ([`ADR-0025`](../../decisions/0025-link-revista-juego-difuso.md)).
- Reportar qué falta para que un juego esté COMPLETO — eso es
  [`attract carga`](../015-carga-guiada/spec.md).
- Empaquetar o generar `_magazines/` — decisión explícita: COINDOOR solo
  referencia revistas que ya existen (ADR-0027 §Alternativa B).
- Lotes multi-juego en un mismo zip — decisión explícita: un juego por
  paquete (ADR-0027 §Alternativa A).
- El lado COINDOOR (exportar el zip) — vive en otro repo. Esta feature es
  solo el lado ATTRACT (decodificar e instalar).
