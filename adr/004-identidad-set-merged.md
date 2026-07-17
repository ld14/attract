# ADR-004 · Identidad de un juego en un set merged

## Estado
🔴 **PENDIENTE — la decidís vos en el LAB 0.3**

## Contexto
El set es **MAME 0.288 merged**: el parent y todos sus clones viven en el mismo zip.
Un `.zip` **no es un juego: es una familia**.

Y el problema es simétrico:

\`\`\`
sf2ce.zip  ->  1 archivo, N juegos    (merged colapsa la familia)
mok.zip    ->  3 archivos, 1 juego    (zip 1.15KB + CHD 132MB + BIOS naomigd)
\`\`\`

Pegasus asume **un archivo = una cosa lanzable**. Merged rompe la asunción por los
dos extremos. Y `media/<archivo-sin-extensión>/` agrupa los assets por familia:
una carátula para todos los clones.

Probablemente la decisión más consecuente de M0: de esta depende cómo nombrás todo.

Opciones: (A) solo parents · (B) un `game:` por set apuntando al mismo zip ·
(C) el zip deja de ser el `file:`.

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
