# Pakete, aktueller Installer und historische Releases

## Aktueller gemeinsamer Installer

Für eine Neuinstallation verwende den [rc.4-Installationssatz](https://github.com/gecompat/SQL_Server_Toolbelt/releases/download/v1.0.0-rc.4/SQL-Server-Toolbelt-v1.0.0-rc.4-Install.zip)
mit seiner [SHA256-Datei](https://github.com/gecompat/SQL_Server_Toolbelt/releases/download/v1.0.0-rc.4/SQL-Server-Toolbelt-v1.0.0-rc.4-Install.zip.sha256).
Er enthält den geprüften Ein-Aufruf-Installer, die vollständige unveränderte
SQL-Basis und die Anleitung. Nach dem Entpacken genügt ein Aufruf für die
lokale oder zentrale Installation. Kein Repositorycheckout, weiterer
Paketdownload oder DLL-Build ist erforderlich.

Beginne mit der [Kurzanleitung](1.0.0/RC4-INSTALL.md) bzw. der
[Anwenderanleitung](../INSTALL.md). Die [Releasehinweise](1.0.0/RC4.md) und der
[versionierte Buildsatz](1.0.0/Builds/rc4/README.md) erklären Source-/Artefaktbindung.
Der Satz bleibt ein **Entwicklungsvorabrelease für leere ausgewählte
Testdatenbanken**. Bestehende Modul-/Installationsnachweise werden nur im
gebundenen Scope wiederverwendet; es gibt keine neue Modul-Supportzusage.

## Quellen und Paketpflege

Der [aktuelle Quellkandidat](1.0.0/CURRENT-CANDIDATE.md) beschreibt den Bau aus
einem festgelegten Git-Commit und die strikte Bindung an den gemeinsamen
Installer. Er richtet sich an Paketpfleger; Anwender beginnen mit der
[Installation](../INSTALL.md). Ein aktueller Quellbaum qualifiziert historische
Pakete nicht rückwirkend.

## Historische Pakete und Nachweise

| Paket oder Quelle | Zweck und zeitliche Grenze |
|---|---|
| [Projektsnapshot v1.0.0-rc.3](https://github.com/gecompat/SQL_Server_Toolbelt/releases/tag/v1.0.0-rc.3) | Ursprünglicher Ein-Aufruf-Installer für vorab bereitgestellte Datenbanken und CLR; unveränderte Originalassets und [Hinweise](1.0.0/RC3.md). |
| [Projektsnapshot v1.0.0-rc.2](https://github.com/gecompat/SQL_Server_Toolbelt/releases/tag/v1.0.0-rc.2) | Unveränderte frühere Lieferung mit SQL-Basis und bereinigter Dokumentation. rc.3 ergänzt den bereits geprüften Ein-Aufruf-Einstieg im Paket. [Originalhinweise](1.0.0/RC2.md). |
| [Projektsnapshot v1.0.0-rc.1](https://github.com/gecompat/SQL_Server_Toolbelt/releases/tag/v1.0.0-rc.1) | Bereits veröffentlichter Entwicklungssnapshot mit damaligem Quellkandidaten und Parameter-Help-Paket. Kein Download des heutigen gemeinsamen Installers. [Bestätigte Veröffentlichungsdaten](1.0.0/RC1-PUBLICATION.json). |
| [Parameter-Help-Paket](1.0.0/PARAMETER-HELP.md) | Frühere eigenständige Lieferung mit ihrem damaligen Hilfestand und eigenen Nachweisen. Für heutige Neuinstallation den gemeinsamen Installer oben verwenden. |
| [CLR-Wartungspaket](1.0.0/CLR-INSTALL.md) | Separater älterer CLR-Satz mit eigenen Binaries und Lifecycle-Grenzen. |
| [Stable-SQL-Kandidaten](1.0.0/STABLE-SQL-INSTALL.md) | Früherer T-SQL-Einstieg mit damals 19 stabilen Kandidaten; keine aktuelle Gesamtdistribution. |
| [SSIS-Standalone-Pakete](../Modules/toolbelt.tsql.ssis-debug/InstallPackages/README.md) | Getrennt gebundene SSIS-Lieferungen mit ursprünglichen Parser-/Providerbytes und datierten Nachweisen. |
| [Historische Vorbereitung v1.0.0](1.0.0/README.md) | Ausführliche Freigabe-/Qualifikationshistorie für Maintainer, keine Installationsanleitung für Einsteiger. |

Ein veröffentlichter **Projektsnapshot** und unterstützte **Modulversionen** sind
verschiedene Aussagen. Der bestehende RC-Snapshot bleibt veröffentlicht; alle
Modulmanifeste bleiben `unreleased`. Der aktuelle gemeinsame Installer und der Quellkandidat sind im
[Buildverzeichnis](1.0.0/Builds/rc3/README.md) versioniert;
Download und Veröffentlichungsstatus des Vorabreleases stehen in den
[Releasehinweisen](1.0.0/RC4.md). Die historischen 19/26-Zielkanäle
der [Freigabematrix](1.0.0/FREIGABEMATRIX.md) sind keine aktuelle Supportfreigabe.

Für Paketpflege gelten die [Veröffentlichungsregeln](../Documentation/Architecture/MODULE_AND_DEPENDENCY_MODEL.md#öffentlicher-veröffentlichungsnachweis).
Ein grüner CI-Lauf oder gebautes Paket ersetzt keinen ausdrücklichen
Veröffentlichungsauftrag. Historische Archive, Records und Lizenztexte bleiben
unverändert; ihre Aussagen gelten nur für die jeweils gebundenen Artefakte.
