// El gradiente tenido con el accent de un juego. Es el `coverBg()` del
// prototipo, y lo usan DOS cosas distintas:
//
//   - CoverImage, como ultimo eslabon de la cadena de CONVENCION #2.2 cuando
//     ninguna imagen carga.
//   - Las tarjetas del rail de la libreria, donde NO es un fallback: el
//     diseno las quiere asi, tenidas con el color del juego y con el titulo
//     encima, no con la caratula.
//
// Vive aparte porque son el mismo dibujo con dos significados. Duplicarlo
// seria dos Canvas que hay que mantener sincronizados a mano.
//
// APROXIMACION A CSS: el prototipo apila radial + conic + linear. Qt Quick
// 5.15 no tiene conic-gradient, ni en Rectangle ni en Canvas, asi que queda
// radial + linear. El conic aportaba un tinte suave en una esquina; la
// diferencia visual es minima y no justifica dibujarlo pixel por pixel.

import QtQuick 2.0
import ".."

Canvas {
    id: root

    property color accent: Theme.accentNeutro
    property color accent2: Theme.accent2Neutro

    // El diseno varia el centro y el angulo por posicion, para que dos juegos
    // seguidos en el rail no se vean identicos.
    property int variacion: 0

    renderStrategy: Canvas.Cooperative

    onAccentChanged: requestPaint()
    onAccent2Changed: requestPaint()
    onVariacionChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d");
        ctx.reset();

        // linear-gradient(150deg, accent2 0%, #0a0b10 66%)
        var lin = ctx.createLinearGradient(0, 0, width, height);
        lin.addColorStop(0.00, accent2);
        lin.addColorStop(0.66, "#0a0b10");
        lin.addColorStop(1.00, "#0a0b10");
        ctx.fillStyle = lin;
        ctx.fillRect(0, 0, width, height);

        // radial-gradient(140% 120% at X% Y%, accent 40%, transparent 50%)
        var cx = width * (0.18 + (variacion % 3) * 0.30);
        var cy = height * (0.14 + (variacion % 2) * 0.42);
        var r = Math.max(width, height) * 1.40;
        var rad = ctx.createRadialGradient(cx, cy, 0, cx, cy, r);
        rad.addColorStop(0.00, Theme.alpha(accent, 0.40));
        rad.addColorStop(0.50, Theme.alpha(accent, 0.00));
        ctx.fillStyle = rad;
        ctx.fillRect(0, 0, width, height);
    }
}
