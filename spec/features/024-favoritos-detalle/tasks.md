# 024 · Tareas

- [x] Control, navegación e integración con Catalog.
- [x] Pruebas de marcar, quitar, último favorito y conservación de filtros.
- [x] Instalar con respaldo y verificar hashes (tres archivos coinciden).
- [ ] Verificar visualmente y comprobar persistencia al reiniciar Pegasus.

## Evidencia

node tests/test_favorites.cjs: tres pruebas correctas contra las funciones reales
de Catalog.qml (marcar, quitar último, preservar filtros y juego nulo).
git diff --check correcto. Sin herramientas de GUI nativa/qmlscene en el entorno;
la verificación de render y persistencia sigue pendiente.
