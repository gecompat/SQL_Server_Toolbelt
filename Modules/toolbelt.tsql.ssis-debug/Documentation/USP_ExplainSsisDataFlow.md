# toolbelt_tsql.USP_ExplainSsisDataFlow

Die Prozedur akzeptiert DTSX als `varbinary(max)`. Zuerst wird eine Vorlage
erzeugt, anschließend dasselbe JSON-Dokument mit geänderten Einträgen unter
`values` zurückgegeben. `availableInputs` und die Paket-/Kontexthashes bleiben
unverändert. Sensitive Eingaben werden nicht exportiert.

Das [vollständige SSMS-Beispiel](../Examples/README.md) enthält ein
[ausführliches SQL-Script](../Examples/SsmsDebugWalkthrough.sql) mit Demodaten,
Paketimport, JSON-Änderung, gezielt angeforderter Einzelstufe und direkter
DECLARE-Bearbeitung. Es verwendet die vorhandene synthetische DTSX-Fixture.

Die [vollständige lokale Installationsanleitung](../Examples/Installation/README.md)
führt durch Servervorbereitung, Parser-/ResultTable-Installation, exakten
Assembly-Trust und Kontrolle vor dem SSMS-Walkthrough. SQL- und PowerShell-
Skripte sind dort getrennt verlinkt.

```sql
-- @PackageBytes wird vom Client übergeben; keine Dateizugriffe im CLR-Provider.
EXEC toolbelt_tsql.USP_ExplainSsisDataFlow
    @PackageBytes = @PackageBytes,
    @Operation = 'bindings-template';

-- @Bindings enthält das vollständige zurückgegebene JSON-Dokument.
EXEC toolbelt_tsql.USP_ExplainSsisDataFlow
    @PackageBytes = @PackageBytes,
    @Bindings = @Bindings,
    @CatalogBindings = N'{"schemaVersion":1,"defaultDatabase":"AdventureWorks",
      "databases":["AdventureWorks"],
      "connections":{"Package.ConnectionManagers[Synthetic]":"AdventureWorks"}}',
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
Vorbereitung, StageSql, TargetSql, Cleanup, ColumnLineage und Diagnose.
`IsComplete`, `SafetyStatus`, `IsExecutable` und `EvidenceClass` gelten pro
Artefakt. Ein ausführbares Script wird als vollständiger Batch in einer
SSMS-Sitzung im angegebenen `defaultDatabase` ausgeführt. Es gibt kein `GO`
zwischen `DECLARE`, Cachevorbereitung, `WITH` und `SELECT`.

Im aktuellen Profil können zusätzlich `PlanManifest`, `PlanUnitSql` und `RowCountSql`
entstehen. Den gewünschten Plan über seinen `planHash` auswählen, dessen
`PlanUnitSql`-Batches in der Manifestreihenfolge genau einmal in derselben
SQL-Sitzung ausführen und danach die zugehörige Stufen-/Zielprojektion oder
Zählabfrage lesen. Eine Zielabfrage vor vollständiger Vorbereitung wird
abgewiesen. Die einzelnen Batches bleiben getrennte Prüfeinheiten; sie werden
nicht zu einem großen SQL-Batch zusammengesetzt. Die zugehörigen
`CleanupSql`-Batches anschließend auch bei teilweiser Vorbereitung in ihrer
ausgewiesenen Reihenfolge ausführen. Fremde oder veränderte Zustände verhindern
deren Bereinigung.

Der `StageIndex` liefert die stabilen Ziel-/Stufen-IDs. Eine konkrete
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
