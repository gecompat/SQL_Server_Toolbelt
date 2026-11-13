# JSON Schema: zehn weitere interne CLR-Facettenmatrizen

Stand 2026-11-13: **PASS_FOR_DECLARED_TEN_POINT_MATRIX_WITH_ENGINE_BOUNDARY**.
Der abgegrenzte Nachweis umfasst 1.248 öffentliche Schema-Lifecycle-Profile
und 240 getrennte Engine-Abweisungen in 24 lokalen beziehungsweise direkt
zentralen Windows-/Linux-Kontexten. Zwölf korrigierte Koordinatoren und
13 frische unabhängige Abschlussaudits sind PASS. Ein ursprünglicher
Fehllauf bleibt unverändert `FAILED_CLEANED` mit null bestandenen Profilen.
Keine Produkt-/Binäränderung oder vollständige Modulqualifikation.

## Echte Lücken und gewählter Umfang

Der Benutzer beauftragte die nächsten zehn freigegebenen Qualifikationspunkte,
Wiederverwendung gültiger Nachweise, Integration grüner PRs und Branchbereinigung.
Die [vorherige CLR-Matrix](JSON-CLR-BINDING-QUALIFICATION.md) belegt Namen,
eine verkleinerte Profile-Eingabelänge, fünf verkleinerte SqlString-Ausgabelängen
und drei CLR-kompatible Nachbartausche. Diese grünen Profile bleiben unverändert
und werden nicht wiederholt. Die jetzige Auswahl betrifft andere Facetten:

| Punkt | Tatsächliche Abweichung am internen Slot | Nachweis bestanden/geplant |
|---|---|---|
| 1 | Jede der zehn Ergebnisspalten einzeln als NOT NULL deklarieren | 240/240 Engine-Abweisungen; öffentliche Spiegel nicht ausführbar |
| 2 | Json-/Schema-Eingabe von nvarchar(max) auf nvarchar(4000) | 96/96 öffentliche Profile |
| 3 | Json-/Schema-Eingabe als nchar(4000), Profile als nchar(32) | 144/144 öffentliche Profile |
| 4 | Profile-Eingabe als nvarchar(33) | 48/48 öffentliche Profile |
| 5 | Profile-Eingabe als nvarchar(max) | 48/48 öffentliche Profile |
| 6 | Jede der fünf begrenzten SqlString-Ausgaben um eine Zeicheneinheit länger | 240/240 öffentliche Profile |
| 7 | Dieselben fünf Ausgaben als nvarchar(max) | 240/240 öffentliche Profile |
| 8 | Dieselben fünf Ausgaben als nchar mit ursprünglicher Zeichenzahl | 240/240 öffentliche Profile |
| 9 | DocumentPointer-/SchemaPointer-Ausgabe als nvarchar(4000) | 96/96 öffentliche Profile |
| 10 | Dieselben beiden Pointer-Ausgaben als nchar(4000) | 96/96 öffentliche Profile |

Die fünf begrenzten SqlString-Ausgaben heißen `RowKind`, `Status`, `Profile`,
`Keyword` und `ErrorCode`. Ihre verlängerten nvarchar-Längen sind 9, 25, 33,
129 beziehungsweise 33. Die Fixed-Length-Fälle verwenden 8, 24, 32, 128
beziehungsweise 32. Alle Ein- und Ausgabeparameter, Ordinale und Bindungsziele
bleiben bei diesen Typ-/Längenfällen unverändert.

