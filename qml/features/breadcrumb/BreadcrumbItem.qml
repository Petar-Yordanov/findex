import QtQuick
import QtQuick.Controls
import "../../components/foundation"
import "../../components/theme" as Theme

Row {
    required property var rootWindow
    required property var modelData
    required property int index
    required property var breadcrumbContextMenu
    required property var pathField

    spacing: Theme.Metrics.spacingSm

    readonly property bool dropHovered: rootWindow.breadcrumbDropHoverIndex === index

    Rectangle {
        id: crumbPill
        height: Theme.Metrics.controlHeightMd
        radius: Theme.Metrics.radiusMd
        color: dropHovered
               ? Theme.AppTheme.selectedSoft
               : crumbMouse.pressed
                 ? Theme.AppTheme.pressed
                 : crumbMouse.containsMouse
                   ? (Theme.AppTheme.isDark ? "#344055" : "#dfe9f8")
                   : "transparent"
        border.color: dropHovered ? Theme.AppTheme.accent : "transparent"
        border.width: dropHovered ? 1 : 0
        width: Math.min(crumbContent.implicitWidth + 16, 190)
        clip: true

        DropArea {
            anchors.fill: parent

            onEntered: function(drag) {
                drag.accepted = rootWindow.draggedFileCount > 0
                if (drag.accepted)
                    rootWindow.breadcrumbDropHoverIndex = index
            }

            onExited: function(drag) {
                if (rootWindow.breadcrumbDropHoverIndex === index)
                    rootWindow.breadcrumbDropHoverIndex = -1
            }

            onDropped: function(drop) {
                if (rootWindow.draggedFileCount > 0) {
                    drop.accepted = true
                    rootWindow.handleDroppedItem(modelData.label, "breadcrumb")
                }

                if (rootWindow.breadcrumbDropHoverIndex === index)
                    rootWindow.breadcrumbDropHoverIndex = -1
            }
        }

        Row {
            id: crumbContent
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: Theme.Metrics.spacingMd
            spacing: Theme.Metrics.spacingSm

            AppIcon {
                anchors.verticalCenter: parent.verticalCenter
                name: modelData.icon
                darkTheme: Theme.AppTheme.isDark
                iconSize: 13
                visible: modelData.icon !== ""
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: modelData.label
                color: Theme.AppTheme.text
                font.pixelSize: Theme.Typography.bodyLg
                elide: Text.ElideRight
                width: Math.min(140, implicitWidth)
            }
        }

        MouseArea {
            id: crumbMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton

            onPressed: function(mouse) {
                if (mouse.button === Qt.RightButton) {
                    rootWindow.contextBreadcrumbIndex = index
                    breadcrumbContextMenu.popup()
                    mouse.accepted = true
                }
            }

            onClicked: function(mouse) {
                if (mouse.button === Qt.LeftButton)
                    rootWindow.setPathFromIndex(index)
            }

            onDoubleClicked: {
                rootWindow.editingPath = true
                pathField.forceActiveFocus()
                pathField.selectAll()
            }
        }
    }

    AppIcon {
        visible: index < rootWindow.pathModel.count - 1
        anchors.verticalCenter: parent.verticalCenter
        name: "chevron-right"
        darkTheme: Theme.AppTheme.isDark
        iconSize: Theme.Metrics.iconXs
        iconOpacity: 0.65
    }
}