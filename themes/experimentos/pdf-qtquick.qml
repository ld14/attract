// EXPERIMENTO ARCHIVADO — ¿Pegasus puede mostrar un PDF con QtQuick.Pdf?
//
// Contexto: el handoff del 2026-07-23 (docs/decisiones/2026-07-23.md, punto 3)
// decide que las páginas de revista se guardan como IMÁGENES, no como PDF,
// apoyándose en que Pegasus está construido con Qt 5.15 y sus dependencias
// declaradas de build son QML/QtQuick2, Multimedia, SVG y SQL. PDF no está.
//
// Este archivo es la contraprueba: si `import QtQuick.Pdf` resolviera y
// PdfDocument cargara, el punto 3 habría que reabrirlo.
//
// PREDICCIÓN (según punto 3): el import falla — el módulo no existe en el
// binario oficial de Pegasus. QtQuick.Pdf es Qt 6; en Qt 5.15 fue tech preview
// y no viene compilado en builds de terceros.
//
// RESULTADO OBSERVADO: ✅ CONFIRMADO — falla, como predecía ADR-0007.
// Verificado contra Pegasus real el 2026-07-28: Pegasus ni siquiera pudo
// CARGAR el theme ("Theme loading failed :( — Pegasus tried to load the
// selected theme, but failed. This may happen when you try to load an
// outdated theme, or when there's a bug in its code"). El `import
// QtQuick.Pdf` no resuelve contra este binario — no es un error al abrir el
// archivo puntual, es que el módulo no existe. ADR-0007 queda confirmada
// con evidencia real, no solo con la investigación de las dependencias de
// build. No hace falta reabrirla.
//
// Cómo correrlo:
//   1. cp pdf-qtquick.qml <themes de Pegasus>/attract-debug/theme.qml
//   2. ajustá la ruta de `source` a este directorio
//   3. abrí Pegasus y mirá si aparece "FUNCIONA" o un error de import
//
// NO vive en themes/attract-debug/ a propósito: ese theme es el harness del
// Bloque 3 y es la evidencia que sostiene ADR-0001. No se pisa.
//
// Deuda conocida: la ruta de `source` es absoluta y apunta al Mac del autor.
// Rompe en el gabinete (ADR-0003). Si el experimento se reabre, hay que
// resolverla relativa al theme antes de darle valor a cualquier resultado.

import QtQuick 2.0
import QtQuick.Pdf

FocusScope {
    id: root
    focus: true
    Rectangle { anchors.fill: parent; color: "#0d1117" }

    PdfDocument {
        id: doc
        source: "file:///Users/familyhouse/workplace/attract/themes/experimentos/prueba.pdf"
        onStatusChanged: {
            if (status === PdfDocument.Ready)
                txt.text = "FUNCIONA\n\npaginas: " + doc.pageCount + "\ntitulo: " + doc.title
            else if (status === PdfDocument.Error)
                txt.text = "ERROR al abrir el PDF:\n" + doc.error
        }
    }

    Text {
        id: txt
        anchors.centerIn: parent
        color: "#7ee787"
        font.family: "monospace"
        font.pixelSize: 18
        text: "=== PRUEBA QtQuick.Pdf ===\ncargando..."
    }
}
