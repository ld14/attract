# Handoff: Pegasus Retro Launcher — Game Detail Screen (+ Library)

## Overview
A themed replacement for Pegasus Frontend's game library + game-detail screens, for a custom arcade cabinet (Amiga/DOS/arcade/console retro library). Adds: an ambient/looping gameplay video on the detail screen with custom transport controls, a "Notas en revistas" (magazine scan) carousel + full paginated document viewer (also used for digitized manuals), a graphical "Trucos & Combos" (cheats/combos) command-board overlay, and per-game dynamic accent theming.

## About the Design Files
The bundled file is a **design reference built in HTML/CSS/JS** (a "Design Component" runtime used for prototyping) — it is **not** QML/JS and not code to paste into Pegasus. The task is to **recreate this design in Pegasus Frontend's actual environment**: QML + JavaScript on Qt Quick, using Pegasus's `api` data object, its metadata format (including custom `x-` fields), QtMultimedia for video, and QML `Image`/`Flickable`/`ListView`/`PathView` for the layouts and carousels described below. Any prototype-only interaction (mouse hover reveal, keyboard `Enter`/`Escape`) should be re-implemented against Pegasus's actual input model: gamepad/joystick, keyboard, and (if enabled) mouse/touch, per the project's existing input handling conventions.

## Fidelity
**High-fidelity.** Colors, typography, spacing, layout proportions, and micro-interactions (hover reveal, transitions, focus states) shown here are final and should be recreated pixel-for-pixel where QML allows. Where QML/Qt Quick cannot exactly replicate a CSS effect (e.g. `backdrop-filter: blur`, `color-mix()`, CSS `clip-path`), approximate as closely as Qt Quick's `FastBlur`/`GaussianBlur` (Qt5Compat.GraphicalEffects or Qt6 `MultiEffect`), pre-computed colors, and `Shape`/`OpacityMask` allow, and flag the gap in a code comment.

## Global Design Tokens

**Typography** (Google Fonts — bundle locally as `.ttf`/`.otf` for offline cabinet use):
- Display/headers: `Chakra Petch`, weights 500/600/700
- Body/UI: `Sora`, weights 300–800
- Monospace/labels/HUD: `JetBrains Mono`, weights 400/500/700

**Base colors:**
- Background: `#04050a` (screen root), `#07080c` / `#0a0c12` (panel gradients)
- Text primary: `#e9ebf2` / `#fff`
- Text secondary: `#8a90a0`, `#6a7081`, `#aeb3c0`, `#b9bdca`
- Panel surfaces: `rgba(255,255,255,.03–.07)` fills with `rgba(255,255,255,.06–.18)` borders (glass/HUD panel look)

**Accent color — per-game dynamic theming:**
Every game/platform has an `accent` (bright) and `accent2` (dark, for gradients) hex pair. The accent drives: focus rings, CTA buttons, active tab/chip states, progress bars, glow/shadow colors, and the cheats-overlay HUD frame. Example pairs used in the prototype:
- Striker (Amiga/DOS, football): `#3ad17a` / `#0c3d22`
- Blade Circuit (arcade fighting): `#ff5a3c` / `#4d150b`
- Chrono Raider (action RPG): `#9b6bff` / `#2a1a4d`
- Void Sector (FPS): `#4b8cff` / `#10264d`
Implement as a per-platform/per-game theme token resolved at runtime (QML `property color accent` bound from game metadata), not hardcoded per screen.

**Radii/shadows:** cards/panels 8–18px radius; large soft drop shadows `0 20–40px 60–120px rgba(0,0,0,.5–.65)` under all elevated panels; glow shadows use the accent color at ~40–60% mix.

**Stage scaling:** the whole UI is authored at a fixed **1280×720** canvas and uniformly scaled to fit the real screen/window (`transform:scale(min(w/1280,h/720))`, centered). In QML, use an `Item` sized 1280×720 wrapped in a `Scale`/`transform` bound to `min(window.width/1280, window.height/720)`, or design at Pegasus's native res and use anchors/relative sizing — team's call, but preserve the fixed-canvas proportions.

---

## Screens / Views

### 1. Library (`isLibrary` state)
**Purpose:** Browse the game collection, pick a game, see its hero synopsis, jump to detail or launch directly.

