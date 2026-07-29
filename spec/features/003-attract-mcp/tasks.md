# 003 · Servidor MCP de ATTRACT — Tareas

_Checklist accionable derivada del `plan.md`._

## Implementación

- [x] `src/attract/mcp_server.py::_run_doctor` — wrapea `doctor.revisar()`
      a dict. Hecho cuando: `_run_doctor(str(FIXTURES))` devuelve `ok`,
      `errores`, `avisos` correctos contra `fixtures/arcade`.
- [x] `src/attract/mcp_server.py::_run_synopsis` — wrapea
      `synopsis.leer_fuente()` + `aplicar()`, atrapa `SynopsisError`.
      Hecho cuando: caso feliz escribe `metadata.pegasus.txt`, caso sin
      fuente devuelve `{"ok": False, "error": ...}` sin excepción.
- [x] `src/attract/mcp_server.py::_construir_app` — import perezoso de
      `mcp.server.mcpserver.MCPServer`, registra `attract_doctor` y
      `attract_synopsis`. Hecho cuando: `list_tools()` devuelve las dos,
      sin bloquear en stdio.
- [x] `src/attract/mcp_server.py::main` — construye la app, atrapa
      `ImportError` con mensaje explícito, corre `app.run()`.
- [x] `src/attract/cli.py` — agregado `"mcp": mcp_server.main` a
      `COMANDOS` y al texto de `--help`.

## Tests (`tests/test_mcp_server.py`) — 9 tests

- [x] Aislamiento: `doctor`/`synopsis`/`cli`/`mcp_server` importan sin
      excepción con `mcp` bloqueado vía `sys.modules` (subprocess aparte,
      no contamina el resto de la suite).
      (`test_modulos_importan_sin_mcp_instalado`)
- [x] `mcp_server.main()` sin el paquete da mensaje explícito, no
      traceback crudo. (`test_mcp_main_sin_paquete_dice_como_instalarlo`)
- [x] `cli.COMANDOS` incluye `"mcp"` sin necesitar el paquete instalado
      para existir como entrada. (`test_cli_tiene_el_comando_mcp_registrado`)
- [x] `_run_doctor` devuelve dict estructurado, incluye el aviso esperado
      de `mags-ref-faltante`. (`test_run_doctor_devuelve_dict_estructurado`)
- [x] `_run_synopsis` caso feliz escribe el archivo de verdad.
      (`test_run_synopsis_caso_feliz`)
- [x] `_run_synopsis` sin fuente y sin `metadata.pegasus.txt` no rompen,
      devuelven `ok=False` explícito.
      (`test_run_synopsis_sin_fuente_no_rompe`,
      `test_run_synopsis_sin_metadata_pegasus_txt`)
- [x] Registro de tools contra el SDK real, con
      `pytest.importorskip("mcp")` — se salta solo si `mcp` no está
      instalado. (`test_construir_app_registra_las_dos_tools`)
- [x] Roundtrip de protocolo MCP real: levanta `python -m attract.mcp_server`
      como subproceso real y le habla `initialize` → `list_tools` →
      `call_tool` (x2) con `ClientSession`/`stdio_client` del SDK oficial —
      no mockea nada, es el wire de verdad, cierra la brecha que dejaban
      los tests de arriba (llaman `_run_doctor`/`_run_synopsis` directo o
      registran tools en memoria, sin pasar por JSON-RPC).
      (`test_roundtrip_protocolo_real_via_stdio`, agregado 2026-07-29)

## Verificación pendiente

- [ ] **Cliente real de verdad (Claude Desktop / Claude Code)** — el
      roundtrip de arriba prueba el protocolo MCP hablado en serio (mismo
      wire, mismo SDK cliente-servidor), pero no reemplaza correr
      `attract mcp` colgado de un `mcp.json` real y ver las tools aparecer
      en la UI de un cliente de verdad. Eso sigue necesitando la máquina
      del autor — intentado en este sandbox (sin acceso root para instalar
      un cliente de escritorio), no se pudo cerrar acá.

## Cierre

- [x] Validar contra los criterios de aceptación de `spec.md` — los 5
      quedaron `[x]`.
- [x] `PYTHONPATH=src python3 -m pytest tests/ -q` en verde (49/49: 19
      `doctor` + 11 `synopsis` + 9 `mcp` + 10 `ingest`).
- [x] `attract doctor` sobre todo el repo en 0 errores después de agregar
      `mcp_server.py` y el skill.
- [x] `spec/constitution/tech-stack.md` actualizado (§Límites duros
      enlaza ADR-0012).
- [x] `Makefile`/`docs/SETUP.md` documentan `pip install mcp` como paso
      opcional aparte de `make setup`.
- [x] Movido `003-attract-mcp` a "Hecho" en `../../constitution/roadmap.md`.
