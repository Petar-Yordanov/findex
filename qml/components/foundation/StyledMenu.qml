import QtQuick
import QtQuick.Controls
import "../theme" as Theme

Menu {
    id: control

    property bool darkTheme: Theme.AppTheme.isDark

    implicitWidth: Theme.Metrics.menuWidth
    leftPadding: 8
    rightPadding: 8
    topPadding: 8
    bottomPadding: 8
    overlap: 2

    background: Rectangle {
        radius: Theme.Metrics.radiusLg
        color: Theme.AppTheme.popupBg
        border.color: Theme.AppTheme.border
        border.width: Theme.Metrics.borderWidth
    }

    delegate: StyledMenuItem {}
}