# Table Clone Trigger-Scriptklon / 4.0.0

Stand 2026-10-04, Codex. Die Funktion wurde am 2026-10-01 einzeln
freigegeben; am 2026-10-04 bestätigte der Benutzer Parameterposition,
Major-Version und das konkrete Triggernamenslayout. Dieser Vor-Source-Vertrag
konkretisiert diese Freigabe im bestehenden Modul
`toolbelt.metadata.table-clone`. Source und begrenzte Fixtures sind vorhanden;
unabhängige Coreprüfung, Statik und offline Syntaxprüfung bestanden. Neue
Runtimequalifikation ist im unten genannten begrenzten Scope bestanden. Historische Planner- oder Parsernachweise
sind keine Trigger-Rewriting-Qualifikation. RelatedReference: `TC-2026-044`.

## ScriptDom-Dependency-Nachtrag 2026-10-07

Der Benutzer hat den Wechsel des separaten ScriptParser-2.0.0-Providers auf
ScriptDom 18.0.117.0 ausdrücklich ausgewählt und die Prüfung aller betroffenen
CLR-Consumer beauftragt. Das Trigger-Opt-in akzeptiert deshalb ausschließlich
das neue Parser-/ScriptDom-Binary-Paar:

- Parser-Provider SHA-512: `E03C6099E2E919F3F930E2CCB5A753C47F16DABFC18B608F8BC33DEA5E93ED10D9A937CF599427FADED4EBBB11653E80D2C8BA23C49E5AAEEB0A80C60D51EDBF`
- ScriptDom FileVersion `18.0.117.0`, SHA-512: `459E137268A4CA378023CD7E68A04655CEC2C19A8D01546E81B1A7ABF1FE2F9226A03CC3FA2323081C3C1B05626AF988C98527711D577919CF409367F853DAC7`

Das historische, am 2026-10-04 ausgeführte Paar war Parser-Provider
SHA-512 `7592A3C2535F43F6B4D0CF491BC3E7A20F2B2B8712C861D1E33BE428971860CD9E2401A67B6E5E2F0853BBF453D9C20DA9C838B070C428BD796D05F86C7A0C42`
mit ScriptDom SHA-512
`24BDEE1CC5296488C3609BB6911DD76935B510F823CAAE4D39E8C45C84D272F3D28E3F6156E1E185C0F81D5812C9100E9C71CBE788966AC477A5B213BCE672D0`.

Die Trigger-Runtime-Evidenz vom 2026-10-04 gilt nur für das damals
installierte Parser-/ScriptDom-Paar und qualifiziert das neue Paar nicht.
Die SQL-Signatur und das Verhalten von `IncludeTriggers=0` ändern sich nicht;
die erneute Windows-Triggerqualifikation mit dem neuen Paar bleibt offen.
Trust bleibt ein separater Administrationsschritt.

## API, Plattform und unveränderte Ausführungsgrenze

Beide vorhandenen Planner-Prozeduren erhalten `@IncludeTriggers bit=0` an
Position 9; der Standardtail ResultTable/KeepData/Debug/Hilfe steht an
Position 10..13. Die ersten acht Parameter bleiben gleich. Positionale
Tailaufrufe müssen angepasst werden. Help bleibt vor allen Gates;
IncludeTriggers darf im Fachmodus nicht NULL sein. Keine neue öffentliche
Prozedur, kein frei gelieferter SQL-Text und keine Ausführung des Plans.

Option 0 bewahrt die bestehende Triggerablehnung und Windows-/Linux-Nutzung.
Sie ruft keinen Parser auf und verlangt keine Parserinstallation. Option 1
ist Windows-only und benötigt die vorhandenen vier registrierten TVFs des
separat installierten Parsers 2.0.0 in derselben Installationsdatenbank:
Nodes, NodeProperties, Tokens und Errors. Vor Parseraufrufen müssen die
bekannten Modul-/Objektmarker, Signaturen und CLR-Bindings sowie die exakten
Provider-/Dependency-Binaryhashes zum bestehenden Parservertrag passen.
Kein neuer Provider, keine automatische Installation, Trustregistrierung,
Rechteerteilung oder Konfigurationsänderung. Nicht registrierte
experimentelle Resolver werden nicht übernommen.

Erwartungsquelle ist das bereits qualifizierte Parser-2.0-Releaseartefakt,
nicht ein behaupteter SourceHash-Marker oder die bloße Trustregistrierung.
Provider-SHA512:

```text
E03C6099E2E919F3F930E2CCB5A753C47F16DABFC18B608F8BC33DEA5E93ED10D9A937CF599427FADED4EBBB11653E80D2C8BA23C49E5AAEEB0A80C60D51EDBF
```

