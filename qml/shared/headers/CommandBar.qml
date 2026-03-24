import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../components/foundation"
import "../../components/theme" as Theme

Rectangle {
    id: commandBar

    required property var rootWindow
    required property var createMenu
    required property var moreActionsMenu
    required property var viewModeMenu
    required property var themeMenu
    required property var deleteProgressTimer

    color: Theme.AppTheme.surface2
    border.color: Theme.AppTheme.borderSoft
    border.width: Theme.Metrics.borderWidth

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.Metrics.spacingXl
        anchors.rightMargin: Theme.Metrics.spacingXl
        spacing: Theme.Metrics.spacingMd

        IconButton {
            id: createButton
            iconName: "add"
            tooltipText: "Create"
            darkTheme: Theme.AppTheme.isDark
            onClicked: commandBar.createMenu.popup()
        }

        IconButton {
            iconName: "content-cut"
            tooltipText: "Cut"
            darkTheme: Theme.AppTheme.isDark
            onClicked: commandBar.rootWindow.cutSelectedOrCurrent()
        }

        IconButton {
            iconName: "content-copy"
            tooltipText: "Copy"
            darkTheme: Theme.AppTheme.isDark
            onClicked: commandBar.rootWindow.copySelectedOrCurrent()
        }

        IconButton {
            iconName: "content-paste"
            tooltipText: "Paste"
            darkTheme: Theme.AppTheme.isDark
            onClicked: commandBar.rootWindow.applySnapshot(commandBar.rootWindow.backend.pasteItems())
        }

        IconButton {
            iconName: "edit"
            tooltipText: "Rename"
            darkTheme: Theme.AppTheme.isDark
            onClicked: {
                if (commandBar.rootWindow.currentFileRow >= 0)
                    commandBar.rootWindow.beginRenameRow(commandBar.rootWindow.currentFileRow)
            }
        }

        IconButton {
            iconName: "delete"
            tooltipText: "Delete"
            darkTheme: Theme.AppTheme.isDark
            onClicked: {
                if (commandBar.rootWindow.selectedFileCount() > 1)
                    commandBar.rootWindow.askDeleteSelection()
                else if (commandBar.rootWindow.currentFileRow >= 0)
                    commandBar.rootWindow.askDeleteRow(commandBar.rootWindow.currentFileRow)
            }
        }

        IconButton {
            iconName: "sync"
            tooltipText: "Test progress notification"
            darkTheme: Theme.AppTheme.isDark
            onClicked: {
                commandBar.deleteProgressTimer.stop()
                commandBar.deleteProgressTimer.progressValue = 0
                commandBar.deleteProgressTimer.notificationId =
                        commandBar.rootWindow.addProgressNotification("Moving files...", 0)
                commandBar.deleteProgressTimer.start()
            }
        }

        IconButton {
            id: toolbarViewButton
            iconName: commandBar.rootWindow.viewModeIcon(commandBar.rootWindow.currentViewMode)
            tooltipText: "View"
            darkTheme: Theme.AppTheme.isDark
            onClicked: commandBar.viewModeMenu.popup()
        }

        IconButton {
            id: moreButton
            iconName: "more-horiz"
            tooltipText: "More"
            darkTheme: Theme.AppTheme.isDark
            onClicked: commandBar.moreActionsMenu.popup()
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.RightButton
                hoverEnabled: false

                onPressed: function(mouse) {
                    if (mouse.button === Qt.RightButton) {
                        commandBar.moreActionsMenu.popup()
                        mouse.accepted = true
                    }
                }
            }
        }

        Rectangle {
            id: previewToggleButton
            width: 108
            height: Theme.Metrics.controlHeightLg
            radius: 9
            color: commandBar.rootWindow.previewEnabled
                   ? (Theme.AppTheme.isDark ? "#243249" : "#e3edff")
                   : (previewToolbarMouse.pressed
                        ? (Theme.AppTheme.isDark ? "#3a475d" : "#cadbf8")
                        : previewToolbarMouse.containsMouse
                          ? (Theme.AppTheme.isDark ? "#2d3748" : "#dce8fb")
                          : (Theme.AppTheme.isDark ? "#1d2431" : "#fafbfc"))
            border.color: commandBar.rootWindow.previewEnabled ? Theme.AppTheme.accent : Theme.AppTheme.border
            border.width: Theme.Metrics.borderWidth

            Row {
                anchors.centerIn: parent
                spacing: Theme.Metrics.spacingMd

                AppIcon {
                    name: "preview"
                    darkTheme: Theme.AppTheme.isDark
                    iconSize: Theme.Metrics.iconSm
                }

                Text {
                    text: "Preview"
                    color: Theme.AppTheme.text
                    font.pixelSize: Theme.Typography.body
                    font.bold: commandBar.rootWindow.previewEnabled
                }
            }

            MouseArea {
                id: previewToolbarMouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton
                onClicked: commandBar.rootWindow.togglePreviewEnabled()
            }
        }

        Rectangle {
            id: themeButton
            width: 116
            height: Theme.Metrics.controlHeightLg
            radius: 9
            color: themeMouse.pressed
                   ? (Theme.AppTheme.isDark ? "#3a475d" : "#cadbf8")
                   : themeMouse.containsMouse
                     ? (Theme.AppTheme.isDark ? "#2d3748" : "#dce8fb")
                     : (Theme.AppTheme.isDark ? "#1d2431" : "#fafbfc")
            border.color: Theme.AppTheme.border
            border.width: Theme.Metrics.borderWidth

            Row {
                anchors.centerIn: parent
                spacing: Theme.Metrics.spacingMd

                AppIcon {
                    name: commandBar.rootWindow.themeMode === "Dark"
                          ? "moon"
                          : commandBar.rootWindow.themeMode === "Light"
                            ? "sun"
                            : "computer"
                    darkTheme: Theme.AppTheme.isDark
                    iconSize: Theme.Metrics.iconSm
                }

                Text {
                    text: commandBar.rootWindow.themeMode
                    color: Theme.AppTheme.text
                    font.pixelSize: Theme.Typography.body
                }
            }

            MouseArea {
                id: themeMouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: commandBar.themeMenu.popup()

                onPressed: function(mouse) {
                    if (mouse.button === Qt.RightButton)
                        commandBar.themeMenu.popup()
                }
            }
        }
    }
}