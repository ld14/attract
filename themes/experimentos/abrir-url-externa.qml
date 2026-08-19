// EXPERIMENTO — ¿este binario de Pegasus puede entregarle un PDF al sistema
// operativo para que lo abra la app predeterminada del usuario?
//
// Contexto: ADR-0007 cerró que Pegasus NO puede RENDERIZAR un PDF adentro del
// theme (contraprueba en pdf-qtquick.qml: `import QtQuick.Pdf` ni deja cargar
// el theme). Eso sigue siendo cierto y no se está reabriendo acá. La pregunta
// de este experimento es la otra mitad, que nunca se hizo: en vez de dibujar el
// PDF, PASÁRSELO AL SO. Si eso funciona, un manual escaneado puede abrirse en
// Preview / Acrobat / Edge sin que el theme sepa nada de PDF.
//
// El mecanismo candidato es `Qt.openUrlExternally(url)`. Se eligió por encima
// de QProcess, Qt.labs.platform y QtQuick.Dialogs por una razón concreta: es
// parte del objeto global `Qt` de QtQml y NO NECESITA NINGÚN `import`. Los
// otros tres sí, y en este binario un import que no resuelve no degrada — mata
// el theme entero (docs/plataforma-pegasus.md §1). O sea: este experimento no
// puede romper nada, y los otros tres sí.
//
// PREDICCIÓN: existe y funciona. Por debajo es QDesktopServices::openUrl, que
// en Windows llama ShellExecuteW y en macOS LSOpenCFURLRef — exactamente la
// semántica "abrí esto con lo que el usuario tenga asociado". Pegasus es una
// app Qt Quick, así que enlaza QtGui, que es donde vive QDesktopServices.
//
// PERO LA DOCUMENTACIÓN DE QT NO ES EVIDENCIA EN ESTE PROYECTO, y ya falló en
// las dos direcciones: game.extra "es un string" según la doc y es una lista
// (ADR-0001); QtGraphicalEffects no está declarado en el build y sin embargo
// existe (docs/plataforma-pegasus.md §1). Por eso se mide.
//
// LO QUE HAY QUE MEDIR, y por qué no alcanza con "¿existe la función?":
//
//   1. Que la función exista (typeof, sin ReferenceError).
//   2. Que ABRA DE VERDAD. Una función que existe, devuelve true y no abre
//      nada es el peor resultado posible: se descubriría en el gabinete. El
//      valor de retorno NO alcanza como prueba — hace falta mirar la pantalla.
//   3. Qué devuelve con una ruta que no existe. Es el único canal de error que
//      vamos a tener para avisarle al usuario; si devuelve true igual, no hay
//      UX de error posible y hay que decirlo en el ADR.
//   4. Espacios y acentos. `Paths.conEsquema()` concatena strings sin
//      percent-encoding: para XMLHttpRequest e Image viene funcionando, pero un
//      nombre con espacios entregado a un shell es el caso clásico de falla.
//      Se prueba CRUDO y CODIFICADO para saber cuál de los dos hay que usar.
//   5. Si el visor aparece DELANTE de Pegasus. El gabinete corre fullscreen; un
//      PDF que abre atrás es indistinguible de un PDF que no abrió.
//   6. Que Pegasus siga vivo después, y que cerrar el visor no lo cierre.
//
// SI ESTO FALLA: la feature 012 no se hace. Se archiva este resultado, se
// escribe el ADR que documenta el "no se puede" (mismo destino que ADR-0007) y
// los manuales siguen siendo páginas-imagen. Esa rama es un resultado válido.
//
// Cómo se corre:
//   1. cp themes/experimentos/abrir-url-externa.qml "$PEGASUS_THEMES/attract-debug/theme.qml"
//   2. cp themes/experimentos/prueba.pdf "$PEGASUS_THEMES/attract-debug/"
//   3. cd "$PEGASUS_THEMES/attract-debug/" && cp prueba.pdf "prueba con acción.pdf"
//   4. abrir Pegasus, elegir ATTRACT Debug, y apretar 1..5
//   5. repetir TODO en el gabinete Windows — es la máquina de producción y
//      ShellExecuteW es un camino distinto de LSOpenCFURLRef (ADR-0003)
//
// Las rutas se resuelven con Qt.resolvedUrl() contra la ubicación del propio
// theme. NO hay ninguna ruta absoluta acá: esa es justamente la deuda que
// pdf-qtquick.qml dejó anotada y que rompe en el gabinete (ADR-0003).
//
// NO vive en themes/attract-debug/ a propósito: ese theme es la evidencia viva
// de ADR-0001 y no se pisa.

