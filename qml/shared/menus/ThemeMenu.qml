import QtQuick
import "../../components/foundation"
import "../../components/theme" as Theme

StyledMenu {
    id: menu

    required property string currentThemeMode
    signal themeSelected(string mode)

    darkTheme: Theme.AppTheme.isDark

    StyledMenuItem {
        text: "Dark"
        darkTheme: Theme.AppTheme.isDark
        onTriggered: menu.themeSelected("Dark")
    }

    StyledMenuItem {
        text: "Light"
        darkTheme: Theme.AppTheme.isDark
        onTriggered: menu.themeSelected("Light")
    }

    StyledMenuItem {
        text: "System"
        darkTheme: Theme.AppTheme.isDark
        onTriggered: menu.themeSelected("System")
    }
}