import QtQuick
import Qt5Compat.GraphicalEffects

Item {
    id: root

    property url source: ""
    property real iconSize: 16
    property real iconOpacity: 1.0
    property color iconColor: "#000000"

    width: iconSize
    height: iconSize
    opacity: iconOpacity

    Image {
        id: iconMask
        anchors.fill: parent
        source: root.source
        fillMode: Image.PreserveAspectFit
        smooth: true
        visible: false
    }

    ColorOverlay {
        anchors.fill: iconMask
        source: iconMask
        color: root.iconColor
    }
}