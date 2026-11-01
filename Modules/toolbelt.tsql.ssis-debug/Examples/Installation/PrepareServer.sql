/*
Administrative Vorbereitung für die lokale SSIS-Debug-Demo.
In SSMS als vorhandener sysadmin auf dem bewusst ausgewählten Windows-
SQL-Server ausführen. @DemoDatabase bei Bedarf anpassen. Keine Labverwaltung.
Der Block kann CLR instanzweit aktivieren und eine neue Demodatenbank anlegen.
Vorhandene Datenbanken erhalten keine geänderten Optionen. Kein Trust-Opt-in.
*/
USE master;

IF @@TRANCOUNT <> 0 OR (@@OPTIONS & 2) <> 0
    THROW 50000, N'Eine Sitzung ohne offene oder implizite Transaktion verwenden.', 1;
IF ISNULL(IS_SRVROLEMEMBER(N'sysadmin'),0) <> 1
    THROW 50000, N'Dieses administrative Beispiel benötigt einen vorhandenen sysadmin-Zugang.', 1;
IF TRY_CONVERT(int, SERVERPROPERTY(N'ProductMajorVersion')) NOT IN (15,16,17)
   OR NOT EXISTS (SELECT 1 FROM sys.dm_os_host_info WITH (NOLOCK)
                  WHERE host_platform = N'Windows')
    THROW 50000, N'Windows SQL Server 2019, 2022 oder 2025 erforderlich.', 1;
IF EXISTS (SELECT 1 FROM sys.configurations WITH (NOLOCK)
           WHERE CONVERT(int,value) <> CONVERT(int,value_in_use)
             -- SQL dokumentiert diese Defaultdarstellungen als erwartete
             -- Abweichung, nicht als ausstehende Änderung. Keine Speicher-
             -- konfiguration schreiben; alle anderen Abweichungen sperren.
             -- https://learn.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-configurations-transact-sql
             AND NOT (CONVERT(int,value)=0 AND (
                 (name=N'min server memory (MB)' AND CONVERT(int,value_in_use) IN (8,16))
                 OR (name=N'max server memory (MB)' AND CONVERT(int,value_in_use)=2147483647))))
    THROW 50000, N'Zuerst ausstehende Serverkonfigurationsänderungen prüfen.', 1;
IF EXISTS (SELECT 1 FROM sys.configurations WITH (NOLOCK)
           WHERE name = N'lightweight pooling' AND value_in_use = 1)
    THROW 50000, N'CLR ist mit lightweight pooling nicht kompatibel.', 1;
IF NOT EXISTS (SELECT 1 FROM sys.configurations WITH (NOLOCK)
               WHERE name = N'clr strict security' AND value_in_use = 1)
    THROW 50000, N'Voraussetzung: clr strict security muss aktiviert sein.', 1;

DECLARE @DemoDatabase sysname = N'ContosoSsisDebug';
IF NULLIF(LTRIM(RTRIM(@DemoDatabase)),N'') IS NULL
   OR @DemoDatabase IN (N'master',N'model',N'msdb',N'tempdb')
    THROW 50000, N'Eine eigene benannte Demodatenbank verwenden.', 1;
IF DB_ID(@DemoDatabase) IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM sys.databases WITH (NOLOCK)
                   WHERE name = @DemoDatabase AND state = 0
                     AND compatibility_level IN (150,160,170))
    THROW 50000, N'Vorhandene Demodatenbank muss ONLINE sein und CL150/160/170 verwenden.', 1;

IF EXISTS (SELECT 1 FROM sys.configurations WITH (NOLOCK)
           WHERE name = N'clr enabled' AND value_in_use = 0)
BEGIN
    EXEC sys.sp_configure N'clr enabled', 1;
    RECONFIGURE;
END;
IF NOT EXISTS (SELECT 1 FROM sys.configurations WITH (NOLOCK)
               WHERE name = N'clr enabled' AND value_in_use = 1)
    THROW 50000, N'CLR wurde nicht wirksam aktiviert.', 1;

IF DB_ID(@DemoDatabase) IS NULL
BEGIN
    DECLARE @Sql nvarchar(max) = N'CREATE DATABASE ' + QUOTENAME(@DemoDatabase) + N';';
    EXEC sys.sp_executesql @Sql;
    SET @Sql = N'ALTER DATABASE ' + QUOTENAME(@DemoDatabase)
             + N' SET COMPATIBILITY_LEVEL = 150;';
    EXEC sys.sp_executesql @Sql;
END;
