#include "DesktopMode.hpp"
#include "Ghosting.hpp"
#include "Layout.hpp"
#include "BarDeco.hpp"

#include <hyprland/src/Compositor.hpp>
#include <hyprland/src/desktop/view/Window.hpp>
#include <hyprland/src/desktop/Workspace.hpp>
#include <hyprland/src/desktop/state/FocusState.hpp>
#include <hyprland/src/desktop/rule/windowRule/WindowRuleApplicator.hpp>
#include <hyprland/src/helpers/Monitor.hpp>
#include <hyprland/src/event/EventBus.hpp>

#include <sstream>

namespace Hyprdesktop::DesktopMode {

    // Listeners are kept alive for the life of the plugin; resetting them unsubscribes.
    static struct {
        CHyprSignalListener open;
        CHyprSignalListener active;
    } g_listeners;

    bool pluginEnabled() {
        return g_config.enabled && g_config.enabled->value();
    }

    static std::vector<std::string> excludedTags() {
        std::vector<std::string> out;
        if (!g_config.excludedTags)
            return out;
        std::stringstream ss(g_config.excludedTags->value());
        std::string       tag;
        while (std::getline(ss, tag, ',')) {
            // trim surrounding whitespace
            const auto b = tag.find_first_not_of(" \t");
            const auto e = tag.find_last_not_of(" \t");
            if (b != std::string::npos)
                out.emplace_back(tag.substr(b, e - b + 1));
        }
        return out;
    }

    bool isManaged(const PHLWINDOW& w) {
        if (!w)
            return false;
        // Hidden windows stay "managed" so toggle can restore them; only skip genuinely
        // unmapped windows.
        if (!w->m_isMapped && !w->isHidden())
            return false;
        if (!w->m_isFloating || w->m_pinned)
            return false;

        const auto ws = w->m_workspace;
        if (!ws || ws->m_isSpecialWorkspace)
            return false;

        if (w->m_ruleApplicator) {
            for (const auto& tag : excludedTags()) {
                if (w->m_ruleApplicator->m_tagKeeper.isTagged(tag))
                    return false;
            }
        }

        if (w->m_title.find("Webcam") != std::string::npos)
            return false;

        return true;
    }

    std::vector<PHLWINDOW> managedFloatsOn(WORKSPACEID ws) {
        std::vector<PHLWINDOW> out;
        for (const auto& w : g_pCompositor->m_windows) {
            if (!isManaged(w))
                continue;
            if (w->m_workspace && w->m_workspace->m_id == ws)
                out.push_back(w);
        }
        return out;
    }

    bool anyVisibleManaged(WORKSPACEID ws) {
        for (const auto& w : managedFloatsOn(ws)) {
            if (!w->isHidden())
                return true;
        }
        return false;
    }

    bool hasManaged(WORKSPACEID ws) {
        return !managedFloatsOn(ws).empty();
    }

    WORKSPACEID focusedWorkspaceID() {
        if (const auto m = Desktop::focusState()->monitor(); m && m->m_activeWorkspace)
            return m->m_activeWorkspace->m_id;
        return workspaceAtCursor();
    }

    WORKSPACEID workspaceAtCursor() {
        if (const auto m = g_pCompositor->getMonitorFromCursor(); m && m->m_activeWorkspace)
            return m->m_activeWorkspace->m_id;
        if (const auto m = Desktop::focusState()->monitor(); m && m->m_activeWorkspace)
            return m->m_activeWorkspace->m_id;
        return WORKSPACE_INVALID;
    }

    static void onWindowOpen(const PHLWINDOW& w) {
        if (!pluginEnabled() || !isManaged(w) || !w->m_workspace)
            return;
        // A new float reactivates the layer: restore any previously-hidden siblings so the
        // whole desktop comes back (state-machine: Hidden -> Active on new float).
        Ghosting::restoreAllOn(w->m_workspace->m_id);
        BarDeco::reconsider(w);
        Layout::placeNewFloat(w);
    }

    static void onWindowActive(const PHLWINDOW& w, Desktop::eFocusReason reason) {
        if (!pluginEnabled() || !w)
            return;

        // Catch float<->tile transitions (e.g. togglefloating) for titlebar attach/detach.
        BarDeco::reconsider(w);

        if (w->m_isFloating) {
            if (!w->m_pinned && !w->isHidden())
                g_pCompositor->changeWindowZOrder(w, true); // raise on focus (bring_to_top parity)
            return;
        }

        // Focus landed on a tiled window. Hide the float layer only on *deliberate* focus
        // (click / keybind), not hover (FFM) — this replaces the old follow_mouse=0 hack.
        if (g_config.hideOnTileFocus && g_config.hideOnTileFocus->value() && Desktop::isHardInputFocusReason(reason)) {
            if (w->m_workspace && !w->m_workspace->m_isSpecialWorkspace)
                Ghosting::hideAllOn(w->m_workspace->m_id);
        }
    }

    void init() {
        auto& events    = Event::bus()->m_events;
        g_listeners.open = events.window.open.listen([](const PHLWINDOW& w) { onWindowOpen(w); });
        g_listeners.active =
            events.window.active.listen([](const PHLWINDOW& w, Desktop::eFocusReason reason) { onWindowActive(w, reason); });
    }

    void cleanup() {
        g_listeners.open.reset();
        g_listeners.active.reset();
    }

}
