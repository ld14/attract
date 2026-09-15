# 024 · Favoritos desde el detalle

Debajo de Nota de la crítica aparece un control para marcar o quitar el juego
de Favoritos. La estrella y el texto reflejan su estado actual.

## Criterios de aceptación

- Clic o D/Enter con el control seleccionado alterna el favorito una vez.
- El control integra el recorrido izquierda/derecha después de los extras.
- Home actualiza contador y lista sin reiniciar y conserva sus filtros.
- Quitar el último favorito deja un catálogo vacío válido.
- El estado usa `game.favorite`, persistido por Pegasus; no se edita su config.
- La opción sigue accesible con reseñas largas y también sin reseña.
- Funciona desde un detalle abierto por Home o por Buscar.
