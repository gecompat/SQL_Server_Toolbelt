# NoOverwrite-Offline-Regression

Der Fixed-only-Harness verwendet den aktuellen kanonischen Provider. Er enthält keine zweite historische Produktimplementierung und ruft ausschließlich dessen privaten Schreibhelper mit synthetischen Dateien auf. SQL, Trust, Caller-Impersonation und NTFS-ACL-Qualifikation sind nicht Bestandteil.

## Reproduktion

PowerShell7 unter Windows und ein bereits vorhandener .NET-Framework-Compiler werden benötigt. Der Runner installiert nichts. Ohne CompilerPath verwendet er den vorhandenen Framework64-Compiler; die vier expliziten Referenzen sind mscorlib, System, System.Data und System.Xml aus dessen Verzeichnis.

```powershell
$framework = "Modules/toolbelt.filesystem.windows/Tests/Framework"
$runner = Join-Path $framework "Invoke-NoOverwrite.ps1"
$runnerHash = (Get-FileHash -LiteralPath $runner -Algorithm SHA256).Hash
$providerHash = (Get-FileHash -LiteralPath "Modules/toolbelt.filesystem.windows/Clr/WindowsFilesystemProvider.cs" -Algorithm SHA256).Hash
$harnessHash = (Get-FileHash -LiteralPath (Join-Path $framework "NoOverwriteHarness.cs") -Algorithm SHA256).Hash
& $runner -ExpectedRunnerSHA256 $runnerHash -ExpectedProviderSHA256 $providerHash -ExpectedHarnessSHA256 $harnessHash
```

Für unabhängig gebundene Prüfungen stammen die drei erwarteten Hashes aus dem vorab geprüften Sourcefreeze. EvidenceDirectory ist optional und muss ein neuer, privater Pfad außerhalb des Repositorys sein. Der Runner bindet seine Source und Tools vor/nach der Ausführung, kompiliert erfasste Sourcebytes in eigene Snapshots und führt Compiler und Harness jeweils höchstens15Sekunden aus. Zwei aktiv gelesene Kanäle sind jeweils auf262144Bytes begrenzt. Erfolgreicher Compiler muss Exit0 und leere Kanäle liefern; Compilerwarnungen sind kein sauberer Build. Ein Fehler versucht den eigenen Child begrenzt zu beenden; fehlende Capture-/Dispose-/Pin-/Cleanup-Gates bleiben Fehler. Private Source-/Toolpins, Kanäle und Evidenz dürfen nicht committed werden.

## Fälle und Grenzen

Neun synthetische Fälle prüfen vorhandene und im Staging-Callback neu erzeugte Ziele bei NoOverwrite, leere Ausgabe, Overwrite=true sowie eigene Staging-Bereinigung bei Writefehler. Der Harness entfernt nur seine bekannten eigenen Dateien und sein leeres eigenes Verzeichnis. Unbekannte Reste werden nicht rekursiv gelöscht. Der Runner übernimmt die tatsächliche Assertionzahl aus dem strikten vollständigen Witness; historisch254 ist keine vorweggenommene aktuelle Assertionzahl.

Test-WitnessControls.ps1 importiert nur den tatsächlich geprüften Parserextent und prüft synthetische gültige/ungültige Witnesses. Diese Kontrollen beweisen keine Prozess-, Provider-, Timeout- oder Filesystemausführung.

Der portierte Harness vor der Streaming-Identitätskorrektur bestand am 2026-10-03 tatsächlich neun Fälle/254 Assertions mit vollständigem Witness, Exit0, eigener Bereinigung und abschließenden Pins. Vier private tatsächliche Prozesskontrollen bestanden Nonzero, Timeout, Capturegrenze und Postpin-Drift; eigene Children wurden beendet und disposed, feste Fehlercodes geprüft. Die elf synthetischen Witness-Kontrollen sind davon getrennt. Aktuelle CI ist ein separater Mergegate am exakten PR-Head. Der damalige vollständige Projektbuild und die Releaseartefakt-Erzeugung sind separat am2026-10-03 erfolgreich. Die historische private Helperqualifikation (neun Fälle/254Assertions) bleibt historische Offline-Evidenz. Neue SQL-Caller-/NTFS-Runtime, Dateisystemraces außerhalb des gezielten Witness und Power-Loss-Garantien bleiben offen.

