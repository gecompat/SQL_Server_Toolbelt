-- Synthetische Beispiele; Module und bestehende Aufrufrechte vorausgesetzt.
EXEC toolbelt_json.USP_ValidateJsonSchema @Hilfe=1;
EXEC toolbelt_json.USP_ValidateJsonSchema @Json=N'12345678901234567890123456789012345678901',
 @Schema=N'{"type":"integer","minimum":12345678901234567890123456789012345678900}';
EXEC toolbelt_json.USP_ValidateJsonSchema @Json=N'{"quantity":0}',
 @Schema=N'{"$defs":{"positive":{"type":"integer","minimum":1}},"properties":{"quantity":{"$ref":"#/$defs/positive"}}}',
 @MaxErrors=0;
