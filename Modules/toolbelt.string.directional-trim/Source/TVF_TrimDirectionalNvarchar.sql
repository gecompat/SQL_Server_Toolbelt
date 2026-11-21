-- ============================================================================
-- Objekt: toolbelt_string.TVF_TrimDirectionalNvarchar
-- Zweck:  LEADING-, TRAILING- und BOTH-Trim für Unicode-Text.
-- ============================================================================
CREATE OR ALTER FUNCTION [toolbelt_string].[TVF_TrimDirectionalNvarchar]
(
      @Value      nvarchar(max)
    , @Characters nvarchar(4000) = N' '
    , @Direction  varchar(8) = 'BOTH'
)
RETURNS TABLE
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-toolbelt-toolbelt-string-tvf-trimdirectionalnvarchar"
-- description: "Entfernt ausgewählte Zeichen links, rechts oder beidseitig aus einem Unicode-Text."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.string.directional-trim"
-- schema_name: "toolbelt_string"
-- object_name: "TVF_TrimDirectionalNvarchar"
-- object_type: "TVF"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@Value", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Unicode-Text als nvarchar(max). SUBSTRING/CHARINDEX und NUL-Probe verwenden dieselben Zeichenpositionen der Installationscollation; SC zählt Supplementaryzeichen zusammen. Die obere Seriengrenze ist physisch DATALENGTH/2 bei nvarchar beziehungsweise DATALENGTH bei varchar und kann mehr Positionen als tatsächliche Zeichen enthalten. Leere Positionen jenseits des letzten Zeichens werden bei der Grenzsuche übersprungen. Leer bleibt leer, NULL ergibt NULL; keine dynamische Caller-Collation. NUL wird nicht entfernt."}, {"name": "@Characters", "sql_type": "nvarchar(4000)", "sql_default": "N' '", "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Bis 4000 UTF-16-Codeeinheiten als nvarchar(4000) als Menge einzelner zu entfernender Zeichen, kein Suchstring/Pattern. Default ist genau ein Space; leer entfernt nichts, NULL ergibt NULL. %, [ usw. sind literal; NUL wird nicht getrimmt."}, {"name": "@Direction", "sql_type": "varchar(8)", "sql_default": "'BOTH'", "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Taxativ: LEADING entfernt Zeichen nur links; TRAILING nur rechts; BOTH an beiden Rändern (Default). UPPER normalisiert die Groß-/Kleinschreibung, Vergleich erfolgt nach SQL-Gleichheitsregeln einschließlich Space-Padding; kein Trim der führenden Spaces. Andere Werte und NULL erzeugen einen Enginefehler, außer NULL bei Value/Characters hat Vorrang."}]
-- source_paths: ["Modules/toolbelt.string.directional-trim/Source/TVF_TrimDirectionalNvarchar.sql"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- ---
--
-- # TVF_TrimDirectionalNvarchar
--
-- ## Zweck und Einsatzfälle
--
-- Entfernt ausgewählte Zeichen links, rechts oder beidseitig aus einem Unicode-Text.
--
-- ## Voraussetzungen
--
-- Directionaltrim-Modul und kanonische mathematische TVF_GenerateSeriesBigInt derselben Installationsdatenbank. Windows/Linux SQL2019/2022/2025, zulässigeCL150/160/170. Installationscollation/Codepage bestimmen den Zeichenvergleich, kein dynamischer Caller-Collationvertrag.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
-- |---|---|---|---|---|
-- | `@Value` | `nvarchar(max)` | kein Default | Input | Unicode-Text als nvarchar(max). SUBSTRING/CHARINDEX und NUL-Probe verwenden dieselben Zeichenpositionen der Installationscollation; SC zählt Supplementaryzeichen zusammen. Die obere Seriengrenze ist physisch DATALENGTH/2 bei nvarchar beziehungsweise DATALENGTH bei varchar und kann mehr Positionen als tatsächliche Zeichen enthalten. Leere Positionen jenseits des letzten Zeichens werden bei der Grenzsuche übersprungen. Leer bleibt leer, NULL ergibt NULL; keine dynamische Caller-Collation. NUL wird nicht entfernt. |
-- | `@Characters` | `nvarchar(4000)` | `N' '` | Input | Bis 4000 UTF-16-Codeeinheiten als nvarchar(4000) als Menge einzelner zu entfernender Zeichen, kein Suchstring/Pattern. Default ist genau ein Space; leer entfernt nichts, NULL ergibt NULL. %, [ usw. sind literal; NUL wird nicht getrimmt. |
-- | `@Direction` | `varchar(8)` | `'BOTH'` | Input | Taxativ: LEADING entfernt Zeichen nur links; TRAILING nur rechts; BOTH an beiden Rändern (Default). UPPER normalisiert die Groß-/Kleinschreibung, Vergleich erfolgt nach SQL-Gleichheitsregeln einschließlich Space-Padding; kein Trim der führenden Spaces. Andere Werte und NULL erzeugen einen Enginefehler, außer NULL bei Value/Characters hat Vorrang. |
--
-- Alle Positionen beim SELECT-Aufruf angeben; DEFAULT verwendet einen deklarierten Funktionsdefault, NULL bleibt ein eigener Wert. SQL-Typbindung und eine mögliche Kürzung auf feste Parameterbreite liegen vor dem Funktionskörper.
--
-- ## Ergebnisse
--
-- Genau eine Zeile mit einer nullable Spalte Value nvarchar(max). NULL in Value/Characters ergibtNULL; leeres Input oder vollständig entfernteZeichen ergibtleerenString, keinNull-/Leerzeilenfallback. Kein Statusresultset und keine garantierte Definition bei ungültiger Richtung außer beschriebenem NULL-Vorrang.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- SELECT * FROM toolbelt_string.TVF_TrimDirectionalNvarchar(N' xxContoso-123xx ',N' x','BOTH');
-- ```
--
-- ## Rechte
--
-- Vorhandenes SELECT/gegebenenfalls REFERENCES auf TVF und benötigte Ownershipchain/Dependencyrechte für GenerateSeries. Keine Metadatensicht, Serverrechte, Trust- oder Rechteänderung.
--
-- ## Ressourcenbedarf
--
-- Characters nvarchar4000 beziehungsweisevarchar8000 wird bereits beim Binden begrenzt; kein Limit der ursprünglichen max-Callerwerte behaupten. Value max ohne eigenes kleinesZähler-/Zeitlimit. GeneriertePositionen bis physischerInputlänge:unterSC/UTF8 kann dies über die tatsächlicheZeichenzahl hinausgehen. Arbeit wächst mitValue undCHARINDEX-Zeichenmenge;mathematischeGenerateSeries hat kein kleinesAusgabelimit. Große untrustedInputs vor Aufruf begrenzen;keineStreaming-/Heap-/Memorygrant-/Wallclockgarantie, auchNULL-/Fehlerzweige sindkein universeller Nullarbeitsnachweis.
--
-- ## Nebenwirkungen
--
-- UPPER(Direction) unter Installationscollation, anschließend binärer SQL-Vergleich zuLEADING/TRAILING/BOTH einschließlich SQL-Space-Padding. Serienobergrenze DATALENGTH/2(nvarchar) beziehungsweise DATALENGTH(varchar) erhält physischeTrailingSpaces, kann beiSC/Multibyte mehr Kandidaten alsZeichen liefern. Leere SUBSTRING-Ergebnisse jenseits des letzten Zeichens beeinflussen die Grenzen nicht. NUL-Probe und CHARINDEX verwenden die Zeichenpositionen der Installationscollation. Kein binärerPositionswechsel allein zurNUL-Erkennung. NUL wird immer alsnichtzutrennend behandelt. Alleanderen Zeichen gegenCharacters alsZeichenmenge perCHARINDEX vergleichen; keine LIKE-/Regex-/Substringmustersyntax, Installationscollation bleibt wirksam.
--
-- MIN/MAX der nicht zu entfernenden Positionen bestimmen Grenzen. LEADING entfernt nurlinks,TRAILING nurrechts,BOTHbeides. DieselbeSUBSTRING-Semantik beimAusschneiden;AusgabeExplizit imursprünglichen SQLStringtyp. LeereCharactersmenge entferntnichts,NULLinValue/CharactershatimCASEVorrang,danachungültigeRichtung perDivisiondurch0. Die deklarierte Defaultmenge ist ein einzelnerSpace. ReinlesendeInline-TVF,keineeigeneTransaktion/Katalog-/Datei-/Netzwerkzugriffe.
--
-- ## Fehlerbehandlung
--
-- Ungültige oderNULLDirection führt über1/0 zuEnginefehler,außerNULLValue/CharactershatimCASEVorrang. SQL-Typbindung,Collation-/Codepage- undRessourcenfehler bleibenoriginal. KeinePattern-/Wildcardinterpretation,keinepauschaleUnicode-Normalisierung oderbinäreZeichenäquivalenz.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter aktueller Vertrag. Die ausdrücklich deklarierten funktionalen Korrekturen in diesem Modul benötigen neue native Gegenproben; historische Nachweise qualifizieren nur ihre ursprünglichen Bytes. Noch kein aktuelles natives API-/SC-/UTF8-/Caller-/Gesamtinstaller-PASS. Keine Installations-/Rechteattestation. Nur synthetische Beispiele; reale Eingaben/Runtimeausgaben privat halten.
-- OBJECT_USAGE_SKILL:END
AS
RETURN
(
    WITH Parameters AS
    (
        SELECT
              InputLength = CONVERT(bigint, DATALENGTH(@Value) / 2)
            , Direction = UPPER(@Direction) COLLATE Latin1_General_100_BIN2
            , IsValid = CONVERT(bit, CASE WHEN UPPER(@Direction) COLLATE Latin1_General_100_BIN2 IN ('LEADING','TRAILING','BOTH') THEN 1 ELSE 0 END)
    ),
    NonTrimmed AS
    (
        SELECT positions.Value
        FROM Parameters AS parameters
        CROSS APPLY toolbelt_core.TVF_GenerateSeriesBigInt(1, parameters.InputLength, 1) AS positions
        CROSS APPLY (VALUES (SUBSTRING(@Value, positions.Value, 1))) AS character_at_position(CharacterValue)
        WHERE CASE
            WHEN DATALENGTH(character_at_position.CharacterValue) = 0 THEN 1
            WHEN UNICODE(character_at_position.CharacterValue) = 0 THEN 0
            ELSE CHARINDEX(character_at_position.CharacterValue, @Characters) END = 0
    ),
    Bounds AS
    (
        SELECT FirstValue = MIN(Value), LastValue = MAX(Value) FROM NonTrimmed
    )
    SELECT Value = CONVERT(nvarchar(max), CASE
        WHEN @Value IS NULL OR @Characters IS NULL THEN NULL
        WHEN parameters.IsValid = 0 THEN CONVERT(nvarchar(max), 1 / 0)
        WHEN parameters.InputLength = 0 THEN N''
        WHEN bounds.FirstValue IS NULL THEN N''
        WHEN parameters.Direction = 'LEADING' THEN SUBSTRING(@Value, bounds.FirstValue, parameters.InputLength - bounds.FirstValue + 1)
        WHEN parameters.Direction = 'TRAILING' THEN SUBSTRING(@Value, 1, bounds.LastValue)
        ELSE SUBSTRING(@Value, bounds.FirstValue, bounds.LastValue - bounds.FirstValue + 1) END)
    FROM Parameters AS parameters CROSS JOIN Bounds AS bounds
);
GO
