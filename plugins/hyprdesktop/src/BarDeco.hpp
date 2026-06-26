#pragma once

#include "Globals.hpp"

#include <hyprland/src/render/decorations/IHyprWindowDecoration.hpp>
#include <hyprland/src/helpers/math/Math.hpp>

#include <any>

// Server-side titlebar, derived from hyprbars' CHyprBar. Float-only, attached/detached
// by BarDeco::reconsider() based on Desktop-Mode + CsdPolicy gating. Drag works without
// holding SUPER; three controls: minimize (ghost), fullscreen toggle, close.
namespace Hyprdesktop {

    class CBarDeco : public IHyprWindowDecoration {
      public:
        CBarDeco(PHLWINDOW w);
        virtual ~CBarDeco() = default;

        virtual SDecorationPositioningInfo getPositioningInfo();
        virtual void                       onPositioningReply(const SDecorationPositioningReply& reply);
        virtual void                       draw(PHLMONITOR, float const& a);
        virtual eDecorationType            getDecorationType();
        virtual void                       updateWindow(PHLWINDOW);
        virtual void                       damageEntire();
        virtual bool                       onInputOnDeco(const eInputType, const Vector2D&, std::any = {});
        virtual eDecorationLayer           getDecorationLayer();
        virtual uint64_t                   getDecorationFlags();
        virtual std::string                getDisplayName();

      private:
        PHLWINDOWREF m_window;

        struct SButtons {
            CBox minimize, fullscreen, close;
        };

        CBox    barLayoutBox() const;                   // bar box in global (unscaled) layout coords
        SButtons buttonBoxes(const CBox& barBox) const; // control boxes, same coord space
    };

    namespace BarDeco {
        int  barHeight();
        // Attach our titlebar if the window should have one and doesn't; detach otherwise.
        void reconsider(const PHLWINDOW& w);
    }
}
