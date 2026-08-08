// Las tres capas de fondo que van DETRAS de todas las pantallas
// (handoff #Background treatment):
//
//   1. ambient backdrop  — gradiente vertical oscuro + glow del accent
//   2. scanlines         — deriva infinita, SIEMPRE presente
//   3. vineta            — legibilidad del texto sobre el arte
//
// La cuarta capa del handoff (el overlay CRT) NO esta aca: va por ENCIMA de
// toda la UI, asi que vive en ui/CrtOverlay.qml.
//
// El accent entra como propiedad, no se lee de Theme: es un dato por juego
// (ADR-0013) y este fondo cambia de color al mover el foco en la libreria.
//
// APROXIMACIONES A CSS QUE Qt 5.15 NO TIENE (el handoff pide que se anoten):
//
//   radial-gradient()      -> Canvas.createRadialGradient. Equivalente real,
//                             no una aproximacion: Canvas si tiene gradientes
//                             radiales, lo que no los tiene es Rectangle.
//   mix-blend-mode: screen -> NO HACE FALTA, y esto NO es una aproximacion.
//                             La capa 2 es blanco puro, y para blanco puro el
//                             screen y el blend normal dan el MISMO pixel:
//                             screen(c, 1) = 1 - (1-c)(1-1) = 1, y componer
//                             eso con alfa a da c(1-a) + a, que es exactamente
//                             el blend normal de blanco a alfa a. Lo mismo vale
//                             para el multiply con negro puro del overlay CRT:
//                             multiply(c, 0) = 0, y componerlo da c(1-a).
//                             Los blend-modes solo se notarian con un color que
//                             no fuera blanco o negro puro, y no hay ninguno.
//                             (Verificado algebraicamente, auditoria 2026-08-08.)
//   repeating-linear-      -> Canvas pintado una sola vez, animando la y. Mas
//   gradient + animacion      barato que un shader y no necesita ningun
//                             modulo extra, que es justo lo que no sabemos si
//                             existe (ver themes/experimentos/graphical-effects.qml).
//
// Todo esto usa solo QtQuick 2.0: si el experimento de QtGraphicalEffects
// falla, este archivo no cambia una linea.

import QtQuick 2.0
import ".."

