# 023 · Plan

1. Extraer normalización y coincidencia a `core/Search.js`, compatible con Qt 5.15.
2. Catalog indexa los campos una vez y devuelve juegos coincidentes por título.
3. SearchOverlay usa TextInput, ListView y tokens existentes. Consume los eventos
   del teclado dentro del modal para aislarlos de Home y Pegasus. Esc y Enter
   se tratan explícitamente porque las letras del perfil local son texto.
4. theme.qml coordina el modal y el regreso desde detalle sin modificar Home.
5. Verificar lógica con Node, diff y copia instalada con respaldo. La validación
   de foco y render requiere Pegasus real.

## Ajuste de leyenda

Quitar únicamente la entrada Buscar del modelo de Leyenda en BrowseScreen.
