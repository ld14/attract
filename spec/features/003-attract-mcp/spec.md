# 003 · Servidor MCP de ATTRACT — Spec

**Estado:** implementada

## Qué hace

`attract mcp` levanta un servidor MCP (protocolo estándar, stdio) que
expone dos herramientas — `attract_doctor` y `attract_synopsis` — para que
**cualquier cliente MCP** (no solo Claude) pueda validar y enriquecer una
librería de ATTRACT de forma programática, sin pasar por la CLI a mano.

Mismo objetivo que el Skill de M4 (`spec/features/002-attract-skill/`):
que un agente no tenga que acordarse de correr los comandos correctos.
Distinto mecanismo: el Skill son instrucciones que lee un agente Claude
específicamente; el servidor MCP es un protocolo que cualquier cliente
compatible puede hablar.

No duplica lógica: las dos tools llaman directo a
`attract.doctor.revisar()` y `attract.synopsis.leer_fuente()`/`aplicar()`,
la misma implementación que ya usa la CLI.

## Por qué

M5 del bootcamp. Interoperabilidad real — el Skill de M4 solo sirve dentro
de una sesión de Claude Code/Cowork sobre este repo; un servidor MCP lo
puede consumir cualquier cliente MCP, incluso fuera de una sesión de
edición de código (por ejemplo, un futuro dashboard, u otro agente
completamente distinto).

## Criterios de aceptación

- [x] `attract mcp` levanta un servidor MCP por stdio con dos tools:
      `attract_doctor(ruta, target)` y `attract_synopsis(set_id, ruta)`.
- [x] Ambas tools devuelven resultados estructurados (dict/JSON), no texto
      libre para parsear — errores y avisos de `doctor` separados; `ok`
      explícito en `synopsis`.
- [x] `attract doctor` y `attract synopsis` siguen funcionando
      **exactamente igual, sin ningún cambio de comportamiento**, con o
      sin el paquete `mcp` instalado — el import es perezoso, ver
      [`ADR-0012`](../../decisions/0012-mcp-dependencia-opcional-acotada.md).
- [x] Si se corre `attract mcp` sin tener `mcp` instalado, el error es
      explícito ("instalá con pip install mcp"), no un traceback crudo de
      `ModuleNotFoundError`.
- [x] `attract.cli`, `attract.doctor`, `attract.synopsis` y
      `attract.mcp_server` importan sin excepción aunque el paquete `mcp`
      no esté instalado — solo llamar a `mcp_server.main()` (o
      `_construir_app()`) lo necesita.

## Fuera de alcance

- Transportes distintos de `stdio` (SSE, streamable-http) — el SDK los
  soporta, pero no hay necesidad real todavía; `stdio` alcanza para un
  cliente MCP local (Claude Desktop, Claude Code, etc.).
- Autenticación/autorización — no aplica a un servidor local que corre en
  la misma máquina que el cliente.
- Exponer `attract ingest` (M7) — no existe todavía.
- Reimplementar el protocolo MCP a mano — decidido en ADR-0012, se usa el
  SDK oficial.
