/*
SSIS-Debug V1: vollständiges SSMS-Beispiel mit synthetischen Daten.
Vertrag/API: PR #324, Merge-Commit 571e46e.

Voraussetzungen:
  - Eigene vorhandene Windows-SQL-Server-Testdatenbank ContosoSsisDebug.
  - SSIS-Debug 1.0.0 samt Parser 2.0.1 und ResultTable installiert.
  - Vorhandene Ausführungs-/Metadatenrechte; für manuelle Stage-SELECTs
    zusätzlich SELECT auf den verwendeten Quelldaten.
  - Tests/Fixtures/synthetic-8.dtsx aus diesem Modul nach C:\Contoso\synthetic-8.dtsx
    auf den SQL-Server-Rechner kopieren. OPENROWSET liest serverseitig;
    Datei- und BULK-Leserechte müssen bereits vorhanden sein.

Abschnitte in EINEM SSMS-Abfragefenster nacheinander ausführen.
GO ist zwischen diesen Steuerabschnitten erlaubt. Innerhalb eines später
ausgegebenen StageSql-/TargetSql-Batches KEIN GO ergänzen.
Der Generator analysiert das Paket; er führt Paket-/Quell-SQL nicht aus.
Dieses Beispiel legt bei manueller Ausführung drei eigene Demotabellen an.
*/
USE [ContosoSsisDebug];
GO

-- 0. Einmalige synthetische Quelldaten; keine vorhandenen Tabellen ersetzen.
SET NOCOUNT ON;
IF @@TRANCOUNT <> 0 OR (@@OPTIONS & 2) <> 0
    THROW 50000, N'Bitte ohne offene Transaktion und mit IMPLICIT_TRANSACTIONS OFF ausführen.', 1;
IF OBJECT_ID(N'dbo.SyntheticSourceA') IS NOT NULL
   OR OBJECT_ID(N'dbo.SyntheticSourceB') IS NOT NULL
   OR OBJECT_ID(N'dbo.SyntheticLookup') IS NOT NULL
    THROW 50000, N'Demotabellen existieren bereits. Eine eigene freie Demodatenbank verwenden.', 1;

CREATE TABLE dbo.SyntheticSourceA
    (KeyA int NOT NULL, KeyB int NOT NULL, Amount int NOT NULL);
CREATE TABLE dbo.SyntheticSourceB
    (KeyA int NOT NULL, KeyB int NOT NULL, Amount int NOT NULL);
CREATE TABLE dbo.SyntheticLookup
    (KeyA int NOT NULL, KeyB int NOT NULL, Score int NULL);
INSERT dbo.SyntheticSourceA VALUES (1,10,100),(1,20,20),(2,10,200);
INSERT dbo.SyntheticSourceB VALUES (1,10,80),(3,30,30);
INSERT dbo.SyntheticLookup VALUES (1,10,7),(1,10,9),(1,20,NULL),(2,10,2);
GO

-- 1. Originalbytes einlesen und Bearbeitungszustand in der Sitzung behalten.
CREATE TABLE #SsisDemoInput
(
    PackageBytes varbinary(max) NOT NULL,
    Bindings nvarchar(max) NULL,
    CatalogBindings nvarchar(max) NULL,
    LookupPolicies nvarchar(max) NULL
);
CREATE TABLE #SsisDemoArtifacts
(
    ArtifactKind varchar(32) NOT NULL,
    TargetFlowId varchar(64) NULL,
    StageId varchar(64) NULL,
    Ordinal int NOT NULL,
    ComponentId nvarchar(4000) NULL,
    EvidenceClass varchar(24) NOT NULL,
    Severity varchar(16) NULL,
    DiagnosticCode varchar(64) NULL,
    IsComplete bit NOT NULL,
    SafetyStatus varchar(24) NOT NULL,
    IsExecutable bit NOT NULL,
    Content nvarchar(max) NOT NULL,
    DetailsJson nvarchar(max) NULL
);
INSERT #SsisDemoInput(PackageBytes)
SELECT BulkColumn
FROM OPENROWSET(BULK 'C:\Contoso\synthetic-8.dtsx', SINGLE_BLOB) AS package;

-- Explizite Connection-Zuordnung zur aktuellen Datenbank, ohne Credentials.
DECLARE @DatabaseJson nvarchar(256) = STRING_ESCAPE(DB_NAME(), 'json');
UPDATE #SsisDemoInput
SET CatalogBindings = N'{"schemaVersion":1,"defaultDatabase":"'
    + @DatabaseJson + N'","databases":["' + @DatabaseJson
    + N'"],"connections":{"Package.ConnectionManagers[Synthetic]":"'
    + @DatabaseJson + N'"}}',
    -- Demo: beim mehrfachen Lookup-Treffer den höchsten Score auswählen.
    LookupPolicies = N'{"schemaVersion":1,"lookups":{"Package\\Flow\\Lookup":'
    + N'{"orderBy":[{"column":"Score","direction":"desc"}]}}}';
