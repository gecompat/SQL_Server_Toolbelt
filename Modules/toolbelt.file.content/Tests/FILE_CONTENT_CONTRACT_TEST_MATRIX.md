# File Content Contract Test Matrix

## Geltungsbereich

- Modul: `toolbelt.file.content`
- Version: `1.0.0`
- Zielversionen: SQL Server 2019, 2022, 2025
- Compatibility Levels: 150, 160, 170
- Plattformen: Windows (Releasevalidierung), Linux (partially validated)

## Statische Tests

| ID | Prüfung | Erwartung |
|---|---|---|
| ST-001 | Alle Artefakte vorhanden | Source, Deployment, Tests, Dokumentation, Beispiele, module.yaml |
| ST-002 | LoadBinaryFile-Vertragsmarker | CREATE OR ALTER, Parameter, OPENROWSET(BULK...), SINGLE_BLOB, Fehlercodes |
| ST-003 | LoadTextFile-Vertragsmarker | CREATE OR ALTER, Parameter, OPENROWSET(BULK...), CODEPAGE, EncodingDetected, BomPresent |
| ST-004 | Gemeinsames Root-Prädikat | Beide Fassaden binden denselben literalen SQLCMD-Vertrag ein; keine neue SQL-Objektanlage |

## Lifecycle-Tests

| ID | Prüfung | Erwartung |
|---|---|---|
| LC-001 | Schema `toolbelt_file` existiert | Deployment erfolgreich |
| LC-002 | Tabelle `FileContentRootAllowlist` existiert | Konfiguration bereit |
| LC-003 | Procedures `USP_LoadBinaryFile` und `USP_LoadTextFile` existieren | Öffentliche Verträge bereit |
| LC-004 | Zwei echte 1.0.0-Repeats mit vier synthetischen Allowlist-Zeilen | Exakte UTF-16-Bytes, NULLs, Auditzeiten und aktive/inaktive Zustände unverändert |
| LC-005 | Gelöschte höchste Identity, Katalog und regulärer Folgeinsert | Identity inklusive verbrauchtem Wert, Objekt-/Schema-/Spalten-/Index-/Constraint-/Trigger- und vorhandene Berechtigungsmetadaten erhalten |
| LC-006 | Veraltete kanonische Beschreibung und zusätzliche Annotationen | Nur Tabellen-`MS_Description` wird erneuert; übrige Properties bleiben gleich |

LC-004 bis LC-006 verwenden `RepeatCurrent.Contract.sql` in eigenen leeren
Testdatenbanken lokal/zentral ohne Datei-I/O, Serverkonfiguration oder Grants.
Linux-CI: native Default-CLs 2019/150, 2022/160, 2025/170. Der
[aktuelle Abschluss](../../../Releases/1.0.0/FILE-CONTENT-REPEAT-COMPLETION.md)
ergänzt Windows und die niedrigeren Linux-CLs: zwölf Engine-/CL-Paare lokal/zentral,
18 neue Kontexte/36 Fixtures/neun frische Audits und sechs wiederverwendete
CI-Kontexte. Nichtleere Benutzergrants, Minimalrechte, unbekannte Schemas und
historische Versionsmigrationen sind dadurch nicht qualifiziert.

## Contract-Tests (ohne echtes Dateisystem)

| ID | Prüfung | Erwartung |
|---|---|---|
| CC-001 | Hilfe-Contract LoadBinaryFile | Resultset mit DESCRIPTION-Section |
| CC-002 | Hilfe-Contract LoadTextFile | Resultset mit DESCRIPTION-Section |
| CC-003 | NULL-Pfad | `IsValid = 0`, `ValidationCode = 51320` |
| CC-004 | Relativer Pfad | `IsValid = 0`, `ValidationCode = 51320` |
| CC-005 | Traversal-Pfad | `IsValid = 0`, `ValidationCode = 51322` |
| CC-006 | Pfad außerhalb Allowlist | `IsValid = 0`, `ValidationCode = 51321` |
| CC-007 | Root mit/ohne Slash, exakter Pfad, Root `/`, Windows/UNC-Normalisierung | Nur exakter Root oder Nachfahren an der Slash-Grenze |
| CC-008 | Geschwisterpräfixe und `%`, `_`, Klammern im Root | Literale Zeichen, keine LIKE-Erweiterung |
| CC-009 | Leerer/inaktiver Root, Groß-/Kleinschreibung, Leerzeichen und Unicode | Exakte BIN2-/UTF-16-Grenzen ohne gepolstertes Exact-Equal |
| CC-010 | Beide Fassaden bei abgelehntem synthetischem Absolutpfad | Genau eine Zeile, `51321`, `IsValid = 0`, `BytesRead = 0`, `Content = NULL`, Returncode `0`; kein Provider-THROW |
| CC-011 | 4000 UTF-16-Einheiten | Candidate-Grenze und reine Präfix-Verkettung ohne Abschneiden; kein 4000-Zeichen-Root-Insert über den bestehenden Unique-Index |

## Runtime-Tests mit echtem Dateisystem (optional, plattformabhängig)

| ID | Prüfung | Erwartung |
|---|---|---|
| RT-001 | Binärdatei lesen | `Content` entspricht Dateiinhalt, `IsValid = 1` |
| RT-002 | Textdatei UTF-8 mit BOM | `EncodingDetected = 'UTF-8'`, `BomPresent = 1` |
| RT-003 | Textdatei Windows-1252 ohne BOM | `EncodingDetected = 'Windows-1252'`, `BomPresent = 0` |
| RT-006 | Textdatei UTF-16-BE mit BOM | `IsValid = 0`, `ValidationCode = 51325` |
| RT-004 | @MaxBytes überschritten | `IsValid = 0`, `ValidationCode = 51323` |
| RT-005 | Nicht existierende Datei | Engine-Fehler propagiert (THROW) |

