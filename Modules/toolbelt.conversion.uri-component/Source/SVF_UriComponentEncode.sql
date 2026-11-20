CREATE OR ALTER FUNCTION [toolbelt_conversion].[SVF_UriComponentEncode](@Value nvarchar(max))
RETURNS nvarchar(max)
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-toolbelt-toolbelt-conversion-svf-uricomponentencode"
-- description: "Codiert eine Unicode-URI-Komponente als begrenzte UTF-8-Percentdarstellung."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.conversion.uri-component"
-- schema_name: "toolbelt_conversion"
-- object_name: "SVF_UriComponentEncode"
-- object_type: "SVF"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@Value", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Eine Unicode-URI-Komponente als nvarchar(max), kein vollständiger URI-Vertrag. Maximal 65536 UTF-16-Bytes vor SQL-UTF-8-Konvertierung; keine separate UTF-16-Validierung im Encoder. Leerer Text ist gültig; vorhandenes % wird erneut codiert. NULL ergibt SQL_NULL/NULL; Überschreitung LIMIT/NULL. Nicht-unreserved UTF-8-Bytes werden %HH, Leerzeichen %20 und nicht +."}]
-- source_paths: ["Modules/toolbelt.conversion.uri-component/Source/SVF_UriComponentEncode.sql", "Modules/toolbelt.conversion.uri-component/Source/TVF_UriComponentEncode.sql"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- ---
--
-- # SVF_UriComponentEncode
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
-- Ein Skalarwert nvarchar(max). NULL bei SQL_NULL oder LIMIT des Statuskerns, sonst der kodierte Text; leer ergibt leeren Text. Für die Unterscheidung die Statusfunktion verwenden.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- SELECT toolbelt_conversion.SVF_UriComponentEncode(N'a b/Ä') AS Value;
-- -- a%20b%2F%C3%84
-- ```
--
-- ## Rechte
--
-- Vorhandenes EXECUTE für den skalaren Aufruf. REFERENCES bei entsprechender Referenzverwendung. Keine Rechtevergabe oder Identitätsänderung; Cross-Database-Zuordnung bleibt erforderlich.
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
AS
BEGIN
 DECLARE @Result nvarchar(max);
 SELECT @Result=encoded.EncodedValue FROM toolbelt_conversion.TVF_UriComponentEncode(@Value) AS encoded;
 RETURN @Result;
END;
GO
