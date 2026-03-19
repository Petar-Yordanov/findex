import QtQuick
import "../../components/foundation"
import "../../components/theme" as Theme

StyledMenu {
    id: menu

    required property var rootWindow

    darkTheme: Theme.AppTheme.isDark

    StyledMenuItem {
        text: "Open"
        enabled: rootWindow.contextSidebarLabel !== ""
        darkTheme: Theme.AppTheme.isDark
        onTriggered: rootWindow.openLocation(
            rootWindow.contextSidebarLabel,
            rootWindow.contextSidebarIcon,
            rootWindow.contextSidebarKind
        )
    }

    StyledMenuItem {
        text: "Open in new tab"
        enabled: rootWindow.contextSidebarLabel !== ""
        darkTheme: Theme.AppTheme.isDark
        onTriggered: rootWindow.openSidebarContextInNewTab()
    }

    StyledMenuSeparator {}

    StyledMenuItem {
        text: "Copy path"
        enabled: rootWindow.contextSidebarLabel !== ""
        darkTheme: Theme.AppTheme.isDark
        onTriggered: rootWindow.copySidebarContextPath()
    }

    StyledMenuSeparator {}

    StyledMenuItem {
        text: "Pin"
        enabled: rootWindow.contextSidebarLabel !== ""
                 && rootWindow.contextSidebarKind !== "section"
        darkTheme: Theme.AppTheme.isDark
        onTriggered: rootWindow.applySnapshot(
            rootWindow.backend.pinSidebarLocation(
                rootWindow.contextSidebarLabel,
                rootWindow.contextSidebarKind
            )
        )
    }

    StyledMenuItem {
        text: "Properties"
        enabled: rootWindow.contextSidebarLabel !== ""
                 && rootWindow.contextSidebarKind !== "section"
        darkTheme: Theme.AppTheme.isDark
        onTriggered: rootWindow.applySnapshot(
            rootWindow.backend.showSidebarLocationProperties(
                rootWindow.contextSidebarLabel,
                rootWindow.contextSidebarKind
            )
        )
    }
}