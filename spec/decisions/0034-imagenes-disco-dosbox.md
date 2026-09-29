---
id: 0034
title: "Montar imagenes de disco (floppy/CD) declaradas para DOSBox"
status: accepted
date: "2026-09-17"
supersedes: null
superseded-by: null
tags: [backend, data]
---

# 0034 — Imágenes de disco declaradas en DOSBox

## Contexto

`spec/features/025-dosbox-import/spec.md` había puesto "instalar desde
imágenes" explícitamente fuera de alcance. Al revisar la librería real
apareció un caso concreto: Monkey Island 2 estaba guardado como 5 imágenes
de floppy de 1.44MB sin extraer, sin ningún ejecutable en disco para
resolver. El resolvedor de `ADR-0032`/`ADR-0033` no tiene forma de generar
nada útil ahí — no hay archivo que buscar.

No se puede enumerar el contenido de una imagen (FAT12 de floppy, ISO9660 de
CD) sin un parser, y el proyecto es stdlib-only a propósito. Tampoco se
puede montarla y listar su contenido durante el import: eso es ejecutar
software de terceros (el propio DOSBox) fuera del alcance del import.

## Decisión

`game.json` (o una declaración post-hoc equivalente) puede declarar
`dosbox.imagenes` (lista de rutas relativas a `.img`/`.ima`/`.iso`/`.cue`),
`dosbox.tipo_imagen` (`floppy` o `cdrom`) y `dosbox.executable` (el nombre
DOS 8.3 del programa a correr, **dentro** de la imagen). El resolvedor NO
verifica que ese ejecutable exista — no puede, sin montar la imagen — y lo
deja explícito en el informe (`verification: "no verificable..."`). Genera
un `dosbox.conf` con `imgmount a/d "img1" "img2" ... -t floppy/iso` en vez
de `mount c "carpeta"`.

Sin esta declaración, si el árbol tiene imágenes sueltas y ningún ejecutable
en disco, el informe lo señala explícitamente (`candidates` vacío más un
aviso dedicado) en vez de simplemente decir "no hay arranque único" - la
causa real es otra y hay que decirla.

Esto reabre el punto "fuera de alcance" de la spec 025: lo que se descartó
ahí era instalar automáticamente DESDE una imagen (extraer/interpretar su
contenido sin intervención), no darle un lugar a la declaración explícita de
alguien que ya sabe qué hay adentro.

## Alternativas consideradas

### Parsear FAT12/ISO9660 para enumerar el contenido de la imagen

- A favor: cubriría el caso automáticamente, sin declaración.
- En contra: reimplementar un parser de sistema de archivos es un proyecto
  en sí mismo; el proyecto es stdlib-only a propósito.
- **Descartada porque:** el costo no está justificado frente a pedirle a
  quien arma el perfil que declare el ejecutable - es información que ya
  tiene (la tuvo que averiguar para poder jugarlo).

### Montar la imagen durante el import para verificar

- A favor: verificación real, no solo declarada.
- En contra: ejecutar DOSBox (o cualquier montador) durante el import es
  exactamente lo que ADR-0032 prohíbe ("sin ejecutar programas del
  paquete").
- **Descartada por el mismo motivo que ADR-0032.**

## Consecuencias

**Positivas**

- Monkey Island 2 (y cualquier juego futuro distribuido por floppy/CD sin
  extraer) tiene un camino, en vez de quedar sin ninguna config posible.

**Coste asumido**

- El ejecutable declarado dentro de una imagen nunca se verifica - un typo
  ahí solo se nota al jugar, no al importar.

**Qué habría que revisar si esto se replantea**

- Si aparece la necesidad real de parsear el contenido de una imagen
  (varios juegos por CD, por ejemplo), vale la pena evaluar un parser
  mínimo de ISO9660 en vez de seguir declarando a mano.

## Referencias

- [Feature 025](../features/025-dosbox-import/spec.md)
- [ADR-0032](0032-perfiles-dosbox-import.md)
- [docs/decisiones/2026-09-17.md](../../docs/decisiones/2026-09-17.md)
