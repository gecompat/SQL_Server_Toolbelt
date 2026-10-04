# JSON 1.2: gemeinsamer CLR-Kern und Lifecyclevertrag

Stand: 2026-10-04. Kanonischer Vertrag für
`toolbelt.json.constructors` 1.2.0. Rootreview dieser gekoppelten Fassung ist
am 2026-10-03 abgeschlossen. Die produktive Umsetzung ist freigegeben,
begrenzte Source-, Build- und native Teilnachweise sind vorhanden; weitergehende
Qualifikation bleibt offen.
Historische 1.0-/1.1-Nachweise und deren SQL-only-Verträge bleiben unverändert.

## Freigabe und konkrete Grenze

Die beiden JSON-AGFs, der gemeinsame Kern und die Tiefengrenze128 wurden
bereits einzeln genehmigt. Am 2026-10-03 bestätigte der Benutzer nach
gesonderter Besprechung außerdem drei konkrete Lifecyclebedingungen mit
„ja“: exakte Markertypen und Werte, ausschließlich unabhängig qualifizierte
bekannte Binaries und kohärente vorhandene Eigentümer der SQL-Objekte und
Assembly. Es erfolgen keine automatische Rechtevergabe oder Ownerreparatur.

Die Migration verwendet eine eigene SAFE-Assembly im vorhandenen Modul:
Managed `Toolbelt.JsonConstructors` 1.2.0.0, SQL `Toolbelt_JsonConstructors`,
Namespace `Toolbelt.JsonConstructors`. Sie ergänzt genau
`AGF_JsonArray`, `AGF_JsonObject` und den internen
`FT_JsonEntryEvaluateInternal`. Zusammen mit den fünf vorhandenen P-Slots
entstehen acht SQL-Slots. Keine Diagnosehülle, zusätzliche öffentliche FT,
Datei-/Netzwerk-/Context-Connection, Bibliothek oder Registryinfrastruktur.

## Bestehende USP-Verträge und Bridge

Die vier öffentlichen USPs behalten sämtliche acht Parameter, Helpfirst,
beide Resultschemas, KeepData-/ResultTable-/Transaktionsregeln, UTF16-
Identitäten, globale Budgets und Fehlerpriorität ihrer
[bestehenden Verträge](JSON_GROUP_CONSTRUCTORS_CONTRACT.md).
`USP_JsonConstructInternal` bleibt der gemeinsame SQL-Adapter. Shared CLR
ersetzt den fachlichen Prüf-/Escapingkern; keine zweite Parserkopie entsteht.

Der FT bindet ausschließlich `JsonEntryEvaluateBridge.Evaluate` und `FillRow`.
Sechs Eingaben in Reihenfolge: ObjectMode bit, Key nvarchar(max),
ValueKind nvarchar(max), Value nvarchar(max), Stage tinyint, Policy tinyint.
Acht physisch nullable Ausgaben: Fragment nvarchar(max), ErrorNumber int,
ErrorState int, FaultPhase tinyint, RawValueBytes bigint, KeyBytes bigint,
StrongMinimumBytes bigint, FragmentBytes bigint. Genau eine interne Row.
SQL-Clientmetadaten und tatsächliche CLR-Bindung werden getrennt qualifiziert.

Stage0 ruft RawOnlyEntry vor dem ursprünglichen echten ISJSON auf. Stage1
führt Legacy-Finalize nach dessen erfolgreichem Abschluss aus. Der vorhandene
ISJSON-Fehler und dessen Position bleiben erhalten; kein nachgebildeter13606.
LegacyJson übernimmt keine AGF127-Ablehnung. Kind-/Key-/NULL-Vorbedingungen
und Rawkosten müssen vor einer begrenzten Valuekopie stehen. Kein Trim oder
Paddingnormalisieren. Defensive unvollständige Strongkosten sind NULL;
Datenfehler liefern Fragment NULL und FragmentBytes0, niemals Teilerfolg.

Die unmögliche interne Transportform ist ein eigener technischer Fehler.
`53611/1` ist nach erneuter repositoryweiter Kollisionssuche ohne fremden
Treffer ausschließlich für den technischen JSON-Bridgevertrag reserviert.
Managed technische Exceptions werden nicht pauschal in
Legacydatenfehler oder erfolgreiche Rows umgedeutet.

## Aggregate und genaue Profile

`JsonArrayAggregate.Accumulate` besitzt Ordinal int, ValueKind nvarchar(max),
Value nvarchar(max), Profile tinyint; Object fügt nach Ordinal Key
nvarchar(max) hinzu. Ergebnis nvarchar(max). Init/Merge/Terminate und
IBinarySerialize.Read/Write sind an die jeweiligen Produktklassen gebunden.
Ordinal ist positiv/eindeutig; Keys sind vollständig UTF16-byteidentifiziert.
Ausgabe wird nach Ordinal geordnet, nicht nach zufälliger Callbackreihenfolge.

