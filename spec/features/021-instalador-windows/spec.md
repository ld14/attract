# 021 · Instalador Windows y lanzador WSL

## Alcance

Lanzadores para `attract.instalar` alojados en ATTRACT. Migrados desde COINDOOR
por pedido del usuario. No implementan el contrato ni escriben metadata.

## Criterios de aceptación

- `install-coindoor.ps1` funciona en Windows PowerShell 5.1 sin `unzip`.
- Usa el código de ATTRACT ubicado junto al script por defecto.
- `install-coindoor-wsl.sh` recibe rutas Linux y ejecuta todo en la consola WSL.
- ZIP y raíz aceptan espacios; raíz por defecto `.` respecto a la invocación.
- Lista el ZIP, delega la instalación y propaga errores; verifica `file:`.
- El original Mac `install-coindoor.sh` permanece intacto.
- No quedan los lanzadores ni su feature en COINDOOR.

## Correcciones verificadas con Elvira (2026-09-11)

- Reimportar sobre metadata sin cabecera restaura `collection:` desde `system`,
  conserva los demás juegos y no duplica una colección válida.
- `doctor` rechaza juegos sin una colección declarada antes del primer `game:`.
- Windows no escribe el registro de colecciones en una ruta de macOS.
  El lanzador indica el paso de configuración y reinicio de Pegasus.
- WSL tiene `configure-pegasus-wsl.sh [raíz de librería]`: convierte rutas Linux
  y delega en PowerShell. Los `.bat` se reservan para Windows.
- Los configuradores rechazan metadata con juegos sin colección antes de escribir.
