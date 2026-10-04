# USP_ScriptTableClone

Version4.1.0: die öffentliche13-Parameter-Vorschau bleibt unverändert; interner
Zweckparameter nur im Core für die separat freigegebene Datenkopie.
Trigger-Opt-in aus4.0 einzeln freigegeben2026-10-01 und konkretisiert2026-10-04;
Script-only same-database. Neue4.1-Qualifikation noch nicht ausgeführt;
historische Nachweise bleiben getrennt.
Signatur: `SourceSchema nvarchar(max)=NULL`, `SourceTable nvarchar(max)=NULL`,
`TargetSchema nvarchar(max)=NULL`, `TargetTable nvarchar(max)=NULL`,
`IncludeIdentity bit=0`, `IncludeExtendedProperties bit=0`, `TableMap sysname=NULL`, `ExternalReferenceRule varchar(16)='REJECT'`, `IncludeTriggers bit=0`, `ResultTable sysname=NULL`, `KeepData bit=0`,
`Debug tinyint=0`, `Hilfe bit=0`. Im W1-Einzelmodus sind alle vier Identifier erforderlich; im Mapmodus sind sie NULL;
einzelne Namen, keine Multipartinterpretation, nicht trimmen,1–128 UTF16Units,
NUL verboten. nvarchar(max) vermeidet stille Parametertrunkierung.
Alle drei Include-Parameter NULL ungültig; Standard-NULLs entsprechen0. Hilfe1 umgeht alles.

Ergebnis: Ordinal int, ObjectKind varchar(32), TargetName nvarchar(776),
ScriptText nvarchar(max), alle NOT NULL. Text BIN2, ObjectKind SESSION_OPTION/EXTENDED_PROPERTY/TABLE/DEFAULT/
CHECK/PRIMARY_KEY/UNIQUE_CONSTRAINT/INDEX/FOREIGN_KEY/FOREIGN_KEY_STATE sowie bei Trigger-Opt-in TRIGGER/TRIGGER_STATE. Ordinal1-basiert lückenlos;
Sieben SESSION_OPTION-Zeilen zuerst, TABLE anOrdinal8, Defaults, Checks, clustered Schlüssel/Index, übrige Indizes.
ResultTable-Tabelle hat keine garantierte physische Reihenfolge.

Unterstützt: reguliere diskbasierte Heap/Clustered-Tabellen; eingebaute Typen
tinyint/smallint/int/bigint/bit/decimal/numeric/money/smallmoney/float/real,
date/time/datetime/smalldatetime/datetime2/datetimeoffset,
char/nchar/varchar/nvarchar/binary/varbinary inklusive max,
uniqueidentifier/xml(untyped)/timestamp/rowversion/sql_variant.
Längen/Precision/Scale/Nullability/Collation erhalten. Optional Identity
Seed/Increment, niemals aktuelle last_value oder Daten.
Defaults und vertrauenswürdige aktive Checks wörtlich; PK/UQ und gewöhnliche
unpartitionierte Rowstoreindizes; gewöhnliche nonclustered Indizes optional gefiltert mit Keyrichtung/INCLUDE/Uniqueness,
Fillfactor/Padding/IgnoreDupKey/Rowlocks/Pagelocks/StatsNoRecompute und Filegroup.
Catalog-Fillfactor0 wird als semantisch äquivalentes explizites100 gerendert;
es ist kein gültiger expliziter DDL-Prozentwert. Catalog-Collationnamen werden
als Engine-validierte COLLATE-Tokens ausgegeben, nicht als geklammerte Identifier.
LOB-Filegroup explizit. Keine Statistikdaten/Buildoptionen/Source-Dateigrößen.

Unsupported führt zu53903 ohne Teilausgabe: temporär/external/system/memory/
FileTable/temporal/ledger/graph/replication/CDC; sparse/columnset/rowguid/
FILESTREAM/generated/hidden/masked/encrypted/typedXML/rules; CLR/alias/legacy
text/ntext/image-Typen/gebundene Defaults/ANSI_PADDING OFF;
im W1-Einzelmodus FK einschließlich eingehender, Trigger bei IncludeTriggers0; relevante Properties bei IncludeExtendedProperties0;
clustered-gefilterte/disabled/hypothetical/OPTIMIZE_FOR_SEQUENTIAL_KEY=ON/partitionierte/compressed/fulltext/XML/spatial/
columnstore Indizes, untrusted/disabled/not-for-replication Checks/Identity.
Kein Rechte-/Ownership-Klon; FK nur im begrenzten W2-Mapmodus; Trigger nur im expliziten Windows-Opt-in. Toolbelt.-Properties werden immer abgelehnt. Berechtigungen bleiben bewusst
außerhalb dieser strukturellen Vorschau; Metadatensichtbarkeit ersetzt keine
spätere DDL-/Funktions-/Dateigruppenberechtigung des ausführenden Callers.

