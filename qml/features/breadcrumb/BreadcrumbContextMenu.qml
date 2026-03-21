import QtQuick
import "../../components/foundation"
import "../../components/theme" as Theme

StyledMenu {
    id: menu

    required property var rootWindow

    darkTheme: Theme.AppTheme.isDark

    StyledMenuItem {
        text: "Copy path"
        darkTheme: Theme.AppTheme.isDark
        enabled: rootWindow.contextBreadcrumbIndex >= 0
        onTriggered: rootWindow.copyBreadcrumbPathAt(rootWindow.contextBreadcrumbIndex)
    }
}