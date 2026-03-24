import QtQuick
import QtQuick.Controls
import "../../components/foundation"
import "../../components/theme" as Theme

Rectangle {
    required property var rootWindow
    required property int index
    required property string title
    required property string icon
    required property var tabsModel
    required property var tabFlick
    required property var tabViewport

    property bool movedEnough: false

    x: index * (rootWindow.tabWidth + rootWindow.tabSpacing)
    y: 1
    width: rootWindow.tabWidth
    height: Theme.Metrics.controlHeightLg
    radius: 9
    z: rootWindow.draggedTabIndex === index ? 100 : 1

    transform: Translate {
        x: rootWindow.draggedTabIndex === index ? rootWindow.draggedTabOffset : 0
    }

    color: index === rootWindow.currentTab
           ? (tabMouse.pressed
                ? (Theme.AppTheme.isDark ? "#2a3342" : "#e7edf8")
                : tabMouse.containsMouse
                  ? (Theme.AppTheme.isDark ? "#242c3a" : "#f4f7fc")
                  : (Theme.AppTheme.isDark ? "#202633" : "#ffffff"))
           : (tabMouse.pressed
                ? Theme.AppTheme.pressed
                : tabMouse.containsMouse
                  ? Theme.AppTheme.hover
                  : "transparent")

    border.color: index === rootWindow.currentTab ? Theme.AppTheme.border : "transparent"
    border.width: Theme.Metrics.borderWidth

    DropArea {
        anchors.fill: parent
        z: 2

        function maybeActivate() {
            if (rootWindow.draggedFileCount > 0 && rootWindow.currentTab !== index) {
                rootWindow.activateTabLocal(index)
                rootWindow.ensureTabVisible(index)
            }
        }

        onEntered: function(drag) {
            if (rootWindow.draggedFileCount > 0) {
                drag.accepted = true
                maybeActivate()
            }
        }

        onPositionChanged: function(drag) {
            if (rootWindow.draggedFileCount > 0) {
                drag.accepted = true
                maybeActivate()
            }
        }

        onDropped: function(drop) {
            if (rootWindow.draggedFileCount > 0) {
                drop.accepted = true
                maybeActivate()
            }
        }
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: Theme.Metrics.spacingXl
        spacing: Theme.Metrics.spacingMd
        visible: rootWindow.editingTabIndex !== index

        AppIcon {
            name: icon || ""
            darkTheme: Theme.AppTheme.isDark
            iconSize: 15
        }

        Text {
            text: title || ""
            color: Theme.AppTheme.text
            font.pixelSize: Theme.Typography.bodyLg
            font.bold: index === rootWindow.currentTab
            elide: Text.ElideRight
            width: 140
        }
    }

    TextField {
        visible: rootWindow.editingTabIndex === index
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: Theme.Metrics.spacingXl
        anchors.right: closeButton.left
        anchors.rightMargin: Theme.Metrics.spacingMd
        height: 24

        text: rootWindow.editingTabTitleDraft || ""
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
                rootWindow.editingTabTitleDraft = text
        }

        onAccepted: rootWindow.commitRenameTab(index, text || "")

        onActiveFocusChanged: {
            if (!activeFocus && visible)
                rootWindow.commitRenameTab(index, text || "")
        }

        Keys.onEscapePressed: rootWindow.cancelRenameTab()
    }

    Rectangle {
        id: closeButton
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: Theme.Metrics.spacingSm
        width: 18
        height: 18
        radius: 9
        color: closeMouse.containsMouse ? Theme.AppTheme.hover : "transparent"
        z: 3
        visible: rootWindow.editingTabIndex !== index

        AppIcon {
            anchors.centerIn: parent
            name: "close"
            darkTheme: Theme.AppTheme.isDark
            iconSize: Theme.Metrics.iconXs
            iconOpacity: 0.75
        }

        MouseArea {
            id: closeMouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            preventStealing: true

            onClicked: function(mouse) {
                rootWindow.closeTab(index)
                mouse.accepted = true
            }
        }
    }

    DragHandler {
        id: dragHandler
        target: null
        acceptedButtons: Qt.LeftButton
        enabled: rootWindow.editingTabIndex !== index
        xAxis.enabled: true
        yAxis.enabled: false
        grabPermissions: PointerHandler.CanTakeOverFromAnything

        onActiveChanged: {
            rootWindow.tabDragActive = active

            if (active) {
                rootWindow.tabPressActive = true
                rootWindow.currentTab = index
                rootWindow.draggedTabIndex = index
                rootWindow.draggedTabStartIndex = index
                rootWindow.draggedTabStartContentX = tabFlick.contentX
                rootWindow.draggedTabOffset = 0
                movedEnough = false
                rootWindow.tabAutoScrollDirection = 0
                rootWindow.tabAutoScrollTimerRef.start()
            } else {
                var rw = rootWindow
                var startIndex = rw.draggedTabStartIndex
                var endIndex = rw.draggedTabIndex

                rw.tabAutoScrollDirection = 0
                rw.tabAutoScrollTimerRef.stop()

                if (startIndex >= 0 && endIndex >= 0 && startIndex !== endIndex) {
                    var finalIndex = endIndex

                    rw.applySnapshot(
                        rw.backend.moveTab(startIndex, finalIndex),
                        { preserveTabsOrder: true }
                    )

                    rw.currentTab = finalIndex

                    if (rw.backend && rw.backend.activateTab) {
                        rw.applySnapshot(
                            rw.backend.activateTab(finalIndex),
                            { preserveTabsOrder: true }
                        )
                    }

                    Qt.callLater(function() {
                        rw.ensureTabVisible(finalIndex)
                    })
                }

                rw.draggedTabIndex = -1
                rw.draggedTabStartIndex = -1
                rw.draggedTabStartContentX = 0
                rw.draggedTabOffset = 0
                rw.tabPressActive = false
                movedEnough = false
            }
        }

        onTranslationChanged: {
            if (rootWindow.draggedTabIndex < 0)
                return

            if (Math.abs(translation.x) > 8)
                movedEnough = true

            var slotSize = rootWindow.tabWidth + rootWindow.tabSpacing
            var currentIndex = rootWindow.draggedTabIndex
            var startIndex = rootWindow.draggedTabStartIndex
            var scrollDelta = tabFlick.contentX - rootWindow.draggedTabStartContentX

            var draggedLeftX = startIndex * slotSize + translation.x + scrollDelta
            var draggedCenterX = draggedLeftX + rootWindow.tabWidth / 2

            var targetIndex = Math.floor(draggedCenterX / slotSize)
            targetIndex = Math.max(0, Math.min(tabsModel.count - 1, targetIndex))

            rootWindow.draggedTabOffset = draggedLeftX - currentIndex * slotSize

            if (targetIndex !== currentIndex) {
                rootWindow.moveTabLocally(currentIndex, targetIndex)
                rootWindow.draggedTabIndex = targetIndex
            }

            var draggedCenterInViewport = draggedCenterX - tabFlick.contentX

            if (draggedCenterInViewport < 36)
                rootWindow.tabAutoScrollDirection = -1
            else if (draggedCenterInViewport > tabViewport.width - 36)
                rootWindow.tabAutoScrollDirection = 1
            else
                rootWindow.tabAutoScrollDirection = 0
        }
    }

    MouseArea {
        id: tabMouse
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.rightMargin: rootWindow.editingTabIndex === index ? 6 : 30
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        enabled: rootWindow.editingTabIndex !== index
        preventStealing: false

        onPressed: function(mouse) {
            rootWindow.tabPressActive = true

            if (rootWindow.editingTabIndex >= 0 && rootWindow.editingTabIndex !== index) {
                rootWindow.commitRenameTab(
                    rootWindow.editingTabIndex,
                    rootWindow.editingTabTitleDraft
                )
            }

            if (mouse.button === Qt.RightButton) {
                rootWindow.showTabContextMenu(index)
                return
            }

            if (mouse.button === Qt.LeftButton)
                rootWindow.currentTab = index
        }

        onReleased: {
            if (!dragHandler.active)
                rootWindow.tabPressActive = false
        }

        onCanceled: {
            rootWindow.tabPressActive = false
        }

        onClicked: function(mouse) {
            if (mouse.button === Qt.LeftButton && !movedEnough) {
                rootWindow.activateTabLocal(index)
                rootWindow.ensureTabVisible(index)
            }

            if (!dragHandler.active)
                rootWindow.tabPressActive = false
        }

        onDoubleClicked: {
            if (!movedEnough)
                rootWindow.beginRenameTab(index)
        }
    }
}