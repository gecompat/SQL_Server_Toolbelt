# Bounded JSON Schema Validation

`toolbelt.json.schema`1.0.0 liefert
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

Vor der Installation müssen `toolbelt.json.core`1.0 und
`toolbelt.core.result-table` mindestens1.0 in derselben Datenbank vorliegen.
Vorhandene Constructors müssen separat auf die bekannte Version1.3 migriert
werden. Der Schema-Lifecycle installiert oder repariert keine Dependency.
Core-, Schema- und Consumerowner müssen bereits kohärent sein.

`Scripts/New-ClrReleaseArtifacts.ps1` benötigt `-AssemblyPath`,
`-CoreAssemblyPath` und ein neues `-OutputDirectory`. Der Generator prüft die
bekannte Closure und erzeugt Deploy-/Uninstall-SQL sowie Trustmanifest; er
installiert und autorisiert keinen Trusthash. Neue qualifizierte Hashes
benötigen weiterhin ihr exaktes Opt-in.

[Offline-Evidenz](Tests/Framework/README.md) und
[Abnahmematrix](Tests/TEST_MATRIX.md) führen ausgeführte und offene Prüfungen
getrennt. Native Core-/Schema-Contract-, Safety-, Client- und begrenzte
Lifecycle-Läufe bestanden auf Linux2019/latest CL150 und Windows2025/CU8
CL170 jeweils local/central. Weitere Matrix, CrossDB, Minimalrechte und
vollständige Lifecycleabnahme bleiben offen. Aktuell teilweise validiert,
unreleased. [Beispiele](Examples/JsonSchema.sql) verwenden synthetische Daten.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-05`
- Nachweis: `local: run-json-schema-lab.ps1`
- Scope: Linux2019/latest CL150 und Windows2025/CU8 CL170 jeweils local/central:30 Contractfälle einschließlich langer escaped NUL-Pointer und Bytepriorität, Safety/Help/ResultTable/Callerrollback, direkte Clientmetadaten, Repeat, Consumer-Abweisungen, Uninstall/Repeat und eigenes DB-/Trustcleanup bestanden. Beide Ziele local/central nach genuine Constructor1.2→1.3 separat26 Contractfälle bestanden. Frische hashgebundene Dispositionaudits beider aktueller Core-/Schema-/Migrationsscopes bestanden. Vollständige Lifecycle-/Zielmatrix, CrossDB und minimale Rechte offen.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
