# JSON Constructors: Aggregate-Fehler und offene Grenzen

Stand 2026-11-13: **PARTIAL_QUALIFICATION_WITH_PRESERVED_FAILURES**.
Die vom Benutzer beauftragten nächsten zwanzig freigegebenen Punkte wurden als
zwanzig Aggregate-Fehler-/Profilfamilien ausgewählt. Sechzehn kleine Fehlerfamilien
bestehen auf 22 lokalen/direkt zentralen Kontexten: 2.640 eindeutige SQL-Prüfungen.
Vier große Eintragsgrenzen und das letzte Zielpaar bleiben offen. Dies ist weder
ein vollständiger Zwanzig-Punkte-Abschluss noch eine Modulgesamtqualifikation.
Keine Produkt-, Binär-, Quoten- oder öffentliche API-Änderung.

## Auswahl, Quelle und Wiederverwendung

Die aktuelle bereits freigegebene Constructor-Implementierung bleibt unverändert.
Die [frühere Callerqualifikation](JSON-CONSTRUCTORS-AGGREGATE-CALLER-QUALIFICATION.md),
[aktuelle Migration](JSON-CONSTRUCTORS-CURRENT-MIGRATION-QUALIFICATION.md) und
[öffentlichen Parameterfacetten](JSON-PUBLIC-FACETS-QUALIFICATION.md) behalten
jeweils ihre ursprünglichen Scopes; ihre grünen Fachprofile werden nicht wiederholt.

Die neue [Fixture](../../Tests/Release/Runtime/JsonConstructors.AggregateErrors.Contract.ps1)
verwendet ausschließlich die direkten öffentlichen AGF-Aufrufe und kanonische
Constructor-/Core-Deploymentdateien. Der [bestehende Runner](../../Tests/Release/Invoke-JsonLifecycleBinaryRegistrationLab.ps1)
verlangt bekannte qualifizierte Paketbinaries, aktuelle Source-/Projekt-/Compiler-/
Registrybindungen und unveränderte Original-Includebäume. Das Schema-Artefakt
wird als generischer Provenienzeingang geprüft, aber weder installiert noch vertraut.
Neue Rechte, Benutzer, Logins oder Owneränderungen gehören nicht zum Testscope.

Die ersten 60 bestandenen lokalen Array-Fehlerprofile des ersten fehlgeschlagenen
Koordinators werden genau einmal wiederverwendet. Der Adapter bindet dessen
unveränderten privaten Runset, finales Journal, frischen Audit und ursprüngliche
Quellkapsel. Produkt und gemeinsame Orakel müssen identisch bleiben; die ersten
60 Eingabe-/Parameter-Datensätze werden zusätzlich semantisch verglichen.
Fehlende, umgeordnete oder falsche Receipts werden verworfen. Diese Wiederverwendung
macht aus dem fehlgeschlagenen ursprünglichen Koordinator keinen Gesamt-PASS.

## Die zwanzig ausgewählten Punkte

Die folgenden Zahlen bezeichnen eindeutige bestandene Fehlerprofile, einschließlich
der 60 wiederverwendeten Profile. Die vollständige Zielmatrix hätte 24 Kontexte.

