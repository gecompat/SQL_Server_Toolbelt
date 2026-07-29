-- ============================================================================
-- Objekt:          toolbelt_core.USP_PrepareResultTable
-- Typ:             Stored Procedure
-- Zweck:           Bereitet eine vorhandene lokale Temp-Tabelle anhand des
--                  Spaltenschemas einer Referenztabelle als ResultTable vor.
-- Vertrag:         Documentation/Architecture/RESULT_TABLE_MODULE_DESIGN.md
-- Parameter:       @ResultTableToAlter sysname = NULL
--                  @LikeTable nvarchar(776) = NULL
--                  @KeepData bit = 0
--                  @Debug tinyint = 0
--                  @Hilfe bit = 0
-- Resultset:       Kein fachliches Resultset; bei @Hilfe = 1 genau ein
--                  standardisiertes Help-Resultset.
-- Dependencies:    Keine weiteren Toolbelt-Module.
-- Rechte:          EXECUTE auf der Procedure und Metadatensichtbarkeit auf
--                  reguläre Referenztabellen. Keine Rechteausweitung.
-- Versionen:       SQL Server 2019, 2022 und 2025.
-- Plattformen:     Windows und Linux; Runtime-Validierung separat auszuweisen.
-- Fehlerverhalten: Vertragsfehler 51020 bis 51029; Engine-Fehler werden nach
--                  transaktionsgerechtem Cleanup unverändert weitergegeben.
-- Performance:     Ein read-only Metadaten-Preflight. DDL nur bei abweichendem
--                  Schema; bei passendem Schema optional TRUNCATE.
-- Einschränkungen: Nur lokale Ziel-Temp-Tabellen und Tabellen als Schemaquelle.
--                  Keine gleichzeitige DDL-Manipulation derselben Zieltable.
-- ============================================================================

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_PrepareResultTable]
(
      @ResultTableToAlter sysname       = NULL
    , @LikeTable          nvarchar(776) = NULL
    , @KeepData           bit           = 0
    , @Debug              tinyint       = 0
    , @Hilfe              bit           = 0
)
AS
BEGIN
    SET NOCOUNT ON;

    -- Explizit übergebenes NULL verwendet denselben technischen Default wie
    -- ein ausgelassener optionaler Steuerparameter.
    SET @KeepData = ISNULL(@KeepData, 0);
    SET @Debug = ISNULL(@Debug, 0);
    SET @Hilfe = ISNULL(@Hilfe, 0);

    /*
     * Der Help-Pfad steht absichtlich vor jeder fachlichen Validierung. Dadurch
     * bleibt ein reiner Hilfeaufruf ohne Zieltable, Referenztabelle oder Rechte
     * auf fremde Metadaten möglich und garantiert keinerlei Mutation.
     */
    IF @Hilfe = 1
    BEGIN
        DECLARE @Help TABLE
        (
              HelpContractVersion varchar(16)    NOT NULL
            , SchemaName          sysname        NOT NULL
            , ObjectName          sysname        NOT NULL
            , Section             varchar(32)    NOT NULL
            , Ordinal             int            NOT NULL
            , ItemName            sysname        NULL
            , SqlDataType         varchar(256)   NULL
            , IsRequired          bit            NULL
            , IsNullable          bit            NULL
            , DefaultValue        nvarchar(4000) NULL
            , Description         nvarchar(max)  NOT NULL
            , ExampleSql          nvarchar(max)  NULL
        );

        INSERT INTO @Help
        (
              HelpContractVersion
            , SchemaName
            , ObjectName
            , Section
            , Ordinal
            , ItemName
            , SqlDataType
            , IsRequired
            , IsNullable
            , DefaultValue
            , Description
            , ExampleSql
        )
        VALUES
          ( '1.0', N'toolbelt_core', N'USP_PrepareResultTable', 'DESCRIPTION', 1
          , NULL, NULL, NULL, NULL, NULL
          , N'Bereitet eine vorhandene lokale Temp-Tabelle anhand des Spaltenschemas einer vorhandenen Referenztabelle vor. Die Procedure fügt keine fachlichen Resultzeilen ein.'
          , NULL )
        , ( '1.0', N'toolbelt_core', N'USP_PrepareResultTable', 'PARAMETER', 1
          , N'@ResultTableToAlter', 'sysname', 1, 0, N'NULL'
          , N'Vorhandene lokale Ziel-Temp-Tabelle. Der Name beginnt mit genau einem #, ist höchstens 116 Zeichen lang und verwendet nicht den reservierten Präfix #tbx_.'
          , NULL )
        , ( '1.0', N'toolbelt_core', N'USP_PrepareResultTable', 'PARAMETER', 2
          , N'@LikeTable', 'nvarchar(776)', 1, 0, N'NULL'
          , N'Referenztabelle in der Form #LocalTemplate, Schema.Table oder Database.Schema.Table. Ziel- und Referenztabelle dürfen nicht identisch sein. Views, Synonyme, globale Temp-Tabellen und vierteilige Namen sind nicht unterstützt.'
          , NULL )
        , ( '1.0', N'toolbelt_core', N'USP_PrepareResultTable', 'PARAMETER', 3
          , N'@KeepData', 'bit', 0, 1, N'0'
          , N'0 verwendet Replace-Semantik. 1 erhält vorhandene Daten nur bei bereits passendem Schema; andernfalls wird vor jeder Mutation mit Fehler 51025 abgebrochen.'
          , NULL )
        , ( '1.0', N'toolbelt_core', N'USP_PrepareResultTable', 'PARAMETER', 4
          , N'@Debug', 'tinyint', 0, 1, N'0'
          , N'Steuert Debug-Messages. Die Stufen 1 bis 3 liefern zunehmend Details; 255 ist der maximale interne Trace. Debug erzeugt kein Resultset.'
          , NULL )
        , ( '1.0', N'toolbelt_core', N'USP_PrepareResultTable', 'PARAMETER', 5
          , N'@Hilfe', 'bit', 0, 1, N'0'
          , N'1 gibt ausschließlich dieses Help-Resultset aus und ignoriert alle anderen Parameter.'
          , NULL )
        , ( '1.0', N'toolbelt_core', N'USP_PrepareResultTable', 'RESULT_COLUMN', 1
          , NULL, NULL, NULL, NULL, NULL
          , N'Diese Infrastruktur-USP besitzt kein fachliches Resultset. Erfolg wird mit RETURN 0, ein Fehler mit THROW signalisiert.'
          , NULL )
        , ( '1.0', N'toolbelt_core', N'USP_PrepareResultTable', 'ERROR', 1
          , N'51020', NULL, NULL, NULL, NULL
          , N'@ResultTableToAlter fehlt oder ist kein zulässiger lokaler Temp-Tabellenname.'
          , NULL )
        , ( '1.0', N'toolbelt_core', N'USP_PrepareResultTable', 'ERROR', 2
          , N'51021', NULL, NULL, NULL, NULL
          , N'Die Zieltable ist im aktuellen Session-Scope nicht sichtbar.'
          , NULL )
        , ( '1.0', N'toolbelt_core', N'USP_PrepareResultTable', 'ERROR', 3
          , N'51022', NULL, NULL, NULL, NULL
          , N'@LikeTable fehlt, ist mehrdeutig, verwendet eine nicht unterstützte Namensform oder bezeichnet dieselbe Temp-Tabelle wie das Ziel.'
          , NULL )
        , ( '1.0', N'toolbelt_core', N'USP_PrepareResultTable', 'ERROR', 4
          , N'51023', NULL, NULL, NULL, NULL
          , N'Die Referenztabelle ist nicht sichtbar oder kein unterstützter Tabellentyp.'
          , NULL )
        , ( '1.0', N'toolbelt_core', N'USP_PrepareResultTable', 'ERROR', 5
          , N'51024', NULL, NULL, NULL, NULL
          , N'Das Referenzschema enthält eine nicht unterstützte oder nicht einfügbare Spaltenform.'
          , NULL )
        , ( '1.0', N'toolbelt_core', N'USP_PrepareResultTable', 'ERROR', 6
          , N'51025', NULL, NULL, NULL, NULL
          , N'@KeepData = 1 verhindert den erforderlichen Schemaumbau.'
          , NULL )
        , ( '1.0', N'toolbelt_core', N'USP_PrepareResultTable', 'ERROR', 7
          , N'51026', NULL, NULL, NULL, NULL
          , N'Ein Index, Constraint oder anderes abhängiges Objekt verhindert den Schemaumbau.'
          , NULL )
        , ( '1.0', N'toolbelt_core', N'USP_PrepareResultTable', 'ERROR', 8
          , N'51027', NULL, NULL, NULL, NULL
          , N'Eine Collation oder ein Datentyp kann nicht sicher in DDL überführt werden.'
          , NULL )
        , ( '1.0', N'toolbelt_core', N'USP_PrepareResultTable', 'ERROR', 9
          , N'51028', NULL, NULL, NULL, NULL
          , N'Der aktuelle Transaktionszustand erlaubt kein kontrolliertes Rollback.'
          , NULL )
        , ( '1.0', N'toolbelt_core', N'USP_PrepareResultTable', 'ERROR', 10
          , N'51029', NULL, NULL, NULL, NULL
          , N'Intern erzeugtes DDL überschreitet einen unterstützten Grenzwert oder ist unvollständig.'
          , NULL )
        , ( '1.0', N'toolbelt_core', N'USP_PrepareResultTable', 'PERMISSION', 1
          , NULL, NULL, NULL, NULL, NULL
          , N'Erforderlich sind EXECUTE auf der Procedure sowie ausreichende Metadatensichtbarkeit auf eine reguläre Referenztabelle. Die Procedure verwendet kein EXECUTE AS und gewährt keine Rechte.'
          , NULL )
        , ( '1.0', N'toolbelt_core', N'USP_PrepareResultTable', 'LIMITATION', 1
          , NULL, NULL, NULL, NULL, NULL
          , N'Permanente oder globale Zieltabellen, Tabellenvariablen, identische Ziel- und Referenztabellen, Views, Synonyme, Linked Server, frei geliefertes DDL und parallele DDL-Manipulation derselben Zieltable sind nicht unterstützt.'
          , NULL )
        , ( '1.0', N'toolbelt_core', N'USP_PrepareResultTable', 'EXAMPLE', 1
          , NULL, NULL, NULL, NULL, NULL
          , N'Bereitet eine synthetische lokale ResultTable anhand einer lokalen Helper-Tabelle vor.'
          , N'CREATE TABLE #Result (Dummy int NULL);
CREATE TABLE #ResultShape (ItemOrdinal bigint NOT NULL, ItemValue varchar(100) NULL);

EXEC toolbelt_core.USP_PrepareResultTable
      @ResultTableToAlter = N''#Result''
    , @LikeTable          = N''#ResultShape''
    , @KeepData           = 0;' );

        SELECT
              HelpContractVersion
            , SchemaName
            , ObjectName
            , Section
            , Ordinal
            , ItemName
            , SqlDataType
            , IsRequired
            , IsNullable
            , DefaultValue
            , Description
            , ExampleSql
        FROM @Help
        ORDER BY
              CASE Section
                  WHEN 'DESCRIPTION'   THEN 1
                  WHEN 'PARAMETER'     THEN 2
                  WHEN 'RESULT_COLUMN' THEN 3
                  WHEN 'ERROR'         THEN 4
                  WHEN 'PERMISSION'    THEN 5
                  WHEN 'LIMITATION'    THEN 6
                  WHEN 'EXAMPLE'       THEN 7
                  ELSE 8
              END
            , Ordinal;

        RETURN 0;
    END;

    DECLARE
          @TargetObjectId          int
        , @TargetQuotedName        nvarchar(258)
        , @SourceObjectId          int
        , @SourceDatabaseName      sysname
        , @SourceDatabaseQuoted    nvarchar(258)
        , @SourceSchemaName        sysname
        , @SourceObjectName        sysname
        , @SourceServerName        sysname
        , @SourceIsLocal           bit = 0
        , @Sql                     nvarchar(max)
        , @ErrorMessage            nvarchar(2048)
        , @DebugMessage            nvarchar(max)
        , @DebugChunk              nvarchar(1800);

    /*
     * Der logische Zielname wird als ein einzelner Identifier behandelt. Ein
     * Punkt oder eine schließende Klammer darf daher Bestandteil des Namens
     * sein; QUOTENAME verhindert, dass daraus ein mehrteiliger Name oder DDL
     * wird. Die physische TempDB-Suffixbildung wird SQL Server überlassen.
     */
    IF @ResultTableToAlter IS NULL
       OR DATALENGTH(@ResultTableToAlter) < 4
       OR DATALENGTH(@ResultTableToAlter) > 232
       OR LEFT(@ResultTableToAlter, 1) COLLATE Latin1_General_100_BIN2 <> N'#'
       OR LEFT(@ResultTableToAlter, 2) COLLATE Latin1_General_100_BIN2 = N'##'
       OR LOWER(LEFT(@ResultTableToAlter, 5) COLLATE Latin1_General_100_BIN2) = N'#tbx_'
       OR QUOTENAME(@ResultTableToAlter) IS NULL
    BEGIN
        THROW 51020, N'@ResultTableToAlter muss eine vorhandene lokale Temp-Tabelle mit genau einem führenden #, höchstens 116 Zeichen und ohne reservierten Präfix #tbx_ bezeichnen.', 1;
    END;

    SET @TargetQuotedName = QUOTENAME(@ResultTableToAlter);
    SET @TargetObjectId = OBJECT_ID(N'tempdb..' + @TargetQuotedName, N'U');

    IF @TargetObjectId IS NULL
    BEGIN
        SET @ErrorMessage = N'Die lokale Zieltable '
            + @TargetQuotedName
            + N' ist im aktuellen Session-Scope nicht sichtbar.';
        SET @ErrorMessage = REPLACE(@ErrorMessage, N'%', N'%%');
        THROW 51021, @ErrorMessage, 1;
    END;

    IF @LikeTable IS NULL OR DATALENGTH(@LikeTable) = 0
    BEGIN
        THROW 51022, N'@LikeTable muss #LocalTemplate, Schema.Table oder Database.Schema.Table bezeichnen.', 1;
    END;

    /*
     * Lokale Referenztabellen werden wie die Zieltable genau einmal aufgelöst.
     * Globale Temp-Tabellen sind eine erkennbare, aber nicht unterstützte
     * Tabellenart und erhalten deshalb den Objektfehler 51023.
     */
    IF (LEFT(@LikeTable, 1) COLLATE Latin1_General_100_BIN2) = N'#'
    BEGIN
        IF (LEFT(@LikeTable, 2) COLLATE Latin1_General_100_BIN2) = N'##'
        BEGIN
            THROW 51023, N'Globale Temp-Tabellen sind als @LikeTable nicht unterstützt.', 1;
        END;

        IF DATALENGTH(@LikeTable) < 4
           OR DATALENGTH(@LikeTable) > 232
           OR QUOTENAME(CONVERT(sysname, @LikeTable)) IS NULL
        BEGIN
            THROW 51022, N'Der lokale Name in @LikeTable ist kein zulässiger Temp-Tabellenname.', 1;
        END;

        SET @SourceIsLocal = 1;
        SET @SourceDatabaseName = N'tempdb';
        SET @SourceDatabaseQuoted = QUOTENAME(@SourceDatabaseName);
        SET @SourceObjectName = CONVERT(sysname, @LikeTable);
        SET @SourceObjectId = OBJECT_ID(
              N'tempdb..' + QUOTENAME(@SourceObjectName)
            , N'U'
        );

        IF @SourceObjectId IS NULL
        BEGIN
            SET @ErrorMessage = N'Die lokale Referenztabelle '
                + QUOTENAME(@SourceObjectName)
                + N' ist im aktuellen Session-Scope nicht sichtbar.';
            SET @ErrorMessage = REPLACE(@ErrorMessage, N'%', N'%%');
            THROW 51023, @ErrorMessage, 1;
        END;
    END;
    ELSE
    BEGIN
        /*
         * PARSENAME zerlegt ausschließlich Objektnamen. Die ermittelten Teile
         * werden nie als Originaltext ausgeführt, sondern als sysname geprüft,
         * mit QUOTENAME neu aufgebaut und Werte in Catalog-Abfragen
         * parametrisiert. Ein Serverteil ist vertraglich ausgeschlossen.
         */
        SET @SourceObjectName = PARSENAME(@LikeTable, 1);
        SET @SourceSchemaName = PARSENAME(@LikeTable, 2);
        SET @SourceDatabaseName = PARSENAME(@LikeTable, 3);
        SET @SourceServerName = PARSENAME(@LikeTable, 4);

        IF @SourceObjectName IS NULL
           OR @SourceSchemaName IS NULL
           OR @SourceServerName IS NOT NULL
           OR QUOTENAME(@SourceObjectName) IS NULL
           OR QUOTENAME(@SourceSchemaName) IS NULL
        BEGIN
            THROW 51022, N'@LikeTable muss als Schema.Table oder Database.Schema.Table ohne Serverteil angegeben werden.', 1;
        END;

        IF @SourceDatabaseName IS NULL
        BEGIN
            SET @SourceDatabaseName = DB_NAME();
        END;

        IF DB_ID(@SourceDatabaseName) IS NULL
           OR QUOTENAME(@SourceDatabaseName) IS NULL
        BEGIN
            THROW 51023, N'Die Datenbank der Referenztabelle ist nicht sichtbar oder nicht vorhanden.', 1;
        END;

        SET @SourceDatabaseQuoted = QUOTENAME(@SourceDatabaseName);
        SET @Sql = N'
SELECT @ResolvedObjectId = t.object_id
FROM ' + @SourceDatabaseQuoted + N'.sys.tables AS t
INNER JOIN ' + @SourceDatabaseQuoted + N'.sys.schemas AS s
    ON s.schema_id = t.schema_id
WHERE s.name COLLATE Latin1_General_100_BIN2
          = @SchemaName COLLATE Latin1_General_100_BIN2
  AND t.name COLLATE Latin1_General_100_BIN2
          = @ObjectName COLLATE Latin1_General_100_BIN2;';

        BEGIN TRY
            EXEC sys.sp_executesql
                  @Sql
                , N'@SchemaName sysname, @ObjectName sysname, @ResolvedObjectId int OUTPUT'
                , @SchemaName      = @SourceSchemaName
                , @ObjectName      = @SourceObjectName
                , @ResolvedObjectId = @SourceObjectId OUTPUT;
        END TRY
        BEGIN CATCH
            /*
             * Ein tatsächlich aufgetretener Engine-Fehler darf nicht als
             * Toolbelt-Validierungsfehler erscheinen. Nur eine erfolgreich
             * ausgeführte Suche ohne unterstütztes Objekt ergibt 51023.
             */
            THROW;
        END CATCH;

        IF @SourceObjectId IS NULL
        BEGIN
            THROW 51023, N'Die reguläre Referenztabelle ist nicht sichtbar, nicht vorhanden oder kein User Table.', 1;
        END;
    END;

    IF @SourceIsLocal = 1 AND @SourceObjectId = @TargetObjectId
    BEGIN
        THROW 51022, N'@ResultTableToAlter und @LikeTable dürfen nicht dieselbe lokale Temp-Tabelle bezeichnen.', 1;
    END;

    IF @Debug >= 1
    BEGIN
        SET @DebugChunk = N'USP_PrepareResultTable: Ziel- und Referenztabelle wurden aufgelöst; read-only Preflight beginnt.';
        RAISERROR(N'%s', 10, 1, @DebugChunk) WITH NOWAIT;
    END;

    DECLARE
          @SourceColumnCount       int
        , @TargetColumnCount       int
        , @UnsupportedColumnName   sysname
        , @UnsupportedReason       nvarchar(4000)
        , @InvalidCollationDetected bit
        , @InvalidCollationName    sysname
        , @SchemaMatches           bit
        , @AddColumnsList          nvarchar(max)
        , @AddColumnAfterAnchor     nvarchar(4000)
        , @DropColumnsList         nvarchar(max)
        , @DropColumnBeforeAnchor   nvarchar(258)
        , @SourceMetadataDebug     nvarchar(max);

    /*
     * Die Quelldatenbank ist der einzige dynamische Catalog-Teil. Sie stammt
     * entweder aus DB_NAME/PARSENAME oder ist tempdb und wird mit QUOTENAME
     * begrenzt. Objekt-IDs werden als Werte parametrisiert.
     *
     * Alias Types werden auf den zugrunde liegenden Systemtyp normalisiert.
     * Typisiertes XML und Sparse werden bewusst als untypisiertes XML
     * beziehungsweise normale Spalte abgebildet. Unbekannte neue Typen bleiben
     * durch die Whitelist gesperrt, bis ihr Vertrag versioniert erweitert wird.
     */
    SET @Sql = N'
DECLARE @SourceColumns TABLE
(
      ColumnOrdinal             int            NOT NULL
    , ColumnName                sysname        NOT NULL
    , TypeName                  sysname        NULL
    , MaxLength                 smallint       NOT NULL
    , PrecisionValue            tinyint        NOT NULL
    , ScaleValue                tinyint        NOT NULL
    , IsNullable                bit            NOT NULL
    , CollationName             sysname        NULL
    , IsIdentity                bit            NOT NULL
    , IsComputed                bit            NOT NULL
    , GeneratedAlwaysType       tinyint        NOT NULL
    , IsHidden                  bit            NOT NULL
    , IsColumnSet               bit            NOT NULL
    , IsSparse                  bit            NOT NULL
    , EncryptionType            int            NULL
    , IsAssemblyType            bit            NOT NULL
    , IsUserDefined             bit            NOT NULL
    , XmlCollectionId           int            NOT NULL
    , UnsupportedReason         nvarchar(4000) NULL
    , NormalizedTypeDeclaration nvarchar(4000) NULL
);

;WITH RawSourceColumns AS
(
    SELECT
          ROW_NUMBER() OVER (ORDER BY c.column_id) AS ColumnOrdinal
        , c.name AS ColumnName
        , CASE
              WHEN st.name = N''sysname'' AND c.system_type_id = 231
                  THEN N''nvarchar''
              WHEN st.is_user_defined = 1 AND st.is_assembly_type = 0
                  THEN bt.name
              ELSE st.name
          END AS TypeName
        , c.system_type_id AS SystemTypeId
        , c.max_length AS MaxLength
        , c.precision AS PrecisionValue
        , c.scale AS ScaleValue
        , c.is_nullable AS IsNullable
        , c.collation_name AS CollationName
        , c.is_identity AS IsIdentity
        , c.is_computed AS IsComputed
        , c.generated_always_type AS GeneratedAlwaysType
        , c.is_hidden AS IsHidden
        , c.is_column_set AS IsColumnSet
        , c.is_sparse AS IsSparse
        , c.encryption_type AS EncryptionType
        , ISNULL(st.is_assembly_type, 0) AS IsAssemblyType
        , ISNULL(st.is_user_defined, 0) AS IsUserDefined
        , c.xml_collection_id AS XmlCollectionId
    FROM ' + @SourceDatabaseQuoted + N'.sys.columns AS c
    LEFT JOIN ' + @SourceDatabaseQuoted + N'.sys.types AS st
        ON st.user_type_id = c.user_type_id
    LEFT JOIN ' + @SourceDatabaseQuoted + N'.sys.types AS bt
        ON bt.system_type_id = c.system_type_id
       AND bt.user_type_id = bt.system_type_id
    WHERE c.object_id = @SourceObjectId
)
INSERT INTO @SourceColumns
(
      ColumnOrdinal
    , ColumnName
    , TypeName
    , MaxLength
    , PrecisionValue
    , ScaleValue
    , IsNullable
    , CollationName
    , IsIdentity
    , IsComputed
    , GeneratedAlwaysType
    , IsHidden
    , IsColumnSet
    , IsSparse
    , EncryptionType
    , IsAssemblyType
    , IsUserDefined
    , XmlCollectionId
    , UnsupportedReason
    , NormalizedTypeDeclaration
)
SELECT
      r.ColumnOrdinal
    , r.ColumnName
    , r.TypeName
    , r.MaxLength
    , r.PrecisionValue
    , r.ScaleValue
    , r.IsNullable
    , r.CollationName
    , r.IsIdentity
    , r.IsComputed
    , r.GeneratedAlwaysType
    , r.IsHidden
    , r.IsColumnSet
    , r.IsSparse
    , r.EncryptionType
    , r.IsAssemblyType
    , r.IsUserDefined
    , r.XmlCollectionId
    , CASE
          WHEN r.IsIdentity = 1
              THEN N''Identity-Spalten sind nicht als Resultset-Shape unterstützt.''
          WHEN r.IsComputed = 1
              THEN N''Computed Columns sind nicht als Resultset-Shape unterstützt.''
          WHEN r.GeneratedAlwaysType <> 0
              THEN N''Generated-always-Spalten sind nicht als Resultset-Shape unterstützt.''
          WHEN r.IsHidden = 1
              THEN N''Hidden Columns sind nicht als Resultset-Shape unterstützt.''
          WHEN r.IsColumnSet = 1
              THEN N''XML Column Sets sind nicht als Resultset-Shape unterstützt.''
          WHEN r.EncryptionType IS NOT NULL
              THEN N''Verschlüsselte Spalten sind nicht als Resultset-Shape unterstützt.''
          WHEN r.SystemTypeId = 189
              THEN N''rowversion/timestamp ist nicht explizit einfügbar.''
          WHEN r.TypeName IN (N''text'', N''ntext'', N''image'')
              THEN N''Legacy-LOB-Typen text, ntext und image sind nicht unterstützt.''
          WHEN r.IsAssemblyType = 1
               AND (r.IsUserDefined = 1
                    OR r.TypeName NOT IN (N''hierarchyid'', N''geometry'', N''geography''))
              THEN N''Benutzerdefinierte oder unbekannte CLR Types sind nicht unterstützt.''
          WHEN r.TypeName IS NULL
               OR r.TypeName NOT IN
                  (
                        N''bigint'', N''binary'', N''bit'', N''char''
                      , N''date'', N''datetime'', N''datetime2'', N''datetimeoffset''
                      , N''decimal'', N''float'', N''geography'', N''geometry''
                      , N''hierarchyid'', N''int'', N''money'', N''nchar''
                      , N''numeric'', N''nvarchar'', N''real'', N''smalldatetime''
                      , N''smallint'', N''smallmoney'', N''sql_variant'', N''time''
                      , N''tinyint'', N''uniqueidentifier'', N''varbinary''
                      , N''varchar'', N''xml''
                  )
              THEN N''Der Datentyp ist in Contract-Version 1.0 nicht freigegeben.''
          ELSE NULL
      END AS UnsupportedReason
    , CASE
          WHEN r.TypeName IN (N''char'', N''varchar'', N''binary'', N''varbinary'')
              THEN QUOTENAME(r.TypeName)
                   + N''(''
                   + CASE
                         WHEN r.MaxLength = -1 THEN N''max''
                         ELSE CONVERT(nvarchar(10), r.MaxLength)
                     END
                   + N'')''
          WHEN r.TypeName IN (N''nchar'', N''nvarchar'')
              THEN QUOTENAME(r.TypeName)
                   + N''(''
                   + CASE
                         WHEN r.MaxLength = -1 THEN N''max''
                         ELSE CONVERT(nvarchar(10), r.MaxLength / 2)
                     END
                   + N'')''
          WHEN r.TypeName IN (N''decimal'', N''numeric'')
              THEN QUOTENAME(r.TypeName)
                   + N''(''
                   + CONVERT(nvarchar(10), r.PrecisionValue)
                   + N'',''
                   + CONVERT(nvarchar(10), r.ScaleValue)
                   + N'')''
          WHEN r.TypeName = N''float''
              THEN N''[float](''
                   + CONVERT(nvarchar(10), r.PrecisionValue)
                   + N'')''
          WHEN r.TypeName IN (N''time'', N''datetime2'', N''datetimeoffset'')
              THEN QUOTENAME(r.TypeName)
                   + N''(''
                   + CONVERT(nvarchar(10), r.ScaleValue)
                   + N'')''
          WHEN r.TypeName IN
               (
                     N''bigint'', N''bit'', N''date'', N''datetime''
                   , N''geography'', N''geometry'', N''hierarchyid'', N''int''
                   , N''money'', N''real'', N''smalldatetime'', N''smallint''
                   , N''smallmoney'', N''sql_variant'', N''tinyint''
                   , N''uniqueidentifier'', N''xml''
               )
              THEN QUOTENAME(r.TypeName)
          ELSE NULL
      END AS NormalizedTypeDeclaration
FROM RawSourceColumns AS r;

DECLARE @TargetColumns TABLE
(
      ColumnOrdinal   int      NOT NULL
    , ColumnName      sysname  NOT NULL
    , TypeName        sysname  NULL
    , MaxLength       smallint NOT NULL
    , PrecisionValue  tinyint  NOT NULL
    , ScaleValue      tinyint  NOT NULL
    , IsNullable      bit      NOT NULL
    , CollationName   sysname  NULL
    , IsInsertable    bit      NOT NULL
);

INSERT INTO @TargetColumns
(
      ColumnOrdinal
    , ColumnName
    , TypeName
    , MaxLength
    , PrecisionValue
    , ScaleValue
    , IsNullable
    , CollationName
    , IsInsertable
)
SELECT
      ROW_NUMBER() OVER (ORDER BY c.column_id)
    , c.name
    , CASE
          WHEN st.name = N''sysname'' AND c.system_type_id = 231
              THEN N''nvarchar''
          WHEN st.is_user_defined = 1 AND st.is_assembly_type = 0
              THEN bt.name
          ELSE st.name
      END
    , c.max_length
    , c.precision
    , c.scale
    , c.is_nullable
    , c.collation_name
    , CONVERT
      (
          bit,
          CASE
              WHEN c.is_identity = 0
               AND c.is_computed = 0
               AND c.generated_always_type = 0
               AND c.is_hidden = 0
               AND c.is_column_set = 0
               AND c.is_sparse = 0
               AND c.encryption_type IS NULL
               AND c.xml_collection_id = 0
               AND c.system_type_id <> 189
               AND NOT
                   (
                       st.is_assembly_type = 1
                       AND (st.is_user_defined = 1
                            OR st.name NOT IN (N''hierarchyid'', N''geometry'', N''geography''))
                   )
                  THEN 1
              ELSE 0
          END
      )
FROM tempdb.sys.columns AS c
LEFT JOIN tempdb.sys.types AS st
    ON st.user_type_id = c.user_type_id
LEFT JOIN tempdb.sys.types AS bt
    ON bt.system_type_id = c.system_type_id
   AND bt.user_type_id = bt.system_type_id
WHERE c.object_id = @TargetObjectId;

SELECT @SourceColumnCount = COUNT(*)
FROM @SourceColumns;

SELECT @TargetColumnCount = COUNT(*)
FROM @TargetColumns;

SELECT TOP (1)
      @UnsupportedColumnName = ColumnName
    , @UnsupportedReason = UnsupportedReason
FROM @SourceColumns
WHERE UnsupportedReason IS NOT NULL
   OR NormalizedTypeDeclaration IS NULL
ORDER BY ColumnOrdinal;

SELECT TOP (1)
      @InvalidCollationDetected = 1
    , @InvalidCollationName = CollationName
FROM @SourceColumns AS c
WHERE c.TypeName IN (N''char'', N''varchar'', N''nchar'', N''nvarchar'')
  AND
  (
      c.CollationName IS NULL
      OR NOT EXISTS
         (
             SELECT 1
             FROM sys.fn_helpcollations() AS hc
             WHERE hc.name COLLATE Latin1_General_100_BIN2
                       = c.CollationName COLLATE Latin1_General_100_BIN2
         )
  )
ORDER BY ColumnOrdinal;

SELECT @SchemaMatches =
    CONVERT
    (
        bit,
        CASE
            WHEN EXISTS
                 (
                     SELECT 1
                     FROM @SourceColumns AS s
                     FULL OUTER JOIN @TargetColumns AS t
                         ON t.ColumnOrdinal = s.ColumnOrdinal
                     WHERE s.ColumnOrdinal IS NULL
                        OR t.ColumnOrdinal IS NULL
                        OR s.ColumnName COLLATE Latin1_General_100_BIN2
                               <> t.ColumnName COLLATE Latin1_General_100_BIN2
                        OR ISNULL(s.TypeName, N'''') COLLATE Latin1_General_100_BIN2
                               <> ISNULL(t.TypeName, N'''') COLLATE Latin1_General_100_BIN2
                        OR s.MaxLength <> t.MaxLength
                        OR s.PrecisionValue <> t.PrecisionValue
                        OR s.ScaleValue <> t.ScaleValue
                        OR s.IsNullable <> t.IsNullable
                        OR ISNULL(s.CollationName, N'''') COLLATE Latin1_General_100_BIN2
                               <> ISNULL(t.CollationName, N'''') COLLATE Latin1_General_100_BIN2
                        OR t.IsInsertable <> 1
                 )
                THEN 0
            ELSE 1
        END
    );

SELECT @AddColumnsList =
    STUFF
    (
        (
            SELECT
                  N'', ''
                + QUOTENAME(c.ColumnName)
                + N'' ''
                + c.NormalizedTypeDeclaration
                + CASE
                      WHEN c.TypeName IN (N''char'', N''varchar'', N''nchar'', N''nvarchar'')
                          THEN N'' COLLATE '' + c.CollationName
                      ELSE N''''
                  END
                + CASE WHEN c.IsNullable = 1 THEN N'' NULL'' ELSE N'' NOT NULL'' END
            FROM @SourceColumns AS c
            WHERE c.ColumnOrdinal < 1024
               OR @SourceColumnCount < 1024
            ORDER BY c.ColumnOrdinal
            FOR XML PATH(N''''), TYPE
        ).value(N''.'', N''nvarchar(max)'')
      , 1
      , 2
      , N''''
    );

SELECT @AddColumnAfterAnchor =
      QUOTENAME(c.ColumnName)
    + N'' ''
    + c.NormalizedTypeDeclaration
    + CASE
          WHEN c.TypeName IN (N''char'', N''varchar'', N''nchar'', N''nvarchar'')
              THEN N'' COLLATE '' + c.CollationName
          ELSE N''''
      END
    + CASE WHEN c.IsNullable = 1 THEN N'' NULL'' ELSE N'' NOT NULL'' END
FROM @SourceColumns AS c
WHERE @SourceColumnCount = 1024
  AND c.ColumnOrdinal = 1024;

SELECT @DropColumnsList =
    STUFF
    (
        (
            SELECT N'', '' + QUOTENAME(c.ColumnName)
            FROM @TargetColumns AS c
            WHERE c.ColumnOrdinal < 1024
               OR @TargetColumnCount < 1024
            ORDER BY c.ColumnOrdinal
            FOR XML PATH(N''''), TYPE
        ).value(N''.'', N''nvarchar(max)'')
      , 1
      , 2
      , N''''
    );

SELECT @DropColumnBeforeAnchor = QUOTENAME(c.ColumnName)
FROM @TargetColumns AS c
WHERE @TargetColumnCount = 1024
  AND c.ColumnOrdinal = 1024;

SELECT @SourceMetadataDebug =
    STUFF
    (
        (
            SELECT
                  NCHAR(10)
                + CONVERT(nvarchar(10), c.ColumnOrdinal)
                + N'': ''
                + QUOTENAME(c.ColumnName)
                + N'' ''
                + ISNULL(c.NormalizedTypeDeclaration, N''<unsupported>'')
                + CASE
                      WHEN c.TypeName IN (N''char'', N''varchar'', N''nchar'', N''nvarchar'')
                          THEN N'' COLLATE '' + ISNULL(c.CollationName, N''<NULL>'')
                      ELSE N''''
                  END
                + CASE WHEN c.IsNullable = 1 THEN N'' NULL'' ELSE N'' NOT NULL'' END
            FROM @SourceColumns AS c
            ORDER BY c.ColumnOrdinal
            FOR XML PATH(N''''), TYPE
        ).value(N''.'', N''nvarchar(max)'')
      , 1
      , 1
      , N''''
    );';

    BEGIN TRY
        EXEC sys.sp_executesql
              @Sql
            , N'@SourceObjectId int,
                @TargetObjectId int,
                @SourceColumnCount int OUTPUT,
                @TargetColumnCount int OUTPUT,
                @UnsupportedColumnName sysname OUTPUT,
                @UnsupportedReason nvarchar(4000) OUTPUT,
                @InvalidCollationDetected bit OUTPUT,
                @InvalidCollationName sysname OUTPUT,
                @SchemaMatches bit OUTPUT,
                @AddColumnsList nvarchar(max) OUTPUT,
                @AddColumnAfterAnchor nvarchar(4000) OUTPUT,
                @DropColumnsList nvarchar(max) OUTPUT,
                @DropColumnBeforeAnchor nvarchar(258) OUTPUT,
                @SourceMetadataDebug nvarchar(max) OUTPUT'
            , @SourceObjectId        = @SourceObjectId
            , @TargetObjectId        = @TargetObjectId
            , @SourceColumnCount     = @SourceColumnCount OUTPUT
            , @TargetColumnCount     = @TargetColumnCount OUTPUT
            , @UnsupportedColumnName = @UnsupportedColumnName OUTPUT
            , @UnsupportedReason     = @UnsupportedReason OUTPUT
            , @InvalidCollationDetected = @InvalidCollationDetected OUTPUT
            , @InvalidCollationName  = @InvalidCollationName OUTPUT
            , @SchemaMatches         = @SchemaMatches OUTPUT
            , @AddColumnsList        = @AddColumnsList OUTPUT
            , @AddColumnAfterAnchor  = @AddColumnAfterAnchor OUTPUT
            , @DropColumnsList       = @DropColumnsList OUTPUT
            , @DropColumnBeforeAnchor = @DropColumnBeforeAnchor OUTPUT
            , @SourceMetadataDebug   = @SourceMetadataDebug OUTPUT;
    END TRY
    BEGIN CATCH
        /*
         * Catalog- und Engine-Fehler werden nicht in einen scheinbar
         * erfolgreichen Validierungsstatus übersetzt. Die ursprüngliche
         * Fehlernummer bleibt durch THROW für den Aufrufer erhalten.
         */
        THROW;
    END CATCH;

    IF @SourceColumnCount IS NULL OR @SourceColumnCount = 0
    BEGIN
        THROW 51023, N'Die Referenztabelle besitzt keine sichtbaren Spalten oder ihre Metadaten sind nicht ausreichend sichtbar.', 1;
    END;

    IF @SourceColumnCount > 1024
    BEGIN
        THROW 51029, N'Das Referenzschema überschreitet das unterstützte Limit von 1024 ResultTable-Spalten.', 1;
    END;

    IF @TargetColumnCount > 1024
    BEGIN
        THROW 51029, N'Die Zieltable überschreitet das unterstützte Limit von 1024 ResultTable-Spalten.', 1;
    END;

    IF @UnsupportedColumnName IS NOT NULL
    BEGIN
        SET @ErrorMessage = N'Die Referenzspalte '
            + QUOTENAME(@UnsupportedColumnName)
            + N' ist nicht unterstützt. '
            + ISNULL(@UnsupportedReason, N'Es konnte keine sichere Typdeklaration erzeugt werden.');
        SET @ErrorMessage = REPLACE(@ErrorMessage, N'%', N'%%');
        THROW 51024, @ErrorMessage, 1;
    END;

    IF @InvalidCollationDetected = 1
    BEGIN
        SET @ErrorMessage = N'Die Collation '
            + COALESCE(QUOTENAME(@InvalidCollationName), N'<NULL>')
            + N' kann nicht sicher für die ResultTable verwendet werden.';
        SET @ErrorMessage = REPLACE(@ErrorMessage, N'%', N'%%');
        THROW 51027, @ErrorMessage, 1;
    END;

    IF @AddColumnsList IS NULL
       OR @DropColumnsList IS NULL
       OR (@SourceColumnCount = 1024 AND @AddColumnAfterAnchor IS NULL)
       OR (@TargetColumnCount = 1024 AND @DropColumnBeforeAnchor IS NULL)
       OR DATALENGTH(@AddColumnsList) > 2000000
       OR DATALENGTH(@DropColumnsList) > 2000000
       OR DATALENGTH(ISNULL(@AddColumnAfterAnchor, N'')) > 8000
    BEGIN
        THROW 51029, N'Das intern erzeugte DDL ist unvollständig oder überschreitet 1.000.000 Unicode-Zeichen je Spaltenliste.', 1;
    END;

    DECLARE @TargetHasRows bit;
    SET @Sql = N'SELECT @HasRows = CONVERT(bit, CASE WHEN EXISTS (SELECT 1 FROM '
        + @TargetQuotedName
        + N') THEN 1 ELSE 0 END);';

    EXEC sys.sp_executesql
          @Sql
        , N'@HasRows bit OUTPUT'
        , @HasRows = @TargetHasRows OUTPUT;

    IF @Debug >= 2
    BEGIN
        SET @DebugChunk = N'USP_PrepareResultTable: TargetObjectId='
            + CONVERT(nvarchar(20), @TargetObjectId)
            + N', SourceObjectId='
            + CONVERT(nvarchar(20), @SourceObjectId)
            + N', SourceIsLocal='
            + CONVERT(nvarchar(1), @SourceIsLocal)
            + N', TargetHasRows='
            + CONVERT(nvarchar(1), @TargetHasRows)
            + N', SchemaMatches='
            + CONVERT(nvarchar(1), @SchemaMatches)
            + N'.';
        RAISERROR(N'%s', 10, 1, @DebugChunk) WITH NOWAIT;
    END;

    IF @Debug >= 3 AND @SourceMetadataDebug IS NOT NULL
    BEGIN
        SET @DebugMessage = N'USP_PrepareResultTable: normalisierte Referenzmetadaten:'
            + NCHAR(10)
            + @SourceMetadataDebug;

        WHILE DATALENGTH(@DebugMessage) > 0
        BEGIN
            SET @DebugChunk = LEFT(@DebugMessage, 1800);
            RAISERROR(N'%s', 10, 1, @DebugChunk) WITH NOWAIT;
            SET @DebugMessage = SUBSTRING(@DebugMessage, 1801, 2147483647);
        END;
    END;

    /*
     * @KeepData = 1 darf bei abweichendem Schema niemals einen Teilumbau
     * auslösen. Der Fehler erfolgt deshalb vor Dependency-Prüfung, Datenlöschung
     * und Transaktionsbeginn und lässt die Zieltable vollständig unverändert.
     */
    IF @SchemaMatches = 0 AND @TargetHasRows = 1 AND @KeepData = 1
    BEGIN
        THROW 51025, N'@KeepData = 1 kann vorhandene Daten bei abweichendem Ziel- und Referenzschema nicht sicher erhalten.', 1;
    END;

    DECLARE
          @BlockerType sysname
        , @BlockerName sysname;

    IF @SchemaMatches = 0
    BEGIN
        /*
         * Der in-place-Algorithmus ersetzt alle alten Spalten. Daher blockiert
         * jedes Objekt, das an einer dieser Spalten hängt. Es wird bewusst
         * nichts automatisch gedroppt oder nachgebaut.
         */
        SELECT TOP (1)
              @BlockerType = d.BlockerType
            , @BlockerName = d.BlockerName
        FROM
        (
            SELECT
                  10 AS PriorityValue
                , CONVERT(sysname, N'INDEX') AS BlockerType
                , i.name AS BlockerName
            FROM tempdb.sys.indexes AS i
            WHERE i.object_id = @TargetObjectId
              AND i.index_id > 0
              AND i.is_hypothetical = 0

            UNION ALL

            SELECT
                  20
                , CONVERT(sysname, N'DEFAULT_CONSTRAINT')
                , dc.name
            FROM tempdb.sys.default_constraints AS dc
            WHERE dc.parent_object_id = @TargetObjectId

            UNION ALL

            SELECT
                  30
                , CONVERT(sysname, N'CHECK_CONSTRAINT')
                , cc.name
            FROM tempdb.sys.check_constraints AS cc
            WHERE cc.parent_object_id = @TargetObjectId

            UNION ALL

            SELECT
                  40
                , CONVERT(sysname, N'FOREIGN_KEY')
                , fk.name
            FROM tempdb.sys.foreign_keys AS fk
            WHERE fk.parent_object_id = @TargetObjectId
               OR fk.referenced_object_id = @TargetObjectId

            UNION ALL

            SELECT
                  50
                , CONVERT(sysname, N'COMPUTED_COLUMN')
                , c.name
            FROM tempdb.sys.columns AS c
            WHERE c.object_id = @TargetObjectId
              AND c.is_computed = 1

            UNION ALL

            SELECT
                  60
                , CONVERT(sysname, N'BOUND_DEFAULT_OR_RULE')
                , c.name
            FROM tempdb.sys.columns AS c
            WHERE c.object_id = @TargetObjectId
              AND (c.default_object_id <> 0 OR c.rule_object_id <> 0)

            UNION ALL

            SELECT
                  70
                , CONVERT(sysname, N'TRIGGER')
                , tr.name
            FROM tempdb.sys.triggers AS tr
            WHERE tr.parent_id = @TargetObjectId

            UNION ALL

            SELECT
                  80
                , CONVERT(sysname, N'USER_STATISTICS')
                , st.name
            FROM tempdb.sys.stats AS st
            WHERE st.object_id = @TargetObjectId
              AND st.user_created = 1
        ) AS d
        ORDER BY
              d.PriorityValue
            , d.BlockerName COLLATE Latin1_General_100_BIN2;

        IF @BlockerType IS NOT NULL
        BEGIN
            SET @ErrorMessage = N'Der Schemaumbau von '
                + @TargetQuotedName
                + N' wird durch '
                + @BlockerType
                + N' '
                + COALESCE(QUOTENAME(@BlockerName), N'<unbenannt>')
                + N' blockiert. Das abhängige Objekt muss der Aufrufer vor dem erneuten Aufruf kontrolliert entfernen.';
            SET @ErrorMessage = REPLACE(@ErrorMessage, N'%', N'%%');
            THROW 51026, @ErrorMessage, 1;
        END;
    END;

    DECLARE @MutationRequired bit =
        CONVERT
        (
            bit,
            CASE
                WHEN @SchemaMatches = 0 THEN 1
                WHEN @TargetHasRows = 1 AND @KeepData = 0 THEN 1
                ELSE 0
            END
        );

    IF @MutationRequired = 0
    BEGIN
        IF @Debug >= 1
        BEGIN
            SET @DebugChunk = N'USP_PrepareResultTable: Schema und Datenzustand erfordern keine Mutation.';
            RAISERROR(N'%s', 10, 1, @DebugChunk) WITH NOWAIT;
        END;

        RETURN 0;
    END;

    IF XACT_STATE() = -1
    BEGIN
        THROW 51028, N'Der aktuelle uncommittable Transaktionszustand erlaubt keine kontrollierte ResultTable-Mutation.', 1;
    END;

    DECLARE
          @InvocationToken       varchar(32) = REPLACE(CONVERT(varchar(36), NEWID()), '-', '')
        , @AnchorColumnName      sysname
        , @SavepointName         varchar(32)
        , @StartedTransaction    bit = 0
        , @ClearMethod           varchar(16)
        , @DropBeforeAnchorSql   nvarchar(max)
        , @AddAnchorSql          nvarchar(max)
        , @DropOldColumnsSql     nvarchar(max)
        , @AddNewColumnsSql      nvarchar(max)
        , @DropAnchorSql         nvarchar(max)
        , @AddAfterAnchorSql     nvarchar(max)
        , @TruncateSql           nvarchar(max);

    SET @AnchorColumnName = CONVERT(sysname, N'tbx_anchor_' + @InvocationToken);

    WHILE EXISTS
    (
        SELECT 1
        FROM tempdb.sys.columns AS c
        WHERE c.object_id = @TargetObjectId
          AND c.name COLLATE Latin1_General_100_BIN2
                  = @AnchorColumnName COLLATE Latin1_General_100_BIN2
    )
    BEGIN
        SET @InvocationToken = REPLACE(CONVERT(varchar(36), NEWID()), '-', '');
        SET @AnchorColumnName = CONVERT(sysname, N'tbx_anchor_' + @InvocationToken);
    END;

    SET @SavepointName = CONVERT(varchar(32), 'tbx_rtbl_' + LEFT(@InvocationToken, 23));
    IF @DropColumnBeforeAnchor IS NOT NULL
    BEGIN
        SET @DropBeforeAnchorSql = N'ALTER TABLE '
            + @TargetQuotedName
            + N' DROP COLUMN '
            + @DropColumnBeforeAnchor
            + N';';
    END;

    SET @AddAnchorSql = N'ALTER TABLE '
        + @TargetQuotedName
        + N' ADD '
        + QUOTENAME(@AnchorColumnName)
        + N' bit NULL;';
    SET @DropOldColumnsSql = N'ALTER TABLE '
        + @TargetQuotedName
        + N' DROP COLUMN '
        + @DropColumnsList
        + N';';
    SET @AddNewColumnsSql = N'ALTER TABLE '
        + @TargetQuotedName
        + N' ADD '
        + @AddColumnsList
        + N';';
    SET @DropAnchorSql = N'ALTER TABLE '
        + @TargetQuotedName
        + N' DROP COLUMN '
        + QUOTENAME(@AnchorColumnName)
        + N';';
    IF @AddColumnAfterAnchor IS NOT NULL
    BEGIN
        SET @AddAfterAnchorSql = N'ALTER TABLE '
            + @TargetQuotedName
            + N' ADD '
            + @AddColumnAfterAnchor
            + N';';
    END;

    SET @TruncateSql = N'TRUNCATE TABLE ' + @TargetQuotedName + N';';

    IF @Debug >= 3
    BEGIN
        SET @DebugMessage = N'USP_PrepareResultTable: geplantes DDL:'
            + NCHAR(10)
            + CASE
                  WHEN @SchemaMatches = 0
                      THEN COALESCE(@DropBeforeAnchorSql + NCHAR(10), N'')
                           + @AddAnchorSql + NCHAR(10)
                           + @DropOldColumnsSql + NCHAR(10)
                           + @AddNewColumnsSql + NCHAR(10)
                           + @DropAnchorSql
                           + COALESCE(NCHAR(10) + @AddAfterAnchorSql, N'')
                  WHEN @TargetHasRows = 1 AND @KeepData = 0
                      THEN @TruncateSql
                  ELSE N'<keine Mutation>'
              END;

        WHILE DATALENGTH(@DebugMessage) > 0
        BEGIN
            SET @DebugChunk = LEFT(@DebugMessage, 1800);
            RAISERROR(N'%s', 10, 1, @DebugChunk) WITH NOWAIT;
            SET @DebugMessage = SUBSTRING(@DebugMessage, 1801, 2147483647);
        END;
    END;

    /*
     * Erst ab hier beginnt die Mutation. Eine vorhandene Caller-Transaktion
     * erhält ausschließlich einen Invocation-spezifischen Savepoint. Die
     * Procedure committed oder rollt niemals die vollständige Caller-
     * Transaktion zurück.
     */
    BEGIN TRY
        IF @@TRANCOUNT = 0
        BEGIN
            BEGIN TRANSACTION;
            SET @StartedTransaction = 1;
        END;
        ELSE
        BEGIN
            SAVE TRANSACTION @SavepointName;
        END;

        IF @TargetHasRows = 1 AND @KeepData = 0
        BEGIN
            /*
             * Eine lokale ResultTable muss truncatable sein. Verhindert die
             * Engine TRUNCATE dennoch, liegt ein nicht unterstützter Zustand
             * vor. Der Originalfehler wird nach dem Rollback unverändert
             * weitergegeben; ein DELETE-Fallback ist ausdrücklich unzulässig.
             */
            EXEC sys.sp_executesql @TruncateSql;
            SET @ClearMethod = 'TRUNCATE';
        END;

        IF @SchemaMatches = 0
        BEGIN
            /*
             * Bei exakt 1024 Ziel- oder Quellspalten wird der Umbau geteilt:
             * eine alte Spalte weicht vor der Anchor-Spalte beziehungsweise
             * die letzte neue Spalte folgt erst nach deren Entfernung. Dadurch
             * entstehen zu keinem Zeitpunkt mehr als 1024 Spalten.
             */
            IF @DropBeforeAnchorSql IS NOT NULL
            BEGIN
                EXEC sys.sp_executesql @DropBeforeAnchorSql;
            END;

            EXEC sys.sp_executesql @AddAnchorSql;
            EXEC sys.sp_executesql @DropOldColumnsSql;
            EXEC sys.sp_executesql @AddNewColumnsSql;
            EXEC sys.sp_executesql @DropAnchorSql;

            IF @AddAfterAnchorSql IS NOT NULL
            BEGIN
                EXEC sys.sp_executesql @AddAfterAnchorSql;
            END;
        END;

        IF @StartedTransaction = 1
        BEGIN
            COMMIT TRANSACTION;
        END;
    END TRY
    BEGIN CATCH
        DECLARE
              @OriginalErrorNumber  int = ERROR_NUMBER()
            , @OriginalErrorMessage nvarchar(2048) = ERROR_MESSAGE();

        IF @StartedTransaction = 1 AND XACT_STATE() <> 0
        BEGIN
            ROLLBACK TRANSACTION;
        END;
        ELSE IF @StartedTransaction = 0 AND XACT_STATE() = 1
        BEGIN
            BEGIN TRY
                ROLLBACK TRANSACTION @SavepointName;
            END TRY
            BEGIN CATCH
                SET @ErrorMessage = N'Der ResultTable-Fehler '
                    + CONVERT(nvarchar(20), @OriginalErrorNumber)
                    + N' konnte wegen Rollback-Fehler '
                    + CONVERT(nvarchar(20), ERROR_NUMBER())
                    + N' nicht kontrolliert zum Savepoint zurückgerollt werden. Ursprüngliche Meldung: '
                    + LEFT(@OriginalErrorMessage, 1200);
                SET @ErrorMessage = REPLACE(@ErrorMessage, N'%', N'%%');
                THROW 51028, @ErrorMessage, 1;
            END CATCH;
        END;

        /*
         * Bei XACT_STATE() = -1 wird kein unzulässiger Savepoint-Rollback
         * versucht. THROW ohne Argumente erhält den ursprünglichen Engine-
         * oder Modulfehler samt Nummer, State und Procedure-Kontext.
         */
        THROW;
    END CATCH;

    IF @Debug >= 2 AND @ClearMethod IS NOT NULL
    BEGIN
        SET @DebugChunk = N'USP_PrepareResultTable: vorhandene Daten wurden mit '
            + @ClearMethod
            + N' entfernt.';
        RAISERROR(N'%s', 10, 1, @DebugChunk) WITH NOWAIT;
    END;

    IF @Debug >= 1
    BEGIN
        SET @DebugChunk = N'USP_PrepareResultTable: Vorbereitung erfolgreich abgeschlossen.';
        RAISERROR(N'%s', 10, 1, @DebugChunk) WITH NOWAIT;
    END;

    RETURN 0;
END;
GO
