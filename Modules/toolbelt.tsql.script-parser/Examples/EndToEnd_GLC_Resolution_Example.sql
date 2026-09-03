-- ============================================================================
-- Vollständiges Schritt-für-Schritt-Beispiel: T-SQL Parsing -> GUIDs -> T-SQL
-- Katalog: [glc].[GlobalCatalog]
-- ============================================================================

DECLARE @CatalogTable nvarchar(512) = N'[glc].[GlobalCatalog]';
DECLARE @SynonymSourceDb sysname = DB_NAME();
DECLARE @CurrentDatabase sysname = DB_NAME();

-- 0. Ausgangsstatement
DECLARE @InputSql nvarchar(max) = N'
    SELECT kopf.IdentCode
        , kopf.Geschaeftstyp
        , kopf.TagIDLoeschung
        , kopf.KontoID
        , kopf.AusfuehrungsNr
        , kopf.Ausfuehrungsdatum
        , kopf.WPGeschaeftstypID
        --
        , det.IdentCode    AS WPAusfuehrungDetailID
        , det.TagIDVon
        , det.TagIDBis
        , det.TagIDBisTechnisch
        , det.VersionsNr
        , det.IstAusserboerslich_Intern
        , det.IstEmission
        , det.IstTilgung
        , det.WPAusfuehrungsphaseID
        , det.WPGeschaeftsstatusID
        , det.WPFunktionstypID
        , det.Kassatag
        , det.Valutadatum
        , det.Belieferungsdatum
        , det.Eingangsdatum
        , det.Eingangszeit
        , det.TradeconfStatusID
        , det.TradeconfPhaseID
        , det.WPEingangsformID
        , det.AusfuehrungsNrFremd
        , det.AusfuehrungsNrFremd2
        , det.Sachbearbeiter
        , det.WPAuftragBeratungID
        , det.VerwahrartDepotID
        , det.WPLagerortID
        , det.Handelsplatz
        , det.WaehrungISOIDHandel
        , det.Kontrahentenkuerzel
        , det.BoerseGeschaeftsNr
        , det.KZDirectSettlement
        , det.WPAuftragsschnittstelleID
        , det.WPPartnertypID
        , det.LandOrganisationISOIDHandelsplatz
        , det.AusfuehrungPhysisch
        , det.WPSettlementartID
        , det.InternerHinweis
        , det.WPZusatzinfoTypID
        , det.WPGeschaeftsartID
        , det.Ausfuehrungsmenge
        , det.Mengeneinheit
        , det.ZwischendepotNr
        , det.WPBruttoNettoID
        , det.AusfuehrungsNrKontrahent
        , det.AusfuehrungsdatumKontrahent
        , det.Settlementbezeichnung
        , det.Schlusszeit
        , det.Schlusstag
        , det.SchlussCode
        , det.Lagerstellendepot
        , det.AuftragIdentifikationsNr
        , det.Kurs
        , det.Aenderungsdatum
        , det.Aenderungszeit
        , det.Auftraggeber
        , det.IstAusserboerslich
        , det.StatusFusionID
        , det.WPBesitzwechselID
        , det.KurswertBerichtsWhgOAnk
        , det.KurswertHandelsWhgOAnk
        , det.WaehrungISOIDHandelUmsatz
        , det.Handelsboerse
        , det.Bewertungsboerse
        , det.WaehrungISOIDBewertung
        , det.KursRWS
        , det.KursdatumRWS
        , det.KurswertRWSEUR
        , det.Devisenkurs
        , det.KursGemeinerWert
        , det.KursdatumGemeinerWert
        , det.KurswertGemeinerWertEUR
        , det.WPFinanzinstrumentID
        , det.RepoIdentifikationsNr
        , det.TerminereignisIdentifikationsNr
        , det.WPTerminereignisIdentTypID
        , det.TerminereignisZeitpunkt
        , det.ZahlungIdentifikationsNr
        , det.WPZahlungIdentTypID
        , det.WPUmsatztypID
        , det.WPGeschaeftsartIDUmsatz
        , det.AuftraggeberCode
        , det.WPAuftraggeberTypID
        , det.WPAuftraggeberCodeSchemaID
        , det.WPMiFIRAggressorIndicatorID
        , det.KontrahentVerwendetBoersemitgliedschaft
        , det.WPUebertragungsartID
        , det.HatZustimmungUebertragungAD
        , det.HatFinanzamtmeldung
        , det.WPPositionID
        , det.WPBetragProzentID
        , det.Buchungszeitpunkt
        , det.VertragsNrNeu
        , det.LeiheVon
        , det.LeiheBis
        , det.WPLeiheartID
        , det.LeiheKurs
        , det.LeiheGebuehr
        , det.WPZinsdivisorID
        , det.LeiheHaircut
        , det.VerrechnungskontoNr
        , det.WPEinheitID
        , det.WPAutoCollateralisationID
        , det.CollateralNr
        , det.CollateralNrExtern
        , det.WPCollateralEinAusID
        , det.HatKundenweisung
        , det.AusfuehrungIdentifikationsNr
        , det.KursInBilanzwaehrung
        , det.FIPartnerKontrahentenvereinbarung
        , det.WPPartnerIDKontrahentenvereinbarung
        , det.DepotCodeCollateralExtern
        , det.DepotNrCollateralExtern
        , det.DepotBLZCollateralExtern
        , [ZDW.vertrag.Konto].KontoNr
        , [R34_ZDW.vertrag.Konto].KontoNr
    FROM zdw_depot.WPAusfuehrungKopf    kopf
    INNER JOIN zdw_depot.WPAusfuehrungDetail  det   ON det.WPAusfuehrungKopfID = kopf.IdentCode
    INNER JOIN R00_ZDW.[vertrag].[Konto] [ZDW.vertrag.Konto] ON kopf.KontoID = [ZDW.vertrag.Konto].IdentCode
    INNER JOIN R34_ZDW.[vertrag].[Konto] [R34_ZDW.vertrag.Konto] ON kopf.KontoID = [R34_ZDW.vertrag.Konto].IdentCode;
