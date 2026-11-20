-- ============================================================================
-- Objekt:          toolbelt_core.TVF_GenerateSeriesInt
-- Zweck:           Typstabile int-Zahlenreihe einschließlich Startwert
-- Parameter:       @Start int, @Stop int, @Step int = NULL
-- Resultset:       Value int
-- Dependencies:    TVF_GenerateSeriesBigInt im selben Modul
-- Versionen:       SQL Server 2019, 2022 und 2025
-- Performance:     dünne Inline-TVF über dem gemeinsamen bigint-Kern
-- Collation:       nicht anwendbar
-- Einschränkungen: keine garantierte Reihenfolge
-- ============================================================================

CREATE OR ALTER FUNCTION [toolbelt_core].[TVF_GenerateSeriesInt]
(
      @Start int
    , @Stop  int
    , @Step  int = NULL
)
RETURNS TABLE
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-toolbelt-toolbelt-core-tvf-generateseriesint"
-- description: "Erzeugt eine Folge von int-Werten einschließlich erreichbarem Endwert."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.core.generate-series"
-- schema_name: "toolbelt_core"
-- object_name: "TVF_GenerateSeriesInt"
-- object_type: "TVF"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@Start", "sql_type": "int", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Erster Wert im gesamten SQL-int-Bereich; Start wird bei gültiger Richtung eingeschlossen. NULL ergibt keine Zeilen; ein zusätzlich übergebener Schritt 0 bleibt ein Enginefehler."}, {"name": "@Stop", "sql_type": "int", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Inklusive Zielgrenze im SQL-int-Bereich; nur tatsächlich durch ganze Schritte erreichbare Werte werden ausgegeben, kein künstlicher Endwert. NULL ergibt keine Zeilen, außer dem ausdrücklich ungültigen Schritt-0-Fall."}, {"name": "@Step", "sql_type": "int", "sql_default": "NULL", "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Ganzzahlige Schrittweite als int. Default/NULL: +1 bei Start <= Stop, sonst -1. Positive Werte laufen aufwärts, negative abwärts; zur Richtung unpassende Grenzen ergeben keine Zeilen. 0 ergibt einen SQL-Engine-Divisionsfehler. Die berechnete Zeilenzahl muss in bigint passen; keine feste kleine Ausgabelimitierung."}]
-- source_paths: ["Modules/toolbelt.core.generate-series/Source/TVF_GenerateSeriesInt.sql", "Modules/toolbelt.core.generate-series/Source/TVF_GenerateSeriesBigInt.sql"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- ---
--
-- # TVF_GenerateSeriesInt
--
-- ## Zweck und Einsatzfälle
--
-- Erzeugt eine Folge von int-Werten einschließlich erreichbarem Endwert. Mathematische Fassade ohne kleines Zeilenlimit; nur für vertrauenswürdige, bewusst begrenzte Aufrufer verwenden. Für untrusted Aufrufe die Statusfunktion bevorzugen.
--
-- ## Voraussetzungen
--
-- SQL Server 2019/2022/2025, Windows oder Linux; Compatibility Level 150/160/170. Modul installiert, kein CLR oder externer Provider. Alle drei Argumentpositionen müssen im Funktionsaufruf angegeben werden; DEFAULT in der dritten Position oder explizites NULL aktiviert den Richtungsdefault.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Vertrag |
-- |---|---|---|---|
-- | `@Start` | `int` | `kein Default` | Erster Wert im gesamten SQL-int-Bereich; Start wird bei gültiger Richtung eingeschlossen. NULL ergibt keine Zeilen; ein zusätzlich übergebener Schritt 0 bleibt ein Enginefehler. |
-- | `@Stop` | `int` | `kein Default` | Inklusive Zielgrenze im SQL-int-Bereich; nur tatsächlich durch ganze Schritte erreichbare Werte werden ausgegeben, kein künstlicher Endwert. NULL ergibt keine Zeilen, außer dem ausdrücklich ungültigen Schritt-0-Fall. |
-- | `@Step` | `int` | `NULL` | Ganzzahlige Schrittweite als int. Default/NULL: +1 bei Start <= Stop, sonst -1. Positive Werte laufen aufwärts, negative abwärts; zur Richtung unpassende Grenzen ergeben keine Zeilen. 0 ergibt einen SQL-Engine-Divisionsfehler. Die berechnete Zeilenzahl muss in bigint passen; keine feste kleine Ausgabelimitierung. |
--
-- ## Ergebnisse
--
-- Null bis mehrere Zeilen mit genau einer Spalte Value int. Bei gültiger Richtung ist Start enthalten; Stop wird nur bei Erreichbarkeit durch ganze Schritte ausgegeben. Falsche Richtung oder NULL in Start/Stop liefert keine Zeilen, außer Step=0: dieser Fehler hat in der mathematischen Fassade Vorrang. Gleiche nicht-NULL-Grenzen liefern bei nichtnulligem Schritt genau den Startwert. Keine garantierte Reihenfolge.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- SELECT Value FROM toolbelt_core.TVF_GenerateSeriesInt(2,10,3) ORDER BY Value;
-- -- 2, 5, 8; kein künstlicher Endwert 10.
-- SELECT Value FROM toolbelt_core.TVF_GenerateSeriesInt(10,1,-4) ORDER BY Value DESC;
-- -- 10, 6, 2.
-- ```
--
-- ## Rechte
--
-- Vorhandenes SELECT für SELECT-Aufrufe auf der Funktion; REFERENCES für entsprechende Referenzverwendungen. Kein Rechtegrant oder Identitätswechsel. Die Installation allein macht unbegrenzte Aufrufe durch untrusted Principals nicht sicher.
--
-- ## Ressourcenbedarf
--
-- Inline-TVF mit binär gestapelter logischer Quellmenge und TOP/ROW_NUMBER. Der Row Goal begrenzt die angeforderten Zeilen; es gibt kein festes kleines API-Limit. Kosten und mögliche Last wachsen mit der Ergebnismenge. int delegiert an bigint; decimal(38,0) schützt Zwischenarithmetik, nicht vor beliebig großer Ausgabe.
--
-- ## Nebenwirkungen
--
-- Keine persistenten Daten-, Datei-, Netzwerk-, Konfigurations- oder Truständerungen. Die Statusfunktion befüllt ausschließlich ihre lokale Rückgabetabelle. Keine Ausführungsautorität durch diese Beschreibung.
--
-- ## Fehlerbehandlung
--
-- Step=0 löst einen Engine-Divisionsfehler aus, auch bei NULL-Grenzen. Kann die berechnete Zeilenzahl nicht als bigint gebunden werden, entsteht Engine-Overflow statt Kürzung. Typbindung, Ressourcenmangel und sonstige Enginefehler werden nicht abgefangen.
--
-- ## Aussagegrenzen
--
-- ORDER BY selbst angeben; keine Ausgabeordnung aus ROW_NUMBER ableiten. Keine Datums-, Dezimal- oder beliebige Zahlenbreitensemantik. Bei der Statusfunktion sind Kontrollzeilen von gültigen Werten durch Status zu unterscheiden; COUNT(*) ist dort keine verlässliche Fachzeilenzahl. Mathematische Fassade und Statusoberfläche haben ausdrücklich unterschiedliche NULL-/Fehlerprioritäten und Mengengrenzen.
-- OBJECT_USAGE_SKILL:END
AS
RETURN
(
    /*
     * DDL-Hilfe: Erzeugt eine typstabile int-Reihe ohne internes Zeilenlimit.
     * Parameter: @Start int NULL, @Stop int NULL, @Step int NULL
     * (Default NULL). NULL oder DEFAULT für @Step wählt +1 bei Start <= Stop,
     * sonst -1. Der Start ist enthalten; Stop nur, wenn die Schrittfolge ihn
     * erreicht. Eine falsche Schrittrichtung oder NULL bei Start/Stop ergibt
     * keine Zeile. Schritt 0 bleibt der
     * unveränderte Enginefehler, auch wenn eine Grenze NULL ist. Sehr große
     * gültige Reihen werden nicht gekürzt und können erhebliche Ressourcen
     * beanspruchen. Ergebnis: Value int; keine Reihenfolge ohne ORDER BY.
     * Für SELECT-Aufrufe ist SELECT auf der Funktion erforderlich.
     * Beispiel: SELECT Value FROM toolbelt_core.TVF_GenerateSeriesInt(2,10,3)
     * ORDER BY Value;
     * Erwartete Werte: 2, 5, 8.
     */
    /*
     * Die gesamte Reihenlogik liegt im bigint-Kern. Die Rückkonvertierung
     * erhält einen int-typisierten Join- und APPLY-Vertrag ohne zweite
     * Fachimplementierung.
     */
    SELECT Value = CONVERT(int, series.Value)
    FROM [toolbelt_core].[TVF_GenerateSeriesBigInt]
    (
          CONVERT(bigint, @Start)
        , CONVERT(bigint, @Stop)
        , CONVERT(bigint, @Step)
    ) AS series
);
GO
