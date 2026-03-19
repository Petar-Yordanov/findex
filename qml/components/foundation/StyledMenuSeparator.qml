import QtQuick
import QtQuick.Controls
import "../theme" as Theme

MenuSeparator {
    id: control

    property bool darkTheme: Theme.AppTheme.isDark

    implicitWidth: Theme.Metrics.menuWidth
    implicitHeight: 10
    padding: 0

    contentItem: Item {
        implicitWidth: Theme.Metrics.menuWidth
        implicitHeight: 10

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            x: 12
            width: parent.width - 24
            height: 1
            color: Theme.AppTheme.separator
        }
    }

    background: Item {}
}