Die Typauswahl berücksichtigt die offizielle
[CLR-Parameterzuordnung](https://learn.microsoft.com/en-us/sql/relational-databases/clr-integration-database-objects-types-net-framework/mapping-clr-parameter-data?view=sql-server-ver17):
nchar/nvarchar sind SqlChars-/SqlString-Zuordnungen; die hier nicht ausgewählten
ANSI-Typen werden nicht als installierbare CLR-Parameter behandelt.
Die installierbaren Abweichungen werden trotzdem erst nach tatsächlichem
Katalogvergleich als negative Lifecycle-Fixture zugelassen.

## Physische Zielmatrix

| Plattform | Engine/Patch | CL | Ergebnis lokal und direkt zentral |
|---|---|---|---|
| Windows | SQL 2019/CU32 | 150 | 104 öffentliche Profile und 20 Engine-Abweisungen, frischer Audit PASS |
| Windows | SQL 2022/CU26 | 150, 160 | je 104 öffentliche Profile und 20 Engine-Abweisungen, je frischer Audit PASS |
| Windows | SQL 2025/CU8 | 150, 160, 170 | je 104 öffentliche Profile und 20 Engine-Abweisungen, je frischer Audit PASS |
| Linux | SQL 2019/latest | 150 | 104 öffentliche Profile und 20 Engine-Abweisungen, frischer Audit PASS |
| Linux | SQL 2022/latest | 150, 160 | je 104 öffentliche Profile und 20 Engine-Abweisungen, je frischer Audit PASS |
| Linux | SQL 2025/latest | 150, 160, 170 | je 104 öffentliche Profile und 20 Engine-Abweisungen, je frischer Audit PASS |

Nur explizit ausgewählte, schema-validierte READY-Ziele werden verwendet;
tatsächliche Engine, Plattform und CL werden geprüft. Der unveränderte
Functional-Transport ist kein authentifizierter TLS-/Windows-/GUI-/CLI-Nachweis.

## Engine-Grenze und erhaltener erster Fehler

Der erste Koordinator versuchte die RowKind-NOT-NULL-Fixture vor jedem anderen
Profil. SQL Server wies die Deklaration selbst ab; der erwartete veränderte
Katalogzustand und die öffentlichen Lifecycle-Aufrufe wurden nicht erreicht.
Der Originalkoordinator bleibt `FAILED_CLEANED` mit null Profilreceipts.
Sein frischer unabhängiger Audit ist PASS mit `originalRunPassed=false`.
Originaljournal, Quellenkapseln und Fehler bleiben unverändert erhalten.

Das ist eine Engine-Beschränkung, keine erfolgreiche öffentliche Guardprüfung.
Die korrigierte Fixture verlangt für jede der zehn Spalten genau die
Engine-Abweisung 6526, State 1, Severity 16 mit dem zu dieser Spalte passenden
NOT-NULL-Constrainttext. Microsoft dokumentiert diese Fehlerklasse in der
[Engine-Fehlerreferenz](https://learn.microsoft.com/en-us/sql/relational-databases/errors-events/database-engine-events-and-errors-6000-to-6999?view=sql-server-ver17).
Der vollständige Zustand muss dabei unverändert bleiben und die externe
Transaktions-/Sitzungs-/AppLock-Prüfung bestehen.

Die tatsächlichen 240 Enginefälle ersetzen keine öffentlichen Profile.
Die ursprünglich vorgesehenen **480 öffentlichen NOT-NULL-Deploy-/Uninstall-
Spiegel bleiben not executed**, weil die Engine den erforderlichen beschädigten
Zustand nicht zulässt. Es gibt dafür keine fiktiven `/deploy`- oder
`/uninstall`-Receiptkeys. Die zehn Spalten werden je Kontext einmal mit
`/engine-denied` erfasst. Keine Umdeutung des ursprünglichen Fehlers zum PASS.

## Öffentliche Guards, Katalog und Restore

Die [neue Fixture](../../Tests/Release/Runtime/JsonLifecycle.ClrFacets.Contract.ps1)
ist ausschließlich für `json-lifecycle-clr-facets/v1` im
[vorhandenen Runner](../../Tests/Release/Invoke-JsonLifecycleBinaryRegistrationLab.ps1)
ausgewählt. Sie nutzt die unveränderte gemeinsame Methode der
[vorherigen CLR-Fixture](../../Tests/Release/Runtime/JsonLifecycle.ClrBinding.Contract.ps1).
Kanonische Original-Deploy-/Uninstall-Scripts, qualifizierte Core-/Schema-
Paketbinaries sowie Quell-/Projekt-/Compiler-/Registry-/SHA256-/SHA512-Bindungen
werden vor SQL-Zugriff geprüft. Keine unbekannten Binaries oder Ersatzguards.

Für die übrigen 26 Deklarationen je Modus wird ausschließlich der eigene
interne CLR-Slot per ALTER geändert. Das ursprüngliche SQL-Bindungsziel und
alle nicht ausgewählten Teile bleiben erhalten. Die Fixture vergleicht alle
acht Parameter und zehn Ergebnisspalten aus dem tatsächlichen Katalog.
Nur die ausgewählten system_type_id-/user_type_id-/max_length-Facetten dürfen
abweichen; Namen, Ordinale, Richtungen, Precision, Scale, Nullability und
Collation bleiben unverändert. Eine nicht eingetretene oder zusätzliche
Abweichung führt zum Abbruch vor den öffentlichen Guardaufrufen.

Pro tatsächlicher Abweichung werden die originalen öffentlichen Schema-
Deploy- und Uninstall-Scripts ausgeführt. Jeder Aufruf muss genau
55633/State 1/Severity 16 mit dem unveränderten CLR-Binding-/Parameter-/
Spaltenvertragstext liefern und den vollständigen beschädigten Snapshot
unverändert lassen. Vor Restore muss derselbe Snapshot erneut passen.
Anschließend wird die ursprüngliche kanonische CLR-Deklaration wiederhergestellt;
der vollständige ursprüngliche Zustand muss exakt passen.

Die Snapshots umfassen Rückgabespalten, Parameter-/Modulmetadaten, CLR-Bindings,
Objekt-/Assemblyidentitäten, Definitionen, Owner, Rechte, Principals,
Rollenmitgliedschaften, typisierte Properties und Core-Projektion.
Externe Neutralitätsorakel bleiben erhalten. Die CLR-API selbst wird mit den
veränderten Deklarationen nicht fachlich aufgerufen. Der abschließende
kanonische Uninstall ist Cleanup, keine neue vollständige API-/Migrationsqualifikation.

## Prüfungen und gemeinsamer Abschluss

Methodenstände `e35629dc` und `1f19cea0`: zwei neue
[Offlinegegenproben](../../Tests/Release/test_json_clr_facets_lab_contract.py),
zwei betroffene bisherige Gegenproben und quellgebundene kanonische Preflights
sind PASS. Die Gegenproben prüfen exakte Fixture-/Pin-Auswahl, 36 geschlossene
Vektoren, tatsächlich 62 Keys je Modus, zehn Gruppen, unveränderte externe
Bindungsziele und Ablehnung unveränderter/zusätzlich veränderter Kataloge.
Fiktive öffentliche Nullabilitykeys und unbekannte Vektoren werden abgewiesen.
Die neue Suite ergänzt den bestehenden Releasevalidator; keine zusätzlichen
CI-Jobs oder Trigger. Head- und tatsächliche Main-PUSH-CI bleiben Integrationsgates.

Der gemeinsame ursprüngliche Rahmen von 32 Ziel-/Auditaufrufen,
32 DB-Reservierungen und 60 Minuten bleibt einschließlich Fehllauf und
Korrektur erhalten. Er ist mit **26/32 Aufrufen und 26/32 DB-Reservierungen**
innerhalb der ursprünglichen Frist geschlossen. Unbenutzte Reserve bleibt
geschlossen; kein grünes Profil wurde wiederholt. Alle 25 tatsächlich
angelegten eigenen Datenbanken und 26 eigenen Releasehash-Trusteinträge
sind entfernt, sechs eigene Konfigurationsänderungen zurückgenommen.
Keine neuen Rechte, Principals, Owner, Serverneustarts, Labressourcen oder
Zertifikats-/Truststoreänderungen. Eigene notwendige CLR-Konfiguration und
bekannter Releasehashtrust verwenden die Root-Freigabe mit Journal und Restore.

Eine getrennte private Auswertung rekonstruiert alle 1.488 tatsächlichen Keys,
prüft die Trennung von 1.248 öffentlichen und 240 Enginefällen, finale
Journal-/Auditbindungen, Quellenkapseln, aktuelle Produktpins und gemeinsame
Frist. Private Originale und historische Fehler anderer Wellen bleiben erhalten.
Schema bleibt **partially validated, unreleased**. Andere Typ-, Alias-,
Binding-, Rechte-, Identitäts-, Recovery- und Ressourcenpflichten bleiben
separat. Keine Veröffentlichung oder Tags.
