# ADR-001 · Transporte de datos ricos al theme

## Estado
🔴 **PENDIENTE — la decidís vos en el LAB 0.3**

## Contexto
El mockup necesita estructuras anidadas:

\`\`\`javascript
mags:   [{name, pages, color, img}]
cheats: { combos:[{n,i}], codes:[{n,i}] }
review: { score, cats:[[label,val]x6], verdict }
\`\`\`

Pegasus expone campos custom vía `x-` y llegan como `game.extra.<nombre>`.
La API reference dice **"as JS string"**; el parser en C++ los guarda en un
`QStringList` (una **lista**). Las dos cosas no pueden ser ciertas.

**Averigualo en el Bloque 3 antes de decidir.** Resultado del experimento: <COMPLETAR>

Opciones: (A) JSON embebido · (B) listas paralelas · (C) archivo de datos aparte.
Los trade-offs están en el módulo.

## Decisión
<COMPLETAR>

## Justificación
<COMPLETAR — contra qué criterio>

## Consecuencias
### Positivas
### Negativas
### Qué nos ata

## Alternativas descartadas

## Verificaciones pendientes
- [ ]

---
> Modelo a imitar: `005-runtime-mame-vanilla.md`. Template: `000-template.md`.
