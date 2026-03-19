import QtQuick
import "../../components/foundation"
import "../../components/theme" as Theme
import "../../shared/menus"

StyledMenu {
    id: menu

    required property var rootWindow

    darkTheme: Theme.AppTheme.isDark

    ViewModeMenu {
        title: "Change view"
        currentViewMode: rootWindow.currentViewMode

        onViewModeSelected: function(mode) {
            rootWindow.currentViewMode = mode
            rootWindow.applySnapshot(rootWindow.backend.setViewMode(mode))
        }
    }

    CreateMenu {
        title: "New"
        fileText: "File"
        folderText: "Folder"

        onNewFileRequested: rootWindow.addNewFile()
        onNewFolderRequested: rootWindow.addNewFolder()
    }

    SortByMenu {
        onSortRequested: function(column, ascending) {
            rootWindow.sortFilesExplicit(column, ascending)
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