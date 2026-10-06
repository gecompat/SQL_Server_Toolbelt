# Bounded JSON Schema Validation

`toolbelt.json.schema`1.0.1 liefert
[`toolbelt_json.USP_ValidateJsonSchema`](Documentation/USP_ValidateJsonSchema.md)
für das ausdrücklich begrenzte Profil `toolbelt-2020-12-v1`. Ein Ergebnis
besteht aus einer SUMMARY-Zeile und höchstens `MaxErrors` ERROR-Zeilen.
Gekürzte Diagnosen ändern das vollständige Urteil nicht; ein ausgeschöpftes
Arbeitsbudget ergibt `LIMIT` mit `IsValid=NULL`.

Der [kanonische Vertrag](../../Documentation/Architecture/JSON_SCHEMA_CONTRACT.md)
definiert unterstützte Keywords, lokale nichtrekursive Referenzen, exakte
Zahlen und Unicode sowie Fehlerpriorität und Ergebnisfelder. Es werden keine
Schemas oder Dokumente über Netzwerk, Dateien oder Datenbankabfragen geladen.
Das Modul verwendet die technische SAFE-Core-Assembly und genau eine interne
CLR-TVF. Die USP besitzt den öffentlichen Help-/ResultTable-Vertrag.

Version1.0.1 korrigiert die Reihenfolge von Schemaformfehlern und
Referenzzyklen nach vollständig codiertem `SchemaPointer`. Beispielsweise
kommt `/$defs/z` vor `/$defs/~0` und `/$defs/~1`. Instanzmember bleiben nach
decodierten Keys geordnet, Instanzarrays nach numerischem Index. Die
öffentliche Signatur, das Profil und die zehn Ergebnisfelder bleiben gleich.

Vor der Installation müssen `toolbelt.json.core`1.0 und
`toolbelt.core.result-table` mindestens1.0 in derselben Datenbank vorliegen.
Vorhandene Constructors müssen separat auf die bekannte Version1.3 migriert
werden. Der Schema-Lifecycle installiert oder repariert keine Dependency.
Core-, Schema- und Consumerowner müssen bereits kohärent sein.
Der Maintenancepfad erkennt die beiden exakten bekannten Schema-Releases
1.0.0 und1.0.1. Ein vorhandener1.0.0-Stand wird innerhalb der eigenen
Deploymenttransaktion auf1.0.1 aktualisiert; der Uninstall erkennt beide
Releases. Die native Qualifikation dieses neuen Pfads bleibt offen.

`Scripts/New-ClrReleaseArtifacts.ps1` benötigt `-AssemblyPath`,
`-CoreAssemblyPath` und ein neues `-OutputDirectory`. Der Generator prüft die
bekannte Closure und erzeugt Deploy-/Uninstall-SQL sowie Trustmanifest; er
installiert und autorisiert keinen Trusthash. Für begrenzte Tests der
laufenden Schema-Welle gilt die bereits dokumentierte
[Trustfreigabe](Documentation/TRUST_UNICODE_BINDING_OPT_IN.md); jede neue
Binaryidentität wird weiterhin separat qualifiziert und exakt gebunden.

[Offline-Evidenz](Tests/Framework/README.md) und
[Abnahmematrix](Tests/TEST_MATRIX.md) führen ausgeführte und offene Prüfungen
getrennt. Für1.0.1 bestanden die begrenzten Offline-Harness-, eigenen IL-,
bytegleichen Schema-Projektbuild- und Paketierungsprüfungen. Die bisherigen
nativen Core-/Schema-Contract-, Safety-, Client- und begrenzten Lifecycle-Läufe
auf Linux2019/latest CL150 und Windows2025/CU8 bleiben historische
1.0.0-Nachweise. Native1.0.1-API, echter1.0.0→1.0.1-Upgrade und exakte
Head-CI sind noch nicht ausgeführt. Weitere Matrix, CrossDB, Minimalrechte und
vollständige Lifecycleabnahme bleiben offen. Aktuell teilweise validiert,
unreleased. [Beispiele](Examples/JsonSchema.sql) verwenden synthetische Daten.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-06`
- Nachweis: `local: Invoke-BoundedPatchQualification.ps1 and Test-BoundedPatchPackaging.ps1`
- Scope: Schema1.0.1:15 erfolgreiche begrenzte Prozessphasen mit stabilen Input-/Produktpins;169 Profilfälle/1275 Assertions,854 Zahlenfälle/6830 Assertions und120 Bridge-Assertions jeweils en-US/de-DE/tr-TR. Eigene Schema-IL und bytegleicher kanonischer Schema-Projektbuild bestanden; sechs positive/negative Patchpaketierungsorakel, sieben Releasepaketierungsorakel und unveränderte historische Frames bestanden. ScriptDom14 Batches/42 Assertions, PowerShell-/Bashsyntax,18 synthetische CI-Cleanupfälle und33 Selector-/Bindungsfälle ohne Labzugriff bestanden. Unveränderte Core-/Constructoridentitäten nur wiederverwendet, keine erneute Gesamt- oder Maximallastqualifikation. Native1.0.1-API/Upgrade und exakte Head-CI noch nicht ausgeführt; historische1.0.0-Nachweise bleiben getrennt.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