Evidenz: https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30692267356

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-07`
- Nachweis: `https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37687448814`
- Scope: Commit 8effcee91106cb4b8924c7a839928d550c0653b6: befüllter 1.0.0-Repeat zweimal lokal und zentral, SQL Server 2019/150, 2022/160 und 2025/170 Linux; exakte Zeilen/Identity/Katalog/Annotationen und Uninstall; vorhandene Permissions nur beobachtet, keine Benutzergrants erzeugt; bestehende Datei-I/O-Suite anschließend erfolgreich; Windows/weitere Repeat-CLs/Minimalrechte/historische Migrationen offen
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->

## Historische Quellenbindung und erster Restversuch — 2026-11-08

Der [Nachweis](../../../Releases/1.0.0/FILE-CONTENT-REPEAT-QUALIFICATION.md)
bestätigt die aktuelle Bindung dreier früherer Linux-CI-Default-Repeats.
Der neue Windows-Restkoordinator ist FAILED_CLEANED mit frischem Audit PASS,
null bestandenen Gesamtfällen und vollständig entferntem eigenem DB-Scope.
Die Adapterkorrektur besteht 13 Offlineprüfungen einschließlich des echten
Erstexport-/Repeat-Batchvergleichs, ist aber nativ nicht ausgeführt. Historische
Ausführungen werden nicht hochgestuft; Windows und zusätzliche Repeat-CLs
bleiben offen. Der geschlossene No-Retry-Rahmen benötigt neue endliche Freigabe.

Die anschließende [korrigierte Welle](../../../Releases/1.0.0/FILE-CONTENT-REPEAT-COMPLETION.md)
wurde ausdrücklich neu freigegeben und vollständig bestanden. Die vorherige
Fehler-/Sperrbeschreibung bleibt historische Evidenz; die konkrete
Windows-/zusätzliche-CL-Repeatlücke ist geschlossen, andere Teilgates bleiben.

## Weitere aktuelle Lifecycleprofile — 2026-11-08

Der [gezielte Nachweis](../../../Releases/1.0.0/FILE-CONTENT-LIFECYCLE-QUALIFICATION.md)
belegt unbekannte Versionsmarker und drei fremde Namenskollisionen jeweils
für Deploy/Uninstall sowie Fremdobjekt-/Schemaerhalt, Neuinstallation,
Leerschemaentfernung und Uninstall bei fehlendem Modul. Zwölf vollständige
Windows-/Linux-Läufe lokal/direkt zentral: 24 Kontexte, 288 Profile, zwölf
frische Audits; alle 24 eigenen Datenbanken entfernt. Keine Wiederholung der
Repeat-Matrix, keine Produkt- oder Rechteänderung. Weitere Drift-/Lock-/
Rechte-/Ressourcen-/Providerprofile bleiben getrennt.

## Aktuelle AppLockergänzung — 2026-11-08

Die [getrennte Sitzungssperre](../../../Releases/1.0.0/FILE-CONTENT-APPLOCK-QUALIFICATION.md)
ist auf zwölf Engine-/CL-Paaren lokal/direkt zentral nativ qualifiziert:
48 exakte 51277/State1-Abweisungen und 48 erfolgreiche Schritte nach bestätigter
Freigabe, 24 verschiedene Arbeits-/Sperrsitzungspaare, zwölf frische Audits,
alle 24 eigenen DBs entfernt. Keine erneute Vollfixture. Andere Identitäten,
Race-/Caller-/SET-/Rollback-/Ressourcen-/Provider- und Modulgesamtgates bleiben separat.

## Gezielte Prozedurdefinitionsdrift — 2026-11-09

Die [aktuelle Driftmatrix](../../../Releases/1.0.0/FILE-CONTENT-DEFINITION-DRIFT-QUALIFICATION.md)
belegt zwölf vollständige Windows-/Linux-Engine-/CL-Läufe lokal/direkt zentral,
24 Kontexte, 48 etablierte Body-Driftzustände und 48 erfolgreiche Reparaturen.
Beide Prozeduren behalten ihre Objekt-ID; Originaldefinitionen/Katalog,
Allowlist-Daten/Identity und Berechtigungen sind exakt erhalten. Zwölf frische
Audits bestätigen alle 24 eigenen DBs entfernt und Konfiguration/Trust unverändert.
24/24 Aufrufe/DB-Reservierungen innerhalb 45 Minuten ohne Wiederholung;
keine pauschal offene Bodyreparatur dieses Scopes. Andere Drift-/Rechte-/
Session-/Rollback-/Ressourcen-/Provider-/Recoveryfälle bleiben separat.

## Eigene ruhende AppLock-Haltersitzung beenden — 2026-11-09

Der [Recovery-Nachweis](../../../Releases/1.0.0/FILE-CONTENT-LEASE-RECOVERY.md)
belegt vier vollständige Deploy-/Uninstallfälle nach erzwungenem Ende einer
eigenen ruhenden Session-Sperre auf Windows2025/CU8 CL170 lokal/zentral.
Exakte Halteridentität, ursprüngliche Verbindung verschwunden, Sperre verfügbar,
kanonischer Deploy beziehungsweise vollständiger Uninstall, ResultTable-Erhalt
und externe/lokale Transaktions-/Sperrneutralität bestanden. Frischer Audit,
beide eigenen DBs entfernt, Konfiguration/Trust unverändert. Zwei frühere
Adapterfehler bleiben FAILED_CLEANED mit frischen PASS-Cleanup-Audits.
Kein aktiver Mutations-, Clientprozess-/Transport-/Host-/VM-/Koordinatorabbruch,
keine neuen Rechte oder Modulgesamtabnahme.
