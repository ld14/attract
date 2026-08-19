---
id: 0022
title: "attract rasterize convierte el PDF del manual a páginas, con PyMuPDF como dependencia opcional acotada"
status: accepted
date: "2026-08-09"
supersedes: null
superseded-by: null
tags: [backend, data, frontend]
---

# 0022 — Rasterizar el PDF del manual dentro de ATTRACT

## Contexto

[`ADR-0021`](0021-manual-pdf-app-del-sistema.md) resolvió abrir el PDF del
manual con la aplicación del sistema, y la medición contra Pegasus real dejó un
coste que no se puede pagar desde el theme: **el visor abre por delante y
Pegasus pierde el foco**, sin ninguna API para recuperarlo. En el gabinete, que
tiene solo joystick, eso es un viaje de ida.

La pregunta que sigue es la obvia: *¿no se puede abrir en un modal, sin salir de
Pegasus?* Y la respuesta tiene dos mitades:

- **Como PDF, no.** [`ADR-0007`](0007-paginas-revista-imagenes-no-pdf.md) lo
  midió: `import QtQuick.Pdf` ni siquiera deja cargar el theme, y no hay
  `QtWebEngine` ni `QtWebView` en los binarios de Pegasus. Eso no se reabre.
- **Como imágenes, sí, y ya está construido.** `overlays/DocumentViewer.qml` es
  exactamente ese modal: pantalla completa dentro de Pegasus, con zoom, paneo y
  miniaturas. Consume `manual.pages[]`
  ([`ADR-0014`](0014-manual-digitalizado.md)) y funciona desde la feature 006.

O sea que no falta un visor: **falta que alguien genere las páginas**. Hoy eso
es trabajo manual, un coste que ADR-0014 asumió explícitamente y que
[`ADR-0009`](0009-frontera-produccion-consumo-revistas.md) puso del lado del
humano. La consecuencia práctica es que un manual sin rasterizar no se puede
leer adentro de Pegasus, aunque el PDF esté ahí al lado de la carátula.

Lo que fuerza a decidir ahora: automatizar ese paso es lo único que hace que el
manual **nunca** tenga que salir de Pegasus, y por lo tanto es la solución real
al foco perdido de ADR-0021, no un parche.

El obstáculo es concreto y ya se midió en esta máquina: **macOS no trae ninguna
herramienta CLI que rasterice un PDF multipágina.** `qlmanage` y `sips` existen
pero solo hacen una miniatura de la primera página. `pdftoppm`, `mutool` y `gs`
no están instalados y exigirían instalar binarios de sistema en las dos
máquinas. No hay camino stdlib-only.

## Decisión

Se agrega el subcomando **`attract rasterize`**, que convierte el PDF declarado
en `manual.file` a las páginas de `manual.pages[]`, en la misma carpeta:

```
media/<set>/_manual/
├─ manual.pdf        ← entrada (manual.file, ADR-0021)
├─ p001.png          ← salida
├─ p002.png
└─ …
```

Usa **PyMuPDF** (`pip install pymupdf`) como **dependencia opcional y acotada**,
siguiendo al pie de la letra el patrón que [`ADR-0012`](0012-mcp-dependencia-opcional-acotada.md)
estableció para `mcp`:

- `src/attract/rasterize.py` es el único lugar del proyecto que la importa, y lo
  hace con **import perezoso** dentro de la función. Si el paquete falta, el
  error lo dice explícito (`pip install pymupdf`), no un `ModuleNotFoundError`
  crudo.
- Se importa como **`import pymupdf`, no `import fitz`**. Medido con 1.28.2 el
  2026-08-09: el alias histórico `fitz` está deprecado y escribe un warning por
  stderr al importarlo. En un comando cuya salida se lee en una terminal, eso es
  ruido que aparece sin que nadie lo haya pedido.
- `cli.py` no la importa al tope. `doctor`, `synopsis` e `ingest` siguen sin
  instalar nada.
- `make setup` **no** la instala.

**El límite duro no se descarta, se acota otra vez** — y esto es deliberado: es
la segunda excepción, no una puerta abierta. Sigue valiendo entero para
`doctor`, `synopsis`, `ingest` y el entry point base.

