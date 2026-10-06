# JSON Schema und gemeinsamer JSON-Core – freigegebener Vor-Source-Vertrag

RelatedReference: RI-2026-048. Stand2026-10-05, Codex.
Status: accepted; implementiert, begrenzte Offline- und native Teilqualifikation vorhanden, unveröffentlicht. Aktuelle Head-CI und übrige Matrix offen.

## Tatsächliche Einzelzustimmung

Nach Besprechung anhand [PR175](https://github.com/gecompat/SQL_Server_Toolbelt/pull/175)
bestätigte der Benutzer die konkrete Frage zu USP_ValidateJsonSchema,
toolbelt-2020-12-v1, zehn Ergebnisfeldern, exakten Zahlen-/Unicodeprüfungen,
lokalen nichtrekursiven Referenzen, globalem Arbeitsbudget, vollständigem
Urteil trotz Diagnosekürzung sowie gemeinsamem SAFE-Core und
semantikerhaltender Constructor1.2→1.3-Migration mit:

> Diese Schema-/Kern-Welle freigegeben

Die nachfolgend übernommene Fassung konkretisiert den ausdrücklich freigegebenen
Umfang. Die ursprüngliche Researchvorlage bleibt getrennte Besprechungshistorie.
Keine erneute Freigabefrage für diese Funktion oder diese Migration.
Neue Binaries werden separat qualifiziert; neue Trusthashes benötigen weiterhin
ihr exaktes Opt-in gemäß dem damaligen Vorschlag. Die anschließende ausdrückliche
Trustfreigabe des Benutzers erlaubt die notwendigen begrenzten Tests dieser
Welle ohne erneute Hashfragen; die konkrete Identität und Qualifikation bleiben
erforderlich. [Datierte Autorität](../../Modules/toolbelt.json.core/Documentation/TRUST_OPT_IN_PROPOSAL.md).
Keine Veröffentlichung, Fremdrechte oder Lab-Infrastruktur.

## Wartung1.0.1 – bestehender Reihenfolgevertrag

Stand2026-10-06, Codex: Schema1.0.1 korrigiert die bereits freigegebene
Reihenfolge vollständig codierter Schema-/Refgraphorte. Die Formprüfung
erfolgt beim geordneten Schemaortbesuch; die Zyklusprüfung folgt budgetiert
codierten Zielpfaden. Bei mehreren fehlerhaften `$defs` kommt beispielsweise
`/$defs/z` vor `/$defs/~0` und `/$defs/~1`. Bei Schemaarrayorten kommt der
codierte Index10 vor2. Instanzmember werden weiterhin nach decodierter
UTF16-Identität und Instanzarrays numerisch evaluiert. Öffentliche Parameter,
Profilumfang, Fehlercodes und Ergebnisfelder bleiben gleich.

Die neue Schemaassembly hat die Managedidentität1.0.1.0. Core1.0.0 und
Constructors1.3.0 behalten ihre bekannten Bytes und unveränderten historischen
Registryframes. Der exakte alte Schema1.0.0-Frame wird im historischen
Closure-Snapshot bewahrt. Der Maintenancepfad erkennt kohärente bekannte
1.0.0-/1.0.1-Tupel, aktualisiert den alten Stand atomar auf1.0.1 und hält den
Uninstall beider bekannten Releases offen. Fremde Tupel, unbekannte Bytes,
Consumer- und Ownergrenzen bleiben abweisend; keine Dependencyinstallation
oder Rechtevergabe. Eine Registryidentität erteilt keine Test- oder
Trustautorität.

Die [begrenzte Offline-Qualifikation](../../Modules/toolbelt.json.schema/Tests/Framework/README.md)
bestand am2026-10-06. Die echte historische1.0.0-DLL wurde separat für einen
künftigen Upgradeversuch reproduziert. Native1.0.1-API, tatsächlicher
SQL-Upgrade und exakte aktuelle Head-CI bleiben offen; die historischen
nativen1.0.0-Nachweise qualifizieren die geänderte Assembly nicht.

## Öffentliche Signatur

Schema toolbelt_json, USP_ValidateJsonSchema; genau diese Reihenfolge:

| Parameter | Typ | Default / zulässiger Bereich |
|---|---|---|
| Json | nvarchar(max) | NULL; SQL-NULL ist Fachstatus |
| Schema | nvarchar(max) | NULL; SQL-NULL ist Fachstatus |
| Profile | varchar(32) | toolbelt-2020-12-v1, exakt |
| MaxDocumentBytes | bigint | 16777216;1..16777216 |
| MaxSchemaBytes | bigint | 1048576;1..1048576 |
| MaxDepth | int |128;1..128 |
| MaxEvaluationSteps | bigint |1000000;1..1000000 |
| MaxErrors | int |100;0..100 |
| ResultTable | sysname |NULL |
| KeepData | bit |0 |
| Debug | tinyint |0 |
| Hilfe | bit |0 |

Standardtail und Helpfirst entsprechen unverändert dem USP-Vertrag.

## Ein öffentliches fachliches Resultset

| Ordinal | Name | SQL-Typ | NULL |
|---|---|---|---|
|1|RowKind|varchar(8)|Nein|
|2|ErrorOrdinal|int|Nein|
|3|Status|varchar(24)|Nein|
|4|Profile|varchar(32)|Nein|
|5|IsValid|bit|Ja|
|6|DocumentPointer|nvarchar(max)|Ja|
|7|SchemaPointer|nvarchar(max)|Ja|
|8|Keyword|nvarchar(128)|Ja|
|9|ErrorCode|varchar(32)|Ja|
|10|ErrorsTruncated|bit|Nein|

Characterfelder verwenden im eigenen unterstützten Pfad explizite ordinale
UTF16-/BIN2-Identität ohne Trim, Casefold oder Normalisierung. Physische
CLR-Bridge-Nullability ist gesondert zu qualifizieren; die öffentlichen
Texttypen bleiben varchar beziehungsweise nvarchar gemäß Ergebnistabelle.
Die interne CLR-TVF transportiert sämtliche Zeichenfelder als nvarchar:
RowKind8, Status24, Profile32, Keyword128, ErrorCode32 und die beiden
max-Pointer; ihr Profile-Parameter ist nvarchar(32). Die USP bildet die
festen ASCII-Felder in ihre öffentlichen varchar-Spalten ab. Dies entspricht
den [CLR-Parametermappings](https://learn.microsoft.com/en-us/sql/relational-databases/clr-integration-database-objects-types-net-framework/mapping-clr-parameter-data)
und der [Unicodegrenze für CLR-TVFs](https://learn.microsoft.com/en-us/sql/relational-databases/clr-integration-database-objects-user-defined-functions/clr-table-valued-functions).
NOT-NULL-Spalten werden durch die eigene typisierte SQL-Ergebnishülle zugesichert.

## Sichtbarer Profilumfang

Boolean-Schemas; $schema ausschließlich https://json-schema.org/draft/2020-12/schema;
$defs und nichtrekursive lokale Fragment-$ref; type, required, properties,
additionalProperties, items, prefixItems, min/maxItems, min/maxProperties,
min/maxLength, minimum/maximum/exclusiveMinimum/exclusiveMaximum;
title/description/$comment als typisierte Annotationen. Fehlendes $schema wird
nur durch das explizite Profil interpretiert. Alle übrigen Keywords, externe
Referenzen, Zyklen, andere Drafts, format, pattern, uniqueItems, multipleOf,
enum/const, Kombinatoren, Konditionale, unevaluated* und dynamic refs sind
UNSUPPORTED. Keine volle Draftkonformitätszusage, Downloads, Defaults, Coercion,
Datenänderung oder automatische Work-Type-Integration.

Vollständige Schemaort- und Graphprüfung einschließlich ungenutzter $defs.
Containment und Referenzen gemeinsam prüfen; DAGs nicht expandieren. Lokale
Referenzen # oder #/... nach einmaligem strikt gültigem Percent-/UTF8-Decoding,
danach RFC6901 ~1/~0. Referenzziele müssen bekannte Schemaorte sein.
Decoded Keys ordinal einschließlich NUL/trailing spaces; Duplicatekeys in
beiden Inputs ungültig. Wohlgeformte UnicodeScalars für Länge, lone Surrogate
UNSUPPORTED. Exakte Mantissen-/Exponentziffernvergleiche und Integersemantik
ohne native decimal-/float-Rundung oder Materialisierung riesiger Nullpads.

Die zugehörige Zahlenkernausarbeitung in
[NEXT_DEVELOPMENT_WAVES_2026-10-04.md](../Research/NEXT_DEVELOPMENT_WAVES_2026-10-04.md)
bleibt ergänzende fachliche Grundlage. 16MiB Input garantieren keinen Abschluss
unter einer Million Schritten; unvollständige Arbeit liefert LIMIT/IsValidNULL.

## Übernommene konkrete Provider-, Lifecycle-, Fehler- und Abnahmefassung

## Physische Schema-Kerngrenze

RelatedReference: `RI-2026-048`. Funktion, Core und Migration sind freigegeben;
neue Trusthashes bleiben separat. Pointer ist unabhängig in
[PR174](https://github.com/gecompat/SQL_Server_Toolbelt/pull/174) umgesetzt und
nach vier erfolgreichen Checks am exakten Head gemergt. Dessen native
Grammatikautorität wird durch diesen Vorschlag nicht ersetzt.

### Nachvollziehbarer Repositorybefund

Der [Constructor-CLR-Preflight](../../Modules/toolbelt.json.constructors/Deployment/ClrPreflight.sql)
prüft nicht nur fremde SQL-/CLR-Bindings. Sobald irgendeine andere Assembly
`Toolbelt_JsonConstructors` referenziert, weist er den Lifecycle mit53626 ab.
Eine Schemaassembly könnte deshalb auch bei unveränderten Constructorbytes
Repeat, Upgrade und Uninstall des bestehenden Moduls blockieren. Dies ist eine
Source-/Vertragsanalyse; kein neuer SQL-Assemblyreferenztest wurde ausgeführt.

Die historische Constructor-Projektdatei1.2
kompilierte `AgfCore.cs` direkt zusammen mit sieben weiteren Quellen. Die
[aktuelle Projektdatei](../../Modules/toolbelt.json.constructors/Clr/Toolbelt.JsonConstructors.csproj)
referenziert stattdessen den gemeinsamen Core. Eine
Erweiterung oder Verschiebung dieses Scanners verändert die qualifizierte
Buildclosure. Das Festhalten am bisherigen DLL-Hash macht eine geänderte
Projektdatei oder neue Source nicht zu einem reproduzierbaren1.2-Artefakt.
Die geschlossene1.2-Registry bleibt historische Wahrheit und wird nicht mit
neuen Bytes überschrieben.

[Modell und Abhängigkeiten](../Architecture/MODULE_AND_DEPENDENCY_MODEL.md)
verlangen genau einen kanonischen Fachkern; eine Dependency darf nicht durch
kopierte Objekte ersetzt werden. Der Text erteilt keine ausdrückliche Ausnahme
für zweimal in getrennte Assemblies kompilierte Parserquellen. Source-Linking
ist deshalb nicht ohne weitere Entscheidung als regelkonforme physische
Wiederverwendung zu behaupten. Historische Versionen und deren Nachweise bleiben
getrennt; daraus folgt kein zweiter aktiver Scanner im neuen Zielstand.

[CREATE ASSEMBLY](https://learn.microsoft.com/en-us/sql/t-sql/statements/create-assembly-transact-sql)
beschreibt Datenbankregistrierung, referenzierte Assemblies und kohärente
Owner. Das ist keine automatische Toolbelt-Dependencyinstallation: Der
Projektvertrag verlangt einen vollständigen Preflight und ausdrücklich
vorhandene, geeignete Abhängigkeiten. Keine zusätzlichen Dependencybytes in
CREATE ASSEMBLY einschleusen, kein Dateipfad-Fallback.

### Vergleich der konkreten Integrationsrichtungen

| Richtung | Konsequenz | Entscheidungsvorschlag |
|---|---|---|
| Neue Schemaassembly referenziert unveränderte Constructors1.2 |53626 blockiert den vorhandenen Lifecycle; Scanner besitzt zusätzlich keine vollständige Schema-Token-/Arbeitsabrechnung | Nicht als unabhängige Erweiterung umsetzen |
| Scanner nach Schema kopieren oder in zwei aktuellen Assemblies Source-linken | Zwei physische Parser; genaue Bedeutung von kanonischer Wiederverwendung wäre gesondert zu genehmigen | Keine implizite Ausnahme ableiten |
| Schema im Constructor-Modul ergänzen | Gemeinsame Assembly möglich, aber neuer öffentlicher Scope, größere Bindingclosure und gekoppelte Release-/Lifecycle-Einheit | Technisch mögliche Alternative; kein unabhängiges Schemamodul behaupten |
| Eigene technische Kernassembly, Constructor-Migration und darauf aufbauendes Schemamodul | Ein physischer CLR-Scanner, klare versionierte Dependencies; drei gekoppelte Build-/Lifecycle-Verträge statt einer unabhängigen Funktion | Bevorzugte zu besprechende Richtung für den eigenen SAFE-Provider |
| Native T-SQL-Schemaevaluation | Native Grammatikautorität vermeidet einen zweiten handgeschriebenen CLR-Parser; vollständige Key-/Tokenindizes, exakte Zahlen, globale Arbeitsabrechnung und Evaluation bleiben zu entwickeln | Gültige Alternative, keine gemessene Überlegenheit oder abgeschlossene Machbarkeit |

### Freigegebener Providerumfang

Die folgenden Namen und Versionen sind ausdrücklich freigegeben. Status und
Registrierung werden erst mit den jeweiligen vollständigen Artefakten gepflegt:

1. `toolbelt.json.core`1.0.0 mit SQL-Assembly `Toolbelt_JsonCore`, Managedidentität
   `Toolbelt.JsonCore`1.0.0.0. Reine technische SAFE-Dependency in derselben
   Installationsdatenbank, ohne öffentliche SQL-Entrypoints. Kanonische JSON-
   Number-/String-/Containerlexik, Escape-/Unicodeprimitive und optionaler
   Tokenindex/Arbeitszähler. Keine Dateien, Netzwerk, Context-Connection,
   eigene Threads, globale veränderliche Zustände oder Drittanbieter.
2. Constructors1.3.0 mit unveränderten acht SQL-Slots und öffentlichen
   Signaturen, aber neu qualifizierten eigenen Assemblybytes und Referenz auf
   Core1.0.0. Legacy- und AGF-Adapter behalten ihre bisherigen Fehlerprioritäten,
   Raw-/Strongkosten, Native-ISJSON-Stufe, Legacy-Tiefenverhalten und AGF127-
   Entrygrenze. Scannerlexik wird in den Core verlegt, nicht dupliziert.
3. `toolbelt.json.schema`1.0.0 mit `toolbelt_json.USP_ValidateJsonSchema`, eigener
   SAFE-Assembly `Toolbelt_JsonSchema` / Managed `Toolbelt.JsonSchema`1.0.0.0 und
   genau einer internen Bridge `FT_ValidateJsonSchemaInternal`. Die USP behält
   die oben vorgeschlagenen acht Fachparameter und den unveränderten
   ResultTable-/KeepData-/Debug-/Hilfe-Tail; die Bridge transportiert dieselben
   acht Fachargumente und zehn Ergebnisfelder. Die Schemafachlogik nutzt den
   gemeinsamen Core; der interne FT ist keine zusätzliche öffentliche API.

Das sichtbare Profil, unterstützte/unsupported Keywords, vollständige
Schemaort-/Referenzgraphprüfung, nichtrekursive lokale Fragmentrefs,
UnicodeScalar-Längen, ordinale decodierte Keyidentität und exakte dezimale
Zahlenvergleiche entsprechen dem zuvor ausgearbeiteten V1-Vorschlag.
`MaxErrors`0..100 begrenzt nur Diagnosen; unvollständige Arbeit ergibt
LIMIT/IsValidNULL. Keine Float-/Decimalrundung, Defaults oder Coercion.
Die anschließende konkrete Fehler-/Diagnosematrix gehört zum ausdrücklich
freigegebenen Vertrag.

### Migration und Lifecycle

Core und abhängige Assemblies liegen je local/central in derselben
Installationsdatenbank. Ein zentraler Consumer ruft die öffentliche USP auf;
er benötigt keine Assemblykopie in seiner Datenbank. Dependencyversion,
Installationsmodus, bekannte Binaryidentität, typisierte eigene Marker,
Bindings und kohärente vorhandene Owner werden vor der ersten Mutation
geprüft. Rechte oder Owner werden nicht automatisch repariert.

Der freigegebene Ablauf lautet: Core separat installieren, bekannte
Constructors1.2 separat auf1.3 migrieren, danach Schema installieren.
Schema-Preflight weist vorhandene Constructors1.2 im Zielstand ab, statt
zwei aktive Scanner zuzulassen. Ein fehlendes Constructormodul ist kein
Installationszwang; Core bleibt ausdrücklich erforderliche Dependency.
Historische Installerskripte sind keine unterstützte Downgrade-Route des
neuen Zielstands. Kein automatisches Nachinstallieren oder stilles Update.

Constructor-Migration verlangt einen kohärenten bekannten1.2-Ausgangsstand,
keine fremden Consumerslots/Assemblyreferenzen und separat vorhandenen Core.
Neue Constructorbytes werden unabhängig qualifiziert und als neue Registryzeile
geführt. Eigene DDL/Bindings/Versionsmarker bilden eine kurze atomare
Transaktion; fehlende oder unbekannte Voraussetzungen brechen ohne Mutation ab.
Öffentliche USP-/AGF-Semantik und vorhandene Fremdconsumer dürfen nicht beiläufig
umgebaut werden. Eine neue detaillierte Migrationsentscheidung muss die
vorhandene DEC-2026-033 ergänzen, ohne sie rückwirkend umzuschreiben.

Native Konkretisierung2026-10-05: Der genuine1.2-Versuch meldete SQL6282,
weil `ALTER ASSEMBLY` keine neue Assemblyreferenz erlaubt. Der erste Ansatz
mit acht erhaltenen ObjectIds ist damit verworfen, kein Migrationsnachweis.
[Microsofts Fehlervertrag](https://learn.microsoft.com/en-us/sql/relational-databases/errors-events/database-engine-events-and-errors-6000-to-6999)
bestätigt diese feste Enginegrenze. Der bereits freigegebene atomare
DDL-/Bindingaustausch erhält die fünf Procedure-ObjectIds und ihre Rechte;
die eigene Assembly und drei CLR-Slots werden in derselben Transaktion neu
erstellt. Namen, SQL-/Managed-Signaturen, effektive Owner und Wireversion3
bleiben erhalten. CLR-ObjectIds/AssemblyId sind kein erhaltener Vertrag.

Vor jeder Mutation und erneut unter den Locks werden direkte Rechte auf
den drei CLR-Slots/der Assembly, explizite CLR-Objectowner, vom Schemaowner
abweichende effektive Owner und zusätzliche Extended Properties abgewiesen
(53622/state1). Es werden keine Rechte neu erteilt, Annotationen verworfen
oder Owner repariert. Fremde SQL-/Assemblyverbraucher bleiben ausgeschlossen.
Bekannte Zustände mit solchen Zusatztupeln benötigen eine separat geplante
Migration; dieser Installer verändert sie nicht. Post-DROP-Rollback muss die
exakte1.2-Ausgangsidentität samt Bytes/Markern restaurieren. Der native Nachweis
dieses korrigierten Pfads bestand auf Linux2019/latest CL150 und Windows2025/
CU8 CL170 jeweils local/central, mit vier aktuellen Constructor-Fixtures,
nachgelagertem Schema, gezieltem post-DROP-Rollback und frischem Dispositionaudit.
[Begrenzte native Evidenz](../../Modules/toolbelt.json.schema/Tests/NATIVE_EVIDENCE.md).

Core darf bei verbliebenen Assemblyverbrauchern nicht entfernt oder
inkompatibel ersetzt werden. Abhängige Module entfernen nur ihre eigenen
SQL-/Assemblyslots und niemals Core oder fremde Consumerslots. Removal erfolgt
explizit in umgekehrter Dependencyreihenfolge. Upgrade mit aktiven Verbrauchern
braucht eine qualifizierte kompatible Kernversion oder weist ab; allgemeines
ALTER-ASSEMBLY-Erfolgspotenzial ersetzt diesen Vertrag nicht.
[ALTER ASSEMBLY](https://learn.microsoft.com/en-us/sql/t-sql/statements/alter-assembly-transact-sql)
beschreibt zusätzliche technische Einschränkungen für referenzierte Assemblies.

Neue Kern-, Constructor- und Schemabinaries benötigen je eigene bekannte
Artifactidentität, reproduzierbaren Build, vollständige Framework-/IL-/NoIO-
Qualifikation und exakten SHA2-512-Trust-Opt-in. Bestehende Known-Artifact-/
Trustfreigaben autorisieren keine neuen Hashes. `clr strict security` bleibt
aktiv; kein TRUSTWORTHY, Rechtegrant oder Serverneustart.

### Konkrete Abnahme und verbleibende Grenze

Vor Produktbindings: Core-Unit-/Differentialnachweise gegen die bestehende
Constructorsemantik, exakte Token-/Zahl-/Unicode-/Budgetoracles, vollständige
Schema-Preflight-/Evaluationstests und Build-/IL-Gates. Danach begrenzte
schema-validierte native Ziele mit direkten Clientmetadaten, Help/ResultTable-
Atomik, local/central/Consumer, Install/Repeat/Migration/Uninstall, Caller-/Lock-/
Rollback-/Marker-/Fremdslot-/Assemblydependencyfällen und frischem Bereinigungsaudit.
MaxErrors0 und abgeschnittene Diagnosen müssen eine fortgesetzte Evaluation
beweisen; gefundene Verletzung vor späterem LIMIT ergibt kein IsValid0.

Der begrenzte Source-Frameworklauf ist ausgeführt und separat in der
[Frameworkdokumentation](../../Modules/toolbelt.json.schema/Tests/Framework/README.md)
beschrieben. Die anschließend getrennt ausgeführten begrenzten nativen
Core-/Schema-/Migrationprüfungen stehen in der
[nativen Evidenz](../../Modules/toolbelt.json.schema/Tests/NATIVE_EVIDENCE.md).
Diese Offlineevidenz beweist keine SAFE-Ladbarkeit, native semantische Parität,
Performance oder einen Release.
Die tatsächliche Einzelzustimmung autorisiert diese Funktion und diese
Core-/Constructor-Migration. Build, Parität, Lifecycle und neue SQL-Bindings
sind gesondert zu qualifizieren; die autonome Umsetzung wird fortgesetzt.

### Freigegebene Schema-Fehlerpriorität und Diagnosen

Diese konkret besprochene Matrix ist durch die Einzelzustimmung eingeschlossen.
Sie ist der öffentliche Zielvertrag; tatsächliche Produktqualifikation bleibt
getrennt von der autorisierten Implementierung nachzuweisen.

Helpfirst gilt gemäß [USP-Vertrag](../Standards/USP_CONTRACT.md).
Ansonsten Profile exakt `toolbelt-2020-12-v1`; alle Budgetparameter NOT NULL,
MaxDocumentBytes1..16777216, MaxSchemaBytes1..1048576, MaxDepth1..128,
MaxEvaluationSteps1..1000000 und MaxErrors0..100. Ungültige Parameter werfen
vor ResultTable-Mutation. Als bisher kollisionsfreie Arbeitsnummern wurden
55600/1 für Parameter und55601/1 für unmöglichen internen Bridgetransport
gegen aktuelle Module/Architektur/Backlog geprüft. Die freigegebene Source
verwendet diese Nummern; die ursprüngliche Recherche allein war keine
Implementierungsfreigabe. Globale Infrastrukturfehler
werden nicht umnummeriert oder als erfolgreiche Fachzeilen abgefangen.

Bei gültigen Parametern zuerst SQL-NULL in Json/Schema erkennen; danach
Schema-Inputbudget, vollständiger Schema-Preflight, Dokument-Inputbudget,
vollständiger Dokument-Preflight und Evaluation. Jeder gestartete Schritt ist
an die verbleibende Arbeit gebunden. Byte-/Depth-/Arbeitslimit führt sofort zu
LIMIT/IsValidNULL; damit wird kein späterer Syntaxfehler behauptet oder
nachträglich gesucht. Bei verfügbarer Arbeit wird JSON-Grammatik vor
Unicodepolicy, danach Duplicatepolicy und Schemaform/Keywordgraph geprüft. Das gesamte
Schema einschließlich unerreichter Orte wird vor dem Dokument geprüft.
Diese eigene Schema-Limitregel übernimmt nicht still die Pointer-Priorität.

| Situation | Status | IsValid | ErrorCode / Diagnose |
|---|---|---|---|
| Ein Input SQL-NULL | SQL_NULL | NULL | SQL_NULL in SUMMARY; keine ERROR-Zeile |
| Schema/Dokument zu groß | LIMIT | NULL | SCHEMA_BYTES / DOCUMENT_BYTES |
| Offene Containertiefe über MaxDepth | LIMIT | NULL | DEPTH_LIMIT |
| Arbeit vor nächstem Schritt nicht ausreichend | LIMIT | NULL | EVALUATION_LIMIT |
| Schema-JSON-Grammatikfehler | INVALID_SCHEMA | NULL | JSON_SYNTAX |
| Dokument-JSON-Grammatikfehler | INVALID_JSON | NULL | JSON_SYNTAX |
| Ungepaarte decodierte Surrogate | UNSUPPORTED | NULL | UNPAIRED_SURROGATE |
| Doppelte decodierte Objektkeys | INVALID_SCHEMA oder INVALID_JSON nach betroffenem Input | NULL | DUPLICATE_KEY |
| Schemaort weder Boolean noch Object; ungültige Keywordform | INVALID_SCHEMA | NULL | SCHEMA_FORM / KEYWORD_FORM |
| Lokales Ref nicht auflösbar oder Ziel kein Schemaort | INVALID_SCHEMA | NULL | REF_TARGET |
| Fehlerhafte lokale Fragment-/UTF8-/Pointerform | INVALID_SCHEMA | NULL | REF_SYNTAX |
| Externe Ref / Zyklus / anderer Draft / unbekanntes oder ausgeschlossenes Keyword | UNSUPPORTED | NULL | EXTERNAL_REF / REF_CYCLE / DRAFT / KEYWORD_UNSUPPORTED |
| Vollständig im Profil geprüft, keine Verletzung | VALID | 1 | NULL |
| Vollständig im Profil geprüft, mindestens eine Verletzung | INVALID_INSTANCE | 0 | INSTANCE_VIOLATION in SUMMARY; konkrete Codes in ERROR-Zeilen |

Die konkret vorgeschlagenen Verletzungscodes sind FALSE_SCHEMA, TYPE,
REQUIRED, ADDITIONAL_PROPERTY, MIN_ITEMS, MAX_ITEMS, MIN_PROPERTIES,
MAX_PROPERTIES, MIN_LENGTH, MAX_LENGTH, MINIMUM, MAXIMUM,
EXCLUSIVE_MINIMUM und EXCLUSIVE_MAXIMUM. Integer ist mathematisch zu prüfen;
beispielsweise gilt1e1000000 als Integer,1e-1000000 nicht, sämtliche
syntaktisch gültigen Nullformen dagegen schon. Eine widersprüchliche
Grenzenkombination ist ein gültiges, gegebenenfalls unerfüllbares Schema.

Genau eine SUMMARY-Zeile mit ErrorOrdinal0; ERROR-Zeilen haben1..N und
N<=MaxErrors. Alle zehn Spalten behalten die oben vorgeschlagene Reihenfolge,
Typen und Nullability. Status/Profile/IsValid/ErrorsTruncated werden auf allen
Zeilen erst nach dem vollständigen Ausgang einheitlich gesetzt. Kein früher
Teilerfolg oder Streaming einer später zu widerrufenden IsValid0-Zeile.
Bei vollständig erfolgreichem VALID ist ErrorsTruncated0. Unterdrückte
Verletzungen setzen ErrorsTruncated1, auch bei MaxErrors0; die Evaluation
läuft weiter. LIMIT überschreibt das Gesamturteil auch nach Verletzungen.
Bereits gespeicherte Diagnosen dürfen dann verbleiben, sind aber alle mit
StatusLIMIT/IsValidNULL gekennzeichnet. Die SUMMARY trägt stets den finalen
Limitcode; ein erschöpftes Diagnosebudget kann ihn nicht verstecken.

DocumentPointer/SchemaPointer sind RFC6901-Stringformen. Leerer String
bezeichnet die bekannte Wurzel, SQL-NULL einen nicht bestimmbaren/nicht
betroffenen Ort. Bei REQUIRED zeigt der Dokumentpfad auf das Objekt, der
Schemapfad auf den fehlgeschlagenen required-Eintrag. ADDITIONAL_PROPERTY
zeigt auf den betroffenen Member und additionalProperties. TYPE und
Längen-/Zahl-/Countgrenzen zeigen auf geprüften Wert und Keyword.
FALSE_SCHEMA zeigt auf Wert und Boolean-Schemaort; Keyword ist dabei NULL.
Preflightfehler zeigen soweit bekannt auf den betroffenen Inputort;
SUMMARY enthält sonst keine fingierten Detailpfade. Kein Value-/Payloadecho.
Bei beliebig langen unbekannten Keywordnamen bleibt Keyword NULL statt
stiller Kürzung auf128 Zeichen; SchemaPointer ist die vollständige Diagnose.

Deterministische ERROR-Reihenfolge: unterstützte Keywords in einer festen
Profilreihenfolge; Member ordinal nach vollständig decodierter UTF16-Identität,
Arrays nach Index; required nach Schemaarrayindex. Schema-/Refgraphorte werden
nach vollständig codiertem SchemaPointer geordnet. $ref-Ziel wird vor seinen
lokalen Geschwistern evaluiert. Feste Profilreihenfolge: $ref, Boolean-Schema, type, minProperties,
maxProperties, required, properties, additionalProperties, minItems,
maxItems, prefixItems, items, minLength, maxLength, minimum, maximum,
exclusiveMinimum, exclusiveMaximum. Nicht passende Typkeywords wirken gemäß
Draftsemantik nicht als zusätzliche type-Assertion. SQL-Ausgabe wird über
ErrorOrdinal explizit geordnet; Sortiervergleiche und Pfadkopien zählen zur Arbeit.

### Abstrakte Arbeitsabrechnung

Die versionierte Arbeitsabrechnung zählt verbrauchte, kopierte und gehashte
UTF16-Einheiten, ordinale Vergleichsschritte, numerische Ziffern sowie Token-,
Schema-, Keyword-, Graph- und Evaluationsbesuche. Variable Arrays, Listen,
Maps, Tokens, Strings und Pfadkopien werden vor ihrer Allokation belastet.
Der Zähler verwendet eine überlaufsichere Subtraktion vom verbleibenden Budget.
Er ist ein abstraktes Kostenmodell, kein CPU-Zeit- oder Heaplimit.

Der feste begrenzte Kontrollrahmen, die terminale SUMMARY und die Kapazität
für höchstens101 Transportzeilen sind vom variablen Modell ausgenommen.
Variable Diagnostik wird vor ihrer Erstellung belastet; die bereits
reservierten finalen Statusfelder können auch nach Budgeterschöpfung gesetzt
werden. Dadurch bleibt ein späteres LIMIT in allen retained ERROR-Zeilen und
der SUMMARY sichtbar. Diagnosekürzung autorisiert keinen Evaluationsabbruch.

Ein Schritt ist eine versionierte abstrakte Einheit, keine CPUinstruktion
oder Hardwallgarantie. Ein globaler verbleibender Zähler wird vor jedem
gehörenden Schritt vermindert: UTF16-Unit im Scanner/Decoder/Hasher,
Unitpaar im ordinalen Vergleich, Zahl-/Exponentziffer, besuchter Token/
Schemaort/Keyword/Graphkante/Evaluationsauftrag sowie kopierte UTF16-Unit
bei Diagnose-/Key-/Zahlenbuffer. Wiederholte Verarbeitung kostet erneut;
Hashkollisionen dürfen exakte Vergleiche nicht kostenlos machen. Zusätzliche
Token-/Frame-/Graph-/Diagnoseeinträge werden vor Allokation ebenfalls belastet.
Kosten immer als `cost > remaining` prüfen, danach subtrahieren; keine
überlaufgefährdete Addition oder Allokation vor dem Gate. Kein viruelles
Padding für riesige Exponenten tatsächlich materialisieren.

Lexiksyntax, Tokenindex und Duplicateprüfung verwenden denselben decodierten
Keyvertrag. Der Scanner liest vollständige Keys ohne OPENJSON4000-Kürzung;
ordinale Gleichheit beinhaltet NUL und trailing spaces. Token-/Graphindizes
werden einmal aufgebaut, DAGs nicht expandiert. Wiederholte semantische
Evaluation desselben DAG-Orts an verschiedenen Dokumentorten bleibt neue
Arbeit und neue Diagnostik. Kein Budgetcache, der Pfade oder Urteil verfälscht.

### Synthetische Abnahmematrix

| Gruppe | Entscheidende Oracles |
|---|---|
| Input/Help | Help mit NULL/ungültigen Budgets ohne Mutation; SQL_NULL; alle positiven Budgetränder; MaxErrors0; ungültiges Profile |
| Lexik/Unicode/Keys | Scalar-/Containerroots; mixed raw/escaped Surrogate; ungepaarte Keys in unselektierten Members; NUL/trailing spaces; Keys über4000Units; gleiche raw/escaped Keys als Duplikat |
| Schemaform | Boolean; type-String/Array einschließlich Duplicate-/Leerfehler; required auch leeres Array, aber keine doppelten Namen; properties/$defs als Object; prefixItems nichtleer; items/zusätzliche Properties als Boolean/Object |
| Vollständiger Preflight | Ausgeschlossenes Keyword in ungenutzten $defs; andere Drafts; fehlerhafte Annotationform; unsupported Namen nur an Schemaorten, nicht gleichnamige Propertykeys |
| Referenzen | #/leere Root; einmaliges strict Percent-/UTF8-Decoding; ~0/~1; NUL-Key; ungelöstes/nichtSchema-Ziel; lokale Geschwister; Containment-plus-Refzyklen; gemeinsam genutzte azyklische Ziele ohne Expansion |
| Exakte Zahlen | Minimum/Maximum inklusive/exklusive; negative Null; riesige positive/negative Exponenten; mantissennahe Grenzen; Bruchzahl-Integer; native decimal/float-Bereich unabhängig |
| Evaluation | Jedes unterstützte Keyword positiv/negativ; fehlende required-Member; false Schema; items nach prefixItems; UnicodeScalar-Länge; widersprüchliche Grenzen als Schema gültig |
| Arbeit/Diagnosen | Limit vor Parser-/Token-/Graph-/Sortier-/Zahl-/Pfadallokation; Hashkollisionen; MaxErrors0/1; Verletzung vor späterem Limit; einheitliche finale Statusfelder; Ordinals stabil |
| Integration | Zehn direkte Clientspalten/Nullability; Help-Vertrag; ResultTable KeepData0/1 atomar; Callertransaktion/SET; local/central/Consumer; neuer Core-/Constructor-/Schema-Lifecycle mit fremden Dependencies und Rollback |

Diese Matrix ist ein verpflichtendes Testdesign, keine ausgeführte Evidenz.
Sie ersetzt keine einzelnen ausführbaren Tests oder echte Abnahmeläufe. Technische Kernel-, Migrations-, Produkt- und
Releasequalifikation bleiben bis zu tatsächlicher Ausführung offen.
