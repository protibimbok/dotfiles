#include "Ghosting.hpp"
#include "DesktopMode.hpp"

#include <hyprland/src/desktop/view/Window.hpp>

namespace Hyprdesktop::Ghosting {

    void hide(const PHLWINDOW& w) {
        if (!w || w->isHidden())
            return;
        w->setHidden(true);
    }

    void restore(const PHLWINDOW& w) {
        if (!w || !w->isHidden())
            return;
        w->setHidden(false);
    }

    void hideAllOn(WORKSPACEID ws) {
        for (auto& w : DesktopMode::managedFloatsOn(ws))
            hide(w);
    }

    void restoreAllOn(WORKSPACEID ws) {
        for (auto& w : DesktopMode::managedFloatsOn(ws))
            restore(w);
    }

    void toggleOn(WORKSPACEID ws) {
        if (DesktopMode::anyVisibleManaged(ws))
            hideAllOn(ws);
        else
            restoreAllOn(ws);
    }

}