**El comando escribe `manual.pages` en el `data.json` del juego.** Es la parte
incómoda de esta decisión y se declara en vez de esconderse: `data.json` es
fuente escrita a mano (ADR-0013), y a partir de acá una de sus claves pasa a ser
**derivada**. Se acota así: `rasterize` toca **únicamente** `manual.pages`, deja
`accent`, `mags`, `cheats`, `review` y `manual.file` exactamente como estaban, y
es idempotente — correrlo dos veces da el mismo archivo.

**`manual.file` no se borra.** El PDF queda, y ADR-0021 queda como **fallback**:
sirve para un manual que todavía no se rasterizó, y para leer el PDF original —
con su texto seleccionable, que una imagen plana no tiene— cuando alguien lo
quiera de verdad.

La resolución es un **parámetro con default, no una constante**: `--dpi 150`. La
hoja del visor mide 540×760 y llega a 2.4× de zoom, o sea ~1300×1824 píxeles
útiles; 150 DPI sobre una página carta da 1275×1650, que es del orden correcto.
El número exacto se ajusta mirando el gabinete, que es donde se ve.

## Alternativas consideradas

### A · Seguir rasterizando a mano

Lo que ADR-0014 asume hoy.

- A favor: cero dependencias, el límite duro queda intacto, y ADR-0009 ya puso
  la producción de escaneos del lado del humano.
- En contra: es el motivo por el que existe el problema. Un manual sin convertir
  no se puede leer adentro de Pegasus, y convertir 200 páginas a mano es
  suficiente fricción como para que no pase nunca. La regla de ADR-0001 —
  "enriquecimiento progresivo barato: agregar datos ricos tiene que costar lo
  mismo que agregar una carátula"— no se cumple para los manuales.
- **Descartada porque:** deja en pie el foco perdido de ADR-0021 como única
  forma de leer un manual, que es exactamente lo que se quiere evitar.

### B · `pdftoppm` (poppler) u otro binario de sistema, por `subprocess`

- A favor: **stdlib puro**, el límite duro no se toca. `subprocess` alcanza.
- En contra: hay que instalar poppler en **las dos** máquinas y mantener las
  versiones alineadas, que es exactamente el problema que ADR-0005 ya sufre con
  MAME. Peor: [`ADR-0018`](0018-launch-ruta-absoluta.md) midió que una app de GUI
  en macOS **no hereda el PATH del shell**, así que la ruta al binario habría que
  resolverla por máquina, igual que el emulador. Y no está instalado hoy en
  ninguna de las dos.
- **Descartada porque:** cambia una dependencia de Python declarada por una
  dependencia de sistema no declarada, que es más frágil y más difícil de
  reproducir en el gabinete. PyMuPDF es un wheel sin librerías de sistema, con
  binarios para Windows y macOS.

### C · Que el theme liste el directorio y arme `pages` solo

Así `data.json` no se tocaría.

- A favor: `data.json` sigue siendo 100% fuente escrita a mano.
- En contra: **el theme no puede listar un directorio.** Su única herramienta de
  disco es `XMLHttpRequest` sobre `file://` (ADR-0001), y `FolderListModel`
  necesita un `import` que no está verificado contra este binario — y un import
  que no resuelve tumba el theme entero (`docs/plataforma-pegasus.md` §1).
- **Descartada porque:** es técnicamente imposible con la plataforma medida, no
  una cuestión de preferencia.

### D · Imprimir el JSON y que el humano lo pegue

`rasterize` genera las imágenes y muestra el `pages[]` por pantalla.

- A favor: `data.json` no se escribe automáticamente; el humano sigue siendo el
  único autor.
- En contra: pegar 200 nombres de archivo a mano es el mismo trabajo tedioso que
  el comando venía a eliminar, con una fuente de error nueva (pegarlo mal).
- **Descartada porque:** conserva la pureza del archivo a cambio de no resolver
  el problema. Se prefiere escribir la clave y **declarar** que es derivada.

## Consecuencias

**Positivas**

