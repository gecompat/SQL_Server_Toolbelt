SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- ============================================================================
-- Objekt:          toolbelt_metadata.SVF_QuoteMultipartName
-- Typ:             Scalar-valued Function
-- Zweck:           Begrenzt einen gültigen Multipart-Namen sicher mit [].
-- Vertrag:         Documentation/SVF_QuoteMultipartName.md
-- Parameter:       @MultipartName nvarchar(1035)
-- Rückgabewert:    nvarchar(1035), bei ungültiger Eingabe NULL
-- Dependencies:    toolbelt_metadata.TVF_ParseMultipartName
-- Rechte:          EXECUTE und erforderliche Ownershipchain zum Parser
-- Versionen:       SQL Server 2019/2022/2025
-- Plattformen:     Windows/Linux
-- Fehlerverhalten: Ungültige Eingaben liefern NULL.
-- Performance:     Verwendet den kanonischen linearen Parser genau einmal.
-- Einschränkungen: Führt keine Objekt- oder Berechtigungsauflösung aus.
-- ============================================================================
CREATE OR ALTER FUNCTION [toolbelt_metadata].[SVF_QuoteMultipartName]
(
    @MultipartName nvarchar(1035)
)
RETURNS nvarchar(1035)
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-toolbelt-toolbelt-metadata-svf-quotemultipartname"
-- description: "Validiert einen mehrteiligen SQL-Namen und quotiert seine Komponenten."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.metadata.identifier"
-- schema_name: "toolbelt_metadata"
-- object_name: "SVF_QuoteMultipartName"
-- object_type: "SVF"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@MultipartName", "sql_type": "nvarchar(1035)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Ein- bis vierteiliger SQL-Identifier als nvarchar(1035), je ausgeschriebenem Teil höchstens 128 UTF16-Codeeinheiten. Formen: Object; Schema.Object; Database.Schema.Object; Server.Database.Schema.Object; Database..Object; Server.Database..Object; Server..Schema.Object; Server...Object. Eckige Klammern erlauben Punkte im Teil und ]] als escaped Schlussklammer. Keine doppelten Quotes als Delimiter, äußeren Spaces, leeren Objektteile oder Steuerzeichen. NULL/leer/ungültig ergibt beim Parser IsValid=0 mit ValidationCode, beim Scalarwrapper NULL. Existenz und Rechte werden nicht dadurch geprüft. ASCII-Delimiter werden binär erkannt, escaped ]] wird einmal zurückgenommen. Gequotete Spaces einschließlich [ ] sind Inhalt, keine Auslassung; Spaces vor einer öffnenden Klammer sind BRACKET_SYNTAX. Parameterbindung auf1035Codeeinheiten liegt vor der Funktion und kann längere Callerwerte kürzen; ursprüngliche Länge bei Bedarf vorher im Client/max-Typ prüfen."}]
-- source_paths: ["Modules/toolbelt.metadata.identifier/Source/SVF_QuoteMultipartName.sql"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- ---
--
-- # SVF_QuoteMultipartName
--
-- ## Zweck und Einsatzfälle
--
-- Validiert einen mehrteiligen SQL-Namen und quotiert seine Komponenten.
--
-- ## Voraussetzungen
--
-- Identifier-Modul, Windows/Linux SQL2019/2022/2025 mit zulässigem CL150/160/170. Rein lokale Stringverarbeitung, keine Objekt-/Datenbank-/Serverauflösung oder Metadatensicht.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
-- |---|---|---|---|---|
-- | `@MultipartName` | `nvarchar(1035)` | kein Default | Input | Ein- bis vierteiliger SQL-Identifier als nvarchar(1035), je ausgeschriebenem Teil höchstens 128 UTF16-Codeeinheiten. Formen: Object; Schema.Object; Database.Schema.Object; Server.Database.Schema.Object; Database..Object; Server.Database..Object; Server..Schema.Object; Server...Object. Eckige Klammern erlauben Punkte im Teil und ]] als escaped Schlussklammer. Keine doppelten Quotes als Delimiter, äußeren Spaces, leeren Objektteile oder Steuerzeichen. NULL/leer/ungültig ergibt beim Parser IsValid=0 mit ValidationCode, beim Scalarwrapper NULL. Existenz und Rechte werden nicht dadurch geprüft. ASCII-Delimiter werden binär erkannt, escaped ]] wird einmal zurückgenommen. Gequotete Spaces einschließlich [ ] sind Inhalt, keine Auslassung; Spaces vor einer öffnenden Klammer sind BRACKET_SYNTAX. Parameterbindung auf1035Codeeinheiten liegt vor der Funktion und kann längere Callerwerte kürzen; ursprüngliche Länge bei Bedarf vorher im Client/max-Typ prüfen. |
--
-- Alle Positionen beim SELECT-Aufruf angeben; DEFAULT verwendet einen deklarierten Funktionsdefault, NULL bleibt ein eigener Wert. SQL-Typbindung und eine mögliche Kürzung auf feste Parameterbreite liegen vor dem Funktionskörper.
--
-- ## Ergebnisse
--
-- Skalares nvarchar(1035),kein Resultset. Genau die kanonische QuotedName eines gültigen Parse,sonstNULL; keine Statusunterscheidung ohne Parser-TVF.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- SELECT * FROM toolbelt_metadata.TVF_ParseMultipartName(N'[ContosoDb]..[Order]]Line]');
-- SELECT toolbelt_metadata.SVF_QuoteMultipartName(N'dbo.ContosoSource');
-- SELECT * FROM toolbelt_metadata.TVF_ParseMultipartName(N'[ ]');
-- ```
--
-- ## Rechte
--
-- Parser-TVF:vorhandenes SELECT/gegebenenfalls REFERENCES. Scalarfunktion:vorhandenes EXECUTE und nötige Ownershipchain zum Parser. Keine Katalog-/Objektvollsicht oder zusätzlichen Serverrechte; diese Ausgabe erteilt keine Ausführungsberechtigung auf den gequoteten Namen.
--
-- ## Ressourcenbedarf
--
-- Fest gebundener Input nvarchar1035, höchstens4Teile je128UTF16-Codeeinheiten. Kleine lokale @Parts-/Resulttablevariablen und linearer Zustandsautomat; QuotedName1035 reicht für vier maximal escapte128erTeile plusDelimitern/Punkten. Bindung kann bereits vor der Funktion kürzen; dies ist keine Prüfung der ursprünglichen Clientlänge. Kein allgemeiner Sqlparser/Unicode-Wellformedness-/Laufzeit- oder Objektexistenzvertrag.
--
-- ## Nebenwirkungen
--
-- Begrenzter Zustandsautomat über physische UTF16-Codeeinheiten: DATALENGTH/2 und explizites BIN2-SUBSTRING verwenden dieselbe Einheit, unabhängig von SC. Nchar1 puffert jeweils genau eine Einheit; ein gültiges Surrogatepaar bleibt beim Zusammenfügen bytegleich und zählt zwei Einheiten gegen sysname128. ASCII-Delimiter/Lookahead/Metazeichen explizit binär, keine linguistische Breitenäquivalenz. Leere Teilwerte/Auslassung anhand Bytelänge, nicht SQL-Space-Padding: [ ] ist ein echter Space-Identifier, [] leer; Text/Space vor öffnenderKlammer kein leeres Präfix.
--
-- 1..4Teile, höchstens128decodierte Codeeinheiten jeTeil. Punkt trennt nur außerhalb [...], ]] entescapt einmal zu]. Nach schließenderKlammer nurPunkt oderEnde. DoppelteQuotes sind keine Delimiter. Unquoted ASCII-Metazeichen * % Quotes ; ( ) , = + - / Backslash : ? ! { } | & < > sowie Steuerzeichen<32/127 abweisen; innerhalbKlammern Metazeichen/Punkte Inhalt, Steuerzeichen weiterhinverboten. Unquoted äußere ASCII-Spaces ungültig, quoted Spaces erhalten. Auslassung nur zwischen vorhandenen Rändern bei3/4Teilen, nie linkester/rechtesterTeil. QUOTENAME jeden vorhandenen Teil, mittlere Auslassungen als leere Stellen zwischenPunkten bewahren. Keine Case-/Unicode-Normalisierung oder Nachweis eines tatsächlich existierenden SQLobjekts. Scalarwrapper fragt den Parser genau einmal ab, nur gültigen QuotedName zurückgeben. Keine Mutation oder eigeneTransaktion.
--
-- ## Fehlerbehandlung
--
-- VALID beiErfolg;NULL_INPUT,EMPTY_INPUT,CONTROL_CHARACTER,BRACKET_SYNTAX,TEXT_AFTER_DELIMITER,UNQUOTED_META_CHARACTER,PART_TOO_LONG,TOO_MANY_PARTS,UNCLOSED_DELIMITER,EMPTY_IDENTIFIER,OUTER_WHITESPACE,INVALID_OMISSION,INVALID_IDENTIFIER. Keine Eingabewerte im Status; Scalar bildet alle Fehler aufNULL ab. Typbindung/sonstige Enginefehler nicht pauschal abgefangen.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter aktueller Vertrag. Die ausdrücklich deklarierten funktionalen Korrekturen in diesem Modul benötigen neue native Gegenproben; historische Nachweise qualifizieren nur ihre ursprünglichen Bytes. Noch kein aktuelles natives API-/SC-/UTF8-/Caller-/Gesamtinstaller-PASS. Keine Installations-/Rechteattestation. Nur synthetische Beispiele; reale Eingaben/Runtimeausgaben privat halten.
-- OBJECT_USAGE_SKILL:END
AS
BEGIN
    DECLARE @QuotedName nvarchar(1035);

    SELECT @QuotedName = parsed.QuotedName
    FROM [toolbelt_metadata].[TVF_ParseMultipartName](@MultipartName) AS parsed
    WHERE parsed.IsValid = 1;

    RETURN @QuotedName;
END;
GO
