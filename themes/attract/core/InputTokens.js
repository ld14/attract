// El tokenizer de secuencias de input: convierte "↓ ↘ → + K" en tokens que
// InputTokenRow dibuja como botones.
//
// FUNCION PURA. No sabe de QML, no sabe de colores de CSS, no dibuja nada.
// Eso NO es purismo: es la unica pieza del theme que se puede verificar sin
// abrir Pegasus, y justamente es donde un error cuesta ver a ojo — que "PP"
// salga como dos botones en vez de uno no salta en una captura de pantalla.
// Ver spec/features/007-theme-trucos/plan.md.
//
// Portado de docs/mockup-referencia.html:670-714, con una diferencia: el
// prototipo mezclaba parseo y estilo en la misma funcion y devolvia strings de
// CSS. Aca devuelve tokens TIPADOS; el estilo lo pone el componente.
//
// LA REGLA QUE HACE UTIL A LA GRAMATICA, y que es facil pasar por alto: lo que
// no encaja en ninguna categoria se devuelve como PROSA. Eso permite mezclar
// notacion y lenguaje natural en la misma linea — "acercate y toca P dos veces
// seguidas" sale como texto con un boton de puño en el medio. Sin esa regla,
// cada truco tendria que ser notacion pura o texto puro.
//
// Y lo que NO hace: adivinar. data.json guarda `input` como string libre
// (ADR-0015), nada obliga a usar esta notacion. Si viene "QCF+P" no se intenta
// deducir que es un cuarto de circulo: se muestra como prosa. Mismo criterio
// con el que `attract ingest` no limpia la basura de region de los titulos.

.pragma library

var FLECHAS = "↑↓←→↖↗↘↙";

// Los colores de los botones de cara NO son elegidos: son la convencion de
// PlayStation, y por eso se reconocen de un vistazo. Cambiarlos romperia lo
// unico que hace legible el bloque sin leerlo.
var CARA = {
    "✕": "#3b6fe0", "×": "#3b6fe0", "⨯": "#3b6fe0",   // cruz, azul
    "○": "#e0454f", "◯": "#e0454f",                   // circulo, rojo
    "△": "#39b878",                                    // triangulo, verde
    "□": "#d65bd6"                                     // cuadrado, magenta
};

var RE_GATILLO = /^[LR][123]$/i;
var RE_ARCADE  = /^[PK]{1,3}$/;

// SIN la bandera `i`, a proposito. Con `/i`, "a" e "y" —la preposicion y la
// conjuncion mas comunes del castellano— coincidian con [ABXYZ] y se
// dibujaban como teclas en medio de una frase: "Golpear [a] los ladrones",
// "[y] pulsar". Bug real visto en Pegasus el 2026-08-09.
//
// El caso legitimo (una tecla escrita en minuscula, "start") se resuelve con
// corchetes: "[start]". Lo explicito le gana a la adivinanza.
var RE_KEYCAP  = /^(START|SELECT|[ABXYZ][12]?)$/;

function _esFlechas(p) {
    if (p.length === 0) return false;
    for (var i = 0; i < p.length; i++)
        if (FLECHAS.indexOf(p.charAt(i)) < 0) return false;
    return true;
}

function _esCara(p) {
    if (p.length === 0) return false;
    for (var i = 0; i < p.length; i++)
        if (!CARA.hasOwnProperty(p.charAt(i))) return false;
    return true;
}

// texto     : la secuencia cruda del data.json
// variante  : "combo"  notacion de lucha (por defecto)
//             "codigo" ademas reconoce START/SELECT/A/B/X/Y/Z como keycaps
//
// devuelve  : [{ tipo, valor, color }]
//             tipo ∈ direccion | cara | gatillo | arcade | keycap | mas | texto
//             color solo viene en `cara` y `arcade`; el resto lo pone el theme
function partir(texto, variante) {
    if (typeof texto !== "string") return [];

    // MARCADO EXPLICITO: lo que va entre corchetes es un boton, lo de afuera
    // es prosa. Siempre. Es la unica forma de escribir una instruccion en
    // castellano sin que la gramatica se coma las palabras: "Golpear a los
    // ladrones" tiene una "a" y una "y" que RE_KEYCAP reconocia como teclas
    // (bug real visto en Pegasus el 2026-08-09, ADR-0020).
    //
    // Sin corchetes se usa la gramatica de siempre, asi que los data.json
    // que ya existen ("↓ ↘ → + P") siguen funcionando sin tocarlos.
    if (texto.indexOf("[") >= 0) return _partirMarcado(texto, variante);

    return _partirLibre(texto, variante);
}

// Cada segmento entre corchetes es UN boton; todo lo de afuera es prosa
// literal, sin pasar por la gramatica.
function _partirMarcado(texto, variante) {
    var toks = [];
    var re = /\[([^\]]*)\]/g;
    var ultimo = 0;
    var m;

    while ((m = re.exec(texto)) !== null) {
        var antes = texto.substring(ultimo, m.index);
        if (antes.trim() !== "") toks.push({ tipo: "texto", valor: antes.trim() });

        var dentro = m[1].trim();
        if (dentro !== "") toks.push(_clasificar(dentro, variante));

        ultimo = m.index + m[0].length;
    }

    var cola = texto.substring(ultimo);
    if (cola.trim() !== "") toks.push({ tipo: "texto", valor: cola.trim() });

    return toks;
}