';

-- ============================================================================
-- SCHRITT 1: Generischer Tokenstrom und Syntaxprüfung (toolbelt_tsql)
-- ============================================================================
PRINT N'--- SCHRITT 1: Tokenstrom (Auszug) ---';
SELECT TOP 15 TokenIndex, TokenType, TokenText, StartOffset, StartLine, StartColumn
FROM toolbelt_tsql.TVF_TokenizeScript(@InputSql, NULL, NULL, NULL, NULL)
ORDER BY TokenIndex;

-- ============================================================================
-- SCHRITT 2: AST-Knoten und Tabellen-/Spaltenextraktion (toolbelt_tsql)
-- ============================================================================
PRINT N'--- SCHRITT 2: Extrahierte Tabellenreferenzen und Aliase ---';
SELECT 
      TableNodeId
    , DatabaseName
    , SchemaName
    , ObjectName
    , AliasName
    , AliasQuoteType
    , SchemaTokenIndex
    , ObjectTokenIndex
    , AliasTokenIndex
FROM toolbelt_tsql.TVF_ExtractScriptTableReferences(@InputSql, NULL, NULL, NULL, NULL);

PRINT N'--- SCHRITT 2b: Extrahierte Spaltenreferenzen (Auszug) ---';
SELECT TOP 10
      ColRefNodeId
    , TableOrAliasQualifier
    , ColumnName
    , ColumnQuoteType
    , ColumnTokenIndex
    , QualifierTokenIndex
FROM toolbelt_tsql.TVF_ExtractScriptColumnReferences(@InputSql, NULL, NULL, NULL, NULL)
ORDER BY ColRefNodeId;

-- ============================================================================
-- SCHRITT 3: Synonym-Auflösung über sys.synonyms (toolbelt_tsql)
-- ============================================================================
PRINT N'--- SCHRITT 3: Synonym-Auflösung ---';
SELECT 
      t.SchemaName AS OrigSchema
    , t.ObjectName AS OrigTable
    , t.AliasName
    , syn.SynonymSchemaName
    , syn.BaseDatabaseName AS ResolvedDatabase
    , syn.BaseSchemaName AS ResolvedSchema
    , syn.BaseObjectNameOnly AS ResolvedTable
    , syn.IsSynonym
