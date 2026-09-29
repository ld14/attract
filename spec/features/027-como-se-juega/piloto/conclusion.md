# Conclusión del piloto de datos (Etapa B)

**Fecha:** 2026-09-28. **Muestra:** los 6 expedientes de esta carpeta
(`sfa2.md`, `pacman.md`, `the-simpsons.md`, `shufshot.md`, `prehistorik.md`,
`oh-no-more-lemmings.md`) y su `matriz.md`.

Esta es la salida que pide `docs/como-se-juega.md` §4.B, y la que el autor
tiene que leer antes de pasar a la Etapa C (la pausa está anotada ahí mismo).

## 1 · Qué fuentes integrar

| Fuente | Integrar? | Por qué |
|---|---|---|
| `mame.exe -listxml` | **Sí, como autoridad de capa 2** | Es gratis (ya está en la máquina), determinista, y fue la fuente que detectó los dos errores de esta muestra. Sin ella, Pacman habría salido con un botón inventado. |
| `cabinet.button_list` de COINDOOR (ArcadeDB) | **Sí, para capas 1+2 combinadas** | En los 3 arcades que lo traían poblado (SFA2, Simpsons, Shuffleshot) los datos fueron consistentes con `-listxml` y con el `genre`. El campo en sí es confiable — el problema estuvo en otro campo (`summary`), no en `cabinet`. |
| `dosbox.conf` generado por ATTRACT | **Sí, ya se usa** | Es la única fuente de capa 2 para DOS y ya existe (`dosbox.py`). No hace falta nada nuevo para leerlo. |
| Perfil declarado del gabinete (§3.2 del plan) | **Sí, ya alcanza para un caso real** | Sin medir nada físico, el perfil declarado bastó para marcar Shuffleshot como "requiere trackball, ausente" — el criterio de aceptación más delicado de la spec ya es alcanzable con datos que existen hoy. |
| `summary`/sinopsis de COINDOOR | **Con revisión, no tal cual** | 2 de 6 juegos (33%) tenían errores de fondo: uno afirmaba un control que no existe, el otro describía un juego distinto. Es una tasa alta para pasar directo a un texto que la guía va a mostrar como si fuera un hecho verificado. |
| `.cfg` por juego (`simpsons.cfg`) | **Sí, para la huella de capa 3** | Se pudo leer y parsear sin sorpresas (`<port>/<newseq>`, tal como preveía el plan). Confirma que el diseño de huella de ADR-0036 es viable. |

## 2 · Qué se automatiza

1. **Cruce `-listxml` × `cabinet.button_list`** antes de mostrar controles:
   si el conteo de botones no coincide, o si `-listxml` no declara el tipo de
   control que `cabinet` sugiere, marcar el grupo como "en conflicto" en vez
   de mostrarlo. Esto es exactamente lo que hubiera atajado a Pacman
   automáticamente.
2. **Detección de periférico ausente**, comparando el `type` de `<control>`
   en `-listxml` (`joy`, `trackball`, `dial`, `lightgun`, `mouse`...) contra
   una lista fija de los tipos que el perfil del gabinete declara tener. Es
   una tabla chica y estática — el caso Shuffleshot se resolvió así, a mano,
   en minutos.
3. **Lectura de `.cfg` por sistema** (`default.cfg`, `ctrlr/`, por-juego) para
   calcular la huella de capa 3 — el plan ya lo preveía (§4.D) y este piloto
   no encontró nada que lo contradiga.
4. **Lo que NO se pudo automatizar en este piloto:** ningún equivalente a
   `-listxml` para DOS. El mapeo de teclas de Prehistorik quedó "pendiente"
   porque no hay una fuente estructurada — solo el manual original o
   probarlo a mano. Para DOS, la capa 1 (qué hace el jugador) va a depender
   de trabajo documentado/manual de forma indefinida con las fuentes de hoy.

## 3 · Qué tiene que aportar COINDOOR

Ajustando el borrador de la spec (§5) con lo que mostró el piloto:

1. **Cablear `cabinet` al contrato de export.** Hoy se recolecta y se
   descarta (`backend/bundle/seleccion.py::_tabla()` no lo incluye,
   confirmado en A5) — es la brecha más barata de cerrar, porque el dato ya
   existe.
2. **Revisar las dos sinopsis rotas de esta muestra** (Pacman, Shuffleshot)
   antes de que se usen como fuente de la guía real, y considerar una
   validación de sanidad propia en su pipeline (algo tan simple como "el
   `summary` no debería contradecir `cabinet.buttons == 0`" ya hubiera
   atajado uno de los dos casos).
3. **Resolver el choque con `ADR-0002`** (procedencia interna, no viaja al
   export) contra lo que pide `docs/como-se-juega.md` §5 ("llevar la
   procedencia de cada grupo hasta el paquete") — sigue sin resolverse,
   anotado ya en §3.4 del plan.
4. **Sumar lo que hoy no existe en ningún campo:** primeros pasos, reglas
   esenciales, cómo salir (a nivel "acción del jugador", no solo la tecla del
   emulador), y una señal explícita de cooperativo-vs-versus — ni `-listxml`
   ni `cabinet` lo distinguen de forma confiable (se tuvo que asumir por
   género en más de un expediente de este piloto).

## 4 · Qué hace ATTRACT

1. **`doctor`**: valida el bloque de guía dentro de `chk_data_contrato`
   (mismo patrón que `cheats`/`gallery`), avisa por claves de primer nivel
   desconocidas — sin cambios respecto de lo que ya preveía el plan.
2. **Un comando nuevo** (forma similar a `mags`, dry-run por defecto) que:
   - lea `-listxml` de cada juego arcade instalado, saliendo del `launch:`
     real y no de una ruta fija;
   - cruce ese resultado contra el bloque de guía que traiga el paquete de
     COINDOOR;
   - marque periféricos no soportados comparando contra el perfil del
     gabinete;
   - calcule la huella de capa 3 leyendo `default.cfg` + `ctrlr/` +
     `cfg/<sistema>.cfg`, y para DOS las tres capas de config (primaria, del
     juego, `mapperfile`).
3. **El perfil físico del gabinete**: el piloto confirma que el perfil
   *declarado* (§3.2, sin medir nada) ya es suficiente para el caso de
   periférico ausente. La ruta exacta del perfil y del artefacto generado
   siguen siendo una de las tres preguntas abiertas de la Etapa C — este
   piloto no las resuelve, las deja igual de abiertas.

## 5 · Resumen en una frase

La cadena automática **MAME `-listxml` + `cabinet` de COINDOOR** funciona
bien para arcade y ya detecta datos rotos con solo cruzarlos entre sí; el
punto débil real es el **texto libre generado** (`summary`), que necesita
revisión editorial y no puede tratarse como verificado solo por venir de
COINDOOR; y el lado **DOS no tiene ninguna fuente automática de capa 1**
— ahí el trabajo documentado/manual no es un defecto temporal, es la
situación real con las fuentes que existen hoy.

---

**Pausa (§4 del plan):** esto es lo que el autor tiene que leer antes de
pasar a la Etapa C. Las tres preguntas abiertas de esa etapa (partir la
feature en 027/028, rutas del perfil y del artefacto, qué se restaura al
volver de un juego) siguen sin decisión — este documento no las contesta.
