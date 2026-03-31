import QtQuick
import "../../../components/foundation"
import "../../../components/theme" as Theme
import "." as Tabs

Item {
    id: tabStrip

    required property var rootWindow
    required property var viewModel
    required property var tabContextMenu

    property int tabWidth: 210
    property int tabSpacing: Theme.Metrics.spacingSm
    property int addButtonSize: Theme.Metrics.controlHeightMd
    property int sideControlWidth: 28
    property int sideInset: 4
    property int sideGap: 6
    property int fadeWidth: 18
    property bool draggingTab: false

    readonly property int tabCount: repeater.count
    readonly property real tabsExtent: tabCount > 0
                                      ? tabCount * tabWidth + (tabCount - 1) * tabSpacing
                                      : 0

    readonly property real leftSlotWidth: sideInset + sideControlWidth + sideGap
    readonly property real rightSlotWidth: sideInset + addButtonSize + sideGap + sideControlWidth

    function clamp(value, minValue, maxValue) {
        return Math.max(minValue, Math.min(maxValue, value))
    }

    function indexAtContentX(centerX) {
        if (tabCount <= 1)
            return 0

        var slot = tabWidth + tabSpacing
        var idx = Math.floor(centerX / slot)
        return clamp(idx, 0, tabCount - 1)
    }

    function scrollBy(delta) {
        tabFlick.contentX = clamp(
            tabFlick.contentX + delta,
            0,
            Math.max(0, tabFlick.contentWidth - tabFlick.width)
        )
    }

    function scrollLeft() {
        scrollBy(-(tabWidth + tabSpacing) * 1.25)
    }

    function scrollRight() {
        scrollBy((tabWidth + tabSpacing) * 1.25)
    }

    Item {
        id: leftSlot
        x: 0
        y: 0
        width: tabStrip.leftSlotWidth
        height: parent.height

        Rectangle {
            anchors.fill: parent
            color: Theme.AppTheme.titleBg
        }

        Rectangle {
            visible: leftScrollButton.visible
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: tabStrip.fadeWidth
            color: "transparent"

            gradient: Gradient {
                GradientStop { position: 0.0; color: Theme.AppTheme.titleBg }
                GradientStop { position: 1.0; color: Qt.rgba(Theme.AppTheme.titleBg.r, Theme.AppTheme.titleBg.g, Theme.AppTheme.titleBg.b, 0.0) }
            }
        }

        Rectangle {
            visible: leftScrollButton.visible
            x: Math.max(0, parent.width - 10)
            y: 6
            width: 10
            height: parent.height - 12
            color: "transparent"

            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, Theme.AppTheme.isDark ? 0.16 : 0.08) }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.0) }
            }
        }

        Rectangle {
            id: leftScrollButton
            visible: tabFlick.contentX > 1
            x: tabStrip.sideInset
            y: Math.round((parent.height - height) / 2)
            width: tabStrip.sideControlWidth
            height: Theme.Metrics.controlHeightMd
            radius: Theme.Metrics.radiusMd

            color: leftMouse.pressed
                   ? Theme.AppTheme.pressed
                   : leftMouse.containsMouse
                     ? Theme.AppTheme.hover
                     : Theme.AppTheme.popupBg

            border.color: Theme.AppTheme.border
            border.width: Theme.Metrics.borderWidth

            AppIcon {
                anchors.centerIn: parent
                name: "chevron-left"
                darkTheme: Theme.AppTheme.isDark
                iconSize: Theme.Metrics.iconSm
                iconOpacity: 0.95
            }

            MouseArea {
                id: leftMouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton
                onClicked: tabStrip.scrollLeft()
            }
        }
    }

    Item {
        id: rightSlot
        x: tabStrip.width - tabStrip.rightSlotWidth
        y: 0
        width: tabStrip.rightSlotWidth
        height: parent.height

        Rectangle {
            anchors.fill: parent
            color: Theme.AppTheme.titleBg
        }

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: tabStrip.fadeWidth
            color: "transparent"

            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(Theme.AppTheme.titleBg.r, Theme.AppTheme.titleBg.g, Theme.AppTheme.titleBg.b, 0.0) }
                GradientStop { position: 1.0; color: Theme.AppTheme.titleBg }
            }
        }

        Rectangle {
            x: 0
            y: 6
            width: 10
            height: parent.height - 12
            color: "transparent"

            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.0) }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, Theme.AppTheme.isDark ? 0.16 : 0.08) }
            }
        }

        Rectangle {
            id: addTabButton
            anchors.right: parent.right
            anchors.rightMargin: tabStrip.sideInset
            anchors.verticalCenter: parent.verticalCenter
            width: tabStrip.addButtonSize
            height: tabStrip.addButtonSize
            radius: Theme.Metrics.radiusMd

            color: addMouse.pressed
                   ? Theme.AppTheme.pressed
                   : addMouse.containsMouse
                     ? Theme.AppTheme.hover
                     : Theme.AppTheme.popupBg

            border.color: Theme.AppTheme.border
            border.width: Theme.Metrics.borderWidth

            AppIcon {
                anchors.centerIn: parent
                name: "add"
                darkTheme: Theme.AppTheme.isDark
                iconSize: Theme.Metrics.iconMd
                iconOpacity: 0.95
            }

            MouseArea {
                id: addMouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton

                onPressed: {
                    if (tabStrip.viewModel && tabStrip.viewModel.editingIndex >= 0)
                        tabStrip.viewModel.cancelRenameTab()
                }

                onClicked: {
                    if (tabStrip.viewModel)
                        tabStrip.viewModel.addTab()
                }
            }
        }

        Rectangle {
            id: rightScrollButton
            visible: tabFlick.contentX < Math.max(0, tabFlick.contentWidth - tabFlick.width - 1)
            anchors.right: addTabButton.left
            anchors.rightMargin: tabStrip.sideGap
            anchors.verticalCenter: parent.verticalCenter
            width: tabStrip.sideControlWidth
            height: Theme.Metrics.controlHeightMd
            radius: Theme.Metrics.radiusMd

            color: rightMouse.pressed
                   ? Theme.AppTheme.pressed
                   : rightMouse.containsMouse
                     ? Theme.AppTheme.hover
                     : Theme.AppTheme.popupBg

            border.color: Theme.AppTheme.border
            border.width: Theme.Metrics.borderWidth

            AppIcon {
                anchors.centerIn: parent
                name: "chevron-right"
                darkTheme: Theme.AppTheme.isDark
                iconSize: Theme.Metrics.iconSm
                iconOpacity: 0.95
            }

            MouseArea {
                id: rightMouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton
                onClicked: tabStrip.scrollRight()
            }
        }
    }

    Item {
        id: viewport
        x: tabStrip.leftSlotWidth
        y: 0
        width: Math.max(0, tabStrip.width - tabStrip.leftSlotWidth - tabStrip.rightSlotWidth)
        height: parent.height
        clip: true

        Flickable {
            id: tabFlick
            anchors.fill: parent
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.HorizontalFlick
            contentWidth: Math.max(width, tabsContent.width)
            contentHeight: height
            interactive: tabsContent.width > width && !tabStrip.draggingTab

            Item {
                id: tabsContent
                width: tabStrip.tabsExtent
                height: tabFlick.height

                Repeater {
                    id: repeater
                    model: tabStrip.viewModel ? tabStrip.viewModel.tabsModel : null

                    delegate: Tabs.TabButton {
                        rootWindow: tabStrip.rootWindow
                        viewModel: tabStrip.viewModel
                        tabContextMenu: tabStrip.tabContextMenu
                        strip: tabStrip
                        tabsContentItem: tabsContent

                        tabWidth: tabStrip.tabWidth
                        tabSpacing: tabStrip.tabSpacing
                    }
                }
            }
        }
    }
}