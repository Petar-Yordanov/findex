#include <QtSystemDetection>

#ifdef Q_OS_MACOS

#include "FileAssociationService.h"

#include <QFileInfo>
#include <QHash>
#include <QList>
#include <QString>

#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>

namespace
{
QString cfStringToQString(CFStringRef s)
{
    if (!s) {
        return {};
    }

    const char* cstr = CFStringGetCStringPtr(s, kCFStringEncodingUTF8);
    if (cstr) {
        return QString::fromUtf8(cstr);
    }

    CFIndex length = CFStringGetLength(s);
    CFIndex maxSize =
        CFStringGetMaximumSizeForEncoding(length, kCFStringEncodingUTF8) + 1;

    QByteArray buffer;
    buffer.resize(static_cast<int>(maxSize));

    if (CFStringGetCString(s, buffer.data(), maxSize, kCFStringEncodingUTF8)) {
        return QString::fromUtf8(buffer.constData());
    }
    return {};
}

QUrl cfUrlToQUrl(CFURLRef url)
{
    if (!url) {
        return {};
    }
    CFStringRef s = CFURLGetString(url);
    return QUrl(cfStringToQString(s));
}

void addUnique(QList<FileAssociationService::AssociatedApp>& apps,
               QHash<QString, int>& seen,
               const FileAssociationService::AssociatedApp& app)
{
    const QString key =
        !app.id.isEmpty() ? app.id.toLower()
        : !app.appUrl.isEmpty() ? app.appUrl.toString().toLower()
                                : app.name.toLower();

    if (key.isEmpty()) {
        return;
    }

    if (seen.contains(key)) {
        auto& existing = apps[seen[key]];
        existing.isDefault = existing.isDefault || app.isDefault;
        if (existing.name.isEmpty()) existing.name = app.name;
        if (existing.executable.isEmpty()) existing.executable = app.executable;
        if (existing.appUrl.isEmpty()) existing.appUrl = app.appUrl;
        return;
    }

    seen.insert(key, apps.size());
    apps.push_back(app);
}

CFStringRef createUtiForMimeOrExtension(const QString& mimeType, const QString& extensionHint)
{
    if (!mimeType.isEmpty()) {
        CFStringRef mime = CFStringCreateWithCString(
            kCFAllocatorDefault,
            mimeType.toUtf8().constData(),
            kCFStringEncodingUTF8);
        if (mime) {
            CFStringRef uti = UTTypeCreatePreferredIdentifierForTag(
                kUTTagClassMIMEType, mime, nullptr);
            CFRelease(mime);
            if (uti) {
                return uti;
            }
        }
    }

    QString ext = extensionHint;
    if (ext.startsWith('.')) {
        ext.remove(0, 1);
    }

    if (!ext.isEmpty()) {
        CFStringRef cfExt = CFStringCreateWithCString(
            kCFAllocatorDefault,
            ext.toUtf8().constData(),
            kCFStringEncodingUTF8);
        if (cfExt) {
            CFStringRef uti = UTTypeCreatePreferredIdentifierForTag(
                kUTTagClassFilenameExtension, cfExt, nullptr);
            CFRelease(cfExt);
            if (uti) {
                return uti;
            }
        }
    }

    return nullptr;
}

QString appPathFromBundleId(const QString& bundleId)
{
    QString out;

    CFStringRef cfBundle = CFStringCreateWithCString(
        kCFAllocatorDefault, bundleId.toUtf8().constData(), kCFStringEncodingUTF8);
    if (!cfBundle) {
        return out;
    }

    CFArrayRef urls = LSCopyApplicationURLsForBundleIdentifier(cfBundle, nullptr);
    CFRelease(cfBundle);

    if (!urls) {
        return out;
    }

    if (CFArrayGetCount(urls) > 0) {
        auto url = static_cast<CFURLRef>(CFArrayGetValueAtIndex(urls, 0));
        if (url) {
            CFStringRef path = CFURLCopyFileSystemPath(url, kCFURLPOSIXPathStyle);
            out = cfStringToQString(path);
            if (path) {
                CFRelease(path);
            }
        }
    }

    CFRelease(urls);
    return out;
}
}

QList<FileAssociationService::AssociatedApp>
FileAssociationService::appsForMimeTypeImpl(const QString& mimeType, const QString& extensionHint)
{
    QList<AssociatedApp> apps;
    QHash<QString, int> seen;

    CFStringRef uti = createUtiForMimeOrExtension(mimeType, extensionHint);
    if (!uti) {
        return apps;
    }

    QString defaultBundleId;
    if (CFStringRef def = LSCopyDefaultRoleHandlerForContentType(uti, kLSRolesAll)) {
        defaultBundleId = cfStringToQString(def);
        CFRelease(def);
    }

    if (CFArrayRef handlers = LSCopyAllRoleHandlersForContentType(uti, kLSRolesAll)) {
        const CFIndex count = CFArrayGetCount(handlers);
        for (CFIndex i = 0; i < count; ++i) {
            auto bundleIdRef = static_cast<CFStringRef>(CFArrayGetValueAtIndex(handlers, i));
            const QString bundleId = cfStringToQString(bundleIdRef);
            if (bundleId.isEmpty()) {
                continue;
            }

            AssociatedApp app;
            app.id = bundleId;
            app.name = bundleId; // best pure-C fallback
            app.executable = appPathFromBundleId(bundleId);
            if (!app.executable.isEmpty()) {
                app.name = QFileInfo(app.executable).completeBaseName();
                app.appUrl = QUrl::fromLocalFile(app.executable);
            }
            app.isDefault = (bundleId == defaultBundleId);

            addUnique(apps, seen, app);
        }
        CFRelease(handlers);
    }

    CFRelease(uti);
    return apps;
}

#endif
