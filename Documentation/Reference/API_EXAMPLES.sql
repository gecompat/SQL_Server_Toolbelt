-- Generiert aus Repositoryquellen; Beispiele einzeln auswählen, nicht gesammelt ausführen.
-- Kein Installationsziel wird fest vorgegeben. In der gewünschten Toolbelt-Datenbank verwenden.

-- toolbelt_archive.USP_CreateZipFileFromEntries
-- Bereitet vollständiges ZIP/Entry-Binary vor und veröffentlicht über WriteBinaryFile. Datei und SQL-Ausgabe sind nicht gemeinsam atomar.
-- Voraussetzung: Windows-only mit lokalem ZIPfiles1.0.0-Profil, ZIPmemory1.4.0, Windowsfilesystem1.0.0 und ResultTable derselben Datenbank. Vorhandener aktiver Root mit AllowWrite, bestehendes Zielverzeichnis und NTFS-Rechte. Caller-Modus verlangt Windowsauthentifizierung. ServiceAccount nur bei expliziter Wahl mit toolbelt_filesystem_service_account und Root-AllowServiceAccount. Keine zentrale Cross-DB- oder Linuxroute.
/* Separat auswählen und ausführen:
EXEC toolbelt_archive.USP_CreateZipFileFromEntries @Hilfe=1;
CREATE TABLE #ContosoEntries(Ordinal int,EntryName nvarchar(max),Payload varbinary(max));
INSERT #ContosoEntries VALUES(1,N'contoso.txt',0x010203);
-- NurmitvorhandenemautorisiertemRoot/Zielverzeichnis;schreibteineDatei.
EXEC toolbelt_archive.USP_CreateZipFileFromEntries @EntryTable=N'#ContosoEntries',@RootAlias=N'ContosoRoot',@RelativePath=N'out\contoso.zip';
DROP TABLE #ContosoEntries;
*/

-- toolbelt_archive.USP_ExtractZipEntryToFile
-- Bereitet vollständiges ZIP/Entry-Binary vor und veröffentlicht über WriteBinaryFile. Datei und SQL-Ausgabe sind nicht gemeinsam atomar.
-- Voraussetzung: Windows-only mit lokalem ZIPfiles1.0.0-Profil, ZIPmemory1.4.0, Windowsfilesystem1.0.0 und ResultTable derselben Datenbank. Vorhandener aktiver Root mit AllowWrite, bestehendes Zielverzeichnis und NTFS-Rechte. Caller-Modus verlangt Windowsauthentifizierung. ServiceAccount nur bei expliziter Wahl mit toolbelt_filesystem_service_account und Root-AllowServiceAccount. Keine zentrale Cross-DB- oder Linuxroute.
/* Separat auswählen und ausführen:
EXEC toolbelt_archive.USP_ExtractZipEntryToFile @Hilfe=1;
-- VollständigeZIPbytesvomClientanstelleNULLbinden.
DECLARE @Archive varbinary(max)=NULL;
EXEC toolbelt_archive.USP_ExtractZipEntryToFile @ZipArchive=@Archive,@EntryName=N'contoso.txt',@RootAlias=N'ContosoRoot',@RelativePath=N'out\contoso.txt';
*/

-- toolbelt_archive.USP_ExtractZipArchiveToDirectory
-- Extrahiert ein ZIP gestreamt in einen konfigurierten lokalen NTFS-Ordner und meldet jeden Eintrag.
-- Voraussetzung: Lokale Installation auf Windows SQL Server, festes NTFS-Laufwerk und vorhandene Root-Konfiguration. Für fehlende Verzeichnisse ist AllowCreateDirectory erforderlich. Die Sitzung darf keine aktive oder implizite SQL-Transaktion haben.
/* Separat auswählen und ausführen:
EXEC toolbelt_archive.USP_ExtractZipArchiveToDirectory @Hilfe = 1;
*/

-- toolbelt_archive.USP_CreateZipFromEntries
-- Erzeugt ein begrenztes ZIP aus Ordinal int, EntryName nvarchar(max), Payload varbinary(max) einer vorhandenen caller-lokalen Temp-Tabelle.
-- Voraussetzung: ZIPmemory1.4.0 mit passender SAFE-Assembly tlblt_Archive_ZipMemory und ResultTable derselben Datenbank. Windows/Linux SQL2019/2022/2025 mit zulässigem CL150/160/170 gemäß Modulmatrix. Vorhandene CLR-/Trustvoraussetzungen; keine Datei- oder Netzwerkquelle.
/* Separat auswählen und ausführen:
EXEC toolbelt_archive.USP_CreateZipFromEntries @Hilfe=1;
CREATE TABLE #ContosoEntries(Ordinal int,EntryName nvarchar(max),Payload varbinary(max));
INSERT #ContosoEntries VALUES(1,N'contoso.txt',0x010203);
EXEC toolbelt_archive.USP_CreateZipFromEntries @EntryTable=N'#ContosoEntries';
DROP TABLE #ContosoEntries;
*/

-- toolbelt_archive.USP_ExtractZipEntryFromBinary
-- Extrahiert einen einzelnen benannten ZIP-Entry aus einem varbinary(max)-Archiv im Speicher. Der interne SAFE-CLR-Provider unterstützt ZIP Methods 0 und 8 und prüft die CRC32 des tatsächlichen Payloads.
-- Voraussetzung: ZIPmemory1.4.0 mit passender SAFE-Assembly tlblt_Archive_ZipMemory und ResultTable derselben Datenbank. Windows/Linux SQL2019/2022/2025 mit zulässigem CL150/160/170 gemäß Modulmatrix. Vorhandene CLR-/Trustvoraussetzungen; keine Datei- oder Netzwerkquelle.
/* Separat auswählen und ausführen:
EXEC toolbelt_archive.USP_ExtractZipEntryFromBinary @Hilfe=1;
-- VollständigeZIPbytesvomClientanstelleNULLbinden.
DECLARE @Archive varbinary(max)=NULL;
EXEC toolbelt_archive.USP_ExtractZipEntryFromBinary @ZipArchive=@Archive,@EntryName=N'contoso.txt';
*/

-- toolbelt_archive.USP_ListZipEntriesFromBinary
-- Listet deklarierte Metadaten aller Central-Directory-Entries eines klassischen Single-Disk-ZIP aus varbinary(max), ohne Payloads zu lesen oder zu dekomprimieren.
-- Voraussetzung: ZIPmemory1.4.0 mit passender SAFE-Assembly tlblt_Archive_ZipMemory und ResultTable derselben Datenbank. Windows/Linux SQL2019/2022/2025 mit zulässigem CL150/160/170 gemäß Modulmatrix. Vorhandene CLR-/Trustvoraussetzungen; keine Datei- oder Netzwerkquelle.
/* Separat auswählen und ausführen:
EXEC toolbelt_archive.USP_ListZipEntriesFromBinary @Hilfe=1;
-- VollständigeZIPbytesvomClientanstelleNULLbinden.
DECLARE @Archive varbinary(max)=NULL;
EXEC toolbelt_archive.USP_ListZipEntriesFromBinary @ZipArchive=@Archive;
*/

-- toolbelt_binary.TVF_LeftShiftBigInt
-- Verschiebt die Bits eines bigint-Werts nach links.
-- Voraussetzung: SQL Server 2019 oder neuer. Alle Funktionsargumente positionsbezogen angeben; für einen deklarierten Default ist DEFAULT anzugeben. Kein CLR oder externer Provider erforderlich.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_binary.TVF_LeftShiftBigInt(255, 2);
*/

-- toolbelt_binary.TVF_RightShiftBigInt
-- Verschiebt die Bits eines bigint-Werts logisch nach rechts.
-- Voraussetzung: SQL Server 2019 oder neuer. Alle Funktionsargumente positionsbezogen angeben; für einen deklarierten Default ist DEFAULT anzugeben. Kein CLR oder externer Provider erforderlich.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_binary.TVF_RightShiftBigInt(255, 2);
*/

-- toolbelt_binary.TVF_BitCountBigInt
-- Zählt gesetzte Bits im bigint-Wert.
-- Voraussetzung: SQL Server 2019 oder neuer. Alle Funktionsargumente positionsbezogen angeben; für einen deklarierten Default ist DEFAULT anzugeben. Kein CLR oder externer Provider erforderlich.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_binary.TVF_BitCountBigInt(255);
*/

-- toolbelt_binary.TVF_GetBitBigInt
-- Liest das Bit an einer nullbasierten Position.
-- Voraussetzung: SQL Server 2019 oder neuer. Alle Funktionsargumente positionsbezogen angeben; für einen deklarierten Default ist DEFAULT anzugeben. Kein CLR oder externer Provider erforderlich.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_binary.TVF_GetBitBigInt(255, 3);
*/

-- toolbelt_binary.TVF_SetBitBigInt
-- Setzt oder löscht ein Bit an einer nullbasierten Position.
-- Voraussetzung: SQL Server 2019 oder neuer. Alle Funktionsargumente positionsbezogen angeben; für einen deklarierten Default ist DEFAULT anzugeben. Kein CLR oder externer Provider erforderlich.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_binary.TVF_SetBitBigInt(255, 3, 1);
*/

-- toolbelt_conversion.TVF_Base64Encode
-- Codiert Binärdaten als Base64 oder Base64URL.
-- Voraussetzung: SQL Server 2019 oder neuer; Aufruf als Tabellenfunktion. Beide Argumentpositionen angeben; für einen deklarierten Default ist in einem Funktionsaufruf DEFAULT zu verwenden.
/* Separat auswählen und ausführen:
SELECT EncodedValue
FROM toolbelt_conversion.TVF_Base64Encode(0xCAFECAFE,0);
-- Erwartet: yv7K/g==
*/

-- toolbelt_conversion.TVF_Base64Decode
-- Decodiert Base64-Text zu Binärdaten.
-- Voraussetzung: SQL Server 2019/2022/2025, Windows/Linux, CL150/160/170; Base64-Modul installiert. Reiner T-SQL/XML-Provider ohne CLR oder Netzwerk. Funktionsargumente positionsbezogen angeben; bei deklariertem Default das Schlüsselwort DEFAULT oder den gewünschten Wert übergeben.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_conversion.TVF_Base64Decode('yv7K_g');
-- 0xCAFECAFE
*/

-- toolbelt_conversion.SVF_Base64Encode
-- Codiert Binärdaten als Base64 oder Base64URL.
-- Voraussetzung: SQL Server 2019/2022/2025, Windows/Linux, CL150/160/170; Base64-Modul installiert. Reiner T-SQL/XML-Provider ohne CLR oder Netzwerk. Funktionsargumente positionsbezogen angeben; bei deklariertem Default das Schlüsselwort DEFAULT oder den gewünschten Wert übergeben.
/* Separat auswählen und ausführen:
SELECT toolbelt_conversion.SVF_Base64Encode(0xCAFECAFE,0) AS Value;
-- yv7K/g==
*/

-- toolbelt_conversion.SVF_Base64Decode
-- Decodiert Base64-Text zu Binärdaten.
-- Voraussetzung: SQL Server 2019/2022/2025, Windows/Linux, CL150/160/170; Base64-Modul installiert. Reiner T-SQL/XML-Provider ohne CLR oder Netzwerk. Funktionsargumente positionsbezogen angeben; bei deklariertem Default das Schlüsselwort DEFAULT oder den gewünschten Wert übergeben.
/* Separat auswählen und ausführen:
SELECT toolbelt_conversion.SVF_Base64Decode('yv7K_g') AS Value;
-- 0xCAFECAFE
*/

-- toolbelt_conversion.TVF_Base64EncodeStatus
-- Codiert begrenzte Binärdaten als Base64 oder Base64URL mit explizitem NULL-/Limitstatus.
-- Voraussetzung: SQL Server 2019 oder neuer; Aufruf als Tabellenfunktion. Beide Argumentpositionen angeben; für einen deklarierten Default ist in einem Funktionsaufruf DEFAULT zu verwenden.
/* Separat auswählen und ausführen:
SELECT EncodedValue,Status
FROM toolbelt_conversion.TVF_Base64EncodeStatus(0xCAFECAFE,0);
-- yv7K/g==, OK
SELECT EncodedValue,Status
FROM toolbelt_conversion.TVF_Base64EncodeStatus(NULL,1);
-- NULL, SQL_NULL
*/

-- toolbelt_conversion.TVF_Base64DecodeStatus
-- Genau eine Zeile: OK, SQL_NULL, INVALID oder LIMIT. Rohtextprüfung vor REPLACE, berechnete Ergebnisgröße vor XML. Standard-/URL-Alphabet und definierter Whitespace bleiben. Die bisherige TVF/SVF behält Syntaxfehler unterhalb der Grenzen und liefert bei LIMIT NULL.
-- Voraussetzung: SQL Server 2019/2022/2025, Windows/Linux, CL150/160/170; Base64-Modul installiert. Reiner T-SQL/XML-Provider ohne CLR oder Netzwerk. Funktionsargumente positionsbezogen angeben; bei deklariertem Default das Schlüsselwort DEFAULT oder den gewünschten Wert übergeben.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_conversion.TVF_Base64DecodeStatus('yv7K_g');
-- 0xCAFECAFE, Status=OK
*/

-- toolbelt_conversion.TVF_IntegerToBase
-- Codiert einen bigint-Wert in einem frei festgelegten Zahlensystem.
-- Voraussetzung: SQL Server 2019/2022/2025, Windows/Linux, CL150/160/170. Modul installiert; reine T-SQL-Funktionen ohne CLR, externe Datenquelle oder Systemkatalogabfrage. Beide Argumente positionsbezogen übergeben. Keine SQL-Defaults.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_conversion.TVF_IntegerToBase(255,'0123456789ABCDEF');
-- FF
*/

-- toolbelt_conversion.TVF_TryBaseToInteger
-- Decodiert einen Text anhand des angegebenen Alphabets in bigint.
-- Voraussetzung: SQL Server 2019/2022/2025, Windows/Linux, CL150/160/170. Modul installiert; reine T-SQL-Funktionen ohne CLR, externe Datenquelle oder Systemkatalogabfrage. Beide Argumente positionsbezogen übergeben. Keine SQL-Defaults.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_conversion.TVF_TryBaseToInteger('FF','0123456789ABCDEF');
-- 255
*/

-- toolbelt_conversion.SVF_IntegerToBase
-- Codiert einen bigint-Wert in einem frei festgelegten Zahlensystem.
-- Voraussetzung: SQL Server 2019/2022/2025, Windows/Linux, CL150/160/170. Modul installiert; reine T-SQL-Funktionen ohne CLR, externe Datenquelle oder Systemkatalogabfrage. Beide Argumente positionsbezogen übergeben. Keine SQL-Defaults.
/* Separat auswählen und ausführen:
SELECT toolbelt_conversion.SVF_IntegerToBase(255,'0123456789ABCDEF') AS Value;
-- FF
*/

-- toolbelt_conversion.SVF_TryBaseToInteger
-- Decodiert einen Text anhand des angegebenen Alphabets in bigint.
-- Voraussetzung: SQL Server 2019/2022/2025, Windows/Linux, CL150/160/170. Modul installiert; reine T-SQL-Funktionen ohne CLR, externe Datenquelle oder Systemkatalogabfrage. Beide Argumente positionsbezogen übergeben. Keine SQL-Defaults.
/* Separat auswählen und ausführen:
SELECT toolbelt_conversion.SVF_TryBaseToInteger('FF','0123456789ABCDEF') AS Value;
-- 255
*/

-- toolbelt_conversion.TVF_TryCastBigInt
-- Prüft ASCII-Ganzzahltext und den exakten bigint-Bereich; liefert Value, Status und ErrorCode.
-- Voraussetzung: SQL Server 2019/2022/2025, Windows/Linux, CL150/160/170; Safe-Cast-Modul installiert. Keine Modul-/Tabellen-/CLR-/Katalogabhängigkeit. Beide Funktionsargumentpositionen angeben, DEFAULT für das technische Budget 8192. Eingabe als Unicodeparameter nvarchar(max) binden, damit keine vorgelagerte varchar-Codepagekonversion den Originaltext verändert.
/* Separat auswählen und ausführen:
SELECT Value,Status,ErrorCode
FROM toolbelt_conversion.TVF_TryCastBigInt(N'+00042',DEFAULT);
-- 42, OK, NULL
SELECT Value,Status,ErrorCode
FROM toolbelt_conversion.TVF_TryCastBigInt(NULL,0);
-- NULL, SQL_NULL, NULL (Text-NULL hat Vorrang).
*/

-- toolbelt_conversion.TVF_TryCastDecimal
-- Prüft exakten decimal(38,18)-Bereich vor Skalenverlust; rundet niemals still.
-- Voraussetzung: SQL Server 2019/2022/2025, Windows/Linux, CL150/160/170; Safe-Cast-Modul installiert. Keine Modul-/Tabellen-/CLR-/Katalogabhängigkeit. Beide Funktionsargumentpositionen angeben, DEFAULT für das technische Budget 8192. Eingabe als Unicodeparameter nvarchar(max) binden, damit keine vorgelagerte varchar-Codepagekonversion den Originaltext verändert.
/* Separat auswählen und ausführen:
SELECT Value,Status,ErrorCode
FROM toolbelt_conversion.TVF_TryCastDecimal(N'12.5000000000000000000',DEFAULT);
-- 12.500000000000000000, OK, NULL
SELECT Value,Status,ErrorCode
FROM toolbelt_conversion.TVF_TryCastDecimal(NULL,0);
-- NULL, SQL_NULL, NULL (Text-NULL hat Vorrang).
*/

-- toolbelt_conversion.TVF_TryCastDate
-- Prüft exakt YYYY-MM-DD und den date-Kalenderbereich unabhängig von Sprache und DATEFORMAT.
-- Voraussetzung: SQL Server 2019/2022/2025, Windows/Linux, CL150/160/170; Safe-Cast-Modul installiert. Keine Modul-/Tabellen-/CLR-/Katalogabhängigkeit. Beide Funktionsargumentpositionen angeben, DEFAULT für das technische Budget 8192. Eingabe als Unicodeparameter nvarchar(max) binden, damit keine vorgelagerte varchar-Codepagekonversion den Originaltext verändert.
/* Separat auswählen und ausführen:
SELECT Value,Status,ErrorCode
FROM toolbelt_conversion.TVF_TryCastDate(N'2026-11-20',DEFAULT);
-- 2026-11-20, OK, NULL
SELECT Value,Status,ErrorCode
FROM toolbelt_conversion.TVF_TryCastDate(NULL,0);
-- NULL, SQL_NULL, NULL (Text-NULL hat Vorrang).
*/

-- toolbelt_conversion.TVF_TryCastDateTime2
-- Prüft ISO-Datetime mit großem T und höchstens sieben Fractionziffern ohne Rundung oder Zeitzonenverlust.
-- Voraussetzung: SQL Server 2019/2022/2025, Windows/Linux, CL150/160/170; Safe-Cast-Modul installiert. Keine Modul-/Tabellen-/CLR-/Katalogabhängigkeit. Beide Funktionsargumentpositionen angeben, DEFAULT für das technische Budget 8192. Eingabe als Unicodeparameter nvarchar(max) binden, damit keine vorgelagerte varchar-Codepagekonversion den Originaltext verändert.
/* Separat auswählen und ausführen:
SELECT Value,Status,ErrorCode
FROM toolbelt_conversion.TVF_TryCastDateTime2(N'2026-11-20T12:34:56.1234567',DEFAULT);
-- 2026-11-20 12:34:56.1234567, OK, NULL
SELECT Value,Status,ErrorCode
FROM toolbelt_conversion.TVF_TryCastDateTime2(NULL,0);
-- NULL, SQL_NULL, NULL (Text-NULL hat Vorrang).
*/

-- toolbelt_conversion.TVF_TryCastBit
-- Akzeptiert ausschließlich den Text0 oder1; native permissive Bitkonversion bleibt ausgeschlossen.
-- Voraussetzung: SQL Server 2019/2022/2025, Windows/Linux, CL150/160/170; Safe-Cast-Modul installiert. Keine Modul-/Tabellen-/CLR-/Katalogabhängigkeit. Beide Funktionsargumentpositionen angeben, DEFAULT für das technische Budget 8192. Eingabe als Unicodeparameter nvarchar(max) binden, damit keine vorgelagerte varchar-Codepagekonversion den Originaltext verändert.
/* Separat auswählen und ausführen:
SELECT Value,Status,ErrorCode
FROM toolbelt_conversion.TVF_TryCastBit(N'1',DEFAULT);
-- 1, OK, NULL
SELECT Value,Status,ErrorCode
FROM toolbelt_conversion.TVF_TryCastBit(NULL,0);
-- NULL, SQL_NULL, NULL (Text-NULL hat Vorrang).
*/

-- toolbelt_conversion.TVF_TryCastUniqueIdentifier
-- Prüft vollständige GUID-Lexik im8-4-4-4-12-Muster vor Konversion; keine Suffixtrunkierung.
-- Voraussetzung: SQL Server 2019/2022/2025, Windows/Linux, CL150/160/170; Safe-Cast-Modul installiert. Keine Modul-/Tabellen-/CLR-/Katalogabhängigkeit. Beide Funktionsargumentpositionen angeben, DEFAULT für das technische Budget 8192. Eingabe als Unicodeparameter nvarchar(max) binden, damit keine vorgelagerte varchar-Codepagekonversion den Originaltext verändert.
/* Separat auswählen und ausführen:
SELECT Value,Status,ErrorCode
FROM toolbelt_conversion.TVF_TryCastUniqueIdentifier(N'00112233-4455-6677-8899-aabbccddeeff',DEFAULT);
-- 00112233-4455-6677-8899-aabbccddeeff, OK, NULL
SELECT Value,Status,ErrorCode
FROM toolbelt_conversion.TVF_TryCastUniqueIdentifier(NULL,0);
-- NULL, SQL_NULL, NULL (Text-NULL hat Vorrang).
*/

-- toolbelt_conversion.TVF_UriComponentEncode
-- Codiert eine Unicode-URI-Komponente als begrenzte UTF-8-Percentdarstellung.
-- Voraussetzung: SQL Server 2019/2022/2025, Windows/Linux, CL150/160/170. URI-Modul und deklarierte Generate-Series-Abhängigkeit installiert. SQL-UTF8-Kollation Latin1_General_100_BIN2_UTF8 und master.dbo.fn_varbintohexstr werden vom T-SQL-Provider verwendet. Kein CLR, Datei-/Netzwerkzugriff oder Fachsystemkatalog.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_conversion.TVF_UriComponentEncode(N'a b/Ä');
-- a%20b%2F%C3%84
*/

-- toolbelt_conversion.TVF_UriComponentDecode
-- Decodiert eine Runde von Prozent-Escapes und prüft die UTF-8-Sequenz.
-- Voraussetzung: URIcomponent-Modul mit demselben kanonischen GenerateSeries-Kern. TSQL auf Windows/Linux SQL2019/2022/2025, zulässiges CL150/160/170. Keine Datei-, Netzwerk-, CLR-, Katalog- oder Trustabhängigkeit.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_conversion.TVF_UriComponentDecodeStatus(N'Contoso%20A%2BB');
SELECT * FROM toolbelt_conversion.TVF_UriComponentDecodeStatus(NCHAR(256));
SELECT toolbelt_conversion.SVF_UriComponentDecode(N'%F0%9F%98%80');
*/

