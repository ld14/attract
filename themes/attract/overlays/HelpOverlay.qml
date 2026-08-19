// El overlay "Cómo cargar un juego nuevo": manual de dos columnas, nav de
// pasos + contenido. Recreación en QML del diseño de referencia en
// design_handoff_help/Pegasus Game Detail.dc.html (estado helpOpen,
// lineas 456-495 el layout, 795-1071 el estado y los estilos, 796-809 los
// 8 pasos). Alta fidelidad: colores, tipografia y contenido son del
// prototipo, no redactados de nuevo.
//
// Sin escuadras HUD ni scanlines: ese lenguaje es de CheatsOverlay
// ("tablero de comandos de arcade"). Este es un manual, panel limpio.
//
// El contenido es fijo, no sale de ningun data.json — por eso vive inline
// como property en vez de un modulo en core/, mismo criterio que la
// version anterior de este overlay.

import QtQuick 2.0
import QtGraphicalEffects 1.0
import ".."
import "../ui"

FocusScope {
    id: root

    property color accent: Theme.accentNeutro
    property Item fondo: null

    signal cerrar()

    anchors.fill: parent

    property int helpIdx: 0

    // Base: texto literal de design_handoff_help/Pegasus Game Detail.dc.html:
    // 796-809. Sumado a pedido explicito del autor (2026-08-04): el prototipo
    // explica el CRITERIO pero omite el dato mas operativo — el nombre EXACTO
    // de cada archivo y la ruta EXACTA de cada carpeta. Sin eso alguien puede
    // seguir el paso al pie de la letra y el sistema igual no reconoce nada
    // (ej.: nunca decia que el archivo se llama "data.json"). Los agregados
    // son bullets/codigo nuevos, citan `docs/guides/cargar-un-juego-nuevo.md`
    // y `docs/CONVENCION.md` — no tocan el texto original del handoff.
    //
    // "corto" es la etiqueta del nav (README §Layout: "1. El ROM", "2. Las
    // imágenes", … "8. Si algo falla"); "titulo" es el encabezado del cuerpo.
    readonly property var pasos: [
        {
            corto: "El ROM",
            titulo: "1 · Poné el ROM en su lugar",
            intro: "Cada sistema (Arcade, NES, …) es una carpeta dentro de library/. El archivo del juego va donde el emulador lo espera — vos no lo movés a mano a ningún otro lado.",
            bullets: [
                "El sistema (carpeta arcade/, nes/, …) ya tiene que existir antes de cargar el juego — esto no crea sistemas nuevos.",
                "El archivo va literal en library/<sistema>/<archivo>.zip — por ejemplo library/arcade/dino.zip.",
                "El nombre de la carpeta del juego es el nombre del archivo .zip sin la extensión, nunca el título bonito.",
                "Evitá los caracteres < > : \" / \\ | ? * en el nombre, y que no termine en espacio o punto."
            ],
            codigo: "python -m attract.ingest library/arcade/dino.zip library/arcade"
        },
        {
            corto: "Las imágenes",
            titulo: "2 · Sumá las imágenes",
            intro: "Van todas sueltas (sin subcarpetas) dentro de la carpeta de medios del juego. El sistema las reconoce por su nombre de archivo.",
            bullets: [
                "boxFront.jpg, marquee.png, poster.png y video.mp4 van todos al mismo nivel.",
                "La carátula que se ve en pantalla usa este orden si falta alguna: boxFront → poster → marquee → una genérica.",
                "No hace falta subir las cuatro. Un juego sin ninguna imagen sigue siendo válido."
            ],
            codigo: "media/dino/\n├─ boxFront.jpg\n├─ marquee.png\n├─ poster.png\n└─ video.mp4"
        },
        {
            corto: "El video",
            titulo: "3 · El video de gameplay",
            intro: "Va en el mismo lugar que las imágenes, con el nombre video.mp4. Si no lo tenés, no pasa nada: la pantalla muestra la carátula como si fuera un video en pausa.",
            bullets: [
                "Ruta completa: media/<juego>/video.mp4 — mismo nivel que boxFront/marquee/poster, ninguna subcarpeta."
            ],
            codigo: ""
        },
        {
            corto: "La revista",
            titulo: "4 · Revistas de la época",
            intro: "Las revistas no se arman a mano — te las entregan ya escaneadas y organizadas en su propia carpeta compartida. Vos solo la referenciás desde el juego.",
            bullets: [
                "La carpeta de la revista NO va adentro del juego ni de un sistema — va una sola vez en _magazines/, al lado de arcade/, nes/ y pc/. Una misma revista habla de juegos de los tres.",
                "Se llama _magazines/<revista>-<número>/ (ej. micromania-34) y adentro van magazine.json, cover.jpg y una carpeta pages/ con p001.jpg, p002.jpg… con ceros a la izquierda.",
                "Si te falta el archivo de la revista para un juego, dejalo así: el juego se muestra igual, solo sin esa sección.",
                "No hace falta escribir la línea de abajo a mano: 'attract mags --apply' lee la revista y la agrega sola en el data.json de cada juego que aparezca en ella."
            ],
            codigo: "{ \"mags\": [ { \"ref\": \"micromania-34\" } ] }"
        },
        {
            corto: "Datos del juego",
            titulo: "5 · Color, trucos, reseña, manual",
            intro: "Toda la info especial de un juego (color de acento, combos, trucos, nota de la crítica, manual) va en un único archivo de datos del juego. Todos los campos son opcionales.",
            bullets: [
                "El archivo se llama exactamente data.json y va en media/<juego>/data.json, al lado de las imágenes.",
                "Podés completar solo lo que tengas — un juego sin este archivo es válido, solo se ve menos completo.",
                "Los colores accent/accent2 van en formato #rrggbb completo (6 dígitos), no abreviado.",
                "Si hay manual escaneado, sus páginas van en media/<juego>/_manual/, numeradas con ceros a la izquierda (p001.jpg, p002.jpg…) para que se ordenen bien."
            ],
            codigo: "media/dino/data.json\n{ \"accent\": \"#ffb020\", \"review\": { \"score\": 94 } }"
        },
        {
            corto: "Sinopsis",
            titulo: "6 · La sinopsis",
            intro: "Es un archivo aparte, chiquito, con un solo campo de texto. No lo escribís vos a mano en el juego — se aplica con un comando después de tenerlo listo.",
            bullets: [
                "Va en <sistema>/_synopsis/<juego>.json — al lado de metadata.pegasus.txt, no dentro de media/.",
                "Formato: { \"summary\": \"el texto acá\" } — un solo campo, nada más.",
                "IMPORTANTE: dejar el archivo NO alcanza. Ese .json es solo la fuente; la pantalla lee metadata.pegasus.txt. Sin correr el comando de abajo, el texto puede estar perfecto y el juego igual va a mostrar \"Sin Informacion\".",
                "Si cambiás el texto del .json más adelante, hay que volver a correr el comando para que se vea."
            ],
            codigo: "python -m attract.synopsis dino library/arcade"
        },
        {
            corto: "Validar todo",
            titulo: "7 · Revisá que quedó bien",
            intro: "Antes de dar por cargado un juego, corré la validación. Te dice archivo por archivo si algo está mal.",
            bullets: [
                "Revisa lo que vimos en todos los pasos: nombres de carpeta/archivo válidos, que los .json tengan el formato correcto, y que las imágenes o páginas que declaraste existan de verdad en el disco.",
                "Un juego recién cargado sin ninguna imagen tiene que dar bien igual — si marca error ahí, el problema es el nombre de carpeta/archivo, no la falta de contenido."
            ],
            codigo: "make doctor-lib"
        },
        {
            corto: "Si algo falla",
            titulo: "8 · Si algo no funciona",
            intro: "El comando de validación casi siempre te dice qué archivo y qué regla está fallando — empezá leyendo ese mensaje. Si necesitás más ayuda, pedile a quien mantiene el sistema que revise el mensaje exacto.",
            bullets: [
                "Cargaste todo y el juego no aparece, o aparece sin los cambios: cerrá el programa DEL TODO y volvé a abrirlo. La librería se lee al arrancar, no mientras está abierto.",
                "Error de \"basura de macOS\" (.DS_Store): son archivos que el explorador de Finder crea solo al abrir una carpeta. No los creaste vos. Se borran y listo — pero van a volver a aparecer cada vez que navegues esas carpetas.",
                "La sinopsis no se ve aunque el archivo esté bien: te faltó correr el comando del paso 6. Es el error más común."
            ],
            codigo: "find library -name \".DS_Store\" -type f -delete"
        }
    ]

    readonly property var pasoActual: pasos[helpIdx]

    function irA(i) {
        root.helpIdx = Math.max(0, Math.min(root.pasos.length - 1, i));
    }

    // --- fondo ------------------------------------------------------------

    FastBlur {
        anchors.fill: parent
        source: root.fondo
        radius: 40
        visible: root.fondo !== null
        cached: true
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(5 / 255, 6 / 255, 9 / 255, 0.9)
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.cerrar()
    }

    // --- el panel: dos columnas -------------------------------------------
    // Item, NO Row/Column: el fondo y el MouseArea de abajo necesitan
    // anchors.fill, y un positioner le pisa el x/y a sus hijos si intentan
    // anclarse — mismo motivo por el que CheatsOverlay.qml usa Item acá.

    Item {
        id: panel
        width: Math.min(880, parent.width * 0.92)
        height: Math.min(parent.height * 0.86, 620)
        anchors.centerIn: parent

        Rectangle {
            anchors.fill: parent
            radius: 16
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#0e1118" }
                GradientStop { position: 1.0; color: "#0a0c11" }
            }
            border.width: 1
            border.color: Theme.alpha(Theme.textBright, 0.1)
        }

        MouseArea {
            // Clicks adentro del panel no cierran el overlay.
            anchors.fill: parent
            onClicked: {}
        }

        Row {
            // Row SI puede tener anchors.fill: sus hijos son Items simples
            // con width propio, no vuelven a anclarse adentro.
            anchors.fill: parent

            // ---- columna izquierda: nav de pasos ----
            Item {
                id: nav
                width: 220
                height: parent.height

                Rectangle {
                    anchors.fill: parent
                    color: Theme.alpha(Theme.textBright, 0.03)
                }
                Rectangle {
                    anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
                    width: 1
                    color: Theme.alpha(Theme.textBright, 0.08)
                }

                Column {
                    anchors { fill: parent; topMargin: 20; bottomMargin: 20; leftMargin: 12; rightMargin: 12 }
                    spacing: 3

                    Text {
                        width: parent.width
                        text: "GUÍA RÁPIDA"
                        color: "#6a7081"
                        font.family: Theme.fontMono
                        font.pixelSize: 10
                        font.letterSpacing: 0.16 * 10
                    }

                    Item { width: 1; height: 9 }   // el "bottomPadding:12" del label, sin usar padding en Text

                    Repeater {
                        model: root.pasos
                        Item {
                            width: parent.width
                            height: 32

                            readonly property bool activo: index === root.helpIdx

                            Rectangle {
                                anchors.fill: parent
                                radius: 8
                                color: activo ? root.accent : "transparent"
                            }

                            Text {
                                anchors { left: parent.left; leftMargin: 10; right: parent.right; verticalCenter: parent.verticalCenter }
                                text: (index + 1) + ". " + modelData.corto
                                color: activo ? "#07080c" : "#aeb3c0"
                                font.family: Theme.fontMono
                                font.pixelSize: 12
                                font.bold: activo
                                elide: Text.ElideRight
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.irA(index)
                            }
                        }
                    }
                }
            }

            // ---- columna derecha: contenido ----
            Item {
                id: derecha
                width: parent.width - nav.width
                height: parent.height

                Item {
                    id: cabecera
                    anchors { top: parent.top; left: parent.left; right: parent.right }
                    height: 68

                    Column {
                        anchors { left: parent.left; leftMargin: 26; verticalCenter: parent.verticalCenter }
                        spacing: 4

                        Text {
                            text: "Cómo cargar un juego nuevo"
                            color: Theme.textBright
                            font.family: Theme.fontDisplay
                            font.bold: true
                            font.pixelSize: 19
                        }
                        Text {
                            text: "Paso " + (root.helpIdx + 1) + " de " + root.pasos.length
                            color: "#6a7081"
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                        }
                    }

                    Boton {
                        anchors { right: parent.right; rightMargin: 20; verticalCenter: parent.verticalCenter }
                        texto: ""; glifo: "✕"; variant: "glass"; accent: root.accent
                        implicitWidth: 36; implicitHeight: 36
                        onActivado: root.cerrar()
                    }

                    Rectangle {
                        anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                        height: 1
                        color: Theme.alpha(Theme.textBright, 0.08)
                    }
                }

                Flickable {
                    id: scroll
                    anchors { top: cabecera.bottom; left: parent.left; right: parent.right; bottom: pie.top }
                    anchors { leftMargin: 26; rightMargin: 26; topMargin: 20; bottomMargin: 10 }
                    contentHeight: cuerpo.height
                    clip: true
                    interactive: true

                    Column {
                        id: cuerpo
                        width: scroll.width
                        spacing: 16

                        Text {
                            width: parent.width
                            text: root.pasoActual.titulo
                            color: root.accent
                            font.family: Theme.fontDisplay
                            font.bold: true
                            font.pixelSize: 22
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            width: parent.width
                            text: root.pasoActual.intro
                            color: "#c4c8d4"
                            font.family: Theme.fontBody
                            font.pixelSize: 15
                            lineHeight: 1.6
                            wrapMode: Text.WordWrap
                        }

                        Column {
                            width: parent.width
                            spacing: 10
                            visible: root.pasoActual.bullets.length > 0

                            Repeater {
                                model: root.pasoActual.bullets

                                // Con ANCHORS sobre la tarjeta, no con un Row: un
                                // Row calcula su ancho a partir del de sus hijos,
                                // y el texto necesita el resto del ancho del Row —
                                // dependencia circular que QML no resuelve (mismo
                                // caso ya documentado en CheatsOverlay.qml).
                                Rectangle {
                                    id: tarjeta
                                    width: parent.width
                                    height: bulletTexto.height + 24
                                    radius: 10
                                    color: Theme.alpha(Theme.textBright, 0.03)
                                    border.width: 1
                                    border.color: Theme.alpha(Theme.textBright, 0.07)

                                    Text {
                                        id: bulletIcono
                                        anchors { left: parent.left; leftMargin: 12; top: parent.top; topMargin: 12 }
                                        text: "▸"
                                        color: root.accent
                                        font.pixelSize: 14
                                    }
                                    Text {
                                        id: bulletTexto
                                        anchors { left: bulletIcono.right; leftMargin: 12 }
                                        anchors { right: parent.right; rightMargin: 12; top: parent.top; topMargin: 12 }
                                        text: modelData
                                        wrapMode: Text.WordWrap
                                        color: "#dfe3ec"
                                        font.family: Theme.fontBody
                                        font.pixelSize: 14
                                        lineHeight: 1.55
                                    }
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: codigo.height + 28
                            radius: 10
                            color: "#0a0c11"
                            border.width: 1
                            border.color: Theme.alpha(Theme.textBright, 0.1)
                            visible: root.pasoActual.codigo !== ""

                            Text {
                                id: codigo
                                anchors { fill: parent; margins: 14 }
                                text: root.pasoActual.codigo
                                wrapMode: Text.WordWrap
                                color: "#8fd6a8"
                                font.family: Theme.fontMono
                                font.pixelSize: 13
                            }
                        }
                    }
                }

                Item {
                    id: pie
                    anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                    height: 68

                    Rectangle {
                        anchors { top: parent.top; left: parent.left; right: parent.right }
                        height: 1
                        color: Theme.alpha(Theme.textBright, 0.08)
                    }

                    Boton {
                        anchors { left: parent.left; leftMargin: 26; verticalCenter: parent.verticalCenter }
                        texto: "‹ Anterior"; variant: "glass"; accent: root.accent
                        opacity: root.helpIdx === 0 ? 0.35 : 1.0
                        enabled: root.helpIdx > 0
                        onActivado: root.irA(root.helpIdx - 1)
                    }

                    Boton {
                        anchors { right: parent.right; rightMargin: 26; verticalCenter: parent.verticalCenter }
                        texto: "Siguiente ›"; variant: "accent"; accent: root.accent
                        opacity: root.helpIdx === root.pasos.length - 1 ? 0.35 : 1.0
                        enabled: root.helpIdx < root.pasos.length - 1
                        onActivado: root.irA(root.helpIdx + 1)
                    }
                }
            }
        }
    }

    Keys.onPressed: {
        if (api.keys.isCancel(event)) {
            root.cerrar(); event.accepted = true;
        } else if (event.key === Qt.Key_Right) {
            root.irA(root.helpIdx + 1); event.accepted = true;
        } else if (event.key === Qt.Key_Left) {
            root.irA(root.helpIdx - 1); event.accepted = true;
        }
    }
}
