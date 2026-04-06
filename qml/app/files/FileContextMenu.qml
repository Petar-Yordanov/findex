import QtQuick
import "../../components/foundation"
import "../../components/theme" as Theme

StyledMenu {
    id: menu

    required property var viewModel
    property int rowIndex: -1

    darkTheme: Theme.AppTheme.isDark

    onRowIndexChanged: {
        if (viewModel && rowIndex >= 0)
            viewModel.prepareOpenWithForRow(rowIndex)
    }

    StyledMenuItem {
        text: "Open"
        darkTheme: Theme.AppTheme.isDark
        enabled: rowIndex >= 0

        onTriggered: {
            if (viewModel && rowIndex >= 0)
                viewModel.openRow(rowIndex)
            menu.close()
        }
    }

    Repeater {
        model: viewModel ? viewModel.openWithApps : []

        delegate: StyledMenuItem {
            required property var modelData

            text: (modelData.isDefault ? "Open with " : "Open in ")
                  + (modelData.name || modelData.id || "App")
            darkTheme: Theme.AppTheme.isDark
            enabled: rowIndex >= 0

            onTriggered: {
                if (viewModel && rowIndex >= 0) {
                    const appKey = modelData.id || modelData.executable || modelData.name
                    viewModel.openRowWithApp(rowIndex, appKey)
                }
                menu.close()
            }
        }
    }

    StyledMenuSeparator {}

    StyledMenuItem {
        text: "Rename"
        darkTheme: Theme.AppTheme.isDark
        enabled: rowIndex >= 0

        onTriggered: {
            if (viewModel && rowIndex >= 0)
                viewModel.requestFileContextAction("Rename", rowIndex)
            menu.close()
        }
    }

    StyledMenuItem {
        text: "Copy"
        darkTheme: Theme.AppTheme.isDark
        enabled: rowIndex >= 0

        onTriggered: {
            if (viewModel && rowIndex >= 0)
                viewModel.requestFileContextAction("Copy", rowIndex)
            menu.close()
        }
    }

    StyledMenuItem {
        text: "Cut"
        darkTheme: Theme.AppTheme.isDark
        enabled: rowIndex >= 0

        onTriggered: {
            if (viewModel && rowIndex >= 0)
                viewModel.requestFileContextAction("Cut", rowIndex)
            menu.close()
        }
    }

    StyledMenuItem {
        text: "Delete"
        darkTheme: Theme.AppTheme.isDark
        enabled: rowIndex >= 0

        onTriggered: {
            if (viewModel && rowIndex >= 0)
                viewModel.requestFileContextAction("Delete", rowIndex)
            menu.close()
        }
    }
}