GO

-- 2. Vollständige JSON-Vorlage erzeugen und unverändert als Basis speichern.
DECLARE @PackageBytes varbinary(max);
SELECT @PackageBytes = PackageBytes FROM #SsisDemoInput WITH (NOLOCK);
EXEC toolbelt_tsql.USP_ExplainSsisDataFlow
    @PackageBytes = @PackageBytes,
    @Operation = 'bindings-template',
    @ResultTable = N'#SsisDemoArtifacts',
    @KeepData = 0;

UPDATE #SsisDemoInput
SET Bindings = (SELECT Content FROM #SsisDemoArtifacts WITH (NOLOCK)
                WHERE ArtifactKind = 'BindingsTemplate');

SELECT Bindings AS BindingsTemplate
FROM #SsisDemoInput WITH (NOLOCK);

-- Schlüssel, Namespace, Scope und Typ immer gemeinsam ansehen.
SELECT j.[key], j.[scope], j.[name], j.sqlType, j.defaultValue,
       j.requiredForSelectedFlow
FROM #SsisDemoInput AS i WITH (NOLOCK)
CROSS APPLY OPENJSON(i.Bindings, '$.availableInputs')
WITH
(
    [key] varchar(16) '$.key',
    [scope] nvarchar(4000) '$.scope',
    [name] nvarchar(4000) '$.name',
    sqlType nvarchar(128) '$.sqlType',
    defaultValue nvarchar(4000) '$.defaultValue',
    requiredForSelectedFlow bit '$.requiredForSelectedFlow'
) AS j;
GO

-- 3. Nur values ändern: User::Threshold im Scope Package von 100 auf 150.
-- Das vollständige Dokument samt Hashes und availableInputs bleibt erhalten.
DECLARE @Bindings nvarchar(max), @ThresholdKey varchar(16);
SELECT @Bindings = Bindings FROM #SsisDemoInput WITH (NOLOCK);
SELECT @ThresholdKey = j.[key]
FROM OPENJSON(@Bindings, '$.availableInputs')
WITH ([key] varchar(16) '$.key', [scope] nvarchar(4000) '$.scope',
      [name] nvarchar(4000) '$.name') AS j
WHERE j.[scope] = N'Package' AND j.[name] = N'User::Threshold';
IF @ThresholdKey IS NULL
    THROW 50000, N'Die erwartete Demovariable fehlt im Paket.', 1;

-- 150 ist hier eine JSON-Zahl, kein Textwert.
SET @Bindings = JSON_MODIFY(@Bindings, N'$.values.' + @ThresholdKey, 150);
UPDATE #SsisDemoInput SET Bindings = @Bindings;
SELECT JSON_QUERY(@Bindings, '$.values') AS ChangedValues,
       @Bindings AS BindingsJson;
GO

-- 4. Geänderte Vorlage zurückgeben und alle einzeln testbaren Stufen erzeugen.
DECLARE @PackageBytes varbinary(max), @Bindings nvarchar(max),
        @Catalog nvarchar(max), @Policies nvarchar(max);
SELECT @PackageBytes = PackageBytes, @Bindings = Bindings,
       @Catalog = CatalogBindings, @Policies = LookupPolicies
FROM #SsisDemoInput WITH (NOLOCK);
EXEC toolbelt_tsql.USP_ExplainSsisDataFlow
    @PackageBytes = @PackageBytes,
    @Operation = 'explain',
    @Bindings = @Bindings,
    @CatalogBindings = @Catalog,
    @LookupPolicies = @Policies,
    @InspectStage = 'all',
    @TSqlVersion = 150,
    @ResultTable = N'#SsisDemoArtifacts',
    @KeepData = 0;

SELECT TargetFlowId, StageId, ComponentId, Content AS CteName,
       IsComplete, DetailsJson
FROM #SsisDemoArtifacts WITH (NOLOCK)
WHERE ArtifactKind = 'StageIndex'
ORDER BY Ordinal;

-- Auch Warnungen ansehen; NOLOCK-Hinweis ist im Demo erwartbar.
SELECT Severity, DiagnosticCode, ComponentId, Content
FROM #SsisDemoArtifacts WITH (NOLOCK)
WHERE ArtifactKind = 'Diagnostic'
ORDER BY Ordinal;
GO

-- 5. Konkret die Derived-Column-Stufe des High-Ziels neu anfordern.
-- Andere Stufen über ihre echten IDs aus dem StageIndex wählen.
DECLARE @Target varchar(64), @Stage varchar(64);
SELECT @Target = TargetFlowId
FROM #SsisDemoArtifacts WITH (NOLOCK)
WHERE ArtifactKind = 'TargetSql'
  AND ComponentId = N'Package\Flow\DestinationHigh';
SELECT @Stage = StageId
FROM #SsisDemoArtifacts WITH (NOLOCK)
WHERE ArtifactKind = 'StageIndex' AND TargetFlowId = @Target
  AND ComponentId = N'Package\Flow\Derived';
