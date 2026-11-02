#!/usr/bin/env python3
"""RedRog look for ROG Control Center (Slint UI), applied to its source tree
before building. Idempotent; run from the asusctl source directory:

    python3 redrog-theme.py rog-control-center/ui

- Every color the UI takes from Slint's Palette comes from a RedRog palette
  global (RR) instead, in the system's light or dark mode: near-black or
  warm white surfaces, text in the opposite tone, ROG red accent.
  The window and card backgrounds are translucent and the window asks KWin
  for its native blur (the one Dolphin and kitty get), with crisp text.
- The sidebar is replaced by sidebar.slint: a macOS-style source list on the
  same glass as the page, with ROG accents (icons from icons/, a red glass pill on the active page,
  section titles, the ROG brand) and a modern quit button.
- The std widgets (switches, sliders, buttons, combo boxes) use Slint's
  Cupertino style, the macOS-like one, instead of Fluent.
"""
import pathlib
import re
import shutil
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import fans  # noqa: E402

ui = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else "rog-control-center/ui")
here = pathlib.Path(__file__).resolve().parent

RR = """
// RedRog palette (packages/rog-control-center/redrog-theme.py), in the
// system's light or dark mode: Slint reads it from the desktop portal and
// follows its changes, so the window turns with RedRog's light/dark switch
export global RR {
    out property <bool> light: Palette.color-scheme == ColorScheme.light;
    // veils and hairlines over the glass: white on dark, black on light
    out property <color> ink: light ? #000000 : #ffffff;
    // the strongest text (hovered, selected): white on dark, black on light
    out property <color> emphasis: light ? #000000 : #ffffff;
    out property <color> background: ink.with-alpha(0.05);
    out property <color> foreground: light ? #2a2826 : #efeeeb;
    // the window glass: the same tone and opacity as the title bar and the
    // other windows (modules/window-decoration)
    out property <color> alternate-background: light ? #f0eee9c4 : #1c1c1cc4;
    out property <color> alternate-foreground: foreground;
    out property <color> control-background: ink.with-alpha(0.07);
    out property <color> control-foreground: foreground;
    out property <color> accent: light ? #d22630 : #ef3340;
    out property <color> accent-background: accent;
    out property <color> accent-foreground: #ffffff;
    out property <color> selection-background: accent.with-alpha(0.22);
    out property <color> selection-foreground: light ? #2a2826 : #ffffff;
    out property <color> border: ink.with-alpha(light ? 0.12 : 0.09);
    // softer text (APCA Lc 60 on either glass), the sidebar's icons and labels
    out property <color> dim: light ? #6b6660 : #888680;
    out property <color> soft: light ? #4a4743 : #c9c7c2;
    out property <color> strong: light ? #2a2826 : #dddbd6;
    out property <color> popup: light ? #f7f6f3f5 : #1c1c1cf5;
    // the window's own background: Slint clears the window with this color
    // without premultiplying its alpha, while Wayland expects premultiplied
    // pixels, so it is given premultiplied (77 % of #1c1c1c = #161616, of
    // #f0eee9 = #b9b7b3) to land on the very tone of the title bar
    out property <color> window: light ? #b9b7b3c4 : #161616c4;
}
"""

QUIT_OLD = re.compile(r"\n([ \t]*)Button \{\n\s*height: 40px;\n\s*width: side-bar\.width;\n"
                      r"\s*text: @tr\(\"Quit App\"\);\n\s*clicked\(\) => \{\n\s*root\.exit-app\(\);\n"
                      r"\s*\}\n\s*\}")


def add_import(text: str, names: str, source: str) -> str:
    """adds an import after the last import statement (single- or multi-line)"""
    found = list(re.finditer(r'import\s*\{[^}]*\}\s*from\s*"[^"]*";', text))
    at = found[-1].end() if found else 0
    return text[:at] + f'\nimport {{ {names} }} from "{source}";' + text[at:]


# Slint controls replaced by the RedRog ones (same API). common.slint keeps
# Slint's Button for its Dialog (dialog-button-role only works there).
SWAP = {"Button": "RRButton", "Switch": "RRSwitch", "Slider": "RRSlider",
        "ComboBox": "RRComboBox", "CheckBox": "RRCheckBox", "LineEdit": "RRLineEdit",
        "GroupBox": "RRGroupBox", "ScrollView": "RRScrollView"}

