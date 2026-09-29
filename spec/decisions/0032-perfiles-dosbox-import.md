---
id: 0032
title: "Generar la configuracion DOSBox durante el import con perfiles locales"
status: accepted
date: "2026-09-15"
supersedes: null
superseded-by: null
tags: [backend, data, proceso]
---

# 0032 — Perfiles DOSBox al importar

## Contexto
El usuario quiere que el resultado probado de Prehistorik se repita al instalar
juegos COINDOOR. Un título no identifica una edición; el piloto encontró un
lanzador de Loom dentro de Prehistorik y una copia Amiga en la colección DOS.

## Decisión
El import de MS-DOS descomprimido resuelve perfiles locales por huellas, acepta
un objeto dosbox opcional declarado y genera configuración portable, launch e
informe dentro del rollback existente. Un caso ambiguo instala la ficha pero
deja el arranque pendiente. Se conserva el dosbox.conf local al reimportar,
como ajuste del runtime; no cambia la política de reemplazo de ROMs y assets.

El catálogo empieza con la copia de Prehistorik confirmada por el usuario.
La prueba no acredita otras ediciones. Cada fuente y tipo de verificación
queda registrado. El emulador se resuelve desde {file.path} (absoluto en Pegasus)
y el cwd se fija con --working-dir: no se vuelve al PATH descartado en ADR-0018.
Windows usa dosbox.exe; en macOS/Linux se espera el binario dosbox en la misma
carpeta relativa. No se distribuyen binarios.

## Alternativas consideradas

### Buscar ajustes en internet durante cada import
- A favor: información nueva disponible.
- En contra: resultado variable y dependiente de red, fuentes y edición.
- Descartada porque el import debe ser reproducible; investigar alimenta el
  catálogo, no es un requisito de instalación.

### Aplicar una configuración por título o por género
- A favor: cubre todos los juegos con poco código.
- En contra: confunde ediciones y programas ajenos, como mostró la biblioteca.
- Descartada porque una base provisional no equivale a un perfil probado.

### Reemplazar siempre dosbox.conf
- A favor: regeneración simple.
- En contra: pierde configuraciones que el usuario ya probó.
- Descartada para este nuevo artefacto local: la reimportación lo conserva.

## Consecuencias
El flujo existente gana generación automática sin dependencias nuevas. Los
paquetes desconocidos pueden requerir un ejecutable declarado o instalación
manual; nunca se ejecuta un programa del paquete al importar. Revisar el
contrato si hacen falta múltiples discos o perfiles alternativos de sonido.

## Referencias
- [Feature 025](../features/025-dosbox-import/spec.md)
- [ADR-0027](0027-contrato-paquete-import-coindoor.md)
- [ADR-0028](0028-rollback-transaccional-import.md)
- [ADR-0018](0018-launch-ruta-absoluta.md)
- [Prehistorik: reportes DOSBox](https://www.dosbox.com/comp_list.php?showID=1943)
