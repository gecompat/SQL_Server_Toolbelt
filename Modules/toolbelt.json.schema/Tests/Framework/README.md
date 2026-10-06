# Begrenzte Offline-Sourcequalifikation

## Schema1.0.1-Wartung, 2026-10-06

`Invoke-BoundedPatchQualification.ps1` baut ausschließlich die aktuelle
Schema-Compileliste gegen die unveränderten bekannten Corebytes. Der finale
Lauf bestand15 Phasen mit tatsächlichen Exits0, vollständigen Captures,
leerem Stderr und unveränderten Input-/Produktpins. Die15 Phasen umfassen
Schema- und Harnessbuilds, eigene vollständige Schema-IL, den bytegleichen
kanonischen Schema-MSBuild und die folgenden Harnessläufe:

| Prüfung | Tatsächlicher Umfang je en-US/de-DE/tr-TR |
|---|---|
| Schema-Profil |169 Fälle/1275 Assertions; neu: codierte Schemaform-/Graphorte, escaped Keys und mehrstellige Indizes; decodierte Instanzmember, numerische Instanzarrays und LIMIT bleiben erhalten |
| Exakte Zahlen |854 Fälle/6830 Assertions |
| CLR-Bridge |120 Assertions, Managedidentität1.0.1.0 und unveränderter öffentlicher Transport |

```powershell
./Modules/toolbelt.json.schema/Tests/Framework/Invoke-BoundedPatchQualification.ps1 `
  -CompilerPath $LocalCompiler -ReferenceDirectory $LocalFrameworkReferences `
  -FrameworkPowerShell $LocalFrameworkPowerShell -MSBuildPath $LocalMSBuild `
  -CoreAssemblyPath $KnownCoreAssembly `
  -ExpectedSchemaCases 169 -ExpectedSchemaAssertions 1275 `
  -OutputDirectory .runtime/schema-patch-qualification
