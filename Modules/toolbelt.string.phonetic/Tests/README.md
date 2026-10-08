# Phonetik – Tests und Evidenz

Version 1.0.0 bleibt `partially validated` und `unreleased`.

## Begrenzter tatsächlicher Differentialnachweis 2026-10-08

Der [Differentialrunner](Differential/run-differential-phonetic.ps1) bestand einmal lokal unter Windows/.NET Framework 4.8 mit dem ausdrücklich gewählten JDK27 und unveränderten Apache-Commons-Codec-1.18.0-Quellen. Eine neu aus den fünf aktuellen C#-Quellen gebaute Assembly wurde über explizites `BindingPath`/`ExpectedBindingSHA256` konsumiert. Zwei Compiler und zwei Consumer bestanden; alle 32 synthetischen Fälle (16 Cologne, 16 Double Metaphone) stimmen in ihren vollständigen Primary-/Alternatebytes überein, einschließlich des alternativen AJ-Endblanks. Eine unabhängige Read-only-Prüfung bestätigte Receipts, ganze Input-/Kopie-/Outputbytes und den strikten Rohtransport ohne Rerun.

Dies schließt nur diesen endlichen Offline-Corpus. SQL-/SAFE-, vollständige Scanner-/Zielmatrix-, Minimalrechte- und Releasequalifikation bleiben offen; Version 1.0.0 bleibt `partially validated` und `unreleased`. stderr ist nur als leerer zurückgegebener decodierter Text belegt. Private Dateien bleiben erhalten; kein Datei-Cleanup-PASS. Die folgenden PR301-Quellen- und früheren Nachweise behalten ihren damaligen Stand.

## Differential-EntryPoint – Quellenstand 2026-10-08

Der zusätzliche [Runner](Differential/run-differential-phonetic.ps1) und sein
[Transportvertrag](Differential/TRANSPORT.md) liegen als Testquellen vor.
Der Vergleich mit 32 synthetischen Fällen ist `NOT_EXECUTED`; daraus folgt
kein Scanner-, SAFE-, SQL-, Matrix- oder Release-PASS.
Der ausgewählte Consumerpfad benötigt Windows, PowerShell 7.3+, explizite
Csc- und .NET-Framework-4.8-Referenzen, Java/Javac sowie eine vorhandene Assembly
mit belegter aktueller Sourceprovenienz. Name und Version der DLL genügen nicht.
Die CLI nimmt `BindingPath` und `ExpectedBindingSHA256`. Das private Binding
enthält genau `Schema`, `Ready`, `Inputs`, `ReferenceDirectory`, `EvidenceDirectory`.
Die 14 Inputrollen sind Coordinator, CSharpConsumer, JavaConsumer, Corpus,
Transport, OwnedProcess, ApacheManifest, Assembly, Csc, Java, Javac, Mscorlib,
System und SystemData, jeweils mit ausdrücklich gewähltem Path/SHA256/Bytes.
Die elf exakt gebundenen Referenzdateien liegen unter einem expliziten externen
ReferenceDirectory; kein Fetch, Installieren, Discovery oder Fallback.
Der Protokollrahmen erlaubt 1–64 Fälle mit 1–128 UTF16-Codeeinheiten und prüft
vollständige Codes einschließlich des alternativen AJ-Endblanks bytegenau.
Vier eigene Kinder teilen 240s mit 12s Cleanupreserve, je höchstens 60s;
dies ist keine absolute Host-, Heap- oder Hardinterruptgarantie. Stdout wird
roh verglichen, stderr nur als vom Helper zurückgegebener decodierter Text;
eine rohe stderr-Byteattestation wird nicht behauptet. Private Inputlocators
und Evidenz bleiben außerhalb des Repositorys; eigene Evidenz wird behalten.

## Begrenzte tatsächliche Evidenz 2026-10-04

Am 2026-10-04 bestanden Build, Frameworkprüfungen mit jeweils 223 Assertions unter en-US/de-DE/tr-TR und die eigene IL-/Metadatenprüfung (keine unbekannten eigenen IL-Aufrufe). Begrenzte private Labadapter bestanden auf SQL Server 2019 Linux/latest CL150 und SQL Server 2025 Windows/exakt CU8 CL170. Je Ziel: vier Fixtures einmal lokal, acht echte Clientreader je local/central sowie zwei lokale Größenwitnesses; Clean/Repeat, resolved Consumer-Ablehnungen, zentrale Bestätigung und Uninstall/Repeat mit frischer eigener Bereinigung. Keine Konfigurations-, Rechte- oder Owneränderungen. Java-Differential, unresolved Consumer, weitere Ziele/CL, tatsächliche Minimalrechte, vollständige Lifecyclematrix und aktuelle Head-CI bleiben offen. Teilweise validiert und unveröffentlicht; kein vollständiger Produkt-PASS.

