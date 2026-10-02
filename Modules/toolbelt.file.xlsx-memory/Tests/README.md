# XLSX-Vertragsqualifizierung

## Additive 1.1-Typwelle – 2026-10-02

Frameworkqualifikation: 19311 Assertions in drei Kulturen PASS. Der begrenzte unabhängige Scannervergleich führte 12370 Vergleiche ohne Abweichung aus. Aktuelle Releasebuild-/IL-/NoIO-Prüfungen sind separate Offline-Evidenz, keine Heapgarantie.

XLSX 1.1.0 ergänzt die einzeln freigegebene `TVF_InterpretXlsxCell` im bestehenden SAFE-Provider. Der finale öffentliche Typadapter bestand am 2026-10-02 auf SQL Server 2019 Linux/latest CL150 und 2025 Windows/CU8 CL150/160/170 jeweils lokal und zentral: drei Types-Runtime-Fixtures, exakte Zahlen-/100-ns-/NULL-/Clientmetadaten, clean/genuine 1.0/Repeat, Caller-TX OFF/ON intakt und doomed, AppLock, postDROP/preCOMMIT-Rollback, historische Zukunftsslots, Sichtbarkeitsprädikate, Uninstall und eigene Bereinigung. Raw→Type-Komposition wurde nach den API-CL-Schleifen auf der jeweils letzten CL (2019:150, 2025:170) sowie separat im zentralen Caller geprüft. Keine Konfigurations- oder Rechteänderungen. Die öffentliche Pfadfassung bestand nach ihrem unabhängig geprüften Port auf beiden ausgewählten Targets einschließlich frischer eigener Bereinigungsprüfungen. Aktuelle CI wird separat am exakten PR-Head als Mergegate geprüft. Tatsächliche Minimalrechte, weitere physische Ziele und Heap-/Produktionskapazität bleiben offen. `partially validated`, `unreleased`; historische Raw-1.0-Evidenz bleibt getrennt.

Die drei ausgeführten SQL-Dateien sind `Types.Contract.sql`, `Types.Safety.sql` und `Types.Lifecycle.sql`. `Types.Metadata.ps1` sowie zusätzliche native Nullability-/Sichtbarkeits-/Lifecycleorakel werden vom Adapter separat ausgeführt. Die Workbook-Komposition liegt in `Types.Composition.sql`, `Types.Composition.xlsx` und `Invoke-TypesComposition.ps1`; sie verwendet neun synthetische Raw-Zellen, bytegenaue Echos, unveränderte Formel-/Cachetrennung sowie Number42 mit Precision2/Scale0. Die Fixture enthält sechs XML-Parts aus der vorhandenen synthetischen Frameworkoracle, sortierte Stored-ZIP-Entries und feste synthetische Zeitstempel; keine realen Workbooks. Der Typkern und sieben bestehende Raw-Source-Dateien bleiben gegenüber der qualifizierten Revision unverändert.

### Öffentlicher reproduzierbarer Typadapter

`Tests/CI/run-xlsx-types-lab.ps1` benötigt vorher gebaute aktuelle und unveränderte genuine-1.0-Artefakte. Die beiden Generatoren sind `Scripts/New-ClrReleaseArtifacts.ps1` und `Scripts/New-Xlsx10LegacyFixture.ps1`. Alle Verzeichnisse werden über Parameter übergeben, nicht aus privaten Pfaden abgeleitet.

```powershell
pwsh -NoProfile -File Tests/CI/run-xlsx-types-lab.ps1 -Platform linux -Version 2019 -Patch latest -ReleaseDirectory $release -LegacyDirectory $legacy -ExpectedDriverSHA256 $driverHash -ExpectedAssemblySHA512 $assemblyHash -ExpectedLegacyProvenanceSHA256 $legacyHash -ExpectedPromptSHA256 $promptHash -OptInExactTrust
pwsh -NoProfile -File Tests/CI/run-xlsx-types-lab.ps1 -Platform windows -Version 2025 -Patch cu8 -ReleaseDirectory $release -LegacyDirectory $legacy -ExpectedDriverSHA256 $driverHash -ExpectedAssemblySHA512 $assemblyHash -ExpectedLegacyProvenanceSHA256 $legacyHash -ExpectedPromptSHA256 $promptHash -OptInExactTrust
```

