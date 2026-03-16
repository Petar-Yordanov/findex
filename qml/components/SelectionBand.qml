import QtQuick

Rectangle {
    id: control

    property bool active: false
    property real startX: 0
    property real startY: 0
    property real currentX: 0
    property real currentY: 0
    property color accentColor: "#4c82f7"
    property color fillColor: Qt.rgba(76 / 255, 130 / 255, 247 / 255, 0.18)

    visible: active
    z: 1001

    x: Math.min(startX, currentX)
    y: Math.min(startY, currentY)
    width: Math.abs(currentX - startX)
    height: Math.abs(currentY - startY)

    color: fillColor
    border.color: accentColor
    border.width: 1
}