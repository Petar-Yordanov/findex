#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlError>
#include <QDebug>
#include <QQuickStyle>
#include "FileAssociationService.h"
#include "FileManagerBridge.h"
#include <QQmlContext>
#include <QIcon>
#include <QFile>

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

    qDebug() << QFile::exists(":/icons/findex-plain.png");
    qDebug() << QFile::exists(":/assets/icons/findex-plain.png");
    qDebug() << QFile::exists(":/qt/qml/Findex/assets/icons/findex-plain.png");
}

int main(int argc, char *argv[])
{
    QQuickStyle::setStyle("Fusion");
    QGuiApplication app(argc, argv);
    app.setWindowIcon(QIcon(":/assets/icons/findex-plain.ico"));

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

    engine.loadFromModule("Findex", "Main");

    if (engine.rootObjects().isEmpty()) {
        qCritical() << "No root objects loaded";
        return -1;
    }

    return app.exec();
}
