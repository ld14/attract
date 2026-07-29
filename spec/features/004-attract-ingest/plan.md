# 004 · `attract ingest` — Plan

_Cómo se implementa lo descrito en `spec.md`. Respeta `constitution/`._

## Enfoque

Reusa el parser de bloques de `synopsis.py` (`parsear_bloques`,
`identificar_set`, `escribir`, `Bloque`) en vez de duplicarlo — `ingest`
solo necesita **agregar** un bloque nuevo al final, `synopsis` ya sabe leer
y reserializar el archivo sin tocar lo que no corresponde. La única pieza
nueva de verdad es la identidad: correr `mame -listxml <set>`, parsear el
XML con `xml.etree.ElementTree` (stdlib — no rompe el límite duro, a
diferencia de `mcp`), y quedarse con las máquinas jugables (mismo filtro
verificado en el LAB 0.2: sin `runnable="no"`).

## Implementación

1. `src/attract/ingest.py`:
   - `IngestError(Exception)` — mismo patrón que `SynopsisError`: fallar
     explícito, nunca escritura parcial.
   - `listar_maquinas_jugables(set_id: str) -> list[dict]` — corre
     `mame -listxml <set_id>` por subprocess, parsea con `ElementTree`,
     descarta `machine[@runnable="no"]`. Atrapa `FileNotFoundError` (mame
     no está en PATH) y `ET.ParseError` (XML raro), los vuelve
     `IngestError` con mensaje explícito.
   - `identificar(set_id) -> dict` — llama a lo de arriba, exige
     **exactamente una** máquina jugable. Cero → "set no reconocido". Más
     de una → "más de una máquina jugable, caso no soportado (ver
     ADR-0004)".
   - `construir_bloque(info, file_name, set_id) -> Bloque` — arma
     `game:`/`file:`/`developer:`/`release:`/`x-set:` a partir de lo que
     `-listxml` haya dado (`developer:`/`release:` se omiten si
     `-listxml` no trae `manufacturer`/`year` — no se inventa nada).
     Normaliza a NFC (mismo criterio que `synopsis.mergear_summary`).
   - `aplicar(metadata_path, sistema_root, rom_path)` — orquesta: si el
     `set_id` (derivado de `rom_path.stem`) ya tiene bloque, falla; si no,
     identifica, construye, agrega al final de `parsear_bloques(...)`,
     reserializa con `synopsis.escribir`, crea `media/<set_id>/` vacía.
   - `main(argv)` — `attract ingest <rom.zip> [ruta]`.
2. `src/attract/cli.py` — agrega `"ingest": ingest.main` a `COMANDOS`.

## Decisiones

- **Reusar el parser de bloques de `synopsis.py`, no duplicarlo** — mismo
  formato de archivo, misma garantía de "no tocar lo que no corresponde".
- **`xml.etree.ElementTree` (stdlib)** — mantiene `ingest` sin
  dependencias externas nuevas, a diferencia de `mcp` (ADR-0012). No hace
  falta un parser XML de terceros para algo tan acotado.
- **`release:` solo con el año** (`YYYY`), nunca un mes/día inventado —
  `-listxml` da año, no fecha completa; escribir `01-01` sería fabricar
  datos que no existen. **Sin verificar** si Pegasus acepta `release:
  YYYY` sin mes/día — ver Riesgos.
- **`genre` queda sin poblar** — `-listxml` no lo trae (viene de
  `catver.ini`, archivo aparte, fuera de alcance). Cae en el default ya
  establecido en `CONVENCION.md` ("Sin Información").
- **Falla explícito ante 0 o >1 máquinas jugables** — decidido
  explícitamente en la sesión, mismo criterio que `doctor`/`synopsis`.

## Riesgos — varios sin verificar, honesto sobre eso

Este sandbox no tiene `mame` instalado. Todo lo de abajo es hipótesis
razonable sobre el formato de `-listxml`, no evidencia:

- **Forma exacta del XML** — se asume `<machine name="..."><description>
  ...</description><year>...</year><manufacturer>...</manufacturer>
  </machine>`, conocimiento general del esquema de MAME, no verificado
  contra el binario real en esta sesión.
- **DOCTYPE interno en el XML de `-listxml`** — MAME históricamente
  emite un `<!DOCTYPE mame [...]>` con subset interno antes del `<mame>`
  raíz. `ElementTree.fromstring` debería poder parsearlo (es DTD interno,
  no pide nada externo), pero no está confirmado en este sandbox.
- **Formato de `release:` que acepta Pegasus** — si exige `YYYY-MM-DD`
  completo y rechaza `YYYY` solo, hay que revisar esta decisión (¿omitir
  `release:` del todo si no hay mes/día, en vez de escribir un año pelado
  que Pegasus rechace?).

**Mitigación:** `tasks.md` tiene una verificación explícita, "bien dummy",
para correr en tu Mac contra un romset real antes de dar esto por cerrado
de verdad. Si algo no coincide, se ajusta `ingest.py` — no es una ADR
todavía porque no hay alternativas reales en juego, es simplemente
"corregir contra evidencia", como pasó con `magazine.json` (ADR-0008 →
0010).
