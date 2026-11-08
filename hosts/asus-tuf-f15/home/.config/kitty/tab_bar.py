# RedRog tab bar for kitty, installed by modules/terminal (don't edit the copy
# in ~/.config/kitty: it is overwritten on every install).
#
# macOS-style tabs across the whole width: one capsule, equal-width tabs, the
# active one a lighter pill, a close button on each and a dot for bell,
# progress or activity. Everything else lives in the right-click menu.
#
# kitty only knows how to click tabs, so the clicks on the close buttons are
# caught by wrapping TabManager.handle_tab_bar_mouse. If a kitty update changes that
# API, the wrapper steps aside and the tabs keep working as usual.
import re

from kitty.fast_data_types import GLFW_MOUSE_BUTTON_LEFT, GLFW_RELEASE, Screen, get_boss, wcswidth
from kitty.tab_bar import DrawData, ExtraData, TabBarData, as_rgb
from kitty.utils import color_as_int

LEFT, RIGHT = "", ""   # Nerd Font half circles

CLOSE_ICON = "\uf00d"
ACCENT = as_rgb(0xef3340)   # the theme accent (set by the installer)

# Per tab bar (keyed by its Screen): the cell ranges of the close buttons
_close_ranges: dict = {}


def _rgb(color) -> int:
    return as_rgb(color_as_int(color))


def _tab_count(tab: TabBarData, fallback: int) -> int:
    try:
        return max(1, len(get_boss().os_window_map[tab.os_window_id].tabs))
    except Exception:
        return fallback


def _fit(text: str, width: int) -> str:
    """text cut with an ellipsis to at most width cells"""
    if wcswidth(text) <= width:
        return text
    while text and wcswidth(text) > width - 1:
        text = text[:-1]
    return text + "…"


def draw_tab(draw_data: DrawData, screen: Screen, tab: TabBarData, before: int,
             max_tab_length: int, index: int, is_last: bool, extra_data: ExtraData) -> int:
    """macOS-style tabs: one capsule (the track) across the free width, every tab
    the same width with its title centered, the active one a lighter pill, the
    close button on the left and a dot for activity, bell or progress."""
    track = _rgb(draw_data.inactive_bg)
    pill = _rgb(draw_data.active_bg)
    dim = _rgb(draw_data.inactive_fg)
    fg = _rgb(draw_data.active_fg)
    first = index == 1
    if first:
        screen.cursor.bg = 0
        screen.draw(" ")
    # every tab gets the same share of the width
    n = _tab_count(tab, max(1, screen.columns // max(1, max_tab_length + 1)))
    free = screen.columns - 1 - 2
    width = max(6, free // n)
    if is_last:                       # the last one takes the rounding leftover
        width = max(6, free - (n - 1) * width)
    start = screen.cursor.x
    if first:
        screen.cursor.fg, screen.cursor.bg = track, 0
        screen.draw(LEFT)
    inner = width - (1 if first else 0) - (1 if is_last else 0)
    if tab.is_active:
        screen.cursor.fg, screen.cursor.bg = pill, track
        screen.draw(LEFT)
        inner -= 2
        body_bg, body_fg = pill, fg
    else:
        body_bg, body_fg = track, dim
    # close button on the left
    screen.cursor.bg, screen.cursor.fg = body_bg, body_fg
    screen.cursor.bold = False
    c = screen.cursor.x
    screen.draw(" " + CLOSE_ICON)
    if not extra_data.for_layout:
        if first:
            _close_ranges[id(screen)] = []
        _close_ranges.setdefault(id(screen), []).append((c, screen.cursor.x, tab.tab_id))
    # status dot: needs attention (bell), progress (e.g. an agent working), activity
    if tab.needs_attention:
        mark, mark_fg = "● ", ACCENT
    elif tab.num_of_windows_with_progress:
        p = tab.total_progress
        mark, mark_fg = ("◔ " if p < 34 else "◑ " if p < 67 else "◕ "), ACCENT
    elif tab.has_activity_since_last_focus and not tab.is_active:
        mark, mark_fg = "• ", body_fg
    else:
        mark, mark_fg = "", body_fg
    room = inner - 2 - 2          # close button, and a cell of air each side
    # "~/.dotfiles - fish" -> "~/.dotfiles": the shell name adds nothing
    name = re.sub(r" - (fish|zsh|bash|sh)$", "", tab.title or "")
    title = _fit(mark + name, max(1, room))
    pad = room - wcswidth(title)
    left = pad // 2
    screen.draw(" " * (1 + left))
    if mark and title.startswith(mark):
        screen.cursor.fg = mark_fg
        screen.draw(mark)
        screen.cursor.fg = body_fg
        title = title[len(mark):]
    screen.cursor.bold = tab.is_active
    screen.draw(title)
    screen.cursor.bold = False
    screen.draw(" " * (pad - left + 1))
    if tab.is_active:
        screen.cursor.fg, screen.cursor.bg = pill, track
        screen.draw(RIGHT)
    if is_last:
        screen.cursor.fg, screen.cursor.bg = track, 0
        screen.draw(RIGHT)
    end = screen.cursor.x
    return end


# ── Clicks on the close buttons ─────────────────────────────────────────
def _close_at(manager, x: float, y: float):
    bar = manager.tab_bar
    ranges = _close_ranges.get(id(bar.screen))
    if not ranges or not bar.laid_out_once:
        return None
    g = bar.window_geometry
    if not (g.left <= x < g.right and g.top <= y < g.bottom):
        return None
    col = int((x - g.left) // bar.cell_width)
    for start, end, tab_id in ranges:
        if start <= col < end:
            return tab_id
    return None


def _install() -> None:
    try:
        from kitty.tabs import TabManager
    except Exception:
        return
    original = getattr(TabManager, "_redrog_original_mouse", None)
    if original is None:
        original = TabManager._redrog_original_mouse = TabManager.handle_tab_bar_mouse

    def handle_tab_bar_mouse(self, x, y, button, modifiers, action):
        try:
            tab_id = _close_at(self, x, y)
        except Exception:
            tab_id = None
        if tab_id is None or button != GLFW_MOUSE_BUTTON_LEFT:
            return original(self, x, y, button, modifiers, action)
        if action == GLFW_RELEASE:      # the press is swallowed: no tab drag
            tab = self.tab_for_id(tab_id)
            if tab is not None:
                get_boss().close_tab(tab)
        return None

    TabManager.handle_tab_bar_mouse = handle_tab_bar_mouse


_install()
