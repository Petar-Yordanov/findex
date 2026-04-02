#pragma once

#include <QObject>
#include <QString>

class CommandBarViewModel final : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QObject* backend READ backend WRITE setBackend NOTIFY backendChanged)
    Q_PROPERTY(QString themeMode READ themeMode WRITE setThemeMode NOTIFY themeModeChanged)
    Q_PROPERTY(QString viewMode READ viewMode WRITE setViewMode NOTIFY viewModeChanged)
    Q_PROPERTY(bool showHiddenFiles READ showHiddenFiles WRITE setShowHiddenFiles NOTIFY showHiddenFilesChanged)

public:
    explicit CommandBarViewModel(QObject* parent = nullptr);

    QObject* backend() const;
    void setBackend(QObject* backend);

    QString themeMode() const;
    void setThemeMode(const QString& value);

    QString viewMode() const;
    void setViewMode(const QString& value);

    bool showHiddenFiles() const;
    void setShowHiddenFiles(bool value);

    Q_INVOKABLE void createFolder();
    Q_INVOKABLE void createFile();

    Q_INVOKABLE void cutSelection();
    Q_INVOKABLE void copySelection();
    Q_INVOKABLE void paste();
    Q_INVOKABLE void renameSelection();
    Q_INVOKABLE void deleteSelection();
    Q_INVOKABLE void refresh();

    Q_INVOKABLE void compressSelection();
    Q_INVOKABLE void extractSelection();
    Q_INVOKABLE void selectAll();
    Q_INVOKABLE void showProperties();

    Q_INVOKABLE void applyTheme(const QString& mode);
    Q_INVOKABLE void applyViewMode(const QString& mode);
    Q_INVOKABLE void toggleHiddenFiles();

signals:
    void backendChanged();
    void themeModeChanged();
    void viewModeChanged();
    void showHiddenFilesChanged();
    void actionRequested(const QString& action);

private:
    void invokeNoArgs(const char* methodName);
    bool hasMethod(const char* signature) const;

private:
    QObject* m_backend = nullptr;
    QString m_themeMode = QStringLiteral("Light");
    QString m_viewMode = QStringLiteral("Details");
    bool m_showHiddenFiles = false;
};