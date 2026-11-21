# SSIS-Debug installieren

Für neue Installationen gilt der [markerfreie SSIS-Funktionssatz](../../Documentation/SimpleInstallation.md)
oder der [gemeinsame Installer](../../../../Deployment/ONE-CALL-INSTALL.md).
Die aktuellen Binarybuilder liefern DLLs und Buildmanifeste; die SQL-Datei
entsteht über den gemeinsamen Buildkern. Es gibt keine separaten
Deploy.WithAssembly-/Trust-/Uninstall-Dateien für neue Installationen.

Mit den gemäß Buildanleitung gebundenen parser/ssis-Eingaben:

```powershell
& Modules/toolbelt.tsql.ssis-debug/Examples/Installation/Install-Local.ps1 `
  -Server localhost -Database ContosoSsisDebug -Inputs .runtime/build-inputs `
  -ValidateOnly
```

ValidateOnly baut und prüft lokale Dateien, ohne SQL-Verbindung. Ohne diesen
Schalter installiert der gemeinsame Client den SSIS-Abhängigkeitssatz lokal.
Für zentralen Betrieb Build-Install mit DeploymentMode central und anschließend
Install-Toolbelt verwenden. Die vorhandenen Rechte und der gewählte Trustweg
gelten unverändert; TrustServerCertificate wird nur ausdrücklich gesetzt.

PrepareServer.sql ist ein erhaltener historischer administrativer Einzelschritt,
kein notwendiger Bestandteil der aktuellen normalen SQL-Datei. Für optionale
Vorbereitung mit dem aktuellen Client gilt [PROVISIONING](../../../../Deployment/PROVISIONING.md).
Die früheren Beispiele und ihre nativen Nachweise bleiben ausschließlich an
[ihren Originalstand](https://github.com/gecompat/SQL_Server_Toolbelt/tree/2fbe8e3e86f370b22ad2ce9f9716d971072a052b/Modules/toolbelt.tsql.ssis-debug/Examples/Installation)
gebunden. Sie qualifizieren diesen neuen Client nicht rückwirkend.
