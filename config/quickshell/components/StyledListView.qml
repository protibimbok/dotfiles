import QtQuick
import qs.tokens

ListView {
    id: root
    maximumFlickVelocity: 3000

    rebound: Transition {
        Anim { properties: "x,y" }
    }
}