-- toolbelt_conversion.SVF_UriComponentEncode
-- Codiert eine Unicode-URI-Komponente als begrenzte UTF-8-Percentdarstellung.
-- Voraussetzung: SQL Server 2019/2022/2025, Windows/Linux, CL150/160/170. URI-Modul und deklarierte Generate-Series-Abhängigkeit installiert. SQL-UTF8-Kollation Latin1_General_100_BIN2_UTF8 und master.dbo.fn_varbintohexstr werden vom T-SQL-Provider verwendet. Kein CLR, Datei-/Netzwerkzugriff oder Fachsystemkatalog.
/* Separat auswählen und ausführen:
SELECT toolbelt_conversion.SVF_UriComponentEncode(N'a b/Ä') AS Value;
-- a%20b%2F%C3%84
*/

-- toolbelt_conversion.SVF_UriComponentDecode
-- Decodiert eine Runde von Prozent-Escapes und prüft die UTF-8-Sequenz.
-- Voraussetzung: URIcomponent-Modul mit demselben kanonischen GenerateSeries-Kern. TSQL auf Windows/Linux SQL2019/2022/2025, zulässiges CL150/160/170. Keine Datei-, Netzwerk-, CLR-, Katalog- oder Trustabhängigkeit.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_conversion.TVF_UriComponentDecodeStatus(N'Contoso%20A%2BB');
SELECT * FROM toolbelt_conversion.TVF_UriComponentDecodeStatus(NCHAR(256));
SELECT toolbelt_conversion.SVF_UriComponentDecode(N'%F0%9F%98%80');
*/

-- toolbelt_conversion.TVF_UriComponentEncodeStatus
-- Codiert eine Unicode-URI-Komponente als begrenzte UTF-8-Percentdarstellung.
-- Voraussetzung: SQL Server 2019/2022/2025, Windows/Linux, CL150/160/170. URI-Modul und deklarierte Generate-Series-Abhängigkeit installiert. SQL-UTF8-Kollation Latin1_General_100_BIN2_UTF8 und master.dbo.fn_varbintohexstr werden vom T-SQL-Provider verwendet. Kein CLR, Datei-/Netzwerkzugriff oder Fachsystemkatalog.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_conversion.TVF_UriComponentEncodeStatus(N'a b/Ä');
-- a%20b%2F%C3%84, Status=OK
*/

-- toolbelt_conversion.TVF_UriComponentDecodeStatus
-- Genau eine Zeile: OK, SQL_NULL, INVALID oder LIMIT. Strikte UTF-8-/Percent-/NUL-Regeln bleiben; bei LIMIT IsValid=0, ValidationCode=14, Wert NULL. Die Ausgabe ist durch den vor Series geprüften Eingang unter 1 MiB begrenzt. Altfassaden behalten ihre Spalten und liefern bei LIMIT NULL.
-- Voraussetzung: URIcomponent-Modul mit demselben kanonischen GenerateSeries-Kern. TSQL auf Windows/Linux SQL2019/2022/2025, zulässiges CL150/160/170. Keine Datei-, Netzwerk-, CLR-, Katalog- oder Trustabhängigkeit.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_conversion.TVF_UriComponentDecodeStatus(N'Contoso%20A%2BB');
SELECT * FROM toolbelt_conversion.TVF_UriComponentDecodeStatus(NCHAR(256));
SELECT toolbelt_conversion.SVF_UriComponentDecode(N'%F0%9F%98%80');
*/

-- toolbelt_core.USP_WriteConsoleMessage
-- Gibt begrenzten Unicode-Text in den SQL-Messages-Kanal aus, wahlweise mit NOWAIT.
-- Voraussetzung: Installierte reine T-SQL-Prozedur auf SQL Server 2019/2022/2025, Windows oder Linux, lokal/zentral gemäß Modulvertrag. Client/Treiber muss Informationsnachrichten entgegennehmen; NOWAIT ist keine Zusage sofortiger UI-Darstellung. Keine CLR-, Datei-, Netzwerk- oder Tabellenabhängigkeit.
/* Separat auswählen und ausführen:
EXEC toolbelt_core.USP_WriteConsoleMessage @Message=N'Example progress: 25%',@Immediate=1;
EXEC toolbelt_core.USP_WriteConsoleMessage @Hilfe=1;
*/

-- toolbelt_core.USP_CaptureErrorEnvelope
-- Formatiert explizit übergebene Fehlerdaten mit aktuellem Ausführungskontext als eine Fehlerzeile.
-- Voraussetzung: Installierte T-SQL-Prozedur auf SQL Server 2019/2022/2025, Windows/Linux, lokal/zentral gemäß Modulvertrag. Direktes Resultset benötigt keine ResultTable-Operation und funktioniert im vorgesehenen uncommittable Callerpfad ohne Temp-DDL/INSERT. Für ResultTable-Ausgabe vorhandene lokale #Temp und USP_PrepareResultTable; zuerst Caller-Rollback bei XACT_STATE()=-1.
/* Separat auswählen und ausführen:
-- Synthetische explizite Fehlerdaten, keine echte Fehlersitzung nötig:
EXEC toolbelt_core.USP_CaptureErrorEnvelope
 @ErrorNumber=50001,@ErrorSeverity=16,@ErrorState=1,
 @ErrorMessage=N'Example failure',@AdditionalContext=N'Synthetic example';
EXEC toolbelt_core.USP_CaptureErrorEnvelope @Hilfe=1;
*/

-- toolbelt_core.VW_Events
-- Öffentliche ungefilterte Projektion aller persistierten Ereignis- und Auditspalten.
-- Voraussetzung: Installiertes Modul toolbelt.core.event-log in der gewählten Datenbank, SQL2019/2022/2025 Windows/Linux gemäß Modulmatrix, passende CL150/160/170. View benötigt die Tabelle. Für das reine SELECT ist keine aktive Second-Session-Verbindung nötig; die getrennte öffentliche Schreibfassade benötigt ihren konfigurierten Second-Session-/Work-Type-/Execution-Context-Vertrag. Kein automatisches Einrichten dieser Infrastruktur.
/* Separat auswählen und ausführen:
SELECT TOP (100) EventId,RecordedAtUtc,EventName,EventLevel
FROM toolbelt_core.VW_Events
ORDER BY RecordedAtUtc DESC,EventId DESC;
-- Explizite Reihenfolge; keine ungefilterte Ausgabe von Message/DataJson.
*/

-- toolbelt_core.USP_WriteEvent
-- Schreibt ein strukturiertes Event synchron über toolbelt.core.second-session. Der Remote-Commit ist unabhängig von Commit oder Rollback der Caller-Transaktion.
-- Voraussetzung: SQL Server 2019/2022/2025 Windows/Linux, passende CL150/160/170, lokal/zentral. EventLog und execution-context installiert. Konfigurierter aktivierter Loopback-Provider in second-session >=1.1.0 mit RPC OUT und Remote-Proc-Transaction-Promotion OFF. Aktiv registrierter JSON_PAYLOAD-Work-Type toolbelt.event-log.write mit kanonischem Handler USP_WriteEventInternal(@PayloadJson nvarchar(max),@Hilfe bit=0), ohne fachliches Resultset. Vorhandene lokale und Remote-Policy EXECUTE_NEW_SESSION plus Remote-Handler-EXECUTE. Runtime-Preflight prüft unter anderem OBJECT_ID und @SuppressResult-Parameter; er installiert/konfiguriert nichts.
/* Separat auswählen und ausführen:
EXEC toolbelt_core.USP_WriteEvent @EventName='contoso.example',@EventLevel='INFO',@Message=N'Synthetic event',@DataJson=N'{"rows":1}';
-- Persistiert über den zuvor autorisierten/konfigurierten Provider.
EXEC toolbelt_core.USP_WriteEvent @Hilfe=1;
*/

-- toolbelt_core.USP_DeleteEventsBefore
-- Löscht alte Events in explizit begrenzten Batches. Die Procedure führt keine automatische Zeitplanung aus.
-- Voraussetzung: Installiertes EventLog, SQL Server 2019/2022/2025 Windows/Linux mit passenden CL150/160/170, lokal oder zentral. Gültiger datetime2(7)-Cutoff als UTC-Konvention ohne automatische Zeitzonenkonvertierung. Kein Second-Session-Provider für Retention erforderlich. Fehlender Cutoff wird im Fachpfad abgewiesen. Committable Callertransaktion erlaubt, uncommittable nicht.
/* Separat auswählen und ausführen:
DECLARE @Deleted bigint;
EXEC toolbelt_core.USP_DeleteEventsBefore @BeforeOccurredAtUtc='2000-01-01T00:00:00',@BatchSize=100,@MaxBatches=1,@DeletedRows=@Deleted OUTPUT;
SELECT @Deleted AS DeletedRows;
-- Nur im autorisierten synthetischen Scope; persistente Löschung.
EXEC toolbelt_core.USP_DeleteEventsBefore @Hilfe=1;
*/

-- toolbelt_core.USP_DeleteRecordedEventsBefore
-- Nur ausdrücklich aufgerufene Retention nach RecordedAtUtc mit Index (RecordedAtUtc,EventId), deterministischen begrenzten Batches und bestehender Caller-Transaktions-/Savepointsemantik. Kein Job, keine Deploymentlöschung. Die OccurredAtUtc-Retention bleibt unverändert. Erfordert vorhandenes EXECUTE; erteilt keine Berechtigungen. Fehler 51710–51714 wie im bestehenden Retentionvertrag.
-- Voraussetzung: Installiertes EventLog, SQL Server 2019/2022/2025 Windows/Linux mit passenden CL150/160/170, lokal oder zentral. Gültiger datetime2(7)-Cutoff als UTC-Konvention ohne automatische Zeitzonenkonvertierung. Kein Second-Session-Provider für Retention erforderlich. Fehlender Cutoff wird im Fachpfad abgewiesen. Committable Callertransaktion erlaubt, uncommittable nicht.
/* Separat auswählen und ausführen:
DECLARE @Deleted bigint;
EXEC toolbelt_core.USP_DeleteRecordedEventsBefore @BeforeRecordedAtUtc='2000-01-01T00:00:00',@BatchSize=100,@MaxBatches=1,@DeletedRows=@Deleted OUTPUT;
SELECT @Deleted AS DeletedRows;
-- Nur im autorisierten synthetischen Scope; persistente Löschung.
EXEC toolbelt_core.USP_DeleteRecordedEventsBefore @Hilfe=1;
*/

-- toolbelt_core.TVF_ExecutionCancellationStatus
-- Liest den registrierten kooperativen Abbruchstatus einer Ausführung.
-- Voraussetzung: SQL Server 2019/2022/2025 Windows/Linux gemäß Modulmatrix, unterstützte CL150/160/170, lokal oder zentral. Modul ExecutionCancellation und seine passenden Quellobjekte installiert. Request benötigt execution-context >=1.0.0, für implizite ID einen gültigen aktuellen Kontext; Statusfunktionen benötigen keinen aktiven Kontext. Tabelle/Quoten sind pro installierender Datenbank, nicht serverweit oder pro Session.
/* Separat auswählen und ausführen:
SELECT toolbelt_core.SVF_IsCancellationRequested(NULL) AS IsRequested;
-- 0.
SELECT * FROM toolbelt_core.TVF_ExecutionCancellationStatus(NULL);
-- Keine Zeilen.
*/

-- toolbelt_core.SVF_IsCancellationRequested
-- Prüft, ob für eine Ausführung ein kooperativer Abbruch angefordert wurde.
-- Voraussetzung: SQL Server 2019/2022/2025 Windows/Linux gemäß Modulmatrix, unterstützte CL150/160/170, lokal oder zentral. Modul ExecutionCancellation und seine passenden Quellobjekte installiert. Request benötigt execution-context >=1.0.0, für implizite ID einen gültigen aktuellen Kontext; Statusfunktionen benötigen keinen aktiven Kontext. Tabelle/Quoten sind pro installierender Datenbank, nicht serverweit oder pro Session.
/* Separat auswählen und ausführen:
SELECT toolbelt_core.SVF_IsCancellationRequested(NULL) AS IsRequested;
-- 0.
SELECT * FROM toolbelt_core.TVF_ExecutionCancellationStatus(NULL);
-- Keine Zeilen.
*/

-- toolbelt_core.USP_RequestExecutionCancellation
-- Persistiert eine irreversible kooperative Cancellation-Anforderung. Die Procedure beendet keine Session und verändert keine Work-Queue-Einträge.
-- Voraussetzung: SQL Server 2019/2022/2025 Windows/Linux gemäß Modulmatrix, unterstützte CL150/160/170, lokal oder zentral. Modul ExecutionCancellation und seine passenden Quellobjekte installiert. Request benötigt execution-context >=1.0.0, für implizite ID einen gültigen aktuellen Kontext; Statusfunktionen benötigen keinen aktiven Kontext. Tabelle/Quoten sind pro installierender Datenbank, nicht serverweit oder pro Session.
/* Separat auswählen und ausführen:
DECLARE @Id uniqueidentifier=NEWID();
EXEC toolbelt_core.USP_RequestExecutionCancellation @ExecutionId=@Id,@CancellationReason=N'Synthetic checkpoint';
SELECT * FROM toolbelt_core.TVF_ExecutionCancellationStatus(@Id);
EXEC toolbelt_core.USP_RequestExecutionCancellation @Hilfe=1;
-- Nur Testidentität in autorisiertem Scope; die Anforderung persistiert.
*/

-- toolbelt_core.TVF_CurrentExecutionContext
-- Liest den aktuellen Toolbelt-Ausführungskontext als relationale null- oder einzeilige Projektion; geeigneter Einstieg für APPLY und Diagnose.
-- Voraussetzung: Installiertes reines T-SQL-Modul auf SQL Server 2019/2022/2025 unter Windows/Linux, lokal oder zentral. Die sechs festen SESSION_CONTEXT-Keys gehören zur aktuellen SQL-Verbindung und sind nicht nach Datenbank getrennt: toolbelt.execution.id, toolbelt.execution.correlation_id, toolbelt.execution.actor, toolbelt.execution.tenant, toolbelt.execution.started_at_utc und toolbelt.execution.depth. Keine CLR-, Datei-, Netzwerk- oder Benutzertabellenabhängigkeit. Nicht gleichzeitig per MARS/anderen Aufrufen oder direkt über sp_set_session_context manipulieren; Enginebeschränkungen und extern read_only gesetzte Keys können Schreibaufrufe blockieren.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_core.TVF_CurrentExecutionContext();
-- Ohne gültige aktive ExecutionId: keine Zeile.
*/

-- toolbelt_core.SVF_CurrentExecutionId
-- Skalarer Komfortzugriff auf die ID des aktuellen Ausführungskontexts; relationaler Kern ist TVF_CurrentExecutionContext.
-- Voraussetzung: Installiertes reines T-SQL-Modul auf SQL Server 2019/2022/2025 unter Windows/Linux, lokal oder zentral. Die sechs festen SESSION_CONTEXT-Keys gehören zur aktuellen SQL-Verbindung und sind nicht nach Datenbank getrennt: toolbelt.execution.id, toolbelt.execution.correlation_id, toolbelt.execution.actor, toolbelt.execution.tenant, toolbelt.execution.started_at_utc und toolbelt.execution.depth. Keine CLR-, Datei-, Netzwerk- oder Benutzertabellenabhängigkeit. Nicht gleichzeitig per MARS/anderen Aufrufen oder direkt über sp_set_session_context manipulieren; Enginebeschränkungen und extern read_only gesetzte Keys können Schreibaufrufe blockieren.
/* Separat auswählen und ausführen:
SELECT toolbelt_core.SVF_CurrentExecutionId() AS ExecutionId;
*/

-- toolbelt_core.USP_BeginExecution
-- Beginnt einen Toolbelt-Ausführungskontext in dieser Verbindung oder erhöht seine ScopeDepth bei zulässiger Verschachtelung.
-- Voraussetzung: Installiertes reines T-SQL-Modul auf SQL Server 2019/2022/2025 unter Windows/Linux, lokal oder zentral. Die sechs festen SESSION_CONTEXT-Keys gehören zur aktuellen SQL-Verbindung und sind nicht nach Datenbank getrennt: toolbelt.execution.id, toolbelt.execution.correlation_id, toolbelt.execution.actor, toolbelt.execution.tenant, toolbelt.execution.started_at_utc und toolbelt.execution.depth. Keine CLR-, Datei-, Netzwerk- oder Benutzertabellenabhängigkeit. Nicht gleichzeitig per MARS/anderen Aufrufen oder direkt über sp_set_session_context manipulieren; Enginebeschränkungen und extern read_only gesetzte Keys können Schreibaufrufe blockieren.
/* Separat auswählen und ausführen:
-- Eigene Sitzung ohne vorher aktiven Context verwenden.
DECLARE @Id uniqueidentifier;
EXEC toolbelt_core.USP_BeginExecution @ExecutionId=@Id OUTPUT,@Actor=N'Contoso example';
SELECT * FROM toolbelt_core.TVF_CurrentExecutionContext();
EXEC toolbelt_core.USP_EndExecution @ExpectedExecutionId=@Id;
-- Hilfe liest/schreibt keinen Context und erhält einen vorhandenen OUTPUT-Wert:
EXEC toolbelt_core.USP_BeginExecution @ExecutionId=@Id OUTPUT,@Hilfe=1;
*/

-- toolbelt_core.USP_SetExecutionContext
-- Ändert CorrelationId, Actor oder Tenant eines aktiven Kontexts unter Prüfung der erwarteten ExecutionId.
-- Voraussetzung: Installiertes reines T-SQL-Modul auf SQL Server 2019/2022/2025 unter Windows/Linux, lokal oder zentral. Die sechs festen SESSION_CONTEXT-Keys gehören zur aktuellen SQL-Verbindung und sind nicht nach Datenbank getrennt: toolbelt.execution.id, toolbelt.execution.correlation_id, toolbelt.execution.actor, toolbelt.execution.tenant, toolbelt.execution.started_at_utc und toolbelt.execution.depth. Keine CLR-, Datei-, Netzwerk- oder Benutzertabellenabhängigkeit. Nicht gleichzeitig per MARS/anderen Aufrufen oder direkt über sp_set_session_context manipulieren; Enginebeschränkungen und extern read_only gesetzte Keys können Schreibaufrufe blockieren.
/* Separat auswählen und ausführen:
DECLARE @Id uniqueidentifier=toolbelt_core.SVF_CurrentExecutionId();
-- Nur mit eigenem bereits begonnenem Context ausführen:
EXEC toolbelt_core.USP_SetExecutionContext @ExpectedExecutionId=@Id,@Actor=N'Contoso step';
EXEC toolbelt_core.USP_SetExecutionContext @ExpectedExecutionId=@Id,@ClearActor=1;
-- Pflichtargument bleibt auch für Hilfe syntaktisch erforderlich:
EXEC toolbelt_core.USP_SetExecutionContext @ExpectedExecutionId=NULL,@Hilfe=1;
*/

-- toolbelt_core.USP_EndExecution
-- Beendet genau eine Ebene des aktiven Ausführungskontexts unter Prüfung der erwarteten ExecutionId.
-- Voraussetzung: Installiertes reines T-SQL-Modul auf SQL Server 2019/2022/2025 unter Windows/Linux, lokal oder zentral. Die sechs festen SESSION_CONTEXT-Keys gehören zur aktuellen SQL-Verbindung und sind nicht nach Datenbank getrennt: toolbelt.execution.id, toolbelt.execution.correlation_id, toolbelt.execution.actor, toolbelt.execution.tenant, toolbelt.execution.started_at_utc und toolbelt.execution.depth. Keine CLR-, Datei-, Netzwerk- oder Benutzertabellenabhängigkeit. Nicht gleichzeitig per MARS/anderen Aufrufen oder direkt über sp_set_session_context manipulieren; Enginebeschränkungen und extern read_only gesetzte Keys können Schreibaufrufe blockieren.
/* Separat auswählen und ausführen:
DECLARE @Id uniqueidentifier=toolbelt_core.SVF_CurrentExecutionId();
-- Nur den eigenen zuvor begonnenen Scope beenden:
EXEC toolbelt_core.USP_EndExecution @ExpectedExecutionId=@Id;
-- Help benötigt das Pflichtargument, aber keinen aktiven Context:
EXEC toolbelt_core.USP_EndExecution @ExpectedExecutionId=NULL,@Hilfe=1;
*/

-- toolbelt_core.TVF_GenerateSeriesBigInt
-- Erzeugt eine Folge von bigint-Werten einschließlich erreichbarem Endwert.
-- Voraussetzung: SQL Server 2019/2022/2025, Windows oder Linux; Compatibility Level 150/160/170. Modul installiert, kein CLR oder externer Provider. Alle drei Argumentpositionen müssen im Funktionsaufruf angegeben werden; DEFAULT in der dritten Position oder explizites NULL aktiviert den Richtungsdefault.
/* Separat auswählen und ausführen:
SELECT Value FROM toolbelt_core.TVF_GenerateSeriesBigInt(2,10,3) ORDER BY Value;
-- 2, 5, 8; kein künstlicher Endwert 10.
SELECT Value FROM toolbelt_core.TVF_GenerateSeriesBigInt(10,1,-4) ORDER BY Value DESC;
-- 10, 6, 2.
*/

-- toolbelt_core.TVF_GenerateSeriesInt
-- Erzeugt eine Folge von int-Werten einschließlich erreichbarem Endwert.
-- Voraussetzung: SQL Server 2019/2022/2025, Windows oder Linux; Compatibility Level 150/160/170. Modul installiert, kein CLR oder externer Provider. Alle drei Argumentpositionen müssen im Funktionsaufruf angegeben werden; DEFAULT in der dritten Position oder explizites NULL aktiviert den Richtungsdefault.
/* Separat auswählen und ausführen:
SELECT Value FROM toolbelt_core.TVF_GenerateSeriesInt(2,10,3) ORDER BY Value;
-- 2, 5, 8; kein künstlicher Endwert 10.
SELECT Value FROM toolbelt_core.TVF_GenerateSeriesInt(10,1,-4) ORDER BY Value DESC;
-- 10, 6, 2.
*/

-- toolbelt_core.TVF_GenerateSeriesBigIntStatus
-- Vor Expansion exakte Anzahl mit decimal(38,0) und Restrechnung bestimmen. Höchstens 1000000 OK-Zeilen. LIMIT, INVALID, SQL_NULL oder EMPTY liefern eine Kontrollzeile ohne Value. RequestedRows unterscheidet leere und zu große Reihen. Keine garantierte Reihenfolge. Die mathematischen Alt-APIs bleiben unverändert und benötigen vertrauenswürdige Direktgrants. Untrusted Legacygrants werden nicht automatisch entzogen; SC-018 bleibt in einer solchen Installation offen.
-- Voraussetzung: SQL Server 2019/2022/2025, Windows oder Linux; Compatibility Level 150/160/170. Modul installiert, kein CLR oder externer Provider. Alle drei Argumentpositionen müssen im Funktionsaufruf angegeben werden; DEFAULT in der dritten Position oder explizites NULL aktiviert den Richtungsdefault.
/* Separat auswählen und ausführen:
SELECT Value,Status,RequestedRows
FROM toolbelt_core.TVF_GenerateSeriesBigIntStatus(1,5,2) ORDER BY Value;
-- (1,OK,3), (3,OK,3), (5,OK,3).
SELECT * FROM toolbelt_core.TVF_GenerateSeriesBigIntStatus(1,1000001,1);
-- Eine Zeile: Value=NULL, Status=LIMIT, RequestedRows=1000001.
*/

