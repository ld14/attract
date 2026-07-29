# SETUP · Entorno de trabajo

Dos máquinas, dos roles. No son intercambiables.

```
┌─────────────────────────┐         ┌─────────────────────────┐
│  MacBook Pro   (DEV)    │  git    │  Windows      (PROD)    │
│                         │ ──────▶ │                         │
│  · escribís código      │         │  · corre Pegasus real   │
│  · corrés attract doctor│         │  · corre MAME real      │
│  · mame -listxml        │         │  · la librería completa │
│  · Pegasus para el theme│         │  · video · launch · fps │
│  · el banco (5 juegos)  │ ◀────── │                         │
└─────────────────────────┘  notas  └─────────────────────────┘
```

**La regla:** todo lo que Windows rechazaría tiene que fallar en el Mac.
Solo tres cosas son irreductibles del lado Windows: **video** (DirectShow),
**`launch:`** y **performance en el hardware**. El resto lo caza `attract doctor`.

---

# 1 · Mac (desarrollo)

## 1.1 Base

```bash
# Xcode Command Line Tools (git viene acá)
xcode-select --install

# Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

brew install python@3.12 node git
python3 --version   # >= 3.10
which -a python3    # /usr/local/bin/python3  ANTES que  /usr/bin/python3
node --version      # >= 18  (22+ si vas a instalar Claude Code por npm)
```

> 🔴 **macOS trae Python 3.9.6 en `/usr/bin/python3`. No lo uses.**
>
> Está **EOL desde octubre de 2025** y es el intérprete *del sistema*: macOS lo usa.
> Meterle `pip install` es cómo se rompen las instalaciones de macOS.
>
> En **Intel** esto se resuelve solo: Homebrew instala en `/usr/local` y el PATH por
> defecto de macOS ya pone `/usr/local/bin` antes que `/usr/bin`. El de Homebrew gana.
> (En Apple Silicon va a `/opt/homebrew` y hay que tocar el PATH a mano.)
>
> Verificá con `which -a python3`. Si `/usr/bin/python3` sale primero, el PATH está mal.
>
> `make setup` te avisa si tu python3 es menor a 3.10.

Node lo vas a necesitar de verdad en **M5**: el MCP Inspector se baja con `npx`.

## 1.2 Claude Code

El instalador nativo es el método recomendado hoy — no necesita Node:

```bash
curl -fsSL https://claude.ai/install.sh | bash
claude --version
claude doctor        # diagnostica PATH, permisos, autenticación
```

Alternativas: `brew install --cask claude-code` (⚠️ **no auto-actualiza**, quedás
viejo en meses) o `npm install -g @anthropic-ai/claude-code` (requiere Node 22+
desde v2.1.198).

> ⚠️ **Nunca uses `sudo npm install -g`.** Deja archivos root-owned que rompen
> todas las instalaciones globales futuras.
>
> Si tenías la versión npm y ponés la nativa, quedan dos binarios pisándose.
> Verificá con `which -a claude`. Si aparece más de uno:
> `npm uninstall -g @anthropic-ai/claude-code && hash -r`

Requiere cuenta paga (Pro, Max, Team, Enterprise o Console). El plan gratuito de
claude.ai no incluye Claude Code.

## 1.3 MAME — acá está la trampa

```bash
brew install mame
mame -version        # ← ANOTÁ ESTE NÚMERO
```

> 🔥 **MAME no publica binarios de macOS.** El sitio oficial da código fuente y
> binarios de Windows x64. En Mac vas por Homebrew, MacPorts, un build de terceros
> sin firmar, o compilás vos.
>
> **Y Homebrew va atrás.** En marzo de 2026 la fórmula estaba en 0.286. Tus ROMs
> son 0.288.
>
> **Si `mame -version` en el Mac ≠ `mame -version` en Windows, ADR-0005 está roto**
> y no te vas a enterar: vas a tener dos `-listxml` distintos, dos ideas distintas
> de qué juegos existen, y bugs que aparecen en la semana 8.

Si Homebrew no llegó a 0.288, tenés tres salidas:

| | Costo |
|---|---|
| **Compilar de source** en el Mac | Xcode CLT + un rato. Da la versión exacta |
| **Bajar el Windows a la de Homebrew** | Tus ROMs 0.288 pueden no validar contra 0.286 |
| **Aceptar la deriva y documentarla** | Solo si verificás que `-listxml` no cambió para tus 5 juegos |

