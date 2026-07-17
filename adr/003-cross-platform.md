# ADR-003 · Estrategia cross-platform macOS → Windows

## Estado
🔴 **PENDIENTE — la decidís vos en el LAB 0.3**

## Contexto
Desarrollo en Mac, ejecución en Windows, las dos máquinas reales.

El costo no es el traslado: es el **ciclo**. Si los errores se descubren del otro
lado, dejás de probar.

Irreductibles (solo Windows): reproducción de video (DirectShow, puede necesitar
códecs), `launch:`, performance en el hardware del gabinete.

Todo lo demás es automatizable en el Mac → ver `attract doctor`.

Definir: transporte (git), qué va y qué no al repo, cuándo se viaja al gabinete.

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
