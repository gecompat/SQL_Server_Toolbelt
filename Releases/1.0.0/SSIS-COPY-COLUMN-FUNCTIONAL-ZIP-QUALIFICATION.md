# Aktuelles Copy-Column-ZIP: funktionale Windows-Gesamtmatrix

Der [kanonische Record](../../Modules/toolbelt.tsql.ssis-debug/Tests/Qualification/CopyColumn.Functional.20261115.json)
belegt zwölf neue vollständige Koordinatorfälle am unveränderten
`SSIS-Debug-CopyColumnV1-Install-Windows.zip`: **15.204 Assertions** und zwölf
frische unabhängige Abschlussaudits, durchgehend `PASS_CLEANED`.
Damit ist die aktuelle funktionale ZIP-/Prozedur-/Rechtematrix geschlossen.
Das Gesamtmodul bleibt teilweise validiert und unveröffentlicht; ein neuer
strikter TLS- oder unabhängiger Sicherheitsgesamtabschluss wird nicht behauptet.

## Matrix und tatsächliche Orakel

| Windows-Ziel | Compatibility Levels | Deployment-Modi | Fälle |
|---|---|---|---:|
| SQL Server 2019 CU32 | 150 | lokal, zentral | 2 |
| SQL Server 2022 CU26 | 150, 160 | lokal, zentral | 4 |
| SQL Server 2025 CU8 | 150, 160, 170 | lokal, zentral | 6 |

Pro Kontext bestehen acht Archivinstallationsorakel, 208 aktuelle API-/DebugScript-,
688 semantische, 87 Metadaten-/API-, 30 Rechte- und 15 Lifecycle-Assertions.
CL170 ergänzt 54 semantische Assertions. Weitere 222 Assertions prüfen die
parametrisierte Prozedur, Typgrenzen, ResultTable, Callerzustände, Parallelität,
DDL-Lebenszyklus und einen tatsächlich separat angemeldeten eingeschränkten Login.
Gesamt: 96 Archiv-, 12.444 funktionale und 2.664 Prozedurassertions.

Jeder vollständige Fall erzeugt zwei eigene Datenbanken, auch lokal.
Zentral liegt die Prozedur im Consumer; der Generator wird dreiteilig adressiert.
Der eingeschränkte Login erhält kein Mapping in die Generator-DB. Dies ist
kein neuer Nachweis einer gemappten CrossDB-Identität.

## Konkrete Rechteausnahme und Bereinigung

Die Benutzerfreigabe vom 2026-11-15 erlaubt ausschließlich je Fall:

- Einen eigenen Benutzer ohne Login in der Generator-Testdatenbank mit EXECUTE
  auf `toolbelt_tsql.USP_ExplainSsisDataFlow`, VIEW DEFINITION der eigenen DB und
  SELECT auf `sys.sql_expression_dependencies` sowie `sys.security_predicates`.
  Negativfälle verweigern und restaurieren genau diese Rechte; kein Quell-SELECT.
- Einen eigenen SQL-Login mit vorher intent-journalisierter SID und gemapptem
  Benutzer ausschließlich in der eigenen Prozedur-Testdatenbank: CONNECT,
  VIEW DEFINITION, EXECUTE auf `ContosoDebug.USP_Synthetic` und
  `toolbelt_core.USP_PrepareResultTable`. SELECT auf die synthetische
  `dbo.SyntheticSourceA` erst nach der erwarteten Abweisung.

Keine Serverrechte, Rollenmitgliedschaften oder Änderungen bestehender Identitäten.
Alle 24 DBs und zwölf Logins sind entfernt; die zwölf loginlosen und zwölf
gemappten Benutzer sind mit ihrem eigenen Scope entfernt. Jeder separate Audit
bindet das exakte finale Journal und prüft den exakten Login samt SID.
Konfiguration, Trust und andere Assemblyverbraucher sind wiederhergestellt
beziehungsweise unverändert.

## Methode und Reproduktion

