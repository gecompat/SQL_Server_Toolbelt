# Split-Advanced Contract Test Matrix

| Scope | Abdeckung |
|---|---|
| API | fünf Parameter und fünf Resultsetfelder; Defaultwerte, APPLY |
| Token | NULL/leer, KeepEmpty inklusive NULL, lückenlose Ordinals, Originaltokens |
| Parser | Quotes überall, Escape allgemein, längster Match, atomare Fehler |
| Unicode | BIN2, Spaces, Supplementary-Paare, NUL, Steuerzeichen-Surrogate |
| JSON | Syntax/root, nichtstring/nested/null, leer, Duplikate, Arrayreihenfolge |
| Limits | Input 65536/65537, JSON 16384/16385, 16/17, Separator 64/65 |
| Lifecycle | local/central, Driftkorrektur, fremde Kollision, Schemaerhalt, Dependencyblocker, zentrale Betreiberbestätigung |
| Collation | lokale CS_AS, zentrale BIN2, Verbraucher CI_AS |
| SELECT-Rechte | synthetische eingeschränkte User lokal und direkt im zentralen Installationskontext; keine serverweiten Login-/Trust-Fixtures |

[S2-Runtime](Runtime/SplitAdvanced.Contract.sql), [Unquoting](Runtime/UnquoteToken.Contract.sql),
[USP](Runtime/SplitAdvancedUsp.Contract.sql), [Lifecycle](Runtime/Lifecycle.Contract.sql),
[Cross-DB](Runtime/Central.Contract.sql), [MinimumRights](Runtime/MinimumRights.Contract.sql)
und [Clientmetadaten](Runtime/SelectMetadata.Contract.ps1).
Keine Performanceaufwertung aus diesen Funktionstests.

1.1.0-Scope zusätzlich: vollständige vier Unquote-Parameter/-Spalten,
Auto/Explicit/Disabled, Randpaar mindestens zwei Codeeinheiten, doubled/
single closing, Opt-in-Escape/Backslashruns, BIN2/Supplementary/NUL/Priorität,
65536/65537 und Dense-Double-Grenzfall, atomare Errorrow und APPLY.
USP: neun Parameter/Defaults, vollständiger Help-/Bypass, unveränderte
Originaltokens, SELECT-/ResultTable-Pfade, alle KeepData-/Schemaszenarien,
Callerindex/Blocker, eigener Rollback/Savepoint/doomed Caller.
Adapter exportiert den echten 1.0-Installer und seine Original-S2-Source
aus gepinntem Git-Commit 3bc644e964b8a35c4e38d3eb2d58e2b1b18631eb in
ignorierte .runtime-Artefakte; Upgrade, Kollisionspreflight für beide neuen
Namen und eigenes Uninstall werden mit synthetischen Datenbanken geprüft.
Clientprobe prüft tatsächlich SELECT-Spaltentypen/NOT-NULL/Zeilenzahl,
genau ein fachliches Resultset und Help ohne Debugmessages; aktuell Lab-only,
keine Behauptung einer ausgeführten GitHub-Clientprobe.

