import QtQuick
import QtQuick.Controls.Basic as Basic
import "../../../components/foundation"
import "../../../components/theme" as Theme

Rectangle {
    id: tabButton

    required property var rootWindow
    required property var viewModel
    required property var tabContextMenu
    required property var strip
    required property var tabsContentItem

    required property int index
    required property string title
    required property string icon
    required property bool active

    required property int tabWidth
    required property int tabSpacing

    readonly property int tabIndex: index
    readonly property string tabTitle: title
    readonly property string tabIcon: icon
    readonly property bool tabActive: active

    property bool dragging: false
    property real dragX: baseX
    property real pressOffsetX: 0
    property int dropIndex: tabIndex

    readonly property real baseX: tabIndex * (tabWidth + tabSpacing)

    x: dragging ? dragX : baseX
    y: Math.round(((parent ? parent.height : height) - height) / 2)
    width: tabWidth
    height: Theme.Metrics.controlHeightLg
    radius: 9
    z: dragging ? 100 : 1

    color: tabActive
           ? (mouseArea.pressed && !dragging
                ? (Theme.AppTheme.isDark ? "#2a3342" : "#e7edf8")
                : mouseArea.containsMouse
                  ? (Theme.AppTheme.isDark ? "#242c3a" : "#f4f7fc")
                  : (Theme.AppTheme.isDark ? "#202633" : "#ffffff"))
           : (mouseArea.pressed && !dragging
                ? (Theme.AppTheme.isDark ? "#2b3443" : "#dde5f0")
                : mouseArea.containsMouse
                  ? (Theme.AppTheme.isDark ? "#252e3c" : "#e7edf5")
                  : (Theme.AppTheme.isDark ? "#1b2230" : "#e9edf2"))

    border.color: tabActive
                  ? Theme.AppTheme.border
                  : (Theme.AppTheme.isDark ? "#2b3443" : "#cfd6df")
    border.width: Theme.Metrics.borderWidth

    function resetDrag() {
        dragging = false
        strip.draggingTab = false
        dragX = baseX
        dropIndex = tabIndex
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: Theme.Metrics.spacingLg
        anchors.rightMargin: 30
        visible: viewModel.editingIndex !== tabIndex

        AppIcon {
            id: tabIconItem
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            name: tabIcon || ""
            darkTheme: Theme.AppTheme.isDark
            iconSize: 15
            visible: name !== ""
        }

        Text {
            anchors.left: tabIconItem.visible ? tabIconItem.right : parent.left
            anchors.leftMargin: tabIconItem.visible ? Theme.Metrics.spacingSm : 0
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            text: tabTitle || ""
            color: Theme.AppTheme.text
            font.pixelSize: Theme.Typography.bodyLg
            font.bold: tabActive
            elide: Text.ElideRight
            maximumLineCount: 1
        }
    }

    Basic.TextField {
        id: renameField
        visible: viewModel.editingIndex === tabIndex

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: Theme.Metrics.spacingLg
        anchors.right: parent.right
        anchors.rightMargin: 30
        height: 24

        text: viewModel.editingTitle
        color: Theme.AppTheme.text
        font.pixelSize: Theme.Typography.bodyLg
        selectByMouse: true
        leftPadding: Theme.Metrics.spacingMd
        rightPadding: Theme.Metrics.spacingMd
        topPadding: 0
        bottomPadding: 0

        background: Rectangle {
            radius: Theme.Metrics.radiusSm
            color: Theme.AppTheme.popupBg
            border.color: Theme.AppTheme.accent
            border.width: Theme.Metrics.borderWidth
        }

        onVisibleChanged: {
            if (visible) {
                forceActiveFocus()
                selectAll()
            }
        }

        onTextChanged: {
            if (visible)
                viewModel.editingTitle = text
        }

        onAccepted: viewModel.commitRenameTab(tabIndex, text || "")

        onActiveFocusChanged: {
            if (!activeFocus && visible)
                viewModel.commitRenameTab(tabIndex, text || "")
        }

        Keys.onEscapePressed: viewModel.cancelRenameTab()
    }

    Rectangle {
        id: closeButton
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: Theme.Metrics.spacingSm
        width: 18
        height: 18
        radius: 6
        visible: viewModel.editingIndex !== tabIndex

        color: closeMouse.pressed
               ? Theme.AppTheme.pressed
               : closeMouse.containsMouse
                 ? Theme.AppTheme.hover
                 : "transparent"

        border.color: closeMouse.containsMouse
                      ? Theme.AppTheme.border
                      : "transparent"
        border.width: closeMouse.containsMouse ? 1 : 0

        AppIcon {
            anchors.centerIn: parent
            name: "close"
            darkTheme: Theme.AppTheme.isDark
            iconSize: 10
            iconOpacity: closeMouse.containsMouse || closeMouse.pressed ? 1.0 : 0.78
        }

        MouseArea {
            id: closeMouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton

            onPressed: {
                if (viewModel.editingIndex >= 0)
                    viewModel.cancelRenameTab()
            }

            onClicked: function(mouse) {
                viewModel.closeTab(tabIndex)
                mouse.accepted = true
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        anchors.rightMargin: viewModel.editingIndex === tabIndex ? 6 : 30
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        enabled: viewModel.editingIndex !== tabIndex

        onPressed: function(mouse) {
            if (mouse.button === Qt.RightButton) {
                if (viewModel.editingIndex >= 0)
                    viewModel.cancelRenameTab()

                tabContextMenu.tabIndex = tabIndex
                var p = tabButton.mapToItem(tabContextMenu.parent, mouse.x, mouse.y)
                tabContextMenu.popupAt(p.x, p.y)
                return
            }

            pressOffsetX = mouse.x
            dropIndex = tabIndex
        }

        onPositionChanged: function(mouse) {
            if (!(mouse.buttons & Qt.LeftButton))
                return

            var p = tabButton.mapToItem(tabsContentItem, mouse.x, mouse.y)
            var proposedX = p.x - pressOffsetX

            if (!dragging && Math.abs(proposedX - baseX) > 8) {
                dragging = true
                strip.draggingTab = true
            }

            if (!dragging)
                return

            dragX = proposedX
            var centerX = dragX + width / 2
            dropIndex = strip.indexAtContentX(centerX)
        }

        onReleased: function(mouse) {
            if (mouse.button !== Qt.LeftButton)
                return

            if (dragging) {
                if (viewModel && dropIndex !== tabIndex)
                    viewModel.moveTab(tabIndex, dropIndex)

                resetDrag()
                return
            }

            if (viewModel)
                viewModel.activateTab(tabIndex)
        }

        onCanceled: resetDrag()
        onDoubleClicked: viewModel.beginRenameTab(tabIndex)
    }
}