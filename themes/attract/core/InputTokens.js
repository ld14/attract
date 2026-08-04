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
var RE_KEYCAP  = /^(START|SELECT|[ABXYZ][12]?)$/i;

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
    var esCodigo = (variante === "codigo");

    // El `+` y la `,` se separan aunque vengan pegados: "→+P" es tres tokens.
    var crudo = texto.replace(/([+,])/g, " $1 ").split(/\s+/);

    var toks = [];
    for (var i = 0; i < crudo.length; i++) {
        var p = crudo[i];
        if (p === "" || p === ",") continue;

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
