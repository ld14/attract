# 024 · Plan

1. Catalog alterna la propiedad nativa y recarga sus claves para invalidar
   favoritos cacheados, contadores y estantes. Conserva pestaña, orden y filtro.
2. DetailScreen emite la intención hacia theme.qml; agrega botón y estado bajo
   ReviewCard, como séptimo destino del recorrido existente. Ignora autorepeat.
3. La columna derecha permite scroll si la reseña supera el espacio disponible;
   al enfocar Favoritos se revela el control.
4. Probar la alternancia y el filtrado con las funciones reales de Catalog en
   Node. Instalar los QML modificados con respaldo y hashes.

API nativa confirmada: [game.favorite es writable](https://pegasus-frontend.org/docs/themes/api/).
Render, foco y persistencia tras cerrar Pegasus requieren verificación real.
