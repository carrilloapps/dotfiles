// RedRog: traffic lights for Antigravity (see antigravity-run)
// Off macOS Antigravity hides the title bar and lets Electron draw Windows-style
// caption buttons over its page; the patch turns those off and the lights go
// into the page instead, top left where macOS puts its own. The SVGs are the
// system's (gtk-4.0/redrog-lights) and travel as data: URLs.
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
#redrog-lights { position: fixed; left: 12px; top: 0; height: 30px; display: flex;
  align-items: center; gap: 6px; z-index: 2147483647; app-region: no-drag; -webkit-app-region: no-drag; }
#redrog-lights button { all: unset; width: 14px; height: 14px; cursor: default;
  background: center / 14px 14px no-repeat; }
${states("active")}
${states("inactive").replaceAll("#redrog-lights .", "html.redrog-blur #redrog-lights:not(:hover) .")}
${states("hover").replaceAll("#redrog-lights .", "#redrog-lights:hover .")}
${states("pressed").replace(/(#redrog-lights \.\w)/g, "$1:active")}
/* room for the lights before Antigravity's menu (Antigravity, Workspace,
   View...), the first row of its window: under .agy-shell since 2.28, the
   older layout too */
body :is(.agy-shell, .h-screen.w-screen.flex.flex-col) > .shrink-0 > .flex.items-center.gap-1.px-2:first-child { padding-left: 76px !important; }
`;
// put back whenever the page replaces its <body>
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
  // the windows' own pages only, not the built-in browser's <webview> guests
  if (wc.getType() !== "window") return;
  let styled = false;   // insertCSS once per document
  const inject = () => {
    if (!styled) {
      styled = true;
      wc.insertCSS(CSS).catch(() => { styled = false; });
    }
    wc.mainFrame.executeJavaScript(INJECT).catch(() => {});
  };
  wc.on("did-navigate", () => { styled = false; inject(); });
  wc.on("dom-ready", inject);
  wc.on("console-message", (e, _level, message) => {
    const m = (e && e.message) || message || "";
    if (m.startsWith("REDROG-WINDOW:")) act(m.slice(14));
  });
});
