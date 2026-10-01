# toolbelt_file.USP_ReadXlsxWorksheetCells

## Zweck und öffentlicher Vertrag

Liest sparse vorhandene Zellen des explizit einsbasiert gewählten Worksheets. RowOrdinal und ColumnOrdinal bilden die sortierte SELECT-Reihenfolge; eine ResultTable garantiert keine physische Reihenfolge.

Die Funktion wurde am 2026-10-01 bedingt nach SAFE-/Memory-only-Gate freigegeben; der dokumentierte Gate-Scope steht im [Qualifizierungsharness](../../../Spikes/XlsxMemory/README.md). Der Provider verarbeitet nur übergebenes Binary und führt Workbookinhalte nicht aus.

## Parameter

`@XlsxBinary varbinary(max) = NULL`, `@SheetOrdinal int = NULL`.
SheetOrdinal ist für nicht-NULL-Binary fachlich erforderlich und bezeichnet ein Worksheet aus USP_ListXlsxWorksheets.

Die gemeinsamen reduzierbaren Parameter mit Default und Ceiling sind:

- `@MaxArchiveBytes bigint = 16777216`, `@MaxPartBytes bigint = 16777216`, `@MaxTotalUncompressedBytes bigint = 67108864`.
- `@MaxParts int = 256`, `@MaxSheets int = 32`, `@MaxCells int = 100000`, `@MaxSharedStrings int = 50000`.
- `@MaxSharedStringBytes bigint = 8388608`, `@MaxXmlDepth int = 64`, `@MaxCompressionRatio decimal(18,4) = 200`, `@BudgetMilliseconds int = 5000`.
- Abschließend `@ResultTable sysname = NULL`, `@KeepData bit = 0`, `@Debug tinyint = 0`, `@Hilfe bit = 0`.

Für nicht-NULL-Binary sind Limits strikt positiv und nicht NULL; höhere Werte sind ausgeschlossen. KeepData/Debug/Hilfe NULL werden wie 0 behandelt. Hilfe ignoriert fachliche Eingaben, Targets, KeepData und Debug und benötigt keine Runtime-Dependencies.

## Resultset

| Spalte | Typ | Nullability/Bedeutung |
|---|---|---|
| RowOrdinal / ColumnOrdinal | int | NOT NULL, einsbasierte Koordinate |
| StoredType | nvarchar(16) | NOT NULL, n/s/inlineStr/str/b/e/d, keine Typinferenz |
| ValuePresent | bit | NOT NULL, v-Element vorhanden |
| RawValue | nvarchar(max) | NULL bei fehlendem v, sonst unveränderter Rohtext einschließlich leer |
| TextValue | nvarchar(max) | NULL ohne Stringtext; aufgelöster Shared-/Inline-/str-Text |
| FormulaPresent | bit | NOT NULL, f-Element vorhanden |
| FormulaText / FormulaKind | nvarchar(max) / nvarchar(16) | NULL ohne Formel; normal/shared/array/dataTable |
| SharedFormulaIndex | int | NULL ohne gespeicherten si |
| CachePresent | bit | NOT NULL, Formel mit vorhandenem v |
| CacheValue | nvarchar(max) | NULL ohne gespeicherten Formelcache, vorhandenes leeres v bleibt leer |

Unicode-Texte bleiben unverändert und verwenden Latin1_General_100_BIN2. NULL-Binary liefert keine Zeilen; bei gesetztem ResultTable bleibt das Ziel vollständig unverändert. Es erfolgt dann keine Sheet-, Limit-, Dependency- oder Zielprüfung. Help hat noch höhere Priorität.

## Routing, Fehler und Transaktionen

Ohne ResultTable genau ein fachliches SELECT; mit vorhandener caller-lokaler Temp-Tabelle kein fachliches SELECT. KeepData=0 ersetzt, 1 hängt an. Fehlerhafte Inputs und das gesamte gewählte Ergebnis werden vor jeder Zielmutation geprüft.

Reservierte `#tbx_`-Ziele und bereits vorhandene private XLSX-Temptabellen sind ausgeschlossen. Der Guard liegt im öffentlichen Wrapper vor einer eigenen internen Compilergrenze; er verhindert auch Caller-Temp-Eclipsing mit fremdem Schema, nicht nur eine spätere Helperprüfung.

51520 ist eine begrenzte erwartete Input-/Container-/XML-/Feature-/Ressourcenfehlerkategorie ohne Workbookinhalt; 51529 kennzeichnet Provider-/Dependencyinkonsistenz. Keine Teilausgabe oder SQL6522-Textparser. Mutationsscope ist eine eigene Transaktion oder ein Caller-Savepoint; kein vollständiger Callerrollback. Doomed Caller müssen selbst zurückrollen. Echte Enginefehler bleiben Originalfehler.

## Dependencies, Berechtigungen und Grenzen

Zielmatrix: SQL Server 2019/2022/2025 auf Windows/Linux; SAFE .NET Framework 4.8. Die tatsächlich qualifizierten Kombinationen stehen in der Testmatrix. Das Modul referenziert kanonischen ZIP-CLR der Major-1-Linie ab 1.4.0 und benötigt same-database ResultTable der Major-1-Linie ab 1.0.0 für den Zielpfad. Aufrufer benötigen EXECUTE auf die öffentliche USP, beim Zielpfad zusätzlich Helper-EXECUTE; keine automatische Rechtevergabe.

Keine Rechteckauffüllung, Shared-Formula-Rekonstruktion oder Berechnung, Styles-/Datums-/Culture-/Anzeigeformatierung oder fachliche Typinferenz. Unterstützt sind Transitional XLSX und kanonische Stored-/Deflate-Parts; ausgeschlossene Varianten und Memory-/Budgetaussagegrenzen stehen in [README](../README.md). Keine File-/Netzwerk-/SDK-/Workerfallbacks, Streaming-, copy-free-, Gesamtpeak- oder SQL-Memory-Grant-Zusage.

Explizite Zeilen-/Zellkoordinaten sind erforderlich; der Reader ersetzt keine vollständige XSD-Validierung. Das zusätzliche interne 128-MiB-Chargebudget zählt jedes ausgewählte String-Ausgabefeld mit vier Bytes je UTF-16-Codeeinheit, wiederholte Shared Strings und identische Raw-/Cachefelder erneut. Die atomare Kategorie `TBX_XLSX_COUNTED_ALLOCATION_LIMIT` kann deshalb trotz eingehaltenen Einzelcaps auftreten. Diese Zählgrenze ist kein Gesamtpeak. Das kooperative 5000-ms-Budget garantiert keine SQL-Marshalling- oder Gesamtwallclock-Grenze.

## Synthetisches Beispiel

```sql
EXEC toolbelt_file.USP_ReadXlsxWorksheetCells @Hilfe = 1;
-- @SyntheticWorkbook stammt ausschließlich aus einem synthetischen Testfixture.
EXEC toolbelt_file.USP_ReadXlsxWorksheetCells @XlsxBinary = @SyntheticWorkbook, @SheetOrdinal = 1;
```
