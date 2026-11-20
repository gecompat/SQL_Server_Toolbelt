-- ============================================================================
-- Objekt:          toolbelt_conversion.TVF_UriComponentEncodeStatus
-- Zweck:           Begrenzter kanonischer Statuskern; Legacy-Wertfassade unten.
-- Parameter:       @Value nvarchar(max)
-- Resultset:       EncodedValue nvarchar(max), Status varchar(16)
-- Vertrag:         Documentation/TVF_UriComponentEncodeStatus.md
-- Versionen:       SQL Server 2019/2022/2025; Windows/Linux
-- Rechte:          SELECT/REFERENCES; keine zusätzlichen Rechte oder Grants.
-- Performance:     MSTVF mit Vorabgrenzen; keine Inline-/Parallelitätszusage.
-- Grenzen:         Freigegebener Vertrag SECURITY_HARDENING_2026_10.md.
-- ============================================================================
CREATE OR ALTER FUNCTION [toolbelt_conversion].[TVF_UriComponentEncodeStatus](@Value nvarchar(max))
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-toolbelt-toolbelt-conversion-tvf-uricomponente-f665768c"
-- description: "Codiert eine Unicode-URI-Komponente als begrenzte UTF-8-Percentdarstellung."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.conversion.uri-component"
-- schema_name: "toolbelt_conversion"
-- object_name: "TVF_UriComponentEncodeStatus"
-- object_type: "TVF"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@Value", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Eine Unicode-URI-Komponente als nvarchar(max), kein vollständiger URI-Vertrag. Maximal 65536 UTF-16-Bytes vor SQL-UTF-8-Konvertierung; keine separate UTF-16-Validierung im Encoder. Leerer Text ist gültig; vorhandenes % wird erneut codiert. NULL ergibt SQL_NULL/NULL; Überschreitung LIMIT/NULL. Nicht-unreserved UTF-8-Bytes werden %HH, Leerzeichen %20 und nicht +."}]
-- source_paths: ["Modules/toolbelt.conversion.uri-component/Source/TVF_UriComponentEncode.sql"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- ---
--
-- # TVF_UriComponentEncodeStatus
--
-- ## Zweck und Einsatzfälle
--
-- Codiert eine Unicode-URI-Komponente als begrenzte UTF-8-Percentdarstellung. Für einen einzelnen URI-Bestandteil, keinen kompletten URI und keine Form-URL-Encoding-Semantik. Statusoberfläche für NULL-/Limitunterscheidung.
--
-- ## Voraussetzungen
--
-- SQL Server 2019/2022/2025, Windows/Linux, CL150/160/170. URI-Modul und deklarierte Generate-Series-Abhängigkeit installiert. SQL-UTF8-Kollation Latin1_General_100_BIN2_UTF8 und master.dbo.fn_varbintohexstr werden vom T-SQL-Provider verwendet. Kein CLR, Datei-/Netzwerkzugriff oder Fachsystemkatalog.
--
-- ## Parameter und Zugriff
--
-- `@Value nvarchar(max)` ohne Default; Unicode-Komponente, maximal 65536 UTF-16-Bytes vor der UTF-8-Konvertierung. Leerer Text ist gültig, NULL bleibt NULL bzw. SQL_NULL. Bestehendes % wird erneut kodiert. Der Encoder besitzt keine eigene UTF-16-/Surrogatvalidierung; er verwendet die SQL-UTF8-Konvertierung.
--
-- ## Ergebnisse
--
-- Genau eine Zeile mit EncodedValue nvarchar(max) NULL und Status varchar(16) NOT NULL: SQL_NULL bei NULL, LIMIT bei Eingabe über 65536 oder Ausgabe über 1048576 UTF-16-Bytes, sonst OK. Nicht-OK hat EncodedValue=NULL.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- SELECT * FROM toolbelt_conversion.TVF_UriComponentEncodeStatus(N'a b/Ä');
-- -- a%20b%2F%C3%84, Status=OK
-- ```
--
-- ## Rechte
--
-- Vorhandenes SELECT für SELECT-Aufrufe. REFERENCES bei entsprechender Referenzverwendung. Keine Rechtevergabe oder Identitätsänderung; Cross-Database-Zuordnung bleibt erforderlich.
--
-- ## Ressourcenbedarf
--
-- Statuskern prüft 65536 Eingabebytes vor UTF-8-Konvertierung und Serienexpansion. Danach ein Ergebnisteil je UTF-8-Byte, geordnetes STRING_AGG und Abschlussschranke von 1048576 UTF-16-Ausgabebytes. Die Eingabegrenze begrenzt die Expansion bereits unter diese Ausgabeschranke. Keine pauschale Inline-/Parallelitäts- oder Laufzeitgarantie; skalare Fassade fragt die TVF ab.
--
-- ## Nebenwirkungen
--
-- Rein lesend ohne Datei-, Netzwerk-, Tabellen-, Trust- oder Konfigurationsänderung. Statuskern befüllt nur seine lokale Rückgabetabelle.
--
-- ## Fehlerbehandlung
--
-- SQL_NULL und LIMIT werden als Status bzw. NULL-Wert geliefert. Unerwartete SQL-Konvertierungs-/Engine-/Ressourcenfehler bleiben Fehler. Keine automatische Nachbesserung oder Wiederholung.
--
-- ## Aussagegrenzen
--
-- Nur ASCII-Buchstaben A..Z/a..z, Ziffern 0..9 und -._~ bleiben unverändert; alle anderen UTF-8-Bytes werden %HH mit großen Hexziffern. Space wird %20, Plus %2B, Slash %2F. Kein URI-Parser, keine Pfad-/Hostvalidierung, keine Normalisierung bestehender Escapes und keine Sicherheitsfreigabe des Ergebnisses. NUL wird nicht gesondert abgelehnt und kann %00 ergeben; der Decoder lehnt decodiertes NUL ab. Ein Roundtrip beliebiger nicht wohlgeformter UTF-16-Eingaben oder aller erlaubten Encodertexte wird deshalb nicht garantiert.
-- OBJECT_USAGE_SKILL:END
RETURNS @Result TABLE(EncodedValue nvarchar(max) NULL,Status varchar(16) NOT NULL) AS
BEGIN
    IF @Value IS NULL BEGIN INSERT @Result VALUES(NULL,'SQL_NULL'); RETURN; END;
    IF DATALENGTH(@Value)>65536 BEGIN INSERT @Result VALUES(NULL,'LIMIT'); RETURN; END;
    DECLARE @Output nvarchar(max);
    WITH Utf8 AS
    (
        SELECT Bytes = CONVERT
        (
            varbinary(max),
            CONVERT
            (
                varchar(max),
                @Value COLLATE Latin1_General_100_BIN2_UTF8
            )
        )
    ),
    Encoded AS
    (
        SELECT EncodedValue = STRING_AGG(CONVERT(varchar(max), CASE
            WHEN SUBSTRING(utf8.Bytes, positions.Value, 1) BETWEEN 0x41 AND 0x5A
              OR SUBSTRING(utf8.Bytes, positions.Value, 1) BETWEEN 0x61 AND 0x7A
              OR SUBSTRING(utf8.Bytes, positions.Value, 1) BETWEEN 0x30 AND 0x39
              OR SUBSTRING(utf8.Bytes, positions.Value, 1) IN (0x2D,0x2E,0x5F,0x7E)
                THEN CONVERT(varchar(1), SUBSTRING(utf8.Bytes, positions.Value, 1)) COLLATE Latin1_General_100_BIN2
            ELSE '%' + UPPER(SUBSTRING(master.dbo.fn_varbintohexstr(SUBSTRING(utf8.Bytes, positions.Value, 1)), 3, 2)) END), '') WITHIN GROUP (ORDER BY positions.Value)
        FROM Utf8 AS utf8
        CROSS APPLY toolbelt_core.TVF_GenerateSeriesBigInt(1, CONVERT(bigint, DATALENGTH(utf8.Bytes)), 1) AS positions
    )
    SELECT @Output = CASE WHEN @Value IS NULL THEN CONVERT(nvarchar(max),NULL) ELSE CONVERT(nvarchar(max),COALESCE(encoded.EncodedValue,'')) END
    FROM Encoded AS encoded;
    IF DATALENGTH(@Output)>1048576 INSERT @Result VALUES(NULL,'LIMIT'); ELSE INSERT @Result VALUES(@Output,'OK');
    RETURN;
END;
GO
-- Legacy-Wertfassade: gleicher Inputvertrag; Limitabbildung siehe Objektseite.
-- Vertrag: Documentation/TVF_UriComponentEncode.md
CREATE OR ALTER FUNCTION [toolbelt_conversion].[TVF_UriComponentEncode](@Value nvarchar(max))
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-toolbelt-toolbelt-conversion-tvf-uricomponentencode"
-- description: "Codiert eine Unicode-URI-Komponente als begrenzte UTF-8-Percentdarstellung."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.conversion.uri-component"
-- schema_name: "toolbelt_conversion"
-- object_name: "TVF_UriComponentEncode"
-- object_type: "TVF"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@Value", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Eine Unicode-URI-Komponente als nvarchar(max), kein vollständiger URI-Vertrag. Maximal 65536 UTF-16-Bytes vor SQL-UTF-8-Konvertierung; keine separate UTF-16-Validierung im Encoder. Leerer Text ist gültig; vorhandenes % wird erneut codiert. NULL ergibt SQL_NULL/NULL; Überschreitung LIMIT/NULL. Nicht-unreserved UTF-8-Bytes werden %HH, Leerzeichen %20 und nicht +."}]
-- source_paths: ["Modules/toolbelt.conversion.uri-component/Source/TVF_UriComponentEncode.sql"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- ---
--
-- # TVF_UriComponentEncode
--
-- ## Zweck und Einsatzfälle
--
-- Codiert eine Unicode-URI-Komponente als begrenzte UTF-8-Percentdarstellung. Für einen einzelnen URI-Bestandteil, keinen kompletten URI und keine Form-URL-Encoding-Semantik.
--
-- ## Voraussetzungen
--
-- SQL Server 2019/2022/2025, Windows/Linux, CL150/160/170. URI-Modul und deklarierte Generate-Series-Abhängigkeit installiert. SQL-UTF8-Kollation Latin1_General_100_BIN2_UTF8 und master.dbo.fn_varbintohexstr werden vom T-SQL-Provider verwendet. Kein CLR, Datei-/Netzwerkzugriff oder Fachsystemkatalog.
--
-- ## Parameter und Zugriff
--
-- `@Value nvarchar(max)` ohne Default; Unicode-Komponente, maximal 65536 UTF-16-Bytes vor der UTF-8-Konvertierung. Leerer Text ist gültig, NULL bleibt NULL bzw. SQL_NULL. Bestehendes % wird erneut kodiert. Der Encoder besitzt keine eigene UTF-16-/Surrogatvalidierung; er verwendet die SQL-UTF8-Konvertierung.
--
-- ## Ergebnisse
--
-- Genau eine Zeile mit EncodedValue nvarchar(max). NULL bei SQL_NULL oder LIMIT des Statuskerns, sonst der kodierte Text; leer ergibt leeren Text. Für die Unterscheidung die Statusfunktion verwenden.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- SELECT * FROM toolbelt_conversion.TVF_UriComponentEncode(N'a b/Ä');
-- -- a%20b%2F%C3%84
-- ```
--
-- ## Rechte
--
-- Vorhandenes SELECT für SELECT-Aufrufe. REFERENCES bei entsprechender Referenzverwendung. Keine Rechtevergabe oder Identitätsänderung; Cross-Database-Zuordnung bleibt erforderlich.
--
-- ## Ressourcenbedarf
--
-- Statuskern prüft 65536 Eingabebytes vor UTF-8-Konvertierung und Serienexpansion. Danach ein Ergebnisteil je UTF-8-Byte, geordnetes STRING_AGG und Abschlussschranke von 1048576 UTF-16-Ausgabebytes. Die Eingabegrenze begrenzt die Expansion bereits unter diese Ausgabeschranke. Keine pauschale Inline-/Parallelitäts- oder Laufzeitgarantie; skalare Fassade fragt die TVF ab.
--
-- ## Nebenwirkungen
--
-- Rein lesend ohne Datei-, Netzwerk-, Tabellen-, Trust- oder Konfigurationsänderung. Statuskern befüllt nur seine lokale Rückgabetabelle.
--
-- ## Fehlerbehandlung
--
-- SQL_NULL und LIMIT werden als Status bzw. NULL-Wert geliefert. Unerwartete SQL-Konvertierungs-/Engine-/Ressourcenfehler bleiben Fehler. Keine automatische Nachbesserung oder Wiederholung.
--
-- ## Aussagegrenzen
--
-- Nur ASCII-Buchstaben A..Z/a..z, Ziffern 0..9 und -._~ bleiben unverändert; alle anderen UTF-8-Bytes werden %HH mit großen Hexziffern. Space wird %20, Plus %2B, Slash %2F. Kein URI-Parser, keine Pfad-/Hostvalidierung, keine Normalisierung bestehender Escapes und keine Sicherheitsfreigabe des Ergebnisses. NUL wird nicht gesondert abgelehnt und kann %00 ergeben; der Decoder lehnt decodiertes NUL ab. Ein Roundtrip beliebiger nicht wohlgeformter UTF-16-Eingaben oder aller erlaubten Encodertexte wird deshalb nicht garantiert.
-- OBJECT_USAGE_SKILL:END
RETURNS TABLE AS RETURN
(SELECT EncodedValue FROM toolbelt_conversion.TVF_UriComponentEncodeStatus(@Value));
GO
