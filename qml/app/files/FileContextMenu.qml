import QtQuick
import "../../components/foundation"
import "../../components/theme" as Theme

StyledMenu {
    id: menu

    required property var viewModel
    property int rowIndex: -1

    darkTheme: Theme.AppTheme.isDark

    onRowIndexChanged: {
        openWithHoverTimer.stop()
        openWithSubmenu.close()
        if (viewModel && rowIndex >= 0)
            viewModel.prepareOpenWithForRow(rowIndex)
    }

    onClosed: {
        openWithHoverTimer.stop()
        openWithSubmenu.close()
    }

    function hasOpenWithApps() {
        return viewModel && viewModel.openWithApps && viewModel.openWithApps.length > 0
    }

    function openOpenWithSubmenu() {
        if (!openWithItem.enabled)
            return

        var itemPos = openWithItem.mapToItem(menu.parent, 0, 0)
        var openRight = true

        if (menu.parent) {
            var estimatedSubmenuWidth = openWithSubmenu.width
            if (itemPos.x + menu.width + estimatedSubmenuWidth + 12 > menu.parent.width)
                openRight = false
        }

        openWithSubmenu.popupBeside(openWithItem, openRight, -8)
    }

    Timer {
        id: openWithHoverTimer
        interval: 120
        repeat: false
        onTriggered: menu.openOpenWithSubmenu()
    }

    StyledMenuItem {
        text: "Open"
        darkTheme: Theme.AppTheme.isDark
        enabled: rowIndex >= 0

        onTriggered: {
            if (viewModel && rowIndex >= 0)
                viewModel.openRow(rowIndex)
            openWithHoverTimer.stop()
            openWithSubmenu.close()
            menu.close()
        }
    }

    StyledMenuItem {
        id: openWithItem
        text: "Open with..."
        darkTheme: Theme.AppTheme.isDark
        enabled: rowIndex >= 0 && menu.hasOpenWithApps()

        onHoverStateChanged: function(hovered) {
            if (!enabled)
                return

            if (hovered)
                openWithHoverTimer.restart()
            else
                openWithHoverTimer.stop()
        }

        onTriggered: {
            if (!enabled)
                return

            openWithHoverTimer.stop()
            menu.openOpenWithSubmenu()
        }
    }

    StyledMenuSeparator {}

    StyledMenuItem {
        text: "Rename"
        darkTheme: Theme.AppTheme.isDark
        enabled: rowIndex >= 0

        onTriggered: {
            if (viewModel && rowIndex >= 0)
                viewModel.requestFileContextAction("Rename", rowIndex)
            openWithHoverTimer.stop()
            openWithSubmenu.close()
            menu.close()
        }
    }

    StyledMenuItem {
        text: "Copy"
        darkTheme: Theme.AppTheme.isDark
        enabled: rowIndex >= 0

        onTriggered: {
            if (viewModel && rowIndex >= 0)
                viewModel.requestFileContextAction("Copy", rowIndex)
            openWithHoverTimer.stop()
            openWithSubmenu.close()
            menu.close()
        }
    }

    StyledMenuItem {
        text: "Cut"
        darkTheme: Theme.AppTheme.isDark
        enabled: rowIndex >= 0

        onTriggered: {
            if (viewModel && rowIndex >= 0)
                viewModel.requestFileContextAction("Cut", rowIndex)
            openWithHoverTimer.stop()
            openWithSubmenu.close()
            menu.close()
        }
    }

    StyledMenuItem {
        text: "Delete"
        darkTheme: Theme.AppTheme.isDark
        enabled: rowIndex >= 0

        onTriggered: {
            if (viewModel && rowIndex >= 0)
                viewModel.requestFileContextAction("Delete", rowIndex)
            openWithHoverTimer.stop()
            openWithSubmenu.close()
            menu.close()
        }
    }

    StyledMenuSeparator {}

    StyledMenuItem {
        text: "Copy path"
        darkTheme: Theme.AppTheme.isDark
        enabled: rowIndex >= 0

        onTriggered: {
            if (viewModel && rowIndex >= 0)
                viewModel.requestFileContextAction("Copy path", rowIndex)
            openWithHoverTimer.stop()
            openWithSubmenu.close()
            menu.close()
        }
    }

    StyledMenuItem {
        text: "Duplicate"
        darkTheme: Theme.AppTheme.isDark
        enabled: rowIndex >= 0

        onTriggered: {
            if (viewModel && rowIndex >= 0)
                viewModel.requestFileContextAction("Duplicate", rowIndex)
            openWithHoverTimer.stop()
            openWithSubmenu.close()
            menu.close()
        }
    }

    StyledMenuItem {
        text: "Open containing folder"
        darkTheme: Theme.AppTheme.isDark
        enabled: rowIndex >= 0

        onTriggered: {
            if (viewModel && rowIndex >= 0)
                viewModel.requestFileContextAction("Open containing folder", rowIndex)
            openWithHoverTimer.stop()
            openWithSubmenu.close()
            menu.close()
        }
    }

    StyledMenuItem {
        text: "Properties"
        darkTheme: Theme.AppTheme.isDark
        enabled: rowIndex >= 0

        onTriggered: {
            if (viewModel && rowIndex >= 0)
                viewModel.requestFileContextAction("Properties", rowIndex)
            openWithHoverTimer.stop()
            openWithSubmenu.close()
            menu.close()
        }
    }

    StyledMenuSeparator {}

    StyledMenuItem {
        text: "Compress"
        darkTheme: Theme.AppTheme.isDark
        enabled: rowIndex >= 0

        onTriggered: {
            if (viewModel && rowIndex >= 0)
                viewModel.requestFileContextAction("Compress", rowIndex)
            openWithHoverTimer.stop()
            openWithSubmenu.close()
            menu.close()
        }
    }

    StyledMenuItem {
        text: "Extract here"
        darkTheme: Theme.AppTheme.isDark
        enabled: rowIndex >= 0

        onTriggered: {
            if (viewModel && rowIndex >= 0)
                viewModel.requestFileContextAction("Extract here", rowIndex)
            openWithHoverTimer.stop()
            openWithSubmenu.close()
            menu.close()
        }
    }

    StyledMenu {
        id: openWithSubmenu
        parent: menu.parent
        darkTheme: Theme.AppTheme.isDark
        menuWidth: 240

        Repeater {
            model: viewModel ? viewModel.openWithApps : []

            delegate: StyledMenuItem {
                required property var modelData

                text: modelData.isDefault
                      ? ((modelData.name || modelData.id || "App") + " (default)")
                      : (modelData.name || modelData.id || "App")
                darkTheme: Theme.AppTheme.isDark
                enabled: menu.rowIndex >= 0

                onTriggered: {
                    if (viewModel && menu.rowIndex >= 0) {
                        const appKey = modelData.id || modelData.executable || modelData.name
                        viewModel.openRowWithApp(menu.rowIndex, appKey)
                    }
                    openWithHoverTimer.stop()
                    openWithSubmenu.close()
                    menu.close()
                }
            }
        }
    }
}