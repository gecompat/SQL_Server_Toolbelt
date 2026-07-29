# ResultTable-Modul – implementierungsreife Spezifikation

## Status und Geltungsbereich

| Feld | Wert |
|---|---|
| Arbeitspaket | `AP-2026-002` |
| Kandidat | `TC-2026-003` |
| Modul-ID | `toolbelt.core.result-table` |
| Modulname | Result Table Infrastructure |
| Zielschema | `toolbelt_core` |
| Zielversion | `1.0.0` |
| Spezifikationsstatus | `validated` |
| Implementierungsstatus | `implemented` |
| Runtime-Validierung | `not executed` |
| Implementierung | `Modules/toolbelt.core.result-table/` |

Dieses Dokument ist die kanonische implementierungsreife Spezifikation für das erste `toolbelt_core`-Modul. Es präzisiert den allgemeinen USP-Vertrag, ersetzt ihn jedoch nicht.

## 1. Zweck

Das Modul stellt eine gemeinsame Infrastruktur bereit, mit der eine aufrufende Procedure ihr bekanntes tabellarisches Resultset in eine bereits vom Aufrufer erzeugte lokale Temp-Tabelle schreiben kann. Die Procedure wird für Toolbelt-USPs bereitgestellt, beschränkt technisch aber nicht die Identität des Aufrufers.

Die Infrastruktur bereitet ausschließlich die Zieltabelle vor. Die fachliche USP:

1. erzeugt ihr Resultset aus genau einer kanonischen Fachlogik;
2. gibt es bei `@ResultTable IS NULL` mit `SELECT` aus;
3. lässt bei gesetztem `@ResultTable` die Zieltabelle vorbereiten;
4. schreibt anschließend dieselben Daten mit expliziter Spaltenliste in diese Tabelle.

Damit bleibt verschachteltes `INSERT ... EXEC` außerhalb der Architektur.

## 2. Non-Goals der ersten Version

Version `1.0.0` unterstützt ausdrücklich nicht:

- permanente Zieltabellen;
- globale Temp-Tabellen;
- Tabellenvariablen;
- mehr als eine Zieltable oder mehr als ein Referenzschema je Aufruf;
- das Kopieren von Indizes, Constraints, Defaults, Triggern oder anderen physischen Tabelleneigenschaften;
- frei vom Benutzer geliefertes und ungeprüft ausgeführtes `CREATE TABLE`-DDL;
- Linked-Server- oder vierteilige Schemaquellen;
- Views oder Synonyme als Schemaquelle;
- eine eigene persistente Modulregistrierungstabelle;
- CLR oder eine externe Runtime;
- nicht ausdrücklich in diesem Vertrag freigegebene neue oder versionsspezifische SQL-Datentypen.

Eine spätere sichere Auswertung frei gelieferten DDLs kann mit Microsoft ScriptDOM oder einem gleichwertigen vollständigen Parser untersucht werden. Die zuvor erwogene `@CreateStmt`-Capability wird nicht grundsätzlich verworfen, gehört aber nicht zu Version `1.0.0`.

## 3. Objektinventar

Die erste Version benötigt genau ein persistentes SQL-Objekt:

| Sichtbarkeit | Objekt | Typ | Zweck |
|---|---|---|---|
| öffentliche Framework-API | `toolbelt_core.USP_PrepareResultTable` | Stored Procedure | Prüft und bereitet eine lokale Temp-Tabelle entsprechend einer Referenztabelle vor. |

Es werden in dieser Version keine persistente Tabelle, kein Synonym, keine Assembly, kein Trigger, keine Sequence und kein Type benötigt. Dadurch wird keine noch offene Namenskonvention aus `DEC-2026-003` vorweggenommen.

Interne Arbeitsdaten werden in Table Variables oder eindeutig benannten lokalen Temp-Objekten gehalten. Es entsteht kein dauerhaftes Datenobjekt.

## 4. Öffentliche Signatur

