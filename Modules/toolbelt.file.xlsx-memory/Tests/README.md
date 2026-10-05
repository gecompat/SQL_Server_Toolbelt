# XLSX-Vertragsqualifizierung

## Additive 1.1-Typwelle – 2026-10-02

Frameworkqualifikation: 19311 Assertions in drei Kulturen PASS. Der begrenzte unabhängige Scannervergleich führte 12370 Vergleiche ohne Abweichung aus. Aktuelle Releasebuild-/IL-/NoIO-Prüfungen sind separate Offline-Evidenz, keine Heapgarantie.

XLSX 1.1.0 ergänzt die einzeln freigegebene `TVF_InterpretXlsxCell` im bestehenden SAFE-Provider. Der finale öffentliche Typadapter bestand am 2026-10-02 auf SQL Server 2019 Linux/latest CL150 und 2025 Windows/CU8 CL150/160/170 jeweils lokal und zentral: drei Types-Runtime-Fixtures, exakte Zahlen-/100-ns-/NULL-/Clientmetadaten, clean/genuine 1.0/Repeat, Caller-TX OFF/ON intakt und doomed, AppLock, postDROP/preCOMMIT-Rollback, historische Zukunftsslots, Sichtbarkeitsprädikate, Uninstall und eigene Bereinigung. Raw→Type-Komposition wurde nach den API-CL-Schleifen auf der jeweils letzten CL (2019:150, 2025:170) sowie separat im zentralen Caller geprüft. Keine Konfigurations- oder Rechteänderungen. Die öffentliche Pfadfassung bestand nach ihrem unabhängig geprüften Port auf beiden ausgewählten Targets einschließlich frischer eigener Bereinigungsprüfungen. Aktuelle CI wird separat am exakten PR-Head als Mergegate geprüft. Tatsächliche Minimalrechte, weitere physische Ziele und Heap-/Produktionskapazität bleiben offen. `partially validated`, `unreleased`; historische Raw-1.0-Evidenz bleibt getrennt.

Die drei ausgeführten SQL-Dateien sind `Types.Contract.sql`, `Types.Safety.sql` und `Types.Lifecycle.sql`. `Types.Metadata.ps1` sowie zusätzliche native Nullability-/Sichtbarkeits-/Lifecycleorakel werden vom Adapter separat ausgeführt. Die Workbook-Komposition liegt in `Types.Composition.sql`, `Types.Composition.xlsx` und `Invoke-TypesComposition.ps1`; sie verwendet neun synthetische Raw-Zellen, bytegenaue Echos, unveränderte Formel-/Cachetrennung sowie Number42 mit Precision2/Scale0. Die Fixture enthält sechs XML-Parts aus der vorhandenen synthetischen Frameworkoracle, sortierte Stored-ZIP-Entries und feste synthetische Zeitstempel; keine realen Workbooks. Der Typkern und sieben bestehende Raw-Source-Dateien bleiben gegenüber der qualifizierten Revision unverändert.

### Öffentlicher reproduzierbarer Typadapter

`Tests/CI/run-xlsx-types-lab.ps1` benötigt vorher gebaute aktuelle und unveränderte genuine-1.0-Artefakte. Die beiden Generatoren sind `Scripts/New-ClrReleaseArtifacts.ps1` und `Scripts/New-Xlsx10LegacyFixture.ps1`. Alle Verzeichnisse werden über Parameter übergeben, nicht aus privaten Pfaden abgeleitet.

