# Deterministische Vertragsqualifikation

Alle Fixtures sind synthetisch. Verbindliche Restfälle stehen in der
[Contract-Testmatrix](CONTRACT_TEST_MATRIX.md). Keine SQL-Konfiguration,
Infrastrukturverwaltung, CLR-Registrierung oder Rechteausweitung erforderlich.

## Translate 1.1.0: aktuelle Qualifikation

Vor Source: 5.540 privat begrenzte Pythonassertions, unabhängig wiederholt;
48 separate Read-only-Nativassertions sind ausschließlich Primitivevidenz.
Die integrierte statische Referenzsuite besteht mit 1.746 zusätzlichen
Translateassertions. Unabhängiger Source-/Lifecycle- und Safetyreview erfolgreich.

`Tests/CI/run-deterministic-translate-lab.ps1` besteht vollständig auf Linux
2019/latest CL150 local/central: bestehende APIregressionen, neuer Translate-
Vertrag, 21 unabhängige Safetybatches mit je einem TVF-Verweis, echte 2-/16-MiB-
LOBs, fünf Fälle je vier Caller-Collations, SQL-/Clientmetadaten, echter
1.0→1.1-Upgrade, Erstinstallation/Wiederholung, CallerTX ON/OFF, Katalog-
Snapshots bei Marker-/Dependency-/Confirm-Abweisung, fremde Zukunftsslots
und historischer Uninstall-Erhalt, administrative CrossDB-Aufrufe.

Windows 2025/CU8: lokale API-/Safetyfälle CL150/160/170 erfolgreich. Der frühe
Gesamtadapter scheiterte anschließend am bekannten offenen Dependency-Temp-
Constraint; kein Gesamt-PASS. Nach Sessionkorrektur besteht der separate
lokale Metadaten-/Lifecycleadapter. Der vollständige zentrale Windows-Adapter
besteht danach unverändert auf CL150/160/170: alle sieben Slots, Safety-/
LOB-/Collationfälle, Metadaten, echtes 1.0-Upgrade, Erstinstallation/
Wiederholung, CallerTX, Snapshot-Faults/Zukunftsslots und Uninstall.
Source unverändert; abgeschlossene eigene Läufe vollständig bereinigt.

Neue direkte/CrossDB-Minimalrechte, weitere physische Targets und aktuelle CI
bleiben offen. Teilweise validiert, unveröffentlicht; keine neue Konfiguration
oder Grants und keine Produktionskapazitätszusage.

Die ersten Adapterfehler waren keine bestandenen Läufe: API-Dateien brauchen
getrennte Sessions wie SQLCMD; der Dependencyinstaller muss seine Session
beenden. Der ursprüngliche große Safetybatch lieferte keinen Abschlussnachweis;
die unveränderten Orakel werden einzeln ausgeführt, ohne Timeouterhöhung.
Keine gemessene Compileursache oder Performancezusage daraus ableiten.

Reproduzieren: zunächst echte unveränderte 1.0-Quellen mit
`Deployment/New-LegacyTestArtifacts.ps1 -OutputDirectory <neues privates Verzeichnis>`
paketieren; dann `pwsh -NoProfile -File Tests/CI/run-deterministic-translate-lab.ps1
-Platform linux -Version 2019 -Patch latest -LegacyDirectory <Fixtureverzeichnis>`.
Windows explizit `-Platform windows -Version 2025 -Patch CU8`.
`RuntimeTests` und `DeploymentModes` dürfen gezielte Nachprüfungen einschränken;
der PASS-Text nennt die tatsächlich ausgewählten Teilscopes.

Der Native-Driver validiert das benachbarte Labschema und den öffentlichen
Legacycommit vor Netzwerkzugriff, koordiniert ausgewählte Targets und führt
keine Grants/Serverkonfiguration/Truständerung durch. Restorejournal außerhalb
Git, nur bestätigte eigene GUID-Datenbanken, plain DROP nach Dispose aller
eigenen Sessions; unklarer CREATE oder gescheiterter Cleanup bleibt blockiert.
Disposable CI verwendet direkt `run-deterministic-linux.sh`, dessen Labroute
gesperrt ist; bestehende Rechtetests ausschließlich dort. Weitere physische
Targets, neue Lab-Minimalrechte/CrossDB-Minimalrechte, Produktionskapazität
und erforderliche grüne CI offen. Modul partially validated, unreleased.

## Historische Teilprüfungen am 2026-10-01

Die folgenden Befehle gehören zum damaligen 1.0-Stand. Der heutige
disposable CI-Adapter verweigert den generischen Labpfad; für 1.1 den
Native-Driver oben verwenden, für historische Wiederholung den echten Gitstand.

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

Der identische vollständige Safetyfix-Adapter ist auch auf SQL Server 2025
Windows/CU8 CL150/160/170 am 2026-10-02 PASS; eigener Cleanup abgeschlossen.
Der Source-/Deployment-/Runtime-/Adapterbaum blieb während beider finaler
Läufe unverändert. SQL2022 und weitere
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
Sie wurde nach freiem koordiniertem Slot ausgeführt. Weitere physische
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
- Nachweis: `local: Tests/CI/run-deterministic-translate-lab.ps1`
- Scope: Version 1.1.0: vollständiger Linux2019/latest CL150 local/central; bestehende APIregressionen, Translate/21Safetybatches/vier Caller-Collations/echte2MiB+16MiB/Metadaten, genuine1.0Upgrade/FirstInstall/Repeat/CallerTX/Snapshot-Faults/fremdeFutureSlots/historischerUninstall/CrossDB/ownCleanup; Windows2025/CU8 vollständiger central-Adapter CL150/160/170 PASS; lokale APIs/Safety im früheren insgesamt fehlgeschlagenen Lauf bestanden, separater korrigierter lokaler Metadaten-/Lifecycleadapter PASS; keine neuen Lab-Grants/Serverkonfiguration, weitere Targets/Minimalrechte/CI offen
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
