// El selector de plataforma (feature 026): la pantalla raiz del theme. Una
// plataforma a la vez, a pantalla completa; al aceptar se abre Home filtrado
// a esa coleccion (theme.qml). TODAS es Home sin filtro.
//
// Diseño de referencia: Diseños/design_handoff_platform_select/ (medidas,
// colores y capas). Su grilla de 7 columnas NO se implementa: el catalogo es
// Home (spec §Qué hace).
//
// LO QUE ESTA PANTALLA NO HACE, a proposito:
//
//   - No toca api.allGames. Las plataformas salen de Catalog.plataformas, que
//     las arma de las claves que ya cargo (regla del encabezado de Catalog).
//   - No toma B. El selector es la raiz: no hay a donde volver, y la leyenda
//     no la nombra. B sigue sin aceptarse para que llegue a Pegasus, igual que
//     en la barra de Home (ver el Keys.onPressed de BrowseScreen: comerse
//     Escape deja a Pegasus sin su tecla).
//   - No guarda la plataforma elegida en ningun lado mas que en `indice`. El
//     componente no se destruye al pasar a Home, asi que volver encuentra el
//     mismo indice sin que nadie lo tenga que restaurar.
//
// CAPAS, de atras hacia adelante (orden de declaracion; nadie usa z):
//   scrims -> video + disolucion -> emblema + fundido -> textos -> flechas ->
//   barra -> leyenda. El fondo con el acento y el CRT los pone theme.qml.

import QtQuick 2.0
import QtMultimedia 5.9
import ".."
import "../core"
import "../core/Platforms.js" as Platforms
import "../ui"

