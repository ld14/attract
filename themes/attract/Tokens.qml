// Tokens de diseno del theme. El equivalente de las variables CSS del
// prototipo: un solo lugar donde viven colores, radios, sombras, espaciado
// y fuentes.
//
// POR QUE EL ARCHIVO SE LLAMA Tokens.qml Y NO Theme.qml, que seria lo obvio:
// Pegasus exige que la entrada del theme sea "theme.qml", y macOS y Windows
// tienen filesystems case-INSENSITIVE. "Theme.qml" y "theme.qml" son EL MISMO
// ARCHIVO ahi: crear uno pisa al otro en silencio. Verificado a lo bruto en
// esta misma maquina (un `echo > theme.qml` borro el contenido de Theme.qml).
// El qmldir permite que el nombre EXPUESTO no sea el del archivo, asi que en
// el codigo se sigue escribiendo Theme.algo — solo cambia como se llama el
// archivo en disco.
//
// Por que esto NO es un chequeo de attract doctor: en un filesystem
// case-insensitive el par colisionante no puede EXISTIR (crear uno pisa al
// otro), asi que no hay nada que detectar en el Mac ni en el gabinete. Solo
// se detectaria en Linux, donde los dos archivos si conviven, y este proyecto
// no tiene ninguna maquina Linux (ADR-0003). Un chequeo que nunca dispara es
// peor que este comentario. Si algun dia entra Linux al circuito, ahi si vale
// agregarlo a CHEQUEOS_UNIVERSALES.
//
// Lo que NO vive aca: el accent. Es un dato POR JUEGO (ADR-0013), asi que
// baja como propiedad desde la pantalla hasta cada atomo. Un componente que
// lo leyera de aca seria un componente que se equivoca en cuanto haya dos
// accents en pantalla a la vez (el rail de la libreria tiene uno por
// tarjeta). Lo unico de accent que vive aca es el neutro de degradacion,
// para el juego que no tiene ninguno cargado.
//
// Todas las medidas son constantes en pixeles, tomadas del diseno tal cual:
// el canvas es fijo de 1280x720 y se escala entero (ADR-0016), asi que los
// clamp() del CSS colapsan a un numero.

pragma Singleton
import QtQuick 2.0