ScriptDom-SHA512 ist der bestehende Pin des Parservertrags:

```text
459E137268A4CA378023CD7E68A04655CEC2C19A8D01546E81B1A7ABF1FE2F9226A03CC3FA2323081C3C1B05626AF988C98527711D577919CF409367F853DAC7
```

Beide installierten Binaries werden selbständig über den vollständigen
Inhalt von sys.assembly_files mit file_id=1 gehasht. Vorhandenes
datenbankweites VIEW DEFINITION, vollständige Assembly-/Binding-Sicht und
SELECT auf alle vier TVFs sind Pflicht; fehlende oder unklare Sicht blockiert.
Keine Annahme eines nicht gesetzten Assembly-Version-/SourceHash-Markers.

Das Plattformgate liest nur intern @@VERSION: der bekannte BIN2-Abschnitt
` on Windows ` muss vorhanden und ` on Linux ` abwesend sein; fehlende oder
unklare Form blockiert. Unterstützte Major-Version15/16/17 und exakte
UNSAFE-Bindung separat prüfen. Keine serverweite DMV-Rechtepflicht allein
für die Plattformfeststellung, keine Ausgabe des Versiontexts.

Der Executor behält seine 14 Parameter und ruft den Planner mit benannten
Parametern und dem Default IncludeTriggers=0 auf. Er akzeptiert und führt
keine TRIGGER-Zeilen aus. Sein Hashlayout v1 bleibt gleich; im Modulrelease
4.0.0 bindet dessen Releasefeld `F(N'4.0.0')`. Clientbeispiel und
Hashfixtures müssen dieselbe Releasebindung verwenden. Kein Umdeuten der
bisherigen Releasebindung 3.1.0 in eine unabhängige Vertragsversion.

## Annahme, Bindung und Umschreibung

Nur gewöhnliche T-SQL-DML-Trigger auf gemappten diskbasierten Tabellen.
INSERT/UPDATE/DELETE, AFTER beziehungsweise INSTEAD OF, NOT FOR REPLICATION
und enabled/disabled bleiben erhalten. Verschlüsselte oder CLR-Trigger,
EXECUTE AS, nativekompilierte Spezialformen, dynamisches SQL im Body sowie
mehrdeutige, ungelöste, callerabhängige oder externe Referenzen blockieren.
Keine automatische Kopie von Funktionen oder Prozeduren. Nicht gemappte
Tabellenreferenzen im Triggerbody bleiben abgelehnt, auch bei FK-Regel KEEP.
Das ist keine Änderung der separaten FK-KEEP-Semantik.
Vollständig aufgelöste same-database T-SQL-Funktionsreferenzen dürfen als
Referenz unverändert bleiben; weder Funktionsbody noch deren Namen werden
kopiert oder umgeschrieben. CLR-, externe, ungelöste, callerabhängige oder
mehrdeutige Funktionsbindungen bleiben abgelehnt. EXEC im Triggerbody wird
konservativ vollständig abgelehnt, einschließlich fester Prozeduraufrufe.

Vor Umschreibung Errors prüfen; Nodes/Properties/Tokens müssen aus denselben
Argumenten stammen. Parser-Version passend zur ausdrücklich unterstützten
SQL-Version, QuotedIdentifiers aus `sys.sql_modules.uses_quoted_identifier`;
vorhandene Parserquoten unverändert. AST ist kein semantischer Binder:
Katalogdependencies und lokale Alias-/CTE-/Subquery-Scope-Auflösung müssen
die konkrete Bindung belegen. inserted/deleted und Tabellenvariablen nicht
als permanente Tabellen umschreiben. Auch Tabellenqualifier in
Spaltenreferenzen korrekt behandeln; ein geändertes FROM allein genügt nicht.
Fehlender oder unklarer Nachweis blockiert vor Ausgabeänderungen.

Ausschließlich belegte UTF16-Fragment-/Tokenspannen rückwärts ersetzen:
Headerverb CREATE/ALTER/CREATE OR ALTER wird CREATE, Triggername und ON-Ziel
werden auf den Klon gebunden, eindeutig gebundene Tabellenverweise auf ihr
Mappingziel. Kommentare und Stringliterale außerhalb ersetzter
Identifier-/Headerlexeme bleiben bytegleich. Nicht-SC-BIN2-Spannenoperationen
verwenden; Supplementaryzeichen dürfen Offsets nicht verschieben.
Überlappende Spannen ablehnen und das Ergebnis erneut parsen. Kein blindes
REPLACE, kein Prettyprint des gesamten Bodys und keine Namensheuristik als
Bindungsnachweis.

## Namen, Batches und Zustände