IF @Target IS NULL OR @Stage IS NULL
    THROW 50000, N'Gewünschtes Demoziel oder gewünschte Stufe ist nicht verfügbar.', 1;

DROP TABLE IF EXISTS #SsisDemoSelected;
SELECT TOP (0) * INTO #SsisDemoSelected
FROM #SsisDemoArtifacts WITH (NOLOCK);

DECLARE @PackageBytes varbinary(max), @Bindings nvarchar(max),
        @Catalog nvarchar(max), @Policies nvarchar(max);
SELECT @PackageBytes = PackageBytes, @Bindings = Bindings,
       @Catalog = CatalogBindings, @Policies = LookupPolicies
FROM #SsisDemoInput WITH (NOLOCK);
EXEC toolbelt_tsql.USP_ExplainSsisDataFlow
    @PackageBytes = @PackageBytes,
    @Bindings = @Bindings,
    @CatalogBindings = @Catalog,
    @LookupPolicies = @Policies,
    @TargetFlow = @Target,
    @InspectStage = @Stage,
    @TSqlVersion = 150,
    @ResultTable = N'#SsisDemoSelected',
    @KeepData = 0;

SELECT TargetFlowId, StageId, Content AS DebugSql
FROM #SsisDemoSelected WITH (NOLOCK)
WHERE ArtifactKind = 'StageSql'
  AND IsComplete = 1 AND SafetyStatus = 'passed' AND IsExecutable = 1
ORDER BY Ordinal;
GO

-- 6. Weitere vollständige Prüfblöcke für Quelle/Union/Lookup/Split/Ziele.
SELECT ArtifactKind, TargetFlowId, StageId, ComponentId,
       DATALENGTH(Content) AS SqlBytes, Content AS DebugSql
FROM #SsisDemoArtifacts WITH (NOLOCK)
WHERE ArtifactKind IN ('StageSql', 'TargetSql')
  AND IsComplete = 1 AND SafetyStatus = 'passed' AND IsExecutable = 1
ORDER BY Ordinal;

/*
JETZT MANUELL TESTEN:
  Den vollständigen Content EINER StageSql-/TargetSql-Zeile in dieses
  SSMS-Abfragefenster kopieren, den gesamten Block markieren und ausführen.
  Alle DECLAREs, Guards und Cachevorbereitungen gehören zum Block.
  Innerhalb des Blocks kein GO; kein PRINT für lange SQL-Inhalte verwenden.

  Erwartet bei unveränderten Demodaten, SourceFloor=0 und Offset=1:
    SourceA: 3 Zeilen; SourceB: 2; Union: 5; Derived: 5.
    Adjusted-Werte nach Derived: 101,21,201,81,31.
    Lookup: weiterhin 5 Zeilen, Score für (1,10) jeweils 9.
    Target High bei Threshold=150: eine Zeile (KeyA=2,KeyB=10,Adjusted=201,Score=2).
    Target Default bei Threshold=150: vier Zeilen.

  Im High-TargetSql lautet die relevante Szenariodeklaration beim Demopaket:
    DECLARE @v0004 int = 150;
  Direkt auf 80 ändern und DIESEN vollständigen Block erneut ausführen:
    High liefert dann 3 Zeilen (Adjusted=101,201,81).
  Dafür sind weder JSON-Änderung noch neuer Generatoraufruf erforderlich.

  Ein CTE gilt nur für das direkt folgende Statement. Für einen anderen
  Prüfpunkt den anderen vollständigen StageSql-Block ausführen. Alternativ
  nur den finalen SELECT eines Blocks auf eine enthaltene Vorgänger-CTE
  umstellen; dort heißen interne Spalten z.B. c0001. Zuordnung: StageIndex
  DetailsJson und ColumnLineage. Nicht nur ein WITH-Fragment ausführen.

  Die Lookupauswahl bleibt in derselben SSMS-Sitzung eingefroren.
  Eine reine Threshold-Änderung baut diesen unabhängigen Lookup nicht neu.
  Für einen frischen Lookupstand zuerst passendes CleanupSql ausführen.
  Erzeugen/Neuladen/Cleanup erfordert eine transaktionsfreie Sitzung.
*/

-- 7. Bei Bedarf nach dem Test die passenden vollständigen Cleanup-Blöcke
-- aus dieser Ausgabe kopieren und in derselben Sitzung ausführen.
SELECT TargetFlowId, StageId, Content AS CleanupSql
FROM #SsisDemoArtifacts WITH (NOLOCK)
WHERE ArtifactKind = 'CleanupSql' AND IsExecutable = 1
ORDER BY Ordinal;

-- Optionale Demodaten-Bereinigung erst nach Abschluss aller Tests:
-- DROP TABLE dbo.SyntheticSourceA, dbo.SyntheticSourceB, dbo.SyntheticLookup;
-- DROP TABLE IF EXISTS #SsisDemoSelected, #SsisDemoArtifacts, #SsisDemoInput;
