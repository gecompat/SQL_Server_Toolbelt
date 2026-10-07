# Deterministische Vertragsqualifikation

Alle Fixtures sind synthetisch. Verbindliche Restfälle stehen in der
[Contract-Testmatrix](CONTRACT_TEST_MATRIX.md). Keine SQL-Konfiguration,
Infrastrukturverwaltung, CLR-Registrierung oder Rechteausweitung erforderlich.

## GeoJitter 1.2.0: finaler ausgewählter Lab-Nachweis

Der [Geo-Vertrag](../../../Documentation/Architecture/DETERMINISTIC_GEO_JITTER_CONTRACT.md)
wurde vor Source unabhängig geprüft und als Commit `ebd7292` festgehalten.
Die integrierte statische Suite besteht mit 6.367 unabhängigen Geoassertions
und prüft die sieben bisherigen Source-Dateien gegen den öffentlichen
1.1-Vorgänger. Dies ist kein nativer SQL-Nachweis. Reine Read-only-UDT-
Clientmetadaten qualifizieren die vorhandene SqlClient-Verarbeitung ohne
zusätzliche Assembly; die finalen integrierten API-Metadaten sind separat bestanden.

Vor dem Native-Driver zwei unveränderte historische Fixtures getrennt mit
`Deployment/New-LegacyTestArtifacts.ps1 -Version 1.0.0` beziehungsweise
`-Version 1.1.0` und jeweils neuem privatem `-OutputDirectory` paketieren.
Dann `Tests/CI/run-deterministic-geo-lab.ps1 -Platform linux -Version 2019
-Patch latest -LegacyDirectory <1.0-Fixture> -Legacy11Directory <1.1-Fixture>`.
Windows ausdrücklich `-Platform windows -Version 2025 -Patch CU8` auswählen.
Keine Konfigurationsänderungen oder neuen Rechte; eigene GUID-Datenbanken,
private Restorejournale und bestätigter Cleanup ohne erzwungene Disconnects.
Ein eingeschränkter `RuntimeTests`-/`DeploymentModes`-Aufruf belegt nur diesen
Teil. Die finalen Läufe verwenden ausdrücklich
`-RuntimeTests @('GeoJitter.Contract.sql', 'GeoJitter.Safety.sql', 'InstalledMetadata.Contract.sql')`.

Der finale synthetische Geo-Adapter besteht auf SQL Server 2019 Linux/latest CL150 und 2025 Windows/CU8 CL150/160/170 jeweils lokal und zentral. Ausgeführt wurden ausdrücklich `GeoJitter.Contract.sql`, `GeoJitter.Safety.sql` und `InstalledMetadata.Contract.sql`, dazu SQL-/Clientmetadaten, echte 1.0.0-/1.1.0-Upgrades, Erstinstallation/Wiederholung, Caller-TX-/SET-Erhalt, Snapshot-Faults, Zukunftsslot-Erhalt, Uninstall und eigene Bereinigung. Der ursprüngliche Geo-Vertrag besteht unverändert in fünf unpartitionierten Batches mit 504 Orakeln. Die sieben bisherigen Source-Dateien bleiben bytegleich; dies ist kein erneuter finaler Runtime-Nachweis aller bisherigen APIs. Keine Konfigurations- oder Rechteänderungen. Neue Minimalrechte, weitere physische Ziele und ein exakt 129-Byte-UDT bleiben offen. Aktuelle CI wird als separater PR-Mergegate am exakten Head nachgewiesen. `partially validated`, `unreleased`.

Historische Zwischenstände vom 2026-10-02: Die ursprüngliche Ausdrucksform und kleinere Zwischenkandidaten scheiterten mit SQL-Fehler 701; ein späterer Lauf endete mit Timeout -2. Diese Läufe bleiben fehlgeschlagen, eine allgemeine Compilerursache ist nicht nachgewiesen. Der historische Vector-Facts-Kandidat bestand auf Linux mit einer vorübergehenden Partitionierung: 72 Gruppen mit je sieben Radiuswerten, zusammen dieselben 504 Orakel, eingebettet in 78 Batches einschließlich Metadaten/Goldens/Defaults, Setup, globalem Coverage-Orakel und Wiederholung. Dieser Zwischenbeleg ersetzt den finalen Nachweis der ursprünglichen fünf Batches nicht.

