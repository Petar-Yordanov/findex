import QtQuick
import QtQuick.Controls
import "../../components/foundation"
import "../../components/theme" as Theme

Popup {
    id: searchScopePopup

    property var rootWindow

    width: 56
    height: 96
    padding: Theme.Metrics.spacingSm
    modal: false
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    background: Rectangle {
        radius: Theme.Metrics.radiusXl
        color: Theme.AppTheme.popupBg
        border.color: Theme.AppTheme.border
        border.width: Theme.Metrics.borderWidth
    }

    Column {
        anchors.fill: parent
        spacing: Theme.Metrics.spacingXs

        Rectangle {
            width: parent.width
            height: 40
            radius: Theme.Metrics.radiusMd
            color: folderMouse.pressed
                   ? (Theme.AppTheme.isDark ? "#3a475d" : "#cadbf8")
                   : folderMouse.containsMouse
                     ? (Theme.AppTheme.isDark ? "#2a3444" : "#e6eefb")
                     : "transparent"
            border.color: folderMouse.pressed
                          ? (Theme.AppTheme.isDark ? "#4a5a72" : "#b7caf0")
                          : "transparent"
            border.width: folderMouse.pressed ? 1 : 0

            AppIcon {
                anchors.centerIn: parent
                name: "folder"
                darkTheme: Theme.AppTheme.isDark
                iconSize: Theme.Metrics.iconMd
            }

            MouseArea {
                id: folderMouse
                anchors.fill: parent
                hoverEnabled: true

                onClicked: {
                    if (!searchScopePopup.rootWindow)
                        return

                    searchScopePopup.rootWindow.searchScope = "folder"
                    searchScopePopup.rootWindow.applySnapshot(
                        searchScopePopup.rootWindow.backend.setSearchScope("folder")
                    )
                    searchScopePopup.close()
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 40
            radius: Theme.Metrics.radiusMd
            color: driveMouse.pressed
                   ? (Theme.AppTheme.isDark ? "#3a475d" : "#cadbf8")
                   : driveMouse.containsMouse
                     ? (Theme.AppTheme.isDark ? "#2a3444" : "#e6eefb")
                     : "transparent"
            border.color: driveMouse.pressed
                          ? (Theme.AppTheme.isDark ? "#4a5a72" : "#b7caf0")
                          : "transparent"
            border.width: driveMouse.pressed ? 1 : 0

            AppIcon {
                anchors.centerIn: parent
                name: "hard-drive"
                darkTheme: Theme.AppTheme.isDark
                iconSize: Theme.Metrics.iconMd
            }

            MouseArea {
                id: driveMouse
                anchors.fill: parent
                hoverEnabled: true

                onClicked: {
                    if (!searchScopePopup.rootWindow)
                        return

                    searchScopePopup.rootWindow.searchScope = "global"
                    searchScopePopup.rootWindow.applySnapshot(
                        searchScopePopup.rootWindow.backend.setSearchScope("global")
                    )
                    searchScopePopup.close()
                }
            }
        }
    }
}