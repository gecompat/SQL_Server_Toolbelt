# Aggregate-Restwelle: Linux/CL170 geschlossen, native Großgrenzen blockiert

Stand 2026-11-14: **PASS_LINUX_CL170_NATIVE_BOUNDARIES_BLOCKED**.
Linux SQL2025/latest CL170 besteht lokal und direkt zentral 240 neue kleine
Fehlerprofile mit vollständigem Originalkoordinator und frischem unabhängigem
Audit. Zusammen mit den gültigen [2.640 bisherigen Profilen](JSON-AGGREGATE-ERRORS-QUALIFICATION.md)
sind damit diese 16 kleinen Fehlerfamilien auf allen 24 unterstützten Kontexten
belegt. Die vier ausschließlich gültigen großen Eingabegrenzen sind nativ
weiterhin offen. Keine Produkt-, Binär-, Quoten-, Rechte- oder Identitätsänderung.

## Konkreter Auftrag und tatsächlicher Rahmen

Der Benutzer gab eine neue, separate Restwelle mit höchstens 32 Ziel-/Auditaufrufen,
32 Testdatenbanken und 60 Minuten frei. Frühere Wellen, Fehler, das beschädigte
Originaljournal und die [explizit autorisierte frühere Sicherheitsbereinigung](JSON-AGGREGATE-BOUNDARY-REST-QUALIFICATION.md)
bleiben unverändert; keine früheren Verbräuche werden zurückgesetzt.

Diese Welle schließt mit 19 Ziel-/Auditreservierungen und 18 DB-Reservierungen
innerhalb ihrer ursprünglichen Frist. Ein ausschließlich lesender, im gemeinsamen
Budget reservierter Request-Diagnoseaufruf ist enthalten. Keine weiteren Aufrufe
werden aus freien Plätzen oder einem späteren Timer abgeleitet.

## Stabiler Client und endliche Koordination

Der Client verwendet eine vorhandene, signierte und hashgebundene PowerShell
außerhalb der austauschbaren App-Runtime. Abgekoppelte versteckte Prozesse liefen
in SQL-freien Gegenproben nach Ende des aufrufenden Prozesses weiter. Dies ist
kein Nachweis beliebiger App-, OS- oder Datenträgerausfälle.

Ein gemeinsamer exklusiver Dateilock und der dauerhaft schreibende Journalwriter
schützen die Zählung. Lauf und unabhängiger Audit werden vor jedem Fall gemeinsam
reserviert. Die vorhandenen Grenzen des Prozesshelpers bleiben erhalten:
900.000 ms für den Fachprozess, 90.000 ms für den Audit und getrennte begrenzte
Ausgabekanäle. Die native Fach-/Cleanupfrist bleibt zwölf/dreizehn Minuten ab
Koordinatorstart, zusätzlich geklemmt durch die gemeinsame Gesamtfrist; vor einer
Admission bleiben mindestens 18 Minuten reserviert. Kein Agent wurde eingesetzt.

Linux/CL170 lief zuerst unabhängig. Danach wurde Windows SQL2019/CU32 als Pilot
verwendet. Nach dessen konkreten, sauber auditierten Fehlern wurden ausschließlich
andere noch ungeprüfte Engines ausgewählt, jeweils höchster CL zuerst. Höchstens
fünf verschiedene Engines arbeiteten parallel; CLs derselben Engine überlappten
nicht. Ein exakt journalgebundener `FAILED_CLEANED`-Timeout mit frischem Audit,
null Teilzeilen, vollständigen Inputpins und unverändertem Serverzustand sperrte
die weitere Queue nur dieser Engine. Andere Fehler, Drift oder unklare Ownership
hätten weiterhin alle neuen Starts gesperrt. Kein Timeout wurde zum PASS erklärt.

SQL-freie Modelle prüften erfolgreiche gemeinsame Zählung von 26 Reservierungen,
einen Fehlerstopp mit reserviertem Audit, ausgeschöpfte Aufrufe, Fristsperre und
vier negative Fälle der Timeout-Isolation. Diese Modelle enthalten keine native
SQL-Qualifikation und werden nicht als ausgeführte Zielaufrufe gezählt.

## Native Ergebnisse und verbleibende Matrix

Der [vorhandene Runner](../../Tests/Release/Invoke-JsonLifecycleBinaryRegistrationLab.ps1)
verwendet den geschlossenen neuen Scope `valid-boundaries` in der
[Aggregate-Fixture](../../Tests/Release/Runtime/JsonConstructors.AggregateErrors.Contract.ps1).
Er wählt ausschließlich Array/Object mal Profil 1/2 mit 10.001 beziehungsweise
100.001 ansonsten gültigen Einträgen. Kleine grüne Kontexte und frühere getrennte
Count-Prioritätsvektoren werden dabei nicht wiederholt.

| Ziel | CL | Tatsächliche große native Prüfung |
|---|---|---|
| Windows SQL2019/CU32 | 150 | Array/Profil1 skalar und mit ORDER GROUP: Timeout; HASH GROUP nicht kompilierbar |
| Windows SQL2022/CU26 | 160 | Array/Profil1 mit ORDER GROUP: Timeout |
| Windows SQL2025/CU8 | 170 | Array/Profil1 mit ORDER GROUP: Timeout |
| Linux SQL2019/latest | 150 | Array/Profil1 mit ORDER GROUP: Timeout |
| Linux SQL2022/latest | 160 | Array/Profil1 mit ORDER GROUP: Timeout |
| Linux SQL2025/latest | 170 | Array/Profil1 mit ORDER GROUP: Timeout |

