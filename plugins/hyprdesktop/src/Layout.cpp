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
#include <hyprland/src/layout/LayoutManager.hpp>
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

    static double decoReservedTop(const PHLWINDOW& w) {
        g_pDecorationPositioner->forceRecalcFor(w);
        w->updateWindowDecos();
        double top = g_pDecorationPositioner->getWindowDecorationReserved(w).topLeft.y;
        if (top <= 0 && DesktopMode::isManaged(w) && CsdPolicy::wantsServerBar(w))
            top = BarDeco::titlebarHeight();
        return top;
    }

    static void warpGeometry(const PHLWINDOW& w, const Vector2D& pos, const Vector2D& size) {
        w->m_realPosition->setValueAndWarp(pos);
        w->m_realSize->setValueAndWarp(size);
        w->m_position = pos;
        w->m_size     = size;
        w->sendWindowSize(true);
    }

    static void ensureBelowTopBar(const PHLWINDOW& w, const CBox& work) {
        const CBox full = w->getFullWindowBoundingBox();
        if (full.y < work.y) {
            const Vector2D p = w->m_realPosition->value();
            warpGeometry(w, {p.x, p.y + (work.y - full.y)}, w->m_realSize->value());
            w->updateWindowDecos();
        }
    }

    Vector2D clampFloatPosition(const PHLWINDOW& w, const Vector2D& pos) {
        if (!w || !w->m_isFloating || !w->m_monitor)
            return pos;
        if (!DesktopMode::isManaged(w) || !CsdPolicy::wantsServerBar(w))
            return pos;

        const auto mon = w->m_monitor.lock();
        if (!mon)
            return pos;

        const CBox   work     = workArea(mon);
        const double reserved = decoReservedTop(w);
        if (pos.y - reserved < work.y)
            return {pos.x, work.y + reserved};
        return pos;
    }

    void commitFloatGeom(const PHLWINDOW& w) {
        if (!w || !w->m_isFloating)
            return;
        const auto target = w->layoutTarget();
        if (!target)
            return;
        // The float's layout geometry is its main-surface box (global coords). Syncing
        // it keeps Hyprland's record in step with the geometry the plugin warped.
        ::g_layoutManager->setTargetGeom(w->getWindowMainSurfaceBox(), target);
    }

    void stabilizeManagedFloat(const PHLWINDOW& w) {
        if (!w || !w->m_monitor)
            return;
        const auto mon = w->m_monitor.lock();
        if (!mon)
            return;
        ensureBelowTopBar(w, workArea(mon));
    }

    void fillWorkArea(const PHLWINDOW& w) {
        if (!w || !w->m_isFloating || !w->m_monitor)
            return;
        const auto mon = w->m_monitor.lock();
        if (!mon)
            return;

        const CBox   work = workArea(mon);
        const double barH = decoReservedTop(w);
        warpGeometry(w, {work.x, work.y + barH}, {work.w, work.h - barH});
        w->updateWindowDecos();
        ensureBelowTopBar(w, work);
        commitFloatGeom(w);
    }

    void place(const PHLWINDOW& w, const Vector2D& refSize) {
        if (!w || !w->m_isFloating || !w->m_monitor)
            return;
        const auto mon = w->m_monitor.lock();
        if (!mon)
            return;

        const CBox   work = workArea(mon);
        const double uw   = work.w;
        const double uh   = work.h;
        const double barH = decoReservedTop(w);

        double tw = (refSize.x >= work.w * fullFraction()) ? std::floor(work.w * shrinkFraction()) : refSize.x;
        double th = (refSize.y >= work.h * fullFraction()) ? std::floor(work.h * shrinkFraction()) : refSize.y;
        tw        = std::min(tw, uw);
        th        = std::min(th, std::max(0.0, uh - barH));

        const double x       = std::floor(work.x + (uw - tw) / 2.0);
        const double totalH  = th + barH;
        const double fullTop = std::floor(work.y + (uh - totalH) / 2.0);
        const double y       = fullTop + barH;

        warpGeometry(w, {x, y}, {tw, th});
        w->updateWindowDecos();

        // One stabilization pass: if the positioner nudged the unified box, correct it
        // now so the first titlebar grab doesn't jump.
        const CBox full = w->getFullWindowBoundingBox();
        const double drift = fullTop - full.y;
        if (std::abs(drift) > 0.5) {
            const Vector2D p = w->m_realPosition->value();
            warpGeometry(w, {p.x, p.y + drift}, {tw, th});
            w->updateWindowDecos();
        }

        ensureBelowTopBar(w, work);
        commitFloatGeom(w);
    }

    void placeNewFloat(const PHLWINDOW& w) {
        if (!w || !w->m_monitor)
            return;
        const auto mon = w->m_monitor.lock();
        if (!mon)
            return;
        const CBox     work = workArea(mon);
        const Vector2D sz   = w->m_realSize->value();
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
