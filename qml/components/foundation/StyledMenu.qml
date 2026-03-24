import QtQuick
import QtQuick.Controls
import "../theme" as Theme

Menu {
    id: control

    property bool darkTheme: Theme.AppTheme.isDark

    implicitWidth: Theme.Metrics.menuWidth
    leftPadding: Theme.Metrics.spacingMd
    rightPadding: Theme.Metrics.spacingMd
    topPadding: Theme.Metrics.spacingMd
    bottomPadding: Theme.Metrics.spacingMd
    overlap: 2

    background: Rectangle {
        radius: Theme.Metrics.radiusLg
        color: Theme.AppTheme.popupBg
        border.color: Theme.AppTheme.border
        border.width: Theme.Metrics.borderWidth
    }

    delegate: StyledMenuItem {}
}