# 021 · Tareas

- [x] Agregar y verificar lanzador WSL con rutas Linux y documentar su uso.

WSL: sintaxis Bash válida, conversión de rutas relativas y con espacios,
rechazo de ZIP ausente y propagación del error de paquete inválido.

- [x] Leer el script original y el instalador real de ATTRACT.
- [x] Escribir spec y plan.
- [x] Implementar lanzador Windows y documentar uso.
- [x] Validar instalación temporal, errores y conservación del script Mac.

Validación: Windows PowerShell 5.1, Python 3.14 y el ZIP real de Elvira;
instalación en raíz temporal con espacios y comprobación `file: OK` (salida 0).
ZIP ausente devuelve 1; paquete inválido propaga el 2 de ATTRACT.
SHA256 del script Mac sin cambios:
`D4ED011FABB9E8800D1341B48B3F8FBA5589ED9389BF20D7CFFA40603D900CD5`.

- [x] Migrar a ATTRACT y retirar los originales de COINDOOR.

## Correcciones de la instalación real

- [x] Reparar metadata sin colección dentro del importador y agregar regresiones.
- [x] Detectar juegos sin colección en doctor y en los configuradores.
- [x] Separar registro macOS de configuración Windows y documentar el reinicio.
- [x] Agregar y probar configuración desde WSL, incluyendo rutas con espacios.
- [x] Ejecutar tests, doctor y revisión del diff antes de commit y push.

Verificación del cierre: 228 tests (218 pasan, 10 omitidos por MAME, MCP o
PyMuPDF ausentes); PowerShell instala y repara un paquete sintético en una
librería temporal con espacios. Los wrappers preservan argumentos y errores
en Git Bash. Sintaxis validada en WSL y PowerShell invocado desde WSL con
`-WhatIf` detecta la configuración real y `library/msdos`. Doctor: librería
sin hallazgos; fixtures sin errores y con los dos avisos intencionales.
La comprobación con Finder/macOS real sigue pendiente en la feature 020.