```sql
CREATE OR ALTER PROCEDURE toolbelt_core.USP_PrepareResultTable
(
      @ResultTableToAlter sysname       = NULL
    , @LikeTable          nvarchar(776) = NULL
    , @KeepData           bit           = 0
    , @Debug              tinyint       = 0
    , @Hilfe              bit           = 0
)
```

Die Reihenfolge ist Teil des öffentlichen Vertrags.

### 4.1 `@ResultTableToAlter`

- bezeichnet eine bereits vorhandene lokale Temp-Tabelle;
- beginnt mit genau einem `#`;
- darf nicht mit `##` beginnen;
- darf keinen Datenbank-, Schema- oder Serverteil enthalten;
- darf nicht den reservierten internen Präfix `#tbx_` verwenden;
- darf wegen des von SQL Server angehängten internen Suffixes maximal 116 Zeichen lang sein;
- ist bei `@Hilfe = 0` fachlich verpflichtend.

### 4.2 `@LikeTable`

Definiert die gewünschte ResultTable-Struktur anhand einer bereits vorhandenen Referenztabelle.

Zulässige Formen:

```text
#LocalTemplate
[Schema].[Table]
[Database].[Schema].[Table]
```

Regeln:

- lokale Temp-Tabellen sind zulässig;
- Ziel- und Referenztabelle dürfen nicht auf dasselbe lokale Temp-Objekt aufgelöst werden;
- reguläre Tabellen müssen mindestens zweiteilig angegeben werden;
- bei zentraler Installation ist für eine Tabelle in der konsumierenden Datenbank ein dreiteiliger Name erforderlich;
- vierteilige Namen und Linked Server sind unzulässig;
- Views, Synonyme und Tabellenvariablen sind unzulässig;
- die aufrufende Identität benötigt ausreichende Metadatensichtbarkeit auf die Referenztabelle;
- `@LikeTable` ist bei `@Hilfe = 0` fachlich verpflichtend.

### 4.3 `@KeepData`

Verwendet die verbindliche Matrix aus `Documentation/Standards/USP_CONTRACT.md`:

| Zielzustand | `@KeepData = 0` | `@KeepData = 1` |
|---|---|---|
| leer, Schema passt | einfügebereit lassen | einfügebereit lassen |
| leer, Schema passt nicht | Schema anpassen | Schema anpassen |
| Daten vorhanden, Schema passt | Daten entfernen | Daten erhalten |
| Daten vorhanden, Schema passt nicht | Daten entfernen und Schema anpassen | vor jeder Mutation abbrechen |

Die Procedure selbst fügt keine fachlichen Resultzeilen ein.

### 4.4 `@Debug`

- `0`: keine Debug-Ausgabe;
- `1`: Hauptschritte;
- `2`: Entscheidungen, Objekt-IDs, Zeilenzahlen und erkannte Schemaabweichung;
- `3`: normalisierte Metadaten und generiertes DDL;
- `4` bis `254`: Verhalten wie Stufe `3`;
- `255`: maximaler interner Trace, kein stabiler öffentlicher Detailvertrag.

Debug verwendet ausschließlich Messages. Echte Secrets werden nicht aktiv ausgegeben.

### 4.5 `@Hilfe`

Bei `@Hilfe = 1` wird ausschließlich das standardisierte Help-Resultset ausgegeben. Alle anderen Parameter werden ignoriert; die Procedure führt keine Metadatenprüfung und keine Mutation aus.

## 5. Rückgabe- und Fehlervertrag

`USP_PrepareResultTable` besitzt kein fachliches Resultset.

- Erfolg: `RETURN 0`;
- Validierungs- oder Vertragsfehler: `THROW` mit einem Modulfehler aus dem Bereich `51020` bis `51029`;
- SQL-Server-Fehler während DDL oder Transaktion: ursprünglichen Fehler mit `THROW;` weitergeben;
- keine zusätzlichen Status-`SELECT`s.