Die Hashargumente werden aus den konkret überprüften Dateien ermittelt; Beispielvariablen sind keine vorgegebene Freigabe. Vor Ausführung sind aktueller Labexport/Schema, ausdrücklich ausgewählter READY-Selektor, Zusatzprompt und Artefakte zu prüfen. `OptInExactTrust` ist standardmäßig aus; der Test setzt vorhandene Berechtigungen und bereits wirksame CLR-Konfiguration voraus. Keine Rechte- oder Konfigurationsänderungen. Private Journale enthalten nur eigenen Wiederherstellungsscope; öffentliche Evidence enthält keine Journale oder Infrastrukturwerte. Preexisting Trust wird nie entfernt; frische DB-/Trustidentitäten und fremde Consumer werden vor Cleanup geprüft. Unklarer Cleanup blockiert PASS. Der Driver pinnt alle konsumierten Helfer/Includes sowie die drei Kompositionsinputs vor und nach Ausführung. SQL und Workbook werden im Kompositionshelfer aus geprüften Byte-Snapshots konsumiert.

Die public-Portierung ändert nur Argument-/Pfadermittlung, Repository-Dateinamen und zugehörige Pins; deren Rücksubstitution ergibt exakt den qualifizierten privaten Driver/Helper. Die öffentliche Pfadfassung besteht auf Linux 2019/latest CL150 und Windows 2025/CU8 CL150/160/170 lokal/zentral samt voller Qualifikation und anschließenden frischen eigenen Bereinigungsprüfungen. Aktuelle CI wird separat am exakten PR-Head als Mergegate geprüft.

### Historische 1.1-Adapterfehler

- `EXACT_TRUST`, SQL214/State191: MAX-Argumente des Testadapters; feste lokale Hash64-/Description4000-Argumente geschlossen. Frischer eigener Abwesenheitsaudit war separat erfolgreich, kein Gesamt-PASS des Fehllaufs.
- `CALLER_local_ON_False`, SQL51592/State3: nested-EXEC-Testtopologie; Engineeffekt wurde ohne Toolbelt reproduziert. Direkte intakte Clientbatches und inline doomed Witness-Topologie ersetzen den Oracle, ohne Produktänderung oder Lockerung.
- `ROLLBACK_local`, SCRIPT_FAILED: unanchored Commit-Seam traf auch zwei Raw-USP-Commits in Includes. Exakte zeilenverankerte Installerstelle geschlossen; eingebundene Raw-Commits unverändert.

Frühere FAILED-Läufe bleiben FAILED; eigene Bereinigung wurde jeweils separat geprüft. Der finale private Adapter bestand auf beiden ausgewählten Targets samt anschließender frischer eigener Cleanup-Prüfung. Keine privaten Fehlertexte oder Runtime-Inventare werden versioniert.

## Historische 1.0-Raw-Evidenz

Historische 1.0-Evidenz: `local: Tests/Runtime/Invoke-LabContract.ps1`, 2026-10-02; Linux 2019/latest und Windows 2025/CU8 erfolgreich nach finaler EOF-Formatpflege. Der damalige Runtime-Endstand ist getrennt erhalten; kein 1.1-PASS.

Stand: 2026-10-01. Die Nachweise verwenden ausschließlich synthetische Workbooks. Keine Lab-Adressen, Zugangsdaten, Datenbanknamen oder Originalausgaben werden gespeichert.

## Reproduzierbare Befehle

```powershell
powershell -NoProfile -File Spikes/XlsxMemory/Run-FrameworkQualification.ps1
python Modules/toolbelt.file.xlsx-memory/Tests/Static/validate_contract.py
python Modules/toolbelt.archive.zip-memory/Tests/Static/validate_contract.py
pwsh -NoProfile -File Modules/toolbelt.file.xlsx-memory/Tests/Runtime/Invoke-LabContract.ps1 -Platform windows -Version 2025 -Patch cu8
pwsh -NoProfile -File Modules/toolbelt.file.xlsx-memory/Tests/Runtime/Invoke-LabContract.ps1 -Platform linux -Version 2019 -Patch latest
```

Vor dem Labadapter werden aktuelle ZIP-/XLSX-Releaseartefakte sowie die gepinnte echte ZIP-1.3-Fixture über die jeweiligen `Scripts/New-ClrReleaseArtifacts.ps1` und `Scripts/New-Zip13LegacyFixture.ps1` erstellt. Der Adapter prüft den schema-validierten Export, den ausdrücklich gewählten READY-Selektor und vorhandene CLR-Konfiguration. Er installiert ausschließlich in eigenen disposable Datenbanken und entfernt eigene Datenbanken und neu angelegte eigene Trusteinträge. Kein automatischer Plattformfallback oder Infrastrukturmanagement.

## Ausgeführte Nachweise

