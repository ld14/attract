// Las tarjetas de CONTENIDO EXTRA del detalle: Cómo se juega, Galería, Hacks
// (trucos y combos) y Manual digitalizado.
//
// LAS REVISTAS NO ESTAN ACA A PROPOSITO. El handoff es explicito: viven solo
// en el carrusel de la columna izquierda, no se duplican como tarjeta. Ese
// carrusel llega con la feature 006.
//
// DIVERGENCIA CONSCIENTE RESPECTO DEL HANDOFF: el handoff omite la tarjeta
// cuando el juego no tiene ese contenido, y muestra una fila punteada solo
// cuando no tiene NINGUNO. CONVENCION #2.3 dice lo contrario y gana: las
// cuatro tarjetas estan siempre, y la que no tiene contenido dice "No
// Disponible" - salvo "Cómo se juega", que SIEMPRE abre (feature 028): sin
// guia propia muestra la ayuda general del gabinete, nunca queda deshabilitada.
//
// "CÓMO SE JUEGA" ENTRA PRIMERA Y SIN SUBTITULO PROPIO (decision 8 de
// docs/como-se-juega.md): una guia no tiene un conteo natural como "N
// piezas". Y CON LAS CUATRO, EL SUBTITULO POR TARJETA SE SACA Y PASA A UNA
// LINEA COMPARTIDA debajo de la fila (decision 8b): a 200px por tarjeta no
// entra un subtitulo propio en cada una sin repetir el problema que ya
// documentaba este archivo con 3×250. La linea compartida muestra el
// detalle de la tarjeta ENFOCADA, o nada si `foco` es -1.
//
// Las tarjetas miden 145px de ANCHO (no 200): con 200 y spacing 14, la fila
// de CUATRO mide 842px — pero el presupuesto real de este hueco (entre
// izquierda.right+48 y derecha.left-32, medido sobre DetailScreen.qml a
// 1280px de lienzo) es ~634px, y `extras` no tiene anchor a la derecha que
// lo frene. Con 3 tarjetas (200px) entraba de casualidad (628px); con 4 se
// vio pisando la columna de FORMATO/reseña en Pegasus real (2026-09-29,
// pantalla de detalle de Pacman).
//
// El ANCHO de 145px (610px de fila) ya entraba bien y ninguna etiqueta
// necesitaba elidir - se probó achicarlo mas por gusto ("menos impacto
// visual") pero el autor pidió volver el ancho atrás y bajar el ALTO en su
// lugar: 66px -> 56px -> 28px -> 40px -> 45px (el icono/tipografia de 28px
// se dejaron igual todo este tramo, solo se le devolvio aire vertical a la
// tarjeta). La etiqueta de la primera tarjeta se acorta a "Guía" (el
// overlay adentro sigue diciendo "CÓMO SE JUEGA"
// completo) porque a 145px "Cómo se juega" no entra sin elidir.

import QtQuick 2.0
import ".."
import "../ui"

