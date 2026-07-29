---
id: 0005
title: "Runtime de emulación: MAME vanilla"
status: accepted
date: 2026-07-17
supersedes: null
superseded-by: null
tags: [infra]
---

# 0005 — Runtime de emulación: MAME vanilla

## Contexto

ATTRACT necesita un emulador que cumpla dos funciones distintas:

1. **Runtime** — lanzar los juegos desde Pegasus en el gabinete Windows.
2. **Fuente de identidad** — `-listxml` es lo único que sabe qué sets existen,
   cuál es parent de cuál, qué CHDs necesita cada uno y de qué BIOS depende.
   En un set **merged** esto es obligatorio: el filesystem no alcanza, porque
   un `.zip` contiene una familia entera de juegos, no uno.

El desarrollo ocurre en macOS; la ejecución en Windows.

Candidatos: MAME vanilla, MAMEUI64, Arcade64 (los dos últimos de Robbbert).

**Hecho técnico sobre compatibilidad de versiones:** MAME es retrocompatible
hacia atrás, pero NO hacia adelante. Un emulador de versión N corre romsets de
versión N o anteriores; NO puede correr romsets de una versión posterior. Cada
set de ROMs está atado a una versión, y un emulador más nuevo que el set sigue
funcionando, pero uno más viejo que el set, no.

## Decisión

**MAME vanilla, versión 0.288 o superior**, con una regla inquebrantable:

> El Mac (desarrollo) y el gabinete (producción) corren **exactamente la misma
> versión** de MAME, y esa versión es **igual o superior** a la del romset
> (0.288).

No es solo "0.288 o superior" a secas: es "la misma versión en ambas
máquinas, nunca inferior al romset". La igualdad entre máquinas es lo que
protege la fuente de identidad; el piso 0.288 es lo que garantiza que el
romset cargue.

**Criterio rector, en orden de peso:**

1. **Un solo `-listxml`.** Es el punto decisivo. Arcade64 solo corre en
   Windows, así que la capa de identificación se construiría contra la salida
   de MAME vanilla en el Mac y correría contra la de Arcade64 en el gabinete:
   dos fuentes de verdad distintas sobre qué juegos existen. Con merged, donde
   la identidad *depende* de `-listxml`, eso es inaceptable. Esta misma razón
   fuerza la regla de "misma versión en ambas máquinas": dos versiones
   distintas de MAME vanilla también producen dos `-listxml` potencialmente
   distintos.
2. **MAME absorbió MESS.** El sitio oficial documenta computadoras, consolas y
   calculadoras además de arcades. Por eso vanilla cubre Striker (Amiga) y
   TMNT (NES); Arcade64, que deja solo la porción arcade, no.
3. **Arcade64 aporta una GUI que se decidió no usar.** Pegasus se eligió
   precisamente porque permite un diseño mucho más custom que la interfaz fija
   de MAMEUI/Arcade64. Si esa GUI nunca se ve, es lo único que Arcade64 agrega
   sobre vanilla — y cuesta la máquina de desarrollo y dos juegos del banco.

**Lo que NO justifica esta decisión:** no es por la migración a Rust. El
anuncio de MAMEdev del 1-abr-2026 sobre migración a Rust y revisión de código
por IA es una **broma de April Fools**; el propio equipo lo aclara en el post
del 7-abr, donde el cambio real que anuncian es C++17 → C++20. La prueba está
en el release: 0.288, primer hito supuesto de la migración, trae C++20 y
clang, cero Rust.

## Alternativas consideradas

### Arcade64

| Criterio | MAME vanilla | Arcade64 |
|---|---|---|
| Corre en macOS (dev) | ✅ SDL; desde 0.286 usa SDL3 por defecto en macOS | ❌ Windows only |
| Corre en Windows (prod) | ✅ | ✅ |
| Cubre el banco de pruebas | ✅ 5 de 5 | ❌ 3 de 5 |
| `-listxml` canónico | ✅ | ❌ fork con cambios propios |

- A favor: fork de Robbbert, arreglos propios sobre vanilla.
- En contra: Windows-only.
- **Descartada porque:** no corre en macOS — rompe el requisito de una sola
  fuente de identidad entre las dos máquinas.

