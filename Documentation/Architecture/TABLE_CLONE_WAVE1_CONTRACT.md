# Tabellenklon Welle 1 – Vor-Source-Reviewvertrag

Datum: 2026-10-02. Status: **Einzeln freigegeben; unabhängig vor Source geprüft**.
Geplantes Modul: `toolbelt.metadata.table-clone` **2.0.0**.
Dieser Entwurf implementiert kein SQL-Objekt und behauptet keine W1-Runtime-Evidenz.
Der installierbare Stand bleibt bis zur gekoppelten Umsetzung 1.0.0.

## Freigabe und Grenzen

Die individuelle Benutzerfreigabe vom 2026-10-01 („ja, das passt so“)
umfasst Welle 1 mit berechneten Spalten einschließlich PERSISTED,
gefilterten Rowstore-Indizes und optionalen Extended Properties.
Am 2026-10-02 bestätigte der Benutzer „Tabellenkopf Welle1 Ja“:
`@IncludeExtendedProperties` steht vor dem Standardtail; sieben einzelne
`SESSION_OPTION`-Zeilen stehen vor `TABLE`. Die dabei verschobenen bisherigen
Positionen 6..9 sind eine bestätigte Signaturänderung, keine additive 1.x-API.
Version 2.0.0 ist die technische Versionsfolgerung daraus.

Nach der gesonderten konkreten Besprechung bestätigte der Benutzer am
2026-10-02 mit „beides ja“ sowohl das Computed-only-SELECT-Gate mit 53901/3
als auch den begrenzten DECLARE-plus-EXEC-Batch pro EXTENDED_PROPERTY-Zeile.
Der unabhängige Rootreview des vollständigen Vertrags und seiner gekoppelten
Discovery-/Backlogänderungen ist abgeschlossen. Diese Freigabe ist kein
Runtime-Nachweis; Welle 2 und eine DDL-ausführende API bleiben getrennt.

Genau die bestehende öffentliche `toolbelt_metadata.USP_ScriptTableClone`
und ihr kanonischer interner Kern `USP_ScriptTableCloneInternal` werden
erweitert. Kein neues fachliches Objekt, Provider, Parser oder Package.
Same-database ScriptOnly bleibt verbindlich. Zentraler Aufruf liest die
Installationsdatenbank, keinen Caller-Datenbankkatalog. Keine automatische
DDL-Ausführung, Datenkopie, Trigger, Berechtigungen, zusätzliche Identity-
Semantik, Foreign Keys, Mehrtabellenplanung oder Spezialtabellen.
Welle 2 bleibt getrennt. Die historischen V1-Verträge bleiben nachvollziehbar.

## Öffentliche Signatur und Ergebnis

| Position | Parameter | Typ | Default |
|---:|---|---|---|
| 1 | `@SourceSchema` | nvarchar(max) | NULL |
| 2 | `@SourceTable` | nvarchar(max) | NULL |
| 3 | `@TargetSchema` | nvarchar(max) | NULL |
| 4 | `@TargetTable` | nvarchar(max) | NULL |
| 5 | `@IncludeIdentity` | bit | 0 |
| 6 | `@IncludeExtendedProperties` | bit | 0 |
| 7 | `@ResultTable` | sysname | NULL |
| 8 | `@KeepData` | bit | 0 |
| 9 | `@Debug` | tinyint | 0 |
| 10 | `@Hilfe` | bit | 0 |

Beide Include-Parameter benötigen einen expliziten nicht-NULL-Wert.
Identifierprüfung und Standardtail folgen dem bestehenden
[Objektvertrag](../../Modules/toolbelt.metadata.table-clone/Documentation/USP_ScriptTableClone.md)
und [USP-Vertrag](../Standards/USP_CONTRACT.md). Help gewinnt vor allen
fachlichen Prüfungen und ignoriert ResultTable/KeepData/Debug/Include-Werte.
Der öffentliche Help-/Namespace-Precompile-Guard bleibt vor dem internen Kern.
Positional Caller müssen angepasst werden; benannte bisherige Argumente
behalten ihre Bedeutung. Kein heuristischer Kompatibilitätsdispatch.

