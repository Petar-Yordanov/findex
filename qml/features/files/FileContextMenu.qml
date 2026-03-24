import QtQuick
import "../../components/foundation"
import "../../components/theme" as Theme

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

    StyledMenu {
        title: "Open with..."
        darkTheme: Theme.AppTheme.isDark

        StyledMenuItem {
            text: "Notepad"
            darkTheme: Theme.AppTheme.isDark
            enabled: rootWindow.contextFileRow >= 0
            onTriggered: {
                if (rootWindow.contextFileRow >= 0) {
                    rootWindow.applySnapshot(
                        rootWindow.backend.openItemsWith(
                            rootWindow.singleItemForBackend(rootWindow.contextFileRow),
                            "Notepad"
                        )
                    )
                }
            }
        }

        StyledMenuItem {
            text: "Visual Studio Code"
            darkTheme: Theme.AppTheme.isDark
            enabled: rootWindow.contextFileRow >= 0
            onTriggered: {
                if (rootWindow.contextFileRow >= 0) {
                    rootWindow.applySnapshot(
                        rootWindow.backend.openItemsWith(
                            rootWindow.singleItemForBackend(rootWindow.contextFileRow),
                            "Visual Studio Code"
                        )
                    )
                }
            }
        }

        StyledMenuItem {
            text: "Qt Creator"
            darkTheme: Theme.AppTheme.isDark
            enabled: rootWindow.contextFileRow >= 0
            onTriggered: {
                if (rootWindow.contextFileRow >= 0) {
                    rootWindow.applySnapshot(
                        rootWindow.backend.openItemsWith(
                            rootWindow.singleItemForBackend(rootWindow.contextFileRow),
                            "Qt Creator"
                        )
                    )
                }
            }
        }

        StyledMenuItem {
            text: "Windows Media Player"
            darkTheme: Theme.AppTheme.isDark
            enabled: rootWindow.contextFileRow >= 0
            onTriggered: {
                if (rootWindow.contextFileRow >= 0) {
                    rootWindow.applySnapshot(
                        rootWindow.backend.openItemsWith(
                            rootWindow.singleItemForBackend(rootWindow.contextFileRow),
                            "Windows Media Player"
                        )
                    )
                }
            }
        }

        StyledMenuSeparator {}

        StyledMenuItem {
            text: "Choose another app..."
            darkTheme: Theme.AppTheme.isDark
            enabled: rootWindow.contextFileRow >= 0
            onTriggered: {
                if (rootWindow.contextFileRow >= 0) {
                    rootWindow.applySnapshot(
                        rootWindow.backend.chooseOpenWithApp(
                            rootWindow.singleItemForBackend(rootWindow.contextFileRow)
                        )
                    )
                }
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

    StyledMenu {
        title: "Copy paths"
        darkTheme: Theme.AppTheme.isDark

        StyledMenuItem {
            text: "Full path"
            darkTheme: Theme.AppTheme.isDark
            enabled: rootWindow.contextFileRow >= 0
            onTriggered: {
                if (rootWindow.contextFileRow >= 0) {
                    rootWindow.copyPathsForItems(
                        rootWindow.singleItemForBackend(rootWindow.contextFileRow),
                        false,
                        false
                    )
                }
            }
        }

        StyledMenuItem {
            text: "Relative path"
            darkTheme: Theme.AppTheme.isDark
            enabled: rootWindow.contextFileRow >= 0
            onTriggered: {
                if (rootWindow.contextFileRow >= 0) {
                    rootWindow.copyPathsForItems(
                        rootWindow.singleItemForBackend(rootWindow.contextFileRow),
                        true,
                        false
                    )
                }
            }
        }

        StyledMenuSeparator {}

        StyledMenuItem {
            text: "Full paths recursively"
            darkTheme: Theme.AppTheme.isDark
            enabled: rootWindow.contextFileRow >= 0
            onTriggered: {
                if (rootWindow.contextFileRow >= 0) {
                    rootWindow.copyPathsForItems(
                        rootWindow.singleItemForBackend(rootWindow.contextFileRow),
                        false,
                        true
                    )
                }
            }
        }

        StyledMenuItem {
            text: "Relative paths recursively"
            darkTheme: Theme.AppTheme.isDark
            enabled: rootWindow.contextFileRow >= 0
            onTriggered: {
                if (rootWindow.contextFileRow >= 0) {
                    rootWindow.copyPathsForItems(
                        rootWindow.singleItemForBackend(rootWindow.contextFileRow),
                        true,
                        true
                    )
                }
            }
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