import QtQuick
import "../../components/foundation"
import "../../components/theme" as Theme

StyledMenu {
    id: menu

    required property var viewModel
    property int rowIndex: -1

    darkTheme: Theme.AppTheme.isDark

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

    StyledMenuSeparator {}

    StyledMenuItem {
        text: "Properties"
        darkTheme: Theme.AppTheme.isDark
        enabled: rowIndex >= 0

        onTriggered: {
            if (viewModel && rowIndex >= 0)
                viewModel.requestFileContextAction("Properties", rowIndex)
            menu.close()
        }
    }
}