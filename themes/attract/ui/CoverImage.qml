// La caratula de un juego, con la cadena de fallback de CONVENCION #2.2:
//
//     boxFront -> poster -> marquee -> color-wash con el accent
//
// Es el UNICO lugar del theme que conoce esa cadena. Un arcade no tiene caja
// (mok tiene marquee y poster, no boxFront), asi que la cadena no es un caso
// raro: es el caso normal de media libreria.
//
// El ultimo eslabon NO es un placeholder de los que el handoff dice que no
// deben llegar a produccion: es un estado real del contrato. Un juego sin
// ninguna imagen tiene que verse igual, con el color que lo identifica, y no
// dejar un hueco (CONVENCION #2.3).
//
// POR QUE SE SALTA POR onStatusChanged Y NO CHEQUEANDO SI EL STRING ESTA
// VACIO: un asset puede existir en el metadata y NO cargar. Medido el
// 2026-08-02: un juego que entra por el provider de Steam devuelve boxFront
// como URL remota (https://shared.akamai.steamstatic.com/...), y en un
// gabinete offline eso nunca carga. Image.Error es la unica senal confiable.
//
// El ultimo eslabon lo dibuja ui/AccentWash.qml, que es el mismo gradiente
// que usan las tarjetas del rail — ahi no es un fallback sino el fondo que el
// diseno pide. Vive aparte para no tener dos Canvas que sincronizar a mano.

import QtQuick 2.0
import ".."

Item {
    id: root

    property var game: null
    property color accent: Theme.accentNeutro
    property color accent2: Theme.accent2Neutro

    // El indice del gradiente: el diseno varia el angulo y el centro por
    // posicion, para que dos juegos seguidos no se vean identicos.
    property int variacion: 0

    property int fillMode: Image.PreserveAspectCrop
    readonly property bool mostrandoPlaceholder: _idx >= _candidatos.length

    // Que eslabon de la cadena se esta viendo: "boxFront" | "poster" |
    // "marquee" | "color-wash". Se expone con NOMBRE y no con un indice
    // porque un indice miente: los assets ausentes no entran en la lista, asi
    // que el "1" de un juego sin boxFront es en realidad el poster. Ese
    // mismo error se colo en el panel de diagnostico y se vio en Pegasus el
    // 2026-08-02 — el instrumento de verificacion reportando mal.
    readonly property string origen:
        mostrandoPlaceholder ? "color-wash" : _nombres[_idx]

    // --- la cadena --------------------------------------------------------

    // El orden ES el contrato (CONVENCION #2.2). No reordenar sin cambiar ese
    // documento primero.
    readonly property var _cadena: ["boxFront", "poster", "marquee"]

    readonly property var _candidatos: {
        if (!game || !game.assets) return [];
        var out = [];
        for (var i = 0; i < _cadena.length; i++) {
            var v = game.assets[_cadena[i]];
            if (v) out.push(v);
        }
        return out;
    }

    // Los nombres de los que SI entraron, en el mismo orden que _candidatos.
    readonly property var _nombres: {
        if (!game || !game.assets) return [];
        var out = [];
        for (var i = 0; i < _cadena.length; i++)
            if (game.assets[_cadena[i]]) out.push(_cadena[i]);
        return out;
    }

    property int _idx: 0
    onGameChanged: _idx = 0

    // --- ultimo eslabon: el color-wash ------------------------------------
    // Mismo dibujo que usan las tarjetas del rail, de ahi que viva aparte.

    AccentWash {
        anchors.fill: parent
        visible: root.mostrandoPlaceholder
        accent: root.accent
        accent2: root.accent2
        variacion: root.variacion
    }

    // --- la imagen --------------------------------------------------------

    Image {
        anchors.fill: parent
        visible: !root.mostrandoPlaceholder
        source: root._idx < root._candidatos.length ? root._candidatos[root._idx] : ""
        fillMode: root.fillMode
        asynchronous: true        // una URL remota no puede congelar la UI
        cache: true

        // Un escaneo real puede ser enorme y esto se dibuja chico (la tarjeta
        // del rail mide 148x166). Sin esto se decodifica la imagen entera en
        // memoria, por cada tarjeta.
        sourceSize.width: Math.max(1, Math.round(root.width * 2))

        onStatusChanged: {
            if (status === Image.Error) root._idx += 1;
        }
    }
}
