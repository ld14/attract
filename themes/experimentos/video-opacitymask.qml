// EXPERIMENTO — ¿OpacityMask enmascara un VideoOutput en este binario?
//
// Contexto: el preview de gameplay del hero de Home (feature 017,
// spec/features/017-hero-video-preview/) se mete POR DEBAJO de la primera fila
// de tarjetas, y para que ese cruce no se vea como un rectángulo con canto
// marcado el panel tiene que DISOLVERSE hacia abajo con una máscara de alfa
// vertical. Sin máscara real no hay feature: la alternativa es tapar el video
// con un gradiente del color del fondo, y el fondo de ATTRACT no es un color
// plano (ui/AccentWash.qml lo tiñe con el accent del juego), así que se vería
// una banda oscura en vez de una disolución.
//
// El único camino disponible es OpacityMask de QtGraphicalEffects 1.0:
// MultiEffect y Qt5Compat.GraphicalEffects son de Qt 6 y este binario es Qt
// 5.15.10 (ADR-0006, docs/plataforma-pegasus.md §1).
//
// LO QUE ESTE EXPERIMENTO MIDE — tres cosas, todas de la misma pantalla:
//
//   1. LA PREGUNTA. OpacityMask con `source` = un Item{visible:false} que
//      contiene un VideoOutput: ¿sale el video enmascarado, o sale un
//      rectángulo negro? La duda no es si OpacityMask anda —ui/FocusRing.qml y
//      screens/GameCard.qml ya lo usan contra este binario (2026-08-03,
//      graphical-effects.qml)— sino si un VideoOutput ADENTRO DE UN ITEM
//      INVISIBLE sigue alimentando el ShaderEffectSource implícito. Una imagen
//      es una textura estática; un VideoOutput es un nodo de scene graph propio
//      (SGVideoNode) que el backend actualiza por cuadro, y "invisible" podría
//      significar "no actualices más".
//
//   2. ¿Y SE SIGUE ACTUALIZANDO? Distinto de (1): puede salir enmascarado pero
//      CONGELADO en el primer cuadro. Por eso el panel B es un mock fiel y no
//      un cuadrado de color — si se mueve, se ve.
//
//   3. GRADIENTE HORIZONTAL POR ROTACIÓN. Un Rectangle de Qt 5 solo hace
//      gradientes verticales (plataforma-pegasus.md §3). El degradé lateral del
//      diseño (capa 2 del panel) se resuelve rotando -90 un Rectangle con los
//      lados intercambiados. Es gratis medirlo acá y ahorra un ⌘Q después.
//      El otro camino sería un Canvas con createLinearGradient, como
//      ui/Background.qml — más caro por un gradiente de dos paradas.
//
// PREDICCIÓN: (1) y (2) funcionan. QSGNode se sigue actualizando aunque el Item
// esté invisible —"invisible" es una propiedad del árbol de QML, no del backend
// multimedia— y ShaderEffectSource captura el subárbol sin preguntar si está
// visible. (3) funciona seguro, es geometría. El candidato a fallar es (2), y
// el modo de falla sería el peor de todos: se ve bien en la captura y está
// congelado en vivo.
//
// PRIMERA CORRIDA (Mac, 2026-08-21): ❌ MEDICIÓN INVÁLIDA, no midió nada.
//
// Panel A mostró el video. **B y C salieron los dos vacíos** — y C ni siquiera
// usa máscara. Un panel sin máscara fallando igual que el panel con máscara es
// la firma de que el problema estaba en el instrumento: la versión de entonces
// colgaba los tres VideoOutput de UN SOLO MediaPlayer, y en QtMultimedia 5 un
// player expone un único renderer (QVideoRendererControl), así que el primer
// VideoOutput se lo queda y los otros no reciben cuadros.
//
// Corregido con un MediaPlayer por panel (ver el bloque de abajo). Es el mismo
// error que ya se había cometido en multimedia-loop.qml y que ese archivo
// documenta: el instrumento respondiendo otra pregunta que la que se hizo.
//
// HALLAZGO QUE SOBREVIVE IGUAL, y vale para producción: **dos VideoOutput no
// pueden compartir un MediaPlayer.** La feature 017 no lo sufre —
// HeroVideoPreview y VideoPanel tienen cada uno el suyo— pero cualquier pantalla
// futura que quiera mostrar el mismo video dos veces necesita dos players.
//
// LO QUE SÍ SE VIO en esa corrida, aunque no era lo que se buscaba: la máscara
// **funciona sobre las capas que no son video**. El badge se dibujó completo y
// el degradé inferior del panel B se disolvió hacia abajo, contra el borde duro
// del panel C. O sea que OpacityMask está corriendo; lo que falta saber es si le
// llega el video.
//
// RESULTADO OBSERVADO (Mac, segunda corrida): ✅ 2026-08-21. La predicción se
// cumplió: OpacityMask enmascara un VideoOutput y el video sigue vivo adentro.
//
//   punto 1 (enmascara)     ✅ el panel B muestra el video, no un rectángulo
//                              negro, y la máscara lo disuelve hacia abajo. La
//                              comparación que lo cierra es contra el panel C:
//                              C termina en un canto recto contra el fondo y B
//                              se desvanece. Eso es exactamente la diferencia
//                              que la feature 017 necesita.
//   punto 2 (se actualiza)  ✅ los tres paneles muestran el MISMO cuadro de
//                              partida (pos 8852, con el sprite a media
//                              pantalla). Un VideoOutput congelado en el primer
//                              cuadro mostraría la pantalla de título, no una
//                              partida en curso: el de adentro de la máscara se
//                              está actualizando igual que el control.
//   punto 3 (rotación)      ~  NO SE PUEDE JUZGAR con esta captura. El borde
//                              izquierdo de B no se ve claramente más oscuro
//                              que el de A, pero la fuente de prueba es un
//                              video letterboxeado sobre negro: un velo del 50%
//                              de #06070c sobre negro no cambia nada visible.
//                              Se cierra contra el hero real, donde el fondo
//                              detrás del borde izquierdo es el AccentWash y no
//                              negro — o con un video de prueba claro.
//
// RESULTADO OBSERVADO (gabinete): <PENDIENTE>
//
// SI (1) O (2) FALLAN — plan B para la feature 017: sacar la máscara y disolver
// con un Rectangle de gradiente vertical a Theme.screen encima del video (es el
// panel C de esta pantalla, que está justamente para poder comparar los dos
// lado a lado sin escribir un segundo experimento). Se ve peor sobre el
// AccentWash, pero no depende de la GPU. Anotar cuál se eligió en el plan.md de
// la feature ANTES de escribir el componente.
//
// El video de prueba sale de la librería real: NO se puede correr contra
// fixtures/, que son de 0 bytes a propósito (CLAUDE.md §Reglas de trabajo).
// Hoy el único .mp4 es library/mame/media/ghost-n-goblins/video.mp4, pero este
// archivo no lo referencia por ruta — busca el primer juego de api.allGames que
// tenga assets.video, así sigue andando cuando la librería cambie.
//
// Cómo correrlo:
//   1. cp themes/experimentos/video-opacitymask.qml \
//        "$PEGASUS_THEMES/attract-debug/theme.qml"
//      (o `make theme-debug` primero y después copiar encima)
//   2. abrí Pegasus > Settings > Theme > ATTRACT Debug
//   3. mirá los tres paneles UNOS SEGUNDOS, no una captura: el punto 2 solo se
//      responde en movimiento
//   4. flecha ▶/◀ cambia de juego si el primero con video no sirve
//   5. anotá arriba los tres resultados

