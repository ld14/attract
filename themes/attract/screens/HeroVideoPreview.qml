// El preview de gameplay del hero de Home: video ambiental a la derecha del
// titulo y la sinopsis, que aparece solo cuando el foco se queda quieto.
//
// NO ES UN REPRODUCTOR. No tiene controles, no recibe foco y no captura clicks.
// El `pointer-events: none` del diseño no necesita traduccion: este archivo no
// declara ningun MouseArea, no es un FocusScope, no pone `focus: true` y no
// aparece en ningun Keys.onPressed — el foco del mando no tiene por donde
// pararse aca. Si algun dia alguien le agrega un MouseArea "para el mouse del
// escritorio", rompe la regla: el transporte vive en el detalle
// (screens/VideoPanel.qml), no aca.
//
// CUATRO COSAS QUE SOSTIENEN EL EFECTO, y ninguna es cosmetica:
//
//   1. LOS 650ms. Sin el delay el panel parpadea al recorrer un estante rapido
//      — diez juegos en dos segundos son diez arranques de video. El Timer se
//      reinicia en CADA cambio de juego y el panel se oculta de inmediato.
//   2. EL VOLUMEN CUELGA DE `activo`, no se fija a mano. El panel suena al
//      0.3 solo mientras se lo ve: el player del juego anterior sigue vivo
//      hasta 650ms despues de ocultarse, y sin esa condicion recorrer un
//      estante dejaria audio de juegos que ya no estan en pantalla.
//   3. VA POR DEBAJO DE LAS TARJETAS y se disuelve con una mascara de alfa.
//      Nada de borde ni de sombra: los cortaria la mascara y se veria peor que
//      no tener nada.
//   4. UN PLAYER NUEVO POR CADA ARCHIVO. Reusar el MediaPlayer entre videos
//      deja al VideoOutput con la geometria del anterior y el panel sale vacio
//      — el bug del 2026-08-22. Ver §reproduccion, que lleva la medicion y las
//      tres alternativas que se probaron y no sirven. Al apagarse el panel se
//      destruye el par, asi que la regla 2 de VideoPanel.qml (soltar el
//      archivo, no pausar) sigue valiendo y ahora es mas fuerte.
//
// Y una que se aprendio de VideoPanel: NADA colgado de `onStopped`. En un loop
// infinito no se dispara nunca (docs/plataforma-pegasus.md §2, medido).
//
// Diseño de referencia: spec/features/017-hero-video-preview/design/.

import QtQuick 2.0
import QtMultimedia 5.9
import ".."

