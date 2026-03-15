#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include "FileAssociationService.h"

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
    dumpApps("");

    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("FileExplorer", "Main");

    return QCoreApplication::exec();
}
