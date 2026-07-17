# ADR-005 · Runtime de emulación: MAME vanilla

## Estado
**Aceptada** · 2026-07-17

> Esta ADR está **escrita** y sirve de modelo para las otras cuatro.
> Fijate en tres cosas: la justificación se apoya en evidencia verificable,
> las consecuencias negativas están escritas de verdad, y las alternativas
> descartadas explican por qué, no solo qué.

## Contexto

ATTRACT necesita un emulador que cumpla dos funciones distintas:

1. **Runtime** — lanzar los juegos desde Pegasus en el gabinete Windows.
2. **Fuente de identidad** — `-listxml` es lo único que sabe qué sets existen,
   cuál es parent de cuál, qué CHDs necesita cada uno y de qué BIOS depende.
   En un set **merged** esto es obligatorio: el filesystem no alcanza, porque
   un `.zip` contiene una familia entera de juegos, no uno.

El desarrollo ocurre en macOS; la ejecución en Windows.

Candidatos: MAME vanilla, MAMEUI64, Arcade64 (los dos últimos de Robbbert).

## Decisión

**MAME vanilla 0.288**, el mismo binario en macOS y en Windows.

## Justificación

| Criterio | MAME vanilla | Arcade64 |
|---|---|---|
| Corre en macOS (dev) | ✅ SDL; desde 0.286 usa SDL3 por defecto en macOS | ❌ Windows only |
| Corre en Windows (prod) | ✅ | ✅ |
| Cubre el banco de pruebas | ✅ **5 de 5** | ❌ **3 de 5** |
| Versión disponible | ✅ 0.288 — 29 may 2026 | ❓ sin confirmar |
| `-listxml` canónico | ✅ | ❌ fork con cambios propios |

Tres razones, en orden de peso:

**1. Un solo `-listxml`.** Es el punto decisivo. Arcade64 solo corre en Windows,
así que la capa de identificación se construiría contra la salida de MAME vanilla
en el Mac y correría contra la de Arcade64 en el gabinete. **Dos fuentes de verdad
distintas sobre qué juegos existen.** Con merged, donde la identidad *depende* de
`-listxml`, eso es inaceptable.

**2. MAME absorbió MESS.** El sitio oficial lo dice: MAME hoy documenta
computadoras, consolas y calculadoras además de los arcades. Por eso vanilla cubre
Striker (Amiga) y TMNT (NES); Arcade64, que deja solo la porción arcade, no.
El banco de pruebas quedaría cojo.

**3. Arcade64 aporta una GUI que decidimos no usar.** Pegasus se eligió
precisamente porque permite un diseño mucho más custom que la interfaz fija de
MAMEUI/Arcade64. Si la GUI no se va a ver nunca, es lo único que Arcade64 agrega
sobre vanilla — y cuesta la máquina de desarrollo y dos juegos del banco.

### Lo que NO justifica esta decisión

**No es por la migración a Rust.** El anuncio de MAMEdev del 1-abr-2026 sobre
migración a Rust y revisión de código por IA es una **broma de April Fools**; el
propio equipo lo aclara en el post del 7-abr, donde el cambio real que anuncian es
C++17 → C++20. La prueba está en el release: 0.288, que era el primer hito
supuesto de la migración, trae C++20 y clang, cero Rust.

Queda anotado porque casi tomamos esta decisión —correcta— por una razón falsa.

## Consecuencias

### Positivas
- Un solo emulador, un solo `-listxml`, una sola fuente de identidad.
- El pipeline de M5 se construye contra lo mismo que corre en producción.
- Los 5 juegos del banco son ejecutables en las dos máquinas.
- El romset 0.288 (merged) matchea la versión exacta del emulador.

### Negativas
- **Perdemos la UI de configuración por juego de MAMEUI.** Mapear controles y
  ajustar opciones se hace editando `.ini` a mano, y es notablemente más incómodo.
- **Perdemos los arreglos de Robbbert** que no están en vanilla (sonidos agregados
  o mejorados en juegos que MAME deja mudos).
- MAME 0.288 exige Windows 10 actualizado o superior en el gabinete.
- El listado de vanilla incluye miles de máquinas no-arcade que hay que filtrar.

### Qué nos ata
Poco. `launch:` es un campo del artefacto de build (ver ADR-002), no del dato.
Cambiar de runtime es regenerar la metadata con otro target. **Migrar es barato
mientras ADR-002 se sostenga** — si la metadata se escribe a mano, esto se
convierte en una migración cara.

### Mitigación pendiente
Evaluar el híbrido: **configurar con MAMEUI, ejecutar con vanilla**. Los `.ini` y
`.cfg` los lee el core igual. Recuperaría la única ventaja real que perdemos.
No verificado.

## Alternativas descartadas

**Arcade64** — descartada por las tres razones de arriba. La decisiva es que no
corre en macOS: rompe el requisito de una sola fuente de identidad.

**MAMEUI64** — más defendible que Arcade64, porque absorbió MESSUI y sí cubre los
5 juegos. Se descarta igual por Windows-only, que es el problema real.

**Un emulador distinto por plataforma** (vanilla en Mac, Arcade64 en Windows) —
es exactamente el escenario de dos fuentes de verdad que queremos evitar. Sería
elegir el peor de los dos mundos.

## Verificaciones pendientes
- [ ] `mame -listxml` corre en macOS y en Windows con la misma versión
- [ ] La salida de `-listxml` es idéntica en ambas (diff de hashes)
- [ ] Los 5 juegos del banco arrancan en las dos máquinas
- [ ] El híbrido de configuración MAMEUI → vanilla funciona
