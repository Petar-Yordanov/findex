import QtQuick
import QtQuick.Controls
import "../../components/theme" as Theme

Dialog {
    required property var rootWindow

    modal: true
    focus: true
    x: Math.round((rootWindow.width - width) / 2)
    y: Math.round((rootWindow.height - height) / 2)
    width: 340
    padding: 0
    closePolicy: Popup.CloseOnEscape

    background: Rectangle {
        radius: 14
        color: Theme.AppTheme.popupBg
        border.color: Theme.AppTheme.border
        border.width: Theme.Metrics.borderWidth
    }

    contentItem: Column {
        spacing: 0

        Rectangle {
            width: parent ? parent.width : 360
            height: 46
            radius: 14
            color: "transparent"

            Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 18
                text: rootWindow.confirmDialogTitle
                color: Theme.AppTheme.text
                font.pixelSize: Theme.Typography.titleSm
                font.bold: true
            }
        }

        Rectangle {
            width: parent ? parent.width : 360
            height: 1
            color: Theme.AppTheme.borderSoft
        }

        Item {
            width: parent ? parent.width : 360
            height: 68

            Text {
                anchors.fill: parent
                anchors.margins: 18
                text: rootWindow.confirmDialogMessage
                color: Theme.AppTheme.text
                font.pixelSize: Theme.Typography.bodyLg
                wrapMode: Text.Wrap
                verticalAlignment: Text.AlignVCenter
            }
        }

        Rectangle {
            width: parent ? parent.width : 360
            height: 1
            color: Theme.AppTheme.borderSoft
        }

        Row {
            width: parent ? parent.width : 340
            height: 48
            spacing: Theme.Metrics.spacingLg

            Item { width: 18; height: 1 }

            Rectangle {
                width: 92
                height: Theme.Metrics.controlHeightLg
                radius: 9
                anchors.verticalCenter: parent.verticalCenter
                color: yesMouse.pressed
                       ? "#c94c4c"
                       : yesMouse.containsMouse
                         ? "#d85b5b"
                         : "#cf5a5a"

                Text {
                    anchors.centerIn: parent
                    text: "Yes"
                    color: "#ffffff"
                    font.pixelSize: Theme.Typography.body
                    font.bold: true
                }

                MouseArea {
                    id: yesMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        if (rootWindow.confirmDialogAction === "deleteRow"
                                && rootWindow.confirmDialogRow >= 0) {
                            rootWindow.applySnapshot(
                                rootWindow.backend.deleteItems(
                                    rootWindow.singleItemForBackend(rootWindow.confirmDialogRow)
                                )
                            )
                            rootWindow.clearFileSelection()
                        } else if (rootWindow.confirmDialogAction === "deleteSelection") {
                            rootWindow.applySnapshot(
                                rootWindow.backend.deleteItems(rootWindow.selectedItemsForBackend())
                            )
                            rootWindow.clearFileSelection()
                        }

                        parent.Dialog.close()
                    }
                }
            }

            Rectangle {
                width: 92
                height: Theme.Metrics.controlHeightLg
                radius: 9
                anchors.verticalCenter: parent.verticalCenter
                color: noMouse.pressed
                       ? (Theme.AppTheme.isDark ? "#384355" : "#dce4ef")
                       : noMouse.containsMouse
                         ? Theme.AppTheme.hover
                         : "transparent"
                border.color: Theme.AppTheme.border
                border.width: Theme.Metrics.borderWidth

                Text {
                    anchors.centerIn: parent
                    text: "No"
                    color: Theme.AppTheme.text
                    font.pixelSize: Theme.Typography.body
                    font.bold: true
                }

                MouseArea {
                    id: noMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: parent.Dialog.close()
                }
            }

            Item { width: 18; height: 1 }
        }
    }
}