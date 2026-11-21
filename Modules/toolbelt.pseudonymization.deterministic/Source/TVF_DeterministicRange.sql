-- ============================================================================
-- Objekt:          toolbelt_pseudonymization.TVF_DeterministicRange
-- Typ:             Inline Table-valued Function
-- Plattformen:     Windows und Linux, portabler T-SQL-Kern.
-- Vertrag:         Documentation/TVF_DeterministicRange.md
-- Zweck:           Versionsstabile Auswahl im geschlossenen bigint-Bereich.
-- Parameter:       Key varbinary(max), MappingVersion int, Seed bigint = 0,
--                  Min bigint, Max bigint.
-- Resultset:       Value bigint NULL, ErrorCode int NOT NULL.
-- Dependencies:    interne Inline-TVF TVF_DeterministicRangeCore.
-- Rechte:          SELECT auf öffentlicher TVF; keine Rechteausweitung.
-- Versionen:       SQL Server 2019/2022/2025, Windows und Linux.
-- Performance:     Relational inline; maximal 128 SHA256-Kandidaten je Key.
-- Collation:       Kein Textvergleich, keine Normalisierung oder Codepage.
-- Fehlerverhalten: NULL-Key zuerst; Fehlercode ohne Value, keine Exceptions.
-- Einschränkungen: Keine Eindeutigkeit, Kryptografie- oder Privacy-Garantie.
-- ============================================================================
CREATE OR ALTER FUNCTION [toolbelt_pseudonymization].[TVF_DeterministicRange]
(
      @Key            varbinary(max)
    , @MappingVersion int
    , @Seed           bigint = 0
    , @Min            bigint
    , @Max            bigint
)
RETURNS TABLE
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-tvf-deterministicrange"
-- description: "Ordnet einen Schlüssel deterministisch einem ganzzahligen Zielbereich zu."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.pseudonymization.deterministic"
-- schema_name: "toolbelt_pseudonymization"
-- object_name: "TVF_DeterministicRange"
-- object_type: "TVF"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@Key", "sql_type": "varbinary(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Binärer Entity-Key varbinary(max) mit 1..8000 Bytes, z.B. 0x010203; keine automatische Textkodierung/Normalisierung. NULL ist ein früher NULL-Ergebnispfad mit ErrorCode 0; leer/größer ergibt Code 4. Gleichheit meint dieselben Bytes, nicht einen Darstellungsstring. Kein Geheimschlüsselvertrag."}, {"name": "@MappingVersion", "sql_type": "int", "sql_default": null, "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Positive Ganzzahl 1..2147483647 als explizite Mappingkontextversion. NULL/0/negativ ergibt ErrorCode 1, sofern kein früher NULL-Eingabepfad greift. Keine automatische aktuelle Version; Änderung verändert das Mapping, garantiert aber nicht jeden Einzelwert."}, {"name": "@Seed", "sql_type": "bigint", "sql_default": "0", "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Jeder nicht-NULL-bigint (-9223372036854775808..9223372036854775807), Default 0. Deterministischer Variantenkontext, kein Zufall je Aufruf und kein Secret. NULL ergibt Code 2 nach dem frühen NULL-Eingabepfad."}, {"name": "@Min", "sql_type": "bigint", "sql_default": null, "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Inklusive Untergrenze im gesamten bigint-Bereich; muss nicht NULL und <=Max sein. Min=Max ist gültig und liefert diesen Wert. NULL/vertauschte Grenzen ergeben Code 3 nach früheren NULL-/Konfigurationsprüfungen."}, {"name": "@Max", "sql_type": "bigint", "sql_default": null, "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Inklusive Obergrenze im gesamten bigint-Bereich; nicht NULL und >=Min. Auch der volle vorzeichenbehaftete 64-Bit-Bereich ist zulässig; kein exklusives Ende. NULL/vertauscht ergibt Code 3."}]
-- source_paths: ["Modules/toolbelt.pseudonymization.deterministic/Source/TVF_DeterministicRange.sql", "Modules/toolbelt.pseudonymization.deterministic/Source/TVF_DeterministicIntegerBytes.sql", "Modules/toolbelt.pseudonymization.deterministic/Source/TVF_DeterministicRangeCore.sql"]
-- review_status: "verified"
-- source_module_version: "1.2.0"
-- ---
--
-- # TVF_DeterministicRange
--
-- ## Zweck und Einsatzfälle
--
-- Ordnet einen Schlüssel deterministisch einem ganzzahligen Zielbereich zu.
--
-- ## Voraussetzungen
--
-- Modul 1.2.0 mit kanonischen T-SQL-Abhängigkeiten derselben Datenbank. SQL2019/2022/2025 auf Windows/Linux mit CL150/160/170 gemäß Modulmatrix. Explizite Versionen und binäre Keys statt impliziter Textkodierung. Keine Fach- oder Systemkatalogabfrage für die Transformation erforderlich. Input- und Fehlercodes vor Weiterverwendung auswerten.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
-- |---|---|---|---|---|
-- | `@Key` | `varbinary(max)` | kein Default | Input | Binärer Entity-Key varbinary(max) mit 1..8000 Bytes, z.B. 0x010203; keine automatische Textkodierung/Normalisierung. NULL ist ein früher NULL-Ergebnispfad mit ErrorCode 0; leer/größer ergibt Code 4. Gleichheit meint dieselben Bytes, nicht einen Darstellungsstring. Kein Geheimschlüsselvertrag. |
-- | `@MappingVersion` | `int` | kein Default | Input | Positive Ganzzahl 1..2147483647 als explizite Mappingkontextversion. NULL/0/negativ ergibt ErrorCode 1, sofern kein früher NULL-Eingabepfad greift. Keine automatische aktuelle Version; Änderung verändert das Mapping, garantiert aber nicht jeden Einzelwert. |
-- | `@Seed` | `bigint` | `0` | Input | Jeder nicht-NULL-bigint (-9223372036854775808..9223372036854775807), Default 0. Deterministischer Variantenkontext, kein Zufall je Aufruf und kein Secret. NULL ergibt Code 2 nach dem frühen NULL-Eingabepfad. |
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
-- Fassade delegiert an RangeCore mit fester DomainTBXDRNG1 und Context0. Echte Inline-TVF: Konfigurationsfehler logisch priorisieren, sichere Operanden auch für vorgezogene Optimizer-Auswertung bilden. Explizite Big-endian-Zweierkomplementbytes, kein impliziter numeric-to-binary-Vertrag. Hashframe V1: Domain8,Context8,MappingVersion4,Seed8,Min8,Max8,KeyLength4,Key und Attempt4. SHA2_256; erste8Digestbytes explizit als unsigned64 in decimal(38,0) interpretieren. Bis128 Kandidaten in Attemptreihenfolge0..127; akzeptieren wenn Candidate<2^64-(2^64 modulo Span), dann Min+Candidate modulo Span. Span=Max-Min+1 in decimal erlaubt den ganzen bigint-Bereich. Nach128 Verwerfungen Code5, kein unbeschränkter Retry. Keine Uniqueness-/Kryptografie-/Privacy-Zusage. Kontext,Version,Seed,Grenzen und Keybytes binden das Mapping; Änderung muss nicht jeden Einzelwert ändern.
--
-- ## Fehlerbehandlung
--
-- Genau eine Zeile; kein fachlicher THROW: KeyNULL zuerst0/ValueNULL; dann Version1,Seed2,Grenzen3,Keybreite4,Samplingerschöpfung5. Value nur beiCode0 und nichtNULLKey. Interner Konfigurationscode6 betrifft feste Domain/Context des Kerns,nicht freie öffentliche Parameter. Ursprüngliche SQL-Binder-/Engine-/Ressourcenfehler bleiben sichtbar; keine automatische Wiederholung.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter aktueller Vertrag; keine neue native Hilfe-/Unicode-/Minimalrechte-/Callerzustands-/Installer-/Mapping-/Spatialabnahme. Historische Nachweise bleiben an ihre Artefakte gebunden. Ausschließlich für synthetische Datenzwecke; keine Anonymisierung, Eindeutigkeit, Kryptografie, Secretverwaltung oder Privacygarantie. Wiederholbarkeit verlangt denselben expliziten Kontext und bei Lookup denselben geordneten Pool. LookupVersion wird nicht automatisch gegen Drift geprüft. Keine pauschale bitweise Gleichheitszusage für Spatial-/Floatwerte zwischen Plattformen. Keine Installations- oder Rechteattestation. Reale Keys, Inputdaten und Runtimebefunde privat halten.
-- OBJECT_USAGE_SKILL:END
AS
RETURN
(
    SELECT rangeValue.Value, rangeValue.ErrorCode
    FROM [toolbelt_pseudonymization].[TVF_DeterministicRangeCore]
        (0x54425844524E4731, 0, @Key, @MappingVersion, @Seed, @Min, @Max) AS rangeValue
);
GO