Ninguna es gratis. **Elegí conscientemente y anotalo en ADR-0005.**

Datos útiles de MAME en Mac:
- **No hay app de doble clic.** Es una aplicación de consola. Terminal o un frontend.
- 0.286+ usa **SDL3** por defecto en macOS (Homebrew lo instala como dependencia).
- Los builds de terceros **no están firmados por Apple**: hay que habilitarlos a mano
  en Gatekeeper.

## 1.4 Pegasus

Bajalo de la página oficial de descargas. Abrilo una vez aunque esté vacío, para que
cree su config en `~/Library/Preferences/pegasus-frontend/`.

## 1.5 El repo

```bash
unzip attract-v0.0.zip && cd attract
git init
make setup       # setea core.precomposeUnicode
make check-git   # verificá que diga true
make doctor      # OK
make test        # 48 passed
git add -A && git commit -m "chore: scaffold v0.0"
git tag v0.0-inicio
```

> `make setup`/`make test` no instalan `mcp` — es la única dependencia
> externa del proyecto, y es opcional (ver
> [`ADR-0012`](../spec/decisions/0012-mcp-dependencia-opcional-acotada.md)).
> Solo hace falta si vas a correr `attract mcp`: `pip install mcp`. Sin
> eso instalado, los tests de `mcp` se saltean solos
> (`pytest.importorskip`) y todo lo demás (`doctor`, `synopsis`) funciona
> exactamente igual.

## 1.6 Qué ROMs necesita el Mac

**Casi ninguna.** Esto sorprende:

```bash
mame -listxml sf2ce    # funciona con CERO roms instaladas
```

`-listxml` consulta la base de drivers interna del emulador, no tu librería. **La capa
de identidad no necesita las ROMs.** Eso hace que M5 sea desarrollable en el Mac aunque
la librería viva en el gabinete.

Para el Mac alcanza con el banco:

| Juego | Tamaño | Nota |
|---|---|---|
| `sf2ce` | chico | |
| `dino` | chico | |
| `tmnt` (NES) | muy chico | |
| `mok` | ~132 MB | zip 1,15 KB + CHD + BIOS `naomigd` |
| Striker (Amiga) | — | ⚠️ ver abajo |

> **Striker es un caso aparte.** Es Amiga/DOS: en MAME sale por el driver de Amiga con
> ADF o WHDLoad, y no es trivial. **Para M0 no hace falta ejecutarlo** — su data ya está
> escrita en el mockup y lo que necesitás es la metadata, no el juego corriendo.
> Postergalo hasta que `launch:` importe de verdad.

---

# 2 · Windows (producción)

Deliberadamente mínimo. Windows no desarrolla: verifica.

## 2.1 MAME

Bajá el binario **oficial x64** de mamedev.org. Ese es el canónico.

```
mame.exe -version     # tiene que coincidir con el del Mac
```

MAME 0.288 exige **Windows 10 actualizado o superior**. Desde 0.288 compilan Windows x64
con clang, UCRT y libc++.

## 2.2 Pegasus + git

Pegasus para Windows, y git para traer el repo. Nada más.

**No hace falta Python.** El `doctor` corre en el Mac; ese es el punto.

## 2.3 Portable mode (recomendado)

```
--portable    o    portable.txt junto al ejecutable
```

Deja toda la config en `<dir del programa>/config/`, que podés versionar y copiar entera.

> ⚠️ Hay un reporte viejo (2020) de que en portable mode Pegasus guarda el path del theme
> en **absoluto** en vez de relativo. Puede estar arreglado. Verificalo antes de
> depender de eso.

---

# 3 · El puente

## 3.1 Qué viaja y qué no

```
git   ✅  src/  docs/  spec/  tests/  themes/  fixtures/  Makefile  .gitattributes
git   ❌  library/**   ← ROMs, CHDs, assets. Pesan y no aportan
git   ❌  *.pegasus.txt ← es un artefacto de build (ADR-0002)
```

