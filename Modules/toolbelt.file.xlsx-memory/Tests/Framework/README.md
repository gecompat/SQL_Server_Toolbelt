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
