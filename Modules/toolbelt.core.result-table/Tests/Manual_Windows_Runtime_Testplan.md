# Manueller Windows-Runtime-Testplan

V0a-Evidenz 2026-08-29: `local: Tests/CI/run-lab-local.ps1` belegt
ausschließlich den im Modulmanifest genannten physischen Linux-Scope; offene
Windows- und modulspezifische Fälle bleiben unberührt.

Status: ausstehend. Dieser Testplan ergänzt die automatisierte Linux-Matrix um den erforderlichen Windows-SQL-Server-Nachweis. Er erzeugt keine Runtime-Evidenz, solange die Tests nicht tatsächlich ausgeführt und bewertet wurden.

Bestehende Linux-Evidenz: [vollständige SQL-Server-2019-/2022-/2025-Matrix](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30459004717) sowie [natürlicher Savepoint-Enginefehler 2705](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30692956855). Diese Evidenz ersetzt keinen Windows-Lauf.

## Sicherheitsrahmen

- Ausschließlich dedizierte synthetische Testdatenbanken und lokale Temp-Tabellen verwenden.
- Keine realen Tabellen, Produktionsdaten, Backups, Hostnamen, Konten, Pfade, Hardwaredaten oder vollständigen Rohlogs in das Repository übernehmen.
- Die Testinstanz darf nach dem Lauf verworfen werden. Bestehende Benutzer- oder Anwendungsdatenbanken sind nicht zu verwenden.
- Ergebnisse nur in der abstrahierten Rückmeldetabelle am Ende dieses Dokuments übermitteln.

## Vorbedingungen

1. Windows SQL Server 2019, 2022 oder 2025 mit `sqlcmd` beziehungsweise einem gleichwertigen Client bereitstellen.
2. Repository auf dem zu prüfenden Commit auschecken.
3. Eine leere Testdatenbank mit case-sensitiver Collation anlegen, beispielsweise `Latin1_General_100_CS_AS`.
4. Sicherstellen, dass `tempdb` eine case-insensitive Collation verwendet, wenn `SavepointEngineError.Contract.sql` ausgeführt werden soll. Bei case-sensitivem `tempdb` ist dieser einzelne Test als `not applicable` zu melden; die übrige Matrix bleibt ausführbar.
5. Modul mit `Deployment/Deploy.sql` im lokalen Modus installieren. Der Test darf keine Instanzoptionen verändern.

## Testreihen

| ID | Test | Erwartung |
|---|---|---|
| DEP-01 | Lokales Deployment, Wiederholung und `Lifecycle.Contract.sql` | Erfolgreich; Modulmarker und Objektversion bleiben konsistent. |
| API-01 | `USP_PrepareResultTable.Contract.sql` | Help-, Parameter-, Fehler-, `@KeepData`- und Schema-Vertrag erfolgreich. |
| COLL-01 | `Collation.Contract.sql` | Binäre Namenssemantik und Referenz-Collations bleiben korrekt. |
| BND-01 | `BoundaryAndTransaction.Contract.sql` | 1024-Spalten-, Caller-Transaktions- und uncommittable-State-Verträge erfolgreich. |
| SAVE-01 | `SavepointEngineError.Contract.sql` | Natürlicher Enginefehler 2705 wird unverändert weitergegeben; Zielschema, Zieldaten, Caller-Marker und Transaktionszähler werden zum Savepoint wiederhergestellt. |
| CONC-01 | Vier parallele Aufrufe von `MultiSession.Contract.sql` mit unterschiedlichen `WorkerId`-Werten | Keine Namenskollisionen oder gegenseitigen Temp-Table-Effekte. |
| PERF-01 | `Performance.Workload.sql`, mindestens drei Wiederholungen nach einem Warm-up | Kein funktionaler Fehler; Laufzeiten nur als abstrahierte Median-/Streuungswerte dokumentieren. Keine Hardware- oder Hostdaten erfassen. |
| CENTRAL-01 | Zentrales Deployment in eine leere Toolbelt-Testdatenbank und `Central.Contract.sql` aus einer getrennten Consumer-Testdatenbank | Cross-database-Aufruf gemäß Vertrag erfolgreich. |
| UNINSTALL-01 | `Deployment/Uninstall.sql` lokal und zentral | Release-Objekte vollständig entfernt; fremde beziehungsweise vorbestehende Schemata bleiben erhalten. |

## Versionsumfang

- Mindestens ein vollständiger Windows-Lauf auf der vorgesehenen primären Zielversion.
- Vor einem Release gezielte Wiederholung auf SQL Server 2019, 2022 und 2025, sofern diese physischen Versionen unterstützt werden sollen.
- Compatibility Levels ersetzen den Windows-Plattformnachweis nicht, können aber für zusätzliche Syntax-/Planungsprüfungen auf einer neueren Engine verwendet werden.

## Abstrahierte Rückmeldung

Nur folgende Felder übermitteln:

| Test-ID | SQL Server-Version | Compatibility Level | Ergebnis | Fehlernummer/Kategorie | Abstrahierte Bemerkung |
|---|---|---:|---|---|---|
| z. B. SAVE-01 | 2022 | 160 | pass | Enginefehler 2705 erwartet | Ziel und Caller-Transaktion vollständig wiederhergestellt |

Keine realen Datenbanknamen, Hostnamen, Konten, Pfade, Screenshots, Hardwaredaten oder vollständigen Fehlermeldungen übermitteln. Bei Fehlern genügen Test-ID, SQL-Fehlernummer, gekürzte Fehlerkategorie und die Angabe, ob Schema, Daten oder Transaktionszustand unerwartet verändert wurden.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-08-29`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Lokales SQL_Server_Lab; physische SQL-Server-2019-, 2022- und 2025-Linux-Ziele; vollständiger Moduladapter mit lokalen, zentralen, Lifecycle- und Uninstall-Verträgen
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