FocusScope {
    id: root

    property var catalogo: null
    property var paths: null
    property var teclas: null
    property string wordmark: "SHINBOX"

    // Lo apaga theme.qml cuando el selector deja de verse: es lo que suelta el
    // decoder del video, igual que HeroVideoPreview.encendido.
    property bool encendido: true
    property bool silenciado: false

    // La plataforma enfocada. Un int y no un currentIndex de una vista: cada
    // alternarFavorito() rehace Catalog.plataformas, y una vista con ese
    // modelo volveria a 0. Un int no se entera.
    property int indice: 0

    readonly property var plataformas: catalogo ? catalogo.plataformas : []
    readonly property int idx: Math.max(0, Math.min(indice, plataformas.length - 1))
    readonly property var plataforma: plataformas.length > 0 ? plataformas[idx] : null

    // Lo que Home necesita de la plataforma elegida: la abreviatura para su
    // pill de filtro. Sale de data.json si lo hay, de la coleccion si no.
    readonly property string abrev: datos.abrev
    readonly property color accent: datos.accent

    // El fondo transiciona el acento (.5s del diseño); el nombre y el conteo
    // cambian en seco. Por eso son dos propiedades y no una.
    property color acentoFondo: accent
    Behavior on acentoFondo { ColorAnimation { duration: 500 } }

    signal aceptar(var plataforma)
    signal alternarSonido()

    PlatformData {
        id: datos
        plataforma: root.plataforma
        paths: root.paths
    }

    function mover(paso) {
        root.indice = Platforms.mover(root.idx, paso, root.plataformas.length);
    }

    function alAzar() {
        root.indice = Platforms.alAzar(root.idx, root.plataformas.length, Math.random);
    }

    // ----------------------------------------------------------- teclado
    Keys.onPressed: {
        if (!root.teclas) return;
        var d = root.teclas.direccion(event);
        if (d === "izq") { root.mover(-1); event.accepted = true; }
        else if (d === "der") { root.mover(1); event.accepted = true; }
        else if (root.teclas.esX(event)) { root.alAzar(); event.accepted = true; }
        else if (root.teclas.esA(event)) {
            if (root.plataforma) root.aceptar(root.plataforma);
            event.accepted = true;
        }
        // Mismo atajo que Home, sin modificadores y sin repeticion.
        else if (event.key === Qt.Key_S
                 && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))) {
            if (!event.isAutoRepeat) root.alternarSonido();
            event.accepted = true;
        }
        // B: ver el encabezado. No se acepta.
    }

    // ------------------------------------------------------------ scrims
    // Horizontal (oscurece la columna de texto) y vertical (arriba y abajo).
    // Canvas porque Rectangle en Qt 5 solo hace degradados verticales.
    Canvas {
        id: scrims
        anchors.fill: parent
        renderStrategy: Canvas.Cooperative
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            var w = width, h = height;

            var hz = ctx.createLinearGradient(0, 0, w, 0);
            hz.addColorStop(0.00, Qt.rgba(6/255, 7/255, 12/255, 0.97));
            hz.addColorStop(0.30, Qt.rgba(6/255, 7/255, 12/255, 0.90));
            hz.addColorStop(0.46, Qt.rgba(6/255, 7/255, 12/255, 0.28));
            hz.addColorStop(0.58, Qt.rgba(6/255, 7/255, 12/255, 0));
            ctx.fillStyle = hz;
            ctx.fillRect(0, 0, w, h);

            var abajo = ctx.createLinearGradient(0, h, 0, 0);
            abajo.addColorStop(0.00, Qt.rgba(4/255, 5/255, 10/255, 0.85));
            abajo.addColorStop(0.42, Qt.rgba(4/255, 5/255, 10/255, 0));
            ctx.fillStyle = abajo;
            ctx.fillRect(0, 0, w, h);

            var arriba = ctx.createLinearGradient(0, 0, 0, h);
            arriba.addColorStop(0.00, Qt.rgba(4/255, 5/255, 10/255, 0.85));
            arriba.addColorStop(0.22, Qt.rgba(4/255, 5/255, 10/255, 0));
            ctx.fillStyle = arriba;
            ctx.fillRect(0, 0, w, h);
        }
    }

    // El marco de 720 de alto donde viven el video y la columna de texto. Por
    // ADR-0019 el lienzo puede medir mas de 720 (1280x800 en 16:10): las
    // medidas del diseño son sobre 720, asi que se centran en vertical en vez
    // de pegarse arriba. En horizontal si van contra el borde izquierdo, como
    // en el diseño (`left:72px`).
    Item {
        id: marco
        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
        height: Theme.canvasHeight
    }

    // ------------------------------------------------------------- video
    //
    // UN PAR MediaPlayer + VideoOutput NUEVO POR CADA CLIP (ADR-0029). Este es
    // el "segundo lugar que cambia de video sin cambiar de pantalla" que ese
    // ADR anticipa: reusar el player entre clips deja al VideoOutput con la
    // geometria del anterior y el panel sale vacio, sin error. Mismo patron
    // que HeroVideoPreview.qml: el Loader pasa por null entre un clip y otro.
    //
    // La cadena: al entrar en una plataforma se elige un juego al azar con
    // video, y se pasa a otro distinto (Platforms.siguiente) cuando el clip
    // termina O cuando lleva `topeClip` reproduciendo, lo que llegue primero
    // (pedido del autor, 2026-09-22: "hasta 1 minuto de cada juego"). Con un
    // solo video en la plataforma, "otro" es el mismo desde el principio.
    //
    // EL SONIDO CUELGA DE `silenciado`, que baja de theme.qml y es la misma
    // perilla que la del preview de Home (tecla S). Los dos bindings —`muted` y
    // `volume`— se dejan declarativos a proposito: fijarlos a mano antes del
    // play(), como en 017, cortaria el binding y la S dejaria de hacer efecto
    // desde el segundo clip.
    //
    // 0.3 es lineal, no el 30 % percibido; es el mismo numero que
    // HeroVideoPreview, para que pasar del selector a Home no cambie de nivel.

    // Cuanto se muestra de cada juego como maximo, en ms. Cuenta desde que el
    // clip REPRODUCE, no desde que se pide: la carga no le come tiempo.
    property int topeClip: 60000

    readonly property var videos: plataforma ? plataforma.videos : []
    property var juegoVideo: null
    property string videoActual: ""

    readonly property var player: cargaVideo.item ? cargaVideo.item.reproductor : null
    readonly property bool reproduciendo:
        player !== null && player.playbackState === MediaPlayer.PlayingState

    onPlataformaChanged: programarVideo()
    onEncendidoChanged: {
        programarVideo();
        // Volver desde Home no cambia de plataforma, asi que PlatformData no
        // vuelve a elegir solo: se le pide otro emblema para esta visita.
        if (encendido) datos.elegirEmblema();
    }

    // Pasar por varias plataformas seguidas no arranca un video por cada una:
    // se espera a que el foco se quede quieto, como el delay de 017.
    Timer {
        id: demoraVideo
        interval: 450
        onTriggered: root.cargarVideo(Platforms.siguiente(root.videos, null, Math.random))
    }

    // El cambio de clip se difiere un tick: la señal de fin llega desde ADENTRO
    // del par, y destruirlo desde su propio handler es borrar el objeto que
    // esta ejecutando.
    Timer {
        id: proximoClip
        interval: 1
        onTriggered: root.cargarVideo(Platforms.siguiente(root.videos, root.juegoVideo, Math.random))
    }

    // El minuto. Lo arranca arrancar() con el primer play() del clip y lo
    // para cargarVideo() al cambiar de clip o de plataforma.
    Timer {
        id: limiteClip
        interval: root.topeClip
        onTriggered: root.terminoClip(cargaVideo.item, false)
    }

    // El timer se arma SIN mirar `videos`: cuando llega onPlataformaChanged,
    // el binding de `videos` todavia puede tener el valor de la plataforma
    // ANTERIOR — al arrancar, la lista vacia de antes de que Catalog cargue.
    // Es la trampa que HeroVideoPreview.reiniciar() ya documenta. En Pegasus
    // (2026-09-22) el selector arrancaba sin video por esto; en qmlscene el
    // orden de evaluacion salio al reves y no se vio. Cuando el timer dispara,
    // `videos` ya vale lo de la plataforma nueva, y con cero videos
    // Platforms.siguiente da null y no se arma nada.
    function programarVideo() {
        demoraVideo.stop();
        proximoClip.stop();
        limiteClip.stop();
        cargarVideo(null);
        if (encendido) demoraVideo.restart();
    }

    function cargarVideo(game) {
        limiteClip.stop();
        juegoVideo = game;
        videoActual = (game && game.assets && game.assets.video) ? String(game.assets.video) : "";
        cargaVideo.sourceComponent = null;
        if (videoActual !== "" && encendido)
            cargaVideo.sourceComponent = reproductorComp;
    }

    function arrancar(mp) {
        if (!mp) return;
        // Siempre 1: el fin del clip es lo que encadena, tambien con un solo
        // video (vuelve a empezar con un par nuevo, igual que al minuto).
        mp.loops = 1;
        mp.play();
        // arrancar() corre mas de una vez por clip (Loaded y Buffered): el
        // minuto se cuenta desde la primera, no se reinicia.
        if (!limiteClip.running) limiteClip.start();
    }

    // Fin del clip. Llega por tres caminos —status EndOfMedia, el player que
    // se para solo, y el minuto de `limiteClip`— y se acepta solo el primero.
    //
    // Un clip que FALLA no se reintenta si es el unico: con un solo video,
    // "el siguiente" es el mismo archivo roto y la cadena lo recargaria en
    // bucle cada tick. Con otros, se sigue con el proximo.
    function terminoClip(par, porError) {
        if (!par || par.terminado) return;
        par.terminado = true;
        limiteClip.stop();
        if (porError && root.videos.length <= 1) return;
        proximoClip.restart();
    }

    Component {
        id: reproductorComp

        Item {
            id: par
            property alias reproductor: mp
            property bool terminado: false

            VideoOutput {
                anchors.fill: parent
                source: mp
                fillMode: VideoOutput.PreserveAspectCrop
            }

            MediaPlayer {
                id: mp
                source: root.videoActual
                autoPlay: false
                muted: root.silenciado
                volume: root.silenciado ? 0 : 0.3

                // El play() espera a que la media este cargada: durante
                // Loading se acepta y se descarta en silencio
                // (docs/plataforma-pegasus.md §QtMultimedia). Loaded Y
                // Buffered, porque la secuencia no es estable.
                onStatusChanged: {
                    if (status === MediaPlayer.Loaded || status === MediaPlayer.Buffered) {
                        if (playbackState !== MediaPlayer.PlayingState && !par.terminado)
                            root.arrancar(mp);
                    } else if (status === MediaPlayer.EndOfMedia) {
                        root.terminoClip(par, false);
                    }
                }
                onPlaybackStateChanged: {
                    if (playbackState === MediaPlayer.StoppedState && status === MediaPlayer.EndOfMedia)
                        root.terminoClip(par, false);
                }
                // Un clip que no carga no corta la cadena: se pasa al siguiente
                // (si hay otro; con uno solo el panel queda apagado).
                onError: {
                    console.warn("PlatformSelectScreen: no pudo reproducir", source, "—", errorString);
                    root.terminoClip(par, true);
                }
            }
        }
    }

    // El panel: left 72, top 190, 440x248. Sin video no se dibuja nada, pero
    // el hueco de la columna de texto se reserva igual (ver `hueco`).
    Item {
        id: panelVideo
        x: 72
        y: marco.y + 190
        width: 440
        height: 248
        opacity: root.reproduciendo ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.InOutQuad } }

        Loader {
            id: cargaVideo
            anchors.fill: parent
        }

        // `inset:-1px` del diseño: el fundido cubre un pixel de mas para que
        // el canto del video no asome por redondeo al escalar el lienzo.
        //
        // Supone que PreserveAspectCrop LLENA la caja, que es lo que se vio
        // en Pegasus (docs/plataforma-pegasus.md §5). En qmlscene con Qt 5.9
        // no: un clip 4:3 sale encajado (~330 de ancho) aunque contentRect
        // diga la caja entera, y los costados de la imagen quedan con canto.
        // Se verifica en Pegasus (tasks.md §4).
        DissolvePanel {
            anchors { fill: parent; margins: -1 }
        }
    }

    // ----------------------------------------------------------- emblema
    // Caja desde el 38% hasta el borde derecho, imagen contenida y alineada a
    // la derecha. Opcional: sin emblema.png no se dibuja nada.
    //
    // EL FUNDIDO LE BAJA EL ALFA AL EMBLEMA; no pinta nada encima. Antes era
    // un Canvas que pintaba un negro fijo sobre los bordes, y en Pegasus
    // (2026-09-22) se veian DOS NEGROS: el fondo de abajo no es parejo —cambia
    // con la altura por los scrims y el degradado de Background— y ningun
    // color fijo coincide en toda la columna. A y=150 el fondo valia
    // (8,10,15) y el Canvas pintaba (6,7,12): una costura vertical en el canto
    // izquierdo de la imagen. Con alfa, lo que se ve en el borde es el fondo
    // real, sea el que sea.
    //
    // POR QUE ESTO NO CHOCA CON "sin mascaras" (plan.md §Decisiones): esa regla
    // salio de la linea de 1 px que la mascara dejaba sobre la capa acelerada
    // del VIDEO en el prototipo. El emblema es una Image. Y la tecnica ya esta
    // en este binario: el ShaderEffect de screens/HeroVideoPreview.qml, que
    // ademas enmascara un video sin esa linea.
    //
    // La mascara es la del diseño, sobre la CAJA (no sobre la imagen):
    //
    //   radial-gradient(120% 118% at 68% 46%, #000 52%, rgba(0,0,0,.55) 78%,
    //                   transparent 100%)
    //   linear-gradient(90deg, transparent 0%, #000 16%)
    //   mask-composite: intersect      -> las dos se multiplican
    //
    // `ShaderEffect.status` miente en este binario (reporta Error y dibuja):
    // no se mira, ver docs/plataforma-pegasus.md §2.
    Item {
        id: cajaEmblema
        anchors { top: parent.top; bottom: parent.bottom; right: parent.right }
        width: parent.width * 0.62
        readonly property bool hayEmblema: emblema.status === Image.Ready

        Image {
            id: emblema
            anchors.fill: parent
            source: datos.emblema
            asynchronous: true
            fillMode: Image.PreserveAspectFit
            horizontalAlignment: Image.AlignRight
            verticalAlignment: Image.AlignVCenter
            // Solo alimenta al ShaderEffect: la que se ve es la enmascarada.
            visible: false
        }

        ShaderEffect {
            anchors.fill: parent
            visible: cajaEmblema.hayEmblema

            property variant source: ShaderEffectSource {
                sourceItem: emblema
                live: true
                // `emblema` ya es visible:false por su cuenta: la misma
                // configuracion que se midio en HeroVideoPreview (2026-08-21).
                hideSource: false
            }

            fragmentShader: "
                varying highp vec2 qt_TexCoord0;
                uniform sampler2D source;
                uniform lowp float qt_Opacity;

                void main() {
                    highp vec2 uv = qt_TexCoord0;

                    // Elipse de radios 120% x 118% de la caja, centrada en
                    // 68% / 46%: d = 1 es el 100% del degradado CSS.
                    highp float d = length(vec2((uv.x - 0.68) / 1.20,
                                                (uv.y - 0.46) / 1.18));
                    highp float radial = d <= 0.52 ? 1.0
                        : d <= 0.78 ? mix(1.0, 0.55, (d - 0.52) / 0.26)
                        : mix(0.55, 0.0, clamp((d - 0.78) / 0.22, 0.0, 1.0));

                    // Transparente en el canto izquierdo, opaco desde el 16%.
                    highp float lateral = clamp(uv.x / 0.16, 0.0, 1.0);

                    // La textura ya viene premultiplicada: se escala entera.
                    gl_FragColor = texture2D(source, uv) * (radial * lateral * qt_Opacity);
                }
            "
        }
    }

    // -------------------------------------------------- columna de texto
    // Hueco del video + nombre + conteo. El hueco se reserva SIEMPRE, haya
    // video o no: el nombre no puede saltar de lugar entre una plataforma con
    // video y otra sin (spec §Criterios). Por eso el nombre se ancla al hueco
    // y no a la mitad de la pantalla como el `justify-content:center` del
    // prototipo — ahi un nombre de dos renglones subia el bloque entero.
    Item {
        id: hueco
        x: 72
        y: marco.y + 190
        width: 440
        height: 248
    }

    Text {
        id: nombre
        anchors { top: hueco.bottom; topMargin: 14; left: hueco.left }
        width: 600                                  // max-width del diseño
        text: datos.nombre
        color: Theme.textPrimary
        wrapMode: Text.WordWrap
        maximumLineCount: 2
        elide: Text.ElideRight
        lineHeight: 0.96
        font.family: Theme.fontDisplay
        font.bold: true
        font.italic: true
        font.pixelSize: 52
        font.letterSpacing: -0.01 * 52
    }

    Row {
        anchors { top: nombre.bottom; topMargin: 10; left: hueco.left }
        spacing: 11

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 7; height: 7
            rotation: 45
            color: root.accent
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Platforms.textoConteo(root.plataformas, root.idx)
            color: "#c2c6d2"
            font.family: Theme.fontMono
            font.pixelSize: 14
            font.letterSpacing: 0.08 * 14
        }
    }

    // ----------------------------------------------------------- flechas
    // Clickeables (el prototipo lo es), pero la entrada primaria es el mando.
    Repeater {
        model: [-1, 1]

        Rectangle {
            readonly property bool izquierda: modelData < 0
            anchors.verticalCenter: parent.verticalCenter
            x: izquierda ? 18 : root.width - 18 - width
            width: 40; height: 120
            radius: 9
            color: sobre.containsMouse ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(10/255, 12/255, 18/255, 0.5)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.10)
            visible: root.plataformas.length > 1

            Text {
                anchors.centerIn: parent
                text: parent.izquierda ? "◄" : "►"
                color: sobre.containsMouse ? Theme.textPrimary : "#aeb3c0"
                font.family: Theme.fontMono
                font.pixelSize: 15
            }

            MouseArea {
                id: sobre
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.mover(modelData)
            }
        }
    }

    // ------------------------------------------------------------- barra
    Item {
        id: barra
        anchors { top: parent.top; left: parent.left; right: parent.right }
        anchors { topMargin: 22; leftMargin: Theme.gutter; rightMargin: Theme.gutter }
        height: 34

        Row {
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            spacing: 18

            // Mismo wordmark que Home, para que las dos pantallas se lean como
            // la misma app.
            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 11

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 13; height: 13; radius: 3
                    color: root.accent
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.wordmark
                    color: Theme.textPrimary
                    font.family: Theme.fontDisplay
                    font.bold: true
                    font.pixelSize: 15
                    font.letterSpacing: 0.16 * 15
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "ARCADE"
                    color: Theme.textFaint
                    font.family: Theme.fontDisplay
                    font.pixelSize: 15
                    font.letterSpacing: 0.16 * 15
                }
            }

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 16

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 1; height: 14
                    color: Qt.rgba(1, 1, 1, 0.12)
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "PRESELECTOR DE PLATAFORMA"
                    color: Theme.textFaint
                    font.family: Theme.fontMono
                    font.pixelSize: 10
                    font.letterSpacing: 0.16 * 10
                }
            }

            // Solo si la plataforma tiene logo.png: sin el, `visible: false`
            // y el Row no le reserva lugar ni espacio.
            Item {
                anchors.verticalCenter: parent.verticalCenter
                width: 104; height: 30
                opacity: 0.9
                visible: logo.status === Image.Ready

                Image {
                    id: logo
                    anchors.fill: parent
                    source: datos.logo
                    asynchronous: true
                    fillMode: Image.PreserveAspectFit
                    horizontalAlignment: Image.AlignLeft
                    verticalAlignment: Image.AlignVCenter
                }
            }
        }

        Row {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            spacing: 14

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Platforms.textoTotal(root.plataformas)
                color: Theme.textMuted
                font.family: Theme.fontMono
                font.pixelSize: 11
                font.letterSpacing: 0.08 * 11
            }
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 1; height: 16
                color: Qt.rgba(1, 1, 1, 0.12)
            }
            Text {
                id: reloj
                anchors.verticalCenter: parent.verticalCenter
                color: "#7c8294"
                font.family: Theme.fontMono
                font.pixelSize: 12
                font.letterSpacing: 0.08 * 12
                text: "--:--"

                // Cada 20s, como el de Home: no hay segundero en pantalla.
                Timer {
                    interval: 20000
                    running: root.visible
                    repeat: true
                    triggeredOnStart: true
                    onTriggered: {
                        var d = new Date();
                        reloj.text = ("0" + d.getHours()).slice(-2) + ":"
                                   + ("0" + d.getMinutes()).slice(-2);
                    }
                }
            }
        }
    }

    // ------------------------------------------------------------ leyenda
    // No estan los cuatro del prototipo: B no hace nada aca, y una leyenda que
    // nombra una tecla muerta miente (ui/Leyenda.qml).
    //
    // "↵" y no "A": la A del prototipo es el BOTON del mando, y en el teclado
    // no existe — `keys.accept` de Pegasus es D, Return, Enter y GamepadA
    // (settings.txt del gabinete, 2026-09-23). Quien mira la leyenda con un
    // teclado apretaba la A y no pasaba nada. El signo de Enter lo entienden
    // los dos: es la tecla, y es el boton de abajo del mando.
    Rectangle {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: leyenda.height + 36              // padding 16px arriba, 20px abajo
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 1.0; color: Qt.rgba(4/255, 5/255, 10/255, 0.9) }
        }

        Leyenda {
            id: leyenda
            anchors { left: parent.left; leftMargin: Theme.gutter; bottom: parent.bottom; bottomMargin: 20 }
            accent: root.accent
            atajos: [{ k: "◄ ►", l: "CAMBIAR PLATAFORMA" }, { k: "↵", l: "SELECCIONAR" },
                     { k: "X", l: "ALEATORIO" },
                     { k: "S", l: root.silenciado ? "ACTIVAR SONIDO" : "SILENCIAR" }]
        }
    }
}
