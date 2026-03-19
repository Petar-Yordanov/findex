import QtQuick
import "../../components/foundation"
import "../../components/theme" as Theme

StyledMenu {
    id: menu

    required property bool enabledForSelection
    signal appSelected(string appName)
    signal chooseAnotherApp()

    title: "Open with..."
    darkTheme: Theme.AppTheme.isDark

    StyledMenuItem {
        text: "Notepad"
        enabled: menu.enabledForSelection
        darkTheme: Theme.AppTheme.isDark
        onTriggered: menu.appSelected("Notepad")
    }

    StyledMenuItem {
        text: "Visual Studio Code"
        enabled: menu.enabledForSelection
        darkTheme: Theme.AppTheme.isDark
        onTriggered: menu.appSelected("Visual Studio Code")
    }

    StyledMenuItem {
        text: "Qt Creator"
        enabled: menu.enabledForSelection
        darkTheme: Theme.AppTheme.isDark
        onTriggered: menu.appSelected("Qt Creator")
    }

    StyledMenuItem {
        text: "Windows Media Player"
        enabled: menu.enabledForSelection
        darkTheme: Theme.AppTheme.isDark
        onTriggered: menu.appSelected("Windows Media Player")
    }

    StyledMenuSeparator {}

    StyledMenuItem {
        text: "Choose another app..."
        enabled: menu.enabledForSelection
        darkTheme: Theme.AppTheme.isDark
        onTriggered: menu.chooseAnotherApp()
    }
}