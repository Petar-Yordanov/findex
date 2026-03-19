import QtQuick
import "../../components/foundation"
import "../../components/theme" as Theme

StyledMenu {
    id: menu

    required property bool enabledForSelection
    property string menuTitle: "Copy paths"

    signal copyRequested(bool relativeToCurrentDir, bool recursive)

    title: menu.menuTitle
    darkTheme: Theme.AppTheme.isDark

    StyledMenuItem {
        text: "Full path"
        enabled: menu.enabledForSelection
        darkTheme: Theme.AppTheme.isDark
        onTriggered: menu.copyRequested(false, false)
    }

    StyledMenuItem {
        text: "Relative path"
        enabled: menu.enabledForSelection
        darkTheme: Theme.AppTheme.isDark
        onTriggered: menu.copyRequested(true, false)
    }

    StyledMenuSeparator {}

    StyledMenuItem {
        text: "Full paths recursively"
        enabled: menu.enabledForSelection
        darkTheme: Theme.AppTheme.isDark
        onTriggered: menu.copyRequested(false, true)
    }

    StyledMenuItem {
        text: "Relative paths recursively"
        enabled: menu.enabledForSelection
        darkTheme: Theme.AppTheme.isDark
        onTriggered: menu.copyRequested(true, true)
    }
}