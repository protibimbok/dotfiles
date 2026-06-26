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

        // Is the press over a real window (incl. its input/reserved extents)? If so, let it
        // through — tile clicks hide via the focus handler, float clicks raise.
        const auto coords = g_pInputManager->getMouseCoordsInternal();
        const auto under  = g_pCompositor->vectorToWindowUnified(
            coords, Desktop::View::RESERVED_EXTENTS | Desktop::View::INPUT_EXTENTS | Desktop::View::ALLOW_FLOATING);
        if (under)
            return;

        // Empty space: dismiss the desktop layer and swallow the click so nothing else
        // reacts to it.
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
