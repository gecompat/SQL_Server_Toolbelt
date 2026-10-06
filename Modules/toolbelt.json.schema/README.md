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
erteilt keine Rechte. Die native Qualifikation dieses neuen Pfads bleibt offen.

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
1.0.0-Nachweise. Der erste native1.0.1-CI-Versuch scheiterte am2026-10-06
auf SQL2019/2022 an Msg515 in der Upgrade-Capture-Fixture; die symmetrische
Leerkatalognormalisierung ist korrigiert und statisch geprüft.
[Fehlversuch und offene Abnahme](Tests/NATIVE_EVIDENCE.md) bleiben ausdrücklich
getrennt: native1.0.1-API, echter1.0.0→1.0.1-Upgrade und exakte korrigierte
Head-CI sind PENDING. Weitere Matrix, CrossDB, Minimalrechte und
vollständige Lifecycleabnahme bleiben offen. Aktuell teilweise validiert,
unreleased. [Beispiele](Examples/JsonSchema.sql) verwenden synthetische Daten.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-06`
- Nachweis: `https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37529400622`
- Scope: Numerische Schema1.0.1-CI-Diagnose am Head72080660c15b3dc33264cba2a1141e9c6a35d29d: Windows PASS; SQL2022/2025 FAILED im Faulttest mit Expected55699/Actual168; SQL2019 bei Erfassung noch laufend. Kein nativer Gesamt-PASS und keine bestätigte Fehlerursache. Separater noch nicht integrierter SQLCMD-i-Faulttransport bestand vier lokale Mockfälle und unabhängigen Review ohne Blocker; kein nativer Nachweis. Frühere zeitgebundene Records unverändert; aktuelle native Abnahme PENDING.
- Ergebnis: `failed`
<!-- END GENERATED:MODULE_EVIDENCE -->
