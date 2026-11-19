# SQL Server Toolbelt – aktueller Release- und Installationssatz

Quellstand: `origin/main` Commit `78fb85711bc0b4dd053ed9354399f1b34e52e875` vom 18. November 2026.
Lokal gebaut, nicht veröffentlicht oder getaggt. Beide tatsächlichen Main-CI-Läufe
dieses Commits sind erfolgreich; es wurden nur notwendige Offline-Prüfungen ausgeführt.

## Installieren

1. `SQL-Server-Toolbelt-1.0.0-Current-Install.zip` und seine danebenliegende `.sha256` prüfen.
2. Vollständig entpacken und die **enthaltene START-HERE.md** lesen. Sie enthält
   die bereinigte vollständige Anwenderanleitung. `SHA256SUMS` prüft die Nutzdaten.
3. Genau ein Windows-/Portable- und lokales/zentrales Profil wählen. Leere
   ausgewählte Testdatenbank, bestehende Rechte, CLR und gesonderter exakter
   Assembly-Trust sind erforderlich. Kein eigener Build, kein allgemeiner Upgradeweg.

## Quellen und vollständige Dokumentation

`SQL-Server-Toolbelt-1.0.0-source-78fb8571.zip` samt SHA256-Datei ist der exakt gebundene Quellkandidat aus
diesem Main-Commit. Nach dem Entpacken mit README.md bzw. INSTALL.md beginnen.
Module, API-Katalog und deren relative Dokumentationslinks sind enthalten.
Die versionierten historischen Installations-ZIPs darin bleiben unverändert;
für die neu dokumentierte Installation dieses Satzes das separate Installer-ZIP oben verwenden.

## Nachweisgrenze

Die ausführbaren Installationsinhalte sind bytegleich zum ursprünglichen
Installationssatz mit zwölf Profilen und sechs frischen erfolgreichen Audits.
Die Originalqualifikation bleibt an dessen ursprüngliche Archivbytes gebunden.
Dieses Dokumentations-Repack hat neue Archivprüfsummen und einen gesonderten
Offline-Nachweis, keine neue native SQL-/TLS- oder Modulgesamtqualifikation.
`BUILD-RECEIPT.json` und die Records im Installer erklären die Bindungen.
`SHA256SUMS.txt` in diesem Verzeichnis prüft alle gelieferten Dateien außer sich selbst.
