# 014 · Más de un manual por juego — Tareas

_Checklist accionable derivada del `plan.md`. Tareas pequeñas y concretas;
marca `[x]` al completarlas._

## Contrato y validación

- [x] `src/attract/doctor.py` — `manual` se valida como **lista**. La forma
      objeto vieja da error explícito citando ADR-0023, no se interpreta.
      `sf2ce` migrado (lista de un elemento sin `label`) sigue en verde.
- [x] Cada elemento de la lista se valida con las reglas que tenía el objeto
      (`_chk_manual_doc`, factorizada). Con `len(manual) > 1`, cada elemento
      exige `label` no vacío y sin repetirse entre documentos.
- [x] `fixtures/arcade/media/sf2ce/data.json` — `manual` envuelto en `[...]`,
      sin `label`. `make doctor` verde.
- [x] Fixture nuevo con **dos** documentos: `dino` gana un segundo manual
      (`_manual/p001.png`, `p002.png`, `service.pdf`) — juego que ya tenía
      `mags`/`review`/`cheats`, así que confirma que el manual múltiple no
      choca con el resto del contrato.

## Theme

- [x] `themes/attract/core/GameData.qml` — `manuales: []`, `manualIdx`
      (reseteado en `cargar()`), `manualActivo`, `hayManual` sobre el JUEGO
      (algún documento con contenido), `hayManualPaginas`/`hayManualPdf` sobre
      el documento ACTIVO, `manualPestanas` para el visor.
- [x] `themes/attract/core/DocModel.qml` — `desdeManual` arma su modelo desde
      `manualActivo`; `fuente` (el label) solo se muestra con más de un
      documento.
- [x] `themes/attract/screens/ExtrasList.qml` — `"N manuales"` con más de uno;
      con uno, subtítulo sin cambios.
- [x] `themes/attract/overlays/DocumentViewer.qml` — rename `revistas` →
      `pestanas`, `revistaActual` → `pestanaActual`, `cambiarRevista` →
      `cambiarPestana`. `grep -rn "revistas\b\|cambiarRevista"` limpio.
- [x] `themes/attract/theme.qml` — `visorModo` ("revista"/"manual"/""),
      `pestanasActuales`/`pestanaIdxActual` derivados del modo,
      `cambiarPestanaVisor` despacha a `abrirRevista`/`abrirManualDoc`.

## Hallazgos de la implementación (no estaban en el plan original)

- [x] **Colisión de nombres entre documentos.** Dos manuales rasterizando los
      dos a `_manual/p001.png` se pisarían. Solución: `dir_documento()` — con
      un solo documento sigue en la raíz de `_manual/` (cero migración); con
      más de uno, cada uno a `_manual/manual-<índice>/`.
- [x] **La puerta de entrada no puede depender del orden de la lista.** Si
      `abrirManual()` saltaba directo al PDF apenas el documento activo no
      tenía páginas, un juego que declaró primero su manual de servicio
      (solo-PDF) quedaba sin forma de llegar a las pestañas del resto.
      Corregido: el salto directo solo ocurre con **un** documento; con más de
      uno, siempre entra al visor.

## CLI

- [x] `src/attract/rasterize.py` — `resolver_indice(datos, label)`: sin
      `label` y un documento, usa ese; sin `label` y varios, error listando
      labels; con `label`, busca el que coincide. `pdf_declarado`/`paginas_a_data`
      reciben el índice y tocan solo ese elemento de la lista.
- [x] `src/attract/cli.py` / `rasterize.py main()` — `<set> [label] [ruta]`
      con la regla "si el único extra es un directorio existente, es ruta; si
      no, es label"; con dos extra, `label` y `ruta` en ese orden.
- [x] Sin `label` y con más de un documento → error listando los labels
      disponibles, exit code 2.

## Tests

- [x] `resolver_indice`: un documento sin label, varios sin label (error con
      la lista), label que coincide, label que no existe, sin `manual`, forma
      objeto vieja.
- [x] `dir_documento`: un documento → raíz; varios → subcarpeta por índice.
- [x] `paginas_a_data`: no pierde ninguna clave del juego, **ni de los otros
      documentos de la lista** (label/file/pages ajenos intactos).
- [x] `pdf_declarado` por índice.
- [x] `aplicar`: dos documentos sin label → error; punta a punta con dos
      documentos reales (PyMuPDF) confirmando que **no colisionan** y que
      `doctor` los valida.
- [x] CLI: un argumento extra que es directorio → ruta; que no lo es → label
      (verificado indirectamente por dónde falla cada camino).
- [x] `doctor`: objeto suelto, lista vacía, un elemento no-dict, dos labels
      repetidos, dos sin label en alguno, caso feliz con y sin label.
- [x] `make test`: **136 passed, 2 skipped**.

## QA contra Pegasus real

- [ ] `sf2ce` (un documento, sin label): la tarjeta y el visor se ven
      exactamente igual que antes de esta feature.
- [ ] `dino` (dos documentos: uso con páginas, servicio solo-PDF): la tarjeta
      dice `"2 manuales"`, el visor abre directo (no salta al PDF), muestra
      pestañas, cambiar a "Manual de servicio" no cierra el visor y ofrece `X`
      para el PDF sin páginas propias.
- [ ] `X ABRIR PDF` aparece o no según el documento **activo** al cambiar de
      pestaña, no según el juego.
- [ ] Layout: dos pestañas no rompen el ancho fijo de 1280px.
- [ ] `goldnaxe` (librería real, migrado a lista de un elemento): sigue
      abriendo igual que antes de la 014.

## Cierre

- [x] Validar contra los criterios de aceptación de `spec.md` verificables sin
      Pegasus real (los de arriba quedan para QA visual).
- [x] Pasar ADR-0023 a `accepted`.
- [x] `spec/decisions/README.md` — índice actualizado.
- [x] `spec/constitution/tech-stack.md` — contrato de `manual` actualizado a
      lista, con el límite nuevo y el ejemplo de `data.json`.
- [ ] `docs/CONVENCION.md`, fila `manual` — no la toca Claude, avisar que
      quedó desactualizada.
- [ ] Mover la feature a "Hecho" en `spec/constitution/roadmap.md` — junto con
      QA visual pendiente en Pegasus real.
