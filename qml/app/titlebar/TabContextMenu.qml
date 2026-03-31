import QtQuick
import "../../components/foundation"
import "../../components/theme" as Theme

StyledMenu {
    id: menu

    required property var viewModel
    property int tabIndex: -1

    darkTheme: Theme.AppTheme.isDark

    StyledMenuItem {
        text: "New tab"
        darkTheme: Theme.AppTheme.isDark

        onTriggered: {
            if (viewModel)
                viewModel.addTab()
            menu.close()
        }
    }

    StyledMenuItem {
        text: "Close tab"
        enabled: tabIndex >= 0
        darkTheme: Theme.AppTheme.isDark

        onTriggered: {
            if (tabIndex >= 0 && viewModel)
                viewModel.closeTab(tabIndex)
            menu.close()
        }
    }

    StyledMenuSeparator {}

    StyledMenuItem {
        text: "Rename tab"
        enabled: tabIndex >= 0
        darkTheme: Theme.AppTheme.isDark

        onTriggered: {
            if (tabIndex >= 0 && viewModel)
                viewModel.beginRenameTab(tabIndex)
            menu.close()
        }
    }
}