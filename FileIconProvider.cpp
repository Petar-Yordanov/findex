#include "FileIconProvider.h"

#include <QDir>
#include <QFileInfo>
#include <QIcon>
#include <QSettings>
#include <QUrl>

#ifdef Q_OS_WINDOWS
#include <QRegularExpression>
#endif

#ifdef Q_OS_WINDOWS
namespace
{
QString expandWindowsEnvironmentVariables(QString value)
{
    static const QRegularExpression envVarPattern(QStringLiteral("%([^%]+)%"));

    QRegularExpressionMatch match;
    int offset = 0;
    while ((match = envVarPattern.match(value, offset)).hasMatch()) {
        const QString variableName = match.captured(1);
        const QString replacement = qEnvironmentVariable(variableName.toUtf8().constData());
        value.replace(match.capturedStart(0), match.capturedLength(0), replacement);
        offset = match.capturedStart(0) + replacement.size();
    }

    return value;
}

QString iconPathForInternetShortcut(const QString& shortcutPath)
{
    QSettings shortcut(shortcutPath, QSettings::IniFormat);
    QString iconFile = shortcut.value(QStringLiteral("InternetShortcut/IconFile")).toString().trimmed();
    if (iconFile.isEmpty())
        return {};

    iconFile = expandWindowsEnvironmentVariables(iconFile);

    QFileInfo iconInfo(iconFile);
    if (iconInfo.isRelative())
        iconFile = QFileInfo(QDir(QFileInfo(shortcutPath).absolutePath()), iconFile).absoluteFilePath();

    if (!QFileInfo::exists(iconFile))
        return {};

    return iconFile;
}

QIcon iconFromExplicitPath(const QString& iconPath)
{
    const QIcon icon(iconPath);
    if (!icon.isNull())
        return icon;

    QFileIconProvider provider;
    return provider.icon(QFileInfo(iconPath));
}
}
#endif

FileIconProvider::FileIconProvider()
    : QQuickImageProvider(QQuickImageProvider::Pixmap)
    , m_cache(256)
{
}

QPixmap FileIconProvider::requestPixmap(const QString& id, QSize* size, const QSize& requestedSize)
{
    const QString path = QUrl::fromPercentEncoding(id.toUtf8());
    const QSize target = requestedSize.isValid() ? requestedSize : QSize(32, 32);
    const QString cacheKey = path + QStringLiteral("|%1x%2").arg(target.width()).arg(target.height());

    if (QPixmap* cached = m_cache.object(cacheKey)) {
        if (size)
            *size = cached->size();
        return *cached;
    }

    QFileIconProvider provider;
    QIcon icon;

#ifdef Q_OS_WINDOWS
    const QFileInfo info(path);
    if (info.suffix().compare(QStringLiteral("url"), Qt::CaseInsensitive) == 0) {
        const QString referencedIconPath = iconPathForInternetShortcut(path);
        if (!referencedIconPath.isEmpty())
            icon = iconFromExplicitPath(referencedIconPath);
    }
#endif

    if (icon.isNull())
        icon = provider.icon(QFileInfo(path));

    const QPixmap pixmap = icon.pixmap(target);

    if (!pixmap.isNull())
        m_cache.insert(cacheKey, new QPixmap(pixmap));

    if (size)
        *size = pixmap.size();

    return pixmap;
}
