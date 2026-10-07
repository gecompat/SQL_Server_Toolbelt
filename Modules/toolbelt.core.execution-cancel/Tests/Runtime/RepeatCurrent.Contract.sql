:On Error exit
-- Nur eigene leere Testdatenbank mit installiertem Cancellation 1.0.0.
-- Aus Deployment/ mit DeploymentMode=local beziehungsweise central aufrufen.
-- Zwei echte Deploys; keine neue API, Rechte-, Config- oder Provideränderung.
SET NOCOUNT ON;
SET XACT_ABORT ON;
IF @@TRANCOUNT <> 0
    THROW 52740, N'Der Repeat-Test benötigt eine eigene Session ohne Callertransaktion.', 1;
IF (2 & @@OPTIONS) = 2
    THROW 52740, N'Der Repeat-Test benötigt IMPLICIT_TRANSACTIONS OFF.', 1;
IF OBJECT_ID(N'toolbelt_core.ExecutionCancellation', N'U') IS NULL
    THROW 52740, N'Der Repeat-Test benötigt eine installierte Cancellation-Tabelle.', 1;
IF EXISTS (SELECT 1 FROM toolbelt_core.ExecutionCancellation)
    THROW 52740, N'Der Repeat-Test benötigt eine leere eigene Cancellation-Tabelle.', 1;
IF EXISTS (SELECT 1 FROM sys.extended_properties WHERE class = 1
           AND major_id = OBJECT_ID(N'toolbelt_core.ExecutionCancellation', N'U')
           AND ((name = N'Toolbelt.Test.CancellationRepeat')
             OR (name = N'MS_Description' AND minor_id IN
                (0, COLUMNPROPERTY(OBJECT_ID(N'toolbelt_core.ExecutionCancellation', N'U'),
                                   N'CancellationReason', 'ColumnId')))))
    THROW 52740, N'Einer der eigenen Repeat-Annotationsnamen ist bereits belegt.', 1;
IF NOT EXISTS (SELECT 1 FROM sys.extended_properties WHERE class = 0
               AND name = N'Toolbelt.Module.toolbelt.core.execution-cancel.Version'
               AND CONVERT(nvarchar(64), value) = N'1.0.0')
    THROW 52740, N'Der Repeat-Test benötigt Version 1.0.0.', 1;
IF NOT EXISTS (SELECT 1 FROM sys.extended_properties WHERE class = 0
               AND name = N'Toolbelt.Module.toolbelt.core.execution-cancel.DeploymentMode'
               AND CONVERT(nvarchar(64), value) = LOWER(N'$(DeploymentMode)'))
    THROW 52740, N'Der Repeat-Test benötigt den bereits installierten Deploymentmodus.', 1;

CREATE TABLE #tbx_CancellationRepeat_State (Phase int NOT NULL);
INSERT #tbx_CancellationRepeat_State VALUES (0);
CREATE TABLE #tbx_CancellationRepeat_Snapshot
    (Phase int NOT NULL, Category varchar(32) COLLATE Latin1_General_100_BIN2 NOT NULL,
     Payload varbinary(max) NOT NULL, PRIMARY KEY (Phase, Category));

-- Deterministische Auditwerte vermeiden reale Login-/Laufzeitdaten.
-- NULL, Leerstring, Unicode, Padding und 100-ns-Anteile bleiben unterscheidbar.
INSERT toolbelt_core.ExecutionCancellation
    (ExecutionId, RequestedAtUtc, RequestedBy, CancellationReason)
VALUES ('00000000-0000-0000-0000-000000000041', '2026-01-02T03:04:05.1234567', N'Synthetic requester', NULL),
       ('00000000-0000-0000-0000-000000000042', '2026-02-03T04:05:06.0000001', N'Synthetic empty', N''),
       ('00000000-0000-0000-0000-000000000043', '2026-03-04T05:06:07.9999999', N'Synthetic ä 中', N'Unicode ä 中 '),
       ('00000000-0000-0000-0000-000000000044', '2026-04-05T06:07:08.0000000', N'Synthetic trailing ', N' ');
-- Ein bereits veränderter Rowversionwert muss ebenfalls bytegleich überleben.
UPDATE toolbelt_core.ExecutionCancellation SET CancellationReason = N'Unicode ä 中 '
WHERE ExecutionId = '00000000-0000-0000-0000-000000000043';
EXEC sys.sp_addextendedproperty @name = N'Toolbelt.Test.CancellationRepeat',
     @value = N'Synthetic table annotation ä ',
     @level0type = N'SCHEMA', @level0name = N'toolbelt_core',
     @level1type = N'TABLE', @level1name = N'ExecutionCancellation';
