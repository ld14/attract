# Plan — 025

1. Añadir un resolvedor stdlib en src/attract/dosbox.py y un catálogo local
   de huellas/perfiles con fuentes en src/attract/dosbox_profiles.py.
2. Ampliar opcionalmente game.json con dosbox: executable, cpu_cycles,
   sbtype y sound_directory. No aceptar comandos libres ni rutas del host.
3. Validar y extraer el zip interior en temporal antes de escribir; reutilizar
   doctor para nombres Windows. Resolver el perfil sobre ese árbol.
4. Integrar configuración, informe y launch por juego en _Deshacer. El launch
   resuelve el emulador absoluto desde {file.path} y fija --working-dir.
5. Conservar configuración y launch locales en reimportaciones. Un paquete con
   dosbox.conf propio se conserva y se identifica como aportado, sin certificarlo.
6. Probar contratos con archivos sintéticos en tmp_path y una importación
   aislada de la copia real; no añadir ROMs al repositorio.

Decisión: ADR-0032. No sustituye al runtime MAME de arcade ni depende del PATH.
