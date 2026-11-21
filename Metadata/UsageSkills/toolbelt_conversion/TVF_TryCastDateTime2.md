---
name: "toolbelt-toolbelt-toolbelt-conversion-tvf-trycastdatetime2"
description: "Prüft ISO-Datetime mit großem T und höchstens sieben Fractionziffern ohne Rundung oder Zeitzonenverlust."
skill_format_version: "1.0"
module_id: "toolbelt.conversion.safe-cast"
schema_name: "toolbelt_conversion"
object_name: "TVF_TryCastDateTime2"
object_type: "TVF"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@Text", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Genau YYYY-MM-DDTHH:mm:ss, optional gefolgt von Punkt und 1..7 ASCII-Nachkommastellen (großes T, insgesamt 19 oder 21..27 Codeeinheiten). Kein Z, Offset, Leerzeichen, 24-Uhr-Zeit, Schaltsekunde oder Rundung; gültiger SQL-datetime2(7)-Bereich. NULL ergibt SQL_NULL, leerer Text EMPTY; sonst ungültige Lexik INVALID_FORMAT, kein stilles Trimmen."}, {"name": "@MaxInputBytes", "sql_type": "int", "sql_default": "8192", "is_output": false, "argument_required": true, "business_required": false, "nullable": false, "description": "Positives int-Bytebudget 1..8192 einschließlich (Default 8192), gemessen mit DATALENGTH des UTF-16-Texts, nicht in Zeichen; auch ungerade Budgets sind zulässig. NULL/0/negativ/>8192 ergibt INVALID_ARGUMENT/PARAMETER, außer Text=NULL hat Vorrang (SQL_NULL). Ein größerer Text ergibt LIMIT/INPUT_LIMIT."}]
source_paths: ["Modules/toolbelt.conversion.safe-cast/Source/TVF_TryCastDateTime2.sql"]
review_status: "verified"
source_module_version: "1.0.0"
---

# TVF_TryCastDateTime2

## Zweck und Einsatzfälle

Prüft ISO-Datetime mit großem T und höchstens sieben Fractionziffern ohne Rundung oder Zeitzonenverlust. Geeignet zur expliziten Klassifikation von gebundenem Eingabetext; Fehlerzustände sind Daten und werden nicht mit einem gültigen NULL-Wert gleichgesetzt.

## Voraussetzungen

SQL Server 2019/2022/2025, Windows/Linux, CL150/160/170; Safe-Cast-Modul installiert. Keine Modul-/Tabellen-/CLR-/Katalogabhängigkeit. Beide Funktionsargumentpositionen angeben, DEFAULT für das technische Budget 8192. Eingabe als Unicodeparameter nvarchar(max) binden, damit keine vorgelagerte varchar-Codepagekonversion den Originaltext verändert.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Vertrag |
|---|---|---|---|
| `@Text` | `nvarchar(max)` | `kein Default` | Genau YYYY-MM-DDTHH:mm:ss, optional gefolgt von Punkt und 1..7 ASCII-Nachkommastellen (großes T, insgesamt 19 oder 21..27 Codeeinheiten). Kein Z, Offset, Leerzeichen, 24-Uhr-Zeit, Schaltsekunde oder Rundung; gültiger SQL-datetime2(7)-Bereich. NULL ergibt SQL_NULL, leerer Text EMPTY; sonst ungültige Lexik INVALID_FORMAT, kein stilles Trimmen. |
| `@MaxInputBytes` | `int` | `8192` | Positives int-Bytebudget 1..8192 einschließlich (Default 8192), gemessen mit DATALENGTH des UTF-16-Texts, nicht in Zeichen; auch ungerade Budgets sind zulässig. NULL/0/negativ/>8192 ergibt INVALID_ARGUMENT/PARAMETER, außer Text=NULL hat Vorrang (SQL_NULL). Ein größerer Text ergibt LIMIT/INPUT_LIMIT. |

Konkrete Lexik: Exakt YYYY-MM-DDTHH:mm:ss mit großem ASCII-T, optional Punkt und ein bis sieben Fractionziffern. Länge 19 oder 21..27. Keine Zone, Offset, kleine t-Schreibweise oder Space als Trenner. Tatsächlicher Kalenderbereich und Stunde 0..23, Minute/Sekunde 0..59; kein 24:00:00 oder Schaltsekunden. Mehr als sieben Fractionziffern ist INVALID_FORMAT, auch bei zusätzlichen Nullen; kein stilles Runden.

