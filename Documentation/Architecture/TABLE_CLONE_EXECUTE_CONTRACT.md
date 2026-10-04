# Table Clone Executor / Hashlayout 1 / Modul 4.0.0

Stand 2026-10-04, Codex. Die Funktion `USP_ExecuteTableClone` wurde am
2026-10-01 einzeln freigegeben. Am 2026-10-04 bestätigte der Benutzer das
zusätzliche Servervollsicht-/DDL-Seiteneffektgate. Dieser Vertrag
konkretisiert die Umsetzung im bestehenden Modul
`toolbelt.metadata.table-clone`. Implementierung und unabhängige Sourceprüfung
sind abgeschlossen; die begrenzten 3.1-Native-Nachweise sind unten abgegrenzt.
Die3.1-Nachweise bleiben historisch; der neue4.0-Hash-/Planner-/Lifecyclepfad
bestand den im [Triggervertrag](TABLE_CLONE_TRIGGER_CONTRACT.md) abgegrenzten
lokalen Nachweis. Vollständige Produktqualifikation bleibt offen.
In4.0 bleiben14Parameter und Hashlayout1 gleich,
das gebundene Modulrelease wechselt auf4.0.0. IncludeTriggers wird nicht
weitergereicht und bleibt im benannten Planneraufruf0.
Historische Planner-V3-Nachweise
qualifizieren den Executor nicht. RelatedReference bleibt `TC-2026-044`;
keine neue Referenzfamilie oder Umdeutung historischer Entscheidungen.

## Zweck und Abgrenzung

Ein neuer öffentlicher P-Slot `toolbelt_metadata.USP_ExecuteTableClone`
erzeugt den kanonischen V3-Plan unmittelbar neu, vergleicht den erwarteten
Hash und führt ausschließlich diesen Plan aus. Die beiden bestehenden
Planner-Prozeduren bleiben Script-only und der einzige Renderer. Keine
frei übergebenen Scripts, zusätzliche Preview-/Hash-API, Datenkopie,
Triggerkopie, CLR-Assembly oder allgemeine Ausführungsinfrastruktur.

Nur neue Tabellenziele im vorhandenen Schema der Installationsdatenbank.
Kein DROP, Overwrite, Adoptieren oder Schema-CREATE. Ein zentraler
dreiteiliger Aufruf arbeitet ebenfalls in der Installationsdatenbank;
keine fremden Datenbanken als Quell-/Zielraum.

## Öffentliche Signatur und Ergebnis

```sql
@SourceSchema nvarchar(max)=NULL,
@SourceTable nvarchar(max)=NULL,
@TargetSchema nvarchar(max)=NULL,
@TargetTable nvarchar(max)=NULL,
@IncludeIdentity bit=0,
@IncludeExtendedProperties bit=0,
@TableMap sysname=NULL,
@ExternalReferenceRule varchar(16)='REJECT',
@ExpectedPlanHash varbinary(max)=NULL,
@ForeignKeyMode varchar(16)='CREATE',
@ResultTable sysname=NULL,
@KeepData bit=0,
@Debug tinyint=0,
@Hilfe bit=0
```

Die ersten acht Parameter übernehmen genau die V3-Semantik.
`@Hilfe=1` wird vor jeder Fach-, Transaktions-, Hash-, Dependency-,
Temp- oder Rechteprüfung behandelt: ausschließlich kanonisches Help,
keine Seiteneffekte oder Debug-Messages. Fachliche Pflichtparameter haben
deshalb technische NULL-Defaults. Im Fachmodus sind exakt 32 Bytes
`ExpectedPlanHash` erforderlich; `varbinary(max)` verhindert stille
Trunkierung überlanger Eingaben vor dieser Prüfung.

`ForeignKeyMode` ist byteexakt `CREATE` oder `DEFER`, ohne Padding,
Casefold oder NULL-Ersatz. Die Option wird vor Source innerhalb des
freigegebenen Executors konkretisiert; sie ändert keine Planner-Signatur.