import QtQuick 2.0

FocusScope {
    id: root
    focus: true
    anchors.fill: parent

    property var lineas: []

    Rectangle { anchors.fill: parent; color: "#0d1117" }

    Text {
        anchors { fill: parent; margins: 36 }
        color: "#7ee787"
        font.family: "monospace"
        font.pixelSize: 13
        wrapMode: Text.WordWrap
        textFormat: Text.PlainText
        text: cabecera() + "\n" + root.lineas.join("\n")
    }

    // --- lo que se mide ---------------------------------------------------

    // typeof sobre una propiedad ausente da "undefined" sin tirar; sobre una
    // funcion de Qt da "function". No hace falta try/catch. Mismo truco que
    // teclas-xy.qml usa para los predicados de api.keys.
    readonly property bool existe: typeof Qt.openUrlExternally === "function"

    // El directorio de ESTE archivo, ya con esquema file:// y barra final.
    // Qt.resolvedUrl es lo que hace que el experimento no tenga rutas del Mac
    // del autor adentro.
    readonly property string dir: String(Qt.resolvedUrl("."))

    // Los cinco casos. `nota` es lo que hay que MIRAR, no lo que se lee en
    // pantalla: el valor de retorno solo cuenta la mitad de la historia.
    readonly property var casos: [
        {
            tecla: "1",
            titulo: "PDF simple",
            url: root.dir + "prueba.pdf",
            nota: "esperado: abre el visor por defecto del sistema"
        },
        {
            tecla: "2",
            titulo: "ruta inexistente",
            url: root.dir + "no-existe-este-archivo.pdf",
            nota: "esperado: false (si da true, no hay UX de error posible)"
        },
        {
            tecla: "3",
            titulo: "espacios + acento, CRUDO",
            url: root.dir + "prueba con acción.pdf",
            nota: "sin encodeURIComponent — el camino que usa hoy conEsquema()"
        },
        {
            tecla: "4",
            titulo: "espacios + acento, CODIFICADO",
            url: root.dir + encodeURIComponent("prueba con acción.pdf"),
            nota: "con encodeURIComponent solo en el nombre, no en el directorio"
        },
        {
            tecla: "5",
            titulo: "url vacia",
            url: "",
            nota: "el guardia trivial: no deberia abrir nada ni romper"
        }
    ]

    function cabecera() {
        var out = [];
        out.push("=== EXPERIMENTO Qt.openUrlExternally ===");
        out.push("");
        out.push("  Qt.openUrlExternally existe : " + (root.existe ? "SI" : "NO"));
        out.push("  dir del theme               : " + root.dir);
        out.push("");
        if (!root.existe) {
            out.push("  >>> NO EXISTE. La feature 012 no se puede hacer por");
            out.push("      esta via. Anotar el resultado y cerrar el ADR.");
            out.push("");
        }
        for (var i = 0; i < root.casos.length; i++) {
            var c = root.casos[i];
            out.push("  [" + c.tecla + "] " + c.titulo);
            out.push("      " + c.nota);
        }
        out.push("");
        out.push("  OJO: el valor de retorno NO es la medicion. Despues de");
        out.push("  cada tecla hay que MIRAR LA PANTALLA y anotar si el visor");
        out.push("  aparecio ADELANTE de Pegasus, atras, o no aparecio.");
        out.push("");
        out.push("--- resultados ---");
        return out.join("\n");
    }

    function probar(i) {
        var c = root.casos[i];
        var r;

        if (!root.existe) {
            r = "(la funcion no existe)";
        } else {
            // Si algo tira, queremos el mensaje en pantalla y no un theme
            // muerto: este archivo tiene que sobrevivir a su propio fallo para
            // poder reportarlo.
            try {
                r = String(Qt.openUrlExternally(c.url));
            } catch (e) {
                r = "EXCEPCION: " + e;
            }
        }

        var nuevas = root.lineas.slice();
        nuevas.push("  [" + c.tecla + "] " + c.titulo + "  ->  " + r);
        nuevas.push("      " + c.url);
        root.lineas = nuevas;
    }

    Keys.onPressed: {
        // Digitos: las letras a d q e f i estan tomadas por los predicados de
        // api.keys y no son teclas libres (teclas-xy.qml #RESULTADO OBSERVADO).
        var i = event.key - Qt.Key_1;
        if (i >= 0 && i < root.casos.length) {
            probar(i);
            event.accepted = true;
        }
    }
}

