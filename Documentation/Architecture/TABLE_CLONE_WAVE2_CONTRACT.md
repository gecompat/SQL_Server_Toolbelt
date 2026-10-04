# Table Clone W2 / 3.0.0

Stand 2026-10-04, Codex. Die bereits einzeln freigegebene Script-only-Funktion wird um FK- und Multitable-Planung erweitert. Der Benutzer bestätigte am 2026-10-03 nach konkreter Besprechung den Positionsbruch zu V3 sowie fail-closed FK-Property-/Zustandsgrenzen. Keine neue API, kein Execute-Wrapper, keine Rechte-/Owneränderung, kein Provider. Implementierung vorhanden; Sourceprüfung und Native-/CI-Qualifikation der Version3 bleiben offen. Historische W1-Nachweise gelten für Version2, nicht automatisch für V3.

## Öffentlicher Vertrag

Die bestehenden öffentlichen und internen Prozeduren bleiben die einzigen Slots. Parameter1..6 sind die bisherigen vier nvarchar(max)-Identifier und zwei Include-bits. TableMap sysname=NULL steht an Position7, ExternalReferenceRule varchar(16)='REJECT' an8; ResultTable/KeepData/Debug/Hilfe an9..12. Alte positionale Tailaufrufe müssen angepasst werden; benannte W1-Aufrufe bleiben fachlich gleich. Help1 umgeht sämtliche Prüfungen.

TableMapNULL ist W1: vier explizite einzelne Identifier, bisherige FK-Ablehnung, ausschließlich byteexaktes REJECT. Im Mapmodus müssen alle vier Identifierparameter NULL sein. Beide Includes gelten für den ganzen Plan und dürfen nicht NULL sein. Rule ist byteexakt REJECT oder KEEP, ohne Padding/Casefold. KEEP behält ausschließlich nicht gemappte sichtbare Referenzziele; es überspringt keinen FK.

Map ist eine bestehende lokale #Temp-Tabelle mit exakt fünf nichtberechneten NOT-NULL-Spalten ohne Aliastyp: MapOrdinal int und SourceSchema/SourceTable/TargetSchema/TargetTable jeweils nvarchar(max). Nichtleer, höchstens64Zeilen; Ordinals positiv/eindeutig, Lücken erlaubt. Namen1..128 UTF16-Einheiten, kein NUL/Trim. Tempmetadaten anhand einmal aufgelöstem object_id; kontrollierte explizite Spaltenkopie in reservierten eigenen Snapshot. Caller hält die Map während dieser Kopie stabil. Danach kein Inputread oder Inputwrite. Map-/ResultTable-object_id müssen verschieden sein. #tbx_-Namen und caller-belegte interne Namen blockieren vor Kernkompilierung.

Quellen nach tatsächlich aufgelöstem object_id eindeutig, Ziele nach SchemaId und DATABASE_DEFAULT eindeutig; keine Mehrfachklone derselben Quelle. Quelle und Ziel gehören zur Installationsdatenbank, auch bei zentralem dreiteiligem Aufruf. Vollständige DB-VIEW-DEFINITION erforderlich; keine Rechteerteilung. Referenzziel und vollständiger unpartitionierter aktiver ungefilterter eindeutiger Rowstore-Referenzschlüssel müssen sichtbar sein. FK-Spaltenreihenfolge ist constraint_column_id, niemals key_ordinal als Ersatz.

## FK und Properties

Nur ausgehende FKs mit Owner in der Map werden geplant; Owner außerhalb der Map werden nicht geändert. Gemappte Referenzziele werden auf ihr Ziel umgebogen, einschließlich Self-FK und Zyklen. REJECT lehnt nicht gemappte Referenzziele ab, KEEP erhält deren originalen qualifizierten Namen. Aktionen NO ACTION/CASCADE/SET NULL/SET DEFAULT und NOT FOR REPLICATION werden erhalten. Zustände enabled/trusted, enabled/untrusted und disabled/untrusted werden durch WITH CHECK beziehungsweise WITH NOCHECK ADD und bei disabled durch spätere NOCHECK CONSTRAINT erhalten. disabled/trusted wird abgewiesen; kein empirischer Erhalt behauptet.

