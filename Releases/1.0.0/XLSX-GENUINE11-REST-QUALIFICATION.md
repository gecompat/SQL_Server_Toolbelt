# XLSX: genuine 1.1 auf aktuellen 1.2-Build

Stand 2026-11-16: `PASS_FOR_DECLARED_SCOPE`. Alle zwölf unterstützten
Windows-/Linux-Engine-/CL-Paare bestehen lokal und direkt zentral die echte
1.1-Installation und anschließende Aktualisierung auf das unveränderte aktuelle
[fokussierte XLSX-Paket](XLSX-NATIVE-PACKAGE-QUALIFICATION.md).
[Maschinenlesbare Originalbindungen](XLSX-GENUINE11-REST-QUALIFICATION.json).

| Plattform / Patchselektor | SQL 2019 | SQL 2022 | SQL 2025 | Modi |
|---|---|---|---|---|
| Linux / latest | CL150 | CL150, CL160 | CL150, CL160, CL170 | lokal / direkt zentral |
| Windows / CU32, CU26, CU8 | CL150 | CL150, CL160 | CL150, CL160, CL170 | lokal / direkt zentral |

24 ursprüngliche 1.1-Baselines, 48 vollständige vorhandene Typ-/Anzeige-
Metadatenhelfer mit 120 Readerfällen und zwölf getrennte frische Abschlussaudits
bestanden. Jeder Gesamtlauf prüft genau ein Engine-/CL-Paar lokal und direkt
zentral; keine Route wird wiederholt.

## Originalartefakt und Upgradeablauf

Die vorhandene `New-Xlsx11LegacyFixture.ps1` rekonstruiert unveränderte
Originalquellen des öffentlichen Commits
`f64ee9eb8f6a7f66fd441821c7c40fcf2d92ee1e`. Fünfzehn obligatorische Sourceblobs
einschließlich ursprünglichem Installer, CLR und Buildprojekt werden gegen
Git sowie ihre SHA256-Bindung geprüft. Zwei unabhängige Originalbuilds in
verschiedenen eigenen Verzeichnissen liefern exakt dieselben DLL-Bytes.
Kein aktuelles Binary erhält nachträglich einen 1.1-Versionsmarker.

Der vorhandene Paketadapter stellt zunächst die heutigen ZIP-/ResultTable-
Dependencies bereit. Dazu installiert er das unveränderte Paket und entfernt
danach ausschließlich XLSX über seinen öffentlichen bestätigten Uninstaller;
die Dependencies bleiben erhalten. Der unveränderte ursprüngliche 1.1-Installer
legt anschließend die genuine 1.1-Assembly und ihre SQL-Oberfläche an.

Vor dem Upgrade bestätigt eine tatsächliche Katalogabfrage den exakten
Originalbinaryhash, SAFE-Bindung, Version 1.1.0, richtigen Deploymentmodus,
sieben Slots und drei CLR-Bindings. Erst eine neue Verbindung führt den heutigen
Paketinstaller aus. Aktuelle Modulversionen, beide aktuellen SAFE-Binaryhashes,
Compatibility Level und Repeat werden geprüft. Eine weitere neue Sitzung
führt die beiden unveränderten Metadatenhelfer vollständig aus: 14 Typfelder,
Defaultzeile und exaktes SqlDecimal1e-38 sowie zwei Anzeigefelder, Default-NULL,
Zahlenfall und vollständige SqlChars-Länge. Definitionen bleiben dabei stabil;
es bleibt keine offene Callertransaktion zurück. Danach folgen öffentliche
Uninstall-/UninstallAbsent-Aufrufe und der eigene Ressourcenabschluss.

Das ist ein konkreter Upgrade-/Metadatenumfang. Vollständige Workbookdomänen,
originale 1.1-API-/Consumerprüfungen, sämtliche Fehler-/Kollisions-/Owner-/Visibilityprofile
oder unabhängige CrossDB-Loginrechte werden dadurch nicht zusätzlich geprüft.

## Exakte Testquellen und endliche Grenzen

Die ausgeführte Methodenversion ist im maschinenlesbaren Record an ihren
Originalcommit gebunden. Fünf Testquellen lagen im Windows-Checkout mit CRLF
vor, während Git LF speichert. Das zusätzliche
[Quellenartefakt](Artifacts/Xlsx-Genuine11-Method-Checkout.zip) enthält exakt
diese fünf ausgeführten öffentlichen Dateien, keine Runtimeausgaben. Der
Validator prüft ihren eigenen SHA256, jede ursprüngliche Ausführungspin und
separat die originalen Git-Bytes; ausschließlich CRLF→LF darf zwischen beiden
abweichen. Es wird kein neuer Commit als ursprüngliche Methode ausgegeben.

Der einmalige Rahmen von 24 Lauf-/Auditaufrufen und DB-Reservierungen sowie
60 Minuten ab erstem nativem Start blieb unverändert. Alle 24 Aufrufe wurden
verbraucht; alle 24 eigenen Datenbanken entfernt. Keine nativen Fehler,
korrigierten nativen Fehlfälle oder Wiederholung grüner Routen. Alle zwölf
frischen Auditprozesse binden exakt das jeweilige finale Journal und prüfen
Datenbankabwesenheit, eigenen Trust und Konfigurationswiederherstellung.
Die Welle ist geschlossen; keine neuen SQL-/Auditaufrufe daraus ableiten.

Vor Skripteintritt wurde ein externer PowerShell-Aufruf wegen einer als
Kommastring übergebenen Int32[]-Option zurückgewiesen. Das Skript war noch
nicht gestartet: null Zielaufrufe, kein Budgetstart und keine Ressourcen.
Der korrekte Aufruf verwendet die unveränderte deklarierte Indexauswahl.
Dieser Aufruferfehler bleibt erhalten und wird nicht als nativer Fall gezählt.

Keine Produkt-SQL-/CLR-, Rechte-, Principal- oder Labänderungen. Notwendige
CLR-Konfiguration und exakter eigener Trust folgen ausschließlich der
vorhandenen Entwicklungsfreigabe; fremde und vorbestehende Zustände bleiben
erhalten. Originaljournale, Tool-/Sourcepins und Rohkanäle bleiben privat.
Functional-Verschlüsselung ist keine authentifizierte TLS-Abnahme. Keine
Heap-/Kapazitäts- oder Gesamtmodulqualifikation, Veröffentlichung oder Tags.
Modul weiterhin teilweise validiert und unveröffentlicht.

Reproduzierbare Integritätsprüfung ohne SQL:

```text
python Scripts/Release/validate_xlsx_genuine11_rest.py
```
