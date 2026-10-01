# XLSX-Vertragsqualifizierung

Aktuelle Evidenz: `local: Tests/Runtime/Invoke-LabContract.ps1`, 2026-10-02; Linux 2019/latest und Windows 2025/CU8 erfolgreich nach finaler EOF-Formatpflege. Der Runtime-Endstand ist danach eingefroren; historische Nachweise bleiben getrennt datiert.

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
- Nachweis: `local: Tests/Runtime/Invoke-LabContract.ps1`
- Scope: Finaler identischer Fixadapter Linux 2019/latest und Windows 2025/CU8: unveränderte CLR-Binaries, vollständiger öffentlicher Vertrag, interne Help-Modi 0/1 mit NOT NULL-Metadaten, XLSX-/ZIP-Lifecycle-Callerablehnung OFF/ON und XLSX-SQLCMD50000; bekannte Restmatrix unverändert offen.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
