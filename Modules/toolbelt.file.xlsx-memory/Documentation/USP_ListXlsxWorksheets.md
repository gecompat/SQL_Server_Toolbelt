# toolbelt_file.USP_ListXlsxWorksheets

## Zweck und öffentlicher Vertrag

Listet die Worksheets in ihrer Workbook-Reihenfolge. Visibility ist visible, hidden oder veryHidden; Date1904 ist lediglich Workbook-Metadatum, keine Datumskonversion.

Die Funktion wurde am 2026-10-01 bedingt nach SAFE-/Memory-only-Gate freigegeben; der dokumentierte Gate-Scope steht im [Qualifizierungsharness](../../../Spikes/XlsxMemory/README.md). Der Provider verarbeitet nur übergebenes Binary und führt Workbookinhalte nicht aus.

## Parameter

`@XlsxBinary varbinary(max) = NULL`.


Die gemeinsamen reduzierbaren Parameter mit Default und Ceiling sind:

- `@MaxArchiveBytes bigint = 16777216`, `@MaxPartBytes bigint = 16777216`, `@MaxTotalUncompressedBytes bigint = 67108864`.
- `@MaxParts int = 256`, `@MaxSheets int = 32`, `@MaxCells int = 100000`, `@MaxSharedStrings int = 50000`.
- `@MaxSharedStringBytes bigint = 8388608`, `@MaxXmlDepth int = 64`, `@MaxCompressionRatio decimal(18,4) = 200`, `@BudgetMilliseconds int = 5000`.
- Abschließend `@ResultTable sysname = NULL`, `@KeepData bit = 0`, `@Debug tinyint = 0`, `@Hilfe bit = 0`.

Für nicht-NULL-Binary sind Limits strikt positiv und nicht NULL; höhere Werte sind ausgeschlossen. KeepData/Debug/Hilfe NULL werden wie 0 behandelt. Hilfe ignoriert fachliche Eingaben, Targets, KeepData und Debug und benötigt keine Runtime-Dependencies.

## Resultset

| Spalte | Typ | Bedeutung |
|---|---|---|
| SheetOrdinal | int NOT NULL | Einsbasierte Worksheet-Reihenfolge |
| SheetName | nvarchar(max) NOT NULL | Unveränderter Name |
| Visibility | nvarchar(16) NOT NULL | visible/hidden/veryHidden |
| Date1904 | bit NOT NULL | Workbook-Datumsmodus |

Unicode-Texte bleiben unverändert und verwenden Latin1_General_100_BIN2. NULL-Binary liefert keine Zeilen; bei gesetztem ResultTable bleibt das Ziel vollständig unverändert. Es erfolgt dann keine Sheet-, Limit-, Dependency- oder Zielprüfung. Help hat noch höhere Priorität.

## Routing, Fehler und Transaktionen

Ohne ResultTable genau ein fachliches SELECT; mit vorhandener caller-lokaler Temp-Tabelle kein fachliches SELECT. KeepData=0 ersetzt, 1 hängt an. Fehlerhafte Inputs und das gesamte gewählte Ergebnis werden vor jeder Zielmutation geprüft.

Reservierte `#tbx_`-Ziele und bereits vorhandene private XLSX-Temptabellen sind ausgeschlossen. Der Guard liegt im öffentlichen Wrapper vor einer eigenen internen Compilergrenze; er verhindert auch Caller-Temp-Eclipsing mit fremdem Schema, nicht nur eine spätere Helperprüfung.

51520 ist eine begrenzte erwartete Input-/Container-/XML-/Feature-/Ressourcenfehlerkategorie ohne Workbookinhalt; 51529 kennzeichnet Provider-/Dependencyinkonsistenz. Keine Teilausgabe oder SQL6522-Textparser. Mutationsscope ist eine eigene Transaktion oder ein Caller-Savepoint; kein vollständiger Callerrollback. Doomed Caller müssen selbst zurückrollen. Echte Enginefehler bleiben Originalfehler.

## Dependencies, Berechtigungen und Grenzen

Zielmatrix: SQL Server 2019/2022/2025 auf Windows/Linux; SAFE .NET Framework 4.8. Das Modul referenziert kanonischen ZIP-CLR der Major-1-Linie ab 1.4.0 und benötigt same-database ResultTable der Major-1-Linie ab 1.0.0 für den Zielpfad.

Für fachliche direkte Ausgabe weist ein enges Objektprofil `EXECUTE` auf dieser USP und `SELECT` auf `toolbelt_file.TVF_InternalXlsxSheets` nach. Für `@ResultTable` kommt `EXECUTE` auf `toolbelt_core.USP_PrepareResultTable` hinzu. In den geprüften Rechtemasken führte öffentliches `EXECUTE` ohne sichtbares internes FT zu 51529; ohne öffentliches `EXECUTE` wurde 229 verlangt. Dies ist ein nachgewiesenes schmales Profil, keine Aussage über mathematische Minimalität oder alle möglichen Rechtekombinationen. Die [Raw-Caller-Evidenz](../../../Releases/1.0.0/XLSX-RAW-CALLER-PROFILE.md) bindet die zwölf ausgewählten Ziel-/CL-Fälle. Deployment vergibt keine Rechte.

