#pragma once

#include <QObject>
#include <QStringList>

class FileOperationWorker final : public QObject
{
    Q_OBJECT

public:
    enum class Mode
    {
        Copy,
        Move,
        Delete
    };

    explicit FileOperationWorker(QObject* parent = nullptr);

    void configure(Mode mode,
                   const QStringList& sourcePaths,
                   const QString& destinationDirectory = QString());

public slots:
    void run();

signals:
    void progress(const QString& title,
                  const QString& details,
                  int progress,
                  bool done);

    void completed(const QString& successMessage);
    void failed(const QString& errorMessage);
    void finished();

private:
    struct ProgressState
    {
        qint64 totalBytes = 0;
        qint64 handledBytes = 0;
        QString title;
    };

    void runCopyOrMove();
    void runDelete();

    bool processCopyPath(const QString& sourcePath,
                         const QString& destinationPath,
                         bool removeSourceAfterCopy,
                         ProgressState& state);

    bool copyDirectoryRecursive(const QString& sourceDirPath,
                                const QString& destinationDirPath,
                                bool removeSourceAfterCopy,
                                ProgressState& state);

    bool copyFileWithProgress(const QString& sourceFilePath,
                              const QString& destinationFilePath,
                              ProgressState& state);

    bool deletePathRecursive(const QString& path, ProgressState& state);

    qint64 computeTotalBytes(const QStringList& paths) const;
    qint64 computePathBytes(const QString& path) const;

    QString uniquePathInDirectory(const QString& directoryPath,
                                  const QString& originalName) const;

    void emitProgress(ProgressState& state, bool done = false);
    static QString formatBytes(qint64 bytes);

private:
    Mode m_mode = Mode::Copy;
    QStringList m_sourcePaths;
    QString m_destinationDirectory;
};