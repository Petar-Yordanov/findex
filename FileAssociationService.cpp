#include "FileAssociationService.h"

#include <QDesktopServices>
#include <QFileInfo>
#include <QMimeDatabase>
#include <QMimeType>
#include <QProcess>
#include <QRegularExpression>
#include <QUrl>

namespace
{
QString fallbackDisplayNameFromExecutable(const QString& executable)
{
    if (executable.trimmed().isEmpty())
        return {};

    QFileInfo fi(executable);
    QString base = fi.completeBaseName().trimmed();
    if (!base.isEmpty())
        return base;

    base = fi.fileName().trimmed();
    return base;
}

bool looksLikeOpaqueAppId(const QString& value)
{
    const QString trimmed = value.trimmed();
    if (trimmed.isEmpty())
        return false;

    static const QRegularExpression windowsAppxLike(
        QStringLiteral("^[A-Za-z0-9]+(?:\\.[A-Za-z0-9]+)*_[A-Za-z0-9]+![A-Za-z0-9.]+$"));

    static const QRegularExpression longOpaqueToken(
        QStringLiteral("^[A-Za-z0-9._-]{24,}$"));

    return windowsAppxLike.match(trimmed).hasMatch()
           || longOpaqueToken.match(trimmed).hasMatch();
}

bool hasUsableDisplayName(const FileAssociationService::AssociatedApp& app)
{
    const QString name = app.name.trimmed();
    if (name.isEmpty())
        return false;

    if (looksLikeOpaqueAppId(name)) {
        const QString exeDisplay = fallbackDisplayNameFromExecutable(app.executable);
        if (exeDisplay.isEmpty())
            return false;
    }

    return true;
}

FileAssociationService::AssociatedApp normalizeApp(FileAssociationService::AssociatedApp app)
{
    QString name = app.name.trimmed();

    if (name.isEmpty())
        name = fallbackDisplayNameFromExecutable(app.executable);

    if (looksLikeOpaqueAppId(name)) {
        const QString exeDisplay = fallbackDisplayNameFromExecutable(app.executable);
        if (!exeDisplay.isEmpty())
            name = exeDisplay;
    }

    app.name = name.trimmed();
    return app;
}

QList<FileAssociationService::AssociatedApp>
sanitizeApps(QList<FileAssociationService::AssociatedApp> apps)
{
    QList<FileAssociationService::AssociatedApp> out;
    out.reserve(apps.size());

    for (auto app : apps) {
        app = normalizeApp(std::move(app));
        if (!hasUsableDisplayName(app))
            continue;

        out.push_back(std::move(app));
    }

    return out;
}
}

QString FileAssociationService::normalizeExtension(QString extension)
{
    extension = extension.trimmed();
    if (extension.isEmpty())
        return {};

    if (!extension.startsWith('.'))
        extension.prepend('.');

    return extension.toLower();
}

QList<FileAssociationService::AssociatedApp>
FileAssociationService::appsForFile(const QString& filePath)
{
    QFileInfo fi(filePath);
    QMimeDatabase db;
    const QMimeType mime = db.mimeTypeForFile(fi);

    QString ext;
    const QString suffix = fi.suffix().trimmed();
    if (!suffix.isEmpty())
        ext = "." + suffix.toLower();

    QList<AssociatedApp> apps = appsForMimeTypeImpl(mime.name(), ext);

    if (apps.isEmpty() && !ext.isEmpty())
        apps = appsForExtension(ext);

    return sanitizeApps(std::move(apps));
}

QList<FileAssociationService::AssociatedApp>
FileAssociationService::appsForExtension(const QString& extension)
{
    const QString ext = normalizeExtension(extension);
    if (ext.isEmpty())
        return {};

    QMimeDatabase db;
    const QMimeType mime = db.mimeTypeForFile("dummy" + ext, QMimeDatabase::MatchExtension);
    return sanitizeApps(appsForMimeTypeImpl(mime.name(), ext));
}

QList<FileAssociationService::AssociatedApp>
FileAssociationService::appsForMimeType(const QString& mimeType)
{
    return sanitizeApps(appsForMimeTypeImpl(mimeType, {}));
}

bool FileAssociationService::openWithDefaultApp(const QString& filePath)
{
    if (filePath.trimmed().isEmpty())
        return false;

    return QDesktopServices::openUrl(QUrl::fromLocalFile(filePath));
}

bool FileAssociationService::openWithApp(const QString& filePath, const AssociatedApp& app)
{
    if (filePath.trimmed().isEmpty())
        return false;

#ifdef Q_OS_MACOS
    if (!app.executable.trimmed().isEmpty()) {
        return QProcess::startDetached(
            QStringLiteral("open"),
            { QStringLiteral("-a"), app.executable, filePath });
    }

    if (!app.id.trimmed().isEmpty()) {
        return QProcess::startDetached(
            QStringLiteral("open"),
            { QStringLiteral("-b"), app.id, filePath });
    }
#else
    if (!app.executable.trimmed().isEmpty()) {
        return QProcess::startDetached(app.executable, { filePath });
    }

    if (!app.command.trimmed().isEmpty()) {
        QString cmd = app.command;
        cmd.replace(QStringLiteral("%1"), filePath);
        cmd.replace(QStringLiteral("%f"), filePath);
        cmd.replace(QStringLiteral("%F"), filePath);
        cmd.replace(QStringLiteral("%u"), QUrl::fromLocalFile(filePath).toString());
        cmd.replace(QStringLiteral("%U"), QUrl::fromLocalFile(filePath).toString());

        QStringList parts = QProcess::splitCommand(cmd);
        if (!parts.isEmpty()) {
            const QString program = parts.takeFirst();
            return QProcess::startDetached(program, parts);
        }
    }
#endif

    return openWithDefaultApp(filePath);
}

bool FileAssociationService::openWithAppId(const QString& filePath, const QString& appIdOrExecutable)
{
    if (filePath.trimmed().isEmpty() || appIdOrExecutable.trimmed().isEmpty())
        return false;

    const QList<AssociatedApp> apps = appsForFile(filePath);
    for (const AssociatedApp& app : apps) {
        if (app.id.compare(appIdOrExecutable, Qt::CaseInsensitive) == 0
            || app.executable.compare(appIdOrExecutable, Qt::CaseInsensitive) == 0
            || app.name.compare(appIdOrExecutable, Qt::CaseInsensitive) == 0) {
            return openWithApp(filePath, app);
        }
    }

    AssociatedApp fallback;
    fallback.executable = appIdOrExecutable;
    return openWithApp(filePath, fallback);
}