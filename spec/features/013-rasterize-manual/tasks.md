# 013 · `attract rasterize` — Tareas

_Checklist accionable derivada del `plan.md`. Tareas pequeñas y concretas;
marca `[x]` al completarlas._

## Implementación

- [x] `src/attract/rasterize.py` — `nombres(total, ext)`. 9 páginas dan
      `p001…p009`, 1000 dan `p0001…`, y `sorted(n) == n` para todos los totales
      probados.
- [x] `src/attract/rasterize.py` — `paginas_a_data(datos, pages)`. Reemplaza
      `manual.pages`, conserva `manual.file` y todas las demás claves, y no muta
      la entrada.
- [x] `src/attract/rasterize.py` — `_render(pdf, destino, dpi)` con
      **`import pymupdf` adentro de la función**. Sin el paquete, el error dice
      `pip install pymupdf`. **Ojo: es `pymupdf`, no `fitz`** — el alias `fitz`
      está deprecado y avisa por stderr al importarlo (medido con 1.28.2).
- [x] `src/attract/rasterize.py` — `aplicar(media_dir, dpi, force)`: resuelve
      rutas, exige `manual.file`, renderiza a temporal, mueve, reescribe el JSON.
- [x] Flags `--dpi` (default 150) y `--force`. Sin `--force` y con páginas
      presentes no toca nada y lo explica.
- [x] `src/attract/cli.py` — entrada en `COMANDOS` y línea de `--help`, sin
      importar `pymupdf` al tope.
- [x] Reusar el estilo de `synopsis.py` (excepción propia, `main(argv) -> int`,
      `error:` a stderr con exit 2) en vez de inventar una tercera forma.

## Tests

- [x] Caso feliz (`importorskip("pymupdf")`): un PDF de 3 páginas deja 3
      imágenes y `manual.pages` con los 3 nombres en orden.
- [x] `nombres()`: padding a 3 y a 4 dígitos; orden alfabético == orden real.
- [x] `paginas_a_data()`: `accent`, `accent2`, `mags`, `cheats`, `review` y
      `manual.file` idénticos antes y después. **Este es el test que importa**:
      el modo de falla temido no es un JSON roto, es una clave que desaparece en
      silencio.
- [x] Idempotencia: dos corridas dejan el mismo `data.json`.
- [x] `--force` borra las páginas sobrantes de una corrida anterior más larga.
- [x] Caso límite: `manual` sin `file` → error que nombra `manual.file`.
- [x] Caso límite: sin `data.json`, y `data.json` roto → error explicado.
- [x] Caso de fallo: PDF ilegible → no queda ninguna imagen ni un `data.json`
      modificado.
- [x] Sin `--force` y con `_manual/` ya poblado → no pisa, avisa, exit code 0.
- [x] Integración: lo que el comando escribe pasa `attract doctor`.
- [x] **Aislamiento de la dependencia**: subproceso que bloquea `pymupdf` en
      `sys.modules` e importa `doctor`, `synopsis`, `ingest`, `cli` y
      `rasterize`. Mismo patrón que el que ya existe para `mcp`.
- [x] `make test` verde: **114 passed, 2 skipped**.

## Cierre

- [x] Validar contra todos los criterios de aceptación de `spec.md`.
- [x] `spec/constitution/tech-stack.md` §Límites duros: **segunda** excepción al
      stdlib-only, con la regla de que una tercera significa reescribir el
      límite, no parchearlo otra vez.
- [x] `docs/SETUP.md`: `pip install pymupdf` como paso opcional, al lado de `mcp`.
- [x] Pasar ADR-0022 a `accepted` y actualizar `spec/decisions/README.md`.
- [ ] Rasterizar un manual real en `library/` y **mirarlo en Pegasus**: que el
      visor lo hojee, que a 2.4× se lea, y que `X` siga abriendo el PDF original.
- [ ] Probar `pip install pymupdf` en el **gabinete Windows** — verificación
      pendiente de ADR-0022. El wheel es `cp310-abi3`, así que es muy probable
      que ande, no seguro.
- [ ] Ajustar el default de `--dpi` con lo que se vea en el gabinete.
- [ ] Mover las features 012 y 013 a "Hecho" en `spec/constitution/roadmap.md`.
