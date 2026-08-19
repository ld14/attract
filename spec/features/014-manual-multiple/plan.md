# 014 · Más de un manual por juego — Plan

_Cómo se implementa lo descrito en `spec.md`. Debe respetar la `constitution/`._

## Enfoque

`manual` pasa de objeto a lista, y **cada elemento de esa lista es exactamente
el `manual` de hoy** (mismas claves `pages`/`file`, misma validación) más un
`label` opcional. Eso significa que la mayor parte del código nuevo es "hacer
lo de siempre, una vez por elemento" — no un contrato distinto, un contrato
repetido.

La generalización de pestañas (`revistas` → `pestanas` en `DocumentViewer`) es
un rename con una condición nueva: hoy `theme.qml` es el único que decide qué
le pasa al visor, y sigue siéndolo — el visor no aprende a distinguir manual
de revista, solo dibuja lo que le dan, igual que hoy no sabe si el `DocModel`
es de un tipo o del otro.

## Implementación

1. `src/attract/doctor.py` — `chk_data_contrato`: `manual` pasa a validarse
   como **lista**. Cada elemento se valida con la lógica que hoy vive para el
   objeto (`pages`, `file`, con las mismas reglas de forma). Se agrega: si
   `len(manual) > 1`, cada elemento **debe** traer `label` (string no vacío).
   El caso viejo — `manual` como objeto suelto — pasa a ser **error explícito**
   ("`manual` tiene que ser una lista; ver ADR-0023"), no una interpretación
   silenciosa.
2. `fixtures/arcade/media/sf2ce/data.json` — se envuelve el `manual` existente
   en una lista de un elemento, sin `label`. Es el caso de "cero migración":
   sirve como fixture de regresión de que un elemento sin label sigue andando.
   Se agrega un **segundo** fixture (`mok` o uno nuevo) con dos documentos y
   `label`, para cubrir el caso múltiple en `doctor` y en Pegasus real.
3. `themes/attract/core/GameData.qml` — `manual` deja de ser el objeto crudo:
   pasa a exponer la lista tal cual llega (`manuales: []`), y `hayManual`,
   `hayManualPaginas`, `hayManualPdf`, `manualPaginas` se recalculan sobre el
   documento **activo** (índice elegido), no sobre "el" manual. `hayManual`
   seguirá siendo cierto si la lista tiene al menos un documento con contenido.
4. `themes/attract/core/DocModel.qml` — `desdeManual` recibe además el índice
   de documento activo, y arma su modelo (`pages`, `pdf`) a partir de
   `manuales[i]` en vez de `gameData.manual`.
5. `themes/attract/screens/ExtrasList.qml` — `_subManual()`: con un documento,
   sigue diciendo `"N págs"` / `"PDF"` / ambas, igual que hoy. Con más de uno,
   dice `"N manuales"` sin desglosar páginas — el desglose por documento pasa a
   vivir en las pestañas del visor, no en la tarjeta.
6. `themes/attract/overlays/DocumentViewer.qml` — rename `revistas` →
   `pestanas`, `revistaActual` → `pestanaActual`, señal `cambiarRevista` →
   `cambiarPestana`. El resto de la lógica (visible solo si `length > 1`, tira
   de botones) no cambia: ya era genérica, solo tenía nombre de dominio.
7. `themes/attract/theme.qml` — nuevo estado `manualIdx` (paralelo a `magIdx`),
   y `abrirManual()` arma `pestanas` a partir de los `label` de
   `detalle.datosDelJuego.manuales` cuando hay más de uno; con uno solo, pasa
   `[]` (sin fila de pestañas, como hoy). `onCambiarPestana` decide si está en
   modo revista o modo manual según cuál está activo, y reconstruye el
   `DocModel` correspondiente.