// #RESULTADO OBSERVADO (2026-08-09, Pegasus alpha16-82-gc3462e68, macOS)
//
// FUNCIONA. `Qt.openUrlExternally` existe en este binario y abre de verdad.
// Los cinco casos dieron exactamente lo predicho:
//
//   caso                            retorno   que se vio en pantalla
//   ------------------------------  --------  ----------------------------
//   [1] PDF simple                  true      abre el visor por defecto
//   [2] ruta inexistente            false     no abre nada
//   [3] espacios + acento, CRUDO    true      abre
//   [4] espacios + acento, CODIF.   true      abre
//   [5] url vacia                   false     no abre nada, no rompe
//
// EL HALLAZGO QUE VALIA LA CORRIDA: [2] devuelve FALSE. O sea que SI hay un
// canal de error: cuando el SO rechaza el pedido se puede avisar. Era el
// resultado que decidia si la UX de error del plan era real o decorativa.
// Es real. (Sigue sin haber senal de que el visor haya ARRANCADO — [1] da
// true porque el SO acepto, no porque el PDF se haya abierto. Ese limite es
// el mismo que game.launch() y no lo arregla nadie.)
//
// [3] Y [4] LOS DOS ABREN EN macOS. LSOpenCFURLRef tolera espacios y UTF-8
// sin codificar en un file://. NO ALCANZA PARA DECIDIR: Windows va por
// ShellExecuteW, que es otro camino (ADR-0003), y la forma canonica de un
// file:// URL es la codificada. Se usa encodeURIComponent — no porque este
// medido que haga falta, sino porque es la unica de las dos que es correcta
// por definicion, y la corrida de Windows todavia no existe. Si en Windows
// resulta que la codificada falla y la cruda anda, hay que volver aca.
//
// EL PROBLEMA REAL, Y NO ES EL QUE SE BUSCABA:
//
//   Con Pegasus en FULLSCREEN, el visor abre en una VENTANA EXTERNA POR
//   DELANTE y PEGASUS PIERDE EL FOCO.
//
// La mitad buena era la que se temia: NO abre detras, o sea que el usuario ve
// que algo paso. La mitad mala es nueva y no estaba en la lista de riesgos:
// el foco se va y el theme no tiene ninguna API para recuperarlo — no existe
// nada equivalente a "traeme al frente" en la superficie de Pegasus
// (docs/plataforma-pegasus.md: la API es allGames, keys, memory y
// game.launch(), nada mas).
//
// En el Mac no molesta: hay cmd-tab. EN EL GABINETE NO HAY TECLADO, hay un
// joystick — y un joystick no cambia de ventana. Ver la discusion en
// spec/decisions/0021-manual-pdf-app-del-sistema.md; es lo unico que quedo
// abierto de esta feature.
//
// PENDIENTE: la corrida en el gabinete Windows. Falta medir si ShellExecuteW
// se comporta igual en los cinco casos, si [4] anda, y como se comporta el
// foco con Pegasus fullscreen ahi.