## Ergebnisse

Genau eine Zeile mit Value datetime2(7) NULL, Status varchar(16) NOT NULL und ErrorCode varchar(32) NULL. Nur OK liefert Value. Priorität: SQL_NULL bei Text=NULL (auch vor ungültigem Budget), INVALID_ARGUMENT/PARAMETER bei Budget=NULL oder außerhalb 1..8192, LIMIT/INPUT_LIMIT bei DATALENGTH(Text)>Budget, EMPTY/EMPTY bei leerem Text, INVALID_FORMAT/FORMAT bei Lexikfehler, OUT_OF_RANGE/RANGE falls der geprüfte Wert nicht konvertierbar/im Zielbereich ist, sonst OK mit ErrorCode=NULL. SQL_NULL hat ebenfalls ErrorCode=NULL. Nicht alle Zweige des gemeinsamen Statusschemas müssen für jeden Zieltyp erreichbar sein; LOSSY wird nur vom Decimal-Kern erzeugt.

## Aufrufbeispiele

```sql
SELECT Value,Status,ErrorCode
FROM toolbelt_conversion.TVF_TryCastDateTime2(N'2026-11-20T12:34:56.1234567',DEFAULT);
-- 2026-11-20 12:34:56.1234567, OK, NULL
SELECT Value,Status,ErrorCode
FROM toolbelt_conversion.TVF_TryCastDateTime2(NULL,0);
-- NULL, SQL_NULL, NULL (Text-NULL hat Vorrang).
```

## Rechte

Vorhandenes SELECT auf der TVF für SELECT-Aufrufe; entsprechende REFERENCES-Rechte bei Referenzverwendung. Keine Rechtevergabe oder Ausführungsidentitätsänderung. Cross-Database-Identitätszuordnung bleibt Caller-Voraussetzung.

## Ressourcenbedarf

Fester Positionsraum von höchstens 4096 UTF-16-Codeeinheiten, binäre non-SC-Lexik und zulässige TRY_CONVERT-Typpaare. Originale DATALENGTH inklusive trailing spaces bestimmt das Budget. Der Lexikscan kann auch bei kleinerem Callerbudget bis zur festen Obergrenze vorbereitet werden; Statuspriorität ist keine Zusage einer physischen Auswertungsreihenfolge. LOB-Übertragung und Bereitstellung des Originalparameters sind dadurch nicht unbegrenzt ressourcensicher. Keine Laufzeit-/Plan-/Parallelitätsgarantie.

## Nebenwirkungen

Rein lesend; keine Tabellen-, Datei-, Netzwerk-, Trust-, Konfigurations- oder Transaktionsänderung. Kein Input-Echo, keine Fehlerdetails mit Originalwerten und kein automatischer Folgeaufruf.

## Fehlerbehandlung

Fachliche Argument-/Format-/Bereichs- und gegebenenfalls Skalenfehler werden als obige Status-/ErrorCode-Kombination gemeldet; keine fachliche THROW-Anweisung. Nicht vorgesehene Enginefehler und Fehler vor der Funktionsbindung bleiben reguläre Fehler. Keine automatische Trimmung, Korrektur oder Wiederholung.

## Aussagegrenzen

Exakt YYYY-MM-DDTHH:mm:ss mit großem ASCII-T, optional Punkt und ein bis sieben Fractionziffern. Länge 19 oder 21..27. Keine Zone, Offset, kleine t-Schreibweise oder Space als Trenner. Tatsächlicher Kalenderbereich und Stunde 0..23, Minute/Sekunde 0..59; kein 24:00:00 oder Schaltsekunden. Mehr als sieben Fractionziffern ist INVALID_FORMAT, auch bei zusätzlichen Nullen; kein stilles Runden. ASCII-Prüfung erfolgt über UTF-16-Codeeinheiten, sodass NUL, Surrogate und Unicode-Ziffern keine ASCII-Ersatzzeichen sind. Das Bytebudget ist nicht eine Zeichenzahl; ungerade positive Budgets sind zulässig. Die native Qualifikation bleibt an ihre ursprünglichen Artefakte gebunden; quellgeprüfte Skilltexte sind kein neuer Runtime-Nachweis.
