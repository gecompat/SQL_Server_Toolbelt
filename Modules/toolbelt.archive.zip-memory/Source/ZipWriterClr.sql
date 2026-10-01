SET ANSI_NULLS ON;
-- Interne CLR-Status-TVFs, Modul1.3.0; keine öffentliche Fach-API.
-- Zweck: validierter UTF8-Namenstransport und bounded Binary-Envelope→ZIP.
-- DataAccess/SystemDataAccess None; keine Datenabfrage/Datei-I/O/Rechteausweitung.
-- Eine Statuszeile ErrorNumber/ErrorMessage/Payload; USP setzt TSQL-THROW um.
-- Erwartete Fehler51350–51359, unerwartete Enginefehler bleiben Originalfehler.
-- Dependency: Toolbelt_Archive_ZipMemory, Assemblyrelease 1.3.0 (SAFE).
SET QUOTED_IDENTIFIER ON;
GO
-- Name-Binding: strenges UTF-16-Validieren vor UTF-8-Encoding; eine Statuszeile.
CREATE FUNCTION toolbelt_archive.TVF_InternalZipWriterName(@Name nvarchar(max), @MaxUnits int)
RETURNS TABLE(ErrorNumber int, ErrorMessage nvarchar(4000), Payload varbinary(max))
AS EXTERNAL NAME [Toolbelt_Archive_ZipMemory].[Toolbelt.Archive.ZipMemory.ZipEntryProvider].[EncodeWriterNameStatus];
GO
-- Archive-Binding: TBZW-Version-1-Envelope ohne ContextConnection/Dateifallback;
-- vollständiges Stored-/Deflate-ZIP oder erwarteter Statusfehler, nie Teiloutput.
CREATE FUNCTION toolbelt_archive.TVF_InternalZipWriterArchive
(@Envelope varbinary(max), @Method int, @MaxEntries int, @MaxNameUnits int,
 @MaxEntry bigint, @MaxTotal bigint, @MaxArchive bigint, @MaxEnvelope bigint, @Budget int)
RETURNS TABLE(ErrorNumber int, ErrorMessage nvarchar(4000), Payload varbinary(max))
AS EXTERNAL NAME [Toolbelt_Archive_ZipMemory].[Toolbelt.Archive.ZipMemory.ZipEntryProvider].[CreateWriterArchiveStatus];
GO