-- toolbelt_core.USP_PrepareResultTable
-- Bereitet eine vorhandene lokale Temp-Tabelle anhand des Spaltenschemas einer vorhandenen Referenztabelle vor. Die Procedure fügt keine fachlichen Resultzeilen ein.
-- Voraussetzung: Ziel-#Temp und Referenztabelle müssen im unterstützten Session-/Namensscope existieren. Kein frei geliefertes DDL, keine globale oder permanente Zieltabelle. Der Help-Pfad benötigt keine Ziel-/Referenztabelle.
/* Separat auswählen und ausführen:
CREATE TABLE #Shape (ItemId int NOT NULL);
CREATE TABLE #Result (Dummy int NULL);
EXEC toolbelt_core.USP_PrepareResultTable
 @ResultTableToAlter=N'#Result', @LikeTable=N'#Shape', @KeepData=0;
*/

-- toolbelt_core.VW_SecondSessionProviders
-- Katalogsicht auf gespeicherten Second-Session-Provider und sichtbare Linked-Server-Flags.
-- Voraussetzung: Installiertes Modul mit dieser Tabelle, SQL2019/2022/2025 Windows/Linux gemäß Modulmatrix, passende CL150/160/170, lokal/zentral. Die Sicht benötigt zusätzlich bestehende Sichtbarkeit in master.sys.servers. Die DDL selbst prüft keine funktionierende Remoteverbindung, Treiberverfügbarkeit oder Datenbank-/Serveridentität.
/* Separat auswählen und ausführen:
SELECT ProviderName,IsEnabled,LinkedServerExists,RpcOutEnabled,RemoteProcTransactionPromotionEnabled
FROM toolbelt_core.VW_SecondSessionProviders;
-- Keine Zeile: kein gespeicherter Provider.
-- Flags sind sichtbare Katalogzustände, kein Connectivity-/TLS-Test.
*/

-- toolbelt_core.USP_ConfigureSecondSessionLoopback
-- Verknüpft das Modul mit einem bereits administrativ eingerichteten Loopback-Linked-Server. Das Modul legt weder Linked Server noch Login-Mappings oder Credentials an.
-- Voraussetzung: SQL Server 2019/2022/2025 Windows/Linux gemäß Modulmatrix, passende CL150/160/170, lokal/zentral. Diese Prozedur läuft im Toolbelt-Zielkatalog. Vorhandener sichtbarer is_linked=1-Eintrag in master.sys.servers, RPC OUT=1, Remote-Proc-Transaction-Promotion=0. Remote-Ziel muss unter DB_NAME() den kanonischen USP_SecondSessionProbe mit passenden Rechten erreichen. Probe gilt auch für Enabled=0 und vor der Providerzeilenänderung. Name und SQL-Typ sind kein Connection String; QUOTENAME schützt die dynamischen Objektidentifier. Datenbankname/SPID der Probe sind Rückgabedaten, kein kryptografischer Nachweis derselben physischen SQLinstanz; das tatsächliche Loopbackziel ist administrativ festzulegen.
/* Separat auswählen und ausführen:
-- Vorhandener administrativ korrekter synthetischer Loopback vorausgesetzt.
EXEC toolbelt_core.USP_ConfigureSecondSessionLoopback @LinkedServerName=N'ContosoLoopback',@Enabled=1;
-- Führt Probe-RPC aus und kann Konfigurationsdaten ändern.
EXEC toolbelt_core.USP_ConfigureSecondSessionLoopback @Hilfe=1;
*/

-- toolbelt_core.USP_ExecuteWorkTypeInNewSession
-- Führt einen registrierten Work Type synchron in einer getrennten SQL-Server-Session aus. Raw SQL ist ausgeschlossen; der Provider muss rpc out aktiv und Remote-Transaction-Promotion deaktiviert haben.
-- Voraussetzung: SQL Server 2019/2022/2025 Windows/Linux gemäß Modulmatrix, passende CL150/160/170, lokal/zentral. Diese Prozedur läuft im Toolbelt-Zielkatalog. Aktiver registrierter lokaler WorkType mit NONE oder JSON_PAYLOAD, sichtbare gültige lokale App-Policy EXECUTE_NEW_SESSION. Aktivierter gespeicherter loopback-Provider mit sichtbarem LinkedServerExists=1,RpcOutEnabled=1,Promotion=0; gültige Remote-Anmeldung und installierter Dispatcher in derselben benannten Toolbelt-DB. Remote ebenfalls aktive Registrierung/Policy/Handler-EXECUTE/korrekte Signatur. Keine automatische Provideranlage oder Umstellung nach Verbindungsfehler.
/* Separat auswählen und ausführen:
-- Registrierter, erlaubter synthetischer NONE-Handler vorausgesetzt.
EXEC toolbelt_core.USP_ExecuteWorkTypeInNewSession @WorkTypeName='contoso.noop';
-- Infrastrukturzeile einschließlich HandlerReturnCode bewusst auswerten.
EXEC toolbelt_core.USP_ExecuteWorkTypeInNewSession @Hilfe=1;
*/

-- toolbelt_core.VW_WorkQueue
-- Öffentliche Queue-Statusprojektion ohne PayloadJson, ClaimToken und Managedtoken.
-- Voraussetzung: SQL2019/2022/2025 Windows/Linux mit zulässigem CL150/160/170, lokal oder zentral in der Moduldatenbank; WorkType- und Queue-Objekte installiert. Keine CLR-/Datei-/Netzwerkabhängigkeit dieser Relation. Der aktuelle gemeinsame Installer ist markerfrei/create-only; keine eigenständige Ausführung alter Upgradezweige oder automatische Reparatur aus diesem Skill. Bestehende Objekte werden erhalten, daher setzt der hier beschriebene Vertrag eine passende aktuelle Definition voraus.
/* Separat auswählen und ausführen:
SELECT WorkItemId,WorkTypeName,Status,IsLeaseExpired
FROM toolbelt_core.VW_WorkQueue ORDER BY WorkItemId;
*/

-- toolbelt_core.VW_WorkQueueBarrierBlockers
-- Öffentliche Barrier-Snapshotprojektion mit aktuellem Claimgenerationsvergleich.
-- Voraussetzung: SQL2019/2022/2025 Windows/Linux mit zulässigem CL150/160/170, lokal oder zentral in der Moduldatenbank; WorkType- und Queue-Objekte installiert. Keine CLR-/Datei-/Netzwerkabhängigkeit dieser Relation. Der aktuelle gemeinsame Installer ist markerfrei/create-only; keine eigenständige Ausführung alter Upgradezweige oder automatische Reparatur aus diesem Skill. Bestehende Objekte werden erhalten, daher setzt der hier beschriebene Vertrag eine passende aktuelle Definition voraus.
/* Separat auswählen und ausführen:
SELECT BarrierWorkItemId,BarrierEpoch,BlockingWorkItemId,BlockingClaimGeneration,IsResolved
FROM toolbelt_core.VW_WorkQueueBarrierBlockers
ORDER BY BarrierWorkItemId,BarrierEpoch,BlockingWorkItemId;
*/

-- toolbelt_core.USP_EnqueueWork
-- Reiht genau ein Work Item für einen registrierten, aktiven Work Type ein. Es wird niemals SQL-Text entgegengenommen oder ausgeführt.
-- Voraussetzung: Kanonische Queue2.1.0 einschließlich WorkType/ResultTable derselben Datenbank. SQL2019/2022/2025 unter Windows/Linux mit geeignetem CL150/160/170 gemäß Modulmatrix. Tatsächlich registrierter aktiver WorkType mit ENQUEUE-Policy und passendem ParameterMode. Nur einfaches Enqueue verlangt zusätzlich sichtbaren P/PC-Handler; kein Handleraufruf. Gesunder Caller-TX ist möglich; keine pauschale Caller-TX-Sperre. Alle Parameter haben technische Defaults für Hilfe; fachliche NULL-Pflichtwerte sind keine gültigen Ersatzwerte. SQL-Typbindung passiert vor dem Prozedurcode.
/* Separat auswählen und ausführen:
EXEC toolbelt_core.USP_EnqueueWork @Hilfe=1;

-- Voraussetzung: tatsächlich registrierter autorisierter NONE-Handler.
EXEC toolbelt_core.USP_EnqueueWork @WorkTypeName='contoso.noop';
-- Erneuter Aufruf erzeugt ein weiteres Item, keine Idempotency-Replaygarantie.
*/

-- toolbelt_core.USP_EnqueueWorkWithPolicy
-- Reiht je nach ExecutionMode SHARED- oder DRAIN_BARRIER-Arbeit mit unveränderlicher Retry-Policy und optionalem Idempotency Key ein.
-- Voraussetzung: Kanonische Queue2.1.0 einschließlich WorkType/ResultTable derselben Datenbank. SQL2019/2022/2025 unter Windows/Linux mit geeignetem CL150/160/170 gemäß Modulmatrix. Tatsächlich registrierter aktiver WorkType mit ENQUEUE-Policy und passendem ParameterMode. Nur einfaches Enqueue verlangt zusätzlich sichtbaren P/PC-Handler; kein Handleraufruf. DRAIN_BARRIER verlangt@@TRANCOUNT0; SHARED unterstützt gesunden Caller-TX/Savepoint. Alle Parameter haben technische Defaults für Hilfe; fachliche NULL-Pflichtwerte sind keine gültigen Ersatzwerte. SQL-Typbindung passiert vor dem Prozedurcode.
/* Separat auswählen und ausführen:
EXEC toolbelt_core.USP_EnqueueWorkWithPolicy @Hilfe=1;

-- Voraussetzung: tatsächlich registrierter autorisierter NONE-Handler.
EXEC toolbelt_core.USP_EnqueueWorkWithPolicy
 @WorkTypeName='contoso.noop',@IdempotencyKey='contoso.request.1',
 @ExecutionGroup='contoso.group',@Priority=10,@ExecutionMode='SHARED',
 @MaxAttempts=3,@RetryBaseDelaySeconds=60,@RetryMaxDelaySeconds=3600;
-- Gleicher Key wird nur mit tatsächlich gleicher Policy wiederverwendet.
*/

-- toolbelt_core.USP_EnqueueBarrierWork
-- Reiht DRAIN_BARRIER-Arbeit ein, die vor ihrem exklusiven Claim die relevanten aktiven Claims derselben ExecutionGroup abwartet; Retry-Policy und optionaler Idempotency Key bleiben gebunden.
-- Voraussetzung: Kanonische Queue2.1.0 einschließlich WorkType/ResultTable derselben Datenbank. SQL2019/2022/2025 unter Windows/Linux mit geeignetem CL150/160/170 gemäß Modulmatrix. Tatsächlich registrierter aktiver WorkType mit ENQUEUE-Policy und passendem ParameterMode. Nur einfaches Enqueue verlangt zusätzlich sichtbaren P/PC-Handler; kein Handleraufruf. DRAIN_BARRIER verlangt@@TRANCOUNT0; SHARED unterstützt gesunden Caller-TX/Savepoint. Alle Parameter haben technische Defaults für Hilfe; fachliche NULL-Pflichtwerte sind keine gültigen Ersatzwerte. SQL-Typbindung passiert vor dem Prozedurcode.
/* Separat auswählen und ausführen:
EXEC toolbelt_core.USP_EnqueueBarrierWork @Hilfe=1;

-- Ohne Caller-TX; registrierter autorisierter NONE-Handler erforderlich.
EXEC toolbelt_core.USP_EnqueueBarrierWork
 @WorkTypeName='contoso.noop',@ExecutionGroup='contoso.group',@Priority=10;
*/

-- toolbelt_core.USP_ClaimWork
-- Atomarer prioritäts- und barriergesteuerter Queueclaim mit begrenzter Lease. Öffentlicher Einstieg.
-- Voraussetzung: Passende Queue2.1.0 mit WorkType-/ResultTable-Abhängigkeiten derselben Moduldatenbank. SQL2019/2022/2025 Windows/Linux mit zulässigem CL150/160/170,lokal/zentral. Tatsächliche aktuelle IDs/Token aus autorisierten Claim-/Statusausgaben verwenden. Keine Callertransaktion im öffentlichen Claimpfad. Private Managed-Admission verlangt genau eine gesunde bestehende Transaktion und passende Gatebindung. Hilfe ignoriert Fachargumente und kehrt vor Datenzugriff/Mutation zurück; SQL-Typkonvertierung liegt vorher.
/* Separat auswählen und ausführen:
EXEC toolbelt_core.USP_ClaimWork @Hilfe=1;

EXEC toolbelt_core.USP_ClaimWork @LeaseDurationSeconds=300;
-- Null oder eine vertrauliche tatsächliche Claimzeile sicher übernehmen.
*/

-- toolbelt_core.USP_RenewWorkLease
-- Verlängert eine noch aktive Lease mit passendem ClaimToken um ihre beim Claim festgelegte Dauer ab Engine-Zeit. Eine abgelaufene Lease wird nicht wiederbelebt.
-- Voraussetzung: Queue 2.1.0 mit WorkType-/ResultTableabhängigkeiten derselben Datenbank. SQL2019/2022/2025 auf Windows/Linux mit zulässigem CL150/160/170 gemäß Modulmatrix. Keine Callertransaktion. Nur eigene aktuelle Claim-ID/Token verwenden; die Lease muss noch aktiv sein. Clientzeiten verlängern keine Enginelease. Alle Argumente haben technische Defaults für Hilfe; erforderliche NULL-Fachwerte bleiben ungültig. SQL-Typbindung und Breitenkonvertierung liegen vor dem Code.
/* Separat auswählen und ausführen:
EXEC toolbelt_core.USP_RenewWorkLease @Hilfe=1;

-- Eigene aktive Claim-ID/Token einsetzen, keine fremden Bindings.
DECLARE @Token uniqueidentifier='00000000-0000-0000-0000-000000000001';
EXEC toolbelt_core.USP_RenewWorkLease @WorkItemId=1,@ClaimToken=@Token;
*/

-- toolbelt_core.USP_RecoverExpiredWork
-- Plant für abgelaufene Claims nach der gespeicherten Retry-Policy RETRY_WAIT oder DEAD_LETTER. Alte ClaimTokens werden atomar invalidiert.
-- Voraussetzung: Queue 2.1.0 mit WorkType-/ResultTableabhängigkeiten derselben Datenbank. SQL2019/2022/2025 auf Windows/Linux mit zulässigem CL150/160/170 gemäß Modulmatrix. Keine Callertransaktion. Expliziter Supervisorbatch; keine Übernahme von Managed-/Holditems. MaxItems 1..1000 begrenzt die Zahl ausgewählter Items. Alle Argumente haben technische Defaults für Hilfe; erforderliche NULL-Fachwerte bleiben ungültig. SQL-Typbindung und Breitenkonvertierung liegen vor dem Code.
/* Separat auswählen und ausführen:
EXEC toolbelt_core.USP_RecoverExpiredWork @Hilfe=1;

-- Autorisierter Supervisor, ohne Caller-TX:
EXEC toolbelt_core.USP_RecoverExpiredWork @MaxItems=100;
*/

-- toolbelt_core.USP_CompleteWork
-- Schließt genau ein CLAIMED Work Item mit dem passenden ClaimToken als COMPLETED ab. Ein fachliches Arbeitsergebnis wird in E1a nicht gespeichert.
-- Voraussetzung: Queue 2.1.0 mit WorkType-/ResultTableabhängigkeiten derselben Datenbank. SQL2019/2022/2025 auf Windows/Linux mit zulässigem CL150/160/170 gemäß Modulmatrix. Ein gesunder Caller-TX ist zulässig. ManagedCompletion verlangt den geschützten äußeren TX, Nonce und AppLock. Ein einfacher aktiver Claim darf einen eigenen TX verwenden. Alle Argumente haben technische Defaults für Hilfe; erforderliche NULL-Fachwerte bleiben ungültig. SQL-Typbindung und Breitenkonvertierung liegen vor dem Code.
/* Separat auswählen und ausführen:
EXEC toolbelt_core.USP_CompleteWork @Hilfe=1;

-- Eigene aktive Claim-ID/Token einsetzen, keine fremden Bindings.
DECLARE @Token uniqueidentifier='00000000-0000-0000-0000-000000000001';
EXEC toolbelt_core.USP_CompleteWork @WorkItemId=1,@ClaimToken=@Token;
*/

-- toolbelt_core.USP_FailWork
-- Tokengebundener endgültiger FAILED-Abschluss eines aktiven Queueclaims. Öffentlicher Einstieg.
-- Voraussetzung: Passende Queue2.1.0 mit WorkType-/ResultTable-Abhängigkeiten derselben Moduldatenbank. SQL2019/2022/2025 Windows/Linux mit zulässigem CL150/160/170,lokal/zentral. Tatsächliche aktuelle IDs/Token aus autorisierten Claim-/Statusausgaben verwenden. Eigene Transaktion oder gesunder Caller-TX mit Savepoint ist im vorhandenen Kern möglich; nicht pauschal als verboten beschreiben. Hilfe ignoriert Fachargumente und kehrt vor Datenzugriff/Mutation zurück; SQL-Typkonvertierung liegt vorher.
/* Separat auswählen und ausführen:
EXEC toolbelt_core.USP_FailWork @Hilfe=1;

-- Tatsächliche eigene Claim-ID/Token ersetzen diese synthetischen Werte:
DECLARE @Token uniqueidentifier='00000000-0000-0000-0000-000000000001';
EXEC toolbelt_core.USP_FailWork @WorkItemId=1,@ClaimToken=@Token,@FailureCode='CONTOSO.TRANSIENT';
-- Kein freier Replaypfad; falsche/nicht vorhandene Bindung ist kein erfolgreicher Übergang.
*/

-- toolbelt_core.USP_ScheduleWorkRetry
-- Tokengebundene Retry-/Dead-Letter-Entscheidung nach gespeicherter Queuepolicy. Öffentlicher Einstieg.
-- Voraussetzung: Passende Queue2.1.0 mit WorkType-/ResultTable-Abhängigkeiten derselben Moduldatenbank. SQL2019/2022/2025 Windows/Linux mit zulässigem CL150/160/170,lokal/zentral. Tatsächliche aktuelle IDs/Token aus autorisierten Claim-/Statusausgaben verwenden. Eigene Transaktion oder gesunder Caller-TX mit Savepoint ist im vorhandenen Kern möglich; nicht pauschal als verboten beschreiben. Hilfe ignoriert Fachargumente und kehrt vor Datenzugriff/Mutation zurück; SQL-Typkonvertierung liegt vorher.
/* Separat auswählen und ausführen:
EXEC toolbelt_core.USP_ScheduleWorkRetry @Hilfe=1;

-- Tatsächliche eigene Claim-ID/Token ersetzen diese synthetischen Werte:
DECLARE @Token uniqueidentifier='00000000-0000-0000-0000-000000000001';
EXEC toolbelt_core.USP_ScheduleWorkRetry @WorkItemId=1,@ClaimToken=@Token,@FailureCode='CONTOSO.TRANSIENT';
-- Kein freier Replaypfad; falsche/nicht vorhandene Bindung ist kein erfolgreicher Übergang.
*/

-- toolbelt_core.USP_RequeueDeadLetter
-- Beginnt für ein Dead-Letter-Item einen neuen Retry-Zyklus.
-- Voraussetzung: Queue 2.1.0 mit WorkType-/ResultTableabhängigkeiten derselben Datenbank. SQL2019/2022/2025 auf Windows/Linux mit zulässigem CL150/160/170 gemäß Modulmatrix. Keine Callertransaktion. Aktuell DEAD_LETTER, nicht gehalten und nicht Managed. Aktuelle RowVersion für optionales CAS; NULL deaktiviert CAS. Keine freie Freigabe unbekannter Ownership. Alle Argumente haben technische Defaults für Hilfe; erforderliche NULL-Fachwerte bleiben ungültig. SQL-Typbindung und Breitenkonvertierung liegen vor dem Code.
/* Separat auswählen und ausführen:
EXEC toolbelt_core.USP_RequeueDeadLetter @Hilfe=1;

-- Synthetische ID/RowVersion durch das eigene tatsächliche DEAD_LETTER-Item ersetzen.
EXEC toolbelt_core.USP_RequeueDeadLetter @WorkItemId=1,
 @ExpectedRowVersion=0x0000000000000001,@RequeueReason=N'Contoso: Ursache behoben';
*/

-- toolbelt_core.USP_GetWorkStatus
-- Liefert genau eine Statuszeile für ein Work Item. Payload und ClaimToken werden bewusst nicht offengelegt.
-- Voraussetzung: Kanonische Queue2.1.0 einschließlich WorkType/ResultTable derselben Datenbank. SQL2019/2022/2025 unter Windows/Linux mit geeignetem CL150/160/170 gemäß Modulmatrix. Tatsächliches existierendes Item; kein aktiver/registrierter Handler für reine Statuslesung erforderlich. Gesunder Caller-TX ist möglich; keine pauschale Caller-TX-Sperre. Alle Parameter haben technische Defaults für Hilfe; fachliche NULL-Pflichtwerte sind keine gültigen Ersatzwerte. SQL-Typbindung passiert vor dem Prozedurcode.
/* Separat auswählen und ausführen:
EXEC toolbelt_core.USP_GetWorkStatus @Hilfe=1;

-- Synthetische ID durch die eigene tatsächliche Enqueue-/Claim-ID ersetzen.
EXEC toolbelt_core.USP_GetWorkStatus @WorkItemId=1;
-- Statuslesung liefert weder Payload noch ClaimToken.
*/

-- toolbelt_core.USP_SetWorkTypePermission
-- Konfiguriert eine ausdrückliche Work-Type-Delegation an einen vorhandenen Datenbankprincipal.
-- Voraussetzung: SQL Server 2019/2022/2025 auf Windows/Linux, passende CL150/160/170, lokal/zentral. WorkType-Katalog und Policyobjekte in derselben Datenbank; zentrale Verwendung wertet den tatsächlichen DBtoken dieses Katalogs aus. Kein Second-Session- oder Queue-Provider für diese lokale Policyverwaltung/-entscheidung erforderlich. Eine Policy bindet WorkTypeId, Aktion, tatsächliche DBprincipal-ID/SID/create_date und exakte binary(8)-RowVersion des Work Types. Ändert sich dessen RowVersion oder wird ein Principal unter neuer Identität wiederangelegt, wird die alte Zeile unwirksam statt automatisch übernommen. Aktuelle sys.user_token-Zeilen einschließlich wirksamer Rollen werden im jeweiligen Katalog ausgewertet; kein frei übergebener Actor/Name kann einen Callertoken ersetzen. Principal muss im lokalen sys.database_principals sichtbar sein, type in S/U/G/R/E/X und principal_id ungleich 0; keine Erstellung fehlender Identitäten. Work Type muss registriert sein, nicht zwingend enabled. Auch REMOVE setzt vorhandenen Principal und Work Type voraus und ist kein allgemeiner Bereiniger verwaister Zeilen.
/* Separat auswählen und ausführen:
-- Bestehender synthetischer Work Type und DBprincipal sind Voraussetzung.
EXEC toolbelt_core.USP_SetWorkTypePermission @WorkTypeName='contoso.noop',@Principal=N'ContosoProducer',@PermissionName='ENQUEUE',@PermissionState='ALLOW';
-- Persistente App-Delegation, nur im autorisierten Verwaltungsscope.
EXEC toolbelt_core.USP_SetWorkTypePermission @Hilfe=1;
*/

