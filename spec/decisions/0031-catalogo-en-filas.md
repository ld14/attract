---
id: 0031
title: El catálogo se divide en filas dentro del scroll vertical existente
status: accepted
date: 2026-09-15
supersedes: null
superseded-by: null
tags: [frontend]
---

# 0031 — Catálogo en filas virtualizadas

## Contexto

El usuario pide salto de línea cuando los juegos exceden el ancho de Home.
La feature 009 usaba carruseles horizontales; cambia este requisito para el
catálogo. Deben conservarse tamaño de carátula, foco y rendimiento.

## Decisión

Dividir el catálogo en filas dentro del ListView vertical existente. Cada fila
contiene como máximo las tarjetas que entran en el ancho disponible. El modelo
de dominio permanece intacto: es una proyección de presentación.

## Alternativas consideradas

- Flow con Repeater: instancia todas las tarjetas, incluidas las fuera de vista.
- GridView de altura total: pierde el beneficio de limitar delegates al viewport.
- GridView de altura acotada dentro de los estantes: añade otro scroll vertical
  y hace ambiguo qué región desplaza la rueda en los límites.

GridView sigue siendo apropiado para una pantalla de resultados independiente
como la prevista en 009. La documentación de Qt describe su virtualización y
flujo por filas: https://doc.qt.io/qt-6/qml-qtquick-gridview.html.

## Consecuencias

Un único scroll; el catálogo ocupa más altura y desplaza los siguientes estantes.
Hay que traducir índices entre estantes originales y filas visuales y conservar
el juego seleccionado cuando cambia el número de columnas.