Item {
    id: root

    property color accent: Theme.accentNeutro

    // --- CAPA 1: gradiente vertical oscuro + glow de accent arriba a la derecha
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.panelTop }
            GradientStop { position: 1.0; color: Theme.panelBottom }
        }
    }

    Canvas {
        id: glow
        anchors.fill: parent

        // 0.22 y no 0.55: con 0.55 el accent no era un halo, era un lavado —
        // la mitad superior de la pantalla quedaba del color del juego y se
        // comia el contraste de la barra y del titulo. Comparado contra el
        // diseño de referencia el 2026-08-06: ahi el tinte apenas se insinua
        // en la esquina superior derecha.
        opacity: 0.22
        renderStrategy: Canvas.Cooperative

        // Repintar al cambiar de juego: el glow es del color del juego enfocado.
        property color acc: root.accent
        onAccChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();

            // radial-gradient(130% 100% at 72% 8%, accent 0%, transparent 46%)
            //
            // Ese "130% 100%" es una ELIPSE: 130% del ancho por 100% del alto.
            // createRadialGradient solo hace circulos, asi que se escala el
            // contexto en y para achatarlo. Sin esto el glow se derrama sobre
            // media pantalla en vez de quedar arriba a la derecha - se vio en
            // la primera corrida contra Pegasus real.
            var cx = width * 0.72;
            var cy = height * 0.08;
            // 1.0 y no 1.30: con 1.30 el halo llegaba hasta el borde izquierdo
            // y dejaba de leerse como "arriba a la derecha". El centro sigue
            // en 72%/8% como el CSS; lo que se achico es el alcance.
            var rx = width * 1.00;
            var ry = height * 1.00;
            var k = ry / rx;             // factor de achatamiento

            ctx.save();
            ctx.scale(1, k);
            var g = ctx.createRadialGradient(cx, cy / k, 0, cx, cy / k, rx);
            g.addColorStop(0.00, Theme.alpha(acc, 1.0));
            g.addColorStop(0.46, Theme.alpha(acc, 0.0));
            g.addColorStop(1.00, Theme.alpha(acc, 0.0));
            ctx.fillStyle = g;
            ctx.fillRect(0, 0, width, height / k);
            ctx.restore();
        }
    }

    // --- CAPA 2: scanlines con deriva (ambiente CRT, decorativo)
    // SIEMPRE presente, independiente del toggle CRT: es la textura que hace
    // que el fondo se vea vivo incluso con el tubo apagado.
    //
    // El patron se pinta UNA vez y despues solo se mueve la y: no hay repintado
    // por frame. El alto extra de un periodo es lo que hace que el loop se vea
    // continuo en vez de saltar.
    Item {
        anchors.fill: parent
        clip: true
        opacity: 0.12

        Canvas {
            id: scan
            width: parent.width
            height: parent.height + 8
            renderStrategy: Canvas.Cooperative

            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                ctx.fillStyle = Qt.rgba(1, 1, 1, 0.05);
                for (var y = 0; y < height; y += 8)
                    ctx.fillRect(0, y, width, 2);
            }

            // 233 ms POR CICLO, no 7000. El CSS anima background-position de
            // 0 a 240px en 7s (Pegasus Home.dc.html:20, @keyframes pgdrift), y
            // 240 = 30 x 8: son TREINTA periodos del patron en esos 7s, o sea
            // 7000/30 = 233ms cada uno, ~34 px/s.
            //
            // Con duration: 7000 aca se hacia UN solo periodo en 7s (1.14 px/s):
            // 30 veces mas lento, y a esa velocidad la deriva es indistinguible
            // de una textura fija. Ese era el motivo real de que el fondo se
            // viera plano — no que faltara la capa. Auditoria 2026-08-08.
            NumberAnimation on y {
                from: -8; to: 0
                duration: 233
                loops: Animation.Infinite
                running: true
            }
        }
    }

    // --- CAPA 3: vineta.
    //
    // DIVERGE A PROPOSITO del gradiente vertical unico del prototipo
    // (4 paradas: 0%→.55, 26%→.2, 62%→.78, 100%→.97 — Pegasus Home.dc.html:35).
    // Aca son DOS gradientes, horizontal + vertical, porque el proposito es
    // otro: la columna izquierda (hero) tiene que leerse por encima de
    // CUALQUIER caratula clara de estante que quede detras, y un solo
    // gradiente vertical no protege esa columna en particular. Los colores
    // base coinciden (~#06070c); la forma no. Auditoria de fidelidad,
    // 2026-08-08.
    //
    // Mantiene legible el texto de la columna izquierda
    // por encima de cualquier arte mas claro que haya detras.
    Canvas {
        anchors.fill: parent
        renderStrategy: Canvas.Cooperative

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();

            // izquierda -> derecha
            var h = ctx.createLinearGradient(0, 0, width, 0);
            h.addColorStop(0.00, Qt.rgba(0.027, 0.031, 0.047, 0.92));
            h.addColorStop(0.42, Qt.rgba(0.027, 0.031, 0.047, 0.55));
            h.addColorStop(1.00, Qt.rgba(0.027, 0.031, 0.047, 0.20));
            ctx.fillStyle = h;
            ctx.fillRect(0, 0, width, height);

            // abajo -> arriba
            var v = ctx.createLinearGradient(0, height, 0, 0);
            v.addColorStop(0.00, Qt.rgba(0.027, 0.031, 0.047, 0.96));
            v.addColorStop(0.45, Qt.rgba(0.027, 0.031, 0.047, 0.0));
            ctx.fillStyle = v;
            ctx.fillRect(0, 0, width, height);
        }
    }

    // La CAPA 4 (overlay CRT) NO esta aca: va encima de toda la UI, no detras.
    // Vive en ui/CrtOverlay.qml y la monta theme.qml como ultimo hijo de stage.
}