8. `src/attract/rasterize.py` — `pdf_declarado()` y `aplicar()` reciben un
   `label` opcional. Sin `label` y con un solo documento, funciona como hoy.
   Sin `label` y con más de uno, error explícito listando los labels
   disponibles. Con `label`, opera solo sobre ese elemento de la lista y
   reescribe solo su `pages`, dejando los demás documentos intactos — mismo
   criterio que `paginas_a_data` ya usa para no tocar `accent`/`cheats`/`review`.
9. `src/attract/cli.py` — `rasterize <set> [label] [ruta] [--dpi] [--force]`:
   el segundo posicional pasa a ser ambiguo entre "label" y "ruta". Se resuelve
   igual que ya resuelve `synopsis`: si el segundo posicional es un directorio
   existente, es `ruta`; si no, es `label`. Documentado en el `--help`.

## Decisiones

- **Lista de documentos, no un segundo campo `manuals`** — un elemento sin
  `label` es indistinguible del contrato de hoy, así que no hace falta migrar
  ningún `data.json` existente. Ver [`ADR 0023`](../../decisions/0023-manual-multiple-con-pestanas.md)
  alternativa C.
- **`label` a mano, no inferido del nombre de archivo** — "multivariado" quiere
  decir que no hay una convención que cubra todos los casos. Mismo argumento
  que ADR-0014 contra `x-manual`.
- **Se reusan las pestañas de revista, generalizadas por rename** — ya están
  construidas, probadas contra Pegasus real (feature 006), y el problema es el
  mismo: elegir entre varios documentos sin cerrar el visor. Nunca conviven
  pestañas de revista y de manual en pantalla a la vez, así que un solo prop
  alcanza.
- **La forma objeto vieja de `manual` pasa a ser error, no un caso soportado en
  paralelo** — dos formas válidas para lo mismo es una fuente de bugs futura;
  se prefiere un error claro con la migración de una línea (envolver en `[]`).
- **`rasterize` distingue label de ruta por si el argumento es un directorio
  existente** — evita agregar un flag (`--label`) para el caso común de un solo
  documento, que sigue sin necesitar nada nuevo en la línea de comandos.
- **Cada documento rasteriza a su propio subdirectorio (`_manual/manual-N/`)
  cuando hay más de uno** — no estaba en el diseño original: surgió al
  implementar, porque dos documentos con sus propias páginas `p001.png`
  colisionarían escribiendo el mismo archivo en el mismo `_manual/`. Con un
  solo documento sigue sin subcarpeta (cero migración para `sf2ce`/`goldnaxe`).
- **La puerta de entrada (`abrirManual()`) salta directo al PDF sin pasar por
  el visor SOLO cuando hay un único documento** — encontrado durante la
  implementación: si un juego con 2+ manuales declara primero uno solo-PDF,
  saltar directo lo dejaría sin forma de llegar a las pestañas de los demás.
  Con más de un documento, siempre entra al visor, aunque el activo no tenga
  páginas (se ve "Página no disponible", igual que una página individual rota).

## Riesgos

- **Ambigüedad label/ruta en `rasterize`** — se mitiga con la regla "si existe
  como directorio, es ruta" y un test que cubre un `label` que coincide por
  accidente con un nombre de carpeta relativo. Si molesta en la práctica, la
  salida es un flag explícito (`--label`), no ambigüedad heurística para
  siempre.
- **Migrar `sf2ce` y no probar el caso múltiple** — se mitiga agregando un
  segundo fixture con dos documentos desde el principio, no como demostración
  después.
- **El rename `revistas` → `pestanas` se filtra a medias** — se mitiga
  buscando todas las ocurrencias del nombre viejo antes de dar la tarea por
  cerrada (no es un contrato de datos, es interno, así que un grep alcanza —
  no hay `data.json` que dependa del nombre del prop).
- **Ancho de pestañas con muchos manuales** — no se resuelve acá (ADR-0023 lo
  deja como señal futura), pero se verifica que 2-3 documentos no rompan el
  layout de 1280px antes de cerrar la feature.
