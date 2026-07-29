---
id: 0012
title: "attract mcp usa el SDK oficial mcp como dependencia opcional, acotada"
status: accepted
date: "2026-07-29"
supersedes: null
superseded-by: null
tags: [backend, tooling]
---

# 0012 — `attract mcp` y el límite stdlib-only

## Contexto

`tech-stack.md` §Límites duros dice: **"Sin dependencias externas en
`src/attract/` — es deliberado (`doctor` corre con cualquier Python ≥3.10,
sin instalar nada)"**. `CLAUDE.md` además lista "Añadir dependencias
nuevas" como fuera de alcance sin preguntar explícitamente.

M5 del bootcamp pide exponer ATTRACT como **servidor MCP**, para que
clientes además de Claude (cualquier cliente MCP) puedan invocar `doctor` y
`synopsis` de forma programática — mismo objetivo que el Skill de M4
(`ADR` no numerada aparte, ver `spec/features/002-attract-skill/`), otro
protocolo.

MCP no es "devolver JSON por un socket": es un protocolo con handshake de
inicialización (`initialize`), negociación de capacidades, mensajes
JSON-RPC 2.0 con forma específica, `tools/list`/`tools/call`, manejo de
errores según spec, y versiones del protocolo que van cambiando. El SDK
oficial (`mcp`, en PyPI) implementa todo eso. Reimplementarlo a mano en
stdlib es posible, pero es reinventar un spec completo — con el riesgo real
de no ser compatible con clientes que sí siguen el estándar al pie de la
letra, que es exactamente lo que se pierde si la implementación casera
tiene un bug de protocolo que el SDK ya resolvió.

## Decisión

Se agrega `mcp` (SDK oficial) como dependencia **opcional, acotada
exclusivamente al subcomando `attract mcp`**:

- `src/attract/mcp_server.py` es el único lugar del proyecto que importa
  `mcp`, y lo hace con **import perezoso** (dentro de la función, no al
  tope del módulo) — si el paquete no está instalado, `attract doctor` y
  `attract synopsis` siguen funcionando exactamente igual que hoy, cero
  instalación. Solo al correr `attract mcp` se necesita `mcp` instalado, y
  si falta, el mensaje de error lo dice explícito (`pip install mcp`), no
  un `ModuleNotFoundError` crudo.
- `cli.py` tampoco importa `mcp` al tope del archivo — el `COMANDOS` dict
  sigue resolviendo `synopsis`/`doctor` sin tocar el módulo nuevo.
- `make setup` **no** instala `mcp` por default — se documenta como paso
  aparte (`pip install mcp` o un extra tipo `pip install -e .[mcp]` si en
  algún momento se agrega `pyproject.toml`).

El límite duro **no se descarta, se acota**: sigue valiendo al pie de la
letra para todo lo que ya existe (`doctor`, `synopsis`, el entry point base
de la CLI). Se abre una excepción puntual, documentada, para un módulo
nuevo y opcional que el usuario activa explícitamente cuando lo necesita.

## Alternativas consideradas

### A · Implementar el protocolo MCP a mano en stdlib

- A favor: cero dependencias nuevas, el límite duro queda intacto sin
  excepciones.
- En contra: reimplementar JSON-RPC 2.0 + el handshake + el versionado del
  protocolo MCP es trabajo real y con superficie de bugs de compatibilidad
  — justo el tipo de problema que adoptar un protocolo estándar busca
  evitar. Si un cliente MCP real no puede hablar con el servidor casero por
  un detalle de spec mal implementado, el objetivo de M5 (interoperar con
  otros clientes, no solo Claude) queda debilitado en la práctica.
- **Descartada porque:** el costo de mantenimiento y el riesgo de
  incompatibilidad superan el valor de no agregar una dependencia acotada
  y opcional.

### B · Posponer M5

- A favor: no hay que tocar el límite duro todavía.
- **Descartada porque:** decisión explícita de continuar con M5 ahora.

## Consecuencias

**Positivas**

- Implementación de protocolo correcta y mantenida por el ecosistema, en
  vez de una versión casera con compatibilidad incierta.
- `doctor`/`synopsis`/`make setup` base siguen con cero fricción de
  instalación — la propiedad que motivó el límite duro en primer lugar
  sigue siendo cierta para todo lo que existía antes de esta ADR.

**Coste asumido**

- Primera dependencia externa real del proyecto — acotada e import
  perezoso, pero existe. Hay que vigilar que no se filtre por accidente a
  un módulo que debería seguir siendo stdlib-only (test explícito, ver
  `spec/features/003-attract-mcp/tasks.md`).
- Un lector de `tech-stack.md` que solo lea "sin dependencias externas" sin
  llegar a esta ADR se puede confundir — mitigado actualizando esa sección
  para que enlace acá.

**Qué habría que revisar si esto se replantea**

- Si en algún momento `doctor` o `synopsis` necesitaran algo de `mcp`
  (no debería pasar, son módulos independientes), esta ADR queda
  invalidada y hay que reabrir la discusión completa.

## Referencias

- `spec/constitution/tech-stack.md` §Límites duros — el límite que esta
  ADR acota.
- `spec/features/003-attract-mcp/` — spec/plan/tasks de la feature que
  motivó esto.
- `spec/features/002-attract-skill/` — mismo objetivo (que un agente use
  ATTRACT sin CLI directa), protocolo distinto.
