# 013 · `attract rasterize` — Plan

_Cómo se implementa lo descrito en `spec.md`. Debe respetar la `constitution/`._

## Enfoque

El módulo se parte en dos mitades con una frontera dura, y esa frontera es la
decisión de diseño principal: **una mitad pura, en stdlib, que decide los
nombres y arma el `data.json` nuevo; y una llamada a PyMuPDF que solo escribe
píxeles.** Todo lo que puede tener un bug —el zero-padding, el orden, no pisar
las otras claves del JSON, la idempotencia— vive del lado puro y se testea sin
instalar nada. PyMuPDF entra por una sola función, con import perezoso.

Esa partición es lo que hace que la suite siga corriendo en una máquina limpia:
un solo test se salta con `importorskip`, el resto no.

Se escribe **primero a temporal y se mueve al final**, para que un PDF corrupto
a la página 40 no deje 39 imágenes sueltas y un `data.json` mintiendo.

## Implementación

1. `src/attract/rasterize.py` — el módulo nuevo. Cuatro piezas:
   - `nombres(total, ext)` — **pura**. `["p001.png", …]` con el ancho de padding
     que haga falta (3 dígitos hasta 999, 4 desde 1000). Es lo que garantiza que
     el orden alfabético sea el orden real (ADR-0007).
   - `paginas_a_data(datos, nombres)` — **pura**. Devuelve el dict con
     `manual.pages` reemplazado y **todo lo demás intacto**, incluido
     `manual.file`. No escribe disco.
   - `_render(pdf, destino, dpi)` — la única que importa `pymupdf`, **adentro de
     la función**. Devuelve los nombres que escribió. **Es `import pymupdf`, no
     `import fitz`**: el alias `fitz` está deprecado y avisa por stderr al
     importarlo (medido con 1.28.2, 2026-08-09).
   - `main(argv)` — resuelve rutas, orquesta, imprime, devuelve el exit code.
2. `src/attract/cli.py` — una línea más en `COMANDOS` y una en el `--help`. **No
   se importa `pymupdf` acá**, igual que con `mcp` (ADR-0012).
3. `src/attract/doctor.py` — sin cambios. `chk_data_contrato` ya valida
   `manual.pages` y `manual.file` desde la feature 012.
4. `tests/test_rasterize.py` — la mayoría sin dependencia; una sola con
   `pytest.importorskip("pymupdf")`.
5. `Makefile` — sin cambios en `setup`. Se documenta `pip install pymupdf` como
   paso aparte.

Reutiliza, sin reimplementar: la resolución de `media/<set>/` y la lectura de
`data.json` ya existen en `doctor.py` e `ingest.py` — hay que mirar cuál de las
dos formas es la del proyecto y seguir esa, no inventar una tercera.

## Decisiones

- **PyMuPDF opcional con import perezoso, en vez de `pdftoppm` o rasterizar a
  mano** — un wheel sin librerías de sistema contra un binario que hay que
  instalar y versionar en las dos máquinas.
  Ver [`ADR 0022`](../../decisions/0022-rasterizar-pdf-a-paginas.md).
- **El comando escribe `manual.pages` en `data.json`** — la alternativa (que el
  humano pegue 200 nombres) es el mismo trabajo que el comando venía a eliminar.
  Se acota a esa única clave y se declara que pasa a ser derivada (ADR-0022).
- **La entrada es `manual.file`, no un argumento de ruta** — el contrato de la
  feature 012 alimenta a esta. Un solo campo para las dos cosas, y `doctor` ya lo
  valida.
- **El PDF no se borra** — queda como fallback de 012 y como la única versión con
  texto seleccionable.
- **Escribir a temporal y mover al final** — media corrida es peor que ninguna:
  dejaría `doctor` en rojo y el visor con huecos.
- **`--dpi` es un parámetro con default, no una constante** — el número correcto
  se ve en el gabinete a 2.4× de zoom, no en el editor.
- **Sin `--force` no se pisa nada** — rasterizar es caro y destructivo sobre lo
  que ya estaba; que el default sea seguro.

## Riesgos

- **PyMuPDF no instala en el gabinete Windows** — se mitiga probándolo ahí antes
  de dar la feature por cerrada. Si ocurre, la salida es rasterizar solo en el
  Mac y copiar las imágenes, que es lo que ya pasa con el resto de `library/`.
- **Peso en disco** — un manual largo a 150 DPI son cientos de MB. Se mitiga con
  `--dpi`. Si igual molesta, la salida es JPEG, no bajar resolución.
- **`data.json` se corrompe al reescribirlo** — se mitiga con la función pura
  testeada (`paginas_a_data`) y escribiendo a temporal. El riesgo real no es el
  JSON inválido sino perder una clave en silencio: hay un test que compara todas
  las demás claves antes y después.
- **La dependencia se filtra a un módulo stdlib-only** — se mitiga con un test
  explícito que importa `doctor`, `synopsis` e `ingest` y falla si alguno arrastra
  `pymupdf`, igual que el que ya existe para `mcp`.
- **150 DPI se ve mal en el gabinete** — no se sabe hasta mirarlo. Es una
  verificación pendiente de ADR-0022, no un bug a prevenir.