Die vier Resultspalten bleiben unverändert: `Ordinal int NOT NULL`,
`ObjectKind varchar(32) NOT NULL`, `TargetName nvarchar(776) NOT NULL`,
`ScriptText nvarchar(max) NOT NULL`; Textspalten verwenden weiterhin BIN2.
Ordinal ist lückenlos, positiv und alleinige fachliche Scriptreihenfolge.
Die ersten sieben Zeilen sind immer vorhanden, auch ohne Computed/Filter:

| Ordinal | ObjectKind | ScriptText |
|---:|---|---|
| 1 | SESSION_OPTION | SET ANSI_NULLS ON; |
| 2 | SESSION_OPTION | SET ANSI_PADDING ON; |
| 3 | SESSION_OPTION | SET ANSI_WARNINGS ON; |
| 4 | SESSION_OPTION | SET ARITHABORT ON; |
| 5 | SESSION_OPTION | SET CONCAT_NULL_YIELDS_NULL ON; |
| 6 | SESSION_OPTION | SET QUOTED_IDENTIFIER ON; |
| 7 | SESSION_OPTION | SET NUMERIC_ROUNDABORT OFF; |

`TargetName` ist dort der gequotete Zieltabellenname. `TABLE` steht an
Position 8. Danach folgen Defaults, Checks, clustered und weitere Indizes
nach bisheriger deterministischer Ordnung; Extended Properties kommen zuletzt.
Die API führt diese SET-Texte nicht aus. Externe Ausführung benötigt eine
gemeinsame Session in Ordinalreihenfolge; sie kann deren Optionen ändern.
Die API garantiert keine spätere Driftfreiheit oder allgemeine Clone-Vollständigkeit.

## Berechnete Spalten

`sys.computed_columns` ist die Definitionquelle. Die Spalten bleiben in
`column_id`-Reihenfolge Bestandteil derselben TABLE-Zeile. Ausgabe:
gequoteter Name, `AS` und unveränderte Definition; bei `is_persisted=1`
zusätzlich `PERSISTED`. Explizites `NOT NULL` wird nur für eine persisted
Spalte mit `is_nullable=0` ausgegeben. Nicht-persistierte abgeleitete
Nicht-Nullability wird nicht als unzulässige zusätzliche Klausel ausgegeben.
Kein normaler Typ-, COLLATE-, Identity- oder NULL-Tail an Computed-Ausdrücken.
Fehlende Definition führt zu 53905/1, nicht zu leerem Script.

W1 unterstützt tabellenlokale Ausdrücke mit eingebauten Funktionen und den
bisher unterstützten Ergebnistypen. Keine Umbenennung innerhalb der Definition,
kein Regexparser, keine Transformation von Literalen. User-defined Functions,
CLR-Ausdrücke/-Typen, externe Tabellen-/Datenbank-/Serverreferenzen, Sequenzen,
benutzerdefinierte Typen sowie nicht auflösbare/mehrdeutige/callerabhängige
Dependencies führen vor Ausgabe zu 53903. Catalogabhängigkeiten werden nur
für die jeweilige Computed-Spalte bewertet; bisherige Default-/Check-Verträge
werden nicht stillschweigend enger. Built-in-Ausdrücke ohne solche
Catalogabhängigkeit sind zulässig. Ein gefiltertes Prädikat auf einer Computed-
Spalte wird nicht als zusätzliche Capability versprochen.