Die Liste validiert Paket-/Worksheet-Metadaten und sämtliche Relationships, aber nicht jeden ungelesenen Zellpart. Unterstützt sind Transitional XLSX und kanonische Stored-/Deflate-Parts; ausgeschlossene Varianten und Memory-/Budgetaussagegrenzen stehen in [README](../README.md). Keine File-/Netzwerk-/SDK-/Workerfallbacks, Streaming-, copy-free-, Gesamtpeak- oder SQL-Memory-Grant-Zusage.

## Synthetisches Beispiel

```sql
-- @SyntheticWorkbook stammt ausschließlich aus einem synthetischen Testfixture.
EXEC toolbelt_file.USP_ListXlsxWorksheets @XlsxBinary = @SyntheticWorkbook;
```

`@Hilfe = 1` liefert separat das standardisierte Help-Resultset ohne
Workbook-Eingabe oder Runtime-Dependency.

## Vollständiger Eingabevertrag

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@XlsxBinary` | `varbinary(max)` | `NULL` | Input | Vollständiger XLSX-Bytepuffer varbinary(max), kein Pfad/Base64text. Unterstützt Transitional-XLSX mit kanonischen Stored-/Deflate-ZIP-Parts, sicheren lokalen Relationships und XML ohne DTD/externe Auflösung; keine XLS/XLSB-/verschlüsselten Workbooks oder Makroausführung. Leer ist ungültig. NULL (Default) liefert keine Zeilen vor Sheet-/Limit-/Dependency-/Zielprüfung und lässt ResultTable unverändert. |
| `@MaxArchiveBytes` | `bigint` | `16777216` | Input | Ganzzahl 1..16777216, Default 16777216: komprimierte Bytes des vollständigen XLSX-Inputs. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung. |
| `@MaxPartBytes` | `bigint` | `16777216` | Input | Ganzzahl 1..16777216, Default 16777216: unkomprimierte Bytes je ZIP-/XML-Part. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung. |
| `@MaxTotalUncompressedBytes` | `bigint` | `67108864` | Input | Ganzzahl 1..67108864, Default 67108864: globale unkomprimierte ZIP-/Partbytes; zusätzliche gezählte XML-Materialisierung bleibt begrenzt. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung. |
| `@MaxParts` | `int` | `256` | Input | Ganzzahl 1..256, Default 256: ZIP-Parts einschließlich nicht als Zelloutput gewählter Einträge. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung. |
| `@MaxSheets` | `int` | `32` | Input | Ganzzahl 1..32, Default 32: Worksheet-Metadaten im Workbook, nicht nur der ausgewählte Sheet. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung. |
| `@MaxCells` | `int` | `100000` | Input | Ganzzahl 1..100000, Default 100000: vorhandene sparse Zellen des gelesenen Worksheets; keine aufgefüllten Rechteckzellen. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung. |
| `@MaxSharedStrings` | `int` | `50000` | Input | Ganzzahl 1..50000, Default 50000: Einträge der Shared-String-Tabelle. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung. |
| `@MaxSharedStringBytes` | `bigint` | `8388608` | Input | Ganzzahl 1..8388608, Default 8388608: decodierte UTF-16-Bytes der Shared-String-Texte, nicht komprimierte XML-Bytes. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung. |
| `@MaxXmlDepth` | `int` | `64` | Input | Ganzzahl 1..64, Default 64: XmlReader-Tiefe; XML-Root hat Depth 0. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung. |
| `@MaxCompressionRatio` | `decimal(18,4)` | `200` | Input | decimal(18,4) im inklusiven Bereich 1..200, Default 200. Deklarierte Uncompressed-/Compressed-Byte-Ratio der ZIP-Einträge; Bruchteile sind zulässig. NULL/&lt;1/&gt;200 ungültig bei nicht-NULL-Binary. Kein Prozentsatz und keine globale Heapgarantie. |
| `@BudgetMilliseconds` | `int` | `5000` | Input | Ganzzahl 1..5000, Default 5000: Millisekunden kooperatives Verarbeitungsbudget; keine harte SQL-Marshalling-/Gesamtwallclock-Garantie. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Kein #tbx_-Präfix. XlsxBinary=NULL lässt das Ziel vollständig unverändert und prüft es nicht. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. Keine Workbookinhalte; im Zielpfad zusätzlich Helperdiagnose. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |
<!-- API_PARAMETERS:END -->


## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#xlsx).