- Framework 4.8: PASS für Stored/Deflate, Rohtext-/String-/Formel-/Cachetrennung, Unicode, leere/fehlende Werte, Grenzkoordinaten, ausgewählte negative Package-/XML-/Ressourcenfälle und vier unabhängige kleine parallele Aufrufe.
- Tatsächliche 100000/100001 Zellen, 8 MiB Shared-String-Text plus eine UTF-16-Codeeinheit, exakte reduzierte interne Chargegrenze und Überschreitung sowie wiederholte Shared-String-Outputexpansion: PASS.
- Begrenzte NoIO-Sandbox mit tatsächlich verweigerten File/Web/IsolatedStorage/Unmanaged/Security-Canaries, External-/DTD-Fixtures und positive IL/API-Allowlist für die eigenen drei Binaries: PASS. Kein vollständiger OS-Trace und kein transitive Framework-IL-Beweis.
- SQL Server 2025 Windows/CU8, aktuelles Releasebinary: PASS für tatsächliche SAFE-Aufrufe, local/central/cross-database, SELECT-/NULL-/Help-Clientmetadaten, ResultTable, Compilergrenze, erwartete atomare Fehler, Outputexpansion, eigene/Caller-Transaktionen einschließlich XACT_ABORT OFF/ON, Redeploy und Uninstall.
- Echte ZIP 1.3 nach 1.4: PASS auf Windows; tatsächliche installierte Assemblybytes werden gegen beide Manifesthashes geprüft. Bestehender Writer-SQL-Vertrag und unabhängiger ZIP-Writer-Frameworkharness: PASS auf dem erweiterten ZIP-Binary.
- SQL Server 2019 Linux/latest: abschließender identischer vollständiger Adapter auf demselben aktuellen Binary PASS, einschließlich local/central/cross-database, Outputcharge, NULL-Metadaten, Transaktionen, tatsächlichen SAFE-Aufrufen, echter ZIP-1.3→1.4-Fixture, Writerregression und eigener Bereinigung.

Abschließender Fixnachweis 2026-10-02: dieselben beiden Labselektoren und unveränderte CLR-Binaries erneut vollständig PASS. Zusätzlich qualifiziert sind die zwölf NOT NULL-konformen internen Help-Spalten für Modus 0/1, XLSX- und ZIP-Deploy/Uninstall-Ablehnung vorhandener Caller-Transaktionen bei XACT_ABORT OFF/ON mit unveränderter Caller-Arbeit, Count/State/Optionen und Releasebestand sowie XLSX-SQLCMD-Abbruch mit Fehler 50000 und Nonzeroexit. Ein vorheriger Fixlauf scheiterte ausschließlich an der neuen SQLCMD-Testanmeldung; er wurde nicht als PASS gewertet und eigene Probeobjekte wurden bereinigt. Der Testadapter verwendet jetzt frische validierte Prozesscredentials statt des nach Open bereinigten ConnectionString. Große unbenutzte Platzhalter werden vor Replace geprüft; vorhandene, fehlende und wiederholte Platzhalter liefern dieselbe Ausgabe. Framework-/Sandbox-/IL- und unabhängige ZIP-Writer-Prüfung wurden ebenfalls erneut erfolgreich ausgeführt.

## Einschränkungen

Die [Testmatrix](XLSX_CONTRACT_TEST_MATRIX.md) trennt konkrete Nachweise von offenen Fällen. Nicht sämtliche konfigurierten numerischen Ceilings wurden als reale große Archive ausgeschöpft. Peak-RAM, Produktionskapazität, minimale EXECUTE-Rechte, sämtliche unterstützten SQL-/Plattformkombinationen und hosted CI wurden nicht qualifiziert. Das Modul bleibt teilweise validiert und unveröffentlicht. Eine gebaute Pipeline ist kein ausgeführter CI-Nachweis.

Exakte SHA2-512-Werte werden in den reproduzierbaren, lokal erzeugten Release-/Trustmanifesten geführt; der CI-Gate vergleicht sie mit den qualifizierten Binaries. Das kooperative Parserbudget ist keine Garantie für SQL-Marshalling oder Gesamtwallclock.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-02`
- Nachweis: `local: Tests/CI/run-xlsx-types-lab.ps1`
- Scope: Finaler identischer öffentlicher XLSX1.1-Adapter Linux2019/latest CL150 und Windows2025/CU8 CL150/160/170 jeweils local/central: drei Types-Fixtures, SQL-/Client-/native Nullability, clean/genuine1.0/repeat, CallerOFF/ON intakt/doomed, AppLock, postDROP/preCOMMIT-Rollback, historische Zukunftsslots, synthetische0/NULL-Sichtbarkeitsgates, Consumer/Uninstall; RawType nach API-Schleifen auf letzterCL150/170 plus zentralerCaller. Voller PASS samt frischen eigenen Cleanup-Audits. Keine Konfigurations-/Rechteänderungen. Aktuelle CI wird separat am exakten PR-Head als Mergegate geprüft. Tatsächliche Lowpriv-Rechte, übrige physische Targets und Heap/Produktionskapazität offen. Historische FAILED-Adapterstände bleiben getrennt.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
