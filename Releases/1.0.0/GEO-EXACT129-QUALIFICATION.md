# GeoJitter: tatsächlicher 129-Byte-Geography-Operand

Am 2026-11-07 bestand der unveränderte GeoJitter-1.2.0-Vertrag den bislang
fehlenden exakten nativen 129-Byte-Fall: **24 Kontexte,24 Ablehnungen mit
ErrorCode15 und NULL sowie24 erfolgreiche Punkt-Kontrollen**.
Zwölf frische unabhängige Abschlussaudits bestanden,24 eigene DBs sind entfernt.
Ergebnis: **PASS_FOR_DECLARED_EXACT129_SCOPE**.

| Ausgewähltes SQL-Ziel | Compatibility Levels | Modi | Kontexte |
|---|---|---|---:|
| Windows2019/CU32 | 150 | lokal/direkt zentral | 2 |
| Windows2022/CU26 | 150,160 | lokal/direkt zentral | 4 |
| Windows2025/CU8 | 150,160,170 | lokal/direkt zentral | 6 |
| Linux2019/latest | 150 | lokal/direkt zentral | 2 |
| Linux2022/latest | 150,160 | lokal/direkt zentral | 4 |
| Linux2025/latest | 150,160,170 | lokal/direkt zentral | 6 |

Clienthost Windows, vorhandene administrative Lab-Anmeldung; direkt zentral
bezeichnet SameDB-Nutzung. Keine neue Login-/CrossDB-Identitätsqualifikation.

## Tatsächlich gemessener Operand und Orakel

Die [Fixture](../../Tests/Release/Geo.Exact129.sql) erzeugt aus dem synthetischen
Punkt(0,0) neun verschachtelte `GEOMETRYCOLLECTION`-Container mit dem nativen
`geography::STGeomFromText`. Vor dem API-Aufruf verlangt sie die tatsächliche
Länge von `CONVERT(varbinary(max),@Boundary)` gleich129, einen gültigen
Geography-Wert und den Typ `GeometryCollection`. WKT-Länge, Integervergleich
oder gepaddete Dummybytes zählen ausdrücklich nicht als UDT-Zeuge.

`TVF_DeterministicGeoJitter` muss genau eine Zeile mit ErrorCode15 und NULL
liefern. Eine getrennte gültige 2D-Punkt-Kontrolle muss genau eine Zeile mit
ErrorCode0 und einem gültigen Point in SRID4326 liefern. Der Client empfängt
nur die fünf skalaren Orakelfelder; er benötigt keine SqlTypes-Assembly zur
Deserialisierung der nativen UDT. Der Test ändert die Produktionsgrenze128
nicht und behauptet keine neue erfolgreiche Behandlung von Collection-Eingaben.

Ausgeführter Methodensnapshot:
[`47bae4a5`](https://github.com/gecompat/SQL_Server_Toolbelt/commit/47bae4a53c058c9f117eccdad5263d894aad406b).
Der [enge Labtreiber](../../Tests/Release/Invoke-Geo129Lab.ps1) verwendet die
vorhandenen T-SQL-Pin-/Verbindungs-/OwnDB-Helfer. Er verlangt zwölf exakte
Engine-/Patch-/CL-Paare und beide Modi; weitere Ersatzwahl ist ausgeschlossen.
Aktuelle Exporte enthalten ausschließlich ResultTable1.0.0 und deterministische
Zuordnung1.2.0. Installierte Version-/Modusmarker, keine Benutzerassembly,
unveränderte Produktdefinitionen und neutraler Sessionabschluss werden geprüft.
Tatsächliche Major-/Plattform-/Softwareversion und vorhandener Sysadmin werden
privat erfasst; der frische Audit bindet die Zielversion erneut.

Alle Produkt-/Methoden-/Fixture-/Exportdateien, privaten Controller, Host und
schema-validierter Labvertrag samt Schema/Prompt bleiben gepinnt. Vor und
nach den Fällen sowie in den frischen Audits werden die Pins verglichen.
Eine frühere reine Vorbereitung wurde vom Exporter wegen einer vorhandenen
Datei korrekt abgewiesen, ohne SQL. Die Vorbereitung erzeugt seitdem neue
Dateinamen und erhält ihre früheren Inputs; keine Native-Wiederholung daraus.

## Endlicher Rahmen und Cleanup

Vor Zulassung galten maximal28 Ziel-/Auditdispatches,28 eigene DB-Reservierungen
und45 Minuten ab erstem Zielaufruf. Zwölf Läufe plus zwölf reservierte Audits
verbrauchten24 Dispatches und24 DBs; keine fehlgeschlagenen Native-Fälle oder
Korrekturversuche. Die ursprüngliche Frist wurde eingehalten und die Welle
einschließlich unbenutzter Restplätze geschlossen.

Der vorhandene Owned-Process-Helfer begrenzt jeden Producer/Audit auf400 Sekunden
mit getrennten4-MiB-Kanälen und eigener Prozessbereinigung. Vor dem nächsten
Fall bleiben mindestens15 Minuten für beide reservierten Prozesse. Innere
SQL-/Cleanupfristen bleiben erhalten; dies ist keine allgemeine harte Host-
oder SQL-Server-Abbruchgarantie.

DROP verlangt eigene volle DB-ID, Erstellungszeit und Owner-Marker; fremde oder
unklare Zustände werden nicht überschrieben. Die zwölf separaten Auditprozesse
binden den unveränderten finalen Originaljournalhash, DB-Abwesenheit,
vollständige unveränderte Konfigurations-/Trustsnapshots, Zielbindung und Pins.
Ein privater Nachprüfer verifiziert alle24 Witnesses und Originalaudits.
Keine Rechte, Principals, CLR-/Trusteinträge, Serveroptionen oder Labressourcen
wurden angelegt oder verändert; eigene DBs bilden den gesamten Änderungsscope.
Private Rohlogs und Identitäten bleiben außerhalb Git.

## Wiederverwendung und Grenzen

Die Originale der bisherigen128-/größer128-Safetyfälle und der früheren
129er-Integerkontrolle bleiben unverändert. Deren damalige Aussage
„129-Byte-UDT nicht qualifiziert“ bleibt für ihre damalige Ausführung richtig;
die konkrete neue Lücke schließt ausschließlich dieser Nachweis.
Die [Geo-Funktionszielmatrix](GEO-MISSING-TARGETS-QUALIFICATION.md) und
[separaten Callerprofile](DETERMINISTIC-RIGHTS-QUALIFICATION.md) behalten ihren
jeweiligen Scope und werden nicht pauschal wiederholt oder aufgewertet.

Neun verbindungslose Gegenproben bestehen gültige Admission, Freigabetyp,
Frist-/Ziel-/Modusabweichungen, kanonische Fixture und Methodenpins,
Exportdrift, echte UDT-/Positivorakel und die erhaltenen Audit-/Cleanupguards.
Die tatsächliche Fixture ist zusätzlich mit ScriptDom Parser150 geprüft.
Offline-/Syntaxprüfungen allein belegen keinen nativen Geography-Wert.

Andere UDT-Formen, weitere Funktions-/Client-/Lifecycle-/Ownerprofile,
Lowpriv-CrossDB-Identitäten, Heap/Parallelität, harte Recovery und vollständige
Modul-/Releaseabnahme bleiben getrennt. Functional-Verschlüsselung mit dem
expliziten Labtrust ist keine authentifizierte TLS-Abnahme. Produkt-SQL,
Manifest, Paket, teilweise validierter/unveröffentlichter Modulstatus und
historische Nachweise bleiben unverändert; keine Veröffentlichung oder Tags.
