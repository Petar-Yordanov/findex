import QtQuick
import "../../components/foundation"
import "../../components/theme" as Theme

StyledMenu {
    id: createMenu

    required property var rootWindow

    darkTheme: Theme.AppTheme.isDark

    StyledMenuItem {
        text: "New folder"
        darkTheme: Theme.AppTheme.isDark
        onTriggered: createMenu.rootWindow.addNewFolder()
    }

    StyledMenuItem {
        text: "New file"
        darkTheme: Theme.AppTheme.isDark
        onTriggered: createMenu.rootWindow.addNewFile()
    }
}