import QtQuick 2.0
import QtMultimedia 5.9
import QtGraphicalEffects 1.0

FocusScope {
    id: root
    focus: true

    // El primer juego con video. Se recalcula al mover `salto`.
    property int salto: 0
    readonly property var g: {
        var vistos = 0;
        for (var i = 0; i < api.allGames.count; i++) {
            var j = api.allGames.get(i);
            if (j.assets && j.assets.video) {
                if (vistos === salto) return j;
                vistos++;
            }
        }
        return null;
    }

    readonly property int conVideo: {
        var n = 0;
        for (var i = 0; i < api.allGames.count; i++) {
            var j = api.allGames.get(i);
            if (j.assets && j.assets.video) n++;
        }
        return n;
    }

    Keys.onRightPressed: if (conVideo > 0) salto = (salto + 1) % conVideo
    Keys.onLeftPressed:  if (conVideo > 0) salto = (salto - 1 + conVideo) % conVideo

    // El fondo NO es negro plano a proposito: si fuera negro, el panel C
    // (gradiente falso) seria indistinguible del panel B (mascara real), que es
    // justo la comparacion que este experimento tiene que permitir. Este
    // gradiente diagonal imita al AccentWash de la Home.
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#1d2b4a" }
            GradientStop { position: 0.5; color: "#3a1f4a" }
            GradientStop { position: 1.0; color: "#0d1117" }
        }
    }

    // UN MediaPlayer POR PANEL, y esto es la correccion de un error de medicion
    // real (2026-08-21, primera corrida). La version anterior tenia UN solo
    // player alimentando los tres VideoOutput, y el resultado fue que solo el
    // panel A mostraba video: B y C salieron vacios los dos.
    //
    // Eso NO era la mascara fallando — era la limitacion de QtMultimedia 5:
    // un MediaPlayer expone UN renderer (QVideoRendererControl), asi que un
    // segundo VideoOutput colgado del mismo player no recibe cuadros. El panel
    // C, que ni siquiera usa mascara, salio igual de vacio que el B: esa es la
    // prueba de que el problema estaba en el instrumento y no en OpacityMask.
    //
    // Es el mismo error que ya documenta multimedia-loop.qml — el instrumento
    // respondiendo otra pregunta que la que se hizo — y por eso queda escrito
    // aca en vez de borrado: en produccion NO molesta (HeroVideoPreview y
    // VideoPanel tienen cada uno el suyo), pero cualquiera que escriba un
    // experimento con dos vistas del mismo video se lo vuelve a comer.
    // Tres declaraciones a mano y no un Repeater: el delegate de un Repeater
    // tiene que ser un Item, y MediaPlayer no lo es.
    readonly property url fuente: root.g && root.g.assets.video ? root.g.assets.video : ""

    MediaPlayer {
        id: playerA
        source: root.fuente
        autoPlay: true; loops: MediaPlayer.Infinite; muted: true; volume: 0
    }

    MediaPlayer {
        id: playerB
        source: root.fuente
        autoPlay: true; loops: MediaPlayer.Infinite; muted: true; volume: 0
    }

    MediaPlayer {
        id: playerC
        source: root.fuente
        autoPlay: true; loops: MediaPlayer.Infinite; muted: true; volume: 0
    }

    // Barras horizontales de referencia: cruzan los tres paneles a la altura
    // donde la mascara ya deberia estar disolviendo (68% y 84%). Sirven para
    // ver DONDE termina cada panel sin tener que adivinar.
    Repeater {
        model: [0.68, 0.84]
        Rectangle {
            x: 24; width: parent.width - 48; height: 1
            y: 96 + 320 * modelData
            color: "#ffffff"
            opacity: 0.22
        }
    }

    // ------------------------------------------------------------ etiquetas
    Text {
        anchors { top: parent.top; left: parent.left; margins: 20 }
        color: "#e8ecf5"
        font.family: "Courier"
        font.pixelSize: 13
        text: root.conVideo === 0
              ? "NO HAY NINGUN JUEGO CON assets.video — este experimento no puede correr"
              : (root.g ? root.g.title : "?")
                + "   ·   " + (root.salto + 1) + "/" + root.conVideo
                + " con video   ·   ◀ ▶ cambia"
                + "\nestado: " + playerA.status + "   playbackState: " + playerA.playbackState
                + "   pos: " + playerA.position
    }

    // ============================================================= panel A
    // CONTROL. VideoOutput pelado. Si esto no se mueve, no hay nada que medir
    // y el problema es el video, no la mascara.
    Item {
        id: panelA
        x: 24; y: 96
        width: 380; height: 320

        VideoOutput {
            anchors.fill: parent
            source: playerA
            fillMode: VideoOutput.PreserveAspectCrop
        }

        Text {
            anchors { bottom: parent.top; left: parent.left; bottomMargin: 6 }
            color: "#9aa3b5"; font.family: "Courier"; font.pixelSize: 11
            text: "A · CONTROL (sin mascara)"
        }
    }

    // ============================================================= panel B
    // LA PREGUNTA. Mock fiel del panel de la feature 017: las cuatro capas
    // adentro de un Item invisible, y OpacityMask al lado. Calcado de
    // screens/GameCard.qml:113-131, que es el patron que ya funciona con una
    // Image adentro.
    Item {
        id: panelB
        x: 428; y: 96
        width: 380; height: 320

        Item {
            id: capas
            anchors.fill: parent
            visible: false          // <- ESTA linea es la pregunta

            // capa 1 · el video
            VideoOutput {
                anchors.fill: parent
                source: playerB
                fillMode: VideoOutput.PreserveAspectCrop
            }

            // capa 2 · degrade lateral — PUNTO 3: gradiente horizontal por
            // rotacion. Lados intercambiados y rotation:-90, asi el tope del
            // gradiente (position 0) cae en el borde IZQUIERDO.
            Rectangle {
                width: parent.height
                height: parent.width
                anchors.centerIn: parent
                rotation: -90
                gradient: Gradient {
                    GradientStop { position: 0.00; color: Qt.rgba(0.024, 0.027, 0.047, 0.5) }
                    GradientStop { position: 0.58; color: "transparent" }
                }
            }

            // capa 3 · degrade inferior
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.00; color: "transparent" }
                    GradientStop { position: 0.56; color: "transparent" }
                    GradientStop { position: 1.00; color: Qt.rgba(0.024, 0.027, 0.047, 0.72) }
                }
            }

            // capa 4 · el badge. Va ADENTRO de la mascara a proposito: esta en
            // la zona 100% opaca, asi que si sale recortado el problema es la
            // mascara, no el badge.
            Rectangle {
                anchors { top: parent.top; left: parent.left; margins: 12 }
                width: fila.width + 18
                height: 22
                radius: 11
                color: Qt.rgba(0.027, 0.031, 0.047, 0.62)

                Row {
                    id: fila
                    anchors.centerIn: parent
                    spacing: 7

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 5; height: 5; radius: 2.5
                        color: "#ffb340"
                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.2; duration: 800 }
                            NumberAnimation { to: 1.0; duration: 800 }
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "GAMEPLAY"
                        color: "#e8ecf5"
                        font.family: "Courier"
                        font.pixelSize: 9
                        font.letterSpacing: 0.1 * 9
                    }
                }
            }
        }

        // La mascara del diseño: opaco hasta 46%, y de ahi se va.
        Rectangle {
            id: mascara
            anchors.fill: parent
            visible: false
            gradient: Gradient {
                GradientStop { position: 0.00; color: "white" }
                GradientStop { position: 0.46; color: "white" }
                GradientStop { position: 0.68; color: Qt.rgba(1, 1, 1, 0.55) }
                GradientStop { position: 0.84; color: Qt.rgba(1, 1, 1, 0.14) }
                GradientStop { position: 0.96; color: "transparent" }
                GradientStop { position: 1.00; color: "transparent" }
            }
        }

        OpacityMask {
            anchors.fill: parent
            source: capas
            maskSource: mascara
        }

        Text {
            anchors { bottom: parent.top; left: parent.left; bottomMargin: 6 }
            color: "#9aa3b5"; font.family: "Courier"; font.pixelSize: 11
            text: "B · OpacityMask  ← LA PREGUNTA"
        }
    }

    // ============================================================= panel C
    // PLAN B. Sin mascara: el mismo video tapado por un gradiente al color del
    // fondo. Esta aca para comparar, no porque sea la opcion preferida — sobre
    // el fondo diagonal de arriba tiene que verse como una BANDA, no como una
    // disolucion. Si no se nota la diferencia contra B, plan B alcanza y la
    // feature se simplifica.
    Item {
        id: panelC
        x: 832; y: 96
        width: 380; height: 320

        VideoOutput {
            anchors.fill: parent
            source: playerC
            fillMode: VideoOutput.PreserveAspectCrop
        }

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.00; color: "transparent" }
                GradientStop { position: 0.46; color: "transparent" }
                GradientStop { position: 0.68; color: Qt.rgba(0.016, 0.020, 0.039, 0.45) }
                GradientStop { position: 0.84; color: Qt.rgba(0.016, 0.020, 0.039, 0.86) }
                GradientStop { position: 0.96; color: "#04050a" }
                GradientStop { position: 1.00; color: "#04050a" }
            }
        }

        Text {
            anchors { bottom: parent.top; left: parent.left; bottomMargin: 6 }
            color: "#9aa3b5"; font.family: "Courier"; font.pixelSize: 11
            text: "C · PLAN B (gradiente, sin mascara)"
        }
    }

    // -------------------------------------------------------------- ayuda
    Text {
        anchors { left: parent.left; bottom: parent.bottom; margins: 20 }
        color: "#6f7a8d"
        font.family: "Courier"
        font.pixelSize: 11
        lineHeight: 1.4
        text: "1. ¿B muestra el video, o un rectangulo negro?\n"
            + "2. ¿B se MUEVE, o quedo congelado en el primer cuadro? (mirar unos segundos)\n"
            + "3. ¿El borde izquierdo de B esta oscurecido? (gradiente rotado)\n"
            + "4. ¿B se disuelve contra el fondo y C se ve como una banda oscura?"
    }
}
