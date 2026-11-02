# macOS menu bar rendering (Big Sur 11 – Sequoia 15): material, glyph color, vibrancy, shadows

Scope note: Apple has never published a technical spec of the menu bar's background or glyph rendering. The HIG and AppKit docs describe the general material/vibrancy system, not the menu bar. Nearly everything menu-bar-specific below is community observation or vendor write-ups. Each finding is labelled [DOC] (Apple documentation/WWDC), [RE] (code or reverse engineering), or [OBS] (user/developer/vendor observation).

## 1. What material is drawn behind the bar (material, blending, blur, saturation, tint)

### Takeaway
Since Big Sur the bar is a translucent, blurred backdrop tinted by the top strip of the desktop picture. Pre-Big Sur bars were nearly opaque light grey or near-black. Apple documents no public "menu bar" NSVisualEffectView material, and I found no published blur radius, saturation factor or fill alpha for the real bar. The bar is drawn by a WindowServer-owned "Menubar" window, not by apps.

### Cited Findings
- [DOC] The public `NSVisualEffectView.Material` enum has 14 active cases (titlebar, selection, menu, popover, sidebar, headerView, sheet, windowBackground, hudWindow, fullScreenUI, toolTip, contentBackground, underWindowBackground, underPageBackground). There is no menu-bar case. The deprecated cases are appearanceBased, light, dark, mediumLight and ultraDark. `.menu` is described only as "The material for menus" (meaning pull-down menus, not the bar). — [Apple: NSVisualEffectView.Material](https://developer.apple.com/documentation/appkit/nsvisualeffectview/material-swift.enum)
- [RE] Raw values: Menu = 5, HeaderView = 10. Selection and Titlebar date from 10.10, Menu from 10.11, HeaderView from 10.14. No MenuBar constant appears. — [window-vibrancy crate docs](https://docs.rs/window-vibrancy/latest/window_vibrancy/enum.NSVisualEffectMaterial.html)
- [RE] NSVisualEffectView accepts undocumented material values 0–37, but nobody has named or characterised them, and none is identified as the menu bar material. — [Michael Tsai, "Periodic Table of NSVisualEffectView" (citing M. Gansrigler)](https://mjtsai.com/blog/?p=35768)
- [DOC] macOS has two blending modes, "behind window and within window". — [Apple HIG Materials (JSON)](https://developer.apple.com/tutorials/data/design/human-interface-guidelines/materials.json)
- [RE] Window structure on Sequoia: a single WindowServer-owned window named `Menubar` draws the bar background and the frontmost app's menus. Each status item lives in its own small window on a layer above it. The bar's blur and tint can only be suppressed by putting a panel between the two, at sub-level 1 via the private `SLSSetWindowSubLevel`. — [MenuBarClear (GitHub)](https://github.com/aafs-ops/MenuBarClear)
- [OBS/vendor] Before Big Sur the bar was opaque, light grey in light mode and near-black in dark mode. Big Sur made it "translucent, tinted by the top edge of the wallpaper", and Monterey through Sequoia kept that. With Reduce Transparency on, the blur is replaced by a solid light-grey or near-black fill. — [publicspace.net (Boring Old Menu Bar vendor)](https://www.publicspace.net/blog/change-menu-bar-color-mac/)
- [OBS] "In Catalina, the PNG was always visible due to the menu bar being more opaque. However, in Big Sur, when a light wallpaper is used, the PNG symbol is not legible… the menu bar adapting to the wallpaper instead of the Aqua theme." — [Apple Developer Forums 662322](https://developer.apple.com/forums/thread/662322)
- [OBS] The menu bar has no fixed color and reflects whatever is behind it. — [MacMost](https://macmost.com/10-ways-to-customize-the-look-of-macos-big-sur.html)
- [RE, indirect reference values only] An open-source private-API recreation of NSVisualEffectView uses CAFilters `gaussianBlur` (default radius 30) and `colorSaturate` (default 2.5), plus darken/lighten compositing. Its presets: light = backdrop white 0.97 @ α0.70 over tint 0.94; dark = white 0.12 @ α0.45 over tint 0.16 with lighten; ultraDark = 0.12 @ α0.80. The author says it does not reproduce the system's "desktop bleed blending". These numbers are one developer's approximation, not measurements of the menu bar. — [torarnv gist](https://gist.github.com/torarnv/8b915957196d1a88e6e2fa81c67be8cb)
- [OBS/vendor] Tahoe (26) removes the bar background by default. A "Show menu bar background" toggle, added in beta 2, restores the Sequoia-style frosted layer. — [9to5Mac](https://9to5mac.com/2025/06/23/macos-tahoe-26-beta-2-includes-toggle-to-restore-menu-bar-background/); [MacVector](https://macvector.com/2025/09/17/macos-tahoe-and-macvector-18-8/); [Apple Support](https://support.apple.com/guide/mac-help/change-menu-bar-settings-mchlad96d366/mac)

### Inferences
- The bar behaves like a behind-window material sampling the desktop-picture windows: a blur, a saturation boost, and a light or dark fill. The fill is visibly much thinner than the pre-Big Sur fill, which is why a light wallpaper yields a pale bar and a dark wallpaper a dark bar. The radius-30 / 2.5× saturation figures from the gist match Apple's usual material look and are reasonable starting values for an imitation, but they are not confirmed for the menu bar.
- Because the bar is a separate WindowServer window, and status items are separate windows on top, glyphs are composited over the already-blurred backdrop.

### Gaps
- No source gives the actual blur radius, saturation, or the alpha of the white or black fill of the Big Sur–Sequoia menu bar. Measuring would need pixel sampling of screenshots over known solid wallpapers, which I found no published write-up of.
- The private material identifier for the bar (if it is an NSVisualEffectView material at all, rather than a WindowServer/SkyLight backdrop) is undocumented.

## 2. How glyph and title color is chosen (wallpaper-driven appearance)

### Takeaway
Since Big Sur, the menu bar's light or dark rendering follows the brightness of the wallpaper behind it, independently of the system Light/Dark setting: black text over bright wallpapers, white over dark. This is widely observed but not documented by Apple. No threshold or algorithm has been published. Status items receive a matching `effectiveAppearance`, and template images are tinted to match.

### Cited Findings
- [OBS] The menu bar appearance is independent of the system light/dark setting and is decided by the wallpaper's colour. SwiftUI `MenuBarExtra` labels don't reliably report their colour scheme. Re-rendering on `effectiveAppearance` changes showed about 0.4 s lag. — [Zenn (kyome, Japanese)](https://zenn.dev/kyome/articles/58d89dc746e0dc)
- [OBS] A developer guessed that macOS 11 averages the brightness of the desktop image to choose dark or light text, and "sometimes guesses wrong". — reported via search snippet of [tyler.io "Surtainly Not"](https://tyler.io/surtainly-not/) (page now 404, so not directly verified)
- [OBS] A dynamic wallpaper flipped menu bar text from black to white as the image darkened in the evening. A third-party status icon stayed black, because it was not a template image. — [DEVONtechnologies forum](https://discourse.devontechnologies.com/t/menu-bar-icon-is-always-black-in-big-sur-even-with-dark-desktop-menu-bar/59525)
- [OBS] Users force black text by adding a light strip across the top of the wallpaper. A light wallpaper makes the menu bar "lighter/screened-back with black text". — [Apple Community (JP) 252698975](https://discussions-jp-prz.apple.com/thread/252698975); [Apple Community 252221191](https://discussions-cn-prz.apple.com/thread/252221191)
- [OBS] Each display can have a different menu bar appearance, because each wallpaper differs. One global check is therefore wrong on multi-monitor setups. There is no public API to query the bar's light or dark state, and reading `AppleInterfaceStyle` doesn't match the bar. — [Apple Developer Forums 662322](https://developer.apple.com/forums/thread/662322)
- [RE/OBS] The practical way to follow the bar is to observe the status button's `effectiveAppearance` (KVO) and re-render with dynamic colours such as `labelColor`. Drawing attributed strings into a static image doesn't resolve dynamic colours. — [Stack Overflow 65157562 (mirror)](https://kiwix.lema.org/stackoverflow.com_en_all_2023-11/questions/65157562/nsappearance-is-not-updating-when-toggling-dark-mode)
- [OBS] On macOS 26 the bar takes its tint from the wallpaper, so a menu that copied the status button's appearance opened light in Dark Mode over a bright wallpaper. This confirms the status button's `effectiveAppearance` reflects the wallpaper, not the system setting. — [ThinkWatch-Lite PR #286](https://github.com/ThinkWatchProject/ThinkWatch-Lite/pull/286)
- [DOC/OBS] Template images (black plus alpha, `isTemplate = true`) are the supported way to let the system colour status icons. They show as dark normally and white on a dark bar or when highlighted. Colour icons are displayed unmodified. — [Apple Dev Forums 662322](https://developer.apple.com/forums/thread/662322); [mackuba.eu, menu bar icons on Yosemite](https://mackuba.eu/2015/03/04/how-to-add-icons-to-menu-bar-on-yosemite/)
- [RE] MenuBarClear reports that macOS sometimes picks the wrong black/white for status icons and recolours them, while coloured icons keep their colours. — [MenuBarClear](https://github.com/aafs-ops/MenuBarClear)
- [OBS/vendor] On Tahoe, macOS still picks white or black text from the picture's brightness behind the bar. Some users say the light-strip trick became less reliable. — [publicspace.net](https://www.publicspace.net/blog/change-menu-bar-color-mac/)

### Inferences
- Effectively there are two discrete states, a light bar (dark glyphs, Aqua/vibrantLight-like) and a dark bar (light glyphs, darkAqua/vibrantDark-like), chosen per display from a luminance estimate of the wallpaper strip under the bar. No hysteresis, threshold value or sampling region is documented.
- The system appearance still matters for the bar's fill when Reduce Transparency is on (solid grey or near-black per the system appearance). With transparency on, wallpaper brightness dominates.

### Gaps
- No source states the luminance threshold, the sampled region (whole image versus the top strip) or the averaging method. Apple has never documented "menu bar adapts to the desktop picture" in the HIG. The HIG menu-bar page could not be fetched as text, and the Materials page does not mention the menu bar.

## 3. Vibrancy: are glyphs blended (plus-darker / plus-lighter) rather than flat?

### Takeaway
AppKit vibrancy is a special blend of foreground with the material behind it, using a mode such as PlusD/PlusL, color burn or dodge. It applies to grayscale and template content and to `labelColor` inside visual effect views with vibrant appearances. Status-item template images and menu titles are system-drawn and almost certainly vibrant, but no source pixel-verifies the exact blend mode used for menu bar glyphs on Big Sur–Sequoia.

### Cited Findings
- [DOC, WWDC 2014 #220] Vibrancy is "a special blend mode where we're taking two different pixels, combining them together". The underlying blend could be "a Linear Burn, a Color Dodge, PlusD, PlusL". "In order to get any sort of Vibrancy, you have to use the vibrant appearance". Vibrancy requires being inside a VisualEffectView. `labelColor` and `secondaryLabelColor` were introduced for vibrant text. — [WWDC 2014 Session 220 transcript (nonstrict index)](https://nonstrict.eu/wwdcindex/wwdc2014/220/)
- [DOC] "Depending on configuration and system settings, system views and controls use vibrancy to make foreground content stand out against any background." macOS provides "vibrant versions of all system colors". — [Apple HIG Materials](https://developer.apple.com/tutorials/data/design/human-interface-guidelines/materials.json)
- [OBS/RE] Vibrancy applies only to grayscale or label-coloured content (custom views must override `allowsVibrancy`). Colour images and custom RGB labels are not vibrant. From 10.14, an inherited visual effect view picks Vibrant Light or Vibrant Dark to match the appearance. Measured pixel example: a label reads R38 G38 B38 under Aqua and R44 G46 B44 (green-tinted from the background) under Vibrant Light. — [mackuba.eu, Dark Side of the Mac pt.1](https://mackuba.eu/2018/07/04/dark-side-mac-1/)
- [RE] Math: plusDarker = max(0, src + dst − 1) per channel, which darkens. plusLighter = min(1, src + dst), which lightens. — [Nil Coalescing, Blend modes in SwiftUI](https://nilcoalescing.com/blog/BlendModesInSwiftUI)
- [RE/OBS] `labelColor` values measured at runtime: light is black at α≈0.847 (216/255) and dark is white at α≈0.847. `secondaryLabelColor`: light black α≈0.498, dark white α≈0.549. — [andrejilderda gist](https://gist.github.com/andrejilderda/8677c565cddc969e6aae7df48622d47c); corroborated by fg0 = 0 0 0 216 in [Apple Dev Forums 771592](https://developer.apple.com/forums/thread/771592)
- [DOC] `NSAppearance.Name.vibrantLight` / `vibrantDark` exist and are meaningful only inside visual effect views. — [Apple NSAppearance.Name](https://developer.apple.com/documentation/appkit/nsappearance/name-swift.struct)

### Inferences
- In a light bar, glyphs most likely render as label-colour black (about 85% alpha) with a darkening vibrant blend (plus-darker family). The glyph picks up a little of the wallpaper hue and reads as a deep, slightly tinted grey rather than pure black. In a dark bar, the glyph is white at about 85% with a lightening blend (plus-lighter family). Treat this as a reasonable model, not a verified spec.
- The non-opaque label alpha plus the vibrant blend is why glyphs look "embedded" in the bar rather than pasted on it.

### Gaps
- No pixel-level analysis specific to menu bar glyphs on Big Sur–Sequoia was found that proves which blend mode (plus-darker versus a color-burn variant) or which exact alphas are used.

## 4. Shadow, halo or glow on glyphs and text (light versus dark)

### Takeaway
I found no source, whether Apple documentation, WWDC, reverse engineering or pixel analysis, stating that Big Sur–Sequoia applies any shadow, halo or glow to menu bar text or status glyphs in either appearance. Legibility comes from the blurred, filled backdrop plus the black/white flip and vibrancy. Developers who wanted extra legibility for non-template icons added shadows to their own images themselves.

### Cited Findings
- [OBS] A developer, after Big Sur made his PNG illegible on light wallpapers, added a shadow to the icon himself and asked for an API to apply it only when the bar is light. No answer or Apple response followed. This implies the system adds no shadow to app glyphs. — [Apple Dev Forums 662322](https://developer.apple.com/forums/thread/662322)
- [OBS] Searches across Apple Community, MacRumors and vendor docs surfaced no description of a built-in menu bar text shadow. Vendor pages describing menu bar rendering in detail don't mention one. — [publicspace.net](https://www.publicspace.net/blog/change-menu-bar-color-mac/); [MenuBarClear](https://github.com/aafs-ops/MenuBarClear)
- [OBS] On Tahoe, with no background, users report menu text becoming "completely unreadable" over light windows or wallpapers. The fix offered is the background toggle, not a shadow. — [MacRumors thread](https://forums.macrumors.com/threads/macos-tahoe-a-pattern-of-poor-usability-and-design-regression.2476149)

### Inferences
- The best-supported answer is that Big Sur–Sequoia uses no shadow or halo on menu bar glyphs in either the light or dark state. The absence of reports is weak evidence, but it is consistent across sources and with the developer having to roll his own shadow.

### Gaps
- No primary source explicitly states "no shadow". Whether Tahoe's backgroundless bar adds a subtle glyph shadow is not established by any source I found. I could not verify it and it is out of scope (pre-Liquid Glass).

## 5. Opacity and tint of the bar background in light versus dark

### Takeaway
Not documented. Qualitatively, the Big Sur–Sequoia bar is a light or dark translucent fill over a blurred, saturated wallpaper, much more transparent than Catalina's. With Reduce Transparency it becomes an opaque light grey or near-black.

### Cited Findings
- [OBS/vendor] Opaque light grey / near-black before Big Sur and under Reduce Transparency. Translucent and wallpaper-tinted from Big Sur through Sequoia. — [publicspace.net](https://www.publicspace.net/blog/change-menu-bar-color-mac/)
- [RE, analogue only] The gist's light preset is white 0.97 @ α0.70 and its dark preset is 0.12 @ α0.45 (lighten), with blur 30 and saturation 2.5. These approximate generic Apple materials, not the menu bar. — [torarnv gist](https://gist.github.com/torarnv/8b915957196d1a88e6e2fa81c67be8cb)
- [OBS] Dark-mode window materials are uniformly tinted by the average desktop colour behind them ("desktop tinting"), which Graphite accent disables. This shows Apple's materials sample the wallpaper's average colour. — [mackuba.eu](https://mackuba.eu/2018/07/04/dark-side-mac-1/)

### Gaps
- No measured alpha for the menu bar's white or black fill in either state was found. Pixel-sampling screenshots over pure black, white and mid-grey wallpapers would answer this, and no published analysis exists.
