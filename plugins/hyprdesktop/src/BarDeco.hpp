#pragma once

#include "Globals.hpp"

#include <hyprland/src/render/decorations/IHyprWindowDecoration.hpp>
#include <hyprland/src/helpers/math/Math.hpp>
#include <hyprland/src/event/EventBus.hpp>
#include <hyprland/src/devices/IPointer.hpp>

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
        bool                m_dragging = false;

        struct SButtons {
            CBox minimize, fullscreen, close;
        };

        CBox     barLayoutBox() const;
        SButtons buttonBoxes(const CBox& barBox) const;
        bool     inputIsValid() const;
        void     onMouseButton(Event::SCallbackInfo& info, IPointer::SButtonEvent e);
        void     handleDown(Event::SCallbackInfo& info, const Vector2D& coords);
        void     handleUp(Event::SCallbackInfo& info);
    };

    namespace BarDeco {
        int  barHeight();
        void reconsider(const PHLWINDOW& w);
        void cleanup();
    }
}
