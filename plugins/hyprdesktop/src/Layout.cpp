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
#include <hyprland/src/render/decorations/DecorationPositioner.hpp>

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

    // Prefer layer-shell reserved area (Quickshell bar). Guarantee at least the config
    // fallback so layout is correct even if QS hasn't registered its exclusive zone yet.
    static CBox workArea(const PHLMONITOR& mon) {
        const Vector2D mPos  = mon->m_position;
        const Vector2D mSize = mon->m_size;
        const CBox     monBox{mPos.x, mPos.y, mSize.x, mSize.y};
        const double   minTop = mPos.y + configTopReserved();

        if (mon->m_reservedArea.ok()) {
            const CBox work = mon->m_reservedArea.apply(monBox);
            if (work.w > 0 && work.h > 0) {
                if (work.y < minTop) {
                    const double delta = minTop - work.y;
                    return {work.x, minTop, work.w, work.h - delta};
                }
                return work;
            }
        }

        return {mPos.x, minTop, mSize.x, mSize.y - configTopReserved()};
    }

    static bool fillsWorkArea(const Vector2D& size, const CBox& work) {
        return size.x >= work.w * fullFraction() || size.y >= work.h * fullFraction();
    }

    static void applyGeometry(const PHLWINDOW& w, const Vector2D& pos, const Vector2D& size) {
        w->m_realPosition->setValueAndWarp(pos);
        w->m_realSize->setValueAndWarp(size);
        w->m_position = pos;
        w->m_size     = size;
        w->sendWindowSize(true);
        g_pDecorationPositioner->forceRecalcFor(w);
        w->updateWindowDecos();
    }

    void place(const PHLWINDOW& w, const Vector2D& refSize) {
        if (!w || !w->m_isFloating || !w->m_monitor)
            return;
        const auto mon = w->m_monitor.lock();
        if (!mon)
            return;

        // Center in the monitor work area (below the Quickshell bar). Do NOT manually
        // inset for the SSD titlebar — reserved decoration extents are applied by the
        // positioner when updateWindowDecos() runs (avoids a fixed drag offset).
        const CBox   work = workArea(mon);
        const double uw   = work.w;
        const double uh   = work.h;

        double tw = (refSize.x >= work.w * fullFraction()) ? std::floor(work.w * shrinkFraction()) : refSize.x;
        double th = (refSize.y >= work.h * fullFraction()) ? std::floor(work.h * shrinkFraction()) : refSize.y;
        tw        = std::min(tw, uw);
        th        = std::min(th, uh);

        const double x = std::floor(work.x + (uw - tw) / 2.0);
        const double y = std::floor(work.y + (uh - th) / 2.0);

        applyGeometry(w, {x, y}, {tw, th});
    }

    void placeNewFloat(const PHLWINDOW& w) {
        if (!w || !w->m_monitor)
            return;
        const auto mon = w->m_monitor.lock();
        if (!mon)
            return;
        const CBox     work = workArea(mon);
        const Vector2D sz   = w->m_realSize->value();
        // Only reshape floats that fill the monitor — leave app-sized floats alone.
        if (fillsWorkArea(sz, work))
            place(w, sz);
    }

    void smartFloat() {
        const auto w = Desktop::focusState()->window();
        if (!w)
            return;

        const bool     wasFloating = w->m_isFloating;
        const Vector2D refSize     = w->m_realSize->value();

        if (const auto it = g_pKeybindManager->m_dispatchers.find("togglefloating"); it != g_pKeybindManager->m_dispatchers.end())
            it->second("");

        if (wasFloating) {
            BarDeco::reconsider(w);
            return;
        }

        if (!w->m_isFloating)
            return;

        BarDeco::reconsider(w);
        place(w, refSize);
    }

}
