# Phonetik – Tests und Evidenz

Noch kein Build-, Framework-, Java-Differential-, IL-, SQL- oder CI-Lauf.
Die Prüfquellen sind vorbereitet; Autoren-Sourcekontrolle ist kein Runtime-PASS.

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

Die Herkunftsversion ist Apache Commons Codec 1.18.0. Goldenwerte verwenden
kurze explizite Referenzfälle und synthetische volle Codes; keine Aspell-Liste.
Ein tatsächlicher Differentialvergleich der vollständigen Scanner und
Metadaten-/IL-Prüfung des neuen Binaries bleibt ein separates Root-Gate.
Kein Test startet oder repariert Lab-Ressourcen und keine Credentials werden
in Repository oder Evidenz kopiert.