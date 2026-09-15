# 022 · Plan

1. Proyectar los estantes del catálogo en filas con un helper JavaScript puro.
   Cada fila referencia su estante original y el desplazamiento de sus juegos.
2. Reutilizar el ListView vertical de BrowseScreen: virtualiza las filas.
3. Shelf recibe si es continuación y el ancho de celda. Solo la primera fila
   lleva encabezado; las tarjetas mantienen tamaño y espacio para elevarse.
4. Traducir el índice original del catálogo al índice visual. Mantener columna
   al navegar y juego al cambiar el ancho.
5. Verificar geometría, partición y mapeos con Node; revisar diff y, si existe
   un entorno gráfico utilizable, validar también en Pegasus.

Decisión: [ADR-0031](../../decisions/0031-catalogo-en-filas.md).

## Corrección de visibilidad al navegar

La captura del usuario muestra el hero de la segunda fila, con su tarjeta
recortada debajo del viewport. Sustituir el rango de highlight implícito por
`positionViewAtIndex(currentIndex, ListView.Contain)` después del layout.
Ejecutarlo al cambiar de fila, reconstruir el modelo y cambiar la altura.
Dejar el desplazamiento manual libre: no reposicionar en cada cambio de contentY.
