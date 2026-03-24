import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../components/foundation"
import "../../components/theme" as Theme

Item {
    id: tabStrip

    required property var rootWindow
    required property var tabsModel

    property alias flickable: tabFlick

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

        readonly property bool overflowing: tabsContent.width > Math.max(0, tabsRow.width - addTabButton.width - tabsRow.spacing)

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
                            model: tabsModel

                            delegate: TabButton {
                                rootWindow: tabStrip.rootWindow
                                index: index
                                title: model.title
                                icon: model.icon
                                tabsModel: tabStrip.tabsModel
                                tabFlick: tabFlick
                                tabViewport: tabViewport
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