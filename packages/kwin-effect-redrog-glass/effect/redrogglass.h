// RedRog glass: makes the content of chosen windows translucent (the title
// bar keeps its own look) and asks KWin's own blur behind them, so apps that
// paint an opaque background (System Settings, Discover...) get the same glass
// as their title bar and as Dolphin or kitty, active or not.
#pragma once

#include <effect/effect.h>

#include <QStringList>

namespace KWin
{

class RedRogGlassEffect : public Effect
{
    Q_OBJECT

public:
    RedRogGlassEffect();

    void reconfigure(ReconfigureFlags flags) override;
    void prePaintWindow(RenderView *view, EffectWindow *w, WindowPrePaintData &data) override;
    bool isActive() const override;
    int requestedEffectChainPosition() const override;

    static bool supported();
    static bool enabledByDefault();

private:
    bool matches(EffectWindow *w) const;
    void apply(EffectWindow *w);

    QStringList m_classes;
    qreal m_opacity = 0.77;
};

} // namespace KWin
