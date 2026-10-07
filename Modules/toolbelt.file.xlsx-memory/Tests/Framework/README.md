# Zelltyp-Frameworkqualifikation

`Invoke-Types.ps1` verwendet einen vorhandenen .NET-Framework4.8-Compiler,
bounded20s je Compile/Kulturkind. Keine Installation. Die Test-EXE besteht aus
dem aktuellen Produktionszellkern und dem separaten Offlineharness; sie ist
kein SAFE-Providerbinary, da der Harness Goldendateien liest.

API-Goldens652 und Numeric-/Temporal-Goldens370 sind synthetische unabhängige
Erwartungswerte aus der vor Source qualifizierten V3-Referenz. Große wiederholte
UTF16-Werte verwenden verlustfreie `!HHHH:Count,...`-Lauflängen; `~` ist NULL,
`!` allein ist der explizite Leerwertmarker; sonst Base64 UTF16LE. Die komprimierte Darstellung verändert keine Inputs oder
Orakel. Leer bleibt leer. Der Harness prüft zusätzlich vollständige Echo-/
Typedfehlerfelder sowie echte SqlDecimal-Wörter/Precision/Scale/Nullnormalisierung.

Aktueller Offline-Lauf2026-10-02: de-DE/en-US/tr-TR jeweils6437 Assertions,
zusammen19311. Dieser Lauf ist auf den tatsächlichen Zellkern begrenzt;
separate native API-/Metadaten-/Lifecycle-Evidenz steht im [Tests-README](../README.md).
Aktuelle CI wird separat am exakten PR-Head als Mergegate geprüft.
Tatsächliche Minimalrechte und gesamte Heapgrenzen bleiben offen.

Der erste Typkern bestand diese Goldens, scheiterte aber tatsächlich am
vorhandenen Provider-IL-Gate wegen Regex außerhalb der Allowlist. Die finale
Revision ersetzt ausschließlich Number-/ISO-Formchecks durch finite ASCII-
Scanner; Grammatik/Status/Priorität bleiben unverändert, Allowlist unverändert.
Danach bestanden19311 Assertions erneut sowie der bestehende vollständige
Framework-/begrenzte Sandbox-/Produktions-IL-Gate. Der Sandboxteil testet
historische Raw-Readerfixtures; daraus folgt kein neuer Typ-Sandbox-/SAFE-PASS.

```powershell
& ./Modules/toolbelt.file.xlsx-memory/Tests/Framework/Invoke-Types.ps1
```

Genuine1.0-Paketierer `Scripts/New-Xlsx10LegacyFixture.ps1` baut unveränderte
öffentliche Originalblobs aus dem gepinnten Commit; kein remakierter1.1Build.
Ein lokaler Vorbereitungslauf überschritt zunächst seine60sDeadline im
Harness bei erst nach WaitForExit geleerten Outputpipes. Nach gleichzeitiger
asynchroner Pipeconsumption bestand der unveränderte Originalbuild. Dieser damalige Build allein ist
keine SQL-Upgrade-Evidenz und keine Timeoutanhebung; das genuine Upgrade ist
inzwischen separat im nativen Typadapter geprüft.


Testfixture-Codierung 2026-10-02: Sechs leere letzte TSV-Felder wurden durch
`!` ersetzt, damit die Fixture keine nachlaufenden Tabs enthält. Der Decoder
behandelt diesen Token vor der `!HHHH:Count,...`-Lauflänge als leeren String.
`~` bleibt NULL; leere Zwischenfelder behalten ihre bisherige Base64-Semantik.
Ein vollständiger Vergleich aller 652×11 decodierten Felder bestätigte
bytegenaue Gleichheit vor/nach dem Codierungswechsel. Keine Produkt-/API-
oder Orakeländerung. Anschließend bestand die tatsächliche Frameworkqualifikation
erneut in de-DE/en-US/tr-TR mit je API652/Numeric370/6437 Assertions,
zusammen19311.

## Gemeinsame Kandidatenqualifikation 1.2

Die aktuelle CI baut den ZIP-1.4- und XLSX-1.2-Release jeweils einmal und
übergibt diese Artefaktverzeichnisse an `Invoke-CandidateQualification.ps1`.
Der Runner bindet dieselben DLLbytes an Trustmanifest, vollständiges
Assembly-Hex im Deployment und die in ein frisches Testverzeichnis kopierten
DLLs. Er baut ausschließlich getrennte Testadapter, keine Provider.
`TypeCandidateHarness.cs`, `DisplayCandidateHarness.cs` und
`RawCandidateHarness.cs` rufen die öffentlichen CLR-EntryPoints/FillRow auf;
die bisherigen Quellkernharnesses bleiben als getrennte historische Tests erhalten.

