import QtQuick
import "../theme" as Theme

Rectangle {
    id: control

    property bool active: false
    property real startX: 0
    property real startY: 0
    property real currentX: 0
    property real currentY: 0
    property color accentColor: Theme.AppTheme.accent
    property color fillColor: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.18)

    visible: active
    z: 1001

    x: Math.min(startX, currentX)
    y: Math.min(startY, currentY)
    width: Math.abs(currentX - startX)
    height: Math.abs(currentY - startY)

    color: fillColor
    border.color: accentColor
    border.width: Theme.Metrics.borderWidth
}