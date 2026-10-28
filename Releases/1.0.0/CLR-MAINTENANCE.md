# CLR-Wartungskandidat für XLSX

Der aktuelle unveröffentlichte Installationskandidat ist
[SQL-Server-Toolbelt-1.0.0-CLR-Maintenance.zip](InstallPackages/SQL-Server-Toolbelt-1.0.0-CLR-Maintenance.zip).
Die [Installationsanleitung](CLR-INSTALL.md) beschreibt Prüfsumme, Voraussetzungen,
Profilauswahl und den Ablauf in einer eigenen Testdatenbank.

Die Wartung ersetzt die XLSX-DLL durch den reproduzierbar gebauten SST-Fix.
Die maximale Verarbeitungszeit bleibt fünf Sekunden. Die beiden öffentlichen
XLSX-Prozeduren zeigen funktionale Beispielaufrufe; die Hilfe der beiden
Zell-TVFs bleibt im gespeicherten DDL erhalten. Der innere ZIP-Ordnername und
die vier Installationsprofile bleiben unverändert.

Neu ausgeführt wurden zwölf Windows-/Linux-Fälle für SQL Server 2019, 2022
und 2025 mit ihren unterstützten Kompatibilitätsstufen, jeweils lokal und
direkt zentral: Installation des ausgewählten ResultTable-/ZIP-/XLSX-Satzes,
Hilfe ohne fachliche Argumente, gespeicherte TVF-Kommentare und die festen
50.000/50.001-Shared-String-Orakel. Alle Fälle und zwölf anschließende
unabhängige Datenbank-/Trust-/Konfigurationsaudits bestanden.

Die anderen zwölf DLLs einschließlich SSIS sind bytegleich zum
[historischen Basispaket](InstallPackages/SQL-Server-Toolbelt-1.0.0-CLR-Install.zip).
Dessen unveränderte Komponenten und Lifecycle-Nachweise werden übernommen.
Eine neue Ausführung sämtlicher Vollprofile, SSIS, die authentifizierte
TLS-Abnahme und eine vollständige neue Lifecycle-Matrix sind damit nicht belegt.
Der Modulstatus und die fehlende Veröffentlichungsfreigabe bleiben erhalten.
Die übrigen Hilfe-/ResultTable-Korrekturen im Repository sind kein Bestandteil
des eingefrorenen Gesamt-Quell-ZIP und werden durch ihre eigenen Modulprüfungen
abgenommen. Der [Hilfe-/Parameterüberblick](HELP-CONTRACT-MAINTENANCE.md)
beschreibt diese Änderungen und die getrennte historische Quellbindung.

Für Maintainer bindet [clr-maintenance-qualification.json](clr-maintenance-qualification.json)
die ausgeführten Fälle, festen Quellen, Prüfmethode und ausgewählten SQL-Exporte.
Der Generator [clr_maintenance.py](../../Scripts/Release/clr_maintenance.py)
erlaubt nur eine bekannte DLL-Ersetzung und sieben ausdrücklich benannte
XLSX-Quellen; alle anderen Nutzdaten stammen aus dem exakten Basispaket.
Der ursprüngliche Generator, Native-Report und qualifizierte ZIP-Container
bleiben unverändert. Der separate [Lieferpin](clr-maintenance-delivery.json)
bindet Container, Report und aktuellen
[Prüfer](../../Scripts/Release/verify_clr_maintenance.py). Dieser vergleicht
alle entpackten Dateien bytegenau und prüft den konkreten Containerhash;
eine plattformabhängige Neukompression dient nicht als Integritätsbeweis.
Die Verifikation arbeitet ohne Build, SQL-Verbindung oder Veröffentlichung:

```powershell
python Scripts/Release/verify_clr_maintenance.py --verify Releases/1.0.0/InstallPackages/SQL-Server-Toolbelt-1.0.0-CLR-Maintenance.zip
```

Ein Fehler bedeutet, dass Paket, Quellen oder Nachweise voneinander abweichen.
Nicht installieren und keine Prüfsumme anpassen, sondern die Abweichung vor
einer neuen Paketqualifikation untersuchen. Frühere Pakete und Ausführungspins
werden für ihre historischen Nachweise erhalten.
