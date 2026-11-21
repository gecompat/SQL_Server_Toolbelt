-- ============================================================================
-- Objekt:          toolbelt_json.TVF_JsonPathExistsStatus
-- Zweck:           Begrenzter kanonischer Statuskern; Legacy-Wertfassade unten.
-- Parameter:       @Json nvarchar(max), @Path nvarchar(max)
-- Resultset:       PathExists int, Status varchar(16)
-- Vertrag:         Documentation/TVF_JsonPathExistsStatus.md
-- Versionen:       SQL Server 2019/2022/2025; Windows/Linux
-- Rechte:          SELECT/REFERENCES; keine zusätzlichen Rechte oder Grants.
-- Performance:     MSTVF mit Vorabgrenzen; keine Inline-/Parallelitätszusage.
-- Grenzen:         Freigegebener Vertrag SECURITY_HARDENING_2026_10.md.
-- ============================================================================
CREATE OR ALTER FUNCTION [toolbelt_json].[TVF_JsonPathExistsStatus]
(
      @Json nvarchar(max)
    , @Path nvarchar(max)
)
RETURNS @Result TABLE
(
    PathExists int NULL, Status varchar(16) NOT NULL
)
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-toolbelt-toolbelt-json-tvf-jsonpathexistsstatus"
-- description: "Genau eine Zeile: FOUND/1, MISSING/0, INVALID/0, SQL_NULL/NULL oder LIMIT/NULL. Höchstens 10000 Frontierwerte; maximal 10001 werden zur Überschreitungsfeststellung aufgenommen. Vor jedem OPENJSON werden die vorgesehenen Inputbytes gegen das kumulative 64-MiB-Budget gebucht. Containerroots werden ohne zusätzliche Wrapper-Ebene validiert. Die bisherige TVF liefert bei LIMIT NULL; kein falsches MISSING."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.json.path-exists"
-- schema_name: "toolbelt_json"
-- object_name: "TVF_JsonPathExistsStatus"
-- object_type: "TVF"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@Json", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Vollständiger JSON-Wert einschließlich Skalar/root-null, maximal 16777216 UTF-16-Bytes und lexikalische Containertiefe 128. Leer ist ungültiges JSON. NULL in Json oder Path liefert SQL_NULL/NULL vor weiterer Prüfung. Syntaxfehler ergeben INVALID/0; Ressourcenüberschreitungen LIMIT/NULL im Statuskern beziehungsweise NULL in der Wertfassade. Frontier höchstens 10000 Werte, kumulatives Parserworkbudget 67108864 Bytes."}, {"name": "@Path", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "SQL/JSON-Teilmenge, maximal 4000 UTF-16-Einheiten/128 Segmente: $ für Root, .ASCII_key mit Buchstaben/Ziffern/_, .\"JSON-escaped key\" für beliebige Keys, [0].. mit nullbasiertem ASCII-Dezimalindex ohne führende Nullen, [*] für beliebiges Arrayelement. Keine Objektwildcards, Filter, Ranges, Indexlisten oder last. Optionale Präfixe lax / strict werden case-insensitiv erkannt und ändern den Existenzvertrag nicht; äußere normale Spaces werden entfernt. Keys bleiben binär/case-sensitiv. Leer/fehlerhaft ergibt INVALID/0; NULL ergibt SQL_NULL/NULL. Objektschlüssel verlangen BIN2-Gleichheit UND identische UTF16-Bytelänge; a und a<Space> sowie leer und Space sind verschieden. Steuer-/Wildcardvergleiche behalten die vorhandene SQL-Paddingsemantik; dies ist keine vollständige native SQL/JSON-Pfadgrammatik."}]
-- source_paths: ["Modules/toolbelt.json.path-exists/Source/TVF_JsonPathExists.sql"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- ---
--
-- # TVF_JsonPathExistsStatus
--
-- ## Zweck und Einsatzfälle
--
-- Genau eine Zeile: FOUND/1, MISSING/0, INVALID/0, SQL_NULL/NULL oder LIMIT/NULL. Höchstens 10000 Frontierwerte; maximal 10001 werden zur Überschreitungsfeststellung aufgenommen. Vor jedem OPENJSON werden die vorgesehenen Inputbytes gegen das kumulative 64-MiB-Budget gebucht. Containerroots werden ohne zusätzliche Wrapper-Ebene validiert. Die bisherige TVF liefert bei LIMIT NULL; kein falsches MISSING.
--
-- ## Voraussetzungen
--
-- JSONpath-Modul mit nativer ISJSON/OPENJSON-Unterstützung in derselben DB. Windows/Linux SQL2019/2022/2025, CL150/160/170 im zulässigen Hostprofil. Kein Quellkatalog-, Datei-, Netzwerk-, CLR- oder Trustzugriff.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
-- |---|---|---|---|---|
-- | `@Json` | `nvarchar(max)` | kein Default | Input | Vollständiger JSON-Wert einschließlich Skalar/root-null, maximal 16777216 UTF-16-Bytes und lexikalische Containertiefe 128. Leer ist ungültiges JSON. NULL in Json oder Path liefert SQL_NULL/NULL vor weiterer Prüfung. Syntaxfehler ergeben INVALID/0; Ressourcenüberschreitungen LIMIT/NULL im Statuskern beziehungsweise NULL in der Wertfassade. Frontier höchstens 10000 Werte, kumulatives Parserworkbudget 67108864 Bytes. |
-- | `@Path` | `nvarchar(max)` | kein Default | Input | SQL/JSON-Teilmenge, maximal 4000 UTF-16-Einheiten/128 Segmente: $ für Root, .ASCII_key mit Buchstaben/Ziffern/_, ."JSON-escaped key" für beliebige Keys, [0].. mit nullbasiertem ASCII-Dezimalindex ohne führende Nullen, [*] für beliebiges Arrayelement. Keine Objektwildcards, Filter, Ranges, Indexlisten oder last. Optionale Präfixe lax / strict werden case-insensitiv erkannt und ändern den Existenzvertrag nicht; äußere normale Spaces werden entfernt. Keys bleiben binär/case-sensitiv. Leer/fehlerhaft ergibt INVALID/0; NULL ergibt SQL_NULL/NULL. Objektschlüssel verlangen BIN2-Gleichheit UND identische UTF16-Bytelänge; a und a<Space> sowie leer und Space sind verschieden. Steuer-/Wildcardvergleiche behalten die vorhandene SQL-Paddingsemantik; dies ist keine vollständige native SQL/JSON-Pfadgrammatik. |
--
-- Alle Positionen beim SELECT-Aufruf angeben; DEFAULT verwendet einen deklarierten Funktionsdefault, NULL bleibt ein eigener Wert. SQL-Typbindung und eine mögliche Kürzung auf feste Parameterbreite liegen vor dem Funktionskörper.
--
-- ## Ergebnisse
--
-- Genau eine Statuszeile mit PathExists int NULL und Status varchar(16) NOT NULL:FOUND/1,MISSING/0,INVALID/0,SQL_NULL/NULL,LIMIT/NULL.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- SELECT * FROM toolbelt_json.TVF_JsonPathExistsStatus(N'{"items":[{"name":null}]}',N'$.items[*].name');
-- SELECT * FROM toolbelt_json.TVF_JsonPathExistsStatus(N'{"a ":1}',N'$."a"');
-- ```
--
-- ## Rechte
--
-- Vorhandenes SELECT/REFERENCES auf gewählten TVFs und erforderliche normale Ownershipchain. OPENJSON auf übergebenen Werten braucht keine Source-Datenrechte oder Metadatenvollsicht. Keine Rechteerteilung.
--
-- ## Ressourcenbedarf
--
-- Json maximal16777216UTF16Bytes; rohe Containertiefe128 vor nativer JSON-Prüfung; Path maximal8000UTF16Bytes,128Segmente. Frontier maximal10000Werte,10001Kandidaten zur Überschreitungserkennung. Kumulatives Parserworkbudget67108864Bytes zählt Envelope-/Frontierparseranteile vor den jeweiligen Aufrufen, keine Messung der gesamten CLR-/Engine-/LOB-/Tempdb-Allokation. Quoted-Path-/Root-Envelopes und Frontierkopien zusätzlicher Aufwand. Keine harte Deadline/Peakheap-/Produktionskapazitätszusage.
--
-- ## Nebenwirkungen
--
-- NULL in Json oder Path liefert zuerst SQL_NULL. Json-Inputbytes begrenzen; rohes JSON chunkweise mit Quoting/Escapes auf Containertiefe prüfen, bevor native ISJSON-Prüfung erfolgt. Danach Pathbytegrenze, äußere normale Spaces entfernen und optionales lax/strict-Präfix case-insensitiv abnehmen. Endlicher Parser für Root$, ASCII-Dotkeys, JSON-quotierte Dotkeys, einzelne Dezimalindizes und Arraywildcard. Quotedkeys durch geschütztes OPENJSON eines Stringarrays entescapen. Steuer-/Wildcardvergleiche bleiben SQL-Vergleiche einschließlich Padding, keine vollständige native Pfadgrammatik. Maximal128Segmente; ungültiger Pfad INVALID.
--
-- Container per ISJSON prüfen; skalare Rootwerte einschließlich JSONnull in ein geschütztes Einzelelementarray einhüllen. Eine Rootfrontierzeile verlangen. Jede Pfadstufe expandiert mit OPENJSON nur Objekt/Arraywerte, nie einen SQL-Ausdruck. Propertymatch verlangt Objektparent sowie binären Schlüsselvergleich und identische DATALENGTH, Indexmatch Arrayparent sowie denselben exakten Keyvergleich; Wildcard nur Array. JSONnull zählt als vorhandener Wert. Vor jeder Parserstufe kumulierten Workcharge prüfen; NextFrontier auf10001Kandidaten begrenzen und >10000 alsLIMIT verwerfen. Nach leerer Frontier stoppen. Mehrere Treffer/Duplikatschlüssel bleiben Existenz, keine geordnete Trefferliste. Wrapper übernimmt ausschließlich PathExists. Keine fachliche Tabelle, eigene Transaktion, Mutation oder dynamische SQL-Ausführung.
--
-- ## Fehlerbehandlung
--
-- SQL_NULL vor Quoten; Jsonbyte-/rohe Tiefen-/Segment-/Frontier-/Workquote ->LIMIT/NULL. Überlanger Pfad ->INVALID/0, ebenso erkannte ungültige Pfad-/JSONformen. Falsche Struktur oder fehlender Key/Index ->MISSING/0, nicht INVALID. Unerwartete Typbindungs-, OPENJSON-/Engine-/Ressourcenfehler bleiben Originalfehler; kein allgemeines TRY-CATCH in der UDF.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter aktueller Vertrag. Die ausdrücklich deklarierten funktionalen Korrekturen in diesem Modul benötigen neue native Gegenproben; historische Nachweise qualifizieren nur ihre ursprünglichen Bytes. Noch kein aktuelles natives API-/SC-/UTF8-/Caller-/Gesamtinstaller-PASS. Keine Installations-/Rechteattestation. Nur synthetische Beispiele; reale Eingaben/Runtimeausgaben privat halten.
-- OBJECT_USAGE_SKILL:END
AS
BEGIN
    IF @Json IS NULL OR @Path IS NULL
    BEGIN
        INSERT @Result (PathExists,Status) VALUES (NULL,'SQL_NULL');
        RETURN;
    END;

    IF DATALENGTH(@Json)>16777216
    BEGIN INSERT @Result VALUES(NULL,'LIMIT'); RETURN; END;
    DECLARE @WorkBytes bigint=0,@Charge bigint,@RawPosition int=1,
        @RawLength int=CONVERT(int,DATALENGTH(@Json)/2),@RawDepth int=0,
        @RawQuoted bit=0,@RawEscaped bit=0,@RawUnit nchar(1),@RootUnit nchar(1),
        @RawChunk nvarchar(4000),@RawChunkStart int=-4000;
    -- Vor nativer JSON-Prüfung lexikalische Tiefe samt Quoting/Escapes begrenzen.
    -- Chunkweises SUBSTRING vermeidet wiederholtes vollständiges LOB-Scanning.
    WHILE @RawPosition<=@RawLength
    BEGIN
        IF @RawPosition>@RawChunkStart+4000
        BEGIN SET @RawChunkStart=@RawPosition-1; SET @RawChunk=SUBSTRING(@Json COLLATE Latin1_General_100_BIN2,@RawPosition,4000); END;
        SET @RawUnit=SUBSTRING(@RawChunk COLLATE Latin1_General_100_BIN2,@RawPosition-@RawChunkStart,1);
        IF @RootUnit IS NULL AND UNICODE(@RawUnit) NOT IN(9,10,13,32) SET @RootUnit=@RawUnit;
        IF @RawQuoted=1
        BEGIN
            IF @RawEscaped=1 SET @RawEscaped=0;
            ELSE IF @RawUnit COLLATE Latin1_General_100_BIN2=N'\' SET @RawEscaped=1;
            ELSE IF @RawUnit COLLATE Latin1_General_100_BIN2=N'"' SET @RawQuoted=0;
        END
        ELSE IF @RawUnit COLLATE Latin1_General_100_BIN2=N'"' SET @RawQuoted=1;
        ELSE IF @RawUnit COLLATE Latin1_General_100_BIN2 IN(N'[',N'{')
        BEGIN
            SET @RawDepth+=1;
            IF @RawDepth>128 BEGIN INSERT @Result VALUES(NULL,'LIMIT'); RETURN; END;
        END
        ELSE IF @RawUnit COLLATE Latin1_General_100_BIN2 IN(N']',N'}') SET @RawDepth-=1;
        SET @RawPosition+=1;
    END;
    -- Der V1-Vertrag begrenzt den Pfad bewusst. Dadurch bleiben alle
    -- Parserpositionen int-basiert und der pro Aufruf materialisierte Zustand
    -- kontrollierbar.
    IF DATALENGTH(@Path) > 8000
    BEGIN
        INSERT @Result (PathExists,Status) VALUES (0,'INVALID');
        RETURN;
    END;

    DECLARE
          @PathText nvarchar(max) = LTRIM(RTRIM(@Path))
        , @PathLength int
        , @Position int = 1
        , @Start int
        , @Scan int
        , @Escaped bit
        , @Invalid bit = 0
        , @Token nvarchar(max)
        , @Literal nvarchar(max)
        , @Envelope nvarchar(max)
        , @SegmentType char(1)
        , @SegmentOrdinal int = 1
        , @SegmentCount int;

    -- lax und strict werden angenommen, beeinflussen den fehlerfreien
    -- Existenzvertrag aber nicht. JSON_PATH_EXISTS wirft selbst in strict
    -- mode keinen Fehler.
    IF LEFT(@PathText, 4) COLLATE Latin1_General_100_CI_AS = N'lax '
        SET @PathText = LTRIM(SUBSTRING(@PathText, 5, 4000));
    ELSE IF LEFT(@PathText, 7) COLLATE Latin1_General_100_CI_AS = N'strict '
        SET @PathText = LTRIM(SUBSTRING(@PathText, 8, 4000));

    SET @PathLength = CONVERT(int, LEN(@PathText));

    IF @PathLength = 0 OR SUBSTRING(@PathText, 1, 1) <> N'$'
        SET @Invalid = 1;
    ELSE
        SET @Position = 2;

    DECLARE @Segments TABLE
    (
          Ordinal int NOT NULL PRIMARY KEY
        , SegmentType char(1) NOT NULL
        , SegmentValue nvarchar(max) NULL
    );

    WHILE @Invalid = 0 AND @Position <= @PathLength
    BEGIN
        IF @SegmentOrdinal>128 BEGIN INSERT @Result VALUES(NULL,'LIMIT'); RETURN; END;
        IF SUBSTRING(@PathText, @Position, 1) = N'.'
        BEGIN
            SET @Position += 1;

            IF @Position > @PathLength
            BEGIN
                SET @Invalid = 1;
                BREAK;
            END;

            IF SUBSTRING(@PathText, @Position, 1) = N'"'
            BEGIN
                SET @Start = @Position;
                SET @Scan = @Position + 1;
                SET @Escaped = 0;

                WHILE @Scan <= @PathLength
                BEGIN
                    IF @Escaped = 1
                        SET @Escaped = 0;
                    ELSE IF SUBSTRING(@PathText, @Scan, 1) = N'\'
                        SET @Escaped = 1;
                    ELSE IF SUBSTRING(@PathText, @Scan, 1) = N'"'
                        BREAK;

                    SET @Scan += 1;
                END;

                IF @Scan > @PathLength
                BEGIN
                    SET @Invalid = 1;
                    BREAK;
                END;

                SET @Literal =
                    SUBSTRING(@PathText, @Start, @Scan - @Start + 1);
                SET @Envelope = N'[' + @Literal + N']';

                -- ISJSON schützt OPENJSON vor einem Providerfehler und prüft
                -- zugleich Escapes einschließlich \uXXXX.
                IF ISJSON(@Envelope) <> 1
                BEGIN
                    SET @Invalid = 1;
                    BREAK;
                END;

                SET @Charge=DATALENGTH(@Envelope);
                IF @Charge>67108864-@WorkBytes BEGIN INSERT @Result VALUES(NULL,'LIMIT'); RETURN; END;
                SET @WorkBytes+=@Charge;
                SELECT @Token = json_value.[value]
                FROM OPENJSON(@Envelope) AS json_value
                WHERE json_value.[key] = N'0'
                  AND json_value.[type] = 1;

                IF @Token IS NULL
                BEGIN
                    SET @Invalid = 1;
                    BREAK;
                END;

                INSERT @Segments (Ordinal, SegmentType, SegmentValue)
                VALUES (@SegmentOrdinal, 'P', @Token);

                SET @SegmentOrdinal += 1;
                SET @Position = @Scan + 1;
            END;
            ELSE
            BEGIN
                SET @Start = @Position;

                WHILE @Position <= @PathLength
                  AND SUBSTRING(@PathText, @Position, 1) NOT IN (N'.', N'[')
                    SET @Position += 1;

                SET @Token =
                    SUBSTRING(@PathText, @Start, @Position - @Start);

                -- Nicht quotierte V1-Schlüssel folgen der dokumentierten
                -- alphanumerischen SQL/JSON-Kurzform; weitere Zeichen und
                -- Unicode-Schlüssel werden in doppelten Anführungszeichen
                -- geschrieben.
                IF @Token = N''
                   OR PATINDEX
                      (
                          N'%[^0-9A-Za-z_]%',
                          @Token COLLATE Latin1_General_100_BIN2
                      ) > 0
                BEGIN
                    SET @Invalid = 1;
                    BREAK;
                END;

                INSERT @Segments (Ordinal, SegmentType, SegmentValue)
                VALUES (@SegmentOrdinal, 'P', @Token);

                SET @SegmentOrdinal += 1;
            END;
        END;
        ELSE IF SUBSTRING(@PathText, @Position, 1) = N'['
        BEGIN
            SET @Start = @Position + 1;
            SET @Scan = CHARINDEX(N']', @PathText, @Start);

            IF @Scan = 0
            BEGIN
                SET @Invalid = 1;
                BREAK;
            END;

            SET @Token = SUBSTRING(@PathText, @Start, @Scan - @Start);

            IF @Token = N'*'
                SET @SegmentType = 'W';
            ELSE IF @Token <> N''
                 AND PATINDEX
                     (
                         N'%[^0-9]%',
                         @Token COLLATE Latin1_General_100_BIN2
                     ) = 0
                 AND
                     (
                         @Token = N'0'
                         OR LEFT(@Token, 1) <> N'0'
                     )
                SET @SegmentType = 'I';
            ELSE
            BEGIN
                SET @Invalid = 1;
                BREAK;
            END;

            INSERT @Segments (Ordinal, SegmentType, SegmentValue)
            VALUES
            (
                  @SegmentOrdinal
                , @SegmentType
                , CASE WHEN @SegmentType = 'I' THEN @Token END
            );

            SET @SegmentOrdinal += 1;
            SET @Position = @Scan + 1;
        END;
        ELSE
        BEGIN
            SET @Invalid = 1;
            BREAK;
        END;
    END;

    IF @Invalid = 1
    BEGIN
        INSERT @Result (PathExists,Status) VALUES (0,'INVALID');
        RETURN;
    END;

    IF @RootUnit IN(N'[',N'{')
    BEGIN
        IF ISJSON(@Json)<>1 BEGIN INSERT @Result VALUES(0,'INVALID'); RETURN; END;
    END
    ELSE
    BEGIN
        SET @Envelope=CAST(N'[' AS nvarchar(max))+@Json+N']';
        IF ISJSON(@Envelope)<>1 BEGIN INSERT @Result VALUES(0,'INVALID'); RETURN; END;
    END;

    DECLARE @Frontier TABLE
    (
          JsonValue nvarchar(max) NULL
        , JsonType int NOT NULL
    );
    DECLARE @NextFrontier TABLE
    (
          JsonValue nvarchar(max) NULL
        , JsonType int NOT NULL
    );

    IF @RootUnit IN(N'[',N'{')
        INSERT @Frontier VALUES(@Json,CASE @RootUnit WHEN N'[' THEN 4 ELSE 5 END);
    ELSE
    BEGIN
        SET @Charge=DATALENGTH(@Envelope);
        IF @Charge>67108864-@WorkBytes BEGIN INSERT @Result VALUES(NULL,'LIMIT'); RETURN; END;
        SET @WorkBytes+=@Charge;
        INSERT @Frontier (JsonValue,JsonType)
        SELECT [value],[type] FROM OPENJSON(@Envelope);
    END;

    IF (SELECT COUNT_BIG(*) FROM @Frontier) <> 1
    BEGIN
        INSERT @Result (PathExists,Status) VALUES (0,'INVALID');
        RETURN;
    END;

    SET @SegmentCount = @SegmentOrdinal - 1;
    SET @SegmentOrdinal = 1;

    WHILE @SegmentOrdinal <= @SegmentCount
    BEGIN
        SELECT
              @SegmentType = segment.SegmentType
            , @Token = segment.SegmentValue
        FROM @Segments AS segment
        WHERE segment.Ordinal = @SegmentOrdinal;

        DELETE @NextFrontier;

        SELECT @Charge=COALESCE(SUM(CONVERT(bigint,CASE WHEN JsonType IN(4,5) THEN DATALENGTH(JsonValue) ELSE 4 END)),0) FROM @Frontier;
        IF @Charge>67108864-@WorkBytes BEGIN INSERT @Result VALUES(NULL,'LIMIT'); RETURN; END;
        SET @WorkBytes+=@Charge;
        INSERT @NextFrontier (JsonValue, JsonType)
        SELECT TOP (10001) child.[value], child.[type]
        FROM @Frontier AS parent
        CROSS APPLY OPENJSON
        (
            CASE
                WHEN parent.JsonType IN (4, 5) THEN parent.JsonValue
                ELSE N'{}'
            END
        ) AS child
        WHERE
            (
                @SegmentType = 'P'
                AND parent.JsonType = 5
                AND child.[key] COLLATE Latin1_General_100_BIN2 =
                    @Token COLLATE Latin1_General_100_BIN2
                AND DATALENGTH(child.[key])=DATALENGTH(@Token)
            )
            OR
            (
                @SegmentType = 'I'
                AND parent.JsonType = 4
                AND child.[key] COLLATE Latin1_General_100_BIN2 =
                    @Token COLLATE Latin1_General_100_BIN2
                AND DATALENGTH(child.[key])=DATALENGTH(@Token)
            )
            OR
            (
                @SegmentType = 'W'
                AND parent.JsonType = 4
            );

        IF (SELECT COUNT_BIG(*) FROM @NextFrontier)>10000
        BEGIN INSERT @Result VALUES(NULL,'LIMIT'); RETURN; END;
        DELETE @Frontier;

        INSERT @Frontier (JsonValue, JsonType)
        SELECT next_value.JsonValue, next_value.JsonType
        FROM @NextFrontier AS next_value;

        IF NOT EXISTS (SELECT 1 FROM @Frontier)
            BREAK;

        SET @SegmentOrdinal += 1;
    END;

    INSERT @Result (PathExists,Status)
    SELECT CASE WHEN EXISTS (SELECT 1 FROM @Frontier) THEN 1 ELSE 0 END,
           CASE WHEN EXISTS (SELECT 1 FROM @Frontier) THEN 'FOUND' ELSE 'MISSING' END;

    RETURN;
END;
GO

-- Legacy-Wertfassade: gleicher Inputvertrag; Limitabbildung siehe Objektseite.
-- Vertrag: Documentation/TVF_JsonPathExists.md
CREATE OR ALTER FUNCTION [toolbelt_json].[TVF_JsonPathExists](@Json nvarchar(max),@Path nvarchar(max))
RETURNS @Result TABLE(PathExists int NULL)
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-toolbelt-toolbelt-json-tvf-jsonpathexists"
-- description: "Prüft, ob ein unterstützter Pfad in einem JSON-Dokument existiert."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.json.path-exists"
-- schema_name: "toolbelt_json"
-- object_name: "TVF_JsonPathExists"
-- object_type: "TVF"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@Json", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Vollständiger JSON-Wert einschließlich Skalar/root-null, maximal 16777216 UTF-16-Bytes und lexikalische Containertiefe 128. Leer ist ungültiges JSON. NULL in Json oder Path liefert SQL_NULL/NULL vor weiterer Prüfung. Syntaxfehler ergeben INVALID/0; Ressourcenüberschreitungen LIMIT/NULL im Statuskern beziehungsweise NULL in der Wertfassade. Frontier höchstens 10000 Werte, kumulatives Parserworkbudget 67108864 Bytes."}, {"name": "@Path", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "SQL/JSON-Teilmenge, maximal 4000 UTF-16-Einheiten/128 Segmente: $ für Root, .ASCII_key mit Buchstaben/Ziffern/_, .\"JSON-escaped key\" für beliebige Keys, [0].. mit nullbasiertem ASCII-Dezimalindex ohne führende Nullen, [*] für beliebiges Arrayelement. Keine Objektwildcards, Filter, Ranges, Indexlisten oder last. Optionale Präfixe lax / strict werden case-insensitiv erkannt und ändern den Existenzvertrag nicht; äußere normale Spaces werden entfernt. Keys bleiben binär/case-sensitiv. Leer/fehlerhaft ergibt INVALID/0; NULL ergibt SQL_NULL/NULL. Objektschlüssel verlangen BIN2-Gleichheit UND identische UTF16-Bytelänge; a und a<Space> sowie leer und Space sind verschieden. Steuer-/Wildcardvergleiche behalten die vorhandene SQL-Paddingsemantik; dies ist keine vollständige native SQL/JSON-Pfadgrammatik."}]
-- source_paths: ["Modules/toolbelt.json.path-exists/Source/TVF_JsonPathExists.sql"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- ---
--
-- # TVF_JsonPathExists
--
-- ## Zweck und Einsatzfälle
--
-- Prüft, ob ein unterstützter Pfad in einem JSON-Dokument existiert.
--
-- ## Voraussetzungen
--
-- JSONpath-Modul mit nativer ISJSON/OPENJSON-Unterstützung in derselben DB. Windows/Linux SQL2019/2022/2025, CL150/160/170 im zulässigen Hostprofil. Kein Quellkatalog-, Datei-, Netzwerk-, CLR- oder Trustzugriff.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
-- |---|---|---|---|---|
-- | `@Json` | `nvarchar(max)` | kein Default | Input | Vollständiger JSON-Wert einschließlich Skalar/root-null, maximal 16777216 UTF-16-Bytes und lexikalische Containertiefe 128. Leer ist ungültiges JSON. NULL in Json oder Path liefert SQL_NULL/NULL vor weiterer Prüfung. Syntaxfehler ergeben INVALID/0; Ressourcenüberschreitungen LIMIT/NULL im Statuskern beziehungsweise NULL in der Wertfassade. Frontier höchstens 10000 Werte, kumulatives Parserworkbudget 67108864 Bytes. |
-- | `@Path` | `nvarchar(max)` | kein Default | Input | SQL/JSON-Teilmenge, maximal 4000 UTF-16-Einheiten/128 Segmente: $ für Root, .ASCII_key mit Buchstaben/Ziffern/_, ."JSON-escaped key" für beliebige Keys, [0].. mit nullbasiertem ASCII-Dezimalindex ohne führende Nullen, [*] für beliebiges Arrayelement. Keine Objektwildcards, Filter, Ranges, Indexlisten oder last. Optionale Präfixe lax / strict werden case-insensitiv erkannt und ändern den Existenzvertrag nicht; äußere normale Spaces werden entfernt. Keys bleiben binär/case-sensitiv. Leer/fehlerhaft ergibt INVALID/0; NULL ergibt SQL_NULL/NULL. Objektschlüssel verlangen BIN2-Gleichheit UND identische UTF16-Bytelänge; a und a<Space> sowie leer und Space sind verschieden. Steuer-/Wildcardvergleiche behalten die vorhandene SQL-Paddingsemantik; dies ist keine vollständige native SQL/JSON-Pfadgrammatik. |
--
-- Alle Positionen beim SELECT-Aufruf angeben; DEFAULT verwendet einen deklarierten Funktionsdefault, NULL bleibt ein eigener Wert. SQL-Typbindung und eine mögliche Kürzung auf feste Parameterbreite liegen vor dem Funktionskörper.
--
-- ## Ergebnisse
--
-- Genau eine Zeile mit PathExists int NULL. FOUND ->1,MISSING/INVALID ->0,SQL_NULL/LIMIT ->NULL. Für die Unterscheidung Status-TVF verwenden; keine zusätzliche Statusspalte.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- SELECT * FROM toolbelt_json.TVF_JsonPathExistsStatus(N'{"items":[{"name":null}]}',N'$.items[*].name');
-- SELECT * FROM toolbelt_json.TVF_JsonPathExistsStatus(N'{"a ":1}',N'$."a"');
-- ```
--
-- ## Rechte
--
-- Vorhandenes SELECT/REFERENCES auf gewählten TVFs und erforderliche normale Ownershipchain. OPENJSON auf übergebenen Werten braucht keine Source-Datenrechte oder Metadatenvollsicht. Keine Rechteerteilung.
--
-- ## Ressourcenbedarf
--
-- Json maximal16777216UTF16Bytes; rohe Containertiefe128 vor nativer JSON-Prüfung; Path maximal8000UTF16Bytes,128Segmente. Frontier maximal10000Werte,10001Kandidaten zur Überschreitungserkennung. Kumulatives Parserworkbudget67108864Bytes zählt Envelope-/Frontierparseranteile vor den jeweiligen Aufrufen, keine Messung der gesamten CLR-/Engine-/LOB-/Tempdb-Allokation. Quoted-Path-/Root-Envelopes und Frontierkopien zusätzlicher Aufwand. Keine harte Deadline/Peakheap-/Produktionskapazitätszusage.
--
-- ## Nebenwirkungen
--
-- NULL in Json oder Path liefert zuerst SQL_NULL. Json-Inputbytes begrenzen; rohes JSON chunkweise mit Quoting/Escapes auf Containertiefe prüfen, bevor native ISJSON-Prüfung erfolgt. Danach Pathbytegrenze, äußere normale Spaces entfernen und optionales lax/strict-Präfix case-insensitiv abnehmen. Endlicher Parser für Root$, ASCII-Dotkeys, JSON-quotierte Dotkeys, einzelne Dezimalindizes und Arraywildcard. Quotedkeys durch geschütztes OPENJSON eines Stringarrays entescapen. Steuer-/Wildcardvergleiche bleiben SQL-Vergleiche einschließlich Padding, keine vollständige native Pfadgrammatik. Maximal128Segmente; ungültiger Pfad INVALID.
--
-- Container per ISJSON prüfen; skalare Rootwerte einschließlich JSONnull in ein geschütztes Einzelelementarray einhüllen. Eine Rootfrontierzeile verlangen. Jede Pfadstufe expandiert mit OPENJSON nur Objekt/Arraywerte, nie einen SQL-Ausdruck. Propertymatch verlangt Objektparent sowie binären Schlüsselvergleich und identische DATALENGTH, Indexmatch Arrayparent sowie denselben exakten Keyvergleich; Wildcard nur Array. JSONnull zählt als vorhandener Wert. Vor jeder Parserstufe kumulierten Workcharge prüfen; NextFrontier auf10001Kandidaten begrenzen und >10000 alsLIMIT verwerfen. Nach leerer Frontier stoppen. Mehrere Treffer/Duplikatschlüssel bleiben Existenz, keine geordnete Trefferliste. Wrapper übernimmt ausschließlich PathExists. Keine fachliche Tabelle, eigene Transaktion, Mutation oder dynamische SQL-Ausführung.
--
-- ## Fehlerbehandlung
--
-- SQL_NULL vor Quoten; Jsonbyte-/rohe Tiefen-/Segment-/Frontier-/Workquote ->LIMIT/NULL. Überlanger Pfad ->INVALID/0, ebenso erkannte ungültige Pfad-/JSONformen. Falsche Struktur oder fehlender Key/Index ->MISSING/0, nicht INVALID. Unerwartete Typbindungs-, OPENJSON-/Engine-/Ressourcenfehler bleiben Originalfehler; kein allgemeines TRY-CATCH in der UDF.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter aktueller Vertrag. Die ausdrücklich deklarierten funktionalen Korrekturen in diesem Modul benötigen neue native Gegenproben; historische Nachweise qualifizieren nur ihre ursprünglichen Bytes. Noch kein aktuelles natives API-/SC-/UTF8-/Caller-/Gesamtinstaller-PASS. Keine Installations-/Rechteattestation. Nur synthetische Beispiele; reale Eingaben/Runtimeausgaben privat halten.
-- OBJECT_USAGE_SKILL:END
AS
BEGIN
    INSERT @Result SELECT PathExists FROM toolbelt_json.TVF_JsonPathExistsStatus(@Json,@Path);
    RETURN;
END;
GO
