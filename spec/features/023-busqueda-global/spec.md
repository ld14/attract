# 023 · Búsqueda global por teclado

## Comportamiento

B o el botón Buscar abre un panel con entrada enfocada y resultados en vivo.
Busca en toda la biblioteca por título, género, desarrolladora, editora,
plataforma/colección y año conocido. Los campos disponibles se explican en el panel.
Cada palabra debe aparecer en alguno de esos campos, como fragmento, sin
distinguir mayúsculas ni tildes. No hay selector de campo ni búsqueda aproximada.
Una consulta vacía invita a escribir. Cero coincidencias muestra un mensaje.

## Aceptación

- Letras B/C/D/X y espacios se escriben; Backspace edita, nunca vuelve.
- Flechas arriba/abajo eligen resultado; Enter abre su detalle; Esc cierra.
- Al volver del detalle reaparecen la consulta y la selección.
- Cerrar recupera Home con su selección, orden y filtros anteriores.
- Los datos ausentes no producen coincidencias ficticias (año 0 incluido).
- No se leen assets ni JSON adicionales, ni se instalan dependencias.
