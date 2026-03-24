import QtQuick
import "../../components/foundation"
import "../../components/theme" as Theme

StyledMenu {
    id: viewModeMenu

    required property var rootWindow

    darkTheme: Theme.AppTheme.isDark

    StyledMenuItem {
        text: "Details"
        darkTheme: Theme.AppTheme.isDark
        onTriggered: {
            viewModeMenu.rootWindow.currentViewMode = "Details"
            viewModeMenu.rootWindow.applySnapshot(
                viewModeMenu.rootWindow.backend.setViewMode("Details")
            )
        }
    }

    StyledMenuItem {
        text: "Tiles"
        darkTheme: Theme.AppTheme.isDark
        onTriggered: {
            viewModeMenu.rootWindow.currentViewMode = "Tiles"
            viewModeMenu.rootWindow.applySnapshot(
                viewModeMenu.rootWindow.backend.setViewMode("Tiles")
            )
        }
    }

    StyledMenuItem {
        text: "Compact"
        darkTheme: Theme.AppTheme.isDark
        onTriggered: {
            viewModeMenu.rootWindow.currentViewMode = "Compact"
            viewModeMenu.rootWindow.applySnapshot(
                viewModeMenu.rootWindow.backend.setViewMode("Compact")
            )
        }
    }

    StyledMenuItem {
        text: "Large icons"
        darkTheme: Theme.AppTheme.isDark
        onTriggered: {
            viewModeMenu.rootWindow.currentViewMode = "Large icons"
            viewModeMenu.rootWindow.applySnapshot(
                viewModeMenu.rootWindow.backend.setViewMode("Large icons")
            )
        }
    }
}