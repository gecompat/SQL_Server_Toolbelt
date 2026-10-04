# Table Clone Data Copy / 4.1.0

Stand 2026-10-04, Codex. Die einzelne `USP_CopyTableCloneData` und die
zusätzlichen Grenzen wurden mit dem Benutzer besprochen und ausdrücklich
freigegeben; der Entscheidungsnachweis steht in [.ai/BACKLOG.md](../../.ai/BACKLOG.md).
Dieser Vertrag konkretisiert die genehmigte Umsetzung. Source, Testcode und
Review sind keine Laufzeitqualifikation. Datenkopie 4.1 ist im unten genannten
normalen Scope teilweise geprüft und unveröffentlicht; historische Planner-/
Executor-Nachweise bleiben getrennt. Keine neue Provider-, Installations- oder
öffentliche FK-Helper-API.

## Öffentliche Schnittstelle

```sql
@TableMap sysname = NULL,
@IdentityMode varchar(16) = NULL,
@ConsistencyMode varchar(16) = NULL,
@RowLimit bigint = 100000,
@PayloadByteLimit bigint = 16777216,
@ResultTable sysname = NULL,
@KeepData bit = 0,
@Debug tinyint = 0,
@Hilfe bit = 0
```

TableMap, IdentityMode und ConsistencyMode sind fachlich erforderlich; technische
NULL-Defaults ermöglichen reine Hilfe. Moduswerte gelten byteexakt einschließlich
Länge: KEEP/REGENERATE und SNAPSHOT/SERIALIZABLE. Limits sind positiv, nicht NULL
und nur absenkbar. Hilfe hat Vorrang vor fachlichen, Rechte-, Transaktions- und
Tempprüfungen. Der [USP-Vertrag](../Standards/USP_CONTRACT.md) bleibt verbindlich.

Erfolg liefert genau eine Zeile, alle fünf Felder NOT NULL:

| Position | Feld | Typ | Bedeutung |
|---|---|---|---|
| 1 | MappedTables | int | Anzahl validierter Maps |
| 2 | CopiedRows | bigint | Tatsächlich eingefügte Gesamtzeilen |
| 3 | PayloadBytes | bigint | Transportierte logische SQL-Nutzdatenbytes |
| 4 | CreatedForeignKeys | int | Tatsächlich neu angelegte fehlende FKs |
| 5 | Status | varchar(16) | Exakt COPIED |

Leere Quellen sind erfolgreicher Copy mit null Zeilen/Bytes. ResultTable verwendet
den vorhandenen Helper und eine eigene Referenzform; kein INSERT EXEC. Bei
ResultTable gibt es kein fachliches SELECT. Debug liefert nur Messages.

## Map und kompatible Tabellen

Eine bestehende lokale Temp-Tabelle mit den fünf bekannten NOT-NULL-Spalten
MapOrdinal int und SourceSchema/SourceTable/TargetSchema/TargetTable nvarchar(max).
Der Snapshot enthält 1..64 Zeilen, positive eindeutige Ordinals, Lücken erlaubt.
Höchstens 65 Kandidaten werden zur Budgetprüfung aufgenommen; Namen werden vor
Verkürzung auf 1..128 UTF16-Einheiten geprüft. Kein Trim oder NUL-Identifier.
Quellen und Ziele sind tatsächliche normale Tabellen derselben Installations-DB;
ihre ObjectIDs sind jeweils eindeutig und zwischen beiden Mengen disjunkt.
Dreiteiliger Aufruf verschiebt die Objektauflösung nicht in die Caller-DB.
Map und ResultTable müssen unterschiedliche Temp-ObjectIDs haben. Fremde belegte
interne Copy-/Core-Temps werden vor Corekompilierung abgewiesen, nicht adoptiert.

Spalten stimmen nach ihrer column_id-geordneten Position, byteexaktem Namen,
System-/Usertyp, Länge, Precision, Scale, Nullability und exakter Collation
einschließlich NULL überein. Numerische column_id-Lücken müssen nicht gleich
sein. Computed-Definition/PERSISTED, Identity-Seed/Increment/NOT FOR REPLICATION,
ANSI_PADDING und XML-Collection-/Documentform werden ebenfalls gebunden.
Identity-last_value gehört nicht zur Formgleichheit. Gewöhnliche native XML-,
typisierte XML- und text/ntext/image-Werte werden ohne Textserialisierung kopiert.
Computed und rowversion entstehen durch die Engine und werden nicht eingefügt.

Nicht unterstützt: Views/Synonyme/CrossDB-Quellen, freie Filter, Merge/Upsert,
Memory-optimized, Temporal, Ledger, Graph, Filetable, externe/Systemtabellen,
Replikation/CDC, versteckte/generated/verschlüsselte/CLR-/Alias-/Sparse-/
Columnset-/masked-/rowguidcol-/Filestreamspalten, gebundene Rules/Legacydefaults
oder RLS-Predicates, auch deaktivierte. Keine stillschweigende Konvertierung.

