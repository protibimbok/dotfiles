#include "Layout.hpp"
#include "BarDeco.hpp"
#include "CsdPolicy.hpp"
#include "DesktopMode.hpp"

#include <hyprland/src/Compositor.hpp>
#include <hyprland/src/desktop/view/Window.hpp>
#include <hyprland/src/desktop/state/FocusState.hpp>
#include <hyprland/src/desktop/reserved/ReservedArea.hpp>
#include <hyprland/src/helpers/Monitor.hpp>
#include <hyprland/src/managers/KeybindManager.hpp>

#include <cmath>

namespace Hyprdesktop::Layout {

    static double fullFraction() {
        return g_config.fullFraction ? g_config.fullFraction->value() : 0.95;
    }
    static double shrinkFraction() {
        return g_config.shrinkFraction ? g_config.shrinkFraction->value() : 0.80;
    }
    static int configTopReserved() {
        return g_config.topReservedPx ? g_config.topReservedPx->value() : 36;
    }

    // Prefer the live layer-shell exclusive zone (Quickshell bar); fall back to config.
    static CBox workArea(const PHLMONITOR& mon) {
        const Vector2D mPos  = mon->m_position;
        const Vector2D mSize = mon->m_size;
        const CBox     monBox{mPos.x, mPos.y, mSize.x, mSize.y};

        if (mon->m_reservedArea.ok()) {
            const CBox work = mon->m_reservedArea.apply(monBox);
            if (work.w > 0 && work.h > 0)
                return work;
        }

        const int top = configTopReserved();
        return {mPos.x, mPos.y + top, mSize.x, mSize.y - top};
    }

    static void applyGeometry(const PHLWINDOW& w, const Vector2D& pos, const Vector2D& size) {
        w->m_realPosition->setValueAndWarp(pos);
        w->m_realSize->setValueAndWarp(size);
        w->m_position = pos;
        w->m_size     = size;
        w->sendWindowSize(true);
        w->updateWindowDecos();
    }

    void place(const PHLWINDOW& w, const Vector2D& refSize) {
        if (!w || !w->m_monitor)
            return;
        const auto mon = w->m_monitor.lock();
        if (!mon)
            return;

        // Monitor coords are logical. workArea() reflects the Quickshell bar via layer-shell
        // reserved area; SSD titlebar height is reserved inside that box.
        const CBox   work     = workArea(mon);
        const double ssdBar   = (DesktopMode::isManaged(w) && CsdPolicy::wantsServerBar(w)) ? BarDeco::barHeight() : 0.0;
        const double uw       = work.w;
        const double uh       = work.h - ssdBar;

        // Shrink any axis that fills the work area.
        double tw = (refSize.x >= work.w * fullFraction()) ? std::floor(work.w * shrinkFraction()) : refSize.x;
        double th = (refSize.y >= work.h * fullFraction()) ? std::floor(work.h * shrinkFraction()) : refSize.y;
        tw        = std::min(tw, uw);
        th        = std::min(th, uh);

        const double x = std::floor(work.x + (uw - tw) / 2.0);
        const double y = std::floor(work.y + ssdBar + (uh - th) / 2.0);

        applyGeometry(w, {x, y}, {tw, th});
    }

    void placeNewFloat(const PHLWINDOW& w) {
        if (!w)
            return;
        place(w, w->m_realSize->goal());
    }

    void smartFloat() {
        const auto w = Desktop::focusState()->window();
        if (!w)
            return;

        const bool     wasFloating = w->m_isFloating;
        const Vector2D refSize     = w->m_realSize->value(); // pre-toggle size

        // Reuse the built-in dispatcher so float/tile toggling matches Hyprland exactly.
        if (const auto it = g_pKeybindManager->m_dispatchers.find("togglefloating"); it != g_pKeybindManager->m_dispatchers.end())
            it->second("");

        if (wasFloating) {
            BarDeco::reconsider(w); // became tiled -> drop the titlebar
            return;
        }

        BarDeco::reconsider(w); // attach titlebar before place so SSD inset is applied
        place(w, refSize);
    }

}
