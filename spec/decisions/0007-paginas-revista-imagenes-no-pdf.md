---
id: 0007
title: "Páginas de revista: imágenes, nunca PDF embebido"
status: accepted
date: "2026-07-23"
supersedes: null
superseded-by: null
tags: [frontend, data]
---

# 0007 — Formato de páginas de revista: imágenes, no PDF

## Contexto

Las páginas escaneadas de una revista necesitan mostrarse dentro del theme
de Pegasus ([`ADR-0008`](0008-modelo-datos-revistas.md) ya asume que existen
como archivos de imagen, `p001.jpg` en adelante). La alternativa obvia —
guardar directamente el PDF de la revista y mostrarlo tal cual — se investigó
antes de descartarla, no se asumió.

**Verificado, no supuesto:**

- Pegasus está construido con **Qt 5.15**, y sus dependencias declaradas de
  build son únicamente QML/QtQuick2, Multimedia, SVG y SQL (SQLite). **PDF
  no está entre ellas.**
- No hay `QtWebView` ni `QtWebEngine` en los binarios oficiales de Pegasus.
  El único soporte de "rich text" en QML es un subconjunto de HTML 3.2/4 sin
  CSS de layout ni JS — no alcanza ni para acercarse al mockup de referencia.
- Mostrar PDF en Qt5/QML requeriría `Poppler-Qt5` + un plugin QML de
  terceros compilado aparte e integrado al binario de Pegasus — fuera de
  alcance, no soportado por los builds oficiales.
- Pegasus está congelado desde octubre 2024 (última release), sin desarrollo
  activo — no va a sumar soporte de PDF por su cuenta.

## Decisión

Las páginas escaneadas de revista se guardan como **imágenes** (`.jpg`/`.png`),
una por página, siguiendo el patrón `p001.jpg`, `p002.jpg`… con ceros a la
izquierda para que el orden alfabético sea el orden real (ver
`docs/CONVENCION.md` y los fixtures de `_magazines/`). **Nunca** como PDF
embebido en el theme.

Consecuencia para el pipeline futuro: quien produzca `magazine.json` (ver
[`ADR-0009`](0009-frontera-produccion-consumo-revistas.md), fuera del
alcance actual de ATTRACT) tiene que **convertir** cada PDF de revista a
imágenes por página como parte de la ingesta — no es un paso automático,
es trabajo nuevo.

## Alternativas consideradas

### Embeber el PDF y mostrarlo con un plugin de terceros (Poppler-Qt5)

- A favor: conserva el PDF original tal cual, sin perder nada en la
  conversión.
- En contra: exige compilar un plugin QML de terceros e integrarlo al
  binario de Pegasus — Pegasus está congelado desde oct-2024, sin desarrollo
  activo, así que cualquier problema con esa integración no se arregla
  upstream, hay que sostenerlo para siempre uno mismo.
- **Descartada porque:** no está soportado por los builds oficiales y el
  costo de mantenimiento cae enteramente en el proyecto, sin ayuda posible
  de la comunidad de Pegasus.

### Convertir a HTML y usar el soporte "rich text" nativo de QML

- A favor: nativo, sin dependencias externas.
- En contra: el subsistema de rich text de QML es HTML 3.2/4 sin CSS de
  layout ni JS — no permite reproducir ni de lejos el diseño del mockup de
  referencia (`docs/mockup-referencia.html`).
- **Descartada porque:** técnicamente insuficiente para el resultado visual
  que se busca.

## Consecuencias

**Positivas**

- Cero dependencias nuevas para el theme — `Image` de QtQuick ya alcanza,
  sin plugins de terceros ni bibliotecas externas.
- Compatible con Pegasus congelado: no depende de que el proyecto agregue
  soporte que nunca va a llegar.
- El visor de revistas puede reusar exactamente el mismo mecanismo de
  navegación que cualquier galería de imágenes — sin lógica especial de
  renderizado de PDF.

**Coste asumido**

- Alguien (hoy un humano, ver ADR-0009) tiene que convertir cada PDF de
  revista a imágenes página por página antes de que exista el
  `magazine.json` — trabajo de ingesta nuevo, no gratis.
- Se pierde la posibilidad de seleccionar/copiar texto de la página (algo
  que un PDF real permitiría) — las páginas son imágenes planas.

**Qué habría que revisar si esto se replantea**

- Si Pegasus retoma desarrollo activo y agrega soporte nativo de PDF (o
  migra a Qt6 con `QtQuick.Pdf`, que si existe en Qt6), reabrir esta
  decisión. Señal concreta: la contraprueba archivada en
  `themes/experimentos/pdf-qtquick.qml` (`import QtQuick.Pdf`) empieza a
  cargar sin error.

## Verificaciones pendientes

- [x] **Confirmado 2026-07-28** — corrida la contraprueba de
      `themes/experimentos/pdf-qtquick.qml` contra Pegasus real: el theme ni
      siquiera cargó ("Theme loading failed"). El `import QtQuick.Pdf` no
      resuelve contra este binario, confirmando la predicción con evidencia
      real, no solo con la investigación de dependencias de build.

## Referencias

- `docs/decisiones/2026-07-23.md` punto 3 — investigación original.
- [`0008-modelo-datos-revistas.md`](0008-modelo-datos-revistas.md) — asume
  este formato en la estructura de `magazine.json`.
- `themes/experimentos/pdf-qtquick.qml` — contraprueba archivada.
- `docs/mockup-referencia.html` — el diseño visual que el HTML nativo de
  QML no puede reproducir.
