# toolbelt_tsql.USP_ExplainSsisDataFlow

Die Prozedur akzeptiert DTSX als `varbinary(max)`. Zuerst wird eine Vorlage
erzeugt, anschließend dasselbe JSON-Dokument mit geänderten Einträgen unter
`values` zurückgegeben. `availableInputs` und die Paket-/Kontexthashes bleiben
unverändert. Sensitive Eingaben werden nicht exportiert.

Die [aktuelle Anleitung mit SQL-Beispielen](CurrentInstallation.md) zeigt,
wie die Vorlage über `@ResultTable` übernommen, unter `values` bearbeitet und
als `@Bindings` zurückgegeben wird. Dort steht auch die Abfrage für das
vollständige `DebugScript`. Der ältere
[synthetische SSMS-Walkthrough](../Examples/README.md) bleibt ein ausdrücklich
historisches Beispiel seines ursprünglichen Builds und ersetzt diese Anleitung
nicht.

Die [vollständige lokale Installationsanleitung](../Examples/Installation/README.md)
führt durch Servervorbereitung, Parser-/ResultTable-Installation, exakten
Assembly-Trust und Kontrolle vor dem SSMS-Walkthrough. SQL- und PowerShell-
Skripte sind dort getrennt verlinkt.
Der aktuelle unveröffentlichte T-SQL-Installer und das zugehörige aktuelle ZIP
sind in der [Installationsanleitung für den aktuellen Entwicklungsstand](CurrentInstallation.md)
beschrieben; historische Installationsbytes bleiben dort getrennt.

```sql
-- @PackageBytes wird vom Client übergeben; keine Dateizugriffe im CLR-Provider.
EXEC toolbelt_tsql.USP_ExplainSsisDataFlow
    @PackageBytes = @PackageBytes,
    @Operation = 'bindings-template';

-- @Bindings enthält das vollständige zurückgegebene JSON-Dokument.
EXEC toolbelt_tsql.USP_ExplainSsisDataFlow
    @PackageBytes = @PackageBytes,
    @Bindings = @Bindings,
    @CatalogBindings = N'{"schemaVersion":2,"defaultDatabase":"AdventureWorks",
      "databases":["AdventureWorks"],
      "connections":{"Package.ConnectionManagers[Synthetic]":"AdventureWorks"},
      "flatFileInputs":{}}',
    @InspectStage = 'all';
```

`bindings-template` und `explain` verwenden unmittelbar den aktuellen
Komponentenumfang. Die Vorlage enthält `schemaVersion: 2` und
`profile: "ssis-debug-components-v2"`; ein `-v2`-Operationsalias oder ein
Opt-in über `ProjectContext` ist nicht erforderlich. Gib dieselbe Vorlage
unter `@Bindings` zurück und bearbeite nur `values`. Nicht-sensitive
Designdefaults sind editierbar vorbelegt. `availableInputs` kennzeichnet
Ausdrucks- und Laufzeitherkunft; diese Angaben belegen keinen ausgeführten
SSIS-Lauf. Sensitive Werte bleiben redigiert.

Ressourcenlimits werden ausschließlich über die 24 benannten `bigint`-
Parameter gesetzt. Jeder Grenzwert hat einen dokumentierten Standardwert;
positive Werte setzen eine Obergrenze und `0` bedeutet für diesen Zähler
unbegrenzt. `NULL` und negative Werte liefern einen verständlichen
Parameterfehler. Die vollständige Parametertabelle steht im
[aktuellen API-Vertrag](../../../Documentation/Architecture/SSIS_CURRENT_API_CONTRACT.md)
und in `@Hilfe=1`. Ressourcenoptionen im `ProjectContext` oder als bearbeitbarer
Teil der Vorlage werden abgewiesen. Ressourcenmetadaten im Workflow sind
schreibgeschützte Ergebnisdetails.

Beispiel für ein unbegrenztes Ausdrucksbudget:

```sql
EXEC toolbelt_tsql.USP_ExplainSsisDataFlow
    @PackageBytes = @PackageBytes,
    @MaxExpressionBytes = 0;
```

