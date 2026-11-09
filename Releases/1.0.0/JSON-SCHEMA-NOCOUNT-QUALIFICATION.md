# JSON Schema: fehlendes Callerprofil XACT_ABORT OFF / NOCOUNT ON

Stand 2026-11-09: **PASS_FOR_DECLARED_OFF_ON_CALLER_GUARD_SCOPE** auf
Windows SQL Server2025/CU8, CL170, lokal, ohne installierte Toolbelt-Module.
Die beiden neuen Deploy-/Uninstall-Guardfälle und ein frischer unabhängiger
Abschlussaudit bestehen. Die eigene Datenbank ist entfernt; Serverkonfiguration
und Trust unverändert. Keine Assemblyinstallation oder -ausführung, neue Rechte,
Identitäten, Owner, Server-/Lab-/Datei-I/O-Änderungen.

Die [vorherigen ON-Profile](JSON-SCHEMA-XACT-ABORT-QUALIFICATION.md) und der
ursprüngliche OFF/OFF-Callertransaktionsnachweis bleiben in ihrem jeweiligen
Scope gültig und wurden nicht wiederholt. Diese Ergänzung prüft ausschließlich
`XACT_ABORT OFF`, `NOCOUNT ON`, `QUOTED_IDENTIFIER ON` und
`IMPLICIT_TRANSACTIONS OFF`. Die tatsächlich wirksamen Sessionbits werden vor
beiden Fällen geprüft und im privaten Originalreceipt festgehalten.

## Orakel und Quellenbindung

Der [Treiber](../../Tests/Release/Invoke-JsonSchemaNoCountLab.ps1) verwendet die
unveränderten vollständigen öffentlichen Deploy-/Uninstall-Skripte mit
kanonischer Include-/Variablenauflösung und paketqualifizierten Schema-DLL-Bytes.
Die frühe Callertransaktionsabwehr muss diese Skripte vor jeglichem Modulsetup
stoppen. Eine verkürzte nachgebaute Guardabfrage zählt nicht als Nachweis.

Die [Fixture](../../Tests/Release/Runtime/JsonSchema.NoCount.Contract.ps1)
verwendet die vorhandenen Caller-/Savepoint-/Observerorakel als Funktionen:
exakt SQL50000/State1/Class16 mit der vereinbarten Guardmeldung, dieselbe
gesunde Callertransaktion und Session, unveränderte Optionen und Modul-/Rechte-/
Principalsnapshots, Zeugenwert300 vor/nach Abweisung, Savepointrollback200 und
voller Rollback100. Der unabhängige Observer bestätigt Aktivität beziehungsweise
neutralen Abschluss ohne Application Locks. Toolbelt-Schemas und Benutzer-
Assemblies bleiben abwesend. Der frische Audit bindet das finale Journal,
exaktes Ziel, eigene DB-Absenz, ursprüngliche Inputpins und Server-/Trustzustand.

Acht [Offlinegegenproben](../../Tests/Release/test_json_schema_nocount_lab_contract.py)
bestehen: konkrete Authority-/Frist-/Ziel-/Modus-/Pin-/Originalskript-/DLL-
Abweichungen sowie tatsächlicher OFF/ON-Profileinstieg. Fehlendes NOCOUNT,
eingeschaltetes XACT_ABORT oder implizite Transaktionen werden vor dem
Callerfall abgewiesen. Der quellgebundene kanonische Preflight besteht.

## Ergebnis und Grenzen

Nativer Methodencommit: `a9a11c5802b817166cd59557dfcc99eed9713cc8`.
Ein vollständiger Erstversuch, zwei vollständige Originalreceipts und ein
frischer Audit PASS. Der vorab bestimmte gemeinsame Rahmen ist geschlossen:
**zwei Ziel-/Auditaufrufe, eine eigene Datenbank, höchstens45Minuten, kein Retry**.
Keine früheren Grenzen oder Fehler zurückgesetzt. Private Originale und
Quellkapseln bleiben außerhalb Git erhalten; ein deterministischer Prüfer
bestätigt Profilbits, Orakel, finale Journalbindung, Cleanup und Inputpins.

Functional verwendet Verschlüsselung und den unveränderten expliziten
Lab-Trustwert. Andere Ziel-/CL-Kombinationen, installierter Uninstall unter den
weiterhin unbelegten SET-Profilen, vollständige Session-/Lifecycle-/Rechte-/
Recoverymatrix sowie TLS- und Modulgesamtabnahme sind damit nicht qualifiziert.
Produktquellen, Manifeste und Modulstatus unverändert. Keine Veröffentlichung
oder Tags.