| Punkt | Aggregat | Familie | Bestanden / vollständige Matrix |
|---|---|---|---|
| 1 | Array | Ungültiges Profil: NULL, 0, 3, 255 | 88 / 96 |
| 2 | Array | Gemischte Profile, beide Reihenfolgen und Fehlerpriorität | 88 / 96 |
| 3 | Array | Ungültige Ordinale, beide Profile | 176 / 192 |
| 4 | Array | Doppelte Ordinale, beide Reihenfolgen/Profile | 88 / 96 |
| 5 | Array | Ungültiger Werttyp einschließlich NULL/Länge | 264 / 288 |
| 6 | Array | NULL-/Werttyp-Widerspruch | 220 / 240 |
| 7 | Array | Ungültige Zahlenliterale | 220 / 240 |
| 8 | Array | Ungültige Booleanliterale | 176 / 192 |
| 9 | Array | Profil 1: ausschließlich gültige Einträge, einer über Limit | Offen; Timeout |
| 10 | Array | Profil 2: ausschließlich gültige Einträge, einer über Limit | Nicht ausgeführt |
| 11 | Object | Ungültiges Profil: NULL, 0, 3, 255 | 88 / 96 |
| 12 | Object | Gemischte Profile, beide Reihenfolgen und Fehlerpriorität | 88 / 96 |
| 13 | Object | Ungültige Ordinale, beide Profile | 176 / 192 |
| 14 | Object | Doppelte Ordinale, verschiedene Schlüssel | 88 / 96 |
| 15 | Object | Ungültiger Werttyp einschließlich NULL/Länge | 264 / 288 |
| 16 | Object | NULL-/Werttyp-Widerspruch | 220 / 240 |
| 17 | Object | Ungültige Zahlenliterale | 220 / 240 |
| 18 | Object | Ungültige Booleanliterale | 176 / 192 |
| 19 | Object | Profil 1: ausschließlich gültige Einträge, einer über Limit | Nicht ausgeführt |
| 20 | Object | Profil 2: ausschließlich gültige Einträge, einer über Limit | Nicht ausgeführt |

Ungültige und gemischte Profile werden nicht unter irrelevanten Basisprofilen
verdoppelt. Die übrigen kleinen Fehlerfälle prüfen Profil 1 und 2 getrennt.
Gemischte Profile prüfen insbesondere Priorität vor Ordinal- und Werttypfehlern.
Die Object-Duplikatprüfung verwendet verschiedene synthetische Schlüssel und
isoliert damit den Ordinalfehler.

## Tatsächlich abgeschlossene physische Kontexte

| Plattform | Engine/Patch | CL | Kleine Profile lokal und direkt zentral |
|---|---|---|---|
| Windows | SQL 2019/CU32 | 150 | 240, frischer Audit PASS |
| Windows | SQL 2022/CU26 | 150, 160 | je 240, je frischer Audit PASS |
| Windows | SQL 2025/CU8 | 150, 160, 170 | je 240, je frischer Audit PASS |
| Linux | SQL 2019/latest | 150 | 240, frischer Audit PASS |
| Linux | SQL 2022/latest | 150, 160 | je 240, je frischer Audit PASS |
| Linux | SQL 2025/latest | 150, 160 | je 240, je frischer Audit PASS |
| Linux | SQL 2025/latest | 170 | Offen; kein Lauf in diesem Paket |

Alle ausgeführten Ziele waren explizit schema-validiert und READY; tatsächliche
Engine, Plattform und CL wurden geprüft. Functional-Transport ist kein Nachweis
von authentifiziertem TLS, Windows-/Netzwerkidentität oder einem Linux-Clienthost.

## Fehlerorakel und Grenzen

Jeder bestandene kleine Fall verlangt SQL-Fehler 6522 mit Severity 16 und genau
einem ausgewählten `TBX_JSON_AGG_*`-Tag. Der tatsächliche SQL-State wird privat
erhalten; es wird kein übergreifender fester State behauptet. Ein geöffneter Reader
darf über sämtliche Resultsets keine Teilzeile liefern. Vor/nach jedem Aufruf
werden tatsächliche Eingabeanzahl und geordneter serverseitiger XML/SHA256-Digest,
vollständiger Modul-/Rechte-/Bindingzustand sowie externe Sitzungs-, Transaktions-
und AppLock-Neutralität verglichen. Nach kanonischem Uninstall müssen eigene
Constructor-Objekte und Assembly fehlen.

Der ausschließlich gültige Array-Input mit 10.001 Einträgen bestand nicht.
Zwei erste Versuche lieferten noch keine vollständige SQL-Fehlerdiagnose; ein
korrigierter Adapter bewahrte anschließend den tatsächlichen SQL-Timeout statt
dessen innerster nativer Exception. Das unveränderte 45-Sekunden-Statementlimit
wurde nicht erhöht. Daraus folgt kein PASS für `ENTRY_LIMIT`, kein bestimmter
Produktfehler und keine Kapazitätsgarantie.