-- toolbelt_core.VW_WorkTypes
-- Liest den Work-Type-Katalog einschließlich Handlername und sichtbarer Handlerexistenz.
-- Voraussetzung: Work-Type-Modul in der gewählten Moduldatenbank installiert und lesbar. Bei zentraler Installation gegebenenfalls dreiteiligen Namen verwenden. Kein Aufrufparameter.
/* Separat auswählen und ausführen:
SELECT WorkTypeName,HandlerQualifiedName,ParameterMode,IsEnabled,HandlerExists
FROM toolbelt_core.VW_WorkTypes
ORDER BY WorkTypeName;
*/

-- toolbelt_core.USP_RegisterWorkType
-- Registriert ausschließlich eine vorhandene Stored Procedure als benannten Work Type. SQL-Text wird weder angenommen noch gespeichert.
-- Voraussetzung: SQL Server 2019/2022/2025 Windows/Linux mit passenden CL150/160/170, lokal/zentral. WorkType und VW_WorkTypes in derselben Datenbank, sichtbare vorhandene Handlerprozedur P/PC in dieser Datenbank, nicht sys oder is_ms_shipped. Vorhandenes Handler-EXECUTE des registrierenden Principals erforderlich. Für Routing zusätzlich existierender sameDB ResultTable-Helper und gültige lokale Caller-Temp. ParameterMode ist eine Deklaration: diese Prozedur prüft NICHT die passende Handler-Parametersignatur; der spätere Dispatcher prüft diese separat. NONE ohne Payloadvertrag; JSON_PAYLOAD verlangt ein JSON-Objekt nach ISJSON und { nach LTRIM gewöhnlicher Spaces, kein ausführbares JSON-Schema.
/* Separat auswählen und ausführen:
-- Vorhandener synthetischer Handler dbo.ContosoNoop ohne Parameter vorausgesetzt.
EXEC toolbelt_core.USP_RegisterWorkType @WorkTypeName='contoso.noop',@HandlerSchema=N'dbo',@HandlerProcedure=N'ContosoNoop',@ParameterMode='NONE';
-- Ändert den Katalog im autorisierten Verwaltungsscope; kein Handleraufruf.
EXEC toolbelt_core.USP_RegisterWorkType @Hilfe=1;
*/

-- toolbelt_core.USP_DisableWorkType
-- Deaktiviert einen registrierten Work Type idempotent und erhält seine Konfiguration.
-- Voraussetzung: WorkType-Katalog und VW_WorkTypes in derselben Datenbank, SQL Server 2019/2022/2025 Windows/Linux mit passenden CL150/160/170, lokal/zentral. Für ResultTable zusätzlich vorhandener sameDB ResultTable-Helper und gültige caller-lokale Temp. Keine automatische Dependencyinstallation. ExpectedRowVersion NULL deaktiviert nur den optimistischen Versionsvergleich; sonst exakte binary(8)-Bytes aus zuletzt gelesenem Katalog verwenden, keinen Hextext. Already-disabled mit NULL-Grund ist ein No-op, die optionale RowVersion-Prüfung gilt trotzdem. Jede tatsächliche Änderung erzeugt neue RowVersion und macht ältere gebundene WorkType-Policies unwirksam, bis sie ausdrücklich neu konfiguriert werden.
/* Separat auswählen und ausführen:
EXEC toolbelt_core.USP_DisableWorkType @WorkTypeName='contoso.noop',@DisabledReason=N'Synthetic maintenance';
-- Persistente Änderung, bestehender synthetischer Eintrag erforderlich.
EXEC toolbelt_core.USP_DisableWorkType @Hilfe=1;
*/

-- toolbelt_core.USP_RemoveWorkType
-- Entfernt ausschließlich einen bereits deaktivierten Work Type. Die explizite Datenverlustfreigabe und optionale RowVersion-Prüfung verhindern versehentliche oder konkurrierende Löschungen.
-- Voraussetzung: WorkType-Katalog und VW_WorkTypes in derselben Datenbank, SQL Server 2019/2022/2025 Windows/Linux mit passenden CL150/160/170, lokal/zentral. Für ResultTable zusätzlich vorhandener sameDB ResultTable-Helper und gültige caller-lokale Temp. Keine automatische Dependencyinstallation. ExpectedRowVersion NULL deaktiviert nur den optimistischen Versionsvergleich; sonst exakte binary(8)-Bytes aus zuletzt gelesenem Katalog verwenden, keinen Hextext. Aktive Einträge können nicht entfernt werden. Bestehende Referenzen können den DELETE durch Engine-/FK-Fehler verhindern; kein automatisches Entfernen von Workitems oder anderen Verbrauchern.
/* Separat auswählen und ausführen:
EXEC toolbelt_core.USP_RemoveWorkType @WorkTypeName='contoso.noop',@AllowDelete=1;
-- Nur bereits deaktivierter synthetischer Eintrag im autorisierten Scope.
EXEC toolbelt_core.USP_RemoveWorkType @Hilfe=1;
*/

-- toolbelt_core.USP_ResolveWorkType
-- Löst einen registrierten Work Type auf und kann Enabled-, Existenz- und Caller-EXECUTE-Vertrag erzwingen.
-- Voraussetzung: WorkType-Katalog und VW_WorkTypes in derselben Datenbank, SQL Server 2019/2022/2025 Windows/Linux mit passenden CL150/160/170, lokal/zentral. Für ResultTable zusätzlich vorhandener sameDB ResultTable-Helper und gültige caller-lokale Temp. Keine automatische Dependencyinstallation. RequireEnabled und RequireExecutableByCaller NULL=>1; RequiredPermission NULL bedeutet keine App-Policyprüfung. SuppressResult muss 0/1 sein, NULL oder 1 mit ResultTable wird abgewiesen. Ein deaktivierter Eintrag ist mit RequireEnabled=0 möglich; der Handler muss dennoch sichtbar existieren. RequireExecutableByCaller=0 überspringt nur dessen EXECUTE-Check, verleiht kein Recht.
/* Separat auswählen und ausführen:
EXEC toolbelt_core.USP_ResolveWorkType @WorkTypeName='contoso.noop',@RequiredPermission='EXECUTE_NEW_SESSION',@SuppressResult=1;
-- Nur Preflight; registrierter Handler, bestehende Rechte und Policy nötig.
EXEC toolbelt_core.USP_ResolveWorkType @Hilfe=1;
*/

-- toolbelt_core.VW_WorkerStatus
-- Öffentliche tokenfreie Statusprojektion aller registrierten Worker-generationen.
-- Voraussetzung: Installiertes Worker-Control1.0.0 und passende Queue2.1.0-/ExecutionContext-/Cancellation-/ResultTable-Abhängigkeiten derselben Moduldatenbank. SQL2019/2022/2025 Windows/Linux mit zulässigem CL150/160/170, lokal/zentral. Markerfreier create-only-Installer erhält vorhandene Objekte; hier ist eine passende aktuelle Definition vorausgesetzt, kein eigenständiges CREATE/Upgrade aus dem Skill. Keine CLR-/Datei-/Netzwerk-/LLM-Aufrufe der Relation.
/* Separat auswählen und ausführen:
SELECT WorkerId,WorkerGeneration,State,Capacity,OccupiedSlots,ConfigVersion
FROM toolbelt_core.VW_WorkerStatus ORDER BY WorkerId,WorkerGeneration;
*/

-- toolbelt_core.VW_WorkerExecutionStatus
-- Öffentliche tokenfreie Reservationshistorie mit exakt passender aktueller Hold-Disposition.
-- Voraussetzung: Installiertes Worker-Control1.0.0 und passende Queue2.1.0-/ExecutionContext-/Cancellation-/ResultTable-Abhängigkeiten derselben Moduldatenbank. SQL2019/2022/2025 Windows/Linux mit zulässigem CL150/160/170, lokal/zentral. Markerfreier create-only-Installer erhält vorhandene Objekte; hier ist eine passende aktuelle Definition vorausgesetzt, kein eigenständiges CREATE/Upgrade aus dem Skill. Keine CLR-/Datei-/Netzwerk-/LLM-Aufrufe der Relation.
/* Separat auswählen und ausführen:
SELECT SlotReservationId,WorkItemId,ClaimGeneration,State,IsHeld,HoldVersion,StopStatus
FROM toolbelt_core.VW_WorkerExecutionStatus ORDER BY WorkItemId,ClaimGeneration;
*/

-- toolbelt_core.USP_ClaimWorkerWork
-- Öffentlicher Einstieg für atomare Managed-Admission eines eigenen Workers.
-- Voraussetzung: Worker-Control 1.0.0 mit passender Queue 2.1.0 sowie Context-, Cancellation- und ResultTable-Integration derselben Moduldatenbank. SQL Server 2019/2022/2025 auf Windows/Linux mit zulässigem CL150/160/170, lokal oder zentral. Der Fachpfad verlangt @@TRANCOUNT=0 und XACT_STATE()=0; keine Caller-Savepoints. Bestehende IDs, Generationen und Versionen aus tatsächlichen autorisierten Ausgaben übernehmen. Hostnamen, SPIDs oder frei gewählte UUIDs ersetzen diese Bindungen nicht. Hilfe ist mit technischen Defaults ohne Fachwerte aufrufbar.
/* Separat auswählen und ausführen:
EXEC toolbelt_core.USP_ClaimWorkerWork @Hilfe=1;

-- IDs/Token aus tatsächlicher eigener Registrierung verwenden:
DECLARE @Id uniqueidentifier='00000000-0000-0000-0000-000000000001',@Token uniqueidentifier='00000000-0000-0000-0000-000000000002';
EXEC toolbelt_core.USP_ClaimWorkerWork @WorkerId=@Id,@WorkerGeneration=1,@WorkerToken=@Token;
-- Synthetische Bindung ohne Registrierung wird abgewiesen; echte Ausgabe privat behandeln.
*/

-- toolbelt_core.USP_CloseWorker
-- Schließt eine exakt token-/principalgebundene Generation ohne belegte Reservations.
-- Voraussetzung: Worker-Control 1.0.0 mit passender Queue 2.1.0 sowie Context-, Cancellation- und ResultTable-Integration derselben Moduldatenbank. SQL Server 2019/2022/2025 auf Windows/Linux mit zulässigem CL150/160/170, lokal oder zentral. Der Fachpfad verlangt @@TRANCOUNT=0 und XACT_STATE()=0; keine Caller-Savepoints. Bestehende IDs, Generationen und Versionen aus tatsächlichen autorisierten Ausgaben übernehmen. Hostnamen, SPIDs oder frei gewählte UUIDs ersetzen diese Bindungen nicht. Hilfe ist mit technischen Defaults ohne Fachwerte aufrufbar.
/* Separat auswählen und ausführen:
EXEC toolbelt_core.USP_CloseWorker @Hilfe=1;

-- Synthetische Bindung durch die eigene tatsächliche Registrierung ersetzen:
DECLARE @Id uniqueidentifier='00000000-0000-0000-0000-000000000001',@Token uniqueidentifier='00000000-0000-0000-0000-000000000002';
EXEC toolbelt_core.USP_CloseWorker @WorkerId=@Id,@WorkerGeneration=1,@WorkerToken=@Token;
*/

-- toolbelt_core.USP_DisableManagedWorkers
-- Deaktiviert Managed-Admission versionsgebunden nur ohne aktive Claims, belegte Reservations und Holds.
-- Voraussetzung: Worker-Control1.0.0 mit passender Queue2.1.0, WorkerControlConfiguration, WorkQueueManagedGate und WorkQueueScheduler in derselben Moduldatenbank. SQL2019/2022/2025 Windows/Linux mit zulässigem CL150/160/170, lokal/zentral. Fachaufruf verlangt @@TRANCOUNT0 und XACT_STATE0. Frische exakte globale ConfigVersion aus autorisierter Ausgabe übernehmen, kein erfundener Default. Optionales ResultTable-Routing benötigt den installierten Helper und eine geeignete vom Caller angelegte lokale Temp. Hilfe benötigt keine gültigen Fachwerte oder Tabellenabfragen.
/* Separat auswählen und ausführen:
EXEC toolbelt_core.USP_DisableManagedWorkers @Hilfe=1;

-- Synthetischer Versionswert: durch frische Ausgabe eines autorisierten
-- Konfigurations-/Registrierungsaufrufs ersetzen; kein Rowversion-Zahlentext.
DECLARE @Expected binary(8)=0x0000000000000001;
EXEC toolbelt_core.USP_DisableManagedWorkers @ExpectedConfigVersion=@Expected;
-- Ein veralteter Beispielwert wird ausdrücklich mit54212 abgewiesen.
*/

-- toolbelt_core.USP_EnableManagedWorkers
-- Aktiviert Managed-Admission versionsgebunden nur ohne aktive Claims, belegte Reservations und Holds.
-- Voraussetzung: Worker-Control1.0.0 mit passender Queue2.1.0, WorkerControlConfiguration, WorkQueueManagedGate und WorkQueueScheduler in derselben Moduldatenbank. SQL2019/2022/2025 Windows/Linux mit zulässigem CL150/160/170, lokal/zentral. Fachaufruf verlangt @@TRANCOUNT0 und XACT_STATE0. Frische exakte globale ConfigVersion aus autorisierter Ausgabe übernehmen, kein erfundener Default. Optionales ResultTable-Routing benötigt den installierten Helper und eine geeignete vom Caller angelegte lokale Temp. Hilfe benötigt keine gültigen Fachwerte oder Tabellenabfragen.
/* Separat auswählen und ausführen:
EXEC toolbelt_core.USP_EnableManagedWorkers @Hilfe=1;

-- Synthetischer Versionswert: durch frische Ausgabe eines autorisierten
-- Konfigurations-/Registrierungsaufrufs ersetzen; kein Rowversion-Zahlentext.
DECLARE @Expected binary(8)=0x0000000000000001;
EXEC toolbelt_core.USP_EnableManagedWorkers @ExpectedConfigVersion=@Expected;
-- Ein veralteter Beispielwert wird ausdrücklich mit54212 abgewiesen.
*/

-- toolbelt_core.USP_HeartbeatWorker
-- Erneuert die Heartbeatzeit einer token-/principalgebundenen, noch nicht abgelaufenen Generation.
-- Voraussetzung: Passendes Worker-Control1.0.0 mit Queue2.1.0 und seinen Context-/Cancellation-/ResultTable-Abhängigkeiten derselben Moduldatenbank. SQL2019/2022/2025 Windows/Linux, zulässiges CL150/160/170, lokal/zentral. Fachaufruf benötigt neutralen Callertransaktionszustand sowie Gate1,Scheduler1,Konfiguration1. Hilfe ist mit technischen Defaults ohne Fachargumente möglich. Keine CLR-/Datei-/Netzwerkabhängigkeit dieses Aufrufs.
/* Separat auswählen und ausführen:
EXEC toolbelt_core.USP_HeartbeatWorker @Hilfe=1;

-- Synthetische Identitäten ersetzen durch tatsächliches eigenes Registrierungsresultat:
DECLARE @Id uniqueidentifier='00000000-0000-0000-0000-000000000001',
 @Token uniqueidentifier='00000000-0000-0000-0000-000000000002';
EXEC toolbelt_core.USP_HeartbeatWorker @WorkerId=@Id,@WorkerGeneration=1,@WorkerToken=@Token;
-- Beispielwerte ohne passende Registrierung ergeben54215.
*/

-- toolbelt_core.USP_ReconcileWorkerExecution
-- Klassifiziert eine exakte aktuelle Disposition anhand von Connectionfence und locking Witness-/Absencebelegen.
-- Voraussetzung: Worker-Control 1.0.0 mit passender Queue 2.1.0 sowie Context-, Cancellation- und ResultTable-Integration derselben Moduldatenbank. SQL Server 2019/2022/2025 auf Windows/Linux mit zulässigem CL150/160/170, lokal oder zentral. Der Fachpfad verlangt @@TRANCOUNT=0 und XACT_STATE()=0; keine Caller-Savepoints. Bestehende IDs, Generationen und Versionen aus tatsächlichen autorisierten Ausgaben übernehmen. Hostnamen, SPIDs oder frei gewählte UUIDs ersetzen diese Bindungen nicht. Hilfe ist mit technischen Defaults ohne Fachwerte aufrufbar.
/* Separat auswählen und ausführen:
EXEC toolbelt_core.USP_ReconcileWorkerExecution @Hilfe=1;

-- Nur aktuelle exakte Reservation/Disposition verwenden:
DECLARE @Slot uniqueidentifier='00000000-0000-0000-0000-000000000001',@Hold binary(8)=0x0000000000000001;
EXEC toolbelt_core.USP_ReconcileWorkerExecution @SlotReservationId=@Slot,@ExpectedHoldVersion=@Hold;
-- Nach echter Reconciliation HoldVersion aus VW_WorkerExecutionStatus neu lesen.
*/

-- toolbelt_core.USP_RegisterWorker
-- Erzeugt eine neue principalgebundene Generation einer stabilen WorkerId ohne Übernahme alter Reservations.
-- Voraussetzung: Passendes Worker-Control1.0.0 mit Queue2.1.0 und seinen Context-/Cancellation-/ResultTable-Abhängigkeiten derselben Moduldatenbank. SQL2019/2022/2025 Windows/Linux, zulässiges CL150/160/170, lokal/zentral. Fachaufruf benötigt neutralen Callertransaktionszustand sowie Gate1,Scheduler1,Konfiguration1. Hilfe ist mit technischen Defaults ohne Fachargumente möglich. Keine CLR-/Datei-/Netzwerkabhängigkeit dieses Aufrufs.
/* Separat auswählen und ausführen:
EXEC toolbelt_core.USP_RegisterWorker @Hilfe=1;

DECLARE @Id uniqueidentifier=NEWID();
EXEC toolbelt_core.USP_RegisterWorker @WorkerId=@Id,@Capacity=1,@RunMode='BOUNDED';
-- Registrierungsresultat einschließlich geheimem WorkerToken sicher übernehmen.
*/

-- toolbelt_core.USP_ReleaseHeldWork
-- Gibt einen nachgewiesen zurückgerollten gehaltenen Queueauftrag versionsgebunden für einen neuen Retryzyklus frei.
-- Voraussetzung: Worker-Control 1.0.0 mit passender Queue 2.1.0 sowie Context-, Cancellation- und ResultTable-Integration derselben Moduldatenbank. SQL Server 2019/2022/2025 auf Windows/Linux mit zulässigem CL150/160/170, lokal oder zentral. Der Fachpfad verlangt @@TRANCOUNT=0 und XACT_STATE()=0; keine Caller-Savepoints. Bestehende IDs, Generationen und Versionen aus tatsächlichen autorisierten Ausgaben übernehmen. Hostnamen, SPIDs oder frei gewählte UUIDs ersetzen diese Bindungen nicht. Hilfe ist mit technischen Defaults ohne Fachwerte aufrufbar.
/* Separat auswählen und ausführen:
EXEC toolbelt_core.USP_ReleaseHeldWork @Hilfe=1;

-- Nur nach bewiesenem Rollback und mit frisch gelesener HoldVersion:
DECLARE @Item bigint=1,@Hold binary(8)=0x0000000000000001;
EXEC toolbelt_core.USP_ReleaseHeldWork @WorkItemId=@Item,@ExpectedHoldVersion=@Hold;
-- Synthetische/stale Werte werden abgewiesen; UNKNOWN ist keine Freigabe.
*/

-- toolbelt_core.USP_SetWorkerCapacity
-- Ändert versionsgebunden die lokale Kapazität einer exakt adressierten nicht geschlossenen Generation.
-- Voraussetzung: Passendes Worker-Control1.0.0 mit Queue2.1.0 und seinen Context-/Cancellation-/ResultTable-Abhängigkeiten derselben Moduldatenbank. SQL2019/2022/2025 Windows/Linux, zulässiges CL150/160/170, lokal/zentral. Fachaufruf benötigt neutralen Callertransaktionszustand sowie Gate1,Scheduler1,Konfiguration1. Hilfe ist mit technischen Defaults ohne Fachargumente möglich. Keine CLR-/Datei-/Netzwerkabhängigkeit dieses Aufrufs.
/* Separat auswählen und ausführen:
EXEC toolbelt_core.USP_SetWorkerCapacity @Hilfe=1;

-- Nur mit realer adressierter Workeridentität und frischer globaler Version verwenden:
DECLARE @Id uniqueidentifier='00000000-0000-0000-0000-000000000001',@Version binary(8)=0x0000000000000001;
EXEC toolbelt_core.USP_SetWorkerCapacity @WorkerId=@Id,@WorkerGeneration=1,@Capacity=2,@ExpectedConfigVersion=@Version;
-- Synthetische/veraltete Werte werden abgewiesen.
*/

-- toolbelt_core.USP_SetWorkerConcurrency
-- Ändert das globale Live-Admissionbudget ohne laufende Arbeit abzubrechen.
-- Voraussetzung: Worker-Control1.0.0 mit passender Queue2.1.0, WorkerControlConfiguration, WorkQueueManagedGate und WorkQueueScheduler in derselben Moduldatenbank. SQL2019/2022/2025 Windows/Linux mit zulässigem CL150/160/170, lokal/zentral. Fachaufruf verlangt @@TRANCOUNT0 und XACT_STATE0. Frische exakte globale ConfigVersion aus autorisierter Ausgabe übernehmen, kein erfundener Default. Optionales ResultTable-Routing benötigt den installierten Helper und eine geeignete vom Caller angelegte lokale Temp. Hilfe benötigt keine gültigen Fachwerte oder Tabellenabfragen.
/* Separat auswählen und ausführen:
EXEC toolbelt_core.USP_SetWorkerConcurrency @Hilfe=1;

-- Synthetischer Versionswert: durch frische Ausgabe eines autorisierten
-- Konfigurations-/Registrierungsaufrufs ersetzen; kein Rowversion-Zahlentext.
DECLARE @Expected binary(8)=0x0000000000000001;
EXEC toolbelt_core.USP_SetWorkerConcurrency @MaxConcurrentExecutions=2,@ExpectedConfigVersion=@Expected;
-- Ein veralteter Beispielwert wird ausdrücklich mit54212 abgewiesen.
*/

-- toolbelt_core.USP_SetWorkerIntervals
-- Ändert globale Registrierungsintervalldefaults; bestehende Generationen behalten ihre gespeicherten Werte.
-- Voraussetzung: Worker-Control1.0.0 mit passender Queue2.1.0, WorkerControlConfiguration, WorkQueueManagedGate und WorkQueueScheduler in derselben Moduldatenbank. SQL2019/2022/2025 Windows/Linux mit zulässigem CL150/160/170, lokal/zentral. Fachaufruf verlangt @@TRANCOUNT0 und XACT_STATE0. Frische exakte globale ConfigVersion aus autorisierter Ausgabe übernehmen, kein erfundener Default. Optionales ResultTable-Routing benötigt den installierten Helper und eine geeignete vom Caller angelegte lokale Temp. Hilfe benötigt keine gültigen Fachwerte oder Tabellenabfragen.
/* Separat auswählen und ausführen:
EXEC toolbelt_core.USP_SetWorkerIntervals @Hilfe=1;

-- Synthetischer Versionswert: durch frische Ausgabe eines autorisierten
-- Konfigurations-/Registrierungsaufrufs ersetzen; kein Rowversion-Zahlentext.
DECLARE @Expected binary(8)=0x0000000000000001;
EXEC toolbelt_core.USP_SetWorkerIntervals @HeartbeatSeconds=15,@UnreachableSeconds=60,@ExpectedConfigVersion=@Expected;
-- Ein veralteter Beispielwert wird ausdrücklich mit54212 abgewiesen.
*/

-- toolbelt_core.USP_SetWorkerState
-- Steuert versionsgebunden die neueste noch lebende Worker-generation auf ACTIVE,PAUSED oder DRAINING.
-- Voraussetzung: Passendes Worker-Control1.0.0 mit Queue2.1.0 und seinen Context-/Cancellation-/ResultTable-Abhängigkeiten derselben Moduldatenbank. SQL2019/2022/2025 Windows/Linux, zulässiges CL150/160/170, lokal/zentral. Fachaufruf benötigt neutralen Callertransaktionszustand sowie Gate1,Scheduler1,Konfiguration1. Hilfe ist mit technischen Defaults ohne Fachargumente möglich. Keine CLR-/Datei-/Netzwerkabhängigkeit dieses Aufrufs.
/* Separat auswählen und ausführen:
EXEC toolbelt_core.USP_SetWorkerState @Hilfe=1;

-- Nur mit neuester lebender Workeridentität und frischer globaler Version:
DECLARE @Id uniqueidentifier='00000000-0000-0000-0000-000000000001',@Version binary(8)=0x0000000000000001;
EXEC toolbelt_core.USP_SetWorkerState @WorkerId=@Id,@WorkerGeneration=1,@RequestedState='PAUSED',@ExpectedConfigVersion=@Version;
-- Synthetische/veraltete Werte werden abgewiesen.
*/

-- toolbelt_core.USP_StopWorkerExecution
-- Persistiert versionsgebunden Stop/Hold einer exakten Reservation oder erkennt deren vorherigen Commit.
-- Voraussetzung: Worker-Control 1.0.0 mit passender Queue 2.1.0 sowie Context-, Cancellation- und ResultTable-Integration derselben Moduldatenbank. SQL Server 2019/2022/2025 auf Windows/Linux mit zulässigem CL150/160/170, lokal oder zentral. Der Fachpfad verlangt @@TRANCOUNT=0 und XACT_STATE()=0; keine Caller-Savepoints. Bestehende IDs, Generationen und Versionen aus tatsächlichen autorisierten Ausgaben übernehmen. Hostnamen, SPIDs oder frei gewählte UUIDs ersetzen diese Bindungen nicht. Hilfe ist mit technischen Defaults ohne Fachwerte aufrufbar.
/* Separat auswählen und ausführen:
EXEC toolbelt_core.USP_StopWorkerExecution @Hilfe=1;

-- Reservation und Claimgeneration aus tatsächlicher Claim-/Statuszeile:
DECLARE @Slot uniqueidentifier='00000000-0000-0000-0000-000000000001';
EXEC toolbelt_core.USP_StopWorkerExecution @SlotReservationId=@Slot,@ExpectedClaimGeneration=1;
*/

-- toolbelt_core.USP_StopWorkers
-- Friert eine explizite Worker-generationen-Auswahl ein und persistiert atomar Pause/Stop/Holds.
-- Voraussetzung: Worker-Control 1.0.0 mit passender Queue 2.1.0 sowie Context-, Cancellation- und ResultTable-Integration derselben Moduldatenbank. SQL Server 2019/2022/2025 auf Windows/Linux mit zulässigem CL150/160/170, lokal oder zentral. Der Fachpfad verlangt @@TRANCOUNT=0 und XACT_STATE()=0; keine Caller-Savepoints. Bestehende IDs, Generationen und Versionen aus tatsächlichen autorisierten Ausgaben übernehmen. Hostnamen, SPIDs oder frei gewählte UUIDs ersetzen diese Bindungen nicht. Hilfe ist mit technischen Defaults ohne Fachwerte aufrufbar.
/* Separat auswählen und ausführen:
EXEC toolbelt_core.USP_StopWorkers @Hilfe=1;

CREATE TABLE #ContosoWorkers(WorkerId uniqueidentifier NOT NULL,WorkerGeneration bigint NOT NULL);
-- Nur tatsächlich gewählte vorhandene IDs/Generationen einfügen.
EXEC toolbelt_core.USP_StopWorkers @WorkersTable=N'#ContosoWorkers';
-- Diese leere Beispielauswahl stoppt keinen Worker.
*/

-- toolbelt_datetime.TVF_DateBucketDate
-- Ordnet einen date-Wert einem originbezogenen Zeit-Bucket zu.
-- Voraussetzung: SQL Server 2019/2022/2025, Windows/Linux, unterstützte CL150/160/170. Modul installiert; kein CLR oder externer Datenzugriff. Alle vier Funktionsargumentpositionen angeben. DEFAULT für Origin wählt den deklarierten Bezugspunkt; explizites NULL wählt ihn nicht.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_datetime.TVF_DateBucketDate
 ('day',2,CONVERT(date,'2026-01-04T12:00:00'),
 CONVERT(date,'2026-01-01T00:00:00'));
-- Bucketanfang 2026-01-03 00:00:00 (bei date ohne Uhrzeit); gültig, Code=0.
*/

-- toolbelt_datetime.TVF_DateBucketDateTime2
-- Ordnet einen datetime2-Wert einem originbezogenen Zeit-Bucket zu.
-- Voraussetzung: SQL Server 2019/2022/2025, Windows/Linux, unterstützte CL150/160/170. Modul installiert; kein CLR oder externer Datenzugriff. Alle vier Funktionsargumentpositionen angeben. DEFAULT für Origin wählt den deklarierten Bezugspunkt; explizites NULL wählt ihn nicht.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_datetime.TVF_DateBucketDateTime2
 ('day',2,CONVERT(datetime2(7),'2026-01-04T12:00:00'),
 CONVERT(datetime2(7),'2026-01-01T00:00:00'));
-- Bucketanfang 2026-01-03 00:00:00 (bei date ohne Uhrzeit); gültig, Code=0.
*/

-- toolbelt_datetime.TVF_DateBucketDateTimeOffset
-- Ordnet einen datetimeoffset-Wert einem originbezogenen Zeit-Bucket zu.
-- Voraussetzung: SQL Server 2019/2022/2025, Windows/Linux, unterstützte CL150/160/170. Modul installiert; kein CLR oder externer Datenzugriff. Alle vier Funktionsargumentpositionen angeben. DEFAULT für Origin wählt den deklarierten Bezugspunkt; explizites NULL wählt ihn nicht.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_datetime.TVF_DateBucketDateTimeOffset
 ('day',2,CONVERT(datetimeoffset(7),'2026-01-04T12:00:00+00:00'),
 CONVERT(datetimeoffset(7),'2026-01-01T00:00:00+00:00'));
-- Bucketanfang 2026-01-03 00:00:00 (bei date ohne Uhrzeit); gültig, Code=0.
*/

-- toolbelt_datetime.TVF_CalendarDifference
-- Zerlegt ein Datumsintervall nach der Anniversary-Regel in Kalenderjahre, Monate und Tage.
-- Voraussetzung: SQL Server 2019, 2022 oder 2025, Windows oder Linux; unterstützte Compatibility Levels 150/160/170. Modul und seine deklarierten Funktionsabhängigkeiten müssen installiert sein. Kein CLR oder externer Datenzugriff. Alle SQL-Funktionsargumente positionsbezogen angeben.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_datetime.TVF_CalendarDifference('20240131','20250302');
-- Sign=1, Years=1, Months=1, Days=2.
*/

-- toolbelt_datetime.TVF_DateSpineDay
-- Liefert alle Tage, die einen halboffenen Zeitraum schneiden.
-- Voraussetzung: SQL Server 2019, 2022 oder 2025, Windows oder Linux; unterstützte Compatibility Levels 150/160/170. Modul und seine deklarierten Funktionsabhängigkeiten müssen installiert sein. Kein CLR oder externer Datenzugriff. Alle SQL-Funktionsargumente positionsbezogen angeben.
/* Separat auswählen und ausführen:
SELECT Ordinal,PeriodStart FROM toolbelt_datetime.TVF_DateSpineDay('20260227','20260303')
ORDER BY Ordinal;
-- vier Zeilen von 2026-02-27 bis 2026-03-02.
*/

-- toolbelt_datetime.TVF_DateSpineIsoWeek
-- Liefert alle ISO-Wochen, die einen halboffenen Zeitraum schneiden.
-- Voraussetzung: SQL Server 2019, 2022 oder 2025, Windows oder Linux; unterstützte Compatibility Levels 150/160/170. Modul und seine deklarierten Funktionsabhängigkeiten müssen installiert sein. Kein CLR oder externer Datenzugriff. Alle SQL-Funktionsargumente positionsbezogen angeben.
/* Separat auswählen und ausführen:
SELECT Ordinal,PeriodStart FROM toolbelt_datetime.TVF_DateSpineIsoWeek('20251231','20260108')
ORDER BY Ordinal;
-- zwei Zeilen mit 2025-12-29 und 2026-01-05.
*/

-- toolbelt_datetime.TVF_DateSpineMonth
-- Liefert alle Monate, die einen halboffenen Zeitraum schneiden.
-- Voraussetzung: SQL Server 2019, 2022 oder 2025, Windows oder Linux; unterstützte Compatibility Levels 150/160/170. Modul und seine deklarierten Funktionsabhängigkeiten müssen installiert sein. Kein CLR oder externer Datenzugriff. Alle SQL-Funktionsargumente positionsbezogen angeben.
/* Separat auswählen und ausführen:
SELECT Ordinal,PeriodStart FROM toolbelt_datetime.TVF_DateSpineMonth('20260115','20260402')
ORDER BY Ordinal;
-- vier Zeilen mit 2026-01-01, 2026-02-01, 2026-03-01 und 2026-04-01.
*/

-- toolbelt_datetime.TVF_TruncateDate
-- Kürzt einen date-Wert auf den Beginn der ausgewählten Kalenderperiode.
-- Voraussetzung: SQL Server 2019, 2022 oder 2025, Windows oder Linux; unterstützte Compatibility Levels 150/160/170. Modul und seine deklarierten Funktionsabhängigkeiten müssen installiert sein. Kein CLR oder externer Datenzugriff. Alle SQL-Funktionsargumente positionsbezogen angeben.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_datetime.TVF_TruncateDate('month', CONVERT(date,'2026-11-20T12:34:56.1234567'));
-- Beginn November 2026, IsValid=1, ValidationCode=0.
*/

-- toolbelt_datetime.TVF_TruncateDateTime2
-- Kürzt einen datetime2-Wert auf den Beginn der gewählten Zeiteinheit.
-- Voraussetzung: SQL Server 2019, 2022 oder 2025, Windows oder Linux; unterstützte Compatibility Levels 150/160/170. Modul und seine deklarierten Funktionsabhängigkeiten müssen installiert sein. Kein CLR oder externer Datenzugriff. Alle SQL-Funktionsargumente positionsbezogen angeben.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_datetime.TVF_TruncateDateTime2('month', CONVERT(datetime2(7),'2026-11-20T12:34:56.1234567'));
-- Beginn November 2026, IsValid=1, ValidationCode=0.
*/

-- toolbelt_datetime.TVF_TruncateDateTimeOffset
-- Kürzt einen datetimeoffset-Wert auf die gewählte Zeiteinheit und erhält den Offset.
-- Voraussetzung: SQL Server 2019, 2022 oder 2025, Windows oder Linux; unterstützte Compatibility Levels 150/160/170. Modul und seine deklarierten Funktionsabhängigkeiten müssen installiert sein. Kein CLR oder externer Datenzugriff. Alle SQL-Funktionsargumente positionsbezogen angeben.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_datetime.TVF_TruncateDateTimeOffset('month', CONVERT(datetimeoffset(7),'2026-11-20T12:34:56.1234567+02:00'));
-- Beginn November 2026, IsValid=1, ValidationCode=0.
*/

-- toolbelt_file.USP_LoadBinaryFile
-- Liest eine Datei als varbinary(max) über OPENROWSET(BULK...). Der Pfad muss unter einem Eintrag der Root-Allowlist liegen.
-- Voraussetzung: SQL Server2019/2022/2025 Windows/Linux gemäß Modulmatrix, passende CL150/160/170. Datenbanktabelle mit administrativ gepflegtem aktivem Root. Provider-/Plattform-/OS-Leserechte unabhängig von Rootfreigabe erfüllen. Für ResultTable sameDB core.result-table>=1.0.0. Aktueller gemeinsamer Offlinebuilder expandiert FileContentRootPredicate.sql in normale SQL-DDL; rohe Source-Prozedurdatei enthält noch :r-Quellinclude und ist kein direkt unverändert auszuführender SQLCMD-freier Installer. Eingabepfad LTRIM/RTRIM normaler Spaces und NULLIF leer; dann zwei REPLACE-Schritte für doppelte/einfache Backslashes nach Slash nur für den Allowlistvergleich. Absolutheit nach Laufwerkbuchstabe:/ oder führendem /; geprüftes ../-Traversal wird abgewiesen, keine vollständige OS-Kanonisierung aller Punkt-/Device-/Aliasformen. Aktive Roots werden ebenfalls slashnormalisiert, nicht generell getrimmt. Vergleich literal BIN2 an exakter Rootlänge oder Verzeichnisgrenze mit angehängtem /; Prozent/Unterstrich/Klammern sind dort keine Wildcards. Ein exakter Rootpfad selbst kann zugelassen sein, nicht nur dessen Kinder. Keine Symlink-/Junction-/Hardlink-/Handleprüfung; tatsächlicher BULK-Aufruf liest den getrimmten Originalpfad. Keine handlegebundene Sandbox oder TOCTOU-/Dateisystemidentitätsgarantie.
/* Separat auswählen und ausführen:
EXEC toolbelt_file.USP_LoadBinaryFile @FilePath=N'C:\Contoso\Input\example.bin',@MaxBytes=1048576;
-- Synthetischer serverseitiger Pfad; aktiver Root und vorhandene Rechte nötig.
-- IsValid/ValidationCode prüfen; MaxBytes ist kein Vorallokationslimit.
EXEC toolbelt_file.USP_LoadBinaryFile @Hilfe=1;
*/

-- toolbelt_file.USP_LoadTextFile
-- Liest eine Textdatei als nvarchar(max) über OPENROWSET(BULK...). Erkennt BOM und decodiert entsprechend; Inhalt ohne BOM wird mit @FallbackEncoding gelesen.
-- Voraussetzung: SQL Server2019/2022/2025 Windows/Linux gemäß Modulmatrix, passende CL150/160/170. Datenbanktabelle mit administrativ gepflegtem aktivem Root. Provider-/Plattform-/OS-Leserechte unabhängig von Rootfreigabe erfüllen. Für ResultTable sameDB core.result-table>=1.0.0. Aktueller gemeinsamer Offlinebuilder expandiert FileContentRootPredicate.sql in normale SQL-DDL; rohe Source-Prozedurdatei enthält noch :r-Quellinclude und ist kein direkt unverändert auszuführender SQLCMD-freier Installer. Eingabepfad LTRIM/RTRIM normaler Spaces und NULLIF leer; dann zwei REPLACE-Schritte für doppelte/einfache Backslashes nach Slash nur für den Allowlistvergleich. Absolutheit nach Laufwerkbuchstabe:/ oder führendem /; geprüftes ../-Traversal wird abgewiesen, keine vollständige OS-Kanonisierung aller Punkt-/Device-/Aliasformen. Aktive Roots werden ebenfalls slashnormalisiert, nicht generell getrimmt. Vergleich literal BIN2 an exakter Rootlänge oder Verzeichnisgrenze mit angehängtem /; Prozent/Unterstrich/Klammern sind dort keine Wildcards. Ein exakter Rootpfad selbst kann zugelassen sein, nicht nur dessen Kinder. Keine Symlink-/Junction-/Hardlink-/Handleprüfung; tatsächlicher BULK-Aufruf liest den getrimmten Originalpfad. Keine handlegebundene Sandbox oder TOCTOU-/Dateisystemidentitätsgarantie.
/* Separat auswählen und ausführen:
EXEC toolbelt_file.USP_LoadTextFile @FilePath=N'C:\Contoso\Input\example.txt',@MaxBytes=1048576;
-- Synthetischer serverseitiger Pfad; aktiver Root und vorhandene Rechte nötig.
-- IsValid/ValidationCode prüfen; MaxBytes ist kein Vorallokationslimit.
EXEC toolbelt_file.USP_LoadTextFile @Hilfe=1;
*/

-- toolbelt_file.USP_ParseCsv
-- Parst begrenzten Unicode-CSV-Text vollständig als rechteckige HEADER-/DATA-Zellen; keine Datei- oder Netzwerkquelle.
-- Voraussetzung: Installiertes Modul mit autorisierter SAFE-Assembly tlblt_File_CsvMemory, SQL Server 2019/2022/2025 auf Windows/Linux gemäß Modulmatrix, CL150/160/170 soweit zur Engine passend, lokal oder zentral. Kein Datei-, Netzwerk- oder Encodingprovider. ResultTable >=1.0.0 in derselben Datenbank für Routing. Separator genau eine UTF-16-Codeunit, nicht NULL/leer, keine Doppelquote, CR, LF, NUL oder Surrogate. NullToken NULL deaktiviert SQL-NULL; sonst 1..128 Codeunits, ohne Separator, Doppelquote, CR, LF, NUL oder ungepaarte Surrogate. Gültige Surrogatpaare im Token sind erlaubt. Tokenvergleich exakt nach Länge und Codeunits, nicht SQL-Padding.
/* Separat auswählen und ausführen:
DECLARE @Csv nvarchar(max)=N'name,value'+NCHAR(10)+N'alpha,1';
EXEC toolbelt_file.USP_ParseCsv @Text=@Csv,@HasHeader=1;
-- Vier Zellen: HEADER (0,1)/(0,2), DATA (1,1)/(1,2).
EXEC toolbelt_file.USP_ParseCsv @Hilfe=1;
*/

-- toolbelt_file.USP_WriteCsv
-- Schreibt einen read-only Snapshot vier typgenauer caller-lokaler Temp-Spalten als vollständig budgetiertes CSV.
-- Voraussetzung: Installiertes Modul mit autorisierter SAFE-Assembly tlblt_File_CsvMemory, SQL Server 2019/2022/2025 auf Windows/Linux gemäß Modulmatrix, CL150/160/170 soweit zur Engine passend, lokal oder zentral. Kein Datei-, Netzwerk- oder Encodingprovider. ResultTable >=1.0.0 in derselben Datenbank für Routing. Separator genau eine UTF-16-Codeunit, nicht NULL/leer, keine Doppelquote, CR, LF, NUL oder Surrogate. NullToken NULL deaktiviert SQL-NULL; sonst 1..128 Codeunits, ohne Separator, Doppelquote, CR, LF, NUL oder ungepaarte Surrogate. Gültige Surrogatpaare im Token sind erlaubt. Tokenvergleich exakt nach Länge und Codeunits, nicht SQL-Padding.
/* Separat auswählen und ausführen:
CREATE TABLE #CsvCells(RowKind varchar(6),RowOrdinal bigint,ColumnOrdinal int,[Value] nvarchar(max));
INSERT #CsvCells VALUES('DATA',1,1,N'a,b'),('DATA',1,2,N'x');
EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#CsvCells',@LineEnding='LF';
-- CsvText: Doppelquote a,b Doppelquote ,x gefolgt von LF; DataRows=1, ColumnCount=2.
DROP TABLE #CsvCells;
EXEC toolbelt_file.USP_WriteCsv @Hilfe=1;
*/

-- toolbelt_file.USP_ListXlsxWorksheets
-- Begrenzter SAFE Binary-XLSX-Reader; atomarer gewählter Snapshot, keine Datei-/Netzwerkzugriffe, Formelberechnung oder Typinferenz.
-- Voraussetzung: Modul XLSXmemory1.2.0 mit SAFE-Assembly tlblt_File_XlsxMemory, ZIPmemory>=1.4.0 und ResultTable>=1.0.0 gemäß Modulabhängigkeiten. Unterstützte SQL2019/2022/2025 Windows/Linux-Kontexte gemäß Modulmatrix, vorhandene CLR-/Trustvoraussetzungen. Keine Installation, Rechteerteilung, Labänderung oder Datenquelle wird durch diesen Aufruf vorbereitet.
/* Separat auswählen und ausführen:
EXEC toolbelt_file.USP_ListXlsxWorksheets @Hilfe=1;
-- Vollständige Client-Workbookbytes binden, keinen Serverpfad.
DECLARE @Workbook varbinary(max)=NULL;
EXEC toolbelt_file.USP_ListXlsxWorksheets @XlsxBinary=@Workbook;
*/

-- toolbelt_file.USP_ReadXlsxWorksheetCells
-- Begrenzter SAFE Binary-XLSX-Reader; atomarer gewählter Snapshot, keine Datei-/Netzwerkzugriffe, Formelberechnung oder Typinferenz.
-- Voraussetzung: Modul XLSXmemory1.2.0 mit SAFE-Assembly tlblt_File_XlsxMemory, ZIPmemory>=1.4.0 und ResultTable>=1.0.0 gemäß Modulabhängigkeiten. Unterstützte SQL2019/2022/2025 Windows/Linux-Kontexte gemäß Modulmatrix, vorhandene CLR-/Trustvoraussetzungen. Keine Installation, Rechteerteilung, Labänderung oder Datenquelle wird durch diesen Aufruf vorbereitet.
/* Separat auswählen und ausführen:
EXEC toolbelt_file.USP_ReadXlsxWorksheetCells @Hilfe=1;
-- Vollständige Client-Workbookbytes binden, keinen Serverpfad.
DECLARE @Workbook varbinary(max)=NULL;
EXEC toolbelt_file.USP_ReadXlsxWorksheetCells @XlsxBinary=@Workbook,@SheetOrdinal=1;
*/

-- toolbelt_file.TVF_InterpretXlsxCell
-- Interpretiert den zuvor gelesenen Rohwert einer XLSX-Zelle als begrenzten, typisierten Wert.
-- Voraussetzung: Modul XLSXmemory1.2.0 mit SAFE-Assembly tlblt_File_XlsxMemory, ZIPmemory>=1.4.0 und ResultTable>=1.0.0 gemäß Modulabhängigkeiten. Unterstützte SQL2019/2022/2025 Windows/Linux-Kontexte gemäß Modulmatrix, vorhandene CLR-/Trustvoraussetzungen. Keine Installation, Rechteerteilung, Labänderung oder Datenquelle wird durch diesen Aufruf vorbereitet.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_file.TVF_InterpretXlsxCell(N'n',1,N'1.235',NULL,N'number',NULL,NULL);
*/

-- toolbelt_file.TVF_FormatXlsxCell
-- Formatiert eine XLSX-Einzelzelle mit den unterstützten Literalformaten und Kulturen.
-- Voraussetzung: Modul XLSXmemory1.2.0 mit SAFE-Assembly tlblt_File_XlsxMemory, ZIPmemory>=1.4.0 und ResultTable>=1.0.0 gemäß Modulabhängigkeiten. Unterstützte SQL2019/2022/2025 Windows/Linux-Kontexte gemäß Modulmatrix, vorhandene CLR-/Trustvoraussetzungen. Keine Installation, Rechteerteilung, Labänderung oder Datenquelle wird durch diesen Aufruf vorbereitet.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_file.TVF_FormatXlsxCell(N'n',1,N'1.235',NULL,N'number',N'0.00',NULL,N'de-DE');
*/

-- toolbelt_filesystem.USP_ReadBinaryFileChunk
-- Liest einen begrenzten Binär-Chunk aus einer per RootAlias freigegebenen Datei.
-- Voraussetzung: Installiertes Windows-Dateisystemmodul mit passender UNSAFE-CLR-Binary auf Windows SQL Server 2019/2022/2025. Nur lokaler Modulpfad, nicht Linux oder zentrale Cross-DB-Verwendung. Aktiver konfigurierter Root und AllowRead erforderlich. Native Provider akzeptieren nur unterstützte lokale Laufwerks-/Handlepfade; UNC-/Netzwerkpfade sind kein zugesicherter Weg. Konfiguration, Trust und Rechte werden nicht automatisch angelegt. Die reine Hilfe kehrt vor diesen fachlichen Voraussetzungen zurück. Ein physischer Dateipfad wird nicht als Caller-Eingabe angenommen; RootAlias verweist auf vorhandene autorisierte Konfiguration.
/* Separat auswählen und ausführen:
-- Reine Hilfe ohne Rootkonfiguration oder Dateioperation:
EXEC toolbelt_filesystem.USP_ReadBinaryFileChunk @Hilfe=1;
-- Fachaufruf nur mit eigener passender Rootkonfiguration:
EXEC toolbelt_filesystem.USP_ReadBinaryFileChunk @RootAlias=N'ContosoRead',@RelativePath=N'sample.bin',@MaxBytes=1024;
*/

-- toolbelt_filesystem.USP_ReadTextFileChunk
-- Liest einen begrenzten Text-Chunk mit expliziter Codepage und liefert die nächste Byte-Position.
-- Voraussetzung: Installiertes Windows-Dateisystemmodul mit passender UNSAFE-CLR-Binary auf Windows SQL Server 2019/2022/2025. Nur lokaler Modulpfad, nicht Linux oder zentrale Cross-DB-Verwendung. Aktiver konfigurierter Root und AllowRead erforderlich. Native Provider akzeptieren nur unterstützte lokale Laufwerks-/Handlepfade; UNC-/Netzwerkpfade sind kein zugesicherter Weg. Konfiguration, Trust und Rechte werden nicht automatisch angelegt. Die reine Hilfe kehrt vor diesen fachlichen Voraussetzungen zurück. Ein physischer Dateipfad wird nicht als Caller-Eingabe angenommen; RootAlias verweist auf vorhandene autorisierte Konfiguration.
/* Separat auswählen und ausführen:
-- Reine Hilfe ohne Rootkonfiguration oder Dateioperation:
EXEC toolbelt_filesystem.USP_ReadTextFileChunk @Hilfe=1;
-- Fachaufruf nur mit eigener passender Rootkonfiguration:
EXEC toolbelt_filesystem.USP_ReadTextFileChunk @RootAlias=N'ContosoRead',@RelativePath=N'sample.txt',@EncodingName=N'utf-8';
*/

-- toolbelt_filesystem.USP_WriteBinaryFile
-- Schreibt Binärdaten gestreamt in eine atomar veröffentlichte Zieldatei.
-- Voraussetzung: Installiertes Windows-Dateisystemmodul mit passender UNSAFE-CLR-Binary auf Windows SQL Server 2019/2022/2025. Nur lokaler Modulpfad, nicht Linux oder zentrale Cross-DB-Verwendung. Aktiver konfigurierter Root und AllowWrite erforderlich. Native Provider akzeptieren nur unterstützte lokale Laufwerks-/Handlepfade; UNC-/Netzwerkpfade sind kein zugesicherter Weg. Konfiguration, Trust und Rechte werden nicht automatisch angelegt. Die reine Hilfe kehrt vor diesen fachlichen Voraussetzungen zurück. Ein physischer Dateipfad wird nicht als Caller-Eingabe angenommen; RootAlias verweist auf vorhandene autorisierte Konfiguration.
/* Separat auswählen und ausführen:
-- Reine Hilfe ohne Rootkonfiguration oder Dateioperation:
EXEC toolbelt_filesystem.USP_WriteBinaryFile @Hilfe=1;
*/

-- toolbelt_filesystem.USP_WriteTextFile
-- Schreibt Text gestreamt mit expliziter Codepage und optionalem BOM.
-- Voraussetzung: Installiertes Windows-Dateisystemmodul mit passender UNSAFE-CLR-Binary auf Windows SQL Server 2019/2022/2025. Nur lokaler Modulpfad, nicht Linux oder zentrale Cross-DB-Verwendung. Aktiver konfigurierter Root und AllowWrite erforderlich. Native Provider akzeptieren nur unterstützte lokale Laufwerks-/Handlepfade; UNC-/Netzwerkpfade sind kein zugesicherter Weg. Konfiguration, Trust und Rechte werden nicht automatisch angelegt. Die reine Hilfe kehrt vor diesen fachlichen Voraussetzungen zurück. Ein physischer Dateipfad wird nicht als Caller-Eingabe angenommen; RootAlias verweist auf vorhandene autorisierte Konfiguration.
/* Separat auswählen und ausführen:
-- Reine Hilfe ohne Rootkonfiguration oder Dateioperation:
EXEC toolbelt_filesystem.USP_WriteTextFile @Hilfe=1;
*/

-- toolbelt_filesystem.USP_TranscodeTextFile
-- Konvertiert eine Textdatei gestreamt zwischen zwei expliziten Codepages.
-- Voraussetzung: Installiertes Windows-Dateisystemmodul mit passender UNSAFE-CLR-Binary auf Windows SQL Server 2019/2022/2025. Nur lokaler Modulpfad, nicht Linux oder zentrale Cross-DB-Verwendung. Aktiver konfigurierter Root und AllowRead und AllowWrite erforderlich. Native Provider akzeptieren nur unterstützte lokale Laufwerks-/Handlepfade; UNC-/Netzwerkpfade sind kein zugesicherter Weg. Konfiguration, Trust und Rechte werden nicht automatisch angelegt. Die reine Hilfe kehrt vor diesen fachlichen Voraussetzungen zurück. Ein physischer Dateipfad wird nicht als Caller-Eingabe angenommen; RootAlias verweist auf vorhandene autorisierte Konfiguration.
/* Separat auswählen und ausführen:
-- Reine Hilfe ohne Rootkonfiguration oder Dateioperation:
EXEC toolbelt_filesystem.USP_TranscodeTextFile @Hilfe=1;
*/

-- toolbelt_filesystem.USP_ListDirectory
-- Listet Verzeichniseinträge unter einem freigegebenen Root mit harten Grenzen.
-- Voraussetzung: Installiertes Windows-Dateisystemmodul mit passender UNSAFE-CLR-Binary auf Windows SQL Server 2019/2022/2025. Nur lokaler Modulpfad, nicht Linux oder zentrale Cross-DB-Verwendung. Aktiver konfigurierter Root und AllowList erforderlich. Native Provider akzeptieren nur unterstützte lokale Laufwerks-/Handlepfade; UNC-/Netzwerkpfade sind kein zugesicherter Weg. Konfiguration, Trust und Rechte werden nicht automatisch angelegt. Die reine Hilfe kehrt vor diesen fachlichen Voraussetzungen zurück. Ein physischer Dateipfad wird nicht als Caller-Eingabe angenommen; RootAlias verweist auf vorhandene autorisierte Konfiguration.
/* Separat auswählen und ausführen:
-- Reine Hilfe ohne Rootkonfiguration oder Dateioperation:
EXEC toolbelt_filesystem.USP_ListDirectory @Hilfe=1;
-- Fachaufruf nur mit eigener passender Rootkonfiguration:
EXEC toolbelt_filesystem.USP_ListDirectory @RootAlias=N'ContosoRead',@RelativePath=N'',@MaxEntries=100;
*/

-- toolbelt_filesystem.USP_CreateDirectory
-- Erstellt ein Verzeichnis unter einem freigegebenen Root.
-- Voraussetzung: Installiertes Windows-Dateisystemmodul mit passender UNSAFE-CLR-Binary auf Windows SQL Server 2019/2022/2025. Nur lokaler Modulpfad, nicht Linux oder zentrale Cross-DB-Verwendung. Aktiver konfigurierter Root und AllowCreateDirectory erforderlich. Native Provider akzeptieren nur unterstützte lokale Laufwerks-/Handlepfade; UNC-/Netzwerkpfade sind kein zugesicherter Weg. Konfiguration, Trust und Rechte werden nicht automatisch angelegt. Die reine Hilfe kehrt vor diesen fachlichen Voraussetzungen zurück. Ein physischer Dateipfad wird nicht als Caller-Eingabe angenommen; RootAlias verweist auf vorhandene autorisierte Konfiguration.
/* Separat auswählen und ausführen:
-- Reine Hilfe ohne Rootkonfiguration oder Dateioperation:
EXEC toolbelt_filesystem.USP_CreateDirectory @Hilfe=1;
*/

-- toolbelt_filesystem.USP_RemoveFile
-- Entfernt eine Datei unter einem freigegebenen Root.
-- Voraussetzung: Installiertes Windows-Dateisystemmodul mit passender UNSAFE-CLR-Binary auf Windows SQL Server 2019/2022/2025. Nur lokaler Modulpfad, nicht Linux oder zentrale Cross-DB-Verwendung. Aktiver konfigurierter Root und AllowDelete erforderlich. Native Provider akzeptieren nur unterstützte lokale Laufwerks-/Handlepfade; UNC-/Netzwerkpfade sind kein zugesicherter Weg. Konfiguration, Trust und Rechte werden nicht automatisch angelegt. Die reine Hilfe kehrt vor diesen fachlichen Voraussetzungen zurück. Ein physischer Dateipfad wird nicht als Caller-Eingabe angenommen; RootAlias verweist auf vorhandene autorisierte Konfiguration.
/* Separat auswählen und ausführen:
-- Reine Hilfe ohne Rootkonfiguration oder Dateioperation:
EXEC toolbelt_filesystem.USP_RemoveFile @Hilfe=1;
*/

-- toolbelt_filesystem.USP_RemoveDirectory
-- Entfernt ein Verzeichnis; rekursives Entfernen ist explizit und begrenzt.
-- Voraussetzung: Installiertes Windows-Dateisystemmodul mit passender UNSAFE-CLR-Binary auf Windows SQL Server 2019/2022/2025. Nur lokaler Modulpfad, nicht Linux oder zentrale Cross-DB-Verwendung. Aktiver konfigurierter Root und AllowDelete erforderlich. Native Provider akzeptieren nur unterstützte lokale Laufwerks-/Handlepfade; UNC-/Netzwerkpfade sind kein zugesicherter Weg. Konfiguration, Trust und Rechte werden nicht automatisch angelegt. Die reine Hilfe kehrt vor diesen fachlichen Voraussetzungen zurück. Ein physischer Dateipfad wird nicht als Caller-Eingabe angenommen; RootAlias verweist auf vorhandene autorisierte Konfiguration.
/* Separat auswählen und ausführen:
-- Reine Hilfe ohne Rootkonfiguration oder Dateioperation:
EXEC toolbelt_filesystem.USP_RemoveDirectory @Hilfe=1;
*/

-- toolbelt_json.USP_JsonArray
-- JSON-Array aus Ordinal/ValueKind/Value; vollständig validiert und atomar geroutet.
-- Voraussetzung: Kanonisches Modul1.3.0 mit JsonCore-Abhängigkeit und bekannter SAFE-Assembly tlblt_JsonConstructors. SQL2019/2022/2025 auf Windows/Linux mit CL150/160/170 gemäß Modulmatrix. Die Prozeduren brauchen den ResultTablehelper auch für direkte Ausgabe. Vorhandene CLR-/Trustvoraussetzungen des gewählten Installers; der Aufruf ändert keine Rechte oder Serverkonfiguration.
/* Separat auswählen und ausführen:
EXEC toolbelt_json.USP_JsonArray @Hilfe=1;
CREATE TABLE #ContosoEntries(Ordinal int,ValueKind nvarchar(max),[Value] nvarchar(max));
INSERT #ContosoEntries VALUES(1,N'string',N'Contoso');
EXEC toolbelt_json.USP_JsonArray @EntriesTable=N'#ContosoEntries';
DROP TABLE #ContosoEntries;
*/

-- toolbelt_json.USP_JsonObject
-- JSON-Object aus Ordinal/ValueKind/Value/Key; vollständig validiert und atomar geroutet.
-- Voraussetzung: Kanonisches Modul1.3.0 mit JsonCore-Abhängigkeit und bekannter SAFE-Assembly tlblt_JsonConstructors. SQL2019/2022/2025 auf Windows/Linux mit CL150/160/170 gemäß Modulmatrix. Die Prozeduren brauchen den ResultTablehelper auch für direkte Ausgabe. Vorhandene CLR-/Trustvoraussetzungen des gewählten Installers; der Aufruf ändert keine Rechte oder Serverkonfiguration.
/* Separat auswählen und ausführen:
EXEC toolbelt_json.USP_JsonObject @Hilfe=1;
CREATE TABLE #ContosoEntries(Ordinal int,[Key] nvarchar(max),ValueKind nvarchar(max),[Value] nvarchar(max));
INSERT #ContosoEntries VALUES(1,N'contoso',N'string',N'Contoso');
EXEC toolbelt_json.USP_JsonObject @EntriesTable=N'#ContosoEntries';
DROP TABLE #ContosoEntries;
*/

-- toolbelt_json.USP_JsonArraysByGroup
-- JSON-Array aus GroupOrdinal/Ordinal/ValueKind/Value; vollständig validiert und atomar geroutet.
-- Voraussetzung: Kanonisches Modul1.3.0 mit JsonCore-Abhängigkeit und bekannter SAFE-Assembly tlblt_JsonConstructors. SQL2019/2022/2025 auf Windows/Linux mit CL150/160/170 gemäß Modulmatrix. Die Prozeduren brauchen den ResultTablehelper auch für direkte Ausgabe. Vorhandene CLR-/Trustvoraussetzungen des gewählten Installers; der Aufruf ändert keine Rechte oder Serverkonfiguration.
/* Separat auswählen und ausführen:
EXEC toolbelt_json.USP_JsonArraysByGroup @Hilfe=1;
CREATE TABLE #ContosoEntries(GroupOrdinal int,Ordinal int,ValueKind nvarchar(max),[Value] nvarchar(max));
INSERT #ContosoEntries VALUES(1,1,N'string',N'Contoso');
EXEC toolbelt_json.USP_JsonArraysByGroup @EntriesTable=N'#ContosoEntries';
DROP TABLE #ContosoEntries;
*/

-- toolbelt_json.USP_JsonObjectsByGroup
-- JSON-Object aus GroupOrdinal/Ordinal/ValueKind/Value/Key; vollständig validiert und atomar geroutet.
-- Voraussetzung: Kanonisches Modul1.3.0 mit JsonCore-Abhängigkeit und bekannter SAFE-Assembly tlblt_JsonConstructors. SQL2019/2022/2025 auf Windows/Linux mit CL150/160/170 gemäß Modulmatrix. Die Prozeduren brauchen den ResultTablehelper auch für direkte Ausgabe. Vorhandene CLR-/Trustvoraussetzungen des gewählten Installers; der Aufruf ändert keine Rechte oder Serverkonfiguration.
/* Separat auswählen und ausführen:
EXEC toolbelt_json.USP_JsonObjectsByGroup @Hilfe=1;
CREATE TABLE #ContosoEntries(GroupOrdinal int,Ordinal int,[Key] nvarchar(max),ValueKind nvarchar(max),[Value] nvarchar(max));
INSERT #ContosoEntries VALUES(1,1,N'contoso',N'string',N'Contoso');
EXEC toolbelt_json.USP_JsonObjectsByGroup @EntriesTable=N'#ContosoEntries';
DROP TABLE #ContosoEntries;
*/

-- toolbelt_json.AGF_JsonArray
-- Aggregiert typisierte JSON-Einträge in Ordinal-Reihenfolge zu einem JSON-Array.
-- Voraussetzung: Kanonisches Modul1.3.0 mit JsonCore-Abhängigkeit und bekannter SAFE-Assembly tlblt_JsonConstructors. SQL2019/2022/2025 auf Windows/Linux mit CL150/160/170 gemäß Modulmatrix. Die Prozeduren brauchen den ResultTablehelper auch für direkte Ausgabe. Vorhandene CLR-/Trustvoraussetzungen des gewählten Installers; der Aufruf ändert keine Rechte oder Serverkonfiguration.
/* Separat auswählen und ausführen:
SELECT toolbelt_json.AGF_JsonArray(Ordinal,ValueKind,[Value],CONVERT(tinyint,1)) AS JsonValue
FROM (VALUES(1,N'string',N'Contoso'),(2,N'number',N'2')) AS e(Ordinal,ValueKind,[Value]);
*/

-- toolbelt_json.AGF_JsonObject
-- Aggregiert typisierte Einträge mit eindeutigen Schlüsseln zu einem JSON-Objekt.
-- Voraussetzung: Kanonisches Modul1.3.0 mit JsonCore-Abhängigkeit und bekannter SAFE-Assembly tlblt_JsonConstructors. SQL2019/2022/2025 auf Windows/Linux mit CL150/160/170 gemäß Modulmatrix. Die Prozeduren brauchen den ResultTablehelper auch für direkte Ausgabe. Vorhandene CLR-/Trustvoraussetzungen des gewählten Installers; der Aufruf ändert keine Rechte oder Serverkonfiguration.
/* Separat auswählen und ausführen:
SELECT toolbelt_json.AGF_JsonObject(Ordinal,[Key],ValueKind,[Value],CONVERT(tinyint,1)) AS JsonValue
FROM (VALUES(1,N'contoso',N'string',N'Contoso'),(2,N'count',N'number',N'2')) AS e(Ordinal,[Key],ValueKind,[Value]);
*/

-- toolbelt_json.TVF_JsonPathExists
-- Prüft, ob ein unterstützter Pfad in einem JSON-Dokument existiert.
-- Voraussetzung: JSONpath-Modul mit nativer ISJSON/OPENJSON-Unterstützung in derselben DB. Windows/Linux SQL2019/2022/2025, CL150/160/170 im zulässigen Hostprofil. Kein Quellkatalog-, Datei-, Netzwerk-, CLR- oder Trustzugriff.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_json.TVF_JsonPathExistsStatus(N'{"items":[{"name":null}]}',N'$.items[*].name');
SELECT * FROM toolbelt_json.TVF_JsonPathExistsStatus(N'{"a ":1}',N'$."a"');
*/

-- toolbelt_json.TVF_JsonPathExistsStatus
-- Genau eine Zeile: FOUND/1, MISSING/0, INVALID/0, SQL_NULL/NULL oder LIMIT/NULL. Höchstens 10000 Frontierwerte; maximal 10001 werden zur Überschreitungsfeststellung aufgenommen. Vor jedem OPENJSON werden die vorgesehenen Inputbytes gegen das kumulative 64-MiB-Budget gebucht. Containerroots werden ohne zusätzliche Wrapper-Ebene validiert. Die bisherige TVF liefert bei LIMIT NULL; kein falsches MISSING.
-- Voraussetzung: JSONpath-Modul mit nativer ISJSON/OPENJSON-Unterstützung in derselben DB. Windows/Linux SQL2019/2022/2025, CL150/160/170 im zulässigen Hostprofil. Kein Quellkatalog-, Datei-, Netzwerk-, CLR- oder Trustzugriff.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_json.TVF_JsonPathExistsStatus(N'{"items":[{"name":null}]}',N'$.items[*].name');
SELECT * FROM toolbelt_json.TVF_JsonPathExistsStatus(N'{"a ":1}',N'$."a"');
*/

-- toolbelt_json.TVF_ResolveJsonPointer
-- Löst einen RFC6901-Pointer mit exakten Keys und unterscheidet FOUND, MISSING, JSON_NULL, SQL_NULL und INVALID. Der freigegebene feste128er-Guard gibt darüber DEPTH_LIMIT vor JSON_SYNTAX zurück.
-- Voraussetzung: SQL Server2019/2022/2025 Windows/Linux gemäß Modulmatrix, unterstützter Compatibility Level mindestens150 auch im zentralen Aufrufkontext. Ausschließlich native ISJSON-/OPENJSON-Grammatik und begrenzter UTF16-Policywalker; keine CLR-Assembly, Daten-/Systemkatalogtabelle, Serveroption oder Abhängigkeit eines anderen Moduls. Der gesamte Input muss gültige Syntax, Tiefen- und Unicodepolicy erfüllen, auch nicht traversierte Teile.
/* Separat auswählen und ausführen:
SELECT Status,JsonType,Value,ErrorCode
FROM toolbelt_json.TVF_ResolveJsonPointer(N'{"a/b":[null,"example"]}',N'/a~1b/1',DEFAULT,DEFAULT);
-- FOUND / STRING / example / NULL.
SELECT * FROM toolbelt_json.TVF_ResolveJsonPointer(N'null',N'',DEFAULT,DEFAULT);
-- JSON_NULL mit JsonType als Text NULL und Value SQL-NULL.
SELECT * FROM toolbelt_json.TVF_ResolveJsonPointer(NULL,NULL,0,0);
-- SQL_NULL vor Parameterfehlern.
*/

-- toolbelt_json.USP_ValidateJsonSchema
-- Prüft JSON im begrenzten Profil toolbelt-2020-12-v1 mit exakten Zahlen, Unicode und globalem Arbeitsbudget; SUMMARY plus begrenzte Diagnosen.
-- Voraussetzung: Installiertes Schema1.0.1 mit autorisierten SAFE-Assemblies tlblt_JsonSchema und tlblt_JsonCore, SQL2019/2022/2025 Windows/Linux mit passenden CL150/160/170, lokal/zentral. Einziges Profil toolbelt-2020-12-v1, exakte ordinale Schreibweise/Länge ohne Trim. Boolean-Schema true/false oder Schemaobjekt. Kein vollständiges Draft2020-12-Profil. Taxative 22 Keywords: `$schema`, `$ref`, `$defs`, `title`, `description`, `$comment`, `type`, `required`, `properties`, `additionalProperties`, `items`, `prefixItems`, `minItems`, `maxItems`, `minProperties`, `maxProperties`, `minLength`, `maxLength`, `minimum`, `maximum`, `exclusiveMinimum`, `exclusiveMaximum`. $schema nur String https://json-schema.org/draft/2020-12/schema, keine andere Draftkennung. title/description/$comment nur Stringannotation ohne Validierungseffekt. Unknowns einschließlich enum,const,format,pattern,multipleOf,allOf/anyOf/oneOf,not,if/then/else,contains,uniqueItems,$id/$anchor/$dynamicRef und unevaluated* ergeben UNSUPPORTED, nicht stilles Ignorieren. `type`: einer von null/boolean/number/string/object/array/integer als String oder nichtleere Arraymenge ohne doppelte Typnamen. `required`: Array eindeutiger Strings, leer erlaubt. `properties` und `$defs`: Objekte mit Boolean-/Objektschemas. `additionalProperties` und `items`: einzelnes Boolean-/Objektschema, keine alte Array-items-Tupleform. `prefixItems`: nichtleeres Array von Schemas; `items` gilt für Positionen dahinter oder alle ohne prefixItems. Object-/Array-/Stringkeywords greifen nur auf den passenden Instanztyp. Zählerbounds min*/max* sind mathematisch nichtnegative ganze JSON-Zahlen, keine auf SQL-int beschränkten Eingabeparameter. minLength/maxLength zählen Unicode-Skalare, nicht UTF16-Codeunits/Grapheme. Numeric minimum/maximum/exclusive* verlangen JSON-Zahlen, keine alten Boolean-exclusive-Schalter. integer wird mathematisch bestimmt: z.B. 1.0 ist integer, ohne Coercion oder Gleitkommarundung. Nur nichtrekursive lokale URIfragment-$ref: beginnt mit #, danach einmal strict Percentbytes/UTF8 und dann einmal RFC6901 ~0/~1 decodieren. Rootfragment # möglich, aber Selbst-/Referenzzyklen im gesamten Schema-/Containmentgraph sind UNSUPPORTED/REF_CYCLE. Kein Netzwerk, Dateizugriff oder externer Resolver; leere/externe Referenz ohne # ist UNSUPPORTED/EXTERNAL_REF. Fehlerhafte Prozent-/UTF8-/~-/Fragmentlexik INVALID_SCHEMA/REF_SYNTAX; fehlendes/nicht als Schema erschlossenes Ziel bzw. ungeeigneter Arrayindex INVALID_SCHEMA/REF_TARGET. Alle bekannten Schemaorte einschließlich ungenutzter $defs werden zuerst geprüft, inklusive Formen, lokaler Targets und Zyklen. Schemaorte/Graphkanten stabil nach vollständig codierten Pointern, Instanzmember nach decodierter UTF16-Identität und Instanzarrays numerisch; keine Kultur-/SQL-Padding-Normalisierung. SameDB core.result-table>=1.0.0 mit exakt fünf erwarteten Parametern ist auch für direkten SELECT erforderlich: seine Metadatensignatur wird vor CLR-Auswertung geprüft. Diese Routine installiert/erweitert keine Abhängigkeit.
/* Separat auswählen und ausführen:
EXEC toolbelt_json.USP_ValidateJsonSchema @Json=N'{"quantity":3}',@Schema=N'{"type":"object","required":["quantity"],"properties":{"quantity":{"type":"integer","minimum":1}}}';
-- SUMMARY VALID,IsValid=1; keine ERROR-Zeilen.
EXEC toolbelt_json.USP_ValidateJsonSchema @Hilfe=1;
*/

-- toolbelt_metadata.VW_ModuleCapabilities
-- Zeigt sichtbare bekannte Modulschnittstellenkandidaten; Version und Deployment-Modus bleiben NULL, MetadataStatus bleibt incomplete.
-- Voraussetzung: Installierte markerfreie View auf SQL2019/2022/2025 Windows/Linux, lokal oder zentral mit dem zulässigen Compatibility Level. Keine Runtime-Modulabhängigkeit und kein CLR-Aufruf. Der Generator liest beim Offlinebuild alle module.yaml-Dateien deterministisch und erzeugt feste Kandidatentupel ModuleId/qualifizierter Name/zulässige SQL-Objekttypen. Assemblies aus expliziten Deklarationen; bei einem Modul ohne Objekte Fallback auf dessen deklarierten CLR-Assemblynamen. Toolbelt-Assemblyalias tlblt_, bereits tlblt-Namen erhalten; private ScriptDom-Alias tlblt.Microsoft.SqlServer.TransactSql.ScriptDom. Unbekannte Manifestformen/Objekttypen oder Assemblyaliasformen brechen den Build ab, keine automatische Runtime-Discovery.
/* Separat auswählen und ausführen:
SELECT ModuleId,ModuleVersion,DeploymentMode,MetadataStatus
FROM toolbelt_metadata.VW_ModuleCapabilities
ORDER BY ModuleId;

SELECT ModuleId,MetadataStatus
FROM ContosoToolbelt.toolbelt_metadata.VW_ModuleCapabilities
WHERE ModuleId=N'toolbelt.metadata.identifier';
-- Eine Zeile bedeutet nur: mindestens ein sichtbarer namens-/typgleicher Kandidat.
*/

-- toolbelt_metadata.VW_ObjectUsageSkills
-- Bekannte Toolbelt-Objekte und ihre vollständigen maschinenlesbaren Usage-Skills lesen.
-- Voraussetzung: Neue Skill-Sicht im gewählten Ziel verfügbar und vorhandenes SELECT-Recht. Die Einträge sind konstante bekannte Beschreibungen und bestätigen weder Installation noch aktuelle Objektdefinition oder Ausführungsrechte. DatabaseRole bezeichnet eine logische Projektrolle, keinen fest kodierten Datenbanknamen. Gesamt- und Teilprofile desselben Quellstands enthalten denselben vollständigen Katalog einschließlich nicht ausgewählter Module.
/* Separat auswählen und ausführen:
SELECT SchemaName,ObjectName,ObjectType,DatabaseRole,IsInternal,Description
FROM toolbelt_metadata.VW_ObjectUsageSkills
ORDER BY DatabaseRole,SchemaName,ObjectName;

SELECT SkillMarkdown
FROM toolbelt_metadata.VW_ObjectUsageSkills
WHERE DatabaseRole=N'toolbelt'
  AND SchemaName=N'toolbelt_conversion'
  AND ObjectName=N'TVF_Base64Encode';
*/

-- toolbelt_metadata.TVF_ParseMultipartName
-- Zerlegt und validiert ein- bis vierteilige SQL-Identifier.
-- Voraussetzung: Identifier-Modul, Windows/Linux SQL2019/2022/2025 mit zulässigem CL150/160/170. Rein lokale Stringverarbeitung, keine Objekt-/Datenbank-/Serverauflösung oder Metadatensicht.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_metadata.TVF_ParseMultipartName(N'[ContosoDb]..[Order]]Line]');
SELECT toolbelt_metadata.SVF_QuoteMultipartName(N'dbo.ContosoSource');
SELECT * FROM toolbelt_metadata.TVF_ParseMultipartName(N'[ ]');
*/

-- toolbelt_metadata.SVF_QuoteMultipartName
-- Validiert einen mehrteiligen SQL-Namen und quotiert seine Komponenten.
-- Voraussetzung: Identifier-Modul, Windows/Linux SQL2019/2022/2025 mit zulässigem CL150/160/170. Rein lokale Stringverarbeitung, keine Objekt-/Datenbank-/Serverauflösung oder Metadatensicht.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_metadata.TVF_ParseMultipartName(N'[ContosoDb]..[Order]]Line]');
SELECT toolbelt_metadata.SVF_QuoteMultipartName(N'dbo.ContosoSource');
SELECT * FROM toolbelt_metadata.TVF_ParseMultipartName(N'[ ]');
*/

-- toolbelt_metadata.USP_ScriptTableClone
-- Vollständige DDL-Vorschau innerhalb des begrenzten unterstützten Strukturumfangs; niemals DDL-Ausführung oder Datenkopie. Unsupported führt zum Abbruch.
-- Voraussetzung: Modul4.1.1 in der tatsächlich ausgewählten Installationsdatenbank; ausschließlich SameDB-Quell-/Zielobjekte. Ein dreiteiliger zentraler Prozeduraufruf verlegt die Quellobjekte nicht in die Caller-Datenbank. Bestehender ResultTable-Helper>=1.0.0. Basisplanung/Executor/Copy sind TSQL auf Windows/Linux SQL2019/2022/2025 mit zulässigem CL150/160/170. Trigger-Opt-in ist gesondert Windows-only mit bereits vorhandenem exakt gebundenem Parser2.0.1 und vier Parser-TVFs; kein Nachinstallieren.
/* Separat auswählen und ausführen:
EXEC toolbelt_metadata.USP_ScriptTableClone @Hilfe=1;
-- Vorhandene synthetische Quelle und freies Ziel in dieser DB vorausgesetzt.
EXEC toolbelt_metadata.USP_ScriptTableClone @SourceSchema=N'dbo',@SourceTable=N'ContosoSource',
 @TargetSchema=N'dbo',@TargetTable=N'ContosoClone';
*/

-- toolbelt_metadata.USP_ExecuteTableClone
-- Erzeugt den V3-Plan neu und führt nur dessen hashgebundene DDL für neue same-database Ziele aus; keine Datenkopie.
-- Voraussetzung: Modul4.1.1 in der tatsächlich ausgewählten Installationsdatenbank; ausschließlich SameDB-Quell-/Zielobjekte. Ein dreiteiliger zentraler Prozeduraufruf verlegt die Quellobjekte nicht in die Caller-Datenbank. Bestehender ResultTable-Helper>=1.0.0. Basisplanung/Executor/Copy sind TSQL auf Windows/Linux SQL2019/2022/2025 mit zulässigem CL150/160/170. Trigger-Opt-in ist gesondert Windows-only mit bereits vorhandenem exakt gebundenem Parser2.0.1 und vier Parser-TVFs; kein Nachinstallieren.
/* Separat auswählen und ausführen:
EXEC toolbelt_metadata.USP_ExecuteTableClone @Hilfe=1;
-- Client muss exakten Hash aus unveränderter Vorschau und tatsächlichem DB-Kontext binden.
DECLARE @AcceptedPlanHash varbinary(max)=NULL;
-- NULL vor Fachaufruf durch die berechneten32Bytes ersetzen; sonst bewusst Fehler.
EXEC toolbelt_metadata.USP_ExecuteTableClone @SourceSchema=N'dbo',@SourceTable=N'ContosoSource',
 @TargetSchema=N'dbo',@TargetTable=N'ContosoClone',@ExpectedPlanHash=@AcceptedPlanHash;
*/

-- toolbelt_metadata.USP_CopyTableCloneData
-- Kopiert einen begrenzten SameDB-Tabellenverbund atomar in bereits vorhandene leere formgleiche Ziele; keine Strukturkopie oder Rechtevergabe.
-- Voraussetzung: Modul4.1.1 in der tatsächlich ausgewählten Installationsdatenbank; ausschließlich SameDB-Quell-/Zielobjekte. Ein dreiteiliger zentraler Prozeduraufruf verlegt die Quellobjekte nicht in die Caller-Datenbank. Bestehender ResultTable-Helper>=1.0.0. Basisplanung/Executor/Copy sind TSQL auf Windows/Linux SQL2019/2022/2025 mit zulässigem CL150/160/170. Trigger-Opt-in ist gesondert Windows-only mit bereits vorhandenem exakt gebundenem Parser2.0.1 und vier Parser-TVFs; kein Nachinstallieren.
/* Separat auswählen und ausführen:
EXEC toolbelt_metadata.USP_CopyTableCloneData @Hilfe=1;
CREATE TABLE #ContosoMap(MapOrdinal int NOT NULL,SourceSchema nvarchar(max) NOT NULL,
 SourceTable nvarchar(max) NOT NULL,TargetSchema nvarchar(max) NOT NULL,TargetTable nvarchar(max) NOT NULL);
INSERT #ContosoMap VALUES(1,N'dbo',N'ContosoSource',N'dbo',N'ContosoClone');
-- Bestehendes leeres formgleiches Ziel, vorhandene Rechte vorausgesetzt; ändert Daten.
EXEC toolbelt_metadata.USP_CopyTableCloneData @TableMap=N'#ContosoMap',
 @IdentityMode='KEEP',@ConsistencyMode='SERIALIZABLE',@RowLimit=1000,@PayloadByteLimit=1048576;
DROP TABLE #ContosoMap;
*/

-- toolbelt_pseudonymization.TVF_DeterministicGeoJitter
-- Verschiebt einen synthetischen 2D-Geography-Point im SRID 4326 deterministisch innerhalb eines Radius.
-- Voraussetzung: Modul 1.2.0 mit kanonischen T-SQL-Abhängigkeiten derselben Datenbank. SQL2019/2022/2025 auf Windows/Linux mit CL150/160/170 gemäß Modulmatrix. Explizite Versionen und binäre Keys statt impliziter Textkodierung. Keine Fach- oder Systemkatalogabfrage für die Transformation erforderlich. Input- und Fehlercodes vor Weiterverwendung auswerten.
/* Separat auswählen und ausführen:
DECLARE @Point geography=geography::Point(0,0,4326);
SELECT * FROM toolbelt_pseudonymization.TVF_DeterministicGeoJitter(@Point,0x010203,1,0,100);
*/

-- toolbelt_pseudonymization.TVF_DeterministicTranslate
-- Übersetzt ASCII-Buchstaben und Ziffern deterministisch über eine bijektive Abbildung.
-- Voraussetzung: Modul 1.2.0 mit kanonischen T-SQL-Abhängigkeiten derselben Datenbank. SQL2019/2022/2025 auf Windows/Linux mit CL150/160/170 gemäß Modulmatrix. Explizite Versionen und binäre Keys statt impliziter Textkodierung. Keine Fach- oder Systemkatalogabfrage für die Transformation erforderlich. Input- und Fehlercodes vor Weiterverwendung auswerten.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_pseudonymization.TVF_DeterministicTranslate(N'Contoso-123',1,0,N'-',N'standard');
*/

-- toolbelt_pseudonymization.TVF_DeterministicRange
-- Ordnet einen Schlüssel deterministisch einem ganzzahligen Zielbereich zu.
-- Voraussetzung: Modul 1.2.0 mit kanonischen T-SQL-Abhängigkeiten derselben Datenbank. SQL2019/2022/2025 auf Windows/Linux mit CL150/160/170 gemäß Modulmatrix. Explizite Versionen und binäre Keys statt impliziter Textkodierung. Keine Fach- oder Systemkatalogabfrage für die Transformation erforderlich. Input- und Fehlercodes vor Weiterverwendung auswerten.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_pseudonymization.TVF_DeterministicRange(0x010203,1,0,-10,10);
*/

-- toolbelt_pseudonymization.TVF_DeterministicDateShift
-- Verschiebt ein Datum deterministisch um eine begrenzte Anzahl Tage.
-- Voraussetzung: Modul 1.2.0 mit kanonischen T-SQL-Abhängigkeiten derselben Datenbank. SQL2019/2022/2025 auf Windows/Linux mit CL150/160/170 gemäß Modulmatrix. Explizite Versionen und binäre Keys statt impliziter Textkodierung. Keine Fach- oder Systemkatalogabfrage für die Transformation erforderlich. Input- und Fehlercodes vor Weiterverwendung auswerten.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_pseudonymization.TVF_DeterministicDateShift(CONVERT(datetime2(7),'2026-01-15T12:34:56'),0x010203,1,0,30);
*/

-- toolbelt_pseudonymization.USP_DeterministicLookup
-- Deterministischer synthetischer Lookup; explizite Poolversion, kein Anonymisierungs- oder Eins-zu-eins-Schutz.
-- Voraussetzung: Modul 1.2.0 mit kanonischen T-SQL-Abhängigkeiten derselben Datenbank. SQL2019/2022/2025 auf Windows/Linux mit CL150/160/170 gemäß Modulmatrix. Explizite Versionen und binäre Keys statt impliziter Textkodierung. Eigene Caller-Temps ohne parallele Mutation; Fassade vor Core verwenden. Ein gesunder Caller-TX mit Savepoint ist möglich. Kein eigener Reparaturvertrag für doomed Caller-TX.
/* Separat auswählen und ausführen:
EXEC toolbelt_pseudonymization.USP_DeterministicLookup @Hilfe=1;
CREATE TABLE #ContosoInput(Ordinal bigint,[Key] varbinary(max));
CREATE TABLE #ContosoPool(Ordinal bigint,[Value] nvarchar(max));
INSERT #ContosoInput VALUES(1,0x010203),(2,NULL);
INSERT #ContosoPool VALUES(10,N'Contoso alpha'),(30,N'Contoso beta');
EXEC toolbelt_pseudonymization.USP_DeterministicLookup @InputTable=N'#ContosoInput',@LookupTable=N'#ContosoPool',@MappingVersion=1,@LookupVersion=1;
DROP TABLE #ContosoInput;DROP TABLE #ContosoPool;
*/

-- toolbelt_string.TVF_TrimDirectionalNvarchar
-- Entfernt ausgewählte Zeichen links, rechts oder beidseitig aus einem Unicode-Text.
-- Voraussetzung: Directionaltrim-Modul und kanonische mathematische TVF_GenerateSeriesBigInt derselben Installationsdatenbank. Windows/Linux SQL2019/2022/2025, zulässigeCL150/160/170. Installationscollation/Codepage bestimmen den Zeichenvergleich, kein dynamischer Caller-Collationvertrag.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_string.TVF_TrimDirectionalNvarchar(N' xxContoso-123xx ',N' x','BOTH');
*/

-- toolbelt_string.TVF_TrimDirectionalVarchar
-- Entfernt ausgewählte Zeichen links, rechts oder beidseitig aus einem varchar-Text.
-- Voraussetzung: Directionaltrim-Modul und kanonische mathematische TVF_GenerateSeriesBigInt derselben Installationsdatenbank. Windows/Linux SQL2019/2022/2025, zulässigeCL150/160/170. Installationscollation/Codepage bestimmen den Zeichenvergleich, kein dynamischer Caller-Collationvertrag.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_string.TVF_TrimDirectionalVarchar(' xxContoso-123xx ',' x','BOTH');
*/

-- toolbelt_string.TVF_JaroWinklerSimilarity
-- Begrenzte symmetrische Unicode-Skalar-Jaro-Winkler-Ähnlichkeit.
-- Voraussetzung: Installiertes Modul und passende SAFE-Assembly tlblt_String_EditDistance auf unterstütztem SQL Server 2019/2022/2025 unter Windows oder Linux; lokaler/zentraler Aufruf gemäß Modulvertrag. CLR muss bereits gültig konfiguriert und autorisiert sein. Kein Daten-/Systemkatalog-, Datei- oder Netzwerkzugriff im Vergleichskern, keine nachgeladene Library oder Runtime-Rechtevergabe.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_string.TVF_JaroWinklerSimilarity(N'MARTHA',N'MARHTA',N'standard');
-- Similarity ungefähr 0.961111; ErrorCode=0.
-- Für Profil-/Schwellen-Defaults die Position mit DEFAULT belegen.
*/

-- toolbelt_string.TVF_LevenshteinDistance
-- Begrenzte Unicode-Skalar-Levenshtein-Distanz mit optionalem Schwellennachweis.
-- Voraussetzung: Installiertes Modul und passende SAFE-Assembly tlblt_String_EditDistance auf unterstütztem SQL Server 2019/2022/2025 unter Windows oder Linux; lokaler/zentraler Aufruf gemäß Modulvertrag. CLR muss bereits gültig konfiguriert und autorisiert sein. Kein Daten-/Systemkatalog-, Datei- oder Netzwerkzugriff im Vergleichskern, keine nachgeladene Library oder Runtime-Rechtevergabe.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_string.TVF_LevenshteinDistance(N'kitten',N'sitting',NULL,N'standard');
-- Distance=3, ExceedsMaxDistance=0, ErrorCode=0.
-- Für Profil-/Schwellen-Defaults die Position mit DEFAULT belegen.
*/

-- toolbelt_string.TVF_OsaDistance
-- Begrenzte Unicode-Skalar-OSA-Distanz mit optionalem Schwellennachweis.
-- Voraussetzung: Installiertes Modul und passende SAFE-Assembly tlblt_String_EditDistance auf unterstütztem SQL Server 2019/2022/2025 unter Windows oder Linux; lokaler/zentraler Aufruf gemäß Modulvertrag. CLR muss bereits gültig konfiguriert und autorisiert sein. Kein Daten-/Systemkatalog-, Datei- oder Netzwerkzugriff im Vergleichskern, keine nachgeladene Library oder Runtime-Rechtevergabe.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_string.TVF_OsaDistance(N'ab',N'ba',NULL,N'standard');
-- OSA-Distance=1.
-- Für Profil-/Schwellen-Defaults die Position mit DEFAULT belegen.
*/

-- toolbelt_string.TVF_ColognePhonetic
-- Vollständiger begrenzter Kölner Phonetikcode mit geschlossenem Alphabet.
-- Voraussetzung: Installiertes Modul mit passender autorisierter SAFE-Assembly tlblt_String_Phonetic, SQL Server 2019/2022/2025 auf Windows/Linux gemäß Modulmatrix, lokal oder zentral. Keine Abhängigkeit von Distanz-/Jaro-Assembly, Daten-/Systemkatalog-, Datei- oder Netzwerkzugriff im Scanner. Der markierte Scannerport und sein Herkunfts-/Lizenzvertrag bleiben unverändert.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_string.TVF_ColognePhonetic(N'PH');
-- PhoneticCode=3, ErrorCode=0.
SELECT * FROM toolbelt_string.TVF_ColognePhonetic(NULL);
-- Genau eine NULL-Codezeile mit ErrorCode=0.
*/

-- toolbelt_string.TVF_DoubleMetaphone
-- Vollständige begrenzte primäre und alternative Double-Metaphone-Codes.
-- Voraussetzung: Installiertes Modul mit passender autorisierter SAFE-Assembly tlblt_String_Phonetic, SQL Server 2019/2022/2025 auf Windows/Linux gemäß Modulmatrix, lokal oder zentral. Keine Abhängigkeit von Distanz-/Jaro-Assembly, Daten-/Systemkatalog-, Datei- oder Netzwerkzugriff im Scanner. Der markierte Scannerport und sein Herkunfts-/Lizenzvertrag bleiben unverändert.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_string.TVF_DoubleMetaphone(N'PH');
-- PrimaryCode=F, AlternateCode=F, ErrorCode=0.
SELECT * FROM toolbelt_string.TVF_DoubleMetaphone(NULL);
-- Genau eine NULL-Codezeile mit ErrorCode=0.
*/

-- toolbelt_string.TVF_RegexCaptures
-- Materialisiert alle Wiederholungen deklarierter Capturegruppen und Kontrollzeilen unbeteiligter Gruppen.
-- Voraussetzung: Installierte SAFE-Regexassembly tlblt_String_Regex und passende kanonische Objekte1.3.0 derselben Datenbank. SQL2019/2022/2025 Windows/Linux mit CL150/160/170 gemäß Modulmatrix. Vorhandene CLR-/Trustvoraussetzungen gemäß gewähltem Installer; keine eigene Serverkonfiguration oder Rechtevergabe. Alle Inputwerte als Unicode übergeben, varchar beim Caller unter seiner Quellcollation ausdrücklich nach nvarchar(max) konvertieren.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_string.TVF_RegexCaptures(N'abab',N'(ab)+',1,N'c',N'standard',10000) ORDER BY MatchOrdinal,GroupOrdinal,CaptureOrdinal;
*/

-- toolbelt_string.SVF_RegexReplaceGroups
-- Ersetzt Gesamttreffer mit streng geprüften numerischen oder benannten Gruppenreferenzen.
-- Voraussetzung: Installierte SAFE-Regexassembly tlblt_String_Regex und passende kanonische Objekte1.3.0 derselben Datenbank. SQL2019/2022/2025 Windows/Linux mit CL150/160/170 gemäß Modulmatrix. Vorhandene CLR-/Trustvoraussetzungen gemäß gewähltem Installer; keine eigene Serverkonfiguration oder Rechtevergabe. Alle Inputwerte als Unicode übergeben, varchar beim Caller unter seiner Quellcollation ausdrücklich nach nvarchar(max) konvertieren.
/* Separat auswählen und ausführen:
SELECT toolbelt_string.SVF_RegexReplaceGroups(N'Contoso42',N'(?<word>[A-Za-z]+)([0-9]+)',N'${word}:$2:$$',1,0,N'c',N'standard') AS Replaced;
*/

-- toolbelt_string.TVF_RegexMatches
-- Materialisiert nicht überlappende Gesamttreffer mit Position, Länge und Originaltext.
-- Voraussetzung: Installierte SAFE-Regexassembly tlblt_String_Regex und passende kanonische Objekte1.3.0 derselben Datenbank. SQL2019/2022/2025 Windows/Linux mit CL150/160/170 gemäß Modulmatrix. Vorhandene CLR-/Trustvoraussetzungen gemäß gewähltem Installer; keine eigene Serverkonfiguration oder Rechtevergabe. Alle Inputwerte als Unicode übergeben, varchar beim Caller unter seiner Quellcollation ausdrücklich nach nvarchar(max) konvertieren.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_string.TVF_RegexMatches(N'a1b22',N'\d+',1,N'c',N'standard',10000) ORDER BY Ordinal;
*/

-- toolbelt_string.TVF_RegexSplit
-- Zerlegt den ganzen Input an Regexseparatoren in Originaltokens einschließlich Leertokens.
-- Voraussetzung: Installierte SAFE-Regexassembly tlblt_String_Regex und passende kanonische Objekte1.3.0 derselben Datenbank. SQL2019/2022/2025 Windows/Linux mit CL150/160/170 gemäß Modulmatrix. Vorhandene CLR-/Trustvoraussetzungen gemäß gewähltem Installer; keine eigene Serverkonfiguration oder Rechtevergabe. Alle Inputwerte als Unicode übergeben, varchar beim Caller unter seiner Quellcollation ausdrücklich nach nvarchar(max) konvertieren.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_string.TVF_RegexSplit(N'a,,b,',N',',N'c',N'standard',10000) ORDER BY Ordinal;
*/

-- toolbelt_string.SVF_RegexIsMatch
-- Prüft im begrenzten Toolbelt-Regexdialekt, ob mindestens ein Gesamttreffer existiert.
-- Voraussetzung: Installierte SAFE-Regexassembly tlblt_String_Regex und passende kanonische Objekte1.3.0 derselben Datenbank. SQL2019/2022/2025 Windows/Linux mit CL150/160/170 gemäß Modulmatrix. Vorhandene CLR-/Trustvoraussetzungen gemäß gewähltem Installer; keine eigene Serverkonfiguration oder Rechtevergabe. Alle Inputwerte als Unicode übergeben, varchar beim Caller unter seiner Quellcollation ausdrücklich nach nvarchar(max) konvertieren.
/* Separat auswählen und ausführen:
SELECT toolbelt_string.SVF_RegexIsMatch(N'Contoso 42',N'\d+',DEFAULT) AS HasDigits;
*/

-- toolbelt_string.SVF_RegexInstr
-- Liefert die absolute UTF-16-Start- oder Endposition des n-ten Gesamttreffers.
-- Voraussetzung: Installierte SAFE-Regexassembly tlblt_String_Regex und passende kanonische Objekte1.3.0 derselben Datenbank. SQL2019/2022/2025 Windows/Linux mit CL150/160/170 gemäß Modulmatrix. Vorhandene CLR-/Trustvoraussetzungen gemäß gewähltem Installer; keine eigene Serverkonfiguration oder Rechtevergabe. Alle Inputwerte als Unicode übergeben, varchar beim Caller unter seiner Quellcollation ausdrücklich nach nvarchar(max) konvertieren.
/* Separat auswählen und ausführen:
SELECT toolbelt_string.SVF_RegexInstr(N'a1b22',N'\d+',1,2,0,N'c') AS StartPosition;
*/

-- toolbelt_string.SVF_RegexCount
-- Zählt nicht überlappende Gesamttreffer ab einer UTF-16-Startposition.
-- Voraussetzung: Installierte SAFE-Regexassembly tlblt_String_Regex und passende kanonische Objekte1.3.0 derselben Datenbank. SQL2019/2022/2025 Windows/Linux mit CL150/160/170 gemäß Modulmatrix. Vorhandene CLR-/Trustvoraussetzungen gemäß gewähltem Installer; keine eigene Serverkonfiguration oder Rechtevergabe. Alle Inputwerte als Unicode übergeben, varchar beim Caller unter seiner Quellcollation ausdrücklich nach nvarchar(max) konvertieren.
/* Separat auswählen und ausführen:
SELECT toolbelt_string.SVF_RegexCount(N'a1b22',N'\d+',1,N'c') AS MatchCount;
*/

-- toolbelt_string.SVF_RegexReplace
-- Ersetzt ausgewählte Gesamttreffer durch literalen Unicode-Text ohne Gruppenexpansion.
-- Voraussetzung: Installierte SAFE-Regexassembly tlblt_String_Regex und passende kanonische Objekte1.3.0 derselben Datenbank. SQL2019/2022/2025 Windows/Linux mit CL150/160/170 gemäß Modulmatrix. Vorhandene CLR-/Trustvoraussetzungen gemäß gewähltem Installer; keine eigene Serverkonfiguration oder Rechtevergabe. Alle Inputwerte als Unicode übergeben, varchar beim Caller unter seiner Quellcollation ausdrücklich nach nvarchar(max) konvertieren.
/* Separat auswählen und ausführen:
SELECT toolbelt_string.SVF_RegexReplace(N'a1b22',N'\d+',N'$1',1,0,N'c',N'standard') AS LiteralReplacement;
-- $1 bleibt hier literal; für Gruppen die getrennte ReplaceGroups-API nutzen.
*/

-- toolbelt_string.SVF_RegexSubstring
-- Liefert den n-ten Gesamttreffer als Unicode-Text oder NULL, wenn er fehlt.
-- Voraussetzung: Installierte SAFE-Regexassembly tlblt_String_Regex und passende kanonische Objekte1.3.0 derselben Datenbank. SQL2019/2022/2025 Windows/Linux mit CL150/160/170 gemäß Modulmatrix. Vorhandene CLR-/Trustvoraussetzungen gemäß gewähltem Installer; keine eigene Serverkonfiguration oder Rechtevergabe. Alle Inputwerte als Unicode übergeben, varchar beim Caller unter seiner Quellcollation ausdrücklich nach nvarchar(max) konvertieren.
/* Separat auswählen und ausführen:
SELECT toolbelt_string.SVF_RegexSubstring(N'a1b22',N'\d+',1,2,N'c',N'standard') AS SecondMatch;
*/

-- toolbelt_string.TVF_SplitAdvanced
-- Zerlegt Originaltokens mit mehreren Separatoren, Quotes und Escape-Regeln; entquotiert sie nicht.
-- Voraussetzung: Reines T-SQL-Modul auf SQL Server 2019/2022/2025 unter Windows/Linux, unterstützter Compatibility Level mindestens 150. OPENJSON liest ausschließlich übergebenes JSON, keine Quelldaten oder externen Systeme. Lokal/zentral dieselbe Fachquelle. Separatoren müssen ein nichtleeres JSON-Array von Strings sein; NUL und aktive Quote-/Escapezeichen darin verboten. Quote und Escape leer unabhängig deaktiviert, sonst jeweils genau eine unterschiedliche Nicht-Surrogate-Codeunit; NULL ist bei nicht-NULL Input ungültig. Separatorstrings selbst sind keine Unicode-Normalisierungsfunktion.
/* Separat auswählen und ausführen:
SELECT Value,Ordinal,IsValid,ErrorCode,ErrorPosition
FROM toolbelt_string.TVF_SplitAdvanced(N'a;"b;c";d',N'[";"]',DEFAULT,DEFAULT,DEFAULT)
ORDER BY Ordinal;
-- Drei Originaltokens; IsValid=1, Fehlerfelder NULL.
SELECT * FROM toolbelt_string.TVF_SplitAdvanced(NULL,NULL,NULL,NULL,NULL);
-- Keine Zeilen, wegen frühem NULL-No-op.
*/

-- toolbelt_string.TVF_UnquoteToken
-- Entfernt ein unterstütztes äußeres Quote-Paar und decodiert dessen Escapes.
-- Voraussetzung: SQL Server 2019/2022/2025, Windows/Linux, CL150/160/170. Split-Advanced-Modul installiert; diese Funktion selbst hat keine Tabellen-/Helper-/CLR-/Netzwerkabhängigkeit. Alle vier Argumentpositionen angeben, DEFAULT für die gewünschten technischen Defaults.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_string.TVF_UnquoteToken
 (N'[a]]b]',DEFAULT,DEFAULT,DEFAULT);
-- Value=a]b, IsValid=1, ErrorCode/ErrorPosition=NULL.
SELECT * FROM toolbelt_string.TVF_UnquoteToken
 (NULL,DEFAULT,DEFAULT,DEFAULT);
