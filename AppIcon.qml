import QtQuick
import QtQuick.Effects

Item {
    id: root

    property url source: ""
    property int iconSize: 16
    property color iconColor: "#000000"
    property real iconOpacity: 1.0
    property bool smooth: true

    width: iconSize
    height: iconSize

    Image {
        id: iconSource
        anchors.fill: parent
        source: root.source
        fillMode: Image.PreserveAspectFit
        smooth: root.smooth
        mipmap: true
        asynchronous: true
        sourceSize.width: root.iconSize
        sourceSize.height: root.iconSize
        visible: false
    }

    MultiEffect {
        anchors.fill: parent
        source: iconSource
        colorization: 1.0
        colorizationColor: root.iconColor
        brightness: 0.0
        contrast: 1.0
        saturation: 1.0
        opacity: root.iconOpacity
    }
}
