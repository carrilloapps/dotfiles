#!/usr/bin/env python3
"""Plasma 6.8 removed Plasma::Applet::globalConfig(). This patch adds an
equivalent helper (same location: the AppletGlobals/<plugin id> group in the
Corona config) and uses it in appgridpanelplugin.cpp.
Usage: plasma68-globalconfig.patch.py FILE.cpp
"""
import sys
from pathlib import Path

p = Path(sys.argv[1])
s = p.read_text()
if "appletGlobalConfig" in s:
    sys.exit(0)
helper = '''#include <KConfigGroup>
#include <KSharedConfig>
#include <Plasma/Containment>
#include <Plasma/Corona>

// Plasma 6.8 removed Applet::globalConfig(): same logic Plasma used.
static KConfigGroup appletGlobalConfig(const Plasma::Applet *applet)
{
    KSharedConfig::Ptr cfg = KSharedConfig::openConfig();
    if (auto *cont = applet->containment(); cont && cont->corona()) {
        cfg = cont->corona()->config();
    }
    KConfigGroup globals(cfg, QStringLiteral("AppletGlobals"));
    return KConfigGroup(&globals, applet->pluginMetaData().pluginId());
}
'''
assert "#include <KConfigGroup>\n" in s
s = s.replace("#include <KConfigGroup>\n", helper, 1)
s = s.replace("globalConfig()", "appletGlobalConfig(this)")
p.write_text(s)
print("Plasma 6.8 patch applied to", p.name)
