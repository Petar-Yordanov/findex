import QtQuick
import QtQuick.Layouts
import "../../components/foundation"
import "../../components/theme" as Theme

Rectangle {
    id: statusBar

    required property var rootWindow
    required property var viewModel
    required property var viewModeMenu
    required property var notificationsPopup

    color: Theme.AppTheme.isDark ? "#141920" : "#f6f7f9"
    border.color: Theme.AppTheme.borderSoft
    border.width: Theme.Metrics.borderWidth

    function viewModeIcon(mode) {
        if (mode === "Large icons")
            return "grid-view"
        if (mode === "Tiles")
            return "tile-view"
        if (mode === "Details")
            return "detailed-view"
        return "list-view"
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.Metrics.spacingXl
        anchors.rightMargin: Theme.Metrics.spacingXl

        Text {
            text: statusBar.viewModel && statusBar.viewModel.itemsText
                  ? statusBar.viewModel.itemsText
                  : "0 items"
            color: Theme.AppTheme.muted
            font.pixelSize: Theme.Typography.caption
        }

        Item {
            Layout.fillWidth: true
        }

        Rectangle {
            id: bottomViewButton
            width: 24
            height: 24
            radius: 7
            color: bottomViewMouse.pressed ? Theme.AppTheme.pressed
                 : bottomViewMouse.containsMouse ? Theme.AppTheme.hover
                 : (Theme.AppTheme.isDark ? "#1a1f27" : "#ffffff")
            border.color: bottomViewMouse.containsMouse || bottomViewMouse.pressed
                        ? Theme.AppTheme.border
                        : Theme.AppTheme.borderSoft
            border.width: Theme.Metrics.borderWidth

            AppIcon {
                anchors.centerIn: parent
                name: statusBar.viewModeIcon(statusBar.viewModel ? statusBar.viewModel.currentViewMode : "Details")
                darkTheme: Theme.AppTheme.isDark
                iconSize: 13
                iconOpacity: 0.75
            }

            MouseArea {
                id: bottomViewMouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton

                onClicked: {
                    if (statusBar.rootWindow && statusBar.viewModeMenu)
                        statusBar.rootWindow.popupBelow(bottomViewButton, statusBar.viewModeMenu)
                }

                onPressed: function(mouse) {
                    if (mouse.button === Qt.RightButton && statusBar.rootWindow && statusBar.viewModeMenu)
                        statusBar.rootWindow.popupBelow(bottomViewButton, statusBar.viewModeMenu)
                }
            }
        }

        Rectangle {
            id: notificationsButton
            width: 24
            height: 24
            radius: 7
            color: notificationsMouse.pressed ? Theme.AppTheme.pressed
                 : notificationsMouse.containsMouse ? Theme.AppTheme.hover
                 : (Theme.AppTheme.isDark ? "#1a1f27" : "#ffffff")
            border.color: notificationsMouse.containsMouse || notificationsMouse.pressed
                        ? Theme.AppTheme.border
                        : Theme.AppTheme.borderSoft
            border.width: Theme.Metrics.borderWidth

            AppIcon {
                anchors.centerIn: parent
                name: "notifications"
                darkTheme: Theme.AppTheme.isDark
                iconSize: 13
                iconOpacity: 0.8
            }

            Rectangle {
                visible: statusBar.viewModel && statusBar.viewModel.notificationCount > 0
                width: 8
                height: 8
                radius: 4
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: 2
                anchors.rightMargin: 2
                color: Theme.AppTheme.accent
                z: 2
            }

            MouseArea {
                id: notificationsMouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton

                onClicked: {
                    if (!statusBar.notificationsPopup || !statusBar.notificationsPopup.parent)
                        return

                    var p = notificationsButton.mapToItem(
                                statusBar.notificationsPopup.parent,
                                notificationsButton.width - statusBar.notificationsPopup.width,
                                -statusBar.notificationsPopup.height - 8)
                    statusBar.notificationsPopup.popupAt(p.x, p.y)
                }
            }
        }
    }
}