FROM toolbelt_tsql.TVF_ExtractScriptTableReferences(@InputSql, NULL, NULL, NULL, NULL) AS t
OUTER APPLY (
    SELECT 
          sch.name AS SynonymSchemaName
        , s.name AS SynonymName
        , CAST(1 AS bit) AS IsSynonym
        , PARSENAME(s.base_object_name, 3) AS BaseDatabaseName
        , PARSENAME(s.base_object_name, 2) AS BaseSchemaName
        , PARSENAME(s.base_object_name, 1) AS BaseObjectNameOnly
    FROM sys.synonyms AS s
    JOIN sys.schemas AS sch ON sch.schema_id = s.schema_id
    WHERE s.name = t.ObjectName AND (sch.name = t.SchemaName OR t.SchemaName IS NULL)
) AS syn;

-- ============================================================================
-- SCHRITT 4: Mandanten-Normalisierung und GlobalCatalog-Match (toolbelt_glc)
-- ============================================================================
PRINT N'--- SCHRITT 4: Mandanten-Zerlegung & GlobalCatalog Match (Tabellen-GUIDs) ---';
SELECT 
      t.ObjectName
    , t.AliasName
    , tp.RawDatabaseName
    , tp.TenantPrefix
    , tp.NormalizedDatabaseName
    , tp.IsCurrentTenant
    , cat.GUID AS TableGuid
    , cat.Qualifier1 AS CatalogDB
    , cat.Qualifier2 AS CatalogSchema
    , cat.Qualifier3 AS CatalogTable
FROM toolbelt_tsql.TVF_ExtractScriptTableReferences(@InputSql, NULL, NULL, NULL, NULL) AS t
OUTER APPLY (
    SELECT 
          sch.name AS SynonymSchemaName
        , s.name AS SynonymName
        , PARSENAME(s.base_object_name, 3) AS BaseDatabaseName
        , PARSENAME(s.base_object_name, 2) AS BaseSchemaName
        , PARSENAME(s.base_object_name, 1) AS BaseObjectNameOnly
    FROM sys.synonyms AS s
    JOIN sys.schemas AS sch ON sch.schema_id = s.schema_id
    WHERE s.name = t.ObjectName AND (sch.name = t.SchemaName OR t.SchemaName IS NULL)
) AS syn
CROSS APPLY toolbelt_glc.TVF_ParseTenantDatabaseName(
      COALESCE(syn.BaseDatabaseName, t.DatabaseName)
    , @CurrentDatabase
) AS tp
LEFT JOIN glc.GlobalCatalog AS cat
    ON cat.Qualifier1 = tp.NormalizedDatabaseName
   AND cat.Qualifier2 = COALESCE(syn.BaseSchemaName, t.SchemaName)
   AND cat.Qualifier3 = COALESCE(syn.BaseObjectNameOnly, t.ObjectName)
   AND cat.ObjectType IN (N'S_OU', N'S_OV')
   AND cat.IsDeleted = 0;

-- ============================================================================
-- SCHRITT 5: Vollständige Transformation in GLC-GUID-Tags (toolbelt_glc)
-- ============================================================================
PRINT N'--- SCHRITT 5: Vorwärts-Transformation (SQL -> GLC-GUIDs) ---';
DECLARE @GuidSql nvarchar(max);

EXEC toolbelt_glc.USP_RewriteScriptToGlcGuids
      @SqlText           = @InputSql
    , @CatalogTable      = @CatalogTable
    , @SynonymSourceDb   = @SynonymSourceDb
    , @CurrentDatabase   = @CurrentDatabase
    , @RewrittenSql      = @GuidSql OUTPUT;

SELECT @GuidSql AS [5_Transformiertes_SQL_mit_GLC_GUIDs];

-- ============================================================================
-- SCHRITT 6: Rückwärts-Transformation zur Laufzeit / Deployment (toolbelt_glc)
-- ============================================================================
PRINT N'--- SCHRITT 6: Rückwärts-Transformation (GLC-GUIDs -> T-SQL) ---';
DECLARE @RestoredSql nvarchar(max);

EXEC toolbelt_glc.USP_TranslateGlcGuidsToScript
      @SqlText           = @GuidSql
    , @CatalogTable      = @CatalogTable
    , @CurrentDatabase   = @CurrentDatabase
    , @TranslatedSql     = @RestoredSql OUTPUT;

SELECT @RestoredSql AS [6_Wiederhergestelltes_TSQL];
GO
