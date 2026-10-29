# Aktuellen SSIS-Debug-Stand installieren und verwenden

Dieser Entwicklungsstand ist unveröffentlicht. Er verwendet den aktuellen
Komponentenumfang ohne Versionsschalter. Historische V1-/V2-Dateien sind keine
Lieferung dieses API-Standards. Der fachliche Vertrag steht in
[SSIS_CURRENT_API_CONTRACT.md](../../../Documentation/Architecture/SSIS_CURRENT_API_CONTRACT.md).

## Installation

Der aktuelle reine T-SQL-Installer heißt
[`SSIS-INSTALL-TSQL-CURRENT.sql`](../../../Releases/1.0.0/SSIS-INSTALL-TSQL-CURRENT.sql).
Er enthält die drei benötigten DLLs und die abhängigen SQL-Objekte; zur
Ausführung sind weder SQLCMD noch weitere Dateien erforderlich. Die Datei in
einer frischen Sitzung in der gewünschten Datenbank vollständig ausführen.
Die Einstellungen am Dateianfang wählen den lokalen oder zentralen Modus.
Die enthaltenen Trust-, Eigentums-, Transaktions- und Sitzungsprüfungen gelten
auch hier. Zusätzliche Serverrechte werden nicht automatisch vergeben.

Alternativ enthält das
[aktuelle ZIP](../InstallPackages/SSIS-Debug-Current-Install-Windows.zip)
Artefakte, Quellen, Lizenztexte und gebundene Qualifikationsnachweise.
Neuinstallation und Wiederholung desselben aktuellen Stands werden getrennt
geprüft. Eine ältere inkompatible Entwicklungsinstallation muss vor der
Neuinstallation kontrolliert entfernt werden; der Installer darf keine fremden
Objekte übernehmen. Die historischen Installer bleiben unverändert erhalten.

## Parameter ermitteln, bearbeiten und zurückgeben

`@PackageBytes` ist der Binärinhalt genau eines unterstützten DTSX-Pakets.
Die Prozedur liest selbst keine Datei. Auch ein bereits vorhandener
`nvarchar(max)`-XML-Wert kann mit `CONVERT(varbinary(max), @PackageXml)`
übergeben werden.

```sql
-- @PackageBytes enthält das zu untersuchende Paket.
CREATE TABLE #Bindings(Placeholder int);
EXEC toolbelt_tsql.USP_ExplainSsisDataFlow
    @PackageBytes = @PackageBytes,
    @Operation = 'bindings-template',
    @ResultTable = '#Bindings';

DECLARE @Bindings nvarchar(max) =
    (SELECT Content FROM #Bindings WHERE ArtifactKind = 'BindingsTemplate');
SELECT @Bindings AS EditierbareVorlage;

SELECT [key], [name], sqlType, defaultAvailable, defaultValue,
       valueOrigin, assignmentState
FROM OPENJSON(@Bindings, '$.availableInputs') WITH (
    [key] nvarchar(128), [name] nvarchar(512), sqlType nvarchar(128),
    defaultAvailable bit, defaultValue nvarchar(max),
    valueOrigin nvarchar(128), assignmentState nvarchar(128)
);
```

Die vollständige JSON-Vorlage enthält `availableInputs` und editierbare
`values`. Vorhandene nicht sensitive Entwurfswerte werden mit Herkunft
ausgewiesen. Sie sind keine Messung tatsächlicher Laufzeitwerte. Ausdrücke,
bekannte Zuweisungen und unbekannte Schreibeffekte bleiben erkennbar. Fehlende
Werte werden nicht erfunden; sensitive Werte werden nicht vorbelegt.

Nur `values` bearbeiten und anschließend die **vollständige Vorlage** als
`@Bindings` übergeben. Ein numerischer Wert muss auch im JSON numerisch bleiben;
Boolean, Zeichenfolge und `null` entsprechend ihrem ausgewiesenen Typ setzen.
Paket-/Kontextbindung und Eingabemetadaten unverändert lassen. Wird ein anderer
`@ProjectContext` verwendet, dafür eine neue Vorlage erzeugen.

