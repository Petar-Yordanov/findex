import QtQuick
import QtQuick.Controls
import "../../components/foundation"
import "../../components/theme" as Theme

Rectangle {
    required property string titleText
    required property int widthValue
    required property bool showSortIcon
    required property bool sortAscending
    required property var sortHandler
    required property Item mapTarget

    property bool resizable: true
    property int minimumWidth: 120
    property var resizeHandler: null

    width: widthValue
    height: parent ? parent.height : 40

    color: headerMouse.pressed
           ? (Theme.AppTheme.isDark ? "#3a475d" : "#cadbf8")
           : headerMouse.containsMouse
             ? (Theme.AppTheme.isDark ? "#2a3444" : "#e6eefb")
             : "transparent"
    border.color: headerMouse.pressed
                  ? (Theme.AppTheme.isDark ? "#4a5a72" : "#b7caf0")
                  : "transparent"
    border.width: headerMouse.pressed ? 1 : 0

    Row {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 16
        spacing: Theme.Metrics.spacingSm

        Text {
            text: titleText
            color: Theme.AppTheme.text
            font.pixelSize: Theme.Typography.body
            font.bold: true
        }

        AppIcon {
            visible: showSortIcon
            name: sortAscending ? "keyboard-arrow-up" : "keyboard-arrow-down"
            darkTheme: Theme.AppTheme.isDark
            iconSize: Theme.Metrics.iconXs
        }
    }

    MouseArea {
        id: headerMouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {
            if (sortHandler)
                sortHandler()
        }
    }

    Rectangle {
        visible: resizable
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 8
        color: resizeMouse.pressed ? Theme.AppTheme.accent
                                   : resizeMouse.containsMouse ? Theme.AppTheme.hover : "transparent"

        MouseArea {
            id: resizeMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.SizeHorCursor

            property real pressSceneX: 0

            onPressed: function(mouse) {
                var p = resizeMouse.mapToItem(mapTarget, mouse.x, mouse.y)
                pressSceneX = p.x
            }

            onPositionChanged: function(mouse) {
                if (!pressed || !resizeHandler)
                    return

                var p = resizeMouse.mapToItem(mapTarget, mouse.x, mouse.y)
                var dx = p.x - pressSceneX
                resizeHandler(dx)
            }
        }
    }
}