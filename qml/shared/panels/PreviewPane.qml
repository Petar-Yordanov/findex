import QtQuick
import QtQuick.Controls
import "../../components/foundation"
import "../../components/theme" as Theme

Rectangle {
    required property var rootWindow

    color: Theme.AppTheme.isDark ? "#141920" : "#fbfcfd"
    border.color: Theme.AppTheme.borderSoft
    border.width: Theme.Metrics.borderWidth

    Flickable {
        id: previewFlick
        anchors.fill: parent
        anchors.leftMargin: Theme.Metrics.spacingXl
        anchors.topMargin: Theme.Metrics.spacingXl
        anchors.bottomMargin: Theme.Metrics.spacingXl
        anchors.rightMargin: Theme.Metrics.spacingSm
        clip: true
        contentWidth: width
        contentHeight: previewColumn.implicitHeight

        ScrollBar.vertical: ExplorerScrollbarV { darkTheme: Theme.AppTheme.isDark }

        Column {
            id: previewColumn
            width: Math.max(0, previewFlick.width - 20)
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
                    spacing: Theme.Metrics.spacingMd
                    visible: !rootWindow.previewData.visible

                    AppIcon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        name: "preview"
                        darkTheme: Theme.AppTheme.isDark
                        iconSize: Theme.Metrics.icon3xl
                        iconOpacity: 0.55
                    }

                    Text {
                        text: "Select an item to preview"
                        color: Theme.AppTheme.muted
                        font.pixelSize: Theme.Typography.body
                    }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: Theme.Metrics.spacingMd
                    visible: rootWindow.previewData.visible

                    AppIcon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        name: rootWindow.previewData.icon || "insert-drive-file"
                        darkTheme: Theme.AppTheme.isDark
                        iconSize: Theme.Metrics.icon4xl
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: rootWindow.previewData.previewType === "multi"
                              ? "Multiple items"
                              : rootWindow.previewData.previewType === "image"
                                ? "Mock image preview"
                                : rootWindow.previewData.previewType === "text"
                                  ? "Mock text preview"
                                  : rootWindow.previewData.previewType === "document"
                                    ? "Mock document preview"
                                    : rootWindow.previewData.previewType === "audio"
                                      ? "Mock audio preview"
                                      : rootWindow.previewData.previewType === "video"
                                        ? "Mock video preview"
                                        : rootWindow.previewData.previewType === "archive"
                                          ? "Mock archive preview"
                                          : rootWindow.previewData.previewType === "folder"
                                            ? "Mock folder preview"
                                            : "Mock file preview"
                        color: Theme.AppTheme.text
                        font.pixelSize: Theme.Typography.bodyLg
                        font.bold: true
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Backend-driven placeholder"
                        color: Theme.AppTheme.muted
                        font.pixelSize: Theme.Typography.caption
                    }
                }
            }

            Text {
                visible: rootWindow.previewData.visible
                width: parent.width
                text: rootWindow.previewData.name || ""
                color: Theme.AppTheme.text
                font.pixelSize: Theme.Typography.subtitle
                font.bold: true
                wrapMode: Text.Wrap
            }

            Text {
                visible: rootWindow.previewData.visible
                width: parent.width
                text: rootWindow.previewData.type || ""
                color: Theme.AppTheme.muted
                font.pixelSize: Theme.Typography.body
                wrapMode: Text.Wrap
            }

            Text {
                visible: rootWindow.previewData.visible && rootWindow.previewData.summary !== ""
                width: parent.width
                text: rootWindow.previewData.summary || ""
                color: Theme.AppTheme.text
                font.pixelSize: Theme.Typography.body
                wrapMode: Text.Wrap
            }

            Rectangle {
                visible: rootWindow.previewData.visible
                width: parent.width
                height: 1
                color: Theme.AppTheme.borderSoft
            }

            Column {
                visible: rootWindow.previewData.visible
                width: parent.width
                spacing: Theme.Metrics.spacingSm

                Text {
                    text: "Details"
                    color: Theme.AppTheme.text
                    font.pixelSize: Theme.Typography.body
                    font.bold: true
                }

                Row {
                    spacing: Theme.Metrics.spacingSm

                    Text {
                        text: "Modified:"
                        color: Theme.AppTheme.muted
                        font.pixelSize: Theme.Typography.caption
                        font.bold: true
                    }

                    Text {
                        text: rootWindow.previewData.dateModified || "—"
                        color: Theme.AppTheme.text
                        font.pixelSize: Theme.Typography.caption
                    }
                }

                Row {
                    spacing: Theme.Metrics.spacingSm

                    Text {
                        text: "Size:"
                        color: Theme.AppTheme.muted
                        font.pixelSize: Theme.Typography.caption
                        font.bold: true
                    }

                    Text {
                        text: rootWindow.previewData.size || "—"
                        color: Theme.AppTheme.text
                        font.pixelSize: Theme.Typography.caption
                    }
                }
            }

            Column {
                visible: rootWindow.previewData.visible
                width: parent.width
                spacing: Theme.Metrics.spacingSm

                Text {
                    text: "Mock content"
                    color: Theme.AppTheme.text
                    font.pixelSize: Theme.Typography.body
                    font.bold: true
                }

                Repeater {
                    model: rootWindow.previewData.lines ? rootWindow.previewData.lines : []

                    delegate: Text {
                        required property var modelData
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