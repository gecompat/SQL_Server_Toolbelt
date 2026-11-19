# SQL Server Toolbelt v1.0.0-rc.2 – Entwicklungssnapshot

Dieser Vorabrelease liefert den gemeinsamen Installer mit bereinigter
Anwenderdokumentation und den zugehörigen vollständigen Quellkandidaten.
Er ist für Tests in leeren ausgewählten Datenbanken bestimmt.

## Download und Installation

Der [GitHub-Vorabrelease](https://github.com/gecompat/SQL_Server_Toolbelt/releases/tag/v1.0.0-rc.2)
und das [versionierte Buildverzeichnis](Builds/2026-11-18-78fb8571/README.md)
liefern dieselben sieben Dateien. Für die Installation das
`SQL-Server-Toolbelt-1.0.0-Current-Install.zip` und seine `.sha256` herunterladen,
prüfen, vollständig entpacken und mit der enthaltenen `START-HERE.md` beginnen.
Sie erklärt Voraussetzungen, lokale/zentrale Profilwahl und die ersten Aufrufe.
Ein eigener Build ist nicht erforderlich.

Der Quellkandidat `SQL-Server-Toolbelt-1.0.0-source-78fb8571.zip` enthält
den vollständigen gebundenen Quellstand einschließlich Dokumentation.
Die historischen Installer darin sind unverändert; für diese Lieferung
den separaten gemeinsamen Installer verwenden.

## Quellen und Nachweisgrenze

Beide Archive wurden aus dem geprüften Main-Quellstand
`78fb85711bc0b4dd053ed9354399f1b34e52e875` gebaut. Der Release-Tag bezeichnet
die spätere Integration dieser fertigen Artefakte und ihrer Downloadhinweise.
Er behauptet keinen erneuten rekursiven Build aus dem Artefaktverzeichnis.

Der Installer ist ein Dokumentations-Repack: Alle ausführbaren Installations-
und Trust-Skripte, eingebetteten DLLs und Herkunfts-/Lizenzdateien sind
bytegleich zum ursprünglich geprüften gemeinsamen Installer. Dessen
[native Installationsabnahme](CURRENT-INSTALL-QUALIFICATION.md) bleibt an das
ursprüngliche Archiv gebunden. `DOCUMENTATION-REPACK.json` im neuen ZIP und
`BUILD-RECEIPT.json` neben den Archiven erklären die Offline-Wiederverwendung.

Es wurden keine neuen SQL-/TLS-Läufe ausgeführt. Diese Lieferung ist keine
Produktionsfreigabe oder unterstützte Modulveröffentlichung; die Modulmanifeste
bleiben `unreleased`. Sie erweitert keine Plattform-, Rechte-, Recovery- oder
sonstigen fachlichen Zusagen der vorhandenen Nachweise. Für bestehende
Installationen gibt es keinen pauschalen Upgradeweg.

Die sieben Builddateien bleiben einschließlich ihrer Prüfsummen unverändert.
Ihre Aussagen „nicht veröffentlicht“ und `published: false` beschreiben den
Bauzeitpunkt am 18. November 2026. Der tatsächliche Veröffentlichungsstatus und
die Assetdaten sind auf der verlinkten GitHub-Releaseseite maßgeblich.

Der Benutzer hat am 19. November 2026 ausdrücklich die Veröffentlichung als
GitHub-Vorabrelease beauftragt. Historische Releases bleiben erhalten.
