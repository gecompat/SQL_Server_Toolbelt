# Installation mit vollständiger Parameterhilfe

Das [Parameter-Help-Paket](InstallPackages/SQL-Server-Toolbelt-1.0.0-Parameter-Help.zip)
enthält aktuelle, eigenständige Installationsskripte für eine **leere, ausdrücklich
ausgewählte Datenbank**. Es ist ein Entwicklungsstand, keine veröffentlichte
Vollqualifikation aller Funktionen. Die älteren Stable-/CLR-/SSIS-Pakete und ihre
datierten Nachweise bleiben unverändert und enthalten ältere Hilfetexte.

Voraussetzungen: SQL Server 2019, 2022 oder 2025, vorhandene erforderliche
Installationsrechte, aktiviertes CLR und eine bewusst eingerichtete Truststrategie.
`clr strict security` bleibt aktiv; `TRUSTWORTHY` ist nicht erforderlich.
Für fachliche Modulgrenzen und Rechte siehe [Deployment](../../Deployment/README.md)
und die jeweiligen Modulbeschreibungen. Das Paket richtet keine Windows-Roots,
Linked Server, Logins oder Dateirechte ein.

1. ZIP und danebenliegende SHA256-Datei herunterladen, Archivhash prüfen und
   `SHA256SUMS` für die entpackten Dateien prüfen.
2. Passendes `Install-<Windows|Portable>-<local|central>.sql` auswählen.
   Portable ist für Windows/Linux ohne Windows-spezifische CLR-Module geeignet.
   Windows-central enthält weder das lokale Dateisystemmodul noch dessen
   ZIP-Dateifassaden. Andere Module werden samt Abhängigkeiten installiert.
3. Die benötigten exakten Assemblyhashes durch eine vorhandene administrative
   Instanz vertrauen lassen. `Trust-Windows.sql` beziehungsweise
   `Trust-Portable.sql` ist eine **separate bewusste** administrative Aktion in
   `master`; die Installationsskripte registrieren Trust nicht selbst.
4. Eine neue Zieldatenbank und eine frische Sitzung ohne Callertransaktion wählen;
   das ausgewählte Installationsskript vollständig im SQLCMD-Modus mit
   Fehlerabbruch ausführen (`sqlcmd -b -f 65001` beziehungsweise SSMS SQLCMD-Modus).
   Kein externes SQLCMD-Include oder Binarypfad nötig.
5. Beispielsweise `EXEC toolbelt_core.USP_BeginExecution @Hilfe=1;` ausführen.
   `Section='PARAMETER'` liefert pro Parameter genau eine vollständige Beschreibung
   mit zulässigen Werten, Datenform, Grenzen, NULL-/Default-Verhalten und
   Abhängigkeiten. Die übrigen Abschnitte erklären Ergebnis und Verwendung.

Dieses Paket ist für Neuinstallation bestimmt. Für Änderungen an bestehenden
Installationen die aktuellen Modul-Lifecycle-Skripte und ihre expliziten
Hash-/Versions- und Consumer-Gates verwenden; kein automatisches Überschreiben
einer vorhandenen Installation ableiten. Eine Datenbankbereinigung erfolgt nie
als Teil dieses Pakets.

## Erzeugung und Nachweisgrenze

Die [gemeinsame Parameterquelle](../../Documentation/Reference/api_examples.json)
versorgt Objektseiten, Katalog und Help. SQL-Signaturen bestimmen Reihenfolge,
Typen, technische Defaults und Richtung. Zusätzliche Help-Metadaten und die
weiteren Abschnitte stehen in
[`usp_help.json`](../../Documentation/Reference/usp_help.json); SSIS verwendet
seinen gekoppelten SQL-/CLR-Generator. Die Hilfeblöcke werden beim Build in die
bestehenden Prozeduren geschrieben; zur Laufzeit gibt es keine Registryabfrage
und keine neue Infrastrukturprozedur.

[`new_parameter_help_package.py`](../../Scripts/Release/new_parameter_help_package.py)
verwendet den bestehenden Deployment-Exporter, unveränderte gebundene
Vorgängerbinaries und eine mit dem bestehenden Releasebuilder zweimal identisch
gebaute SSIS-DLL. `PACKAGE.json` bindet Quellen, Redaktion, Binaries und Nutzdaten.
Historische Ergebnisse gelten weiterhin nur für ihre archivierten Bytes.
Neue Help-Laufzeitprüfungen belegen Help-Verhalten und keine erneute vollständige
fachliche Modulabnahme oder authentifizierte TLS-Verbindung.