```

Die neue eigene Schemazeile wird durch `Scripts/New-KnownSchemaPatch.ps1`
aus genau diesem `BOUNDED_SCHEMA_PATCH`-Receipt abgeleitet. Der Generator
schreibt nur einen neuen privaten Registrykandidaten. Historische Core- und
Constructorframes bleiben unverändert; ihre frühere Gesamtqualifikation wird
nicht als erneuter Patchnachweis ausgegeben. Der unveränderte historische
Closure-Snapshot bleibt in `KNOWN_JSON_ARTIFACT_CLOSURE_SCHEMA_1_0.json` erhalten.

`Test-BoundedPatchPackaging.ps1` bestand sechs Paketierungsorakel: den
qualifizierten Patchkandidaten sowie die Abweisung eines belegten Ziels,
eines früheren Gesamt-Receipts, einer fehlenden Phase, veränderter Sourcepins
und veränderter Binarybytes. Inputpins, historische Frames und die erlaubten
Schemafelder bestanden. Die Receipt-Scope lautet
`BOUNDED_SCHEMA_PATCH_PACKAGING`.

`Deployment/New-Historical10TestArtifacts.ps1` reproduzierte separat die echte
Schema1.0.0 aus dem festen Commit `0185603b0e30e4d0b2dd9c1cfa4e698fccd9feb9`.
50 Originalblobs wurden ohne Text-Reencoding übernommen;53 Prozessphasen
bestanden. Source-/Projektpins, Snapshotbytehash, beide historischen
Binaryhashes, Managedidentität und der originale Schema-Packager bestanden.
Eine falsche Coreassembly wurde vor neuer Ausgabe abgewiesen; ein belegtes
Ausgabeziel blieb unverändert. Dies ist historische Artefakterzeugung für
einen späteren Upgradeversuch, kein ausgeführter SQL-Upgrade.

Der historische Erzeuger begrenzt einzelne Prozesse auf5 Sekunden und den
Gesamtversuch auf60 Sekunden. Die Patchqualifikation verwendet15 Sekunden
für Compiler/IL und30 Sekunden für den kanonischen Build und die Harnesses;
der Patchpaketierungstest verwendet15 Sekunden je Childprozess.
Private Receipts bleiben ausschließlich in
neuen ignorierten `.runtime`-Verzeichnissen. Constructor-Maximallast, erneute
Core-/Constructor-Gesamtqualifikation, SQL/Docker und neue native1.0.1-Tests
wurden lokal nicht ausgeführt. Eigenes IL beweist keine transitive Framework-
SAFE-Zertifizierung oder SQL-Host-Ladbarkeit. Die unveränderlichen
Known-Artifact-Felder `nativeQualification` und `trustAuthorization` bleiben
Offline-Freeze-Metadaten; aktuelle Testautorität und spätere native Evidenz
werden getrennt dokumentiert.

Separat bestanden am2026-10-06: `../Static/Test-SqlSyntax.ps1` mit14 Batches
und42 Assertions in ScriptDom150/160/170 sowie PowerShell-/Bashsyntax.
Der aktuelle Release-Packager bestand alle drei Modulpositivfälle und die
sieben Orakel aus `Test-ReleasePackaging.ps1` mit stabilen Pins: drei bekannte
Produkte sowie vier Abweisungen für falsches Produkt, falschen/fehlenden Core
und veränderte Bytes.18 synthetische CI-Cleanupfälle bestanden ohne SQL oder
Container. Diese Prüfungen belegen Syntax, Paketierung und die geprüfte
Cleanup-Steuerung, keine tatsächliche native1.0.1-Ausführung oder Bereinigung.
`Test-JsonSchemaLabScope.ps1` bestand zusätzlich33 synthetische Selector-/
Bindungsfälle ohne Labzugriff.

## Historische Gesamtqualifikation mit Schema1.0.0

Stand2026-10-05, Codex. Die Schema-/Kern-Welle wurde ausdrücklich anhand von
PR175 freigegeben. [Kanonischer Vertrag](../../../../Documentation/Architecture/JSON_SCHEMA_CONTRACT.md).

`Invoke-SourceQualification.ps1` baut die drei expliziten Projekt-Compilelisten
gegen lokal bereitgestellte .NET-Framework4.8-Referenzen mit einem ausdrücklich
bereitgestellten Compiler. Keine Installation, Toolbeschaffung, SQL-Verbindung
oder Truständerung. Ausgabe ausschließlich in einem neuen ignorierten
`.runtime`-Unterverzeichnis; keine automatische Löschung. Produkt-, Harness-,
Compiler-, Referenz-, Fixture- und Driverinputs werden vor und nach dem Lauf
gehasht. Childprozesse haben tatsächliche Exit-/Capture-/Stderrprüfungen und
15/30/45-Sekunden-Grenzen. Dies ist Source-Frameworkevidenz, noch keine bekannte
Releaseartifact-Zeile oder kanonische MSBuild-Abnahme. Der eigene vollständige
IL-Aufrufscan ist enthalten; er zertifiziert keine transitive Framework-SAFE-
Implementierung oder tatsächliche SQL-Host-Ladbarkeit.

Ein gescheiterter Childprozess meldet nur seinen festen Phasennamen und eine
feste Start-/Timeout-/Capture-/Encoding-/Limit-/Cleanup- oder allgemeine
Fehlerkategorie. Unbekannte Exceptiontexte, Childausgaben und Hostpfade
werden nicht in CI-Diagnosen übernommen. Die Kategorie ist ein Diagnosehinweis,
kein Ersatz für die vollständige private Prozessevidenz oder einen PASS.

```powershell
./Modules/toolbelt.json.schema/Tests/Framework/Invoke-SourceQualification.ps1 `
  -CompilerPath $LocalCompiler `
  -ReferenceDirectory $LocalFrameworkReferences `
  -FrameworkPowerShell $LocalFrameworkPowerShell `
  -OutputDirectory .runtime/schema-source-qualification