```powershell
./Modules/toolbelt.file.xlsx-memory/Tests/Framework/Invoke-CandidatePackaging.ps1 -OutputDirectory .runtime/xlsx-candidate
./Spikes/XlsxMemory/Run-FrameworkQualification.ps1 -XlsxDirectory .runtime/xlsx-candidate/xlsx -ZipDirectory .runtime/xlsx-candidate/zip -OutputDirectory .runtime/xlsx-candidate/qualification
```

Der portable Kandidatenrunner enthält 19 endliche Phasen: sechs stille
Testadapter-Compiles, vier physische CLR-FT-Metadaten mit neun SQL-Quelldateien,
Typ-6437-/Anzeige-5619-Goldens je en-US/de-DE/tr-TR, Transport55,
das bestehende Raw-Orakel, drei begrenzte Sandboxfälle und eigenes Provider-IL.
Pro Phase gelten 20 Sekunden, für Raw45; Compilerentdeckung20. Verpackung
begrenzt jeden bestehenden Generator als eigenen Prozess auf120 Sekunden.
Der gemeinsame Prozesshelfer begrenzt jeden Kanal vor dem Schreiben auf4MiB;
Vor-/Nachpins und genaue Ausgabemarker sind Erfolgsbedingungen. Die bestehende
CI-Jobfrist bleibt10 Minuten, keine Zusage einer Worst-Case-Gesamtlaufzeit.
MSBuildausgaben dürfen ausführlich sein; nur die sechs Testadapter-Compiles
müssen tatsächlich stille Kanäle liefern.

Am2026-10-04 bestand diese 19-Phasen-Orakelfolge privat gegen das tatsächlich
gebaute1.2-Kandidatenbinary und seine1.4-ZIP-Abhängigkeit. Die öffentliche
ConsumeCandidate-Folge bestand ebenfalls mit denselben Artefakten; der exakte
aktuelle CI-Head bleibt separat offen. Die genuine1.1-Baseline bestand13
getrennte Offlinephasen.
Diese Offlineevidenz behauptet weder SQL-/Trust-/Registryqualifikation noch
vollständige transitive Framework-/OS-NoIO- oder Produktqualifikation.

Die aktuellen Genuine1.0-/ZIP1.3-Generatoradapter begrenzen ihre eigenen Git-
Schritte auf30 Sekunden und ihre Aufrufe der originalen Releasebuilder auf60
Sekunden. Vor-/Nachpins binden aktuelle Scripts, Helfer, Git/pwsh sowie alle
vor dem Build extrahierten Originaldateien. Vollständige Kanäle und beobachtete
Disposition gelten für diese direkt gestarteten Kinder; daraus folgt keine
separate Qualifikation sämtlicher interner Tasks der unveränderten historischen
Builder. Ein fehlgeschlagener Helfer wird mit unbekannter Disposition erfasst.
Die äußere Verpackungsgrenze120 Sekunden bleibt unverändert; keine Retry-
oder Timeoutanhebung. Diese aktuellen Adapter bestanden am2026-10-04 mit unveränderten
archivierten Quellen und Manifest-/DLL-/Hex-Bindung. Vorherige fehlgeschlagene
Pfad-/Adapterstände bleiben getrennt; aktuelle Head-CI bleibt offen.

Für die unveränderten historischen Compiler verwendet die Verpackung einen
kurzen isolierten Ausgaberoot. Der Kurzpfadvergleich bestand; lange
Intermediatepfade können die historische Compilergrenze überschreiten.
Der aktuelle Workflow verwendet denselben kurzen Root für Verpackung und
ConsumeCandidate. Der Upload `xlsx-qualified-release-input` enthält ausschließlich
15 benannte Releaseinputs: jeweils DLL, Trustmanifest und `Deploy.WithAssembly.sql`
für aktuellen ZIP1.4/XLSX1.2 sowie genuine ZIP1.3/XLSX1.0/XLSX1.1. Diese Inputs
ersetzen keinen Repositorycheckout oder eigenständige historische Quellfixtures.
Qualifikations-/Argument-/Prozessdateien, stdout/stderr, ursprüngliche Archive
und historische Arbeits-/Buildbäume werden nicht hochgeladen.

Der bestehende Staticvalidator prüft die echte Workflowauswahl in drei
synthetischen Dateibaumfällen mit 14 privaten Sentinels und zusätzlichen
gleichnamigen Argumentdateien. Nur Literalpfade sind erlaubt; neue Rootdateien
werden nicht automatisch veröffentlicht. Die bestehenden 19 Frameworkphasen,
Binaries, Trust- und SQL-Grenzen bleiben unverändert. Tatsächliche Head-/Main-CI
und die hochgeladene Dateiauswahl werden separat im PR geprüft.
