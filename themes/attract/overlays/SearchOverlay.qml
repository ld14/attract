import QtQuick 2.0
import ".."

FocusScope {
    id: root
    property var catalogo: null
    property color accent: Theme.accentNeutro
    property var resultados: []
    signal cerrar()
    signal abrirDetalle(var game)

    function enfocar() { entrada.forceActiveFocus(); }
    function abrirSeleccion() {
        if (lista.currentIndex >= 0 && lista.currentIndex < resultados.length)
            abrirDetalle(resultados[lista.currentIndex]);
    }
    function actualizar() {
        resultados = catalogo ? catalogo.buscar(entrada.text) : [];
        lista.currentIndex = resultados.length ? 0 : -1;
    }
    onVisibleChanged: if (visible) enfocar()
    Component.onCompleted: enfocar()

    Rectangle { anchors.fill: parent; color: "#ee04050a" }
    MouseArea { anchors.fill: parent; onClicked: root.enfocar() }
    Rectangle {
        id: panel
        anchors { fill: parent; margins: 48 }
        color: Theme.panelTop
        border.color: Theme.glassBorderHi
        radius: Theme.radiusPanel

        Text {
            x: 28; y: 22
            text: "BUSCAR EN LA BIBLIOTECA"
            color: Theme.textPrimary
            font { family: Theme.fontMono; pixelSize: 20; bold: true }
        }
        Text {
            x: 28; y: 58; width: parent.width - 56
            text: "Título, género, desarrolladora, editora, plataforma o año. Podés combinar palabras."
            color: Theme.textMuted
            font { family: Theme.fontMono; pixelSize: 12 }
            wrapMode: Text.WordWrap
        }
        Rectangle {
            x: 28; y: 100; width: parent.width - 56; height: 50
            color: Theme.glassFillHi; radius: 8; border.color: root.accent
            TextInput {
                id: entrada
                anchors { fill: parent; margins: 12 }
                color: Theme.textBright
                selectionColor: root.accent
                font { family: Theme.fontMono; pixelSize: 20 }
                clip: true
                selectByMouse: true
                maximumLength: 160
                onTextChanged: root.actualizar()
                // Antes de TextInput, solo comandos que no son letras.
                Keys.onPressed: {
                    if (event.key === Qt.Key_Escape) { root.cerrar(); event.accepted = true; }
                    else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        root.abrirSeleccion(); event.accepted = true;
                    } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Up) {
                        var step = event.key === Qt.Key_Down ? 1 : -1;
                        lista.currentIndex = Math.max(0, Math.min(root.resultados.length - 1, lista.currentIndex + step));
                        lista.positionViewAtIndex(lista.currentIndex, ListView.Contain);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                        event.accepted = true;
                    }
                }
            }
            Text {
                anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                visible: entrada.text.length === 0
                text: "Ej.: capcom 1992"
                color: Theme.textFaint
                font { family: Theme.fontMono; pixelSize: 20 }
            }
        }
        Text {
            x: 28; y: 164
            text: entrada.text.trim() === "" ? "Escribí para buscar en todos los campos."
                 : root.resultados.length === 0 ? "Sin resultados. Probá con otras palabras."
                 : root.resultados.length + " resultados"
            color: Theme.textMuted
            font { family: Theme.fontMono; pixelSize: 13 }
        }
        ListView {
            id: lista
            anchors { left: parent.left; right: parent.right; top: parent.top; bottom: pie.top
                leftMargin: 28; rightMargin: 28; topMargin: 194; bottomMargin: 16 }
            model: root.resultados
            clip: true
            spacing: 6
            delegate: Rectangle {
                width: lista.width; height: 62; radius: 8
                color: ListView.isCurrentItem ? Theme.glassFillHi : Theme.glassFill
                border.color: ListView.isCurrentItem ? root.accent : Theme.glassBorder
                Text {
                    x: 14; y: 8; width: parent.width - 28
                    text: modelData.title
                    color: Theme.textPrimary
                    elide: Text.ElideRight
                    font { family: Theme.fontMono; pixelSize: 17; bold: true }
                }
                Text {
                    x: 14; y: 35; width: parent.width - 28
                    text: [modelData.genre || "", modelData.developer || modelData.publisher || "",
                        modelData.releaseYear > 0 ? modelData.releaseYear : ""].filter(function(v) { return v !== ""; }).join(" · ")
                    color: Theme.textMuted
                    elide: Text.ElideRight
                    font { family: Theme.fontMono; pixelSize: 12 }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: { lista.currentIndex = index; root.abrirSeleccion(); }
                }
            }
        }
        Text {
            id: pie
            anchors { bottom: parent.bottom; bottomMargin: 22; horizontalCenter: parent.horizontalCenter }
            text: "↑ ↓ Seleccionar    Enter Ver detalle    Esc Cerrar"
            color: Theme.textBody
            font { family: Theme.fontMono; pixelSize: 13 }
        }
    }
    // Lo que TextInput no usa tampoco debe activar atajos de Pegasus/Home.
    Keys.onPressed: event.accepted = true
    Keys.onReleased: event.accepted = true
}