SECTION = re.compile(
    r"(?P<i>[ \t]*)Rectangle \{\n\s*background: RR\.alternate-background;\n\s*border-color: RR\.border;\n"
    r"\s*border-width: 1px;\n\s*border-radius: \d+px;\n\s*height: 36px;\n\s*Text \{\n"
    r"\s*font-size: 16px;\n\s*color: RR\.control-foreground;\n"
    r"\s*horizontal-alignment: TextHorizontalAlignment\.center;\n\s*text: (?P<t>@tr\([^;]*\));\n\s*\}\n\s*\}")


def restyle(f: pathlib.Path, text: str) -> str:
    # std controls -> RedRog controls
    for m in list(re.finditer(r'import \{([^}]*)\} from "std-widgets.slint";', text)):
        names = [n.strip() for n in m.group(1).split(",") if n.strip()]
        swap = [n for n in names if n in SWAP and not (f.name == "common.slint" and n == "Button")]
        if swap:
            keep = [n for n in names if n not in swap]
            line = 'import { %s } from "std-widgets.slint";' % ", ".join(keep)
            line += '\nimport { %s } from "widgets/rr.slint";' % ", ".join(f"{SWAP[n]} as {n}" for n in swap)
            text = text.replace(m.group(0), line)
    # the same breathing room as About on every page: the first padding of the
    # page (About keeps its own, which its inner boxes add to)
    if f.parent.name == "pages" and f.name not in ("about.slint", "fans.slint"):
        text = re.sub(r"padding: 1[02]px;", "padding: 28px;\n            padding-top: 22px;", text, count=1)
    # section titles: a ROG red bar and spaced capitals, left-aligned
    if SECTION.search(text):
        text = SECTION.sub(lambda m: f"{m.group('i')}RRSection {{\n{m.group('i')}    text: {m.group('t')};\n{m.group('i')}}}", text)
        if "RRSection" not in text.split("component", 1)[0]:
            text = add_import(text, "RRSection", "widgets/rr.slint")
    # help and reset: round icon buttons instead of Slint's text buttons
    if "StandardButtonKind.help" in text or "StandardButtonKind.reset" in text:
        text = re.sub(r"StandardButton \{\n(\s*)kind: StandardButtonKind\.help;", r'RRIconButton {\n\1glyph: "?";', text)
        text = re.sub(r"StandardButton \{\n(\s*)kind: StandardButtonKind\.reset;", r'RRIconButton {\n\1glyph: "↺";', text)
        text = add_import(text, "RRIconButton", "widgets/rr.slint")
    # rounded cards (macOS) instead of square boxes
    text = re.sub(r"border-radius: [24]px;", "border-radius: 10px;", text)
    # fan curve point labels: a dark glass tag with readable text (the
    # original dims the whole tag, text included, to 30 %)
    text = text.replace("""                background: RR.control-foreground;
                opacity: 0.3;
                border-radius: 12px;""", """                background: #000000b8;
                border-width: 1px;
                border-color: RR.accent.with-alpha(0.4);
                border-radius: 12px;""")
    # untranslated notice and battery states from the kernel
    text = text.replace('text: " WIP: some features like notifications are not complete";',
                        'text: @tr("WIP: some features like notifications are not complete");')
    text = text.replace("text: SystemPageData.battery_status;", """text: SystemPageData.battery_status == "Charging" ? @tr("Charging")
                                : SystemPageData.battery_status == "Discharging" ? @tr("Discharging")
                                : SystemPageData.battery_status == "Full" ? @tr("Full")
                                : SystemPageData.battery_status == "Not charging" ? @tr("Not charging")
                                : SystemPageData.battery_status;""")
    # popups stay solid so they read well over the glass
    text = text.replace("border-color: RR.accent-background;\n                background: RR.background;",
                        "border-color: RR.accent-background;\n                background: RR.popup;")
    # About: this build is a RedRog presentation of the asusctl project's app
    if f.name == "about.slint" and "RedRog edition" not in text:
        text = text.replace("""                    text: "ROG Control Center";
                    font-size: 22px;
                }""", """                    text: "ROG Control Center";
                    font-size: 22px;
                }

                Rectangle {
                    border-radius: 12px;
                    background: RR.accent.with-alpha(0.12);
                    border-width: 1px;
                    border-color: RR.accent.with-alpha(0.35);
                    height: redrog-note.preferred-height;
                    redrog-note := VerticalLayout {
                        padding: 14px;
                        spacing: 4px;
                        Text {
                            text: @tr("RedRog edition");
                            color: RR.accent;
                            font-size: 12px;
                            font-weight: 700;
                            letter-spacing: 1.4px;
                        }
                        Text {
                            wrap: TextWrap.word-wrap;
                            color: RR.foreground;
                            font-size: 13px;
                            text: @tr("A RedRog presentation by Junior Carrillo: the same ROG Control Center from the asusctl project (OpenGamingCollective, MPL-2.0), with RedRog's look, modern controls and the Spanish translation.");
                        }
                    }
                }""")
    # warnings: red glass instead of a flat maroon bar
    text = text.replace("background: maroon;", "background: RR.accent.with-alpha(0.14);\n                border-radius: 10px;\n"
                        "                border-width: 1px;\n                border-color: RR.accent.with-alpha(0.4);")
    return text


