import QtQuick
import "../../components/foundation"
import "../../components/theme" as Theme

StyledMenu {
    id: menu

    required property var rootWindow

    darkTheme: Theme.AppTheme.isDark

    StyledMenuItem {
        text: "New folder"
        darkTheme: Theme.AppTheme.isDark
        onTriggered: rootWindow.addNewFolder()
    }

    StyledMenuItem {
        text: "New file"
        darkTheme: Theme.AppTheme.isDark
        onTriggered: rootWindow.addNewFile()
    }

    StyledMenuSeparator {}

    StyledMenuItem {
        text: "Paste"
        darkTheme: Theme.AppTheme.isDark
        onTriggered: rootWindow.applySnapshot(rootWindow.backend.pasteItems())
    }

    StyledMenuSeparator {}

    StyledMenuItem {
        text: "Refresh"
        darkTheme: Theme.AppTheme.isDark
        onTriggered: rootWindow.applySnapshot(rootWindow.backend.refresh())
    }

    StyledMenuItem {
        text: "Properties"
        darkTheme: Theme.AppTheme.isDark
        onTriggered: rootWindow.applySnapshot(rootWindow.backend.showCurrentLocationProperties())
    }
}