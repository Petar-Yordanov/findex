import QtQuick
import "../theme" as Theme

Item {
    id: root

    property string name: ""
    property bool darkTheme: Theme.AppTheme.isDark
    property int iconSize: Theme.Metrics.iconMd
    property real iconOpacity: 1.0

    width: iconSize
    height: iconSize

    readonly property string iconSource: {
        if (!name || name.trim() === "")
            return ""
        return "qrc:/qt/qml/Findex/assets/icons/"
                + (darkTheme ? "light/" : "dark/")
                + name + ".png"
    }

    Image {
        anchors.fill: parent
        source: root.iconSource
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
        opacity: root.iconOpacity
        visible: root.iconSource !== ""
    }
}
