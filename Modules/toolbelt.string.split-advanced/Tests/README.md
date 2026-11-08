# Split-Advanced Tests

[Matrix](SPLIT_ADVANCED_CONTRACT_TEST_MATRIX.md). Synthetische Tests ohne Persistenz realer Runtime-Ausgaben.

Statisch: `python Modules/toolbelt.string.split-advanced/Tests/Static/validate_contract.py`.

Runtime: `pwsh -NoProfile -File Tests/CI/run-lab-local.ps1 -Versions 2025 -Platforms linux -RunScripts run-split-advanced-linux.sh`. Weitere Zielversionen/Plattformen scopebezogen über dieselben Parameter. Lab-Adapter verwaltet keine Infrastruktur; synthetische Testdatenbanken werden vom vorhandenen Shim isoliert und entfernt.

GitHub-hosted Matrix: [Workflow](../../../.github/workflows/split-advanced-runtime.yml). Ein vorhandener Workflow ist kein Nachweis seiner Ausführung.

1.1.0 ergänzt Unquoting-, USP-, MinimumRights- und Lab-only SqlClient-
Metadaten-/Resultsetproben. Der gepinnte 1.0-Installer stammt per git archive
aus 3bc644e964b8a35c4e38d3eb2d58e2b1b18631eb; erzeugte Exporte in
ignorierter .runtime sind keine versionierten Kopien oder Runtime-Logs.
GitHub-Checkout benötigt die Commit-Historie. Niedrigprivilegierter Cross-DB-
Caller bleibt separat offen; direkte lokale/zentral-DB-Probe ist kein Ersatz.

Am 2026-10-01 ist zusätzlich die [GitHub-hosted Linux-Matrix 2019/2022/2025](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/36857332229) erfolgreich ausgeführt worden. Dieser ergänzende CI-Nachweis ersetzt weder die physischen Labtests noch fehlende Windows-/mapped-Caller-Proben. Der unten generierte Nachweis beschreibt den vorherigen lokalen Reviewlauf.

## Command-/Reader-Ownership der Clientprobe – 2026-10-09

`Runtime/SelectMetadata.Contract.ps1` schützt eigene Commands vor Property- und ExecuteReader-Aufnahme. Die Readerfreigabe ist nullgeschützt; ein unabhängiges verschachteltes finally erreicht Command.Dispose auch bei einem Reader.Dispose-Fehler. Dispose-Fehler können nach bestehender PowerShell-Semantik einen vorherigen Fehler ersetzen; keine Garantie zur getrennten Erhaltung beider Fehler.

Quellenstand SOURCE_ONLY, neue lokale/native Qualifikation NOT_EXECUTED. Der vorhandene Caller führt diese Probe ausschließlich im Lab-Pfad aus; hosted CI allein qualifiziert die geänderte Aufnahme-/Fehlerroute nicht. SQL-Texte, Timeouts, Orakel und Erfolgmarker bleiben unverändert. Der folgende generierte Nachweis bleibt historische Evidenz seines damaligen Quellstands.

## Aktuelle Funktions- und Clientmatrix — 2026-11-08

Der [aktuelle Nachweis](../../../Releases/1.0.0/SPLIT-ADVANCED-CURRENT-QUALIFICATION.md)
schließt die Funktions-/USP-/Clientmatrix auf zwölf Windows-/Linux-Engine-/CL-Paaren
lokal und direkt zentral: 24 Kontexte, 96 vollständige Original-SQL-Fixtures,
24 originale Clientproben und zwölf frische Audits; alle 24 eigenen DBs entfernt.
Damit ist auch der Erfolgsweg der oben historisch nur quellseitig geprüften
Command-/Readeraufnahme nativ ausgeführt. Keine injizierten Dispose-Fehler.
Die vorhandenen [Callerrechte](../../../Releases/1.0.0/SPLIT-ADVANCED-CL-COMPLETION.md)
bleiben bei der im Bericht erklärten Eingangs-/Fachpfadbindung verwendbar und
wurden nicht wiederholt. Weitere Lifecycle-/Collation-/Ressourcen-/Recovery-
und echte Lowpriv-CrossDB-Fälle bleiben separat. `partially validated`, `unreleased`.

