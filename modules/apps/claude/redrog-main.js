// RedRog: macOS traffic lights for Claude desktop (see claude-run)
// The window's top bar is drawn by claude.ai in a view that covers the whole
// window, so the lights go into that page (and into main_window, shown while
// it loads). The SVGs travel as data: URLs: an https page can't load file://.
const { app, BaseWindow } = require("electron");
const fs = require("fs");
const LIGHTS = require("os").homedir() + "/.config/gtk-4.0/redrog-lights";
const svg = (name) => {
  try {
    return `url("data:image/svg+xml,${encodeURIComponent(fs.readFileSync(`${LIGHTS}/${name}.svg`, "utf8"))}")`;
  } catch { return "none"; }
};
const BUTTONS = [["c", "close"], ["m", "minimize"], ["x", "maximize"]];
const states = (state) => BUTTONS
  .map(([cls, b]) => `#redrog-lights .${cls} { background-image: ${svg(`${b}-${state}`)}; }`).join("\n");
const CSS = `
#redrog-lights { position: fixed; left: 16px; top: 0; height: 36px; display: flex;
  align-items: center; gap: 6px; z-index: 2147483647; app-region: no-drag; -webkit-app-region: no-drag; }
#redrog-lights button { all: unset; width: 14px; height: 14px; cursor: default;
  background: center / 14px 14px no-repeat; }
${states("active")}
${states("inactive").replaceAll("#redrog-lights .", "html.redrog-blur #redrog-lights:not(:hover) .")}
${states("hover").replaceAll("#redrog-lights .", "#redrog-lights:hover .")}
${states("pressed").replace(/(#redrog-lights \.\w)/g, "$1:active")}
`;
// claude.ai: room for the lights in its top bar (the pad-start variable keeps
// the Chat/Code switcher aligned to the sidebar's edge), and none on the right
// for the Windows-style caption buttons it reserves 120px for off macOS
const CLAUDE_AI_CSS = `
.dframe-chrome-bar { padding-left: 80px !important; --df-chrome-bar-pad-start: 80px !important;
  padding-right: var(--df-chrome-bar-end-gutter, 12px) !important; --df-chrome-bar-caption-reserve: 0px !important; }
`;
// runs as soon as the page commits, long before claude.ai finishes loading,
// and again at dom-ready; the page may not have a <body> yet, or may replace
// it while it loads, so the lights are put back whenever they go missing
const INJECT = `(() => {
  const add = () => {
    if (!document.body || document.getElementById("redrog-lights")) return;
    const box = document.createElement("div");
    box.id = "redrog-lights";
    for (const [cls, act] of ${JSON.stringify(BUTTONS)}) {
      const b = document.createElement("button");
      b.className = cls; b.title = act;
      b.addEventListener("click", () => console.log("REDROG-WINDOW:" + act));
      box.appendChild(b);
    }
    document.body.appendChild(box);
  };
  add();
  if (window.__redrogLights || !document.documentElement) return;
  window.__redrogLights = true;
  // <html>'s own children only (head, body): cheap to watch for good
  new MutationObserver(add).observe(document.documentElement, { childList: true });
  addEventListener("blur", () => document.documentElement.classList.add("redrog-blur"));
  addEventListener("focus", () => document.documentElement.classList.remove("redrog-blur"));
})();`;
function act(name) {
  const w = BaseWindow.getFocusedWindow();
  if (!w) return;
  if (name === "close") w.close();
  else if (name === "minimize") w.minimize();
  else if (name === "maximize") w.isMaximized() ? w.unmaximize() : w.maximize();
}
app.on("web-contents-created", (_e, wc) => {
  let styled = false;   // insertCSS once per document
  const inject = () => {
    let url;
    try { url = new URL(wc.getURL()); } catch { return; }
    const claudeAi = url.protocol === "https:" && /(^|\.)claude\.ai$/.test(url.hostname);
    if (!claudeAi && !/\/main_window\//.test(url.pathname)) return;
    if (!styled) {
      styled = true;
      wc.insertCSS(CSS + (claudeAi ? CLAUDE_AI_CSS : "")).catch(() => { styled = false; });
    }
    // the frame's executeJavaScript runs now; the webContents' one waits for the load
    wc.mainFrame.executeJavaScript(INJECT).catch(() => {});
  };
  wc.on("did-navigate", () => { styled = false; inject(); });
  wc.on("dom-ready", inject);
  wc.on("console-message", (e, _level, message) => {
    const m = (e && e.message) || message || "";
    if (m.startsWith("REDROG-WINDOW:")) act(m.slice(14));
  });
});
