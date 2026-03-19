import QtQuick
import "../../components/foundation"
import "../../components/theme" as Theme

StyledMenu {
    id: menu

    signal sortRequested(int column, bool ascending)

    darkTheme: Theme.AppTheme.isDark
    title: "Sort by"

    StyledMenu {
        title: "Name"
        darkTheme: Theme.AppTheme.isDark

        StyledMenuItem {
            text: "Ascending"
            darkTheme: Theme.AppTheme.isDark
            onTriggered: menu.sortRequested(0, true)
        }
        StyledMenuItem {
            text: "Descending"
            darkTheme: Theme.AppTheme.isDark
            onTriggered: menu.sortRequested(0, false)
        }
    }

    StyledMenu {
        title: "Date modified"
        darkTheme: Theme.AppTheme.isDark

        StyledMenuItem {
            text: "Ascending"
            darkTheme: Theme.AppTheme.isDark
            onTriggered: menu.sortRequested(1, true)
        }
        StyledMenuItem {
            text: "Descending"
            darkTheme: Theme.AppTheme.isDark
            onTriggered: menu.sortRequested(1, false)
        }
    }

    StyledMenu {
        title: "Type"
        darkTheme: Theme.AppTheme.isDark

        StyledMenuItem {
            text: "Ascending"
            darkTheme: Theme.AppTheme.isDark
            onTriggered: menu.sortRequested(2, true)
        }
        StyledMenuItem {
            text: "Descending"
            darkTheme: Theme.AppTheme.isDark
            onTriggered: menu.sortRequested(2, false)
        }
    }

    StyledMenu {
        title: "Size"
        darkTheme: Theme.AppTheme.isDark

        StyledMenuItem {
            text: "Ascending"
            darkTheme: Theme.AppTheme.isDark
            onTriggered: menu.sortRequested(3, true)
        }
        StyledMenuItem {
            text: "Descending"
            darkTheme: Theme.AppTheme.isDark
            onTriggered: menu.sortRequested(3, false)
        }
    }
}