#include "InputBackdrop.hpp"
#include "DesktopMode.hpp"
#include "Ghosting.hpp"

#include <hyprland/src/Compositor.hpp>
#include <hyprland/src/desktop/view/Window.hpp>
#include <hyprland/src/devices/IPointer.hpp>
#include <hyprland/src/event/EventBus.hpp>
#include <hyprland/src/managers/input/InputManager.hpp>

namespace Hyprdesktop::InputBackdrop {

    static CHyprSignalListener g_buttonListener;

    static void onMouseButton(IPointer::SButtonEvent e, Event::SCallbackInfo& info) {
        if (!DesktopMode::pluginEnabled())
            return;
        if (e.state != WL_POINTER_BUTTON_STATE_PRESSED)
            return;

        const auto ws = DesktopMode::focusedWorkspaceID();
        // Only intercept when there's actually a visible float layer to dismiss.
        if (!DesktopMode::anyVisibleManaged(ws))
            return;

        const auto coords = g_pInputManager->getMouseCoordsInternal();
        const auto under  = g_pCompositor->vectorToWindowUnified(
            coords, Desktop::View::RESERVED_EXTENTS | Desktop::View::INPUT_EXTENTS | Desktop::View::ALLOW_FLOATING);

        if (under) {
            // Visible managed float: let it handle the click (raise / titlebar).
            if (!under->isHidden() && under->m_isFloating && DesktopMode::isManaged(under))
                return;
            // Tiled window under cursor: hide floats even when the tile is already focused
            // (window.active won't fire again, so the focus handler can't dismiss).
            if (!under->m_isFloating) {
                Ghosting::hideAllOn(ws);
                return;
            }
            return;
        }

        // Empty space: dismiss and swallow so nothing underneath reacts.
        Ghosting::hideAllOn(ws);
        info.cancelled = true;
    }

    void init() {
        g_buttonListener = Event::bus()->m_events.input.mouse.button.listen(
            [](IPointer::SButtonEvent e, Event::SCallbackInfo& info) { onMouseButton(e, info); });
    }

    void cleanup() {
        g_buttonListener.reset();
    }

}
