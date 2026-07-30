-- Mehrere einzelne Separatorzeichen, leere Tokens erhalten.
SELECT
      tokens.Value
    , tokens.Ordinal
FROM toolbelt_string.TVF_SplitByCharacters
(
    N'Alpha,Beta;;Gamma|',
    N',;|',
    DEFAULT
) AS tokens
ORDER BY tokens.Ordinal;
GO

-- Leere Tokens entfernen; Whitespace bleibt erhalten.
SELECT
      tokens.Value
    , tokens.Ordinal
FROM toolbelt_string.TVF_SplitByCharacters
(
    N' Eins ,; Zwei ',
    N',;',
    0
) AS tokens
ORDER BY tokens.Ordinal;
GO
