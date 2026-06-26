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
            m->m_scheduledRecalc = true;
        }
    }

    static void damageWindow(const PHLWINDOW& w) {
        if (!w)
            return;
        g_pHyprRenderer->damageWindow(w, true);
        w->updateWindowDecos();
    }

    void hide(const PHLWINDOW& w) {
        if (!w || w->isHidden())
            return;
        damageWindow(w);
        w->setHidden(true);
        damageWindow(w);
        if (w->m_workspace)
            damageWorkspace(w->m_workspace->m_id);
    }

    void restore(const PHLWINDOW& w) {
        if (!w || !w->isHidden())
            return;
        w->setHidden(false);
        damageWindow(w);
        if (w->m_workspace)
            damageWorkspace(w->m_workspace->m_id);
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
