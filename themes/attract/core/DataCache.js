// Cache de los data.json ya leidos, COMPARTIDO entre todas las instancias de
// GameData.
//
// `.pragma library` es lo que lo hace compartido: sin eso, cada archivo .js
// importado se instancia por componente y el cache seria uno por tarjeta, que
// es exactamente lo que no sirve.
//
// Por que hace falta: el rail de la libreria le da a CADA tarjeta su propio
// accent, que sale de su data.json (ADR-0013). Con un ListView solo existen
// las tarjetas visibles, pero al scrollear los delegates se DESTRUYEN y se
// recrean — un cache por instancia se pierde en cada pasada y la misma
// lectura se repite cada vez que una tarjeta vuelve a entrar en pantalla.
//
// La clave es la url completa del data.json, no el <set>: dos colecciones
// distintas pueden tener el mismo set (pasa de verdad — fixtures/arcade y
// library/preview tienen las dos un "mok") y son archivos distintos.
//
// Un valor null es un resultado valido y cacheable: significa "ya se pidio y
// no hay data.json". Por eso se pregunta con tiene() y no con un truthy.

.pragma library

var _datos = {};

function tiene(url) {
    return _datos.hasOwnProperty(url);
}

function leer(url) {
    return _datos[url];
}

function guardar(url, valor) {
    _datos[url] = valor;
}

// ponytail: sin limite de tamano. Son objetos JSON chicos y una libreria de
// mil juegos son unos pocos MB. Si algun dia molesta, aca va un LRU.
function limpiar() {
    _datos = {};
}