QtObject {
    id: t

    // -----------------------------------------------------------------
    // Lienzo (ADR-0016)
    // -----------------------------------------------------------------
    readonly property int canvasWidth: 1280
    readonly property int canvasHeight: 720
    readonly property int gutter: 48        // margen lateral de todas las pantallas

    // -----------------------------------------------------------------
    // Colores base
    // -----------------------------------------------------------------
    readonly property color screen: "#04050a"       // fondo raiz
    readonly property color panelTop: "#0a0c12"     // gradiente de panel, arriba
    readonly property color panelBottom: "#07080c"  // gradiente de panel, abajo

    readonly property color textPrimary: "#e9ebf2"
    readonly property color textBright: "#ffffff"
    readonly property color textBody: "#b9bdca"     // parrafos
    readonly property color textMuted: "#8a90a0"    // etiquetas
    readonly property color textFaint: "#6a7081"    // lo mas apagado que se usa
    readonly property color textOnAccent: "#07080c" // sobre un fondo de accent

    // Superficies tipo vidrio: relleno y borde. El diseno las usa en un rango
    // (.03-.07 de relleno, .06-.18 de borde); estos son los dos valores que
    // aparecen mas seguido, el resto se arma con alpha().
    readonly property color glassFill: Qt.rgba(1, 1, 1, 0.03)
    readonly property color glassFillHi: Qt.rgba(1, 1, 1, 0.07)
    readonly property color glassBorder: Qt.rgba(1, 1, 1, 0.10)
    readonly property color glassBorderHi: Qt.rgba(1, 1, 1, 0.18)

    // Accent de degradacion: el juego sin accent en su data.json no se rompe,
    // se ve apagado (ADR-0013 + CONVENCION #2.3). No es una rama muerta: se
    // usa de verdad en todo juego que todavia no tiene colores elegidos.
    readonly property color accentNeutro: "#6f7a8d"
    readonly property color accent2Neutro: "#1e232e"

    // -----------------------------------------------------------------
    // Escala de radios y espaciado (handoff #Design Tokens)
    // -----------------------------------------------------------------
    readonly property int radiusChip: 6
    readonly property int radiusButton: 10
    readonly property int radiusCard: 12
    readonly property int radiusPanel: 18

    readonly property int spaceXs: 6
    readonly property int spaceSm: 10
    readonly property int spaceMd: 16
    readonly property int spaceLg: 26
    readonly property int spaceXl: 48

    // -----------------------------------------------------------------
    // Sombras
    // -----------------------------------------------------------------
    // El diseno pide "0 20-40px 60-120px rgba(0,0,0,.5-.65)" bajo los paneles
    // elevados y glows de accent al 40-60%. Aca solo viven los NUMEROS; como
    // se dibujan depende de si QtGraphicalEffects existe en este binario, que
    // es lo que responde themes/experimentos/graphical-effects.qml. Si no
    // existe, los componentes caen a rectangulos translucidos y lo anotan.
    readonly property color shadowSoft: Qt.rgba(0, 0, 0, 0.55)
    readonly property int shadowRadius: 40
    readonly property int shadowOffsetY: 20
    readonly property real glowAlpha: 0.5

    // -----------------------------------------------------------------
    // Tipografia
    // -----------------------------------------------------------------
    // Los .ttf los baja el autor a fonts/ (el gabinete es offline, no se
    // pueden pedir en runtime - ver fonts/README.md). Si faltan, FontLoader
    // deja name vacio y se cae a la fuente del sistema: el theme se ve peor
    // pero carga igual. Nunca se queda sin fuente.
    readonly property FontLoader _display: FontLoader {
        source: Qt.resolvedUrl("fonts/ChakraPetch-Bold.ttf")
    }
    readonly property FontLoader _body: FontLoader {
        source: Qt.resolvedUrl("fonts/Sora-Regular.ttf")
    }
    readonly property FontLoader _mono: FontLoader {
        source: Qt.resolvedUrl("fonts/JetBrainsMono-Regular.ttf")
    }

    readonly property string fontDisplay: _display.name !== "" ? _display.name : "Helvetica"
    readonly property string fontBody: _body.name !== "" ? _body.name : "Helvetica"
    readonly property string fontMono: _mono.name !== "" ? _mono.name : "Courier"

    readonly property bool fuentesPropias:
        _display.name !== "" && _body.name !== "" && _mono.name !== ""

    // Tamanos del diseno. Con el canvas fijo son constantes, no hay clamp().
    readonly property int sizeHero: 104        // titulo del hero en la libreria
    readonly property int sizeTitle: 60        // titulo en el detalle
    readonly property int sizePanelTitle: 30   // titulo sobre el panel de caratula
    readonly property int sizeBody: 16
    readonly property int sizeLabel: 13
    readonly property int sizeMono: 12
    readonly property int sizeMonoSm: 10

    readonly property real trackingWide: 0.18  // "SHINBOX", en em
    readonly property real trackingLabel: 0.16 // etiquetas de seccion

    // -----------------------------------------------------------------
    // Helpers de color
    // -----------------------------------------------------------------

    // Reemplaza color-mix(in srgb, a X%, b) del CSS. t=0 devuelve a, t=1 b.
    function mix(a, b, t) {
        var ca = Qt.darker(a, 1.0);   // normaliza strings tipo "#rrggbb" a color
        var cb = Qt.darker(b, 1.0);
        return Qt.rgba(
            ca.r + (cb.r - ca.r) * t,
            ca.g + (cb.g - ca.g) * t,
            ca.b + (cb.b - ca.b) * t,
            ca.a + (cb.a - ca.a) * t
        );
    }

    // Reemplaza los rgba(...) sueltos del CSS: mismo color, otra opacidad.
    function alpha(c, a) {
        var cc = Qt.darker(c, 1.0);
        return Qt.rgba(cc.r, cc.g, cc.b, a);
    }

    // El accent de un juego, con la degradacion de ADR-0013 aplicada.
    // Un solo lugar decide que pasa cuando data.json no trae color.
    function accentDe(valor) {
        return (typeof valor === "string" && /^#[0-9a-fA-F]{6}$/.test(valor))
            ? valor : accentNeutro;
    }

    function accent2De(valor) {
        return (typeof valor === "string" && /^#[0-9a-fA-F]{6}$/.test(valor))
            ? valor : accent2Neutro;
    }
}
