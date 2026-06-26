#include "BarDeco.hpp"
#include "DesktopMode.hpp"
#include "CsdPolicy.hpp"
#include "Ghosting.hpp"

#include <hyprland/src/Compositor.hpp>
#include <hyprland/src/desktop/view/Window.hpp>
#include <hyprland/src/desktop/Workspace.hpp>
#include <hyprland/src/desktop/state/FocusState.hpp>
#include <hyprland/src/helpers/Monitor.hpp>
#include <hyprland/src/helpers/Color.hpp>
#include <hyprland/src/render/Renderer.hpp>
#include <hyprland/src/render/pass/RectPassElement.hpp>
#include <hyprland/src/render/decorations/DecorationPositioner.hpp>
#include <hyprland/src/managers/KeybindManager.hpp>
#include <hyprland/src/managers/input/InputManager.hpp>
#include <hyprland/src/devices/IPointer.hpp>

namespace Hyprdesktop {

    int BarDeco::barHeight() {
        return g_config.barHeight ? g_config.barHeight->value() : 24;
    }

    static bool barsWhenHidden() {
        return g_config.barsWhenHidden && g_config.barsWhenHidden->value();
    }

    CBarDeco::CBarDeco(PHLWINDOW w) : IHyprWindowDecoration(w), m_window(w) {}

    SDecorationPositioningInfo CBarDeco::getPositioningInfo() {
        SDecorationPositioningInfo info;
        info.policy         = DECORATION_POSITION_STICKY;
        info.edges          = DECORATION_EDGE_TOP;
        info.priority       = 9990;
        info.reserved       = true;
        info.desiredExtents = {{0.0, (double)BarDeco::barHeight()}, {0.0, 0.0}};
        return info;
    }

    void CBarDeco::onPositioningReply(const SDecorationPositioningReply&) {
        // Geometry is queried live from the positioner in barLayoutBox().
    }

    eDecorationType  CBarDeco::getDecorationType() {
        return DECORATION_CUSTOM;
    }
    eDecorationLayer CBarDeco::getDecorationLayer() {
        return DECORATION_LAYER_OVER;
    }
    uint64_t CBarDeco::getDecorationFlags() {
        return DECORATION_ALLOWS_MOUSE_INPUT;
    }
    std::string CBarDeco::getDisplayName() {
        return "Hyprdesktop Titlebar";
    }

    CBox CBarDeco::barLayoutBox() const {
        return g_pDecorationPositioner->getWindowDecorationBox(const_cast<CBarDeco*>(this));
    }

    CBarDeco::SButtons CBarDeco::buttonBoxes(const CBox& box) const {
        SButtons      b;
        const double  bs    = box.h * 0.45; // button diameter
        const double  pad   = (box.h - bs) / 2.0;
        double        right = box.x + box.w - pad - bs;
        b.close      = {right, box.y + pad, bs, bs};
        right -= (bs + pad);
        b.fullscreen = {right, box.y + pad, bs, bs};
        right -= (bs + pad);
        b.minimize   = {right, box.y + pad, bs, bs};
        return b;
    }

    void CBarDeco::draw(PHLMONITOR pMonitor, float const& a) {
        const auto w = m_window.lock();
        if (!w || !pMonitor)
            return;
        if (w->isHidden() && !barsWhenHidden())
            return;

        const CBox    layoutBox = barLayoutBox();
        const SButtons btns     = buttonBoxes(layoutBox);

        auto toScaled = [&](CBox b) {
            b.translate(-pMonitor->m_position).scale(pMonitor->m_scale).round();
            return b;
        };
        auto addRect = [&](const CBox& b, const CHyprColor& c, int round) {
            CRectPassElement::SRectData rd;
            rd.box   = b;
            rd.color = c;
            rd.round = round;
            g_pHyprRenderer->m_renderPass.add(makeUnique<CRectPassElement>(rd));
        };

        addRect(toScaled(layoutBox), CHyprColor{0.13, 0.13, 0.16, a}, 0);

        const int r = (int)((btns.close.h * pMonitor->m_scale) / 2.0);
        addRect(toScaled(btns.minimize), CHyprColor{0.96, 0.77, 0.27, a}, r);
        addRect(toScaled(btns.fullscreen), CHyprColor{0.30, 0.79, 0.36, a}, r);
        addRect(toScaled(btns.close), CHyprColor{0.92, 0.34, 0.34, a}, r);
    }

    void CBarDeco::updateWindow(PHLWINDOW) {
        damageEntire();
    }

    void CBarDeco::damageEntire() {
        const auto w = m_window.lock();
        if (!w)
            return;
        CBox b = barLayoutBox();
        g_pHyprRenderer->damageBox(b);
    }

    bool CBarDeco::onInputOnDeco(const eInputType type, const Vector2D& coords, std::any data) {
        const auto w = m_window.lock();
        if (!w)
            return false;

        const CBox     bar  = barLayoutBox();
        const SButtons btns = buttonBoxes(bar);

        if (type == INPUT_TYPE_BUTTON) {
            IPointer::SButtonEvent e;
            try {
                e = std::any_cast<IPointer::SButtonEvent>(data);
            } catch (const std::bad_any_cast&) {
                return false;
            }
            if (e.state != WL_POINTER_BUTTON_STATE_PRESSED)
                return true; // swallow the release too

            if (btns.close.containsPoint(coords)) {
                w->sendClose();
                return true;
            }
            if (btns.fullscreen.containsPoint(coords)) {
                const auto cur = w->m_fullscreenState.internal;
                g_pCompositor->setWindowFullscreenInternal(w, cur == FSMODE_FULLSCREEN ? FSMODE_NONE : FSMODE_FULLSCREEN);
                return true;
            }
            if (btns.minimize.containsPoint(coords)) {
                Ghosting::hide(w);
                return true;
            }
            return true;
        }

        if (type == INPUT_TYPE_DRAG_START) {
            // Pressing a control starts no drag.
            if (btns.close.containsPoint(coords) || btns.fullscreen.containsPoint(coords) || btns.minimize.containsPoint(coords))
                return true;
            // Drag the titlebar body to move — no SUPER needed (replaces SUPER+LMB drag).
            Desktop::focusState()->fullWindowFocus(w, Desktop::FOCUS_REASON_CLICK);
            CKeybindManager::changeMouseBindMode(MBIND_MOVE);
            return true;
        }

        if (type == INPUT_TYPE_DRAG_END) {
            CKeybindManager::changeMouseBindMode(MBIND_INVALID);
            return true;
        }

        return false;
    }

    namespace BarDeco {

        static CBarDeco* findOurDeco(const PHLWINDOW& w) {
            for (auto& d : w->m_windowDecorations) {
                if (auto* p = dynamic_cast<CBarDeco*>(d.get()))
                    return p;
            }
            return nullptr;
        }

        void reconsider(const PHLWINDOW& w) {
            if (!w)
                return;
            const bool should = DesktopMode::pluginEnabled() && w->m_isFloating && DesktopMode::isManaged(w) && CsdPolicy::wantsServerBar(w);
            auto*      existing = findOurDeco(w);

            if (should && !existing)
                HyprlandAPI::addWindowDecoration(PHANDLE, w, makeUnique<CBarDeco>(w));
            else if (!should && existing)
                HyprlandAPI::removeWindowDecoration(PHANDLE, existing);
        }

    }

}
