:On Error exit
-- Nur eigene leere Installationsdatenbank mit Second Session 1.1.0.
-- Aus Deployment/ mit DeploymentMode=local beziehungsweise central aufrufen.
-- Tabellenrepeat ohne Configure-USP, RPC, Serververwaltung oder Rechteänderung.
SET NOCOUNT ON;
SET XACT_ABORT ON;
IF @@TRANCOUNT <> 0
    THROW 52674, N'Der Provider-Repeat benötigt eine eigene Session ohne Callertransaktion.', 1;
IF (2 & @@OPTIONS) = 2
    THROW 52674, N'Der Provider-Repeat benötigt IMPLICIT_TRANSACTIONS OFF.', 1;
IF OBJECT_ID(N'toolbelt_core.SecondSessionProvider', N'U') IS NULL
    THROW 52674, N'Der Provider-Repeat benötigt eine installierte Providertabelle.', 1;
IF EXISTS (SELECT 1 FROM toolbelt_core.SecondSessionProvider)
    THROW 52674, N'Der Provider-Repeat benötigt eine leere eigene Providertabelle.', 1;
IF EXISTS
   (SELECT 1 FROM sys.extended_properties WHERE class = 1
    AND major_id = OBJECT_ID(N'toolbelt_core.SecondSessionProvider', N'U')
    AND ((name = N'Toolbelt.Test.SecondSessionRepeat')
      OR (name = N'MS_Description' AND minor_id IN
         (0, COLUMNPROPERTY(OBJECT_ID(N'toolbelt_core.SecondSessionProvider', N'U'),
                            N'LinkedServerName', 'ColumnId')))))
    THROW 52674, N'Einer der eigenen Provider-Annotationsnamen ist bereits belegt.', 1;
IF NOT EXISTS (SELECT 1 FROM sys.extended_properties WHERE class = 0
               AND name = N'Toolbelt.Module.toolbelt.core.second-session.Version'
               AND CONVERT(nvarchar(64), value) = N'1.1.0')
    THROW 52674, N'Der Provider-Repeat benötigt Version 1.1.0.', 1;
IF NOT EXISTS (SELECT 1 FROM sys.extended_properties WHERE class = 0
               AND name = N'Toolbelt.Module.toolbelt.core.second-session.DeploymentMode'
               AND CONVERT(nvarchar(64), value) = LOWER(N'$(DeploymentMode)'))
    THROW 52674, N'Der Provider-Repeat benötigt den bereits installierten Deploymentmodus.', 1;

CREATE TABLE #tbx_SecondSessionRepeat_State (Phase int NOT NULL);
INSERT #tbx_SecondSessionRepeat_State VALUES (0);
CREATE TABLE #tbx_SecondSessionRepeat_Snapshot
    (Phase int NOT NULL, Category varchar(32) COLLATE Latin1_General_100_BIN2 NOT NULL,
     Payload varbinary(max) NOT NULL, PRIMARY KEY (Phase, Category));

-- PK und CK erlauben genau einen loopback-Eintrag. Der synthetische Name
-- wird nur als deaktivierter Tabellenwert gespeichert, niemals aufgerufen.
-- Beide Auditzeitpunkte sind verschieden und enthalten 100-ns-Anteile.
INSERT toolbelt_core.SecondSessionProvider
    (ProviderName, LinkedServerName, IsEnabled, CreatedAtUtc, CreatedBy,
     ModifiedAtUtc, ModifiedBy)
VALUES ('loopback', N'localhost', 0, '2026-01-02T03:04:05.1234567', N'Synthetic creator ä ',
        '2026-02-03T04:05:06.0000001', N'Synthetic modifier 中 ');
-- Bereits veränderter Rowversionwert vor der Baseline, ohne Aktivierung.
UPDATE toolbelt_core.SecondSessionProvider SET IsEnabled = 0 WHERE ProviderName = 'loopback';
EXEC sys.sp_addextendedproperty @name = N'Toolbelt.Test.SecondSessionRepeat',
     @value = N'Synthetic provider table annotation ä ',
     @level0type = N'SCHEMA', @level0name = N'toolbelt_core',
     @level1type = N'TABLE', @level1name = N'SecondSessionProvider';