Deterministische DF/CK/PK/UQ/IX-Namen: Typpräfix + vollständiger SHA256hex64
über length-framed UTF16 Zielschema/Zieltabelle und Quellcolumnordinal bzw.
originalen Constraint-/Indexnamen. Kein zufälliger Suffix/Trunkieren/Casefold.
Constraintnamen werden gegen Zielschema/Plan unter DATABASE_DEFAULT geprüft;
Indexnamen gehören zur noch nicht existierenden Zieltabelle. Identifier stets
QUOTENAME. Hashnamen enthalten keine verwertbaren Datenschutzgarantien.

Fehlerpriorität: Help; reservierter Caller-Tempnamespace vor Core-Kompilierung;
DB-VIEW-DEFINITION vor Argumenten/NUL; Quellsicht; Zielsicht/Existenz; Unsupported in dokumentierter
Source-Prüfreihenfolge; Definitionssicht; Metadatengrenzen; Namenskollision;
fertige Planbytes; optional Dependency/Outputpreflight/Write.
53900 Argumente,53901 Quelle/Sicht,53902 Ziel/Sicht,53903 Unsupported,
53904 Kollision,53905 Definition,53906 Ressourcen,53907 Dependency,
53908 Namespace (caller-belegte interne Tabelle oder reserviertes ResultTable-Prefix,
auch in Großschreibung; vor Kernkompilierung geprüft). Enginefehler bleiben unverändert.
Keine realen Werte im Fehlertext.
Limits1024Spalten/128Indexmetadaten je Tabelle, Map64, global2048Kindobjekte-plus-FK-Spaltentupel/2MiB Scripttext,
vor LOB-Materialisierung Definitionsbytes prüfen; keine RAM/Wallclockgarantie.

Quelle strukturell stabil halten. Vorschau ist Momentaufnahme; keine spätere
Driftfreiheit, kein automatisches Recovery.
CHANGE_TRACKING, LOCK_ESCALATION und sonstige nicht ausdrücklich gelistete
Tabellenoptionen sind nicht als Erhalt qualifiziert. Dieser begrenzte
Scriptplaner ist keine vollständige Tabellenkopie; solche Optionen benötigen
einen gesonderten Vertrag und synthetische Oracles.
Vollständiger Plan vor ResultTable-Mutation, kanonischer Helper, eigene
Transaktion oder Caller-savepoint;
niemals fremde Transaktion committen. Doomed Caller benötigt Callerrollback.
Debug nur Messages. EXECUTE plus datenbankweite VIEW DEFINITION erforderlich:
incoming-FKs in fremden Schemas dürfen durch Metadata Visibility nicht unsichtbar
bleiben. Objekt-/Schemasicht allein reicht nicht; fehlende DB-Sicht ergibt53901
vor Planung und ResultTable-Mutation. Die API erteilt keine Rechte.
kein EXECUTE AS/Rechteausweitung. Zentrale Quellen liegen in InstallationsDB.

Historische V1-Tests: ausschließlich synthetische Metadaten/DDL; risikobasierte2019Linux-
und2025Windows-Nachweise erfolgreich, weitere Kontexte offen; siehe Modul-Testmatrix.

Primärquellen:

