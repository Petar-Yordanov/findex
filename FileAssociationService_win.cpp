#include <QtSystemDetection>

#ifdef Q_OS_WINDOWS

#include "FileAssociationService.h"

#include <QFileInfo>
#include <QHash>
#include <QList>
#include <QStringList>

#include <windows.h>
#include <shlwapi.h>
#include <winreg.h>

#pragma comment(lib, "Shlwapi.lib")
#pragma comment(lib, "Advapi32.lib")

namespace
{
QString fromWide(const wchar_t* s)
{
    return s ? QString::fromWCharArray(s) : QString();
}

QString queryAssocString(ASSOCSTR str, const QString& assoc, const wchar_t* verb = L"open")
{
    const std::wstring wAssoc = assoc.toStdWString();

    DWORD len = 0;
    HRESULT hr = AssocQueryStringW(ASSOCF_NOTRUNCATE, str, wAssoc.c_str(), verb, nullptr, &len);
    if (hr != S_FALSE && hr != E_POINTER && FAILED(hr)) {
        return {};
    }
    if (len == 0) {
        return {};
    }

    std::wstring buffer;
    buffer.resize(len);
    hr = AssocQueryStringW(ASSOCF_NOTRUNCATE, str, wAssoc.c_str(), verb, buffer.data(), &len);
    if (FAILED(hr)) {
        return {};
    }

    if (!buffer.empty() && buffer.back() == L'\0') {
        buffer.pop_back();
    }
    return QString::fromStdWString(buffer);
}

bool openRegKey(HKEY root, const QString& subKey, HKEY* outKey)
{
    const std::wstring wSubKey = subKey.toStdWString();
    return RegOpenKeyExW(root, wSubKey.c_str(), 0, KEY_READ, outKey) == ERROR_SUCCESS;
}

QString readDefaultValue(HKEY root, const QString& subKey)
{
    HKEY hKey = nullptr;
    if (!openRegKey(root, subKey, &hKey)) {
        return {};
    }

    DWORD type = 0;
    DWORD size = 0;
    LONG rc = RegQueryValueExW(hKey, nullptr, nullptr, &type, nullptr, &size);
    if (rc != ERROR_SUCCESS || (type != REG_SZ && type != REG_EXPAND_SZ) || size == 0) {
        RegCloseKey(hKey);
        return {};
    }

    std::wstring value;
    value.resize(size / sizeof(wchar_t));
    rc = RegQueryValueExW(hKey, nullptr, nullptr, &type,
                          reinterpret_cast<LPBYTE>(value.data()), &size);
    RegCloseKey(hKey);

    if (rc != ERROR_SUCCESS) {
        return {};
    }

    if (!value.empty() && value.back() == L'\0') {
        value.pop_back();
    }
    return QString::fromStdWString(value);
}

QStringList enumValueNames(HKEY root, const QString& subKey)
{
    QStringList out;
    HKEY hKey = nullptr;
    if (!openRegKey(root, subKey, &hKey)) {
        return out;
    }

    DWORD valueCount = 0;
    DWORD maxValueNameLen = 0;
    if (RegQueryInfoKeyW(hKey, nullptr, nullptr, nullptr, nullptr, nullptr, nullptr,
                         &valueCount, &maxValueNameLen, nullptr, nullptr, nullptr) != ERROR_SUCCESS) {
        RegCloseKey(hKey);
        return out;
    }

    std::wstring name;
    name.resize(maxValueNameLen + 1);

    for (DWORD i = 0; i < valueCount; ++i) {
        DWORD nameLen = static_cast<DWORD>(name.size());
        LONG rc = RegEnumValueW(hKey, i, name.data(), &nameLen, nullptr, nullptr, nullptr, nullptr);
        if (rc == ERROR_SUCCESS) {
            out.push_back(QString::fromStdWString(std::wstring(name.data(), nameLen)));
        }
    }

    RegCloseKey(hKey);
    return out;
}

QString commandForProgId(const QString& progId)
{
    return readDefaultValue(HKEY_CLASSES_ROOT, progId + "\\shell\\open\\command");
}

QString friendlyNameForProgId(const QString& progId)
{
    QString s = readDefaultValue(HKEY_CLASSES_ROOT, progId);
    if (!s.isEmpty()) {
        return s;
    }
    return progId;
}

void addUnique(QList<FileAssociationService::AssociatedApp>& apps,
               QHash<QString, int>& seen,
               const FileAssociationService::AssociatedApp& app)
{
    const QString key =
        !app.id.isEmpty() ? app.id.toLower()
        : !app.executable.isEmpty() ? app.executable.toLower()
                                    : app.name.toLower();

    if (key.isEmpty()) {
        return;
    }

    if (seen.contains(key)) {
        auto& existing = apps[seen[key]];
        existing.isDefault = existing.isDefault || app.isDefault;
        if (existing.name.isEmpty()) existing.name = app.name;
        if (existing.command.isEmpty()) existing.command = app.command;
        if (existing.executable.isEmpty()) existing.executable = app.executable;
        return;
    }

    seen.insert(key, apps.size());
    apps.push_back(app);
}

QString extractExecutableFromCommand(QString cmd)
{
    cmd = cmd.trimmed();
    if (cmd.isEmpty()) {
        return {};
    }

    if (cmd.startsWith('"')) {
        const int end = cmd.indexOf('"', 1);
        if (end > 1) {
            return cmd.mid(1, end - 1);
        }
    }

    const int space = cmd.indexOf(' ');
    if (space > 0) {
        return cmd.left(space);
    }
    return cmd;
}
}

