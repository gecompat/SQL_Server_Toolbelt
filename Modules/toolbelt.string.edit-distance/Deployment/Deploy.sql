:On Error exit
-- RETURN beendet den gesamten ersten Batch; SQLCMD stoppt vor weiteren Batches.
IF @@TRANCOUNT <> 0
BEGIN
    RAISERROR(N'Der Editierdistanz-Lifecycle akzeptiert keine Caller-Transaktion.', 16, 1);
    RETURN;
END;
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @VersionProperty sysname = N'Toolbelt.Module.toolbelt.string.edit-distance.Version',
        @ModeProperty sysname = N'Toolbelt.Module.toolbelt.string.edit-distance.DeploymentMode',
        @InstalledVersion nvarchar(max), @InstalledMode nvarchar(max),
        @Release int, @AssemblyId int, @InstalledAssemblyHash varbinary(64),
        @Pass int = 1, @OwnTransaction bit = 0;
DECLARE @Slots TABLE (Name sysname COLLATE DATABASE_DEFAULT PRIMARY KEY, SinceRelease int NOT NULL,
                      Kind char(2) COLLATE DATABASE_DEFAULT NOT NULL, ObjectId int NULL);
INSERT @Slots(Name, SinceRelease, Kind) VALUES
    (N'TVF_LevenshteinDistance', 10, 'IF'),
    (N'TVF_OsaDistance', 10, 'IF'),
    (N'TVF_LevenshteinDistanceCore', 10, 'FT'),
    (N'TVF_OsaDistanceCore', 10, 'FT'),
    (N'TVF_JaroWinklerSimilarity', 11, 'IF'),
    (N'TVF_JaroWinklerSimilarityCore', 11, 'FT');
DECLARE @DeploymentMode nvarchar(16) = N'$(DeploymentMode)',
        @AssemblyBits varbinary(max) = $(AssemblyBits), @AssemblyHash varbinary(64);
IF TRY_CONVERT(int, SERVERPROPERTY(N'ProductMajorVersion')) NOT IN (15, 16, 17)
    THROW 55030, N'Dieses Modul unterstützt SQL Server 2019, 2022 und 2025.', 1;
IF CONVERT(varbinary(max), @DeploymentMode) NOT IN (CONVERT(varbinary(max), N'local'), CONVERT(varbinary(max), N'central')) OR DATALENGTH(N'$(DeploymentMode)') NOT IN (10,14)
    THROW 55031, N'DeploymentMode muss local oder central sein.', 1;
IF @AssemblyBits IS NULL OR DATALENGTH(@AssemblyBits) < 1024
    THROW 55043, N'AssemblyBits enthält kein plausibles Release-Binary.', 1;
SET @AssemblyHash = HASHBYTES(N'SHA2_512', @AssemblyBits);
-- Explizite Offline-Erwartung; niemals aus dem aktuellen Katalog ableiten.
DECLARE @ExpectedInstalledAssemblyHashText nvarchar(max) = N'$(ExpectedInstalledAssemblyHash)',
        @ExpectedInstalledAssemblyHash varbinary(64), @ExpectedAbsence bit = 0;
IF CONVERT(varbinary(max), @ExpectedInstalledAssemblyHashText) = CONVERT(varbinary(max), N'0x')
    SET @ExpectedAbsence = 1;
ELSE
BEGIN
    IF @ExpectedInstalledAssemblyHashText IS NULL
       OR DATALENGTH(@ExpectedInstalledAssemblyHashText) <> 260
       OR CONVERT(varbinary(max), LEFT(@ExpectedInstalledAssemblyHashText, 2)) <> CONVERT(varbinary(max), N'0x')
       OR SUBSTRING(@ExpectedInstalledAssemblyHashText, 3, 128) COLLATE Latin1_General_100_BIN2 LIKE N'%[^0-9A-Fa-f]%'
       OR TRY_CONVERT(varbinary(max), @ExpectedInstalledAssemblyHashText, 1) IS NULL
       OR DATALENGTH(TRY_CONVERT(varbinary(max), @ExpectedInstalledAssemblyHashText, 1)) <> 64
        THROW 55046, N'ExpectedInstalledAssemblyHash muss 0x oder exakt 128 Hexzeichen nach 0x enthalten.', 1;
    SET @ExpectedInstalledAssemblyHash = TRY_CONVERT(varbinary(64), @ExpectedInstalledAssemblyHashText, 1);
