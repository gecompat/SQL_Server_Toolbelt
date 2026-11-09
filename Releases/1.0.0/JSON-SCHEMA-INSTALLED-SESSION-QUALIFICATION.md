# JSON Schema: neue Callerprofile bei installiertem Modul

Stand2026-11-09: **PASS_FOR_DECLARED_INSTALLED_SCHEMA_SESSION_SCOPE** auf
Windows SQL2025/CU8 CL170 lokal. Drei bislang unbelegte Uninstall-Guardprofile
mit installiertem aktuellem Schema/Core bestanden beim ersten Gesamtlauf.
Ein frischer unabhängiger Audit bestätigt die entfernte eigene Datenbank,
beide entfernten eigenen Trusteinträge und vollständig unveränderten
ursprünglichen Konfigurations-/Trustbestand. Keine neuen Rechte oder Identitäten.

| Öffentliches Skript | XACT_ABORT | NOCOUNT | Modul vor/nach Abweisung |
|---|---|---|---|
| Uninstall, ConfirmNoExternalConsumers=1 | OFF | ON | installiert, unverändert |
| Uninstall, ConfirmNoExternalConsumers=1 | ON | OFF | installiert, unverändert |
| Uninstall, ConfirmNoExternalConsumers=1 | ON | ON | installiert, unverändert |

Der ursprüngliche [installierte OFF/OFF-Fall](json-schema-caller-transaction-qualification.json)
und die späteren [ON-](JSON-SCHEMA-XACT-ABORT-QUALIFICATION.md) und
[OFF/ON-Guards bei fehlenden Modulen](JSON-SCHEMA-NOCOUNT-QUALIFICATION.md)
bleiben getrennt gebunden und wurden nicht wiederholt. Ein installierter
Uninstall-ON-Fall ist damit für diesen ausgewählten Kontext nicht mehr offen.
Andere physische Ziele, weitere SET-Optionen oder eine vollständige Modulabnahme
werden daraus nicht abgeleitet.

## Aktuelle Artefakte und Originalorakel

Der [Treiber](../../Tests/Release/Invoke-JsonSchemaInstalledSessionLab.ps1)
prüft die bekannten Core-/Schema-Release-DLLs gegen qualifizierte Paketbytes,
die aktuelle gemeinsame Artefaktregistry, Projektdateien und die dort gebundenen
Compilerquellen. Kein neuer Build. Kanonische ResultTable-/Core-Baseline und
vollständiges öffentliches Schema-Deploy werden einmal als Voraussetzung
ausgeführt; die Guardfälle verwenden das unveränderte vollständige Uninstall.
Keine verkürzte Guardnachbildung oder erneute API-Vollsuite.

Die [Fixture](../../Tests/Release/Runtime/JsonSchema.InstalledSession.Contract.ps1)
verwendet die bestehenden gesunden Caller-/Savepoint-/Snapshot-/Observerorakel
als Funktionen. Je Fall: exakt SQL50000/State1/Class16 und vereinbarte Meldung,
dieselbe gesunde Callertransaktion und Sitzung, tatsächlich geprüfte und
erhaltene Sessionbits, unveränderte Modul-/Rechte-/Principalsnapshots und
Zeugenwert300. Savepointrollback ergibt200, voller Rollback100. Der externe
Observer bestätigt anschließend eine neutrale Sitzung ohne Application Locks.
Das installierte Modul bleibt über alle drei Abweisungen unverändert erhalten.

CLR muss bereits eingeschaltet sein; der Lauf führt keine Konfigurationsänderung
aus. Die ständige Root-Freigabe erlaubt ausschließlich die zwei zuvor geprüften
Releasehashes. Die bestehenden Trust-/Consumerhelfer erhalten Fremd- oder
vorbestehende Fingerprints; nur eigene unveränderte und nicht mehr verwendete
Einträge werden entfernt. Fehlende Sichtbarkeit, Drift oder unklare Ownership
verhindern die Entfernung. Die unabhängige finale Prüfung bindet das exakte
Originaljournal, Zielversion, DB-Absenz, vollständigen ursprünglichen
Konfigurations-/Trustbestand und unveränderte Inputpins.

## Prüfung und endlicher Rahmen

Methodencommit: `af91b0451b54c554084006dee23cb19d4e848f05`.
Zehn [Offlinegegenproben](../../Tests/Release/test_json_schema_installed_session_lab_contract.py)
und der kanonische Preflight bestehen. Die Gegenproben prüfen unter anderem
falsche Baseline-/Corebytes trotz neuer Prüfsumme, die tatsächlichen drei
Sessioninputs und das Ablehnen falscher Optionen sowie Schutz vor Entfernen
fremder, vorbestehender, konsumierter oder unklarer Trusteinträge.

Vorab gemeinsamer Rahmen: höchstens vier Ziel-/Auditaufrufe, zwei eigene DBs,
45Minuten und maximal ein geänderter Adapterfall nach Befund, bestätigtem Cleanup
und ohne bestandene Profilwiederholung. Tatsächlich benötigt: **zwei Aufrufe,
eine eigene DB, drei vollständige Originalreceipts und ein frischer Audit**.
Erster Versuch COMPLETE; keine Korrektur oder Wiederholung. Ungenutzte Reserve
geschlossen. Private Originale und Quellkapseln bleiben außerhalb Git erhalten;
frühere Grenzen und Fehler bleiben unverändert.

Functional verwendet Verschlüsselung und den unveränderten expliziten Lab-
Trustwert. Keine Zertifikats-/Truststore-/Lab-/Owner-/Datei-I/O-Änderung,
keine Grants oder neue Principals. Vollständige Lifecycle-/Owner-/Drift-/Lock-/
Ressourcen-/Recoverymatrix und authentifiziertes TLS bleiben eigenständig.
Produktquellen, Manifeste und Modulstatus unverändert. Keine Veröffentlichung
oder Tags.