Das eine Erfolgsresult hat genau drei NOT-NULL-Spalten:

| Spalte | SQL-Typ | Bedeutung |
|---|---|---|
| PlanHash | varbinary(32) | Vollständiger Hash einschließlich Modus |
| TablesCreated | int | Tatsächlich neu angelegte Tabellen |
| StatementsExecuted | int | Tatsächlich ausgeführte fachliche Planschritte |

Die sieben `SESSION_OPTION`-Zeilen zählen nicht als fachliche DDL-Schritte.
In `DEFER` zählen die ausgelassenen FK-Zeilen ebenfalls nicht.
Bei gesetztem `ResultTable` erfolgt die abschließende Veröffentlichung
über den bestehenden kanonischen Helper mit expliziter Spaltenliste und
Standard-Replace-/Append-Semantik, ohne zusätzliches SELECT. Kein
verschachteltes `INSERT ... EXEC` oder Zwischenresultset.

## Mapping und zwei feste ResultTable-Brücken

Im Mapmodus gilt die bestehende fünfspaltige lokale V3-Map: MapOrdinal int
und vier nvarchar(max)-Identifier, alle NOT NULL, keine Alias-/Computedtypen,
1..64 Zeilen, positive eindeutige Ordinals mit erlaubten Lücken. Quellen
sind nach tatsächlicher Objekt-ID, Ziele nach Schema-ID und
`DATABASE_DEFAULT` eindeutig. Die Map wird einmal kontrolliert in einen
eigenen Snapshot kopiert. Caller hält sie während dieser Kopie stabil;
danach weder Inputread noch Inputwrite. Im Einzelmodus wird für Hash und
Snapshot eine synthetische Zeile mit MapOrdinal 1 verwendet, der Planner
wird weiterhin im V3-Einzelmodus aufgerufen.

Technische Codex-Entscheidung innerhalb des freigegebenen Scopes:
ausschließlich `#TableCloneExecute_MapStage` und
`#TableCloneExecute_PlanStage` sind feste eigene Brücken für den statischen
Planner-Aufruf über die bestehende ResultTable-Interoperabilität. Der
Corehelper lehnt `#tbx_` als öffentliches Ziel ab; er wird nicht verändert.
Dies ist eine enge Namingausnahme, keine allgemeine Tempnamensfreigabe.
Andere interne Arbeitsobjekte behalten den reservierten `#tbx_`-Präfix.

Vor CREATE beide Brückennamen auf vorhandene Tempobjekte prüfen, auch bei
abweichendem Schema. Caller-Map und Caller-ResultTable dürfen keinen dieser
Namen verwenden und nicht dieselbe Objekt-ID haben. Keine Adoption oder
Löschung fremder Temps; eigene Brücken enden im eigenen Procedure-Scope.
Diese Ausnahme ist im kanonischen
[Namingstandard](../Standards/SQL_OBJECT_NAMING.md) und der Ergänzung zu
[DEC-2026-017](DECISIONS.md) eng verankert.

## Vollständiger Plan und FK-Aufschub

Die kanonischen ObjectKind-Werte sind `SESSION_OPTION`, `TABLE`, `DEFAULT`,
`CHECK`, `PRIMARY_KEY`, `UNIQUE_CONSTRAINT`, `INDEX`, `EXTENDED_PROPERTY`,
`FOREIGN_KEY` und `FOREIGN_KEY_STATE`. Unbekannte Kinds blockieren.
Ordinals und vier Planfelder bleiben vollständig und unverändert.

`CREATE` führt sämtliche fachlichen Planzeilen aus. `DEFER` lässt
ausschließlich `FOREIGN_KEY` und `FOREIGN_KEY_STATE` aus; Tabellen,
Referenzschlüssel, Checks, Defaults, Indizes und Properties bleiben im
gleichen Plan und werden unverändert ausgeführt. Auch ausgelassene FK-Zeilen
werden vollständig validiert und gehasht. Keine Änderung von Fremdobjekten
und keine Deaktivierung bestehender Constraints.