| Profil | Entries | JSON-Payloadbytes | Serialisierter Zustand |
|---|---:|---:|---:|
| 1 | 10000 | 2097152 | 5242880 |
| 2 | 100000 | 16777216 | 37748736 |

Wireversion3 und beide Profilgrenzen werden durch dieselben qualifizierten
Produktquellen bestimmt. Entrytiefe127 plus äußerer Aggregatcontainer ergibt
Finaltiefe128. Profile dürfen nicht vermischt werden. Fehler-/Budgetzustände
werden vollständig und fail closed transportiert; kein Teilergebnis.
Die SQL-Engine darf Callbacks, Partitionierung und Merge frei bestimmen;
daraus folgen keine Callbackhäufigkeits-, Spill-, Heap- oder Hardwallzusagen.

## Konkreter qualifizierter Buildkandidat

Die modullokale
[Registryzeile](../../Modules/toolbelt.json.constructors/Documentation/KNOWN_CLR_ARTIFACTS.json)
enthält ausschließlich den tatsächlich offline qualifizierten Produktbuild
mit allen acht Sourcehashes und FT-/AF-Bindings. SHA256:
`4a414f5326f617de1225b0a23183bf51d1322361e3156d64027dfd2c3b69e6af`.
SHA512 und Managedidentität sind in derselben Zeile fest gebunden.
Die unveränderten privaten Produktbytes bestanden Compilerreproduzierbarkeit,
vollständige IL-Metadatenprüfung, drei synthetische Cultureläufe mit jeweils
37 Fällen/962 Assertions und einen großen synthetischen Lauf mit drei
Fällen/67 Assertions. Dies ist ausschließlich Offlineevidenz. Private Pfade,
Runtimeausgaben und Inventardaten werden hier nicht übernommen.

Die Zeile ist `OFFLINE_QUALIFIED_KNOWN_ARTIFACT`, kein installierter1.2-Nachweis.
Neue Binarybytes verlangen neue unabhängige Qualifikation und neue Zeile.
Ein Targethash ersetzt niemals die KnownInstalled-Zeile. SQLmarker oder eine
Datenbankkopie der Zeile sind keine Registryautorität. Keine Dummyhashes oder
Adoption eines Debug-/Diagnosebinaries.

## Exakte ArtifactId-Präimage

Format ist modullokal `toolbelt.json.constructors.known-artifact/v1`:
elf ASCII-Bytes `TBXJSONART1`, uint32 little-endian Feldanzahl, danach jedes
Feld in der expliziten `fieldOrder`-Liste der Registrydatei. Pro Feld folgen
uint32 little-endian Namensbytelänge, strikte UTF8-Namensbytes ohne BOM,
uint32 little-endian Wertbytelänge und strikte UTF8-Wertbytes ohne BOM.
Alle Werte sind Strings; Zahlen kanonische ASCII-Dezimalstrings,
Hashwerte lowercase ASCII-Hex fester Länge. Keine NULLs, unbekannten Felder,
Duplikate, Normalisierung oder zusätzlichen EOF-Bytes.

ArtifactId ist lowercase hex SHA256 dieser vollständigen Präimage ohne
ArtifactId selbst. Die konkrete Zeile hat34 Felder und2824 Präimagebytes,
ID `e5d0a37f7643a1a7bbe17602ab0d8457bc959464e97496f45f6ddbe92fa15525`.
JSONpropertyreihenfolge oder Whitespace werden nicht gehasht. Pfade,
Buildzeitpunkt, OwnerIDs und Deploymentmode sind nicht enthalten; dieselbe
Produktzeile gilt lokal und zentral. Neue Framingsemantik erhält eine neue
Formatversion. Diese feste Zeile schafft kein allgemeines Registryframework.

## Assemblymarker und installierte Zustände

Genau class5, eigene assembly_id als major_id, minor_id0. Alle sechs
Pflichtfelder existieren genau einmal und sind nicht NULL. BaseType,
MaxLength, DATALENGTH und vollständiger Wert werden unabhängig geprüft;
keine TRY_CONVERT-Adoption abweichender Typen.

| Feld | Exakter Typ / MaxLength | Exakter Inhalt / DATALENGTH |
|---|---|---|
| Toolbelt.Managed | int / 4 | 1 / 4 |
| Toolbelt.ModuleId | nvarchar(64) / 128 | toolbelt.json.constructors / 52 |
| Toolbelt.ModuleVersion | nvarchar(16) / 32 | 1.2.0 / 10 |
| Toolbelt.DeploymentMode | nvarchar(16) / 32 | local / 10 oder central / 14 |
| Toolbelt.AssemblySha512 | varbinary(64) / 64 | actualfile_id1SHA512 = bekannte Zeile / 64 |
| Toolbelt.ArtifactId | varchar(64) / 64 | lowercase ASCII-Hex der bekannten ID / 64 |

