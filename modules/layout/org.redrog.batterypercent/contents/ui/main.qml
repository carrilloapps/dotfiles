// Battery percentage as text ("85 %") next to Plasma's battery icon in the top
// bar; clicking it opens the RedRog panel, a ROG-style system dashboard in the
// RedRog colours: CPU (model), GPU, battery and fan rings; cards for the
// processor (load of every thread), graphics (mode selector, video memory),
// power (ROG profile, CPU watts against the applied power limits, average and
// fastest core frequency with a throttling warning, battery rate and time,
// charge limit), memory (RAM, zram swap) and storage and network, each with a
// short explanation.
//
// The NVIDIA card is never woken up: its readings are only taken while it is
// already active, otherwise the Intel GPU is shown.
import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasma5support as P5Support
import org.kde.ksysguard.sensors as Sensors
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    readonly property color red: Kirigami.Theme.highlightColor
    readonly property color fg: Kirigami.Theme.textColor
    readonly property color dim: Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.62)
    readonly property string mono: "JetBrainsMono Nerd Font"

    property bool hasBattery: false
    property int percent: 0
    property string batteryState: ""
    property real remainingMsec: 0

    // In Plasma 6 a binding on power.data[...] is not re-evaluated when new
    // data arrives, so update explicitly on every event.
    function update(data) {
        if (!data) return;
        hasBattery = data["Has Battery"] === true;
        percent = data["Percent"] || 0;
        batteryState = data["State"] || "";
        remainingMsec = data["Remaining msec"] || 0;
    }

    P5Support.DataSource {
        id: power
        engine: "powermanagement"
        connectedSources: ["Battery"]
        interval: 30000
        onNewData: (source, data) => root.update(data)
        Component.onCompleted: root.update(data["Battery"])
    }

    // Closed: drop the "panel open" mark at once, so the banners rog-notify
    // held while it was open come out now
    P5Support.DataSource {
        id: oneShot
        engine: "executable"
        onNewData: (source, data) => disconnectSource(source)
    }
    onExpandedChanged: if (!expanded) oneShot.connectSource("sh -c 'rm -f \"${XDG_RUNTIME_DIR:-/tmp}/redrog-panel-open\"'")

    toolTipMainText: i18n("System")
    toolTipSubText: ""

    compactRepresentation: MouseArea {
        Layout.minimumWidth: label.implicitWidth
        Layout.preferredWidth: label.implicitWidth
        Layout.maximumWidth: label.implicitWidth
        Layout.fillHeight: true
        visible: root.hasBattery
        onClicked: root.expanded = !root.expanded
        PlasmaComponents.Label {
            id: label
            anchors.fill: parent
            text: root.hasBattery ? Qt.locale().toString(root.percent) + " %" : ""
            verticalAlignment: Text.AlignVCenter
        }
    }

    fullRepresentation: Item {
        id: panel
        // Minimal view: rings, power profile and one line of readings; the
        // full view never grows past the screen (it scrolls instead)
        // follows the setting through viewSwitch, so the content fades out,
        // the popup resizes unseen, and the new view fades in
        property bool minimal: Plasmoid.configuration.minimal
        readonly property bool graphicsDetails: Plasmoid.configuration.graphicsDetails
        readonly property bool memoryDetails: Plasmoid.configuration.memoryDetails
        readonly property real fitHeight: Math.min(content.implicitHeight + Kirigami.Units.largeSpacing * 2,
                                                   Screen.desktopAvailableHeight - Kirigami.Units.gridUnit * 2)
        Layout.preferredWidth: Kirigami.Units.gridUnit * (minimal ? 26 : 40)
        Layout.preferredHeight: fitHeight
        Layout.minimumWidth: Kirigami.Units.gridUnit * (minimal ? 24 : 36)
        Layout.minimumHeight: fitHeight
        // Plasma remembers a resized popup; the maximum makes it follow the
        // view instead (no empty space after switching to the minimal one)
        Layout.maximumWidth: Kirigami.Units.gridUnit * (minimal ? 26 : 40)
        Layout.maximumHeight: fitHeight

        // ── Sensors (only while the panel is open) ───────────────────────────
        component Probe: Sensors.Sensor { updateRateLimit: 2000; enabled: root.expanded }
        Probe { id: cpuTemp; sensorId: "cpu/all/averageTemperature" }
        Probe { id: cpuUse; sensorId: "cpu/all/usage" }
        Probe { id: cpuFreq; sensorId: "cpu/all/averageFrequency" }
        Probe { id: memUsed; sensorId: "memory/physical/used" }
        Probe { id: memTotal; sensorId: "memory/physical/total" }
        Probe { id: memPct; sensorId: "memory/physical/usedPercent" }
        Probe { id: swapUsed; sensorId: "memory/swap/used" }
        Probe { id: swapPct; sensorId: "memory/swap/usedPercent" }
        Probe { id: swapTotal; sensorId: "memory/swap/total" }
        Probe { id: fanCpu; sensorId: "lmsensors/asus-isa-000a/fan1" }
        Probe { id: fanGpu; sensorId: "lmsensors/asus-isa-000a/fan2" }
        Probe { id: diskPct; sensorId: "disk/all/usedPercent" }
        Probe { id: diskUsed; sensorId: "disk/all/used" }
        Probe { id: diskTotal; sensorId: "disk/all/total" }
        Probe { id: diskRead; sensorId: "disk/all/read" }
        Probe { id: diskWrite; sensorId: "disk/all/write" }
        Probe { id: netDown; sensorId: "network/all/download" }
        Probe { id: netUp; sensorId: "network/all/upload" }
        Probe { id: wifiName; sensorId: "network/wlan0/network" }
        Probe { id: wifiSignal; sensorId: "network/wlan0/signal" }
        Probe { id: batRate; sensorId: "power/battery_BAT1/chargeRate" }
        Probe { id: batHealth; sensorId: "power/battery_BAT1/health" }
        Probe { id: igpuUse; sensorId: "gpu/gpu1/usage" }
        Probe { id: kernel; sensorId: "os/kernel/version" }
        Probe { id: igpuVramUsed; sensorId: "gpu/gpu1/usedVram" }
        Probe { id: igpuVramTotal; sensorId: "gpu/gpu1/totalVram" }
        Probe { id: uptime; sensorId: "os/system/uptime" }

        // NVIDIA power state (a sysfs read, never wakes it) and, while it is
        // already active, temperature/load/power; plus the ROG power profile
        property string dgpuState: ""         // "" until the first read: shown as "—"
        property real dgpuTemp: 0
        property real dgpuUse: 0
        property real dgpuPower: 0
        property string dgpuName: "NVIDIA"
        property real dgpuMemUsed: 0      // MiB
        property real dgpuMemTotal: 0
        property real dgpuClock: 0        // MHz: core now / top, memory
        property real dgpuClockMax: 0
        property real dgpuMemClock: 0
        property string dgpuPstate: ""     // P0 (full speed) ... P8 (idle)
        property string dgpuLink: ""       // PCIe generation × lanes
        property string dgpuDriver: ""
        // Graphics and memory details (contents/code/details.sh), key=value
        property var details: ({})
        property real igpuWatts: 0         // uncore RAPL counter, between two reads
        property real lastUncore: -1
        property real lastUncoreTime: 0
        property var topApps: []           // [[name, kB], ...]
        readonly property string detailsCmd: "sh " + Qt.resolvedUrl("../code/details.sh").toString().replace("file://", "")
        property string profile: ""
        property string rogProfile: ""     // asusctl: Quiet / Balanced / Performance
        property int chargeLimit: 100
        property string gpuMode: ""        // supergfxctl: Integrated / Hybrid / AsusMuxDgpu, "none" if missing
        property string gpuPending: ""
        property string panelGpu: ""        // driver of the GPU on the built-in screen (nvidia, i915, xe)
        property real batteryWatts: 0     // current_now × voltage_now
        // CPU package power from the RAPL energy counter (µJ, between two
        // reads), the power limits really applied (asus-armoury) and the
        // fastest core, to catch a throttled CPU at a glance
        property real cpuWatts: 0
        property real lastEnergy: -1
        property real lastEnergyTime: 0
        property int pl1: 0
        property int pl2: 0
        property real maxGHz: 0
        // busy but slow: what a CPU held at a few watts looks like
        readonly property bool cpuThrottled: num(cpuUse.value) > 40 && maxGHz > 0 && maxGHz < 1
        // CPU model, physical cores and threads, read once
        property string cpuNameText: ""
        property int cores: 0
        property int threads: 0
        property var pThreads: []
        property real pMaxGHz: 0
        property real eMaxGHz: 0
        // "0-7,12" -> [0..7, 12]
        function cpuList(text) {
            const out = [];
            text.trim().split(",").forEach(part => {
                if (!part) return;
                const r = part.split("-").map(x => parseInt(x));
                for (let i = r[0]; i <= (r.length > 1 ? r[1] : r[0]); i++) out.push(i);
            });
            return out;
        }
        readonly property string infoCmd: "sh -c 'grep -m1 \"model name\" /proc/cpuinfo | cut -d: -f2-; lscpu -p=core 2>/dev/null | grep -v \"^#\" | sort -u | wc -l; nproc; " +
            "cat /sys/devices/cpu_core/cpus 2>/dev/null || echo; cat /sys/devices/cpu_atom/cpus 2>/dev/null || echo; " +
            "cat /sys/devices/system/cpu/cpufreq/policy*/cpuinfo_max_freq 2>/dev/null | sort -n | sed -n \"1p;\\$p\"'"
        P5Support.DataSource {
            engine: "executable"
            connectedSources: [panel.infoCmd]
            onNewData: (source, data) => {
                const l = (data["stdout"] || "").trim().split("\n");
                panel.cpuNameText = (l[0] || "").trim();
                panel.cores = parseInt(l[1]) || 0;
                panel.threads = parseInt(l[2]) || 0;
                panel.pThreads = panel.cpuList(l[3] || "");
                const lo = (parseInt(l[5]) || 0) / 1e6, hi = (parseInt(l[6]) || 0) / 1e6;
                panel.pMaxGHz = hi;
                panel.eMaxGHz = lo;
                disconnectSource(source);
            }
        }
        // The MUX changes only after a reboot, and supergfxctl still says "No
        // action required": compare the chosen mode with the GPU that really
        // drives the built-in screen (the Intel GPU stays loaded, without a
        // screen, in the dedicated mode, so its presence proves nothing)
        readonly property bool gpuRebootNeeded: gpuMode !== "none" && gpuMode !== "" && panelGpu !== ""
            && ((gpuMode === "AsusMuxDgpu") !== (panelGpu === "nvidia"))
        readonly property bool dgpuActive: dgpuState === "active"
        // Also marks the panel as open (the file's time, renewed every read):
        // rog-notify holds banners meanwhile, so none lands on top of it
        readonly property string stateCmd: "sh -c 'touch \"${XDG_RUNTIME_DIR:-/tmp}/redrog-panel-open\"; cat /sys/bus/pci/drivers/nvidia/0000:*/power/runtime_status 2>/dev/null | head -1; " +
            "cat /sys/firmware/acpi/platform_profile 2>/dev/null; echo; asusctl profile get 2>/dev/null | head -1; " +
            "asusctl battery info 2>/dev/null | head -1; " +
            "if command -v supergfxctl >/dev/null; then supergfxctl -g 2>/dev/null || echo none; supergfxctl -p 2>/dev/null | head -1; else echo none; echo; fi; " +
            "echo $(for c in /sys/class/drm/card*-eDP-*; do [ \"$(cat $c/status 2>/dev/null)\" = connected ] && basename \"$(readlink -f $c/device/device/driver)\"; done | head -1); " +
            "B=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -1); cat $B/current_now 2>/dev/null || echo 0; cat $B/voltage_now 2>/dev/null || echo 0; " +
            "cat /sys/class/powercap/intel-rapl:0/energy_uj 2>/dev/null || echo -1; A=/sys/class/firmware-attributes/asus-armoury/attributes; " +
            "cat $A/ppt_pl1_spl/current_value 2>/dev/null || echo 0; cat $A/ppt_pl2_sppt/current_value 2>/dev/null || echo 0; " +
            "sort -n /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq 2>/dev/null | tail -1'"
        readonly property string queryCmd: "nvidia-smi --query-gpu=temperature.gpu,utilization.gpu,power.draw,memory.used,memory.total,name," +
            "clocks.gr,clocks.max.gr,clocks.mem,pstate,pcie.link.gen.current,pcie.link.width.current,driver_version --format=csv,noheader,nounits"
        P5Support.DataSource {
            engine: "executable"
            connectedSources: root.expanded ? [panel.detailsCmd] : []
            interval: 3000
            onNewData: (source, data) => {
                const d = {}, top = [];
                (data["stdout"] || "").trim().split("\n").forEach(l => {
                    const i = l.indexOf("=");
                    if (i < 0) return;
                    const k = l.slice(0, i), v = l.slice(i + 1);
                    if (k === "top") { const p = v.split(":"); top.push([p.slice(1).join(":"), parseInt(p[0]) || 0]); }
                    else d[k] = v;
                });
                // µJ between two reads -> W, as for the CPU package
                const e = parseFloat(d.uncore_uj), now = Date.now(), dt = (now - panel.lastUncoreTime) / 1000;
                if (e >= 0 && panel.lastUncore >= 0 && e >= panel.lastUncore && dt >= 0.5)
                    panel.igpuWatts = (e - panel.lastUncore) / 1e6 / dt;
                if (e >= 0 && dt >= 0.5) { panel.lastUncore = e; panel.lastUncoreTime = now; }
                panel.details = d;
                panel.topApps = top;
            }
        }
        function kb(v) { return size((parseFloat(v) || 0) * 1024); }

        P5Support.DataSource {
            id: shell
            engine: "executable"
            connectedSources: root.expanded ? [panel.stateCmd] : []
            interval: 3000
            onNewData: (source, data) => {
                const out = (data["stdout"] || "").trim();
                if (source === panel.stateCmd) {
                    const lines = out.split("\n");
                    panel.dgpuState = lines[0] || "suspended";
                    panel.profile = lines[1] || "";
                    panel.rogProfile = ((lines[3] || "").match(/(Quiet|Balanced|Performance|LowPower)/) || [""])[0];
                    panel.chargeLimit = parseInt(((lines[4] || "").match(/(\d+)\s*%/) || [0, 100])[1]);
                    panel.gpuMode = (lines[5] || "none").trim();
                    panel.gpuPending = (lines[6] || "").trim();
                    panel.panelGpu = (lines[7] || "").trim();
                    // µA × µV -> W (the battery has no power_now)
                    panel.batteryWatts = (parseInt(lines[8]) || 0) * (parseInt(lines[9]) || 0) / 1e12;
                    // µJ between two reads -> W; the counter wraps around, and
                    // reads closer than half a second say little
                    const energy = parseFloat(lines[10]), now = Date.now();
                    const dt = (now - panel.lastEnergyTime) / 1000;
                    if (energy >= 0 && panel.lastEnergy >= 0 && energy >= panel.lastEnergy && dt >= 0.5)
                        panel.cpuWatts = (energy - panel.lastEnergy) / 1e6 / dt;
                    if (energy >= 0 && dt >= 0.5) { panel.lastEnergy = energy; panel.lastEnergyTime = now; }
                    panel.pl1 = parseInt(lines[11]) || 0;
                    panel.pl2 = parseInt(lines[12]) || 0;
                    panel.maxGHz = (parseInt(lines[13]) || 0) / 1e6;
                    if (panel.awaitingState) panel.finish();
                } else if (source === panel.queryCmd && out) {
                    const v = out.split(",").map(x => parseFloat(x));
                    panel.dgpuTemp = v[0] || 0;
                    panel.dgpuUse = v[1] || 0;
                    panel.dgpuPower = v[2] || 0;
                    panel.dgpuMemUsed = v[3] || 0;
                    panel.dgpuMemTotal = v[4] || 0;
                    const name = (out.split(",")[5] || "").trim();
                    if (name) panel.dgpuName = name.replace(/^NVIDIA GeForce /, "").replace(/ Laptop GPU$/, "");
                    const s = out.split(",").map(x => x.trim());
                    panel.dgpuClock = v[6] || 0;
                    panel.dgpuClockMax = v[7] || 0;
                    panel.dgpuMemClock = v[8] || 0;
                    panel.dgpuPstate = s[9] || "";
                    panel.dgpuLink = s[10] && s[11] ? "Gen" + s[10] + " ×" + s[11] : "";
                    panel.dgpuDriver = s[12] || "";
                }
            }
        }
        // One change at a time (profile, GPU mode or charge limit). The
        // selector stays busy until the command has finished AND the refreshed
        // state has arrived, so a change can never be triggered twice.
        property string busyTag: ""        // "profile" / "gpu" / "charge"
        property string busyValue: ""
        property bool awaitingState: false
        property string errorText: ""

        P5Support.DataSource {
            id: action
            engine: "executable"
            onNewData: (source, data) => {
                disconnectSource(source);
                if ((data["exit code"] || 0) !== 0) {
                    const msg = (data["stderr"] || data["stdout"] || "").trim().split("\n")[0];
                    panel.errorText = i18n("Could not apply the change") + (msg ? ": " + msg : "");
                    errorTimer.restart();
                }
                panel.awaitingState = true;
                shell.disconnectSource(panel.stateCmd);
                shell.connectSource(panel.stateCmd);   // refresh the state now
            }
        }
        function run(tag, value, cmd) {
            if (busyTag !== "") return;
            busyTag = tag;
            busyValue = value;
            errorText = "";
            confirmMode = "";
            safety.restart();
            minBusy.restart();
            action.connectSource(cmd);
        }
        // Ends the busy state once the state is confirmed, but never before
        // the minimum time, so the feedback is always visible
        property bool stateConfirmed: false
        function finish() {
            stateConfirmed = true;
            if (!minBusy.running) clearBusy();
        }
        function clearBusy() { busyTag = ""; busyValue = ""; awaitingState = false; stateConfirmed = false; }
        Timer { id: minBusy; interval: 1000; onTriggered: if (panel.stateConfirmed) panel.clearBusy() }
        // GPU modes switch only after a logout or reboot: ask first
        property string confirmMode: ""
        // Never stay busy forever (e.g. a command that hangs)
        Timer { id: safety; interval: 20000; onTriggered: panel.clearBusy() }
        Timer { id: errorTimer; interval: 6000; onTriggered: panel.errorText = "" }

        Timer {
            interval: 3000
            repeat: true
            triggeredOnStart: true
            running: root.expanded && panel.dgpuActive
            onTriggered: {
                shell.disconnectSource(panel.queryCmd);
                shell.connectSource(panel.queryCmd);
            }
        }

        function num(v) { return isNaN(v) ? 0 : v; }
        // "12th Gen Intel(R) Core(TM) i5-12500H" -> "i5-12500H", generation 12
        readonly property string cpuModel: {
            const n = panel.cpuNameText;
            const m = n.match(/(i[3579]-\w+|Ultra \d \w+|Ryzen \d \w+)/);
            return m ? m[1] : (n.replace(/\(R\)|\(TM\)/g, "").trim() || "CPU");
        }
        readonly property int cpuGen: parseInt(((panel.cpuNameText).match(/(\d+)th Gen/) || [0, 0])[1])
        // Everything in the panel as plain text, for the Copy button
        function summary() {
            const L = [];
            L.push("RedRog · " + i18n("System") + " · " + new Date().toLocaleString(Qt.locale()));
            L.push("");
            L.push(i18n("Processor") + ": " + cpuNameText.replace(/\(R\)|\(TM\)/g, "") + " · "
                   + i18n("%1 cores · %2 threads", cores, threads));
            L.push("  " + Math.round(num(cpuTemp.value)) + " °C · " + Math.round(num(cpuUse.value)) + " % · "
                   + (num(cpuFreq.value) / 1000).toFixed(2) + " GHz");
            L.push(i18n("Graphics") + ": " + (gpuMode || "-") + (dgpuActive
                   ? " · " + dgpuName + " " + Math.round(dgpuTemp) + " °C, " + Math.round(dgpuUse) + " %, " + Math.round(dgpuPower) + " W"
                   : " · " + i18n("NVIDIA resting")));
            if (dgpuActive && dgpuClockMax > 0)
                L.push("  " + dgpuPstate + " · " + Math.round(dgpuClock) + " / " + Math.round(dgpuClockMax) + " MHz · "
                       + Math.round(dgpuMemClock) + " MHz VRAM · PCIe " + dgpuLink + " · " + dgpuDriver);
            if (details.igpu_max !== undefined)
                L.push("  Intel " + (parseInt(details.igpu_mhz) || 0) + " / " + details.igpu_max + " MHz · " + igpuWatts.toFixed(1) + " W");
            L.push(i18n("Power profile") + ": " + profileName(profile));
            L.push("  CPU " + cpuWatts.toFixed(1) + " W" + (pl1 > 0 ? " · PL1/PL2 " + pl1 + "/" + pl2 + " W" : "")
                   + " · " + (num(cpuFreq.value) / 1000).toFixed(2) + " / " + maxGHz.toFixed(2) + " GHz"
                   + (cpuThrottled ? " · " + i18n("throttled") : ""));
            L.push(i18n("Battery") + ": " + root.percent + " % · " + stateName(root.batteryState)
                   + (batteryWatts > 0.1 ? " · " + batteryWatts.toFixed(1) + " W" : "")
                   + " · " + i18n("Charge limit") + " " + chargeLimit + " %");
            L.push("FAN: " + Math.round(num(fanCpu.value)) + " / " + Math.round(num(fanGpu.value)) + " rpm");
            L.push(i18n("RAM") + ": " + gb(memUsed.value) + " / " + Math.round(num(memTotal.value) / 1073741824) + " GB");
            L.push(i18n("Swap") + ": " + size(swapUsed.value) + " / " + size(swapTotal.value));
            if (details.mem_avail !== undefined)
                L.push("  " + i18n("Available") + " " + kb(details.mem_avail) + " · " + i18n("Pressure") + " " + (details.psi || "0") + " %"
                       + (topApps.length ? " · " + topApps.map(a => a[0] + " " + kb(a[1])).join(", ") : ""));
            L.push(i18n("Disk") + ": " + Math.round(num(diskUsed.value) / 1073741824) + " / "
                   + Math.round(num(diskTotal.value) / 1073741824) + " GB");
            L.push(i18n("Network") + ": " + (wifiName.value || "-") + " · ↓ " + rate(netDown.value) + " ↑ " + rate(netUp.value));
            L.push("Linux " + (kernel.value || "") + " · " + i18n("Up %1", duration(uptime.value)));
            return L.join("\n");
        }
        function hm(msec) {
            const m = Math.round(num(msec) / 60000);
            return Math.floor(m / 60) + " h " + (m % 60) + " min";
        }
        function gb(bytes) { return (num(bytes) / 1073741824).toFixed(1); }
        function rate(bps) {
            const v = num(bps);
            if (v >= 1048576) return (v / 1048576).toFixed(1) + " MB/s";
            if (v >= 1024) return Math.round(v / 1024) + " KB/s";
            return Math.round(v) + " B/s";
        }
        readonly property var profileModel: [{ text: i18n("Quiet"), value: "Quiet" },
                                             { text: i18n("Balanced"), value: "Balanced" },
                                             { text: i18n("Performance"), value: "Performance" }]
        function throttleText() {
            return i18n("The CPU is held back: %1 GHz at %2 % load. Pick the profile again to reapply its power limits.",
                        maxGHz.toFixed(2), Math.round(num(cpuUse.value)));
        }
        // How the current graphics mode works, in one sentence
        function gpuHow() {
            if (gpuMode === "AsusMuxDgpu" || (gpuMode === "none" && panelGpu === "nvidia"))
                return i18n("NVIDIA drives the screen directly (MUX): the most frames and the lowest latency in games, at a higher power draw. The Intel GPU rests.");
            if (gpuMode === "Hybrid")
                return i18n("Intel draws the desktop; NVIDIA wakes only for a game or an app that asks for it, then goes back to sleep at 0 W.");
            if (gpuMode === "Integrated")
                return i18n("Only the Intel GPU works and NVIDIA is switched off: the longest battery life, no games on NVIDIA.");
            return "";
        }
        // NVIDIA performance states: P0 is full speed, P8 idle
        function pstateName(p) {
            const n = parseInt((p || "").replace("P", ""));
            return isNaN(n) ? "" : n <= 2 ? i18n("full speed") : n <= 5 ? i18n("medium") : i18n("idle");
        }
        function heat(t) { return Math.max(0, Math.min(1, (num(t) - 30) / 70)); }
        function profileName(p) {
            return p === "performance" ? i18n("Performance")
                 : p === "balanced" ? i18n("Balanced")
                 : p === "quiet" ? i18n("Quiet")
                 : p === "low-power" ? i18n("Low power") : p;
        }
        function stateName(s) {
            // Plugged in at or above the charge limit, the battery is held
            // where it is: say so instead of a bare "not charging"
            if (s !== "Charging" && s !== "Discharging" && chargeLimit < 100 && root.percent >= chargeLimit - 1)
                return i18n("Limit %1 %", chargeLimit);
            return s === "Charging" ? i18n("Charging")
                 : s === "Discharging" ? i18n("Discharging")
                 : s === "FullyCharged" ? i18n("Fully charged")
                 : i18n("Not charging");
        }
        function size(bytes) {
            const v = num(bytes);
            if (v >= 1073741824) return (v / 1073741824).toFixed(1) + " GB";
            if (v >= 1048576) return Math.round(v / 1048576) + " MB";
            return Math.round(v / 1024) + " KB";
        }
        function duration(sec) {
            const s = Math.floor(num(sec)), d = Math.floor(s / 86400), h = Math.floor(s % 86400 / 3600), m = Math.floor(s % 3600 / 60);
            return (d > 0 ? d + "d " : "") + h + "h " + m + "m";
        }

        Connections {
            target: Plasmoid.configuration
            function onValueChanged(key, value) { if (key === "minimal") viewSwitch.restart(); }
        }
        SequentialAnimation {
            id: viewSwitch
            ParallelAnimation {
                NumberAnimation { target: scroller; property: "opacity"; to: 0; duration: 130; easing.type: Easing.InCubic }
                NumberAnimation { target: viewLift; property: "y"; to: -6; duration: 130; easing.type: Easing.InCubic }
            }
            ScriptAction { script: panel.minimal = Plasmoid.configuration.minimal }
            PropertyAction { target: viewLift; property: "y"; value: 8 }
            PauseAnimation { duration: 40 }   // the popup takes its new size here
            ParallelAnimation {
                NumberAnimation { target: scroller; property: "opacity"; to: 1; duration: 240; easing.type: Easing.OutCubic }
                NumberAnimation { target: viewLift; property: "y"; to: 0; duration: 280; easing.type: Easing.OutCubic }
            }
        }
        Flickable {
            id: scroller
            transform: Translate { id: viewLift }
            anchors.fill: parent
            contentHeight: content.implicitHeight + Kirigami.Units.largeSpacing * 2
            boundsBehavior: Flickable.StopAtBounds
            clip: true
            QQC2.ScrollBar.vertical: PlasmaComponents.ScrollBar { policy: scroller.contentHeight > scroller.height + 4 ? QQC2.ScrollBar.AsNeeded : QQC2.ScrollBar.AlwaysOff }
            ColumnLayout {
                id: content
                x: Kirigami.Units.largeSpacing
                y: Kirigami.Units.largeSpacing
                width: scroller.width - Kirigami.Units.largeSpacing * 2
                spacing: 12

                // Header: title, active ROG profile
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: i18n("System").toUpperCase()
                        color: root.fg
                        font.family: root.mono
                        font.pixelSize: 14
                        font.letterSpacing: 5
                        font.bold: true
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: panel.profileName(panel.profile)
                        color: root.red
                        font.family: root.mono
                        font.pixelSize: 11
                        font.letterSpacing: 1.5
                    }
                    // Minimal / full view, remembered
                    IconButton {
                        Layout.leftMargin: 6
                        icon: panel.minimal ? "expand" : "collapse"
                        tip: panel.minimal ? i18n("Full view") : i18n("Minimal view")
                        onTapped: Plasmoid.configuration.minimal = !panel.minimal
                    }
                    // Copy everything; it turns into a red check for a moment and
                    // ignores clicks while it shows it
                    IconButton {
                        id: copyButton
                        property bool done: false
                        icon: done ? "checkmark" : "edit-copy"
                        tip: done ? i18n("Copied") : i18n("Copy all data")
                        tipVisible: hovered || done
                        highlighted: done
                        enabled: !done
                        onTapped: {
                            clipboard.text = panel.summary();
                            clipboard.selectAll();
                            clipboard.copy();
                            done = true;
                            copiedTimer.restart();
                        }
                        Timer { id: copiedTimer; interval: 1600; onTriggered: copyButton.done = false }
                        // invisible editor used to reach the clipboard
                        TextEdit { id: clipboard; visible: false }
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: root.red }
                        GradientStop { position: 1; color: "transparent" }
                    }
                }

                // Rings
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    Ring {
                        label: "CPU"
                        value: Math.round(panel.num(cpuTemp.value)) + "°"
                        detail: Math.round(panel.num(cpuUse.value)) + " % · " + (panel.num(cpuFreq.value) / 1000).toFixed(2) + " GHz"
                        fraction: panel.heat(cpuTemp.value)
                        inner: panel.num(cpuUse.value) / 100
                    }
                    Ring {
                        label: panel.dgpuActive ? panel.dgpuName.toUpperCase() : "IRIS XE"
                        value: panel.dgpuActive ? Math.round(panel.dgpuTemp) + "°" : Math.round(panel.num(igpuUse.value)) + "%"
                        detail: panel.dgpuActive ? Math.round(panel.dgpuUse) + " % · " + Math.round(panel.dgpuPower) + " W"
                              : panel.gpuRebootNeeded && panel.gpuMode === "AsusMuxDgpu" ? i18n("NVIDIA after restart")
                              : i18n("NVIDIA resting")
                        fraction: panel.dgpuActive ? panel.heat(panel.dgpuTemp) : panel.num(igpuUse.value) / 100
                        inner: (panel.dgpuActive ? panel.dgpuUse : panel.num(igpuUse.value)) / 100
                    }
                    Ring {
                        label: i18n("Battery").toUpperCase()
                        value: root.percent + "%"
                        detail: panel.batteryWatts > 0.1 && (root.batteryState === "Discharging" || root.batteryState === "Charging")
                                ? (root.batteryState === "Charging" ? "+" : "−") + panel.batteryWatts.toFixed(1) + " W · " + panel.stateName(root.batteryState)
                                : panel.stateName(root.batteryState)
                        fraction: root.percent / 100
                        inner: panel.num(batHealth.value) / 100
                    }
                    Ring {
                        label: "FAN"
                        value: (Math.max(panel.num(fanCpu.value), panel.num(fanGpu.value)) / 1000).toFixed(1) + "k"
                        detail: Math.round(panel.num(fanCpu.value)) + " · " + Math.round(panel.num(fanGpu.value)) + " rpm"
                        fraction: panel.num(fanCpu.value) / 6500
                        inner: panel.num(fanGpu.value) / 6500
                    }
                }

                // ── Minimal view: the power profile and one block of readings
                ColumnLayout {
                    visible: panel.minimal
                    Layout.fillWidth: true
                    spacing: 10
                    Segmented {
                        current: panel.rogProfile
                        busy: panel.busyTag === "profile"
                        pendingValue: panel.busyValue
                        enabled: panel.busyTag === "" || busy
                        model: panel.profileModel
                        onSelected: value => panel.run("profile", value, "asusctl profile set " + value)
                    }
                    Facts {
                        rows: [
                            ["CPU", panel.cpuWatts.toFixed(1) + " W · " + panel.maxGHz.toFixed(2) + " GHz"],
                            [i18n("RAM"), panel.gb(memUsed.value) + " / " + Math.round(panel.num(memTotal.value) / 1073741824) + " GB"],
                            [i18n("Disk"), Math.round(panel.num(diskUsed.value) / 1073741824) + " / " + Math.round(panel.num(diskTotal.value) / 1073741824) + " GB"],
                            [i18n("Network"), "↓ " + panel.rate(netDown.value) + " ↑ " + panel.rate(netUp.value)]
                        ]
                    }
                    Text {
                        Layout.fillWidth: true
                        visible: panel.cpuThrottled
                        text: panel.throttleText()
                        color: root.red
                        font.pixelSize: 10
                        wrapMode: Text.WordWrap
                    }
                }

                Card {
                    visible: !panel.minimal
                    Layout.fillWidth: true
                    title: panel.cpuNameText.replace(/\(R\)|\(TM\)|\bCPU\b|@.*$/g, "").replace(/\s+/g, " ").trim() || i18n("Processor")
                    shown: root.expanded
                    order: 1
                    note: i18n("%1 cores · %2 threads", panel.cores, panel.threads)
                    CpuEqualizer {
                        threads: panel.threads
                        pThreads: panel.pThreads
                        pMaxGHz: panel.pMaxGHz
                        eMaxGHz: panel.eMaxGHz
                        active: root.expanded
                    }
                }

                // ── Two-column grid; the lower cards stretch so both columns end level
                RowLayout {
                    visible: !panel.minimal
                    Layout.fillWidth: true
                    spacing: 12

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.fillHeight: true
                        spacing: 12

                        Card {
                            title: i18n("Graphics")
                            shown: root.expanded
                            order: 2
                            note: panel.gpuMode === "none" ? i18n("needs supergfxctl")
                                : panel.gpuRebootNeeded ? i18n("Restart to apply")
                                : panel.gpuPending && !/^(none|no action)/i.test(panel.gpuPending)
                                  ? i18n("Pending: %1", panel.gpuPending) : ""
                            Segmented {
                                current: panel.gpuMode
                                busy: panel.busyTag === "gpu"
                                pendingValue: panel.busyValue
                                enabled: panel.gpuMode !== "none" && (panel.busyTag === "" || busy)
                                model: [{ text: i18n("Intel"), value: "Integrated" },
                                        { text: i18n("Automatic"), value: "Hybrid" },
                                        { text: i18n("NVIDIA"), value: "AsusMuxDgpu" }]
                                onSelected: value => panel.confirmMode = value
                            }
                            // Confirmation bar for a GPU mode change
                            Rectangle {
                                Layout.fillWidth: true
                                visible: panel.confirmMode !== ""
                                implicitHeight: confirmRow.implicitHeight + 12
                                radius: 6
                                color: Qt.alpha(Kirigami.Theme.highlightColor, 0.12)
                                border.width: 1
                                border.color: Qt.alpha(Kirigami.Theme.highlightColor, 0.35)
                                RowLayout {
                                    id: confirmRow
                                    anchors.fill: parent
                                    anchors.margins: 6
                                    Text {
                                        Layout.fillWidth: true
                                        text: panel.confirmMode === "AsusMuxDgpu" ? i18n("NVIDIA only needs a restart")
                                            : panel.confirmMode === "Integrated" ? i18n("Intel only may need a logout")
                                            : i18n("Automatic may need a restart")
                                        color: root.fg
                                        font.pixelSize: 11
                                        wrapMode: Text.WordWrap
                                    }
                                    PlasmaComponents.Button { text: i18n("Cancel"); flat: true; onClicked: panel.confirmMode = "" }
                                    PlasmaComponents.Button {
                                        text: i18n("Switch")
                                        onClicked: panel.run("gpu", panel.confirmMode, "supergfxctl -m " + panel.confirmMode)
                                    }
                                }
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                visible: panel.gpuRebootNeeded && panel.confirmMode === "" && panel.busyTag === ""
                                Text {
                                    Layout.fillWidth: true
                                    text: i18n("The new graphics mode starts after a restart")
                                    color: root.dim
                                    font.pixelSize: 10
                                    wrapMode: Text.WordWrap
                                }
                                PlasmaComponents.Button {
                                    text: i18n("Restart now")
                                    icon.name: "system-reboot"
                                    onClicked: panel.run("reboot", "", "qdbus6 org.kde.Shutdown /Shutdown org.kde.Shutdown.logoutAndReboot")
                                }
                            }
                            Meter {
                                // the Intel GPU reports no figures for its shared memory
                                visible: (panel.dgpuActive && panel.dgpuMemTotal > 0) || panel.num(igpuVramTotal.value) > 0
                                label: i18n("Video memory")
                                value: panel.dgpuActive && panel.dgpuMemTotal > 0
                                       ? (panel.dgpuMemUsed / 1024).toFixed(1) + " / " + (panel.dgpuMemTotal / 1024).toFixed(1) + " GB"
                                       : panel.size(igpuVramUsed.value) + " / " + panel.size(igpuVramTotal.value)
                                fraction: panel.dgpuActive && panel.dgpuMemTotal > 0 ? panel.dgpuMemUsed / panel.dgpuMemTotal
                                        : panel.num(igpuVramUsed.value) / Math.max(1, panel.num(igpuVramTotal.value))
                                hint: panel.dgpuActive ? i18n("Dedicated memory of the NVIDIA card")
                                                       : i18n("The Intel GPU borrows it from the RAM")
                            }
                            // at a glance: who drives the screen and how the NVIDIA card is doing;
                            // every row is there from the first frame ("—" until the data arrives),
                            // so nothing jumps while the panel fills in
                            Facts {
                                rows: [
                                    [i18n("Screen"), panel.panelGpu === "nvidia" ? "NVIDIA" : panel.panelGpu ? "Intel" : "—"],
                                    ["NVIDIA", panel.dgpuState === "" ? "—" : panel.dgpuActive ? (panel.dgpuPstate || i18n("awake")) : i18n("asleep · 0 W")],
                                    [i18n("Temperature"), panel.dgpuActive && panel.dgpuTemp > 0 ? Math.round(panel.dgpuTemp) + " °C" : "—"],
                                    [i18n("Power"), panel.dgpuActive && panel.dgpuTemp > 0 ? panel.dgpuPower.toFixed(1) + " W" : "—"]
                                ]
                            }
                            Collapsible {
                                open: panel.graphicsDetails
                                Facts {
                                    readonly property real igpuMhz: parseInt(panel.details.igpu_mhz) || 0
                                    rows: [
                                        [i18n("Load"), panel.dgpuActive ? Math.round(panel.dgpuUse) + " %" : ""],
                                        [i18n("State"), panel.dgpuActive ? panel.pstateName(panel.dgpuPstate) : ""],
                                        [i18n("Core"), panel.dgpuActive && panel.dgpuClockMax > 0
                                                       ? Math.round(panel.dgpuClock) + " / " + Math.round(panel.dgpuClockMax) + " MHz" : ""],
                                        ["VRAM", panel.dgpuActive && panel.dgpuMemClock > 0 ? Math.round(panel.dgpuMemClock) + " MHz" : ""],
                                        ["PCIe", panel.dgpuActive ? panel.dgpuLink : ""],
                                        [i18n("Driver"), panel.dgpuActive ? panel.dgpuDriver : ""],
                                        ["Intel", panel.details.igpu_max === undefined ? ""
                                                  : igpuMhz > 0 ? igpuMhz + " / " + panel.details.igpu_max + " MHz" : i18n("resting")],
                                        [i18n("Intel power"), panel.lastUncore >= 0 ? panel.igpuWatts.toFixed(1) + " W" : ""]
                                    ]
                                }
                                Text {
                                    Layout.fillWidth: true
                                    visible: text !== ""
                                    text: panel.gpuHow()
                                    color: root.dim
                                    font.pixelSize: 9
                                    wrapMode: Text.WordWrap
                                }
                            }
                            MoreToggle {
                                open: panel.graphicsDetails
                                onToggled: Plasmoid.configuration.graphicsDetails = !panel.graphicsDetails
                            }
                        }

                        Card {
                            Layout.fillHeight: true
                            title: i18n("Memory")
                            shown: root.expanded
                            order: 4
                            Meter {
                                label: i18n("RAM")
                                value: panel.gb(memUsed.value) + " / " + Math.round(panel.num(memTotal.value) / 1073741824) + " GB"
                                fraction: panel.num(memPct.value) / 100
                                hint: i18n("Working memory used by open apps")
                            }
                            Meter {
                                label: i18n("Swap")
                                value: panel.size(swapUsed.value) + " / " + panel.size(swapTotal.value)
                                fraction: panel.num(swapPct.value) / 100
                                hint: i18n("zram: compressed space inside the RAM, used only when it fills up")
                            }
                            Facts {
                                rows: [
                                    [i18n("Available"), panel.details.mem_avail !== undefined ? panel.kb(panel.details.mem_avail) : "—"],
                                    [i18n("Pressure"), panel.details.psi !== undefined && panel.details.psi !== "" ? panel.details.psi + " %" : "—"]
                                ]
                            }
                            Collapsible {
                                open: panel.memoryDetails
                                Facts {
                                    readonly property real zramOrig: parseFloat(panel.details.zram_orig) || 0
                                    readonly property real zramCompr: parseFloat(panel.details.zram_compr) || 0
                                    rows: [
                                        [i18n("Disk cache"), panel.details.mem_cached !== undefined
                                                             ? panel.kb((parseFloat(panel.details.mem_cached) || 0) + (parseFloat(panel.details.mem_buffers) || 0)) : ""],
                                        [i18n("Shared"), panel.details.mem_shmem !== undefined ? panel.kb(panel.details.mem_shmem) : ""],
                                        [i18n("To write"), panel.details.mem_dirty !== undefined ? panel.kb(panel.details.mem_dirty) : ""],
                                        ["zram", panel.details.zram_orig === undefined ? ""
                                                 : zramOrig > 0 ? panel.size(zramOrig) + " → " + panel.size(zramCompr) : i18n("empty")],
                                        [i18n("Compression"), panel.details.zram_alg === undefined ? ""
                                                              : (zramCompr > 0 ? (zramOrig / zramCompr).toFixed(1) + "× · " : "") + panel.details.zram_alg]
                                    ]
                                }
                                Text {
                                    visible: panel.topApps.length > 0
                                    text: i18n("Using the most").toUpperCase()
                                    color: root.dim
                                    font.family: root.mono
                                    font.pixelSize: 9
                                    font.letterSpacing: 2
                                }
                                Facts {
                                    rows: panel.topApps.map(a => [a[0], panel.kb(a[1])])
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: i18n("Linux fills free RAM with disk cache to speed things up and hands it back as soon as an app needs it: \"available\" is what apps can still use. Pressure above 0 % means apps are waiting for memory.")
                                    color: root.dim
                                    font.pixelSize: 9
                                    wrapMode: Text.WordWrap
                                }
                            }
                            MoreToggle {
                                open: panel.memoryDetails
                                onToggled: Plasmoid.configuration.memoryDetails = !panel.memoryDetails
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.fillHeight: true
                        spacing: 12

                        Card {
                            title: i18n("Power")
                            shown: root.expanded
                            order: 3
                            note: panel.batteryWatts > 0.1
                                  ? (root.batteryState === "Charging" ? "+" : "−") + panel.batteryWatts.toFixed(1) + " W" : ""
                            Segmented {
                                current: panel.rogProfile
                                busy: panel.busyTag === "profile"
                                pendingValue: panel.busyValue
                                enabled: panel.busyTag === "" || busy
                                model: panel.profileModel
                                onSelected: value => panel.run("profile", value, "asusctl profile set " + value)
                            }
                            Meter {
                                label: i18n("Processor")
                                value: panel.cpuWatts.toFixed(1) + " W" + (panel.pl1 > 0 ? " · " + i18n("limit %1/%2 W", panel.pl1, panel.pl2) : "")
                                fraction: panel.cpuWatts / Math.max(1, panel.pl2 || 45)
                                hint: i18n("Now · the profile's sustained / burst limit")
                            }
                            Meter {
                                label: i18n("Frequency")
                                value: i18n("avg %1 · max %2 GHz", (panel.num(cpuFreq.value) / 1000).toFixed(2), panel.maxGHz.toFixed(2))
                                fraction: panel.maxGHz / Math.max(1, panel.pMaxGHz)
                            }
                            Text {
                                Layout.fillWidth: true
                                visible: panel.cpuThrottled
                                text: panel.throttleText()
                                color: root.red
                                font.pixelSize: 10
                                wrapMode: Text.WordWrap
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    Layout.fillWidth: true
                                    text: root.batteryState === "Discharging" && root.remainingMsec > 0
                                          ? i18n("%1 left", panel.hm(root.remainingMsec))
                                          : root.batteryState === "Charging" && root.remainingMsec > 0
                                          ? i18n("Full in %1", panel.hm(root.remainingMsec))
                                          : i18n("Charge limit")
                                    color: root.fg
                                    font.pixelSize: 11
                                }
                                Segmented {
                                    Layout.fillWidth: false
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 7
                                    implicitHeight: 24
                                    current: panel.chargeLimit >= 100 ? "100" : "80"
                                    busy: panel.busyTag === "charge"
                                    pendingValue: panel.busyValue
                                    enabled: panel.busyTag === "" || busy
                                    model: [{ text: "80 %", value: "80" }, { text: "100 %", value: "100" }]
                                    onSelected: value => panel.run("charge", value, "asusctl battery limit " + value)
                                }
                            }
                            Text {
                                Layout.fillWidth: true
                                text: i18n("80 % makes the battery last more years; use 100 % before a trip")
                                color: root.dim
                                font.pixelSize: 9
                                wrapMode: Text.WordWrap
                            }
                        }

                        Card {
                            Layout.fillHeight: true
                            title: i18n("Storage and network")
                            shown: root.expanded
                            order: 5
                            Meter {
                                label: i18n("Disk")
                                value: Math.round(panel.num(diskUsed.value) / 1073741824) + " / " + Math.round(panel.num(diskTotal.value) / 1073741824) + " GB"
                                fraction: panel.num(diskPct.value) / 100
                            }
                            Meter {
                                label: i18n("Read / write")
                                value: panel.rate(diskRead.value) + " · " + panel.rate(diskWrite.value)
                                fraction: Math.min(1, (panel.num(diskRead.value) + panel.num(diskWrite.value)) / 524288000)
                            }
                            Meter {
                                label: (wifiName.value || i18n("Network")) + ""
                                value: "↓ " + panel.rate(netDown.value) + "  ↑ " + panel.rate(netUp.value)
                                fraction: panel.num(wifiSignal.value) / 100
                                hint: wifiName.value ? i18n("Wi-Fi signal %1 %", Math.round(panel.num(wifiSignal.value))) : ""
                            }
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    visible: panel.errorText !== ""
                    text: panel.errorText
                    color: root.red
                    font.pixelSize: 10
                    wrapMode: Text.WordWrap
                }

                // Footer
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "Linux " + (kernel.value || "")
                        color: root.dim
                        font.family: root.mono
                        font.pixelSize: 10
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: i18n("Up %1", panel.duration(uptime.value))
                        color: root.dim
                        font.family: root.mono
                        font.pixelSize: 10
                    }
                }
            }
        }
    }
}
