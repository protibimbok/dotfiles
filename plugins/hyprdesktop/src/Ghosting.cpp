#include "Ghosting.hpp"
#include "DesktopMode.hpp"

#include <hyprland/src/Compositor.hpp>
#include <hyprland/src/desktop/view/Window.hpp>
#include <hyprland/src/helpers/Monitor.hpp>
#include <hyprland/src/render/Renderer.hpp>

namespace Hyprdesktop::Ghosting {

    static void damageWorkspace(WORKSPACEID ws) {
        for (const auto& m : g_pCompositor->m_monitors) {
            if (!m || !m->m_activeWorkspace || m->m_activeWorkspace->m_id != ws)
                continue;
            g_pHyprRenderer->damageMonitor(m);
        }
    }

    void hide(const PHLWINDOW& w) {
        if (!w || w->isHidden())
            return;
        w->setHidden(true);
        w->updateWindowDecos();
    }

    void restore(const PHLWINDOW& w) {
        if (!w || !w->isHidden())
            return;
        w->setHidden(false);
        w->updateWindowDecos();
    }

    void hideAllOn(WORKSPACEID ws) {
        for (auto& w : DesktopMode::managedFloatsOn(ws))
            hide(w);
        damageWorkspace(ws);
    }

    void restoreAllOn(WORKSPACEID ws) {
        for (auto& w : DesktopMode::managedFloatsOn(ws))
            restore(w);
        damageWorkspace(ws);
    }

    void toggleOn(WORKSPACEID ws) {
        if (DesktopMode::anyVisibleManaged(ws))
            hideAllOn(ws);
        else
            restoreAllOn(ws);
    }

}
