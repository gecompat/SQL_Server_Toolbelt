# ZIP-Dateifassaden

toolbelt.archive.zip-files 1.0.0 verbindet genau zwei öffentliche T-SQL-USPs
mit bestehenden ZIP-Memory-/Windows-Filesystem-/ResultTableverträgen.
Source implementiert; begrenzte native Windows-local-Teilnachweise vorhanden,
vollständige Qualifikation offen; unveröffentlicht. Keine Assembly.
Der genaue getrennte Laufumfang steht in [Tests](Tests/README.md).

- [CreateZipFileFromEntries](Documentation/USP_CreateZipFileFromEntries.md)
- [ExtractZipEntryToFile](Documentation/USP_ExtractZipEntryToFile.md)
- [Öffentlicher Vertrag](../../Documentation/Architecture/ZIP_FILES_CONTRACT.md)
- [Tests](Tests/README.md)

## Installation

Windows SQL Server 2019/2022/2025, local. Zuerst ZIP Memory >=1.4.0,
Windows Filesystem/ResultTable >=1.0.0 in derselben DB nach deren eigenen
Binary-/Trustverträgen installieren. Keine Assembly-, Trust-, Root-, Rechte-,
Owner- oder Configänderung. Aus Deployment-Verzeichnis SQLCMD Deploy.sql mit
DeploymentMode=local ausführen; kein Providerfallback. Objektmarker sind nur
für ZIP-Writer und Core erforderlich; der bestehende Legacyreader und FS
bleiben an ihre P-Slots/DB-Versionen gebunden (siehe öffentlichen Vertrag).
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

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-04`
- Nachweis: `Privater begrenzter Windows-local-Lauf und gezielte AppLock-Probes`
- Scope: SQL Server 2025/CU8 Windows, CL170, local: elf Fälle in früheren Teilabläufen erfolgreich, danach zwei gezielte Aliasprüfungen unter AppLock erfolgreich, mit identischen Produktbytes. Zusammen 13 Fallnachweise, kein gemeinsamer 13-Fälle-Erfolgslauf. Fünf SQL-Fixtures, Windows-Caller/SQLauth-Ablehnung, Deploy-/Uninstall-Repeat und Alias-First-GO-/AppLock-Schutz; eigene DB/Root abwesend, zwei Trustzustände wiederhergestellt und frische Prüfung erfolgreich, keine Konfigurations-/Rechte-/Owneränderung. Historische fehlgeschlagene Abläufe bleiben fehlgeschlagen; unveränderte Provider wiederverwendet, keine vollständige ZIP-/NTFS-/Zielmatrix-, Central-/Linux-, Minimalrechte- oder aktuelle Head-CI-Qualifikation.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