Das Help-Resultset enthält einen deklarativen `RESULT_COLUMN`-Eintrag mit dem Hinweis, dass kein fachliches Resultset existiert und Erfolg über Return Code beziehungsweise Fehler über `THROW` signalisiert werden.

Vorgesehene Modulfehler:

| Fehlernummer | Bedeutung |
|---:|---|
| `51020` | `@ResultTableToAlter` fehlt oder ist kein zulässiger lokaler Temp-Tabellenname. |
| `51021` | Zieltable ist im aktuellen Session-Scope nicht sichtbar. |
| `51022` | `@LikeTable` fehlt, ist mehrdeutig, verwendet eine nicht unterstützte Namensform oder bezeichnet dasselbe lokale Temp-Objekt wie das Ziel. |
| `51023` | Referenztabelle ist nicht sichtbar oder kein unterstützter Tabellentyp. |
| `51024` | Referenzschema enthält einen nicht unterstützten oder nicht einfügbaren Spaltentyp. |
| `51025` | `@KeepData = 1` verhindert den erforderlichen Schemaumbau. |
| `51026` | Ein Index, Constraint oder anderes abhängiges Objekt verhindert den Schemaumbau. |
| `51027` | Eine Collation oder ein Datentyp kann nicht sicher in DDL überführt werden. |
| `51028` | Der aktuelle Transaktionszustand erlaubt kein kontrolliertes Rollback. |
| `51029` | Intern erzeugtes DDL überschreitet einen unterstützten Grenzwert oder ist unvollständig. |

## 6. Schemaquelle und zurückgestellter `@CreateStmt`-Pfad

Die ursprüngliche Designoption sah zusätzlich `@CreateStmt nvarchar(max)` vor. Version `1.0.0` stellt diesen öffentlichen Parameter zurück, ohne die Capability für eine spätere Version auszuschließen.

Stattdessen erzeugt die aufrufende Toolbelt-USP eine lokale, routinenspezifisch benannte Helper-Temp-Tabelle mit exakt dem gewünschten Resultsetschema und übergibt deren Namen über `@LikeTable`.

Beispielmuster:

```sql
DECLARE @OwnsResultShape bit = 0;

IF OBJECT_ID(N'tempdb..#tbx_String_Split_ResultShape', N'U') IS NULL
BEGIN
    CREATE TABLE #tbx_String_Split_ResultShape
    (
          ItemOrdinal bigint        NOT NULL
        , ItemValue   varchar(8000) NULL
    );

    SET @OwnsResultShape = 1;
END;

-- Eine bereits vorhandene Helper-Tabelle wird vor der Wiederverwendung gegen
-- den erwarteten unveränderlichen Shape-Vertrag geprüft.
{{ValidateExistingResultShape}}

EXEC toolbelt_core.USP_PrepareResultTable
      @ResultTableToAlter = @ResultTable
    , @LikeTable          = N'#tbx_String_Split_ResultShape'
    , @KeepData           = @KeepData
    , @Debug              = @Debug;

IF @OwnsResultShape = 1
    DROP TABLE #tbx_String_Split_ResultShape;
```

Dieses Muster hat folgende Vorteile:

- SQL Server selbst löst Datentyp, Länge, Precision, Scale, Nullability und Collation auf;
- kein unvollständiger Regex- oder String-Parser muss frei geliefertes DDL bewerten;
- kein ungeprüftes DDL wird innerhalb der Core-Procedure ausgeführt;
- rekursive Aufrufe derselben USP verwenden dieselbe unveränderliche Schema-Helper-Tabelle;
- nur der tatsächliche Erzeuger entfernt die Helper-Tabelle.

Helper-Temp-Tabellen sind routinenspezifisch nach `SQL_OBJECT_NAMING.md` zu benennen. Generische Namen wie `#Temp`, `#Result` oder `#Schema` sind unzulässig.

Ein späterer öffentlicher `@CreateStmt`-Pfad benötigt:

