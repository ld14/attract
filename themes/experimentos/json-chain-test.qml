// EXPERIMENTO ARCHIVADO — ¿el theme puede encadenar DOS lecturas de JSON?
//
// Contexto: ADR-0008 decide que un juego no copia las páginas de su revista,
// solo la referencia por `ref` en su data.json. Eso significa que el theme
// tiene que:
//   1. Leer media/dino/data.json          → sacar mags[0].ref ("micromania-16")
//   2. Leer media/_magazines/micromania-16/magazine.json  → sacar los datos reales
//
// Ya se probó UN JSON externo por separado y funciona (ADR-0001, Bloque 3).
// Lo que NO se probó todavía es la cadena de DOS, uno dependiendo del otro.
//
// PREDICCIÓN: debería funcionar — es la misma técnica (XMLHttpRequest +
// JSON.parse) corrida dos veces seguidas, la segunda con una ruta armada a
// partir del resultado de la primera.
//
// RESULTADO OBSERVADO: ✅ FUNCIONA — CADENA COMPLETA. Confirmado contra
// Pegasus real el 2026-07-28. El theme lee media/dino/data.json, saca
// mags[0].ref ("micromania-16"), y con eso arma la ruta y lee
// media/_magazines/micromania-16/magazine.json exitosamente. La técnica de
// XMLHttpRequest + JSON.parse funciona igual la segunda vez, encadenada.
//
// Deuda conocida: las rutas de abajo son absolutas y apuntan al Mac del
// autor (mismo problema que themes/experimentos/pdf-qtquick.qml). Rompe en
// el gabinete (ADR-0003). Si el experimento se reabre para producción, hay
// que resolverlas relativas al theme antes de darle valor a los resultados.

import QtQuick 2.0

FocusScope {
    id: root
    focus: true
    Rectangle { anchors.fill: parent; color: "#0d1117" }

    property string base: "file:///Users/familyhouse/workplace/attract/fixtures/arcade/media/"

    Text {
        id: txt
        anchors.centerIn: parent
        width: parent.width * 0.85
        wrapMode: Text.WordWrap
        color: "#7ee787"
        font.family: "monospace"
        font.pixelSize: 15
        text: "=== PRUEBA: cadena de dos JSON ===\ncargando data.json..."
    }

    Component.onCompleted: leerDataJson()

    function leerDataJson() {
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            if (xhr.status !== 200 && xhr.status !== 0) {
                txt.text = "PASO 1 FALLÓ\n\nNo pude leer data.json.\nstatus: " + xhr.status;
                return;
            }
            try {
                var data = JSON.parse(xhr.responseText);
                var ref = data.mags && data.mags[0] ? data.mags[0].ref : null;
                if (!ref) {
                    txt.text = "PASO 1 OK, pero no hay mags[0].ref\n\n" + xhr.responseText;
                    return;
                }
                txt.text = "PASO 1 OK\n\ndata.json:\n" + xhr.responseText +
                           "\n\nref encontrado: " + ref + "\ncargando magazine.json...";
                leerMagazineJson(ref);
            } catch (e) {
                txt.text = "PASO 1 OK pero JSON.parse falló\n\n" + e + "\n\n" + xhr.responseText;
            }
        };
        xhr.open("GET", base + "dino/data.json");
        xhr.send();
    }

    function leerMagazineJson(ref) {
        var xhr2 = new XMLHttpRequest();
        xhr2.onreadystatechange = function() {
            if (xhr2.readyState !== XMLHttpRequest.DONE) return;
            if (xhr2.status !== 200 && xhr2.status !== 0) {
                txt.text = "PASO 1 OK, PASO 2 FALLÓ\n\nNo pude leer magazine.json.\nstatus: " + xhr2.status;
                return;
            }
            try {
                var mag = JSON.parse(xhr2.responseText);
                txt.text = "FUNCIONA — CADENA COMPLETA\n\n" +
                           "revista: " + mag.name + " #" + mag.issue + "\n" +
                           "páginas totales: " + mag.pages.length + "\n" +
                           "artículos: " + JSON.stringify(mag.articles);
            } catch (e) {
                txt.text = "PASO 1 OK, PASO 2 JSON.parse falló\n\n" + e;
            }
        };
        xhr2.open("GET", base + "_magazines/" + ref + "/magazine.json");
        xhr2.send();
    }
}