- [Microsoft CREATE TABLE](https://learn.microsoft.com/en-us/sql/t-sql/statements/create-table-transact-sql?view=sql-server-ver17)
- [Microsoft CREATE INDEX](https://learn.microsoft.com/en-us/sql/t-sql/statements/create-index-transact-sql?view=sql-server-ver15)
- [Microsoft sys.columns](https://learn.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-columns-transact-sql?view=sql-server-ver17)

## Welle1-Details und Positionsbruch

Der [freigegebene W1-Vertrag](../../../Documentation/Architecture/TABLE_CLONE_WAVE1_CONTRACT.md)
ist für Computed/PERSISTED, Filter, endliche Propertytypen, Quotas und Fehlerphasen verbindlich.
Computed-Spalten verwenden unveränderte Catalogdefinitionen; PERSISTED und explizites NOT NULL
nur gemäß Catalog. Nur tabellenlokale Built-ins; UDF/externe/unklare Dependencies blockieren53903.
Bei Computed wird vorhandenes SELECT sys.sql_expression_dependencies vorausgesetzt;
fehlend oder NULL blockiert53901/3 vor Dependencyabfrage. Keine Rechtevergabe.

Die sieben SET-Zeilen sind reine Texte, keine Optionsänderung durch die API.
EXTENDED_PROPERTY enthält zwei Statements: typisierte DECLARE-Variable und
sp_addextendedproperty. Nur die neue TRIGGER-Zeile enthält zusätzlich die feste
Quell-SET-/sp_executesql-Kapselung gemäß Triggervertrag. Bei externer Batchzusammenfügung ist @tbx_CloneEp<Ordinal>
reserviert; separate Batches derselben Session haben getrennten Variablenscope.
Propertywerte werden mit Basistyp/Precision/Scale/MaxLength/Collation rekonstruiert.
Unsupported oder ein spätes Bytequota verwirft den ganzen Plan vor ResultTable-Mutation.
Keine neue feste Planzeilenquote; die bestehende2MiB-Gesamtgrenze gilt inklusive SET/Properties.

Position6 ist jetzt IncludeExtendedProperties; altePositionen6..9 verschieben sich auf7..10.
Benannte Argumente bleiben eindeutig; kein automatischer V1-Dispatch.
[Historischer V1-Vertrag](https://github.com/gecompat/SQL_Server_Toolbelt/blob/fdafa8038e4d5240dd727096f144c8d5fd884117/Modules/toolbelt.metadata.table-clone/Documentation/USP_ScriptTableClone.md).
W1-Runtime und Propertyroundtrips: ausgewählter öffentlicher Scope bestanden. CI am geprüften Head 76888216 bestanden; neue Rechtekontexte: NOT_EXECUTED.
## Finaler öffentlicher W1-Nachweis 2026-10-03

Am 2026-10-03 bestanden die finalen öffentlichen Adapter auf SQL Server 2019 Linux/latest CL150 und 2025 Windows/CU8 CL150/160/170 jeweils lokal und zentral. Vier Runtime-Fixtures einschließlich 27 Propertytypen und separater 18-datetimeoffset-Produktpfadregression, Client-/Lifecycle-/Caller-TX-/SET-/AppLock-/Rollback-/Kollisions-/Dependency-/Atomikorakel sowie genuine 1.0-Upgrades und eigene Bereinigung sind qualifiziert. Inputs und Genuine-Blobs sind hashgebunden; tatsächlicher Exit, vollständige Kanäle, exakt gebundenes Journal und frischer Cleanup-Audit wurden zusammen geprüft. Keine Konfigurations-, Rechte-, Trust- oder Infrastrukturänderungen. Der Zähler32 ist nur der Visibility-Teilbereich. CI am geprüften PR-Head 76888216 bestanden: alle sieben Checks SUCCESS einschließlich SQL Server 2019/2022/2025 Linux. Tatsächliche Minimalrechte mit eigenem Principal und weitere physische Ziele bleiben NOT_EXECUTED. Teilweise validiert und unveröffentlicht.

## W2-Map-/FK-Vertrag

[Verbindliche historische V3-Details](../../../Documentation/Architecture/TABLE_CLONE_WAVE2_CONTRACT.md): Position7 TableMap,8 ExternalReferenceRule, damals9..12 Standardtail. In4.0 steht IncludeTriggers an9 und der Tail an10..13. Genau fünf Mapspalten, Snapshot, REJECT/KEEP, globale Phasen, begrenzte FK-States und strikte FK-EP-Ablehnung bleiben gleich. W1-Ordnung TABLE8 gilt nur im Einzelmodus; Mapmodus stellt alle TABLEs vor Constraints. Begrenzte V3-Native- und historische Fixture-Teilnachweise stehen getrennt in der Testdokumentation; sie qualifizieren4.0 nicht.

## Trigger-Scriptklon 4.0

Der [Triggervertrag](../../../Documentation/Architecture/TABLE_CLONE_TRIGGER_CONTRACT.md)
begrenzt den Windows-Opt-in auf gewöhnliche T-SQL-DML-Trigger und den exakt
vorhandenen Parser2.0. Kein automatisches Installieren oder Ausführen.
Default0 bleibt auf Windows/Linux parserfrei. Die Ausgabe erhält Ereignisse,
AFTER/INSTEAD OF, Quell-SET-Werte, FIRST/LAST und disabled-Zustand.
Namen sind TR_ plus vollständiger SHA256 über genau drei längengerahmte
UTF16LE-Identifier; kein zusätzlicher Domainmarker. Eindeutig gebundene
gemappte Tabellenverweise werden anhand tatsächlicher AST-/Tokenspannen
umgeschrieben. Kommentare/Literale bleiben erhalten; dynamische,
verschlüsselte, CLR-, EXECUTE-AS-, externe oder unklare Formen blockieren
vor Veröffentlichung. Keine automatische Kopie von Funktionen/Prozeduren.
Der begrenzte lokale Windows2025/exakt-CU8-CL170-Triggernachweis bestand
am2026-10-04; Scope und verbleibende Grenzen stehen im
[Triggervertrag](../../../Documentation/Architecture/TABLE_CLONE_TRIGGER_CONTRACT.md).
Aktuelle Head-CI wird separat im PR nachgewiesen.

Triggeroption NULL meldet53900/10. Plattform-/Parsergates verwenden53907/2..6,
Unsupported-/Bindungsformen53903/15..22, Namenskollisionen53904/2 und
Parser-/Spannenfehler53905/3..6. Der Triggervertrag ordnet die States genau zu.

Beispiel für eine vorhandene synthetische Tabelle mit gewöhnlichem DML-Trigger
und separat installiertem Parser2.0 auf Windows:

```sql
EXEC toolbelt_metadata.USP_ScriptTableClone
    @SourceSchema=N'dbo', @SourceTable=N'SyntheticSource',
    @TargetSchema=N'dbo', @TargetTable=N'SyntheticClone',
    @IncludeTriggers=1;
```
