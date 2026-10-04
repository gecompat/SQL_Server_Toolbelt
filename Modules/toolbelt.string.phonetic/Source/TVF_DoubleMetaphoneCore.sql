-- Interner FT: beide vollständigen Codes werden vor der einzelnen Zeile ermittelt.
CREATE FUNCTION toolbelt_string.TVF_DoubleMetaphoneCore(@Text nvarchar(max))
RETURNS TABLE (PrimaryCode nvarchar(max), AlternateCode nvarchar(max), ErrorCode int)
AS EXTERNAL NAME [Toolbelt_String_Phonetic].[Toolbelt.String.Phonetic.PhoneticBridge].[EvaluateDoubleMetaphone];
GO