END;
BEGIN TRY
    WHILE @Pass <= 2
    BEGIN
        -- Vollständige Metadatensicht wird auch unter dem AppLock neu geprüft.
        IF ISNULL(HAS_PERMS_BY_NAME(DB_NAME(), N'DATABASE', N'VIEW DEFINITION'), 0) <> 1
         OR ISNULL(HAS_PERMS_BY_NAME(N'sys.sql_expression_dependencies', N'OBJECT', N'SELECT'), 0) <> 1
            THROW 55034, N'Vollständige Dependency-Metadatensicht fehlt; keine Rechtevergabe.', 6;
        -- Beide Durchläufe lesen den aktuellen Katalog; der zweite läuft unter AppLock.
        SET @InstalledVersion = NULL;
        SET @InstalledMode = NULL;
        SET @AssemblyId = NULL;
        SET @InstalledAssemblyHash = NULL;
        SELECT @InstalledVersion = TRY_CONVERT(nvarchar(max), value)
        FROM sys.extended_properties
        WHERE class = 0 AND major_id = 0 AND minor_id = 0 AND name = @VersionProperty;
        SELECT @InstalledMode = TRY_CONVERT(nvarchar(max), value)
        FROM sys.extended_properties
        WHERE class = 0 AND major_id = 0 AND minor_id = 0 AND name = @ModeProperty;
        SET @Release = CASE CONVERT(varbinary(max), @InstalledVersion)
            WHEN CONVERT(varbinary(max), N'1.0.0') THEN 10
            WHEN CONVERT(varbinary(max), N'1.1.0') THEN 11 ELSE 0 END;
        IF @Release = 0 AND EXISTS (SELECT 1 FROM sys.extended_properties
            WHERE class = 0 AND major_id = 0 AND minor_id = 0 AND name = @VersionProperty)
            THROW 55032, N'Die installierte Modulversion ist nicht bekannt.', 1;
        SELECT @AssemblyId = a.assembly_id,
               @InstalledAssemblyHash = HASHBYTES(N'SHA2_512', f.content)
        FROM sys.assemblies a LEFT JOIN sys.assembly_files f
          ON f.assembly_id = a.assembly_id AND f.file_id = 1
        WHERE a.name = N'Toolbelt_String_EditDistance';
        UPDATE s SET ObjectId = o.object_id FROM @Slots s
        LEFT JOIN sys.objects o ON o.schema_id = SCHEMA_ID(N'toolbelt_string') AND o.name COLLATE DATABASE_DEFAULT = s.Name COLLATE DATABASE_DEFAULT;

        IF @Release = 0 AND (@AssemblyId IS NOT NULL OR EXISTS (SELECT 1 FROM sys.extended_properties WHERE class=0 AND major_id=0 AND minor_id=0 AND name=@ModeProperty)
            OR EXISTS (SELECT 1 FROM @Slots WHERE ObjectId IS NOT NULL))
            THROW 55033, N'Zielobjekte ohne bekannten Versionsmarker sind fremd belegt.', 7;
        IF @Release > 0 AND (@InstalledMode IS NULL OR
            CONVERT(varbinary(max), @InstalledMode) NOT IN
            (CONVERT(varbinary(max), N'local'), CONVERT(varbinary(max), N'central')))
            THROW 55033, N'Der installierte DeploymentMode ist nicht kohärent.', 1;
        IF SCHEMA_ID(N'toolbelt_string') IS NOT NULL AND
          (NOT EXISTS (SELECT 1 FROM sys.extended_properties WHERE class = 3
            AND major_id = SCHEMA_ID(N'toolbelt_string') AND minor_id = 0
            AND name = N'Toolbelt.Managed' AND TRY_CONVERT(int, value) = 1)
           OR NOT EXISTS (SELECT 1 FROM sys.extended_properties WHERE class = 3
            AND major_id = SCHEMA_ID(N'toolbelt_string') AND minor_id = 0
            AND name = N'Toolbelt.SchemaCategory'
            AND CONVERT(varbinary(max), TRY_CONVERT(nvarchar(max), value)) = CONVERT(varbinary(max), N'string')))
            THROW 55033, N'Das vorhandene Schema hat keine eigene Toolbelt-Zuordnung.', 2;
        IF @Release > 0 AND EXISTS
          (SELECT 1 FROM @Slots s LEFT JOIN sys.objects o ON o.object_id = s.ObjectId
           WHERE s.SinceRelease <= @Release AND
           (o.object_id IS NULL OR CONVERT(varbinary(max),o.name)<>CONVERT(varbinary(max),s.Name)
            OR o.type COLLATE DATABASE_DEFAULT <> s.Kind COLLATE DATABASE_DEFAULT
            OR NOT EXISTS (SELECT 1 FROM sys.extended_properties e WHERE e.class = 1
              AND e.major_id = o.object_id AND e.minor_id = 0 AND e.name = N'Toolbelt.Managed'
              AND TRY_CONVERT(int, e.value) = 1)
            OR NOT EXISTS (SELECT 1 FROM sys.extended_properties e WHERE e.class = 1
              AND e.major_id = o.object_id AND e.minor_id = 0 AND e.name = N'Toolbelt.ModuleId'
              AND CONVERT(varbinary(max), TRY_CONVERT(nvarchar(max), e.value)) = CONVERT(varbinary(max), N'toolbelt.string.edit-distance'))
            OR NOT EXISTS (SELECT 1 FROM sys.extended_properties e WHERE e.class = 1
              AND e.major_id = o.object_id AND e.minor_id = 0 AND e.name = N'Toolbelt.ModuleVersion'
              AND CONVERT(varbinary(max), TRY_CONVERT(nvarchar(max), e.value)) = CONVERT(varbinary(max), @InstalledVersion))
            OR NOT EXISTS (SELECT 1 FROM sys.extended_properties e WHERE e.class=1
              AND e.major_id=o.object_id AND e.minor_id=0 AND e.name=N'Toolbelt.Visibility'
              AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),e.value))=
                  CONVERT(varbinary(max),CASE WHEN s.Kind='FT' THEN N'internal' ELSE N'public' END))))
            THROW 55033, N'Das installierte Release-Objektmanifest ist nicht kohärent.', 3;
        -- Historische Releasebytes werden explizit gebunden, nicht aus clr_name erschlossen.
        IF @Release = 0 AND @ExpectedAbsence = 0
           OR @Release > 0 AND @ExpectedAbsence = 1
            THROW 55046, N'Die erwartete Assembly-Anwesenheit passt nicht zum geprüften Modulzustand.', 2;
        IF @Release > 0 AND (@InstalledAssemblyHash IS NULL
            OR @InstalledAssemblyHash <> @ExpectedInstalledAssemblyHash)
            THROW 55047, N'Der installierte Assemblyhash entspricht nicht der expliziten Offline-Erwartung.', 1;
        IF @Release > 0 AND EXISTS
          (SELECT 1 FROM @Slots s JOIN sys.assembly_modules m ON m.object_id=s.ObjectId
           WHERE s.SinceRelease<=@Release AND s.Kind='FT' AND (CONVERT(varbinary(max),m.assembly_class) <> CONVERT(varbinary(max),CASE WHEN s.Name=N'TVF_JaroWinklerSimilarityCore' THEN N'Toolbelt.String.EditDistance.JaroProvider' ELSE N'Toolbelt.String.EditDistance.DistanceProvider' END)
             OR CONVERT(varbinary(max),m.assembly_method) <> CONVERT(varbinary(max),CASE s.Name
                WHEN N'TVF_LevenshteinDistanceCore' THEN N'Levenshtein' WHEN N'TVF_JaroWinklerSimilarityCore' THEN N'Evaluate' ELSE N'Osa' END)
             OR m.null_on_null_input<>0))
            THROW 55033, N'Der CLR-Kern besitzt eine falsche EntryPoint- oder NULL-Bindung.', 8;
        IF @Release > 0 AND EXISTS
          (SELECT 1 FROM @Slots s WHERE s.SinceRelease<=@Release AND
            ((SELECT COUNT(*) FROM sys.parameters p WHERE p.object_id=s.ObjectId AND p.parameter_id>0)
                 <>CASE WHEN s.SinceRelease=11 THEN 3 ELSE 4 END
            OR (SELECT COUNT(*) FROM sys.columns c WHERE c.object_id=s.ObjectId)
                 <>CASE WHEN s.SinceRelease=11 THEN 2 ELSE 3 END
            OR EXISTS(SELECT 1 FROM sys.parameters p WHERE p.object_id=s.ObjectId AND
              (p.user_type_id<>p.system_type_id
               OR (p.parameter_id=1 AND(CONVERT(varbinary(max),p.name)<>CONVERT(varbinary(max),N'@LeftText') OR TYPE_NAME(p.system_type_id)<>N'nvarchar' OR p.max_length<>-1))
               OR (p.parameter_id=2 AND(CONVERT(varbinary(max),p.name)<>CONVERT(varbinary(max),N'@RightText') OR TYPE_NAME(p.system_type_id)<>N'nvarchar' OR p.max_length<>-1))
               OR (s.SinceRelease=10 AND p.parameter_id=3 AND(CONVERT(varbinary(max),p.name)<>CONVERT(varbinary(max),N'@MaxDistance') OR TYPE_NAME(p.system_type_id)<>N'int' OR p.max_length<>4))
               OR (s.SinceRelease=10 AND p.parameter_id=4 AND(CONVERT(varbinary(max),p.name)<>CONVERT(varbinary(max),N'@Profile') OR TYPE_NAME(p.system_type_id)<>N'nvarchar' OR p.max_length<>-1))
               OR (s.SinceRelease=11 AND p.parameter_id=3 AND(CONVERT(varbinary(max),p.name)<>CONVERT(varbinary(max),N'@Profile') OR TYPE_NAME(p.system_type_id)<>N'nvarchar' OR p.max_length<>-1))))
            OR EXISTS(SELECT 1 FROM sys.columns c WHERE c.object_id=s.ObjectId AND
              (c.user_type_id<>c.system_type_id
               OR (s.SinceRelease=10 AND ((c.column_id=1 AND(CONVERT(varbinary(max),c.name)<>CONVERT(varbinary(max),N'Distance') OR TYPE_NAME(c.system_type_id)<>N'int' OR c.max_length<>4))
                 OR(c.column_id=2 AND(CONVERT(varbinary(max),c.name)<>CONVERT(varbinary(max),N'ExceedsMaxDistance') OR TYPE_NAME(c.system_type_id)<>N'bit' OR c.max_length<>1))
                 OR(c.column_id=3 AND(CONVERT(varbinary(max),c.name)<>CONVERT(varbinary(max),N'ErrorCode') OR TYPE_NAME(c.system_type_id)<>N'int' OR c.max_length<>4))))
               OR (s.SinceRelease=11 AND ((c.column_id=1 AND(CONVERT(varbinary(max),c.name)<>CONVERT(varbinary(max),N'Similarity') OR TYPE_NAME(c.system_type_id)<>N'float' OR c.max_length<>8 OR c.precision<>53))
                 OR(c.column_id=2 AND(CONVERT(varbinary(max),c.name)<>CONVERT(varbinary(max),N'ErrorCode') OR TYPE_NAME(c.system_type_id)<>N'int' OR c.max_length<>4))))))))
            THROW 55033, N'Die Parameter-/Resultset-Metadaten des installierten Releases sind nicht kohärent.', 9;
        IF @Release > 0 AND (@AssemblyId IS NULL OR @InstalledAssemblyHash IS NULL
          OR NOT EXISTS (SELECT 1 FROM sys.assemblies a WHERE a.assembly_id = @AssemblyId
              AND a.permission_set_desc = N'SAFE_ACCESS' AND a.is_user_defined = 1)
          OR NOT EXISTS (SELECT 1 FROM sys.extended_properties e WHERE e.class = 5
              AND e.major_id = @AssemblyId AND e.minor_id = 0 AND e.name = N'Toolbelt.Managed' AND TRY_CONVERT(int, e.value) = 1)
          OR NOT EXISTS (SELECT 1 FROM sys.extended_properties e WHERE e.class = 5
              AND e.major_id = @AssemblyId AND e.minor_id = 0 AND e.name = N'Toolbelt.ModuleId'
              AND CONVERT(varbinary(max), TRY_CONVERT(nvarchar(max), e.value)) = CONVERT(varbinary(max), N'toolbelt.string.edit-distance'))
          OR (@Release IN (10,11) AND NOT EXISTS (SELECT 1 FROM sys.extended_properties e WHERE e.class = 5
              AND e.major_id = @AssemblyId AND e.minor_id = 0 AND e.name = N'Toolbelt.ModuleVersion'
              AND CONVERT(varbinary(max), TRY_CONVERT(nvarchar(max), e.value)) = CONVERT(varbinary(max), @InstalledVersion))))
            THROW 55033, N'Die installierte Assembly-Zuordnung ist nicht kohärent.', 4;
        IF EXISTS (SELECT 1 FROM sys.sql_expression_dependencies d
              JOIN @Slots s ON s.ObjectId = d.referenced_id AND s.SinceRelease <= @Release
              WHERE NOT EXISTS (SELECT 1 FROM @Slots own WHERE own.ObjectId = d.referencing_id AND own.SinceRelease <= @Release))
            THROW 55038, N'Eine fremde same-database Dependency blockiert den Lifecycle.', 1;
        IF EXISTS (SELECT 1 FROM sys.assembly_modules m WHERE m.assembly_id = @AssemblyId
              AND NOT EXISTS (SELECT 1 FROM @Slots s WHERE s.ObjectId = m.object_id AND s.SinceRelease <= @Release AND s.Kind IN ('FS', 'FT')))
           OR EXISTS (SELECT 1 FROM sys.assembly_references WHERE referenced_assembly_id = @AssemblyId)
            THROW 55038, N'Ein fremder Assembly-Verbraucher blockiert den Lifecycle.', 2;
        IF EXISTS (SELECT 1 FROM @Slots s JOIN sys.assembly_modules m ON m.object_id = s.ObjectId
              WHERE s.SinceRelease <= @Release AND s.Kind IN ('FS', 'FT') AND m.assembly_id <> @AssemblyId)
            THROW 55033, N'Ein CLR-Kern verweist auf eine andere Assembly.', 5;
        IF NOT EXISTS (SELECT 1 FROM sys.configurations WHERE name = N'clr enabled' AND value_in_use = 1)
            THROW 55040, N'CLR ist nicht aktiviert; der Lifecycle ändert keine Instanzoption.', 1;
        IF NOT EXISTS (SELECT 1 FROM sys.configurations WHERE name = N'clr strict security' AND value_in_use = 1)
            THROW 55042, N'clr strict security muss aktiviert bleiben.', 1;
        IF @AssemblyHash IS NULL OR NOT EXISTS (SELECT 1 FROM sys.trusted_assemblies WHERE hash = @AssemblyHash)
            THROW 55045, N'Der exakte Release-Hash ist nicht freigegeben.', 1;
        -- Neue Slots gehören keinem Vorgängerrelease, auch mit imitierten Markern.
        IF EXISTS (SELECT 1 FROM @Slots WHERE SinceRelease > @Release AND ObjectId IS NOT NULL)
            OR (@Release = 0 AND (@AssemblyId IS NOT NULL OR EXISTS (SELECT 1 FROM sys.extended_properties WHERE class=0 AND major_id=0 AND minor_id=0 AND name=@ModeProperty)))
            THROW 55033, N'Ein Zielslot oder die Assembly ist fremd belegt.', 6;
        IF SCHEMA_ID(N'toolbelt_string') IS NULL AND ISNULL(HAS_PERMS_BY_NAME(DB_NAME(), N'DATABASE', N'CREATE SCHEMA'), 0) <> 1
            THROW 55034, N'CREATE SCHEMA fehlt.', 1;
        IF SCHEMA_ID(N'toolbelt_string') IS NOT NULL AND ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_string', N'SCHEMA', N'ALTER'), 0) <> 1
            THROW 55034, N'ALTER auf toolbelt_string fehlt.', 2;
        IF ISNULL(HAS_PERMS_BY_NAME(DB_NAME(), N'DATABASE', N'CREATE FUNCTION'), 0) <> 1
            THROW 55034, N'CREATE FUNCTION fehlt.', 3;
        IF @AssemblyId IS NULL AND ISNULL(HAS_PERMS_BY_NAME(DB_NAME(), N'DATABASE', N'CREATE ASSEMBLY'), 0) <> 1
            THROW 55034, N'CREATE ASSEMBLY fehlt.', 4;
        IF @AssemblyId IS NOT NULL AND @InstalledAssemblyHash <> @AssemblyHash
           AND ISNULL(HAS_PERMS_BY_NAME(DB_NAME(), N'DATABASE', N'ALTER ANY ASSEMBLY'), 0) <> 1
            THROW 55034, N'ALTER ANY ASSEMBLY fehlt.', 5;
        IF @Pass = 1
        BEGIN
            BEGIN TRANSACTION;
            SET @OwnTransaction = 1;
            DECLARE @LockResult int;
            EXEC @LockResult = sys.sp_getapplock
                  @Resource = N'toolbelt.deploy.toolbelt.string.edit-distance',
                  @LockMode = N'Exclusive', @LockOwner = N'Transaction',
                  @LockTimeout = 0, @DbPrincipal = N'public';
            IF @LockResult < 0
                THROW 55035, N'Ein paralleler Editierdistanz-Lifecycle ist bereits aktiv.', 1;
        END;
        SET @Pass += 1;
    END;
    IF SCHEMA_ID(N'toolbelt_string') IS NULL
    BEGIN
        EXEC sys.sp_executesql N'CREATE SCHEMA [toolbelt_string];';
        EXEC sys.sp_addextendedproperty @name = N'Toolbelt.Managed', @value = 1,
             @level0type = N'SCHEMA', @level0name = N'toolbelt_string';
        EXEC sys.sp_addextendedproperty @name = N'Toolbelt.SchemaCategory', @value = N'string',
             @level0type = N'SCHEMA', @level0name = N'toolbelt_string';
    END;
    IF @Release IN (10,11)
    BEGIN
        IF @Release=11
        BEGIN
            DROP FUNCTION [toolbelt_string].[TVF_JaroWinklerSimilarity];
            DROP FUNCTION [toolbelt_string].[TVF_JaroWinklerSimilarityCore];
        END;
        DROP FUNCTION [toolbelt_string].[TVF_LevenshteinDistance];
        DROP FUNCTION [toolbelt_string].[TVF_OsaDistance];
        DROP FUNCTION [toolbelt_string].[TVF_LevenshteinDistanceCore];
        DROP FUNCTION [toolbelt_string].[TVF_OsaDistanceCore];
    END;
    IF @InstalledAssemblyHash IS NULL OR @InstalledAssemblyHash <> @AssemblyHash
    BEGIN
        DECLARE @AssemblyDdl nvarchar(max) =
            CASE WHEN @AssemblyId IS NULL THEN N'CREATE' ELSE N'ALTER' END
            + N' ASSEMBLY [Toolbelt_String_EditDistance] FROM ' + CONVERT(nvarchar(max), @AssemblyBits, 1)
            + N' WITH PERMISSION_SET = SAFE;';
        EXEC sys.sp_executesql @AssemblyDdl;
    END;