**Einzeln freigegebene Voraussetzung:** Bei vorhandenen Computed-Spalten
benötigt die sichere Dependencyklassifikation neben dem bisherigen DB-
`VIEW DEFINITION` vorhandenes `SELECT` auf `sys.sql_expression_dependencies`.
Vor der ersten Dependencyabfrage muss
`COALESCE(HAS_PERMS_BY_NAME(N'sys.sql_expression_dependencies',N'OBJECT',N'SELECT'),0)<>1`
mit festem payloadfreiem 53901/3 blockiert werden. 0 und NULL blockieren gleichermaßen.
Dieses zusätzliche Gate gilt ausschließlich bei Computed-Spalten, nicht für
unveränderte normale Tabellen. Keine GRANTs, Impersonation oder automatische
Reparatur. Die JSON-Uninstall-Freigabe gilt nicht für Clone; diese konkrete
Grenze wurde am 2026-10-02 separat besprochen und ausdrücklich freigegeben.

## Gefilterte Rowstore-Indizes

Ordinary nonclustered Indizes dürfen zusätzlich `has_filter=1` haben;
PK/UQ-Constraints, clustered, disabled, hypothetical, partitionierte,
komprimierte und bisher ausgeschlossene Spezialindizes erhalten keine neue
Unterstützung. Der unveränderte `filter_definition`-Text steht nach Keys/INCLUDE
und vor WITH/ON. `has_filter=1` mit NULL-Definition führt zu 53905/1.
Unique-Flag, ASC/DESC, Include-Reihenfolge, Filegroup und bisherige Optionen
bleiben erhalten. Enginevalidierte Definitionen werden nicht umgeschrieben.
Namen werden weiterhin mit vollständigem length-framed SHA256 erzeugt;
Kollisionen prüfen DATABASE_DEFAULT, keine Trunkierung oder Casefold-Namen.

## Extended Properties

`@IncludeExtendedProperties=0` lehnt vorhandene relevante Properties weiterhin
als 53903 ab; das ist kein stilles Weglassen. Bei 1 werden alle unterstützten
Properties typgetreu geplant oder die gesamte Vorschau verworfen.
Zulässige Owner: Tabelle, Spalte, Default, Check, PK/UQ-Constraint und ordinary
Index. Catalogklasse 1 beziehungsweise 7 wird mit Tabelle/Spalte und den
deterministisch neu erzeugten Constraint-/Indexnamen gekoppelt. Keine
Datenbank-, Schema-, Rollen-, Benutzer- oder sonstigen Objektproperties.

Konservativer Ownershipschutz: jeder relevante Propertyname mit ASCII-
case-insensitivem Präfix `Toolbelt.` führt zu 53903, unabhängig vom Wert.
Keine Markerauslassung und keine durch Kopieren erfundene Managed-Ownership.
Das ist eine technische Unsupported-Grenze, keine neue Permission-Capability.
Andere Namen, einschließlich Leerzeichen und Quotes, bleiben exakt erhalten.

Endliche Value-Whitelist: NULL, bit, tinyint/smallint/int/bigint,
decimal/numeric, money/smallmoney, finite float/real, date/time/datetime/
smalldatetime/datetime2/datetimeoffset, char/varchar/nchar/nvarchar,
binary/varbinary und uniqueidentifier. Keine MAX-/CLR-/XML-/sql_variant-
Verschachtelung oder andere unbekannte Basistypen. Wert, Basistyp, Precision,
Scale, MaxLength und String-Collation werden erhalten; numerische Werte
werden nicht über float oder kleinere decimal-Typen geführt.

