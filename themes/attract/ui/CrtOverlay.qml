// CAPA 4: el filtro de tubo. Lineas finas que OSCURECEN, mas una vineta que
// apaga las esquinas como un CRT real.
//
// VIVE APARTE DE Background.qml A PROPOSITO. Las capas 1-3 van detras de todo;
// esta va ENCIMA de todo, incluidos los overlays de ayuda, trucos, visor y el
// popover de orden (background-texture-spec.md:37, z-index:80 en el prototipo).
// Mientras estuvo adentro de Background el filtro se dibujaba detras de la UI
// entera y no llegaba a tocar ni la barra ni las tarjetas. Se monta como ultimo
// hijo de `stage` en theme.qml.
//
// No necesita el equivalente de `pointer-events: none` del CSS: un Canvas sin
// MouseArea adentro no intercepta input en Qt Quick.
//
// Sobre el mix-blend-mode: multiply del CSS — no hace falta, y no es una
// aproximacion. Ver la cabecera de Background.qml: para negro puro el multiply
// y el blend normal dan el mismo pixel.

import QtQuick 2.0
import ".."

Canvas {
    id: root

    property bool activo: true

    visible: activo
    renderStrategy: Canvas.Cooperative

    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d");
        ctx.reset();

        // repeating-linear-gradient(0deg, rgba(0,0,0,.15) 0 1px, transparent 1px 3px)
        //
        // 0.15 directo y sin opacity de item: antes era rgba(0,0,0,.25) con
        // opacity 0.30, o sea alfa efectiva 0.075 — la MITAD de lo que pide el
        // prototipo (Pegasus Home.dc.html:340). Auditoria 2026-08-08.
        ctx.fillStyle = Qt.rgba(0, 0, 0, 0.15);
        for (var y = 0; y < height; y += 3)
            ctx.fillRect(0, y, width, 1);

        // radial-gradient(120% 120% at 50% 50%, transparent 64%, rgba(0,0,0,.5) 100%)
        //
        // Mismo achatamiento de elipse que el glow de la capa 1:
        // createRadialGradient solo hace circulos, asi que se escala el
        // contexto en y y se dibuja en coordenadas ya escaladas.
        //
        // 64% y .5 salen del HTML, no del .md del handoff, que dice 68% y .4
        // (background-texture-spec.md:28). Las dos fuentes no coinciden y se
        // toma el HTML: es contra ese archivo que se compara a ojo.
        var cx = width * 0.50;
        var cy = height * 0.50;
        var rx = width * 1.20;
        var ry = height * 1.20;
        var k = ry / rx;

        ctx.save();
        ctx.scale(1, k);
        var g = ctx.createRadialGradient(cx, cy / k, 0, cx, cy / k, rx);
        g.addColorStop(0.00, Qt.rgba(0, 0, 0, 0.0));
        g.addColorStop(0.64, Qt.rgba(0, 0, 0, 0.0));
        g.addColorStop(1.00, Qt.rgba(0, 0, 0, 0.5));
        ctx.fillStyle = g;
        ctx.fillRect(0, 0, width, height / k);
        ctx.restore();
    }
}
