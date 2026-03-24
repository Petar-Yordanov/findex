import QtQuick
import "../../components/foundation"
import "../../components/theme" as Theme

StyledMenu {
    id: openWithMenu

    property var rootWindow

    title: "Open with..."
    darkTheme: Theme.AppTheme.isDark

    StyledMenuItem {
        text: "Notepad"
        darkTheme: Theme.AppTheme.isDark
        enabled: openWithMenu.rootWindow && openWithMenu.rootWindow.hasSelectedOrCurrentItems()
        onTriggered: openWithMenu.rootWindow.openSelectedOrCurrentWith("Notepad")
    }

    StyledMenuItem {
        text: "Visual Studio Code"
        darkTheme: Theme.AppTheme.isDark
        enabled: openWithMenu.rootWindow && openWithMenu.rootWindow.hasSelectedOrCurrentItems()
        onTriggered: openWithMenu.rootWindow.openSelectedOrCurrentWith("Visual Studio Code")
    }

    StyledMenuItem {
        text: "Qt Creator"
        darkTheme: Theme.AppTheme.isDark
        enabled: openWithMenu.rootWindow && openWithMenu.rootWindow.hasSelectedOrCurrentItems()
        onTriggered: openWithMenu.rootWindow.openSelectedOrCurrentWith("Qt Creator")
    }

    StyledMenuItem {
        text: "Windows Media Player"
        darkTheme: Theme.AppTheme.isDark
        enabled: openWithMenu.rootWindow && openWithMenu.rootWindow.hasSelectedOrCurrentItems()
        onTriggered: openWithMenu.rootWindow.openSelectedOrCurrentWith("Windows Media Player")
    }

    StyledMenuSeparator {}

    StyledMenuItem {
        text: "Choose another app..."
        darkTheme: Theme.AppTheme.isDark
        enabled: openWithMenu.rootWindow && openWithMenu.rootWindow.hasSelectedOrCurrentItems()
        onTriggered: openWithMenu.rootWindow.chooseOpenWithForSelectedOrCurrent()
    }
}