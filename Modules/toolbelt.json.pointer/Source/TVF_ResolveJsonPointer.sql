-- ============================================================================
-- Objekt:          toolbelt_json.TVF_ResolveJsonPointer
-- Typ:             Multi-statement Table-valued Function (TF)
-- Zweck:           Einen RFC6901-Pointer lesend gegen ein vollständiges JSON auflösen.
-- Vertrag:         Documentation/Architecture/JSON_POINTER_CONTRACT.md, 1.0.0
-- Parameter:       @Json/@Pointer nvarchar(max); @MaxInputBytes bigint=16777216;
--                  @MaxDepth int=128; beide Budgets positiv und nur absenkbar
-- Resultset:       Status varchar(16) NOT NULL; JsonType varchar(8) NULL;
--                  Value nvarchar(max) NULL; ErrorCode varchar(32) NULL; BIN2
-- Dependencies:    Keine Module, Tabellen, Helper oder CLR-Assembly; ISJSON/OPENJSON
-- Rechte:          SELECT auf der Funktion; keine Daten-, Rechte- oder Servermutation
-- Versionen:       SQL Server 2019, 2022 und 2025, Compatibility Level mindestens150
-- Plattformen:     Windows und Linux; jeweilige native Abnahme separat
-- Fehlerverhalten: Genau eine Zeile; keine Enginefehlertexte oder Input-Echos.
--                  SQL_NULL, Parameter, Limits, Pointer, native Schutzgrenze128,
--                  JSON-Syntax, abgesenkte Tiefe, Dokument-Unicode, Traversal.
-- Performance:     Vorwärts laufende Struktur-/Policy-Scans in festen Chunks; bis MaxDepth
--                  Containerenumerationen mit wiederholter Fragmentprüfung/-kopie.
--                  Kein Heap-, Laufzeit- oder APPLY-Performanceversprechen.
-- Einschränkungen: Pointer höchstens4000 UTF-16-Einheiten; kein URIfragment/Patch.
--                  MSTVF wegen sequenzieller Unicode-/Traversalzustände und expliziter
--                  sicherer Parseroperanden; keine behauptete Inline-Alternative.
-- ============================================================================
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE FUNCTION toolbelt_json.TVF_ResolveJsonPointer
(
    @Json nvarchar(max),
    @Pointer nvarchar(max),
    @MaxInputBytes bigint=16777216,
    @MaxDepth int=128
)
RETURNS @Result TABLE
(
    Status varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL,
    JsonType varchar(8) COLLATE Latin1_General_100_BIN2 NULL,
    Value nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,
    ErrorCode varchar(32) COLLATE Latin1_General_100_BIN2 NULL
)
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-toolbelt-toolbelt-json-tvf-resolvejsonpointer"
-- description: "Löst einen RFC6901-Pointer mit exakten Keys und unterscheidet FOUND, MISSING, JSON_NULL, SQL_NULL und INVALID. Der freigegebene feste128er-Guard gibt darüber DEPTH_LIMIT vor JSON_SYNTAX zurück."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.json.pointer"
-- schema_name: "toolbelt_json"
-- object_name: "TVF_ResolveJsonPointer"
-- object_type: "TVF"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@Json", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Vollständiger JSON-Wert einschließlich Skalar/root-null, wohlgeformtes Unicode auch in decodierten Escapes. Leer ist ungültig; DATALENGTH darf MaxInputBytes nicht überschreiten. Vor nativer Prüfung gilt die absolute Containertiefengrenze 128, danach das abgesenkte MaxDepth. NULL in Json oder Pointer ergibt SQL_NULL vor Parameterprüfung. Kein partiell gültiges Dokument und keine Mutation. Argumentposition ausdrücklich angeben; nur bei den beiden vorhandenen SQL-Budgetdefaults ist DEFAULT zulässig. SQL-NULL in Json oder Pointer kurzschließt auch ungültige Budgets."}, {"name": "@Pointer", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "RFC6901-Stringpointer, keine URIfragmentform #/...: leer bezeichnet Root, sonst beginnt der Text mit /. Segmente sind exakte binäre/case-sensitive Objektkeys; ~0 decodiert einmal zu ~, ~1 zu /. Kein anderes ~-Escape oder Percentdecoding. Arrayindizes sind nullbasiert kanonische nicht negative ASCII-Dezimalzahlen ohne führende Nullen; - ist kein Appendindex, Wildcards fehlen. Maximal 4000 UTF-16-Einheiten, wohlgeformtes Unicode; / bezeichnet einen leeren Key. NULL ergibt SQL_NULL. Argumentposition ausdrücklich angeben; nur bei den beiden vorhandenen SQL-Budgetdefaults ist DEFAULT zulässig. SQL-NULL in Json oder Pointer kurzschließt auch ungültige Budgets."}, {"name": "@MaxInputBytes", "sql_type": "bigint", "sql_default": "16777216", "is_output": false, "argument_required": true, "business_required": false, "nullable": false, "description": "Ganzzahl 1..16777216 UTF-16-Bytes des JSON-Dokuments, Default 16777216; keine Zeichenanzahl. NULL/außerhalb ergibt INVALID/PARAMETER, Überschreitung INVALID/INPUT_LIMIT. Nur absenkbar; früher Json-/Pointer-NULL-Pfad hat Vorrang. Argumentposition ausdrücklich angeben; nur bei den beiden vorhandenen SQL-Budgetdefaults ist DEFAULT zulässig. SQL-NULL in Json oder Pointer kurzschließt auch ungültige Budgets."}, {"name": "@MaxDepth", "sql_type": "int", "sql_default": "128", "is_output": false, "argument_required": true, "business_required": false, "nullable": false, "description": "Ganzzahl 1..128 gleichzeitig offene JSON-Container, Default 128. Gilt für das gesamte Dokument, auch nicht traversierte Teile. NULL/außerhalb ergibt INVALID/PARAMETER; vor nativer JSON-Prüfung bleibt zusätzlich die absolute Schutzgrenze 128 wirksam. Argumentposition ausdrücklich angeben; nur bei den beiden vorhandenen SQL-Budgetdefaults ist DEFAULT zulässig. SQL-NULL in Json oder Pointer kurzschließt auch ungültige Budgets."}]
-- source_paths: ["Modules/toolbelt.json.pointer/Source/TVF_ResolveJsonPointer.sql"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- ---
--
-- # TVF_ResolveJsonPointer
--
-- ## Zweck und Einsatzfälle
--
-- Löst genau einen RFC6901-Stringpointer gegen einen vollständigen JSON-Wert auf, einschließlich Scalarroot und JSON-null. Rein lesende native T-SQL-Multi-statement-TVF; kein JSON-Patch, kein URIfragment, keine SQL-Ausführung aus dem Eingabetext.
--
-- ## Voraussetzungen
--
-- SQL Server2019/2022/2025 Windows/Linux gemäß Modulmatrix, unterstützter Compatibility Level mindestens150 auch im zentralen Aufrufkontext. Ausschließlich native ISJSON-/OPENJSON-Grammatik und begrenzter UTF16-Policywalker; keine CLR-Assembly, Daten-/Systemkatalogtabelle, Serveroption oder Abhängigkeit eines anderen Moduls. Der gesamte Input muss gültige Syntax, Tiefen- und Unicodepolicy erfüllen, auch nicht traversierte Teile.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Vertrag |
-- |---|---|---|---|
-- | `@Json` | `nvarchar(max)` | `kein Default` | Vollständiger JSON-Wert einschließlich Skalar/root-null, wohlgeformtes Unicode auch in decodierten Escapes. Leer ist ungültig; DATALENGTH darf MaxInputBytes nicht überschreiten. Vor nativer Prüfung gilt die absolute Containertiefengrenze 128, danach das abgesenkte MaxDepth. NULL in Json oder Pointer ergibt SQL_NULL vor Parameterprüfung. Kein partiell gültiges Dokument und keine Mutation. Argumentposition ausdrücklich angeben; nur bei den beiden vorhandenen SQL-Budgetdefaults ist DEFAULT zulässig. SQL-NULL in Json oder Pointer kurzschließt auch ungültige Budgets. |
-- | `@Pointer` | `nvarchar(max)` | `kein Default` | RFC6901-Stringpointer, keine URIfragmentform #/...: leer bezeichnet Root, sonst beginnt der Text mit /. Segmente sind exakte binäre/case-sensitive Objektkeys; ~0 decodiert einmal zu ~, ~1 zu /. Kein anderes ~-Escape oder Percentdecoding. Arrayindizes sind nullbasiert kanonische nicht negative ASCII-Dezimalzahlen ohne führende Nullen; - ist kein Appendindex, Wildcards fehlen. Maximal 4000 UTF-16-Einheiten, wohlgeformtes Unicode; / bezeichnet einen leeren Key. NULL ergibt SQL_NULL. Argumentposition ausdrücklich angeben; nur bei den beiden vorhandenen SQL-Budgetdefaults ist DEFAULT zulässig. SQL-NULL in Json oder Pointer kurzschließt auch ungültige Budgets. |
-- | `@MaxInputBytes` | `bigint` | `16777216` | Ganzzahl 1..16777216 UTF-16-Bytes des JSON-Dokuments, Default 16777216; keine Zeichenanzahl. NULL/außerhalb ergibt INVALID/PARAMETER, Überschreitung INVALID/INPUT_LIMIT. Nur absenkbar; früher Json-/Pointer-NULL-Pfad hat Vorrang. Argumentposition ausdrücklich angeben; nur bei den beiden vorhandenen SQL-Budgetdefaults ist DEFAULT zulässig. SQL-NULL in Json oder Pointer kurzschließt auch ungültige Budgets. |
-- | `@MaxDepth` | `int` | `128` | Ganzzahl 1..128 gleichzeitig offene JSON-Container, Default 128. Gilt für das gesamte Dokument, auch nicht traversierte Teile. NULL/außerhalb ergibt INVALID/PARAMETER; vor nativer JSON-Prüfung bleibt zusätzlich die absolute Schutzgrenze 128 wirksam. Argumentposition ausdrücklich angeben; nur bei den beiden vorhandenen SQL-Budgetdefaults ist DEFAULT zulässig. SQL-NULL in Json oder Pointer kurzschließt auch ungültige Budgets. |
--
-- ## Ergebnisse
--
-- Genau eine Zeile: Status varchar(16) NOT NULL, JsonType varchar(8) NULL, Value nvarchar(max) NULL, ErrorCode varchar(32) NULL; alle vier Spalten Latin1_General_100_BIN2. Taxative Statussemantik:
--
-- | Status | JsonType | Value | ErrorCode |
-- |---|---|---|---|
-- | FOUND | STRING, NUMBER, BOOLEAN, ARRAY oder OBJECT | gefundener Text/Fragment, auch leerer String | NULL |
-- | JSON_NULL | NULL als Typtext | SQL-NULL | NULL |
-- | MISSING | SQL-NULL | SQL-NULL | NULL |
-- | SQL_NULL | SQL-NULL | SQL-NULL | NULL |
-- | INVALID | SQL-NULL | SQL-NULL | stabiler Code |
--
-- Strings werden nativ decodiert, Numbers bleiben Textliterale ohne eigenen numerischen Cast, Booleans Text, Array-/Objektwerte Fragmente. Rootcontainer mit leerem Pointer bleibt der ursprüngliche vollständige Text; kein kanonischer JSON-Serializer oder einheitliches Whitespaceformat versprochen. Keine OUTPUT-Parameter, SQL-Rückgabecodes oder zusätzlichen Fehlerresultsets. Unerwartete technische Enginefehler sind keine garantierte INVALID-Zeile.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- SELECT Status,JsonType,Value,ErrorCode
-- FROM toolbelt_json.TVF_ResolveJsonPointer(N'{"a/b":[null,"example"]}',N'/a~1b/1',DEFAULT,DEFAULT);
-- -- FOUND / STRING / example / NULL.
-- SELECT * FROM toolbelt_json.TVF_ResolveJsonPointer(N'null',N'',DEFAULT,DEFAULT);
-- -- JSON_NULL mit JsonType als Text NULL und Value SQL-NULL.
-- SELECT * FROM toolbelt_json.TVF_ResolveJsonPointer(NULL,NULL,0,0);
-- -- SQL_NULL vor Parameterfehlern.
-- ```
--
-- ## Rechte
--
-- Vorhandenes SELECT auf dieser öffentlichen TVF und gültige Datenbankauthentifizierung. Keine SELECT-Rechte auf Daten-/Systemtabellen oder Serverstatus-/Trustrechte, da solche Quellen nicht gelesen werden. Zentraler Dreiteilname ersetzt kein gültiges Ziel-DB-Mapping/Objektrecht. Die Funktion erteilt keine Rechte und ändert keinen Principal.
--
-- ## Ressourcenbedarf
--
-- MaxInputBytes 1..16777216 Roh-UTF16-Bytes, MaxDepth 1..128 gleichzeitig offene Container im gesamten Dokument (Rootcontainer Tiefe1, Scalar0), beide nur absenkbar. Pointer maximal8000 Bytes=4000 UTF16-Codeunits einschließlich Slashes/Escapes. Fester vorgelagerter escape-aware Strukturguard bei beobachteter Tiefe>128 schützt native Grammatik, auch für sonst ungültiges JSON. Kumulatives festes Budget67108864 Bytes (64 MiB) ausschließlich für konkrete OPENJSON-Operanden: Scalarwrapper und wiederholt geparste Containerfragmente werden VOR jedem Aufruf geladen/charged; ISJSON und übrige Policy-/Tokenscans sind dadurch nicht als CPU-/Heapquote begrenzt. Originaldokument vorwärts in4000-Codeunit-Chunks scannen, niemals als schrumpfenden Rest kopieren; native Fragmentenumeration/COUNT/MAX und Kopien können sich je traversiertem Container wiederholen. Pointertokens werden codeunitweise bis zur festen Grenze aufgebaut. MSTVF mit materialisiertem Einzelresultat, keine behauptete inline-/Streaming-/APPLY-/Parallelitäts- oder Produktionsdurchsatzzusage.
--
-- ## Nebenwirkungen
--
-- Deterministische lesende Berechnung aus expliziten Argumenten, keine persistenten Änderungen, Caller-Temps, Transaktionen, Session-Context-, Datei-/Netzwerk-/Katalogzugriffe. Status/Typen beschreiben das Eingabedokument, keine installierten Serverobjekte. Kein Hilfeschalter an dieser Funktion; vollständiger Skill in DDL und künftig gemeinsamem vollständigem SQL-Skillkatalog.
--
-- ## Fehlerbehandlung
--
-- Priorität: SQL_NULL bei Json/Pointer NULL; INVALID/PARAMETER bei NULL/außerhalb der Budgetwerte; INPUT_LIMIT; POINTER_LIMIT; POINTER_SYNTAX (nicht leer und kein führender / oder ungültige ~-Sequenz); Pointer-UNICODE; fester Strukturguard128/DEPTH_LIMIT; JSON_SYNTAX; abgesenktes MaxDepth/DEPTH_LIMIT; Dokument-UNICODE; danach Traversal mit ARRAY_INDEX,DUPLICATE_KEY und vor jedem OPENJSON geprüfter WORK_LIMIT. Scalarwrapper wird auf genau einen nativen Rootwert geprüft, Listen/leer sind JSON_SYNTAX. Vollständige Dokument-Unicodeprüfung decodiert auch JSON-\uXXXX-Surrogate; ungepaarte rohe/decodierte Surrogate in Strings/Keys und Pointer werden abgewiesen, NUL als gültige Codeunit in Pointer/decodiertem Key ist kein generelles Verbot. Unicodefaults werden bis zur vollständigen Tiefenprüfung gespeichert, damit späteres Depthlimit Vorrang hat.
--
-- Leerer Pointer adressiert Root, sonst jeder Slash ein Token, auch leer. ~0=>~,~1=>/ genau einmal; ~01 wird ~1, kein Percentdecoding, kein URI-#fragment. Objektkeys exakt BIN2 PLUS DATALENGTH, daher case-/trailing-space-/NUL-sensitiv ohne Normalisierung. Nur mehrere passende Keys am tatsächlich adressierten Schritt sind DUPLICATE_KEY; unberührte Duplikate machen das Dokument nicht pauschal ungültig. Arraytoken: - bedeutet MISSING, sonst kanonisches ASCII-Dezimal 0 oder nichtnullführende Ziffern; leer,+1,-1,01 oder Nichtziffern sind ARRAY_INDEX. Kein Ganzzahlcast des Indextexts: auch riesige gültige Dezimalindizes werden gegen native Schlüssel verglichen und sind bei Fehlen MISSING statt Overflow. Weiterer Schritt unter Scalar/JSON-null ergibt MISSING. Kein früher MISSING-Pfad überspringt die vorherige vollständige Dokument-/Pointervalidierung. Unerwartete technische Fehler bleiben sichtbar; keine Input-Echos/Enginefehlertexte in eigenen Statuscodes.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter aktueller Vertrag, keine neue native Skill-/Installer-/Minimalrechte-/Ressourcenabnahme. Historische Fach-/Sicherheits-/Clientbelege behalten ihre ursprünglichen Artefaktbindungen. Keine Garantie unbegrenzter Kapazität, kanonischer Serialisierung oder sicherer weiterer Verarbeitung des gefundenen Textes. Keine Serverkonfiguration, SQL-/JSON-Patchmutation oder Installations-/Rechteattestation.
-- OBJECT_USAGE_SKILL:END
AS
BEGIN
    IF @Json IS NULL OR @Pointer IS NULL
    BEGIN
        INSERT @Result VALUES('SQL_NULL',NULL,NULL,NULL);
        RETURN;
    END;
    IF @MaxInputBytes IS NULL OR @MaxInputBytes<1 OR @MaxInputBytes>16777216
       OR @MaxDepth IS NULL OR @MaxDepth<1 OR @MaxDepth>128
    BEGIN
        INSERT @Result VALUES('INVALID',NULL,NULL,'PARAMETER');
        RETURN;
    END;
    IF DATALENGTH(@Json)>@MaxInputBytes
    BEGIN
        INSERT @Result VALUES('INVALID',NULL,NULL,'INPUT_LIMIT');
        RETURN;
    END;
    IF DATALENGTH(@Pointer)>8000
    BEGIN
        INSERT @Result VALUES('INVALID',NULL,NULL,'POINTER_LIMIT');
        RETURN;
    END;

    DECLARE @ParserWorkBytes bigint=0;
    DECLARE @PointerUnits int=CONVERT(int,DATALENGTH(@Pointer)/2),
            @JsonUnits int=CONVERT(int,DATALENGTH(@Json)/2),
            @Position int=1,@Unit int,@NextUnit int,@PendingHigh bit=0,
            @PointerSyntax bit=0,@UnicodeFault bit=0;
    IF @PointerUnits>0 AND UNICODE(SUBSTRING(@Pointer COLLATE Latin1_General_100_BIN2,1,1))<>47
        SET @PointerSyntax=1;
    -- Originale Codeeinheiten prüfen: ~-Syntax und Unicode gelten für den ganzen
    -- Pointer, auch wenn ein früherer Traversalschritt später MISSING ergeben würde.
    WHILE @Position<=@PointerUnits
    BEGIN
        SET @Unit=UNICODE(SUBSTRING(@Pointer COLLATE Latin1_General_100_BIN2,@Position,1));
        IF @Unit=126
        BEGIN
            SET @NextUnit=UNICODE(SUBSTRING(@Pointer COLLATE Latin1_General_100_BIN2,@Position+1,1));
            IF @NextUnit IS NULL OR @NextUnit NOT IN(48,49) SET @PointerSyntax=1;
        END;
        IF @PendingHigh=1
        BEGIN
            IF @Unit NOT BETWEEN 56320 AND 57343 SET @UnicodeFault=1;
            SET @PendingHigh=0;
        END
        ELSE IF @Unit BETWEEN 56320 AND 57343 SET @UnicodeFault=1;
        IF @Unit BETWEEN 55296 AND 56319 SET @PendingHigh=1;
        SET @Position+=1;
    END;
    IF @PendingHigh=1 SET @UnicodeFault=1;
    IF @PointerSyntax=1
    BEGIN
        INSERT @Result VALUES('INVALID',NULL,NULL,'POINTER_SYNTAX');
        RETURN;
    END;
    IF @UnicodeFault=1
    BEGIN
        INSERT @Result VALUES('INVALID',NULL,NULL,'UNICODE');
        RETURN;
    END;

    DECLARE @Current nvarchar(max)=NULL,@CurrentType int=NULL,
            @SafeJson nvarchar(max)=N'[]',@RootCount bigint=0,
            @Chunk nvarchar(4000),@ChunkStart int=0,@ChunkUnits int=0;
    -- Freigegebene native Schutzgrenze: ISJSON selbst kann bei129 Ebenen
    -- werfen. Vor nativer Grammatikprüfung nur rohe Quote-/Escapegrenzen und
    -- Container beobachten. Kein Grammarurteil und kein Unicode-Decoding.
    -- Schließzeichen bei0 bleiben bei0; falsche Klammerarten werden nicht geprüft.
    -- Auch fehlerhafte Eingaben oberhalb dieser Grenze liefern DEPTH_LIMIT.
    DECLARE @RawQuoted bit=0,@RawEscaped bit=0,@RawDepth int=0,
            @RawContainer bit=0,@FirstUnit int=NULL;
    SET @Position=1;
    WHILE @Position<=@JsonUnits
    BEGIN
        IF @Position>=@ChunkStart+@ChunkUnits
        BEGIN
            SET @Chunk=SUBSTRING(@Json COLLATE Latin1_General_100_BIN2,@Position,4000);
            SET @ChunkStart=@Position;
            SET @ChunkUnits=CONVERT(int,DATALENGTH(@Chunk)/2);
        END;
        SET @Unit=UNICODE(SUBSTRING(@Chunk COLLATE Latin1_General_100_BIN2,@Position-@ChunkStart+1,1));
        IF @FirstUnit IS NULL AND @Unit NOT IN(9,10,13,32) SET @FirstUnit=@Unit;
        IF @RawQuoted=1
        BEGIN
            IF @RawEscaped=1 SET @RawEscaped=0;
            ELSE IF @Unit=92 SET @RawEscaped=1;
            ELSE IF @Unit=34 SET @RawQuoted=0;
        END
        ELSE IF @Unit=34 SET @RawQuoted=1;
        ELSE IF @Unit IN(91,123)
        BEGIN
            SET @RawContainer=1;
            SET @RawDepth+=1;
            IF @RawDepth>128
            BEGIN
                INSERT @Result VALUES('INVALID',NULL,NULL,'DEPTH_LIMIT');
                RETURN;
            END;
        END
        ELSE IF @Unit IN(93,125)
        BEGIN
            SET @RawContainer=1;
            IF @RawDepth>0 SET @RawDepth-=1;
        END;
        SET @Position+=1;
    END;
    -- ISJSON bleibt die einzige JSON-Grammatik. Containerroots werden direkt
    -- geprüft; ungültige Container fallen niemals in den Scalarwrapper zurück.
    IF @FirstUnit IN(91,123)
    BEGIN
        IF ISJSON(@Json)<>1
        BEGIN
            INSERT @Result VALUES('INVALID',NULL,NULL,'JSON_SYNTAX');
            RETURN;
        END;
        SET @Current=@Json;
        SET @CurrentType=CASE WHEN @FirstUnit=91 THEN 4 ELSE 5 END;
    END
    ELSE
    BEGIN
        -- Ein einzelner Scalar enthält außerhalb von Strings keine Container-
        -- zeichen. Solche Kandidaten vor dem Wrapper ablehnen, damit fehlerhafte
        -- Scalar-/Containerlisten keine künstliche129. Ebene erzeugen.
        IF @RawContainer=1
        BEGIN
            INSERT @Result VALUES('INVALID',NULL,NULL,'JSON_SYNTAX');
            RETURN;
        END;
        -- Max-Typ vor Konkatenation, nach Input-Precharge. OPENJSON bekommt
        -- erst in einem separaten, erfolgreichen IF-Zweig den gültigen Wrapper.
        DECLARE @Wrapper nvarchar(max)=CAST(N'[' AS nvarchar(max))+@Json+N']';
        IF ISJSON(@Wrapper)<>1
        BEGIN
            INSERT @Result VALUES('INVALID',NULL,NULL,'JSON_SYNTAX');
            RETURN;
        END;
        SET @SafeJson=@Wrapper;
        IF DATALENGTH(@SafeJson)>67108864-@ParserWorkBytes
        BEGIN
            INSERT @Result VALUES('INVALID',NULL,NULL,'WORK_LIMIT'); RETURN;
        END;
        SET @ParserWorkBytes+=DATALENGTH(@SafeJson);
        SELECT @RootCount=COUNT_BIG(*),@Current=MAX([value]),@CurrentType=MAX([type])
        FROM OPENJSON(@SafeJson);
        IF @RootCount<>1
        BEGIN
            INSERT @Result VALUES('INVALID',NULL,NULL,'JSON_SYNTAX');
            RETURN;
        END;
    END;

    -- Nach der nativen Syntaxprüfung nur Policy prüfen: String-/Escapegrenzen,
    -- gleichzeitig offene Container und decodierte UTF-16-Paare. Keine zweite
    -- Number-, Literal-, Member- oder Separatorgrammatik. Der Originaltext wird
    -- vorwärts in4000-Einheiten-Chunks gelesen, nie als schrumpfender Rest kopiert.
    DECLARE @InsideString bit=0,@Depth int=0,@Advance int,@HexText nvarchar(4),
            @HexPosition int,@HexUnit int;
    SET @Position=1;
    SET @ChunkStart=0;
    SET @ChunkUnits=0;
    SET @PendingHigh=0;
    SET @UnicodeFault=0;
    WHILE @Position<=@JsonUnits
    BEGIN
        IF @Position>=@ChunkStart+@ChunkUnits
        BEGIN
            SET @Chunk=SUBSTRING(@Json COLLATE Latin1_General_100_BIN2,@Position,4000);
            SET @ChunkStart=@Position;
            SET @ChunkUnits=CONVERT(int,DATALENGTH(@Chunk)/2);
        END;
        SET @Unit=UNICODE(SUBSTRING(@Chunk COLLATE Latin1_General_100_BIN2,@Position-@ChunkStart+1,1));
        SET @Advance=1;
        IF @InsideString=0
        BEGIN
            IF @Unit=34
            BEGIN
                SET @InsideString=1;
                SET @PendingHigh=0;
            END
            ELSE IF @Unit IN(91,123)
            BEGIN
                SET @Depth+=1;
                IF @Depth>@MaxDepth
                BEGIN
                    INSERT @Result VALUES('INVALID',NULL,NULL,'DEPTH_LIMIT');
                    RETURN;
                END;
            END
            ELSE IF @Unit IN(93,125) SET @Depth-=1;
        END
        ELSE IF @Unit=34
        BEGIN
            IF @PendingHigh=1 SET @UnicodeFault=1;
            SET @PendingHigh=0;
            SET @InsideString=0;
        END
        ELSE
        BEGIN
            IF @Unit=92
            BEGIN
                SET @NextUnit=UNICODE(SUBSTRING(@Json COLLATE Latin1_General_100_BIN2,@Position+1,1));
                IF @NextUnit=117
                BEGIN
                    SET @HexText=SUBSTRING(@Json COLLATE Latin1_General_100_BIN2,@Position+2,4);
                    SET @Unit=0;
                    SET @HexPosition=1;
                    WHILE @HexPosition<=4
                    BEGIN
                        SET @HexUnit=UNICODE(SUBSTRING(@HexText COLLATE Latin1_General_100_BIN2,@HexPosition,1));
                        SET @Unit=@Unit*16+CASE WHEN @HexUnit BETWEEN 48 AND 57 THEN @HexUnit-48
                                              WHEN @HexUnit BETWEEN 65 AND 70 THEN @HexUnit-55 ELSE @HexUnit-87 END;
                        SET @HexPosition+=1;
                    END;
                    SET @Advance=6;
                END
                ELSE
                BEGIN
                    -- Die übrigen gültigen Escapes liefern ausschließlich
                    -- Nicht-Surrogate; ihr ASCII-Escapezeichen genügt hier.
                    SET @Unit=@NextUnit;
                    SET @Advance=2;
                END;
            END;
            IF @PendingHigh=1
            BEGIN
                IF @Unit NOT BETWEEN 56320 AND 57343 SET @UnicodeFault=1;
                SET @PendingHigh=0;
            END
            ELSE IF @Unit BETWEEN 56320 AND 57343 SET @UnicodeFault=1;
            IF @Unit BETWEEN 55296 AND 56319 SET @PendingHigh=1;
        END;
        SET @Position+=@Advance;
    END;
    -- Unicodefehler werden gespeichert statt früh zurückgegeben: ein späteres
    -- Tiefenlimit hat nach gültiger Syntax den vereinbarten Vorrang.
    IF @UnicodeFault=1
    BEGIN
        INSERT @Result VALUES('INVALID',NULL,NULL,'UNICODE');
        RETURN;
    END;

    DECLARE @Token nvarchar(max),@TokenUnits int,@Matches bigint,
            @NextValue nvarchar(max),@NextType int,@TokenPosition int,
            @ArraySyntax bit;
    SET @Position=1;
    WHILE @Position<=@PointerUnits
    BEGIN
        -- Eine Slashposition einlesen, dann genau ein Token decodieren. Kein
        -- REPLACE: Pointer/Keys dürfen NUL enthalten. ~01 wird korrekt zu ~1.
        SET @Position+=1;
        SET @Token=CAST(N'' AS nvarchar(max));
        WHILE @Position<=@PointerUnits
        BEGIN
            SET @Unit=UNICODE(SUBSTRING(@Pointer COLLATE Latin1_General_100_BIN2,@Position,1));
            IF @Unit=47 BREAK;
            IF @Unit=126
            BEGIN
                SET @NextUnit=UNICODE(SUBSTRING(@Pointer COLLATE Latin1_General_100_BIN2,@Position+1,1));
                SET @Token+=CASE WHEN @NextUnit=49 THEN N'/' ELSE N'~' END;
                SET @Position+=2;
            END
            ELSE
            BEGIN
                SET @Token+=SUBSTRING(@Pointer COLLATE Latin1_General_100_BIN2,@Position,1);
                SET @Position+=1;
            END;
        END;
        IF @CurrentType NOT IN(4,5)
        BEGIN
            INSERT @Result VALUES('MISSING',NULL,NULL,NULL);
            RETURN;
        END;
        SET @TokenUnits=CONVERT(int,DATALENGTH(@Token)/2);
        IF @CurrentType=4
        BEGIN
            IF @TokenUnits=1 AND @Token COLLATE Latin1_General_100_BIN2=N'-'
            BEGIN
                INSERT @Result VALUES('MISSING',NULL,NULL,NULL);
                RETURN;
            END;
            SET @ArraySyntax=0;
            IF @TokenUnits=0 SET @ArraySyntax=1;
            IF @TokenUnits>1 AND UNICODE(SUBSTRING(@Token COLLATE Latin1_General_100_BIN2,1,1))=48 SET @ArraySyntax=1;
            SET @TokenPosition=1;
            WHILE @TokenPosition<=@TokenUnits
            BEGIN
                SET @Unit=UNICODE(SUBSTRING(@Token COLLATE Latin1_General_100_BIN2,@TokenPosition,1));
                IF @Unit NOT BETWEEN 48 AND 57 SET @ArraySyntax=1;
                SET @TokenPosition+=1;
            END;
            IF @ArraySyntax=1
            BEGIN
                INSERT @Result VALUES('INVALID',NULL,NULL,'ARRAY_INDEX');
                RETURN;
            END;
            -- Lexikalischer Vergleich mit nativen Indexkeys vermeidet jede
            -- Ganzzahlkonvertierung; beliebig große gültige Indizes sind MISSING.
        END;
        SET @Matches=0;
        SET @NextValue=NULL;
        SET @NextType=NULL;
        -- Aktueller Wert stammt ausschließlich aus dem vollständig validierten
        -- Root oder einem nativen Containerfragment. IF schützt den Parseraufruf,
        -- kein Optimizer-Prädikat. Nur passende Werte werden aggregiert gehalten.
        IF @CurrentType IN(4,5)
        BEGIN
            SET @SafeJson=@Current;
            IF DATALENGTH(@SafeJson)>67108864-@ParserWorkBytes
            BEGIN
                INSERT @Result VALUES('INVALID',NULL,NULL,'WORK_LIMIT'); RETURN;
            END;
            SET @ParserWorkBytes+=DATALENGTH(@SafeJson);
            SELECT @Matches=COUNT_BIG(*),@NextValue=MAX([value]),@NextType=MAX([type])
            FROM OPENJSON(@SafeJson)
            WHERE [key] COLLATE Latin1_General_100_BIN2=@Token COLLATE Latin1_General_100_BIN2
              AND DATALENGTH([key])=DATALENGTH(@Token);
        END;
        IF @Matches=0
        BEGIN
            INSERT @Result VALUES('MISSING',NULL,NULL,NULL);
            RETURN;
        END;
        IF @Matches>1
        BEGIN
            INSERT @Result VALUES('INVALID',NULL,NULL,'DUPLICATE_KEY');
            RETURN;
        END;
        SET @Current=@NextValue;
        SET @CurrentType=@NextType;
    END;
    IF @CurrentType=0
        INSERT @Result VALUES('JSON_NULL','NULL',NULL,NULL);
    ELSE
        INSERT @Result VALUES('FOUND',CASE @CurrentType WHEN 1 THEN 'STRING' WHEN 2 THEN 'NUMBER'
            WHEN 3 THEN 'BOOLEAN' WHEN 4 THEN 'ARRAY' ELSE 'OBJECT' END,@Current,NULL);
    RETURN;
END;
GO