## Streaming-Sequenzregression — begrenzter Offline-Scope

Der Harness ergänzt sieben sourcegebundene Fälle: Binary mit drei 1-MiB-Reads, Text mit zwei Zeichenblöcken und BOM, ursprünglicher Readfehler trotz sekundärem Disposefehler, Write-, Flush- und Publikationsfehler sowie Readfehler trotz sekundärem Cleanupfehler. Die tatsächlichen privaten Copy-/Staginghelper werden mit einem synthetischen Scope-Executor aufgerufen. Eine öffentliche SqlBytes(Stream)-Eingabe verweigert Length/Read bei aktivem synthetischem Dateisystem-Scope. Der Erstfehler wird nach Objektidentität geprüft; sekundäre Fehler sind intern ausschließlich als feste Codes erkennbar.

Dies beweist nach erfolgreicher Ausführung die Helpersequenz, jedoch keine reale Windows-Impersonation, keinen SQL-backed LOB und keine NTFS-Rechte. Die neun bisherigen NoOverwrite-Fälle bleiben getrennt, ebenso beide tatsächlichen Assertionzahlen im Witness. Die neue Witness-Grammatik verlangt sieben Streaming-Fälle und positive begrenzte Assertionzahlen. Kein geplantes Zählerfeld ist ein Ausführungsnachweis. Die bisher elf Parserkontrollen wurden um drei synthetische Streaming-Gegenfälle erweitert.
Die vorbereitete Caller-Policykontrolle ruft das reale private Providerpraedikat mit fuenf exakten Windows-Modi und zehn Ablehnungsfaellen auf. Sie erhoeht die beobachtete Assertionzahl, nicht die neun Datei- oder sieben Streaming-Fallzaehler. Die reine Policykontrolle beweist keine Contextconnection-/Token-/Auth-Runtime; der getrennte Zwei-Fall-Auth-Probe-Scope folgt unten.

## Aktueller begrenzter Nachweis 2026-10-04

Der aktuelle Provider bestand einen privaten begrenzten produktiven C#-Sourcebuild und den sourcegebundenen Frameworklauf: neun NoOverwrite-Fälle/270 Assertions sowie sieben Streaming-Fälle/188 Assertions; darin enthalten ist die reine Caller-Policyprüfung mit fünf erlaubten und zehn abgewiesenen Werten. Vollständige Captures, Exit0, eigene Bereinigung und abschließende Sourcepins wurden geprüft. Die synthetischen Sequenzfälle beweisen keine echte Impersonation.

Die private native Zwei-Fall-Authentifizierungsprüfung auf SQL Server 2025/CU8 unter Windows bestand: Windows-Caller (NTLM) schrieb drei synthetische Bytes über `USP_WriteBinaryFile`; SQL-Authentifizierung wurde mit `51540/1` und `CallerWindowsAuthenticationRequired` vor Datei-/Staging-I/O abgewiesen. Eigene DB-, Root- und Trustbereinigung und eine separate frische Prüfung bestanden, ohne Konfigurations-, Rechte- oder Owneränderungen. Dieser begrenzte Probe-Scope ist kein vollständiger Produkttest.

Aktueller kanonischer Projektbuild/Releaseartefakt, direkte CLR-/RunAs-Qualifikation aller neun Einstiegspunkte, vollständige NTFS-/Caller-/ServiceAccount-Matrix, Races, weitere Ziele und aktuelle Head-CI bleiben separate offene Gates. Status `partially validated`, Version1.0.0 und `unreleased` bleiben erhalten; frühere Nachweise sind historisch.
