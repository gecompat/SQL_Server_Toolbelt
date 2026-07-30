:setvar DeploymentMode local

-- Beispiel: File-Content-Modul lokal deployen.
-- sqlcmd -S localhost -d master -i Modules/toolbelt.file.content/Deployment/Deploy.sql -v DeploymentMode=local

-- Allowlist-Eintrag für synthetische Demodaten.
INSERT INTO [toolbelt_file].[FileContentRootAllowlist]
(
      RootPath
    , Description
)
VALUES
(
      N'/var/opt/mssql/data/allowed'
    , N'Synthetisches Demoverzeichnis für File-Content-Tests.'
);

-- Hilfe anzeigen.
EXEC [toolbelt_file].[USP_LoadBinaryFile] @Hilfe = 1;
EXEC [toolbelt_file].[USP_LoadTextFile]   @Hilfe = 1;

-- Beispielaufrufe (erfordern existierende Dateien im erlaubten Pfad).
-- EXEC [toolbelt_file].[USP_LoadBinaryFile]
--       @FilePath = N'/var/opt/mssql/data/allowed/sample.bin';
--
-- EXEC [toolbelt_file].[USP_LoadTextFile]
--       @FilePath = N'/var/opt/mssql/data/allowed/sample.txt';