El repo entero pesa unos pocos MB y viaja en un `git push` sin problema. Los
fixtures son casi todos ROMs de **0 bytes** con los nombres correctos: para
validar que el generador emite bien no necesitás un CHD de 132 MB.
Excepción a propósito: `fixtures/arcade/sf2ce.zip` es un romset real chico
(~3.5 MB), para poder correr `mame -listxml` contra él de verdad.

## 3.2 Los tres settings de git

```bash
git config core.precomposeUnicode   # → true. Sin esto, los acentos llegan rotos
git config core.autocrlf            # → vacío está bien: manda .gitattributes
```

> **`core.precomposeUnicode` arregla los NOMBRES de archivo. No arregla el CONTENIDO.**
>
> ```
> media/Micromanía/pag01.jpg              ← nombre → git lo normaliza a NFC ✅
> assets.boxFront: media/Micromanía/...   ← esto es TEXTO dentro del metadata ❌
> ```
>
> Si tu generador escribe esa línea en NFD, git no la toca: es contenido, no un path del
> índice. Llega a Windows en NFD, el archivo está en NFC, **no matchean, y no hay error**.
> La imagen simplemente no aparece.
>
> `attract doctor` lo caza. Es el chequeo `nfc-contenido`.

---

# 4 · El ciclo diario

```
MAC                                    WINDOWS
───                                    ───────
editar / codear
     ↓
make doctor        ← 9 chequeos        (no viajás si esto falla)
     ↓
make test          ← 48 tests
     ↓
git push  ────────────────────────────▶ git pull
                                            ↓
                                        probar lo irreductible:
                                          · el video reproduce
                                          · el launch funciona
                                          · los fps en el hardware
                                            ↓
◀────────────────────────────────────── anotar
```

**El costo no es el traslado: es el ciclo.** Aunque sean 3 minutos, a la décima vez del
día dejás de probar, y ahí los bugs se acumulan. Por eso el `doctor` corre en el Mac: la
ingeniería está en **no viajar**.

---

# 5 · Verificación final

Antes de escribir una línea de M0:

```
MAC
[ ] python3 >= 3.10 · node >= 18 · git
[ ] claude --version  ·  claude doctor sin quejas
[ ] mame -version   →  _____________   ← anotalo
[ ] Pegasus abre
[ ] make check-git → core.precomposeUnicode = true
[ ] make doctor → OK
[ ] make test → 48 passed
[ ] make theme → el theme de debug aparece en Pegasus

WINDOWS
[ ] mame.exe -version → _____________  ← ¿COINCIDE con el del Mac?
[ ] Pegasus abre
[ ] git clone del repo funciona

EL PUENTE
[ ] git push / git pull en las dos direcciones
[ ] Un archivo con acentos sobrevive el viaje con el nombre intacto

CRÍTICO
[ ] Las dos versiones de MAME coinciden.
    Si no: elegiste una salida y la anotaste en ADR-0005.
```

> El único que puede bloquearte es el último. Los demás se arreglan en minutos.

---

# 6 · Verificaciones que deberías hacer y quizá no hiciste

Ninguna lleva más de 15 minutos y las cuatro cambian decisiones:

```bash
# 1. ¿Los -listxml de las dos máquinas son idénticos?  (ADR-0005)
mame -listxml sf2ce > /tmp/mac.xml          # en el Mac
mame.exe -listxml sf2ce > win.xml           # en Windows
#    después: diff. Si difieren, tenés dos verdades.

# 2. ¿Cuántos juegos hay dentro de un archivo?  (ADR-0004)
mame -listxml sf2ce | grep -c "<machine"
unzip -l sf2ce.zip | tail -1

# 3. ¿Qué necesita mok para arrancar?
mame -listxml mok | grep -E "disk name|romof|<machine name"

# 4. ¿game.extra.X es string o lista?  (ADR-0001 — el experimento del Bloque 3)
make theme
```

---

## Fuentes

| Qué | Dónde |
|---|---|
| MAME | https://www.mamedev.org/ · https://www.mamedev.org/release.html |
| MAME en SDL/macOS | https://wiki.mamedev.org/index.php/SDL_Supported_Platforms |
| Homebrew mame | https://formulae.brew.sh/formula/mame |
| Pegasus | https://pegasus-frontend.org/ |
| Claude Code · setup | https://code.claude.com/docs/en/setup |
| Claude Code · docs | https://docs.claude.com/en/docs/claude-code/overview |
