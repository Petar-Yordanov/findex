import QtQuick
import "../../components/foundation"
import "../../components/theme" as Theme

StyledMenu {
    id: themeMenu

    required property var rootWindow

    darkTheme: Theme.AppTheme.isDark

    StyledMenuItem {
        text: "Dark"
        darkTheme: Theme.AppTheme.isDark
        onTriggered: {
            themeMenu.rootWindow.themeMode = "Dark"
            themeMenu.rootWindow.applySnapshot(
                themeMenu.rootWindow.backend.setTheme("Dark")
            )
        }
    }

    StyledMenuItem {
        text: "Light"
        darkTheme: Theme.AppTheme.isDark
        onTriggered: {
            themeMenu.rootWindow.themeMode = "Light"
            themeMenu.rootWindow.applySnapshot(
                themeMenu.rootWindow.backend.setTheme("Light")
            )
        }
    }
}