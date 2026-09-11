# Vorschlag: Regex-Erweiterungen nach R1b (`TC-2026-010`)

## Status

Der bestehende R1b-Slice `toolbelt.string.regex` ist `validated` und
exportiert bewusst nur Is-Match, Instr und Count. Dieses Dokument bereitet
einen späteren Erweiterungsslice vor. Es autorisiert keine Änderung des
Moduls, keine Assembly und kein neues öffentliches SQL-Objekt.

## Ausgangslage

SQL Server 2025 bietet zusätzlich Replace, Substring, Matches und
Split-to-Table. Die aktuelle Microsoft-Dokumentation beschreibt dafür
unterschiedliche Ergebnisformen: Replace liefert Text, Substring einen Wert
oder SQL-`NULL`, und Matches liefert Zeilen einschließlich einer JSON-
Beschreibung der Captures. Diese Breite ist nicht Teil des vorhandenen
Toolbelt-Dialekts und SQL Server 2019/2022 besitzen keine native
Regex-Engine.

R1b übersetzt alle akzeptierten Gruppen in nicht-capturing Gruppen. Damit
schützt der Parser den engen Matching-Vertrag, kann aber keine Capture-Gruppen
oder Replacement-Backreferences nachträglich korrekt hinzufügen. Eine
Erweiterung darf die validierten R1b-Signaturen und ihre Dialektzusage nicht
stillschweigend verändern.

## Empfohlene Welle

Die nächste Welle sollte in zwei getrennten Verträgen erfolgen:

1. **R2a: skalare Transformationsfunktionen.** Ein neuer, klar benannter
   Provider- oder Modul-Slice für Replace und Substring. Er übernimmt die
   vorhandenen Größenlimits, den festen Timeout und die culture-invarianten
   Flags nur, wenn die neue Capture-Grammatik diese Eigenschaften weiterhin
   präzise tragen kann.
2. **R2b: relationale Ergebnisse.** Captures, Matches und Regex-Split als
   eigene TVF- oder ResultTable-Entscheidung. Dieser Slice benötigt stabile
   Ordinals, leere Treffer, Capture-Nullwerte und ein Resultset-Schema; er
   bleibt nach R2a separat.

R2a soll ohne Capture-Backreferences beginnen: der Replacement-Text ist
literal und die ganze Übereinstimmung wird ersetzt. Damit ist der erste
Transformationsvertrag klein und eindeutig. Capture-Gruppen und `\\1` bis
`\\9` gehören erst zu R2b oder einem ausdrücklich erweiterten R2a-Vertrag.

## Vorgeschlagener R2a-Vertrag

| Aspekt | Vorschlag |
|---|---|
| Pattern-Dialekt | Derselbe begrenzte R1b-Grunddialekt; nur eine ausdrücklich spezifizierte Capture-Erweiterung darf davon abweichen. |
| Replace | Startposition ist 1-basiert; `occurrence = 0` ersetzt alle, positive Werte genau den n-ten Treffer. Kein Treffer liefert den unveränderten Eingabetext. |
| Substring | Startposition und occurrence sind 1-basiert; kein Treffer liefert SQL-`NULL`. Der erste Slice liefert den Gesamttreffer, keine Capture-Gruppe. |
| Empty matches | Der Suchcursor rückt nach einem leeren Treffer um eine UTF-16-Codeeinheit vor, damit weder Replace noch Substring endlos laufen. |
| SQL `NULL` | SQL-`NULL` in Quelle, Pattern oder Flags propagiert SQL-`NULL`; ungültige Parameter und Pattern bleiben stabile `TBX_REGEX_*`-Fehler. |
| Grenzen | Höchstens 2 MiB Quelle und Ersatztext sowie 8.000 UTF-16-Bytes Pattern; eine künftige Erhöhung ist eine eigene Ressourcenentscheidung. |
| Ergebnis | Textfunktionen geben `nvarchar(max)` zurück; Positionsfunktionen bleiben bei den bereits festgelegten UTF-16-Positionen. |

Die vorgeschlagene R2a-Semantik weicht bewusst an einzelnen Stellen von der
SQL-Server-2025-Oberfläche ab, etwa bei fehlenden Capture-Backreferences. Das
Modul darf deshalb keine vollständige Native-Parität behaupten. Wo der
Vertrag beabsichtigt mit 2025 verglichen wird, müssen die Abweichungen sichtbar
dokumentiert und getestet werden.

## R2b-Entscheidungen und Risiken

R2b kann nicht allein über eine skalare SQL-CLR-Funktion gelöst werden. Vor
dem ersten Objekt müssen Resultset-Form, Capture-Repräsentation und
Reihenfolge feststehen. Ein JSON-Blob pro Treffer, wie SQL Server 2025 ihn
für `REGEXP_MATCHES` nutzt, ist nicht automatisch ein guter Toolbeltvertrag:
er koppelt den Slice an JSON-Konstruktion und verdeckt SQL-`NULL`-Captures.
Ein normalisiertes Resultset mit Match- und Capture-Ordinalen bleibt eine
gleichwertige, aber andere öffentliche API.

Alle Erweiterungen behalten die wesentlichen R1b-Risiken: .NET-Backtracking
ist nicht linear garantiert, Regex-Aufrufe sind nicht SARGable und ein Timeout
ist keine Performancezusage. R2b fügt Materialisierung, Zeilenexplosion bei
leeren Treffern und größenabhängigen Speicherverbrauch hinzu. Tests müssen
deshalb mindestens Regressionen für R1b, Escape- und Unicodefälle, leere
Treffer, Start/Occurrence, Timeout, große Eingaben, Windows-/Linux-Deployment
und SQL-Server-2019-/2022-/2025-Lab-Ziele abdecken. Spezifische CUs sind nur
bei patchgebundenen Tests erforderlich.

## Entscheidungspunkt

Für eine spätere Implementierungsfreigabe wird der vorgeschlagene R2a-Schnitt
zur Bestätigung vorgelegt: Replace und Substring, keine Capture-
Backreferences, literal Replacement, gleiche Ressourcen- und
Sicherheitsgrenzen wie R1b. R2b bleibt bewusst eine getrennte Entscheidung.
Danach können Zweck, konkrete Signaturen, Alternativen, Risiken und Scope der
jeweiligen Funktionen verbindlich besprochen werden.

## Quellen

- [Microsoft: REGEXP_REPLACE](https://learn.microsoft.com/en-us/sql/t-sql/functions/regexp-replace-transact-sql?view=sql-server-ver17)
- [Microsoft: REGEXP_SUBSTR](https://learn.microsoft.com/en-us/sql/t-sql/functions/regexp-substr-transact-sql?view=sql-server-ver17)
- [Microsoft: REGEXP_MATCHES](https://learn.microsoft.com/en-us/sql/t-sql/functions/regexp-matches-transact-sql?view=sql-server-ver17)
- [Microsoft: REGEXP_SPLIT_TO_TABLE](https://learn.microsoft.com/en-us/sql/t-sql/functions/regexp-split-to-table-transact-sql?view=sql-server-ver17)
- [bestehendes Regex-Moduldesign](./REGEX_MODULE_DESIGN.md)
