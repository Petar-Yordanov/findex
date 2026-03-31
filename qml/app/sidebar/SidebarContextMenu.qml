import QtQuick
import "../../components/foundation"
import "../../components/theme" as Theme

StyledMenu {
    id: menu

    required property var viewModel
    darkTheme: Theme.AppTheme.isDark

    StyledMenuItem {
        text: "Open"
        enabled: !!viewModel && viewModel.contextLabel !== ""
        darkTheme: Theme.AppTheme.isDark

        onTriggered: {
            if (!viewModel)
                return

            viewModel.openLocation(
                viewModel.contextLabel,
                viewModel.contextIcon,
                viewModel.contextKind
            )
            menu.close()
        }
    }

    StyledMenuItem {
        text: "Open in new tab"
        enabled: !!viewModel && viewModel.contextLabel !== ""
        darkTheme: Theme.AppTheme.isDark

        onTriggered: {
            if (viewModel)
                viewModel.requestOpenContextInNewTab()
            menu.close()
        }
    }

    StyledMenuSeparator {}

    StyledMenuItem {
        text: "Copy path"
        enabled: !!viewModel && viewModel.contextLabel !== ""
        darkTheme: Theme.AppTheme.isDark

        onTriggered: {
            if (viewModel)
                viewModel.requestCopyContextPath()
            menu.close()
        }
    }

    StyledMenuSeparator {}

    StyledMenuItem {
        text: "Pin"
        enabled: !!viewModel
                 && viewModel.contextLabel !== ""
                 && viewModel.contextKind !== "section"
        darkTheme: Theme.AppTheme.isDark

        onTriggered: {
            if (viewModel)
                viewModel.requestPinContext()
            menu.close()
        }
    }

    StyledMenuItem {
        text: "Properties"
        enabled: !!viewModel
                 && viewModel.contextLabel !== ""
                 && viewModel.contextKind !== "section"
        darkTheme: Theme.AppTheme.isDark

        onTriggered: {
            if (viewModel)
                viewModel.requestContextProperties()
            menu.close()
        }
    }
}