Die vier Originalfixtures liefen je Ziel einmal lokal, nicht erneut zentral.
Je Modus bestanden acht typgenaue Einzeilenreader mit EOF/noNext, Status-/NULL-
und Byteprüfung. Zwei zusätzliche lokale Full-Scan-Witnesses bestätigten
8192 Cologne-Codebytes und 6144/8191 Double-Metaphone-Codebytes. Ihre
Erwartungen sind unabhängig aus der Quelle hergeleitet, kein Java-Differential.
Die resolved Consumer-Prüfung bestätigte Deploy-/Uninstall-Ablehnung55266/1
und unveränderten Snapshot mit gesunder Session; Confirm0 zentral55267/1.
Ein eigener Testdatenbank- und Trustscope wurde vollständig wiederhergestellt
und frisch auf Abwesenheit geprüft. Historische Fehlversuche bleiben fehlgeschlagen.

Die Labadapter sind vom öffentlichen Windows-Offline-CI-Workflow getrennt.
Der Workflow enthält Source-/Build-/Frameworkprüfungen, keinen SQL-Lauf.
Eigene IL-/Metadatenprüfung ist keine transitive SAFE- oder Vollqualifikation.

## Begrenzte vorhandene EntryPoints

- Tests/Static/validate_contract.py prüft Quell-/Slot-/Budget-/Lizenzkopplung.
- Scripts/New-ClrReleaseArtifacts.ps1 benötigt explizites MSBuildPath und ein
  frisches OutputDirectory. Ein Child maximal 120s, Kanäle getrennt maximal
  4MiB. Manifest/Binary/SQL-Hex stammen aus einem Snapshot mit prä/post
  Quellpins; BuildOnly ist keine OfflineQualified-Zusage.
- Tests/Framework/run-framework-phonetic.ps1 konsumiert exakt ein vorhandenes
  AssemblyPath/ExpectedAssemblySHA256. CscPath, FrameworkReferenceDirectory
  und frisches EvidenceDirectory sind explizit. Nur der Harness wird gebaut;
  compile und drei Kulturen jeweils maximal 60s. Keine SQL-/Trustoperation.
- Runtime/Phonetic.Contract.sql, Phonetic.Boundaries.sql und
  InstalledMetadata.Contract.sql liefern jeweils ihren festen PASS-PRINT
  ausschließlich nach ihren konkreten Orakeln.
- Runtime/Lifecycle.Contract.sql ist ein read-only Installed-Hash-/Ownerwitness
  mit expliziter Manifest-Erwartung. Mutation/Repeat/Uninstall und negative
  Lifecyclepfade benötigen den getrennten Root-Nativeadapter.

Historischer Referenz-/Testquellenstand vor dem oben dokumentierten Differentiallauf:

Die Herkunftsversion ist Apache Commons Codec 1.18.0. Goldenwerte verwenden
kurze explizite Referenzfälle und synthetische volle Codes; keine Aspell-Liste.
Ein tatsächlicher Java-Differentialvergleich der vollständigen Scanner bleibt
NOT_EXECUTED; die eigene Metadaten-/IL-Prüfung betrifft die unveränderten
tatsächlich gebauten Kandidatenbytes.
Kein Test startet oder repariert Lab-Ressourcen und keine Credentials werden
in Repository oder Evidenz kopiert.
## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-04`
- Nachweis: `Begrenzte private Offline-/Nativeadapter mit unabhängiger physischer Prozess- und Bereinigungsprüfung`
- Scope: Am 2026-10-04 bestanden Build, Frameworkprüfungen mit jeweils 223 Assertions unter en-US/de-DE/tr-TR und die eigene IL-/Metadatenprüfung (keine unbekannten eigenen IL-Aufrufe). Begrenzte private Labadapter bestanden auf SQL Server 2019 Linux/latest CL150 und SQL Server 2025 Windows/exakt CU8 CL170. Je Ziel: vier Fixtures einmal lokal, acht echte Clientreader je local/central sowie zwei lokale Größenwitnesses; Clean/Repeat, resolved Consumer-Ablehnungen, zentrale Bestätigung und Uninstall/Repeat mit frischer eigener Bereinigung. Keine Konfigurations-, Rechte- oder Owneränderungen. Java-Differential, unresolved Consumer, weitere Ziele/CL, tatsächliche Minimalrechte, vollständige Lifecyclematrix und aktuelle Head-CI bleiben offen. Teilweise validiert und unveröffentlicht; kein vollständiger Produkt-PASS.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
