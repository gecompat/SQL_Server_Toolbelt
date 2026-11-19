# SQL Server Toolbelt v1.0.0-rc.3 – Ein-Aufruf-Installer

Dieser Entwicklungsvorabrelease bündelt den geprüften Ein-Aufruf-Installer
mit seiner vollständigen SQL-Basis. Nach dem Entpacken genügt ein Aufruf für
die lokale oder zentrale Neuinstallation. Ein Repositorycheckout ist für
die Installation nicht erforderlich.

## Download

- [Installationssatz](https://github.com/gecompat/SQL_Server_Toolbelt/releases/download/v1.0.0-rc.3/SQL-Server-Toolbelt-v1.0.0-rc.3-Install.zip)
  und [SHA256-Datei](https://github.com/gecompat/SQL_Server_Toolbelt/releases/download/v1.0.0-rc.3/SQL-Server-Toolbelt-v1.0.0-rc.3-Install.zip.sha256).
- [Quellkandidat](https://github.com/gecompat/SQL_Server_Toolbelt/releases/download/v1.0.0-rc.3/SQL-Server-Toolbelt-v1.0.0-rc.3-source.zip)
  und [SHA256-Datei](https://github.com/gecompat/SQL_Server_Toolbelt/releases/download/v1.0.0-rc.3/SQL-Server-Toolbelt-v1.0.0-rc.3-source.zip.sha256).
- [Versionierter Satz und Buildnachweis](Builds/rc3/README.md).

Die [Kurzanleitung](RC3-INSTALL.md) entspricht der mitgelieferten `START-HERE.md`
mit an den Lieferort angepassten Links. Sie enthält die beiden Aufrufe,
Voraussetzungen, erwartetes Ergebnis und den Fehlerweg.

## Wiederverwendete Nachweise

Der Einstieg bleibt unverändert gegenüber dem in
[PR #622](https://github.com/gecompat/SQL_Server_Toolbelt/pull/622) integrierten
Stand. Die innere rc.2-ZIP mit SQL-Skripten, eingebetteten DLLs, Herkunft und
Lizenzdaten bleibt vollständig bytegleich. Das Paket verwendet dieselbe
relative Laufzeitstruktur wie der Repositorycheckout; der Einstieg findet
die mitgelieferte Basis lokal. Es gibt keine neue Installationslogik.

Die [native Clientabnahme](../../Deployment/Tests/Qualification/OneCallInstaller.20261119.json)
bleibt an ihre Originalquellen gebunden: zwölf Profile, Windows/Linux mit
SQL2019/CL150, SQL2022/CL160 und SQL2025/CL170, sechs frische unabhängige Audits.
Sie verwendete SQL-Anmeldung von einem Windows-Client und vorbereiteten exakten
Trust. Die ursprüngliche Neueintragungssemantik des unveränderten Trustskripts
wird wiederverwendet. Integrierte Anmeldung besitzt die dort beschriebenen
Offline-Gegenproben; eine neue native Windows-Anmeldung wird nicht behauptet.
Frühere Fehler und ihre Audits bleiben erhalten.

Neu geprüft werden Archivintegrität, lokale Paketauflösung ohne Download,
alle vier Profile mit synthetischen Clientantworten aus dem entpackten Paket,
Lizenz-/Nutzdatenidentität und die vollständigen betroffenen Lesewege.
Keine neuen SQL-, TLS- oder GUI-Läufe; keine Modulgesamt-/Produktionsfreigabe.
Alle Modulmanifeste bleiben `unreleased`.

## Quellen und Veröffentlichung

`BUILD-RECEIPT.json` nennt den exakten Vorbereitungscommit des Quellkandidaten
und Installationssatzes. Der Release-Tag zeigt auf die spätere grüne Integration
dieser fertigen Artefakte nach `origin/main`. Produkt-/Einstiegsbytes bleiben
dabei unverändert; Quell- und Integrationscommit sind getrennt ausgewiesen.
Fertige Liefer-ZIPs werden aus späteren Git-Quell-Exports ausgeschlossen,
um rekursive Lieferungen zu verhindern, bleiben aber in Git verfügbar.

Der Benutzer hat am 19. November 2026 diesen neuen Satz und seine öffentliche
Veröffentlichung als GitHub-Vorabrelease ausdrücklich beauftragt. Der tatsächliche
Veröffentlichungsstatus und die Assetdaten stehen auf der
[Releaseseite](https://github.com/gecompat/SQL_Server_Toolbelt/releases/tag/v1.0.0-rc.3).
Die bisherigen Releases rc.1 und rc.2 samt Artefakten und Nachweisen bleiben unverändert.
