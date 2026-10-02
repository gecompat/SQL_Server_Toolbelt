# Vertrag: gruppierte JSON-Konstruktoren

Stand: 2026-10-02. Kanonischer Vor-Source-Vertrag für die individuell
freigegebenen beiden USPs. Geplante additive Modulversion: `1.1.0` in
`toolbelt.json.constructors`. Die Sourceumsetzung ist noch offen. Das technische
Vor-Source-Gate wurde nach unabhängigem Kandidatenreview und Rootreview am
2026-10-02 abgeschlossen; dieses Dokument behauptet weder Installation noch SQL-Validierung.

Additiver Umsetzungsstand 2026-10-02: `toolbelt.json.constructors` 1.1.0 implementiert die beiden einzeln freigegebenen Gruppen-USPs über den gemeinsamen T-SQL-Kern. Auf Linux 2019/latest CL150 und Windows 2025/CU8 CL150/160/170 bestanden lokal und zentral die API-/100000-/16-MiB-/Clientprüfungen als Teil insgesamt fehlgeschlagener früherer Läufe. Die finalen fokussierten Läufe mit ausschließlich InstalledMetadata.Contract.sql als Runtime-Auswahl bestanden Metadaten, genuine 1.0-Upgrades, Lifecycle, Central und eigene Bereinigung. Neue Minimalrechte bleiben offen; die Uninstall-Voraussetzung VIEW DEFINITION/SELECT wurde am 2026-10-02 einzeln freigegeben und die neue Gateumsetzung bestand fokussierte native Lifecycle-Läufe, negative CI-Injektionen bleiben offen; aktuelle CI wird als separater PR-Mergegate nachgewiesen. Teilweise validiert und unveröffentlicht; historische 1.0-Evidenz bleibt getrennt. Die vorstehende offene Sourcebeschreibung gehört zum historischen Vor-Source-Gate; normative Vertragsregeln sind unverändert.

## 1. Freigabe, Zweck und Grenzen