-- Keine Zeile.
*/

-- toolbelt_string.USP_SplitAdvanced
-- Originaltokens aus kanonischer TVF; Geschäftsfehler vor Zielmutation, kein Unquoting.
-- Voraussetzung: Reines T-SQL-Modul auf SQL Server 2019/2022/2025 unter Windows/Linux, unterstützter Compatibility Level mindestens 150. OPENJSON liest ausschließlich übergebenes JSON, keine Quelldaten oder externen Systeme. Lokal/zentral dieselbe Fachquelle. Öffentlicher TVF-Kern in derselben Datenbank installiert; ResultTable-Pfad zusätzlich sameDB USP_PrepareResultTable >=1.0.0 mit exakt den fünf erwarteten SQL-Parametern. Keine Extended Properties oder Runtime-Modulmarkerprüfung. Separatoren müssen ein nichtleeres JSON-Array von Strings sein; NUL und aktive Quote-/Escapezeichen darin verboten. Quote und Escape leer unabhängig deaktiviert, sonst jeweils genau eine unterschiedliche Nicht-Surrogate-Codeunit; NULL ist bei nicht-NULL Input ungültig. Separatorstrings selbst sind keine Unicode-Normalisierungsfunktion.
/* Separat auswählen und ausführen:
EXEC toolbelt_string.USP_SplitAdvanced @Input=N'a;"b;c";d',@SeparatorsJson=N'[";"]';
-- Drei Originaltokens: a, Doppelquote b;c Doppelquote, d.
EXEC toolbelt_string.USP_SplitAdvanced @Hilfe=1;
*/

