-- ============================================================================
-- Objekt:          toolbelt_conversion.TVF_TryCastDateTime2
-- Typ:             Inline Table-valued Function mit SCHEMABINDING
-- Zweck:           ISO-Datetime mit T und optional 1..7 Fractionstellen prüfen.
-- Vertrag:         Documentation/Architecture/SAFE_CAST_CONTRACT.md, 1.0.0
-- Parameter:       @Text nvarchar(max); @MaxInputBytes int = 8192 (positiv, nur absenkbar)
-- Resultset:       Value datetime2(7) NULL; Status varchar(16) NOT NULL; ErrorCode varchar(32) NULL
-- Dependencies:    Keine Modul-, Tabellen- oder Helperabhängigkeit
-- Rechte:          SELECT auf der Funktion; keine Daten-/Servermutation
-- Versionen:       SQL Server 2019, 2022 und 2025; jeweilige native Abnahme separat
-- Plattformen:     Windows und Linux; native Abnahme separat
-- Fehlerverhalten: Genau eine Zeile; Statuspriorität NULL, Parameter, Limit, leer, Lexik,
--                  Bereich, Verlust, OK; kein Input-Echo und keine Enginefehlermeldung
-- Performance:     Relationaler Ausdruck; höchstens 4096 UTF-16-Codeeinheiten je Lexikscan
-- Einschränkungen: Keine Zeitzone; keine Offsetentfernung; keine Fractionkürzung.
-- ============================================================================
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE FUNCTION toolbelt_conversion.TVF_TryCastDateTime2
(
    @Text nvarchar(max),
    @MaxInputBytes int=8192
)
RETURNS TABLE
WITH SCHEMABINDING
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-toolbelt-toolbelt-conversion-tvf-trycastdatetime2"
-- description: "Prüft ISO-Datetime mit großem T und höchstens sieben Fractionziffern ohne Rundung oder Zeitzonenverlust."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.conversion.safe-cast"
-- schema_name: "toolbelt_conversion"
-- object_name: "TVF_TryCastDateTime2"
-- object_type: "TVF"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@Text", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Genau YYYY-MM-DDTHH:mm:ss, optional gefolgt von Punkt und 1..7 ASCII-Nachkommastellen (großes T, insgesamt 19 oder 21..27 Codeeinheiten). Kein Z, Offset, Leerzeichen, 24-Uhr-Zeit, Schaltsekunde oder Rundung; gültiger SQL-datetime2(7)-Bereich. NULL ergibt SQL_NULL, leerer Text EMPTY; sonst ungültige Lexik INVALID_FORMAT, kein stilles Trimmen."}, {"name": "@MaxInputBytes", "sql_type": "int", "sql_default": "8192", "is_output": false, "argument_required": true, "business_required": false, "nullable": false, "description": "Positives int-Bytebudget 1..8192 einschließlich (Default 8192), gemessen mit DATALENGTH des UTF-16-Texts, nicht in Zeichen; auch ungerade Budgets sind zulässig. NULL/0/negativ/>8192 ergibt INVALID_ARGUMENT/PARAMETER, außer Text=NULL hat Vorrang (SQL_NULL). Ein größerer Text ergibt LIMIT/INPUT_LIMIT."}]
-- source_paths: ["Modules/toolbelt.conversion.safe-cast/Source/TVF_TryCastDateTime2.sql"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- ---
--
-- # TVF_TryCastDateTime2
--
-- ## Zweck und Einsatzfälle
--
-- Prüft ISO-Datetime mit großem T und höchstens sieben Fractionziffern ohne Rundung oder Zeitzonenverlust. Geeignet zur expliziten Klassifikation von gebundenem Eingabetext; Fehlerzustände sind Daten und werden nicht mit einem gültigen NULL-Wert gleichgesetzt.
--
-- ## Voraussetzungen
--
-- SQL Server 2019/2022/2025, Windows/Linux, CL150/160/170; Safe-Cast-Modul installiert. Keine Modul-/Tabellen-/CLR-/Katalogabhängigkeit. Beide Funktionsargumentpositionen angeben, DEFAULT für das technische Budget 8192. Eingabe als Unicodeparameter nvarchar(max) binden, damit keine vorgelagerte varchar-Codepagekonversion den Originaltext verändert.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Vertrag |
-- |---|---|---|---|
-- | `@Text` | `nvarchar(max)` | `kein Default` | Genau YYYY-MM-DDTHH:mm:ss, optional gefolgt von Punkt und 1..7 ASCII-Nachkommastellen (großes T, insgesamt 19 oder 21..27 Codeeinheiten). Kein Z, Offset, Leerzeichen, 24-Uhr-Zeit, Schaltsekunde oder Rundung; gültiger SQL-datetime2(7)-Bereich. NULL ergibt SQL_NULL, leerer Text EMPTY; sonst ungültige Lexik INVALID_FORMAT, kein stilles Trimmen. |
-- | `@MaxInputBytes` | `int` | `8192` | Positives int-Bytebudget 1..8192 einschließlich (Default 8192), gemessen mit DATALENGTH des UTF-16-Texts, nicht in Zeichen; auch ungerade Budgets sind zulässig. NULL/0/negativ/>8192 ergibt INVALID_ARGUMENT/PARAMETER, außer Text=NULL hat Vorrang (SQL_NULL). Ein größerer Text ergibt LIMIT/INPUT_LIMIT. |
--
-- Konkrete Lexik: Exakt YYYY-MM-DDTHH:mm:ss mit großem ASCII-T, optional Punkt und ein bis sieben Fractionziffern. Länge 19 oder 21..27. Keine Zone, Offset, kleine t-Schreibweise oder Space als Trenner. Tatsächlicher Kalenderbereich und Stunde 0..23, Minute/Sekunde 0..59; kein 24:00:00 oder Schaltsekunden. Mehr als sieben Fractionziffern ist INVALID_FORMAT, auch bei zusätzlichen Nullen; kein stilles Runden.
--
-- ## Ergebnisse
--
-- Genau eine Zeile mit Value datetime2(7) NULL, Status varchar(16) NOT NULL und ErrorCode varchar(32) NULL. Nur OK liefert Value. Priorität: SQL_NULL bei Text=NULL (auch vor ungültigem Budget), INVALID_ARGUMENT/PARAMETER bei Budget=NULL oder außerhalb 1..8192, LIMIT/INPUT_LIMIT bei DATALENGTH(Text)>Budget, EMPTY/EMPTY bei leerem Text, INVALID_FORMAT/FORMAT bei Lexikfehler, OUT_OF_RANGE/RANGE falls der geprüfte Wert nicht konvertierbar/im Zielbereich ist, sonst OK mit ErrorCode=NULL. SQL_NULL hat ebenfalls ErrorCode=NULL. Nicht alle Zweige des gemeinsamen Statusschemas müssen für jeden Zieltyp erreichbar sein; LOSSY wird nur vom Decimal-Kern erzeugt.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- SELECT Value,Status,ErrorCode
-- FROM toolbelt_conversion.TVF_TryCastDateTime2(N'2026-11-20T12:34:56.1234567',DEFAULT);
-- -- 2026-11-20 12:34:56.1234567, OK, NULL
-- SELECT Value,Status,ErrorCode
-- FROM toolbelt_conversion.TVF_TryCastDateTime2(NULL,0);
-- -- NULL, SQL_NULL, NULL (Text-NULL hat Vorrang).
-- ```
--
-- ## Rechte
--
-- Vorhandenes SELECT auf der TVF für SELECT-Aufrufe; entsprechende REFERENCES-Rechte bei Referenzverwendung. Keine Rechtevergabe oder Ausführungsidentitätsänderung. Cross-Database-Identitätszuordnung bleibt Caller-Voraussetzung.
--
-- ## Ressourcenbedarf
--
-- Fester Positionsraum von höchstens 4096 UTF-16-Codeeinheiten, binäre non-SC-Lexik und zulässige TRY_CONVERT-Typpaare. Originale DATALENGTH inklusive trailing spaces bestimmt das Budget. Der Lexikscan kann auch bei kleinerem Callerbudget bis zur festen Obergrenze vorbereitet werden; Statuspriorität ist keine Zusage einer physischen Auswertungsreihenfolge. LOB-Übertragung und Bereitstellung des Originalparameters sind dadurch nicht unbegrenzt ressourcensicher. Keine Laufzeit-/Plan-/Parallelitätsgarantie.
--
-- ## Nebenwirkungen
--
-- Rein lesend; keine Tabellen-, Datei-, Netzwerk-, Trust-, Konfigurations- oder Transaktionsänderung. Kein Input-Echo, keine Fehlerdetails mit Originalwerten und kein automatischer Folgeaufruf.
--
-- ## Fehlerbehandlung
--
-- Fachliche Argument-/Format-/Bereichs- und gegebenenfalls Skalenfehler werden als obige Status-/ErrorCode-Kombination gemeldet; keine fachliche THROW-Anweisung. Nicht vorgesehene Enginefehler und Fehler vor der Funktionsbindung bleiben reguläre Fehler. Keine automatische Trimmung, Korrektur oder Wiederholung.
--
-- ## Aussagegrenzen
--
-- Exakt YYYY-MM-DDTHH:mm:ss mit großem ASCII-T, optional Punkt und ein bis sieben Fractionziffern. Länge 19 oder 21..27. Keine Zone, Offset, kleine t-Schreibweise oder Space als Trenner. Tatsächlicher Kalenderbereich und Stunde 0..23, Minute/Sekunde 0..59; kein 24:00:00 oder Schaltsekunden. Mehr als sieben Fractionziffern ist INVALID_FORMAT, auch bei zusätzlichen Nullen; kein stilles Runden. ASCII-Prüfung erfolgt über UTF-16-Codeeinheiten, sodass NUL, Surrogate und Unicode-Ziffern keine ASCII-Ersatzzeichen sind. Das Bytebudget ist nicht eine Zeichenzahl; ungerade positive Budgets sind zulässig. Die native Qualifikation bleibt an ihre ursprünglichen Artefakte gebunden; quellgeprüfte Skilltexte sind kein neuer Runtime-Nachweis.
-- OBJECT_USAGE_SKILL:END
AS
RETURN
(
    WITH
    Digit AS
    (
        SELECT n FROM (VALUES(0),(1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12),(13),(14),(15)) d(n)
    ),
    Position AS
    (
        SELECT 1+a.n+16*b.n+256*c.n AS n
        FROM Digit a CROSS JOIN Digit b CROSS JOIN Digit c
    ),
    Input AS
    (
        -- DATALENGTH erhält trailing spaces; alle späteren Slices bleiben auf 4096 Einheiten begrenzt.
        SELECT DATALENGTH(@Text) AS InputBytes,
               LEFT(@Text COLLATE Latin1_General_100_BIN2,4096) AS ScanText
    ),
    Bounded AS
    (
        SELECT InputBytes,ScanText,CONVERT(int,ISNULL(DATALENGTH(ScanText)/2,0)) AS ScanLength
        FROM Input
    ),
    CodeUnit AS
    (
        -- Non-SC-BIN2 plus UNICODE prüft ASCII exakt, einschließlich NUL und einzelner Surrogate.
        SELECT p.n,ISNULL(UNICODE(SUBSTRING(b.ScanText,p.n,1)),-1) AS Code
        FROM Position p CROSS JOIN Bounded b WHERE p.n<=b.ScanLength
    ),
    Lexical AS
    (
        SELECT ISNULL(MAX(CASE WHEN (n IN(5,8) AND Code<>45) OR (n=11 AND Code<>84)
              OR (n IN(14,17) AND Code<>58) OR (n=20 AND Code<>46)
              OR (n NOT IN(5,8,11,14,17,20) AND (Code<48 OR Code>57)) THEN 1 ELSE 0 END),0) AS BadCode
        FROM CodeUnit
    ),
    Validated AS
    (
        SELECT b.InputBytes,b.ScanText,b.ScanLength,CASE WHEN (ScanLength=19 OR ScanLength BETWEEN 21 AND 27) AND l.BadCode=0 THEN 1 ELSE 0 END AS LexicalValid
        FROM Bounded b CROSS JOIN Lexical l
    ),
    Converted AS
    (
        -- Nur erlaubte TRY_CONVERT-Typpaare; auch vorgezogene Auswertung ist kein THROW-Pfad.
        SELECT v.InputBytes,v.ScanText,v.ScanLength,v.LexicalValid,TRY_CONVERT(datetime2(7),LEFT(ScanText,27),126) AS ConvertedValue FROM Validated v
    ),
    Verdict AS
    (
        SELECT c.InputBytes,c.ScanText,c.ScanLength,c.LexicalValid,c.ConvertedValue,ISNULL(CONVERT(varchar(16),CASE
            WHEN @Text IS NULL THEN 'SQL_NULL'
            WHEN @MaxInputBytes IS NULL OR @MaxInputBytes<1 OR @MaxInputBytes>8192 THEN 'INVALID_ARGUMENT'
            WHEN InputBytes>@MaxInputBytes THEN 'LIMIT'
            WHEN InputBytes=0 THEN 'EMPTY'
            WHEN LexicalValid=0 THEN 'INVALID_FORMAT'
            WHEN ConvertedValue IS NULL OR TRY_CONVERT(int,SUBSTRING(ScanText,12,2))>23
                OR TRY_CONVERT(int,SUBSTRING(ScanText,15,2))>59 OR TRY_CONVERT(int,SUBSTRING(ScanText,18,2))>59 THEN 'OUT_OF_RANGE'
            ELSE 'OK' END),'INVALID_FORMAT') AS ResultStatus
        FROM Converted c
    )
    SELECT CASE WHEN ResultStatus='OK' THEN ConvertedValue ELSE CONVERT(datetime2(7),NULL) END AS [Value],
           ISNULL(CONVERT(varchar(16),ResultStatus),'INVALID_FORMAT') COLLATE Latin1_General_100_BIN2 AS [Status],
           CONVERT(varchar(32),CASE ResultStatus
             WHEN 'INVALID_ARGUMENT' THEN 'PARAMETER'
             WHEN 'LIMIT' THEN 'INPUT_LIMIT'
             WHEN 'EMPTY' THEN 'EMPTY'
             WHEN 'INVALID_FORMAT' THEN 'FORMAT'
             WHEN 'OUT_OF_RANGE' THEN 'RANGE'
             WHEN 'LOSSY' THEN 'SCALE'
             ELSE NULL END) COLLATE Latin1_General_100_BIN2 AS ErrorCode
    FROM Verdict
);
GO
