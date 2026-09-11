# 021 · Plan

1. Migrar los lanzadores desde COINDOOR a la raíz de ATTRACT.
2. PowerShell resuelve ATTRACT por `$PSScriptRoot`; mantiene `-AttractPath`
   opcional, la biblioteca estándar Python y el subproceso `attract.instalar`.
3. Renombrar el lanzador WSL a `install-coindoor-wsl.sh` para conservar
   `install-coindoor.sh` de Mac sin cambios. Convertir rutas con `wslpath`.
4. Migrar documentación y retirar la feature 011 de COINDOOR. La regla LF
   existente en ATTRACT ya cubre los scripts.
5. Verificar resolución del instalador y errores desde WSL; conservar evidencia
   de la instalación temporal de Elvira y comparar hash del script Mac.

6. Reparar la cabecera dentro del merge transaccional de `attract.instalar`;
   agregar la comprobación de colección a `doctor.chk_metadata`.
7. Limitar el registro histórico de macOS a ese sistema operativo. En Windows,
   usar el configurador explícito, que cierra Pegasus antes de editar su config.
8. Agregar un wrapper WSL de configuración y `-LibraryRoot` en PowerShell;
   imprimir el siguiente comando tras importar, también para destinos externos.
9. Probar regresión de cabecera ausente/vacía, preservación e idempotencia,
   rechazo en configuradores y ejecución WSL con rutas con espacios.