FK-Properties sind immer Unsupported, auch bei IncludeExtendedProperties1; kein stilles Weglassen. Alle anderen W1-Propertygrenzen bleiben strikt: Include0 lehnt relevante Properties ab, Include1 erhält unterstützte originale sql_variant-Werte und Metadaten, Toolbelt.-Marker werden niemals kopiert. Keine neue Property-Opt-out-Semantik.

## Reihenfolge, Namen, Quoten und Atomik

Vier NOT-NULL-Ergebnisfelder/BIN2 unverändert. Globale positive lückenlose Ordinals: sieben SET-Zeilen einmal, alle TABLEs nach MapOrdinal, je Map W1-Objekte in W1-Reihenfolge, danach globale typisierte EPs, alle FK-CREATEs nach OwnerMapOrdinal/originalem FK-Namen BIN2 mit Bytetie, zuletzt erforderliche FK-Statezeilen in derselben Ordnung. FK/State sind je eine Anweisung; die bestehende EP-DECLARE-plus-EXEC-Ausnahme bleibt allein.

FK-Namen FK_ plus voller SHA256 über length-framed UTF16-Zielschema/Zieltabelle, FK-Kind und originalen FK-Namen. Globale Constraintkollisionen mit Plan und Zielcatalog unter DATABASE_DEFAULT blockieren; kein Zufall/Trunkieren/Adoptieren. Bestehende W1-DF/CK/PK/UQ/IX-Namen bleiben unverändert.

2048 global zählt **distinct sys.objects mit parent_object_id in den eindeutigen Mapquellen plus distinct sys.foreign_key_columns-Tupel mit FK-Owner in diesen Quellen**. FK-Objekte sind bereits im ersten Summanden, kein doppeltes Addieren. Gewöhnliche columns/indexes/index_columns/EP zählen nicht2048. Separate1024Spalten und128Indexmetadaten je Tabelle bleiben. Map64 und insgesamt2097152UTF16-Scriptbytes inklusive SET/EP/FKSTATE. Definitions-/Propertyminimalbytes vor Output-LOB; gesamte Planung vor Veröffentlichung. Keine CPU-/RAM-/Wallclockgarantie.

ResultTable wird erst nach vollständigem Plan und unverändertem kanonischen Helperpreflight einmal geschrieben; eigene TX oder Caller-Savepoint, kein Callercommit. Planung führt niemals Scripttext aus. Synthetische externe Test-DDL ist keine Produktmutation.

## Fehler und Qualifikation

Bestehende Kategorien53900..53908 bleiben. Zusätzliche Argumentstates53900/3 Rule,4 Modus,5 Mapname,6 fehlende/gleiche Map,7 Shape,8 Zeilen/Ordinals/Identifier,9 doppelte Source-/Targetidentität. FK-Unsupported53903/13 externe REJECT-Referenz,14 Zustand; FK-Properties bleiben Unsupported10 (oder vorgelagerte W1-Propertygrenze4). Unvollständige FK-Metadaten53905/2. Quoten53906/1 und Outputbytes53906/2. Enginefehler werden nicht ersetzt.

Neue Fixtures sind Source, kein PASS: W2.Contract für externe synthetische DDL/Flags/Mapping/Reihenfolge und Varianten, W2.Safety für Help/Map/Kollision/FK-EP/ResultTable-Erhalt, W2.Caps für getrennte Grenzen. W1-Regressionsquellen bleiben bytegleich. Genuine2→3, native SQL2019/2022/2025, lokal/zentral, aktuelle CI, tatsächliche Minimalrechte und restliche negative Lifecyclegates sind offen und werden separat qualifiziert. Kein FullProduct-PASS aus historischen Läufen.
