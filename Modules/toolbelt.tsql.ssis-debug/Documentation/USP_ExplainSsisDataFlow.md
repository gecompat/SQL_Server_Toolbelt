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

Die erste Spalte `ArtifactKind` unterscheidet Vorlage, Workflow, StageIndex,
Vorbereitung, StageSql, TargetSql, Cleanup, ColumnLineage und Diagnose.
`IsComplete`, `SafetyStatus`, `IsExecutable` und `EvidenceClass` gelten pro
Artefakt. Ein ausführbares Script wird als vollständiger Batch in einer
SSMS-Sitzung im angegebenen `defaultDatabase` ausgeführt. Es gibt kein `GO`
zwischen `DECLARE`, Cachevorbereitung, `WITH` und `SELECT`.

Der `StageIndex` liefert die stabilen Ziel-/Stufen-IDs. Eine konkrete
`@InspectStage` verlangt `@TargetFlow`; `all` liefert die unterstützten
Vorgängerstufen. Jede Stufe enthält ihre eigene vollständige CTE-Kette.
Zwischenergebnisse werden durch den SQL Server erneut ausgewertet;
Lookupauswahlen bleiben bis zur relevanten Werteänderung oder Cleanup erhalten.

`@ProjectContext` beschreibt Projektparameter und Projektconnections.
`@LookupPolicies` bestimmt optional eine fachliche Referenzsortierung;
ohne diese ist die Trefferauswahl ausdrücklich beliebig. Die vollständigen
JSON-Schemata, Fehlercodes und Grenzen stehen im
[V1-Vertrag](../../../Documentation/Architecture/SSIS_DTSX_DEBUG_SELECT_V1_CONTRACT.md).
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