- einen vollständigen T-SQL-Parser wie ScriptDOM;
- einen expliziten Trust- und Berechtigungsvertrag;
- eine eigene Testmatrix für zusätzliche Statements, Kommentare, Strings, delimitierte Identifier und Transaktionskontrolle;
- eine separate Architekturentscheidung und Versionierung als Vertragsänderung.

## 7. Objektauflösung

### 7.1 Zieltable

1. Parameterform validieren.
2. Den logischen Namen genau einmal über `OBJECT_ID(N'tempdb..' + QUOTENAME(@ResultTableToAlter), N'U')` auflösen.
3. Bei `NULL` mit `51021` abbrechen.
4. Alle Folgeabfragen über die ermittelte `object_id` und `tempdb.sys.*` ausführen.
5. Den physischen, von SQL Server erzeugten Suffix nicht rekonstruieren.

### 7.2 Lokale Referenztable

Eine lokale `@LikeTable` wird auf dieselbe Weise einmalig in `tempdb` aufgelöst. Ziel- und Referenz-`object_id` dürfen identisch sein; in diesem Fall ist nur die Schema- und gegebenenfalls Datenbehandlung relevant.

### 7.3 Reguläre Referenztable

- zwei- und dreiteilige Namen werden kontrolliert in ihre Bestandteile zerlegt;
- jeder Bestandteil wird als `sysname` validiert und mit `QUOTENAME` neu aufgebaut;
- ein Serverteil ist unzulässig;
- Catalog Views werden über präzise `database_id`, `schema_id`, `object_id` und `column_id` abgefragt;
- geeignete read-only Catalog-Abfragen dürfen `WITH (NOLOCK)` verwenden;
- nach der ID-Ermittlung werden Metadatenfunktionen nicht wiederholt in Prädikaten aufgerufen.

### 7.4 Namensvergleich

Technische Vergleiche von Datenbank-, Schema-, Objekt- und Spaltennamen verwenden eine explizite invariant-binäre Vergleichssemantik. Sie dürfen nicht zufällig von der Collation der Toolbelt-Datenbank, der Referenzdatenbank oder `tempdb` abhängen.

Die konkrete BIN2-Collation wird bei der Implementierung aus einer auf allen Zielversionen verfügbaren Instanzcollation gewählt und in den Contract Tests verifiziert.

## 8. Normalisierte Spaltenmetadaten

Die Implementierung normalisiert Referenz- und Zielspalten intern mindestens auf folgende Felder:

| Feld | Zweck |
|---|---|
| `ColumnOrdinal` | physische Reihenfolge der Spalte |
| `ColumnName` | Zielname |
| `SystemTypeId` | zugrunde liegender SQL-Systemtyp |
| `TypeName` | kanonischer Typname |
| `MaxLength` | Byte-Länge beziehungsweise `-1` für `max` |
| `PrecisionValue` | numerische Precision |
| `ScaleValue` | Scale beziehungsweise Fractional Seconds |
| `IsNullable` | Nullability |
| `CollationName` | Spaltencollation für Zeichentypen |
| `IsIdentity` | physische Identity-Eigenschaft |
| `IsComputed` | computed column |
| `GeneratedAlwaysType` | systemgenerierte Spalte |
| `IsHidden` | versteckte Spalte |
| `IsColumnSet` | XML-Column-Set-Eigenschaft |
| `IsSparse` | Sparse-Eigenschaft zur bewussten Normalisierung |
| `EncryptionType` | Always-Encrypted-Eigenschaft |
| `IsAssemblyType` | CLR-basierter Typ |
| `IsUserDefined` | Alias- oder User-defined Type |
| `NormalizedTypeDeclaration` | sicher generierbares DDL-Fragment |
| `IsInsertableShapeColumn` | Eignung als ResultTable-Spalte |

### 8.1 Unterstützte Spalten

Version `1.0.0` verwendet eine ausdrückliche Whitelist gewöhnlicher einfügbarer Spalten auf Basis etablierter SQL-Systemtypen:

- Ganzzahl- und Bit-Typen;
- `decimal`/`numeric`, Money- und Gleitkommatypen;
- Datum-/Zeittypen einschließlich Scale;
- `char`, `varchar`, `nchar`, `nvarchar` einschließlich `max`;
- `binary`, `varbinary` einschließlich `max`;
- `uniqueidentifier`;
- `sql_variant`;
- untypisiertes `xml`;
- `hierarchyid`, `geometry` und `geography`, wenn sie auf der Zielversion vorhanden sind.

Zusätzliche Regeln:

- `varchar` und `nvarchar` werden nicht ineinander konvertiert;
- Länge, Precision und Scale werden erhalten;
- Zeichencollations werden ausdrücklich erhalten;
- Alias Types werden auf den zugrunde liegenden Systemtyp normalisiert;
- typisiertes XML wird als untypisiertes `xml` normalisiert;
- `rowversion` beziehungsweise `timestamp` ist als Schemaquelle unzulässig, weil die Zielspalte explizit befüllt werden muss;
- Identity-, computed-, hidden-, generated-always-, column-set- und verschlüsselte Spalten sind als Referenzschema unzulässig;
- benutzerdefinierte CLR Types sind in Version `1.0.0` nicht unterstützt;
- Legacy-LOB-Typen `text`, `ntext` und `image` sind nicht unterstützt;
- neue versionsspezifische Typen wie ein nativer JSON- oder Vector-Typ sind erst nach einer eigenen Contract-Erweiterung unterstützt.

Nicht freigegebene oder unbekannte Formen führen vor jeder Mutation zu `51024`. Eine spätere Typ-Erweiterung ist eine versionierte öffentliche Vertragsänderung.

## 9. Schema-Gleichheit

Ein Zieltable-Schema gilt nur dann als passend, wenn folgende Eigenschaften übereinstimmen:

- Spaltenanzahl;
- Spaltenreihenfolge;
- Spaltenname unter der invariant-binären Namenssemantik;
- normalisierter Systemtyp;
- Länge;
- Precision;
- Scale;
- Nullability;
- Collation bei Zeichentypen;
- Einfügebarkeit der Zielspalte.

Nicht Bestandteil des Resultsetvertrags sind:

- Indizes;
- Primary- oder Unique Constraints;
- Check Constraints;
- Default Constraints;
- Trigger;
- Statistiken;
- physische Sortierreihenfolge.

Sind solche Objekte bei passendem Spaltenschema vorhanden, werden sie nicht entfernt. Verhindern sie später den Insert, wird der tatsächliche Fehler durch die fachliche USP weitergegeben.

## 10. Read-only Preflight

Vor der ersten Mutation werden vollständig geprüft:

1. Parameter und Help-Modus;
2. Sichtbarkeit von Ziel- und Referenztabelle;
3. unterstützte Objektarten;
4. normalisierte Referenzspalten;
5. aktuelles Zielschema;
6. Vorhandensein von Zielzeilen;
7. `@KeepData`-Konflikte;
8. bei notwendigem Schemaumbau alle bekannten abhängigen Objekte;
9. vollständige Generierbarkeit des DDLs;
10. aktueller Transaktionszustand.

Wenn ein Schemaumbau erforderlich ist, gelten als Blocker insbesondere:

- alle Indizes mit Abhängigkeit zu einer zu entfernenden oder zu ändernden Spalte;
- Primary-, Unique-, Check- oder Foreign-Key-Constraints;
- Default Constraints;
- computed columns;
- DML-Trigger;
- user-created statistics;
- sonstige Catalog-Abhängigkeiten auf zu entfernende Spalten.

Kein Blocker wird automatisch entfernt. Ein erkannter Blocker führt mit `51026` zum Abbruch, bevor Daten gelöscht oder Spalten geändert werden.

## 11. Mutationsalgorithmus

### 11.1 Schema passt

- `@KeepData = 1`: keine Mutation;
- `@KeepData = 0`: vorhandene Zeilen mit `TRUNCATE TABLE` entfernen;
- keine DDL-Operation ausführen;
- Indizes und Constraints unverändert lassen.