Die dauerhafte Einzelfreigabe steht in
[BACKLOG: Individuell freigegebene Ergänzungen](../../.ai/BACKLOG.md#individuell-freigegebene-ergänzungen-jaro-winkler-paarvergleich-und-gruppiertes-json).
Nach Besprechung bestätigte der Benutzer am 2026-10-01 die ausdrückliche
Implementierungsfrage mit „ja“, insbesondere für
`USP_JsonArraysByGroup` und `USP_JsonObjectsByGroup`: bestehender Entries-
Vertrag plus positive `GroupOrdinal`, ein Ergebnis je vorhandener Gruppe,
Reihenfolge nach Entry-Ordinal, Duplicate Keys nur innerhalb einer Gruppe
verboten, gemeinsamer Prüf-/Escapingkern, globale Ressourcenbudgets und keine
Teilmutation. Diese Einzelfreigabe ist keine allgemeine Backlogfreigabe.

Genau zwei öffentliche APIs entstehen:

- `toolbelt_json.USP_JsonArraysByGroup`
- `toolbelt_json.USP_JsonObjectsByGroup`

Beide verwenden den bestehenden T-SQL-Kern. Keine zusätzliche Assembly,
kein Provider, keine neue ResultTable-Infrastruktur, keine Installation von
Dependencies, keine Rechteausweitung und keine Serverkonfiguration gehören
zum Funktionsscope. Es gibt keine Typinferenz, Formatierung, JSON-Patches,
Gruppennamen, Gruppenheader oder explizit leere Gruppen. Die USPs sind keine
in `GROUP BY` aufrufbaren SQL-Aggregatobjekte. Values und JSON-Fragmente
werden niemals als SQL ausgeführt.

Der [bestehende ungruppierte Vertrag](JSON_CONSTRUCTOR_PROPOSAL.md#aktueller-freigegebener-slice-b-2026-10-01)
bleibt für `USP_JsonArray` und `USP_JsonObject` erhalten. Maßgeblich bleiben
der [USP-Vertrag](../Standards/USP_CONTRACT.md) und das
[Deployment-Modell](DEPLOYMENT_MODEL.md).

## 2. Öffentliche Signaturen und Help

Beide neuen USPs besitzen exakt dieselben acht Parameter wie die bisherigen
öffentlichen Fassaden, in dieser Reihenfolge:

| Position | Parameter | SQL-Typ | Technischer Default |
|---|---|---|---|
| 1 | `@EntriesTable` | `sysname` | `NULL` |
| 2 | `@MaxEntries` | `int` | `10000` |
| 3 | `@MaxTotalValueBytes` | `bigint` | `2097152` |
| 4 | `@MaxResultBytes` | `bigint` | `2097152` |
| 5 | `@ResultTable` | `sysname` | `NULL` |
| 6 | `@KeepData` | `bit` | `0` |
| 7 | `@Debug` | `tinyint` | `0` |
| 8 | `@Hilfe` | `bit` | `0` |

Ressourcenparameter müssen positiv sein und dürfen explizit nicht `NULL`
sein. `NULL` für `KeepData`, `Debug` und `Hilfe` wird auf `0` normalisiert.
`@Hilfe=1` hat Vorrang: ausschließlich standardisiertes Help, keine
fachliche Prüfung, kein Dependency-, Input-, Namespace- oder Outputpreflight,
keine Debug-Messages und keine Mutation. Help beschreibt alle Parameter,
beide Resultspalten, Fehler, Grenzen und einen vollständigen synthetischen
Aufruf. Die vorhandenen öffentlichen acht Parametersignaturen ändern sich nicht.

## 3. Input und Identität

`EntriesTable` bezeichnet eine bestehende caller-lokale `#Temp`.
Globale Temps, Tabellenvariablen, permanente Tabellen und der reservierte
interne `#tbx_`-Namespace sind ausgeschlossen. Der Input wird einmal über
seine `object_id` aufgelöst; weitere Metadatenprüfungen verwenden diese ID.
Input und ResultTable dürfen nicht dasselbe Objekt sein.

Erforderliche Spalten besitzen die exakten Systemtypen, keine Alias-Typen
und keine computed columns; zusätzliche Spalten werden ignoriert:

| Spalte | Typ | Semantik |
|---|---|---|
| `GroupOrdinal` | `int` | Nicht NULL und positiv; Lücken erlaubt. |
| `Ordinal` | `int` | Nicht NULL und positiv; Lücken erlaubt. |
| `ValueKind` | `nvarchar(max)` | Exakt bestehender Kindvertrag. |
| `Value` | `nvarchar(max)` | Exakt bestehender Valuevertrag. |
| `Key` | `nvarchar(max)` | Nur Objects: nicht NULL/leer, höchstens 1024 UTF-16-Codeeinheiten. |

`(GroupOrdinal,Ordinal)` ist eindeutig. Gleiche Entry-Ordinals in
unterschiedlichen Gruppen sind erlaubt. Object-Keys werden über vollständige
UTF-16-Bytes und Bytelänge identifiziert, nicht allein über SQL-Textgleichheit:
`a`, `a ` und `A` bleiben verschieden. Duplikate sind nur innerhalb derselben
Gruppe verboten. Die Keyprüfung verwendet nach der Längengrenze
`GroupOrdinal`, `CONVERT(varbinary(2048),Key)` und `DATALENGTH(Key)`.

Alle bestehenden Regeln für `string`, `number`, `boolean`, `null` und `json`,
SQL-NULL, unveränderte Fragmenttexte, tatsächliche und decodierte Unicode-
Surrogate sowie Escaping und Literalgrammatik werden aus genau einem Kern
wiederverwendet. Kein gruppierter Zweitparser entsteht. Der bestehende
`json`-Kind akzeptiert vollständige Objekte/Arrays, keine Scalars; die
Gruppierung fügt keine rekursive Duplicate-Key- oder Schemaprüfung hinzu.

## 4. Resultset und Routing

| Position | Spalte | Typ | Nullability |
|---|---|---|---|
| 1 | `GroupOrdinal` | `int` | `NOT NULL` |
| 2 | `JsonValue` | `nvarchar(max) COLLATE Latin1_General_100_BIN2` | `NOT NULL` |

Es entsteht genau eine Zeile je tatsächlich vorhandener Gruppe. Der
fachliche SELECT sortiert ausdrücklich nach `GroupOrdinal`; Entries jeder
Gruppe werden nach `Ordinal` serialisiert. Eine ResultTable garantiert keine
physische Zeilenordnung; `GroupOrdinal` ist ihre stabile Sortierspalte.

Leerer Input erzeugt ein fachliches Resultset mit null Zeilen, keine
Phantomgruppe. Mit ResultTable erfolgt trotzdem die normale Vorbereitung:
Replace entfernt alte Daten und bereitet das Zweispaltenschema vor; Append
bewahrt kompatible Daten. Eine gefüllte inkompatible Append-Table wird vor
Mutation abgewiesen. Leere inkompatible Tabellen dürfen regulär angepasst
werden. Blockierende Dependencies werden nicht entfernt. Es gelten alle
übrigen KeepData-/Help-/Debug-Regeln des bestehenden USP-Vertrags.

Ungruppierte Aufrufe behalten eine einzige `JsonValue`-Spalte und genau eine
Zeile, einschließlich `[]` beziehungsweise `{}` bei leerem Input.

## 5. Ein kanonischer Kern und zwei feste Referenzschemas

`USP_JsonConstructInternal` erhält den technischen Parameter
`@GroupMode bit=0` direkt nach `@MaxResultBytes` und vor dem Standardtail
`@ResultTable,@KeepData,@Debug,@Hilfe`. Die interne Signatur wird damit
gekoppelt geändert; diese Änderung wird nicht als unveränderte interne
Metadaten behauptet. `GroupMode=NULL` ist außerhalb Help ein Fehler `53600`.
Bestehende Fassaden rufen benannt auf und verwenden den Default `0`; die
neuen Fassaden setzen benannt `1`.

Internes Help klassifiziert `ObjectMode` und `GroupMode` als technische
Parameter und beschreibt die zwei modusspezifischen Resultschemas ausdrücklich.
Seine Parameterordinals werden aktualisiert. Help bleibt auch bei ungültigen
technischen Parametern ein reiner Help-Aufruf ohne fachliche Validierung.

Snapshot und Fragmente tragen intern `GroupOrdinal`. GroupMode `0` verwendet
eine synthetische konstante Gruppe, die nicht öffentlich ausgegeben wird.
Der bestehende begrenzte Entry-Cursor arbeitet in der Reihenfolge
`GroupOrdinal,Ordinal`; die gemeinsame Validierung und Escapinglogik
existiert weiterhin genau einmal. Kein Core-Aufruf je Gruppe und kein
verschachteltes `INSERT ... EXEC` werden eingeführt.

Geordnete `STRING_AGG`-Assembly erfolgt je Gruppe in einer gemeinsamen
Gruppierungsabfrage, erst nach dem gesamten Fragment-/Syntaxbudgetpreflight.
Alle Ergebnisse werden vollständig privat materialisiert, bevor genau ein
ResultTable-Helper-Aufruf und ein expliziter Insert beziehungsweise ein
fachlicher SELECT stattfinden.

Zwei verschiedene private Tabellen mit festen Schemas sind erforderlich:
die bestehende `#tbx_JsonConstructor_Result(JsonValue)` und eine neue
`#tbx_JsonConstructor_GroupResult(GroupOrdinal,JsonValue)`. Keine bedingten
`CREATE TABLE` desselben Namens mit verschiedenen Schemas. Das Routing
verwendet jeweils das richtige Referenzschema, sodass das bisherige
Einspaltenschema nicht durch das Gruppenschema ersetzt wird.

Alle vier Fassaden prüfen vor Core-Kompilierung die bestehenden reservierten
Tempnamen und den neuen GroupResult-Namen. Help steht vor diesem Guard.
CS-/CI- und Temp-Eclipsing-Regressionen sind erforderlich; ein Callerobjekt
im reservierten Namespace darf keine frühere Compile-Ausnahme anstelle des
festen Vertragsfehlers hervorrufen. Der Guard enthält keine Nutzdaten.

## 6. Globale Budgets und untere Grenzen

| Parameter | Default | Harte Obergrenze | Zählung |
|---|---|---|---|
| `MaxEntries` | 10000 | 100000 | Alle Inputzeilen, über sämtliche Gruppen. |
| `MaxTotalValueBytes` | 2097152 | 16777216 | Summe `DATALENGTH(Value)`; SQL-NULL zählt 0. |
| `MaxResultBytes` | 2097152 | 16777216 | Summe `DATALENGTH(JsonValue)` über sämtliche Gruppen. |

Es gibt keinen Budgetreset je Gruppe und keine Multiplikation einer Grenze
mit der Gruppenanzahl. Bei `N` Entries und `G` vorhandenen Gruppen gilt
`0<=G<=N<=MaxEntries`. Ein zusätzlicher Gruppenparameter ist nicht erforderlich.

Für `N>0` sind die finalen Syntaxbytes exakt
`4*G+2*(N-G)`: zwei UTF-16-Klammern je Gruppe und ein UTF-16-Komma zwischen
benachbarten Entries derselben Gruppe. Dazu kommen sämtliche vollständigen
Fragmentbytes. GroupMode `1` mit `N=0` hat `G=0` und null Ergebnisbytes;
GroupMode `0` mit `N=0` hat weiterhin vier Syntaxbytes.

Vor privater LOB-Kopie erfolgt der bestehende begrenzte
`TOP(MaxEntries+1)`-Preflight unter `TABLOCK,HOLDLOCK`. Nach Count- und
Ordinal-/Key-/Kindlängenprüfung wird die rohe untere Ergebnisgrenze geprüft:
`ValueBytes+KeyBytes+SyntaxBytes+6*N` für Objects, beziehungsweise
`ValueBytes+SyntaxBytes` für Arrays. Die `6*N` zählen Object-Keyquotes und
Doppelpunkt. Nach Kind-/NULL-Prüfung ersetzt die stärkere untere Grenze
NULL-Values durch acht Bytes für `null` und ergänzt vier Stringquote-Bytes;
Object-Keybytes und sechs Object-Syntaxbytes je Entry bleiben enthalten.

Anschließend erfolgen die unveränderten Unicode-/Literalprüfungen vor den
Fragmenten. Die globale Fragment-/Syntaxsumme wird vor `STRING_AGG` und
vor ResultTable-Mutation geprüft. Größenarithmetik und `SUM` verwenden
ausreichend breite Typen; kein `int`-Überlauf darf Limits umgehen.

Gezählt werden ausschließlich UTF-16-JSON-Nutzbytes. GroupOrdinal-Spalten,
SQL-Zeilen, Indizes, Locks und Allocatoroverhead sind kein Bestandteil des
Outputbudgets. Es gibt keine globale Heap-, Hardwall-, Durchsatz- oder
Parallelitätsgarantie. Begrenzte Ressourcen sind keine Produktionskapazitätszusage.

## 7. Fehlerpriorität und Atomarität

Die Priorität gilt über alle Gruppen; Fehler einer späteren Gruppe dürfen
nicht durch vorherige Ausgabe oder Zielmutation sichtbar werden:

| Reihenfolge | Kategorie | Fehler/State |
|---|---|---|
| 1 | Help | Ausschließlich Help. |
| 2 | Reservierter Caller-Tempnamespace vor Core-Kompilierung | `53601`, State 5. |
| 3 | Ressourcen/GroupMode | `53600`, State 1. |
| 4 | Registrierte ResultTable-Dependency | `53610`, State 1. |
| 5 | Inputname/Metadaten/Input-Output-Alias | Bestehende `53601`, States 1–4. |
| 6 | Globale Entryanzahl | `53609`, State 1. |
| 7 | GroupOrdinal NULL/nichtpositiv | `53602`, State 2. |
| 8 | Ordinal NULL/nichtpositiv oder Composite-Duplikat | `53602`, State 1. |
| 9 | Key NULL/leer/zu lang | `53603`, State 1. |
| 10 | Kind NULL/zu lang | `53605`, State 2. |
| 11 | Rohe Wertebytes, danach rohe minimale Outputbytes | `53609`, State 2, danach State 4. |
| 12 | Snapshot-Keyduplikat, exakter Kind, NULL-Vertrag | `53604`/`53605`/`53606`, jeweils State 1. |
| 13 | Stärkere minimale Outputbytes | `53609`, State 4. |
| 14 | Je GroupOrdinal/Ordinal ursprüngliche Unicode-/Literalprüfung | Bestehende `53607`-/`53608`-States unverändert. |
| 15 | Globale finale Outputsumme | `53609`, State 3. |
| 16 | Outputhelper/Insert | Originalfehler unverändert. |

Die neue Statebindung `53602/2` ist eine technische Konkretisierung des
vorhandenen Ordinalfehlers. Es wird keine zusätzliche Fehlernummer reserviert.
Ungruppierte Aufrufe prüfen keine vom Caller gelieferte GroupOrdinal und
behalten ihre ursprüngliche Priorität. Fachliche Fehlermessages und Debug
enthalten keine Values, Keys, JSON-Fragmente oder privaten Objektnamen.

Input bleibt unmutiert; ein stabiler privater Snapshot ist die gemeinsame
Verarbeitungsgrundlage. Alle Gruppen werden validiert und konstruiert,
bevor das erste fachliche Ergebnis oder der Outputhelper sichtbar wird.
Eigene Transaktionen werden bei Fehler zurückgerollt. Bei Callertransaktionen
werden Savepoints nur im committable Zustand zurückgerollt; kein Callercommit
und kein vollständiger Callerrollback. Eine doomed Callertransaktion muss
der Caller zurückrollen. Atomare Materialisierung ist keine Garantie für
atomare Client-/Netzwerkübertragung nach Beginn des abschließenden SELECT.

## 8. Gekoppelte Lifecycle-Voraussetzung

Der neue Releaseumfang enthält genau fünf Slots: die bisherigen drei
`USP_JsonConstructInternal`, `USP_JsonArray`, `USP_JsonObject` seit `1.0.0`
und die zwei gruppierten Fassaden seit `1.1.0`. Die Erweiterung erfordert
ein echtes gepinntes `1.0.0`-Upgrade, Reinstall und Uninstall; lokale und
zentrale Modi verwenden dieselbe Source.

Deploy und Uninstall müssen eine aktive Callertransaktion **vor jedem SET,
jeder Temp-DDL und jeder Mutation** mit einer festen nondooming
`RAISERROR`-/Return-Grenze abweisen; der SQLCMD-Adapter beendet bei Fehler
die weitere Ausführung. Dies gilt auch für bereits doomed Caller und beide
`XACT_ABORT`-Zustände. Keine SET-Option, Transaction Count, Marker, Definition
oder Callerressource darf durch den abgewiesenen Aufruf verändert werden.
Diese Voraussetzung ist Teil der konkreten Erst-/Upgrade-/Uninstall-Welle,
kein globaler Lifecycle-Umbau anderer Module.

Bekannte installierte Versionen sind ausschließlich bytegenau `1.0.0` und
`1.1.0`; DeploymentMode ist ausschließlich bytegenau `local` oder `central`.
BIN2-Textvergleich allein genügt wegen SQL-Padding nicht. Unbekannte,
anders geschriebene oder gepaddete Werte werden fail-closed abgewiesen.
Kein Trimmen oder Normalisieren macht sie gültig.

Vor der ersten Mutation und erneut unter derselben installationsbezogenen
AppLock sind installierte Version, vollständiger releasebezogener Inventory,
Slots/Objekttypen, Objektmarker `Toolbelt.ModuleId` und bytegenaue
`Toolbelt.ModuleVersion` sowie Dependency und Ownership kohärent zu prüfen.
SourceHash bleibt ausschließlich diagnostisch: lokale Änderungen bekannter
eigener Releaseobjekte sind reparierbar; Hash oder Inhalt verleihen fremden
Objekten keine Ownership.

Für einen installierten historischen `1.0.0`-Scope sind die beiden neuen
Namen fremde Zukunftsslots. Vorhandene Objekte dort blockieren Upgrade auch
bei nachgeahmten historischen Markern; historischer Uninstall bewahrt sie.
Unbekannte/inkohärente Ownership wird nicht adoptiert. Der bekannte `1.1.0`-
Scope umfasst alle fünf eigenen Slots. Fremde Kollisionen, Dependencies und
Objekte bleiben unverändert. Alle eigenen DDL-/DML-/Markeränderungen sind
transaktional gekoppelt; Original- und Cleanupfehler werden nicht verschleiert.
Neue modulbezogene Lifecyclefehlermessages sind fest und enthalten keine
privaten Namen oder Inhalte. Die vorhandene Nummernzuordnung bleibt erhalten:

| Fehler/State | Lifecycle-Grenze |
|---|---|
| `50000/1` | Nondooming Callertransaktions-Reject mit festem JSON-Lifecycle-Prefix. |
| `53620/1` | Nicht unterstützte SQL-Version. |
| `53621/1` | Ungültiger angeforderter Deployment-Modus. |
| `53622/1` | Fehlende Rechte oder ungeeignete registrierte Dependency. |
| `53623/1` | Unbekannter/inkohärenter installierter Release-, Modus- oder Ownershipstand. |
| `53624/1` | Fremder neuer Zielslot beim Preflight. |
| `53625/1` | Ungültige Bestätigung oder fehlende zentrale Consumer-Bestätigung. |
| `53626/1` | Blockierende same-database Dependency beim Uninstall. |
| `53627/1` | AppLock oder unter Lock veränderter/inkohärenter Preflightstand. |
| `53628/1` | Unvollständiges Deployment innerhalb der eigenen Transaktion. |
| `53629/1` | Nicht unterstützter Compatibility Level. |

Der Caller-Reject verwendet einen festen Text, damit der Adapter `50000/1`
eindeutig zuordnen kann; Enginefehler werden unverändert weitergegeben.

### Freigegebene Uninstall-Metadatensichtbarkeit (2026-10-02)

Der Benutzer hat ausdrücklich freigegeben, dass Uninstall vorhandenes
`VIEW DEFINITION` auf der Installationsdatenbank und `SELECT` auf
`sys.sql_expression_dependencies` voraussetzt und fehlende Sichtbarkeit als
`53622/1` blockiert. Beide `HAS_PERMS_BY_NAME`-Prüfungen müssen exakt `1`
ergeben; `0` und `NULL` werden abgewiesen. Die Prüfung erfolgt vor der
Dependencyabfrage sowohl im Preflight als auch erneut unter derselben AppLock,
vor der ersten Objektmutation. Das Skript erteilt keine Rechte.

Am 2026-10-02 bestand die neue Gateumsetzung den fokussierten nativen
Adapter auf Linux 2019/latest CL150 und Windows 2025/CU8 CL150/160/170,
jeweils lokal und zentral mit ausschließlich InstalledMetadata.Contract.sql
und den gekoppelten Lifecycle-/Client-/Consumerprüfungen. Beide Läufe
beendeten sich erfolgreich mit vollständiger eigener Bereinigung und ohne
Konfigurations- oder Rechteänderung. Dies ist kein neuer Default-All-PASS.
Statische Predicate-/Reihenfolgeprüfungen und die neuen synthetischen
CI-Predicate-Injektionen ersetzen keinen tatsächlichen Minimalrechte-Nachweis.
Die negativen Injektionen und vollständige gekoppelte CI am neuen PR-Head
sind noch nicht ausgeführt. Frühere SQL-/CI-Nachweise bleiben getrennt.

Die ResultTable-Dependency bleibt registriert `>=1.0.0` in derselben
Installationsdatenbank, ohne automatische Installation oder Berechtigungserteilung.

## 9. Alternativen und Risiken

Ein Core-Aufruf je Gruppe würde Budget-/Transaktionsgrenzen zerteilen und
mehrfaches Routing erlauben; er wird verworfen. Ein separater Escapingkern
würde alte und neue Unicode-/Literalsemantik auseinanderlaufen lassen.
CLR/Aggregatprovider sind für diesen begrenzten relationalen USP-Scope nicht
erforderlich. Ein gemeinsamer Tempname mit zwei Schemas gefährdet bereits
die Kompilierung und das alte ResultTable-Referenzschema.

Neue Compiler-/Metadatenformen, Temp-Eclipsing, SQL-Collations, LOB-
Materialisierung, AppLock und tatsächliche ResultTable-DDL können durch
ein privates Gruppenmodell nicht qualifiziert werden. Daher bleiben
native SQL-Verträge und Lifecycleprüfungen verbindliche nächste Gates.

## 10. Tatsächliche Vorbereitung und offene Nachweise

Am 2026-10-02 wurde der private Kandidat gegen den vorhandenen T-SQL-Kern,
die dokumentierte Einzelfreigabe und USP-/Deployment-/Datenschutzregeln
unabhängig geprüft. Ein privates synthetisches Python-Gruppenmodell wurde
mit `python -B reference.py` reproduziert: **111 Assertions erfolgreich**.
Das Modell liegt nicht im Repository; private Pfade und rohe Runtimeausgaben
werden hier nicht übernommen. Es ist kein öffentliches CI-Artefakt.

Geprüft wurden alle 24 Inputpermutationen, Gruppen-/Entryordinals,
gruppenlokale Keyidentität, Empty Replace/Append, globale Count-/Value-/
Resultgrenzen, späte Fehler ohne synthetischen Targetwrite, tatsächliche
100000 Modellgruppen und ein tatsächliches 16777216-Byte-Modellergebnis.
Die Fragmente waren synthetisch vorvalidiert. Das Modell prüft ausschließlich
Gruppierung, Byteformel und verlangte Publish-Atomarität; es qualifiziert
keine SQL-Escaping-/Unicode-/Literalimplementierung, keine Fehlernummern,
SQL-CATCHs, ResultTable-DDL, CLR, Native SQL oder Optimizergrenzen.

Historische offene Gates zum Vor-Source-Zeitpunkt (aktueller Nachweis anschließend):

- Source-/Offline-Syntax-/Static-Verträge der zwei neuen USPs und des Coreumbaus;
- vollständige alte ungruppierte Regression und Help-/Clientmetadaten;
- tatsächliche SQL-100000-Gruppen-/16-MiB-Outputgrenzen und Unicode-/Literalfälle;
- zwei Resultschemas, alle KeepData-Fälle, Empty-Routing, Constraints und Eclipsing;
- Fehlerprioritäten, Own-/Caller-/doomed-Transaktionen und späte Gruppenfehler;
- echte `1.0.0`-Upgrade-/Reinstall-/Uninstall-/Future-Slot-/AppLock-/Rollbackfälle;
- lokale/zentrale native Labziele, Minimalrechte, übrige Zielmatrix und neue CI.

Rootreview vom 2026-10-02 bestätigt Signaturen, Budgets, Fehlerstates,
gemeinsamen Kern, beide Resultschemas und die gekoppelten Lifecycle-Grenzen.
Die dokumentierte Benutzer-Einzelfreigabe vom 2026-10-01 trägt die Umsetzung
der beiden USPs; der unabhängige private Review und dieser schriftliche
Vertrag schließen ausschließlich deren technisches Vor-Source-Gate.
Zum Vor-Source-Zeitpunkt blieben native SQL- und Merge-Gates offen. Modulstatus,
Testmatrix und Releasezustand werden erst aus tatsächlich ausgeführten
jeweiligen Nachweisen aktualisiert. Bestehende `1.0.0`-Evidenz wird nicht
rückwirkend auf gruppierte `1.1.0`-APIs übertragen.

## 10. Tatsächliche Umsetzungsevidenz 2026-10-02

Vor-Source-Gate als Commit `412dbdd3` festgehalten. Genau zwei neue Fassaden verwenden den bestehenden Kern mit GroupMode.

Am 2026-10-02 bestanden auf Linux 2019/latest CL150 und Windows 2025/CU8 CL150/160/170 lokal und zentral die fünf Runtime-Fixtures `JsonConstructors.Contract.sql`, `Collation.Contract.sql`, `JsonGroups.Contract.sql`, `JsonGroups.Boundaries.sql` und `InstalledMetadata.Contract.sql` sowie Clientmetadaten. Dazu gehören alte ungruppierte Regression, Unicode-/Literalfälle, Gruppierung, beide Resultschemas, KeepData/Empty-Routing, späte Fehler und echte 100000-Gruppen-/16-MiB-Grenzen. Diese Teilnachweise stammen aus insgesamt fehlgeschlagenen Läufen: Das spätere Central-Orakel meldete 54600/45 wegen einer column_id-Lücke. Sie sind kein vollständiger Adapter-PASS.

Die finalen fokussierten Läufe wählten ausdrücklich nur `-RuntimeTests InstalledMetadata.Contract.sql`. Beide Adapter bestanden lokal und zentral Metadaten, genuine unveränderte 1.0-Upgrades, Repeat, Rollback/Postlock/AppLock, Marker, Future-Slot-Typen, Dependencies, committable/doomed Callertransaktionen mit ON/OFF-Optionen, Central-Bestätigung, den tatsächlichen Consumer am höchsten ausgewählten CL, Uninstall und eigene Bereinigung. Die Wiederherstellungsjournale wurden unabhängig geprüft: abgeschlossen, eigene Datenbanken entfernt, keine Konfigurations- oder Rechteänderung. Daraus wird kein finaler Default-All-Fixtures-PASS abgeleitet.

Frühere fehlgeschlagene Läufe bleiben erhalten: 53609/4 im Escape-Budget-Orakel, 206 im Kollisionsfixture, 3998 im Caller-Batch und 54600/45 im Central-Orakel. Die jeweiligen Test-/Adapterkorrekturen ändern keinen Corevertrag.

Neue Minimalrechte, weitere Zielkombinationen und Produktions-/Parallelkapazität bleiben offen. Die Uninstall-Voraussetzung `VIEW DEFINITION`/`SELECT` wurde am 2026-10-02 einzeln freigegeben; die neue Gateumsetzung bestand fokussierte native Lifecycle-Läufe, negative CI-Injektionen bleiben offen. Aktuelle CI wird als separater PR-Mergegate nachgewiesen. Status `partially validated`, `unreleased`. Historische 1.0-Evidenz im Modulmanifest und in der Modultestmatrix gilt ausschließlich für die damaligen drei Slots.

Reproduzierbarer Adapter: `Tests/CI/run-json-groups-lab.ps1`; genaue Abgrenzung in der [Modultestmatrix](../../Modules/toolbelt.json.constructors/Tests/JSON_CONSTRUCTOR_CONTRACT_TEST_MATRIX.md).