## Historische Validierungsevidenz — 2026-10-01

Die folgenden Befehle wurden am 2026-10-01 mit dem finalen 1.1.0-Adapter
erfolgreich ausgeführt (Exit 0); keine reale Ausgabe wird versioniert:

~~~powershell
pwsh -NoProfile -File Tests/CI/run-lab-local.ps1 -Versions 2019 -Platforms linux -RunScripts run-split-advanced-linux.sh -StopOnFailure
pwsh -NoProfile -File Tests/CI/run-lab-local.ps1 -Versions 2025 -Platforms windows -WindowsPatches CU8 -RunScripts run-split-advanced-linux.sh -StopOnFailure
python Modules/toolbelt.string.split-advanced/Tests/Static/validate_contract.py
~~~

SQL Server 2019 Linux/latest und 2025 Windows/CU8 wurden scopebezogen
ausgewählt, keine neue vollständige Sechs-Ziel-Matrix. Der Dense65536-Fall
ist ein Grenzfunktionstest, keine Durchsatz-/Performancebaseline.
Clientmetadatenprobe wurde im lokalen CS_AS-Datenbankkontext ausgeführt;
die zentralen fachlichen ResultTable-/TVF-Proben nutzen denselben Adapter.

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-01`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: 1.1.0: SQL Server 2019 Linux/latest und SQL Server 2025 Windows/CU8; S2-Regression, Unquoting inklusive Dense65536, USP/Help/ResultTable/OwnTransaction/Savepoint/doomed Caller, echte 1.0-Installerupgradefixture aus gepinntem Git, neue Namenskollisionen, alle API-Marker/SourceHashes, lokale/zentral-DB-Minimalrechte, administrative Cross-DB-Aufrufe. Lab-only SqlClient-Metadaten/NOT-NULL/Resultsetprobe erfolgreich. Andere neue Version-/Plattformkombinationen, GitHub-1.1-Workflow und niedrigprivilegierter mapped Caller Cross-DB nicht ausgeführt.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->

## Aktuelle gezielte Lifecycleprofile — 2026-11-08

Die [aktuelle Lifecyclematrix](../../../Releases/1.0.0/SPLIT-ADVANCED-LIFECYCLE-QUALIFICATION.md)
belegt zwölf Windows-/Linux-Engine-/CL-Paare lokal/direkt zentral: 240 gezielte
Profile, zwölf frische Audits und 24 entfernte eigene Datenbanken. Unbekannte
Marker, exakte Bestätigungs-/Consumerabweisungen, kanonische Drift-/Typreparatur,
Fremdobjekterhalt, Neuinstallation und fehlendes Uninstall sind in lokalen
CS_AS-/zentralen BIN2-Kontexten qualifiziert. Alte API-/Client-/Rechtefixtures
wurden nicht erneut ausgeführt. Weitere Genuine-/Rollback-/Session-/
Consumer-Collation-/Ressourcen-/Identitätsprofile bleiben getrennt.

## AppLock mit getrennter Sitzung — 2026-11-08

Der [aktuelle Sperrnachweis](../../../Releases/1.0.0/SPLIT-ADVANCED-APPLOCK-QUALIFICATION.md)
ergänzt 24 lokale/direkt zentrale Windows-/Linux-Kontexte und 96 Profile:
Deploy und Uninstall weisen unter tatsächlich gehaltener fremder Sitzungssperre
exakt mit 51677/State1 ab; nach verifizierter eigener Freigabe funktionieren
beide. Zwölf frische Audits, alle 24 eigenen Datenbanken entfernt, keine neuen
Rechte oder Server-/Labänderungen. Kein allgemeiner Race-/Recoverynachweis;
übrige Modulpflichtfälle bleiben getrennt, Status teilweise validiert/unveröffentlicht.