# Native KWin blur, the one Dolphin and kitty get, asked for when the window
# shows. KWin 6.8 dropped KDE's own blur protocol (the only one winit's
# set_blur speaks) for the standard ext-background-effect-v1, so redrog_blur.rs
# speaks that one on the window's surface
src = ui.parent / "src"
shutil.copy(here / "redrog_blur.rs", src / "redrog_blur.rs")
lib_rs = src / "lib.rs"
l = lib_rs.read_text()
if "mod redrog_blur;" not in l:
    lib_rs.write_text(l.replace("pub mod window;\n", "pub mod redrog_blur;\npub mod window;\n", 1))
window_rs = src / "window.rs"
w = window_rs.read_text()
if "redrog_blur::enable" not in w:
    old = "            Ok(()) => set_app_state(&self.0.app_state, AppState::MainWindowOpen),"
    assert old in w, "window.rs changed upstream"
    w = w.replace(old, """            Ok(()) => {
                // RedRog: KWin's own blur behind the translucent window
                use slint::winit_030::WinitWindowAccessor;
                ui.window().with_winit_window(crate::redrog_blur::enable);
                set_app_state(&self.0.app_state, AppState::MainWindowOpen)
            }""")
    window_rs.write_text(w)
    print("native blur requested")
main_rs = src / "main.rs"
m = main_rs.read_text()
if "redrog_blur::install" not in m:
    old = "fn main() -> Result<()> {\n"
    assert old in m, "main.rs changed upstream"
    m = m.replace(old, old + "    // RedRog: KWin's blur from the window's first frame\n"
                  "    rog_control_center::redrog_blur::install();\n", 1)
    main_rs.write_text(m)
crate_toml = ui.parent / "Cargo.toml"
t = crate_toml.read_text()
if "wayland-protocols" not in t:
    t = t.replace("slint.workspace = true\n", "slint.workspace = true\n"
                  '# RedRog: KWin blur (ext-background-effect-v1)\n'
                  'wayland-client = "0.31"\n'
                  'wayland-backend = { version = "0.3", features = ["client_system"] }\n'
                  'wayland-protocols = { version = "0.32.9", features = ["client", "staging"] }\n', 1)
    crate_toml.write_text(t)
    print("wayland blur dependencies")
cargo = ui.parent.parent / "Cargo.toml"
c = cargo.read_text()
if '"unstable-winit-030"' not in c:
    old = '  "backend-winit-wayland",\n'
    assert old in c, "slint features changed upstream"
    cargo.write_text(c.replace(old, old + '  "unstable-winit-030",\n', 1))
    print("slint: winit access")

# Cupertino controls instead of Fluent
build_rs = ui.parent / "build.rs"
b = build_rs.read_text()
if '.with_style("fluent".into())' in b:
    build_rs.write_text(b.replace('.with_style("fluent".into())', '.with_style("cupertino".into())'))
    print("style: cupertino")

# The RedRog palette
globals_file = ui / "globals.slint"
g = globals_file.read_text()
if "export global RR" not in g:
    if "std-widgets.slint" not in g:
        g = 'import { Palette } from "std-widgets.slint";\n' + g
    globals_file.write_text(g.rstrip() + "\n" + RR)

# The new sidebar, its icons and the RedRog controls
shutil.copy(here / "sidebar.slint", ui / "widgets" / "sidebar.slint")
shutil.copy(here / "rr.slint", ui / "widgets" / "rr.slint")
shutil.copy(here / "colour_picker.slint", ui / "widgets" / "colour_picker.slint")
# The fan curves page: segmented controls instead of nested tabs
(ui / "pages" / "fans.slint").write_text(fans.page())
shutil.copytree(here / "icons", ui / "icons", dirs_exist_ok=True)

