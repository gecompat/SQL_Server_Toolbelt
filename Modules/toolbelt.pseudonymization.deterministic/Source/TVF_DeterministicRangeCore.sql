-- ============================================================================
-- Objekt:          toolbelt_pseudonymization.TVF_DeterministicRangeCore
-- Zweck:           Interner, relationaler SHA256/Range-Kern mit Format V1.
-- Parameter:       Domain binary(8), Context bigint; Key varbinary(max),
--                  MappingVersion int, Seed bigint, Min bigint, Max bigint.
-- Resultset:       Value bigint NULL, ErrorCode int NOT NULL.
-- Dependencies:    interner IntegerBytes-Encoder; keine Scalar-UDF oder Assembly.
-- Versionen:       SQL Server 2019/2022/2025, Windows und Linux.
-- Performance:     Inline TVF; maximal 128 Hashkandidaten je Eingabe.
-- Collation:       ausschließlich binäre Eingabe und feste Hashbytes.
-- Einschränkungen: Interne Implementierung; keine Anonymisierung oder Sicherheit.
-- ============================================================================
CREATE OR ALTER FUNCTION [toolbelt_pseudonymization].[TVF_DeterministicRangeCore]
(
      @Domain         binary(8)
    , @Context        bigint
    , @Key            varbinary(max)
    , @MappingVersion int
    , @Seed           bigint
    , @Min            bigint
    , @Max            bigint
)
RETURNS TABLE
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-tvf-deterministicrangecore"
-- description: "Interner V1-SHA256-Rejection-Sampler mit gebundener Domäne und Kontext."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.pseudonymization.deterministic"
-- schema_name: "toolbelt_pseudonymization"
-- object_name: "TVF_DeterministicRangeCore"
-- object_type: "TVF"
-- database_role: "toolbelt"
-- is_internal: true
-- parameters: [{"name": "@Domain", "sql_type": "binary(8)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Interne feste 8-Byte-Domäne des öffentlichen Verfahrens. NichtNULL, keine freie Fachcaller-Konfiguration; sonst Code6 nach vorgeordneten Prüfungen."}, {"name": "@Context", "sql_type": "bigint", "sql_default": null, "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Interner nichtNULL-Domänenkontext: Range0,LookuppositiveLookupVersion,GeoSlot0/1; sonst Code6."}, {"name": "@Key", "sql_type": "varbinary(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Binärer Entity-Key varbinary(max) mit 1..8000 Bytes, z.B. 0x010203; keine automatische Textkodierung/Normalisierung. NULL ist ein früher NULL-Ergebnispfad mit ErrorCode 0; leer/größer ergibt Code 4. Gleichheit meint dieselben Bytes, nicht einen Darstellungsstring. Kein Geheimschlüsselvertrag."}, {"name": "@MappingVersion", "sql_type": "int", "sql_default": null, "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Positive Ganzzahl 1..2147483647 als explizite Mappingkontextversion. NULL/0/negativ ergibt ErrorCode 1, sofern kein früher NULL-Eingabepfad greift. Keine automatische aktuelle Version; Änderung verändert das Mapping, garantiert aber nicht jeden Einzelwert."}, {"name": "@Seed", "sql_type": "bigint", "sql_default": null, "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Jeder nicht-NULL-bigint (-9223372036854775808..9223372036854775807), Default 0. Deterministischer Variantenkontext, kein Zufall je Aufruf und kein Secret. NULL ergibt Code 2 nach dem frühen NULL-Eingabepfad."}, {"name": "@Min", "sql_type": "bigint", "sql_default": null, "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Inklusive Untergrenze im gesamten bigint-Bereich; muss nicht NULL und <=Max sein. Min=Max ist gültig und liefert diesen Wert. NULL/vertauschte Grenzen ergeben Code 3 nach früheren NULL-/Konfigurationsprüfungen."}, {"name": "@Max", "sql_type": "bigint", "sql_default": null, "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Inklusive Obergrenze im gesamten bigint-Bereich; nicht NULL und >=Min. Auch der volle vorzeichenbehaftete 64-Bit-Bereich ist zulässig; kein exklusives Ende. NULL/vertauscht ergibt Code 3."}]
-- source_paths: ["Modules/toolbelt.pseudonymization.deterministic/Source/TVF_DeterministicRangeCore.sql", "Modules/toolbelt.pseudonymization.deterministic/Source/TVF_DeterministicIntegerBytes.sql"]
-- review_status: "verified"
-- source_module_version: "1.2.0"
-- public_entrypoints: ["toolbelt_pseudonymization.TVF_DeterministicRange"]
-- ---
--
-- # TVF_DeterministicRangeCore
--
-- ## Zweck und Einsatzfälle
--
-- Interner V1-SHA256-Rejection-Sampler mit gebundener Domäne und Kontext. Kein eigener öffentlicher Fachaufrufweg.
--
-- ## Voraussetzungen
--
-- Modul 1.2.0 mit kanonischen T-SQL-Abhängigkeiten derselben Datenbank. SQL2019/2022/2025 auf Windows/Linux mit CL150/160/170 gemäß Modulmatrix. Explizite Versionen und binäre Keys statt impliziter Textkodierung. Keine Fach- oder Systemkatalogabfrage für die Transformation erforderlich. Input- und Fehlercodes vor Weiterverwendung auswerten.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
-- |---|---|---|---|---|
-- | `@Domain` | `binary(8)` | kein Default | Input | Interne feste 8-Byte-Domäne des öffentlichen Verfahrens. NichtNULL, keine freie Fachcaller-Konfiguration; sonst Code6 nach vorgeordneten Prüfungen. |
-- | `@Context` | `bigint` | kein Default | Input | Interner nichtNULL-Domänenkontext: Range0,LookuppositiveLookupVersion,GeoSlot0/1; sonst Code6. |
-- | `@Key` | `varbinary(max)` | kein Default | Input | Binärer Entity-Key varbinary(max) mit 1..8000 Bytes, z.B. 0x010203; keine automatische Textkodierung/Normalisierung. NULL ist ein früher NULL-Ergebnispfad mit ErrorCode 0; leer/größer ergibt Code 4. Gleichheit meint dieselben Bytes, nicht einen Darstellungsstring. Kein Geheimschlüsselvertrag. |
-- | `@MappingVersion` | `int` | kein Default | Input | Positive Ganzzahl 1..2147483647 als explizite Mappingkontextversion. NULL/0/negativ ergibt ErrorCode 1, sofern kein früher NULL-Eingabepfad greift. Keine automatische aktuelle Version; Änderung verändert das Mapping, garantiert aber nicht jeden Einzelwert. |
-- | `@Seed` | `bigint` | kein Default | Input | Jeder nicht-NULL-bigint (-9223372036854775808..9223372036854775807), Default 0. Deterministischer Variantenkontext, kein Zufall je Aufruf und kein Secret. NULL ergibt Code 2 nach dem frühen NULL-Eingabepfad. |
-- | `@Min` | `bigint` | kein Default | Input | Inklusive Untergrenze im gesamten bigint-Bereich; muss nicht NULL und <=Max sein. Min=Max ist gültig und liefert diesen Wert. NULL/vertauschte Grenzen ergeben Code 3 nach früheren NULL-/Konfigurationsprüfungen. |
-- | `@Max` | `bigint` | kein Default | Input | Inklusive Obergrenze im gesamten bigint-Bereich; nicht NULL und >=Min. Auch der volle vorzeichenbehaftete 64-Bit-Bereich ist zulässig; kein exklusives Ende. NULL/vertauscht ergibt Code 3. |
--
-- Bei TVF-Aufrufen alle Argumentpositionen angeben; DEFAULT nur bei tatsächlichem SQL-Default. NULL-Ergebnispriorität ist ein logischer Vertrag,keine Zusage über physische Optimizer-Auswertung. SQL-Typkonvertierung liegt vorher.
--
-- ## Ergebnisse
--
-- | Spalte | SQL-Typ | Vertrag |
-- |---|---|---|
-- | `Value` | `bigint` | NULL beiNULLpfad oderFachfehler;Translate-AusgabeLatin1_General_100_BIN2 |
-- | `ErrorCode` | `int` | NOT NULL;logischerCode gemäßFehlerabschnitt |
--
-- Genau eine relationale Zeile,auch imNULL-/Fehlerpfad. Keine ResultTable,OUTPUT- oderHilfeparameter. ErrorCode ist kein SQL-Returncode.
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
-- Echte Inline-TVF: Konfigurationsfehler logisch priorisieren, sichere Operanden auch für vorgezogene Optimizer-Auswertung bilden. Explizite Big-endian-Zweierkomplementbytes, kein impliziter numeric-to-binary-Vertrag. Hashframe V1: Domain8,Context8,MappingVersion4,Seed8,Min8,Max8,KeyLength4,Key und Attempt4. SHA2_256; erste8Digestbytes explizit als unsigned64 in decimal(38,0) interpretieren. Bis128 Kandidaten in Attemptreihenfolge0..127; akzeptieren wenn Candidate<2^64-(2^64 modulo Span), dann Min+Candidate modulo Span. Span=Max-Min+1 in decimal erlaubt den ganzen bigint-Bereich. Nach128 Verwerfungen Code5, kein unbeschränkter Retry. Keine Uniqueness-/Kryptografie-/Privacy-Zusage. Kontext,Version,Seed,Grenzen und Keybytes binden das Mapping; Änderung muss nicht jeden Einzelwert ändern.
--
-- ## Fehlerbehandlung
--
-- Logische Priorität: KeyNULL0/ValueNULL; Version1,Seed2,Grenzen3,Keybreite4,Domain/Context6; ansonsten nach128 nichtakzeptierten Kandidaten5. Keine fachliche Exception; ValueNULL beiFehler. Ursprüngliche SQL-Binder-/Engine-/Ressourcenfehler bleiben sichtbar; keine automatische Wiederholung.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter aktueller Vertrag; keine neue native Hilfe-/Unicode-/Minimalrechte-/Callerzustands-/Installer-/Mapping-/Spatialabnahme. Historische Nachweise bleiben an ihre Artefakte gebunden. Ausschließlich für synthetische Datenzwecke; keine Anonymisierung, Eindeutigkeit, Kryptografie, Secretverwaltung oder Privacygarantie. Wiederholbarkeit verlangt denselben expliziten Kontext und bei Lookup denselben geordneten Pool. LookupVersion wird nicht automatisch gegen Drift geprüft. Keine pauschale bitweise Gleichheitszusage für Spatial-/Floatwerte zwischen Plattformen. Keine Installations- oder Rechteattestation. Reale Keys, Inputdaten und Runtimebefunde privat halten.
-- OBJECT_USAGE_SKILL:END
AS
RETURN
(
    WITH Configuration AS
    (
        SELECT ConfigurationError = CONVERT(int, CASE
            WHEN @Key IS NULL THEN 0
            WHEN @MappingVersion IS NULL OR @MappingVersion <= 0 THEN 1
            WHEN @Seed IS NULL THEN 2
            WHEN @Min IS NULL OR @Max IS NULL OR @Min > @Max THEN 3
            WHEN DATALENGTH(@Key) = 0 OR DATALENGTH(@Key) > 8000 THEN 4
            WHEN @Domain IS NULL OR @Context IS NULL THEN 6
            ELSE 0 END)
    ), SafeConfiguration AS
    (
            -- Sichere Operanden auch bei Optimizer-Auswertung vor Filter/CASE:
            -- kein Nullnenner und kein außerhalb bigint liegender Cast.
        SELECT configuration.ConfigurationError
            , Span = CONVERT(decimal(38,0), CASE
                WHEN configuration.ConfigurationError = 0 AND @Key IS NOT NULL
                    THEN CONVERT(decimal(38,0), @Max) - CONVERT(decimal(38,0), @Min) + 1
                ELSE CONVERT(decimal(38,0), 1) END)
            , SafeMin = CONVERT(decimal(38,0), CASE
                WHEN configuration.ConfigurationError = 0 AND @Key IS NOT NULL THEN @Min ELSE 0 END)
            , Frame = CONVERT(varbinary(max), ISNULL(@Domain, 0x0000000000000000))
                + contextBytes.Bytes + SUBSTRING(versionBytes.Bytes, 5, 4)
                + seedBytes.Bytes + minBytes.Bytes + maxBytes.Bytes
                + SUBSTRING(lengthBytes.Bytes, 5, 4)
                + CASE WHEN configuration.ConfigurationError = 0 AND @Key IS NOT NULL THEN @Key ELSE CONVERT(varbinary(max), 0x00) END
        FROM Configuration AS configuration
        CROSS APPLY [toolbelt_pseudonymization].[TVF_DeterministicIntegerBytes](ISNULL(@Context, 0)) AS contextBytes
        CROSS APPLY [toolbelt_pseudonymization].[TVF_DeterministicIntegerBytes](ISNULL(@MappingVersion, 0)) AS versionBytes
        CROSS APPLY [toolbelt_pseudonymization].[TVF_DeterministicIntegerBytes](ISNULL(@Seed, 0)) AS seedBytes
        CROSS APPLY [toolbelt_pseudonymization].[TVF_DeterministicIntegerBytes](ISNULL(@Min, 0)) AS minBytes
        CROSS APPLY [toolbelt_pseudonymization].[TVF_DeterministicIntegerBytes](ISNULL(@Max, 0)) AS maxBytes
        CROSS APPLY [toolbelt_pseudonymization].[TVF_DeterministicIntegerBytes]
            (CASE WHEN configuration.ConfigurationError = 0 AND @Key IS NOT NULL THEN DATALENGTH(@Key) ELSE 1 END) AS lengthBytes
    ), Limits AS
    (
        SELECT safe.ConfigurationError, safe.Span, safe.SafeMin, safe.Frame
            -- U = 2^64. Modulo vermeidet gerundete Division bei großen Spans.
            , AcceptanceLimit = CONVERT(decimal(38,0), 18446744073709551616)
                - CONVERT(decimal(38,0), 18446744073709551616) % safe.Span
        FROM SafeConfiguration AS safe
    )
    SELECT Value = CONVERT(bigint, CASE
            WHEN limits.ConfigurationError = 0 AND @Key IS NOT NULL AND chosen.Candidate IS NOT NULL
                THEN limits.SafeMin + chosen.Candidate % limits.Span
            ELSE NULL END)
        , ErrorCode = ISNULL(CONVERT(int, CASE
            WHEN @Key IS NULL THEN 0
            WHEN limits.ConfigurationError <> 0 THEN limits.ConfigurationError
            WHEN chosen.Candidate IS NULL THEN 5
            ELSE 0 END), 5)
    FROM Limits AS limits
    OUTER APPLY
    (
        SELECT TOP (1) candidate.Candidate
        FROM (VALUES (0),(1),(2),(3),(4),(5),(6),(7)) AS highDigit(n)
        CROSS JOIN (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12),(13),(14),(15)) AS lowDigit(n)
        CROSS APPLY (SELECT Attempt = highDigit.n * 16 + lowDigit.n) AS counter
        CROSS APPLY [toolbelt_pseudonymization].[TVF_DeterministicIntegerBytes](counter.Attempt) AS attemptBytes
        CROSS APPLY (SELECT Digest = HASHBYTES('SHA2_256', limits.Frame + SUBSTRING(attemptBytes.Bytes, 5, 4))) AS hashValue
        CROSS APPLY (SELECT HexValue = CONVERT(varchar(16), SUBSTRING(hashValue.Digest, 1, 8), 2)) AS digestHex
        CROSS APPLY
        (
            -- Explizite Hexinterpretation statt nativer Binary-to-integer-Konvertierung.
            SELECT Candidate =
                   CONVERT(decimal(38,0), CHARINDEX(SUBSTRING(digestHex.HexValue, 1, 1) COLLATE Latin1_General_100_BIN2, '0123456789ABCDEF' COLLATE Latin1_General_100_BIN2) - 1) * CONVERT(decimal(38,0), 1152921504606846976)
                 + CONVERT(decimal(38,0), CHARINDEX(SUBSTRING(digestHex.HexValue, 2, 1) COLLATE Latin1_General_100_BIN2, '0123456789ABCDEF' COLLATE Latin1_General_100_BIN2) - 1) * CONVERT(decimal(38,0), 72057594037927936)
                 + CONVERT(decimal(38,0), CHARINDEX(SUBSTRING(digestHex.HexValue, 3, 1) COLLATE Latin1_General_100_BIN2, '0123456789ABCDEF' COLLATE Latin1_General_100_BIN2) - 1) * CONVERT(decimal(38,0), 4503599627370496)
                 + CONVERT(decimal(38,0), CHARINDEX(SUBSTRING(digestHex.HexValue, 4, 1) COLLATE Latin1_General_100_BIN2, '0123456789ABCDEF' COLLATE Latin1_General_100_BIN2) - 1) * CONVERT(decimal(38,0), 281474976710656)
                 + CONVERT(decimal(38,0), CHARINDEX(SUBSTRING(digestHex.HexValue, 5, 1) COLLATE Latin1_General_100_BIN2, '0123456789ABCDEF' COLLATE Latin1_General_100_BIN2) - 1) * CONVERT(decimal(38,0), 17592186044416)
                 + CONVERT(decimal(38,0), CHARINDEX(SUBSTRING(digestHex.HexValue, 6, 1) COLLATE Latin1_General_100_BIN2, '0123456789ABCDEF' COLLATE Latin1_General_100_BIN2) - 1) * CONVERT(decimal(38,0), 1099511627776)
                 + CONVERT(decimal(38,0), CHARINDEX(SUBSTRING(digestHex.HexValue, 7, 1) COLLATE Latin1_General_100_BIN2, '0123456789ABCDEF' COLLATE Latin1_General_100_BIN2) - 1) * CONVERT(decimal(38,0), 68719476736)
                 + CONVERT(decimal(38,0), CHARINDEX(SUBSTRING(digestHex.HexValue, 8, 1) COLLATE Latin1_General_100_BIN2, '0123456789ABCDEF' COLLATE Latin1_General_100_BIN2) - 1) * CONVERT(decimal(38,0), 4294967296)
                 + CONVERT(decimal(38,0), CHARINDEX(SUBSTRING(digestHex.HexValue, 9, 1) COLLATE Latin1_General_100_BIN2, '0123456789ABCDEF' COLLATE Latin1_General_100_BIN2) - 1) * CONVERT(decimal(38,0), 268435456)
                 + CONVERT(decimal(38,0), CHARINDEX(SUBSTRING(digestHex.HexValue, 10, 1) COLLATE Latin1_General_100_BIN2, '0123456789ABCDEF' COLLATE Latin1_General_100_BIN2) - 1) * CONVERT(decimal(38,0), 16777216)
                 + CONVERT(decimal(38,0), CHARINDEX(SUBSTRING(digestHex.HexValue, 11, 1) COLLATE Latin1_General_100_BIN2, '0123456789ABCDEF' COLLATE Latin1_General_100_BIN2) - 1) * CONVERT(decimal(38,0), 1048576)
                 + CONVERT(decimal(38,0), CHARINDEX(SUBSTRING(digestHex.HexValue, 12, 1) COLLATE Latin1_General_100_BIN2, '0123456789ABCDEF' COLLATE Latin1_General_100_BIN2) - 1) * CONVERT(decimal(38,0), 65536)
                 + CONVERT(decimal(38,0), CHARINDEX(SUBSTRING(digestHex.HexValue, 13, 1) COLLATE Latin1_General_100_BIN2, '0123456789ABCDEF' COLLATE Latin1_General_100_BIN2) - 1) * CONVERT(decimal(38,0), 4096)
                 + CONVERT(decimal(38,0), CHARINDEX(SUBSTRING(digestHex.HexValue, 14, 1) COLLATE Latin1_General_100_BIN2, '0123456789ABCDEF' COLLATE Latin1_General_100_BIN2) - 1) * CONVERT(decimal(38,0), 256)
                 + CONVERT(decimal(38,0), CHARINDEX(SUBSTRING(digestHex.HexValue, 15, 1) COLLATE Latin1_General_100_BIN2, '0123456789ABCDEF' COLLATE Latin1_General_100_BIN2) - 1) * CONVERT(decimal(38,0), 16)
                 + CONVERT(decimal(38,0), CHARINDEX(SUBSTRING(digestHex.HexValue, 16, 1) COLLATE Latin1_General_100_BIN2, '0123456789ABCDEF' COLLATE Latin1_General_100_BIN2) - 1) * CONVERT(decimal(38,0), 1)
        ) AS candidate
        WHERE limits.ConfigurationError = 0 AND @Key IS NOT NULL
          AND candidate.Candidate < limits.AcceptanceLimit
        ORDER BY counter.Attempt
    ) AS chosen
);
GO
