#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlError>
#include <QDebug>
#include <QQuickStyle>
#include "FileAssociationService.h"
#include "FileManagerBridge.h"
#include <QQmlContext>
// TODO:
// Tab rename is broken
// Drop files selected to a tab should make it active
// Fix handlers (some have no backend handling, some have it even though they shouldnt)
// We need to split up into reusable files (Start with views and context menus)
// Validate text fields? In particularly filepaths if they exist and name/folders
// to ensure that characters that are invalid cant be used for names/renames
// Make minimium height/width friendlier for window tiling systems
// Clicking away from filepath bar should turn it back into pills
// Hover over for context menus is a bit too soft/rounded
// Hover over color in dark mode for context menu is too aggressive (text disappears)
// Why does opening context menu outside item boundaries makes it change the order of the items?

void dumpApps(const QString& filePath)
{
    const auto pdfApps = FileAssociationService::appsForExtension(".png");

    qDebug() << "Apps for" << filePath;
    for (const auto& app : pdfApps) {
        qDebug().noquote()
            << QString("  [%1] name=%2 id=%3 exe=%4 cmd=%5 url=%6")
                   .arg(app.isDefault ? "default" : "other")
                   .arg(app.name)
                   .arg(app.id)
                   .arg(app.executable)
                   .arg(app.command)
                   .arg(app.appUrl.toString());
    }
}

int main(int argc, char *argv[])
{
    QQuickStyle::setStyle("Fusion");
    QGuiApplication app(argc, argv);

    qInstallMessageHandler([](QtMsgType, const QMessageLogContext&, const QString& msg) {
        fprintf(stderr, "%s\n", msg.toLocal8Bit().constData());
        fflush(stderr);
    });

    dumpApps("");

    QQmlApplicationEngine engine;

    auto* fileManagerBridge = new FileManagerBridge(&engine);
    engine.rootContext()->setContextProperty("fileManagerBridge", fileManagerBridge);

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::warnings,
        [](const QList<QQmlError>& warnings) {
            for (const auto& w : warnings) {
                qWarning().noquote() << w.toString();
            }
        });

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() {
            qCritical() << "QML object creation failed";
            QCoreApplication::exit(-1);
        },
        Qt::QueuedConnection);

    engine.loadFromModule("FileExplorer", "Main");

    if (engine.rootObjects().isEmpty()) {
        qCritical() << "No root objects loaded";
        return -1;
    }

    return app.exec();
}
