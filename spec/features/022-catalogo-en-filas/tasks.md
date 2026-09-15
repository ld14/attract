# 022 · Tareas

- [x] Proyección de filas y pruebas de límites.
- [x] Integración del layout, foco y filtros.
- [x] Verificación de diff y geometría.
- [ ] Verificación visual en Pegasus: varias filas, última incompleta,
  cambio de ancho, filtros, favoritos, vuelta desde detalle y rueda del mouse.

## Evidencia

`node tests/test_catalog_rows.cjs`: 4 pruebas correctas, incluyendo 1200 juegos,
límites exactos de ancho, catálogo vacío y conservación de identidad al cambiar
columnas. `git diff --check` sin errores. Sin dependencias nuevas.

No se dispone de control gráfico nativo ni de qmlscene/qmllint en este entorno;
la interacción de foco y el renderizado final en Pegasus quedan pendientes.

## Corrección tras la captura del usuario

- La captura confirma siete columnas y salto de fila, pero la segunda fila
  seleccionada queda debajo del pie: la validación visual anterior no cubría esto.
- Se reemplazó el rango de highlight por posicionamiento explícito con Contain
  tras resolver el layout. Se aplica al navegar, reconstruir y cambiar de altura.
- Las cuatro pruebas de datos siguen pasando; no validan el scroll de Qt.
- Corrección copiada al theme instalado y hash verificado. Pendiente volver a
  abrir Pegasus y comprobar arriba/abajo con la segunda fila completamente visible.