Der Cross-DB-Funktionstest verwendet den administrativen Testkontext.
Niedrigprivilegierter Cross-DB-Zugriff erfordert separat administrierte,
in beiden Datenbanken passende Login-/User-/SELECT-Berechtigungen; die
WITHOUT-LOGIN-/EXECUTE-AS-USER-Probe beweist keine Cross-DB-Authentifizierung.
Die zusätzlichen IF/TF-Drift- und SELECT-Minimalrechteproben wurden gezielt
auf SQL Server 2025 Linux ausgeführt, nicht rückwirkend auf anderen Zielen.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-01`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: 1.1.0: SQL Server 2019 Linux/latest und SQL Server 2025 Windows/CU8; S2-Regression, Unquoting inklusive Dense65536, USP/Help/ResultTable/OwnTransaction/Savepoint/doomed Caller, echte 1.0-Installerupgradefixture aus gepinntem Git, neue Namenskollisionen, alle API-Marker/SourceHashes, lokale/zentral-DB-Minimalrechte, administrative Cross-DB-Aufrufe. Lab-only SqlClient-Metadaten/NOT-NULL/Resultsetprobe erfolgreich. Andere neue Version-/Plattformkombinationen, GitHub-1.1-Workflow und niedrigprivilegierter mapped Caller Cross-DB nicht ausgeführt.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->

## Aktuelle Funktions- und Clientergänzung — 2026-11-08

Die [aktuelle Matrix](../../../Releases/1.0.0/SPLIT-ADVANCED-CURRENT-QUALIFICATION.md)
besteht auf allen zwölf ausgewählten Windows-/Linux-Engine-/CL-Paaren lokal und
direkt zentral: 24 Kontexte, 96 vollständige Split-/Unquote-/USP-/read-only-
Lifecyclefixtures und 24 unveränderte Clientproben, zwölf frische Audits.
Alle 24 eigenen Datenbanken entfernt, keine neue Rechtevergabe oder Serveränderung.
Die ältere pauschale Ziel-/Client-Offenangabe gilt damit nur historisch.
Die [direkten Callerprofile](../../../Releases/1.0.0/SPLIT-ADVANCED-CL-COMPLETION.md)
werden mit der im aktuellen Bericht erklärten unveränderten Fachpfadbindung
wiederverwendet. Echte Lowpriv-CrossDB-Mappings, weitere Lifecycleprofile,
Collations, Linux-Clienthost, Heap/Konkurrenz und harte Recovery bleiben getrennt.

## Gezielte Lifecycleergänzung — 2026-11-08

Der [aktuelle Nachweis](../../../Releases/1.0.0/SPLIT-ADVANCED-LIFECYCLE-QUALIFICATION.md)
schließt 240 gezielte Profile auf zwölf Engine-/CL-Paaren lokal/direkt zentral:
exakte Versions-/Bestätigungs-/Consumerabweisungen, kanonische Drift-/Typreparatur,
Fremdobjekterhalt, Neuinstallation, Leerschemaentfernung und fehlendes Uninstall.
Lokale CS_AS-/zentrale BIN2-Collation nativ bestätigt; zwölf frische Audits,
alle 24 eigenen DBs entfernt. Frühere allgemeine Linux-Lifecyclefälle bleiben
enger gebunden; alte grüne API-/Client-/Rechtefixtures wurden nicht wiederholt.
Weitere Genuine-/Rollback-/Session-, Consumer-Collation-, Rechte-/
Identitäts-/Ressourcen-/Recoveryprofile bleiben separat.

## AppLock mit getrennter Sitzung — 2026-11-08

Die [gezielte Sperrmatrix](../../../Releases/1.0.0/SPLIT-ADVANCED-APPLOCK-QUALIFICATION.md)
ergänzt zwölf vollständige Läufe, 24 lokale/direkt zentrale Windows-/Linux-
Kontexte und 96 Profile: 48 exakte 51677/State1-Abweisungen von Deploy/Uninstall
unter tatsächlich bestätigter exklusiver Sitzungssperre und 48 erfolgreiche
Schritte nach eigener verifizierter Freigabe. Verschiedene positive Sitzungs-IDs,
weiterhin gehaltene Sperre, NoLock nach Release, neutrale Transaktionen und
erhaltene Core-Definitionen sind geprüft. Zwölf frische Audits bestätigen alle
24 eigenen DBs entfernt und unveränderte Serverkonfiguration/Trust.
Der 24-Aufrufe-/24-DB-/45-Minuten-Rahmen ist ohne Wiederholung geschlossen.
Frühere pauschale AppLock-Offenangaben gelten nicht für diesen Scope; allgemeine
Race-/Rollback-/SET-/Caller-/Identitäts-/Ressourcen-/Recoveryprofile bleiben separat.

## Echter gemappter SQL-Netzwerkcaller — 2026-11-09

Die [gezielte Ergänzung](../../../Releases/1.0.0/SPLIT-ADVANCED-MAPPED-CALLER-QUALIFICATION.md)
schließt den ausgewählten zentralen Windows-SQL2025/CU8-/CL170-Pfad mit
getrennter Consumer-DB: echter SQL-TCP-Login, zwei SID-genaue Zuordnungen,
drei gezielte DB-Rechte, ein positives Drei-Token-Orakel und fünf strikte
Rechteabweisungen einschließlich Widerruf. Zwei frische Audits bestätigen
Cleanup beider Versuche; der erste Adapterfehler bleibt FAILED_CLEANED.
Frühere pauschale CrossDB-Offenangaben gelten nicht mehr für diesen Scope.
Windows/Kerberos/SSMS, andere Netzwerkzielpaare und weitere APIs bleiben separat.