EXEC sys.sp_addextendedproperty @name = N'Toolbelt.Test.SecondSessionRepeat',
     @value = N'Synthetic provider column annotation 中 ',
     @level0type = N'SCHEMA', @level0name = N'toolbelt_core',
     @level1type = N'TABLE', @level1name = N'SecondSessionProvider',
     @level2type = N'COLUMN', @level2name = N'LinkedServerName';
-- Keine kanonische Erneuerung im bestehenden Installer: beide Beschreibungen
-- bleiben ebenso wie eigene Annotationen typ-/längen-/bytegleich erhalten.
EXEC sys.sp_addextendedproperty @name = N'MS_Description',
     @value = N'Synthetic provider table description ä ',
     @level0type = N'SCHEMA', @level0name = N'toolbelt_core',
     @level1type = N'TABLE', @level1name = N'SecondSessionProvider';
EXEC sys.sp_addextendedproperty @name = N'MS_Description',
     @value = N'Synthetic provider column description 中 ',
     @level0type = N'SCHEMA', @level0name = N'toolbelt_core',
     @level1type = N'TABLE', @level1name = N'SecondSessionProvider',
     @level2type = N'COLUMN', @level2name = N'LinkedServerName';
GO
:r ../Tests/Runtime/RepeatCurrent.Capture.sql

UPDATE #tbx_SecondSessionRepeat_State SET Phase = 1;
GO
:r Deploy.sql
:r ../Tests/Runtime/RepeatCurrent.Capture.sql
:r ../Tests/Runtime/RepeatCurrent.Assert.sql

UPDATE #tbx_SecondSessionRepeat_State SET Phase = 2;
GO
:r Deploy.sql
:r ../Tests/Runtime/RepeatCurrent.Capture.sql
:r ../Tests/Runtime/RepeatCurrent.Assert.sql

-- Die View darf den deaktivierten Eintrag lesen; keine Provider-Probe.
IF (SELECT COUNT(*) FROM toolbelt_core.VW_SecondSessionProviders) <> 1
    THROW 52675, N'Die Provider-View hat den erhaltenen Eintrag verloren.', 1;
IF NOT EXISTS
   (SELECT 1 FROM toolbelt_core.VW_SecondSessionProviders WHERE ProviderName = 'loopback'
    AND IsEnabled = 0 AND CONVERT(varbinary(256), LinkedServerName) = CONVERT(varbinary(256), N'localhost'))
    THROW 52675, N'Die Provider-View zeigt keinen unverändert deaktivierten Eintrag.', 1;

-- Der eigene Eingang war leer; der Bytevergleich schützt die Fixture bis hier.
DELETE toolbelt_core.SecondSessionProvider WHERE ProviderName = 'loopback'
    AND IsEnabled = 0 AND CONVERT(varbinary(256), LinkedServerName) = CONVERT(varbinary(256), N'localhost');
IF EXISTS (SELECT 1 FROM toolbelt_core.SecondSessionProvider)
    THROW 52676, N'Die eigene Provider-Fixture wurde nicht bereinigt.', 1;
EXEC sys.sp_dropextendedproperty @name = N'Toolbelt.Test.SecondSessionRepeat',
     @level0type = N'SCHEMA', @level0name = N'toolbelt_core',
     @level1type = N'TABLE', @level1name = N'SecondSessionProvider';
EXEC sys.sp_dropextendedproperty @name = N'Toolbelt.Test.SecondSessionRepeat',
     @level0type = N'SCHEMA', @level0name = N'toolbelt_core',
     @level1type = N'TABLE', @level1name = N'SecondSessionProvider',
     @level2type = N'COLUMN', @level2name = N'LinkedServerName';
EXEC sys.sp_dropextendedproperty @name = N'MS_Description',
     @level0type = N'SCHEMA', @level0name = N'toolbelt_core',
     @level1type = N'TABLE', @level1name = N'SecondSessionProvider';
EXEC sys.sp_dropextendedproperty @name = N'MS_Description',
     @level0type = N'SCHEMA', @level0name = N'toolbelt_core',
     @level1type = N'TABLE', @level1name = N'SecondSessionProvider',
     @level2type = N'COLUMN', @level2name = N'LinkedServerName';
DROP TABLE #tbx_SecondSessionRepeat_Snapshot;
DROP TABLE #tbx_SecondSessionRepeat_State;
PRINT N'Second Session populated repeat (two cycles): successful';
GO
