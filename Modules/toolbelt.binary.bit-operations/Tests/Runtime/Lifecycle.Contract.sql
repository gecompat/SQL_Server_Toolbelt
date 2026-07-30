SET NOCOUNT ON;

IF OBJECT_ID(N'toolbelt_binary.TVF_LeftShiftBigInt', N'IF') IS NULL
   OR OBJECT_ID(N'toolbelt_binary.TVF_RightShiftBigInt', N'IF') IS NULL
   OR OBJECT_ID(N'toolbelt_binary.TVF_BitCountBigInt', N'IF') IS NULL
   OR OBJECT_ID(N'toolbelt_binary.TVF_GetBitBigInt', N'IF') IS NULL
   OR OBJECT_ID(N'toolbelt_binary.TVF_SetBitBigInt', N'IF') IS NULL
    THROW 52880, N'Die Bit-Releaseobjekte fehlen.', 1;

IF NOT EXISTS
   (
       SELECT 1 FROM sys.extended_properties
       WHERE class = 0
         AND name =
             N'Toolbelt.Module.toolbelt.binary.bit-operations.Version'
         AND TRY_CONVERT(nvarchar(64), value) = N'1.0.0'
   )
   OR NOT EXISTS
   (
       SELECT 1 FROM sys.extended_properties
       WHERE class = 0
         AND name =
             N'Toolbelt.Module.toolbelt.binary.bit-operations.DeploymentMode'
         AND TRY_CONVERT(nvarchar(16), value) IN (N'local', N'central')
   )
    THROW 52881, N'Die Bit-Modulmarker sind inkonsistent.', 1;

PRINT N'Bigint Bit Operations Lifecycle-Contract-Prüfung: erfolgreich';
GO
