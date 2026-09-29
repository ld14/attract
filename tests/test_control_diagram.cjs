// Ejecutar: node tests/test_control_diagram.cjs (sin dependencias). Feature 028.
//
// Logica pura de ui/ControlDiagram.qml, extraida a core/ControlDiagram.js
// justamente para poder probarla aca — mismo motivo que InputTokens.js
// (spec/features/007-theme-trucos/plan.md): es donde un error de
// clasificacion no se nota mirando una captura.
const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

function load(file) {
    const ctx = vm.createContext({});
    vm.runInContext(fs.readFileSync(path.join(__dirname,
        '../themes/attract/core', file), 'utf8'), ctx);
    return ctx;
}

const D = load('ControlDiagram.js');

function accion(control, action, color) {
    return {control, action, color: color || ''};
}

// --- botonesDeclarados -----------------------------------------------------

test('botonesDeclarados: seis botones del jugador 1 (SFA2)', () => {
    const declarados = [
        {type: 'joy', player: '1', buttons: '6', ways: '8'},
        {type: 'joy', player: '2', buttons: '6', ways: '8'},
    ];
    assert.equal(D.botonesDeclarados(declarados, '1'), 6);
});

test('botonesDeclarados: cero cuando el jugador es solo joystick (Pacman)', () => {
    const declarados = [
        {type: 'joy', player: '1', buttons: null, ways: '4'},
        {type: 'joy', player: '2', buttons: null, ways: '4'},
    ];
    assert.equal(D.botonesDeclarados(declarados, '1'), 0);
});

test('botonesDeclarados: cero sin ningun control declarado', () => {
    assert.equal(D.botonesDeclarados([], '1'), 0);
});

test('botonesDeclarados: no confunde trackball con boton', () => {
    // Shuffleshot: type "trackball", no "joy" - no tiene "botones" en este sentido.
    const declarados = [{type: 'trackball', player: '1', buttons: '2'}];
    assert.equal(D.botonesDeclarados(declarados, '1'), 0);
});

// --- accionesPorBoton --------------------------------------------------------

test('accionesPorBoton: mapea cada boton numerado a su accion', () => {
    const acciones = [
        accion('P1_BUTTON1', 'Jab Punch', 'Blue'),
        accion('P1_BUTTON3', 'Fierce Punch', 'Red'),
    ];
    const out = D.accionesPorBoton(acciones, '1');
    assert.equal(out[1].action, 'Jab Punch');
    assert.equal(out[3].action, 'Fierce Punch');
    assert.equal(out[2], undefined);
});

test('accionesPorBoton: ignora acciones de otro jugador', () => {
    // deepEqual contra {} literal: un objeto armado DENTRO del contexto vm
    // tiene otro prototipo que un objeto del contexto host, y el modo
    // strict de assert los rechaza aunque esten vacios los dos por igual
    // (mismo motivo que el comentario de "plain" en test_platforms.cjs,
    // pero para objetos en vez de arrays) - se compara por claves.
    const acciones = [accion('P2_BUTTON1', 'Jab Punch')];
    assert.equal(Object.keys(D.accionesPorBoton(acciones, '1')).length, 0);
});

test('accionesPorBoton: ignora direcciones y perifericos', () => {
    const acciones = [accion('P1_JOYSTICK_UP', 'Saltar'), accion('P1_TRACKBALL_X', 'Mover')];
    assert.equal(Object.keys(D.accionesPorBoton(acciones, '1')).length, 0);
});

// --- direcciones -------------------------------------------------------------

test('direcciones: solo las declaradas, en el orden que vinieron', () => {
    const acciones = [
        accion('P1_JOYSTICK_UP', 'Saltar'),
        accion('P1_JOYSTICK_DOWN', 'Agacharse'),
    ];
    const out = D.direcciones(acciones, '1');
    assert.equal(out.length, 2);
    assert.equal(out[0].dir, 'UP');
    assert.equal(out[0].accion.action, 'Saltar');
    assert.equal(out[1].dir, 'DOWN');
});

test('direcciones: vacio si la guia no declaro ninguna', () => {
    // .length y no deepEqual([]): un array armado dentro del contexto vm
    // tiene otro prototipo (mismo motivo que "plain" en test_platforms.cjs).
    assert.equal(D.direcciones([accion('P1_BUTTON1', 'Golpe')], '1').length, 0);
});

