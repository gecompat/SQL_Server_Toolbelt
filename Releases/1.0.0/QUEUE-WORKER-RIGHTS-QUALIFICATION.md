# Queue-Worker-APIs mit getrennten Callerrechten

Stand 2026-10-25, zweite Welle des neuen endlichen Release-Rahmens. Sieben
öffentliche Worker-APIs und die befüllte Blockerview sind lokal/direkt zentral
auf zwölf Ziel-/CL-Kombinationen geprüft. Produktquellen und Modulstatus bleiben
unverändert; dies ist eine Qualifikation direkter SQL-Aufrufe im unmanaged Scope.

## Rollen und tatsächliche Orakel

Der [gemeinsame Testweg](../../Tests/Release/README.md#weitere-tsql-callerrechte-prüfen)
installiert ResultTable 1.0.0, Work Type 1.2.0 und Queue 2.1.0. Die feste
`Runtime/QueueWorker.Rights.sql` verlangt eine eigene markierte frische Datenbank
und deaktivierte Managed Admission. Sie erstellt einen eigenen No-op-Handler,
Work Type, Benutzer ohne Login und feste CLAIM-ALLOW-Policy. Die Policy bleibt
getrennt von SQL-Objektgrants und wird hier nicht erneut vollständig variiert.

| API | Positives SQL-Profil | Geprüfter Zustand |
|---|---|---|
| `USP_ClaimWork` | EXECUTE plus EXECUTE auf genau den eigenen Handler | echter Claim, Token/Generation/Lease; ohne Handler-EXECUTE bleibt das Item unverändert QUEUED |
| `USP_RenewWorkLease` | einzelnes EXECUTE | aktive Lease verlängert |
| `USP_RecoverExpiredWork` | einzelnes EXECUTE | eigener abgelaufener Claim nach RETRY_WAIT, Token entfernt und RecoveryCount erhöht |
| `USP_CompleteWork` | einzelnes EXECUTE | eigener Claim abgeschlossen |
| `USP_FailWork` | einzelnes EXECUTE | eigener Claim mit festem synthetischem Fehler abgeschlossen |
| `USP_ScheduleWorkRetry` | einzelnes EXECUTE | eigener Claim nach RETRY_WAIT und Token entfernt |
| `USP_RequeueDeadLetter` | einzelnes EXECUTE | eigener Dead Letter nach QUEUED und neuer Retryzyklus |
| `VW_WorkQueueBarrierBlockers` | einzelnes SELECT | dieselbe tatsächliche Snapshotzeile zuerst ungelöst, nach eigenem Root-Complete aufgelöst |

Beim Claimvorlauf ist der Handler ausdrücklich sichtbar, aber nicht ausführbar.
Die eigene Queuezeile samt RowVersion bleibt unverändert; danach genügt die
zusätzliche enge Handler-EXECUTE-Berechtigung. Renew, Complete, Fail und Retry
weisen ein falsches Token mit exakt SQL51952/51923/51928/51987 ab; die eigene
Zeile samt RowVersion bleibt jeweils erhalten. Fehlende/entzogene API-Rechte,
andere öffentliche APIs, interne Kerne/Tabellen, nicht benötigter Handler,
ResultTable-Helper und Katalogverwaltung müssen mit genau SQL229 scheitern.
Breite Rollen-, Schema- und Datenbankrechte entfallen.

Die Zustandsorakel lesen als eigener Root die eigenen synthetischen Zeilen.
Die Fixture erfasst keine vollständigen Resultsets oder Clientmetadaten; auch
die Ausgabezeilenzahl des nicht reservierenden Claimvorlaufs wird hier nicht
separat erfasst. Die Blockerzeile wird als eigene Testfixture direkt angelegt.
Geprüft ist ihre Viewauswertung vor/nach einem tatsächlichen Complete, nicht
die automatische Snapshotanlage durch Barrier-Enqueue oder deren Parallelität.

## Matrix und Bereinigung

Windows/Linux SQL2019 CL150, SQL2022 CL150/160 und SQL2025 CL150/160/170
bestanden local/direct-central: zwölf Fälle, 168 Einzelgrantprofile und
24 Claim-/Handlerprofile, insgesamt 192 positive Profile. Dazu 4.776 strikte
SQL229-Abweisungen, 96 falsche Token mit genauen Fehlercodes, 24 nicht
reservierende Claimvorläufe und 48 befüllte Viewzustände.

Ein absichtlich falscher Claim-Sollstatus und ein zusätzliches fremdes Objektrecht
wurden aus den erwarteten Gründen verworfen; beide bleiben `FAILED_CLEANED`.
Alle 14 Versuche bestanden unabhängige Input-/Abwesenheitsaudits. Frische Audits
nach dem letzten Verbraucher bestätigten alle 26 eigenen Datenbanknamen als
abwesend. Eigene Handler, Principals, Policies und Fixturezeilen sind entfernt;
Moduldefinitionen, Serverkonfiguration, CLR und Assemblytrust bleiben unverändert.
Private Identitäten, Tokens und Logs bleiben lokal.

## Quellen und verbleibende Grenzen

Die [JSON-Projektion](queue-worker-rights-qualification.json) bindet konsumierte
Source-/Fixture-/Treiber-/Exportbytes und tatsächliche Fallzahlen. Die frühere
[Frontendqualifikation](QUEUE-FRONTEND-RIGHTS-QUALIFICATION.md) und
[Policyqualifikation](QUEUE-AUTHORIZATION-QUALIFICATION.md) behalten ihren
getrennten Umfang und werden nicht wiederholt. Zusammen bestehen direkte
Callerprofile aller 13 öffentlichen Queue-APIs; das ist keine volle API- oder
Modulabnahme sämtlicher Ausgabe- und Betriebsvarianten.

Worker-ResultTable-Pfade, volle Resultset-/Clientmetadaten, Managed Admission,
Completion/Holds, Workerhost-/Providerkombinationen, automatische Blocker-
Snapshots und Parallelität, volle Lifecycle-/Ressourcenverträge, echte Lowpriv-
CrossDB-Mappings und harte Recovery bleiben separat. Functional verwendet
Verschlüsselung und den expliziten Trustwert des schema-validierten Labvertrags;
authentifizierte TLS-Abnahme bleibt getrennt. Keine Produkt-, Manifest-, Status-
oder Paketänderung und keine Veröffentlichung; die [Releasegates](RELEASE-GATES.md)
gelten weiterhin.
