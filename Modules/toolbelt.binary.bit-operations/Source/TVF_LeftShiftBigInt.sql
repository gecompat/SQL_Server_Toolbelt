-- ============================================================================
-- Objekt:          toolbelt_binary.TVF_LeftShiftBigInt
-- Zweck:           Logischer 64-Bit-Left-Shift für bigint.
-- Parameter:       @Value bigint, @ShiftAmount bigint
-- Resultset:       Value bigint
-- Dependencies:    keine Toolbelt-Module
-- Versionen:       SQL Server 2019, 2022 und 2025
-- Performance:     Inline TVF; decimal(38,0)-Arithmetik ohne Loop
-- Einschränkungen: Ausschließlich bigint; Binary-Typen sind nicht Teil V1.
-- ============================================================================

CREATE OR ALTER FUNCTION [toolbelt_binary].[TVF_LeftShiftBigInt]
(
      @Value       bigint
    , @ShiftAmount bigint
)
RETURNS TABLE
AS
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-toolbelt-toolbelt-binary-tvf-leftshiftbigint"
-- description: "Verschiebt die Bits eines bigint-Werts nach links."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.binary.bit-operations"
-- schema_name: "toolbelt_binary"
-- object_name: "TVF_LeftShiftBigInt"
-- object_type: "TVF"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@Value", "sql_type": "bigint", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "SQL-bigint als vorzeichenbehaftetes 64-Bit-Zweierkomplement (-9223372036854775808 bis 9223372036854775807); negative Werte sind gültige Bitmuster. NULL liefert einen NULL-Wert."}, {"name": "@ShiftAmount", "sql_type": "bigint", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Ganzzahlige Bitanzahl: 0 lässt das Muster unverändert; 1..63 verschiebt links; -1..-63 kehrt die Richtung um. Beträge ab 64 liefern 0, auch der kleinste bigint. NULL ergibt NULL."}]
-- source_paths: ["Modules/toolbelt.binary.bit-operations/Source/TVF_LeftShiftBigInt.sql"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- ---
--
-- # TVF_LeftShiftBigInt
--
-- ## Zweck und Einsatzfälle
--
-- Verschiebt die Bits eines bigint-Werts nach links. Der Vertrag wird aus der bigint-/decimal-Arithmetik und den CASE-Guards der jeweiligen Source abgeleitet.
--
-- ## Voraussetzungen
--
-- SQL Server 2019 oder neuer. Alle Funktionsargumente positionsbezogen angeben; für einen deklarierten Default ist DEFAULT anzugeben. Kein CLR oder externer Provider erforderlich.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
-- |---|---|---|---|---|
-- | `@Value` | `bigint` | `kein Default` | Input | SQL-bigint als vorzeichenbehaftetes 64-Bit-Zweierkomplement (-9223372036854775808 bis 9223372036854775807); negative Werte sind gültige Bitmuster. NULL liefert einen NULL-Wert. |
-- | `@ShiftAmount` | `bigint` | `kein Default` | Input | Ganzzahlige Bitanzahl: 0 lässt das Muster unverändert; 1..63 verschiebt links; -1..-63 kehrt die Richtung um. Beträge ab 64 liefern 0, auch der kleinste bigint. NULL ergibt NULL. |
--
-- ## Ergebnisse
--
-- Genau eine Zeile mit Value bigint. NULL in einem Argument ergibt NULL. Logischer 64-Bit-Shift mit Nullauffüllung; herausgeschobene Bits gehen verloren, das Ergebnis wird als vorzeichenbehaftetes Zweierkomplement-bigint zurückgegeben. Negativer Shiftbetrag kehrt die Richtung um; Betrag ab 64 liefert 0. RightShift behandelt bigint-Minimum explizit ohne Negationsüberlauf.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- SELECT * FROM toolbelt_binary.TVF_LeftShiftBigInt(255, 2);
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
-- Kein arithmetischer Shift mit Vorzeichenerweiterung, keine beliebige Binärbreite und keine Ganzzahlmultiplikation mit Überlaufmeldung. Rechtsverschiebung negativer Zahlen kann einen positiven Wert ergeben.
-- OBJECT_USAGE_SKILL:END
RETURN
(
    WITH Parameters AS
    (
        SELECT
              UnsignedValue =
                  CONVERT(decimal(38,0), @Value)
                  + CASE
                        WHEN @Value < 0
                            THEN CONVERT(decimal(38,0), 18446744073709551616)
                        ELSE CONVERT(decimal(38,0), 0)
                    END
            , EffectiveAmount = CONVERT
              (
                  int,
                  CASE
                      WHEN @ShiftAmount BETWEEN 0 AND 63 THEN @ShiftAmount
                      WHEN @ShiftAmount BETWEEN -63 AND -1
                          THEN -@ShiftAmount
                      ELSE 0
                  END
              )
            , IsLeft = CONVERT(bit, CASE WHEN @ShiftAmount >= 0 THEN 1 ELSE 0 END)
    ),
    Shifted AS
    (
        SELECT ShiftedUnsigned =
            CONVERT
            (
                decimal(38,0),
                CASE
                    WHEN @Value IS NULL OR @ShiftAmount IS NULL THEN NULL
                    WHEN @ShiftAmount NOT BETWEEN -63 AND 63 THEN 0
                    WHEN parameters.IsLeft = 1
                        THEN
                            (
                                parameters.UnsignedValue
                                % POWER
                                  (
                                      CONVERT(decimal(38,0), 2),
                                      64 - parameters.EffectiveAmount
                                  )
                            )
                            * POWER
                              (
                                  CONVERT(decimal(38,0), 2),
                                  parameters.EffectiveAmount
                              )
                    ELSE FLOOR
                         (
                             parameters.UnsignedValue
                             / POWER
                               (
                                   CONVERT(decimal(38,0), 2),
                                   parameters.EffectiveAmount
                               )
                         )
                END
            )
        FROM Parameters AS parameters
    )
    SELECT Value = CONVERT
    (
        bigint,
        CASE
            WHEN shifted.ShiftedUnsigned >=
                 CONVERT(decimal(38,0), 9223372036854775808)
                THEN shifted.ShiftedUnsigned
                     - CONVERT(decimal(38,0), 18446744073709551616)
            ELSE shifted.ShiftedUnsigned
        END
    )
    FROM Shifted AS shifted
);
GO
