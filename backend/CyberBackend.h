#pragma once

#include <QFileSystemWatcher>
#include <QObject>
#include <QProcess>
#include <QString>
#include <QTimer>
#include <QtNetwork/QNetworkInterface>
#include <QtQml/qqml.h>

class CyberBackend final : public QObject {
    Q_OBJECT
    QML_NAMED_ELEMENT(CyberBackend)
    QML_SINGLETON

    Q_PROPERTY(QString targetIp READ targetIp NOTIFY targetIpChanged FINAL)
    Q_PROPERTY(bool hasTarget READ hasTarget NOTIFY targetIpChanged FINAL)
    Q_PROPERTY(QString vpnIp READ vpnIp NOTIFY vpnStateChanged FINAL)
    Q_PROPERTY(QString vpnInterface READ vpnInterface NOTIFY vpnStateChanged FINAL)
    Q_PROPERTY(bool vpnConnected READ vpnConnected NOTIFY vpnStateChanged FINAL)

public:
    explicit CyberBackend(QObject *parent = nullptr);
    ~CyberBackend() override = default;

    QString targetIp() const;
    bool hasTarget() const;

    QString vpnIp() const;
    QString vpnInterface() const;
    bool vpnConnected() const;

    Q_INVOKABLE void setTarget(const QString &ip);
    Q_INVOKABLE void clearTarget();
    Q_INVOKABLE void copyTarget();
    Q_INVOKABLE void copyVpn();
    Q_INVOKABLE void launchTerminalCommand(const QString &command, const QString &title = QString());
    Q_INVOKABLE void launchGuiTool(const QString &command);
    Q_INVOKABLE void runQuickNmap(const QString &scanType);

signals:
    void targetIpChanged();
    void vpnStateChanged();
    void feedbackMessage(const QString &title, const QString &body);

private slots:
    void reloadTargetIp();
    void updateVpnStatus();

private:
    void setupTargetWatcher();
    void setupVpnMonitor();
    void copyToClipboard(const QString &text);
    QString resolveTargetFilePath() const;

    QString m_targetIp;
    bool m_hasTarget = false;

    QString m_vpnIp;
    QString m_vpnInterface;
    bool m_vpnConnected = false;

    QFileSystemWatcher m_targetWatcher;
    QTimer m_vpnPollTimer;
    QString m_targetFilePath;
};
