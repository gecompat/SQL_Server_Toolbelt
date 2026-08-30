:On Error exit
SET NOCOUNT ON;

/*
 * Separater administrativer Opt-in. Dieses Skript aktiviert CLR nicht und
 * verändert clr strict security nicht.
 */
IF IS_SRVROLEMEMBER(N'sysadmin') <> 1
    THROW 52040, N'Das Trust-Opt-in für die Regex-Assembly erfordert sysadmin.', 1;

IF NOT EXISTS
   (
       SELECT 1
       FROM sys.configurations
       WHERE name = N'clr enabled'
         AND value_in_use = 1
   )
    THROW 52041, N'CLR ist nicht aktiviert. Das Modul ändert keine Instanzoption.', 1;

IF NOT EXISTS
   (
       SELECT 1
       FROM sys.configurations
       WHERE name = N'clr strict security'
         AND value_in_use = 1
   )
    THROW 52042, N'clr strict security muss aktiviert bleiben.', 1;

DECLARE
      @AssemblyHash varbinary(64) =
          CONVERT(varbinary(64), N'$(AssemblyHash)', 1)
    , @AssemblyDescription nvarchar(4000) =
          N'$(AssemblyDescription)';

IF @AssemblyHash IS NULL OR DATALENGTH(@AssemblyHash) <> 64
    THROW 52043, N'AssemblyHash muss ein SHA2-512-Hexliteral mit genau 64 Bytes sein.', 1;
IF NULLIF(@AssemblyDescription, N'') IS NULL
    THROW 52044, N'AssemblyDescription darf nicht leer sein.', 1;

IF NOT EXISTS
   (
       SELECT 1
       FROM sys.trusted_assemblies
       WHERE hash = @AssemblyHash
   )
    EXEC sys.sp_add_trusted_assembly
          @hash = @AssemblyHash
        , @description = @AssemblyDescription;
GO
