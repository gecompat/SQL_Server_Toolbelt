# XLSX: genuine 1.0 auf aktuellen 1.2-Build

Stand 2026-11-16: `PASS_FOR_DECLARED_SCOPE`. Alle zwölf unterstützten
Windows-/Linux-Engine-/CL-Paare bestehen lokal und direkt zentral die echte
1.0-Installation und anschließende Aktualisierung auf das unveränderte aktuelle
[fokussierte XLSX-Paket](XLSX-NATIVE-PACKAGE-QUALIFICATION.md).
[Maschinenlesbare Originalbindungen](XLSX-GENUINE10-REST-QUALIFICATION.json).

| Plattform / Patchselektor | SQL 2019 | SQL 2022 | SQL 2025 | Modi |
|---|---|---|---|---|
| Linux / latest | CL150 | CL150, CL160 | CL150, CL160, CL170 | lokal / direkt zentral |
| Windows / CU32, CU26, CU8 | CL150 | CL150, CL160 | CL150, CL160, CL170 | lokal / direkt zentral |

24 ursprüngliche 1.0-Baselines, 48 vollständige vorhandene Typ-/Anzeige-
Metadatenhelfer mit 120 Readerfällen und 13 getrennte frische Abschlussaudits
bestanden. Die Aufteilung in 13 statt zwölf Gesamtläufe vermeidet die
Wiederholung des bereits grünen lokalen Linux2019-Falls beim später gezielt
ergänzten zentralen Fall.

## Originalartefakt und Upgradeablauf

Die vorhandene `New-Xlsx10LegacyFixture.ps1` rekonstruiert unveränderte
Originalquellen des öffentlichen Commits
`fdafa8038e4d5240dd727096f144c8d5fd884117`. Zwölf obligatorische Sourceblobs
einschließlich ursprünglichem Installer, CLR und Buildprojekt werden gegen
Git sowie ihre SHA256-Bindung geprüft. Zwei unabhängige Originalbuilds in
verschiedenen eigenen Verzeichnissen liefern exakt dieselben DLL-Bytes.
Kein aktuelles Binary erhält nachträglich einen 1.0-Versionsmarker.

Der vorhandene Paketadapter stellt zunächst die heutigen ZIP-/ResultTable-
Dependencies bereit. Dazu installiert er das unveränderte Paket und entfernt
danach ausschließlich XLSX über seinen öffentlichen bestätigten Uninstaller;
die Dependencies bleiben erhalten. Der unveränderte ursprüngliche 1.0-Installer
legt anschließend die genuine 1.0-Assembly und ihre SQL-Oberfläche an.

Vor dem Upgrade bestätigt eine tatsächliche Katalogabfrage den exakten
Originalbinaryhash, SAFE-Bindung, Version 1.0.0, richtigen Deploymentmodus,
fünf Slots und zwei CLR-Bindings. Erst eine neue Verbindung führt den heutigen
Paketinstaller aus. Aktuelle Modulversionen, beide aktuellen SAFE-Binaryhashes,
Compatibility Level und Repeat werden geprüft. Eine weitere neue Sitzung
führt die beiden unveränderten Metadatenhelfer vollständig aus: 14 Typfelder,
Defaultzeile und exaktes SqlDecimal1e-38 sowie zwei Anzeigefelder, Default-NULL,
Zahlenfall und vollständige SqlChars-Länge. Definitionen bleiben dabei stabil;
es bleibt keine offene Callertransaktion zurück. Danach folgen öffentliche
Uninstall-/UninstallAbsent-Aufrufe und der eigene Ressourcenabschluss.

Das ist ein konkreter Upgrade-/Metadatenumfang. Vollständige Workbookdomänen,
genuine 1.1-Upgrades, sämtliche Fehler-/Kollisions-/Owner-/Visibilityprofile
oder unabhängige CrossDB-Loginrechte werden dadurch nicht zusätzlich geprüft.

## Bindungsabgleich und endliche Grenzen

Zunächst wurde die historische zentrale Linux2019-Teilabnahme ausgenommen.
Nach 24 von höchstens 28 Aufrufen zeigte der Bindungsabgleich, dass sie den
früheren Providerstand qualifiziert und für das heutige Binary nicht genügt.
Vor Abschluss wurde deshalb ausschließlich diese fehlende zentrale Route
ergänzt. Der lokale Fall wurde nicht wiederholt. Beide Methodenversionen und
ihre ursprünglichen Inputs bleiben getrennt erhalten; der alte Bericht wird
weder geändert noch auf das neue Binary aufgewertet.

Der gemeinsame ursprüngliche Rahmen von 28 Lauf-/Auditaufrufen und
DB-Reservierungen sowie 60 Minuten ab erstem nativem Start blieb unverändert.
26 Aufrufe/Reservierungen wurden verbraucht; alle 24 tatsächlich angelegten
eigenen Datenbanken entfernt. Keine nativen Fehler, korrigierten Fehlfälle
oder Wiederholung grüner Routen. Alle 13 frischen Auditprozesse binden exakt
das jeweilige finale Journal und prüfen Datenbankabwesenheit, eigenen Trust
und vollständige Konfigurationswiederherstellung. Die Welle ist geschlossen;
ungenutzte Plätze eröffnen keine Wiederholung.

Keine Produkt-SQL-/CLR-, Rechte-, Principal- oder Labänderungen. Notwendige
CLR-Konfiguration und exakter eigener Trust folgen ausschließlich der
vorhandenen Entwicklungsfreigabe; fremde und vorbestehende Zustände bleiben
erhalten. Originaljournale, Tool-/Sourcepins und Rohkanäle bleiben privat.
Functional-Verschlüsselung ist keine authentifizierte TLS-Abnahme. Keine
Heap-/Kapazitäts- oder Gesamtmodulqualifikation, Veröffentlichung oder Tags.
Modul weiterhin teilweise validiert und unveröffentlicht.

Reproduzierbare Integritätsprüfung ohne SQL:

```text
python Scripts/Release/validate_xlsx_genuine10_rest.py
```
