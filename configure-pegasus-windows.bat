@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\configure-pegasus-windows.ps1" %*
if errorlevel 1 (
  echo.
  echo La configuracion fallo. Revisa el mensaje anterior.
  pause
  exit /b 1
)
endlocal
