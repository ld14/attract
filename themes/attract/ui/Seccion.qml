// La regla que encabeza cada seccion del overlay de trucos: etiqueta en
// accent, subrayado que se desvanece, y contador a la derecha.
//
// El subrayado en degrade es del diseno y no es decorativo: separa las
// secciones sin meter una linea dura que corte el tablero en dos.

import QtQuick 2.0
import ".."

Item {
    id: root

    property string etiqueta: ""
    property string contador: ""
    property color accent: Theme.accentNeutro

    height: 18

    Text {
        id: txt
        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
        text: root.etiqueta
        color: root.accent
        font.family: Theme.fontMono
        font.pixelSize: 11
        font.bold: true
        font.letterSpacing: Theme.trackingLabel * 11
    }

    // Con Canvas y no con un Gradient: `orientation: Gradient.Horizontal`
    // existe desde QtQuick 2.12 y el theme importa 2.0, que es la version que
    // se sabe que carga contra este binario. Mismo criterio que Background y
    // AccentWash — Rectangle solo hace gradientes verticales en 2.0.
    Canvas {
        id: subrayado
        anchors { left: txt.right; leftMargin: 12; right: cont.left; rightMargin: 12 }
        anchors.verticalCenter: parent.verticalCenter
        height: 1
        renderStrategy: Canvas.Cooperative

        property color c: root.accent
        onCChanged: requestPaint()
        onWidthChanged: requestPaint()

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            var g = ctx.createLinearGradient(0, 0, width, 0);
            g.addColorStop(0.0, Theme.alpha(c, 0.5));
            g.addColorStop(1.0, Theme.alpha(c, 0.0));
            ctx.fillStyle = g;
            ctx.fillRect(0, 0, width, height);
        }
    }

    Text {
        id: cont
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        text: root.contador
        color: Theme.textFaint
        font.family: Theme.fontMono
        font.pixelSize: 10
    }
}