Column {
    id: root

    property var datos: null
    property color accent: Theme.accentNeutro
    property int foco: -1               // indice enfocado, -1 = ninguno

    signal abrir(string tipo)

    spacing: 12

    SectionLabel {
        text: "CONTENIDO EXTRA"
        activo: root.foco >= 0
        accent: root.accent
    }

    Row {
        // 4×145 + 3×10 = 610px de fila, contra un presupuesto real de
        // ~634px (ver encabezado del archivo).
        spacing: 10

        Repeater {
            model: [
                {
                    // Glifo del mismo estilo que los otros tres (Dingbats/
                    // Geometric Shapes, no emoji): un emoji de color depende
                    // de una fuente que Pegasus/Qt 5.15 puede no tener.
                    // Etiqueta corta ("Guía", no "Cómo se juega"): a 145px de
                    // tarjeta el título completo no entra sin elidir. El
                    // overlay sigue mostrando "CÓMO SE JUEGA" entero.
                    tipo: "guia",
                    glifo: "✛",
                    etiqueta: "Guía",
                    hay: true   // la tarjeta SIEMPRE abre (feature 028)
                },
                {
                    tipo: "galeria",
                    glifo: "▣",
                    etiqueta: "Galería",
                    hay: root.datos ? root.datos.hayGaleria : false
                },
                {
                    tipo: "cheats",
                    glifo: "☠",
                    etiqueta: "Hacks",
                    hay: root.datos ? root.datos.hayCheats : false
                },
                {
                    tipo: "manual",
                    glifo: "❐",
                    etiqueta: "Manual",
                    hay: root.datos ? root.datos.hayManual : false
                }
            ]

            Item {
                id: tarjeta
                width: 145
                height: 45

                readonly property bool enfocada: root.foco === index
                readonly property bool disponible: modelData.hay

                // Por transform y no por `y`: un Row tambien escribe la y de
                // sus hijos. Mismo motivo que en ui/Boton.qml.
                transform: Translate {
                    y: tarjeta.enfocada ? -3 : 0
                    Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radiusCard
                    color: tarjeta.enfocada ? Theme.glassFillHi : Theme.glassFill
                    border.width: 1
                    border.color: tarjeta.enfocada ? root.accent : Theme.glassBorder
                    Behavior on color { ColorAnimation { duration: 180 } }
                }

                Row {
                    id: filaIcono
                    anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                    spacing: 8

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 20; height: 20
                        radius: Theme.radiusChip
                        color: Theme.alpha(root.accent, tarjeta.disponible ? 0.14 : 0.05)
                        border.width: 1
                        border.color: Theme.alpha(root.accent, tarjeta.disponible ? 0.45 : 0.15)

                        Text {
                            anchors.centerIn: parent
                            text: modelData.glifo
                            color: tarjeta.disponible ? root.accent : Theme.textFaint
                            font.pixelSize: 11
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        // Ancho explicito + elide: a 145px de tarjeta el
                        // presupuesto para el texto es chico (~58px). Sin
                        // esto, una etiqueta larga se dibuja fuera de la
                        // tarjeta y pisa la siguiente - "…" es preferible a
                        // eso. En la practica ninguna de las 4 etiquetas de
                        // hoy necesita elidir a este ancho.
                        width: 58
                        elide: Text.ElideRight
                        text: modelData.etiqueta
                        color: tarjeta.disponible ? Theme.textPrimary : Theme.textFaint
                        font.family: Theme.fontBody
                        font.pixelSize: Theme.sizeLabel
                    }
                }

                Text {
                    anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                    text: "›"
                    color: tarjeta.disponible ? Theme.textMuted : Theme.textFaint
                    font.pixelSize: 13
                }

                MouseArea {
                    anchors.fill: parent
                    // Una tarjeta sin contenido se ve, pero no se abre: no hay
                    // nada del otro lado. "Cómo se juega" es siempre disponible.
                    enabled: tarjeta.disponible
                    onClicked: root.abrir(modelData.tipo)
                }
            }
        }
    }

    // La linea compartida (decision 8b): el detalle de la tarjeta enfocada,
    // o nada con foco -1. Reemplaza al subtitulo que antes vivia dentro de
    // cada tarjeta.
    Text {
        text: root._subtituloDe(root.foco)
        visible: text !== ""
        color: Theme.textFaint
        font.family: Theme.fontMono
        font.pixelSize: Theme.sizeMonoSm
    }

    // Cuanto entra en el subtitulo compartido. Es una sola linea bajo toda
    // la fila (no una por tarjeta), asi que el presupuesto es generoso -
    // pero igual acotado, para no invadir la columna derecha con un detalle
    // larguisimo.
    readonly property int _anchoSubtitulo: 40

    function _subtituloDe(indice) {
        if (indice < 0) return "";
        if (indice === 0) return _subGuia();
        if (indice === 1) return _subGaleria();
        if (indice === 2) return _subCheats();
        if (indice === 3) return _subManual();
        return "";
    }

    // Tres niveles, cada uno mas corto que el anterior, y el ultimo SIEMPRE
    // entra sin importar los datos: es la garantia de que la linea no se
    // rompe por mucho contenido, cualquiera sea.
    function _acortar(detalle, resumen) {
        if (detalle.length <= _anchoSubtitulo) return detalle;
        if (resumen && resumen.length <= _anchoSubtitulo) return resumen;
        return "Ver detalle";
    }

    // "Cómo se juega" no tiene conteo natural (decision 8): dice si este
    // juego tiene guia propia o si va a mostrar la ayuda general.
    function _subGuia() {
        if (!datos) return "";
        return datos.hayGuia ? "Guía propia" : "Ayuda general";
    }

    // Subtitulo de la galería: desglose por tipo ("1 video · 5 imágenes"),
    // o resumen ("N piezas"). Un conteo en cero no imprime su parte.
    function _subGaleria() {
        if (!datos || !datos.hayGaleria) return "";
        var partes = [];
        var v = datos.galeriaVideos;
        var im = datos.galeriaImagenes;
        if (v > 0) partes.push(v + " " + (v === 1 ? "video" : "videos"));
        if (im > 0) partes.push(im + " " + (im === 1 ? "imagen" : "imágenes"));
        var detalle = partes.join("  ·  ");
        var resumen = datos.galeria.length + " " + (datos.galeria.length === 1 ? "pieza" : "piezas");
        return _acortar(detalle, resumen);
    }

    // Con MAS de un documento (ADR-0023) el desglose por pagina/PDF pasa a
    // vivir en las pestañas del visor, no en la tarjeta: acá solo se cuenta.
    // Con UNO, "12 págs", "PDF", o "12 págs · PDF" (ADR-0021) — sin cambios
    // respecto de antes de la 0023, salvo el recorte si algun dia no entrara.
    function _subManual() {
        if (!datos) return "";
        if (datos.manuales.length > 1)
            return _acortar(datos.manuales.length + " manuales");
        var p = [];
        if (datos.hayManualPaginas) p.push(datos.manualPaginas + " págs");
        if (datos.hayManualPdf) p.push("PDF");
        return _acortar(p.join("  ·  "));
    }

    // Un renglon por grupo, sea cual sea su nombre (ADR-0020): antes esto
    // contaba las dos claves fijas combos/codes, asi que un grupo con
    // nombre propio no aparecia en el subtitulo aunque tuviera entradas. El
    // detalle completo esta a un A de distancia, adentro del overlay - el
    // subtitulo es un adelanto, no tiene que decirlo todo.
    function _subCheats() {
        if (!datos || !datos.hayCheats) return "";
        var g = datos.gruposCheats;

        var p = [];
        for (var i = 0; i < g.length; i++)
            p.push(g[i].items.length + " " + g[i].label.replace(/^[▶★]\s*/, "").toLowerCase());
        var detalle = p.join("  ·  ");
        var resumenCorto = datos.cheatsCount + " entradas";
        var resumenLargo = datos.cheatsCount + " entradas · " + g.length + " grupos";

        if (detalle.length <= _anchoSubtitulo) return detalle;
        if (resumenLargo.length <= _anchoSubtitulo) return resumenLargo;
        if (resumenCorto.length <= _anchoSubtitulo) return resumenCorto;
        return "Ver detalle";
    }
}
