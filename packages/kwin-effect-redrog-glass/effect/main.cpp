#include "redrogglass.h"

namespace KWin
{
KWIN_EFFECT_FACTORY_SUPPORTED_ENABLED(RedRogGlassEffect, "metadata.json", return RedRogGlassEffect::supported();, return RedRogGlassEffect::enabledByDefault();)
}

#include "main.moc"
