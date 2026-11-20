-- ============================================================================
-- Objekt:          toolbelt_conversion.TVF_Base64EncodeStatus
-- Zweck:           Begrenzter kanonischer Statuskern; Legacy-Wertfassade unten.
-- Parameter:       @Value varbinary(max), @UrlSafe bit = 0
-- Resultset:       EncodedValue varchar(max), Status varchar(16)
-- Vertrag:         Documentation/TVF_Base64EncodeStatus.md
-- Versionen:       SQL Server 2019/2022/2025; Windows/Linux
-- Rechte:          SELECT/REFERENCES; keine zusätzlichen Rechte oder Grants.
-- Performance:     MSTVF mit Vorabgrenzen; keine Inline-/Parallelitätszusage.
-- Grenzen:         Freigegebener Vertrag SECURITY_HARDENING_2026_10.md.
-- ============================================================================
CREATE OR ALTER FUNCTION [toolbelt_conversion].[TVF_Base64EncodeStatus]
(@Value varbinary(max),@UrlSafe bit=0)
RETURNS @Result TABLE(EncodedValue varchar(max) NULL,Status varchar(16) NOT NULL)
WITH SCHEMABINDING
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-toolbelt-toolbelt-conversion-tvf-base64encodestatus"
-- description: "Codiert begrenzte Binärdaten als Base64 oder Base64URL mit explizitem NULL-/Limitstatus."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.conversion.base64"
-- schema_name: "toolbelt_conversion"
-- object_name: "TVF_Base64EncodeStatus"
-- object_type: "TVF"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@Value", "sql_type": "varbinary(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Binärwert varbinary(max), etwa 0xCAFECAFE oder ein vom Client gebundener Bytepuffer; keine Text-Decodierung. Leer (0x) ist gültig. Maximal 16777216 Bytes; darüber Status LIMIT bzw. NULL in der Wertfassade. NULL ergibt SQL_NULL bzw. NULL."}, {"name": "@UrlSafe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Taxativ für den gebundenen bit-Wert: 0 erzeugt Standard-Base64 mit +, / und Padding = (Default); 1 erzeugt Base64URL mit -, _ und ohne Padding. NULL wird wie 0 behandelt."}]
-- source_paths: ["Modules/toolbelt.conversion.base64/Source/TVF_Base64Encode.sql"]
-- review_status: "verified"
-- source_module_version: "1.1.0"
-- ---
--
-- # TVF_Base64EncodeStatus
--
-- ## Zweck und Einsatzfälle
--
-- Codiert begrenzte Binärdaten als Base64 oder Base64URL mit explizitem NULL-/Limitstatus. Öffentlicher Statuskern der Wertfassaden; kann SQL-NULL und Ausgabelimit unterscheiden.
--
-- ## Voraussetzungen
--
-- SQL Server 2019 oder neuer; Aufruf als Tabellenfunktion. Beide Argumentpositionen angeben; für einen deklarierten Default ist in einem Funktionsaufruf DEFAULT zu verwenden.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
-- |---|---|---|---|---|
-- | `@Value` | `varbinary(max)` | `kein Default` | Input | Binärwert varbinary(max), etwa 0xCAFECAFE oder ein vom Client gebundener Bytepuffer; keine Text-Decodierung. Leer (0x) ist gültig. Maximal 16777216 Bytes; darüber Status LIMIT bzw. NULL in der Wertfassade. NULL ergibt SQL_NULL bzw. NULL. |
-- | `@UrlSafe` | `bit` | `0` | Input | Taxativ für den gebundenen bit-Wert: 0 erzeugt Standard-Base64 mit +, / und Padding = (Default); 1 erzeugt Base64URL mit -, _ und ohne Padding. NULL wird wie 0 behandelt. |
--
-- ## Ergebnisse
--
-- Genau eine Zeile mit EncodedValue varchar(max) NULL und Status varchar(16) NOT NULL. Taxativ SQL_NULL bei NULL-Eingabe und EncodedValue=NULL; LIMIT bei mehr als 16777216 Eingabebytes und EncodedValue=NULL; OK bei gültiger Eingabe einschließlich leerer Bytes. 0x ergibt leeren Text und OK. URL-safe kodiert nur bei gebundenem @UrlSafe=1.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- SELECT EncodedValue,Status
-- FROM toolbelt_conversion.TVF_Base64EncodeStatus(0xCAFECAFE,0);
-- -- yv7K/g==, OK
-- SELECT EncodedValue,Status
-- FROM toolbelt_conversion.TVF_Base64EncodeStatus(NULL,1);
-- -- NULL, SQL_NULL
-- ```
--
-- ## Rechte
--
-- Vorhandenes SELECT auf der Funktion; keine automatische Rechtevergabe. Cross-Database-Zuordnung muss im gewählten Aufrufkontext bestehen.
--
-- ## Ressourcenbedarf
--
-- Multistatement-TVF mit höchstens 16777216 Eingabebytes vor der XML-Kodierung. Standard-Base64 liefert 4*CEILING(Bytes/3) ASCII-Zeichen; URL-safe ersetzt + und / und entfernt bis zu zwei Paddingzeichen. Ausgabegröße bleibt trotz Eingabegrenze erheblich. Kein Streaming, keine pauschale Inline-, Parallelitäts- oder Laufzeitgarantie.
--
-- ## Nebenwirkungen
--
-- Read-only; keine Tabellenänderung, Datei- oder Netzwerkoperation.
--
-- ## Fehlerbehandlung
--
-- NULL- und Größenprüfungen liegen vor der XML-Kodierung. Diese fachlichen Fälle werden als SQL_NULL oder LIMIT zurückgegeben; Typbindung und unerwartete Engine-/XML-/Ressourcenfehler bleiben Fehler.
--
-- ## Aussagegrenzen
--
-- Base64 ist Kodierung, keine Verschlüsselung. URL-safe wird nur bei gebundenem bit-Wert 1 aktiviert; NULL wirkt wie 0. Kein unbegrenzter Streamingencoder.
-- OBJECT_USAGE_SKILL:END
AS
BEGIN
    /* DDL-Hilfe: Codiert varbinary(max) als Base64/Base64URL.
       Parameter: @Value varbinary(max), NULL erlaubt; @UrlSafe bit = 0,
       NULL entspricht 0. Höchstens 16777216 Eingabebytes; darüber Status LIMIT.
       Ergebnis: genau eine Zeile (EncodedValue varchar(max), Status varchar(16));
       Status ist SQL_NULL, LIMIT oder OK. Für den Aufruf ist SELECT erforderlich.
       Beispiel: SELECT * FROM toolbelt_conversion.TVF_Base64EncodeStatus(0xCAFECAFE,0);
       Erwartet: EncodedValue='yv7K/g==', Status='OK'. */
    IF @Value IS NULL BEGIN INSERT @Result VALUES(NULL,'SQL_NULL'); RETURN; END;
    IF DATALENGTH(@Value)>16777216 BEGIN INSERT @Result VALUES(NULL,'LIMIT'); RETURN; END;
    DECLARE @Encoded varchar(max);
    WITH Encoded AS
    (
        SELECT EncodedValue =
            CASE
                WHEN @Value IS NULL
                    THEN CONVERT(varchar(max), NULL)
                ELSE
                    CAST(N'' AS xml).value
                    (
                          N'xs:base64Binary(sql:variable("@Value"))'
                        , N'varchar(max)'
                    )
            END
    ),
    UrlSafe AS
    (
        SELECT
              EncodedValue
            , TransformedValue =
                  REPLACE(REPLACE(EncodedValue, '+', '-'), '/', '_')
        FROM Encoded
    )
    SELECT @Encoded =
        CONVERT
        (
              varchar(max)
            , CASE
                  WHEN ISNULL(@UrlSafe, 0) <> 1 OR EncodedValue IS NULL
                      THEN EncodedValue
                  ELSE LEFT
                       (
                             TransformedValue
                           , DATALENGTH(TransformedValue)
                             - CASE
                                   WHEN RIGHT(TransformedValue, 2) = '=='
                                       THEN 2
                                   WHEN RIGHT(TransformedValue, 1) = '='
                                       THEN 1
                                   ELSE 0
                               END
                       )
              END
        )
    FROM UrlSafe;
    INSERT @Result VALUES(@Encoded,'OK'); RETURN;
END;
GO
-- Legacy-Wertfassade: gleicher Inputvertrag; Limitabbildung siehe Objektseite.
-- Vertrag: Documentation/TVF_Base64Encode.md
CREATE OR ALTER FUNCTION [toolbelt_conversion].[TVF_Base64Encode]
(@Value varbinary(max),@UrlSafe bit=0)
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-toolbelt-conversion-tvf-base64encode"
-- description: "Codiert Binärdaten als Base64 oder Base64URL."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.conversion.base64"
-- schema_name: "toolbelt_conversion"
-- object_name: "TVF_Base64Encode"
-- object_type: "TVF"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@Value", "sql_type": "varbinary(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Binärwert varbinary(max), etwa 0xCAFECAFE oder ein vom Client gebundener Bytepuffer; keine Text-Decodierung. Leer (0x) ist gültig. Maximal 16777216 Bytes; darüber Status LIMIT bzw. NULL in der Wertfassade. NULL ergibt SQL_NULL bzw. NULL."}, {"name": "@UrlSafe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Taxativ für den gebundenen bit-Wert: 0 erzeugt Standard-Base64 mit +, / und Padding = (Default); 1 erzeugt Base64URL mit -, _ und ohne Padding. NULL wird wie 0 behandelt."}]
-- source_paths: ["Modules/toolbelt.conversion.base64/Source/TVF_Base64Encode.sql"]
-- review_status: "verified"
-- source_module_version: "1.1.0"
-- ---
--
-- # TVF_Base64Encode
--
-- ## Zweck und Einsatzfälle
--
-- Binärdaten in eine Base64- oder Base64URL-Wertzeile umwandeln. Für maschinell unterscheidbare NULL-/Limitfälle die öffentliche Statusfunktion verwenden.
--
-- ## Voraussetzungen
--
-- SQL Server 2019 oder neuer; Aufruf als Tabellenfunktion. Beide Argumentpositionen angeben; für einen deklarierten Default ist in einem Funktionsaufruf DEFAULT zu verwenden.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
-- |---|---|---|---|---|
-- | `@Value` | `varbinary(max)` | `kein Default` | Input | Binärwert varbinary(max), etwa 0xCAFECAFE oder ein vom Client gebundener Bytepuffer; keine Text-Decodierung. Leer (0x) ist gültig. Maximal 16777216 Bytes; darüber Status LIMIT bzw. NULL in der Wertfassade. NULL ergibt SQL_NULL bzw. NULL. |
-- | `@UrlSafe` | `bit` | `0` | Input | Taxativ für den gebundenen bit-Wert: 0 erzeugt Standard-Base64 mit +, / und Padding = (Default); 1 erzeugt Base64URL mit -, _ und ohne Padding. NULL wird wie 0 behandelt. |
--
-- ## Ergebnisse
--
-- Genau eine Zeile mit EncodedValue varchar(max). SQL-NULL-Eingabe ergibt NULL; leere Binärdaten ergeben einen leeren Text. Über 16777216 Eingabebytes wird NULL geliefert. Die Statusfunktion unterscheidet SQL_NULL, LIMIT und OK.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- SELECT EncodedValue
-- FROM toolbelt_conversion.TVF_Base64Encode(0xCAFECAFE,0);
-- -- Erwartet: yv7K/g==
-- ```
--
-- ## Rechte
--
-- Vorhandenes SELECT auf der Funktion; keine automatische Rechtevergabe. Cross-Database-Zuordnung muss im gewählten Aufrufkontext bestehen.
--
-- ## Ressourcenbedarf
--
-- Maximal 16777216 Eingabebytes. Base64 vergrößert die Ausgabe typischerweise auf vier Zeichen je drei Eingabebytes. Kanonischer begrenzter Statuskern; keine pauschale Inline-/Parallelitätsgarantie.
--
-- ## Nebenwirkungen
--
-- Read-only; keine Tabellenänderung, Datei- oder Netzwerkoperation.
--
-- ## Fehlerbehandlung
--
-- Die Wertfassade bildet SQL_NULL und LIMIT auf NULL ab. Für explizite Statusauswertung TVF_Base64EncodeStatus verwenden; unerwartete Enginefehler bleiben Enginefehler.
--
-- ## Aussagegrenzen
--
-- Base64 ist Kodierung, keine Verschlüsselung. URL-safe wird nur bei gebundenem bit-Wert 1 aktiviert; NULL wirkt wie 0. Kein unbegrenzter Streamingencoder.
-- OBJECT_USAGE_SKILL:END
RETURNS TABLE AS RETURN
/* DDL-Hilfe: Liefert eine Base64-Wertzeile für Binärdaten.
   Parameter: @Value varbinary(max), NULL erlaubt; @UrlSafe bit = 0,
   NULL entspricht 0. Höchstens 16777216 Eingabebytes; bei Überschreitung NULL.
   Ergebnis: EncodedValue varchar(max), genau eine Zeile; bei Größen-LIMIT NULL.
   Für den Aufruf ist SELECT erforderlich.
   Beispiel: SELECT EncodedValue FROM toolbelt_conversion.TVF_Base64Encode(0xCAFECAFE,0);
   Erwartet: yv7K/g==. */
(SELECT EncodedValue FROM toolbelt_conversion.TVF_Base64EncodeStatus(@Value,@UrlSafe));
GO