Triggername ist `TR_` plus 64 Großbuchstaben-Hexzeichen von SHA256 über
genau drei Frames für Zielschema, Zieltabelle und Originaltriggername.
`F(s)=I32(DATALENGTH(s)) || UTF16LE(s)` ohne BOM; I32 ist vier Byte
Big-Endian. Von Beginn an varbinary(max), keine Trunkierung, Normalisierung
oder zusätzliche Domainmarke. Fremde Zielnamen und geplante
Hashnamenskollisionen unter DATABASE_DEFAULT blockieren ohne Adoption.
Diese Benennung ist ausschließlich die genehmigte DML-Klonkonvention.

CREATE TRIGGER muss erster Statement seines eigenen Batches sein. Nur die
neue TRIGGER-Planzeile erhält dafür einen fest generierten begrenzten
SET-plus-sp_executesql-Batch: Quell-ANSI_NULLS und QUOTED_IDENTIFIER im
wirksamen äußeren Parse-/Ausführungsscope setzen, inneren Unicodepayload
mit CREATE TRIGGER beginnen lassen. Quotes des Payloads vollständig escapen.
Kein Caller-SQL-Batch und keine Zulassung dynamischen SQLs im Triggerbody.
Die bestehende typisierte EXTENDED_PROPERTY-Batchausnahme bleibt getrennt;
die neue Kapselung macht den Executor nicht triggerfähig.

Nach allen Trigger-CREATEs werden FIRST/LAST-Anordnungen für AFTER-Trigger
je tatsächlichem INSERT/UPDATE/DELETE-Ereignis quellengetreu durch feste
sp_settriggerorder-Planzeilen erhalten; keine erfundene Reihenfolge für
INSTEAD OF. Danach erforderliche DISABLE-TRIGGER-Zeilen. ObjectKind ist
TRIGGER für CREATE und TRIGGER_STATE für Order-/Disabledzustand.
Sortierung nach MapOrdinal, Originaltriggername BIN2 mit Bytetie und dann
fester Ereignisreihenfolge INSERT/UPDATE/DELETE. Zustandsschritte dürfen
ausschließlich die eigenen generierten Triggernamen adressieren.

## Vollständigkeit, Ressourcen und Fehler

Die bisherige vierfältige NOT-NULL-Ergebnisform bleibt unverändert.
Sämtliche Trigger, Namen, Bindungen und Zustände werden vor Veröffentlichung
des vollständigen Plans geprüft. ResultTable wird erst danach über den
kanonischen Helper geschrieben; bisherige Transaktions-/Savepointgrenze
bleibt erhalten. Trigger-Properties dürfen nicht still verloren gehen:
nicht unterstützte Trigger-Properties sichtbar ablehnen.

Bestehende Limits bleiben: Map64, Spalten1024 und Indexmetadaten128 je
Tabelle; global2048 zählt genau distinct sys.objects mit parent_object_id
in den eindeutigen Mapquellen plus distinct sys.foreign_key_columns-Tupel
mit FK-Owner in diesen Quellen. Trigger sind bereits im ersten Summanden,
keine Kindfilterung oder zusätzliche Doppelzählung. Insgesamt 2097152 UTF16-Scriptbytes zählen
den tatsächlich escapierten Wrapper und alle Zustandszeilen mit.
Keine neue Laufzeit-/Heapgarantie, kein Quotenausweichpfad.

Bestehende Fehlerkategorien 53900..53909 und ursprüngliche Enginefehler
bleiben erhalten. Neue Fehlerzustände sind gekoppelt:

| Fehler/State | Bedeutung |
|---|---|
| 53900/10 | NULL-Triggeroption im Fachmodus |
| 53907/2..6 | Plattform; Katalogsicht; Binary-/Modulmarker; TVF-Binding/SELECT/Owner; Parameter-/Ausgabeschema |
| 53903/15..18 | Spezial-/verschlüsselter Trigger; Dependency; Form/EXEC; Header-/ON-Bindung |
| 53903/19..22 | AST-Namespace/Range; permanente Tabellenbindung; Spaltenqualifier; Ereignisbindung |
| 53904/2 | Bestehender oder geplanter schemaweiter Triggernamenskonflikt |
| 53905/3..6 | Quellsyntax; inkonsistente AST-/Token-/Identifierform; Spannenüberlappung; Syntax nach Rewrite |

Nicht unterstützte Trigger-Properties verwenden weiterhin53903/10;
Scriptbyteüberschreitungen53906/1 beziehungsweise/2. Keine Teil-Erfolgszeile.

## Lifecycle und kleinster Nachweis

