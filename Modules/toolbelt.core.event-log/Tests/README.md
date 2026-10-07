# Event-Log-Testevidenz

Statischer Vertrag sowie SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170 einschließlich Caller-Rollback, uncommittable Caller, Context, Validierung, Retention, Concurrency, Redeploy, Central und Uninstall sind erfolgreich.

Evidenz: https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/31018284410

Der lokale physische Linux-Lauf vom 2026-08-29 war auf SQL Server 2025
erfolgreich, scheiterte aber auf SQL Server 2019 und 2022 im gemeinsamen
W5-Vertrag. Windows-Läufe bleiben `not executed`.

## Aktuelle Validierungsevidenz

Der zusätzliche befüllte `RepeatCurrent.Contract.sql` ist `not executed`.
Er läuft in einer eigenen installierten Testdatenbank mit einer exklusiven
Session aus `Deployment/`, erhält vorhandene Events und ergänzt vier eigene
synthetische Zeilen. Beide echten 1.0.0-Deploys vergleichen alle 24 Eventspalten
einschließlich NULL, Leerstring, Unicode, Padding und datetime2(7)-Auditwerten.
Ein eingefügter und gelöschter Identityhöchstwert sowie der nächste reguläre
Insert prüfen auch den verbrauchten Identityzustand. EventLog hat keine
rowversion; dieser Vertrag prüft Rowversions ausschließlich bei WorkType.

Vor dem ersten Snapshot ändern Register mit `AllowUpdate=1` und Disable
die eigene Event-Registrierung über öffentliche APIs. Deploy1 muss sie mit
gleicher ID und gleichen Created-Auditwerten kanonisch reaktivieren; Modified-
Auditwerte und Rowversion dürfen dabei bewusst wechseln. Deploy2 muss die
vollständige kanonische Zeile einschließlich Rowversion unverändert lassen.
Alle übrigen Registrierungen einschließlich eines eigenen deaktivierten
Sentinels werden in beiden Repeats bytegenau verglichen. API-Ergebnisse aus
Setup/Cleanup bleiben im privaten lokalen ResultTable-Sink.

Die gemeinsamen Capture/Assert-Includes vergleichen ausgewählte Tabellen-,
Objekt-, Spalten-, Constraint-, Index-, Identity-, Moduldefinitions-, Parameter-,
Permission- und typisierte Propertymetadaten. Eigene Tabellen-/Spaltenannotation
und `MS_Description` bleiben erhalten; Event-Deploy normalisiert keine
Tabellenbeschreibung. Es werden keine Benutzergrants erzeugt. Leere FK- oder
Triggerbestände beweisen keine Erhaltung nichtleerer Erweiterungen. Cleanup
entfernt nur eigene EventIds, den eigenen Sentinel über Remove nach Disable
und die vorab kollisionsgeprüften Annotationen. Identitywerte werden nicht
zurückgesetzt. Bei Fehlern bleibt die Bereinigung des eigenen Datenbankscope
beim bestehenden Adapter; Snapshotdaten werden nicht öffentlich ausgegeben.

Der neue Tabellenrepeat benötigt weder Provideraufrufe noch Serverkonfiguration
oder zusätzliche Rechte. Die bestehende Providerqualifikation bleibt getrennt.
Der vorgesehene CI-Scope ist Linux2019/150,2022/160,2025/170 jeweils lokal/zentral.
Windows, weitere Repeat-CLs, nichtleere Benutzergrants und Minimalrechte bleiben
offen; historische Modulnachweise belegen diesen neuen Test nicht.

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-09-01`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Physische SQL-Server-2019-, 2022- und 2025-Ziele unter Windows base und Linux latest; Provider-Probe, Caller-Rollback, uncommittable Caller, Kontext, Validierung, Retention, Konkurrenz, zentrales Deployment, Lifecycle und Uninstall
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
