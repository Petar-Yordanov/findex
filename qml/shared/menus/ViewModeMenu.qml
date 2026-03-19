import QtQuick
import "../../components/foundation"
import "../../components/theme" as Theme

StyledMenu {
    id: menu

    required property string currentViewMode
    signal viewModeSelected(string mode)

    darkTheme: Theme.AppTheme.isDark

    StyledMenuItem {
        text: "Details"
        darkTheme: Theme.AppTheme.isDark
        onTriggered: menu.viewModeSelected("Details")
    }

    StyledMenuItem {
        text: "Tiles"
        darkTheme: Theme.AppTheme.isDark
        onTriggered: menu.viewModeSelected("Tiles")
    }

    StyledMenuItem {
        text: "Compact"
        darkTheme: Theme.AppTheme.isDark
        onTriggered: menu.viewModeSelected("Compact")
    }

    StyledMenuItem {
        text: "Large icons"
        darkTheme: Theme.AppTheme.isDark
        onTriggered: menu.viewModeSelected("Large icons")
    }
}