## Konsistenz, Budget und Rollback

Eine aktive Callertransaktion wird nichtdoomend vor Facharbeit abgewiesen.
Die eigene Transaktion umfasst Daten, neue FK-DDL und spätes ResultTable-Routing.
SNAPSHOT benötigt bereits aktiviertes ALLOW_SNAPSHOT_ISOLATION; die öffentliche
Funktion konfiguriert nichts. SERIALIZABLE hält Quellsperren bis Ende. Alle
Quell-/Ziel-Locks werden in fester ObjectID-Reihenfolge erworben. Targets müssen
auch unter SNAPSHOT durch einen aktuellen sperrenden Read leer sein und bleiben
bis Commit exklusiv geschützt; ein versionierter Leerheitsread genügt nicht.
Metadataform, Identitäten und Seiteneffektgates werden erneut geprüft. Kein
Driftversprechen gegen beliebige fremde DDL oder externe Atomikzusage.

Vor erstem Insert gelten global maximal 100000 COUNT_BIG-Zeilen und 16777216
Nutzdatenbytes. Payload ist die bigint-Summe von DATALENGTH tatsächlich
transportierter Spalten; NULL zählt 0, ausgelassene Identity/computed/rowversion
zählen nicht. Keine Netzwerk-/Log-/Index-/Heap-/CPU-/Wallclockgarantie. Tatsächliche
Insertcounts müssen Sourcecounts entsprechen, auch bei IGNORE_DUP_KEY.

KEEP kopiert Identitywerte mit vorhandenen ALTER-Rechten; ON/INSERT/OFF befinden
sich im selben dynamischen Batch innerhalb des eigenen USP-Scopes. Ein fremder
Identityzustand wird nicht durch ein pauschales OFF repariert. REGENERATE lässt
Identity aus und ist bei identityabhängigen FK-Beziehungen ausgeschlossen;
keine neue ID-Zuordnung oder Reihenfolge wird zugesagt. Bei null Transportspalten
gilt ausschließlich ein durch den vorab geprüften RowLimit begrenzter DEFAULT
VALUES-Pfad. Normale Tabellen verwenden ein mengenbasiertes INSERT je Tabelle.
Fehler rollen eigene SQL-Writes zurück; Identity-Zählerfortschritt kann bleiben,
kein RESEED. Originalfehler bleiben erhalten; sekundäre Cleanupfehler separat.

## FK und vorhandene Rechte

Alle ausgehenden Source-FKs müssen innerhalb der Map liegen. Eingehende externe
FKs werden nicht geändert. Bestehende Target-FKs müssen exakt dem semantischen
Tupel aus Parent/Referenzziel, geordneten Spalten, Aktionen, NOT FOR REPLICATION
und Zustand entsprechen; passende bleiben unverändert, zusätzliche, abweichende
oder mehrdeutige Beziehungen blockieren. Aktivierte Beziehungen zwischen
unterschiedlichen Targets bestimmen die Insertreihenfolge; ein vorhandener
aktiver Zyklus blockiert. Self-FKs sind davon ausgenommen und werden durch ein
einziges Bulk-INSERT geprüft. Keine heimliche Constraint-Deaktivierung.

Fehlende FKs werden nach allen Inserts durch die einmalige kanonische interne
FK-Herleitung angelegt. Vollständig aufgeschobene Zyklen sind damit möglich.
Bekannte Zustände checked/trusted, enabled/untrusted und disabled/untrusted
bleiben erhalten; disabled/trusted wird abgewiesen. Targettrigger fehlen oder
sind deaktiviert; vorhandene deaktivierte Trigger bleiben unverändert.
DEFAULT/CHECK/computed-Pfade werden als tabellenlokal klassifiziert; UDF/CLR/
Sequenzen, externe, unaufgelöste oder callerabhängige Ausführung blockieren.

Immer erforderlich: vorhandene datenbankweite VIEW DEFINITION und SELECT auf
sys.sql_expression_dependencies, sys.security_predicates und sys.security_policies,
sowie Source-SELECT und Target-SELECT/INSERT. Fehlende/unklare Sicht blockiert.
Nur bei tatsächlich fehlenden FKs gelten zusätzlich vorhandene vollständige
Server-DDL-Sicht, lesbare Trigger-/Eventnotification-Kataloge sowie erforderliche
ALTER-/REFERENCES-Rechte. Relevante oder unbekannte DDL-Seiteneffekte blockieren.
Das Gate wird vor Writes und unmittelbar vor DDL nach erneutem identischem
FK-Plan geprüft. Keine GRANTs, Ownerwechsel, Sicherheitsrelaxierung oder Parser-
Installation; der Copy-Pfad benötigt keinen Triggerparser.

## Interne Kopplung und Lifecycle