- **El manual se lee sin salir de Pegasus.** El foco perdido de ADR-0021 deja de
  ser el camino normal y pasa a ser una opción.
- Se reusa el visor que ya existe y ya está verificado contra Pegasus real
  (feature 006). Cero UI nueva, cero contrato nuevo: `manual.pages[]` es el
  mismo de siempre.
- La entrada del comando es `manual.file`, o sea que el contrato de ADR-0021
  **alimenta** a este: un solo campo sirve para las dos cosas.
- Rasterizar un manual pasa a costar un comando, que es lo que ADR-0001 pide de
  cualquier enriquecimiento.

**Coste asumido**

- **Segunda dependencia externa del proyecto.** Opcional y con import perezoso,
  pero existe. Hay que vigilar que no se filtre a un módulo que debe seguir
  siendo stdlib-only — con un test explícito, igual que con `mcp`.
- **`data.json` deja de ser enteramente escrito a mano.** `manual.pages` pasa a
  ser derivado. Se acota a esa única clave, pero la propiedad "este archivo lo
  escribe una persona" ya no es cierta sin matices.
- **Peso en disco.** Un manual de 200 páginas a 150 DPI en PNG puede ocupar
  cientos de MB. `library/` no va a git, así que no afecta al repo, pero sí al
  gabinete. La salida si molesta es JPEG con calidad, no bajar la resolución.
- Rasterizar sigue siendo un paso explícito: nadie lo corre solo. Un manual con
  `file` y sin `pages` es un estado válido y esperable.

**Qué habría que revisar si esto se replantea**

- Que PyMuPDF cambie de licencia o deje de publicar wheels para Windows: ahí la
  alternativa B vuelve a la mesa con otro peso.
- Que el peso en disco haga inviable rasterizar los manuales largos — la salida
  es JPEG, o el patrón `"pages": "p###.png", "count": 200` que ADR-0014 ya dejó
  anotado como escape.
- Que aparezca una tercera dependencia opcional. Dos son excepciones acotadas;
  tres es que el límite duro ya no describe el proyecto y hay que reescribirlo
  en vez de seguir parchándolo.

## Verificaciones pendientes

- [x] **Confirmado 2026-08-09 en macOS** — `pip install pymupdf` trae
      `pymupdf-1.28.2-cp310-abi3-*.whl`. El `abi3` importa: es ABI estable, o sea
      que **un solo wheel sirve para cualquier Python ≥3.10**, incluido el 3.14
      de esta máquina, sin esperar a que publiquen uno nuevo por versión. Era el
      riesgo más concreto de esta decisión y queda descartado. Comando end-to-end
      verificado: 1 página, `--dpi 150` → 417×417, `--dpi 300` → 834×834, y
      `attract doctor` verde sobre el `data.json` resultante.
- [ ] Que PyMuPDF instale limpio en el gabinete Windows, no solo en el Mac. El
      wheel es `abi3`, así que es muy probable — no seguro.
- [ ] Mirar un manual rasterizado a 150 DPI en el gabinete y confirmar que a
      2.4× de zoom se lee. Si no, subir el default.

## Referencias

- [`ADR-0007`](0007-paginas-revista-imagenes-no-pdf.md) — por qué el PDF no se
  puede dibujar adentro del theme. **No se reabre.**
- [`ADR-0021`](0021-manual-pdf-app-del-sistema.md) — abrir el PDF afuera, y el
  foco perdido que motiva este ADR. Queda como fallback.
- [`ADR-0014`](0014-manual-digitalizado.md) — `manual.pages[]`, el contrato que
  este comando llena.
- [`ADR-0012`](0012-mcp-dependencia-opcional-acotada.md) — el patrón de
  dependencia opcional acotada que este ADR copia.
- [`ADR-0009`](0009-frontera-produccion-consumo-revistas.md) — la frontera
  productor/consumidor que esto mueve, para manuales y solo para manuales: las
  revistas las sigue escaneando un humano.
- `spec/features/013-rasterize-manual/` — la feature que lo implementa.
- `spec/constitution/tech-stack.md` §Límites duros — el límite que se acota.
