// Perfil fisico del gabinete (themes/attract/core/gabinete.json,
// ADR-0036/0037). Se instancia UNA VEZ en theme.qml (mismo criterio que
// Paths/Teclas: no es singleton a proposito, ver encabezado de theme.qml) y
// baja por propiedad a quien lo necesite (ControlDiagram, GuideOverlay).
//
// A diferencia de GameData/PlatformData esto NO varia por juego ni por
// plataforma: es un solo archivo, versionado junto con el theme, que
// `make theme` instala en las dos maquinas. La lectura es la MISMA tecnica
// que GameData (XMLHttpRequest + tres estados) para no introducir una
// tecnica de QML sin verificar contra Pegasus real; lo unico que cambia es
// que la URL es fija (Qt.resolvedUrl la resuelve relativa a este archivo,
// sin pasar por Paths.qml ni por ningun juego).
//
// Un gabinete.json corrupto o ausente NO rompe el theme: degrada a "sin
// perfil" (jugadores/perifericos/salida vacios), que el resto del theme
// trata igual que "nada verificado, ningun periferico instalado" - la ayuda
// general sigue siendo posible, solo mas generica (mismo costo asumido que
// ADR-0036 ya documenta para un data.json roto).

import QtQuick 2.0

QtObject {
    id: gabinete

    // "cargando" | "listo" | "sin-datos". En la practica "cargando" dura un
    // instante: es un archivo local de pocos KB empaquetado con el theme.
    property string estado: "cargando"
    property var datos: null

    readonly property var jugadores: (datos && Array.isArray(datos.jugadores)) ? datos.jugadores : []
    readonly property var flippers: (datos && datos.flippers) ? datos.flippers : ({ cantidad: 0, instalado: false })
    readonly property var perifericos: (datos && datos.perifericos) ? datos.perifericos : ({})
    readonly property var salida: (datos && datos.salida) ? datos.salida : ({})

    // Si ALGUNA posicion del panel esta medida (Etapa F). Hoy siempre false:
    // el panel esta en transicion y nada se midio todavia. El diagrama de
    // controles usa esto como el unico interruptor entre "mostrar la entrada
    // logica" y "intentar resaltar una posicion fisica" - resolver A CUAL
    // posicion corresponde cada control es trabajo de la Etapa F, que
    // todavia no tiene datos con que operar (docs/como-se-juega.md,
    // "Condicion de exito").
    readonly property bool algunaPosicionMedida: {
        for (var i = 0; i < jugadores.length; i++) {
            var botones = jugadores[i].botones || [];
            for (var j = 0; j < botones.length; j++)
                if (botones[j].medido) return true;
        }
        return false;
    }

    Component.onCompleted: cargar()

    function cargar() {
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            var parseado = null;
            // Con file:// el status llega 0 aunque haya salido bien (mismo
            // criterio que GameData/PlatformData).
            if ((xhr.status === 200 || xhr.status === 0) && xhr.responseText) {
                try {
                    parseado = JSON.parse(xhr.responseText);
                    if (typeof parseado !== "object" || parseado === null) parseado = null;
                } catch (e) {
                    console.log("ATTRACT: gabinete.json invalido - " + e);
                    parseado = null;
                }
            }
            gabinete.datos = parseado;
            gabinete.estado = parseado ? "listo" : "sin-datos";
        };
        xhr.open("GET", Qt.resolvedUrl("gabinete.json"));
        xhr.send();
    }

    // true solo si el perfil declara ESE periferico Y lo marca instalado.
    // Uno que el perfil no menciona cuenta como no instalado, no como
    // desconocido - es el mismo criterio "ausente = false" que el resto del
    // contrato (ADR-0037).
    function perifericoInstalado(nombre) {
        var p = perifericos[nombre];
        return !!(p && p.instalado);
    }

    // La tecla de salida por defecto para "mame" o "dosbox", o "" si el
    // perfil no la trae. Las excepciones de DOSBox (mapperfile propio) las
    // resuelve el artefacto de 027 por juego, no esta funcion.
    function teclaSalida(emulador) {
        var e = salida[emulador];
        if (!e) return "";
        var t = e.tecla || (e.porDefecto ? e.porDefecto.tecla : "");
        return t || "";
    }
}
