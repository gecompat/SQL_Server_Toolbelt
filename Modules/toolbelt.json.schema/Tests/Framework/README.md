# Begrenzte Offline-Sourcequalifikation

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
- Datum: `2026-10-05`
- Nachweis: `local: run-json-schema-lab.ps1 Windows CL150/160`
- Scope: Windows2025/exaktCU8 CL150 und CL160 jeweils local/central:30 Contractfälle, Safety/Help/ResultTable/Callerrollback, direkte Clientmetadaten, Repeat, Consumer-Abweisungen, Uninstall/Repeat und eigenes DB-/Trustcleanup bestanden. Je frischer hashgebundener Dispositionaudit bestanden; keine Konfigurations-/Rechte-/Owneränderungen. Genuine1.2→1.3 separat auf beiden zusätzlichen Windowslevels local/central mit Schema30-Fixture und frischem Dispositionaudit bestanden; weitere physische Ziele und Minimalrechte offen.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
