-- ============================================================================
-- Objekt:          toolbelt_core.TVF_GenerateSeriesBigInt
-- Zweck:           Portable bigint-Zahlenreihe einschließlich Startwert
-- Parameter:       @Start bigint, @Stop bigint, @Step bigint = NULL
-- Resultset:       Value bigint
-- Dependencies:    keine Toolbelt-Module
-- Versionen:       SQL Server 2019, 2022 und 2025
-- Performance:     Inline TVF; konstante Rowsets und zeilenzahlgesteuerter TOP
-- Collation:       nicht anwendbar
-- Einschränkungen: keine garantierte Reihenfolge; Row Count muss bigint-fähig sein
-- ============================================================================

CREATE OR ALTER FUNCTION [toolbelt_core].[TVF_GenerateSeriesBigInt]
(
      @Start bigint
    , @Stop  bigint
    , @Step  bigint = NULL
)
RETURNS TABLE
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-toolbelt-toolbelt-core-tvf-generateseriesbigint"
-- description: "Erzeugt eine Folge von bigint-Werten einschließlich erreichbarem Endwert."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.core.generate-series"
-- schema_name: "toolbelt_core"
-- object_name: "TVF_GenerateSeriesBigInt"
-- object_type: "TVF"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@Start", "sql_type": "bigint", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Erster Wert im gesamten SQL-bigint-Bereich; Start wird bei gültiger Richtung eingeschlossen. NULL ergibt keine Zeilen; ein zusätzlich übergebener Schritt 0 bleibt ein Enginefehler."}, {"name": "@Stop", "sql_type": "bigint", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Inklusive Zielgrenze im SQL-bigint-Bereich; nur tatsächlich durch ganze Schritte erreichbare Werte werden ausgegeben, kein künstlicher Endwert. NULL ergibt keine Zeilen, außer dem ausdrücklich ungültigen Schritt-0-Fall."}, {"name": "@Step", "sql_type": "bigint", "sql_default": "NULL", "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Ganzzahlige Schrittweite als bigint. Default/NULL: +1 bei Start <= Stop, sonst -1. Positive Werte laufen aufwärts, negative abwärts; zur Richtung unpassende Grenzen ergeben keine Zeilen. 0 ergibt einen SQL-Engine-Divisionsfehler. Die berechnete Zeilenzahl muss in bigint passen; keine feste kleine Ausgabelimitierung."}]
-- source_paths: ["Modules/toolbelt.core.generate-series/Source/TVF_GenerateSeriesBigInt.sql"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- ---
--
-- # TVF_GenerateSeriesBigInt
--
-- ## Zweck und Einsatzfälle
--
-- Erzeugt eine Folge von bigint-Werten einschließlich erreichbarem Endwert. Mathematische Fassade ohne kleines Zeilenlimit; nur für vertrauenswürdige, bewusst begrenzte Aufrufer verwenden. Für untrusted Aufrufe die Statusfunktion bevorzugen.
--
-- ## Voraussetzungen
--
-- SQL Server 2019/2022/2025, Windows oder Linux; Compatibility Level 150/160/170. Modul installiert, kein CLR oder externer Provider. Alle drei Argumentpositionen müssen im Funktionsaufruf angegeben werden; DEFAULT in der dritten Position oder explizites NULL aktiviert den Richtungsdefault.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Vertrag |
-- |---|---|---|---|
-- | `@Start` | `bigint` | `kein Default` | Erster Wert im gesamten SQL-bigint-Bereich; Start wird bei gültiger Richtung eingeschlossen. NULL ergibt keine Zeilen; ein zusätzlich übergebener Schritt 0 bleibt ein Enginefehler. |
-- | `@Stop` | `bigint` | `kein Default` | Inklusive Zielgrenze im SQL-bigint-Bereich; nur tatsächlich durch ganze Schritte erreichbare Werte werden ausgegeben, kein künstlicher Endwert. NULL ergibt keine Zeilen, außer dem ausdrücklich ungültigen Schritt-0-Fall. |
-- | `@Step` | `bigint` | `NULL` | Ganzzahlige Schrittweite als bigint. Default/NULL: +1 bei Start <= Stop, sonst -1. Positive Werte laufen aufwärts, negative abwärts; zur Richtung unpassende Grenzen ergeben keine Zeilen. 0 ergibt einen SQL-Engine-Divisionsfehler. Die berechnete Zeilenzahl muss in bigint passen; keine feste kleine Ausgabelimitierung. |
--
-- ## Ergebnisse
--
-- Null bis mehrere Zeilen mit genau einer Spalte Value bigint. Bei gültiger Richtung ist Start enthalten; Stop wird nur bei Erreichbarkeit durch ganze Schritte ausgegeben. Falsche Richtung oder NULL in Start/Stop liefert keine Zeilen, außer Step=0: dieser Fehler hat in der mathematischen Fassade Vorrang. Gleiche nicht-NULL-Grenzen liefern bei nichtnulligem Schritt genau den Startwert. Keine garantierte Reihenfolge.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- SELECT Value FROM toolbelt_core.TVF_GenerateSeriesBigInt(2,10,3) ORDER BY Value;
-- -- 2, 5, 8; kein künstlicher Endwert 10.
-- SELECT Value FROM toolbelt_core.TVF_GenerateSeriesBigInt(10,1,-4) ORDER BY Value DESC;
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
     * DDL-Hilfe: Erzeugt eine portable bigint-Reihe ohne internes Zeilenlimit.
     * Parameter: @Start bigint NULL, @Stop bigint NULL, @Step bigint NULL
     * (Default NULL). NULL oder DEFAULT für @Step wählt +1 bei Start <= Stop,
     * sonst -1. Der Start ist enthalten; Stop nur, wenn die Schrittfolge ihn
     * erreicht. Eine falsche Schrittrichtung oder NULL bei Start/Stop ergibt
     * keine Zeile. Schritt 0 bleibt der
     * unveränderte Enginefehler, auch wenn eine Grenze NULL ist. Eine
     * Zeilenzahl außerhalb bigint löst Engine-Overflow statt Kürzung aus.
     * Ergebnis: Value bigint; keine Reihenfolge ohne ORDER BY. Für SELECT-
     * Aufrufe ist SELECT auf der Funktion erforderlich.
     * Beispiel: SELECT Value FROM toolbelt_core.TVF_GenerateSeriesBigInt
     * (CONVERT(bigint,10),CONVERT(bigint,1),CONVERT(bigint,-4)) ORDER BY Value DESC;
     * Erwartete Werte: 10, 6, 2.
     */
    /*
     * Die binäre Stapelung stellt 2^64 logische Quellzeilen bereit. TOP
     * begrenzt die tatsächlich angeforderte Menge durch einen Row Goal; die
     * Zwischenmenge wird nicht materialisiert. decimal(38,0) verhindert
     * Überläufe bei Differenz, Betrag und Wertberechnung an bigint-Grenzen.
     */
    WITH
    ResolvedParameters AS
    (
        SELECT
              StartValue = @Start
            , StopValue  = @Stop
            , StepValue  = COALESCE
              (
                  @Step
                , CASE WHEN @Start <= @Stop
                       THEN CONVERT(bigint, 1)
                       ELSE CONVERT(bigint, -1)
                  END
              )
    ),
    CountedParameters AS
    (
        SELECT
              parameters.StartValue
            , parameters.StepValue
            , RequestedRows = CASE
                  /*
                   * Eine Schrittweite 0 bleibt ein unveränderter Enginefehler.
                   * Die Division wird nur für diesen ungültigen Fall gewählt.
                   */
                  WHEN parameters.StepValue = 0
                      THEN CONVERT(bigint, 1 / parameters.StepValue)
                  WHEN parameters.StartValue IS NULL
                    OR parameters.StopValue IS NULL
                      THEN CONVERT(bigint, 0)
                  WHEN parameters.StepValue > 0
                   AND parameters.StartValue <= parameters.StopValue
                      THEN CONVERT
                           (
                               bigint
                             , (
                                   CONVERT(decimal(38, 0), parameters.StopValue)
                                   - CONVERT(decimal(38, 0), parameters.StartValue)
                               )
                               / CONVERT(decimal(38, 0), parameters.StepValue)
                               + 1
                           )
                  WHEN parameters.StepValue < 0
                   AND parameters.StartValue >= parameters.StopValue
                      THEN CONVERT
                           (
                               bigint
                             , (
                                   CONVERT(decimal(38, 0), parameters.StartValue)
                                   - CONVERT(decimal(38, 0), parameters.StopValue)
                               )
                               / -CONVERT(decimal(38, 0), parameters.StepValue)
                               + 1
                           )
                  ELSE CONVERT(bigint, 0)
              END
        FROM ResolvedParameters AS parameters
    ),
    E1(N) AS
    (
        SELECT source.N
        FROM (VALUES (0), (0)) AS source(N)
    ),
    E2(N) AS
    (
        SELECT 0 FROM E1 AS a CROSS JOIN E1 AS b
    ),
    E4(N) AS
    (
        SELECT 0 FROM E2 AS a CROSS JOIN E2 AS b
    ),
    E8(N) AS
    (
        SELECT 0 FROM E4 AS a CROSS JOIN E4 AS b
    ),
    E16(N) AS
    (
        SELECT 0 FROM E8 AS a CROSS JOIN E8 AS b
    ),
    E32(N) AS
    (
        SELECT 0 FROM E16 AS a CROSS JOIN E16 AS b
    ),
    E64(N) AS
    (
        SELECT 0 FROM E32 AS a CROSS JOIN E32 AS b
    ),
    Ordinals AS
    (
        SELECT TOP
        (
            COALESCE
            (
                (SELECT counted.RequestedRows FROM CountedParameters AS counted)
              , CONVERT(bigint, 0)
            )
        )
            Ordinal = ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1
        FROM E64
    )
    SELECT
        Value = CONVERT
        (
            bigint
          , CONVERT(decimal(38, 0), parameters.StartValue)
            + CONVERT(decimal(38, 0), ordinals.Ordinal)
              * CONVERT(decimal(38, 0), parameters.StepValue)
        )
    FROM CountedParameters AS parameters
    CROSS JOIN Ordinals AS ordinals
);
GO

-- Begrenzte Oberfläche für untrusted Aufrufe. Die mathematische Altfassade
-- bleibt unter der ausdrücklichen Betreiberpolicy für vertrauenswürdige Principals.
CREATE OR ALTER FUNCTION [toolbelt_core].[TVF_GenerateSeriesBigIntStatus]
(@Start bigint,@Stop bigint,@Step bigint=NULL)
RETURNS @Result TABLE(Value bigint NULL,Status varchar(16) NOT NULL,RequestedRows decimal(38,0) NULL)
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-toolbelt-toolbelt-core-tvf-generateseriesbigintstatus"
-- description: "Vor Expansion exakte Anzahl mit decimal(38,0) und Restrechnung bestimmen. Höchstens 1000000 OK-Zeilen. LIMIT, INVALID, SQL_NULL oder EMPTY liefern eine Kontrollzeile ohne Value. RequestedRows unterscheidet leere und zu große Reihen. Keine garantierte Reihenfolge. Die mathematischen Alt-APIs bleiben unverändert und benötigen vertrauenswürdige Direktgrants. Untrusted Legacygrants werden nicht automatisch entzogen; SC-018 bleibt in einer solchen Installation offen."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.core.generate-series"
-- schema_name: "toolbelt_core"
-- object_name: "TVF_GenerateSeriesBigIntStatus"
-- object_type: "TVF"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@Start", "sql_type": "bigint", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Erster Wert im gesamten SQL-bigint-Bereich; Start wird bei gültiger Richtung eingeschlossen. NULL ergibt eine SQL_NULL-Kontrollzeile."}, {"name": "@Stop", "sql_type": "bigint", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Inklusive Zielgrenze im SQL-bigint-Bereich; nur tatsächlich durch ganze Schritte erreichbare Werte werden ausgegeben, kein künstlicher Endwert. NULL ergibt SQL_NULL."}, {"name": "@Step", "sql_type": "bigint", "sql_default": "NULL", "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Ganzzahlige Schrittweite als bigint. Default/NULL: +1 bei Start <= Stop, sonst -1. Positive Werte laufen aufwärts, negative abwärts; zur Richtung unpassende Grenzen ergeben EMPTY. 0 ergibt INVALID; NULL bei Start/Stop hat Vorrang. Maximal 1000000 Werte, sonst LIMIT mit RequestedRows."}]
-- source_paths: ["Modules/toolbelt.core.generate-series/Source/TVF_GenerateSeriesBigInt.sql"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- ---
--
-- # TVF_GenerateSeriesBigIntStatus
--
-- ## Zweck und Einsatzfälle
--
-- Vor Expansion exakte Anzahl mit decimal(38,0) und Restrechnung bestimmen. Höchstens 1000000 OK-Zeilen. LIMIT, INVALID, SQL_NULL oder EMPTY liefern eine Kontrollzeile ohne Value. RequestedRows unterscheidet leere und zu große Reihen. Keine garantierte Reihenfolge. Die mathematischen Alt-APIs bleiben unverändert und benötigen vertrauenswürdige Direktgrants. Untrusted Legacygrants werden nicht automatisch entzogen; SC-018 bleibt in einer solchen Installation offen. Begrenzte Kontrolloberfläche für nicht vertrauenswürdige Eingaben.
--
-- ## Voraussetzungen
--
-- SQL Server 2019/2022/2025, Windows oder Linux; Compatibility Level 150/160/170. Modul installiert, kein CLR oder externer Provider. Alle drei Argumentpositionen müssen im Funktionsaufruf angegeben werden; DEFAULT in der dritten Position oder explizites NULL aktiviert den Richtungsdefault.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Vertrag |
-- |---|---|---|---|
-- | `@Start` | `bigint` | `kein Default` | Erster Wert im gesamten SQL-bigint-Bereich; Start wird bei gültiger Richtung eingeschlossen. NULL ergibt eine SQL_NULL-Kontrollzeile. |
-- | `@Stop` | `bigint` | `kein Default` | Inklusive Zielgrenze im SQL-bigint-Bereich; nur tatsächlich durch ganze Schritte erreichbare Werte werden ausgegeben, kein künstlicher Endwert. NULL ergibt SQL_NULL. |
-- | `@Step` | `bigint` | `NULL` | Ganzzahlige Schrittweite als bigint. Default/NULL: +1 bei Start <= Stop, sonst -1. Positive Werte laufen aufwärts, negative abwärts; zur Richtung unpassende Grenzen ergeben EMPTY. 0 ergibt INVALID; NULL bei Start/Stop hat Vorrang. Maximal 1000000 Werte, sonst LIMIT mit RequestedRows. |
--
-- ## Ergebnisse
--
-- Value bigint NULL, Status varchar(16) NOT NULL und RequestedRows decimal(38,0) NULL. Bei gültigen höchstens 1000000 Werten je eine Zeile mit Status OK und derselben Gesamtzahl. Sonst genau eine Kontrollzeile: SQL_NULL bei NULL in Start/Stop (Value/RequestedRows NULL), INVALID bei Step=0 (beide NULL), EMPTY bei falscher Richtung (Value=NULL, RequestedRows=0), LIMIT bei mehr als 1000000 Werten (Value=NULL, RequestedRows=exakte Gesamtzahl). NULL-Prüfung hat Vorrang vor Step=0.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- SELECT Value,Status,RequestedRows
-- FROM toolbelt_core.TVF_GenerateSeriesBigIntStatus(1,5,2) ORDER BY Value;
-- -- (1,OK,3), (3,OK,3), (5,OK,3).
-- SELECT * FROM toolbelt_core.TVF_GenerateSeriesBigIntStatus(1,1000001,1);
-- -- Eine Zeile: Value=NULL, Status=LIMIT, RequestedRows=1000001.
-- ```
--
-- ## Rechte
--
-- Vorhandenes SELECT für SELECT-Aufrufe auf der Funktion; REFERENCES für entsprechende Referenzverwendungen. Kein Rechtegrant oder Identitätswechsel. Die Installation allein macht unbegrenzte Aufrufe durch untrusted Principals nicht sicher.
--
-- ## Ressourcenbedarf
--
-- Multistatement-TVF berechnet die angeforderte Anzahl in decimal(38,0) vor der Expansion. Oberhalb 1000000 keine Fachzeilenexpansion, sondern eine LIMIT-Kontrollzeile. Bis zu 1000000 Zeilen werden über den bigint-Kern in die Rückgabetabelle eingefügt; diese Grenze ist kein Laufzeit-/Speicherversprechen.
--
-- ## Nebenwirkungen
--
-- Keine persistenten Daten-, Datei-, Netzwerk-, Konfigurations- oder Truständerungen. Die Statusfunktion befüllt ausschließlich ihre lokale Rückgabetabelle. Keine Ausführungsautorität durch diese Beschreibung.
--
-- ## Fehlerbehandlung
--
-- NULL, Step=0, falsche Richtung und Mengenüberschreitung werden wie oben als Kontrollzeilen ausgegeben. Typbindung und unerwartete Enginefehler bleiben Fehler.
--
-- ## Aussagegrenzen
--
-- ORDER BY selbst angeben; keine Ausgabeordnung aus ROW_NUMBER ableiten. Keine Datums-, Dezimal- oder beliebige Zahlenbreitensemantik. Bei der Statusfunktion sind Kontrollzeilen von gültigen Werten durch Status zu unterscheiden; COUNT(*) ist dort keine verlässliche Fachzeilenzahl. Mathematische Fassade und Statusoberfläche haben ausdrücklich unterschiedliche NULL-/Fehlerprioritäten und Mengengrenzen.
-- OBJECT_USAGE_SKILL:END
AS
BEGIN
    /*
     * DDL-Hilfe: Liefert Werte oder eine begrenzte Statuszeile für nicht
     * vertrauenswürdige
     * Aufrufe. Parameter: @Start bigint NULL, @Stop bigint NULL,
     * @Step bigint NULL (Default NULL; Richtung automatisch). NULL bei Start
     * oder Stop hat Vorrang und ergibt (NULL,SQL_NULL,NULL). Schritt 0 ergibt
     * (NULL,INVALID,NULL); falsche Richtung ergibt (NULL,EMPTY,0). Mehr als
     * 1000000 angeforderte Werte ergibt (NULL,LIMIT,exakte RequestedRows).
     * Gültige Werte ergeben je eine Zeile mit Status=OK und der Gesamtzahl.
     * Ergebnis: Value bigint NULL, Status varchar(16),
     * RequestedRows decimal(38,0) NULL; keine Reihenfolge ohne ORDER BY.
     * Für SELECT-Aufrufe ist SELECT auf der Funktion erforderlich.
     * Beispiel: SELECT Value,Status,RequestedRows
     * FROM toolbelt_core.TVF_GenerateSeriesBigIntStatus(1,5,2)
     * ORDER BY Value;
     * Erwartet: (1,OK,3), (3,OK,3), (5,OK,3).
     */
    IF @Start IS NULL OR @Stop IS NULL
    BEGIN INSERT @Result VALUES(NULL,'SQL_NULL',NULL); RETURN; END;
    SET @Step=COALESCE(@Step,CASE WHEN @Start<=@Stop THEN CONVERT(bigint,1) ELSE CONVERT(bigint,-1) END);
    IF @Step=0 BEGIN INSERT @Result VALUES(NULL,'INVALID',NULL); RETURN; END;
    IF (@Step>0 AND @Start>@Stop) OR (@Step<0 AND @Start<@Stop)
    BEGIN INSERT @Result VALUES(NULL,'EMPTY',0); RETURN; END;
    DECLARE @Distance decimal(38,0)=ABS(CONVERT(decimal(38,0),@Stop)-CONVERT(decimal(38,0),@Start)),
            @Magnitude decimal(38,0)=ABS(CONVERT(decimal(38,0),@Step)),@Rows decimal(38,0);
    SET @Rows=(@Distance-(@Distance%@Magnitude))/@Magnitude+1;
    IF @Rows>1000000 BEGIN INSERT @Result VALUES(NULL,'LIMIT',@Rows); RETURN; END;
    INSERT @Result SELECT Value,'OK',@Rows FROM toolbelt_core.TVF_GenerateSeriesBigInt(@Start,@Stop,@Step);
    RETURN;
END;
GO
