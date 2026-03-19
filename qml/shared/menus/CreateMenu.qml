import QtQuick
import "../../components/foundation"
import "../../components/theme" as Theme

StyledMenu {
    id: menu

    property string folderText: "New folder"
    property string fileText: "New file"

    signal newFolderRequested()
    signal newFileRequested()

    darkTheme: Theme.AppTheme.isDark

    StyledMenuItem {
        text: menu.folderText
        darkTheme: Theme.AppTheme.isDark
        onTriggered: menu.newFolderRequested()
    }

    StyledMenuItem {
        text: menu.fileText
        darkTheme: Theme.AppTheme.isDark
        onTriggered: menu.newFileRequested()
    }
}