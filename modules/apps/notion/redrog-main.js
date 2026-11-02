// RedRog: macOS-style traffic lights for Notion (see notion-run)
const { app, BaseWindow } = require("electron");
const LIGHTS = "file://" + require("os").homedir() + "/.config/gtk-4.0/redrog-lights";
const INJECT = `(() => {
  if (document.getElementById("redrog-lights")) return;
  const s = document.createElement("style");
  s.textContent = \`
    #redrog-lights { position: fixed; left: 13px; top: 0; height: 36px; display: flex; align-items: center;
      gap: 6px; z-index: 2147483647; app-region: no-drag; -webkit-app-region: no-drag; }
    #redrog-lights button { all: unset; width: 14px; height: 14px; cursor: default;
      background: center / 14px 14px no-repeat; }
    #redrog-lights .c { background-image: url(${LIGHTS}/close-active.svg); }
    #redrog-lights .m { background-image: url(${LIGHTS}/minimize-active.svg); }
    #redrog-lights .x { background-image: url(${LIGHTS}/maximize-active.svg); }
    #redrog-lights:hover .c { background-image: url(${LIGHTS}/close-hover.svg); }
    #redrog-lights:hover .m { background-image: url(${LIGHTS}/minimize-hover.svg); }
    #redrog-lights:hover .x { background-image: url(${LIGHTS}/maximize-hover.svg); }
    #redrog-lights .c:active { background-image: url(${LIGHTS}/close-pressed.svg); }
    #redrog-lights .m:active { background-image: url(${LIGHTS}/minimize-pressed.svg); }
    #redrog-lights .x:active { background-image: url(${LIGHTS}/maximize-pressed.svg); }
    body.redrog-blur #redrog-lights:not(:hover) button { background-image: url(${LIGHTS}/close-inactive.svg); }
  \`;
  document.head.appendChild(s);
  const box = document.createElement("div");
  box.id = "redrog-lights";
  for (const [cls, act] of [["c", "close"], ["m", "minimize"], ["x", "maximize"]]) {
    const b = document.createElement("button");
    b.className = cls; b.title = act;
    b.addEventListener("click", () => console.log("REDROG-WINDOW:" + act));
    box.appendChild(b);
  }
  document.body.appendChild(box);
  addEventListener("blur", () => document.body.classList.add("redrog-blur"));
  addEventListener("focus", () => document.body.classList.remove("redrog-blur"));
})();`;
function act(name) {
  const w = BaseWindow.getFocusedWindow();
  if (!w) return;
  if (name === "close") w.close();
  else if (name === "minimize") w.minimize();
  else if (name === "maximize") w.isMaximized() ? w.unmaximize() : w.maximize();
}
app.on("web-contents-created", (_e, wc) => {
  wc.on("dom-ready", () => {
    if (wc.getURL().includes("/renderer/tabs/")) wc.executeJavaScript(INJECT).catch(() => {});
  });
  wc.on("console-message", (e, _level, message) => {
    const m = (e && e.message) || message || "";
    if (m.startsWith("REDROG-WINDOW:")) act(m.slice(14));
  });
});
