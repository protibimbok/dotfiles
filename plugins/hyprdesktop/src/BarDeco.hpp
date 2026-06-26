#pragma once

#include "Globals.hpp"

#include <hyprland/src/render/decorations/IHyprWindowDecoration.hpp>
#include <hyprland/src/helpers/math/Math.hpp>
#include <hyprland/src/event/EventBus.hpp>
#include <hyprland/src/devices/IPointer.hpp>

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

        CHyprSignalListener m_mouseButton;
        CHyprSignalListener m_mouseMove;
        bool                m_dragPending = false;
        bool                m_dragging    = false;

        struct SButtons {
            CBox minimize, fullscreen, close;
        };

        CBox     barLayoutBox() const;
        SButtons buttonBoxes(const CBox& barBox) const;
        bool     inputIsValid() const;
        void     onMouseButton(Event::SCallbackInfo& info, IPointer::SButtonEvent e);
        void     onMouseMove(Vector2D coords);
        void     handleDown(Event::SCallbackInfo& info, const Vector2D& coords);
        void     handleUp(Event::SCallbackInfo& info);
        void     handleMovement();
    };

    namespace BarDeco {
        int  barHeight();
        void reconsider(const PHLWINDOW& w);
        void cleanup();
    }
}
