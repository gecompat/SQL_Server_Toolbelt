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
Releases. Der bekannte1.0.0→1.0.1-Upgrade benötigt zusätzlich das bereits
vorhandene `ALTER`-Recht auf `ASSEMBLY::Toolbelt_JsonSchema`; der Lifecycle
erteilt keine Rechte. Der begrenzte native CI-Nachweis dieses Pfads gilt für
den exakten Head83164b5; die übrige Lifecyclematrix bleibt offen.

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
bytegleichen Schema-Projektbuild- und Paketierungsprüfungen; final15 Phasen
und acht Packagingfälle nach Common-Härtung. Ein einziger strict-UTF8-
Byteinput ist an den festen historischen Snapshot-SHA256 gebunden; neu
gerahmte Constructorframes werden vor Ausgabe abgewiesen. Der Kandidat
entspricht semantisch exakt der aktiven Registry und ihren Binaryhashes.
Die früheren erfolgreichen sechs Packagingfälle bleiben getrennte Historie.
Die bisherigen
nativen Core-/Schema-Contract-, Safety-, Client- und begrenzten Lifecycle-Läufe
auf Linux2019/latest CL150 und Windows2025/CU8 bleiben historische
1.0.0-Nachweise. Für1.0.1 bestand am2026-10-06 die
[native CI am exakten Head83164b5](Tests/NATIVE_EVIDENCE.md):
SQL2019/CL150,2022/CL160 und2025/CL170 jeweils local/central mit
genuine1.0.0→1.0.1-Upgrade, Rollback,40 Contractfällen pro Modus, Safety,
CrossDB, Repeat und Cleanup. Frühere Fehlläufe bleiben historische Records.
Jeder spätere Head benötigt vor Integration eigene erfolgreiche Checks;
weitere physische Matrix, Minimalrechte und vollständige Lifecycle-/
Kapazitätsabnahme bleiben offen. Aktuell teilweise validiert,
unreleased. [Beispiele](Examples/JsonSchema.sql) verwenden synthetische Daten.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-06`
- Nachweis: `https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37532174433`
- Scope: Schema1.0.1 am exakten Head83164b539e637deeb1ad21b74a15cad99e0184c1: Windows und Linux-SQL2019/CL150,2022/CL160,2025/CL170 PASS. Schema je SQL-Version local/central: genuine1.0.0-DLL, Mode-Abweisung, erwarteter post-ALTER55699-Rollback, aktueller Uninstall alt/Reinstall/Upgrade/Repeat, zweimal40 Contractfälle, Safety, CrossDB und Cleanup; je acht Upgrade- und zwei Safety-Witnesses, kein UnexpectedSQL/CleanupUnverified-Witness. SQLCMD-Dateifaulttransport im tatsächlichen Testpfad bestanden. Breitere Constructor-CL-Matrix ist kein Schema-Nachweis. Docs37532174428 am selben Head PASS; frühere failed/PENDING-Records bleiben Historie, Actual168-Rootcause nicht bewiesen. Neuer Dokumentationshead benötigt eigene exakte CI; übrige physische-/Minimalrechte-/Lifecycle-/Kapazitätsmatrix und Release offen. Partially validated, unreleased.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
