import QtQuick
import "../../components/foundation"
import "../../components/theme" as Theme

StyledMenu {
    id: popup

    required property var viewModel
    darkTheme: Theme.AppTheme.isDark
    menuWidth: 260

    StyledMenuItem {
        text: viewModel && viewModel.notificationCount > 0
              ? (viewModel.notificationCount + " notification(s)")
              : "No notifications"
        darkTheme: Theme.AppTheme.isDark
        enabled: false
    }

    StyledMenuSeparator {}

    StyledMenuItem {
        text: "Nothing wired yet"
        darkTheme: Theme.AppTheme.isDark
        enabled: false
    }
}