Damit kann eine spätere separat implementierte Copy-USP leere Ziele
befüllen und die vorgesehenen FKs kontrolliert aus geprüftem Katalog
anlegen. Der Executor selbst kopiert keine Daten und führt keinen
nachgelagerten Copy-Schritt aus. Kein weiterer Dispatcher oder persistenter
Plan-Token. Caller muss die späteren Copy-/FK-Voraussetzungen erneut erfüllen.

Limits unverändert: Map64, 1024 Spalten und 128 Indexmetadaten je Tabelle;
global2048 zählt distinct sys.objects mit parent_object_id in Mapquellen
plus distinct sys.foreign_key_columns-Tupel mit FK-Owner in diesen Quellen.
FK-Objekte werden nicht doppelt gezählt. Gewöhnliche columns, indexes,
index_columns und EP zählen nicht global2048. Insgesamt höchstens 2097152
UTF16-Scriptbytes inklusive SET-/EP-/FK-Statezeilen. Keine neue CPU-, RAM-
oder Wallclockgarantie aus diesen Grenzen.

## Hashlayout, Version 1

Alle Verkettungen beginnen mit `varbinary(max)`, damit keine 8000-Byte-
Trunkierung entsteht. `||` bedeutet Byteverkettung. SHA256 liefert 32 Bytes.

- `I32(x)` ist `CONVERT(binary(4), x)` für einen nichtnegativen SQL-int;
  Darstellung Big-Endian, keine Dezimaltextdarstellung.
- `U(s)` sind die rohen UTF16LE-Bytes des nvarchar-Wertes ohne BOM.
- `F(s) = I32(DATALENGTH(s)) || U(s)`. Die Länge zählt Bytes.
- Bits sind je exakt ein Byte: `0x00` oder `0x01`.
- Alle gehashten Identifier/Planfelder sind vorher validiert und NOT NULL.
  Keine Normalisierung, Trim, Casefold, Collation-/Paddinggleichsetzung,
  Unicode- oder LF/CRLF-Umschreibung.

Map-/Planordinals bleiben positiv. Feldlänge 0 ist durch das Framing
darstellbar und wird nicht mit NULL verwechselt.

Der Header verwendet folgende feste Reihenfolge:

```text
H0 = SHA256(
  F(N'Toolbelt.TableClone.Execute.Hash') || I32(1) || F(N'4.0.0') ||
  I32(InstallDB_ID) || F(InstallDB_NAME) ||
  Bit(IncludeIdentity) || Bit(IncludeExtendedProperties) || Bit(MapMode) ||
  F(ExternalReferenceRule als nvarchar) || F(ForeignKeyMode als nvarchar) ||
  I32(MapCount) ||
  [I32(MapOrdinal) || F(SourceSchema) || F(SourceTable) ||
   F(TargetSchema) || F(TargetTable)] je Zeile aufsteigend nach MapOrdinal
)
```

MapMode=0 bindet die synthetische Einzelzeile mit Ordinal 1 und die vier
originalen validierten Identifier. MapMode=1 bindet die originalen Ordinals
einschließlich Lücken. Namen werden nicht durch katalogkanonische Schreibweise
ersetzt. InstallDB_ID/NAME kommen aus dem Installationskontext, auch bei
zentralem dreiteiligem Aufruf. Tempnamen und Standardtail sind kein Hashinput.
Das Releasefeld ist die Modulversionsbindung, keine getrennte
Executorvertragsversion. Im historischen Modul3.1 war es entsprechend3.1.0.

Für jede Planzeile, strikt aufsteigend nach positiver lückenloser Ordinal:

```text
Hi = SHA256(H(i-1) || I32(PlanOrdinal) ||
            F(ObjectKind als nvarchar) || F(TargetName) || F(ScriptText))
PlanHash = SHA256(Hn || I32(PlanRowCount) ||
                  F(N'Toolbelt.TableClone.Execute.Final'))
```

Alle vollständigen Planzeilen werden eingebunden, einschließlich SET und
in DEFER ausgelassener FKs. Der Modus im Header verhindert Mehrdeutigkeit.
Das Layout wird mit Client-/SQL-Beispiel dokumentiert; zwei unabhängige
Byteableitungen gehören zur späteren fokussierten Qualifikation, hier
kein behaupteter Hashimplementierungs-PASS. Der Hash ist weder Rechtebeleg
noch garantiert er unveränderte externe Katalogbedingungen.

## Transaktion, SET und Fehlererhalt

Aktiven Caller-TX vor Facharbeit und Tempwrites ablehnen. Ausschließlich
dieser frühe Ablehnungszweig setzt `XACT_ABORT` im Prozedurscope auf OFF,
damit Fehler 50000 die vorhandene Caller-Transaktion nicht doomt. Beim
Verlassen der Prozedur wird die vorherige Caller-Option wiederhergestellt;
Transaktionszähler, Commitfähigkeit und SET-Erhalt sind separat nachzuweisen.
Vollständige Planung, Hashvergleich und Sicherheitsprüfung erfolgen vor
eigener Ziel-DDL. Eine eigene begrenzte TX umfasst nur neue Ziel-DDL und
abschließendes ResultTable-Prepare/Insert. Letzteres muss vor dem Commit
erfolgen, damit ein später ResultTable-Fehler auch Ziel-DDL zurückrollt.
Erfolgsausgabe erst nach Commit; Netzwerkfehler danach bedeuten keine
nachträgliche SQL-Rollbackzusage.

Jeder fachliche DDL-Schritt erhält alle sieben kanonischen SET-Optionen
im selben dynamischen Batch. SESSION_OPTION-Zeilen nicht als getrennte
dynamische SET-Aufrufe ausführen. Nur EXTENDED_PROPERTY darf den vorhandenen
begrenzten typisierten DECLARE-plus-EXEC-Batch verwenden. Caller-SETs nach
Return unverändert, auch bei Fehler. Keine frei zusammengesetzten Mehrfach-
Scripts, EXECUTE AS, GRANT oder Owneränderung.

Engine-/Plannerfehler behalten ihre ursprüngliche Ursache; eigener Rollback
und SET-/Tempcleanup dürfen den Primärfehler nicht ersetzen. Cleanupfehler
getrennt sichtbar machen. Keine Teil-Erfolgszeile bei fehlgeschlagener TX.

## Rechte und DDL-Seiteneffektgate

Bestehende V3-Sicht-/Dependencyrechte plus aktuelle CREATE TABLE-, Schema-
ALTER- und für FKs REFERENCES-Rechte erforderlich; keine Rechteerteilung.
DEFAULT-/CHECK-Ausführungspfade wie Computed vollständig sichtbar
klassifizieren. UDF, CLR, Sequenzen und externe, unresolved oder
callerabhängige Ausführung ablehnen; Planner-Vorschau bleibt unverändert.

Die ausdrücklich bestätigte zusätzliche Grenze verlangt vorhandenes
`VIEW ANY DEFINITION` auf SERVER und lesbare DB-/Server-DDL-Trigger- sowie
Eventnotification-Kataloge. Fehlende, NULL oder unklare Sicht stoppt
payloadfrei vor DDL. Relevante aktive DB-/Server-DDL-Trigger und
Eventnotifications blockieren; nichts deaktivieren. Prüfung vor Mutation
und erneut innerhalb eigener TX unmittelbar vor DDL. Keine externen
Effekte in die Rollbackzusage einschließen. Eventnotifications sind nicht
rollbackfähig. Keine Konfigurationsänderung oder Ownerreparatur.

