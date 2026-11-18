# Pakete, aktueller Installer und historische Releases

## Aktueller gemeinsamer Installer

Für eine Neuinstallation verwende den [gemeinsamen aktuellen Installer](1.0.0/InstallPackages/SQL-Server-Toolbelt-1.0.0-Current-Install.zip)
mit seiner [SHA256-Datei](1.0.0/InstallPackages/SQL-Server-Toolbelt-1.0.0-Current-Install.zip.sha256).
Die [Anwenderanleitung](../INSTALL.md) führt durch Profilwahl, Voraussetzungen,
lokale/zentrale Installation, ersten Aufruf und Fehlerklärung. Die DLLs sind
eingebettet; ein eigener Build ist nicht nötig.

Dieser am 17. November 2026 gemeinsam geprüfte Satz ist ein **unveröffentlichter
Entwicklungskandidat** für leere ausgewählte Testdatenbanken. Seine
[Installationsabnahme](1.0.0/CURRENT-INSTALL-QUALIFICATION.md) erweitert keine
Modul-Supportzusage. Die [Modulübersicht](../Modules/README.md) zeigt die
jeweiligen Implementierungs-, Validierungs- und Releasegrenzen.

## Quellen und Paketpflege

Der [aktuelle Quellkandidat](1.0.0/CURRENT-CANDIDATE.md) beschreibt den Bau aus
einem festgelegten Git-Commit und die strikte Bindung an den gemeinsamen
Installer. Er richtet sich an Paketpfleger; Anwender beginnen mit der
[Installation](../INSTALL.md). Ein aktueller Quellbaum qualifiziert historische
Pakete nicht rückwirkend.

## Historische Pakete und Nachweise

| Paket oder Quelle | Zweck und zeitliche Grenze |
|---|---|
| [Projektsnapshot v1.0.0-rc.1](https://github.com/gecompat/SQL_Server_Toolbelt/releases/tag/v1.0.0-rc.1) | Bereits veröffentlichter Entwicklungssnapshot mit damaligem Quellkandidaten und Parameter-Help-Paket. Kein Download des heutigen gemeinsamen Installers. [Bestätigte Veröffentlichungsdaten](1.0.0/RC1-PUBLICATION.json). |
| [Parameter-Help-Paket](1.0.0/PARAMETER-HELP.md) | Frühere eigenständige Lieferung mit ihrem damaligen Hilfestand und eigenen Nachweisen. Für heutige Neuinstallation den gemeinsamen Installer oben verwenden. |
| [CLR-Wartungspaket](1.0.0/CLR-INSTALL.md) | Separater älterer CLR-Satz mit eigenen Binaries und Lifecycle-Grenzen. |
| [Stable-SQL-Kandidaten](1.0.0/STABLE-SQL-INSTALL.md) | Früherer T-SQL-Einstieg mit damals 19 stabilen Kandidaten; keine aktuelle Gesamtdistribution. |
| [SSIS-Standalone-Pakete](../Modules/toolbelt.tsql.ssis-debug/InstallPackages/README.md) | Getrennt gebundene SSIS-Lieferungen mit ursprünglichen Parser-/Providerbytes und datierten Nachweisen. |
| [Historische Vorbereitung v1.0.0](1.0.0/README.md) | Ausführliche Freigabe-/Qualifikationshistorie für Maintainer, keine Installationsanleitung für Einsteiger. |

Ein veröffentlichter **Projektsnapshot** und unterstützte **Modulversionen** sind
verschiedene Aussagen. Der bestehende RC-Snapshot bleibt veröffentlicht; alle
Modulmanifeste bleiben `unreleased`. Der aktuelle gemeinsame Installer wurde
nicht zusätzlich veröffentlicht oder getaggt. Die historischen 19/26-Zielkanäle
der [Freigabematrix](1.0.0/FREIGABEMATRIX.md) sind keine aktuelle Supportfreigabe.

Für Paketpflege gelten die [Veröffentlichungsregeln](../Documentation/Architecture/MODULE_AND_DEPENDENCY_MODEL.md#öffentlicher-veröffentlichungsnachweis).
Ein grüner CI-Lauf oder gebautes Paket ersetzt keinen ausdrücklichen
Veröffentlichungsauftrag. Historische Archive, Records und Lizenztexte bleiben
unverändert; ihre Aussagen gelten nur für die jeweils gebundenen Artefakte.
