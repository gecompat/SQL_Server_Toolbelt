-- ============================================================================
-- Objekt:          toolbelt_conversion.TVF_UriComponentDecodeStatus
-- Zweck:           Begrenzter kanonischer Statuskern; Legacy-Wertfassade unten.
-- Parameter:       @Value nvarchar(max)
-- Resultset:       DecodedValue nvarchar(max), IsValid bit, ValidationCode tinyint, Status varchar(16)
-- Vertrag:         Documentation/TVF_UriComponentDecodeStatus.md
-- Versionen:       SQL Server 2019/2022/2025; Windows/Linux
-- Rechte:          SELECT/REFERENCES; keine zusätzlichen Rechte oder Grants.
-- Performance:     MSTVF mit Vorabgrenzen; keine Inline-/Parallelitätszusage.
-- Grenzen:         Freigegebener Vertrag SECURITY_HARDENING_2026_10.md.
-- ============================================================================
CREATE OR ALTER FUNCTION [toolbelt_conversion].[TVF_UriComponentDecodeStatus](@Value nvarchar(max))
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-toolbelt-toolbelt-conversion-tvf-uricomponentd-ec85ccdb"
-- description: "Genau eine Zeile: OK, SQL_NULL, INVALID oder LIMIT. Strikte UTF-8-/Percent-/NUL-Regeln bleiben; bei LIMIT IsValid=0, ValidationCode=14, Wert NULL. Die Ausgabe ist durch den vor Series geprüften Eingang unter 1 MiB begrenzt. Altfassaden behalten ihre Spalten und liefern bei LIMIT NULL."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.conversion.uri-component"
-- schema_name: "toolbelt_conversion"
-- object_name: "TVF_UriComponentDecodeStatus"
-- object_type: "TVF"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@Value", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "ASCII-Text mit optionalen %HH-Triplets als UTF-8-Bytes, maximal 65536 UTF-16-Bytes. Genau eine Decodierrunde; + bleibt +, leerer Text ist gültig. Nicht-ASCII-Rohtext, fehlerhafte Triplets, ungültiges UTF-8 und decodiertes NUL sind ungültig (Codes 10..13). NULL ergibt NULL-Felder/SQL_NULL; Überschreitung Code 14/LIMIT, Wert NULL."}]
-- source_paths: ["Modules/toolbelt.conversion.uri-component/Source/TVF_UriComponentDecode.sql"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- ---
--
-- # TVF_UriComponentDecodeStatus
--
-- ## Zweck und Einsatzfälle
--
-- Genau eine Zeile: OK, SQL_NULL, INVALID oder LIMIT. Strikte UTF-8-/Percent-/NUL-Regeln bleiben; bei LIMIT IsValid=0, ValidationCode=14, Wert NULL. Die Ausgabe ist durch den vor Series geprüften Eingang unter 1 MiB begrenzt. Altfassaden behalten ihre Spalten und liefern bei LIMIT NULL.
--
-- ## Voraussetzungen
--
-- URIcomponent-Modul mit demselben kanonischen GenerateSeries-Kern. TSQL auf Windows/Linux SQL2019/2022/2025, zulässiges CL150/160/170. Keine Datei-, Netzwerk-, CLR-, Katalog- oder Trustabhängigkeit.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
-- |---|---|---|---|---|
-- | `@Value` | `nvarchar(max)` | kein Default | Input | ASCII-Text mit optionalen %HH-Triplets als UTF-8-Bytes, maximal 65536 UTF-16-Bytes. Genau eine Decodierrunde; + bleibt +, leerer Text ist gültig. Nicht-ASCII-Rohtext, fehlerhafte Triplets, ungültiges UTF-8 und decodiertes NUL sind ungültig (Codes 10..13). NULL ergibt NULL-Felder/SQL_NULL; Überschreitung Code 14/LIMIT, Wert NULL. |
--
-- Alle Positionen beim SELECT-Aufruf angeben; DEFAULT verwendet einen deklarierten Funktionsdefault, NULL bleibt ein eigener Wert. SQL-Typbindung und eine mögliche Kürzung auf feste Parameterbreite liegen vor dem Funktionskörper.
--
-- ## Ergebnisse
--
-- Genau eine Statuszeile: DecodedValue nvarchar(max) NULL,IsValid bit NULL,ValidationCode tinyint NULL,Status varchar(16) NOT NULL. OK:Wert,1,0. INVALID:NULL,0,Code10..13. LIMIT:NULL,0,14. SQL_NULL:NULL,NULL,NULL.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- SELECT * FROM toolbelt_conversion.TVF_UriComponentDecodeStatus(N'Contoso%20A%2BB');
-- SELECT * FROM toolbelt_conversion.TVF_UriComponentDecodeStatus(NCHAR(256));
-- SELECT toolbelt_conversion.SVF_UriComponentDecode(N'%F0%9F%98%80');
-- ```
--
-- ## Rechte
--
-- Vorhandenes SELECT/gegebenenfalls REFERENCES für TVFs, EXECUTE für die skalare Funktion und benötigte normale Ownershipchain/Dependencyrechte. Keine Metadatenvollsicht, Serverrechte oder Rechteerteilung aus diesem Vertrag.
--
-- ## Ressourcenbedarf
--
-- MSTVF-Statuskern mit65536UTF16-Inputbyteguard und1048576Outputbyteguard; Wertfassaden übernehmen diese Grenzen. Serien-/Validierungs-/Hex-/Binary-/Octet-/Unicode-Zwischenkopien und zusätzlicher früher ASCIIscan kosten CPU/Speicher. Kein Streaming-, Parallelitäts-, gesamter Heap-/Memorygrant- oder Wallclockvertrag. Die Outputgrenze ist ein konservativer eigener Guard, kein Nachweis eines öffentlich erreichbaren Grenzfalls.
--
-- ## Nebenwirkungen
--
-- Statuskern: NULL zuerst ->SQL_NULL, anschließend65536UTF16-Inputbytes ->LIMIT. Vor jeder Hex-/Binary-CTE-Auswertung prozedural jede physische UTF16-Einheit auf NichtASCII prüfen und gegebenenfalls10/INVALID zurückgeben. Damit kann beispielsweise Codepunkt256 nicht mehr in eine ungerade Hexdarstellung gelangen; ein späterer CASE-Status allein wäre kein CONVERT-Guard. Für übriges ASCIIinput die Prozenttriplets validieren und genau einmal zu Bytes zusammensetzen; + bleibt +, %25 wird Prozent und kein zweiter Decode folgt. Ungültiges Prozent wird nur zu sicherem Dummy00 hexgebaut, Status11 hat Vorrang vor folgendem UTF8-/NUL-Status.
--
-- UTF8-Folgen strikt anhand Lead-/Continuationranges prüfen: keine Overlongs, isolierten Fortsetzungen, Surrogateskalarwerte oder Codepunkte>10FFFF. Gültige BMP-/Supplementarywerte in ursprünglicher Reihenfolge zusammensetzen; vollständige Byteabdeckung verlangen. Decodiertes NUL wird13 stattFachtext. Fehlerpriorität nach frühen Guards:10NichtASCII,11Percent,12UTF8,13NUL. Physische Outputbytes zuletzt auf1048576 begrenzen. Wert-TVF delegiert einmal und liefert drei Felder; Scalarwrapper delegiert an die Wert-TVF und liefert nur DecodedValue. Keine Datenabfrage oder Mutation, keine eigene Transaktion.
--
-- ## Fehlerbehandlung
--
-- Erwartete Eingabefehler sind Status10 NichtASCIIrohtext,11Percenttriplet,12UTF8,13NUL,14Limit; kein Teiltext. SQLNULL ist kein INVALID. Wertfassaden behalten ihre beschriebenen Informationsverluste. Typbindungs-, Ressourcen- und unerwartete Enginefehler werden nicht pauschal abgefangen.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter aktueller Vertrag. Die ausdrücklich deklarierten funktionalen Korrekturen in diesem Modul benötigen neue native Gegenproben; historische Nachweise qualifizieren nur ihre ursprünglichen Bytes. Noch kein aktuelles natives API-/SC-/UTF8-/Caller-/Gesamtinstaller-PASS. Keine Installations-/Rechteattestation. Nur synthetische Beispiele; reale Eingaben/Runtimeausgaben privat halten.
-- OBJECT_USAGE_SKILL:END
RETURNS @Result TABLE(DecodedValue nvarchar(max) NULL,IsValid bit NULL,ValidationCode tinyint NULL,Status varchar(16) NOT NULL) AS
BEGIN
    IF @Value IS NULL BEGIN INSERT @Result VALUES(NULL,NULL,NULL,'SQL_NULL'); RETURN; END;
    IF DATALENGTH(@Value)>65536 BEGIN INSERT @Result VALUES(NULL,0,14,'LIMIT'); RETURN; END;
    -- Procedural return before any HexValue/BinaryData evaluation.
    -- A CASE status later in the query cannot guard an eager CONVERT.
    IF EXISTS
    (
        SELECT 1 FROM toolbelt_core.TVF_GenerateSeriesBigInt
            (1,CONVERT(bigint,DATALENGTH(@Value)/2),1) positions
        WHERE UNICODE(SUBSTRING(@Value COLLATE Latin1_General_100_BIN2,positions.Value,1))>127
    )
    BEGIN INSERT @Result VALUES(NULL,0,10,'INVALID'); RETURN; END;
    DECLARE @Output nvarchar(max),@Valid bit,@Code tinyint;
    WITH Parameters AS
    (
        SELECT InputLength = CONVERT(bigint,DATALENGTH(@Value)/2)
    ),
    Positions AS
    (
        SELECT positions.Value
        FROM Parameters AS parameters
        CROSS APPLY toolbelt_core.TVF_GenerateSeriesBigInt(1,parameters.InputLength,1) AS positions
    ),
    Validation AS
    (
        SELECT
              HasNonAscii=CONVERT(bit,MAX(CASE WHEN UNICODE(SUBSTRING(@Value COLLATE Latin1_General_100_BIN2,positions.Value,1))>127 THEN 1 ELSE 0 END))
            , HasInvalidPercent=CONVERT(bit,MAX(CASE WHEN SUBSTRING(@Value,positions.Value,1)=N'%' AND (positions.Value+2>parameters.InputLength OR SUBSTRING(@Value,positions.Value+1,1) COLLATE Latin1_General_100_BIN2 NOT LIKE N'[0-9A-Fa-f]' OR SUBSTRING(@Value,positions.Value+2,1) COLLATE Latin1_General_100_BIN2 NOT LIKE N'[0-9A-Fa-f]') THEN 1 ELSE 0 END))
        FROM Parameters AS parameters LEFT JOIN Positions AS positions ON 1=1
    ),
    Bytes AS
    (
        SELECT HexValue=STRING_AGG(CONVERT(varchar(max),CASE
          WHEN SUBSTRING(@Value,positions.Value,1)=N'%'
           AND positions.Value+2<=parameters.InputLength
           AND SUBSTRING(@Value,positions.Value+1,1) COLLATE Latin1_General_100_BIN2 LIKE N'[0-9A-Fa-f]'
           AND SUBSTRING(@Value,positions.Value+2,1) COLLATE Latin1_General_100_BIN2 LIKE N'[0-9A-Fa-f]'
              THEN CONVERT(varchar(2),SUBSTRING(@Value,positions.Value+1,2))
          WHEN SUBSTRING(@Value,positions.Value,1)=N'%' THEN '00'
          ELSE SUBSTRING('0123456789ABCDEF',UNICODE(SUBSTRING(@Value,positions.Value,1))/16+1,1)+SUBSTRING('0123456789ABCDEF',UNICODE(SUBSTRING(@Value,positions.Value,1))%16+1,1) END),'') WITHIN GROUP(ORDER BY positions.Value)
        FROM Parameters AS parameters CROSS APPLY Positions AS positions
        WHERE NOT (positions.Value>1 AND SUBSTRING(@Value,positions.Value-1,1)=N'%' AND positions.Value+1<=parameters.InputLength AND SUBSTRING(@Value,positions.Value,1) COLLATE Latin1_General_100_BIN2 LIKE N'[0-9A-Fa-f]' AND SUBSTRING(@Value,positions.Value+1,1) COLLATE Latin1_General_100_BIN2 LIKE N'[0-9A-Fa-f]')
          AND NOT (positions.Value>2 AND SUBSTRING(@Value,positions.Value-2,1)=N'%' AND SUBSTRING(@Value,positions.Value-1,1) COLLATE Latin1_General_100_BIN2 LIKE N'[0-9A-Fa-f]' AND SUBSTRING(@Value,positions.Value,1) COLLATE Latin1_General_100_BIN2 LIKE N'[0-9A-Fa-f]')
    ),
    BinaryData AS
    (
        SELECT
              BinaryValue=CONVERT(varbinary(max),CONCAT('0x',COALESCE(bytes.HexValue,'')),1)
            , ByteLength=CONVERT(bigint,DATALENGTH(CONVERT(varbinary(max),CONCAT('0x',COALESCE(bytes.HexValue,'')),1)))
        FROM Bytes AS bytes
    ),
    Octets AS
    (
        SELECT
              Position=positions.Value
            , data.ByteLength
            , FirstByte=CONVERT(int,SUBSTRING(data.BinaryValue,positions.Value,1))
            , SecondByte=CONVERT(int,SUBSTRING(data.BinaryValue,positions.Value+1,1))
            , ThirdByte=CONVERT(int,SUBSTRING(data.BinaryValue,positions.Value+2,1))
            , FourthByte=CONVERT(int,SUBSTRING(data.BinaryValue,positions.Value+3,1))
        FROM BinaryData AS data
        CROSS APPLY toolbelt_core.TVF_GenerateSeriesBigInt(1,data.ByteLength,1) AS positions
    ),
    ValidSequences AS
    (
        SELECT
              StartPosition=octets.Position
            , SequenceLength=CONVERT(tinyint,CASE
                WHEN octets.FirstByte<=127 THEN 1
                WHEN octets.FirstByte<=223 THEN 2
                WHEN octets.FirstByte<=239 THEN 3
                ELSE 4 END)
            , CodePoint=CONVERT(int,CASE
                WHEN octets.FirstByte<=127 THEN octets.FirstByte
                WHEN octets.FirstByte<=223 THEN
                    (octets.FirstByte-192)*64+(octets.SecondByte-128)
                WHEN octets.FirstByte<=239 THEN
                    (octets.FirstByte-224)*4096
                    +(octets.SecondByte-128)*64
                    +(octets.ThirdByte-128)
                ELSE
                    (octets.FirstByte-240)*262144
                    +(octets.SecondByte-128)*4096
                    +(octets.ThirdByte-128)*64
                    +(octets.FourthByte-128) END)
        FROM Octets AS octets
        WHERE octets.FirstByte<=127
           OR
              (
                  octets.FirstByte BETWEEN 194 AND 223
                  AND octets.Position+1<=octets.ByteLength
                  AND octets.SecondByte BETWEEN 128 AND 191
              )
           OR
              (
                  octets.FirstByte BETWEEN 224 AND 239
                  AND octets.Position+2<=octets.ByteLength
                  AND octets.ThirdByte BETWEEN 128 AND 191
                  AND
                  (
                      (octets.FirstByte=224 AND octets.SecondByte BETWEEN 160 AND 191)
                      OR (octets.FirstByte BETWEEN 225 AND 236 AND octets.SecondByte BETWEEN 128 AND 191)
                      OR (octets.FirstByte=237 AND octets.SecondByte BETWEEN 128 AND 159)
                      OR (octets.FirstByte BETWEEN 238 AND 239 AND octets.SecondByte BETWEEN 128 AND 191)
                  )
              )
           OR
              (
                  octets.FirstByte BETWEEN 240 AND 244
                  AND octets.Position+3<=octets.ByteLength
                  AND octets.ThirdByte BETWEEN 128 AND 191
                  AND octets.FourthByte BETWEEN 128 AND 191
                  AND
                  (
                      (octets.FirstByte=240 AND octets.SecondByte BETWEEN 144 AND 191)
                      OR (octets.FirstByte BETWEEN 241 AND 243 AND octets.SecondByte BETWEEN 128 AND 191)
                      OR (octets.FirstByte=244 AND octets.SecondByte BETWEEN 128 AND 143)
                  )
              )
    ),
    Decoded AS
    (
        SELECT
              TextValue=CONVERT(nvarchar(max),COALESCE
              (
                  STRING_AGG
                  (
                      CASE
                          WHEN sequences.CodePoint<=65535
                              THEN CONVERT(nvarchar(max),NCHAR(sequences.CodePoint))
                          ELSE
                              CONVERT(nvarchar(max),NCHAR(55296+(sequences.CodePoint-65536)/1024))
                              +CONVERT(nvarchar(max),NCHAR(56320+(sequences.CodePoint-65536)%1024))
                      END,
                      N''
                  ) WITHIN GROUP(ORDER BY sequences.StartPosition),
                  N''
              ))
            , IsUtf8=CONVERT(bit,CASE
                WHEN COALESCE(SUM(CONVERT(bigint,sequences.SequenceLength)),0)=data.ByteLength
                    THEN 1 ELSE 0 END)
            , HasNul=CONVERT(bit,COALESCE(MAX(CASE WHEN sequences.CodePoint=0 THEN 1 ELSE 0 END),0))
        FROM BinaryData AS data
        LEFT JOIN ValidSequences AS sequences ON 1=1
        GROUP BY data.ByteLength
    )
    SELECT
          @Output=CONVERT(nvarchar(max),CASE WHEN @Value IS NULL OR validation.HasNonAscii=1 OR validation.HasInvalidPercent=1 OR decoded.IsUtf8=0 OR decoded.HasNul=1 THEN NULL ELSE decoded.TextValue END)
        , @Valid=CONVERT(bit,CASE WHEN @Value IS NULL THEN NULL WHEN validation.HasNonAscii=1 OR validation.HasInvalidPercent=1 OR decoded.IsUtf8=0 OR decoded.HasNul=1 THEN 0 ELSE 1 END)
        , @Code=CONVERT(tinyint,CASE WHEN @Value IS NULL THEN NULL WHEN validation.HasNonAscii=1 THEN 10 WHEN validation.HasInvalidPercent=1 THEN 11 WHEN decoded.IsUtf8=0 THEN 12 WHEN decoded.HasNul=1 THEN 13 ELSE 0 END)
    FROM Validation AS validation CROSS JOIN Decoded AS decoded;
    IF DATALENGTH(@Output)>1048576 INSERT @Result VALUES(NULL,0,14,'LIMIT'); ELSE INSERT @Result VALUES(@Output,@Valid,@Code,CASE WHEN @Valid=1 THEN 'OK' ELSE 'INVALID' END);
    RETURN;
END;
GO
-- Legacy-Wertfassade: gleicher Inputvertrag; Limitabbildung siehe Objektseite.
-- Vertrag: Documentation/TVF_UriComponentDecode.md
CREATE OR ALTER FUNCTION [toolbelt_conversion].[TVF_UriComponentDecode](@Value nvarchar(max))
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-toolbelt-toolbelt-conversion-tvf-uricomponentdecode"
-- description: "Decodiert eine Runde von Prozent-Escapes und prüft die UTF-8-Sequenz."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.conversion.uri-component"
-- schema_name: "toolbelt_conversion"
-- object_name: "TVF_UriComponentDecode"
-- object_type: "TVF"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@Value", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "ASCII-Text mit optionalen %HH-Triplets als UTF-8-Bytes, maximal 65536 UTF-16-Bytes. Genau eine Decodierrunde; + bleibt +, leerer Text ist gültig. Nicht-ASCII-Rohtext, fehlerhafte Triplets, ungültiges UTF-8 und decodiertes NUL sind ungültig (Codes 10..13). NULL ergibt NULL-Felder/SQL_NULL; Überschreitung Code 14/LIMIT, Wert NULL."}]
-- source_paths: ["Modules/toolbelt.conversion.uri-component/Source/TVF_UriComponentDecode.sql"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- ---
--
-- # TVF_UriComponentDecode
--
-- ## Zweck und Einsatzfälle
--
-- Decodiert eine Runde von Prozent-Escapes und prüft die UTF-8-Sequenz.
--
-- ## Voraussetzungen
--
-- URIcomponent-Modul mit demselben kanonischen GenerateSeries-Kern. TSQL auf Windows/Linux SQL2019/2022/2025, zulässiges CL150/160/170. Keine Datei-, Netzwerk-, CLR-, Katalog- oder Trustabhängigkeit.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
-- |---|---|---|---|---|
-- | `@Value` | `nvarchar(max)` | kein Default | Input | ASCII-Text mit optionalen %HH-Triplets als UTF-8-Bytes, maximal 65536 UTF-16-Bytes. Genau eine Decodierrunde; + bleibt +, leerer Text ist gültig. Nicht-ASCII-Rohtext, fehlerhafte Triplets, ungültiges UTF-8 und decodiertes NUL sind ungültig (Codes 10..13). NULL ergibt NULL-Felder/SQL_NULL; Überschreitung Code 14/LIMIT, Wert NULL. |
--
-- Alle Positionen beim SELECT-Aufruf angeben; DEFAULT verwendet einen deklarierten Funktionsdefault, NULL bleibt ein eigener Wert. SQL-Typbindung und eine mögliche Kürzung auf feste Parameterbreite liegen vor dem Funktionskörper.
--
-- ## Ergebnisse
--
-- Genau eine Zeile mit DecodedValue nvarchar(max) NULL,IsValid bit NULL,ValidationCode tinyint NULL; die Statusspalte entfällt, übrige Werte bleiben exakt vom Statuskern erhalten.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- SELECT * FROM toolbelt_conversion.TVF_UriComponentDecodeStatus(N'Contoso%20A%2BB');
-- SELECT * FROM toolbelt_conversion.TVF_UriComponentDecodeStatus(NCHAR(256));
-- SELECT toolbelt_conversion.SVF_UriComponentDecode(N'%F0%9F%98%80');
-- ```
--
-- ## Rechte
--
-- Vorhandenes SELECT/gegebenenfalls REFERENCES für TVFs, EXECUTE für die skalare Funktion und benötigte normale Ownershipchain/Dependencyrechte. Keine Metadatenvollsicht, Serverrechte oder Rechteerteilung aus diesem Vertrag.
--
-- ## Ressourcenbedarf
--
-- MSTVF-Statuskern mit65536UTF16-Inputbyteguard und1048576Outputbyteguard; Wertfassaden übernehmen diese Grenzen. Serien-/Validierungs-/Hex-/Binary-/Octet-/Unicode-Zwischenkopien und zusätzlicher früher ASCIIscan kosten CPU/Speicher. Kein Streaming-, Parallelitäts-, gesamter Heap-/Memorygrant- oder Wallclockvertrag. Die Outputgrenze ist ein konservativer eigener Guard, kein Nachweis eines öffentlich erreichbaren Grenzfalls.
--
-- ## Nebenwirkungen
--
-- Statuskern: NULL zuerst ->SQL_NULL, anschließend65536UTF16-Inputbytes ->LIMIT. Vor jeder Hex-/Binary-CTE-Auswertung prozedural jede physische UTF16-Einheit auf NichtASCII prüfen und gegebenenfalls10/INVALID zurückgeben. Damit kann beispielsweise Codepunkt256 nicht mehr in eine ungerade Hexdarstellung gelangen; ein späterer CASE-Status allein wäre kein CONVERT-Guard. Für übriges ASCIIinput die Prozenttriplets validieren und genau einmal zu Bytes zusammensetzen; + bleibt +, %25 wird Prozent und kein zweiter Decode folgt. Ungültiges Prozent wird nur zu sicherem Dummy00 hexgebaut, Status11 hat Vorrang vor folgendem UTF8-/NUL-Status.
--
-- UTF8-Folgen strikt anhand Lead-/Continuationranges prüfen: keine Overlongs, isolierten Fortsetzungen, Surrogateskalarwerte oder Codepunkte>10FFFF. Gültige BMP-/Supplementarywerte in ursprünglicher Reihenfolge zusammensetzen; vollständige Byteabdeckung verlangen. Decodiertes NUL wird13 stattFachtext. Fehlerpriorität nach frühen Guards:10NichtASCII,11Percent,12UTF8,13NUL. Physische Outputbytes zuletzt auf1048576 begrenzen. Wert-TVF delegiert einmal und liefert drei Felder; Scalarwrapper delegiert an die Wert-TVF und liefert nur DecodedValue. Keine Datenabfrage oder Mutation, keine eigene Transaktion.
--
-- ## Fehlerbehandlung
--
-- Erwartete Eingabefehler sind Status10 NichtASCIIrohtext,11Percenttriplet,12UTF8,13NUL,14Limit; kein Teiltext. SQLNULL ist kein INVALID. Wertfassaden behalten ihre beschriebenen Informationsverluste. Typbindungs-, Ressourcen- und unerwartete Enginefehler werden nicht pauschal abgefangen.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter aktueller Vertrag. Die ausdrücklich deklarierten funktionalen Korrekturen in diesem Modul benötigen neue native Gegenproben; historische Nachweise qualifizieren nur ihre ursprünglichen Bytes. Noch kein aktuelles natives API-/SC-/UTF8-/Caller-/Gesamtinstaller-PASS. Keine Installations-/Rechteattestation. Nur synthetische Beispiele; reale Eingaben/Runtimeausgaben privat halten.
-- OBJECT_USAGE_SKILL:END
RETURNS TABLE AS RETURN
(SELECT DecodedValue,IsValid,ValidationCode FROM toolbelt_conversion.TVF_UriComponentDecodeStatus(@Value));
GO
