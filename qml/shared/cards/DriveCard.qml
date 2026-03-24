import QtQuick
import QtQuick.Controls
import "../../components/foundation"
import "../../components/theme" as Theme

Rectangle {
    required property var rootWindow
    required property var modelData
    required property var sidebarContextMenu

    width: parent ? parent.width : 240
    height: 48
    radius: Theme.Metrics.radiusMd

    readonly property real usedPct: modelData.total > 0 ? (modelData.used / modelData.total) : 0
    readonly property color usedColor: usedPct >= 0.85 ? Theme.AppTheme.driveUsedRed : Theme.AppTheme.driveUsedBlue
    readonly property bool dropHovered: rootWindow.navDropHoverLabel === modelData.label
                                        && rootWindow.navDropHoverKind === "drive"

    color: dropHovered
           ? Theme.AppTheme.selectedSoft
           : driveMouseArea.pressed
             ? (Theme.AppTheme.isDark ? "#3a475d" : "#cadbf8")
             : (rootWindow.selectedSidebarKind === "drive" && rootWindow.selectedSidebarLabel === modelData.label)
               ? Theme.AppTheme.selected
               : driveMouseArea.containsMouse
                 ? (Theme.AppTheme.isDark ? "#2a3444" : "#e6eefb")
                 : "transparent"

    border.color: dropHovered
                  ? Theme.AppTheme.accent
                  : driveMouseArea.pressed
                    ? (Theme.AppTheme.isDark ? "#4a5a72" : "#b7caf0")
                    : "transparent"
    border.width: (dropHovered || driveMouseArea.pressed) ? 1 : 0

    Column {
        anchors.fill: parent
        anchors.leftMargin: Theme.Metrics.spacingMd
        anchors.rightMargin: Theme.Metrics.spacingMd
        anchors.topMargin: Theme.Metrics.spacingXs
        anchors.bottomMargin: Theme.Metrics.spacingXs
        spacing: 2

        Row {
            spacing: Theme.Metrics.spacingSm

            AppIcon {
                name: modelData.icon
                darkTheme: Theme.AppTheme.isDark
                iconSize: Theme.Metrics.iconSm
            }

            Text {
                text: modelData.label
                color: Theme.AppTheme.text
                font.pixelSize: Theme.Typography.body
                font.bold: true
            }
        }

        Rectangle {
            width: parent.width
            height: 5
            radius: Theme.Metrics.radiusXs
            color: Theme.AppTheme.driveFree

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, usedPct))
                height: parent.height
                radius: Theme.Metrics.radiusXs
                color: usedColor
            }
        }

        Text {
            text: modelData.usedText
            color: Theme.AppTheme.muted
            font.pixelSize: 10
        }
    }

    DropArea {
        anchors.fill: parent

        onEntered: function(drag) {
            drag.accepted = true
            rootWindow.setNavDropHover(modelData.label, "drive")
        }

        onExited: function(drag) {
            rootWindow.clearNavDropHover(modelData.label, "drive")
        }

        onDropped: function(drop) {
            drop.accepted = true
            rootWindow.handleDroppedItem(modelData.label, "drive")
        }
    }

    MouseArea {
        id: driveMouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: rootWindow.openLocation(modelData.label, modelData.icon, "drive")

        onPressed: function(mouse) {
            if (mouse.button === Qt.RightButton) {
                rootWindow.contextSidebarLabel = modelData.label
                rootWindow.contextSidebarKind = "drive"
                rootWindow.contextSidebarIcon = modelData.icon
                sidebarContextMenu.popup()
            }
        }
    }
}