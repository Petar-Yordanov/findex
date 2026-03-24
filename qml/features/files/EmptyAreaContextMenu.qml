import QtQuick
import "../../components/foundation"
import "../../components/theme" as Theme

StyledMenu {
    id: menu

    required property var rootWindow

    darkTheme: Theme.AppTheme.isDark

    StyledMenu {
        title: "Change view"
        darkTheme: Theme.AppTheme.isDark

        StyledMenuItem {
            text: "Details"
            darkTheme: Theme.AppTheme.isDark
            onTriggered: {
                rootWindow.currentViewMode = "Details"
                rootWindow.applySnapshot(rootWindow.backend.setViewMode("Details"))
            }
        }

        StyledMenuItem {
            text: "Tiles"
            darkTheme: Theme.AppTheme.isDark
            onTriggered: {
                rootWindow.currentViewMode = "Tiles"
                rootWindow.applySnapshot(rootWindow.backend.setViewMode("Tiles"))
            }
        }

        StyledMenuItem {
            text: "Compact"
            darkTheme: Theme.AppTheme.isDark
            onTriggered: {
                rootWindow.currentViewMode = "Compact"
                rootWindow.applySnapshot(rootWindow.backend.setViewMode("Compact"))
            }
        }

        StyledMenuItem {
            text: "Large icons"
            darkTheme: Theme.AppTheme.isDark
            onTriggered: {
                rootWindow.currentViewMode = "Large icons"
                rootWindow.applySnapshot(rootWindow.backend.setViewMode("Large icons"))
            }
        }
    }

    StyledMenu {
        title: "New"
        darkTheme: Theme.AppTheme.isDark

        StyledMenuItem {
            text: "New folder"
            darkTheme: Theme.AppTheme.isDark
            onTriggered: rootWindow.addNewFolder()
        }

        StyledMenuItem {
            text: "New file"
            darkTheme: Theme.AppTheme.isDark
            onTriggered: rootWindow.addNewFile()
        }
    }

    StyledMenu {
        title: "Sort by"
        darkTheme: Theme.AppTheme.isDark

        StyledMenu {
            title: "Name"
            darkTheme: Theme.AppTheme.isDark

            StyledMenuItem {
                text: "Ascending"
                darkTheme: Theme.AppTheme.isDark
                onTriggered: rootWindow.sortFilesExplicit(0, true)
            }

            StyledMenuItem {
                text: "Descending"
                darkTheme: Theme.AppTheme.isDark
                onTriggered: rootWindow.sortFilesExplicit(0, false)
            }
        }

        StyledMenu {
            title: "Date modified"
            darkTheme: Theme.AppTheme.isDark

            StyledMenuItem {
                text: "Ascending"
                darkTheme: Theme.AppTheme.isDark
                onTriggered: rootWindow.sortFilesExplicit(1, true)
            }

            StyledMenuItem {
                text: "Descending"
                darkTheme: Theme.AppTheme.isDark
                onTriggered: rootWindow.sortFilesExplicit(1, false)
            }
        }

        StyledMenu {
            title: "Type"
            darkTheme: Theme.AppTheme.isDark

            StyledMenuItem {
                text: "Ascending"
                darkTheme: Theme.AppTheme.isDark
                onTriggered: rootWindow.sortFilesExplicit(2, true)
            }

            StyledMenuItem {
                text: "Descending"
                darkTheme: Theme.AppTheme.isDark
                onTriggered: rootWindow.sortFilesExplicit(2, false)
            }
        }

        StyledMenu {
            title: "Size"
            darkTheme: Theme.AppTheme.isDark

            StyledMenuItem {
                text: "Ascending"
                darkTheme: Theme.AppTheme.isDark
                onTriggered: rootWindow.sortFilesExplicit(3, true)
            }

            StyledMenuItem {
                text: "Descending"
                darkTheme: Theme.AppTheme.isDark
                onTriggered: rootWindow.sortFilesExplicit(3, false)
            }
        }
    }

    StyledMenuSeparator {}

    StyledMenuItem {
        text: "Select all"
        darkTheme: Theme.AppTheme.isDark
        onTriggered: rootWindow.selectAllFiles()
    }

    StyledMenuItem {
        text: "Properties"
        darkTheme: Theme.AppTheme.isDark
        onTriggered: rootWindow.applySnapshot(
            rootWindow.backend.showCurrentLocationProperties()
        )
    }
}