Release 4.1 führt vier P-Slots: PublicPlanner13, interner Core14, Executor14,
Copy9. PublicPlanner erzwingt PREVIEW. Der interne varchar(16)-Parameter
InternalPurpose an Position10 hat Default PREVIEW; COPY_FK ist ausschließlich
der interne Map-/FK-Pfad mit eigener gesunder Caller-TX, REJECT und ausgeschalteten
Trigger-/Property-Includes. Kein weiterer öffentlicher Helper. Gemeinsame FK-
Ableitung/Renderer existieren einmal. Planhash bindet Release4.1; die bereits
installierte 4.0-Historie bleibt 13/13/14 mit drei Slots. Uninstall entfernt
keine fachlichen Quell-/Zieltabellen und wahrt fremde Consumers.

## Fehler und gezielte Qualifikation

53940 ist Input/Map/Tempform, 53941 Sicht/Rechte/Tabellen-/Spaltenform,
53942 Seiteneffektpfad, 53943 globales Zeilen-/Bytebudget, 53944 FK-/Insert-/
Planintegrität, 53946 Application-Lock-Verfügbarkeit. 53945 bleibt reserviert;
fehlendes aktiviertes SNAPSHOT wird mit 53941/2 abgewiesen.
53920..53929 bleiben Lifecycle; bestehende Core-/Helper- und Enginefehler bleiben
erhalten. Caller-TX nutzt RAISERROR/RETURN mit TBX_TABLE_CLONE_COPY_CALLER_TRANSACTION.

Fünf zusammenhängende Fixturegruppen prüfen Formlücken/KEEP/Bytes/existingFK,
Self-FK und verbotene REGENERATE-Beziehung, Identity-only und gewöhnliche
REGENERATE-Kopie, fehlende zyklische FK-Zustände sowie atomare Safety-/Budget-/
späte ResultTablefehler. Gekoppelt: Help, neun Parameter/fünf Clientfelder, Caller-
und Sessionzustand, echte 4.0→4.1-Migration, Lifecycle und eigene Bereinigung.
Zusätzlich werden der tatsächliche dynamische Identity-Scope und aktuelle
SNAPSHOT-Leerheit/Konkurrenz gezielt geprüft. Historischer statischer Identity-
Zeuge ist kein Nachweis dieser dynamischen Ausführung. Keine unveränderte
vollständige Parser-, CL-, Versions- oder Heapmatrix.

Stand 2026-10-04: Die fünf Gruppen bestanden auf SQL Server 2019 Linux/latest
CL150 und SQL Server 2025 Windows/exakt CU8 CL170 jeweils einmal im Cleanzyklus.
Clean/Repeat, genuine4.0→4.1 mit frischer Session, vier resolved-Consumer-
Ablehnungen53926/1, Uninstall/Repeat und die typgenaue fünffeldrige Clientausgabe
mit NOT NULL/EOF/keinem Folgeresult bestanden. Je zwei eigene Datenbanken wurden
entfernt; Prozesskanäle, Inputpins, Journale und frischer Cleanup-Audit wurden
unabhängig physisch geprüft. Keine Serverkonfigurations-, Rechte-, Owner- oder
Truständerungen. Der erste fehlgeschlagene Linuxlauf ist kein PASS; sein
Helper-Namenskonflikt wurde korrigiert und der betroffene Scope wiederholt.
Zusätzlich bestanden auf demselben Linux2019/latest-CL150-Ziel vier dynamische
Identity-Fälle: KEEP bei ursprünglichem OFF, spätes CHECK547 mit Rollback,
vorbestehendes Target-ON und vorbestehendes Other-ON mit Original8107. Direkte
INSERT-Proben belegen den vorherigen und nachherigen Zustand in derselben
Verbindung; Transaktions- und SET-Zustand sowie typgenauer Reader geprüft.
SNAPSHOT-Quellkonsistenz und bis zum Abschluss gehaltene Targetsperren wurden
durch beobachtete Sperrbeziehungen und konkurrierende Writes nachgewiesen.
Der separat ausgeführte Nichtleer-Fall beobachtete die tatsächliche Blockierung,
anschließend Original53944/1, gesunde Session und erhaltene Targets.

Identity und positiver SNAPSHOT-Fall stammen als abgeschlossene Teilnachweise
aus insgesamt fehlgeschlagenen Adapterläufen. Unveränderte Produktbytes wurden
geprüft und diese Fälle nicht wiederholt. Testadapterfehler266, fehlender
Nichtleer-Rendezvous und anschließender Cleanupfehler3701 zählen nicht als PASS.
Der abschließende isolierte Nichtleer-Lauf bestand vollständig. SNAPSHOT wurde
nur in den jeweils eigenen synthetischen Datenbanken vorbereitet, privat
journalisiert, wiederhergestellt und die Datenbanken entfernt; frische
Bereinigung, Prozesskanäle und Pins unabhängig physisch geprüft.
Head-CI wird getrennt im Pull Request nachgewiesen. Keine vollständige
Produktqualifikation; weitere Ziele/CL, zentrale Nutzung, tatsächliche
Minimalrechte und große Nutzdaten-/Heapmatrix bleiben nicht ausgeführt.