Toolbelt-AppLock koordiniert Toolbelt-Aufrufe, sperrt keine fremde DDL.
Caller muss Quell-, Ziel- und Serverbedingungen während des Aufrufs stabil
halten; keine allgemeine Drift- oder globale Nebenwirkungsfreiheit behaupten.

## Lifecycle und fokussierter Nachweis

Release 3.1 ergänzt genau den Executor-P-Slot. Bekannte genuine Releases
1/2/3 und Ziel3.1 werden explizit im bestehenden Lifecycle erfasst.
Unbekannte Versionen, Zukunftsslots und katalogäquivalente fremde Aliase
blockieren. Vor Mutation und unter AppLock vollständige Sicht sowie resolved
und unresolved sameDB Consumer nach bestehendem katalogäquivalentem Vertrag
prüfen. Keine implizite Änderung an Planner- oder ResultTable-Verträgen.

Nach unabhängiger Sourceprüfung fokussiert prüfen: Help/Shape/Hash/Modus,
Mapping und neue Ziele, Mismatch ohne Zielmutation, CREATE/DEFER mit Self-/
zyklischen FKs, Caller-TX/SET-Erhalt, später ResultTable-Fehlerrollback,
DEFAULT-/CHECK-Unsupported, tatsächliche Vollsicht-/DDL-Seiteneffektblocker,
Lifecycle und eigene Bereinigung. Vorhandene bytegleiche Planner-Nachweise
reusebar, keine unveränderte Vollmatrix erneut laufen lassen.
Am 2026-10-04 bestanden die gezielten lokalen Nachweise auf den
schema-validierten Zielen Linux2019/latest CL150 und Windows2025/exakt CU8
CL170. Beide neuen Runtime-Fixtures liefen je Ziel einmal im erfolgreichen
Clean3.1-Zyklus; der genuine3→3.1-Zyklus wiederholte sie nicht. Unabhängiger
Client-Hash, genaue dreispaltige Resultmetadata/NOT-NULL/32-Byte-Binary/EOF,
resolved Consumer, Uninstall/Repeat und eigene Bereinigung bestanden.
Der Caller-Gate-Fix wurde mit gesundem Ausgangszustand, Fehler50000,
erhaltener Commitfähigkeit und ursprünglichen SET-Optionen geprüft.
Vorherige fehlgeschlagene Läufe gelten nicht als Gesamt-PASS.
Head-CI ist ein separater PR-Nachweis. Serverweite negative Trigger-/
Eventnotification-Fixtures, tatsächliche Minimalrechte, zusätzliche native
Ziele/CL und zentrale Executor-Nutzung bleiben nicht ausgeführt;
keine Release- oder vollständige Produktqualifikation.

## Gekoppelte Quellen

- [Einzelfreigaben und Zusatzentscheidungen](../../.ai/BACKLOG.md)
- [V3-Planvertrag](TABLE_CLONE_WAVE2_CONTRACT.md)
- [USP-Vertrag](../Standards/USP_CONTRACT.md)
- [ResultTable-Vertrag](RESULT_TABLE_MODULE_DESIGN.md)
- [Microsoft: DDL Events](https://learn.microsoft.com/en-us/sql/relational-databases/triggers/ddl-events?view=sql-server-ver17)
- [Microsoft: sys.server_triggers](https://learn.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-server-triggers-transact-sql?view=sql-server-ver17)
- [Microsoft: sys.server_event_notifications](https://learn.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-server-event-notifications-transact-sql?view=sql-server-ver17)
- [Microsoft: Event Notifications](https://learn.microsoft.com/en-us/sql/relational-databases/service-broker/event-notifications?view=sql-server-ver17)

Source, Manifest, RepoMap und Objektdokumentation sind gekoppelt;
dieser Dokumentationsstand ersetzt keine unabhängige Prüfung oder aktuelle CI.
