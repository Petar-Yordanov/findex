import QtQuick
import "../../components/foundation"
import "../../components/theme" as Theme

StyledMenu {
    id: copyPathsMenu

    property var rootWindow

    title: "Copy paths"
    darkTheme: Theme.AppTheme.isDark

    StyledMenuItem {
        text: "Full path"
        darkTheme: Theme.AppTheme.isDark
        enabled: copyPathsMenu.rootWindow
                 && (copyPathsMenu.rootWindow.selectedFileCount() > 0
                     || copyPathsMenu.rootWindow.currentFileRow >= 0)
        onTriggered: copyPathsMenu.rootWindow.copySelectedOrCurrentPaths(false, false)
    }

    StyledMenuItem {
        text: "Relative path"
        darkTheme: Theme.AppTheme.isDark
        enabled: copyPathsMenu.rootWindow
                 && (copyPathsMenu.rootWindow.selectedFileCount() > 0
                     || copyPathsMenu.rootWindow.currentFileRow >= 0)
        onTriggered: copyPathsMenu.rootWindow.copySelectedOrCurrentPaths(true, false)
    }

    StyledMenuSeparator {}

    StyledMenuItem {
        text: "Full paths recursively"
        darkTheme: Theme.AppTheme.isDark
        enabled: copyPathsMenu.rootWindow
                 && (copyPathsMenu.rootWindow.selectedFileCount() > 0
                     || copyPathsMenu.rootWindow.currentFileRow >= 0)
        onTriggered: copyPathsMenu.rootWindow.copySelectedOrCurrentPaths(false, true)
    }

    StyledMenuItem {
        text: "Relative paths recursively"
        darkTheme: Theme.AppTheme.isDark
        enabled: copyPathsMenu.rootWindow
                 && (copyPathsMenu.rootWindow.selectedFileCount() > 0
                     || copyPathsMenu.rootWindow.currentFileRow >= 0)
        onTriggered: copyPathsMenu.rootWindow.copySelectedOrCurrentPaths(true, true)
    }
}