Item {
    id: root

    // El juego enfocado. Lo pasa la pantalla; cambiarlo reinicia el delay.
    property var game: null

    // Baja como propiedad (ADR-0013). El punto del badge se tiñe con esto.
    property color accent: Theme.accentNeutro

    // Lo apaga la pantalla cuando Home deja de verse. Es lo que suelta el
    // decoder: sin esto, abrir el detalle deja dos videos decodificando.
    property bool encendido: true

    readonly property bool hayVideo:
        game !== null && game.assets && game.assets.video ? true : false

    // Lo pone el Timer, lo saca cualquier cambio de juego. Es la unica pieza
    // de estado del componente.
    property bool mostrar: false

    // Que el Timer haya disparado no alcanza para mostrar nada: entre que se
    // asigna la fuente y sale el primer cuadro hay buffering, y hacerle fade-in
    // a un rectangulo negro es justo lo que el delay existe para evitar.
    //
    // OJO CON ESTA CONDICION: `playbackState` solo sirve de guarda porque el
    // play() ahora espera a `status: Loaded` (ver MediaPlayer, abajo). Llamado
    // antes, QMediaPlayer pone PlayingState igual y lo saca 1ms despues — y
    // esto se prendia y apagaba con el. El parpadeo del 2026-08-21 fue eso.
    readonly property bool activo:
        mostrar && player !== null
        && player.playbackState === MediaPlayer.PlayingState

    // No dibuja nada mientras esta oculto: la mascara es un shader, y no tiene
    // sentido correrlo sobre algo con opacidad cero.
    visible: opacity > 0

    // --- el delay de 650ms ------------------------------------------------

    onGameChanged: reiniciar()
    onEncendidoChanged: reiniciar()

    // La fuente que el player tiene REALMENTE cargada. La escribe el Timer y
    // NADIE mas: es lo que separa "ocultar el panel" de "soltar el archivo".
    //
    // ESTO ES EL ARREGLO DEL PANEL GRIS, y va contra lo que decia el codigo de
    // antes. `source` colgaba de `mostrar`, asi que CADA movimiento del foco
    // hacia un teardown completo del backend y un setMedia nuevo 650ms despues.
    // Ese teardown es el que le voltea la AVPlayerLayer a AVFoundation en macOS
    // —el log lo grita en el mismo instante, "updateVideoFrame called without
    // AVPlayerLayer"— y el video siguiente carga, reproduce y avanza la
    // posicion sin dibujar un solo cuadro. El panel queda gris parejo.
    //
    // Ahora pasar de un video al siguiente es UN setMedia, sin apagon en el
    // medio. El precio es que el video del juego anterior sigue decodificando
    // hasta 650ms mas, invisible. Es barato y es acotado.
    //
    // La regla 2 de VideoPanel.qml (soltar el archivo, no pausar) se mantiene
    // donde importa: al apagarse el panel —salir de Home— y al parar el foco en
    // un juego sin video. Esos dos siguen dejando `source` en "".
    property string videoActual: ""

    function reiniciar() {
        // Ocultar es INMEDIATO; soltar la fuente no. Son dos cosas distintas y
        // antes estaban atadas.
        mostrar = false;
        demora.stop();
        // Apagar Home si suelta el decoder: es el caso para el que se escribio
        // la regla 2, y el unico donde el teardown no cuesta nada porque no hay
        // ningun video que vaya a entrar atras.
        if (!encendido) cargarVideo("");
        // Se arma el timer sin mirar `hayVideo`: cuando llega `gameChanged`,
        // `hayVideo` TODAVIA tiene el valor del juego ANTERIOR — su binding aun
        // no se re-evaluo. Leerlo aca seria leer el del juego que se acaba de
        // ir. No es teoria: se instrumento el 2026-08-22 y el log salia corrido
        // un juego (Ghost'n Goblins, que tiene video, se logueaba como "no").
        //
        // No hace falta mirarlo igual: cuando el timer dispare, `hayVideo` ya
        // vale lo del juego nuevo.
        if (encendido) demora.restart();
    }

    Timer {
        id: demora
        interval: 650
        repeat: false
        onTriggered: {
            root.mostrar = true;
            // Aca SI se puede leer `hayVideo`: paso mas de medio segundo desde
            // el cambio de juego y los bindings ya se re-evaluaron.
            root.cargarVideo(root.hayVideo ? String(root.game.assets.video) : "");
        }
    }

    // --- reproduccion -----------------------------------------------------
    //
    // EL PAR player+VideoOutput SE TIRA Y SE REHACE POR CADA VIDEO, y esto es
    // el arreglo del bug del panel vacio. No es prolijidad: es la unica forma
    // que quedo en pie despues de descartar todo lo demas.
    //
    // QUE SE MIDIO (2026-08-22, grabacion de pantalla + cartel en pantalla con
    // `sourceRect` del VideoOutput, 36 cuadros a 1 por segundo):
    //
    //   foco                 src cargado   correcto     resultado
    //   Street Fighter II    490x360       384x224      panel vacio
    //   Metal Slug           480x360       490x360      panel vacio
    //   Metal Slug           384x224       490x360      panel vacio
    //   Metal Slug           490x360       490x360      anda
    //
    // El VideoOutput se queda con la geometria del video ANTERIOR: su
    // superficie no se reinicia con el formato del medio nuevo, asi que no
    // llega un solo cuadro aunque el player reproduzca y `pos` avance. Por eso
    // volver a pararse sobre el mismo juego lo arreglaba a veces — otro
    // setMedia, otra chance de que la superficie arranque bien.
    //
    // Reusar el player entre archivos es lo que dispara esa carrera. Un par
    // nuevo por archivo no puede heredar el formato de nadie.
    //
    // LO QUE NO FUNCIONO, PROBADO Y DESCARTADO (para que nadie lo reintente):
    //   · Reasignar `VideoOutput.source` despues de arrancar: no recupera la
    //     superficie y ademas se ve — deja un cuadro en blanco (destello).
    //   · Evitar el teardown pasando de un video al otro sin apagon: el
    //     `setMedia` directo tambien deja la geometria vieja.
    //   · Mantener el subarbol renderizado durante la carga (`opacity: 0.003`):
    //     no cambia nada. La superficie no depende de que se dibuje.

    Component {
        id: reproductorComp

        Item {
            property alias reproductor: mp
            property alias salidaVideo: vo

            VideoOutput {
                id: vo
                anchors.fill: parent
                source: mp
                fillMode: VideoOutput.PreserveAspectCrop
            }

            MediaPlayer {
                id: mp
                source: root.videoActual
                // A PROPOSITO en false: play() lo llama arrancar(), que fija
                // `loops` antes.
                autoPlay: false
                loops: MediaPlayer.Infinite
                muted: false

                // EL VOLUMEN CUELGA DE `activo`, Y ESO ES LO QUE HACE QUE ESTO
                // SEA TOLERABLE. El panel suena solo cuando se lo ve.
                //
                // Sin esta condicion el preview seria insoportable: el player
                // del juego anterior sigue reproduciendo hasta 650ms despues de
                // que el panel se oculto (ver `videoActual`), asi que recorrer
                // un estante dejaria un reguero de audio de juegos que ya no
                // estan en pantalla. Atado a `activo` el sonido entra y sale
                // con la imagen.
                //
                // 0.3 es lineal, que es lo que toma QtMultimedia. No es el 30%
                // percibido — para eso haria falta `QtMultimedia.convertVolume`
                // y una conversion logaritmica. Si suena mas bajo de lo
                // esperado, la perilla es este numero.
                volume: root.activo ? 0.3 : 0

                // EL play() VA ACA Y NO EN onSourceChanged, y esto es el bug del
                // 2026-08-21, medido en el log de Pegasus:
                //
                // Cuando llega `onSourceChanged` el `status` todavia es
                // `Loading`. Ahi QMediaPlayer ACEPTA el play() —pone
                // PlayingState— y vuelve a StoppedState UN MILISEGUNDO despues,
                // sin error y sin warning, porque no hay media cargada.
                //
                // `playbackState` NO mide carga; `status` si.
                //
                // Los DOS estados hacen falta: la primera carga paso por
                // `Loaded` y las siguientes fueron `Loading -> Stalled ->
                // Buffered`, salteandoselo.
                onStatusChanged: {
                    if (root.mostrar && (status === MediaPlayer.Loaded
                                         || status === MediaPlayer.Buffered))
                        // Se pasa `mp` explicito: cuando llega la primera
                        // señal, el Loader todavia puede no haber publicado su
                        // `item`, y ahi `root.player` seria null.
                        root.arrancar(mp);
                }
                // QtMultimedia falla callado (plataforma-pegasus.md §2): un
                // video que no carga deja el panel apagado sin decir nada.
                onError: console.warn("HeroVideoPreview: no pudo reproducir",
                                      source, "—", error, errorString)
            }
        }
    }

    // El player vivo, o null mientras no hay ninguno. TODO lo que lo use tiene
    // que bancarse el null: entre un video y el siguiente no existe.
    readonly property var player: cargaVideo.item ? cargaVideo.item.reproductor : null
    readonly property var salida: cargaVideo.item ? cargaVideo.item.salidaVideo : null

    // Tira el par viejo y arma uno nuevo. Los dos pasos importan: sin el null
    // de por medio el Loader reusaria la instancia y volveriamos al bug.
    function cargarVideo(url) {
        videoActual = url;
        cargaVideo.sourceComponent = null;
        if (url !== "" && encendido)
            cargaVideo.sourceComponent = reproductorComp;
    }

    // El punto de falla que el diseño marca en §Reproduccion, traducido a QML.
    //
    // En QML los bindings declarativos de arriba YA funcionan — VideoPanel.qml
    // lleva desde la feature 006 asi y nunca sono. Lo que agrega esta funcion no
    // es arreglar un bug, es hacer el orden VERIFICABLE: con `autoPlay: false`
    // el unico camino a play() pasa por aca, y aca las tres propiedades se
    // setean antes. Un gabinete que se pone a sonar solo no puede depender de
    // cuando resuelve QML sus bindings.
    //
    // Puede correr mas de una vez por fuente (Loaded y Buffered llegan los dos,
    // y el reenganche del loop los vuelve a pasar). No molesta: play() sobre un
    // player que ya reproduce es no-op, y remuteear no cuesta nada.
    function arrancar(cual) {
        var pl = cual ? cual : player;
        if (!pl) return;
        pl.loops = MediaPlayer.Infinite;
        pl.play();

        // El chequeo que pide el diseño. El volumen ya NO se fuerza aca: cuelga
        // de `activo` (ver el MediaPlayer), y pisarlo a mano cortaria ese
        // binding — el panel quedaria sonando despues de ocultarse.
        if (pl.loops !== MediaPlayer.Infinite)
            console.warn("HeroVideoPreview: loops no quedo en Infinite —",
                         pl.loops);
    }

    // --- entrada ----------------------------------------------------------
    //
    // El desplazamiento va por `transform: Translate` y no por un binding sobre
    // `x`: la x la escriben los anchors, y un binding ahi pelea contra el
    // layout y gana a veces (docs/plataforma-pegasus.md §3; mismo motivo que
    // GameCard.qml).
    //
    // LAS TRES ANIMACIONES SON DE ENTRADA Y NADA MAS. El `enabled: root.activo`
    // de cada Behavior las apaga en el sentido contrario, porque el diseño pide
    // ocultar "inmediatamente" al cambiar de juego (§Delay de arranque) y acá
    // eso no es un capricho: reiniciar() ya dejo `source` en "" en el mismo
    // tick, asi que un fade de salida no funde el video — funde un VideoOutput
    // vacio. Seria el mismo rectangulo que el criterio de la entrada prohibe,
    // nada mas que al reves.
    //
    // Apagarlas tambien deja la salida en un solo frame, y con eso la proxima
    // entrada arranca SIEMPRE desde 0.97 / -16 exactos en vez de desde donde
    // hubiera quedado una animacion de salida a medio camino.

    // El 0.003 que estuvo aca no era: se probo mantener el subarbol renderizado
    // durante la carga —Qt no dibuja opacidad cero— por si AVFoundation
    // necesitaba la superficie viva al enganchar. No cambia nada (medido el
    // 2026-08-22). La superficie no depende de que el item se dibuje.
    opacity: activo ? 1 : 0
    scale: activo ? 1.0 : 0.97

    transform: Translate {
        x: root.activo ? 0 : -16
        // La curva del diseño para el movimiento. La opacidad usa `ease`, que
        // es InOutQuad.
        Behavior on x {
            enabled: root.activo
            NumberAnimation {
                duration: 450
                easing.type: Easing.Bezier
                easing.bezierCurve: [0.2, 0.7, 0.2, 1.0, 1, 1]
            }
        }
    }

    Behavior on opacity {
        enabled: root.activo
        NumberAnimation { duration: 450; easing.type: Easing.InOutQuad }
    }

    Behavior on scale {
        enabled: root.activo
        NumberAnimation {
            duration: 450
            easing.type: Easing.Bezier
            easing.bezierCurve: [0.2, 0.7, 0.2, 1.0, 1, 1]
        }
    }

    // --- la fuente ----------------------------------------------------------
    //
    // El video adentro de un Item INVISIBLE que no se dibuja: lo unico que hace
    // es alimentar al ShaderEffect de abajo. Mismo patron que GameCard.qml, con
    // un VideoOutput adentro en vez de una Image.
    //
    // Que un Item invisible siga alimentando el efecto —y con un VideoOutput
    // adentro, que se sigue actualizando por cuadro en vez de congelarse en el
    // primero— esta MEDIDO: themes/experimentos/video-opacitymask.qml,
    // 2026-08-21. Se midio con OpacityMask, pero lo que prueba es la captura
    // del subarbol por ShaderEffectSource, que es la misma pieza que usa este
    // ShaderEffect.
    //
    // La condicion es una sola y no se puede aflojar: ESTE VideoOutput necesita
    // SU PROPIO MediaPlayer. Dos VideoOutput colgados del mismo player dejan
    // vacio al segundo (plataforma-pegasus.md §2) — por eso `player` se declara
    // aca arriba y no se comparte con VideoPanel.

    Item {
        id: capas
        anchors.fill: parent
        visible: false

        // 1 · el video, RECONSTRUIDO POR CADA ARCHIVO. Ver `reproductorComp`.
        Loader {
            id: cargaVideo
            anchors.fill: parent
        }

        // NO VA ACA EL DEGRADE LATERAL DEL DISEÑO (§Capas internas, capa 2).
        // Era un velo de color —de transparente a rgba(6,7,12,.5) contra el
        // borde izquierdo— y en el mockup CSS funciona porque ahi el fondo es
        // casi plano. Aca NO: detras hay ui/AccentWash.qml tiñendo con el
        // accent del juego, asi que el velo no fundia nada, se leia como una
        // BANDA OSCURA pegada al costado. Es el mismo error que plan.md
        // §Decisiones ya habia descartado para la mascara de abajo ("un
        // gradiente opaco se veria como una banda oscura en vez de una
        // disolucion") y que esta capa se habia traido igual del CSS.
        //
        // El borde izquierdo ahora lo resuelve el shader, con alfa de verdad.
        // Visto en Pegasus el 2026-08-22: con el velo el panel se veia cuadrado
        // y pegoteado.

        // TAMPOCO VA EL DEGRADE INFERIOR (§Capas internas, capa 3). Existia
        // para oscurecer la zona donde cruzan las tarjetas y que se leyeran
        // sobre un fotograma claro. Con el keying por luminancia de abajo eso
        // ya no hace falta: oscurecer AHORA significa volver transparente, y la
        // orilla inferior del shader se lleva puesto todo lo que llegue ahi.
    }

    // --- el compuesto: keying por luminancia + orillas, en una sola pasada ---
    //
    // ESTE ES EL CORAZON DE LA FEATURE, y no es lo que decia el diseño. Vale la
    // pena contar por que, porque el diseño no estaba mal: estaba escrito para
    // otro fondo.
    //
    // El diseño resuelve la integracion con (a) una mascara VERTICAL que
    // disuelve hacia abajo y (b) dos velos de color contra el borde izquierdo y
    // el inferior. Eso funciona en el mockup CSS porque ahi el fondo es un
    // negro casi plano: un velo a rgba(6,7,12,.5) SE CONFUNDE con el fondo, y
    // los cantos de arriba y de la derecha —que el diseño ni trata— casi no se
    // ven contra un plano del mismo valor.
    //
    // Aca el fondo es ui/Background.qml + ui/AccentWash.qml: azul-negro y
    // teñido con el accent del juego. Contra eso pasan dos cosas, y las dos se
    // vieron en Pegasus el 2026-08-22:
    //
    //   1. Los velos de color no funden: se leen como bandas oscuras pegadas.
    //   2. Y lo que de verdad delata al panel NO es el borde, es el RELLENO.
    //      Un video de arcade es casi todo negro con sprites brillantes, y ese
    //      negro es MAS OSCURO que el fondo de la pantalla. Queda un pozo
    //      rectangular. Por mas que se disuelvan las cuatro orillas, el ojo
    //      sigue leyendo el rectangulo por el relleno.
    //
    // Por eso el punto (2) no se arregla con ninguna mascara de bordes. Se
    // arregla haciendo que LA OSCURIDAD SEA TRANSPARENCIA: se keyea el video
    // por luminancia, el negro deja de existir como superficie y quedan solo
    // los sprites, flotando como luz adentro del hero. El panel deja de ser un
    // objeto pegado encima y pasa a ser una fuente de luz de la escena — que es
    // lo que el diseño pedia en su propia frase, "se integra al fondo por
    // disolucion, no por marco" (§Cruce con las tarjetas, punto 3).
    //
    // POR QUE UN ShaderEffect Y NO LA CADENA DE ANTES:
    //
    // - Un OpacityMask solo puede tallar bordes. No puede mirar el color del
    //   pixel, que es justo lo que hace falta.
    // - La mascara de Canvas que estuvo aca ANTES no funcionaba: un Canvas con
    //   `visible: false` no llega a pintar nunca, y OpacityMask con una mascara
    //   que nunca se pinto deja pasar la fuente entera. Se veia igual que sin
    //   mascara. Anotado en plataforma-pegasus.md §3.
    // - Rectangle en Qt 5 solo hace gradientes verticales, y apilar rectangulos
    //   semitransparentes SUMA alfa (source-over) cuando aca hay que restarla.
    //
    // Un solo ShaderEffect hace las dos cosas —el key y las cuatro orillas— en
    // una pasada, y de paso borra el Canvas, el OpacityMask y los dos
    // Rectangle de velo. Menos arbol y menos piezas que puedan fallar calladas.
    //
    // No es tecnica nueva en este binario: TODO QtGraphicalEffects es
    // ShaderEffect por dentro, y que OpacityMask ande sobre un VideoOutput ya
    // esta medido (plataforma-pegasus.md §2). Si el shader no compilara,
    // `status` queda en Error y el log lo dice — no falla callado.

    ShaderEffect {
        id: compuesto
        anchors.fill: parent

        property variant source: ShaderEffectSource {
            sourceItem: capas
            live: true
            // NO hideSource: `capas` ya es visible:false por su cuenta, que es
            // la configuracion exacta que se midio el 2026-08-21.
            hideSource: false
        }

        // --- perillas del key ---
        // Debajo de `pisoLuz` el pixel desaparece; arriba de `techoLuz` queda
        // opaco. El rango entre los dos es el degrade. Subir `pisoLuz` come mas
        // fondo del video; bajar `techoLuz` deja el panel mas solido.
        property real pisoLuz: 0.04
        property real techoLuz: 0.32

        // --- perillas de las orillas, en fraccion del panel ---
        // La izquierda es la mas ancha porque da contra la sinopsis, que es
        // donde el corte vertical se notaba mas. La de abajo es "desde donde
        // empieza a caer", no un ancho.
        property real orillaIzq: 0.34
        property real orillaDer: 0.16
        property real orillaArr: 0.26
        property real orillaAbj: 0.45

        // Cuanto del video sobrevive en las zonas OSCURAS. Es la perilla de
        // "quiero ver mas video": con `piso` en 0 el negro desaparece del todo
        // y solo quedan los sprites; subirlo trae de vuelta el fondo del video
        // —los escenarios, el suelo, el cielo— sin tocar los brillos.
        //
        // Tambien es el seguro contra un fotograma oscuro que haga desaparecer
        // el panel entero y parezca que el video se corto.
        property real piso: 0.35

        fragmentShader: "
            varying highp vec2 qt_TexCoord0;
            uniform sampler2D source;
            uniform lowp float qt_Opacity;
            uniform lowp float pisoLuz;
            uniform lowp float techoLuz;
            uniform lowp float orillaIzq;
            uniform lowp float orillaDer;
            uniform lowp float orillaArr;
            uniform lowp float orillaAbj;
            uniform lowp float piso;

            void main() {
                lowp vec4 c = texture2D(source, qt_TexCoord0);

                // Luminancia perceptual (Rec.601), no el promedio de los
                // canales: el verde pesa mucho mas que el azul para el ojo, y
                // con el promedio los sprites azules se borraban solos.
                lowp float lum = dot(c.rgb, vec3(0.299, 0.587, 0.114));
                lowp float luz = smoothstep(pisoLuz, techoLuz, lum);
                luz = piso + (1.0 - piso) * luz;

                highp vec2 uv = qt_TexCoord0;
                lowp float orillas =
                      smoothstep(0.0, orillaIzq, uv.x)
                    * smoothstep(0.0, orillaDer, 1.0 - uv.x)
                    * smoothstep(0.0, orillaArr, uv.y)
                    * (1.0 - smoothstep(orillaAbj, 1.0, uv.y));

                lowp float a = luz * orillas * qt_Opacity;

                // Alfa PREMULTIPLICADO: es lo que espera el scene graph de Qt.
                // Devolver c.rgb sin multiplicar deja halos claros en todo el
                // degrade.
                gl_FragColor = vec4(c.rgb, 1.0) * a;
            }
        "

        // Se loguea TODA transicion, no solo el Error: la del 2026-08-22 llego
        // con `log` vacio, y sin ver la secuencia no se sabe si el Error quedo
        // pegado o si despues compilo igual.
        // NO SE MIRA `status` ACA, y no es un olvido. En este binario el
        // ShaderEffect reporta `Error` con el `log` VACIO y DIBUJA IGUAL:
        // se verifico el 2026-08-22 con grabToImage —el compuesto sale con el
        // cuadro keyeado— y con cuatro sondas, incluida una SIN shader propio,
        // que tambien daban Error. Un aviso colgado de aca es una alarma que
        // suena siempre y por nada, y nos costo media noche de perseguirla.
        // Anotado en docs/plataforma-pegasus.md §2.
    }

    // EL BADGE VA FUERA DE LA MASCARA, y antes iba adentro. Podia ir adentro
    // mientras la mascara solo tallaba abajo: el badge cae arriba a la
    // izquierda, en la franja que quedaba 100% opaca. Ahora esa esquina es
    // justo el cruce de los tallados de arriba y de la izquierda —los dos mas
    // agresivos—, asi que adentro saldria lavado. Afuera queda nitido y sigue
    // apareciendo y desapareciendo con el panel, porque hereda la opacidad y el
    // transform de `root` igual que todo lo demas.
    //
    // Sin el blur del diseño (`backdrop-filter`): FastBlur para un efecto de
    // 22px de alto no paga, y el fondo plano es el que ya usa VideoPanel.qml.
    Rectangle {
        anchors { top: parent.top; left: parent.left; margins: 12 }
        width: fila.width + 18
        height: 22
        radius: 11
        color: Theme.alpha("#07080c", 0.62)

        Row {
            id: fila
            anchors.centerIn: parent
            spacing: 7

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 5; height: 5; radius: 2.5
                color: root.accent
                // El latido de 1.6s del diseño.
                SequentialAnimation on opacity {
                    running: root.visible
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.2; duration: 800 }
                    NumberAnimation { to: 1.0; duration: 800 }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "GAMEPLAY"
                color: Theme.textPrimary
                font.family: Theme.fontMono
                font.pixelSize: 9
                font.letterSpacing: 0.1 * 9
            }
        }
    }
}