**Layout:** Full-bleed column (`flex-direction:column`) over an ambient background (see Background section below).
- **Top bar** (padding `26px 48px 0`): left — 13px accent-colored square (glow) + wordmark "SHINBOX" (Chakra Petch 700, 15px, letter-spacing .18em) + "ARCADE" in muted gray. Right — filter pills "TODOS / ARCADE / CONSOLA / FAVORITOS" (JetBrains Mono 12px, active item in accent color) + a live clock (`HH:MM`, updates every 20s) separated by a left border.
- **Hero block** (bottom-aligned in remaining flex space, `max-width:680px`, `padding-bottom:24px`):
  - System/year/genre eyebrow row: bordered pill with system name (accent border+text) + "{year} · {genre}" in muted gray. JetBrains Mono 12px.
  - Title: Chakra Petch 700, `clamp(44px,6.4vw,104px)`, line-height .92, drop shadow.
  - Synopsis: Sora 16px/1.55, max-width 560px, color `#b9bdca`.
  - Actions row (26px gap): primary "▶ JUGAR" button (accent bg, dark text, 13×24px padding, 8px radius, accent-colored glow shadow) — secondary "▤ VER DETALLE" outline/glass button — index counter "`0N / 0N`" in mono.
- **Cover rail** (bottom, `padding:0 48px 58px`, horizontally scrolling via transform translateX, 16px gaps): each game card is 148×166px, rounded 10px, radial/conic gradient background tinted with that game's `accent`/`accent2`. Card shows system tag + year (top row) and title + content-type dots (bottom). The **focused** card lifts (`translateY(-14px) scale(1.06)`), full opacity, ring + glow shadow in its own accent; unfocused cards sit at 0.5 opacity. Rail auto-scrolls to keep the focused card roughly 3rd-from-left.

**Interactions:** ArrowLeft/Right (or A/D) move focus one card at a time; Enter/Space opens Detail for the focused game; clicking the already-focused card also opens Detail; clicking any other card just focuses it (matches a single-press-to-focus, second-press-to-select TV/console UX pattern — do not auto-drill on first focus).

---

### 2. Detail (`isDetail` state)
**Purpose:** Full info + all optional rich content entry points for one game.

**Layout:** Column with a top bar, then a two-column body (`gap:48px`, `padding:30px 48px 0`).

**Top bar:** "◄ GALERÍA" back button (glass pill) — left. System · year label in accent color — right.

