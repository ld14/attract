---
id: 0018
title: "El launch: usa la ruta absoluta del emulador, resuelta por máquina"
status: accepted
date: "2026-08-03"
supersedes: null
superseded-by: null
tags: [infra, data]
---

# 0018 — El `launch:` usa la ruta absoluta del emulador

## Contexto

Al probar el theme contra Pegasus real apareció un error que no tiene nada que
ver con el theme:

```
Could not launch `mame`. Either the program is missing, or you don't
have the permission to run it.
```

MAME **está instalado** (`/usr/local/bin/mame`, vanilla 0.288). El diagnóstico,
verificado:

| Dato | Valor |
|---|---|
| Dónde está MAME | `/usr/local/bin/mame` (symlink de Homebrew) |
| PATH que hereda una app de GUI en macOS | `/usr/bin:/bin:/usr/sbin:/sbin` |
| `launch:` en el metadata | `mame -rompath …` — sin ruta |

`launchctl getenv PATH` no devuelve nada, así que Pegasus arranca con el PATH
mínimo del sistema (`getconf PATH`). **`/usr/local/bin` no está ahí.** La
terminal sí lo tiene porque lo agrega el perfil del shell, pero una app abierta
desde el Finder no lee ese perfil. Es el clásico problema de las apps de GUI en
macOS, no una particularidad de Pegasus.

**Y no es solo de desarrollo:** el gabinete arranca Pegasus solo, sin terminal
de por medio. Ahí el problema es exactamente el mismo.

Lo que la documentación de Pegasus (`pegasus-frontend.org/docs/user-guide/meta-files`)
confirma y descarta:

- **No hay `launch:` por sistema operativo.** Solo `launch` (o su alias
  `command`), uno por colección, más `workdir`/`cwd`.
- **Sí existe `{env.MYVAR}`**, que sería el atajo elegante… pero una app de GUI
  en macOS tampoco hereda las variables de entorno del shell. Mismo problema,
  una capa más abajo.

## Decisión

**El `launch:` lleva la ruta absoluta del emulador, y esa ruta se resuelve por
máquina.**

```
launch: /usr/local/bin/mame -rompath "{file.dir}" {file.basename}
```

**Esto no rompe cross-platform** ([`ADR-0003`](0003-cross-platform.md)), y el
motivo es una decisión que el proyecto ya había tomado:
`metadata.pegasus.txt` es **artefacto de build, no fuente**
([`ADR-0002`](0002-metadata-fuente-o-artefacto.md)) — se genera por máquina y
**no va a git**. Así que el Mac puede tener `/usr/local/bin/mame` y el gabinete
`C:\mame\mame.exe` sin que ninguno de los dos pise al otro: nunca comparten ese
archivo.

**Los `metadata.pegasus.txt` de `fixtures/` son la excepción y se quedan con
`mame` pelado.** Son entradas de test escritas a mano y versionadas: nunca se
lanzan de verdad, solo se le dan de comer a `attract doctor`. Poner ahí la ruta
del Mac del autor metería una ruta absoluta en un archivo que sí viaja a git,
que es justo lo que ADR-0003 evita.

**Consecuencia para la ingesta:** hoy nadie genera la línea `launch:` — está
escrita a mano en los `metadata.pegasus.txt`. `attract ingest` solo agrega
bloques `game:`. El día que ATTRACT genere la cabecera de la colección, la ruta
del emulador pasa a ser un dato de configuración de la máquina, no una
constante del código.

**Hallazgo de rebote, corregido en la misma pasada:** el `launch:` de
`library/arcade` decía `mame The Maze of the Kings` — le pasaba a MAME el
**título** en vez del set. MAME espera un nombre de máquina (`mok`). O sea que
aunque hubiera encontrado el binario, habría fallado igual. Pasa a
`{file.basename}`, que es lo que ya usaba el fixture.

## Alternativas consideradas

### A · `{env.MAME}` en el `launch:`, con la variable seteada afuera

- A favor: la ruta sale del metadata y queda en un solo lugar por máquina;
  Pegasus lo soporta explícitamente.
- En contra: **el problema es idéntico un nivel más abajo.** Una app de GUI en
  macOS no hereda las variables del shell, así que habría que setearla con
  `launchctl setenv`, que **no sobrevive a un reinicio** sin un LaunchAgent
  aparte. Y en el gabinete, que es Windows, `launchctl` no existe: sería un
  mecanismo por plataforma para evitar una ruta por plataforma.
- **Descartada porque:** agrega una pieza frágil y específica de macOS para no
  escribir una ruta en un archivo que ya es por máquina.

### B · Arrancar Pegasus desde una terminal para que herede el PATH

- A favor: cero cambios en el metadata; funciona hoy mismo en el Mac.
- En contra: **el gabinete arranca Pegasus solo**, sin terminal. Es la máquina
  donde esto tiene que funcionar de verdad.
- **Descartada porque:** arregla la máquina donde el problema no importa y deja
  rota la que sí.

### C · Symlink de `mame` dentro del PATH por defecto

- A favor: el `launch:` queda igual en todas las máquinas.
- En contra: `/usr/bin` está protegido por SIP en macOS moderno y no se puede
  escribir; los otros directorios del PATH mínimo tampoco son lugar para
  symlinks a mano. En Windows el PATH por defecto es otra cosa entera.
- **Descartada porque:** no hay ningún directorio escribible en el PATH mínimo
  donde ponerlo.

## Consecuencias

**Positivas**

- El juego arranca, que es el punto.
- Cero código y cero dependencias nuevas: es una línea de un archivo que ya se
  genera por máquina.
- Aprovecha una decisión que ya estaba tomada (ADR-0002) en vez de inventar un
  mecanismo nuevo.

**Coste asumido**

- **La ruta del emulador pasa a ser configuración de máquina.** Instalar MAME en
  otro lado, o que Homebrew cambie de prefijo (`/opt/homebrew` en Apple
  Silicon), obliga a regenerar el metadata.
- `attract doctor` **no puede validar** que el binario del `launch:` exista: el
  archivo del Mac no describe al gabinete y viceversa. Chequearlo daría falsos
  errores al validar el metadata de la otra máquina.
- Un `metadata.pegasus.txt` que igual se copie a mano entre máquinas queda
  roto. La red de seguridad es que el archivo esté en `.gitignore`, no una
  validación.

**Qué habría que revisar si esto se replantea**

- Que ATTRACT empiece a generar la cabecera de la colección: ahí la ruta del
  emulador se vuelve un parámetro de configuración explícito y conviene
  decidir dónde vive (¿un archivo de config por máquina? ¿una variable?).
- Que Pegasus agregue `launch:` por sistema operativo en alguna versión futura
  — improbable, está congelado desde octubre de 2024
  ([`ADR-0006`](0006-version-politica-pegasus.md)).

## Referencias

- `pegasus-frontend.org/docs/user-guide/meta-files` — `launch`/`command`,
  `workdir`/`cwd`, y las variables `{file.*}` y `{env.*}`. Consultado
  2026-08-03.
- [`ADR-0002`](0002-metadata-fuente-o-artefacto.md) — el metadata es artefacto
  de build. Es lo que hace que esta decisión no rompa nada.
- [`ADR-0003`](0003-cross-platform.md) — la estrategia cross-platform que
  obliga a tratar las rutas absolutas con cuidado.
- Error observado en Pegasus real, 2026-08-01: `Could not launch 'mame'`.
