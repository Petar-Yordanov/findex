import QtQuick
import "../../components/foundation"
import "../../components/theme" as Theme

StyledMenu {
    id: menu

    required property var rootWindow
    required property int tabsCount

    darkTheme: Theme.AppTheme.isDark

    StyledMenuItem {
        text: "New tab"
        darkTheme: Theme.AppTheme.isDark
        onTriggered: rootWindow.addTab("New Tab")
    }

    StyledMenuItem {
        text: "Close tab"
        enabled: rootWindow.contextTabIndex >= 0 && tabsCount > 1
        darkTheme: Theme.AppTheme.isDark
        onTriggered: rootWindow.closeTab(rootWindow.contextTabIndex)
    }

    StyledMenuItem {
        text: "Duplicate tab"
        enabled: rootWindow.contextTabIndex >= 0
        darkTheme: Theme.AppTheme.isDark
        onTriggered: {
            if (rootWindow.contextTabIndex >= 0) {
                rootWindow.applySnapshot(
                    rootWindow.backend.duplicateTab(rootWindow.contextTabIndex)
                )
            }
        }
    }

    StyledMenuSeparator {}

    StyledMenuItem {
        text: "Rename active tab"
        enabled: rootWindow.contextTabIndex >= 0
        darkTheme: Theme.AppTheme.isDark
        onTriggered: {
            if (rootWindow.contextTabIndex >= 0)
                rootWindow.beginRenameTab(rootWindow.contextTabIndex)
        }
    }
}