`TRUNCATE TABLE` ist das einzige zulässige Löschverfahren. Schlägt es fehl, liegt für dieses Modul ein nicht unterstützter Zustand vor. Es erfolgt kein `DELETE`-Fallback; die eigene Mutation wird zurückgerollt und der ursprüngliche Engine-Fehler mit `THROW;` weitergegeben. Das Verfahren wird bei `@Debug >= 2` als Message ausgewiesen.

### 11.2 Schema passt nicht

1. Bei vorhandenen Daten und `@KeepData = 1` mit `51025` abbrechen.
2. Abhängige Objekte vollständig prüfen.
3. Transaktion beziehungsweise Savepoint anlegen.
4. Vorhandene Daten bei Bedarf entfernen.
5. Eindeutig benannte temporäre Anchor-Spalte hinzufügen.
6. Alte Spalten entfernen.
7. Zielspalten in der definierten Reihenfolge hinzufügen.
8. Anchor-Spalte entfernen.
9. Eigene Transaktion committen.

Die Zieltable wird nicht gedroppt und neu erstellt. Dadurch bleibt das vom Aufrufer erzeugte Temp-Objekt im ursprünglichen Scope erhalten.

Bei exakt 1024 Quell- oder Zielspalten teilt die Implementierung den Umbau:
Eine alte Spalte wird gegebenenfalls vor der Anchor-Spalte entfernt und die
letzte neue Spalte erst nach deren Entfernung angelegt. Dadurch überschreitet
der in-place-Umbau zu keinem Zeitpunkt das SQL-Server-Spaltenlimit.

Eine zweite vollständige Metadatenabfrage unmittelbar vor der DDL-Ausführung ist nicht erforderlich. Der Aufrufvertrag setzt voraus, dass das lokale Zielobjekt während der synchronen Ausführung nicht parallel verändert wird. Der Erfolg der DDL ist autoritativ; Contract Tests prüfen anschließend den Endzustand.

## 12. Transaktionsvertrag

- Bei `@@TRANCOUNT = 0` beginnt die Procedure unmittelbar vor der ersten Mutation eine eigene Transaktion.
- Bei bestehender, committable Transaktion wird ein Invocation-spezifisch benannter Savepoint innerhalb des SQL-Server-Namenslimits verwendet.
- Bei Erfolg wird nur eine selbst begonnene Transaktion committed.
- Bei Fehler wird eine selbst begonnene Transaktion vollständig zurückgerollt.
- Bei bestehender Transaktion und `XACT_STATE() = 1` wird zum eigenen Savepoint zurückgerollt.
- Bei `XACT_STATE() = -1` ist ein Savepoint-Rollback nicht möglich; der Originalfehler wird weitergegeben und der uncommittable Zustand bleibt für den Aufrufer sichtbar.
- Die Procedure committed oder rollt niemals eine vom Aufrufer gestartete vollständige Transaktion zurück.
- Die Procedure verändert keine dauerhaften Session-SET-Optionen des Aufrufers. Erforderliche SET-Annahmen werden dokumentiert und getestet.
- Error Handling erfolgt an diesen Grenzen und nicht nach jedem Einzelstatement.

## 13. Collation- und Datentypvertrag

- Metadatennamen werden nicht von der Collation der Toolbelt-Datenbank abhängig gemacht.
- Zeichenbasierte Zielspalten erhalten die in der Referenztable dokumentierte Collation.
- Ein dynamisch verwendeter Collation-Name muss aus Catalog-Metadaten stammen und gegen die auf der Instanz verfügbaren Collations validiert werden.
- `varchar` bleibt `varchar`; `nvarchar` bleibt `nvarchar`.
- `max`-Typen, Byte-Längen, Precision und Scale werden explizit behandelt.
- Der Toolbelt korrigiert keine vom Benutzer außerhalb des Moduls geschriebenen Vergleiche inkompatibler Collations.