-- toolbelt_string.TVF_SplitByCharacters
-- Teilt begrenzten Unicode-Text an einer Menge einzelner UTF-16-Separatoren.
-- Voraussetzung: SQL Server 2019/2022/2025, Windows/Linux, CL150/160/170. Modul und Generate-Series-Abhängigkeit installiert. Alle drei Argumentpositionen angeben; DEFAULT oder NULL bei KeepEmpty wirkt wie 1. Keine CLR-, Datei-, Netzwerk- oder Systemkatalogabhängigkeit.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_string.TVF_SplitByCharacters(N'a,,b',N',',DEFAULT)
ORDER BY Ordinal;
-- Value a / leer / b, Ordinal 1 / 2 / 3.
*/

-- toolbelt_string.TVF_SplitByCharactersStatus
-- Teilt begrenzten Unicode-Text an einer Menge einzelner UTF-16-Separatoren.
-- Voraussetzung: SQL Server 2019/2022/2025, Windows/Linux, CL150/160/170. Modul und Generate-Series-Abhängigkeit installiert. Alle drei Argumentpositionen angeben; DEFAULT oder NULL bei KeepEmpty wirkt wie 1. Keine CLR-, Datei-, Netzwerk- oder Systemkatalogabhängigkeit.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_string.TVF_SplitByCharactersStatus(N'a,,b',N',',DEFAULT)
ORDER BY Ordinal;
-- Value a / leer / b, Ordinal 1 / 2 / 3, jeweils OK.
*/