Der Renderer verwendet explizite typisierte Rekonstruktion, Unicode-/Binary-
Literale und enginevalidierte Collationnamen. Insbesondere decimal(38,s),
negative Null-/Exponentdarstellungen bei float, trailing spaces, binäre
Nullbytes und DateTime-Bruchteile benötigen echte Roundtriporakel; einfache
universelle CONVERT(nvarchar)-Darstellung ist kein Nachweis. Float-Style3 ist
ein geplanter verlustfreier Textweg, dessen Basistyp-/Bitparität zu prüfen ist.
**Einzeln freigegebene Ergebnisvertragsausnahme:** Ausschließlich eine Zeile mit
`ObjectKind=EXTENDED_PROPERTY` darf genau zwei Statements als begrenzten Batch
enthalten: `DECLARE @tbx_CloneEp<Ordinal> sql_variant = <typisierte Rekonstruktion>;`
und `EXEC sys.sp_addextendedproperty @name=N'<escaped Name>',
@value=@tbx_CloneEp<Ordinal>, @level0type=N'SCHEMA', ...;`.
Die konkreten level-Namen sind vollständig gequotete Stringargumente, keine
Identifierinterpolation oder Ausführung durch den Planer. Alle übrigen Zeilen,
einschließlich SESSION_OPTION, bleiben genau eine Anweisung pro Zeile.
Kein zusätzlicher EXEC-Wrapper und keine weitere Planart.
Der positive finale Ordinal erzeugt innerhalb des Plans eindeutige Variablen.
Bei externer Zusammenfügung ist die Namensfamilie `@tbx_CloneEp<Ordinal>` im
ausführenden Batch reserviert; vorhandene gleichnamige Caller-Variablen würden
zu einem Engine-Compilefehler führen, werden nicht überschrieben oder übernommen.
Separate externe Batches in derselben Session haben getrennten Variablenscope
und erhalten trotzdem die vorher ausgeführten SET-Optionen. Die API fügt
keine GO-Direktiven ein. Diese eng begrenzte Batchausnahme wurde am
2026-10-02 konkret besprochen und ausdrücklich freigegeben. Sie gilt für
2.0.0; der historische V1-Vertrag bleibt unverändert nachvollziehbar.

Propertyreihenfolge: Ownerklasse Tabelle/Spalte/Default/Check/PK/UQ/Index,
darunter vorhandene Source-Spalten-/Objektordnung, danach Propertyname nach
BIN2 und binärer Identität. `TargetName` bezeichnet den gequoteten Target-
Ownerpfad. Rawwerte und Propertynamen werden niemals in festen Fehlertexten
oder öffentlicher Testevidenz protokolliert.
Der native 7500-Byte-Propertywertvertrag und `SQL_VARIANT_PROPERTY`-Metadaten
müssen vor der Typ-/Scriptrekonstruktion überprüft werden. DATALENGTH-
Payload und Variant-Gesamtbytes sind getrennt zu betrachten; der Grenztest
darf deren unterschiedliche Bedeutung nicht stillschweigend gleichsetzen.

## Fehler, Ressourcen und atomare Ausgabe

Help, öffentlicher Namespaceguard, bestehende DB-Sichtbarkeit und Argumente,
Source-/Targetprüfung, neues Computed-only-Sichtbarkeitsgate, Unsupported,
fehlende Definitionen, Metadatenressourcen, Namen, finale Scriptbytes,
ResultTable-Dependency und Output bilden die Prüfphasen. Bestehende relative
V1-Priorität DB-Sichtbarkeit vor Argumenten bleibt erhalten. Keine
datenabhängige neue Fehlerpriorität durch vorzeitige LOB-/Value-Konvertierung.
53900 Argumente, 53901 Sichtbarkeit/Quelle, 53902 Ziel, 53903 Unsupported,
53904 Namen, 53905 Definition, 53906 Ressourcen, 53907 ResultTable-Dependency,
53908 Namespace bleiben bestehen; neue States werden gekoppelt dokumentiert.
Enginefehler bleiben unverändert; feste Toolbeltfehler tragen keine Payload.

Keine Limitänderung: höchstens 1024 Spalten, 128 Index-Metadatenzeilen,
2048 untergeordnete Catalogobjekte und 2097152 UTF16-Scriptbytes insgesamt.
Keine zusätzliche feste 2048-Grenze für Planzeilen oder Properties.
Aus der bestehenden Bytegrenze folgt konservativ höchstens 1048576 finale
Zeilen, weil jeder ScriptText mindestens eine UTF16-Codeeinheit umfasst.
Der tatsächliche Höchstwert ist wegen der festen Syntax kleiner; dieses
abgeleitete Maximum ist keine zusätzliche engere Ablehnung gültiger Pläne.
Ein früher Count-/Minimalbyte-Preflight darf nur ablehnen, wenn bereits ein
beweisbarer unterer Scriptbytewert die bestehende Bytegrenze überschreitet.
Wide/checked-Arithmetik; Definitionen von Defaults, Checks, Computed und Filter
werden vor STRING_AGG/Scriptkopien kumulativ begrenzt. Propertyanzahl/-werte
werden vor Rekonstruktion begrenzt; escaped Rendererexpansion zählt zur
finalen Grenze. Kein stilles Abschneiden oder Überspringen.

