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

namespace Hyprdesktop {

    int BarDeco::barHeight() {
        return g_config.barHeight ? g_config.barHeight->value() : 24;
    }

    static bool barsWhenHidden() {
        return g_config.barsWhenHidden && g_config.barsWhenHidden->value();
    }

    CBarDeco::CBarDeco(PHLWINDOW w) : IHyprWindowDecoration(w), m_window(w) {
        m_mouseButton = Event::bus()->m_events.input.mouse.button.listen(
            [this](IPointer::SButtonEvent e, Event::SCallbackInfo& info) { onMouseButton(info, e); });
    }

    SDecorationPositioningInfo CBarDeco::getPositioningInfo() {
        SDecorationPositioningInfo info;
        info.policy         = DECORATION_POSITION_STICKY;
        info.edges          = DECORATION_EDGE_TOP;
        info.priority       = 9990;
        info.reserved       = true;
        info.desiredExtents = {{0.0, (double)BarDeco::barHeight()}, {0.0, 0.0}};
        return info;
    }

    void CBarDeco::onPositioningReply(const SDecorationPositioningReply&) {}

    eDecorationType  CBarDeco::getDecorationType() {
        return DECORATION_CUSTOM;
    }
    eDecorationLayer CBarDeco::getDecorationLayer() {
        return DECORATION_LAYER_UNDER;
    }
    uint64_t CBarDeco::getDecorationFlags() {
        return DECORATION_ALLOWS_MOUSE_INPUT | DECORATION_PART_OF_MAIN_WINDOW;
    }
    std::string CBarDeco::getDisplayName() {
        return "Hyprdesktop Titlebar";
    }

    CBox CBarDeco::barLayoutBox() const {
        return g_pDecorationPositioner->getWindowDecorationBox(const_cast<CBarDeco*>(this));
    }

    CBarDeco::SButtons CBarDeco::buttonBoxes(const CBox& box) const {
        SButtons      b;
        const double  bs    = box.h * 0.45;
        const double  pad   = (box.h - bs) / 2.0;
        double        right = box.x + box.w - pad - bs;
        b.close            = {right, box.y + pad, bs, bs};
        right -= (bs + pad);
        b.fullscreen = {right, box.y + pad, bs, bs};
        right -= (bs + pad);
        b.minimize = {right, box.y + pad, bs, bs};
        return b;
    }

    bool CBarDeco::inputIsValid() const {
        const auto w = m_window.lock();
        if (!w || !DesktopMode::pluginEnabled() || !w->m_isMapped)
            return false;

        const auto atCursor = g_pCompositor->vectorToWindowUnified(g_pInputManager->getMouseCoordsInternal(),
                                                                   Desktop::View::RESERVED_EXTENTS | Desktop::View::INPUT_EXTENTS |
                                                                       Desktop::View::ALLOW_FLOATING);
        return atCursor == w;
    }

    void CBarDeco::onMouseButton(Event::SCallbackInfo& info, IPointer::SButtonEvent e) {
        // End drag on release even when the cursor left this window (otherwise LMB-up
        // is missed and move mode stays active until another click).
        if (m_dragging) {
            if (e.state == WL_POINTER_BUTTON_STATE_RELEASED)
                handleUp(info);
            return;
        }

        if (!inputIsValid())
            return;

        const auto bar    = barLayoutBox();
        const auto coords = g_pInputManager->getMouseCoordsInternal();
        if (!bar.containsPoint(coords))
            return;

        if (e.state == WL_POINTER_BUTTON_STATE_PRESSED)
            handleDown(info, coords);
    }

    void CBarDeco::handleDown(Event::SCallbackInfo& info, const Vector2D& coords) {
        const auto w = m_window.lock();
        if (!w)
            return;

        const CBox     bar  = barLayoutBox();
        const SButtons btns = buttonBoxes(bar);

        if (btns.close.containsPoint(coords)) {
            w->sendClose();
            info.cancelled = true;
            return;
        }
        if (btns.fullscreen.containsPoint(coords)) {
            const auto cur = w->m_fullscreenState.internal;
            g_pCompositor->setWindowFullscreenInternal(w, cur == FSMODE_FULLSCREEN ? FSMODE_NONE : FSMODE_FULLSCREEN);
            info.cancelled = true;
            return;
        }
        if (btns.minimize.containsPoint(coords)) {
            Ghosting::hide(w);
            info.cancelled = true;
            return;
        }

        Desktop::focusState()->fullWindowFocus(w, Desktop::FOCUS_REASON_CLICK);
        if (w->m_isFloating)
            g_pCompositor->changeWindowZOrder(w, true);

        // Start Hyprland move mode immediately on press so the grab offset matches the
        // click point (deferred start on mouse-move caused a fixed titlebar offset).
        CKeybindManager::changeMouseBindMode(MBIND_MOVE);
        m_dragging     = true;
        info.cancelled = true;
    }

    void CBarDeco::handleUp(Event::SCallbackInfo& info) {
        if (m_dragging)
            CKeybindManager::changeMouseBindMode(MBIND_INVALID);
        m_dragging     = false;
        info.cancelled = true;
    }

    void CBarDeco::draw(PHLMONITOR pMonitor, float const& a) {
        const auto w = m_window.lock();
        if (!w || !pMonitor)
            return;
        if (w->isHidden() && !barsWhenHidden())
            return;

        const CBox     layoutBox = barLayoutBox();
        const SButtons btns      = buttonBoxes(layoutBox);

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
        g_pHyprRenderer->damageBox(barLayoutBox());
    }

    bool CBarDeco::onInputOnDeco(const eInputType, const Vector2D&, std::any) {
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
            const bool should   = DesktopMode::pluginEnabled() && w->m_isFloating && DesktopMode::isManaged(w) && CsdPolicy::wantsServerBar(w);
            auto*      existing = findOurDeco(w);

            if (should && !existing)
                HyprlandAPI::addWindowDecoration(PHANDLE, w, makeUnique<CBarDeco>(w));
            else if (!should && existing)
                HyprlandAPI::removeWindowDecoration(PHANDLE, existing);
        }

        void cleanup() {
            std::vector<IHyprWindowDecoration*> decos;
            for (const auto& w : g_pCompositor->m_windows) {
                if (!w)
                    continue;
                for (auto& d : w->m_windowDecorations) {
                    if (dynamic_cast<CBarDeco*>(d.get()))
                        decos.push_back(d.get());
                }
            }
            for (auto* d : decos)
                HyprlandAPI::removeWindowDecoration(PHANDLE, d);

            for (auto& m : g_pCompositor->m_monitors)
                m->m_scheduledRecalc = true;
        }

    }

}
