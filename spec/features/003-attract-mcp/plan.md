# 003 · Servidor MCP de ATTRACT — Plan

_Cómo se implementa lo descrito en `spec.md`. Respeta `constitution/` y
[`ADR-0012`](../../decisions/0012-mcp-dependencia-opcional-acotada.md)._

## Enfoque

El SDK `mcp` (PyPI, versión 2.0.0 al momento de escribir esto — la API de
alto nivel es `mcp.server.mcpserver.MCPServer`, no
`mcp.server.fastmcp.FastMCP` como en versiones más viejas del SDK que
circulan en ejemplos; se verificó contra el paquete instalado, no contra
memoria) hace todo el trabajo de protocolo. El módulo nuevo solo registra
dos tools que llaman a las funciones que ya existen en `doctor.py` y
`synopsis.py` — cero lógica de negocio duplicada.

La única disciplina real de esta feature es el aislamiento: `mcp` se
importa **adentro de una función**, nunca al tope del módulo, para que
importar `attract.cli` (que ahora importa `attract.mcp_server` para
registrar el comando) no dispare una dependencia en cadena hacia el SDK.

## Implementación

1. `src/attract/mcp_server.py`:
   - `_run_doctor(ruta, target) -> dict` — wrapea
     `doctor.revisar()`, serializa `Reporte` a dict plano.
   - `_run_synopsis(set_id, ruta) -> dict` — wrapea
     `synopsis.leer_fuente()` + `synopsis.aplicar()`, atrapa
     `SynopsisError` y lo vuelve `{"ok": False, "error": ...}` en vez de
     dejarlo propagar.
   - `_construir_app()` — import perezoso de `mcp.server.mcpserver`,
     registra `attract_doctor` y `attract_synopsis` como tools sobre las
     dos funciones de arriba. Separado de `main()` para poder testear el
     registro de tools sin bloquear en el loop de stdio.
   - `main(argv)` — llama `_construir_app()`, atrapa `ImportError` con
     mensaje explícito, si construye bien corre `app.run()` (stdio).
2. `src/attract/cli.py` — agrega `"mcp": mcp_server.main` a `COMANDOS`.
   `mcp_server` se importa al tope del archivo (es solo un módulo Python,
   no dispara la dependencia — el import de `mcp` en sí sigue perezoso
   adentro de `_construir_app()`).

## Decisiones

- **`mcp` como dependencia opcional acotada, import perezoso** — ver
  [`ADR-0012`](../../decisions/0012-mcp-dependencia-opcional-acotada.md).
- **`MCPServer` (API 2.0.0), no `FastMCP`** — la versión del SDK
  disponible no expone `mcp.server.fastmcp`; se verificó la API real
  contra el paquete instalado en vez de asumir un ejemplo desactualizado.
  Si en el futuro el SDK cambia de nuevo, es un problema de esta feature
  puntual, no del resto de ATTRACT (por el aislamiento).
- **Las tools llaman a las funciones existentes de `doctor`/`synopsis`
  directamente, no al CLI por subprocess** — más simple, más rápido, y
  los resultados ya vienen estructurados (no hay que parsear texto
  impreso).
- **Solo transporte `stdio`** — es el default de `MCPServer.run()` y
  alcanza para el caso de uso real (cliente MCP local). Ver Fuera de
  alcance en `spec.md`.

## Riesgos

- **El SDK `mcp` puede cambiar de API otra vez** — se mitiga con el
  aislamiento (ADR-0012): si vuelve a romper, es un problema acotado a
  `mcp_server.py`, no se lleva puesto a `doctor`/`synopsis`.
- **Que el import perezoso se filtre por accidente** (alguien agrega
  `import mcp` al tope de otro módulo sin darse cuenta) — se mitiga con un
  test explícito que bloquea `mcp` vía `sys.modules` y confirma que
  `doctor`/`synopsis`/`cli`/`mcp_server` siguen importando (ver
  `tasks.md`).