## Translate 1.1.0: historischer Lab-Stand vor CI-Abschluss

[PR #140](https://github.com/gecompat/SQL_Server_Toolbelt/pull/140) belegt
inzwischen Merge und alle sieben erfolgreichen CI-Prüfungen am unveränderten
finalen 1.1-Head. Dies qualifiziert keine GeoJitter-API. Der folgende Abschnitt
bewahrt den zuvor dokumentierten Lab-Stand einschließlich damaliger CI-Grenze.

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
- Nachweis: `local: Tests/CI/run-deterministic-geo-lab.ps1`
- Scope: Version 1.2.0: Linux2019/latest CL150 und Windows2025/CU8 CL150/160/170 lokal/zentral PASS; ausdrücklich GeoJitter.Contract.sql (ursprüngliche fünf unpartitionierte Batches/504 Orakel), GeoJitter.Safety.sql, InstalledMetadata.Contract.sql plus Client-/SQLmetadaten, echte1.0/1.1-Upgrades, FirstInstall/Repeat/CallerTX-SET/Snapshot-Faults/FutureSlots/Uninstall/ownCleanup; alte sieben Source-Dateien bytegleich, kein erneuter finaler Vollfamilien-Runtime-Nachweis; keine Konfigurations-/Rechteänderungen, neue Minimalrechte/weitere Targets/exakt129ByteUDT offen; aktueller CI-/PR-Mergegate am exakten Head separat nachzuweisen; unreleased
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->


## Geo-PR-CI: getrennte Version-/Compatibility-Paare

Der historische CI-Lauf [36972696140](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/36972696140)
am damaligen PR-Head bestand SQL 2019 und 2022. SQL 2025 wurde nach
Überschreiten der maximalen Joblaufzeit von 30 Minuten abgebrochen; ein
vollständiger SQL-2025-CI-Nachweis fehlt für diesen Head. Daraus wird kein
algorithmischer Fehler abgeleitet.

Historischer Aufteilungsstand vor der CL-Bindungskorrektur vom 2026-10-07:

Die folgende CI-Aufteilung enthält sechs explizite Paare: 2019/150,
2022/150, 2022/160, 2025/150, 2025/160 und 2025/170. Jeder Job führt den
vollständigen bisherigen Ablauf aus. Der gewählte CL gilt für die bestehenden
API-CL-Schleifen; frühe Vorgängerprüfungen und nachgelagerte Lifecycle-/Fault-
Aufrufe behalten ihren bisherigen Datenbank-/Default-CL-Kontext. Runtime-Fixtures
und SQL-Source bleiben unverändert. Das Limit bleibt 30 Minuten je Job,
maximal drei Jobs laufen parallel. `TBX_SQL_COMPATIBILITY_LEVEL` wählt
optional genau ein unterstütztes Paar, validiert vor Docker; ohne Variable
behält der Bash-Adapter seine bisherige Levelauswahl. Synthetische Phasenlabels
nennen Modus, Vorgänger, CL und Fixture ohne Verbindungs- oder Inventarangaben.
Aktuelle CI wird als separater PR-Mergegate am exakten neuen Head nachgewiesen;
die Aufteilung allein ist kein erfolgreicher Runtime-Nachweis.

Nachtrag 2026-10-07: Beim vorhandenen exakten CL-Opt-in werden jetzt alle
13 eigenen Datenbanken jeweils unmittelbar nach CREATE und vor ihrem ersten SQL-Skript
auf den gewählten Level gesetzt und frisch geprüft. Das umfasst Central-
Consumer, genuine 1.0/1.1-Upgrades sowie die vorhandenen Future-/Casing-/
Dependencyziele. Vor jedem SQL-Skript wird der Level erneut failclosed
geprüft; `expect_failure` startet nach fehlgeschlagenem Gate kein Skript.
Die sechs Jobs, Fixtures und Fristen bleiben unverändert. Ohne Opt-in bleibt
der oben begrenzte historische Multi-Level-Pfad erhalten. Exakte neue Head-/
Main-CI wird im zugehörigen PR getrennt belegt; keine Minimalrechte-, Heap-,
Hard-Interrupt- oder Releasequalifikation.
