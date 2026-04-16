import QtQuick
import QtQuick.Controls
import "../theme" as Theme

Popup {
    id: control

    property bool darkTheme: Theme.AppTheme.isDark
    property int menuWidth: 184
    property int edgeMargin: 6

    default property alias contentData: menuColumn.data

    modal: false
    focus: true

    padding: 8
    topPadding: 8
    bottomPadding: 8
    leftPadding: 8
    rightPadding: 8
    margins: 0

    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    width: menuWidth + leftPadding + rightPadding
    implicitWidth: width
    implicitHeight: menuColumn.childrenRect.height + topPadding + bottomPadding
    height: implicitHeight

    background: Rectangle {
        radius: Theme.Metrics.radiusLg
        color: Theme.AppTheme.popupBg
        border.color: Theme.AppTheme.border
        border.width: Theme.Metrics.borderWidth
    }

    contentItem: Column {
        id: menuColumn
        width: control.menuWidth
        spacing: 0
    }

    function popupAt(px, py) {
        var popupWidth = control.width
        var popupHeight = control.implicitHeight

        var nextX = px + 2
        var nextY = py + 2

        if (parent) {
            nextX = Math.max(edgeMargin, Math.min(nextX, parent.width - popupWidth - edgeMargin))
            nextY = Math.max(edgeMargin, Math.min(nextY, parent.height - popupHeight - edgeMargin))
        }

        if (control.visible) {
            if (control.x !== nextX)
                control.x = nextX
            if (control.y !== nextY)
                control.y = nextY
            return
        }

        control.x = nextX
        control.y = nextY
        control.open()
    }

    function popupBeside(item, offsetX, offsetY) {
        if (!item || !parent)
            return

        var dx = offsetX === undefined ? 0 : offsetX
        var dy = offsetY === undefined ? 0 : offsetY

        var p = item.mapToItem(parent, item.width + dx, dy)
        popupAt(p.x, p.y)
    }

    function popup() {
        if (!control.visible)
            control.open()
    }
}