### MAMEUI64

- A favor: cubre los 5 juegos del banco (absorbió MESSUI); UI de configuración
  por juego.
- En contra: Windows-only, mismo problema que Arcade64.
- **Descartada porque:** mismo motivo — sin macOS no hay una sola fuente de
  identidad.

### Un emulador distinto por plataforma (vanilla en Mac, Arcade64 en Windows)

- A favor: ninguna ventaja real sobre usar vanilla en las dos.
- En contra: es exactamente el escenario de dos fuentes de verdad que se
  quiere evitar.
- **Descartada porque:** viola el criterio rector #1.

### Clavar 0.288 exacto, sin "o superior"

- A favor: cero ambigüedad de versión.
- En contra: impediría aplicar parches y mejoras de precisión del emulador.
- **Descartada porque:** se prefiere permitir versiones superiores CON la
  regla de igualdad entre máquinas, en vez de prohibir toda actualización.

## Consecuencias

**Positivas**

- Un solo emulador, un solo `-listxml`, una sola fuente de identidad.
- El pipeline de M5 se construye contra lo mismo que corre en producción.
- Los 5 juegos del banco son ejecutables en las dos máquinas.
- El romset 0.288 (merged) matchea la versión exacta del emulador.
- Permitir "0.288 o superior" habilita actualizar el emulador (parches,
  mejoras de precisión) sin quedar clavado en una versión, siempre que se
  actualicen AMBAS máquinas juntas y el romset siga siendo ≤ la versión del
  emulador.

**Coste asumido**

- La actualización deja de ser trivial: ya no se puede dejar que Homebrew
  actualice el Mac solo, cualquier salto de versión debe hacerse en las dos
  máquinas a la vez. En la práctica conviene FIJAR la versión de MAME (evitar
  auto-update) y actualizar de forma deliberada.
- Actualizar el emulador puede exigir actualizar el romset: si se quiere un
  set más nuevo (0.291, por ejemplo), el emulador debe ser ≥ 0.291 en ambas
  máquinas. Versión de emulador y de romset quedan acopladas por la regla
  "emulador ≥ romset".
- Se pierde la UI de configuración por juego de MAMEUI (mapear controles se
  hace editando `.ini` a mano).
- Se pierden los arreglos de Robbbert que no están en vanilla.
- MAME 0.288 exige Windows 10 actualizado o superior en el gabinete.

**Qué habría que revisar si esto se replantea**

- Si en algún momento las dos máquinas divergen de versión sin querer (bug de
  proceso), reintroduce el bug de las dos fuentes de identidad — señal de que
  la disciplina operativa (ver abajo) no se está sosteniendo.
- Poco ata en cuanto a runtime en sí: `launch:` es un campo del artefacto de
  build (ver [`0002-metadata-fuente-o-artefacto.md`](0002-metadata-fuente-o-artefacto.md),
  pendiente), no del dato. Cambiar de runtime es regenerar la metadata con
  otro target.

## Regla operativa

Cada vez que se considere actualizar MAME:

1. Verificar `mame -version` en el Mac y en el gabinete: deben ser idénticas.
2. Nunca actualizar una sola máquina. Se actualizan las dos, o ninguna.
3. La versión del emulador debe ser siempre ≥ la versión del romset.
4. Después de cualquier actualización, correr el diff de `-listxml` de los 5
   juegos del banco entre ambas máquinas (ver §Verificaciones pendientes).
5. Preferir versión FIJADA sobre auto-update, para que la actualización sea
   siempre una decisión consciente y no un accidente de Homebrew.

## Verificaciones pendientes

- [ ] `mame -listxml` corre en macOS y en Windows con la misma versión.
- [ ] La salida de `-listxml` es idéntica en ambas (diff de hashes) para los 5
      del banco.
- [ ] Los 5 juegos del banco arrancan en las dos máquinas.
- [ ] El híbrido de configuración MAMEUI → vanilla funciona (recupera la
      ventaja perdida).
- [ ] Documentar cómo fijar la versión de MAME en Homebrew (evitar
      auto-update).

## Referencias

- `docs/SETUP.md` §1.3 "MAME — acá está la trampa" y §5 "Verificación final".
