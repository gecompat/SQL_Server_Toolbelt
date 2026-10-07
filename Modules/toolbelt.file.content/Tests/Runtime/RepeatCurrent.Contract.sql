:On Error exit
-- Ausschließlich eigene leere Testdatenbank, installiertes File Content 1.0.0.
-- Aus Deployment/ aufrufen: die echten Deploy-Includes bleiben unverändert.
-- Keine Datei-I/O, Serverkonfiguration, Grants oder zusätzliche SQL-Funktion.
SET NOCOUNT ON;
SET XACT_ABORT ON;
IF @@TRANCOUNT <> 0
    THROW 52945, N'Der Repeat-Test benötigt eine eigene Session ohne Callertransaktion.', 1;
IF (2 & @@OPTIONS) = 2
    THROW 52945, N'Der Repeat-Test benötigt IMPLICIT_TRANSACTIONS OFF.', 1;
IF OBJECT_ID(N'toolbelt_file.FileContentRootAllowlist', N'U') IS NULL
    THROW 52945, N'Der Repeat-Test benötigt eine installierte Allowlist.', 1;
IF EXISTS (SELECT 1 FROM toolbelt_file.FileContentRootAllowlist)
    THROW 52945, N'Der Repeat-Test benötigt eine leere eigene Allowlist.', 1;
IF EXISTS (SELECT 1 FROM sys.extended_properties WHERE class = 1
           AND major_id = OBJECT_ID(N'toolbelt_file.FileContentRootAllowlist', N'U')
           AND name = N'Toolbelt.Test.FileContentRepeat')
    THROW 52945, N'Die synthetische Repeat-Annotation ist bereits belegt.', 1;
IF NOT EXISTS
   (SELECT 1 FROM sys.extended_properties WHERE class = 0 AND name =
        N'Toolbelt.Module.toolbelt.file.content.Version' AND CONVERT(nvarchar(64), value) = N'1.0.0')
    THROW 52945, N'Der Repeat-Test benötigt Version 1.0.0.', 1;

CREATE TABLE #tbx_FileContentRepeat_State (Phase int NOT NULL, LastIdentity decimal(38,0) NULL);
INSERT #tbx_FileContentRepeat_State (Phase) VALUES (0);
CREATE TABLE #tbx_FileContentRepeat_Snapshot
    (Phase int NOT NULL, Category varchar(32) COLLATE Latin1_General_100_BIN2 NOT NULL,
     Payload varbinary(max) NOT NULL, PRIMARY KEY (Phase, Category));

INSERT toolbelt_file.FileContentRootAllowlist (RootPath, Description, IsActive, CreatedAt)
VALUES (N'/synthetic/file-content/active', N'Active root', 1, '2026-01-02T03:04:05'),
       (N'/synthetic/file-content/inactive', NULL, 0, '2026-02-03T04:05:06'),
       (N'/synthetic/file-content/Unicode-ä-中', N'Unicode ä 中 ', 1, '2026-03-04T05:06:07'),
       (N'/synthetic/file-content/trailing ', N'', 0, '2026-04-05T06:07:08');
-- Verbrauchte Identity oberhalb MAX(id): ein Rebuild aus Zeilen würde sie verlieren.
INSERT toolbelt_file.FileContentRootAllowlist (RootPath) VALUES (N'/synthetic/file-content/deleted');
DELETE toolbelt_file.FileContentRootAllowlist WHERE RootPath = N'/synthetic/file-content/deleted';
UPDATE #tbx_FileContentRepeat_State
SET LastIdentity = IDENT_CURRENT(N'toolbelt_file.FileContentRootAllowlist');
EXEC sys.sp_updateextendedproperty @name = N'MS_Description', @value = N'Synthetic stale description',
     @level0type = N'SCHEMA', @level0name = N'toolbelt_file',
     @level1type = N'TABLE', @level1name = N'FileContentRootAllowlist';
EXEC sys.sp_addextendedproperty @name = N'Toolbelt.Test.FileContentRepeat', @value = N'Synthetic table annotation ä ',
     @level0type = N'SCHEMA', @level0name = N'toolbelt_file',
     @level1type = N'TABLE', @level1name = N'FileContentRootAllowlist';
EXEC sys.sp_addextendedproperty @name = N'Toolbelt.Test.FileContentRepeat', @value = N'Synthetic column annotation 中 ',
     @level0type = N'SCHEMA', @level0name = N'toolbelt_file',
     @level1type = N'TABLE', @level1name = N'FileContentRootAllowlist',
     @level2type = N'COLUMN', @level2name = N'Description';
GO
:r ../Tests/Runtime/RepeatCurrent.Capture.sql

UPDATE #tbx_FileContentRepeat_State SET Phase = 1;
GO
:r Deploy.sql
:r ../Tests/Runtime/RepeatCurrent.Capture.sql
:r ../Tests/Runtime/RepeatCurrent.Assert.sql

UPDATE #tbx_FileContentRepeat_State SET Phase = 2;
GO
:r Deploy.sql
:r ../Tests/Runtime/RepeatCurrent.Capture.sql
:r ../Tests/Runtime/RepeatCurrent.Assert.sql

-- Zusätzlicher DML-Witness nach beiden Repeats: nächster regulärer Identitywert.
INSERT toolbelt_file.FileContentRootAllowlist (RootPath) VALUES (N'/synthetic/file-content/next');
IF CONVERT(decimal(38,0), SCOPE_IDENTITY()) <> (SELECT LastIdentity + 1 FROM #tbx_FileContentRepeat_State)
    THROW 52946, N'Der Repeat hat den nächsten Identitywert verändert.', 1;
DELETE toolbelt_file.FileContentRootAllowlist;
IF EXISTS (SELECT 1 FROM toolbelt_file.FileContentRootAllowlist)
    THROW 52947, N'Die eigene Allowlist-Fixture wurde nicht bereinigt.', 1;
EXEC sys.sp_dropextendedproperty @name = N'Toolbelt.Test.FileContentRepeat',
     @level0type = N'SCHEMA', @level0name = N'toolbelt_file',
     @level1type = N'TABLE', @level1name = N'FileContentRootAllowlist';
EXEC sys.sp_dropextendedproperty @name = N'Toolbelt.Test.FileContentRepeat',
     @level0type = N'SCHEMA', @level0name = N'toolbelt_file',
     @level1type = N'TABLE', @level1name = N'FileContentRootAllowlist',
     @level2type = N'COLUMN', @level2name = N'Description';
DROP TABLE #tbx_FileContentRepeat_Snapshot;
DROP TABLE #tbx_FileContentRepeat_State;
PRINT N'File Content populated repeat (two cycles): successful';
GO
