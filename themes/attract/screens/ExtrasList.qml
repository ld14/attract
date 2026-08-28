// Las tarjetas de CONTENIDO EXTRA del detalle: Galería, Hacks (trucos y
// combos) y Manual digitalizado.
//
// LAS REVISTAS NO ESTAN ACA A PROPOSITO. El handoff es explicito: viven solo
// en el carrusel de la columna izquierda, no se duplican como tarjeta. Ese
// carrusel llega con la feature 006.
//
// DIVERGENCIA CONSCIENTE RESPECTO DEL HANDOFF: el handoff omite la tarjeta
// cuando el juego no tiene ese contenido, y muestra una fila punteada solo
// cuando no tiene NINGUNO. CONVENCION #2.3 dice lo contrario y gana: las tres
// tarjetas estan siempre, y la que no tiene contenido dice "No Disponible".
// El motivo es que la estructura de la pantalla no cambie de juego en juego —
// que el ojo encuentre las cosas en el mismo lugar siempre. Consecuencia: la
// fila punteada del handoff no existe, porque su caso nunca se da.
//
// Las tres tarjetas miden 200px (no 250): tres de 250 con spacing 14 miden
// 764 y pisan la columna derecha segun el largo de la resena (plan §Decisiones).
// Con 200px la fila mide 628 y entra sin tocar nada.

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
        spacing: 14

        Repeater {
            model: [
                {
                    tipo: "galeria",
                    glifo: "▣",
                    etiqueta: "Galería",
                    hay: root.datos ? root.datos.hayGaleria : false,
                    sub: root.datos ? root._subGaleria() : ""
                },
                {
                    tipo: "cheats",
                    glifo: "☠",
                    etiqueta: "Hacks",
                    hay: root.datos ? root.datos.hayCheats : false,
                    sub: root.datos ? root._subCheats() : ""
                },
                {
                    tipo: "manual",
                    glifo: "❐",
                    etiqueta: "Manual",
                    hay: root.datos ? root.datos.hayManual : false,
                    sub: root.datos ? root._subManual() : ""
                }
            ]

            Item {
                id: tarjeta
                width: 200
                height: 66

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
                    anchors { left: parent.left; leftMargin: 18; verticalCenter: parent.verticalCenter }
                    spacing: 14

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 50; height: 50
                        radius: Theme.radiusChip
                        color: Theme.alpha(root.accent, tarjeta.disponible ? 0.14 : 0.05)
                        border.width: 1
                        border.color: Theme.alpha(root.accent, tarjeta.disponible ? 0.45 : 0.15)

                        Text {
                            anchors.centerIn: parent
                            text: modelData.glifo
                            color: tarjeta.disponible ? root.accent : Theme.textFaint
                            font.pixelSize: 22
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4

                        Text {
                            text: modelData.etiqueta
                            color: tarjeta.disponible ? Theme.textPrimary : Theme.textFaint
                            font.family: Theme.fontBody
                            font.pixelSize: Theme.sizeLabel
                        }

                        Text {
                            // El bloque no desaparece: dice que no hay (§2.3).
                            text: tarjeta.disponible ? modelData.sub : "No Disponible"
                            color: Theme.textFaint
                            font.family: Theme.fontMono
                            font.pixelSize: Theme.sizeMonoSm
                        }
                    }
                }

                Text {
                    anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
                    text: "›"
                    color: tarjeta.disponible ? Theme.textMuted : Theme.textFaint
                    font.pixelSize: 18
                }

                MouseArea {
                    anchors.fill: parent
                    // Una tarjeta sin contenido se ve, pero no se abre: no hay
                    // nada del otro lado.
                    enabled: tarjeta.disponible
                    onClicked: root.abrir(modelData.tipo)
                }
            }
        }
    }

    // Cuanto entra en el subtitulo sin romper la tarjeta (200px fijos, texto
    // en Theme.fontMono a Theme.sizeMonoSm=10 -> ~6px/caracter, y el icono +
    // los margenes ya se comen buena parte del ancho). Con 200px caben ~13
    // caracteres, que es mucho menos que antes (22). El desglose
    // "1 video · 12 imágenes" no entra nunca; cae a "N piezas".
    readonly property int _anchoSubtitulo: 13

    // Tres niveles, cada uno mas corto que el anterior, y el ultimo SIEMPRE
    // entra sin importar los datos: es la garantia de que la tarjeta no
    // vuelve a romperse por mucho contenido, cualquiera sea.
    function _acortar(detalle, resumen) {
        if (detalle.length <= _anchoSubtitulo) return detalle;
        if (resumen && resumen.length <= _anchoSubtitulo) return resumen;
        return "Ver detalle";
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
    //
    // Con 200px de ancho el presupuesto es ~13 caracteres, asi que el
    // resumen intermedio "6 entradas · 2 grupos" (21 chars) tampoco entra.
    // Se agrega un tercer nivel: "N entradas" (mas corto).
    function _subCheats() {
        if (!datos || !datos.hayCheats) return "";
        var g = datos.gruposCheats;

        var p = [];
        for (var i = 0; i < g.length; i++)
            p.push(g[i].items.length + " " + g[i].label.replace(/^[▶★]\s*/, "").toLowerCase());
        var detalle = p.join("  ·  ");
        var resumenCorto = datos.cheatsCount + " entradas";
        var resumenLargo = datos.cheatsCount + " entradas · " + g.length + " grupos";

        // Tres niveles: detalle, resumen largo, resumen corto, "Ver detalle".
        if (detalle.length <= _anchoSubtitulo) return detalle;
        if (resumenLargo.length <= _anchoSubtitulo) return resumenLargo;
        if (resumenCorto.length <= _anchoSubtitulo) return resumenCorto;
        return "Ver detalle";
    }
}
