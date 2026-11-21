# ZIP-Dateifassaden

`toolbelt.archive.zip-files` 1.0.0 bietet drei öffentliche Prozeduren zur
ZIP-Erzeugung, Einzel-Entry-Extraktion und vollständigen Archivextraktion
auf Windows. ZIP-Memory, Windows-Filesystem und ResultTable liegen in
derselben Datenbank. Der ZIP-Dateifassaden-Build ist unveröffentlicht.

- [CreateZipFileFromEntries](Documentation/USP_CreateZipFileFromEntries.md)
- [ExtractZipEntryToFile](Documentation/USP_ExtractZipEntryToFile.md)
- [ExtractZipArchiveToDirectory](Documentation/USP_ExtractZipArchiveToDirectory.md)
- [Öffentlicher Vertrag](../../Documentation/Architecture/ZIP_FILES_CONTRACT.md)
- [Tests](Tests/README.md)

## Installation

Für Windows SQL Server 2019, 2022 oder 2025 das Profil `Windows/local` wählen.
Der modulbezogene Build erzeugt eine SQL-Datei mit den Pflichtabhängigkeiten.
In dieser Datei die Zieldatenbank im ersten `USE` einsetzen und sie als
normale SQL-Abfrage ausführen. Der gemeinsame Installationsclient ist der
zweite Einstieg und beschreibt die Voraussetzungen für CLR, Trust und
Aufruferrechte. Beide Wege verwenden den markerfreien Create-only-Installer.
Wiederholungsinstallationen erhalten bestehende Objekte. Die Anleitung zum
modulbezogenen Build verlinkt auch die historischen Lifecycle-Artefakte.
[Modulbezogener Build](Deployment/README.md) · [Gemeinsamer Installer](../../Deployment/ONE-CALL-INSTALL.md)

## Sicherheits- und Ergebnisgrenzen

Caller Default mit Windowsauthentifizierung/vorhandenen NTFS-Rechten,
ServiceAccount nur explizit; keine aktive Caller-SQL-TX.
Writer und Einzel-Entry-Fassade bereiten den Payload vor der
Dateipublikation vollständig auf. Die vollständige Archivextraktion
prüft das Archivverzeichnis vorab und veröffentlicht die geprüften
Einträge einzeln.
Keine SQL-/Dateisystematomarität: später SQL-/Clientfehler kann eine
veröffentlichte Datei hinterlassen. Prepare+Insert gemeinsam spät SQL-
rückrollbar; kein kompensierender Delete. Leerer Entry: 0-Byte-Datei.
Limits sind Obergrenzen, keine Kapazitätszusagen.
Drei eigene kollisionsgeprüfte #ZipFiles_* Brücken ausdrücklich nur wegen
ResultTable-#tbx_-Verbot erlaubt; sonst #tbx_. Keine fremde Tempadoption.

## Aktuelle Validierungsevidenz

Die [Windows-/CL-Abnahme](Tests/ZIP_FILES_TEST_MATRIX.md#aktuelle-windows-cl-abnahme-für-einzel-entry-writer-und-v1)
enthält die sechs geprüften Engine-/CL-Kombinationen und die getrennten
ServiceAccount-, Negativ- und Publish-Nachweise. Die
[V1-Abnahme](Tests/ZIP_FILES_TEST_MATRIX.md#vollständige-archivextraktion-v1)
dokumentiert unter anderem die physischen Grenzfälle. Der folgende
Manifestnachweis gehört zu den historischen Einzel-Entry- und Writer-Läufen.

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-04`
- Nachweis: `Privater begrenzter Windows-local-Lauf und gezielte AppLock-Probes`
- Scope: SQL Server 2025/CU8 Windows, CL170, local: elf Fälle in früheren Teilabläufen erfolgreich, danach zwei gezielte Aliasprüfungen unter AppLock erfolgreich, mit identischen Produktbytes. Zusammen 13 Fallnachweise, kein gemeinsamer 13-Fälle-Erfolgslauf. Fünf SQL-Fixtures, Windows-Caller/SQLauth-Ablehnung, Deploy-/Uninstall-Repeat und Alias-First-GO-/AppLock-Schutz; eigene DB/Root abwesend, zwei Trustzustände wiederhergestellt und frische Prüfung erfolgreich, keine Konfigurations-/Rechte-/Owneränderung. Historische fehlgeschlagene Abläufe bleiben fehlgeschlagen; unveränderte Provider wiederverwendet, keine vollständige ZIP-/NTFS-/Zielmatrix-, Central-/Linux-, Minimalrechte- oder aktuelle Head-CI-Qualifikation.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->

## Freigegebene Security-Härtung 2026-10-15

SC-004: Extraktion erbt Default16 MiB und feste64-MiB-Entrygrenze; Dateifassade prüft diese vor dem Binaryprovider. Größere bisherige Extraktionsparameter sind zu migrieren. Keine stillen Teilpayloads.

Details und abgegrenzte Nachweise: [Security-Härtung](../../Documentation/Architecture/SECURITY_HARDENING_2026_10.md).

## Maschinenlesbare Usage-Skills

Alle katalogisierten Objekte dieses Moduls besitzen quellgeprüfte Skills.
DDL, frühe Prozedurhilfe und die gemeinsame Usage-Skill-View verwenden
dieselben Texte.
