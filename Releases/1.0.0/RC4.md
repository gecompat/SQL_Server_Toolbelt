# SQL Server Toolbelt v1.0.0-rc.4 – ausdrückliche Installationsvorbereitung

Dieser Entwicklungsvorabrelease erweitert den Ein-Aufruf-Installer um
`CreateDatabase` und `EnableClr`. Beide sind standardmäßig aus. Sie erlauben
fehlende benannte Datenbanken und CLR-Aktivierung, ohne Rechte zu vergeben,
Sicherheitsoptionen abzuschwächen oder fremde Pending-Änderungen mitzuaktivieren.

Die [Kurzanleitung](RC4-INSTALL.md) erklärt Download, Voraussetzungen und je
einen lokalen/zentralen Aufruf. Die [Vorbereitungsreferenz](../../Deployment/PROVISIONING.md)
beschreibt Journal, Zustandsbindung und mögliche Teiländerungen nach Fehlern.
Ein neues BUNDLE bindet Einstieg, Helfer, SQL-Basis und die separate aktuelle
Vorbereitungsabnahme. Die SQL-Skripte und Binaries der inneren rc.2-ZIP bleiben
bytegleich. Alte Vorabreleases und historische Nachweise werden nicht verändert.

Die ursprüngliche rc.3-Clientabnahme gilt ausschließlich für ihre damaligen
Einstiegsbytes. Der aktuelle Nachweis wird getrennt unter
[InstallerProvisioning.20261119.json](../../Deployment/Tests/Qualification/InstallerProvisioning.20261119.json)
geführt. Zusätzliche Tests betreffen ausschließlich die neue Vorbereitung,
deren Fehlergrenzen und das ausgelieferte Paketlayout; unveränderte Modulmatrizen
werden wiederverwendet. Es gibt keine neue TLS-/GUI- oder Modulgesamtqualifikation;
Modulmanifeste bleiben `unreleased`.

`BUILD-RECEIPT.json` benennt den exakten Vorbereitungscommit der beiden ZIPs;
der Release-Tag zeigt auf die spätere grüne Integration der fertigen Artefakte.
Der Benutzer hat am 19. November 2026 diese konkrete Erweiterung einschließlich
neuem öffentlichen GitHub-Vorabrelease beauftragt. Der tatsächliche Status und
die sieben Assets stehen auf der
[Releaseseite](https://github.com/gecompat/SQL_Server_Toolbelt/releases/tag/v1.0.0-rc.4).