Eine danach getrennte Count-Prioritätsprobe verwendet Ordinal 0 und NULL-Schlüssel,
sodass keine gültige Nutzdaten-/Ordinalmenge aufgebaut werden soll. Nur Array,
Profil 1, im ersten lokalen Kontext bestand bei 10.000 Einträgen mit
`ORDINAL_INVALID` und bei 10.001 mit `ENTRY_LIMIT`: zwei zusätzliche eigene
Teilreceipts. Die entsprechende Probe mit Profil 2 lief ebenfalls in einen
Timeout. Diese zwei Teilreceipts ersetzen keinen der vier ursprünglichen
Grenzfälle und werden nicht zu den 2.640 kleinen Profilen addiert. Weitere
Count-Prioritätskontexte wurden nicht ausgeführt.

## Fehlverläufe, Bereinigung und gemeinsamer Rahmen

Vier native Fachversuche blieben fehlgeschlagen. Drei endeten `FAILED_CLEANED`
mit jeweils frischem Audit PASS. Beim vierten hatte der Bearbeiter eine privat
gepinnte Verifikationsdatei während des Laufs geändert. Die Eingangsprüfung
verhinderte daraufhin den automatischen Cleanup; der ursprüngliche Zustand bleibt
`CLEANUP_BLOCKED`, sein reservierter Audit ist kein PASS. Nach Wiederherstellung
der exakten Datei aus ihrer gebundenen Quellkapsel entfernte eine separate,
eigentumsgeprüfte Sicherheitsbereinigung die eigenen Ressourcen. Deren eigenes
Journal ist `FAILED_CLEANED`, bindet das unveränderte blockierte Original und
besitzt einen frischen unabhängigen Audit PASS. Kein Fehlverlauf wird überschrieben.

Die anschließende unabhängige Kleinfall-Restmatrix bestand elf vollständige
Originalkoordinatoren und elf frische Audits. Insgesamt sind 15 abschließende
Audits PASS; 26 eigene Datenbanken und 30 eigene Trust-Einträge wurden entfernt,
neun eigene Konfigurationsänderungen zurückgesetzt. Andere Verbraucher und
Serverzustände wurden erhalten. Originale private Journale, Audits, Eingaben,
Fehlerdiagnosen und Quellkapseln bleiben außerhalb der Versionskontrolle erhalten.

Der gemeinsame, vor dem ersten SQL-Aufruf gewählte Rahmen schloss mit 32/32
Ziel-/Auditaufrufen, 30/32 DB-Reservierungen und innerhalb der ursprünglichen
60 Minuten. Fehler, Diagnoseversuche und Sicherheitsbereinigung sind enthalten.
Die zwei freien DB-Reservierungen eröffnen keine zusätzlichen Aufrufe.

## Offline-/Integrationsgate und verbleibende Arbeit

Drei aktuelle Offlineprüfungen bestehen: kanonische Admission mit negativen
Provenienz-/Include-Gegenproben; geschlossene Vektoren und Scopes einschließlich
falscher Fehler-/Teilzeilenorakel; Ablehnung beschädigter Wiederverwendungsreceipts.
Die Tests sind einmal in die bestehende Releasevalidierung aufgenommen; es gibt
keine neuen CI-Trigger oder parallele Prüfkette. Head- und tatsächliche Main-PUSH-CI
werden separat am finalen PR-/Mergecommit geprüft.

Offen bleiben die beiden kleinen Kontexte Linux SQL 2025/latest CL170,
die vier ausschließlich gültigen großen Eintragsgrenzen und die übrigen
Count-Prioritätskontexte. Engine-Merge-/Serialisierungspfad, Heap-/Spill-/Hardwall-
und Produktionskapazitätsnachweise werden durch diese Welle nicht qualifiziert.
Die [Modultestmatrix](../../Modules/toolbelt.json.constructors/Tests/JSON_CONSTRUCTOR_CONTRACT_TEST_MATRIX.md)
und [Testanleitung](../../Modules/toolbelt.json.constructors/Tests/README.md) führen
diesen Teilabschluss. Modulstatus bleibt `partially validated`, `unreleased`.
Keine Veröffentlichung und keine Tags.
