# Deterministische Vertragsqualifikation

Alle Fixtures sind synthetisch. Verbindliche Restfälle stehen in der
[Contract-Testmatrix](CONTRACT_TEST_MATRIX.md). Keine SQL-Konfiguration,
Infrastrukturverwaltung, CLR-Registrierung oder Rechteausweitung erforderlich.

## Historische Teilprüfungen am 2026-10-01

- `python Modules/toolbelt.pseudonymization.deterministic/Tests/Static/validate_contract.py`:
  PASS für unabhängige SHA256-/Byteformat-Referenzvektoren und Range-Sourceguards.
  12.288 synthetische Referenzfälle; kein SQL-/Optimizer-/Deploymentnachweis.
- `pwsh -NoProfile -File Tests/CI/run-lab-local.ps1 -Versions 2019 -Platforms linux -LinuxPatches latest -RunScripts run-deterministic-linux.sh -StopOnFailure`:
  initialer Adapter PASS auf SQL Server 2019 Linux CL150: Erstinstallation,
  Range-/DateShift-/Lookup-Verträge, Wiederholungsdeployment und Uninstall.
  Der erste Versuch scheiterte ausschließlich an einem Testoracle, das nach
  ResultTable-Schemaumbau lückenlose physische column_id-Werte voraussetzte.
  Nach ordinalbasiertem Testfix bestand der unveränderte Source-/Lifecycle-Stand.
- PowerShell-Parser für `Runtime/SelectMetadata.Contract.ps1`: PASS.
  Clientprobe selbst noch nicht ausgeführt.

Diese ursprüngliche Evidenz ist kein Nachweis für den späteren Safetyfixbaum.
Auch der anschließend erfolgreiche erweiterte Linux-/Windows-Lauf vom
2026-10-01 liegt vor den finalen Compilergrenzen-/Lifecycleguard-Fixes und
wird nicht als deren Qualifikation ausgegeben.
Reale Lab-Verbindungswerte und Logs bleiben außerhalb des Repositorys.

## Finaler Safetyfix-Nachweis am 2026-10-02

Der vollständige Adapter ist auf SQL Server 2019 Linux/latest CL150 PASS:
Range-/DateShift-/Lookup-Verträge und unabhängige Vektoren, Ressourcen- und
Fehlerprioritäten, ResultTable-Replace/Append einschließlich tatsächlichem
Insertfehler und Callerrollback, lokale CS-/zentrale BIN2-Collation,
administrative CrossDB-CI-Aufrufe, direkte Minimalrechte ohne Login,
clientseitige SELECT-/Help-Metadaten lokal/zentral und Lifecycle.
Alle vier inkompatiblen privaten Caller-Temps wurden einzeln geprüft:
Help erfolgreich ohne Fachprüfung, danach Fehler 54009/1 ohne Zielmutation.
Die tatsächlichen Installer-Präfixe verweigern offene Callertransaktionen
bei XACT_ABORT ON/OFF mit 50000/1, erhalten Count/State/Options/Daten und
erzeugen im separaten SQLCMD-Fixture einen nonzero Exit mit festem Prefix.
Ein relativer Runner-Eingabepfad wurde korrigiert; die scharfen Fehleroracles
wurden nicht gelockert. Cleanup der eigenen synthetischen Datenbanken erfolgt.

Finaler Windows-Safetyfix-Nachweis steht noch aus. SQL2022 und weitere
physische Targets, CrossDB-Minimalrechte, Produktionskapazität,
100000-Zeilen-Durchsatz und tatsächliche SQL-128-Reject-Exhaustion bleiben
`not executed`; der erzwungene Exhaustion-Nachweis gilt nur für die Referenz.

## Reproduzierbarer Zielscope

Der Lab-Runner validiert Export und benachbartes Schema vor der Auswahl.
Gezielt SQL Server 2019 Linux/latest und SQL Server 2025 Windows/CU8,
CL150 beziehungsweise CL150/160/170; kein impliziter Provider-/Patchfallback.
Vor jedem Lauf Slotkoordination; ausschließlich eigene disposable Testdatenbanken.
Die Windows-Auswahl bleibt exakt CU8, auch wenn allgemeine base-Auswahl
bereitstehende CU-Ziele aufgrund des Root-Overrides einschließen darf.

```powershell
pwsh -NoProfile -File Tests/CI/run-lab-local.ps1 -Versions 2019 -Platforms linux -LinuxPatches latest -RunScripts run-deterministic-linux.sh -StopOnFailure
```

Die gezielte Windows-Befehlsvariante lautet `-Versions 2025 -Platforms windows
-WindowsPatches CU8 -RunScripts run-deterministic-linux.sh -StopOnFailure`.
Sie wird erst nach freiem koordiniertem Slot ausgeführt. Weitere physische
SQL-2022-/Plattform-, CrossDB-Minimalrechte- und Kapazitätsnachweise bleiben
sichtbar getrennt. Keine harte Latenz- oder Parallelitätsgarantie.

## Lifecycle und Cleanup

Erstes Release 1.0.0: historisches Vorgängerupgrade ist `not applicable`,
nicht durch einen erfundenen Altinstaller ersetzen. Wiederholung, eigene
Source-/Function-kind-Drift, fremde Kollisionen, Marker-/Dependencydrift,
Central-Bestätigung und dependencygeschützter Uninstall gehören zum aktuellen
Pflichtscope. Der vorhandene Runner besitzt den Cleanup eigener disposable
Datenbanken; keine fremden Datenbanken, Temps oder Ressourcen entfernen.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-02`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Finaler Safetyfix-Adapter SQL Server 2019 Linux/latest CL150; API/Fehler/Grenzen/Transaktionen, vier Caller-Temp-Eclipsing/Help-Fixtures, Installer-Callertransaction ON/OFF und SQLCMD-nonzero, Local-CS/Central-BIN2, administrative CrossDB-CI, direkte Minimalrechte und Clientmetadaten lokal/zentral, Wiederholung/Drift/Kollision/Dependency/Uninstall; finaler Windowsbaum und weitere physische Targets offen
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
