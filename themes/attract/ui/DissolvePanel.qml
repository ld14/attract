// El fundido de cuatro bordes que se PINTA ENCIMA de un panel de video para
// que se disuelva contra el fondo, sin marco ni esquinas (feature 026).
//
// POR QUE ENCIMA Y NO UNA MASCARA: el prototipo lo probo con `mask-image` y la
// capa acelerada del video dejaba una linea de 1 px en el canto de la mascara
// (Diseños/design_handoff_platform_select/README.md §Panel de video). Pintar
// del color del fondo sobre el video no tiene canto que dejar: el video queda
// intacto abajo y lo que se ve en el borde es color plano.
//
// El precio es que funde contra UN color, no contra lo que haya detras. Sirve
// porque el panel vive a la izquierda del selector, sobre el scrim horizontal
// que ya lleva esa zona a casi negro (rgba(6,7,12,.9-.97)). Movido a una zona
// con fondo claro o teñido, se veria el rectangulo — ahi haria falta el
// keying por luminancia de screens/HeroVideoPreview.qml.
//
// LO QUE TRADUCE, del CSS del diseño:
//
//   box-shadow: inset 0 0 30px 14px #07080d,
//               inset 0 0 78px 34px rgba(7,8,13,.9)
//     -> una franja por borde con degradado lineal hacia adentro. Un inset
//        shadow con spread S y blur B es opaco hasta ~S-B/2 y se apaga en
//        ~S+B/2; las dos sombras juntas dan las paradas de abajo.
//   background: radial-gradient(118% 122% at 50% 50%,
//               transparent 52%, rgba(7,8,13,.75) 84%, #07080d 100%)
//     -> createRadialGradient sobre un contexto escalado, porque el CSS pide
//        una ELIPSE y Canvas solo hace circulos (docs/plataforma-pegasus.md
//        §Cosas de CSS que Qt Quick 5.15 no tiene).
//
// Canvas y no Rectangle: Rectangle en Qt 5 solo hace gradientes verticales, y
// apilar rectangulos no hace un degradado radial.

import QtQuick 2.0
import ".."

Canvas {
    id: root

    // El negro del video del diseño (#07080d).
    property color color: "#07080d"

    renderStrategy: Canvas.Cooperative
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onColorChanged: requestPaint()
    // UN CANVAS INVISIBLE NO PINTA, y el pedido no queda en cola
    // (docs/plataforma-pegasus.md §3). El panel de video arranca con opacidad
    // 0 —visible false— hasta que el clip reproduce, asi que el requestPaint
    // del tamaño llegaba con el Canvas invisible y se perdia: en Pegasus
    // (2026-09-22) el video salia como un rectangulo duro, sin fundido.
    // `visible` es la visibilidad efectiva: cambia tambien cuando se prende
    // el padre.
    onVisibleChanged: if (visible) requestPaint()
    onAvailableChanged: if (available) requestPaint()

    onPaint: {
        var ctx = getContext("2d");
        ctx.reset();
        var w = width, h = height;
        if (w <= 0 || h <= 0) return;

        var c = Theme.alpha(root.color, 1);
        function rgba(a) { return Qt.rgba(c.r, c.g, c.b, a); }

        // --- las dos sombras inset, una franja por borde ---
        var ancho = 73;           // 34 + 78/2: donde se apaga la segunda
        var paradas = [[0, 1.0], [14 / ancho, 0.85], [40 / ancho, 0.45], [1, 0]];

        function franja(x0, y0, x1, y1, rx, ry, rw, rh) {
            var g = ctx.createLinearGradient(x0, y0, x1, y1);
            for (var i = 0; i < paradas.length; i++)
                g.addColorStop(paradas[i][0], rgba(paradas[i][1]));
            ctx.fillStyle = g;
            ctx.fillRect(rx, ry, rw, rh);
        }
        var a = Math.min(ancho, w / 2, h / 2);
        franja(0, 0, a, 0, 0, 0, a, h);             // izquierda
        franja(w, 0, w - a, 0, w - a, 0, a, h);     // derecha
        franja(0, 0, 0, a, 0, 0, w, a);             // arriba
        franja(0, h, 0, h - a, 0, h - a, w, a);     // abajo

        // --- el radial, como elipse 118% x 122% centrada ---
        var rx = 1.18 * w, ry = 1.22 * h;
        ctx.save();
        ctx.translate(w / 2, h / 2);
        ctx.scale(1, ry / rx);
        var rg = ctx.createRadialGradient(0, 0, 0, 0, 0, rx);
        rg.addColorStop(0.00, rgba(0));
        rg.addColorStop(0.52, rgba(0));
        rg.addColorStop(0.84, rgba(0.75));
        rg.addColorStop(1.00, rgba(1));
        ctx.fillStyle = rg;
        // El rectangulo en coordenadas escaladas: el alto se estira por rx/ry.
        ctx.fillRect(-w / 2, -(h / 2) * (rx / ry), w, h * (rx / ry));
        ctx.restore();
    }
}