**Left column** (fixed `280px`):
1. **Cover/video panel** — 280×288px, 12px radius, `padding:16px`, content bottom-aligned.
   - If the game has a `video` (looping gameplay clip): an absolutely-positioned `<video>` (loop, muted default, autoplay) fills the panel (`object-fit:cover`), with a soft radial vignette, a top-right **"● GAMEPLAY"** live pill (small red dot pulsing via 1.6s opacity keyframe), and **custom transport controls** that fade in on hover/focus (`opacity 0→1`, `translateY(8px→0)`, 0.2s):
     - Play/Pause toggle (glyph swaps `▶ / ❚❚`)
     - Volume down (−) / up (+) buttons stepping the video's volume by 0.2
     - A 5-segment level meter (bars light up in accent color proportional to volume; all off = muted)
     - Mute toggle button (border/icon turns red when muted; a diagonal strike-through renders over a speaker glyph)
     - All controls are real `<video>` element bindings: `volume`, `muted`, `paused`. In Pegasus, bind these to `MediaPlayer`/`VideoOutput` (QtMultimedia) properties and build the same button row in QML, with focus-based (not just hover-based) reveal for gamepad use — **add an explicit D-pad-focus reveal state**, since TV/cabinet input has no mouse hover.
   - If no video: shows a static color-washed placeholder (radial/conic gradient from the game's accent) instead.
   - Bottom-aligned inside the panel: game title, Chakra Petch 700 30px, uppercase, drop shadow.
2. **"▶ JUGAR" button** — full-width, accent bg, 15px radius→10px, bold; gets a white/accent focus ring + lift when it's the currently-focused action target.
3. **"NOTAS EN REVISTAS" carousel** (only rendered if the game has `mags`) — pinned to the bottom of the left column (`margin-top:auto; padding-bottom:62px`):
   - Section label (mono, 10px, letter-spacing .16em) turns accent-colored when this component has focus.
   - A viewport (178px tall) showing **2 magazine-cover cards at a time** (each 133×178px), sliding horizontally via `translateX` in 143px steps (10px gap included), 0.35s cubic-bezier easing.
   - Each cover card: if a real scanned cover image (`img`) exists, render it as a cover-fit background image; otherwise render a **styled placeholder** — a colored masthead bar (magazine's brand color) with its name, plus a textured "hero" area (accent-tinted gradient over a diagonal striped placeholder swatch) with a circular score-flash badge and the game title overlaid at the bottom.
   - Prev/Next chevron buttons appear only when there are more than 2 magazines; a dot row (wide pill for the 2 currently visible, small dot otherwise) plus a "`1–2 / 4`" counter sits below the viewport.
   - Clicking a cover, or pressing Enter with this row focused, opens the **Document Viewer** (see section 4) starting at that magazine's cover page.

**Info column** (flex:1):
1. **Header row**: title (Chakra Petch 700, `clamp(34px,4vw,60px)`) + wrapped meta chips (AÑO / SISTEMA / GÉNERO / JUG. / DEV — pill chips, mono 11px, muted-gray key + white value) on the left (`max-width:600px`); **absolutely positioned at top-right** (`width:190px`) a **box-art + format badge + critic-review card** column:
   - Box art: 108×144px rounded panel. Uses the real cover image (`cover` field) if present, else the accent color-wash placeholder. A small corner "media format" badge (26×26px rounded square, dark bg, accent icon) overlays its bottom-right corner, showing a hand-drawn-in-CSS icon for **Floppy Disk / CD-ROM / Cartridge** depending on the platform+year (see `mediaFor()` logic below) — plus a "FORMATO" label + human-readable value ("Diskette" / "CD-ROM" / "Cartucho") centered underneath.
   - **Critic review card** (only if review data exists for the game) — a retro-magazine-styled scorecard: dashed-corner accent frame, subtle scanline overlay, a "NOTA DE LA CRÍTICA" header band (accent-tinted), 6 stat rows (label + numeric value + a filled progress bar in accent gradient) for categories like ORIGINALIDAD/GRÁFICOS/ADICCIÓN/SONIDO/DIFICULTAD/ANIMACIÓN, a verdict paragraph, and a large accent-colored score number (e.g. "94") with "PUNTUACIÓN · SOBRE 100" caption in a footer band.
2. **Synopsis** (`margin-top:18px`, `max-width:600px`): "SINOPSIS" label (accent, mono) + body copy (Sora 16px/1.62).
3. **"CONTENIDO EXTRA" section cards** (pinned to bottom via `margin-top:auto; padding-bottom:72px`) — one card per available optional content type (only rendered when present, never an empty/greyed placeholder):
   - **Hacks** (cheats/combos): 50×50px icon tile (accent-tinted bg+border) with a skull glyph, label "Hacks", sub-line "{n} combos · {n} trucos".
   - **Manual digitalizado**: icon tile with a two-page-book line-drawing (CSS borders), sub-line "{n} págs".
   - (Magazines are NOT duplicated here — they only live in the left-column carousel.)
   - Cards: pill-shaped info row (icon + label + sub-label) + a "›" chevron; on focus/hover: accent border, lighter fill, lifts 3px with a drop shadow.
   - If a game has **no** extra content at all, render a single dashed-border placeholder row: "— Sin contenido extra para este juego —" (never leave a blank gap).

**Interactions:** Left/Right (A/D) moves focus across detail targets in this fixed order: [Play] → [Magazine carousel, if present] → [each extras card, in order]. Up/Down (W/S) — **only while the magazine carousel is focused** — steps the carousel by one page instead of moving focus. Enter/Space activates the focused target (launch game / open magazine viewer at the current carousel page / open the relevant overlay). Escape/Backspace returns to Library.

---

### 3. Document Viewer overlay (`viewerOpen`)
**Purpose:** Shared paginated reader for both magazine scans and digitized manuals.

**Layout:** Full-screen overlay, `rgba(5,6,9,.86)` scrim + 16px backdrop blur.
- **Top bar:** glyph + title ("Revistas de la época" / "Manual digitalizado") + current source name — left. If multiple magazine sources exist for this game, small pill **tabs** (colored dot matching each magazine's brand color + its short name) let the user switch between magazine sources without leaving the viewer — right, before the ✕ close button.
- **Stage:** centered "sheet" (560×760px for magazines / 540×760px for manuals, max 88% viewport height), with round prev/next chevron buttons floating on either side (disabled/dimmed at the first/last page). The sheet itself:
  - **Magazine page 0 (cover):** if a real cover scan image exists, show it `background-size:contain` on a dark mat; otherwise render a fully-designed **retro magazine cover mockup** — colored masthead with the magazine's name + issue number + tagline, a hero art area (accent-gradient over a textured placeholder) with a circular "NOTA {score}" badge, a red "★ EN PORTADA" flag, the game title as the cover line, 3 teaser bullets (diamond bullet + mono caps text), and a footer bar with date/price + a barcode graphic (repeating stripes).
  - **Magazine pages 1+ ("review" template):** parchment-colored page with a review masthead (rotating heading: REVIEW/ANÁLISIS/GUÍA DE JUEGO/PÓSTER CENTRAL/TRUCOS), the game title, a two-column layout — left: a placeholder screenshot swatch + text-line placeholders; right: a bordered score box ("PUNTAJE {n}/100") + more text-line placeholders — and a footer with source name + page number.
  - **Manual pages:** parchment page with masthead ("{title} · MANUAL"), a rotating section heading (CONTROLES/CÓMO JUGAR/PERSONAJES/ÍTEMS Y ARMAS/PANTALLAS/PUNTAJE), a control-diagram placeholder (CSS-drawn d-pad outline + colored action-button dots), a numbered instruction-step list (placeholder bars), and a page-number footer.
  - **Zoom & pan:** the sheet scales via CSS `transform: scale(zoom)` — 4 zoom steps (1×, 1.4×, 1.85×, 2.4×). Above 1× zoom, mouse-drag pans the sheet (`transform: translate(panX,panY) scale(zoom)`); the cursor shows grab/grabbing. Mouse wheel also zooms in/out.
- **Bottom bar:** a thumbnail strip (one numbered button per page — square-ish 34×46px, accent-highlighted glow on the active page, click to jump) on the left; page counter ("PÁG. n / total") + zoom controls (−, %, +) on the right.

**Interactions:** Left/Right (A/D) = prev/next page. `+`/`-` = zoom in/out. Escape/Backspace closes. Wheel zooms; drag pans when zoomed.

---

### 4. "Trucos & Combos" overlay (`cheatsOpen`)
**Purpose:** A graphical, arcade-command-board style cheat sheet — explicitly designed to *not* look like a generic web list. Parses each game's raw cheat/combo strings into visual "keycap" tokens.

**Layout:** Centered panel (`min(900px,95vw)`, max 88vh), dark gradient bg, accent-tinted 1px border, heavy drop shadow + inner accent glow, full-panel scanline overlay, and accent-colored corner brackets (top-left/top-right/bottom-left/bottom-right, HUD-style) drawn with CSS border segments.
- **Header band:** angular clipped-corner icon tile (skull/joystick motif circles) + blinking accent diamond + "TRUCOS & COMBOS" title (Chakra Petch 700, 20px) + "{game title} · LISTA DE COMANDOS" sub-line; a "P1" accent tag chip + ✕ close button on the right.
- **Body (scrollable):**
  - **"▶ COMBOS" section** (only if the game has combos) — section rule (accent label + gradient underline + a "0N MOVS" counter) then a stacked list of combo cards: each is a left-accent-bar row with an index number, the combo name, and its **parsed input sequence rendered as real button/direction glyphs** (see token grammar below) right-aligned and wrapping.
  - **"★ CÓDIGOS SECRETOS" section** (only if the game has codes) — same rule treatment, then rows with a star icon chip, the code's name, and its parsed key sequence.
- **Footer:** centered blinking "— PRESIONÁ B PARA VOLVER —" hint.

**Input-token grammar (must be reproduced, since it's the core visual language of this screen):**
Raw cheat/combo strings are tokenized and rendered as:
- **Directional inputs** (`↑ ↓ ← → ↖ ↗ ↘ ↙` or any run made only of those glyphs): a 36×36px rounded dark "d-pad key" with the accent-colored arrow glyph and a subtle glow.
- **Face buttons** (`✕ × ⨯ ○ ◯ △ □`): a 34×34px circular button, colored per convention — `✕/×/⨯` = blue `#3b6fe0`, `○/◯` = red `#e0454f`, `△` = green `#39b878`, `□` = magenta `#d65bd6` — with a matching-color glow ring (PlayStation-style face buttons).
- **Shoulder/pad buttons** (regex `^[LR][123]$`, e.g. `L1`, `R2`, `L3`): a pill-shaped dark keycap with the label text.
- **Arcade buttons** (regex `^[PK]{1,3}$`, e.g. `P`, `K`, `PP`): a 34×34px circular gradient button — Punch (`P`) red, Kick (`K`) blue — with a beveled highlight, like a real arcade cabinet button.
- **`+` separators**: a plain gray "+" glyph between simultaneous inputs.
- **Any other word** (free text like "mantené la línea…"): rendered as plain inline prose text (Sora 13px, muted gray) — so natural-language instructions and symbolic notation can be mixed in the same combo string without breaking the visual grammar.
This tokenizer should become a small reusable QML function/component (`InputTokenRow` or similar) that takes a raw string + the current accent color and emits a `Row` of styled `Item`s — reused for both the Combos and Códigos lists.

---

### 5. Launch overlay (`launching`)
Full-screen scrim, centered spinner (accent-colored, 0.8s linear rotation), "INICIANDO" label (accent, mono, letter-spacing .2em), the game title (Chakra Petch 700, 32px, uppercase), and a small monospace line simulating the launch command (e.g. `launch: retroarch -L core.dll …`) — this line should be replaced with Pegasus's **actual** resolved launch command from the game's metadata. Shown for ~2.3s in the prototype; in Pegasus this should show for as long as the actual external process takes to spawn/gain focus, per Pegasus's existing launch-transition conventions.

---

## Background treatment (all screens)
Three stacked layers behind all content:
1. A radial accent-colored glow anchored top-right (`radial-gradient(130% 100% at 72% 8%, accent 0%, transparent 46%)`) over a dark vertical gradient (`#0a0c12 → #07080c`), ~55% opacity.
2. A subtle animated scanline texture (`repeating-linear-gradient` every 8px, `screen` blend mode, slow vertical drift loop, ~12% opacity) — purely decorative "CRT ambiance."
3. A left-to-right + bottom vignette (dark gradient) ensuring left-column text stays legible over any lighter background art.
Plus an optional global **CRT scanline + vignette overlay** (`repeating-linear-gradient` darken lines + radial vignette, `multiply` blend) toggleable via a `crtScanlines` flag/setting.

## Design Tokens (consolidated)
- **Fonts:** Chakra Petch (500/600/700), Sora (300–800), JetBrains Mono (400/500/700)
- **Radius scale:** 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 16, 18px (context-dependent; panels mostly 8–12px, chips/pills fully rounded)
- **Shadow scale:** soft ambient `0 8–24px 20–60px rgba(0,0,0,.4–.55)`; accent glow `0 0 12–40px {accent}` at 40–90% mix, used on focus states and buttons
- **Spacing scale:** 6, 8, 10, 12, 14, 16, 18, 20, 24, 26, 30, 32, 48px (screen gutters are 48px)
- **Per-game accent pairs:** stored as game/platform metadata (`accent`, `accent2` hex), see examples above

## Assets
- All artwork in the prototype is either a **real scanned image** (magazine covers, box art, gameplay video) supplied by the project owner, or a **CSS-drawn placeholder** (gradients, repeating stripes, line-art icons) standing in for assets not yet acquired — **no placeholder should be shipped to production**; replace every placeholder with the real scanned/rendered asset (magazine page scans, manual page scans, box art, gameplay capture) per game before release.
- Gameplay video: a short looping capture per game, loaded as a local file in production (Pegasus/QtMultimedia `MediaPlayer` + `VideoOutput`), not a network fetch.
- Fonts: Google Fonts (Chakra Petch, Sora, JetBrains Mono) — bundle as local font files since the cabinet is offline.

## Data / Metadata Requirements
Each game needs, beyond Pegasus's standard fields: an `accent`/`accent2` color pair, an optional local `video` file path, an optional `cover` (box art) image, an optional list of magazine entries (`name`, `page count`, `brand color`, optional cover scan image path — maps to the project's already-planned `x-magazines` field and its per-magazine page-image folders), an optional `manual` entry (page count — maps to `x-manual`), and optional structured cheat/combo data (`combos: [{name, input}]`, `codes: [{name, input}]` — maps to `x-cheats`, parsed into the input-token format above) plus review score/verdict/category-breakdown data if a "critic review" card is desired. All of these are optional per game; the UI must gracefully omit any section/component with no data — never render an empty or greyed placeholder for missing content.

## Files
- `Pegasus Game Detail.dc.html` — the full interactive prototype (Library + Detail + Document Viewer + Cheats overlay + Launch overlay), included in this bundle. Open directly in a browser to interact with all states (keyboard: arrow keys, Enter, Escape).