ABSENT verlangt wirklich abwesende alte Marker, alle acht freien Zielslots
und freien Assemblynamen. NULLmarker sind nicht absent. KNOWN1.0/1.1 haben
genau ihre drei/fünf bekannten P-Slots; die neuen FT-/AF-/Assemblynamen
müssen frei sein. KNOWN1.2 verlangt acht kohärente Slots, SAFE-Assembly,
vollständiges class5-Tuple, bekannte Zeile, file1SHA512 und exakte tatsächliche
FT-/AF-Katalogbindungen. UNKNOWN/inkohärent wird nicht repariert/adoptiert.
Die bisherigen P-Marker und deren bekannte eigene Source-Reparatur bleiben
erhalten; SourceHash bleibt diagnostisch, kein Ownershipbeweis.

## Owner, Metadatensicht und atomarer Lifecycle

Effektiver SQL-Objectowner ist expliziter sys.objects.principal_id, sonst
Schemaowner. Alle fünf P, FT und beide AF sowie Assembly müssen denselben
kohärenten bereits autorisierten Principal besitzen. Keine ALTER AUTHORIZATION,
GRANT, CREATE USER, Signing-/EXECUTE-AS- oder Ownerreparatur.

Vollständige relevante Metadatensicht ist vor Mutation und frisch unter
derselben AppLock erforderlich. SQL-/Assemblyverbraucher, Referenzen,
Bindings, Marker, bekannte Installedzeile und Owner werden in beiden Pässen
neu gelesen. Bestehende Uninstall-Voraussetzung VIEW DEFINITION und SELECT
auf sys.sql_expression_dependencies bleibt erhalten, 0/NULL fail closed.
Die neue Assembly-/Referenzsicht darf nicht aus einer leeren Abfrage gefolgert
werden. Trustfreigabe ist getrennt von Markerownership und Binaryidentität.
Kein Trust-Wildcard, TRUSTWORTHY oder Abschalten von clr strict security.

Caller-TX-Reject steht weiterhin vor SET/TempDDL/Mutation. Alle eigenen
DDL-/Markeränderungen sind transaktional gekoppelt; exakte alte Release- und
fremde Zukunftsslots bleiben geschützt. Lifecyclecodes53620..53629/State1
behalten ihre Kategorien: Rechte/Voraussetzung22; unbekannt23;
fremder neuer Slot24; Bestätigung25; Consumer26; Lock/Drift27;
finaler Zustand28; SQL-Version20, Modus21, CL29. Bridge-/AGF-Datenfehler
werden nicht in diese Kategorien umgebogen. Originalfehler bleiben erhalten.

## Noch getrennt zu schließende Gates

Root hat diesen Vertrag und die gekoppelte tatsächliche Zeile vor
produktiver Source geprüft. Bytegleiche CLR-Quellen, der kanonische lokale
Projektbuild und begrenzte Legacy-/Lifecycleadapter wurden getrennt geprüft;
Offline-Buildnachweise ersetzen keine SQLqualifikation.

Die lokale native Acht-Fixture-Regression auf Linux2019/CL150 und
Windows2025/CU8/CL170, das lokale genuine1.1-Upgrade mit acht Slots und sechs
typisierten Markern, genuine1.0 lokal/zentral mit Repeat/Uninstall und
zentraler Bestätigung/Consumer sowie sechs erste-GO-Negativfälle sind getrennte,
begrenzte Teilnachweise. Der Guest-Kontext916/4 und der Owneränderungsfall
blieben NOT_EXECUTED. Tests-README und Testmatrix halten die genaue Reichweite
fest; daraus folgt keine vollständige Produktqualifikation.

Offen bleiben vollständige Regression aller vier USPs einschließlich echter
ISJSON-Position/13606, Fehlerprioritäten/Unicode/nullableKosten/Help/ResultTable,
weitere native FT-/AF-/Clientmetadaten und AGFprofile, weitere Upgrade- und
Repeat-/Uninstall-Zielkombinationen sowie Collision/Owner/Registry/Visibility/
AppLock/Rollback jenseits der beschriebenen Proben und tatsächliche lokale/
zentrale Callerrechte mit bereits geeignetem
eingeschränktem Kontext. Gleicher Owner allein beweist keine Callerchain.
Ohne verfügbaren Kontext bleibt das Rechtegate NOT_EXECUTED; kein Erzwingen
durch Rechteänderung. Weitere Zielmatrix, Heap/Spill, aktuelle CI und Release
sind ebenfalls offen. Bestehender Modulstatus wird durch diesen Vertrag
nicht aufgewertet.
