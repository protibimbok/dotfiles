#pragma once

#include "Globals.hpp"

#include <hyprland/src/render/decorations/IHyprWindowDecoration.hpp>
#include <hyprland/src/helpers/math/Math.hpp>
#include <hyprland/src/event/EventBus.hpp>
#include <hyprland/src/devices/IPointer.hpp>

#include <optional>

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
        bool                m_dragging = false;
        Vector2D            m_grabOffset;
        std::optional<std::pair<Vector2D, Vector2D>> m_savedGeom;

        struct SButtons {
            CBox minimize, fullscreen, close;
        };

        CBox     barLayoutBox() const;
        SButtons buttonBoxes(const CBox& barBox) const;
        bool     inputIsValid() const;
        bool     isActionButton(const Vector2D& coords) const;
        void     onMouseButton(Event::SCallbackInfo& info, IPointer::SButtonEvent e);
        void     onMouseMove(Event::SCallbackInfo& info);
        void     startDrag(Event::SCallbackInfo& info);
        void     endDrag(Event::SCallbackInfo& info);
        void     toggleMaximize(const PHLWINDOW& w);
        void     applyDragPosition(const PHLWINDOW& w, const Vector2D& pos);
    };

    namespace BarDeco {
        int  buttonSize();
        int  titlebarHeight();
        int  barHeight();
        void reconsider(const PHLWINDOW& w);
        void cleanup();
    }
}
