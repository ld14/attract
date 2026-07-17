# ADR-002 · ¿La metadata es fuente o artefacto de build?

## Estado
🔴 **PENDIENTE — la decidís vos en el LAB 0.3**

## Contexto
`launch:` acepta exactamente un comando y no tiene condicionales por plataforma.
Y los comandos no se parecen en nada:

\`\`\`
macOS:   open /Applications/RetroArch.app --args -L "core.dylib" "{file.path}"
Windows: C:\RetroArch\retroarch.exe -L C:\RetroArch\cores\core.dll {file.path}
\`\`\`

No existe un `metadata.pegasus.txt` que sirva en los dos lados.

Si la metadata es un **artefacto de build**, el launch pasa de ser un dato a ser
una decisión de renderizado — y te da el gancho natural para normalizar a NFC y
sanitizar nombres al emitir.

Si es **fuente**, la editás a mano y ADR-005 se vuelve caro de revertir.

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
