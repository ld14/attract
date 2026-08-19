# 012 · Manual en PDF — Tareas

_Checklist accionable derivada del `plan.md`. Tareas pequeñas y concretas;
marca `[x]` al completarlas._

## 0 · Verificación bloqueante

> Ninguna tarea de las secciones siguientes arranca sin esto. Si el resultado es
> negativo, se salta directo a §Cierre: se archiva el experimento y ADR-0021
> documenta el "no se puede".

- [x] Escribir `themes/experimentos/abrir-url-externa.qml`. Hecho cuando: mide
      los cinco casos y no tiene ninguna ruta absoluta adentro.
- [x] Correrlo contra Pegasus real en **macOS**. Existe y abre; ruta inexistente
      da `false` (hay canal de error); el visor abre **por delante** pero Pegasus
      **pierde el foco**.
- [ ] Correrlo contra Pegasus real en el **gabinete Windows**. Hecho cuando: lo
      mismo, anotado aparte — `ShellExecuteW` no es `LSOpenCFURLRef` y ADR-0003
      no permite dar por buena una sola corrida.
- [x] Decidir con la evidencia: **`encodeURIComponent`**. Las dos formas abren en
      macOS, así que se elige la codificada por canónica; revisar si Windows la
      rechaza.
- [x] Pasar ADR-0021 a `accepted`, con el foco perdido anotado en §Coste asumido.

## 1 · Contrato y validación

- [ ] `src/attract/doctor.py` — validar `manual.file` en `chk_data_contrato`.
      Hecho cuando: string no vacío, termina en `.pdf`, sin `/ \ ..`, y existe en
      `_manual/`; y `manual` con `file` y sin `pages` pasa. Depende de: §0.
- [ ] `fixtures/arcade/media/sf2ce/_manual/manual.pdf` de **0 bytes** + su línea
      en `fixtures/arcade/media/sf2ce/data.json`. Hecho cuando: `make doctor`
      sigue verde. (Política de fixtures vacíos: para validar estructura no hace
      falta un PDF real. El PDF real para mirar el theme va en `library/`, que
      no se versiona.)

## 2 · Theme

- [ ] `themes/attract/core/Paths.qml` — `manualPdfDe(game, nombre)` y la función
      que llama a `Qt.openUrlExternally`. Hecho cuando: devuelve `""` sin base o
      sin nombre, y el comentario explica el `encodeURIComponent` al estilo de
      las "tres trampas" del encabezado. Depende de: §0.
- [ ] `themes/attract/core/GameData.qml` — `hayManualPaginas` / `hayManualPdf` /
      `hayManual`. Hecho cuando: un juego con solo `pages` se comporta
      exactamente igual que antes del cambio.
- [ ] `themes/attract/core/DocModel.qml` — campo `pdf` en `desdeManual`, `""` en
      `desdeRevista`. Hecho cuando: el visor sigue sin preguntar de qué tipo es.
- [ ] `themes/attract/screens/ExtrasList.qml` — subtítulo `"12 págs"` / `"PDF"` /
      `"12 págs · PDF"`. Hecho cuando: sin `pages` ni `file` sigue diciendo
      `"No Disponible"` y la tarjeta no se abre.
- [ ] `themes/attract/theme.qml` — `onAbrirExtra`: con páginas, el visor; solo
      PDF, el launcher. Hecho cuando: es el único `if` que decide entre los dos.
- [ ] `themes/attract/overlays/DocumentViewer.qml` — botón + `isDetails` +
      leyenda, **solo** cuando el modelo trae `pdf`. Hecho cuando: en una revista
      no aparece nada nuevo y la leyenda no nombra una tecla que no hace nada.
- [ ] `themes/attract/overlays/LaunchOverlay.qml` — `titulo` / `subtitulo` /
      `modo` opcionales. Hecho cuando: el lanzamiento de un juego se ve idéntico
      a hoy sin pasarle ninguna propiedad nueva.
- [ ] Cablear el flujo completo: tarjeta → `manual.file` → `Paths.manualPdfDe` →
      `Qt.openUrlExternally` → PDF abierto, o overlay de error.

## Tests

- [ ] Caso feliz: `manual` con `pages` y `file` reales → `doctor` verde.
- [ ] Caso feliz: `manual` con `file` y **sin** `pages` → `doctor` verde.
- [ ] Caso límite: `manual` vacío (ni `pages` ni `file`) → error.
- [ ] Caso de fallo: `file` que no existe en `_manual/` → error explícito.
- [ ] Caso de fallo: `file` con `../` → error.
- [ ] Caso de fallo: `file` con `/` o `\` → error.
- [ ] Caso de fallo: `file` sin extensión `.pdf` → error.
- [ ] Invariante: un `data.json` con solo `pages` produce exactamente el mismo
      reporte que antes de esta feature.
- [ ] `make test` verde (72 + los nuevos).

## QA contra Pegasus real

- [ ] `sf2ce` (pages + file): A abre el visor como hoy, X abre el PDF afuera.
- [ ] Un juego solo-PDF: la tarjeta dice `PDF` y A lo abre sin pasar por el visor.
- [ ] `mok` (ni uno ni otro): `"No Disponible"`, tarjeta inerte. **Si solo anda
      con Striker, no anda** (`spec/constitution/mission.md`).
- [ ] Nombre con espacios y acentos: abre.
- [ ] Borrar el PDF dejando el `file` declarado → overlay de error, Pegasus vivo,
      se cierra con B/ESC.
- [ ] Cerrar el visor de PDF no cierra Pegasus.
- [ ] Repetir todo lo anterior en el **gabinete Windows**.

## Cierre

- [ ] Validar contra todos los criterios de aceptación de `spec.md`.
- [ ] Actualizar `spec/decisions/README.md` (índice y conteo).
- [ ] Actualizar `spec/constitution/tech-stack.md` §Límites duros: el matiz de
      que ADR-0007 prohíbe *renderizar* PDF y ADR-0021 permite *entregarlo* al
      SO. Sin ese matiz escrito, la próxima sesión va a leer "nunca PDF" y
      borrar esto.
- [ ] Actualizar `docs/CONVENCION.md`, fila `manual`.
- [ ] Actualizar `docs/plataforma-pegasus.md` con lo que midió la Fase 0 — es el
      registro de hechos verificados de la plataforma, y `Qt.openUrlExternally`
      pasa a ser uno.
- [ ] Mover la feature a "Hecho" en `spec/constitution/roadmap.md`.