EXEC sys.sp_addextendedproperty @name = N'Toolbelt.Test.CancellationRepeat',
     @value = N'Synthetic column annotation 中 ',
     @level0type = N'SCHEMA', @level0name = N'toolbelt_core',
     @level1type = N'TABLE', @level1name = N'ExecutionCancellation',
     @level2type = N'COLUMN', @level2name = N'CancellationReason';
-- Dieser Installer erneuert keine Beschreibung. Daher bleibt auch eine
-- nichtleere MS_Description an Tabelle und Spalte exakt erhalten.
EXEC sys.sp_addextendedproperty @name = N'MS_Description',
     @value = N'Synthetic cancellation table description ä ',
     @level0type = N'SCHEMA', @level0name = N'toolbelt_core',
     @level1type = N'TABLE', @level1name = N'ExecutionCancellation';
EXEC sys.sp_addextendedproperty @name = N'MS_Description',
     @value = N'Synthetic cancellation reason description 中 ',
     @level0type = N'SCHEMA', @level0name = N'toolbelt_core',
     @level1type = N'TABLE', @level1name = N'ExecutionCancellation',
     @level2type = N'COLUMN', @level2name = N'CancellationReason';
GO
:r ../Tests/Runtime/RepeatCurrent.Capture.sql

UPDATE #tbx_CancellationRepeat_State SET Phase = 1;
GO
:r Deploy.sql
:r ../Tests/Runtime/RepeatCurrent.Capture.sql
:r ../Tests/Runtime/RepeatCurrent.Assert.sql

UPDATE #tbx_CancellationRepeat_State SET Phase = 2;
GO
:r Deploy.sql
:r ../Tests/Runtime/RepeatCurrent.Capture.sql
:r ../Tests/Runtime/RepeatCurrent.Assert.sql

-- Beide Repeats müssen das bestehende kooperative Signal weiterhin liefern.
IF EXISTS
   (SELECT 1 FROM toolbelt_core.ExecutionCancellation AS c
    OUTER APPLY toolbelt_core.TVF_ExecutionCancellationStatus(c.ExecutionId) AS s
    WHERE s.ExecutionId IS NULL OR s.IsCancellationRequested <> 1
       OR s.RequestedAtUtc <> c.RequestedAtUtc
       OR toolbelt_core.SVF_IsCancellationRequested(c.ExecutionId) <> 1)
    THROW 52744, N'Der Repeat hat den bestehenden Cancellation-Status verändert.', 1;

-- Der Eingang war leer und die eigene Fixture enthält ausschließlich vier IDs.
DELETE toolbelt_core.ExecutionCancellation
WHERE ExecutionId IN ('00000000-0000-0000-0000-000000000041',
                      '00000000-0000-0000-0000-000000000042',
                      '00000000-0000-0000-0000-000000000043',
                      '00000000-0000-0000-0000-000000000044');
IF EXISTS (SELECT 1 FROM toolbelt_core.ExecutionCancellation)
    THROW 52745, N'Die eigene Cancellation-Fixture wurde nicht bereinigt.', 1;
EXEC sys.sp_dropextendedproperty @name = N'Toolbelt.Test.CancellationRepeat',
     @level0type = N'SCHEMA', @level0name = N'toolbelt_core',
     @level1type = N'TABLE', @level1name = N'ExecutionCancellation';
EXEC sys.sp_dropextendedproperty @name = N'Toolbelt.Test.CancellationRepeat',
     @level0type = N'SCHEMA', @level0name = N'toolbelt_core',
     @level1type = N'TABLE', @level1name = N'ExecutionCancellation',
     @level2type = N'COLUMN', @level2name = N'CancellationReason';
EXEC sys.sp_dropextendedproperty @name = N'MS_Description',
     @level0type = N'SCHEMA', @level0name = N'toolbelt_core',
     @level1type = N'TABLE', @level1name = N'ExecutionCancellation';
EXEC sys.sp_dropextendedproperty @name = N'MS_Description',
     @level0type = N'SCHEMA', @level0name = N'toolbelt_core',
     @level1type = N'TABLE', @level1name = N'ExecutionCancellation',
     @level2type = N'COLUMN', @level2name = N'CancellationReason';
DROP TABLE #tbx_CancellationRepeat_Snapshot;
DROP TABLE #tbx_CancellationRepeat_State;
PRINT N'Execution Cancellation populated repeat (two cycles): successful';
GO
