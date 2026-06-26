#include "CsdPolicy.hpp"

#include <hyprland/src/desktop/view/Window.hpp>
#include <hyprland/src/desktop/rule/windowRule/WindowRuleApplicator.hpp>

#include <regex>

namespace Hyprdesktop::CsdPolicy {

    bool wantsServerBar(const PHLWINDOW& w) {
        if (!w)
            return false;

        // Explicit per-window overrides via window-rule tags (apps.lua):
        //   tag = +hyprdesktop:force_bar  -> always bar
        //   tag = +hyprdesktop:no_bar     -> never bar
        if (w->m_ruleApplicator) {
            const auto& tags = w->m_ruleApplicator->m_tagKeeper;
            if (tags.isTagged("hyprdesktop:force_bar"))
                return true;
            if (tags.isTagged("hyprdesktop:no_bar"))
                return false;
        }

        // XWayland: honor the X11 motif/borders hint.
        if (w->m_isX11 && w->m_X11DoesntWantBorders)
            return false;

        // Class / title blacklist (e.g. CSD apps like Code, Cursor, electron, nautilus).
        // NOTE: live xdg-decoration CLIENT_SIDE negotiation is not yet read (the mode is
        // not cleanly exposed per-window); the blacklist regex is the supported mechanism.
        if (g_config.csdBlacklist) {
            const std::string pattern = g_config.csdBlacklist->value();
            if (!pattern.empty()) {
                try {
                    const std::regex rx(pattern, std::regex::ECMAScript | std::regex::icase);
                    if (std::regex_search(w->m_class, rx) || std::regex_search(w->m_title, rx))
                        return false;
                } catch (const std::regex_error&) {
                    // Malformed pattern: fail open (allow the bar) rather than break silently.
                }
            }
        }

        return true;
    }

}
