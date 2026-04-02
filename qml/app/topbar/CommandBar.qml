import QtQuick
import QtQuick.Layouts
import "../../components/foundation"
import "../../components/theme" as Theme

Rectangle {
    id: commandBar

    required property var rootWindow
    required property var viewModel
    required property var createMenu
    required property var moreActionsMenu
    required property var viewModeMenu
    required property var themeMenu
    required property var previewViewModel

    color: Theme.AppTheme.surface2
    border.color: Theme.AppTheme.borderSoft
    border.width: Theme.Metrics.borderWidth

    function viewModeIcon(mode) {
        if (mode === "Details")
            return "detailed-view"
        if (mode === "Tiles")
            return "tile-view"
        if (mode === "Compact")
            return "list-view"
        if (mode === "Large icons")
            return "grid-view"
        return "list-view"
    }

    MouseArea {
        anchors.fill: parent
        z: 0
        acceptedButtons: Qt.RightButton
        hoverEnabled: false

        onPressed: function(mouse) {
            if (mouse.button !== Qt.RightButton)
                return

            if (!commandBar.moreActionsMenu || !commandBar.moreActionsMenu.parent)
                return

            var p = commandBar.mapToItem(commandBar.moreActionsMenu.parent, mouse.x, mouse.y)
            commandBar.moreActionsMenu.popupAt(p.x, p.y)
            mouse.accepted = true
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.Metrics.spacingXl
        anchors.rightMargin: Theme.Metrics.spacingXl
        spacing: Theme.Metrics.spacingMd
        z: 1

        IconButton {
            id: createButton
            iconName: "add"
            tooltipText: "Create"
            darkTheme: Theme.AppTheme.isDark
            onClicked: commandBar.rootWindow.popupBelow(createButton, commandBar.createMenu)
        }

        IconButton {
            iconName: "content-cut"
            tooltipText: "Cut"
            darkTheme: Theme.AppTheme.isDark
            onClicked: {
                if (commandBar.viewModel)
                    commandBar.viewModel.cutSelection()
            }
        }

        IconButton {
            iconName: "content-copy"
            tooltipText: "Copy"
            darkTheme: Theme.AppTheme.isDark
            onClicked: {
                if (commandBar.viewModel)
                    commandBar.viewModel.copySelection()
            }
        }

        IconButton {
            iconName: "content-paste"
            tooltipText: "Paste"
            darkTheme: Theme.AppTheme.isDark
            onClicked: {
                if (commandBar.viewModel)
                    commandBar.viewModel.paste()
            }
        }

        IconButton {
            iconName: "edit"
            tooltipText: "Rename"
            darkTheme: Theme.AppTheme.isDark
            onClicked: {
                if (commandBar.viewModel)
                    commandBar.viewModel.renameSelection()
            }
        }

        IconButton {
            iconName: "delete"
            tooltipText: "Delete"
            darkTheme: Theme.AppTheme.isDark
            onClicked: {
                if (commandBar.viewModel)
                    commandBar.viewModel.deleteSelection()
            }
        }

        IconButton {
            iconName: "refresh"
            tooltipText: "Refresh"
            darkTheme: Theme.AppTheme.isDark
            onClicked: {
                if (commandBar.viewModel)
                    commandBar.viewModel.refresh()
            }
        }

        IconButton {
            id: toolbarViewButton
            iconName: commandBar.viewModeIcon(
                commandBar.viewModel ? commandBar.viewModel.viewMode : "Details"
            )
            tooltipText: "View"
            darkTheme: Theme.AppTheme.isDark
            onClicked: commandBar.rootWindow.popupBelow(toolbarViewButton, commandBar.viewModeMenu)
        }

        IconButton {
            iconName: "sync"
            tooltipText: "Test progress"
            darkTheme: Theme.AppTheme.isDark
            onClicked: {
                if (appStatusBarViewModel)
                    appStatusBarViewModel.startTestProgress()
            }
        }

        IconButton {
            id: moreButton
            iconName: "more-horiz"
            tooltipText: "Show more"
            darkTheme: Theme.AppTheme.isDark
            onClicked: commandBar.rootWindow.popupBelow(moreButton, commandBar.moreActionsMenu)
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        Rectangle {
            id: previewToggleButton
            width: 108
            height: Theme.Metrics.controlHeightLg
            radius: 9

            color: commandBar.previewViewModel && commandBar.previewViewModel.previewEnabled
                ? (Theme.AppTheme.isDark ? "#243249" : "#e3edff")
                : (previewToolbarMouse.pressed
                    ? (Theme.AppTheme.isDark ? "#3a475d" : "#cadbf8")
                    : previewToolbarMouse.containsMouse
                        ? (Theme.AppTheme.isDark ? "#2d3748" : "#dce8fb")
                        : (Theme.AppTheme.isDark ? "#1d2431" : "#fafbfc"))

            border.color: commandBar.previewViewModel && commandBar.previewViewModel.previewEnabled
                ? Theme.AppTheme.accent
                : Theme.AppTheme.border
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
                    font.bold: !!(commandBar.previewViewModel && commandBar.previewViewModel.previewEnabled)
                }
            }

            MouseArea {
                id: previewToolbarMouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton
                onClicked: {
                    if (commandBar.previewViewModel)
                        commandBar.previewViewModel.togglePreviewEnabled()
                }
            }
        }

        Rectangle {
            id: themeButton
            width: 116
            height: Theme.Metrics.controlHeightLg
            radius: 9
            color: themeMouse.pressed ? (Theme.AppTheme.isDark ? "#3a475d" : "#cadbf8")
                 : themeMouse.containsMouse ? (Theme.AppTheme.isDark ? "#2d3748" : "#dce8fb")
                 : (Theme.AppTheme.isDark ? "#1d2431" : "#fafbfc")
            border.color: Theme.AppTheme.border
            border.width: Theme.Metrics.borderWidth

            Row {
                anchors.centerIn: parent
                spacing: Theme.Metrics.spacingMd

                AppIcon {
                    name: !commandBar.viewModel ? "sun"
                        : commandBar.viewModel.themeMode === "Dark" ? "moon"
                        : commandBar.viewModel.themeMode === "Light" ? "sun"
                        : "computer"
                    darkTheme: Theme.AppTheme.isDark
                    iconSize: Theme.Metrics.iconSm
                }

                Text {
                    text: commandBar.viewModel ? commandBar.viewModel.themeMode : "Light"
                    color: Theme.AppTheme.text
                    font.pixelSize: Theme.Typography.body
                }
            }

            MouseArea {
                id: themeMouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: commandBar.rootWindow.popupBelow(themeButton, commandBar.themeMenu)
                onPressed: function(mouse) {
                    if (mouse.button === Qt.RightButton)
                        commandBar.rootWindow.popupBelow(themeButton, commandBar.themeMenu)
                }
            }
        }
    }
}