QList<FileAssociationService::AssociatedApp>
FileAssociationService::appsForMimeTypeImpl(const QString& mimeType, const QString& extensionHint)
{
    Q_UNUSED(mimeType);

    QList<AssociatedApp> apps;
    QHash<QString, int> seen;

    const QString ext = normalizeExtension(extensionHint);
    if (ext.isEmpty()) {
        return apps;
    }

    const QString defaultExe = queryAssocString(ASSOCSTR_EXECUTABLE, ext);
    const QString defaultProgId = queryAssocString(ASSOCSTR_PROGID, ext);
    const QString defaultFriendly = queryAssocString(ASSOCSTR_FRIENDLYAPPNAME, ext);

    if (!defaultExe.isEmpty() || !defaultProgId.isEmpty() || !defaultFriendly.isEmpty()) {
        AssociatedApp app;
        app.id = defaultProgId;
        app.name = !defaultFriendly.isEmpty()
                       ? defaultFriendly
                       : (!defaultProgId.isEmpty() ? friendlyNameForProgId(defaultProgId)
                                                   : QFileInfo(defaultExe).completeBaseName());
        app.executable = defaultExe;
        app.command = !defaultProgId.isEmpty() ? commandForProgId(defaultProgId) : QString();
        app.isDefault = true;
        addUnique(apps, seen, app);
    }

    const QStringList openWithProgIdsHkcr =
        enumValueNames(HKEY_CLASSES_ROOT, ext + "\\OpenWithProgids");

    const QStringList openWithProgIdsUser =
        enumValueNames(HKEY_CURRENT_USER,
                       "Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\FileExts\\"
                           + ext + "\\OpenWithProgids");

    QStringList allProgIds = openWithProgIdsHkcr;
    for (const QString& p : openWithProgIdsUser) {
        if (!allProgIds.contains(p, Qt::CaseInsensitive)) {
            allProgIds.push_back(p);
        }
    }

    for (const QString& progId : allProgIds) {
        if (progId.trimmed().isEmpty()) {
            continue;
        }

        AssociatedApp app;
        app.id = progId;
        app.name = friendlyNameForProgId(progId);
        app.command = commandForProgId(progId);
        app.executable = extractExecutableFromCommand(app.command);
        app.isDefault = (!defaultProgId.isEmpty() &&
                         progId.compare(defaultProgId, Qt::CaseInsensitive) == 0);

        addUnique(apps, seen, app);
    }

    return apps;
}

#endif