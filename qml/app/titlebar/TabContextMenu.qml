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
        text: "Close other tabs"
        enabled: tabIndex >= 0
        darkTheme: Theme.AppTheme.isDark

        onTriggered: {
            if (tabIndex >= 0 && viewModel)
                viewModel.closeOtherTabs(tabIndex)
            menu.close()
        }
    }

    StyledMenuItem {
        text: "Close tabs to the left"
        enabled: tabIndex >= 0
        darkTheme: Theme.AppTheme.isDark

        onTriggered: {
            if (tabIndex >= 0 && viewModel)
                viewModel.closeTabsToLeft(tabIndex)
            menu.close()
        }
    }

    StyledMenuItem {
        text: "Close tabs to the right"
        enabled: tabIndex >= 0
        darkTheme: Theme.AppTheme.isDark

        onTriggered: {
            if (tabIndex >= 0 && viewModel)
                viewModel.closeTabsToRight(tabIndex)
            menu.close()
        }
    }

    StyledMenuSeparator {}

    StyledMenuItem {
        text: "Duplicate tab"
        enabled: tabIndex >= 0
        darkTheme: Theme.AppTheme.isDark

        onTriggered: {
            if (tabIndex >= 0 && viewModel)
                viewModel.duplicateTab(tabIndex)
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