Bekannte historische Releaseobjektmanifeste 1/2/3/3.1 und neue Version 4.0
explizit erfassen; weiterhin drei Modulslots einschließlich unverändertem
14-Parameter-Executor. Der bestehende Lifecycle prüft Release, Objekttyp,
Ownership-/Versionsmarker und Consumer vor Mutation und unter AppLock;
lokale Änderungen an eindeutig eigenen bekannten Objekten bleiben gemäß
Deploymentvertrag aktualisierbar. Die neue 13-Parameter-Plannerform und der
14-Parameter-Executor werden nach Installation als Metadatenvertrag geprüft.
Bekannte eigene Releases upgraden, Fremdobjekte,
unbekannte Versionen und Consumers erhalten beziehungsweise blockieren.
Parserabhängigkeit ist ausschließlich das explizite Runtime-Opt-in;
Deploy/Uninstall von Option-0-Nutzung dürfen Linux nicht ausschließen.

Vor Native zuerst unabhängige Source-/Vertragsprüfung und passende Statik.
Gezielte neue Fixtures: Name/ON/Map, tatsächliches AFTER-/INSTEAD-Verhalten,
enabled/disabled/FIRST/LAST, Alias/CTE/Qualifier, UTF16 und Kommentar-/
Literalerhalt, Quell-QI/ANSI, dynamische/externe/unklare Ablehnung sowie
Kollision und unverändertes ResultTable bei Fehler. Windows-Opt-in am
ausgewählten schema-validierten Ziel; Linux nur der betroffene Option-0-/
13-Parameter-/4.0-Hash-/Lifecyclepfad. Keine Wiederholung unveränderter
Parser-Frameworktests, vollständiger CL-Matrix oder alter Fachfixtures ohne
konkreten Defektbedarf. Historische Nachweise bleiben separat.

## Quellen und gekoppelte Verträge

- [Individuelle Freigaben](../../.ai/BACKLOG.md)
- [Planner V3](TABLE_CLONE_WAVE2_CONTRACT.md)
- [Executor](TABLE_CLONE_EXECUTE_CONTRACT.md)
- [Parser 2.0](TSQL_SCRIPT_PARSER_HARDENING_CONTRACT.md)
- [USP-Vertrag](../Standards/USP_CONTRACT.md)
- [Microsoft: CREATE TRIGGER](https://learn.microsoft.com/en-us/sql/t-sql/statements/create-trigger-transact-sql?view=sql-server-ver17)
- [Microsoft: SET QUOTED_IDENTIFIER](https://learn.microsoft.com/en-us/sql/t-sql/statements/set-quoted-identifier-transact-sql?view=sql-server-ver17)
- [Microsoft: sp_settriggerorder](https://learn.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-settriggerorder-transact-sql?view=sql-server-ver17)
- [Microsoft: @@VERSION](https://learn.microsoft.com/en-us/sql/t-sql/functions/version-transact-sql-configuration-functions?view=sql-server-ver17)

## Begrenzte Ausführungsnachweise 2026-10-04

Der private Nativeadapter bestand auf SQL Server 2025 Windows/exakt CU8
CL170 ausschließlich lokal: beide Trigger-Fixtures einmal in Clean4,
Cleaninstallation und genuine3.1→4.0 mit frischer Upgradesession, Repeat,
13/13/14 Parameter, unabhängiger Clienthash und typgenaue dreispaltige
Executor-Ausgabe mit NOT NULL/Binary32/EOF, vier resolved-Consumer-Ablehnungen
53926/1 sowie Uninstall/Repeat. Beide eigenen Datenbanken wurden entfernt,
temporärer exakter Parsertrust wiederhergestellt und vorbestehender
ScriptDom-Trust erhalten. Prozesskanäle, Journale, Inputpins und frischer
Cleanup-Audit wurden unabhängig physisch geprüft. Keine Konfigurations-,
Rechte- oder Owneränderung. Frühere fehlgeschlagene Läufe sind kein Gesamt-PASS.

Der separate Linux2019/latest-CL150-Nachweis für Option0, Release4-Hash und
denselben Lifecycle wird wiederverwendet: nachfolgende Corekorrekturen
betreffen ausschließlich Option1, unabhängig per vollständigem Sourcevergleich
geprüft. Kein Linux-Triggernachweis und keine erneute Linux-Ausführung behauptet.
Weitere native Ziele/CL, zentrale4.0-Nutzung, tatsächliche Minimalrechte,
serverweite negative Fixtures und unsichtbare/mehrdeutige Bindungskontexte
bleiben nicht ausgeführt; unresolved Consumer nicht etabliert. Head-CI wird
separat im Pull Request nachgewiesen. Status teilweise validiert, unveröffentlicht.

Manifest, Source, Lifecycle, Objektseiten, Help, Beispiele, Tests und RepoMap
sind gekoppelt; diese Teilnachweise sind keine vollständige Produktqualifikation.