## 14. Rekursion, Verschachtelung und Parallelität

- Verschachtelte Toolbelt-USPs verwenden `@ResultTable` statt `INSERT ... EXEC`.
- Routinenspezifische Schema-Helper-Temp-Tabellen werden bei Rekursion nur dann wiederverwendet, wenn ihr tatsächliches Schema dem unveränderlichen Shape-Vertrag entspricht.
- Nur der tatsächliche Erzeuger droppt eine wiederverwendete Helper-Tabelle.
- Modulinterne dynamisch erzeugte Arbeitsnamen verwenden den Präfix `#tbx_` und einen Invocation-spezifischen Suffix.
- Gleichzeitige DDL-Manipulation derselben Zieltable durch MARS oder parallele Batches derselben Session ist nicht unterstützt.
- Unterschiedliche Sessions sind durch die SQL-Server-Suffixe lokaler Temp-Tabellen getrennt.

## 15. Deployment und Berechtigungen

### 15.1 Capability-Matrix

| Capability | Status für Version 1.0.0 |
|---|---|
| `local` | unterstützt |
| `central` | unterstützt |
| `central_with_synonyms` | nicht erforderlich |
| `local_required` | nein |
| `central_preferred` | ja für gemeinsam genutzte Toolbelt-Installationen |

Ein zentral installiertes `USP_PrepareResultTable` kann die lokalen Temp-Tabellen derselben Session verwenden. Für Version `1.0.0` werden keine Synonyme benötigt; dadurch bleibt die offene Synonym-Namenskonvention unberührt.

### 15.2 Berechtigungen

- kein `EXECUTE AS OWNER` als Default;
- kein `TRUSTWORTHY ON`;
- keine CLR-Autorisierung;
- Aufrufer benötigt `EXECUTE` auf der Procedure;
- Aufrufer benötigt Metadatensichtbarkeit auf eine reguläre `@LikeTable`;
- lokale Helper-Temp-Tabellen benötigen keine zusätzlichen dauerhaften Rechte;
- die Procedure gewährt keine Rechte auf fremde Objekte.

## 16. Lifecycle

### Deploy

Ein einziges parametergesteuertes `Deploy.sql` übernimmt Erstinstallation, Upgrade und Wiederholungsinstallation:

- `DeploymentMode=local|central` bestimmt Installationsort und Metadatum, nicht die Fachimplementierung;
- SQL Server 2019, 2022 oder 2025 sowie Berechtigungen werden vor der ersten Mutation geprüft;
- ein vorhandenes unmarkiertes Schema `toolbelt_core` darf wiederverwendet werden; Eigentümer und Berechtigungen werden nicht ungefragt verändert;
- das Release enthält ein versioniertes Objektmanifest;
- ein Zielobjekt, das im installierten Vorgängerrelease enthalten war, wird unabhängig von lokalen Änderungen aktualisiert;
- bei erneuter Installation derselben Version werden alle Framework-Objekte des Releases erneut deployed;
- ein im Ziel neu hinzukommender Objektname führt bei einer nicht aus dem Vorgängerrelease stammenden Kollision vor jeder Mutation zum Abbruch;
- nur Objekte, die im bekannten installierten Release enthalten waren und im Zielrelease fehlen, werden entfernt;
- frameworkfremde Objekte werden weder verändert noch gelöscht;
- Source-Hashes dürfen diagnostisch gespeichert werden, sind aber kein Überschreib- oder Upgrade-Gate;
- interne Framework-Tabellen würden über explizite versionierte Migrationen und, soweit fachlich zulässig, `TRUNCATE`/`DELETE`/`INSERT` gepflegt; Version `1.0.0` besitzt keine persistente Tabelle;
- eine Application Lock und eine zweite Zustandsprüfung schützen die Mutation vor parallelen Deployments;
- die Datenbanktransaktion beginnt unmittelbar vor der ersten Änderung und endet nach Objekt-, Manifest- und Versionsaktualisierung.

