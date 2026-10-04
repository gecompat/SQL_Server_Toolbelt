# ZIP-Dateifassaden

toolbelt.archive.zip-files 1.0.0 verbindet genau zwei öffentliche T-SQL-USPs
mit bestehenden ZIP-Memory-/Windows-Filesystem-/ResultTableverträgen.
Source implementiert; Windows-/SQL-/NTFS-Runtime noch nicht ausgeführt,
unveröffentlicht. Keine Assembly.

- [CreateZipFileFromEntries](Documentation/USP_CreateZipFileFromEntries.md)
- [ExtractZipEntryToFile](Documentation/USP_ExtractZipEntryToFile.md)
- [Öffentlicher Vertrag](../../Documentation/Architecture/ZIP_FILES_CONTRACT.md)
- [Tests](Tests/README.md)

## Installation

Windows SQL Server 2019/2022/2025, local. Zuerst ZIP Memory >=1.4.0,
Windows Filesystem/ResultTable >=1.0.0 in derselben DB nach deren eigenen
Binary-/Trustverträgen installieren. Keine Assembly-, Trust-, Root-, Rechte-,
Owner- oder Configänderung. Aus Deployment-Verzeichnis SQLCMD Deploy.sql mit
DeploymentMode=local ausführen; kein Providerfallback.
Bekannter Zwei-P-Release1.0.0 wiederholbar. Uninstall entfernt nur eigene
Slots/Marker; sichtbare Consumer blockieren. Dependencies/Schema bleiben.

## Sicherheits- und Ergebnisgrenzen

Caller Default mit Windowsauthentifizierung/vorhandenen NTFS-Rechten,
ServiceAccount nur explizit; keine aktive Caller-SQL-TX.
Erst vollständiges ZIP/Entry-Binary, dann Dateipublikation.
Keine SQL-/Dateisystematomarität: später SQL-/Clientfehler kann eine
veröffentlichte Datei hinterlassen. Prepare+Insert gemeinsam spät SQL-
rückrollbar; kein kompensierender Delete. Leerer Entry: 0-Byte-Datei.
Limits sind Obergrenzen, keine Kapazitätszusagen.
Drei eigene kollisionsgeprüfte #ZipFiles_* Brücken ausdrücklich nur wegen
ResultTable-#tbx_-Verbot erlaubt; sonst #tbx_. Keine fremde Tempadoption.
