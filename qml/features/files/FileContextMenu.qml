import QtQuick
import "../../components/foundation"
import "../../components/theme" as Theme
import "../../shared/menus"

StyledMenu {
    id: menu

    required property var rootWindow

    darkTheme: Theme.AppTheme.isDark

    StyledMenuItem {
        text: "Open"
        enabled: rootWindow.contextFileRow >= 0
        darkTheme: Theme.AppTheme.isDark
        onTriggered: {
            if (rootWindow.contextFileRow >= 0) {
                rootWindow.applySnapshot(
                    rootWindow.backend.openItems(
                        rootWindow.singleItemForBackend(rootWindow.contextFileRow)
                    )
                )
            }
        }
    }

    StyledMenuItem {
        text: "Open in new tab"
        enabled: rootWindow.contextFileRow >= 0
        darkTheme: Theme.AppTheme.isDark
        onTriggered: {
            if (rootWindow.contextFileRow >= 0) {
                rootWindow.applySnapshot(
                    rootWindow.backend.openItemsInNewTab(
                        rootWindow.singleItemForBackend(rootWindow.contextFileRow)
                    )
                )
            }
        }
    }

    OpenWithMenu {
        enabledForSelection: rootWindow.contextFileRow >= 0

        onAppSelected: function(appName) {
            if (rootWindow.contextFileRow >= 0) {
                rootWindow.applySnapshot(
                    rootWindow.backend.openItemsWith(
                        rootWindow.singleItemForBackend(rootWindow.contextFileRow),
                        appName
                    )
                )
            }
        }

        onChooseAnotherApp: {
            if (rootWindow.contextFileRow >= 0) {
                rootWindow.applySnapshot(
                    rootWindow.backend.chooseOpenWithApp(
                        rootWindow.singleItemForBackend(rootWindow.contextFileRow)
                    )
                )
            }
        }
    }

    StyledMenuItem {
        text: "Select all"
        darkTheme: Theme.AppTheme.isDark
        onTriggered: rootWindow.selectAllFiles()
    }

    StyledMenuSeparator {}

    StyledMenuItem {
        text: "Cut"
        enabled: rootWindow.contextFileRow >= 0
        darkTheme: Theme.AppTheme.isDark
        onTriggered: {
            if (rootWindow.contextFileRow >= 0) {
                rootWindow.applySnapshot(
                    rootWindow.backend.cutItems(
                        rootWindow.singleItemForBackend(rootWindow.contextFileRow)
                    )
                )
            }
        }
    }

    StyledMenuItem {
        text: "Copy"
        enabled: rootWindow.contextFileRow >= 0
        darkTheme: Theme.AppTheme.isDark
        onTriggered: {
            if (rootWindow.contextFileRow >= 0) {
                rootWindow.applySnapshot(
                    rootWindow.backend.copyItems(
                        rootWindow.singleItemForBackend(rootWindow.contextFileRow)
                    )
                )
            }
        }
    }

    CopyPathsMenu {
        enabledForSelection: rootWindow.contextFileRow >= 0

        onCopyRequested: function(relativeToCurrentDir, recursive) {
            rootWindow.copyPathsForItems(
                rootWindow.singleItemForBackend(rootWindow.contextFileRow),
                relativeToCurrentDir,
                recursive
            )
        }
    }

    StyledMenuItem {
        text: "Rename"
        enabled: rootWindow.contextFileRow >= 0
        darkTheme: Theme.AppTheme.isDark
        onTriggered: rootWindow.beginRenameRow(rootWindow.contextFileRow)
    }

    StyledMenuSeparator {}

    StyledMenuItem {
        text: "Delete"
        enabled: rootWindow.contextFileRow >= 0
        darkTheme: Theme.AppTheme.isDark
        onTriggered: rootWindow.askDeleteRow(rootWindow.contextFileRow)
    }

    StyledMenuItem {
        text: "Properties"
        enabled: rootWindow.contextFileRow >= 0
        darkTheme: Theme.AppTheme.isDark
        onTriggered: {
            if (rootWindow.contextFileRow >= 0) {
                rootWindow.applySnapshot(
                    rootWindow.backend.showItemProperties(
                        rootWindow.singleItemForBackend(rootWindow.contextFileRow)
                    )
                )
            }
        }
    }
}