```powershell
pwsh -NoProfile -File Tests/CI/run-xlsx-types-lab.ps1 -Platform linux -Version 2019 -Patch latest -ReleaseDirectory $release -LegacyDirectory $legacy -Legacy11Directory $legacy11 -ExpectedLegacy11ProvenanceSHA256 $legacy11Hash -ExpectedDriverSHA256 $driverHash -ExpectedAssemblySHA512 $assemblyHash -ExpectedLegacyProvenanceSHA256 $legacyHash -ExpectedPromptSHA256 $promptHash -OptInExactTrust
pwsh -NoProfile -File Tests/CI/run-xlsx-types-lab.ps1 -Platform windows -Version 2025 -Patch cu8 -ReleaseDirectory $release -LegacyDirectory $legacy -Legacy11Directory $legacy11 -ExpectedLegacy11ProvenanceSHA256 $legacy11Hash -ExpectedDriverSHA256 $driverHash -ExpectedAssemblySHA512 $assemblyHash -ExpectedLegacyProvenanceSHA256 $legacyHash -ExpectedPromptSHA256 $promptHash -OptInExactTrust
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
pwsh -NoProfile -File Modules/toolbelt.file.xlsx-memory/Tests/Framework/Invoke-CandidatePackaging.ps1 -OutputDirectory .runtime/xlsx-candidate
pwsh -NoProfile -File Spikes/XlsxMemory/Run-FrameworkQualification.ps1 -XlsxDirectory .runtime/xlsx-candidate/xlsx -ZipDirectory .runtime/xlsx-candidate/zip -OutputDirectory .runtime/xlsx-candidate/qualification
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
- Datum: `2026-10-05`
- Nachweis: `local: Tests/CI/run-xlsx-types-lab.ps1 -QualificationScope DisplayCentralLifecycle`
- Scope: Linux2019/latest zentral CL150: vier postDROP/preCOMMIT-Rollbackfälle und zwei AppLock-Abweisungen; separate positive aktuelle1.2-Installation, neun Slots/vier CLR-Bindings/SAFE-Binaryhash/Modus/CL und vollständiger vorhandener Lifecycle-Snapshot vor/nach, neutraler Sitzungszustand zwischen Statements, bestätigter Uninstall. Eigener äußerer Prozesswatchdog, Exit0 und vollständige private Kanäle; frischer unabhängiger Audit bestätigt eine OwnDB/zwei OwnTrust-Hashes abwesend, keine Konfigurations-/Rechteänderungen. Früherer gemischter Setup-Prüflauf bleibt FAILED_CLEANED; gezielter Read-only-Probe begründet getrennte Transaktionsprüfung. API/Consumer/Upgrade nicht wiederholt; weitere Lifecycle-/Kollisionsmatrix, Minimalrechte, Heap und Ziele offen; partially validated/unreleased.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->

## Anzeigeformatierung 1.2.0 – Source und Nachweisgrenzen

Stand 2026-10-03, Codex. Die konkrete Kulturmenge en-US/de-DE/tr-TR,
half-away-from-zero, Datetimecarry/time24h-Status8 und unveränderte Typquote
wurden einzeln bestätigt. Die vorhandene SAFE-Assembly wird additiv erweitert;
keine neue Rechte-/Providergrenze. Historische Raw-/Type-Evidenz bleibt getrennt.
Private Renderer-/Transport- und minimale SQL-Bindungsproben einschließlich
Fehlerbereinigung bestanden; sie belegen keinen vollständigen 1.2-Produktlauf.

Reproduzierbare neue Quellen: `Tests/Framework/Invoke-Display.ps1` mit eigenem
frischem privaten Ausgabeverzeichnis, konservativen Einzelprozessdeadlines,
Source-/Tool-/Outputpins und vollständigen privaten Kanälen; drei Kulturen und
CLR-Transport. Geplante Counts werden erst nach tatsächlichem Lauf als Evidenz
übernommen. SQL-Fixtures `Display.Contract.sql`, `Display.Safety.sql`,
`Display.Lifecycle.sql`, `Display.Metadata.ps1`, `Display.Composition.sql`;
Komposition verwendet das unveränderte synthetische Types.Composition.xlsx.

Der öffentliche Labadapter verlangt zusätzlich `Legacy11Directory` und
`ExpectedLegacy11ProvenanceSHA256`; beide echten Vorgängerpakete entstehen durch
`Scripts/New-Xlsx10LegacyFixture.ps1` und `Scripts/New-Xlsx11LegacyFixture.ps1`.
Genuine Quellen bleiben Original-Gitblobs, keine Marker-Umetikettierung.
Default sind drei Types- und drei Display-Fixtures je ausgewählter CL/Modus;
Displayclient und Raw→Type→Display-Komposition werden zusätzlich gebunden.

Der Opt-in `-QualificationScope DisplayCentral10Upgrade` begrenzt den Adapter
auf Linux2019/latest, zentral und CL150. Er installiert genuine1.0 und führt
ein Upgrade auf1.2 über eine frische Session aus. Danach folgen Display.Lifecycle,
neun Slots/vier CLR-Bindings, Repeat, Display.Contract/Safety ausschließlich in
der Installationsdatenbank sowie Display.Metadata und Raw→Type→Display aus
einer frischen Consumerdatenbank. Confirm0-Abweisung, Uninstall und die
vorhandenen Ownership-/Cleanupgates bleiben aktiv. Legacy1.1 wird weiterhin
offline gepinnt, erhält in diesem Slice aber keinen Trusteintrag. `Full`
bleibt der unveränderte Default; der Slice behauptet dessen übrige Fälle nicht.

Am 2026-10-05 bestand dieser Scope mit äußerem eigenem Prozesswatchdog, Exit0
und vollständigen privaten Kanälen. Zwei eigene Datenbanken wurden entfernt,
drei exakte Trust-Vorzustände wiederhergestellt; ein unabhängiger Audit über eine
neue Verbindung bestätigte OwnDB-/OwnTrustabwesenheit. Keine Konfigurations- oder
Rechteänderungen. Damit sind zentrale1.2-Consumerverwendung und genuine1.0→1.2
für Linux2019/latest CL150 begrenzt qualifiziert. Weitere Ziele, vollständige
Lifecycle-/Kollisionsmatrix, Minimalrechte und Heap bleiben offen.

Der weitere Opt-in `-QualificationScope DisplayCentralLifecycle` erzwingt
denselben Linux2019/latest-/central-/CL150-Scope und akzeptiert ausdrücklich
nur Display.Lifecycle.sql als Runtimeauswahl. Aktuelle1.2 wird einmal als
Testvoraussetzung installiert; nur current-XLSX und ZIP erhalten gegebenenfalls
eigene Trusteinträge, beide Vorgänger bleiben offline gepinnt. Die bestehenden
Helper führen vier postDROP-/preCOMMIT-Injektionen und zwei AppLock-Abweisungen
aus. Fallzahlen werden erst nach vollständigem Helperabschluss journalisiert.
Vor-/Nachzeugen prüfen den vorhandenen vollständigen Lifecycle-Snapshot,
neun Slots/vier CLR-Bindings, SAFE-Binaryhash, Modus/CL150 und neutralen
Sessionzustand zwischen Statements. Bestätigter Uninstall und eigene frische
Disposition bleiben verpflichtend; API, Consumer und Upgrades sind ausgenommen.

Am 2026-10-05 bestand dieser Scope mit äußerem eigenem Prozesswatchdog, Exit0
und vollständigen privaten Kanälen. Der unabhängige frische Audit bestätigte
eine OwnDB und zwei eigene Trust-Hashes abwesend, ohne Konfigurations-/
Rechteänderungen. Ein früherer Setup-Prüflauf bleibt FAILED_CLEANED und
qualifizierte keine Negativfälle. Ein gezielter Read-only-Probe auf SQL2019
reproduzierte den aktiven Transaktionszustand im gemischten Katalogprädikat;
die getrennte katalogfreie Prüfung zwischen Statements blieb neutral.
Alle ursprünglichen Setupbedingungen bleiben aktiv. Dies ist ein begrenzter
separater Lifecycle-Nachweis, keine volle Kollisions- oder Plattformmatrix.

Am 2026-10-04 bestand ein privater Qualifikationsadapter auf SQL Server 2019 Linux/latest CL150 und SQL Server 2025 Windows/exakt CU8 CL170 jeweils ausschließlich lokal: Clean1.2 und genuine installierte1.1→1.2 mit frischer Session, drei→vier CLR-Bindings und sieben→neun Slots am identischen aktuellen Binary. Je Ziel bestanden zwölf SQL-Fixtures, sechs Display-Clientprüfungen und zwei Raw→Type-/Raw→Type→Display-Kompositionen, Repeat sowie Uninstall/Repeat. Zwei eigene Datenbanken wurden entfernt und drei exakte Trust-Vorzustände wiederhergestellt; frische unabhängige Bereinigungsprüfungen bestanden. Keine Konfigurations-, Rechte- oder Owneränderungen.

Dies ist ein begrenzter privater Adapternachweis, kein vollständiger öffentlicher Labadapter- oder Produkt-PASS. Zentrale1.2-Nutzung, genuine1.0→1.2, weitere CL/Ziele, vollständige Lifecycle-/Kollisionsmatrix, Minimalrechte, Heap und aktuelle exakte Head-CI bleiben offen. Status bleibt `partially validated`, `unreleased`.

Frühere fehlgeschlagene Adapterstände bei Paketvariablen, Metadatenfixture und
Callback-Scope bleiben fehlgeschlagen; ihre eigene Bereinigung wurde getrennt
geprüft. Sie werden nicht durch den späteren Erfolg umgewertet.
Der Releasegenerator nutzt den gemeinsamen begrenzten Prozesshelfer für
Discovery (20 Sekunden) und MSBuild (120 Sekunden), mit getrennten 4-MiB-Kanälen
und Tool-/Helperpins. Der Driver besitzt je ausgewähltem Ziel ein 960-Sekunden-
Fachbudget und 1200 Sekunden Gesamtscope, damit 240 Sekunden für eigenen Cleanup
reserviert bleiben. SQL- und Clienthelper-Timeouts konsumieren dasselbe Restbudget;
Reads prüfen es kooperativ. Ein eigener äußerer Root-Prozesswatchdog und ein
anschließender unabhängiger Abwesenheitsaudit bleiben erforderlich: diese Grenzen
sind keine absolute Wallclock- oder SQL-Server-Abbruchgarantie. COMPLETE benötigt
frische sichtbare OwnDB-/OwnTrustabsenz und unveränderte vollständige Fingerprints
vorbestehender Trustzeilen. Keine Rights-/Configänderung wird dafür vorgenommen.
Aktuelle CI ist ein separater exakter PR-Head-Mergegate. Minimalrechte, Heap,
weitere physische Ziele und Produktionsworkbooks bleiben offen.

Der aktuelle Release-Quellmanifestvertrag umfasst exakt 20 modulrelative Pfade,
einschließlich "Scripts/Invoke-XlsxBuildProcess.ps1". Generator und Lab-Prüfung
binden diesen Buildhelper gemeinsam; dies ist kein zusätzlicher Produkt- oder
Runtime-Nachweis.

Die aktuelle öffentliche Offline-/CI-Kopplung konsumiert bereits paketierte
1.2-/ZIP1.4-DLLs in19 bounded Phasen; sie baut die Provider nicht erneut.
Details und Nachweisgrenzen stehen im [Framework-README](Framework/README.md#gemeinsame-kandidatenqualifikation-12).
Die öffentliche ConsumeCandidate-Orakelfolge bestand in19 Phasen gegen dasselbe
1.2-/ZIP1.4-Artefaktpaar. Die genuine1.1-Baseline bestand separat13 Offlinephasen.
Die aktuellen Genuine1.0-/ZIP1.3-Verpackungsadapter bestanden für unveränderte
archivierte Quellen; individuelle historische interne Buildtasks sind dadurch
nicht qualifiziert. Aktuelle exakte Head-CI bleibt ein separates Mergegate.
