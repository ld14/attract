---
id: 0009
title: "Frontera del sistema: ATTRACT consume revistas, no las produce"
status: accepted
date: "2026-07-23"
supersedes: null
superseded-by: null
tags: [backend, proceso]
---

# 0009 — Frontera del sistema: producción vs. consumo de metadata de revistas

## Contexto

El modelo de datos de revistas ([`ADR-0008`](0008-modelo-datos-revistas.md))
define el **contrato** (`magazine.json`), pero no dice quién lo **llena**.
Escanear una revista, hacer OCR, y decidir en qué página está la nota de
cada juego es un trabajo con forma completamente distinta al resto de
ATTRACT — no es parsear metadata ni generar estructura de archivos, es
reconocimiento de imagen y criterio editorial.

## Decisión

La **generación** de `magazine.json` (escanear, OCR, mapear qué juego está
en qué página) es responsabilidad de un **subsistema aparte, futuro, fuera
del alcance actual de ATTRACT**.

ATTRACT es **consumidor** del contrato, no productor:

- **ATTRACT sí es dueño de:** el formato de `magazine.json` (el contrato en
  sí), leerlo, resolver el `ref` desde el `data.json` de un juego, el visor
  que lo muestra, y la degradación cuando la revista referenciada no existe.
- **ATTRACT no es dueño de:** escanear la revista, correr OCR, ni decidir en
  qué página está cada nota. Eso lo hace un humano hoy, y potencialmente un
  subsistema separado mañana.

## Alternativas consideradas

### Que ATTRACT también genere `magazine.json` (escaneo + OCR integrado)

- A favor: un solo sistema, sin frontera que mantener ni coordinar.
- En contra: mezcla dos problemas de naturaleza distinta — estructura de
  archivos y metadata (lo que ATTRACT ya hace) vs. reconocimiento de imagen
  y criterio editorial (qué nota corresponde a qué juego, algo que hoy
  requiere ojo humano). Acoplar ambos significa que ATTRACT no se puede
  testear ni completar sin que el problema de OCR esté resuelto.
- **Descartada porque:** bloquea todo el desarrollo de ATTRACT a que exista
  primero un pipeline de escaneo/OCR que ni siquiera está diseñado.

## Consecuencias

**Positivas**

- ATTRACT se puede desarrollar y testear **entero** sin que el subsistema de
  revistas exista. Alcanza con escribir un `magazine.json` a mano como
  fixture — el visor no sabe ni le importa quién lo generó, solo que
  respete el contrato. Ver `fixtures/arcade/media/_magazines/`.
- Define un límite de sistema real, no una posposición vaga: el día que
  exista el subsistema de escaneo, solo tiene que producir archivos que
  cumplan el contrato de ADR-0008 — no necesita saber nada de Pegasus, del
  theme, ni de cómo se muestra la revista en pantalla.

**Coste asumido**

- Hasta que el subsistema de escaneo exista, cargar una revista nueva es
  trabajo manual: escanear, recortar páginas, y escribir el `magazine.json`
  a mano (incluido decidir en qué página está cada nota).

**Qué habría que revisar si esto se replantea**

- Si en algún momento se decide construir el subsistema de escaneo/OCR, esta
  ADR sigue vigente igual — define la frontera, no que el subsistema no
  vaya a existir. Solo se revisaría si se decidiera fusionar ambos sistemas
  en un mismo proceso, lo cual reabriría la alternativa descartada arriba.

## Referencias

- `docs/decisiones/2026-07-23.md` punto 6 — razonamiento original.
- [`0008-modelo-datos-revistas.md`](0008-modelo-datos-revistas.md) — el
  contrato que esta ADR dice que ATTRACT consume sin producir.