// Un token marcado con corchetes: se le aplica la misma gramatica para saber
// COMO dibujarlo, pero si no encaja en ninguna categoria igual es un boton
// (keycap), no prosa — el autor ya dijo que lo es al ponerle corchetes.
// Por eso "[C]" sale como tecla aunque C no este en la lista de keycaps.
function _clasificar(p, variante) {
    var t = _partirLibre(p, variante);
    if (t.length === 1 && t[0].tipo !== "texto") return t[0];
    return { tipo: "keycap", valor: p };
}

function _partirLibre(texto, variante) {
    var esCodigo = (variante === "codigo");

    // El `+` se separa aunque venga pegado: "→+P" es tres tokens.
    //
    // La COMA no. Antes se separaba igual que el `+` y despues se descartaba,
    // asi que toda la puntuacion de una instruccion en prosa desaparecia:
    // "pulsa arriba, abajo, izquierda" salia "pulsa arriba abajo izquierda", y
    // "30,000" salia "30 000". Visto con ghost-n-goblins el 2026-08-21. Ningun
    // data.json usa la coma como separador de notacion, asi que no hay nada
    // que ganar separandola — y si algun dia hiciera falta, los corchetes ya
    // resuelven el caso ("[↓],[→]").
    var crudo = texto.replace(/(\+)/g, " $1 ").split(/\s+/);

    var toks = [];
    for (var i = 0; i < crudo.length; i++) {
        var p = crudo[i];
        if (p === "") continue;

        if (p === "+") { toks.push({ tipo: "mas", valor: "+" }); continue; }

        if (_esFlechas(p)) { toks.push({ tipo: "direccion", valor: p }); continue; }

        if (_esCara(p)) {
            // El color lo da el PRIMER simbolo: una tirada como "○○" es el
            // mismo boton dos veces, no dos colores.
            toks.push({ tipo: "cara", valor: p, color: CARA[p.charAt(0)] });
            continue;
        }

        if (RE_GATILLO.test(p)) {
            toks.push({ tipo: "gatillo", valor: p.toUpperCase() });
            continue;
        }

        if (RE_ARCADE.test(p)) {
            // Puño rojo, patada azul. "PP" es UN boton (los dos puños a la
            // vez), no dos tokens: por eso el regex acepta 1 a 3 letras.
            toks.push({
                tipo: "arcade", valor: p,
                color: p.indexOf("P") >= 0 ? "#e0454f" : "#3b6fe0"
            });
            continue;
        }

        if (esCodigo && RE_KEYCAP.test(p)) {
            toks.push({ tipo: "keycap", valor: p.toUpperCase() });
            continue;
        }

        toks.push({ tipo: "texto", valor: p });
    }

    // Las palabras de prosa consecutivas se fusionan. Sin esto,
    // "acercate y toca P" daria tres tokens de texto que el Flow dibujaria
    // con espacios raros entre si, como si cada palabra fuera una ficha.
    var out = [];
    for (var k = 0; k < toks.length; k++) {
        var t = toks[k];
        if (t.tipo === "texto" && out.length && out[out.length - 1].tipo === "texto")
            out[out.length - 1].valor += " " + t.valor;
        else
            out.push({ tipo: t.tipo, valor: t.valor, color: t.color });
    }
    return out;
}

// Cuantas PALABRAS de prosa tolera una entrada antes de dejar de ser "una
// secuencia de mando".
//
// Se cuentan palabras y no caracteres, y eso NO es un detalle: la primera
// version contaba caracteres con tope 24, y "manten [↓] mientras te atacan"
// —una instruccion en prosa— daba exactamente 24 y se dibujaba como tarjeta
// de combo. Medir por largo confunde "una frase" con "una etiqueta larga":
// "ATAQUE ESPECIAL" son 15 caracteres y UNA etiqueta; "mientras te atacan"
// son 18 y TRES palabras de una oracion.
//
// Lo que distingue de verdad a una secuencia es que sus textos son
// ETIQUETAS sueltas (ATAQUE, SALTO, MAGIA), no frases. Tres palabras en
// total es el corte: "← ← + ATAQUE" tiene una, "manten ↓ mientras te
// atacan" tiene cuatro.
var MAX_PALABRAS_SECUENCIA = 3;

// ¿Esta entrada se dibuja como una SECUENCIA de botones (tarjeta con teclas)
// o como una INSTRUCCION en prosa (renglon con ★)?
//
// No es una heuristica sobre el texto crudo: se apoya en el tokenizer, que
// ya sabe distinguir un boton de una palabra. Una entrada es secuencia si
//
//   1. tiene AL MENOS un token que es un boton de verdad, y
//   2. la prosa suelta que la acompaña es corta (conectores como "+",
//      "ATAQUE", "SALTO" — no una oracion).
//
// Existe porque `cheats` acepta grupos con nombre libre (ADR-0020): sin
// esto habria que declarar el estilo por grupo, y el mismo grupo puede
// mezclar un combo con una explicacion larga.
function esSecuencia(texto, variante) {
    var toks = partir(texto, variante);
    var hayBoton = false;
    var palabras = 0;

    for (var i = 0; i < toks.length; i++) {
        if (toks[i].tipo === "texto") {
            var t = toks[i].valor.trim();
            if (t !== "") palabras += t.split(/\s+/).length;
        } else if (toks[i].tipo !== "mas") {
            hayBoton = true;
        }
    }

    return hayBoton && palabras <= MAX_PALABRAS_SECUENCIA;
}
