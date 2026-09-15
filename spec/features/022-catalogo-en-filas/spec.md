# 022 · Catálogo en filas

El catálogo de Home respeta el ancho disponible y continúa en nuevas filas.

## Criterios de aceptación

- Tarjetas de 148 × 166, separación mínima de 16 y margen para el foco.
- Columnas calculadas a partir del ancho del catálogo; sin scroll horizontal.
- Un único scroll vertical para filas del catálogo y los demás estantes.
- Arriba/abajo conserva la columna cuando existe; una última fila incompleta
  permite alcanzar todos sus juegos. Arriba del primer estante vuelve a la barra.
- Al cambiar de fila, el scroll contiene la fila seleccionada completa en el
  espacio sobre el pie; no alcanza con que asome su borde superior.
- Orden, favoritos, filtros, hero y apertura de detalle siguen funcionando.
- Redimensionar mantiene el juego seleccionado dentro del catálogo.
- Solo se crean tarjetas de las filas visibles y del búfer de la lista.
- Los demás estantes conservan su presentación horizontal.
