// El overlay "Cómo se juega" (feature 028, spec/features/028-theme-como-se-juega/).
//
// Sin bosquejo de referencia (docs/como-se-juega.md decision 7: el bosquejo
// original es solo orden/ubicación de la fila de tarjetas) — el panel en si
// sigue el mismo lenguaje visual que CheatsOverlay (escuadras HUD, panel de
// vidrio), pero con su propio contenido: diagrama, objetivo, primeros
// pasos, reglas esenciales, salida, periféricos, JUGAR.
//
// LA TARJETA SIEMPRE ABRE (criterio de aceptación): sin `guia` propia
// (`datos.hayGuia === false`), este overlay muestra la ayuda general del
// gabinete (Gabinete.qml) — crédito/start genéricos y la tecla de salida del
// emulador de este juego — con el aviso "Sin guía específica para este
// juego". Nunca queda deshabilitado ni vacío.
//
// JUGAR reusa `root.lanzar(game)` de theme.qml (mismo camino que el botón
// JUGAR del detalle) — no hay un segundo mecanismo de lanzamiento.
//
// Accesos a Hacks/Manual: emiten señales en vez de abrir un Loader
// directamente, porque theme.qml es quien sabe volver a este overlay al
// cerrarlos (ADR-0038 / plan.md §volverAGuiaAlCerrar).

import QtQuick 2.0
import QtGraphicalEffects 1.0
import ".."
import "../ui"