```

Ausgeführter finaler Source-Frameworklauf am2026-10-05: COMPLETE,
unveränderte Input-/Produktpins, tatsächliche Exits0, vollständige Captures,
leere Stderr. Alle folgenden Prüfungen liefen gegen gemeinsam erfasste
Core-/Constructor1.3-/Schema1.0-Sourcebytes:

| Prüfung | Tatsächlicher Umfang |
|---|---|
| Constructor-Goldens |37 Fälle/960 Assertions je en-US/de-DE/tr-TR; bestehende37 fachliche Fixturezeilen unverändert |
| Constructor groß |3 Fälle/67 Assertions |
| Coretoken |37 Fälle/95 Assertions, Unicode/Keys/Hashkollision/128-/129-Tiefe/Budget |
| Corebudget |10 Assertions, einschließlich long.MaxValue und Vorbelastung |
| Exakte Schema-Zahlen |854 Fälle/6830 Assertions je drei Kulturen; unabhängige Python-Decimal/Fraction-Oracles und manuell abgeleitete riesige Exponenten |
| Schema-Profil |159 Fälle/1174 Assertions je drei Kulturen; vollständiger Preflight, Graph,200-stufiger Refpfad, Evaluation, Priorität, Diagnosekürzung und späterer LIMIT |
| CLR-Bridge |120 Assertions je drei Kulturen; acht fachliche Args, zehn FillRow-Typen, Flags, SqlChars-NULL-/Scalartransport, lange Pointer, exakte Profile |

Die geänderte Metadatazählung960 gegenüber dem historischen1.2-Harness962
enthält die neue physische Coreassemblygrenze. Sie ersetzt keinen nativen
1.2→1.3-Paritätsnachweis. Ein früherer Driverlauf scheiterte am erwarteten
Witnessformat des Zahlenharness; der korrigierte vollständige Lauf bleibt
als eigener Versuch getrennt. Compilerfehler während der Sourcearbeit sind
keine erfolgreichen Qualifikationsversuche.

`generate-number-oracles.py` erzeugt die853 Vergleichspaarzeilen in
`NumberOracles.tsv` deterministisch. Produktcode verwendet weder Python noch
Decimal/Fraction. Die zusätzlichen Count-/Zeroassertions des C#-Harness
erklären seine854 Fälle. Die Cultureläufe verwenden identische synthetische
Fixtures und prüfen die vollständigen Urteile.

Separat ausgeführt: `../Static/Test-SqlSyntax.ps1` gegen bereits lokal
bereitgestelltes ScriptDom, zwölf Batches in Parser150/160/170,36 Syntax-
Assertions. Öffentliche USP und interner Slot sowie deren konstante innere
Batches werden jeweils geparst. Dies beweist weder SQL-CLR-Binding noch
ResultTable-, Client-, Lifecycle-, Berechtigungs- oder native Grammatikparität.

Historischer Source-Scannervergleich:1746 synthetische Inputs/3492 Legacy-/AGF-
Policyergebnisse waren gegen die1.2-Quelle identisch. Dieser getrennte frühere
Sourcevergleich ist kein Vergleich installierter SQL-Assemblies und kein
Nachweis neuer SQL-Slots. Die drei kanonischen MSBuild-Projektbuilds waren
bytegleich zum aktuellen Source-Driver. Die geschlossene Known-Artifact-Registry
und sieben positive/negative Offline-Paketierungskontrollen wurden geprüft.
Die anschließend getrennt ausgeführten begrenzten nativen Core-/Schema- und
Migrationsprüfungen stehen in [NATIVE_EVIDENCE.md](../NATIVE_EVIDENCE.md).
Weitere Matrix- und vollständige Lifecyclequalifikation bleiben offen. Die
Felder `nativeQualification`/`trustAuthorization` der unveränderlichen
Registryzeile beschreiben deren ursprünglichen Offline-Freeze, keine aktuelle
globale Freigabe oder Modulstatusautorität. Datierte Benutzerautorität und
native Teilnachweise stehen getrennt im Gesamtvertrag und der nativen Evidenz.

`toolbelt.json.core/Tests/Framework/Test-JsonClosureIL.ps1` prüft die gesamte
eigene IL einschließlich privater Methoden, Kontrollfluss-/Operandgrenzen,
catch-Typen, exakter geschlossener Frameworkbindungen, Managed-Identität,
direkter Referenzidentität und gepinnter Corebytes. Neue Core-/Schema-Statics
sind auf Literale und den unveränderlichen SignedDecimalDigits.Zero begrenzt.
Die bestehende Constructor-Transport-/MemoryStream-/Exceptiongrenze bleibt
explizit und wird nicht auf Schema übertragen. Ein generischer Object.ToString-
Call wird nur für die dokumentierten StringBuilder-Caller mit bewiesenem
lokalem Receivertyp und Kontrollfluss akzeptiert. Unbekannte Calls blockieren.

Separat bestanden: acht Negativfixtures aus `Test-RejectedClosure.ps1`, mit
tatsächlichem CompilerExit0/GateExit1 und vollständiger Capture. Datei-, Thread-,
Netzwerk-, SQL-Kontext-, Reflection-, unbekannte Generic-, mutable-Static- und
P/Invoke-Fixtures werden nur gebaut und als Metadaten gelesen, niemals aufgerufen.
Ein Gate-PASS für Constructor oder Schema allein umfasst keine transitiv
ungeprüfte Coreassembly; der gemeinsame Driver prüft zuerst die exakt selben
Corebytes und danach beide Konsumenten.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-06`
- Nachweis: `local: Invoke-BoundedPatchQualification.ps1 and Test-BoundedPatchPackaging.ps1`
- Scope: Schema1.0.1:15 erfolgreiche begrenzte Prozessphasen mit stabilen Input-/Produktpins;169 Profilfälle/1275 Assertions,854 Zahlenfälle/6830 Assertions und120 Bridge-Assertions jeweils en-US/de-DE/tr-TR. Eigene Schema-IL und bytegleicher kanonischer Schema-Projektbuild bestanden; sechs positive/negative Patchpaketierungsorakel, sieben Releasepaketierungsorakel und unveränderte historische Frames bestanden. ScriptDom14 Batches/42 Assertions, PowerShell-/Bashsyntax,18 synthetische CI-Cleanupfälle und33 Selector-/Bindungsfälle ohne Labzugriff bestanden. Unveränderte Core-/Constructoridentitäten nur wiederverwendet, keine erneute Gesamt- oder Maximallastqualifikation. Native1.0.1-API/Upgrade und exakte Head-CI noch nicht ausgeführt; historische1.0.0-Nachweise bleiben getrennt.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
