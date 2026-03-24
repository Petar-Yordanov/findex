import QtQuick
import "../theme" as Theme

Rectangle {
    id: control

    property bool darkTheme: Theme.AppTheme.isDark
    property bool hoverFxEnabled: true

    property string iconName: ""
    property color hoverColor: Theme.AppTheme.selected
    property color pressedColor: Theme.AppTheme.menuHighlight
    property color hoverBorderColor: Theme.AppTheme.menuHighlightBorder

    signal clicked()

    width: 42
    height: 28
    radius: Theme.Metrics.radiusMd

    color: mouse.pressed
           ? control.pressedColor
           : (control.hoverFxEnabled && mouse.containsMouse ? control.hoverColor : "transparent")

    border.color: control.hoverFxEnabled && mouse.containsMouse && !mouse.pressed
                  ? control.hoverBorderColor
                  : "transparent"
    border.width: control.hoverFxEnabled && mouse.containsMouse ? Theme.Metrics.borderWidth : 0

    AppIcon {
        anchors.centerIn: parent
        name: control.iconName
        darkTheme: control.darkTheme
        iconSize: Theme.Metrics.iconSm
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: control.hoverFxEnabled
        onClicked: control.clicked()
    }
}