# Queue-Einreihung und Status mit getrennten Callerrechten

> Späterer Nachtrag vom 2026-10-25: Die [Worker-Callerrechte](QUEUE-WORKER-RIGHTS-QUALIFICATION.md)
> ergänzen sieben Worker-APIs und die befüllte Blockerview. Dieser ursprüngliche
> Bericht und seine JSON-Projektion bewahren den damaligen begrenzten Umfang.

Stand 2026-10-25. Queue 2.1.0 ist für sechs Producer-/Status-/Viewprofile
lokal und direkt zentral geprüft. Fünf Profile verwenden je ein Objektrecht.
Das ältere `USP_EnqueueWork` benötigt zusätzlich ein enges VIEW DEFINITION
auf seinen registrierten Handler; Handler-EXECUTE bleibt verweigert.

## Tatsächlich geprüfter Umfang

Der [gemeinsame T-SQL-Testweg](../../Tests/Release/README.md#weitere-tsql-callerrechte-prüfen)
installiert ResultTable 1.0.0, Work Type 1.2.0 und Queue 2.1.0. Die feste
`Runtime/QueueFrontend.Rights.sql` verlangt eine eigene markierte frische
Datenbank. Sie erstellt nur einen eigenen No-op-Testhandler, Work Type,
Benutzer ohne Login und explizite ENQUEUE-ALLOW-Policy. Diese Policy bleibt
für alle Profile fest; sie ersetzt keine SQL-Objektberechtigung.

| API | Positives Profil |
|---|---|
| `USP_EnqueueWork` | EXECUTE plus VIEW DEFINITION auf genau den eigenen Handler |
| `USP_EnqueueWorkWithPolicy` | einzelnes EXECUTE |
| `USP_EnqueueBarrierWork` | einzelnes EXECUTE |
| `USP_GetWorkStatus` | einzelnes EXECUTE |
| `VW_WorkQueue` | einzelnes SELECT |
| `VW_WorkQueueBarrierBlockers` | einzelnes SELECT; leere View und Metadaten |

Die Producer prüfen tatsächliche persistierte Initialzustände sowie explizite
Policy-/Barriermetadaten. GetWorkStatus und Statusview lesen ein bekanntes
synthetisches Item. Beide Views enthalten weder PayloadJson noch ClaimToken.
Die Blockerview wird ausschließlich leer geprüft, ohne tatsächlichen
Blocker-Snapshot oder dessen Auflösung zu qualifizieren.

Der Legacyproducer weist fehlende Handler-Metadatensicht zuerst mit genau
SQL51902 ab und verändert keine Queuezeile. Danach ermöglicht ausschließlich
VIEW DEFINITION den Aufruf; Handler-EXECUTE wird weiterhin ausgeschlossen.
Fehlende und entzogene API-Rechte, andere öffentliche Queue-/Worker-APIs,
interne Kerne/Tabellen, ResultTable-Helper und Katalogverwaltung müssen mit
exakt SQL229 scheitern. Breite Rollen-, Schema- oder Datenbankrechte entfallen.

Windows/Linux SQL2019 CL150, SQL2022 CL150/160 und SQL2025 CL150/160/170
bestanden local/direct-central: zwölf Fälle, 120 Einzelgrantprofile,
24 Legacyproducer-/Metadatenprofile, 3.456 SQL229- und 24 SQL51902-Abweisungen.
Ein falscher persistierter Sollstatus und ein zusätzliches Objektrecht wurden
aus den erwarteten Gründen verworfen; beide Kontrollen bleiben `FAILED_CLEANED`.

Ein früherer Versuch ohne die nötige Handler-Metadatensicht scheiterte mit
SQL51902 und wurde bereinigt. Er ist keine bestandene Orakelkontrolle; sein
Verbrauch bleibt erhalten. Alle 15 Versuche bestanden unabhängige Input- und
Abwesenheitsaudits. Nach dem letzten Verbraucher bestätigten frische Audits
alle 27 eigenen Datenbanknamen als abwesend. Eigene Handler, Principals,
Policies und Daten sind entfernt; Moduldefinitionen, Serverkonfiguration,
CLR und Assemblytrust bleiben unverändert. Private Identitäten/Logs bleiben lokal.

## Quellen, Leseweg und Grenzen

Die [JSON-Projektion](queue-frontend-rights-qualification.json) bindet die
konsumierten Quellen, Exports, Fixture und vorhandenen Harness-/Labadapter.
Der [Moduleinstieg](../../Modules/toolbelt.core.work-queue/README.md) führt
nun zum aktuellen 2.1-Manifest und grenzt die historische 2.0-Evidenz ab.
Die [Objektdokumentation](../../Modules/toolbelt.core.work-queue/Documentation/WORK_QUEUE_OBJECTS.md)
erklärt die bestehende Metadatenvoraussetzung des Legacyproducers.

Die frühere [Policyqualifikation](QUEUE-AUTHORIZATION-QUALIFICATION.md) behält
ihren getrennten Scope. Sie wird hier nicht erneut als vollständige Suite
ausgeführt. Sieben andere öffentliche Worker-/Recovery-APIs erhalten durch
ihre Abweisung kein positives Minimalrechtenachweis. Vollständige Blocker-,
Managed-/Claim-/Lease-/Recovery-/Parallelitäts-/Lifecycle- und Providerverträge,
echte Lowpriv-CrossDB-Mappings, authentifizierte TLS-Abnahme und harte Recovery
bleiben separat. Functional verwendet erforderliche Verschlüsselung und den
expliziten Trustwert des schema-validierten Labvertrags.

Keine volle Modul-/Releaseabnahme, neue Produktfunktion, Paketänderung,
Statushochsetzung oder Veröffentlichung; die [Releasegates](RELEASE-GATES.md)
und separate Veröffentlichungsfreigabe gelten weiterhin.