Die gesamte Vorschau wird vor fachlichem SELECT oder ResultTable-Mutation
materialisiert und validiert. Alle vier KeepData-Fälle, Helperidentität,
eigene Transaktion/Caller-Savepoint, Originalfehler und Cleanup folgen V1.
Kein fremder Commit/Rollback; bei doomed Caller wird kein Savepointrollback
behauptet. Keine Scriptausführung im Kern, Help, Debug oder Lifecycletest-
Adapter ohne gesonderte synthetische Testautorisierung.

## Lifecycle und gekoppelte Akzeptanzgates

Beide bestehenden P-Slots werden für genuine 1.0.0 und Ziel 2.0.0 registriert.
Bekannte Version-/Managed-/ModuleId-/Mode-Kohärenz vor Mutation und unter dem
gemeinsamen AppLock; unbekannte/fremde Slots und externe Dependencies blockieren.
Caller-TX-Guard bleibt RAISERROR16+RETURN vor SET mit SQLCMD-Abbruch.
Keine neue generische Schema-, Rechte- oder Infrastrukturpolicy.
Echte 1.0.0-Fixture aus öffentlichem Gitpin, unveränderte historische Source/
Deployment und Provenienz; kein zurückversionierter neuer Installer.

Die konkrete Besprechung und Freigabe des Computed-only-Metadatengates und
der einzelnen EP-Batchausnahme sowie der unabhängige Vertragsreview sind
abgeschlossen. Jetzt folgt gekoppelte Source-/Help-/Objektdoc-/
Manifest-/Lifecycle-/Static-/Runtime-/CI-Pflege für 2.0.0.
Pflichtorakel: alle zehn Parameter/Defaults und Positionsbruch; reine Hilfe;
exakte SET1..7/TABLE8 und Calleroptionen; Computed persistiert/nichtpersistiert/
explizit NOT NULL, indexierte Computed, Built-in/UDF/externe/NULL-Definition;
Filter NULL/IN/range mit unique/nonunique/Includes; jeder Propertybasistyp
mit Metadaten und exakten Werten, decimal38/Scale38, float/real, DateTime7,
CI/CS/BIN2/UTF8-Strings, Binary, NULL, Quotes/trailing spaces, Ownershipmarker;
Grenzen jeweils minus/at/plus und späte Fehler mit unveränderter ResultTable;
alle KeepData-/Caller-TX-/Central-/Client-/Lifecycle-Kollision-/Upgradefälle.
Properties auf umbenannten Defaults/Checks/PK/UQ/Indizes werden gegen den
extern synthetisch ausgeführten Zielkatalog verglichen; Scriptvergleich allein
ist kein semantischer Roundtripnachweis. Externe DDL bleibt reine Testfixture.

W1-Source und der ausgewählte öffentliche Runtime-Scope sind umgesetzt und teilweise validiert; V1-Nachweise bleiben getrennt.
Kein konkreter SQL-Host, private Pfade, Inventar, reale Katalogwerte oder
Credentials gehören in Repository-Evidenz. Die echte scopebezogene Labqualifikation
bestand in den beiden unten dokumentierten finalen öffentlichen Läufen. CI am geprüften Head 76888216 bestanden; tatsächliche Minimalrechte und weitere physische Ziele bleiben getrennte offene Gates.

## Primärquellen und Alternativen

Geprüft am 2026-10-02. Die Quellen dokumentieren native Voraussetzungen,
nicht die erfolgreiche Toolbelt-W1-Implementierung.

