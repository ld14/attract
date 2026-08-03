// La sombra grande de los paneles elevados del diseno:
// "box-shadow: 0 20-40px 60-120px rgba(0,0,0,.5-.65)".
//
// Se usa envolviendo al item que proyecta la sombra:
//
//     Sombra { fuente: panel }
//     Item { id: panel; ... }
//
// La fuente se dibuja normal; esto solo agrega la sombra DEBAJO, asi que hay
// que declararlo ANTES que el panel en el mismo padre.
//
// Disponible desde que el experimento confirmo QtGraphicalEffects contra
// Pegasus real (themes/experimentos/graphical-effects.qml, 2026-08-03). Antes
// esto no se podia y las sombras eran una deuda anotada en Tokens.qml.
//
// ponytail: cada sombra es una pasada de GPU. Va en los paneles grandes y
// quietos (el de caratula, el box art), NO en cada tarjeta del rail — ahi
// serian tantas como delegates visibles y el rail se mueve todo el tiempo.
// Si algun dia hace falta ahi, medir primero.

import QtQuick 2.0
import QtGraphicalEffects 1.0
import ".."

DropShadow {
    id: root

    property Item fuente: null

    anchors.fill: fuente
    source: fuente
    cached: true            // el panel no cambia; se calcula una vez

    horizontalOffset: 0
    verticalOffset: Theme.shadowOffsetY
    radius: Theme.shadowRadius
    samples: 25             // acotado a mano: el default (2*radius+1 = 81) no
                            // se nota mas y cuesta bastante mas
    color: Theme.shadowSoft
}
