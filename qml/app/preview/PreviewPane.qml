import QtQuick
import QtQuick.Controls
import "../../components/foundation"
import "../../components/theme" as Theme

Rectangle {
    id: root

    required property var viewModel

    readonly property bool hasVm: viewModel !== null && viewModel !== undefined
    readonly property bool previewVisible: hasVm && !!viewModel.visible
    readonly property string previewName: hasVm && viewModel.name ? viewModel.name : ""
    readonly property string previewFileType: hasVm && viewModel.type ? viewModel.type : ""
    readonly property string previewIcon: hasVm && viewModel.icon ? viewModel.icon : "insert-drive-file"
    readonly property string previewKind: hasVm && viewModel.previewType ? viewModel.previewType : "none"
    readonly property string previewSize: hasVm && viewModel.size ? viewModel.size : ""
    readonly property string previewDateModified: hasVm && viewModel.dateModified ? viewModel.dateModified : ""
    readonly property string previewSummary: hasVm && viewModel.summary ? viewModel.summary : ""
    readonly property var previewLines: hasVm && viewModel.lines ? viewModel.lines : []

    color: Theme.AppTheme.isDark ? "#141920" : "#fbfcfd"
    border.color: Theme.AppTheme.borderSoft
    border.width: Theme.Metrics.borderWidth
    clip: true

    Flickable {
        id: previewFlick
        anchors.fill: parent
        anchors.leftMargin: Theme.Metrics.spacingXl
        anchors.topMargin: Theme.Metrics.spacingXl
        anchors.bottomMargin: Theme.Metrics.spacingXl
        anchors.rightMargin: Theme.Metrics.spacingSm + (previewScrollBar.visible ? previewScrollBar.width : 0)
        clip: true
        contentWidth: previewColumn.width
        contentHeight: previewColumn.implicitHeight

        ScrollBar.vertical: ExplorerScrollbarV {
            id: previewScrollBar
        }

        Column {
            id: previewColumn
            width: Math.max(0, previewFlick.width)
            spacing: Theme.Metrics.spacingXl

            Text {
                text: "Preview"
                color: Theme.AppTheme.text
                font.pixelSize: Theme.Typography.bodyLg
                font.bold: true
            }

            Rectangle {
                width: parent.width
                height: 180
                radius: Theme.Metrics.radiusXl
                color: Theme.AppTheme.isDark ? "#1b2230" : "#f4f7fb"
                border.color: Theme.AppTheme.borderSoft
                border.width: Theme.Metrics.borderWidth

                Column {
                    anchors.centerIn: parent
                    width: Math.max(0, parent.width - Theme.Metrics.spacingXl * 2)
                    spacing: Theme.Metrics.spacingMd
                    visible: !root.previewVisible

                    AppIcon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        name: "preview"
                        darkTheme: Theme.AppTheme.isDark
                        iconSize: Theme.Metrics.icon3xl
                        iconOpacity: 0.55
                    }

                    Text {
                        width: parent.width
                        text: "Select an item to preview"
                        color: Theme.AppTheme.muted
                        font.pixelSize: Theme.Typography.body
                        wrapMode: Text.Wrap
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                Column {
                    anchors.centerIn: parent
                    width: Math.max(0, parent.width - Theme.Metrics.spacingXl * 2)
                    spacing: Theme.Metrics.spacingMd
                    visible: root.previewVisible

                    AppIcon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        name: root.previewIcon
                        darkTheme: Theme.AppTheme.isDark
                        iconSize: Theme.Metrics.icon4xl
                    }

                    Text {
                        width: parent.width
                        text: root.previewKind === "multi" ? "Multiple items"
                              : root.previewKind === "image" ? "Mock image preview"
                              : root.previewKind === "text" ? "Mock text preview"
                              : root.previewKind === "document" ? "Mock document preview"
                              : root.previewKind === "audio" ? "Mock audio preview"
                              : root.previewKind === "video" ? "Mock video preview"
                              : root.previewKind === "archive" ? "Mock archive preview"
                              : root.previewKind === "folder" ? "Mock folder preview"
                              : "Mock file preview"
                        color: Theme.AppTheme.text
                        font.pixelSize: Theme.Typography.bodyLg
                        font.bold: true
                        wrapMode: Text.Wrap
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Text {
                        width: parent.width
                        text: "Backend/viewmodel-driven placeholder"
                        color: Theme.AppTheme.muted
                        font.pixelSize: Theme.Typography.caption
                        wrapMode: Text.Wrap
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            Text {
                visible: root.previewVisible
                width: parent.width
                text: root.previewName
                color: Theme.AppTheme.text
                font.pixelSize: Theme.Typography.subtitle
                font.bold: true
                wrapMode: Text.Wrap
            }

            Text {
                visible: root.previewVisible
                width: parent.width
                text: root.previewFileType
                color: Theme.AppTheme.muted
                font.pixelSize: Theme.Typography.body
                wrapMode: Text.Wrap
            }

            Text {
                visible: root.previewVisible && root.previewSummary !== ""
                width: parent.width
                text: root.previewSummary
                color: Theme.AppTheme.text
                font.pixelSize: Theme.Typography.body
                wrapMode: Text.Wrap
            }

            Rectangle {
                visible: root.previewVisible
                width: parent.width
                height: 1
                color: Theme.AppTheme.borderSoft
            }

            Column {
                visible: root.previewVisible
                width: parent.width
                spacing: Theme.Metrics.spacingSm

                Text {
                    text: "Details"
                    color: Theme.AppTheme.text
                    font.pixelSize: Theme.Typography.body
                    font.bold: true
                }

                Row {
                    width: parent.width
                    spacing: Theme.Metrics.spacingSm

                    Text {
                        text: "Modified:"
                        color: Theme.AppTheme.muted
                        font.pixelSize: Theme.Typography.caption
                        font.bold: true
                    }

                    Text {
                        width: Math.max(0, parent.width - x)
                        text: root.previewDateModified !== "" ? root.previewDateModified : "—"
                        color: Theme.AppTheme.text
                        font.pixelSize: Theme.Typography.caption
                        wrapMode: Text.Wrap
                    }
                }

                Row {
                    width: parent.width
                    spacing: Theme.Metrics.spacingSm

                    Text {
                        text: "Size:"
                        color: Theme.AppTheme.muted
                        font.pixelSize: Theme.Typography.caption
                        font.bold: true
                    }

                    Text {
                        width: Math.max(0, parent.width - x)
                        text: root.previewSize !== "" ? root.previewSize : "—"
                        color: Theme.AppTheme.text
                        font.pixelSize: Theme.Typography.caption
                        wrapMode: Text.Wrap
                    }
                }
            }

            Column {
                visible: root.previewVisible
                width: parent.width
                spacing: Theme.Metrics.spacingSm

                Text {
                    text: "Mock content"
                    color: Theme.AppTheme.text
                    font.pixelSize: Theme.Typography.body
                    font.bold: true
                }

                Repeater {
                    model: root.previewLines

                    delegate: Text {
                        required property string modelData
                        width: previewColumn.width
                        text: "• " + modelData
                        color: Theme.AppTheme.muted
                        font.pixelSize: Theme.Typography.caption
                        wrapMode: Text.Wrap
                    }
                }
            }
        }
    }
}