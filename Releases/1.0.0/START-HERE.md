# SQL Server Toolbelt 1.0.0 – Hier beginnen

Öffne zuerst die **[Installationsanleitung Schritt für Schritt](../../INSTALL.md)**.
Sie führt vom entpackten Paket über SSMS und eine neue Demodatenbank zum
ersten erfolgreichen Aufruf. Für den Einstieg mit den 19 stabilen
T-SQL-Kandidaten brauchst du keinen eigenen Build, Git oder Python.

| Datei oder Bereich | Wofür du ihn brauchst |
|---|---|
| `Install-Stable-local.sql` im Paketroot | Fertige SQL-Datei für die 19 stabilen Kandidaten direkt in deiner Testdatenbank; Ablauf in der Installationsanleitung |
| `Install-Stable-central.sql` im Paketroot | Alternative gemeinsame Installation; unterstützte Consumerpfade und Rechte je Modul beachten |
| [CLR-Installation mit fertigen DLLs](CLR-INSTALL.md) | Zusätzliches ZIP mit zwölf Toolbelt-DLLs, ScriptDom, Quellcode, exaktem Trust und fertigen SQL-Dateien; kein eigener Build nötig |
| [SSIS-Installationssatz](../../Modules/toolbelt.tsql.ssis-debug/InstallPackages/README.md) | Separates Windows-ZIP mit passenden DLLs, Trustskripten und vollständigem SSMS-Beispiel |
| [Modulübersicht](../../Modules/README.md) | Weitere Funktionen, Parameter, Voraussetzungen und Beispiele |
| [Freigabematrix](FREIGABEMATRIX.md) | Modulversionen, stabile/Preview-Kandidaten und ihre Nachweisgrenzen |
| [Supportumfang](SUPPORT.md) | Freigegebener Zielumfang und die Grenze zur tatsächlichen öffentlichen Supportzusage |
| [Paketpflege und Prüfung](README.md) | Vollständiger verbindungsfreier Source-/Paketcheck und reproduzierbarer Neubau für Maintainer |
| [Offene Releasegates](RELEASE-GATES.md) | Was geprüft ist und welche Freigaben beziehungsweise Nachweise noch fehlen |
| [Hilfe- und Parameterkorrekturen](HELP-CONTRACT-MAINTENANCE.md) | Verbesserte Objekt-Hilfe, ResultTable-Routen und nötige Anpassung positionsgebundener FileContent-Aufrufe |

Das Gesamtpaket ist eine **unveröffentlichte Quellpaket-Vorbereitung** mit
45 Modulen: 19 stabile und 26 Preview-Kandidaten. Die Kennzeichnung ist noch
keine Produktions- oder Plattformzusage. Alle Modulmanifeste bleiben `unreleased`.
Das eingefrorene Gesamt-ZIP enthält zusätzlich den historischen CLR-Basisstand unter
`Releases/1.0.0/InstallPackages/`. Den aktuellen XLSX-Wartungskandidaten separat
über die [CLR-Anleitung](CLR-INSTALL.md) beziehen. Windows-/Portable- und lokale/zentrale Profile
erhalten die Modulgrenzen. Die Paketprüfung ersetzt keine vollständige neue
API-/Rechte-/Releaseabnahme sämtlicher Preview-Module.

`PACKAGE-MANIFEST.json`, `SHA256SUMS.txt` und die externe ZIP-Prüfsumme binden
den Paketinhalt. Sie ersetzen keine Herausgebersignatur oder fachliche
Abnahme. Der vollständige Maintainer-Prüfmodus verwendet `PREPARATION.bundle`
und einen Git-Checkout mit der öffentlichen Basis aus `product-source.json`.
Der bytegleiche Produkt-Snapshot ist im Bundle enthalten, damit die Prüfung
auch nach Squash-Merge und Branchcleanup möglich bleibt; Endanwender folgen
der Prüfsummen- und Installationsanleitung. Die [Lizenz](../../LICENSE.md)
gilt unverändert. Das Paket ändert keine Server-, Rechte- oder Trustkonfiguration.
