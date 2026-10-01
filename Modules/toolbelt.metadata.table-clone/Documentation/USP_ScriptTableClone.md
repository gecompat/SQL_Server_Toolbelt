# USP_ScriptTableClone

Einzeln freigegeben2026-10-01, TC-2026-044; Script-only same-database-V1.
Signatur: `SourceSchema nvarchar(max)=NULL`, `SourceTable nvarchar(max)=NULL`,
`TargetSchema nvarchar(max)=NULL`, `TargetTable nvarchar(max)=NULL`,
`IncludeIdentity bit=0`, `ResultTable sysname=NULL`, `KeepData bit=0`,
`Debug tinyint=0`, `Hilfe bit=0`. Alle Identifier fachlich erforderlich;
einzelne Namen, keine Multipartinterpretation, nicht trimmen,1–128 UTF16Units,
NUL verboten. nvarchar(max) vermeidet stille Parametertrunkierung.
IncludeIdentity NULL ungültig; Standard-NULLs entsprechen0. Hilfe1 umgeht alles.

Ergebnis: Ordinal int, ObjectKind varchar(32), TargetName nvarchar(776),
ScriptText nvarchar(max), alle NOT NULL. Text BIN2, ObjectKind TABLE/DEFAULT/
CHECK/PRIMARY_KEY/UNIQUE_CONSTRAINT/INDEX. Ordinal1-basiert lückenlos;
TABLE zuerst, Defaults, Checks, clustered Schlüssel/Index, übrige Indizes.
ResultTable-Tabelle hat keine garantierte physische Reihenfolge.

Unterstützt: reguliere diskbasierte Heap/Clustered-Tabellen; eingebaute Typen
tinyint/smallint/int/bigint/bit/decimal/numeric/money/smallmoney/float/real,
date/time/datetime/smalldatetime/datetime2/datetimeoffset,
char/nchar/varchar/nvarchar/binary/varbinary inklusive max,
uniqueidentifier/xml(untyped)/timestamp/rowversion/sql_variant.
Längen/Precision/Scale/Nullability/Collation erhalten. Optional Identity
Seed/Increment, niemals aktuelle last_value oder Daten.
Defaults und vertrauenswürdige aktive Checks wörtlich; PK/UQ und gewöhnliche
unpartitionierte ungefilterte Rowstoreindizes mit Keyrichtung/INCLUDE/Uniqueness,
Fillfactor/Padding/IgnoreDupKey/Rowlocks/Pagelocks/StatsNoRecompute und Filegroup.
Catalog-Fillfactor0 wird als semantisch äquivalentes explizites100 gerendert;
es ist kein gültiger expliziter DDL-Prozentwert. Catalog-Collationnamen werden
als Engine-validierte COLLATE-Tokens ausgegeben, nicht als geklammerte Identifier.
LOB-Filegroup explizit. Keine Statistikdaten/Buildoptionen/Source-Dateigrößen.

Unsupported führt zu53903 ohne Teilausgabe: temporär/external/system/memory/
FileTable/temporal/ledger/graph/replication/CDC; computed/sparse/columnset/rowguid/
FILESTREAM/generated/hidden/masked/encrypted/typedXML/rules; CLR/alias/legacy
text/ntext/image-Typen/gebundene Defaults/ANSI_PADDING OFF;
FK einschließlich eingehender, Trigger, Extended Properties;
filtered/disabled/hypothetical/OPTIMIZE_FOR_SEQUENTIAL_KEY=ON/partitionierte/compressed/fulltext/XML/spatial/
columnstore Indizes, untrusted/disabled/not-for-replication Checks/Identity.
Kein Rechte-/Ownership-/EP-/Trigger-/FK-Klon. Berechtigungen bleiben bewusst
außerhalb dieser strukturellen Vorschau; Metadatensichtbarkeit ersetzt keine
spätere DDL-/Funktions-/Dateigruppenberechtigung des ausführenden Callers.

Deterministische DF/CK/PK/UQ/IX-Namen: Typpräfix + vollständiger SHA256hex64
über length-framed UTF16 Zielschema/Zieltabelle und Quellcolumnordinal bzw.
originalen Constraint-/Indexnamen. Kein zufälliger Suffix/Trunkieren/Casefold.
Constraintnamen werden gegen Zielschema/Plan unter DATABASE_DEFAULT geprüft;
Indexnamen gehören zur noch nicht existierenden Zieltabelle. Identifier stets
QUOTENAME. Hashnamen enthalten keine verwertbaren Datenschutzgarantien.

Fehlerpriorität: Help; reservierter Caller-Tempnamespace vor Core-Kompilierung;
Argumente/NUL; Quellsicht; Zielsicht/Existenz; Unsupported in dokumentierter
Source-Prüfreihenfolge; Definitionssicht; Metadatengrenzen; Namenskollision;
fertige Planbytes; optional Dependency/Outputpreflight/Write.
53900 Argumente,53901 Quelle/Sicht,53902 Ziel/Sicht,53903 Unsupported,
53904 Kollision,53905 Definition,53906 Ressourcen,53907 Dependency,
53908 Namespace (caller-belegte interne Tabelle oder reserviertes ResultTable-Prefix,
auch in Großschreibung; vor Kernkompilierung geprüft). Enginefehler bleiben unverändert.
Keine realen Werte im Fehlertext.
Limits1024Spalten/128Indexmetadatenzeilen/2048Kindobjekte/2MiB Scripttext,
vor LOB-Materialisierung Definitionsbytes prüfen; keine RAM/Wallclockgarantie.

Quelle strukturell stabil halten. Vorschau ist Momentaufnahme; keine spätere
Driftfreiheit, kein automatisches Recovery. Vollständiger Plan vor ResultTable-
Mutation, kanonischer Helper, eigene Transaktion oder Caller-savepoint;
niemals fremde Transaktion committen. Doomed Caller benötigt Callerrollback.
Debug nur Messages. EXECUTE plus datenbankweite VIEW DEFINITION erforderlich:
incoming-FKs in fremden Schemas dürfen durch Metadata Visibility nicht unsichtbar
bleiben. Objekt-/Schemasicht allein reicht nicht; fehlende DB-Sicht ergibt53901
vor Planung und ResultTable-Mutation. Die API erteilt keine Rechte.
kein EXECUTE AS/Rechteausweitung. Zentrale Quellen liegen in InstallationsDB.

Tests: ausschließlich synthetische Metadaten/DDL; risikobasierte2019Linux-
und2025Windows-Nachweise erfolgreich, weitere Kontexte offen; siehe Modul-Testmatrix.

Primärquellen:

- [Microsoft CREATE TABLE](https://learn.microsoft.com/en-us/sql/t-sql/statements/create-table-transact-sql?view=sql-server-ver17)
- [Microsoft CREATE INDEX](https://learn.microsoft.com/en-us/sql/t-sql/statements/create-index-transact-sql?view=sql-server-ver15)
- [Microsoft sys.columns](https://learn.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-columns-transact-sql?view=sql-server-ver17)
