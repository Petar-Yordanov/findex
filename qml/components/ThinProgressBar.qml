import QtQuick

Rectangle {
    id: control

    property real value: 0.0
    property color trackColor: "#d4d8de"
    property color fillColor: "#4c82f7"

    radius: height / 2
    color: control.trackColor
    clip: true

    Rectangle {
        width: parent.width * Math.max(0, Math.min(1, control.value))
        height: parent.height
        radius: parent.radius
        color: control.fillColor
    }
}