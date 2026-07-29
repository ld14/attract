# 004 · `attract ingest` — Tareas

_Checklist accionable derivada del `plan.md`._

## Implementación

- [x] `src/attract/ingest.py::listar_maquinas_jugables` — corre
      `mame -listxml <set>`, filtra `runnable="no"`. Hecho cuando: contra
      un XML sintético con una jugable + un device, devuelve solo la
      jugable.
- [x] `src/attract/ingest.py::identificar` — exige exactamente 1 máquina.
      Hecho cuando: 0 y >1 fallan explícito con mensajes distintos.
- [x] `src/attract/ingest.py::construir_bloque` — arma el bloque nuevo sin
      inventar `developer:`/`release:` si `-listxml` no los dio.
- [x] `src/attract/ingest.py::aplicar` — orquesta todo, reusa
      `synopsis.parsear_bloques`/`escribir`/`identificar_set`. Hecho
      cuando: agrega al final sin tocar bloques existentes, crea
      `media/<set>/`.
- [x] `src/attract/cli.py` — agregado `"ingest"` a `COMANDOS` y al
      `--help`.

## Tests (`tests/test_ingest.py`) — 10 tests, todos con XML sintético mockeado

- [x] `mame` no instalado → `IngestError` explícito. **Este test corre
      contra el `mame` real de este sandbox** (no hay uno instalado) — es
      el único test de todo el archivo que no depende del XML sintético.
- [x] Filtra `runnable="no"` correctamente.
- [x] 0 máquinas jugables → falla explícito ("no reconocido").
- [x] Más de 1 máquina jugable → falla explícito, menciona ADR-0004.
- [x] XML inválido → falla explícito, no traceback crudo.
- [x] `construir_bloque` completo (con year/manufacturer) y sin ellos —
      confirma que no inventa campos.
- [x] `aplicar` caso feliz: agrega el bloque, no toca lo existente, crea
      `media/<set>/`.
- [x] `aplicar` con set ya existente: falla, archivo sin tocar.
- [x] `aplicar` con set no reconocido por mame: falla, archivo sin tocar,
      no crea `media/<set>/`.

## ⚠️ Verificación pendiente — correr en tu Mac, bien dummy

_Esta es la única parte de `004-attract-ingest` que no puedo confirmar yo
mismo: no hay `mame` instalado en este sandbox. Todo lo de arriba está
probado contra un XML **sintético** (inventado a partir de conocimiento
general del formato), no contra el binario real._

**Paso 1** — elegí un ROM real y conocido de tu librería (por ejemplo
`sf2ce`, el mismo que ya usamos en el LAB 0.2).

**Paso 2** — confirmá la forma real del XML:

```bash
mame -listxml sf2ce
```

Mirá si tiene `<description>`, `<year>`, `<manufacturer>` con esos nombres
exactos, y si el XML empieza con un `<!DOCTYPE mame [...]>` antes del
`<mame>` raíz (esperado, no debería romper el parseo, pero confirmalo).

**Paso 3** — corré `attract ingest` contra un `metadata.pegasus.txt` de
prueba (no el real, para no arriesgar tu librería):

```bash
cp fixtures/arcade/metadata.pegasus.txt /tmp/prueba.txt
mkdir -p /tmp/prueba-media
cd /tmp && PYTHONPATH=<ruta-al-repo>/src python3 -m attract.ingest sf2ce.zip .
```

(Vas a necesitar ajustar la ruta para que `metadata.pegasus.txt` esté en
el directorio donde corrés el comando.)

**Paso 4** — mirá qué bloque `game:` quedó. ¿El título tiene basura de
región/revisión (`"(Japan 920513)"` o similar)? ¿`release:` con solo el
año se ve bien, o Pegasus lo rechaza? Contame qué viste y ajustamos
`ingest.py` si algo no coincide — no hace falta una ADR nueva para esto,
es corregir contra evidencia (mismo patrón que `magazine.json`,
ADR-0008 → 0010).

## Cierre

- [x] `PYTHONPATH=src python3 -m pytest tests/ -q` en verde (48/48: 19
      `doctor` + 11 `synopsis` + 8 `mcp` + 10 `ingest`).
- [x] `attract doctor` sobre todo el repo en 0 errores.
- [ ] Verificación de arriba corrida contra `mame` real — pendiente,
      necesita tu Mac.
- [x] Movido `004-attract-ingest` a "Hecho (con verificación pendiente)"
      en `../../constitution/roadmap.md`.
