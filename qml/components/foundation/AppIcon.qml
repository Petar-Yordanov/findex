import QtQuick
import "../theme" as Theme

Item {
    id: root

    property string name: ""
    property string sourceOverride: ""
    property bool darkTheme: Theme.AppTheme.isDark
    property int iconSize: Theme.Metrics.iconMd
    property real iconOpacity: 1.0

    width: iconSize
    height: iconSize

    readonly property string bundledIconSource: {
        if (!name || name.trim() === "")
            return ""
        return "qrc:/qt/qml/Findex/assets/icons/"
                + (darkTheme ? "light/" : "dark/")
                + name + ".png"
    }

    readonly property string resolvedSource: {
        if (sourceOverride && sourceOverride.trim() !== "")
            return sourceOverride
        return bundledIconSource
    }

    Image {
        anchors.fill: parent
        source: root.resolvedSource
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
        asynchronous: true
        opacity: root.iconOpacity
        visible: root.resolvedSource !== ""
    }
}
