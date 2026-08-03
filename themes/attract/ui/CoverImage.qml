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
// APROXIMACION A CSS: el coverBg() del prototipo apila radial + conic +
// linear. Qt Quick 5.15 no tiene conic-gradient y Canvas tampoco, asi que se
// deja radial + linear. La diferencia visual es minima (el conic aportaba un
// tinte suave en una esquina) y no justifica dibujar el gradiente a mano
// pixel por pixel.

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

    // --- la cadena --------------------------------------------------------

    readonly property var _candidatos: {
        if (!game || !game.assets) return [];
        var out = [];
        // El orden ES el contrato (CONVENCION #2.2). No reordenar sin cambiar
        // ese documento primero.
        var cadena = [game.assets.boxFront, game.assets.poster, game.assets.marquee];
        for (var i = 0; i < cadena.length; i++)
            if (cadena[i]) out.push(cadena[i]);
        return out;
    }

    property int _idx: 0
    onGameChanged: _idx = 0

    // --- ultimo eslabon: el color-wash ------------------------------------

    Canvas {
        anchors.fill: parent
        visible: root.mostrandoPlaceholder
        renderStrategy: Canvas.Cooperative

        property color a: root.accent
        property color b: root.accent2
        onAChanged: requestPaint()
        onBChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();

            // linear-gradient(150deg, accent2 0%, #0a0b10 66%)
            var lin = ctx.createLinearGradient(0, 0, width, height);
            lin.addColorStop(0.00, b);
            lin.addColorStop(0.66, "#0a0b10");
            lin.addColorStop(1.00, "#0a0b10");
            ctx.fillStyle = lin;
            ctx.fillRect(0, 0, width, height);

            // radial-gradient(140% 120% at X% Y%, accent 40%, transparent 50%)
            var cx = width * (0.18 + (root.variacion % 3) * 0.30);
            var cy = height * (0.14 + (root.variacion % 2) * 0.42);
            var r = Math.max(width, height) * 1.40;
            var rad = ctx.createRadialGradient(cx, cy, 0, cx, cy, r);
            rad.addColorStop(0.00, Theme.alpha(a, 0.40));
            rad.addColorStop(0.50, Theme.alpha(a, 0.00));
            ctx.fillStyle = rad;
            ctx.fillRect(0, 0, width, height);
        }
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
