// Verificacion de core/InputTokens.js. Se corre a mano:
//
//     node themes/experimentos/verificar-tokens.js
//
// POR QUE NO ESTA EN tests/: ese directorio es de pytest y prueba
// src/attract/, que es Python. Meter una prueba de JavaScript ahi romperia
// `make test` en cualquier maquina sin node instalado, y el proyecto es
// stdlib-only a proposito.
//
// POR QUE EXISTE IGUAL: el tokenizer es la unica pieza del theme que se puede
// verificar sin abrir Pegasus, porque es una funcion pura. Y es justo donde un
// error cuesta ver a ojo — que "PP" salga como dos botones en vez de uno no
// salta en una captura de pantalla. Todo lo demas del theme es layout y se
// verifica mirando; esto no.
//
// Los casos salen de los fixtures reales, no de ejemplos inventados.

var fs = require("fs");
var path = require("path");

// El .qml/.js de QML no es un modulo de node: se lee el archivo, se le saca la
// directiva `.pragma library` (que node no entiende) y se evalua.
var fuente = fs.readFileSync(
    path.join(__dirname, "../attract/core/InputTokens.js"), "utf8");
eval(fuente.replace(/^\s*\.pragma\s+library\s*$/m, ""));

var casos = [
  // --- de fixtures/arcade/media/dino/data.json ---
  ["↓ ↘ → + K", "combo",
   [["direccion","↓"],["direccion","↘"],["direccion","→"],["mas","+"],["arcade","K"]],
   "direcciones, separador y boton de arcade"],

  ["↓ ↙ ← ↓ ↙ ← + PP", "combo",
   [["direccion","↓"],["direccion","↙"],["direccion","←"],
    ["direccion","↓"],["direccion","↙"],["direccion","←"],
    ["mas","+"],["arcade","PP"]],
   "PP es UN boton, no dos"],

  ["acercate y toca P dos veces seguidas", "combo",
   [["texto","acercate y toca"],["arcade","P"],["texto","dos veces seguidas"]],
   "prosa con un boton en el medio - la regla que hace util la gramatica"],

  ["En el test menu: PLAYERS 3", "codigo",
   [["texto","En el test menu: PLAYERS 3"]],
   "prosa pura: nada se convierte en boton por error"],

  ["↑ ↑ ↓ ↓ START", "codigo",
   [["direccion","↑"],["direccion","↑"],["direccion","↓"],["direccion","↓"],
    ["keycap","START"]],
   "keycap con nombre, solo en variante codigo"],

  // --- de library/preview/media/tekken3/data.json ---
  ["→ ↓ ↘ + ✕", "combo",
   [["direccion","→"],["direccion","↓"],["direccion","↘"],["mas","+"],["cara","✕"]],
   "boton de cara"],

  ["← ← + ○ ○ △", "combo",
   [["direccion","←"],["direccion","←"],["mas","+"],
    ["cara","○"],["cara","○"],["cara","△"]],
   "varios botones de cara seguidos"],

  ["L1 + R2", "combo",
   [["gatillo","L1"],["mas","+"],["gatillo","R2"]],
   "gatillos"],

  // --- casos borde ---
  ["", "combo", [], "string vacio"],
  ["   ", "combo", [], "solo espacios"],
  ["+", "combo", [["mas","+"]], "un separador suelto"],
  ["→+P", "combo",
   [["direccion","→"],["mas","+"],["arcade","P"]],
   "el + pegado se separa igual"],
  ["↓K", "combo", [["texto","↓K"]],
   "una flecha pegada a una letra NO es una direccion"],
  ["START", "combo", [["texto","START"]],
   "en variante combo, START es prosa: los keycaps son de los codigos"],
];

var colores = {
  "✕": "#3b6fe0", "○": "#e0454f", "△": "#39b878", "□": "#d65bd6",
  "P": "#e0454f", "K": "#3b6fe0"
};

var fallas = 0;
console.log("");
for (var i = 0; i < casos.length; i++) {
    var entrada = casos[i][0], variante = casos[i][1];
    var esperado = casos[i][2], nombre = casos[i][3];
    var dio = partir(entrada, variante);

    var ok = dio.length === esperado.length;
    if (ok) for (var k = 0; k < dio.length; k++)
        if (dio[k].tipo !== esperado[k][0] || dio[k].valor !== esperado[k][1]) ok = false;

    if (!ok) fallas++;
    console.log((ok ? "  OK    " : "  FALLA ") + nombre);
    if (!ok) {
        console.log("          entrada : " + JSON.stringify(entrada));
        console.log("          esperado: " + JSON.stringify(esperado));
        console.log("          dio     : " + JSON.stringify(
            dio.map(function(t) { return [t.tipo, t.valor]; })));
    }
}

// Los colores de la convencion, aparte: son la parte que hace legible el
// bloque de un vistazo y equivocarlos no rompe nada, solo confunde.
console.log("");
var pares = [["✕","cara"],["○","cara"],["△","cara"],["□","cara"],["P","arcade"],["K","arcade"]];
for (var j = 0; j < pares.length; j++) {
    var s = pares[j][0], tipo = pares[j][1];
    var t = partir(s, "combo")[0];
    var bien = t && t.tipo === tipo && t.color === colores[s];
    if (!bien) fallas++;
    console.log((bien ? "  OK    " : "  FALLA ") + "color de " + s + " = " +
                (t ? t.color : "?") + " (convencion: " + colores[s] + ")");
}

console.log("\n" + (fallas === 0 ? "TODO BIEN" : fallas + " FALLAS") + "\n");
process.exit(fallas === 0 ? 0 : 1);
