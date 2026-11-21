-- ============================================================================
-- Objekt:          toolbelt_pseudonymization.TVF_DeterministicIntegerBytes
-- Zweck:           Interne explizite bigint-Big-endian-Zweierkomplementkodierung.
-- Parameter:       Value bigint; Resultset: Bytes binary(8) NULL.
-- Dependencies:    keine; echte Inline TVF, keine Scalar-UDF.
-- Versionen:       SQL Server 2019/2022/2025; Windows/Linux.
-- Performance:     16 feste Hexziffern, keine Schleife oder Aggregation.
-- Collation:       feste ASCII-Hexzeichen; kein Vergleich von Caller-Text.
-- Einschränkungen: Intern; NULL ergibt NULL. Keine Numeric-to-binary-Kodierung.
-- ============================================================================
CREATE OR ALTER FUNCTION [toolbelt_pseudonymization].[TVF_DeterministicIntegerBytes]
(
    @Value bigint
)
RETURNS TABLE
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-tvf-deterministicintegerbytes"
-- description: "Interner fester bigint-Encoder für explizite Big-endian-Zweierkomplementbytes."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.pseudonymization.deterministic"
-- schema_name: "toolbelt_pseudonymization"
-- object_name: "TVF_DeterministicIntegerBytes"
-- object_type: "TVF"
-- database_role: "toolbelt"
-- is_internal: true
-- parameters: [{"name": "@Value", "sql_type": "bigint", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Jeder bigint einschließlich Min/Max; NULL ergibt eine Zeile mit Bytes=NULL. Keine Text-/Codepagekonvertierung."}]
-- source_paths: ["Modules/toolbelt.pseudonymization.deterministic/Source/TVF_DeterministicIntegerBytes.sql"]
-- review_status: "verified"
-- source_module_version: "1.2.0"
-- public_entrypoints: ["toolbelt_pseudonymization.TVF_DeterministicRange"]
-- ---
--
-- # TVF_DeterministicIntegerBytes
--
-- ## Zweck und Einsatzfälle
--
-- Interner fester bigint-Encoder für explizite Big-endian-Zweierkomplementbytes. Kein eigener öffentlicher Fachaufrufweg.
--
-- ## Voraussetzungen
--
-- Modul 1.2.0 mit kanonischen T-SQL-Abhängigkeiten derselben Datenbank. SQL2019/2022/2025 auf Windows/Linux mit CL150/160/170 gemäß Modulmatrix. Explizite Versionen und binäre Keys statt impliziter Textkodierung. Keine Fach- oder Systemkatalogabfrage für die Transformation erforderlich. Input- und Fehlercodes vor Weiterverwendung auswerten.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
-- |---|---|---|---|---|
-- | `@Value` | `bigint` | kein Default | Input | Jeder bigint einschließlich Min/Max; NULL ergibt eine Zeile mit Bytes=NULL. Keine Text-/Codepagekonvertierung. |
--
-- Bei TVF-Aufrufen alle Argumentpositionen angeben; DEFAULT nur bei tatsächlichem SQL-Default. NULL-Ergebnispriorität ist ein logischer Vertrag,keine Zusage über physische Optimizer-Auswertung. SQL-Typkonvertierung liegt vorher.
--
-- ## Ergebnisse
--
-- | Spalte | SQL-Typ | Vertrag |
-- |---|---|---|
-- | `Bytes` | `binary(8)` | NULL genau beiNULLValue |
--
-- Genau eine Zeile ohne ErrorCode;keine Mutation oderHilfeschnittstelle.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- -- Interner Helfer: öffentlichen Einstieg verwenden.
-- SELECT * FROM toolbelt_pseudonymization.TVF_DeterministicRange(0x010203,1,0,-10,10);
-- ```
--
-- ## Rechte
--
-- Vorhandenes SELECT auf die öffentliche TVF. Interne Encoder-/Rangehelfer nur über öffentliche Einstiegspunkte verwenden. Keine fachliche Tabellen- oder Systemkatalogabfrage, CLR-Assembly, Serverrolle oder Rechtevergabe für die Transformation. Zentrale Dreiteilnamen brauchen gültigen Datenbankzugriff und Identitätsmapping. Tatsächliche Ownership-Chains und Objektrechte bleiben maßgeblich.
--
-- ## Ressourcenbedarf
--
-- Range verwendet bis zu 128 logische Hashkandidaten je Aufruf, Geo zwei Rangeziehungen. Keine physische Auswertungszahlgarantie einer Inline-TVF. Translate verwendet 36 logische Hashframes und begrenzte Input-/Separatoroperanden. Standard2MiB/large16MiB gelten nur für Translate; der Key hat 1..8000 Bytes. Die Geography-Serialisierung zur Größenmessung erfolgt vor der 128-Byte-Prüfung. Keine harte Zeit-, Peakheap-, Plan- oder Parallelitätsgarantie.
--
-- ## Nebenwirkungen
--
-- Eine relationale Zeile:16 feste ASCII-Hexziffern aus bigint-Bitmasken einschließlich Vorzeichenbit bilden,dann CONVERT(binary(8),Hex,2). Big-endian-Zweierkomplement ohne native numeric-to-binary-Annahme. NULL propagiert Bytes=NULL. Keine Schleife,Hashfunktion,Normalisierung oder Datenabfrage.
--
-- ## Fehlerbehandlung
--
-- Keine fachlichen Fehlercodes; NULL ergibt BytesNULL. SQL-Binder-/Engine-/Konvertierungsfehler bleiben sichtbar. Ursprüngliche SQL-Binder-/Engine-/Ressourcenfehler bleiben sichtbar; keine automatische Wiederholung.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter aktueller Vertrag; keine neue native Hilfe-/Unicode-/Minimalrechte-/Callerzustands-/Installer-/Mapping-/Spatialabnahme. Historische Nachweise bleiben an ihre Artefakte gebunden. Ausschließlich für synthetische Datenzwecke; keine Anonymisierung, Eindeutigkeit, Kryptografie, Secretverwaltung oder Privacygarantie. Wiederholbarkeit verlangt denselben expliziten Kontext und bei Lookup denselben geordneten Pool. LookupVersion wird nicht automatisch gegen Drift geprüft. Keine pauschale bitweise Gleichheitszusage für Spatial-/Floatwerte zwischen Plattformen. Keine Installations- oder Rechteattestation. Reale Keys, Inputdaten und Runtimebefunde privat halten.
-- OBJECT_USAGE_SKILL:END
AS
RETURN
(
    SELECT Bytes = CONVERT(binary(8),
          SUBSTRING('0123456789ABCDEF', ((@Value & CONVERT(bigint, 8070450532247928832)) / CONVERT(bigint, 1152921504606846976)) + CASE WHEN @Value < 0 THEN 8 ELSE 0 END + 1, 1)
        + SUBSTRING('0123456789ABCDEF', ((@Value & CONVERT(bigint, 1080863910568919040)) / CONVERT(bigint, 72057594037927936)) + 1, 1)
        + SUBSTRING('0123456789ABCDEF', ((@Value & CONVERT(bigint, 67553994410557440)) / CONVERT(bigint, 4503599627370496)) + 1, 1)
        + SUBSTRING('0123456789ABCDEF', ((@Value & CONVERT(bigint, 4222124650659840)) / CONVERT(bigint, 281474976710656)) + 1, 1)
        + SUBSTRING('0123456789ABCDEF', ((@Value & CONVERT(bigint, 263882790666240)) / CONVERT(bigint, 17592186044416)) + 1, 1)
        + SUBSTRING('0123456789ABCDEF', ((@Value & CONVERT(bigint, 16492674416640)) / CONVERT(bigint, 1099511627776)) + 1, 1)
        + SUBSTRING('0123456789ABCDEF', ((@Value & CONVERT(bigint, 1030792151040)) / CONVERT(bigint, 68719476736)) + 1, 1)
        + SUBSTRING('0123456789ABCDEF', ((@Value & CONVERT(bigint, 64424509440)) / CONVERT(bigint, 4294967296)) + 1, 1)
        + SUBSTRING('0123456789ABCDEF', ((@Value & CONVERT(bigint, 4026531840)) / CONVERT(bigint, 268435456)) + 1, 1)
        + SUBSTRING('0123456789ABCDEF', ((@Value & CONVERT(bigint, 251658240)) / CONVERT(bigint, 16777216)) + 1, 1)
        + SUBSTRING('0123456789ABCDEF', ((@Value & CONVERT(bigint, 15728640)) / CONVERT(bigint, 1048576)) + 1, 1)
        + SUBSTRING('0123456789ABCDEF', ((@Value & CONVERT(bigint, 983040)) / CONVERT(bigint, 65536)) + 1, 1)
        + SUBSTRING('0123456789ABCDEF', ((@Value & CONVERT(bigint, 61440)) / CONVERT(bigint, 4096)) + 1, 1)
        + SUBSTRING('0123456789ABCDEF', ((@Value & CONVERT(bigint, 3840)) / CONVERT(bigint, 256)) + 1, 1)
        + SUBSTRING('0123456789ABCDEF', ((@Value & CONVERT(bigint, 240)) / CONVERT(bigint, 16)) + 1, 1)
        + SUBSTRING('0123456789ABCDEF', ((@Value & CONVERT(bigint, 15)) / CONVERT(bigint, 1)) + 1, 1)
        , 2)
);
GO