Die erste Spalte `ArtifactKind` unterscheidet Vorlage, Workflow, StageIndex,
Vorbereitung, StageSql, PlanManifest, PlanUnitSql, TargetSql, RowCountSql,
Cleanup, DebugScript, FlatFileWriteProjection, ColumnLineage und Diagnose.
`IsComplete`, `SafetyStatus`, `IsExecutable` und `EvidenceClass` gelten pro
Artefakt. Einzelne SQL-Artefakte werden jeweils vollständig in einer
SSMS-Sitzung im angegebenen `defaultDatabase` ausgeführt. Innerhalb eines
einzelnen Batches kein `GO` zwischen zusammengehörige Statements einfügen.
Das vollständige `DebugScript` enthält dagegen mehrere geordnete Batches.

Im aktuellen Profil können zusätzlich `PlanManifest`, `PlanUnitSql` und `RowCountSql`
entstehen. Bei vollständigem Pfad bündelt `DebugScript` genau den gebundenen
Plan: vorbereitete Einheiten in Manifestreihenfolge, Zielprojektion, Zählabfragen
für denselben Snapshot und anschließend Cleanup. `GO` trennt SSMS-Batches;
das Script behauptet keine globale Atomarität. Die Einzelartefakte bleiben
separat verfügbar und einzeln sicherheitsgeprüft. Fremde oder veränderte
Zustände verhindern die Bereinigung. Ein unvollständiges `DebugScript` ist
nicht ausführbar und verweist auf Erstursache, benötigte Werte und verfügbare
vollständige Teilpläne.

Der `StageIndex` liefert den vollständigen Zielpfad einschließlich Eltern,
blockiertem Status und Erstursache. Eine Kaskadenmeldung bewahrt den ursprünglichen
Blocker, statt nur eine nachgelagerte Stufennummer zu nennen. Eine konkrete
`@InspectStage` verlangt `@TargetFlow`; `all` liefert die unterstützten
Vorgängerstufen. Jede Stufe enthält ihre eigene vollständige CTE-Kette.
Zwischenergebnisse werden durch den SQL Server erneut ausgewertet;
Lookupauswahlen bleiben bis zur relevanten Werteänderung oder Cleanup erhalten.

`@ProjectContext` beschreibt Projektparameter und Projektconnections.
`@LookupPolicies` bestimmt optional eine fachliche Referenzsortierung;
ohne diese ist die Trefferauswahl ausdrücklich beliebig. Die vollständigen
JSON-Schemata, Fehlercodes und Grenzen stehen im
[aktuellen API-Vertrag](../../../Documentation/Architecture/SSIS_CURRENT_API_CONTRACT.md)
und im [Komponentenvertrag](../../../Documentation/Architecture/SSIS_COMPONENTS_V2_CONTRACT.md).
Die geordnete maschinenlesbare API liegt in [Contracts/Api.json](../Contracts/Api.json).

