import QtQuick
import "../theme" as Theme

Item {
    id: control

    property bool darkTheme: Theme.AppTheme.isDark

    width: parent && parent.width > 0 ? parent.width : implicitWidth
    implicitWidth: 184
    implicitHeight: 8

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        height: 1
        color: Theme.AppTheme.separator
    }
}