# Pakete, aktueller Installer und historische Releases

## Aktueller markerfreier Quellstand

Der aktuelle [gemeinsame Installationskern](../Scripts/Install/README.md)
erzeugt normale SQL-Dateien ohne SQLCMD-Modus oder Deploymentmarker. Der
[Ein-Aufruf-Client](../Deployment/ONE-CALL-INSTALL.md) verwendet denselben Kern.
Der aktuelle Satz wird aus einem festgeschriebenen Commit gebaut; ein Build
ist keine Veröffentlichung und übernimmt keine native Gesamtqualifikation
historischer Lieferungen. Anwender beginnen mit [INSTALL](../INSTALL.md).

## Veröffentlichte Vorabreleases

Die bisher veröffentlichten Sätze bis rc.4 bleiben unverändert. Der
[rc.4-Installationssatz](https://github.com/gecompat/SQL_Server_Toolbelt/releases/download/v1.0.0-rc.4/SQL-Server-Toolbelt-v1.0.0-rc.4-Install.zip)
mit [SHA256](https://github.com/gecompat/SQL_Server_Toolbelt/releases/download/v1.0.0-rc.4/SQL-Server-Toolbelt-v1.0.0-rc.4-Install.zip.sha256)
enthält seinen ursprünglichen Client und seine SQL-Basis. Dessen
[Kurzanleitung](1.0.0/RC4-INSTALL.md), [Releasehinweise](1.0.0/RC4.md) und
[Buildbindung](1.0.0/Builds/rc4/README.md) gelten ausschließlich für diesen
veröffentlichten Stand; sie liefern den neuen markerfreien Vertrag nicht nach.

Die früheren [Quellkandidaten](1.0.0/CURRENT-CANDIDATE.md) und ihre Builder
bleiben an ihre ursprünglichen Sätze gebunden. Für aktuelle Paketpflege gelten
[die neuen Buildschritte](../Scripts/Install/README.md#installationssatz-aus-festgeschriebenen-quellen-bauen).

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
Modulmanifeste bleiben `unreleased`. Die früheren gemeinsamen Installer und Quellkandidaten stehen in ihren
versionierten Buildverzeichnissen; ihr Veröffentlichungsstatus steht bei den
jeweiligen Releasehinweisen. Die historischen 19/26-Zielkanäle
der [Freigabematrix](1.0.0/FREIGABEMATRIX.md) sind keine aktuelle Supportfreigabe.

Für Paketpflege gelten die [Veröffentlichungsregeln](../Documentation/Architecture/MODULE_AND_DEPENDENCY_MODEL.md#öffentlicher-veröffentlichungsnachweis).
Ein grüner CI-Lauf oder gebautes Paket ersetzt keinen ausdrücklichen
Veröffentlichungsauftrag. Historische Archive, Records und Lizenztexte bleiben
unverändert; ihre Aussagen gelten nur für die jeweils gebundenen Artefakte.
