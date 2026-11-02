# Replicating macOS menu-bar legibility on a KDE Plasma 6 top panel with Panel Colorizer (KWin 6)

Scope note: Panel Colorizer findings come mostly from the **installed source, v8.0.0** (`/usr/share/plasma/plasmoids/luisbocanegra.panel.colorizer/`, `metadata.json` "Version": "8.0.0"), plus the upstream README. Local-config observations (the user's own presets and kwinrc) are marked "[local]". Paths cited as `contents/...` are relative to that install directory; the same files live in the upstream repo at https://github.com/luisbocanegra/plasma-panel-colorizer (package/contents/...).

## Q1. Panel Colorizer: foreground color, foreground shadow, blend modes, presets/auto-loading, tray icons

### Takeaway
Panel Colorizer's foreground shadow is a Qt5Compat `DropShadow` with a **hard-coded `spread: 0.35`**, configurable only by size (radius), x/y offset and color/alpha. With zero offset and a light color it reads as a halo/glow. There is no blend-mode option. Shadow and foreground color are stored per preset (and per element: panel / widgets / tray, and per widget state), so the clean way to get "no shadow on dark glyphs, subtle shadow on light glyphs" is **two presets** that you switch between. Built-in auto-loading reacts to window and panel state, not to the wallpaper. Wallpaper-driven switching has to come from an external script that calls the plasmoid's D-Bus `preset` method.

### Cited Findings
**Config schema (contents/ui/code/globals.js)**
- Foreground color object `baseFgColor`: `enabled, alpha, sourceType, custom, systemColor ("highlightColor"), systemColorSet ("View"), list, followColor, saturationEnabled/Value, lightnessEnabled/Value, animation`. Shadow object `baseShadow = { enabled:false, color: baseShadowColor, size: 5, xOffset: 0, yOffset: 0 }`, and `shadow: { background: baseShadow, foreground: baseShadow }`. The shadow color defaults to `custom: "#000000"` but `sourceType: 1` (system color `backgroundColor`). — [installed source globals.js; upstream repo](https://github.com/luisbocanegra/plasma-panel-colorizer)
- These blocks repeat for `panel`, `widgets` and `trayWidgets`, each under the states `normal, busy, hovered, needsAttention, expanded`, so foreground color and foreground shadow can differ per element type and per widget state. — [globals.js `defaultConfig`](https://github.com/luisbocanegra/plasma-panel-colorizer)
- Panel-level keys: `blurBehind`, `backgroundColor` (with `alpha`), `nativePanel.background { enabled, opacity, shadow }` (hides or keeps the stock panel SVG and its shadow), plus `stockPanelSettings.opacity` (value "adaptive" and others). — [globals.js](https://github.com/luisbocanegra/plasma-panel-colorizer)
- `sourceType` meanings (utils.js `getColor`): 0 = custom hex, 1 = Kirigami system color, 2 = color list, 3 = random, 4 = follow panel/parent background color. Optional saturation/lightness scaling is applied afterwards, then **`alpha` replaces the color's alpha**. Gotcha: a custom shadow hex is ignored unless `sourceType` is 0. — [utils.js `getColor`](https://github.com/luisbocanegra/plasma-panel-colorizer)

**How the foreground shadow is drawn (contents/ui/components/CustomBackground.qml)**
- `DropShadow { horizontalOffset: fgShadow.xOffset; verticalOffset: fgShadow.yOffset; radius: fgShadowEnabled ? fgShadow.size : 0; samples: radius*2+1; spread: 0.35; color: Utils.getColor(...); source: rect.target?.applet }`. The shadow is the alpha silhouette of the **whole applet item** (text and icons together), blurred with radius = "size" px and thickened by a fixed 35% spread. — [CustomBackground.qml](https://github.com/luisbocanegra/plasma-panel-colorizer)
- The background shadow is a separate `Kirigami.ShadowedRectangle` (`shadow.size / xOffset / yOffset / color`) behind the widget or panel background. It does not affect glyphs. — [CustomBackground.qml](https://github.com/luisbocanegra/plasma-panel-colorizer)
- Grepping the installed QML/JS finds no blend-mode property. The only other effect is `ColorEffect.qml`, a `MultiEffect { colorization: 1 }` that the comments call "a not very effective way to recolor things that can't be recolored". — [installed source](https://github.com/luisbocanegra/plasma-panel-colorizer)
- The README lists shadow only for shapes plus "Hide native panel shadow". The text/icon shadow is undocumented there. — [README](https://github.com/luisbocanegra/plasma-panel-colorizer)

**How foreground recoloring works and what it reaches (utils.js `applyFgColor`)**
- It walks visible children of each applet and, for `Text, ToolButton, Label, Canvas, Kirigami.Icon`, sets `child.color` (once modified) and `child.Kirigami.Theme.textColor = newColor` plus the colorSet. Symbolic (`-symbolic`/mask) icons drawn by `Kirigami.Icon` follow the theme textColor, so they recolor. Full-color icons do not, unless a per-widget "force" rule uses `method.mask` (sets `isMask = true`, which flattens the icon to a silhouette) or `method.multiEffect` (MultiEffect colorization). — [utils.js](https://github.com/luisbocanegra/plasma-panel-colorizer)
- README: "Force Text/Icon color" with a mask for symbolic icons and an effect for colorful icons; periodic re-application for widgets that reset colors (e.g. Global Menu); "Recolor applications System Tray icons" and "Replace applications system tray icons" (the latter requires the C++ plugin). — [README](https://github.com/luisbocanegra/plasma-panel-colorizer)
- Tray items with no own fg config inherit the tray container's fg color (`main.trayWidgetBgItem.fgColor`). — [CustomBackground.qml `fgColor`](https://github.com/luisbocanegra/plasma-panel-colorizer)

**Blur behind**
- "Blur behind custom background" requires building and installing the C++ plugin, which may break after system updates and need a rebuild. — [README](https://github.com/luisbocanegra/plasma-panel-colorizer). [local] The plugin is installed at `/usr/lib/qt6/qml/org/kde/plasma/panelcolorizer`.
- Implementation: the plasmoid builds a region mask (`panelColorizer.updatePanelMask(...)` with corner radii) and assigns it as the panel's blur mask when `blurBehind` is on. KWin's blur effect (or Better Blur DX) then blurs only that shape. — [main.qml / CustomBackground.qml](https://github.com/luisbocanegra/plasma-panel-colorizer)

**Presets and auto-loading (main.qml, utils.js `getPresetName`, configPresetAutoload.qml)**
- Panel states tracked: `fullscreenWindow, maximized, touchingWindow, activeWindow, visibleWindows, floating, activity`, with the fallback `normal`. Priority order is exactly that list. The first true state with a preset assigned wins, otherwise `normal`. — [utils.js `getPresetName`](https://github.com/luisbocanegra/plasma-panel-colorizer)
- Window tracking options: "Per screen" (`filterByScreen`, default true), "Active only" (`filterByActive`) and "Active window fallback" (`trackLastActive`). There is also a per-activity preset map. The UI warns: "Disable preset auto-loading before making changes to presets, unsaved preset settings will be lost". — [configPresetAutoload.qml](https://github.com/luisbocanegra/plasma-panel-colorizer)
- No wallpaper, brightness or luminance input exists anywhere in the plasmoid. Grepping the source for wallpaper, luminance or brightness returns nothing. — [installed source](https://github.com/luisbocanegra/plasma-panel-colorizer)
- External control over D-Bus. Each instance has its own name, e.g. `qdbus6 luisbocanegra.panel.colorizer.c337.w2346 /preset preset /path/to/preset/dir/`. Broadcast to all panels: `dbus-send --session --type=signal /preset luisbocanegra.panel.colorizer.all.preset string:"/path/to/preset dir/"`. Single properties can be set with dot notation through the `property` method, e.g. `stockPanelSettings.visible {"enabled": true, "value": false}`. The README cautions "There is no validation". — [README](https://github.com/luisbocanegra/plasma-panel-colorizer); service implementation in `contents/ui/tools/service.py` (methods `preset(s)`, `property(s)`, signals `preset_changed`, `property_changed`).

**[local] Current user setup (evidence for the halo problem)**
- `~/.config/panel-colorizer/presets/RedRog Clear dark-white-12`: widgets fg custom `#1d1c1a` (dark glyphs) **with foreground shadow enabled, color `#ffffff`, alpha 0.35, size 4, yOffset 1** (panel-level shadow `#ffffff` 0.35 size 4 offset 0 as well). With the hard-coded spread 0.35, this produces the white halo around dark glyphs.
- `RedRog Clear` (light glyphs): widget fg shadow black, alpha 0.05, size 4, y 1. The panel-level fg shadow is enabled with sourceType 1, meaning theme backgroundColor at alpha 1, not the `#000000` shown.
- `RedRog Frosted` / `RedRog Frosted dark`: fg shadow off, blurBehind on, bg alpha 0.35 (theme bg) / `#f7f6f3` at 0.55.
- The auto-loading map in `plasma-org.kde.plasma.desktop-appletsrc` is normal → "RedRog Clear dark-white-12", maximized and fullscreen → "RedRog Frosted dark".

### Inferences
- **Recommended preset recipe** (all values in the preset's `settings.json` or the UI):
  - *Dark-glyph preset (bright wallpaper strip)*: `widgets/trayWidgets/panel.normal.foregroundColor = {enabled:true, sourceType:0, custom:"#1d1d1f" (or near-black), alpha:1}`; **`shadow.foreground.enabled = false` on panel, widgets and tray**. Tint `panel.normal.backgroundColor = {enabled:true, sourceType:0, custom:"#f5f5f7" (light), alpha: from Q3 table}`; `blurBehind: true`.
  - *Light-glyph preset (dark or mid wallpaper strip)*: fg `#ffffff` (or ~#f5f5f5), alpha 1. Optional `shadow.foreground = {enabled:true, color:{sourceType:0, custom:"#000000", alpha:0.25–0.4}, size:2–3, xOffset:0, yOffset:1}`. Tint `#1d1d1f` (dark) at the alpha from Q3; `blurBehind: true`.
  - Keep `size` small (2–3). The fixed 35% spread turns large radii into a fat outline. A 1 px y-offset makes it read as a drop shadow instead of a glow.
- To avoid a doubled shadow, enable the fg shadow at one level only (widgets or panel), since both levels have their own `shadow.foreground`.
- Because auto-loading can't see the wallpaper, a small user service (systemd user unit or a KWin/Plasma script) should sample the wallpaper strip under the panel, compute luminance (Q3), and call `qdbus6 <instance> /preset preset <dir>` only when crossing a threshold **with hysteresis**. Pointing the auto-loader's `normal` slot at the currently chosen polarity preset (rewriting `presetAutoloading`) would let maximized/fullscreen still override. Alternatively, the `property` method could change just `widgets.normal.foregroundColor.custom`. That dot path is extrapolated from the README example and is not verified.
- Full-color tray icons (non-symbolic SNI icons) won't flip unless forced with mask/MultiEffect. macOS menu-bar extras are template (monochrome) images, so the force-mask route matches macOS best, at the cost of losing the icon's color.

### Gaps
- The KDE Store page's "Contrast correction" option (seen only in a search snippet) was not verified in the README or the v8.0.0 source.
- Not verified whether dot-notation `property` works for nested keys under `widgets.normal...` or only for `stockPanelSettings`.
- Whether the panel-level `shadow.foreground` draws anything (its `target.applet` may be null for the panel element) was not tested.

## Q2. Existing KDE work on wallpaper-adaptive panels; blur parameters to emulate a vibrant material

### Takeaway
Plasma 6 has no built-in "glyph color follows wallpaper brightness" feature. Its "Adaptive" opacity reacts to touching/maximized windows, not to the wallpaper. The closest precedent is Latte Dock, which used a brightness formula to pick black or white text. For the material itself, Better Blur DX adds brightness, contrast and saturation controls on top of KWin's blur, which can approximate Apple's "blur + luminosity/saturation" material.

### Cited Findings
- KDE bug 402115 (Latte Dock): Latte first used WCAG relative luminance. The developer disliked that it "does not specify a threshold", switched to the W3C AERT brightness formula, and the issue was resolved as FIXED. Plain-color wallpapers were not supported. — [KDE bug 402115](https://bugs.kde.org/show_bug.cgi?id=402115)
- A bug report where panel items did not follow the wallpaper-derived accent color (a visibility problem with translucent panels) was closed NOT A BUG. — search summary of [bugs.kde.org](https://bugs.kde.org/show_bug.cgi?id=457861) (low confidence about which exact bug; snippet-level)
- Plasma "Adaptive" opacity: the panel goes opaque when windows touch it ([bug 465470](https://bugs.kde.org/show_bug.cgi?id=465470)). There were regressions with maximized windows in 6.1 ([bug 488834](https://bugs.kde.org/show_bug.cgi?id=488834)). Adaptive was extended to non-normal (auto-hide) panels in Aug 2025 ([bug 507209](https://bugs.kde.org/show_bug.cgi?id=507209)). Blur persisting on opaque panels was reported on 6.4.3 ([bug 507904](https://bugs.kde.org/show_bug.cgi?id=507904)).
- Better Blur DX (xarblu/kwin-effects-better-blur-dx): a continuation of Better Blur (taj-ny/kwin-effects-forceblur), itself a fork of the Plasma 6 blur effect. Features: force blur, "Adjustable blur brightness, contrast and saturation", adjustable corner radius, refraction. Supports Plasma 6.5, 6.6 and 6.7 and must be rebuilt for the exact KWin version. — [GitHub README](https://github.com/xarblu/kwin-effects-better-blur-dx)
- An unofficial docs mirror says brightness/saturation are applied as a contrast pass on blurred regions, that by default the effect respects contrast parameters supplied by windows (e.g. Plasma panels), and that a "Force Contrast Parameters" option overrides them. — [search summary of mintlify mirror](https://www.mintlify.com/xarblu/kwin-effects-better-blur-dx) (page now returns 410; unverified)
- [local] kwinrc `[Effect-better-blur-dx]`: `BlurStrength=12, NoiseStrength=2, Brightness=100, Contrast=100, Saturation=100, CornerRadius=12, RefractionStrength=0, BlurDocks=false, BlurMatching=true` (WindowClasses list), and stock `blurEnabled=true` alongside `better_blur_dxEnabled=true`, `contrastEnabled=false`.
- Apple HIG Materials: the regular material "blurs and adjusts the luminosity of background content to maintain legibility". Use system vibrant colors so symbols aren't "too dark, bright, saturated, or low contrast". Avoid quaternary labels on thin/ultra-thin materials. Consider a dimming layer behind clear Liquid Glass. — [Apple HIG: Materials](https://developer.apple.com/design/human-interface-guidelines/materials)

### Inferences
- To emulate a vibrant menu-bar material: a strong blur (BlurStrength ~10–15) so the strip averages toward a smooth field (this also makes the luminance measurement stable), **Saturation >100 (e.g. 120–150)** for the "vibrant" look, small Noise (1–2) against banding, and the polarity-specific tint layer from Panel Colorizer (`backgroundColor.alpha`) doing the luminosity work. Brightness/Contrast are global for all matched surfaces, so it's better to keep them near 100 and do polarity-dependent darkening/lightening with the tint.
- Running the stock blur and Better Blur DX at once may be redundant or conflicting. Check upstream guidance (unverified).
- Since the panel's blur region is supplied by the Panel Colorizer C++ plugin through the standard blur mechanism, it should be handled by whichever blur effect is active, and `BlurDocks` relates to force-blur matching. Not verified.

### Gaps
- No authoritative docs found for Better Blur DX value ranges/defaults or the exact semantics of "Force Contrast Parameters" (mirror is gone; would need to read `src/` in the repo).
- No existing maintained "panel follows wallpaper luminance" script for Plasma 6 was found.

## Q3. Contrast criteria and formulas: choosing glyph polarity and tint alpha

### Takeaway
Measure the blurred wallpaper strip under the panel as luminance Y. With pure white vs pure black glyphs, **WCAG's equal-contrast crossover is Y ≈ 0.179, APCA's is Y ≈ 0.342** (computed from the published APCA-W3 constants, where both polarities give |Lc| ≈ 54.5). Target about **Lc 60** (APCA minimum for non-body content text) for clock/menu text and **Lc 45** for icons. Then pick the tint alpha that brings the composite strip to that target.

### Cited Findings
- APCA-W3 (Beta 0.1.9, SA98G 0.0.98G-4g) constants: `mainTRC 2.4; sRco 0.2126729, sGco 0.7151522, sBco 0.0721750; normBG 0.56, normTXT 0.57, revTXT 0.62, revBG 0.65; blkThrs 0.022, blkClmp 1.414; scaleBoW = scaleWoB = 1.14; loBoWoffset = loWoBoffset = 0.027; deltaYmin 0.0005; loClip 0.1`. — [apca-w3.js](https://raw.githubusercontent.com/Myndex/apca-w3/master/src/apca-w3.js)
  - `Y = 0.2126729·(R/255)^2.4 + 0.7151522·(G/255)^2.4 + 0.0721750·(B/255)^2.4`. If Y < 0.022, then Y += (0.022 − Y)^1.414.
  - Dark text on light bg (BoW): `S = (Ybg^0.56 − Ytxt^0.57)·1.14; Lc = S<0.1 ? 0 : (S − 0.027)·100`.
  - Light text on dark bg (WoB): `S = (Ybg^0.65 − Ytxt^0.62)·1.14; Lc = S>−0.1 ? 0 : (S + 0.027)·100` (negative Lc).
  - The license is the W3 license, restricted to web content use per the source header. Note this for reimplementation. — [apca-w3.js](https://raw.githubusercontent.com/Myndex/apca-w3/master/src/apca-w3.js)
- APCA level guidance: Lc 90 preferred body text; Lc 75 minimum body columns; **Lc 60 minimum for content text that isn't body text**; **Lc 45** for large/heavy text and fine-detail pictograms/outline icons; **Lc 30** absolute minimum for spot text and solid icons (≥ ~5.5 px solid); Lc 15 minimum discernible non-text. Add 15 for AAA-equivalent. APCA is perceptually uniform across polarity, while WCAG 2.x overstates contrast for dark colors. — [APCA in a Nutshell](https://git.apcacontrast.com/documentation/APCA_in_a_Nutshell)
- WCAG 2.x relative luminance and contrast ratio: `(L1+0.05)/(L2+0.05)`. 4.5:1 for normal text, 3:1 for large text and UI graphics. — WCAG 2.x definitions (https://www.w3.org/TR/WCAG21/#dfn-contrast-ratio). Formula is standard; page not re-fetched in this session.
- Latte Dock chose the W3C AERT brightness formula over luminance because luminance "does not specify a threshold". — [KDE bug 402115](https://bugs.kde.org/show_bug.cgi?id=402115)

**Derived numbers (computed in this session with the APCA constants above, white glyph Y=1, black glyph Y=0)**
- Equal-contrast crossover: WCAG `L* = sqrt(1.05·0.05) − 0.05 = 0.1791`. APCA `Y* ≈ 0.342` (|Lc| = 54.5 both ways).
- Background Y limits per target:

| Target | White glyph OK if strip Y ≤ | Black glyph OK if strip Y ≥ |
|---|---|---|
| Lc 30 | 0.594 | 0.140 |
| Lc 45 | 0.434 | 0.254 |
| Lc 60 | 0.293 | 0.397 |
| Lc 75 | 0.172 | 0.567 |

  Between Y 0.293 and 0.397, neither polarity reaches Lc 60 without a tint. That band is exactly where the tint is needed.
- WCAG equivalents: white text 4.5:1 needs L_bg ≤ 1.05/4.5 − 0.05 = 0.183 (3:1 → ≤ 0.30). Black text 4.5:1 needs L_bg ≥ 0.175 (3:1 → ≥ 0.10).
- **Tint alpha formula.** Qt/KWin normally blend in gamma-encoded sRGB, so work in encoded values v = Y^(1/2.4) (APCA's simple TRC):
  - Light glyphs with dark tint (v_t): `α ≥ (v_bg − v_target)/(v_bg − v_t)`
  - Dark glyphs with light tint (v_t): `α ≥ (v_target − v_bg)/(v_t − v_bg)`
  - where v_target = Y_target^(1/2.4) from the table above. If blending happens in linear light instead, use Y in place of v.
- Example α table (dark tint #1d1d1f, v=0.114; light tint #f5f5f7, v=0.96; sRGB-space blend):

| Strip Y | White glyph Lc60 α (dark tint) | White Lc45 α | Black glyph Lc60 α (light tint) | Black Lc45 α |
|---|---|---|---|---|
| 0.05 | 0 | 0 | 0.58 | 0.41 |
| 0.15 | 0 | 0 | 0.45 | 0.22 |
| 0.25 | 0 | 0 | 0.30 | 0.01 |
| 0.34 | 0.07 | 0 | 0.13 | 0 |
| 0.45 | 0.19 | 0.02 | 0 | 0 |
| 0.60 | 0.30 | 0.15 | 0 | 0 |
| 0.80 | 0.39 | 0.26 | 0 | 0 |

### Inferences
- **Decision rule:** compute Y on the *blurred* strip (blur radius ≈ the KWin blur so you measure what the eye sees). Use a robust statistic per polarity: for white glyphs, check the ~90th-percentile Y (the bright patches hurt them); for black glyphs, the ~10th percentile. Choose white if Y_mean < ~0.34 (APCA crossover), else black. Add **hysteresis** (e.g. switch to dark glyphs at Y > 0.38, back to light at Y < 0.30) to prevent flicker on slideshows/dynamic wallpapers.
- Then set the tint alpha from the formula for Lc 60 with a floor (e.g. α ≥ 0.10–0.15 so the bar always reads as a material) and a ceiling (≈0.6) so it stays translucent. Your current presets (light tint 0.55 in "Frosted dark", 0.12 white in "Clear dark-white-12") fall inside this range.
- APCA's polarity asymmetry means light glyphs are usable on brighter backgrounds than WCAG's 0.179 crossover suggests. That matches macOS keeping white menu-bar text over fairly bright wallpapers with a darkening tint.

### Gaps
- KWin 6 with color management/HDR may composite in linear light. Which space applies to translucent panel layers on the user's setup (SDR vs HDR) is unverified, and it changes α noticeably.
- Apple does not publish the exact thresholds or tint values macOS uses for menu-bar polarity switching. None were found.

## Q4. Why light halos around dark text look dated vs. dark drop shadows under light text

### Takeaway
Sources treat dark, small-offset, translucent shadows under light text over images as a standard technique. Heavy or glowing effects are described as dated. The deeper reason is physical: shadows are darker than their surroundings, so a light "shadow" behind dark glyphs reads as an emission/glow (a 2000s-era outer-glow look) rather than depth. Apple's own approach relies on materials, vibrancy and dimming layers instead of glyph halos.

### Cited Findings
- CSS reference (summary): a faint dark shadow can help light text over images, but contrast should still be met by the background itself. Heavy shadows look dated on body text, and small offsets with translucent colors look more polished. — [codeshack text-shadow reference](https://codeshack.io/references/css/text-shadow/) (stylistic opinion, not a usability study)
- Cal Lutheran brand guide: when a headline is almost legible, add a slight outer glow **using multiply blend mode with a black glow**, tuned so no sharp shadow appears. That is a darkening glow, not a light halo. — [Cal Lutheran: Text on Photos](https://www.callutheran.edu/offices/marketing/brand/photos/text-on-photos.html)
- uxdesign.cc: a scrim (semi-transparent overlay) is "the most popular solution" for text over images. Gradient scrims can fail mid-way. — [Techniques to Display Text over Background Images](https://uxdesign.cc/techniques-to-display-text-over-background-images-b089de1cc8bc)
- Apple HIG: legibility comes from materials that blur and adjust luminosity, vibrant system colors, and optional dimming layers behind clear glass. No glyph halos are prescribed. — [Apple HIG: Materials](https://developer.apple.com/design/human-interface-guidelines/materials)

### Inferences
- In Panel Colorizer terms: never give dark glyphs a light foreground shadow (the user's `#ffffff` α0.35 size 4 is exactly the dated halo). Let the light tint at the Q3 alpha provide the contrast. For light glyphs, a black shadow at α 0.25–0.4, size 2–3, y +1 mirrors the iOS status bar and macOS desktop-label convention.
- The hard-coded `spread: 0.35` makes even a dark shadow look outline-like at larger sizes, which is another reason to keep size ≤ 3.

### Gaps
- No authoritative design-critique source (e.g. NN/g or Apple) explicitly calls light halos around dark text "dated" was found. That claim rests on practitioner opinion and the physical-shadow argument above.
- No primary Apple documentation describing the macOS desktop icon-label shadow or the iOS status bar shadow parameters was found.