-- toolbelt_string.USP_CompareTextPairs
-- Begrenzt vergleicht vorhandene lokale Textpaare mit den kanonischen Distanz-/Jaro-TVFs. Globale Fehler veröffentlichen keine Teilresultate.
-- Voraussetzung: Installierte Module text-pairs, edit-distance mit passender SAFE-Assembly und ResultTable-Helfer im selben Toolbelt-Datenbankkontext, SQL Server 2019/2022/2025 unter Windows/Linux gemäß Modulmatrix. Zentrale Verwendung erfolgt dreiteilig mit sessionlokalen #Temps des Callers. Input muss während des synchronen Aufrufs stabil bleiben; keine MARS-/parallele Mutation. Tabellenrouting benötigt eine committable lokale Transaktion oder eine neu startbare eigene Transaktion; verteilte Caller-Savepoints sind nicht unterstützt. Reine Hilfe kehrt vor diesen Fachprüfungen zurück.
/* Separat auswählen und ausführen:
CREATE TABLE #Pairs(PairOrdinal bigint,LeftText nvarchar(max),RightText nvarchar(max));
INSERT #Pairs VALUES(1,N'kitten',N'sitting'),(2,NULL,N'example');
EXEC toolbelt_string.USP_CompareTextPairs @PairsTable=N'#Pairs',@Algorithm=N'levenshtein';
-- Ordinal 1: Distance=3/Exceeds=0/Code=0; Ordinal 2: NULL-Fachwerte/Code=0.
EXEC toolbelt_string.USP_CompareTextPairs @Hilfe=1;
DROP TABLE #Pairs;
*/

