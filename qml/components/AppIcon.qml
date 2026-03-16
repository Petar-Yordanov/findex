import QtQuick

Item {
    id: root

    property string name: ""
    property bool darkTheme: false
    property int iconSize: 16
    property real iconOpacity: 1.0

    width: iconSize
    height: iconSize

    readonly property string iconSource: {
        if (!name || name.trim() === "")
            return ""
        return "qrc:/qt/qml/FileExplorer/assets/icons/"
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