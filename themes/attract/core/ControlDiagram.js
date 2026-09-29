// Logica pura del diagrama de controles (ui/ControlDiagram.qml), separada
// para poder probarla con `node --test` sin abrir Pegasus — mismo motivo que
// core/InputTokens.js: es la unica pieza de esta feature donde un error de
// clasificacion no se nota mirando una captura (un boton que deberia decir
// "Sin uso" y en cambio no aparece, o al reves).
//
// Vocabulario de `control` que reconoce, todo P<jugador>_<algo> (spec 027,
// mismos tokens que -listxml/COINDOOR):
//   P1_BUTTON3            -> boton numerado
//   P1_JOYSTICK_UP/DOWN/LEFT/RIGHT -> palanca
//   P1_TRACKBALL_X, P1_DIAL, ...    -> periferico (no se dibuja aca, lo
//                                      resuelve GuideOverlay como requisito)
//
// "SIN USO" vs "ACCION DESCONOCIDA": el primero es un boton que el juego
// declara (via -listxml, `totalBotones`) pero `acciones` no menciona; el
// segundo es una accion cuyo `control` no encaja con ningun boton numerado
// valido para ese rango — dato inconsistente (ej. P1_BUTTON9 en un juego de
// 4 botones), no periferico ni direccion.
//
// FUNCIONES PURAS, sin `.pragma library`: no hay estado compartido que
// proteger (a diferencia de DataCache.js), mismo criterio que Platforms.js
// e InputTokens.js.

var RE_BOTON = /^P(\d+)_BUTTON(\d+)$/;
var RE_DIRECCION = /^P(\d+)_JOYSTICK_(UP|DOWN|LEFT|RIGHT)$/;
var RE_PERIFERICO = /^P\d+_(TRACKBALL|DIAL|PADDLE|LIGHTGUN|PEDAL|AD_STICK)/;

// Cuantos botones declara -listxml para un jugador, del array
// `controlesDeclarados` que arma Correspondencia.qml
// ([{type,player,buttons,ways}, ...]). 0 si no hay dato.
function botonesDeclarados(controlesDeclarados, jugador) {
    jugador = String(jugador || "1");
    for (var i = 0; i < controlesDeclarados.length; i++) {
        var c = controlesDeclarados[i];
        if (c && String(c.player) === jugador && c.type === "joy" && c.buttons)
            return parseInt(c.buttons, 10) || 0;
    }
    return 0;
}

// { numero: accion } de los botones de `jugador` que SI tienen accion
// declarada en `acciones` ([{control, action, color?}, ...]).
function accionesPorBoton(acciones, jugador) {
    jugador = String(jugador || "1");
    var out = {};
    for (var i = 0; i < acciones.length; i++) {
        var m = RE_BOTON.exec(acciones[i].control || "");
        if (m && m[1] === jugador) out[parseInt(m[2], 10)] = acciones[i];
    }
    return out;
}

// [{dir, accion}] de las direcciones de palanca que `acciones` declaro para
// `jugador`. Sin entrada para una direccion no declarada — no se inventa.
function direcciones(acciones, jugador) {
    jugador = String(jugador || "1");
    var out = [];
    for (var i = 0; i < acciones.length; i++) {
        var m = RE_DIRECCION.exec(acciones[i].control || "");
        if (m && m[1] === jugador) out.push({ dir: m[2], accion: acciones[i] });
    }
    return out;
}

// Las acciones de `acciones` cuyo control no es un boton numerado VALIDO
// para `jugador` (dentro de 1..totalBotones), ni direccion, ni periferico.
function desconocidas(acciones, totalBotones, jugador) {
    jugador = String(jugador || "1");
    var out = [];
    for (var i = 0; i < acciones.length; i++) {
        var control = acciones[i].control || "";
        if (RE_DIRECCION.test(control)) continue;
        if (RE_PERIFERICO.test(control)) continue;
        var m = RE_BOTON.exec(control);
        if (!m || m[1] !== jugador) { out.push(acciones[i]); continue; }
        var num = parseInt(m[2], 10);
        if (num < 1 || num > totalBotones) out.push(acciones[i]);
    }
    return out;
}
