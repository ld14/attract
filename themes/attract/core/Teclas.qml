// Traduce un evento de teclado crudo a la intencion del mando: A, B, X, Y y
// una direccion. Nada mas.
//
// ES UN TRADUCTOR, NO UN DESPACHADOR. No sabe que pantalla esta arriba y no
// debe saberlo: el foco lo resuelve el arbol de FocusScopes (ver el
// encabezado de theme.qml). El prototipo tiene un onKey(e) global con un if
// por estado (design_handoff_home/Pegasus Home.dc.html:567-618) y ese es
// exactamente el diseño que aca no se copia.
//
// POR QUE EXISTE, si api.keys ya hace esto: para que el theme escriba
// `teclas.esX(event)` en vez de `api.keys.isDetails(event)`. El nombre del
// boton fisico es lo que el diseño nombra en cada pantalla ("atajo X"), y
// api.keys los llama por su funcion en el menu de Pegasus. Un solo lugar
// traduce entre los dos vocabularios.
//
// MEDIDO CONTRA PEGASUS REAL (themes/experimentos/teclas-xy.qml, 2026-08-05):
// los cuatro predicados existen y ninguno se superpone — cada tecla prende
// exactamente uno. Con el teclado: I=X, F=Y, Enter=A, Esc=B.
//
// LO QUE NO HACE, y es deliberado: no ofrece un `esTexto(event)`. La pantalla
// de Buscar (010) escribe con el teclado fisico, y ahi la regla es preguntar
// SOLO esB y tratar todo lo demas como texto — porque las letras a d q e f i
// estan tomadas por otros predicados y preguntar por ellas se comeria el
// tipeo. Esa regla vive en Buscar, no aca.
//
// No es un singleton por el mismo motivo que Paths: un singleton en
// subcarpeta necesita su propio qmldir y es el mecanismo del que menos se
// sabe contra este binario. Se instancia una vez en theme.qml y baja por
// propiedad.

import QtQuick 2.0

QtObject {
    function esA(event) { return api.keys.isAccept(event); }
    function esB(event) { return api.keys.isCancel(event); }
    function esX(event) { return api.keys.isDetails(event); }
    function esY(event) { return api.keys.isFilters(event); }

    // "izq" | "der" | "arriba" | "abajo" | ""
    //
    // Se compara la tecla y NUNCA los modificadores: en macOS las flechas
    // llegan con KeypadModifier puesto (mod=0x20000000), asi que un
    // `event.modifiers === Qt.NoModifier` no dispararia nunca en el Mac
    // (medido 2026-08-05, docs/plataforma-pegasus.md §3).
    function direccion(event) {
        switch (event.key) {
            case Qt.Key_Left:  return "izq";
            case Qt.Key_Right: return "der";
            case Qt.Key_Up:    return "arriba";
            case Qt.Key_Down:  return "abajo";
        }
        return "";
    }
}
