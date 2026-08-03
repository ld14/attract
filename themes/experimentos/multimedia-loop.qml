// EXPERIMENTO — ¿QtMultimedia loopea el video del juego y responde al transporte?
//
// Contexto: el panel de carátula del detalle (design_handoff_game_detail/README.md
// §2) no es una imagen: es un video de gameplay en loop, con controles propios
// dibujados por el theme — play/pausa, volumen en pasos de 0.2, un medidor de
// 5 barras y un botón de mute. El handoff dice que en Pegasus eso se ata a
// MediaPlayer/VideoOutput de QtMultimedia.
//
// QtMultimedia SÍ está en las dependencias de build declaradas de Pegasus
// (a diferencia de PDF, ver ADR-0007) — el módulo va a estar. Lo que este
// experimento mide no es "si existe", son las cuatro cosas concretas de las
// que depende el diseño:
//
//   1. qué versión del import resuelve contra este binario
//   2. si `loops: MediaPlayer.Infinite` realmente reengancha el video, o si
//      hay que reengancharlo a mano con onStopped: play()
//   3. si `volume` y `muted` responden en vivo (son la mitad del transporte)
//   4. si `fillMode: PreserveAspectCrop` recorta como el "object-fit: cover"
//      del diseño, sin deformar ni dejar barras negras
//
// PREDICCIÓN: el import resuelve y los cuatro puntos funcionan. `loops` existe
// en QtMultimedia desde bastante antes de 5.9, así que la versión conservadora
// del import debería alcanzar. Si algo falla, el candidato más probable es (2):
// `loops` es la propiedad con más historia de comportamiento raro entre
// backends de plataforma, y el gabinete es Windows mientras que esto se prueba
// primero en Mac — o sea que este punto hay que correrlo en LAS DOS máquinas
// (ADR-0003), no alcanza con el Mac.
//
// RESULTADO OBSERVADO (Mac):      PARCIAL, 2026-08-03.
//   punto 1 (import 5.9)  ✅ resuelve.
//   punto 3 (transporte)  ✅ play/pausa, mute y volumen responden en vivo.
//   punto 2 (loops)       ❓ sin responder — y la primera medicion estaba
//                            MAL HECHA: contaba onStopped, que un loop
//                            continuo puede no disparar nunca. Reemplazada
//                            por un contador de reenganches que mira si la
//                            posicion retrocede. Falta correrlo de nuevo.
//   punto 4 (crop)        ❓ sin responder.
// RESULTADO OBSERVADO (gabinete): <PENDIENTE>
//
// OJO — esto NO se puede correr contra fixtures/. Los fixtures son de 0 bytes
// a propósito (CLAUDE.md §Reglas de trabajo) y no hay ningún .mp4 real ahí.
//
// EL VIDEO DE PRUEBA YA ESTÁ, en `library/preview/media/dino/video.mp4` —
// gitignored, igual que las carátulas reales y por el mismo criterio. Son 4
// segundos generados con ffmpeg: patrón `testsrc` (que trae un contador de
// cuadros bien visible, así se ve al toque cuando el loop reengancha) más un
// tono de 440 Hz, que es lo que hace audible el control de volumen y de mute.
//
// Se regenera con:
//
//   ffmpeg -y -f lavfi -i "testsrc=size=640x480:rate=30:duration=4" \
//          -f lavfi -i "sine=frequency=440:sample_rate=48000:duration=4" \
//          -c:v libx264 -pix_fmt yuv420p -profile:v baseline -level 3.0 \
//          -c:a aac -b:a 96k -shortest library/preview/media/dino/video.mp4
//
// Es a propósito un video SINTÉTICO y no una captura de gameplay: para lo que
// este experimento mide (¿loopea? ¿responde el volumen? ¿recorta bien?) un
// contador y un tono dicen más que una partida real, y no pesa nada.
//
// Cómo correrlo:
//   1. cp multimedia-loop.qml <themes de Pegasus>/attract-debug/theme.qml
//   2. abrí Pegasus (el video está en la colección Preview, juego "Cadillacs
//      and Dinosaurs")
//   3. flechas para llegar a ese juego; espacio/M/+/- para el transporte
//   4. dejalo llegar al final del video y mirá si vuelve a empezar solo
//   5. anotá arriba los dos resultados (Mac y gabinete)
//
// Se importa 5.9 a proposito: es vieja y conservadora, y ya tiene todo lo que
// el diseño necesita. Si algun dia hace falta algo mas nuevo, es otra pregunta.

