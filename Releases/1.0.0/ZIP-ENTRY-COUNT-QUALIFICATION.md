# ZIP-Entryanzahl: Paketgebundene Grenzprüfung

Diese Prüfung belegt einen eng begrenzten bestehenden Vertrag von
`toolbelt_archive.USP_ListZipEntriesFromBinary`: das positive Limit von 10.000
Einträgen, die Ablehnung eines Archivs mit 10.001 Einträgen und die Ablehnung
eines angeforderten `@MaxEntries`-Werts von 10.001. Die maschinenlesbare
[Evidenz](zip-entry-count-qualification.json) bindet das geprüfte
Installationspaket, die ZIP-DLL und 115 öffentliche Repository-Eingaben.

## Feste Eingaben und Orakel

Der Composer
[`compose_zip_entry_count.py`](../../Tests/Release/compose_zip_entry_count.py)
erzeugt zwei synthetische ZIP-Dateien mit leeren `Stored`-Einträgen,
`e00000.txt` bis `e10000.txt`, CRC32 0 und dem festen DOS-Zeitwert
`2020-02-03 04:05:06`. Das positive Archiv enthält genau 10.000 Einträge;
das Overflow-Archiv enthält 10.001. Die Quelleinträge und erwarteten Metadaten
werden unabhängig vom SQL-Ergebnis festgelegt.

Der direkte Reader muss 13 erwartete Spalten liefern. Jede Zeile wird anhand
ihres eindeutigen `EntryOrdinal` gegen den Namen und alle festen Metadaten
geprüft; die SQL-Auslieferungsreihenfolge wird nicht vorausgesetzt. Beide
Negativpfade verwenden `SqlDataReader` und lesen bis zum Fehler weiter. Jeder
Pfad schlägt fehl, sobald er vor dem erwarteten Fehler eine Zeile erhält.

## Matrix und Ergebnis

Die zwölf Ziel-/Kompatibilitätsfälle decken Windows und Linux mit SQL Server
2019/CL150, 2022/CL150 und CL160 sowie 2025/CL150, CL160 und CL170 ab. Jeder
Fall prüft lokale und direkt zentrale Deployment-Ausgabe.

- 24 positive Routen lieferten je 10.000 feste Ergebniszeilen (240.000 Zeilen insgesamt).
- 24 Overflow-Routen wurden mit SQL-Fehler 51325 und ohne vorher gelesene Zeile abgewiesen.
- 24 Routen mit `@MaxEntries = 10001` wurden mit SQL-Fehler 51320 und ohne vorher gelesene Zeile abgewiesen.
- Alle zwölf Fälle und ihre unmittelbaren Audits bestanden. 24 eigene Datenbankeinträge wurden erstellt und entfernt; zwölf Trust-Entfernungsereignisse wurden protokolliert.
- Sechs zusätzliche schreibgeschützte Abschlussaudits prüften je einen ausgewählten Fall für jeden Windows-/Linux- und SQL-Versionszielpunkt. Sie werden nicht als erneute Prüfung aller 24 Datenbankeinträge gezählt.

Insgesamt wurden 30 SQL-Prozessinvokationen ausgeführt: zwölf Testfälle,
zwölf unmittelbare Audits und sechs zusätzliche Abschlussaudits. Die weiteren
Prüfungen bestätigten den wiederhergestellten Trust- und Konfigurationszustand.

## Nachgelagerte CI-Korrektur

Der erste CI-Lauf am ursprünglichen PR-Head scheiterte ausschließlich an der
Cold-Checkout-AST-Prüfung für die explizite Labvertrag-Abhängigkeit im
Runset-Preparer. Der Preparer verwendet jetzt dieselbe direkte
`Join-Path`-Dot-Command-Form wie der Labtreiber. Der Report behält den
ausgeführten Original-Preparer-Pin und dessen öffentlichen Commitanker;
der Regressionstest rekonstruiert die Originalbytes durch genau die inverse
Zweizeilenänderung, prüft den ursprünglichen SHA-256 und bindet den aktuellen
Quellhash separat. Diese syntaktische Korrektur wurde nicht erneut ausgeführt
und löste keinen SQL- oder Frameworklauf aus. Der ursprüngliche CI-Fehler
bleibt in der PR-Historie erhalten.

## Grenzen

Dieser Nachweis deckt die aufgelistete Entryanzahl-Grenze und die feste
Metadatenausgabe dieser einen API ab. Der deklarierte 256-MiB-Archivgrenzwert
wurde hier nicht getestet. Die Prüfung belegt weder Payload-Extraktion noch
ZIP64-/Multi-Disk-Verhalten, andere ZIP-APIs, ResultTable-Ausgabe,
Objektrechteprofile, das vollständige Modulverhalten oder eine
Authentifizierungs-/TLS-Abnahme. Die Modulvalidierung bleibt `partially
validated`, der Release-Status bleibt `unreleased`; Produktquellen,
Assemblycode und Paket wurden nicht geändert.
