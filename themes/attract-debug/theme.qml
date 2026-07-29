// ATTRACT Debug v2 — ahora navegable.
// Flechas izq/der para recorrer los juegos. X salta al primero con extras.

import QtQuick 2.0

FocusScope {
    id: root
    focus: true

    property int idx: 0
    property var g: api.allGames.count > 0 ? api.allGames.get(idx) : null

    Rectangle { anchors.fill: parent; color: "#0d1117" }

    Text {
        anchors.centerIn: parent
        width: parent.width * 0.9
        color: "#7ee787"
        font.family: "monospace"
        font.pixelSize: 15
        wrapMode: Text.WordWrap
        textFormat: Text.PlainText
        text: root.g ? reporte(root.g) : "Sin juegos."
    }

    function tipoDe(v) {
        if (v === undefined) return "undefined";
        if (v === null) return "null";
        if (Array.isArray(v)) return "Array[" + v.length + "]";
        return typeof v;
    }

    function reporte(g) {
        var out = [];
        out.push("=== ATTRACT DEBUG v2 ===");
        out.push("  <- ->  navegar     X  ir al primero con extras");
        out.push("");
        out.push("juego " + (root.idx + 1) + " de " + api.allGames.count + ": " + g.title);
        out.push("");
        out.push("--- nativos ---");
        out.push("  releaseYear : " + g.releaseYear);
        out.push("  players     : " + g.players);
        out.push("  rating      : " + g.rating);
        out.push("  rating*100  : " + (g.rating * 100));
        out.push("  redondeado  : " + Math.round(g.rating * 100));
        out.push("  boxFront    : " + (g.assets.boxFront || "(vacio)"));
        out.push("  cartridge   : " + (g.assets.cartridge || "(vacio)"));
        out.push("  marquee     : " + (g.assets.marquee || "(vacio)"));
        out.push("");
        out.push("--- LA PREGUNTA: game.extra ---");

        var claves = [];
        for (var k in g.extra) claves.push(k);

        if (claves.length === 0) {
            out.push("  (vacio)  <- este juego no tiene x-. Segui con ->");
        } else {
            for (var i = 0; i < claves.length; i++) {
                var k = claves[i], v = g.extra[k];
                out.push("  extra[" + JSON.stringify(k) + "]");
                out.push("     tipo  : " + tipoDe(v));
                out.push("     valor : " + JSON.stringify(v));
                if (Array.isArray(v) && v.length > 0)
                    out.push("     [0]   : " + JSON.stringify(v[0]) + "  (" + tipoDe(v[0]) + ")");
            }
        }
        return out.join("\n");
    }

    function tieneExtras(i) {
        var e = api.allGames.get(i).extra;
        for (var k in e) return true;
        return false;
    }

    Keys.onPressed: {
        if (event.key === Qt.Key_Right) {
            root.idx = (root.idx + 1) % api.allGames.count;
            event.accepted = true;
        } else if (event.key === Qt.Key_Left) {
            root.idx = (root.idx - 1 + api.allGames.count) % api.allGames.count;
            event.accepted = true;
        } else if (event.key === Qt.Key_X) {
            for (var i = 0; i < api.allGames.count; i++) {
                if (tieneExtras(i)) { root.idx = i; break; }
            }
            event.accepted = true;
        }
    }
}
