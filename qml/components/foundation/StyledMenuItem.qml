import QtQuick
import "../theme" as Theme

Rectangle {
    id: control

    property bool darkTheme: Theme.AppTheme.isDark
    property string text: ""

    signal triggered()

    width: parent && parent.width > 0 ? parent.width : implicitWidth
    implicitWidth: 184
    implicitHeight: 36
    radius: Theme.Metrics.radiusSm

    color: !enabled
           ? "transparent"
           : mouseArea.pressed
             ? (Theme.AppTheme.isDark ? "#2d394a" : "#d7e3f7")
             : mouseArea.containsMouse
               ? Theme.AppTheme.menuHighlight
               : "transparent"

    border.color: mouseArea.containsMouse && enabled
                  ? Theme.AppTheme.menuHighlightBorder
                  : "transparent"
    border.width: mouseArea.containsMouse && enabled ? Theme.Metrics.borderWidth : 0
    opacity: enabled ? 1.0 : 0.6

    Text {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        text: control.text
        color: enabled ? Theme.AppTheme.text : Theme.AppTheme.disabledText
        font.pixelSize: Theme.Typography.bodyLg
        elide: Text.ElideRight
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignLeft
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: control.enabled
        enabled: control.enabled
        cursorShape: control.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

        onClicked: control.triggered()
    }
}