- [Microsoft: Indizes auf berechneten Spalten und SET-Voraussetzungen](https://learn.microsoft.com/en-us/sql/relational-databases/indexes/indexes-on-computed-columns?view=sql-server-ver17)
- [Microsoft: CREATE TABLE / Computed-Syntax](https://learn.microsoft.com/en-us/sql/t-sql/statements/create-table-transact-sql?view=sql-server-ver17)
- [Microsoft: sys.sql_expression_dependencies und Rechte](https://learn.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-sql-expression-dependencies-transact-sql?view=sql-server-ver17)
- [Microsoft: sp_addextendedproperty](https://learn.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-addextendedproperty-transact-sql?view=sql-server-ver17)
- [Microsoft: SQL_VARIANT_PROPERTY](https://learn.microsoft.com/en-us/sql/t-sql/functions/sql-variant-property-transact-sql?view=sql-server-ver17)

SMO/DacFx/CLR würde zusätzliche Provider-/Versionsabhängigkeiten schaffen.
Ein neuer Execute-Wrapper überschritte ScriptOnly. Stille Propertyauslassung
oder Textkonvertierung aller Values verlöre Struktur beziehungsweise Typen.
Der vorhandene Catalogkern mit endlichen Typgrenzen bleibt der gewählte Weg.

## Zusätzliche Lifecycle-Sichtbarkeitsfreigabe am 2026-10-02

Der Benutzer hat nach konkreter Besprechung ausdrücklich "Ja, Lifecycle-Sichtbarkeitsgate freigeben" geantwortet. Deploy und Uninstall setzen vorhandenes datenbankweites VIEW DEFINITION sowie SELECT auf sys.sql_expression_dependencies voraus. Beide Prädikate müssen exakt1 liefern; 0, NULL oder unklar blockieren vor Änderungen und erneut unter AppLock mit payloadfreiem53926/2. Keine Rechte werden erteilt. Das Computed-only-Vorschaugate53901/3 bleibt unverändert. Negative Predicate-Injektionen sind technische Orakel, kein tatsächlicher Lowpriv-Nachweis.

Managed1 und byteexakte SchemaCategory=metadata begründen ausschließlich das bedingte Entfernen eines tatsächlich eigenen, leeren Schemas, frisch nach AppLock und unmittelbar vor DROP. Ein vorhandenes unmarkiertes oder fremdes Schema bleibt wie genuine1.0 nutzbar und wird nicht adoptiert oder entfernt. Die beiden Modulslots benötigen TypP, byteexakte ModuleId und Releaseversion sowie bekannte Modekohärenz vor Mutation und unter AppLock. Keine neuen historischen Objekt-Managed-Marker. Versionsreread ist byteexakt einschließlich NULL/Propertyexistenz; gepaddete Werte sind kein bekannter Release.

## Gezielter öffentlicher Runtime-Nachweis 2026-10-03

Am 2026-10-03 bestanden die finalen öffentlichen Adapter auf SQL Server 2019 Linux/latest CL150 und 2025 Windows/CU8 CL150/160/170 jeweils lokal und zentral. Vier Runtime-Fixtures einschließlich 27 Propertytypen und separater 18-datetimeoffset-Produktpfadregression, Client-/Lifecycle-/Caller-TX-/SET-/AppLock-/Rollback-/Kollisions-/Dependency-/Atomikorakel sowie genuine 1.0-Upgrades und eigene Bereinigung sind qualifiziert. Inputs und Genuine-Blobs sind hashgebunden; tatsächlicher Exit, vollständige Kanäle, exakt gebundenes Journal und frischer Cleanup-Audit wurden zusammen geprüft. Keine Konfigurations-, Rechte-, Trust- oder Infrastrukturänderungen. Der Zähler32 ist nur der Visibility-Teilbereich. CI am geprüften PR-Head 76888216 bestanden: alle sieben Checks SUCCESS einschließlich SQL Server 2019/2022/2025 Linux. Tatsächliche Minimalrechte mit eigenem Principal und weitere physische Ziele bleiben NOT_EXECUTED. Teilweise validiert und unveröffentlicht.