-- toolbelt_tsql.TVF_ParseScriptNodes
-- Liefert die AST-Knoten eines begrenzten T-SQL-Skripts.
-- Voraussetzung: Windows-only UNSAFE-CLR-Modul2.0.1 gemäß aktuellem Modulvertrag; passende tlblt_Tsql_ScriptParser-Assembly und exakt vom aktuellen Builder gebundene tlblt.Microsoft.SqlServer.TransactSql.ScriptDom-Abhängigkeit. Unterstützte SQL2019/2022/2025-Hosts mit zulässigem CL150/160/170; der Parserdialekt ist separat wählbar. Vorhandene CLR-/Trustvoraussetzungen des gewählten Installers. Es wird kein Zielsystem oder Katalog für den Text benötigt.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_tsql.TVF_ParseScriptNodes(N'SELECT 1 AS ContosoValue;',160,1,2097152,100) ORDER BY NodeId;
*/

-- toolbelt_tsql.TVF_ParseScriptNodeProperties
-- Liefert Eigenschaften der geparsten T-SQL-AST-Knoten.
-- Voraussetzung: Windows-only UNSAFE-CLR-Modul2.0.1 gemäß aktuellem Modulvertrag; passende tlblt_Tsql_ScriptParser-Assembly und exakt vom aktuellen Builder gebundene tlblt.Microsoft.SqlServer.TransactSql.ScriptDom-Abhängigkeit. Unterstützte SQL2019/2022/2025-Hosts mit zulässigem CL150/160/170; der Parserdialekt ist separat wählbar. Vorhandene CLR-/Trustvoraussetzungen des gewählten Installers. Es wird kein Zielsystem oder Katalog für den Text benötigt.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_tsql.TVF_ParseScriptNodeProperties(N'SELECT 1 AS ContosoValue;',160,1,2097152,100) ORDER BY NodeId,PropertyName;
*/

-- toolbelt_tsql.TVF_TokenizeScript
-- Liefert Tokens eines T-SQL-Skripts.
-- Voraussetzung: Windows-only UNSAFE-CLR-Modul2.0.1 gemäß aktuellem Modulvertrag; passende tlblt_Tsql_ScriptParser-Assembly und exakt vom aktuellen Builder gebundene tlblt.Microsoft.SqlServer.TransactSql.ScriptDom-Abhängigkeit. Unterstützte SQL2019/2022/2025-Hosts mit zulässigem CL150/160/170; der Parserdialekt ist separat wählbar. Vorhandene CLR-/Trustvoraussetzungen des gewählten Installers. Es wird kein Zielsystem oder Katalog für den Text benötigt.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_tsql.TVF_TokenizeScript(N'SELECT 1 AS ContosoValue;',160,1,2097152,100) ORDER BY TokenIndex;
*/

-- toolbelt_tsql.TVF_ParseScriptErrors
-- Liefert Parserfehler eines T-SQL-Skripts, ohne das Skript auszuführen.
-- Voraussetzung: Windows-only UNSAFE-CLR-Modul2.0.1 gemäß aktuellem Modulvertrag; passende tlblt_Tsql_ScriptParser-Assembly und exakt vom aktuellen Builder gebundene tlblt.Microsoft.SqlServer.TransactSql.ScriptDom-Abhängigkeit. Unterstützte SQL2019/2022/2025-Hosts mit zulässigem CL150/160/170; der Parserdialekt ist separat wählbar. Vorhandene CLR-/Trustvoraussetzungen des gewählten Installers. Es wird kein Zielsystem oder Katalog für den Text benötigt.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_tsql.TVF_ParseScriptErrors(N'SELECT 1 AS ContosoValue;',160,1,2097152,100) ORDER BY ErrorOrdinal;
-- Eigene reine Syntaxgegenprobe,keine Ausführung des Texts:
SELECT * FROM toolbelt_tsql.TVF_ParseScriptErrors(N'SELECT FROM;',160,1,2097152,100) ORDER BY ErrorOrdinal;
*/

-- toolbelt_tsql.USP_ExplainSsisDataFlow
-- Debug-SQL aus DTSX-XML, Paketdefaults und optionalen JSON-Startwerten. Standardmäßig paketbasierter Entwurf ohne Quellkatalogzugriff; CatalogMode=catalog wählt strengere Prüfung. Keine automatische Paket-/SQL-Ausführung.
-- Voraussetzung: Windows SQL2019/2022/2025 und zum Host zulässiges CL150/160/170. Vorhandene UNSAFE-Assembly tlblt_Tsql_SsisDebug mit privatem gepinntem tlblt.Microsoft.SqlServer.TransactSql.ScriptDom, vorhandene CLR-/Trustvoraussetzungen. Keine Abhängigkeit auf öffentliche Parser-TVFs. Derselbe ResultTable-Helper nur bei optionalem Zielrouting. Vollständiges entschlüsseltes DTSX-XML mit unterstütztem Format6/8; keine SSIS-Installation, Dateiquelle oder Zielserververbindung wird benötigt. Package-Modus kann Zielmetadaten durch Paketdeklarationen ersetzen, aber keine nicht vorhandene Prozedurdefinition rekonstruieren.
/* Separat auswählen und ausführen:
EXEC toolbelt_tsql.USP_ExplainSsisDataFlow @Hilfe=1;
-- Vollständiges synthetisches DTSX-XML vom Client binden.
DECLARE @Dtsx nvarchar(max)=NULL;
-- @Dtsx vor dem Fachaufruf mit dem Paket füllen.
EXEC toolbelt_tsql.USP_ExplainSsisDataFlow @PackageXml=@Dtsx,@CatalogMode='package',
 @StartValues=N'{"User::SourceFloor":5}';
-- Nur tatsächlich vorhandene, eindeutig benannte, nicht sensitive Werte angeben.
*/

-- toolbelt_validation.TVF_ParseSemanticVersion
-- Prüft und zerlegt einen strikten SemVer-2.0.0-Text mit explizitem Validierungsstatus.
-- Voraussetzung: Installiertes T-SQL-Modul auf unterstütztem SQL Server 2019/2022/2025 unter Windows oder Linux. Lokal und zentral gemäß vorhandenem Deploymentvertrag; Abhängigkeiten innerhalb des Moduls müssen vorhanden sein. Keine CLR-, Root-, Datenquellen- oder Netzwerkanforderung. Die relevanten Zeichenvergleiche verwenden explizit Latin1_General_100_BIN2.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_validation.TVF_ParseSemanticVersion('1.2.3-alpha.1+build.007');
-- IsValid=1, ValidationCode=VALID; BuildMetadata bleibt build.007.
SELECT IsValid,ValidationCode FROM toolbelt_validation.TVF_ParseSemanticVersion(NULL);
-- Genau eine Zeile mit NULL_INPUT.
*/

-- toolbelt_validation.TVF_CompareSemanticVersion
-- Vergleicht zwei gültige SemVer-Versionen nach Präzedenz als relationaler Kern.
-- Voraussetzung: Installiertes T-SQL-Modul auf unterstütztem SQL Server 2019/2022/2025 unter Windows oder Linux. Lokal und zentral gemäß vorhandenem Deploymentvertrag; Abhängigkeiten innerhalb des Moduls müssen vorhanden sein. Keine CLR-, Root-, Datenquellen- oder Netzwerkanforderung. Die relevanten Zeichenvergleiche verwenden explizit Latin1_General_100_BIN2.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_validation.TVF_CompareSemanticVersion('1.0.0-alpha.2','1.0.0-alpha.10');
-- ComparisonResult=-1.
SELECT * FROM toolbelt_validation.TVF_CompareSemanticVersion('1.0.0+one','1.0.0+two');
-- ComparisonResult=0, Builddaten sind kein Tie-Breaker.
*/

-- toolbelt_validation.TVF_SemanticVersionSortKey
-- Erzeugt einen binären Sortierschlüssel für gültige SemVer-Präzedenz.
-- Voraussetzung: Installiertes T-SQL-Modul auf unterstütztem SQL Server 2019/2022/2025 unter Windows oder Linux. Lokal und zentral gemäß vorhandenem Deploymentvertrag; Abhängigkeiten innerhalb des Moduls müssen vorhanden sein. Keine CLR-, Root-, Datenquellen- oder Netzwerkanforderung. Die relevanten Zeichenvergleiche verwenden explizit Latin1_General_100_BIN2.
/* Separat auswählen und ausführen:
SELECT v.Version,s.SortKey
FROM (VALUES('1.0.0'),('1.0.0-beta'),('1.0.0-alpha')) v(Version)
CROSS APPLY toolbelt_validation.TVF_SemanticVersionSortKey(v.Version) s
WHERE s.SortKey IS NOT NULL
ORDER BY s.SortKey,v.Version;
-- alpha, beta, Release; zusätzlicher Tie-Breaker für gleiche Präzedenz.
*/

-- toolbelt_validation.SVF_CompareSemanticVersion
-- Skalarer Komfortaufruf des kanonischen relationalen SemVer-Vergleichs.
-- Voraussetzung: Installiertes T-SQL-Modul auf unterstütztem SQL Server 2019/2022/2025 unter Windows oder Linux. Lokal und zentral gemäß vorhandenem Deploymentvertrag; Abhängigkeiten innerhalb des Moduls müssen vorhanden sein. Keine CLR-, Root-, Datenquellen- oder Netzwerkanforderung. Die relevanten Zeichenvergleiche verwenden explizit Latin1_General_100_BIN2.
/* Separat auswählen und ausführen:
SELECT toolbelt_validation.SVF_CompareSemanticVersion('2.0.0','1.9.9') AS ComparisonResult;
-- 1; für viele Quellzeilen die TVF per APPLY verwenden.
*/

-- toolbelt_validation.SVF_SemanticVersionSortKey
-- Skalarer Komfortaufruf des kanonischen relationalen SemVer-Sortierschlüssels.
-- Voraussetzung: Installiertes T-SQL-Modul auf unterstütztem SQL Server 2019/2022/2025 unter Windows oder Linux. Lokal und zentral gemäß vorhandenem Deploymentvertrag; Abhängigkeiten innerhalb des Moduls müssen vorhanden sein. Keine CLR-, Root-, Datenquellen- oder Netzwerkanforderung. Die relevanten Zeichenvergleiche verwenden explizit Latin1_General_100_BIN2.
/* Separat auswählen und ausführen:
SELECT toolbelt_validation.SVF_SemanticVersionSortKey('1.2.3-alpha.1') AS SortKey;
-- Für Mengen TVF_SemanticVersionSortKey per APPLY verwenden.
*/
