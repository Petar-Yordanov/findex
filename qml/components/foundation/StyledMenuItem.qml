import QtQuick
import QtQuick.Controls
import "../theme" as Theme

MenuItem {
    id: control

    property bool darkTheme: Theme.AppTheme.isDark

    implicitWidth: Theme.Metrics.menuWidth
    implicitHeight: 40

    leftPadding: 16
    rightPadding: control.subMenu ? 36 : 16
    topPadding: 0
    bottomPadding: 0

    indicator: null

    arrow: Item {
        visible: control.subMenu !== null
        width: visible ? 14 : 0
        height: control.height
        x: control.width - width - 16
        y: 0

        AppIcon {
            anchors.centerIn: parent
            name: "chevron-right"
            darkTheme: control.darkTheme
            iconSize: Theme.Metrics.iconSm
            iconOpacity: control.enabled ? 0.8 : 0.45
        }
    }

    contentItem: Text {
        text: control.text
        color: control.enabled ? Theme.AppTheme.text : Theme.AppTheme.disabledText
        font.pixelSize: Theme.Typography.bodyLg
        elide: Text.ElideRight
        verticalAlignment: Text.AlignVCenter
    }

    background: Rectangle {
        x: 6
        y: 4
        width: control.width - 12
        height: control.height - 8
        radius: Theme.Metrics.radiusSm

        color: control.highlighted ? Theme.AppTheme.menuHighlight : "transparent"
        border.color: control.highlighted ? Theme.AppTheme.menuHighlightBorder : "transparent"
        border.width: control.highlighted ? Theme.Metrics.borderWidth : 0
    }
}