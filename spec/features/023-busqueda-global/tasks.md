# 023 · Tareas

- [x] Índice y pruebas de campos, normalización, palabras y datos ausentes.
- [x] Panel, conexión de Buscar y regreso desde detalle.
- [x] Verificación y despliegue local con respaldo (cuatro hashes coinciden).
- [ ] Verificación visual e interacción en Pegasus real.

## Evidencia

node tests/test_search.cjs: 4 pruebas correctas.
node tests/test_catalog_rows.cjs: 4 pruebas correctas.
El runner node --test no puede crear subprocesos en el sandbox; ambas suites
se ejecutaron directamente, sin cambiar las pruebas. git diff --check correcto.
No hay qmlscene/qmllint ni control gráfico nativo disponibles; foco y render
quedan pendientes de comprobar en Pegasus.

- [x] Quitar Buscar del pie e instalar BrowseScreen con respaldo; diff y hash verificados.