```sql
-- Beispiel nach Auswahl eines tatsächlichen Schlüssels aus availableInputs:
-- SET @Bindings = JSON_MODIFY(@Bindings, '$.values."<ausgegebener Schlüssel>"', 123);
CREATE TABLE #Explain(Placeholder int);
EXEC toolbelt_tsql.USP_ExplainSsisDataFlow
    @PackageBytes = @PackageBytes,
    @Bindings = @Bindings,
    @CatalogBindings = @CatalogBindings,
    @ResultTable = '#Explain';

SELECT TargetFlowId, IsComplete, IsExecutable, Content, DetailsJson
FROM #Explain
WHERE ArtifactKind = 'DebugScript'
ORDER BY Ordinal;
```

`@CatalogBindings` ist die ausdrücklich erlaubte Zuordnung der Paketverbindungen
zu Datenbanken derselben Instanz. Sie enthält keine Zugangsdaten und wird nicht
aus einer fremden Umgebung übernommen. Die Felder und Flatfile-Zuordnungen sind
in der [Prozedurbeschreibung](USP_ExplainSsisDataFlow.md) erklärt. Ohne benötigte
Zuordnung bleibt der betroffene Pfad als unvollständig gekennzeichnet.

## Debug-SQL und fehlende Werte

`DebugScript.Content` enthält für ein vollständig auflösbares Ziel die geordnete
Vorbereitung, Planeinheiten, Ziel-/Row-Count-Projektion und Bereinigung. Das
Script verwendet `GO` zwischen den Batches und läuft in einer frischen Sitzung
auf der ausdrücklich zugeordneten Instanz. Bei einem Vorbereitungsfehler keine
Ergebnisbatches ausführen; die zugehörigen `CleanupSql`-Batches in derselben
Sitzung verwenden. Es gibt keine globale Atomaritätszusage.

`Workflow`, `StageIndex` und `ColumnLineage` zeigen Ablauf, Vorgänger und
Spaltenherkunft; `PreparationSql`, `PlanUnitSql`, `TargetSql`, `RowCountSql` und
`CleanupSql` bleiben einzeln verfügbar. Die Analyse führt dieses SQL nicht aus.
Das erzeugte Debug-SQL liest ausschließlich die explizit zugeordneten Quellen;
Flatfile-Ziele werden als lesende Projektion dargestellt, keine Datei wird
geschrieben und kein SSIS-Task gestartet.

Bei einem unvollständigen Ziel enthält `DebugScript.DetailsJson` den gesamten
Strukturpfad, die Erstursache, fehlende Eingabeschlüssel und verfügbare Teilpläne.
`IsExecutable = 0` ist verbindlich. Ein fehlender Command-Text muss als
Debugwert bereitgestellt werden; die Analyse kann unbekannten Laufzeitcode
nicht zuverlässig erfinden.

## Grenzen direkt als SQL-Parameter

Für Limits gibt es **keine JSON-Konfiguration**. `@MaxPackageBytes`,
`@MaxComponents` und die weiteren in `@Hilfe = 1` aufgeführten `@Max`-Parameter
sind benannte `bigint`-Parameter. Positiv setzt die jeweilige Obergrenze,
`0` öffnet diesen konfigurierbaren Zähler nach oben; `NULL` und negative Werte
werden abgewiesen. Die Analysezeit ist standardmäßig offen. Caller-Timeouts und
feste Parser-, Tiefen-, Sicherheits- und Ownershipgrenzen bleiben wirksam.

```sql
EXEC toolbelt_tsql.USP_ExplainSsisDataFlow
    @PackageBytes = @PackageBytes,
    @Bindings = @Bindings,
    @CatalogBindings = @CatalogBindings,
    @MaxComponents = 0,
    @MaxPackageBytes = 0;

EXEC toolbelt_tsql.USP_ExplainSsisDataFlow @Hilfe = 1;
```

Die konkrete qualifizierte Plattform-/CL-/Modusauswahl sowie verbleibende
Analysegrenzen stehen in der [Prüfmatrix](../Tests/README.md). Funktionale
Labprüfungen belegen keine authentifizierte TLS-Verbindung, tatsächliche
SSIS-Paketausführung oder Veröffentlichungsfreigabe.
