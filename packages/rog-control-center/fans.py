"""Writes the RedRog fan curves page (pages/fans.slint) for ROG Control Center:
two segmented controls (profile, fan) instead of nested tabs, and one card
with the curve and its actions for the chosen pair. Same data and callbacks
as the original page (nine profile/fan pairs). Used by redrog-theme.py."""

PROFILES = [("Balanced", "balanced"), ("Performance", "performance"), ("Quiet", "quiet")]
FANS = [("CPU", "cpu", "CPU"), ("Middle", "mid", "Mid"), ("GPU", "gpu", "GPU")]

HEAD = '''// RedRog fan curves page (packages/rog-control-center/fans.py)
import { Graph, Node } from "../widgets/graph.slint";
import { Profile, FanType, FanPageData } from "../types/fan_types.slint";
import { RRButton, RRCheckBox, RRSegmented } from "widgets/rr.slint";
import { RR } from "globals.slint";

component FanCard inherits Rectangle {
    in-out property <bool> enabled: false;
    in-out property <bool> tab_enabled: true;
    in-out property <[Node]> nodes;
    callback apply();
    callback cancel();
    callback default();
    callback toggled();

    border-radius: 14px;
    background: RR.ink.with-alpha(0.05);
    border-width: 1px;
    border-color: RR.ink.with-alpha(0.08);

    VerticalLayout {
        padding: 14px;
        spacing: 10px;
        if root.tab_enabled: Graph {
            nodes <=> root.nodes;
        }
        if !root.tab_enabled: Rectangle {
            Text {
                text: @tr("FanTab" => "This fan is not avilable on this machine");
                color: RR.dim;
                font-size: 15px;
            }
        }
        Rectangle {
            height: 1px;
            background: RR.ink.with-alpha(0.08);
        }
        HorizontalLayout {
            spacing: 10px;
            alignment: LayoutAlignment.end;
            RRCheckBox {
                text: @tr("FanTab" => "Enabled");
                checked <=> root.enabled;
                enabled <=> root.tab_enabled;
                toggled => {
                    root.toggled();
                }
            }
            RRButton {
                text: @tr("FanTab" => "Factory Default (all fans)");
                enabled: root.tab_enabled;
                clicked => {
                    root.default();
                }
            }
            RRButton {
                text: @tr("FanTab" => "Cancel");
                enabled: root.tab_enabled;
                clicked => {
                    root.cancel();
                }
            }
            RRButton {
                text: @tr("FanTab" => "Apply");
                primary: true;
                enabled: root.tab_enabled;
                clicked => {
                    root.apply();
                }
            }
        }
    }
}

export component PageFans inherits VerticalLayout {
    property <int> profile: 0;
    property <int> fan: 0;
    padding: 28px;
    padding-top: 22px;
    spacing: 12px;

    HorizontalLayout {
        spacing: 12px;
        vertical-stretch: 0;
        RRSegmented {
            model: [@tr("Balanced"), @tr("Performance"), @tr("Quiet")];
            current-index <=> root.profile;
        }
        RRSegmented {
            model: [@tr("CPU"), @tr("Mid"), @tr("GPU")];
            current-index <=> root.fan;
        }
    }
'''

CARD = '''
    if root.profile == {pi} && root.fan == {fi}: FanCard {{
        tab_enabled <=> FanPageData.{fan}_fan_available;
        enabled <=> FanPageData.{prof}_{fan}_enabled;
        nodes <=> FanPageData.{prof}_{fan};
        apply => {{
            FanPageData.set_fan_data(FanType.{ftype}, Profile.{pname}, self.enabled, FanPageData.{prof}_{fan});
        }}
        toggled => {{
            FanPageData.set_fan_data(FanType.{ftype}, Profile.{pname}, self.enabled, FanPageData.{prof}_{fan});
        }}
        default => {{
            FanPageData.set_profile_default(Profile.{pname});
        }}
    }}
'''


def page() -> str:
    out = HEAD
    for pi, (pname, prof) in enumerate(PROFILES):
        for fi, (ftype, fan, _) in enumerate(FANS):
            out += CARD.format(pi=pi, fi=fi, pname=pname, prof=prof, ftype=ftype, fan=fan)
    return out + "}\n"