Extended Properties an Framework-Objekten dokumentieren mindestens Modul, Release, Contract und Deployment-Modus. Der installierte Modulstand wird zusätzlich datenbankweit markiert, damit auch weggefallene Objekte anhand des bekannten Vorgängerrelease-Manifests sicher bestimmt werden können.

Wird `toolbelt_core` durch das Deployment neu angelegt, erhält es `Toolbelt.Managed = 1` und `Toolbelt.SchemaCategory = core`. Ein bereits vorhandenes Schema wird nicht adoptiert oder nachträglich als Toolbelt-Eigentum markiert.

### Uninstall

- statische same-database Dependencies soweit möglich ermitteln;
- keine fremden Objekte entfernen;
- ausschließlich Objekte des installierten Release-Manifests und ihre Extended Properties entfernen;
- `toolbelt_core` nur entfernen, wenn es durch `Toolbelt.Managed = 1` markiert und vollständig leer ist;
- bei zentraler Installation kann die Abwesenheit beliebiger externer direkter Aufrufer nicht automatisch bewiesen werden. Der Uninstall-Pfad benötigt deshalb eine ausdrückliche Betreiberbestätigung, dass keine externen Konsumenten mehr vorhanden sind.

## 17. Implementierungswellen nach dieser Spezifikation

### Welle A – Modulgerüst und öffentliche Procedure

- Modulverzeichnis aus den Templates erzeugen;
- Manifest mit Status `planned` beziehungsweise nach Codeerstellung `implemented`;
- Procedure, Help, Objekt-Dokumentation und Lifecycle-Skripte;
- keine zweite Fachimplementierung.

### Welle B – Contract- und Runtime-Tests

- vollständige Matrix aus `Tests/RESULT_TABLE_CONTRACT_TEST_MATRIX.md`;
- GitHub-hosted Linux: vollständiger vorhandener Contract auf SQL Server 2019 und reduzierte Compatibility-Smokes auf SQL Server 2022 und 2025;
- keine Remote-Runner für diese erste Welle;
- Windows bleibt bis zu einer separaten tatsächlichen Ausführung `not executed`;
- lokale und zentrale Installation;
- unterschiedliche Server-, Toolbelt-, Zieldatenbank- und TempDB-Collations.

### Welle C – Validierung und Release

- alle Pflichtprüfungen tatsächlich ausführen;
- Einschränkungen und empirische Performance-Ergebnisse dokumentieren;
- Modul erst danach auf `validated` setzen.

## 18. Primärquellen

- `CREATE TABLE` und Temp-Table-Scope: https://learn.microsoft.com/en-us/sql/t-sql/statements/create-table-transact-sql?view=sql-server-ver17
- `OBJECT_ID`: https://learn.microsoft.com/en-us/sql/t-sql/functions/object-id-transact-sql?view=sql-server-ver17
- `sys.columns`: https://learn.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-columns-transact-sql?view=sql-server-ver17
- `sys.types`: https://learn.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-types-transact-sql?view=sql-server-ver17
- `PARSENAME`: https://learn.microsoft.com/en-us/sql/t-sql/functions/parsename-transact-sql?view=sql-server-ver17
- `QUOTENAME`: https://learn.microsoft.com/en-us/sql/t-sql/functions/quotename-transact-sql?view=sql-server-ver17
- `sys.fn_helpcollations`: https://learn.microsoft.com/en-us/sql/relational-databases/system-functions/sys-fn-helpcollations-transact-sql?view=sql-server-ver17
- `SAVE TRANSACTION`: https://learn.microsoft.com/en-us/sql/t-sql/language-elements/save-transaction-transact-sql?view=sql-server-ver17
- `XACT_STATE`: https://learn.microsoft.com/en-us/sql/t-sql/functions/xact-state-transact-sql?view=sql-server-ver17
- `TRY...CATCH`: https://learn.microsoft.com/en-us/sql/t-sql/language-elements/try-catch-transact-sql?view=sql-server-ver17
