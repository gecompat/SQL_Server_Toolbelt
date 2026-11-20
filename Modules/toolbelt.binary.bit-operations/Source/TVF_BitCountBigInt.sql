-- ============================================================================
-- Objekt:          toolbelt_binary.TVF_BitCountBigInt
-- Zweck:           Zählt gesetzte Bits im vollständigen bigint-Bitmuster.
-- Parameter:       @Value bigint
-- Resultset:       Value bigint
-- Dependencies:    keine Toolbelt-Module
-- Versionen:       SQL Server 2019, 2022 und 2025
-- Performance:     Inline TVF; acht Bytes werden set-basiert ausgewertet.
-- ============================================================================

CREATE OR ALTER FUNCTION [toolbelt_binary].[TVF_BitCountBigInt]
(
    @Value bigint
)
RETURNS TABLE
AS
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-toolbelt-toolbelt-binary-tvf-bitcountbigint"
-- description: "Zählt gesetzte Bits im bigint-Wert."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.binary.bit-operations"
-- schema_name: "toolbelt_binary"
-- object_name: "TVF_BitCountBigInt"
-- object_type: "TVF"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@Value", "sql_type": "bigint", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "SQL-bigint als vorzeichenbehaftetes 64-Bit-Zweierkomplement (-9223372036854775808 bis 9223372036854775807); negative Werte sind gültige Bitmuster. NULL liefert einen NULL-Wert. Gezählt werden alle 64 Bits, einschließlich des Vorzeichenbits; -1 hat 64 gesetzte Bits."}]
-- source_paths: ["Modules/toolbelt.binary.bit-operations/Source/TVF_BitCountBigInt.sql"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- ---
--
-- # TVF_BitCountBigInt
--
-- ## Zweck und Einsatzfälle
--
-- Zählt gesetzte Bits im bigint-Wert. Der Vertrag wird aus der bigint-/decimal-Arithmetik und den CASE-Guards der jeweiligen Source abgeleitet.
--
-- ## Voraussetzungen
--
-- SQL Server 2019 oder neuer. Alle Funktionsargumente positionsbezogen angeben; für einen deklarierten Default ist DEFAULT anzugeben. Kein CLR oder externer Provider erforderlich.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
-- |---|---|---|---|---|
-- | `@Value` | `bigint` | `kein Default` | Input | SQL-bigint als vorzeichenbehaftetes 64-Bit-Zweierkomplement (-9223372036854775808 bis 9223372036854775807); negative Werte sind gültige Bitmuster. NULL liefert einen NULL-Wert. Gezählt werden alle 64 Bits, einschließlich des Vorzeichenbits; -1 hat 64 gesetzte Bits. |
--
-- ## Ergebnisse
--
-- Genau eine Zeile mit Value bigint. NULL-Eingabe liefert NULL; sonst 0..64 gesetzte Bits des vollständigen 64-Bit-Zweierkomplementmusters. Für -1 ist das Ergebnis 64.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- SELECT * FROM toolbelt_binary.TVF_BitCountBigInt(255);
-- ```
--
-- ## Rechte
--
-- Vorhandenes SELECT oder REFERENCES auf der Funktion; Cross-Database-Zuordnung und Aufrufrechte gelten unverändert. Keine Rechtevergabe oder Ausführungsidentitätsänderung.
--
-- ## Ressourcenbedarf
--
-- Inline-TVF ohne persistente Zustandsänderung. Konstante begrenzte 64-Bit-/decimal(38,0)-Arithmetik; BitCount wertet acht Bytes set-basiert aus. Keine unbeschränkten Schleifen und keine pauschale Plan-/Laufzeitgarantie.
--
-- ## Nebenwirkungen
--
-- Read-only; keine Datei-, Netzwerk-, Tabellen- oder Konfigurationsänderung.
--
-- ## Fehlerbehandlung
--
-- NULL und fachlich ungültige Werte werden wie unten beschrieben als Ergebniswerte/Status abgebildet. SQL-Typbindung und unerwartete Enginefehler bleiben reguläre Enginefehler; keine automatische Umdeutung.
--
-- ## Aussagegrenzen
--
-- Zählt das Bitmuster des gebundenen bigint, keine Zeichen-/Hexdarstellung und keine beliebig breiten Binärdaten. Keine Gleichsetzung von Anzahl gesetzter Bits und Vorzeichen/Betrag.
-- OBJECT_USAGE_SKILL:END
RETURN
(
    WITH Bytes AS
    (
        SELECT ByteValue = CONVERT
        (
            int,
            SUBSTRING(CONVERT(binary(8), @Value), positions.BytePosition, 1)
        )
        FROM
        (
            VALUES (1), (2), (3), (4), (5), (6), (7), (8)
        ) AS positions(BytePosition)
    )
    SELECT Value = CONVERT
    (
        bigint,
        CASE
            WHEN @Value IS NULL THEN NULL
            ELSE SUM
                 (
                       (bytes.ByteValue & 1)
                     + ((bytes.ByteValue & 2) / 2)
                     + ((bytes.ByteValue & 4) / 4)
                     + ((bytes.ByteValue & 8) / 8)
                     + ((bytes.ByteValue & 16) / 16)
                     + ((bytes.ByteValue & 32) / 32)
                     + ((bytes.ByteValue & 64) / 64)
                     + ((bytes.ByteValue & 128) / 128)
                 )
        END
    )
    FROM Bytes AS bytes
);
GO
