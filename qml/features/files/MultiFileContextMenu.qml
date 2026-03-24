import QtQuick
import "../../components/foundation"
import "../../components/theme" as Theme

StyledMenu {
    id: menu

    required property var rootWindow

    darkTheme: Theme.AppTheme.isDark

    StyledMenuItem {
        text: "Open"
        enabled: rootWindow.selectedFileCount() > 0
        darkTheme: Theme.AppTheme.isDark
        onTriggered: {
            if (rootWindow.selectedFileCount() > 0) {
                rootWindow.applySnapshot(
                    rootWindow.backend.openItems(rootWindow.selectedItemsForBackend())
                )
            }
        }
    }

    StyledMenuItem {
        text: "Open in new tab"
        enabled: rootWindow.selectedFileCount() === 1
        darkTheme: Theme.AppTheme.isDark
        onTriggered: {
            if (rootWindow.selectedFileCount() === 1 && rootWindow.currentFileRow >= 0) {
                rootWindow.applySnapshot(
                    rootWindow.backend.openItemsInNewTab(
                        rootWindow.singleItemForBackend(rootWindow.currentFileRow)
                    )
                )
            }
        }
    }

    StyledMenuSeparator {}

    StyledMenuItem {
        text: "Cut"
        enabled: rootWindow.selectedFileCount() > 0
        darkTheme: Theme.AppTheme.isDark
        onTriggered: rootWindow.applySnapshot(
            rootWindow.backend.cutItems(rootWindow.selectedItemsForBackend())
        )
    }

    StyledMenuItem {
        text: "Copy"
        enabled: rootWindow.selectedFileCount() > 0
        darkTheme: Theme.AppTheme.isDark
        onTriggered: rootWindow.applySnapshot(
            rootWindow.backend.copyItems(rootWindow.selectedItemsForBackend())
        )
    }

    StyledMenuSeparator {}

    StyledMenuItem {
        text: "Compress"
        enabled: rootWindow.selectedFileCount() > 0
        darkTheme: Theme.AppTheme.isDark
        onTriggered: rootWindow.applySnapshot(
            rootWindow.backend.compressItems(rootWindow.selectedItemsForBackend())
        )
    }

    StyledMenuItem {
        text: "Extract here"
        enabled: rootWindow.selectedFileCount() > 0
        darkTheme: Theme.AppTheme.isDark
        onTriggered: rootWindow.applySnapshot(
            rootWindow.backend.extractItems(rootWindow.selectedItemsForBackend())
        )
    }

    StyledMenuSeparator {}

    StyledMenu {
        title: "Copy paths"
        darkTheme: Theme.AppTheme.isDark

        StyledMenuItem {
            text: "Full path"
            darkTheme: Theme.AppTheme.isDark
            enabled: rootWindow.selectedFileCount() > 0
            onTriggered: {
                rootWindow.copyPathsForItems(
                    rootWindow.selectedItemsForBackend(),
                    false,
                    false
                )
            }
        }

        StyledMenuItem {
            text: "Relative path"
            darkTheme: Theme.AppTheme.isDark
            enabled: rootWindow.selectedFileCount() > 0
            onTriggered: {
                rootWindow.copyPathsForItems(
                    rootWindow.selectedItemsForBackend(),
                    true,
                    false
                )
            }
        }

        StyledMenuSeparator {}

        StyledMenuItem {
            text: "Full paths recursively"
            darkTheme: Theme.AppTheme.isDark
            enabled: rootWindow.selectedFileCount() > 0
            onTriggered: {
                rootWindow.copyPathsForItems(
                    rootWindow.selectedItemsForBackend(),
                    false,
                    true
                )
            }
        }

        StyledMenuItem {
            text: "Relative paths recursively"
            darkTheme: Theme.AppTheme.isDark
            enabled: rootWindow.selectedFileCount() > 0
            onTriggered: {
                rootWindow.copyPathsForItems(
                    rootWindow.selectedItemsForBackend(),
                    true,
                    true
                )
            }
        }
    }

    StyledMenuSeparator {}

    StyledMenuItem {
        text: "Delete"
        enabled: rootWindow.selectedFileCount() > 0
        darkTheme: Theme.AppTheme.isDark
        onTriggered: rootWindow.askDeleteSelection()
    }

    StyledMenuItem {
        text: "Rename"
        enabled: rootWindow.selectedFileCount() === 1 && rootWindow.currentFileRow >= 0
        darkTheme: Theme.AppTheme.isDark
        onTriggered: rootWindow.beginRenameRow(rootWindow.currentFileRow)
    }

    StyledMenuSeparator {}

    StyledMenuItem {
        text: "Select all"
        darkTheme: Theme.AppTheme.isDark
        onTriggered: rootWindow.selectAllFiles()
    }

    StyledMenuItem {
        text: "Clear selection"
        enabled: rootWindow.selectedFileCount() > 0
        darkTheme: Theme.AppTheme.isDark
        onTriggered: rootWindow.clearFileSelection()
    }

    StyledMenuSeparator {}

    StyledMenuItem {
        text: "Properties"
        enabled: rootWindow.selectedFileCount() > 0
        darkTheme: Theme.AppTheme.isDark
        onTriggered: rootWindow.applySnapshot(
            rootWindow.backend.showItemProperties(rootWindow.selectedItemsForBackend())
        )
    }
}