END TRY
BEGIN CATCH
    IF @OwnTransaction = 1 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

:r ../Source/EditDistance.sql
:r ../Source/JaroWinkler.sql

SET NOCOUNT ON;
BEGIN TRY
    IF @@TRANCOUNT <> 1
        THROW 55039, N'Die Deployment-Transaktion ist vorzeitig beendet worden.', 1;

    DECLARE
          @VersionProperty sysname =
              N'Toolbelt.Module.toolbelt.string.edit-distance.Version'
        , @ModeProperty sysname =
              N'Toolbelt.Module.toolbelt.string.edit-distance.DeploymentMode'
        , @DeploymentMode nvarchar(16) = N'$(DeploymentMode)';

    IF EXISTS (SELECT 1 FROM sys.extended_properties WHERE class = 0 AND name = @VersionProperty)
        EXEC sys.sp_updateextendedproperty @name = @VersionProperty, @value = N'1.1.0';
    ELSE
        EXEC sys.sp_addextendedproperty @name = @VersionProperty, @value = N'1.1.0';

    IF EXISTS (SELECT 1 FROM sys.extended_properties WHERE class = 0 AND name = @ModeProperty)
        EXEC sys.sp_updateextendedproperty @name = @ModeProperty, @value = @DeploymentMode;
    ELSE
        EXEC sys.sp_addextendedproperty @name = @ModeProperty, @value = @DeploymentMode;

    IF EXISTS
       (
           SELECT 1 FROM sys.extended_properties AS ep
           INNER JOIN sys.assemblies AS a ON a.assembly_id = ep.major_id
           WHERE ep.class = 5 AND ep.name = N'Toolbelt.Managed'
             AND a.name = N'Toolbelt_String_EditDistance'
       )
        EXEC sys.sp_updateextendedproperty
              @name = N'Toolbelt.Managed', @value = 1
            , @level0type = N'ASSEMBLY', @level0name = N'Toolbelt_String_EditDistance';
    ELSE
        EXEC sys.sp_addextendedproperty
              @name = N'Toolbelt.Managed', @value = 1
            , @level0type = N'ASSEMBLY', @level0name = N'Toolbelt_String_EditDistance';

    IF EXISTS
       (
           SELECT 1 FROM sys.extended_properties AS ep
           INNER JOIN sys.assemblies AS a ON a.assembly_id = ep.major_id
           WHERE ep.class = 5 AND ep.name = N'Toolbelt.ModuleId'
             AND a.name = N'Toolbelt_String_EditDistance'
       )
        EXEC sys.sp_updateextendedproperty
              @name = N'Toolbelt.ModuleId', @value = N'toolbelt.string.edit-distance'
            , @level0type = N'ASSEMBLY', @level0name = N'Toolbelt_String_EditDistance';
    ELSE
        EXEC sys.sp_addextendedproperty
              @name = N'Toolbelt.ModuleId', @value = N'toolbelt.string.edit-distance'
            , @level0type = N'ASSEMBLY', @level0name = N'Toolbelt_String_EditDistance';

    IF EXISTS (SELECT 1 FROM sys.extended_properties e JOIN sys.assemblies a ON a.assembly_id = e.major_id
               WHERE e.class = 5 AND e.name = N'Toolbelt.ModuleVersion' AND a.name = N'Toolbelt_String_EditDistance')
        EXEC sys.sp_updateextendedproperty @name = N'Toolbelt.ModuleVersion', @value = N'1.1.0',
             @level0type = N'ASSEMBLY', @level0name = N'Toolbelt_String_EditDistance';
    ELSE
        EXEC sys.sp_addextendedproperty @name = N'Toolbelt.ModuleVersion', @value = N'1.1.0',
             @level0type = N'ASSEMBLY', @level0name = N'Toolbelt_String_EditDistance';

    DECLARE @FunctionName sysname;
    DECLARE FunctionCursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT name
        FROM sys.objects
        WHERE schema_id = SCHEMA_ID(N'toolbelt_string')
          AND name IN (N'TVF_LevenshteinDistance', N'TVF_OsaDistance', N'TVF_LevenshteinDistanceCore', N'TVF_OsaDistanceCore', N'TVF_JaroWinklerSimilarity', N'TVF_JaroWinklerSimilarityCore');
    OPEN FunctionCursor;
    FETCH NEXT FROM FunctionCursor INTO @FunctionName;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXEC sys.sp_addextendedproperty
              @name = N'Toolbelt.Managed', @value = 1
            , @level0type = N'SCHEMA', @level0name = N'toolbelt_string'
            , @level1type = N'FUNCTION', @level1name = @FunctionName;
        EXEC sys.sp_addextendedproperty
              @name = N'Toolbelt.ModuleId', @value = N'toolbelt.string.edit-distance'
            , @level0type = N'SCHEMA', @level0name = N'toolbelt_string'
            , @level1type = N'FUNCTION', @level1name = @FunctionName;
        EXEC sys.sp_addextendedproperty
              @name = N'Toolbelt.ModuleVersion', @value = N'1.1.0'
            , @level0type = N'SCHEMA', @level0name = N'toolbelt_string'
            , @level1type = N'FUNCTION', @level1name = @FunctionName;
        DECLARE @Visibility nvarchar(16) = CASE WHEN @FunctionName IN (N'TVF_LevenshteinDistanceCore', N'TVF_OsaDistanceCore', N'TVF_JaroWinklerSimilarityCore') THEN N'internal' ELSE N'public' END;
        EXEC sys.sp_addextendedproperty
              @name = N'Toolbelt.Visibility', @value = @Visibility
            , @level0type = N'SCHEMA', @level0name = N'toolbelt_string'
            , @level1type = N'FUNCTION', @level1name = @FunctionName;
        FETCH NEXT FROM FunctionCursor INTO @FunctionName;
    END;
    CLOSE FunctionCursor;
    DEALLOCATE FunctionCursor;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF CURSOR_STATUS(N'local', N'FunctionCursor') >= 0 CLOSE FunctionCursor;
    IF CURSOR_STATUS(N'local', N'FunctionCursor') > -3 DEALLOCATE FunctionCursor;
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
