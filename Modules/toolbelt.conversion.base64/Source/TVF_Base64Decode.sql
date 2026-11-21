-- ============================================================================
-- Objekt:          toolbelt_conversion.TVF_Base64DecodeStatus
-- Zweck:           Begrenzter kanonischer Statuskern; Legacy-Wertfassade unten.
-- Parameter:       @Value varchar(max)
-- Resultset:       DecodedValue varbinary(max), Status varchar(16)
-- Vertrag:         Documentation/TVF_Base64DecodeStatus.md
-- Versionen:       SQL Server 2019/2022/2025; Windows/Linux
-- Rechte:          SELECT/REFERENCES; keine zusätzlichen Rechte oder Grants.
-- Performance:     MSTVF mit Vorabgrenzen; keine Inline-/Parallelitätszusage.
-- Grenzen:         Freigegebener Vertrag SECURITY_HARDENING_2026_10.md.
-- ============================================================================
CREATE OR ALTER FUNCTION [toolbelt_conversion].[TVF_Base64DecodeStatus]
(@Value varchar(max))
RETURNS @Result TABLE(DecodedValue varbinary(max) NULL,Status varchar(16) NOT NULL)
WITH SCHEMABINDING
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-toolbelt-toolbelt-conversion-tvf-base64decodestatus"
-- description: "Genau eine Zeile: OK, SQL_NULL, INVALID oder LIMIT. Rohtextprüfung vor REPLACE, berechnete Ergebnisgröße vor XML. Standard-/URL-Alphabet und definierter Whitespace bleiben. Die bisherige TVF/SVF behält Syntaxfehler unterhalb der Grenzen und liefert bei LIMIT NULL."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.conversion.base64"
-- schema_name: "toolbelt_conversion"
-- object_name: "TVF_Base64DecodeStatus"
-- object_type: "TVF"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@Value", "sql_type": "varchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "ASCII-Base64-Text (A-Z, a-z, 0-9, +, /) oder Base64URL (-, _ statt +, /); beide Alphabete werden normalisiert. Nur Space, Tab, CR und LF werden entfernt. Optionales =-Padding nur am Ende in passender Länge; ohne Padding sind Restlängen 0, 2 oder 3 modulo 4 gültig. Leer/Whitespace-only ergibt leere Bytes. Höchstens 25165824 Rohtextbytes und 16777216 Ergebnisbytes; NULL ergibt SQL_NULL/NULL, Überschreitung LIMIT/NULL. Ungültige Syntax ergibt INVALID im Statuskern, einen Konvertierungsfehler in TVF/SVF-Wertfassaden."}]
-- source_paths: ["Modules/toolbelt.conversion.base64/Source/TVF_Base64Decode.sql"]
-- review_status: "verified"
-- source_module_version: "1.1.0"
-- ---
--
-- # TVF_Base64DecodeStatus
--
-- ## Zweck und Einsatzfälle
--
-- Genau eine Zeile: OK, SQL_NULL, INVALID oder LIMIT. Rohtextprüfung vor REPLACE, berechnete Ergebnisgröße vor XML. Standard-/URL-Alphabet und definierter Whitespace bleiben. Die bisherige TVF/SVF behält Syntaxfehler unterhalb der Grenzen und liefert bei LIMIT NULL. Für APPLY-basierte Verarbeitung mit expliziter Ergebniszeile.
--
-- ## Voraussetzungen
--
-- SQL Server 2019/2022/2025, Windows/Linux, CL150/160/170; Base64-Modul installiert. Reiner T-SQL/XML-Provider ohne CLR oder Netzwerk. Funktionsargumente positionsbezogen angeben; bei deklariertem Default das Schlüsselwort DEFAULT oder den gewünschten Wert übergeben.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Vertrag |
-- |---|---|---|---|
-- | `@Value` | `varchar(max)` | `kein Default` | ASCII-Base64-Text (A-Z, a-z, 0-9, +, /) oder Base64URL (-, _ statt +, /); beide Alphabete werden normalisiert. Nur Space, Tab, CR und LF werden entfernt. Optionales =-Padding nur am Ende in passender Länge; ohne Padding sind Restlängen 0, 2 oder 3 modulo 4 gültig. Leer/Whitespace-only ergibt leere Bytes. Höchstens 25165824 Rohtextbytes und 16777216 Ergebnisbytes; NULL ergibt SQL_NULL/NULL, Überschreitung LIMIT/NULL. Ungültige Syntax ergibt INVALID im Statuskern, einen Konvertierungsfehler in TVF/SVF-Wertfassaden. |
--
-- ## Ergebnisse
--
-- Genau eine Zeile mit DecodedValue varbinary(max) NULL und Status varchar(16) NOT NULL. Taxativ SQL_NULL bei NULL-Eingabe, LIMIT bei Überschreitung einer Größenprüfung, INVALID bei ungültigen Zeichen/Längen/Paddingstrukturen und OK bei erfolgreicher Decodierung einschließlich leerer Eingabe. Bei SQL_NULL/LIMIT/INVALID ist DecodedValue NULL.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- SELECT * FROM toolbelt_conversion.TVF_Base64DecodeStatus('yv7K_g');
-- -- 0xCAFECAFE, Status=OK
-- ```
--
-- ## Rechte
--
-- Vorhandenes SELECT für SELECT-Aufrufe; REFERENCES für entsprechende Referenzverwendungen. Keine Rechtevergabe oder Identitätsänderung. Cross-Database-Mapping und Berechtigungen bleiben erforderlich.
--
-- ## Ressourcenbedarf
--
-- Vor jeder Normalisierung höchstens 25165824 Original-Eingabebytes einschließlich später entfernter Leerzeichen. Der Statuskern materialisiert normalisierten Text einmal und prüft vor XML-Decodierung die erwartete Ausgabe gegen 16777216 Bytes. Mehrere lineare Stringoperationen und bis zu 16 MiB Ausgabe; kein Streaming. Keine pauschale Inline-/Parallelitäts- oder Laufzeitgarantie; skalare Wrapper führen eine weitere Funktionsabfrage aus.
--
-- ## Nebenwirkungen
--
-- Keine persistenten Daten-, Datei-, Netzwerk-, Trust- oder Konfigurationsänderungen. Der Statuskern befüllt ausschließlich seine lokale Rückgabetabelle.
--
-- ## Fehlerbehandlung
--
-- Im Statuskern gilt die Reihenfolge NULL, Original-Eingabelimit, Formatprüfung, erwartetes Ausgabelimit, XML-Decodierung. Wertfassaden erzeugen bei Status INVALID absichtlich einen Engine-Konvertierungsfehler. SQL_NULL und LIMIT werden dort auf NULL abgebildet; nur die Statusfunktion unterscheidet die Gründe. Typbindung, Ressourcenmangel und unerwartete Engine-/XML-Fehler bleiben Fehler; kein Retry.
--
-- ## Aussagegrenzen
--
-- Akzeptiert ASCII-Zeichen aus Standard- und URL-safe-Alphabet; Die Zeichen `-` und `_` werden vor der binären Alphabetprüfung in `+` beziehungsweise `/` umgewandelt, auch bei gemischtem Alphabet. Nur Space (32), Tab (9), CR (13) und LF (10) werden ignoriert. Fehlendes Padding wird bei Restlängen 2/3 ergänzt; Restlänge 1 ist INVALID. Vorhandenes Padding muss aus genau einem oder zwei terminalen = bestehen und zur Viererblocklänge passen. Keine allgemeine Unicode-Whitespace-Bereinigung und keine Zusage einer Prüfung kanonischer Paddingbits über die tatsächlichen Strukturguards und den XML-Konverter hinaus. Keine Installations-, Rechte- oder Sicherheitsattestation durch diese Beschreibung.
-- OBJECT_USAGE_SKILL:END
AS
BEGIN
    /* DDL-Hilfe: Decodiert Base64/Base64URL und meldet den festen Status.
       Parameter: @Value varchar(max), NULL erlaubt; Space, Tab, CR und LF werden
       ignoriert. Eingabe höchstens 25165824 Bytes, Ergebnis höchstens 16777216.
       Ergebnis: genau eine Zeile (DecodedValue varbinary(max), Status varchar(16));
       Status ist SQL_NULL, LIMIT, INVALID oder OK. Für den Aufruf ist SELECT erforderlich.
       Beispiel: SELECT * FROM toolbelt_conversion.TVF_Base64DecodeStatus('yv7K_g');
       Erwartet: DecodedValue=0xCAFECAFE, Status='OK'. */
    IF @Value IS NULL BEGIN INSERT @Result VALUES(NULL,'SQL_NULL'); RETURN; END;
    IF DATALENGTH(@Value)>25165824 BEGIN INSERT @Result VALUES(NULL,'LIMIT'); RETURN; END;
    DECLARE @Canonical varchar(max),@InvalidFormat bit=0,@Expected bigint,@Decoded varbinary(max),
        @Normalized varchar(max),@Length bigint,@FirstPadding bigint,@PaddingCount bigint,@LengthRemainder bigint;
    -- Normalisierung einmal materialisieren; CTE-Expansion scannte große
    -- gültige Inputs mehrfach. Die binäre ASCII-Prüfung nutzt denselben Stand.
    SET @Normalized=REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@Value,'-','+'),'_','/'),CHAR(32),''),CHAR(9),''),CHAR(13),''),CHAR(10),'');
    SET @Length=DATALENGTH(@Normalized);
    SET @FirstPadding=NULLIF(CHARINDEX('=',@Normalized COLLATE Latin1_General_100_BIN2),0);
    SET @PaddingCount=CASE WHEN @FirstPadding IS NULL THEN 0 ELSE @Length-@FirstPadding+1 END;
    SET @LengthRemainder=COALESCE(@FirstPadding-1,@Length)%4;
    IF @Normalized COLLATE Latin1_General_100_BIN2 LIKE '%[^A-Za-z0-9+/=]%'
        SET @InvalidFormat=1;
    IF (@FirstPadding IS NULL AND @LengthRemainder=1)
       OR (@FirstPadding IS NOT NULL AND (@PaddingCount NOT IN(1,2)
           OR DATALENGTH(REPLACE(SUBSTRING(@Normalized,@FirstPadding,@PaddingCount),'=',''))<>0
           OR @Length%4<>0 OR (@PaddingCount=1 AND @LengthRemainder<>3) OR (@PaddingCount=2 AND @LengthRemainder<>2)))
        SET @InvalidFormat=1;
    SET @Canonical=CASE WHEN @FirstPadding IS NULL AND @LengthRemainder=2 THEN @Normalized+'=='
                        WHEN @FirstPadding IS NULL AND @LengthRemainder=3 THEN @Normalized+'=' ELSE @Normalized END;
    IF @InvalidFormat=1 BEGIN INSERT @Result VALUES(NULL,'INVALID'); RETURN; END;
    SET @Expected=(DATALENGTH(@Canonical)/4)*CONVERT(bigint,3)
        -CASE WHEN RIGHT(@Canonical,2)='==' THEN 2 WHEN RIGHT(@Canonical,1)='=' THEN 1 ELSE 0 END;
    IF @Expected>16777216 BEGIN INSERT @Result VALUES(NULL,'LIMIT'); RETURN; END;
    IF DATALENGTH(@Canonical)=0 SET @Decoded=0x;
    ELSE SET @Decoded=CAST(N'' AS xml).value(N'xs:base64Binary(sql:variable("@Canonical"))',N'varbinary(max)');
    INSERT @Result VALUES(@Decoded,'OK'); RETURN;
END;
GO
-- Legacy-Wertfassade: gleicher Inputvertrag; Limitabbildung siehe Objektseite.
-- Vertrag: Documentation/TVF_Base64Decode.md
CREATE OR ALTER FUNCTION [toolbelt_conversion].[TVF_Base64Decode](@Value varchar(max))
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-toolbelt-toolbelt-conversion-tvf-base64decode"
-- description: "Decodiert Base64-Text zu Binärdaten."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.conversion.base64"
-- schema_name: "toolbelt_conversion"
-- object_name: "TVF_Base64Decode"
-- object_type: "TVF"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@Value", "sql_type": "varchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "ASCII-Base64-Text (A-Z, a-z, 0-9, +, /) oder Base64URL (-, _ statt +, /); beide Alphabete werden normalisiert. Nur Space, Tab, CR und LF werden entfernt. Optionales =-Padding nur am Ende in passender Länge; ohne Padding sind Restlängen 0, 2 oder 3 modulo 4 gültig. Leer/Whitespace-only ergibt leere Bytes. Höchstens 25165824 Rohtextbytes und 16777216 Ergebnisbytes; NULL ergibt SQL_NULL/NULL, Überschreitung LIMIT/NULL. Ungültige Syntax ergibt INVALID im Statuskern, einen Konvertierungsfehler in TVF/SVF-Wertfassaden."}]
-- source_paths: ["Modules/toolbelt.conversion.base64/Source/TVF_Base64Decode.sql"]
-- review_status: "verified"
-- source_module_version: "1.1.0"
-- ---
--
-- # TVF_Base64Decode
--
-- ## Zweck und Einsatzfälle
--
-- Decodiert Base64-Text zu Binärdaten. Für APPLY-basierte Verarbeitung mit expliziter Ergebniszeile.
--
-- ## Voraussetzungen
--
-- SQL Server 2019/2022/2025, Windows/Linux, CL150/160/170; Base64-Modul installiert. Reiner T-SQL/XML-Provider ohne CLR oder Netzwerk. Funktionsargumente positionsbezogen angeben; bei deklariertem Default das Schlüsselwort DEFAULT oder den gewünschten Wert übergeben.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Vertrag |
-- |---|---|---|---|
-- | `@Value` | `varchar(max)` | `kein Default` | ASCII-Base64-Text (A-Z, a-z, 0-9, +, /) oder Base64URL (-, _ statt +, /); beide Alphabete werden normalisiert. Nur Space, Tab, CR und LF werden entfernt. Optionales =-Padding nur am Ende in passender Länge; ohne Padding sind Restlängen 0, 2 oder 3 modulo 4 gültig. Leer/Whitespace-only ergibt leere Bytes. Höchstens 25165824 Rohtextbytes und 16777216 Ergebnisbytes; NULL ergibt SQL_NULL/NULL, Überschreitung LIMIT/NULL. Ungültige Syntax ergibt INVALID im Statuskern, einen Konvertierungsfehler in TVF/SVF-Wertfassaden. |
--
-- ## Ergebnisse
--
-- Genau eine Zeile mit DecodedValue varbinary(max). NULL bleibt NULL; Eingabe-/Ausgabelimit wird auf NULL abgebildet. Leer oder ausschließlich Space/Tab/CR/LF ergibt 0x. Ungültige Formatstruktur löst einen SQL-Engine-Konvertierungsfehler aus, statt NULL als Erfolg vorzutäuschen.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- SELECT * FROM toolbelt_conversion.TVF_Base64Decode('yv7K_g');
-- -- 0xCAFECAFE
-- ```
--
-- ## Rechte
--
-- Vorhandenes SELECT für SELECT-Aufrufe; REFERENCES für entsprechende Referenzverwendungen. Keine Rechtevergabe oder Identitätsänderung. Cross-Database-Mapping und Berechtigungen bleiben erforderlich.
--
-- ## Ressourcenbedarf
--
-- Vor jeder Normalisierung höchstens 25165824 Original-Eingabebytes einschließlich später entfernter Leerzeichen. Der Statuskern materialisiert normalisierten Text einmal und prüft vor XML-Decodierung die erwartete Ausgabe gegen 16777216 Bytes. Mehrere lineare Stringoperationen und bis zu 16 MiB Ausgabe; kein Streaming. Keine pauschale Inline-/Parallelitäts- oder Laufzeitgarantie; skalare Wrapper führen eine weitere Funktionsabfrage aus.
--
-- ## Nebenwirkungen
--
-- Keine persistenten Daten-, Datei-, Netzwerk-, Trust- oder Konfigurationsänderungen. Der Statuskern befüllt ausschließlich seine lokale Rückgabetabelle.
--
-- ## Fehlerbehandlung
--
-- Im Statuskern gilt die Reihenfolge NULL, Original-Eingabelimit, Formatprüfung, erwartetes Ausgabelimit, XML-Decodierung. Wertfassaden erzeugen bei Status INVALID absichtlich einen Engine-Konvertierungsfehler. SQL_NULL und LIMIT werden dort auf NULL abgebildet; nur die Statusfunktion unterscheidet die Gründe. Typbindung, Ressourcenmangel und unerwartete Engine-/XML-Fehler bleiben Fehler; kein Retry.
--
-- ## Aussagegrenzen
--
-- Akzeptiert ASCII-Zeichen aus Standard- und URL-safe-Alphabet; Die Zeichen `-` und `_` werden vor der binären Alphabetprüfung in `+` beziehungsweise `/` umgewandelt, auch bei gemischtem Alphabet. Nur Space (32), Tab (9), CR (13) und LF (10) werden ignoriert. Fehlendes Padding wird bei Restlängen 2/3 ergänzt; Restlänge 1 ist INVALID. Vorhandenes Padding muss aus genau einem oder zwei terminalen = bestehen und zur Viererblocklänge passen. Keine allgemeine Unicode-Whitespace-Bereinigung und keine Zusage einer Prüfung kanonischer Paddingbits über die tatsächlichen Strukturguards und den XML-Konverter hinaus. Keine Installations-, Rechte- oder Sicherheitsattestation durch diese Beschreibung.
-- OBJECT_USAGE_SKILL:END
RETURNS TABLE AS RETURN
/* DDL-Hilfe: Decodiert eine Base64/Base64URL-Wertzeile; ungültige Eingabe
   löst einen SQL-Engine-Konvertierungsfehler aus.
   Parameter: @Value varchar(max), NULL erlaubt; Space, Tab, CR und LF werden
   ignoriert. Eingabe höchstens 25165824 Bytes, decodierte Ausgabe höchstens 16777216.
   Ergebnis: DecodedValue varbinary(max), genau eine Zeile; bei Größen-LIMIT NULL.
   Für den Aufruf ist SELECT erforderlich.
   Beispiel: SELECT DecodedValue FROM toolbelt_conversion.TVF_Base64Decode('yv7K_g');
   Erwartet: 0xCAFECAFE. */
(SELECT DecodedValue=CASE WHEN Status='INVALID'
    THEN CONVERT(varbinary(max),CONVERT(int,LEFT('toolbelt.invalid.base64'+ISNULL(@Value,''),23)))
    ELSE DecodedValue END FROM toolbelt_conversion.TVF_Base64DecodeStatus(@Value));
GO