Alle sieben tatsächlich begonnenen großen Aggregatausführungen erreichten das
180-Sekunden-Statementlimit mit SQL-Timeout und null Ergebniszeilen. Das ist kein
bestandener SQL6522/`ENTRY_LIMIT`-Fall. Ein weiterer Fall scheiterte bereits bei der
Planermittlung, weil der erzwungene Hash-Plan nicht erzeugt werden konnte.
Es gibt **null** bestandene große native Grenzprofile. Array/Profil2 und beide
Object-Grenzen wurden nach dem jeweils ersten Fehler nicht mehr ausgeführt;
die übrigen unteren CLs wurden nach dem Fehler derselben Engine nicht gestartet.

Für gruppierte Versuche wurde genau eine tatsächliche Profilgruppe geprüft;
keine Zeile wurde gefiltert, dupliziert oder vorzeitig abgeschnitten. Alle
Eingabemengen behalten den vor/nach dem erwarteten Fehler zu prüfenden
Anzahl-/Digestvertrag. Die gruppierte Form verwendet die dokumentierten
[GROUP- und MAXDOP-Queryhints](https://learn.microsoft.com/en-us/sql/t-sql/queries/hints-transact-sql-query?view=sql-server-ver17).
Geschätzte Pläne wurden mit wieder ausgeschaltetem SHOWPLAN ausschließlich privat
gebunden. Der skalare Pilot zeigte einen seriellen Stream-Aggregate-Plan; ein
zusätzlicher rein lesender Requestbefund wurde privat gesichert. Die Ursache der
Kosten und insbesondere die tatsächliche Read-/Write-Callbackhäufigkeit sind
nicht nachgewiesen. Keine Performance-, Heap-, Spill- oder Produktionskapazitäts-
garantie wird daraus abgeleitet.

## Ergänzender Nachweis mit den unveränderten Original-DLLs

Ein gesonderter SQL-freier CLR-Lauf verwendete die exakt hashgeprüften Original-
Core-/Constructor-Binaries. Für Array und Object sowie beide Profile wurde jeweils
der vollständig gültige Maximalzustand mit 10.000 beziehungsweise 100.000 Einträgen
aufgebaut, geschrieben und in ein frisches Aggregat eingelesen. Genau ein weiterer
gültiger Eintrag führte jeweils zu `TBX_JSON_AGG_ENTRY_LIMIT`: vier bestandene
Managed-Grenzprüfungen, einschließlich des großen gültigen Transportzustands.
Die synthetischen Ordinale und Object-Schlüssel waren eindeutig.

Dies bestätigt den ausgewählten kompilierten Guard-/Transportübergang im separaten
CLR-Host. Es ist kein SQL6522-Nachweis, kein Beleg nativer Callbackfolgen und keine
Aufwertung der fehlgeschlagenen SQL-Aufrufe. Die vier nativen Lücken werden deshalb
nicht durch diese ergänzende Evidenz geschlossen oder umbenannt.

## Bereinigung, Verifikation und Integration

Ein vollständiger Linux-Koordinator ist PASS. Acht andere Koordinatoren bleiben
`FAILED_CLEANED` mit jeweils eigenem frischem Audit; alle neun unabhängigen Audits
sind PASS für ihren tatsächlichen Abschluss-/Bereinigungsscope. Zehn tatsächlich
angelegte eigene Datenbanken und 18 eigene Trust-Einträge wurden entfernt; fünf
eigene Konfigurationsänderungen restauriert. Andere beziehungsweise schon vor der
Welle bestehende Konfigurationen und Verbraucher blieben erhalten. Keine
Ownership-Neuzuordnung oder zusätzliche Hostfreigabe war erforderlich.

Fünf fokussierte Offlinegegenproben prüfen die geschlossenen Scopes, typisierten
Plan-/Formparameter, Zeitgrenzen, Fehlerorakel, Reusereceipts und Journalhärtung.
Ein unabhängiger lokaler Prüfer bindet Fälle, Resultate, Originaljournale, frische
Audits, Quellkapseln, unveränderte Produktquellen, Zählung und Managed-Teilnachweise.
Der Dokumentationsaudit und finale Head-/Main-PUSH-CI sind separate Integrations-
gates und schließen keinen nativen Timeout. Private Originale und Pläne bleiben
unversioniert erhalten.

Der nächste fachliche Schritt ist die Aufklärung des nativen Ausführungsblockers
vor einer erneuten großen SQL-Qualifikation. Weitere unveränderte Wiederholungen
sind kein Fortschrittsnachweis. Die [Modultestmatrix](../../Modules/toolbelt.json.constructors/Tests/JSON_CONSTRUCTOR_CONTRACT_TEST_MATRIX.md)
und [Testanleitung](../../Modules/toolbelt.json.constructors/Tests/README.md) unterscheiden
den geschlossenen Linux-/Kleinfallumfang vom offenen großen Native-Umfang.
Modulstatus bleibt `partially validated`, `unreleased`. Keine Veröffentlichung oder Tags.
