#include "Layout.hpp"
#include "BarDeco.hpp"

#include <hyprland/src/Compositor.hpp>
#include <hyprland/src/desktop/view/Window.hpp>
#include <hyprland/src/desktop/state/FocusState.hpp>
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
    static int topReserved() {
        return g_config.topReservedPx ? g_config.topReservedPx->value() : 36;
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

        // Monitor m_size/m_position are already in logical (scaled) coordinates.
        const Vector2D mSize = mon->m_size;
        const Vector2D mPos  = mon->m_position;
        const int      bar   = topReserved();

        // Shrink any axis that fills the monitor.
        double tw = (refSize.x >= mSize.x * fullFraction()) ? std::floor(mSize.x * shrinkFraction()) : refSize.x;
        double th = (refSize.y >= mSize.y * fullFraction()) ? std::floor(mSize.y * shrinkFraction()) : refSize.y;

        // Usable area is full width but excludes the top bar.
        const double uw = mSize.x;
        const double uh = mSize.y - bar;
        tw              = std::min(tw, uw);
        th              = std::min(th, uh);

        const double x = std::floor(mPos.x + (uw - tw) / 2.0);
        const double y = std::floor(mPos.y + bar + (uh - th) / 2.0);

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

        place(w, refSize);
        BarDeco::reconsider(w); // became floating -> attach the titlebar
    }

}
