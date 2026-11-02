#include "redrogglass.h"

#include <effect/effecthandler.h>
#include <effect/effectwindow.h>
#include <scene/surfaceitem.h>
#include <scene/windowitem.h>

#include <KConfigGroup>
#include <KSharedConfig>

namespace KWin
{

RedRogGlassEffect::RedRogGlassEffect()
{
    reconfigure(ReconfigureAll);
    connect(effects, &EffectsHandler::windowAdded, this, &RedRogGlassEffect::apply);
    const auto windows = effects->stackingOrder();
    for (EffectWindow *w : windows) {
        apply(w);
    }
}

bool RedRogGlassEffect::supported()
{
    return effects->isOpenGLCompositing();
}

bool RedRogGlassEffect::enabledByDefault()
{
    return false;
}

void RedRogGlassEffect::reconfigure(ReconfigureFlags)
{
    // [Effect-redrogglass] in kwinrc: WindowClasses (one per line) and
    // Opacity (percent, the title bar's opacity)
    const KConfigGroup group = KSharedConfig::openConfig(QStringLiteral("kwinrc"))->group(QStringLiteral("Effect-redrogglass"));
    m_classes = group.readEntry("WindowClasses", QStringLiteral("systemsettings\norg.kde.discover\norg.kde.plasma-systemmonitor\norg.kde.kinfocenter"))
                    .split(QLatin1Char('\n'), Qt::SkipEmptyParts);
    m_opacity = group.readEntry("Opacity", 77) / 100.0;
    const auto windows = effects->stackingOrder();
    for (EffectWindow *w : windows) {
        apply(w);
    }
}

bool RedRogGlassEffect::matches(EffectWindow *w) const
{
    if (!w || w->isDesktop() || w->isDock() || w->isPopupWindow()) {
        return false;
    }
    // windowClass() is "resourceName resourceClass"
    const QStringList parts = w->windowClass().split(QLatin1Char(' '), Qt::SkipEmptyParts);
    for (const QString &part : parts) {
        if (m_classes.contains(part)) {
            return true;
        }
    }
    return false;
}

void RedRogGlassEffect::apply(EffectWindow *w)
{
    if (!matches(w)) {
        return;
    }
    // KWin's own blur behind the whole window, as the title bar has
    w->setData(WindowForceBlurRole, QVariant(true));
    w->addRepaintFull();
}

void RedRogGlassEffect::prePaintWindow(RenderView *view, EffectWindow *w, WindowPrePaintData &data)
{
    if (matches(w)) {
        // only the content goes translucent; the decoration keeps its look
        if (WindowItem *item = w->windowItem()) {
            if (SurfaceItem *surface = item->surfaceItem()) {
                if (surface->opacity() != m_opacity) {
                    surface->setOpacity(m_opacity);
                }
            }
        }
        data.setTranslucent();
    }
    effects->prePaintWindow(view, w, data);
}

bool RedRogGlassEffect::isActive() const
{
    return !m_classes.isEmpty();
}

int RedRogGlassEffect::requestedEffectChainPosition() const
{
    return 5;
}

} // namespace KWin
