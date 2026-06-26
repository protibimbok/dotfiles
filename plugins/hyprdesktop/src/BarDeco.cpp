#include "BarDeco.hpp"
#include "DesktopMode.hpp"
#include "CsdPolicy.hpp"
#include "Ghosting.hpp"
#include "Layout.hpp"

#include <hyprland/src/Compositor.hpp>
#include <hyprland/src/desktop/view/Window.hpp>
#include <hyprland/src/desktop/state/FocusState.hpp>
#include <hyprland/src/helpers/Color.hpp>
#include <hyprland/src/render/Renderer.hpp>
#include <hyprland/src/render/pass/RectPassElement.hpp>
#include <hyprland/src/render/decorations/DecorationPositioner.hpp>
#include <hyprland/src/managers/input/InputManager.hpp>
#include <hyprland/src/managers/SeatManager.hpp>
#include <hyprland/src/devices/IKeyboard.hpp>
#include <hyprland/src/layout/LayoutManager.hpp>
#include <hyprland/src/desktop/Workspace.hpp>

#include <linux/input-event-codes.h>

namespace Hyprdesktop {

    static constexpr double BUTTON_PAD = 3.0;

    static CBox windowDamageBox(const PHLWINDOW& w) {
        CBox      box = w->getFullWindowBoundingBox();
        const int pad = std::max(w->getRealBorderSize(), 1);
        box.x -= pad;
        box.y -= pad;
        box.w += 2 * pad;
        box.h += 2 * pad;
        return box;
    }

    int BarDeco::buttonSize() {
        return g_config.barHeight ? (int)std::max(g_config.barHeight->value(), 6L) : 12;
    }

    int BarDeco::titlebarHeight() {
        return buttonSize() + (int)(BUTTON_PAD * 2.0);
    }

    int BarDeco::barHeight() {
        return titlebarHeight();
    }

    static bool barsWhenHidden() {
        return g_config.barsWhenHidden && g_config.barsWhenHidden->value();
    }

    // SUPER (logo/meta) held — the modifier that turns a left-drag into a window move.
    static bool superHeld() {
        const auto kb = g_pSeatManager->m_keyboard.lock();
        return kb && (kb->getModifiers() & HL_MODIFIER_META);
    }

    CBarDeco::CBarDeco(PHLWINDOW w) : IHyprWindowDecoration(w), m_window(w) {
        m_mouseButton = Event::bus()->m_events.input.mouse.button.listen(
            [this](IPointer::SButtonEvent e, Event::SCallbackInfo& info) { onMouseButton(info, e); });
        m_mouseMove = Event::bus()->m_events.input.mouse.move.listen(
            [this](Vector2D, Event::SCallbackInfo& info) { onMouseMove(info); });
    }