Der [Adapter](../../Modules/toolbelt.tsql.ssis-debug/Tests/Runtime/Invoke-CopyColumnFunctionalLab.ps1)
am Quellcommit `123bf820fa44bc1d70d534775b78011dcc24937a` bindet Archiv,
Manifest, Provider, Produktquellen, alle Laufzeitmethoden und Fixtures vor Dispatch.
Nur der feste Archivname der eingefrorenen kombinierten Methode wird adaptiert;
Orakel, Lowpriv-Audit und ein einmaliges 900-Sekunden-Fenster mit 60 Sekunden
Cleanup bleiben erhalten. Der alte Buildrecord ist Methodenprovenienz und
qualifiziert nicht die heutige DLL.

Ein vor Start gebundener privater Plan enthält die zwölf exakten schema-validierten
READY-Ziele, noch nicht existierende Journalpfade, Inputpins und Rechteausnahme.
Ein einzelner Aufrufer reserviert Lauf und Audit gemeinsam und startet den Adapter
je Fallindex einmal mit `Action=Run`, danach frisch mit `Action=Audit`, demselben
Plan und dessen exaktem Digest. `ValidateOnly` und `DescribeOnly` prüfen ohne SQL.
Ein Planfeld erteilt keine Rechte. Originalplan, Journalbindungen und Rohreceipts
bleiben privat und werden nicht als reale Ziel-/Identitätsdaten veröffentlicht.

Der ursprüngliche 180-Minuten-Rahmen ist mit 24/24 Ziel-/Auditaufrufen,
24 DB- und zwölf Login-Reservierungen geschlossen: kein nativer Fehler oder Retry.
Der gültige aktuelle 29-Fälle-Frameworknachweis wird bytegebunden wiederverwendet.
Separate Copy-, Host-, Installations- und SSMS-Nachweise behalten ihren Scope;
keine zusätzliche GUI-/Host-/TLS-Wiederholung oder Erneuerung früherer Grenzen.

Die [15 Zulassungsgegenproben](../../Tests/Release/test_ssis_copy_column_functional.py)
und [14 Evidenzgegenproben](../../Tests/Release/test_ssis_copy_column_functional_evidence.py)
schützen vollständige Kontexte/Teilgruppen, CL170-Zusätze, Rechteausnahme,
DB-/Loginentfernung, frischen journalgebundenen Audit und geschlossene Grenzen.
Der [Validator](../../Scripts/Release/validate_ssis_copy_column_functional.py)
prüft exakte aktuelle Quellen/Archivbytes in bestehender Releaseprüfung und CI,
ohne selbst SQL zu öffnen oder aus Testcode Runtime-Evidenz abzuleiten.

## Verbleibende Grenzen

Diese Verbindung ist `Functional` mit ausdrücklich übernommenem Trustwert;
authentifiziertes TLS bleibt hier `not executed`. Der separate aktuelle SSMS-Fall
wird nicht mit diesem SQL-Login zu einem kombinierten Windows-/TLS-Nachweis vereint.
Vollständige SSIS-Runtime-Parität, unbegrenzte Produktionskapazität und OS-/VM-
Verlust des Koordinators sind nicht qualifiziert. Keine Veröffentlichung oder Tags.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-11-15`
- Nachweis: `local: vollstaendige funktionale Copy-Column-ZIP-Matrix mit konkreter Rechteausnahme`
- Scope: PASS_FOR_DECLARED_SCOPE: zwoelf Windows-/CL-/Moduskontexte SQL2019CU32 CL150, SQL2022CU26 CL150/160, SQL2025CU8 CL150/160/170 lokal/zentral. 15204 Assertions:96 Archiv,12444 funktional,2664 Prozedur; zwoelf PASS_CLEANED-Koordinatoren und frische finaljournalgebundene Audits. Alle24DBs/12Logins entfernt, eigene Benutzer mit eigenem Scope entfernt; Konfiguration/Trust/andere Verbraucher erhalten. Konkrete Benutzerfreigabe2026-11-15 fuer begrenzte API-/Prozedurrechte, keine Serverrechte/Bestandsidentitaetsaenderung. Rahmen24Aufrufe/24DBs/12Logins/180Minuten geschlossen, kein nativerFehler/Retry. Gueltige Framework-/Copy-/Host-/SSMS-Belege erhalten, kein neues striktesTLS/Mapping-/Modulgesamt-PASS oder Veroeffentlichung.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
