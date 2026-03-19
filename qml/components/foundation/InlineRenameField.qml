import QtQuick
import QtQuick.Controls
import "../theme" as Theme

TextField {
    id: control

    property bool darkTheme: Theme.AppTheme.isDark
    property color textColor: Theme.AppTheme.text
    property color bgColor: Theme.AppTheme.popupBg
    property color accentColor: Theme.AppTheme.accent

    selectByMouse: true
    color: textColor
    font.pixelSize: Theme.Typography.bodyLg
    leftPadding: 8
    rightPadding: 8
    topPadding: 0
    bottomPadding: 0

    background: Rectangle {
        radius: Theme.Metrics.radiusSm
        color: control.bgColor
        border.color: control.accentColor
        border.width: Theme.Metrics.borderWidth
    }

    Keys.onEscapePressed: control.focus = false
}