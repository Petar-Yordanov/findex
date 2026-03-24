import QtQuick
import "." as LocalMenus
import "../../components/foundation"
import "../../components/theme" as Theme

StyledMenu {
    id: moreActionsMenu

    property var rootWindow

    darkTheme: Theme.AppTheme.isDark

    StyledMenuItem {
        text: "Compress"
        darkTheme: Theme.AppTheme.isDark
        enabled: moreActionsMenu.rootWindow.hasSelectedOrCurrentItems()
        onTriggered: moreActionsMenu.rootWindow.compressSelectedOrCurrent()
    }

    StyledMenuItem {
        text: "Extract here"
        darkTheme: Theme.AppTheme.isDark
        enabled: moreActionsMenu.rootWindow.hasSelectedOrCurrentItems()
        onTriggered: moreActionsMenu.rootWindow.extractSelectedOrCurrent()
    }

    StyledMenuItem {
        text: "Duplicate"
        darkTheme: Theme.AppTheme.isDark
        enabled: moreActionsMenu.rootWindow.hasSelectedOrCurrentItems()
        onTriggered: moreActionsMenu.rootWindow.duplicateSelectedOrCurrent()
    }

    StyledMenuSeparator {}

    LocalMenus.OpenWithMenu {
        rootWindow: moreActionsMenu.rootWindow
    }

    LocalMenus.CopyPathsMenu {
        rootWindow: moreActionsMenu.rootWindow
    }

    StyledMenuItem {
        text: "Open in terminal"
        darkTheme: Theme.AppTheme.isDark
        enabled: moreActionsMenu.rootWindow.hasSelectedOrCurrentItems()
        onTriggered: moreActionsMenu.rootWindow.openSelectedOrCurrentInTerminal()
    }

    StyledMenuSeparator {}

    StyledMenuItem {
        text: "Select all"
        darkTheme: Theme.AppTheme.isDark
        onTriggered: moreActionsMenu.rootWindow.selectAllFiles()
    }

    StyledMenuItem {
        text: moreActionsMenu.rootWindow.showHiddenFiles ? "Hide hidden files" : "Show hidden files"
        darkTheme: Theme.AppTheme.isDark
        onTriggered: moreActionsMenu.rootWindow.applySnapshot(
            moreActionsMenu.rootWindow.backend.setShowHiddenFiles(
                !moreActionsMenu.rootWindow.showHiddenFiles
            )
        )
    }

    StyledMenuItem {
        text: "Properties"
        darkTheme: Theme.AppTheme.isDark
        onTriggered: moreActionsMenu.rootWindow.showPropertiesForSelectedOrCurrentOrLocation()
    }
}