FocusScope {
    id: root

    property var datos: null            // el GameData del juego
    property var gabinete: null         // core/Gabinete.qml, instanciado en theme.qml
    property var correspondencia: null  // core/Correspondencia.qml
    property string titulo: ""
    property string sistema: ""         // "mame" | "dosbox" | "" — para la tecla de salida
    property color accent: Theme.accentNeutro
    property Item fondo: null

    signal cerrar()
    signal jugar()
    signal abrirHacksDesdeGuia()
    signal abrirManualDesdeGuia()

    anchors.fill: parent

    readonly property bool hayGuia: datos ? datos.hayGuia : false

    // La tecla de salida efectiva: la del artefacto de 027 si el juego es
    // DOSBox y ya se resolvió (puede diferir de la del emulador si el juego
    // trae mapperfile propio), si no la del perfil por sistema — nunca una
    // constante fija en el theme (criterio de aceptación de la spec).
    //
    // FUNCION, no `readonly property` encadenada: si algo de la cadena
    // (gabinete/correspondencia todavia sin cargar, sistema vacio) tira una
    // excepcion, un `try/catch` explicito evita que la propiedad quede en
    // un estado invalido y en blanco sin ningun aviso - se vio en el
    // gabinete real el 2026-09-29 con Pacman: la seccion "COMO SALIR"
    // aparecia completamente vacia, ni el texto ni el fallback.
    function _teclaSalidaCalculada() {
        try {
            if (!gabinete) return "";
            if (sistema === "dosbox" && correspondencia && correspondencia.salidaJuego)
                return correspondencia.salidaJuego.tecla || "";
            return gabinete.teclaSalida(sistema) || "";
        } catch (e) {
            console.log("ATTRACT: error calculando la tecla de salida (sistema=" + sistema + "): " + e);
            return "";
        }
    }

    // Periféricos que la guía pide y el gabinete NO tiene instalados —
    // requisito, nunca un botón (criterio de aceptación).
    readonly property var _perifericosFaltantes: {
        if (!datos || !gabinete) return [];
        var out = [];
        var decl = datos.guiaPerifericos;
        for (var i = 0; i < decl.length; i++) {
            var p = decl[i];
            if (p === "joy" || p === "keyboard" || p === "mouse") continue; // siempre presentes
            if (!gabinete.perifericoInstalado(p)) out.push(p);
        }
        return out;
    }

    readonly property bool _palancaDeshabilitada:
        sistema === "dosbox" && correspondencia && correspondencia.joysticktype === "disabled"

    // --- acciones enfocables: JUGAR, [Hacks], [Manual] --------------------
    property int foco: 0
    readonly property var _acciones: {
        var out = [{ tipo: "jugar" }];
        if (datos && datos.hayCheats) out.push({ tipo: "hacks" });
        if (datos && datos.hayManualPaginas) out.push({ tipo: "manual" });
        return out;
    }

    // --- fondo --------------------------------------------------------------

    FastBlur {
        anchors.fill: parent
        source: root.fondo
        radius: 40
        visible: root.fondo !== null
        cached: true
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(5/255, 6/255, 9/255, 0.86)
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.cerrar()
    }

    // --- el panel -------------------------------------------------------------

    Item {
        id: panel
        width: Math.min(880, parent.width - 2 * Theme.gutter)
        height: Math.min(parent.height * 0.88, contenido.height + 132)
        anchors.centerIn: parent

        Rectangle {
            anchors.fill: parent
            radius: 4
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#0e1119" }
                GradientStop { position: 1.0; color: "#07080c" }
            }
            border.width: 1
            border.color: Theme.alpha(root.accent, 0.45)
        }

        Repeater {
            model: [[0, 0], [1, 0], [0, 1], [1, 1]]
            Item {
                width: 16; height: 16
                x: modelData[0] === 0 ? -1 : panel.width - 15
                y: modelData[1] === 0 ? -1 : panel.height - 15
                Rectangle {
                    width: 16; height: 2
                    anchors.top: modelData[1] === 0 ? parent.top : undefined
                    anchors.bottom: modelData[1] === 1 ? parent.bottom : undefined
                    anchors.left: modelData[0] === 0 ? parent.left : undefined
                    anchors.right: modelData[0] === 1 ? parent.right : undefined
                    color: root.accent
                }
                Rectangle {
                    width: 2; height: 16
                    anchors.top: modelData[1] === 0 ? parent.top : undefined
                    anchors.bottom: modelData[1] === 1 ? parent.bottom : undefined
                    anchors.left: modelData[0] === 0 ? parent.left : undefined
                    anchors.right: modelData[0] === 1 ? parent.right : undefined
                    color: root.accent
                }
            }
        }

        // --- cabecera -------------------------------------------------------

        Item {
            id: cabecera
            anchors { top: parent.top; left: parent.left; right: parent.right }
            anchors.margins: 18
            height: 46

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 14

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 40; height: 40
                    radius: 8
                    color: Theme.alpha(root.accent, 0.14)
                    border.width: 1
                    border.color: Theme.alpha(root.accent, 0.45)
                    Text {
                        anchors.centerIn: parent
                        text: "✛"
                        color: root.accent
                        font.pixelSize: 20
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3
                    Text {
                        text: "CÓMO SE JUEGA"
                        color: Theme.textBright
                        font.family: Theme.fontDisplay
                        font.bold: true
                        font.pixelSize: 20
                        font.letterSpacing: 0.05 * 20
                    }
                    Text {
                        text: root.titulo
                        color: Theme.textFaint
                        font.family: Theme.fontMono
                        font.pixelSize: 10
                        font.letterSpacing: 0.08 * 10
                    }
                }
            }

            Boton {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                texto: ""; glifo: "✕"; variant: "glass"; accent: root.accent
                implicitWidth: 32; implicitHeight: 30
                onActivado: root.cerrar()
            }
        }

        Rectangle {
            id: reglaCabecera
            anchors { top: cabecera.bottom; topMargin: 12 }
            anchors { left: parent.left; right: parent.right; leftMargin: 18; rightMargin: 18 }
            height: 1
            color: Theme.alpha(root.accent, 0.22)
        }

        // --- cuerpo -----------------------------------------------------------

        Flickable {
            id: scroll
            anchors { top: reglaCabecera.bottom; topMargin: 16 }
            anchors { left: parent.left; right: parent.right; bottom: pie.top }
            anchors { leftMargin: 18; rightMargin: 18; bottomMargin: 12 }
            contentHeight: contenido.height
            clip: true
            interactive: true

            Column {
                id: contenido
                width: scroll.width
                spacing: 18

                // Aviso de guia ausente — la tarjeta SIEMPRE abre igual.
                Text {
                    width: parent.width
                    visible: !root.hayGuia
                    text: "Sin guía específica para este juego — ayuda general del gabinete."
                    color: Theme.textFaint
                    font.family: Theme.fontBody
                    font.italic: true
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                }

                // --- objetivo ---
                Seccion {
                    width: parent.width
                    etiqueta: "OBJETIVO"
                    accent: root.accent
                }
                Text {
                    width: parent.width
                    text: root.hayGuia ? root.datos.guiaObjetivo
                                       : "Insertá crédito, empezá la partida y jugá — este juego no tiene una guía propia todavía."
                    color: Theme.textBody
                    font.family: Theme.fontBody
                    font.pixelSize: 13
                    wrapMode: Text.WordWrap
                }

                // --- diagrama de controles ---
                Seccion {
                    width: parent.width
                    visible: root.hayGuia && root.datos.guiaAcciones.length > 0
                    etiqueta: "CONTROLES"
                    accent: root.accent
                }
                ControlDiagram {
                    visible: root.hayGuia && root.datos.guiaAcciones.length > 0
                    acciones: root.hayGuia ? root.datos.guiaAcciones : []
                    controlesDeclarados: root.correspondencia ? root.correspondencia.controlesDeclarados : []
                    accent: root.accent
                }

                // --- periférico requerido, si falta ---
                Text {
                    width: parent.width
                    visible: root._perifericosFaltantes.length > 0
                    text: "Requiere " + root._perifericosFaltantes.join(", ") +
                          " — este gabinete no lo tiene instalado."
                    color: "#e0453f"
                    font.family: Theme.fontBody
                    font.bold: true
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                }

                // --- palanca deshabilitada (DOS) ---
                Text {
                    width: parent.width
                    visible: root._palancaDeshabilitada
                    text: "Este juego usa teclado" +
                          (root.datos && root.datos.guiaPerifericos.indexOf("mouse") >= 0 ? " y mouse" : "") +
                          " — la palanca está deshabilitada para este juego."
                    color: Theme.textMuted
                    font.family: Theme.fontBody
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                }

                // --- primeros pasos ---
                Seccion {
                    width: parent.width
                    visible: root.hayGuia && root.datos.guiaPrimerosPasos.length > 0
                    etiqueta: "PRIMEROS PASOS"
                    accent: root.accent
                }
                Column {
                    width: parent.width
                    spacing: 6
                    visible: root.hayGuia && root.datos.guiaPrimerosPasos.length > 0
                    Repeater {
                        model: root.hayGuia ? root.datos.guiaPrimerosPasos : []
                        Row {
                            spacing: 10
                            width: contenido.width
                            Text {
                                text: (index + 1) + "."
                                color: root.accent
                                font.bold: true
                                font.family: Theme.fontMono
                                font.pixelSize: 13
                            }
                            Text {
                                width: parent.width - 24
                                text: modelData
                                wrapMode: Text.WordWrap
                                color: Theme.textBody
                                font.family: Theme.fontBody
                                font.pixelSize: 13
                            }
                        }
                    }
                }

                // --- reglas esenciales ---
                Seccion {
                    width: parent.width
                    visible: root.hayGuia && root.datos.guiaReglasEsenciales.length > 0
                    etiqueta: "REGLAS ESENCIALES"
                    accent: root.accent
                }
                Column {
                    width: parent.width
                    spacing: 6
                    visible: root.hayGuia && root.datos.guiaReglasEsenciales.length > 0
                    Repeater {
                        model: root.hayGuia ? root.datos.guiaReglasEsenciales : []
                        Row {
                            spacing: 10
                            width: contenido.width
                            Text { text: "•"; color: root.accent; font.pixelSize: 13 }
                            Text {
                                width: parent.width - 20
                                text: modelData
                                wrapMode: Text.WordWrap
                                color: Theme.textBody
                                font.family: Theme.fontBody
                                font.pixelSize: 13
                            }
                        }
                    }
                }

                // --- multijugador ---
                Text {
                    width: parent.width
                    visible: root.hayGuia && root.datos.guiaMultijugadorJugadores > 1
                    text: "Multijugador: " +
                          (root.datos ? root.datos.guiaMultijugadorModo : "") +
                          " (" + (root.datos ? root.datos.guiaMultijugadorJugadores : 0) + " jugadores)"
                    color: Theme.textMuted
                    font.family: Theme.fontMono
                    font.pixelSize: 11
                }

                // --- como salir ---
                Seccion { width: parent.width; etiqueta: "CÓMO SALIR"; accent: root.accent }
                Text {
                    width: parent.width
                    readonly property string _tecla: root._teclaSalidaCalculada()
                    text: _tecla !== ""
                        ? "Apretá " + _tecla + " para volver a Pegasus."
                        // Con sistema/gabinete a la vista: si esto se ve, ya sabemos
                        // que dato faltó sin tener que mirar el log de Pegasus.
                        : "No se pudo determinar la tecla de salida (sistema: '" +
                          root.sistema + "', perfil: " +
                          (root.gabinete ? "cargado" : "sin cargar") + ")."
                    color: Theme.textBody
                    font.family: Theme.fontBody
                    font.pixelSize: 13
                    wrapMode: Text.WordWrap
                }
            }
        }

        // --- pie: JUGAR + accesos ------------------------------------------

        Row {
            id: pie
            anchors { bottom: parent.bottom; bottomMargin: 16 }
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 14

            Repeater {
                model: root._acciones

                Boton {
                    readonly property bool _activo: root.foco === index
                    texto: modelData.tipo === "jugar" ? "▶ JUGAR"
                         : modelData.tipo === "hacks" ? "☠ HACKS"
                         : "❐ MANUAL"
                    variant: modelData.tipo === "jugar" ? "accent" : "glass"
                    accent: root.accent
                    activo: _activo
                    onActivado: root._activar(modelData.tipo)
                }
            }
        }
    }

    function _activar(tipo) {
        if (tipo === "jugar") root.jugar();
        else if (tipo === "hacks") root.abrirHacksDesdeGuia();
        else if (tipo === "manual") root.abrirManualDesdeGuia();
    }

    Keys.onPressed: {
        if (api.keys.isCancel(event)) {
            root.cerrar(); event.accepted = true;
        } else if (event.key === Qt.Key_Right) {
            root.foco = Math.min(root._acciones.length - 1, root.foco + 1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Left) {
            root.foco = Math.max(0, root.foco - 1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Down) {
            scroll.contentY = Math.min(
                Math.max(0, scroll.contentHeight - scroll.height),
                scroll.contentY + 60);
            event.accepted = true;
        } else if (event.key === Qt.Key_Up) {
            scroll.contentY = Math.max(0, scroll.contentY - 60);
            event.accepted = true;
        } else if (api.keys.isAccept(event) && !event.isAutoRepeat) {
            root._activar(root._acciones[root.foco].tipo);
            event.accepted = true;
        }
    }
}