import QtQuick 2.0
import QtMultimedia 5.9

FocusScope {
    id: root
    focus: true

    property int idx: 0
    property var g: api.allGames.count > 0 ? api.allGames.get(idx) : null
    property int vueltas: 0        // via onStopped - poco confiable, ver abajo
    property int reenganches: 0    // via posicion que retrocede - el bueno
    property int posAnterior: 0
    property int posMaxVista: 0

    Rectangle { anchors.fill: parent; color: "#0d1117" }

    MediaPlayer {
        id: player
        source: root.g && root.g.assets.video ? root.g.assets.video : ""
        autoPlay: true
        loops: MediaPlayer.Infinite
        volume: 0.6
        muted: true

        // Punto 2, PRIMER intento de medirlo: contar los onStopped.
        //
        // NO ALCANZA, y se vio corriendolo (2026-08-03): un loop continuo
        // puede no pasar NUNCA por StoppedState, asi que este contador se
        // queda en 0 tanto si el loop anda bien como si el video se colgo en
        // el ultimo cuadro. Un contador que no distingue el exito del fracaso
        // no mide nada.
        onStopped: root.vueltas += 1

        // Punto 2, la medicion que SI sirve: si la posicion RETROCEDE de
        // golpe, el video reengancho. Es independiente de por que estados
        // pase el player, y por eso responde la pregunta de verdad.
        onPositionChanged: {
            if (position + 200 < root.posAnterior) root.reenganches += 1;
            root.posAnterior = position;
            if (position > root.posMaxVista) root.posMaxVista = position;
        }
    }

    // Punto 4: el panel del diseno mide 280x288 y el video lo llena recortando.
    Rectangle {
        id: panel
        anchors { top: parent.top; right: parent.right; margins: 40 }
        width: 280; height: 288
        color: "#07080c"
        border { width: 1; color: "#2a2e38" }

        VideoOutput {
            anchors.fill: parent
            anchors.margins: 1
            source: player
            fillMode: VideoOutput.PreserveAspectCrop
        }
    }

    Text {
        anchors { top: parent.top; left: parent.left; margins: 40 }
        width: parent.width - panel.width - 120
        color: "#7ee787"
        font.family: "monospace"
        font.pixelSize: 14
        wrapMode: Text.WordWrap
        textFormat: Text.PlainText
        text: reporte()
    }

    function nombreEstado(s) {
        if (s === MediaPlayer.PlayingState) return "PLAYING";
        if (s === MediaPlayer.PausedState) return "PAUSED";
        if (s === MediaPlayer.StoppedState) return "STOPPED";
        return "?(" + s + ")";
    }

    function nombreStatus(s) {
        if (s === MediaPlayer.NoMedia) return "NoMedia";
        if (s === MediaPlayer.Loading) return "Loading";
        if (s === MediaPlayer.Loaded) return "Loaded";
        if (s === MediaPlayer.Buffering) return "Buffering";
        if (s === MediaPlayer.Buffered) return "Buffered";
        if (s === MediaPlayer.EndOfMedia) return "EndOfMedia";
        if (s === MediaPlayer.InvalidMedia) return "InvalidMedia  <- archivo roto o codec no soportado";
        return "?(" + s + ")";
    }

    // Punto 3: el medidor de 5 barras del diseno. Si `volume` responde en vivo,
    // esto se mueve al tocar + y -.
    function medidor() {
        var llenas = player.muted ? 0 : Math.round(player.volume * 5);
        var s = "";
        for (var i = 0; i < 5; i++) s += (i < llenas ? "#" : ".");
        return "[" + s + "]";
    }

    function reporte() {
        var out = [];
        out.push("=== EXPERIMENTO: QtMultimedia ===");
        out.push("  <- ->  juego     ESPACIO  play/pausa");
        out.push("  + -    volumen   M        mute");
        out.push("");

        if (!root.g) return out.join("\n") + "\nSin juegos.";

        out.push("juego " + (root.idx + 1) + " de " + api.allGames.count + ": " + root.g.title);
        out.push("");

        if (!root.g.assets.video) {
            out.push("ESTE JUEGO NO TIENE VIDEO.");
            out.push("");
            out.push("No es un fallo del experimento: assets.video esta vacio.");
            out.push("Segui con -> hasta encontrar uno que si tenga, o revisa");
            out.push("que estes apuntando a library/ y no a fixtures/ (los");
            out.push("fixtures son de 0 bytes a proposito, no hay mp4 real).");
            return out.join("\n");
        }

        out.push("  source     : " + player.source);
        out.push("");
        out.push("--- 1. el import resolvio (si lees esto, si) ---");
        out.push("");
        out.push("--- 2. loops: MediaPlayer.Infinite ---");
        out.push("  REENGANCHES: " + root.reenganches
                 + "   <- ESTE es el que importa. Sube cuando la posicion");
        out.push("               retrocede, o sea cuando el video vuelve a");
        out.push("               empezar. Espera que llegue al final.");
        out.push("  posicion   : " + player.position + " / " + player.duration + " ms");
        out.push("  pos maxima : " + root.posMaxVista + " ms   (tiene que acercarse a la duracion)");
        out.push("  status     : " + nombreStatus(player.status));
        out.push("  vueltas    : " + root.vueltas
                 + "   (via onStopped; puede quedarse en 0 aunque loopee)");
        out.push("");
        out.push("--- 3. transporte ---");
        out.push("  estado     : " + nombreEstado(player.playbackState));
        out.push("  volume     : " + player.volume.toFixed(2));
        out.push("  muted      : " + player.muted);
        out.push("  medidor    : " + medidor());
        out.push("");
        out.push("--- 4. PreserveAspectCrop ---");
        out.push("  video 640x480 (4:3) en un panel de 280x288 (casi cuadrado).");
        out.push("  Con PreserveAspectCrop tiene que RECORTAR ~52px de cada");
        out.push("  lado. El patron testsrc trae un circulo que toca los bordes");
        out.push("  izquierdo y derecho: si ves el circulo COMPLETO, no esta");
        out.push("  recortando; si le faltan los costados, esta bien.");
        out.push("  Y no tiene que haber franjas negras ni imagen estirada.");

        if (player.errorString) {
            out.push("");
            out.push("!!! ERROR: " + player.errorString);
        }
        return out.join("\n");
    }

    Keys.onPressed: {
        if (event.key === Qt.Key_Right) {
            root.idx = (root.idx + 1) % api.allGames.count;
            root.vueltas = 0;
            event.accepted = true;
        } else if (event.key === Qt.Key_Left) {
            root.idx = (root.idx - 1 + api.allGames.count) % api.allGames.count;
            root.vueltas = 0;
            event.accepted = true;
        } else if (event.key === Qt.Key_Space) {
            if (player.playbackState === MediaPlayer.PlayingState) player.pause();
            else player.play();
            event.accepted = true;
        } else if (event.key === Qt.Key_M) {
            player.muted = !player.muted;
            event.accepted = true;
        } else if (event.key === Qt.Key_Plus || event.key === Qt.Key_Equal) {
            player.volume = Math.min(1.0, player.volume + 0.2);
            player.muted = false;
            event.accepted = true;
        } else if (event.key === Qt.Key_Minus) {
            player.volume = Math.max(0.0, player.volume - 0.2);
            event.accepted = true;
        }
    }
}
