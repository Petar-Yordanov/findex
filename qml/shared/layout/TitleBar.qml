import QtQuick
import QtQuick.Layouts
import "../../components/foundation"
import "../../components/theme" as Theme

Rectangle {
    id: titleBar

    required property var rootWindow
    required property var tabsModel
    required property var tabContextMenu

    color: Theme.AppTheme.titleBg
    border.color: Theme.AppTheme.borderSoft
    border.width: Theme.Metrics.borderWidth

    Component.onCompleted: {
        rootWindow.tabFlickRef = tabFlick
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.Metrics.spacingLg
        anchors.rightMargin: Theme.Metrics.spacingSm
        spacing: Theme.Metrics.spacingMd

        Item {
            id: tabsArea
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignVCenter

            MouseArea {
                id: tabsCaptionArea
                anchors.fill: parent
                z: 0
                acceptedButtons: Qt.LeftButton
                hoverEnabled: false

                onPressed: function(mouse) {
                    if (mouse.button === Qt.LeftButton)
                        rootWindow.startSystemMove()
                }

                onDoubleClicked: rootWindow.toggleMaximize()
            }

            Row {
                id: tabsRow
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: 34
                spacing: Theme.Metrics.spacingSm
                z: 2

                readonly property bool overflowing: tabsContent.width > Math.max(
                    0,
                    tabsRow.width - addTabButton.width - tabsRow.spacing
                )

                Rectangle {
                    id: scrollLeftButton
                    width: 26
                    height: 26
                    radius: Theme.Metrics.radiusMd
                    anchors.verticalCenter: parent.verticalCenter
                    visible: tabsRow.overflowing
                    color: leftScrollMouse.pressed
                           ? Theme.AppTheme.pressed
                           : leftScrollMouse.containsMouse
                             ? Theme.AppTheme.hover
                             : "transparent"
                    opacity: tabFlick.contentX > 0 ? 1.0 : 0.45

                    AppIcon {
                        anchors.centerIn: parent
                        name: "chevron-left"
                        darkTheme: Theme.AppTheme.isDark
                        iconSize: Theme.Metrics.iconSm
                    }

                    MouseArea {
                        id: leftScrollMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: tabFlick.contentX > 0
                        onClicked: rootWindow.scrollTabsBy(-240)
                    }
                }

                Item {
                    id: tabCluster
                    height: parent.height
                    width: Math.max(
                               0,
                               tabsRow.width
                               - (tabsRow.overflowing ? scrollLeftButton.width : 0)
                               - (tabsRow.overflowing ? scrollRightButton.width : 0)
                               - (tabsRow.overflowing ? tabsRow.spacing * 2 : 0)
                           )

                    Item {
                        id: addTabDock
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        x: Math.min(
                               Math.max(0, tabsContent.width + rootWindow.tabSpacing),
                               Math.max(0, tabCluster.width - addTabButton.width)
                           )
                        width: addTabButton.width
                        z: 6

                        Rectangle {
                            id: addTabButton
                            width: Theme.Metrics.controlHeightMd
                            height: Theme.Metrics.controlHeightMd
                            radius: Theme.Metrics.radiusMd
                            anchors.verticalCenter: parent.verticalCenter
                            color: addTabMouse.containsMouse ? Theme.AppTheme.hover : "transparent"

                            AppIcon {
                                anchors.centerIn: parent
                                name: "add"
                                darkTheme: Theme.AppTheme.isDark
                                iconSize: Theme.Metrics.iconMd
                            }

                            MouseArea {
                                id: addTabMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    rootWindow.addTab("New Tab")
                                    Qt.callLater(function() {
                                        rootWindow.ensureTabVisible(tabsModel.count - 1)
                                    })
                                }
                            }
                        }
                    }

                    Item {
                        id: tabViewport
                        x: 0
                        y: 0
                        width: addTabDock.x
                        height: parent.height
                        clip: true

                        Flickable {
                            id: tabFlick
                            anchors.fill: parent
                            contentWidth: tabsContent.width
                            contentHeight: height
                            boundsBehavior: Flickable.StopAtBounds
                            flickableDirection: Flickable.HorizontalFlick
                            interactive: contentWidth > width
                            acceptedButtons: Qt.NoButton
                            clip: true

                            Item {
                                id: tabsContent
                                width: tabsModel.count > 0
                                       ? tabsModel.count * rootWindow.tabWidth + (tabsModel.count - 1) * rootWindow.tabSpacing
                                       : 0
                                height: parent.height

                                Repeater {
                                    id: tabsRepeater
                                    model: tabsModel

                                    delegate: Rectangle {
                                        id: tabDelegate

                                        property var rootRef: rootWindow
                                        required property int index
                                        required property string title
                                        required property string icon

                                        property bool movedEnough: false

                                        x: index * (rootRef.tabWidth + rootRef.tabSpacing)
                                        y: 1
                                        width: rootRef.tabWidth
                                        height: Theme.Metrics.controlHeightLg
                                        radius: 9
                                        z: rootRef.draggedTabIndex === index ? 100 : 1

                                        transform: Translate {
                                            x: rootRef.draggedTabIndex === index ? rootRef.draggedTabOffset : 0
                                        }

                                        color: index === rootRef.currentTab
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

                                        border.color: index === rootRef.currentTab ? Theme.AppTheme.border : "transparent"
                                        border.width: Theme.Metrics.borderWidth

                                        DropArea {
                                            anchors.fill: parent
                                            z: 2

                                            function maybeActivate() {
                                                if (tabDelegate.rootRef.draggedFileCount > 0
                                                        && tabDelegate.rootRef.currentTab !== tabDelegate.index) {
                                                    tabDelegate.rootRef.activateTabLocal(tabDelegate.index)
                                                    tabDelegate.rootRef.ensureTabVisible(tabDelegate.index)
                                                }
                                            }

                                            onEntered: function(drag) {
                                                if (tabDelegate.rootRef.draggedFileCount > 0) {
                                                    drag.accepted = true
                                                    maybeActivate()
                                                }
                                            }

                                            onPositionChanged: function(drag) {
                                                if (tabDelegate.rootRef.draggedFileCount > 0) {
                                                    drag.accepted = true
                                                    maybeActivate()
                                                }
                                            }

                                            onDropped: function(drop) {
                                                if (tabDelegate.rootRef.draggedFileCount > 0) {
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
                                            visible: tabDelegate.rootRef.editingTabIndex !== tabDelegate.index

                                            AppIcon {
                                                name: tabDelegate.icon || ""
                                                darkTheme: Theme.AppTheme.isDark
                                                iconSize: 15
                                            }

                                            Text {
                                                text: tabDelegate.title || ""
                                                color: Theme.AppTheme.text
                                                font.pixelSize: Theme.Typography.bodyLg
                                                font.bold: tabDelegate.index === tabDelegate.rootRef.currentTab
                                                elide: Text.ElideRight
                                                width: 140
                                            }
                                        }

                                        TextField {
                                            visible: tabDelegate.rootRef.editingTabIndex === tabDelegate.index
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.left: parent.left
                                            anchors.leftMargin: Theme.Metrics.spacingXl
                                            anchors.right: closeButton.left
                                            anchors.rightMargin: Theme.Metrics.spacingMd
                                            height: 24

                                            text: tabDelegate.rootRef.editingTabTitleDraft || ""
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
                                                    tabDelegate.rootRef.editingTabTitleDraft = text
                                            }

                                            onAccepted: tabDelegate.rootRef.commitRenameTab(tabDelegate.index, text || "")

                                            onActiveFocusChanged: {
                                                if (!activeFocus && visible)
                                                    tabDelegate.rootRef.commitRenameTab(tabDelegate.index, text || "")
                                            }

                                            Keys.onEscapePressed: tabDelegate.rootRef.cancelRenameTab()
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
                                            visible: tabDelegate.rootRef.editingTabIndex !== tabDelegate.index

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
                                                    tabDelegate.rootRef.closeTab(tabDelegate.index)
                                                    mouse.accepted = true
                                                }
                                            }
                                        }

                                        DragHandler {
                                            id: dragHandler
                                            target: null
                                            acceptedButtons: Qt.LeftButton
                                            enabled: tabDelegate.rootRef.editingTabIndex !== tabDelegate.index
                                            xAxis.enabled: true
                                            yAxis.enabled: false
                                            grabPermissions: PointerHandler.CanTakeOverFromAnything

                                            onActiveChanged: {
                                                tabDelegate.rootRef.tabDragActive = active

                                                if (active) {
                                                    tabDelegate.rootRef.tabPressActive = true
                                                    tabDelegate.rootRef.currentTab = tabDelegate.index
                                                    tabDelegate.rootRef.draggedTabIndex = tabDelegate.index
                                                    tabDelegate.rootRef.draggedTabStartIndex = tabDelegate.index
                                                    tabDelegate.rootRef.draggedTabStartContentX = tabFlick.contentX
                                                    tabDelegate.rootRef.draggedTabOffset = 0
                                                    tabDelegate.movedEnough = false
                                                    tabDelegate.rootRef.tabAutoScrollDirection = 0
                                                    tabDelegate.rootRef.tabAutoScrollTimerRef.start()
                                                } else {
                                                    var rw = tabDelegate.rootRef
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
                                                    tabDelegate.movedEnough = false
                                                }
                                            }

                                            onTranslationChanged: {
                                                if (tabDelegate.rootRef.draggedTabIndex < 0)
                                                    return

                                                if (Math.abs(translation.x) > 8)
                                                    tabDelegate.movedEnough = true

                                                var slotSize = tabDelegate.rootRef.tabWidth + tabDelegate.rootRef.tabSpacing
                                                var currentIndex = tabDelegate.rootRef.draggedTabIndex
                                                var startIndex = tabDelegate.rootRef.draggedTabStartIndex
                                                var scrollDelta = tabFlick.contentX - tabDelegate.rootRef.draggedTabStartContentX

                                                var draggedLeftX = startIndex * slotSize + translation.x + scrollDelta
                                                var draggedCenterX = draggedLeftX + tabDelegate.rootRef.tabWidth / 2

                                                var targetIndex = Math.floor(draggedCenterX / slotSize)
                                                targetIndex = Math.max(0, Math.min(tabsModel.count - 1, targetIndex))

                                                tabDelegate.rootRef.draggedTabOffset =
                                                        draggedLeftX - currentIndex * slotSize

                                                if (targetIndex !== currentIndex) {
                                                    tabDelegate.rootRef.moveTabLocally(currentIndex, targetIndex)
                                                    tabDelegate.rootRef.draggedTabIndex = targetIndex
                                                }

                                                var draggedCenterInViewport = draggedCenterX - tabFlick.contentX

                                                if (draggedCenterInViewport < 36)
                                                    tabDelegate.rootRef.tabAutoScrollDirection = -1
                                                else if (draggedCenterInViewport > tabViewport.width - 36)
                                                    tabDelegate.rootRef.tabAutoScrollDirection = 1
                                                else
                                                    tabDelegate.rootRef.tabAutoScrollDirection = 0
                                            }
                                        }

                                        MouseArea {
                                            id: tabMouse
                                            anchors.left: parent.left
                                            anchors.top: parent.top
                                            anchors.bottom: parent.bottom
                                            anchors.right: parent.right
                                            anchors.rightMargin: tabDelegate.rootRef.editingTabIndex === tabDelegate.index ? 6 : 30
                                            hoverEnabled: true
                                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                                            enabled: tabDelegate.rootRef.editingTabIndex !== tabDelegate.index
                                            preventStealing: false

                                            onPressed: function(mouse) {
                                                tabDelegate.rootRef.tabPressActive = true

                                                if (tabDelegate.rootRef.editingTabIndex >= 0
                                                        && tabDelegate.rootRef.editingTabIndex !== tabDelegate.index) {
                                                    tabDelegate.rootRef.commitRenameTab(
                                                        tabDelegate.rootRef.editingTabIndex,
                                                        tabDelegate.rootRef.editingTabTitleDraft
                                                    )
                                                }

                                                if (mouse.button === Qt.RightButton) {
                                                    tabDelegate.rootRef.showTabContextMenu(tabDelegate.index)
                                                    return
                                                }

                                                if (mouse.button === Qt.LeftButton)
                                                    tabDelegate.rootRef.currentTab = tabDelegate.index
                                            }

                                            onReleased: {
                                                if (!dragHandler.active)
                                                    tabDelegate.rootRef.tabPressActive = false
                                            }

                                            onCanceled: {
                                                tabDelegate.rootRef.tabPressActive = false
                                            }

                                            onClicked: function(mouse) {
                                                if (mouse.button === Qt.LeftButton && !tabDelegate.movedEnough) {
                                                    tabDelegate.rootRef.activateTabLocal(tabDelegate.index)
                                                    tabDelegate.rootRef.ensureTabVisible(tabDelegate.index)
                                                }

                                                if (!dragHandler.active)
                                                    tabDelegate.rootRef.tabPressActive = false
                                            }

                                            onDoubleClicked: {
                                                if (!tabDelegate.movedEnough)
                                                    tabDelegate.rootRef.beginRenameTab(tabDelegate.index)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 26
                        visible: tabsRow.overflowing && tabFlick.contentX > 0
                        z: 5

                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: Theme.AppTheme.isDark ? "#000000" : "#cfd5dd" }
                            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0) }
                        }
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 26
                        visible: tabsRow.overflowing
                                 && tabFlick.contentX < (tabFlick.contentWidth - tabFlick.width - 1)
                        z: 5

                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0) }
                            GradientStop { position: 1.0; color: Theme.AppTheme.isDark ? "#000000" : "#cfd5dd" }
                        }
                    }
                }

                Rectangle {
                    id: scrollRightButton
                    width: 26
                    height: 26
                    radius: Theme.Metrics.radiusMd
                    anchors.verticalCenter: parent.verticalCenter
                    visible: tabsRow.overflowing
                    color: rightScrollMouse.pressed
                           ? Theme.AppTheme.pressed
                           : rightScrollMouse.containsMouse
                             ? Theme.AppTheme.hover
                             : "transparent"
                    opacity: tabFlick.contentX < (tabFlick.contentWidth - tabFlick.width - 1) ? 1.0 : 0.45

                    AppIcon {
                        anchors.centerIn: parent
                        name: "chevron-right"
                        darkTheme: Theme.AppTheme.isDark
                        iconSize: Theme.Metrics.iconSm
                    }

                    MouseArea {
                        id: rightScrollMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: tabFlick.contentX < (tabFlick.contentWidth - tabFlick.width - 1)
                        onClicked: rootWindow.scrollTabsBy(240)
                    }
                }
            }

            MouseArea {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: tabsRow.right
                anchors.right: parent.right
                z: 1
                acceptedButtons: Qt.LeftButton

                onPressed: function(mouse) {
                    if (mouse.button === Qt.LeftButton)
                        rootWindow.startSystemMove()
                }

                onDoubleClicked: rootWindow.toggleMaximize()
            }
        }

        Item {
            id: dragStrip
            Layout.fillHeight: true
            Layout.preferredWidth: 140

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton

                onPressed: function(mouse) {
                    if (mouse.button === Qt.LeftButton)
                        rootWindow.startSystemMove()
                }

                onDoubleClicked: rootWindow.toggleMaximize()
            }
        }

        RowLayout {
            id: windowButtons
            spacing: 2

            WindowButton {
                iconName: "minimize"
                darkTheme: Theme.AppTheme.isDark
                onClicked: rootWindow.showMinimized()
            }

            WindowButton {
                iconName: rootWindow.visibility === Window.Maximized
                          ? "filter-none"
                          : "check-box-outline-blank"
                darkTheme: Theme.AppTheme.isDark
                onClicked: rootWindow.toggleMaximize()
            }

            WindowButton {
                iconName: "close"
                darkTheme: Theme.AppTheme.isDark
                hoverColor: "#d85b5b"
                pressedColor: "#c94c4c"
                onClicked: Qt.quit()
            }
        }
    }
}