SQL-Ausdruckstypen werden in einem endlichen Profil abgeleitet. Unbelegte
Rückgabetypen verlangen einen expliziten CAST oder blockieren die Stufe.
Das gilt insbesondere für dezimales CEILING/FLOOR bis zur nativen
Versionsqualifikation sowie für nicht nationale Nicht-ASCII-Literale ohne
belegte Bytebindung. Die zugrunde gelegten
[Präzisions-/Längenregeln](https://learn.microsoft.com/en-us/sql/t-sql/data-types/precision-scale-and-length-transact-sql),
[AVG-Rückgabetypen](https://learn.microsoft.com/en-us/sql/t-sql/functions/avg-transact-sql)
und [LEN-Rückgabetypen](https://learn.microsoft.com/en-us/sql/t-sql/functions/len-transact-sql)
stammen aus Microsofts Typverträgen. Inline-TVFs mit versteckten
Tabellenlesezugriffen werden mit `hint_not_supported` blockiert, wenn der
NOLOCK-Hint ohne persistente Definitionsänderung nicht durchsetzbar ist.
`DetailsJson.catalogBinding` enthält die lokale Objekt-/Definitionsbindung
des Analyseaufrufs; sie ist keine Sperre gegen spätere DDL.

`@Hilfe=1` liefert vor jeder fachlichen Validierung die Standardhilfe.
`@ResultTable` akzeptiert eine bereits vorhandene lokale Temp-Tabelle;
`@KeepData` folgt dem kanonischen ResultTable-Vertrag. Fehler liefern 50000
mit `TBX_SSISDBG_` und ohne vertrauliche Quellfehlermeldungen.

## Vollständiger Eingabevertrag

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@PackageBytes` | `varbinary(max)` | `NULL` | Input | Genau ein vollständiges DTSX-XML-Paket als UTF-8-/UTF-16-Bytepuffer varbinary(max), kein Pfad/Base64-/XML-Stringparameter. DTSX-Formatprofile PackageFormatVersion 6 oder 8 werden unterstützt; kein verschlüsselter Container, DTD, externer Resolver oder XInclude. Leer/NULL ungültig, NULL ist nur technischer Help-Default. MaxPackageBytes begrenzt die Rohbytes; XML-Tiefe bleibt absolut 128. Paket/enthaltenes SQL werden beim Analysieren nicht ausgeführt. |
| `@Operation` | `varchar(32)` | `N'explain'` | Input | Taxativ, ordinal/case- und whitespace-sensitiv: explain (Default) analysiert die gebundenen Datenflüsse und erzeugt Workflow, Stufenverzeichnis, Debug-SQL und Diagnosen; bindings-template erzeugt ausschließlich die paket-/kontextgebundene Schema-2-Eingabevorlage zum Bearbeiten unter values. Template verlangt Bindings=NULL und CatalogBindings=NULL. Kein -v2-Alias, kein Opt-in; NULL/leer/andere Schreibweisen ungültig. |
| `@ProjectContext` | `nvarchar(max)` | `NULL` | Input | NULL (Default) bedeutet leeren Schema-2-Projektkontext. Sonst JSON-Objekt {"schemaVersion":2,"projectParameters":[...],"connectionManagers":[...]}; beide Arrays optional. Parameterentry: name, ssisType sowie optional designValue, required und sensitive (JSON-Booleans); Connectionentry: refId, name, provider. Provider taxativ sqlserver-oledb oder sqlserver-adonet, beide ordnen vorhandene SQL-Server-Connections zu; keine Connectionstrings/Credentials. Eindeutige Namen/refIds, Projektconnections dürfen Paketconnections nicht überlagern. Typ-/Wertabbildung im Abschnitt SSIS-Eingabetypen der Objektreferenz; unbekannte Typen sind nicht bindbar. Andere Rootkeys, resourceOptions und schemaVersion ungleich 2 ungültig. Feste Kontrollprotokollgrenze 4194304 UTF-16-Bytes zusätzlich zu den gewählten JSON-Limits; beim Zurückgeben der Bindings denselben Kontext verwenden. |
| `@Bindings` | `nvarchar(max)` | `NULL` | Input | NULL (Default) verwendet vorhandene nicht sensitive Designdefaults; benötigte fehlende Laufzeitwerte bleiben als fehlender Kontext sichtbar. Sonst vollständiges von bindings-template zurückgegebenes JSON-Objekt mit schemaVersion=2, profile exakt ssis-debug-components-v2, packageSha256, contextSha256, availableInputs und values. Ausschließlich values nach generierten Eingabekeys bearbeiten; Paket-/Kontexthashes und vollständige Herkunftsmetadaten unverändert zurückgeben. values ist ein Objekt typisierter JSON-Werte: Stringtexte/ISO-Datum/-GUID/-Hex, JSON-Boolean für bit, exakte Zahlen gemäß SSIS-Eingabetypen; JSON-null als SQL-NULL, keine SQL-Ausdrücke. Sensitive/ unbekannte/nicht bindbare Keys abgewiesen. Im Template-Modus ausschließlich NULL; kein leeres Ersatzobjekt und keine Ressourcenoptionen. |
| `@CatalogBindings` | `nvarchar(max)` | `NULL` | Input | NULL (Default) liefert keine explizite Katalogzuordnung; fehlende erforderliche Bindungen bleiben missing_context. Sonst JSON-Objekt mit schemaVersion 1 oder 2, defaultDatabase als Name, databases als Array eindeutiger erlaubter Same-instance-Datenbanknamen und connections als Objekt {importierteConnectionId:Datenbankname}. Default und jede Zuordnung müssen in databases stehen; Connection-IDs müssen im Paket/Projektkontext vorhanden sein. Version 1 erlaubt nur diese Felder; Version 2 ergänzt flatFileInputs als Objekt (auch {}). Je Flatfileentry: database, schema, object, columns als Mapping importierter Spalten-IDs zu SQL-Spaltennamen; optional rowOrdinalColumn und errorRows als entsprechender Quellobjekt-/Spaltenbeschreiber gemäß Komponentenvertrag. Keine freien SQL-Fragmente, Server-/Credential-/Dateipfade oder automatische Rechte. Template-Modus verlangt NULL; leer/andere Shapes ungültig. |
| `@TargetFlow` | `varchar(64)` | `NULL` | Input | NULL (Default) berücksichtigt alle erkannten Zielflüsse getrennt. Sonst exakte modellinterne TargetFlowId aus der Workflow-/StageIndex-Ausgabe desselben Pakets, maximal varchar(64); keine frei gewählte Komponentenbezeichnung oder dauerhafte Projekt-ID. Groß-/Kleinschreibung/Whitespace werden nicht normalisiert; unbekannt/leer ungültig im Explain-Pfad. |
| `@InspectStage` | `varchar(64)` | `NULL` | Input | Taxativ für Steuerwerte: NULL (Default) liefert Zielskript/Stufenverzeichnis ohne zusätzliche StageSql-Auswahl; all liefert die unterstützten Vorgängerstufen jedes gewählten Ziels. Alternativ eine exakte StageId aus dem StageIndex desselben Pakets; dann ist TargetFlow fachlich erforderlich und die Stufe muss zu dessen Vorgängerpfad gehören. all benötigt keinen expliziten TargetFlow. Kein Trim/Casefold; unbekannte/leere konkrete ID ungültig. |
| `@LookupPolicies` | `nvarchar(max)` | `NULL` | Input | NULL (Default) bedeutet beliebige, pro relevantem Snapshot einmal materialisierte Trefferauswahl. Sonst exakt JSON-Objekt {"schemaVersion":1,"lookups":{"&lt;Lookup-Komponenten-ID&gt;":{"orderBy":[{"column":"&lt;Referenzspalte&gt;","direction":"asc"}]}}}. IDs müssen existierende Lookupkomponenten adressieren, orderBy nicht leer und ohne doppelte Spalten. direction taxativ asc = aufsteigend oder desc = absteigend, exakt kleingeschrieben. Keine freien ORDER-BY-Ausdrücke; vollständige Sortierbindung erforderlich, Gleichstände erhalten keine erfundene Eindeutigkeit. |
| `@ComparisonCollation` | `sysname` | `NULL` | Input | NULL (Default) verwendet bei Katalogbindung die Collation der expliziten defaultDatabase. Sonst genau ein tatsächlich vom Server unterstützter Collationname als sysname, kein COLLATE-SQL-Fragment; Prüfung gegen sys.fn_helpcollations. Dynamische Serverwertemenge, kein festes erfundenes Inventar: SELECT name FROM sys.fn_helpcollations() zeigt sie. Dient Vergleichs-/Ausdrucksbindung und ändert keine DB-/Spaltencollation; leer/unbekannt ungültig. |
| `@TSqlVersion` | `smallint` | `150` | Input | Taxativ: 150 = SQL-Server-2019-Grammatik (Default), 160 = 2022, 170 = 2025 für die Parser-/Sicherheitsprüfung erzeugten SQLs. Kein automatischer Dialektwechsel/Ablesen der Engineversion. NULL/andere smallint-Werte ungültig. |
| `@MaxPackageBytes` | `bigint` | `134217728` | Input | bigint 0..9223372036854775807, Default 134217728: Rohbytes des DTSX-Pakets. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxXmlCharacters` | `bigint` | `134217728` | Input | bigint 0..9223372036854775807, Default 134217728: vom XML-Reader gezählte Zeichen des Pakets. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxXmlNodes` | `bigint` | `1048576` | Input | bigint 0..9223372036854775807, Default 1048576: gelesene XML-Knoten. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxModelNodes` | `bigint` | `262144` | Input | bigint 0..9223372036854775807, Default 262144: Knoten des importierten Modells. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxModelEdges` | `bigint` | `1048576` | Input | bigint 0..9223372036854775807, Default 1048576: Kanten des importierten Modells. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxComponents` | `bigint` | `4096` | Input | bigint 0..9223372036854775807, Default 4096: SSIS-Komponenten. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxPaths` | `bigint` | `8192` | Input | bigint 0..9223372036854775807, Default 8192: Datenflusskanten/Pfade. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxColumns` | `bigint` | `65536` | Input | bigint 0..9223372036854775807, Default 65536: importierte Spaltenmetadaten. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxInputs` | `bigint` | `8192` | Input | bigint 0..9223372036854775807, Default 8192: entdeckte/gebundene Eingaben. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxJsonDocumentBytes` | `bigint` | `4194304` | Input | bigint 0..9223372036854775807, Default 4194304: UTF-16-Bytes je JSON-Eingabedokument; ProjectContext behält zusätzlich das feste Kontrollprotokolllimit. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxAllJsonBytes` | `bigint` | `8388608` | Input | bigint 0..9223372036854775807, Default 8388608: Summe der UTF-16-Bytes von Bindings, CatalogBindings und LookupPolicies, ohne ProjectContext. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxJsonNodes` | `bigint` | `131072` | Input | bigint 0..9223372036854775807, Default 131072: Knoten je begrenzt geparstem JSON-Dokument. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxExpressionBytes` | `bigint` | `4194304` | Input | bigint 0..9223372036854775807, Default 4194304: UTF-16-Bytes eines SSIS-Ausdrucks. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxExpressionTokens` | `bigint` | `262144` | Input | bigint 0..9223372036854775807, Default 262144: Tokens eines SSIS-Ausdrucks. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxExpressionNodes` | `bigint` | `131072` | Input | bigint 0..9223372036854775807, Default 131072: Knoten eines SSIS-Ausdrucks. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxPlanUnits` | `bigint` | `8192` | Input | bigint 0..9223372036854775807, Default 8192: geprüfte Debugplaneinheiten. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxCatalogObjects` | `bigint` | `4096` | Input | bigint 0..9223372036854775807, Default 4096: gebundene Katalogobjekte. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxCatalogQueries` | `bigint` | `4096` | Input | bigint 0..9223372036854775807, Default 4096: Katalogabfragen. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxParserCalls` | `bigint` | `32768` | Input | bigint 0..9223372036854775807, Default 32768: SQL-Parser-/Sicherheitsprüfaufrufe. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxArtifacts` | `bigint` | `65536` | Input | bigint 0..9223372036854775807, Default 65536: erzeugte Ergebnisartefakte. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxDiagnostics` | `bigint` | `16384` | Input | bigint 0..9223372036854775807, Default 16384: erzeugte Diagnosen. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxSqlArtifactBytes` | `bigint` | `2097152` | Input | bigint 0..9223372036854775807, Default 2097152: UTF-16-Bytes je erzeugtem SQL-Artefakt. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxTotalOutputBytes` | `bigint` | `134217728` | Input | bigint 0..9223372036854775807, Default 134217728: UTF-16-Bytes der gezählten Gesamtausgabe. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxAnalysisMilliseconds` | `bigint` | `0` | Input | bigint 0..9223372036854775807, Default 0: Millisekunden kooperatives Analysezeitbudget, keine harte Gesamtwallclock-Garantie. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Name 2..116 UTF-16-Einheiten; der vollständige Artefaktsatz wird vor Zielmutation erzeugt. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255, Default 0; NULL wirkt wie 0. 0 still, 1..255 eine redigierte Abschlussmessage mit Artefakt-/SQL-Prüfeinheitenzählern. Kein zusätzliches Resultset und keine Quell-/Secretwerte; der interne ResultTable-Helper wird ausdrücklich mit Debug=0 aufgerufen. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |
<!-- API_PARAMETERS:END -->


## SSIS-Eingabetypen

`ProjectContext.projectParameters[].ssisType` verwendet folgende vollständige
Menge unterstützter Typnamen/Aliase. Typnamen werden invariant kleingeschrieben,
aber nicht getrimmt. Zahlencodes sind Strings wie `"3"`, keine JSON-Zahlen.
`values` und `designValue` enthalten Daten, niemals SQL-Ausdrücke. Die gewählte
SQL-Deklaration steht auch in `availableInputs[].sqlType`.

| `ssisType` – alle unterstützten Aliase | SQL-Abbildung und Datenform |
|---|---|
| `11`, `boolean`, `bool` | `bit`; JSON `true`/`false`, kein String `"true"` und keine Zahl `1`. |
| `16`, `sbyte`, `i1` | `smallint` mit zusätzlicher SByte-Grenze -128..127; Ganzzahl. |
| `2`, `int16`, `i2` | `smallint`; Ganzzahl -32768..32767. |
| `17`, `byte`, `ui1` | `tinyint`; Ganzzahl 0..255. |
| `18`, `uint16`, `ui2` | `int` mit zusätzlicher UInt16-Grenze 0..65535. |
| `3`, `int32`, `i4` | `int`; Ganzzahl -2147483648..2147483647. |
| `19`, `uint32`, `ui4` | `bigint` mit zusätzlicher UInt32-Grenze 0..4294967295. |
| `20`, `int64`, `i8` | `bigint`; vollständiger vorzeichenbehafteter 64-Bit-Bereich, große exakte Werte als Dezimalstring. |
| `21`, `uint64`, `ui8` | `decimal(20,0)` mit UInt64-Grenze 0..18446744073709551615; große Werte als String. |
| `4`, `single`, `r4` | `real`; endlicher numerischer Wert, auch Exponentform, keine NaN-/Infinity-Literale. |
| `5`, `double`, `r8` | `float(53)`; endlicher numerischer Wert, auch Exponentform. |
| `6`, `currency`, `cy` | `decimal(19,4)`; exakter Dezimalstring ohne Exponent, höchstens 15 Ganzzahl- und vier Nachkommastellen. |
| `14`, `decimal`, `numeric` | `decimal(p,s)` gemäß Paketmetadaten; ohne diese `decimal(38,18)`. Exakter Dezimalstring ohne Exponent; keine gerundete JSON-Zahl. |
| `8`, `string`, `wstr` | `nvarchar(n)` bei bekannter Länge 1..4000, sonst `nvarchar(max)`; JSON-String. Im Projektkontext ohne zusätzliche Längenfelder entsteht `max`. |
| `str` | `varchar(n)` bei bekannter Länge 1..8000, sonst `varchar(max)`. Der aktuelle Literalbinder besitzt dafür keinen allgemeinen Textliteralpfad; der Typname allein erlaubt keinen frei bindbaren JSON-String. |
| `7`, `datetime`, `date`, `dbtimestamp` | `datetime2(7)`; ISO-String `YYYY-MM-DDTHH:mm:ss` mit optional bis zu sieben Nachkommastellen. Der Alias `date` bezeichnet hier ebenfalls `datetime2(7)`. |
| `dbtimestamp2` | `datetime2(s)` gemäß Metadaten, s=0..7; ISO-String ohne Präzisionsverlust. |
| `dbdate` | `date`; ISO-String `YYYY-MM-DD`. |
| `dbtime` | `time(0)`; String `HH:mm:ss`. |
| `dbtime2` | `time(s)` gemäß Metadaten, s=0..7; String `HH:mm:ss` mit passenden Nachkommastellen. |
| `72`, `guid` | `uniqueidentifier`; String in Form `00000000-0000-0000-0000-000000000001`, ohne Klammern. |
| `bytes` | `varbinary(n)` bei bekannter Länge 1..8000, sonst `varbinary(max)`; String `"0x"` mit null oder mehr vollständigen Hexbytepaaren. Kein Base64. |

Numerische Eingaben verwenden die ASCII-JSON-Zahlengrammatik ohne führendes
Plus, Randspaces oder führende Nullen. Native JSON-Zahlen für exakte
Ganzzahltypen sind zusätzlich auf ±9007199254740991 beschränkt; außerhalb
davon Strings verwenden. Exakte Decimaltypen verlangen grundsätzlich Strings;
UInt64 besitzt den oben beschriebenen Sonderpfad. Datum/Zeit akzeptiert weder
`Z` noch Offsets; Nachkommastellen über der deklarierten Skala sind nur mit
abschließenden Nullen zulässig. JSON `null` erzeugt ein SQL-NULL-Literal,
berechtigt aber nicht zum Binden sensitiver oder nicht unterstützter Keys.

Die Regeln folgen dem gemeinsamen Literalbinder
[`Types.Sql`/`Types.Literal`](../Clr/PackageModel.cs), keiner allgemeinen
SQL-`CAST`-Konvertierung. Nicht unterstützte Typen bleiben nicht bindbar;
ein Typname belegt noch keinen vollständig übersetzbaren Komponentenpfad.

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#ssis).