// --- desconocidas: el criterio de aceptacion "sin uso" vs "accion desconocida" ---

test('desconocidas: vacio cuando todo boton declarado esta dentro de rango', () => {
    const acciones = [accion('P1_BUTTON1', 'Golpe'), accion('P1_BUTTON2', 'Patada')];
    assert.equal(D.desconocidas(acciones, 4, '1').length, 0);
});

test('desconocidas: un boton fuera del rango declarado es inconsistente', () => {
    // El caso citado en el comentario del componente: P1_BUTTON9 en un juego
    // de 4 botones.
    const acciones = [accion('P1_BUTTON9', 'Especial')];
    const out = D.desconocidas(acciones, 4, '1');
    assert.equal(out.length, 1);
    assert.equal(out[0].control, 'P1_BUTTON9');
});

test('desconocidas: boton 0 tambien es invalido (los botones empiezan en 1)', () => {
    const out = D.desconocidas([accion('P1_BUTTON0', 'Algo')], 4, '1');
    assert.equal(out.length, 1);
});

test('desconocidas: NO marca una direccion de palanca como desconocida', () => {
    assert.equal(D.desconocidas([accion('P1_JOYSTICK_UP', 'Saltar')], 0, '1').length, 0);
});

test('desconocidas: NO marca un periferico (trackball/dial/...) como desconocida', () => {
    const acciones = [
        accion('P1_TRACKBALL_X', 'Izquierda'),
        accion('P1_TRACKBALL_X_EXT', 'Derecha'),
        accion('P1_DIAL', 'Girar'),
        accion('P1_LIGHTGUN_X', 'Apuntar'),
    ];
    assert.equal(D.desconocidas(acciones, 0, '1').length, 0);
});

test('desconocidas: un control de otro jugador es desconocida en este diagrama', () => {
    // El panel de hoy solo tiene el jugador 1 instalado (gabinete.json): una
    // accion de P2 no se puede clasificar contra el rango de botones de P1.
    const out = D.desconocidas([accion('P2_BUTTON1', 'Golpe P2')], 6, '1');
    assert.equal(out.length, 1);
});

test('desconocidas: un control que no matchea ningun patron conocido', () => {
    const out = D.desconocidas([accion('ALGO_RARO', 'Misterio')], 4, '1');
    assert.equal(out.length, 1);
    assert.equal(out[0].control, 'ALGO_RARO');
});

// --- caso real completo: Street Fighter Alpha 2 (piloto/sfa2.md) -----------

test('caso real: SFA2 completo no deja nada sin uso ni desconocido', () => {
    const declarados = [{type: 'joy', player: '1', buttons: '6', ways: '8'}];
    const acciones = [
        accion('P1_BUTTON1', 'Jab Punch', 'Blue'),
        accion('P1_BUTTON2', 'Strong Punch', 'Yellow'),
        accion('P1_BUTTON3', 'Fierce Punch', 'Red'),
        accion('P1_BUTTON4', 'Short Kick', 'Blue'),
        accion('P1_BUTTON5', 'Strong Kick', 'Yellow'),
        accion('P1_BUTTON6', 'Roundhouse Kick', 'Red'),
        accion('P1_JOYSTICK_UP', 'Jump'),
        accion('P1_JOYSTICK_DOWN', 'Crouch'),
    ];
    const total = D.botonesDeclarados(declarados, '1');
    const porBoton = D.accionesPorBoton(acciones, '1');
    assert.equal(total, 6);
    assert.equal(Object.keys(porBoton).length, 6);
    assert.equal(D.desconocidas(acciones, total, '1').length, 0);
    assert.equal(D.direcciones(acciones, '1').length, 2);
});

// --- caso real: Pacman, sin botones -> todo lo que llegue es sin uso/desconocido ---

test('caso real: Pacman sin botones, cualquier accion de boton queda desconocida', () => {
    const declarados = [{type: 'joy', player: '1', buttons: null, ways: '4'}];
    const total = D.botonesDeclarados(declarados, '1');
    assert.equal(total, 0);
    const out = D.desconocidas([accion('P1_BUTTON1', 'Inventado')], total, '1');
    assert.equal(out.length, 1);
});