    SDecorationPositioningInfo CBarDeco::getPositioningInfo() {
        SDecorationPositioningInfo info;
        info.policy         = DECORATION_POSITION_STICKY;
        info.edges          = DECORATION_EDGE_TOP;
        info.priority       = 9990;
        info.reserved       = true;
        info.desiredExtents = {{0.0, (double)BarDeco::titlebarHeight()}, {0.0, 0.0}};
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

    CBarDeco::SButtons CBarDeco::buttonBoxes(const CBox& barBox) const {
        SButtons     b;
        const double bs  = BarDeco::buttonSize();
        const CBox   row = {barBox.x, barBox.y + BUTTON_PAD, barBox.w, bs};

        double right = row.x + row.w - bs;
        b.close      = {right, row.y, bs, bs};
        right -= (bs + BUTTON_PAD);
        b.fullscreen = {right, row.y, bs, bs};
        right -= (bs + BUTTON_PAD);
        b.minimize = {right, row.y, bs, bs};
        return b;
    }

    bool CBarDeco::isActionButton(const Vector2D& coords) const {
        const auto btns = buttonBoxes(barLayoutBox());
        return btns.close.containsPoint(coords) || btns.fullscreen.containsPoint(coords) || btns.minimize.containsPoint(coords);
    }

    void CBarDeco::toggleMaximize(const PHLWINDOW& w) {
        if (w->m_fullscreenState.internal != FSMODE_NONE)
            g_pCompositor->setWindowFullscreenInternal(w, FSMODE_NONE);

        if (m_savedGeom) {
            g_pHyprRenderer->damageBox(windowDamageBox(w));
            w->m_realPosition->setValueAndWarp(m_savedGeom->first);
            w->m_position = m_savedGeom->first;
            w->m_realSize->setValueAndWarp(m_savedGeom->second);
            w->m_size     = m_savedGeom->second;
            w->sendWindowSize(true);
            w->updateWindowDecos();
            m_savedGeom.reset();
            Layout::commitFloatGeom(w);
            g_pHyprRenderer->damageBox(windowDamageBox(w));
            return;
        }

        m_savedGeom = {{w->m_realPosition->value(), w->m_realSize->value()}};
        Layout::fillWorkArea(w);
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

    void CBarDeco::applyDragPosition(const PHLWINDOW& w, const Vector2D& pos) {
        const Vector2D clamped = Layout::clampFloatPosition(w, pos);
        const Vector2D cur     = w->m_realPosition->value();
        if (clamped == cur)
            return;

        g_pHyprRenderer->damageBox(windowDamageBox(w));

        w->m_realPosition->setValueAndWarp(clamped);
        w->m_position = clamped;
        w->sendWindowSize(true);
        w->updateWindowDecos();

        g_pHyprRenderer->damageBox(windowDamageBox(w));
    }

    bool CBarDeco::onInputOnDeco(const eInputType type, const Vector2D& coords, std::any data) {
        const auto w = m_window.lock();
        if (!w || !DesktopMode::pluginEnabled() || type != INPUT_TYPE_BUTTON)
            return false;

        IPointer::SButtonEvent e;
        try {
            e = std::any_cast<IPointer::SButtonEvent>(data);
        } catch (const std::bad_any_cast&) {
            return false;
        }
        if (e.state != WL_POINTER_BUTTON_STATE_PRESSED || !isActionButton(coords))
            return false;

        const SButtons btns = buttonBoxes(barLayoutBox());
        if (btns.close.containsPoint(coords)) {
            w->sendClose();
            return true;
        }
        if (btns.fullscreen.containsPoint(coords)) {
            toggleMaximize(w);
            return true;
        }
        if (btns.minimize.containsPoint(coords)) {
            Ghosting::hide(w);
            return true;
        }
        return false;
    }

    void CBarDeco::startDrag(Event::SCallbackInfo& info) {
        const auto w = m_window.lock();
        if (!w)
            return;

        Desktop::focusState()->fullWindowFocus(w, Desktop::FOCUS_REASON_CLICK);
        if (w->m_isFloating)
            g_pCompositor->changeWindowZOrder(w, true);

        const Vector2D cursor = g_pInputManager->getMouseCoordsInternal();
        m_grabOffset          = cursor - w->m_realPosition->value();
        m_dragging            = true;
        info.cancelled        = true;
    }

    void CBarDeco::onMouseMove(Event::SCallbackInfo& info) {
        const auto w = m_window.lock();
        if (!w) {
            m_dragging = false;
            return;
        }

        if (!m_dragging)
            return;

        const Vector2D cursor = g_pInputManager->getMouseCoordsInternal();
        applyDragPosition(w, cursor - m_grabOffset);
        info.cancelled = true;
    }

    void CBarDeco::endDrag(Event::SCallbackInfo& info) {
        m_dragging     = false;
        info.cancelled = true;
        if (const auto w = m_window.lock())
            Layout::commitFloatGeom(w); // sync layout record so a later resize doesn't jump
    }

    void CBarDeco::onMouseButton(Event::SCallbackInfo& info, IPointer::SButtonEvent e) {
        if (m_dragging) {
            if (e.state == WL_POINTER_BUTTON_STATE_RELEASED && e.button == BTN_LEFT)
                endDrag(info);
            return;
        }

        if (!inputIsValid())
            return;

        const auto coords = g_pInputManager->getMouseCoordsInternal();

        if (e.state != WL_POINTER_BUTTON_STATE_PRESSED || e.button != BTN_LEFT)
            return;

        // Action buttons are handled in onInputOnDeco; ignore them here.
        if (isActionButton(coords))
            return;

        // Titlebar drag (or SUPER+drag anywhere on the window) moves the float.
        // Window-border resizing is left to Hyprland's native resize_on_border so
        // the plugin and compositor never fight over the geometry (that fight was
        // the resize "jump").
        if (superHeld() || barLayoutBox().containsPoint(coords))
            startDrag(info);
    }

    void CBarDeco::draw(PHLMONITOR pMonitor, float const& a) {
        const auto w = m_window.lock();
        if (!w || !pMonitor)
            return;
        if (w->isHidden() && !barsWhenHidden())
            return;

        const CBox     bar  = barLayoutBox();
        const SButtons btns = buttonBoxes(bar);
        const int      round = (int)std::round(w->rounding() * pMonitor->m_scale);
        const float    roundPower = w->roundingPower();

        auto toScaled = [&](CBox b) {
            b.translate(-pMonitor->m_position).scale(pMonitor->m_scale).round();
            return b;
        };
        auto addRect = [&](const CBox& b, const CHyprColor& c, int intRound) {
            CRectPassElement::SRectData rd;
            rd.box           = b;
            rd.color         = c;
            rd.round         = intRound;
            rd.roundingPower = roundPower;
            g_pHyprRenderer->m_renderPass.add(makeUnique<CRectPassElement>(rd));
        };

        addRect(toScaled(bar), CHyprColor{0.13, 0.13, 0.16, a}, round);

        const int r = (int)std::round((btns.close.h * pMonitor->m_scale) / 2.0);
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

            if (should && !existing) {
                HyprlandAPI::addWindowDecoration(PHANDLE, w, makeUnique<CBarDeco>(w));
                g_pDecorationPositioner->forceRecalcFor(w);
                w->updateWindowDecos();
            } else if (!should && existing)
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