# Hardware monitor: one tile per chip (monitor.slint) instead of long
# "Status | full model name" rows that ran past the card's edge
system = ui / "pages" / "system.slint"
s = system.read_text()
if "component HwMonitor" not in s:
    start = s.index("            if SystemPageData.cpu_usage_val != -1.0: Rectangle {")
    end = s.index("            if SystemPageData.platform_profile != -1: HorizontalLayout {")
    s = s[:start] + "            if SystemPageData.cpu_usage_val != -1.0: HwMonitor { }\n\n" + s[end:]
    s = s.replace("export component PageSystem", (here / "monitor.slint").read_text() + "\nexport component PageSystem", 1)
    system.write_text(s)
    print("hardware monitor tiles")
# ...with short chip names: "Intel Core i5-12500H", "NVIDIA GeForce RTX 3050 Mobile"
setup_rs = ui.parent / "src" / "ui" / "setup_system.rs"
r = setup_rs.read_text()
if "redrog_short_name" not in r:
    for var, setter in (("cpu_model", "set_cpu_name"), ("igpu_model", "set_igpu_name"), ("dgpu_model", "set_dgpu_name")):
        old = f"{setter}({var}.into())"
        assert old in r, f"setup_system.rs changed upstream ({setter})"
        r = r.replace(old, f"{setter}(redrog_short_name(&{var}).into())")
    r += '''
/// RedRog: a chip name short enough for the monitor tiles.
/// "12th Gen Intel(R) Core(TM) i5-12500H" -> "Intel Core i5-12500H",
/// "GA107M [GeForce RTX 3050 Mobile]" -> "NVIDIA GeForce RTX 3050 Mobile",
/// "Alder Lake-P GT2 [Iris Xe Graphics]" -> "Intel Iris Xe Graphics".
fn redrog_short_name(name: &str) -> String {
    let mut s = match (name.find('['), name.rfind(']')) {
        (Some(a), Some(b)) if b > a + 1 => name[a + 1..b].to_string(),
        _ => name.to_string(),
    };
    if let Some(at) = s.find(" @") {
        s.truncate(at);
    }
    for junk in ["(R)", "(r)", "(TM)", "(tm)", " CPU", " Processor", " with Radeon Graphics"] {
        s = s.replace(junk, "");
    }
    let words: Vec<&str> = s.split_whitespace().collect();
    let mut out: Vec<&str> = Vec::new();
    let mut i = 0;
    while i < words.len() {
        // "12th Gen", "13th Gen"...
        let ordinal = words[i].chars().next().is_some_and(|c| c.is_ascii_digit())
            && ["st", "nd", "rd", "th"].iter().any(|e| words[i].ends_with(e));
        if ordinal && words.get(i + 1) == Some(&"Gen") {
            i += 2;
            continue;
        }
        out.push(words[i]);
        i += 1;
    }
    let s = out.join(" ");
    let vendor = if s.starts_with("GeForce") || s.starts_with("Quadro") {
        "NVIDIA "
    } else if s.starts_with("Iris") || s.starts_with("UHD") || s.starts_with("Arc") {
        "Intel "
    } else if s.starts_with("Radeon") {
        "AMD "
    } else {
        ""
    };
    format!("{vendor}{s}")
}
'''
    setup_rs.write_text(r)
    print("short chip names")

# Palette colors -> RedRog colors, everywhere else
for f in ui.rglob("*.slint"):
    if f in (globals_file, ui / "widgets" / "sidebar.slint", ui / "widgets" / "rr.slint", ui / "pages" / "fans.slint",
             ui / "widgets" / "colour_picker.slint"):
        continue
    t = f.read_text()
    new = re.sub(r"\bPalette\.([a-z-]+)", r"RR.\1", t)
    if f.name == "main_window.slint" and QUIT_OLD.search(new):
        new = QUIT_OLD.sub(r"""
\1SideBarQuit {
\1    width: side-bar.width;
\1    text: @tr("Quit App");
\1    clicked => {
\1        root.exit-app();
\1    }
\1}""", new)
        # the window background (premultiplied, see RR.window)
        new = new.replace("    background: RR.alternate-background;\n\n    HorizontalLayout {", "    background: RR.window;\n\n    HorizontalLayout {", 1)
        # one glass for the sidebar and the pages, like Dolphin
        new = new.replace("        Rectangle {\n            background: RR.background;\n            if(side-bar.current-item == 0)",
                          "        Rectangle {\n            background: transparent;\n            if(side-bar.current-item == 0)")
        new = new.replace('import { SideBar } from "widgets/sidebar.slint";',
                          'import { SideBar, SideBarQuit } from "widgets/sidebar.slint";')
    new = restyle(f, new)
    if new != t:
        if "RR." in new and not re.search(r"import \{[^}]*\bRR\b", new):
            new = add_import(new, "RR", "globals.slint")
        f.write_text(new)
        print("themed", f.relative_to(ui))
