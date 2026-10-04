-- Interner FT: eager speicherreine Bridge, NULL-/Fehlerzeile bleibt sichtbar.
CREATE FUNCTION toolbelt_string.TVF_ColognePhoneticCore(@Text nvarchar(max))
RETURNS TABLE (PhoneticCode nvarchar(max), ErrorCode int)
AS EXTERNAL NAME [Toolbelt_String_Phonetic].[Toolbelt.String.Phonetic.PhoneticBridge].[EvaluateCologne];
GO
