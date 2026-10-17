# SSIS-/DTSX-Workflow als schrittweise prüfbares T-SQL

Stand: 2026-10-16 · Autor: Codex · Status: `researched`, Schnittstellenentwurf.
Dies ist eine Machbarkeitsanalyse und keine Implementierungsfreigabe, kein
öffentlicher Runtime-Vertrag und kein Kompatibilitätsnachweis.

Konkretisierung nach Benutzerbesprechung: Der
[V1-Vertrag zur Freigabe](../Architecture/SSIS_DTSX_DEBUG_SELECT_V1_CONTRACT.md)
legt direkten T-SQL-/SSMS-Aufruf, den ersten Komponenten-/Ausdrucksumfang,
explizite lesende Same-instance-Katalogprüfung und das zusätzlich angeforderte
NOLOCK-Profil fest. Er ersetzt für V1 die folgenden vorläufigen API-/Provider-
Vorschläge, einschließlich des nun konkret begrenzten direkten ScriptDom-
Einstiegs und gekoppelten Parser-/Consumerpatchs; Implementierung und Runtime
bleiben nicht ausgeführt.

## Ergebnis und Aufgabenabgrenzung

Das Vorhaben ist für einen ausdrücklich begrenzten Komponenten- und
Ausdrucksumfang machbar. Empfohlen wird ein lokaler C#-Übersetzungskern mit
einem eigenen SSIS-Ausdrucksparser, einem typisierten Datenflussmodell und
ScriptDom für T-SQL-Syntax und die Prüfung erlaubter Konstrukte. Sein Ergebnis
ist lesbares Microsoft-T-SQL, kein SparkSQL, PySpark oder dbt. Eine SQL-CLR-USP
ist als optionale Toolbelt-Fassade sinnvoll prüfbar; Microsofts SSIS-Runtime
gehört nicht in diese Assembly.

Der Generator erklärt den Paketinhalt und erzeugt pro zusammengehörigem
Zielfluss ein SELECT. Er liest keine Quelldaten und führt weder Pakete noch
enthaltene Abfragen oder Tasks aus. Paketziele sind Projektionen. Das erzeugte
Skript darf ausschließlich eigene lokale Temp-Tabellen verändern; persistente
DML und DDL bleiben ausgeschlossen. Eine spätere manuelle Ausführung des
Debug-Skripts ist ein eigener Vorgang und kein impliziter Teil der Analyse.

Benutzerpräzisierung vom 2026-10-16: **Schrittweise Fehlereingrenzung ist
Kernumfang.** T-SQL bildet die Datenlogik nachvollziehbar ab; es baut SSIS nicht
nach. Bevorzugt wird ausdrücklich die vom Benutzer vorgeschlagene CTE-Kette:
`mains` → `calculated` → `lookup1` → `main_lookup1` → Split → Ziel.
Ein einziges unübersichtliches End-SELECT wäre unzureichend. Siehe
[Debug-Stufen](#debug-stufen-und-einzeln-ausführbare-abschnitte).

Restart, Checkpoints, Scheduler, vollständige Transaktions-, Event- und
Fehlerlaufzeit sowie schreibende Zielverarbeitung gehören nicht in diesen
ersten Funktionsvertrag. Unbekannte Logik wird sichtbar, nicht entfernt.
SQL_Server_Lab wird in diesem Auftrag weder geändert noch verwendet.

## Repositorygestützter Iststand

Untersucht wurde der lokale Toolbelt-Quellstand auf Basis von Commit
`8772e9d`, einschließlich Manifesten, Source und Fachverträgen. Die folgenden
Statuswerte stammen aus den aktuellen Manifesten, nicht aus älteren
Backlogbehauptungen. Alle aufgeführten Module sind `unreleased`.

| Vorhandener Baustein | Geprüfter Stand | Nutzen und tatsächliche Lücke |
|---|---|---|
| [Script-Parser](../../Modules/toolbelt.tsql.script-parser/module.yaml), [C#-Provider](../../Modules/toolbelt.tsql.script-parser/Clr/ScriptParserProvider.cs) | 2.0.0; `implemented`, `partially validated`; .NET Framework 4.8; `UNSAFE`, Windows | Vier lesende TVFs liefern Nodes, Properties, Tokens und Fehler, `DataAccessKind.None`. Keine DTSX-Verarbeitung, SSIS-Ausdrucksübersetzung, semantische Referenzbindung oder Schreibgrenzenprüfung. |
| [Parser-Härtung](../Architecture/TSQL_SCRIPT_PARSER_HARDENING_CONTRACT.md) und [Projektdatei](../../Modules/toolbelt.tsql.script-parser/Clr/Toolbelt.Tsql.ScriptParser.csproj) | Exakter ScriptDom-Pin 180.117.0 / FileVersion 18.0.117.0; Byte-, Tiefen-, Rohtext- und Ausgabelimits | Der SQL-Parser ist keine allgemeine Sicherheitsfreigabe. Große generierte CTE-Ketten können seine konservativen Grenzen überschreiten. Kein automatisches Aufweiten oder ungeprüfter Fallback. Historische 1.0-Evidenz qualifiziert 2.0 nicht. |
| [Dateiinhalt](../../Modules/toolbelt.file.content/module.yaml) | 1.0.0; `implemented`, `partially validated` | Optionale getrennte Einlesefassade; der Übersetzungskern sollte bereits gelieferte Bytes verarbeiten und keine Pfad-/Netzwerkrechte benötigen. |
| [ZIP Memory](../../Modules/toolbelt.archive.zip-memory/module.yaml) | 1.4.0; `implemented`, `partially validated`; `SAFE` | Listing und Extraktion als mögliche ISPAC-Zulieferung; kein ISPAC-/SSIS-Projektresolver. Containergrenzen und unterstützte ZIP-Varianten gelten weiter. |
| [XLSX-XML-Leser](../../Modules/toolbelt.file.xlsx-memory/Clr/Workbook.cs) | Modul 1.2.0; `implemented`, `partially validated` | Vorbild für `XmlReader`, `DtdProcessing.Prohibit`, `XmlResolver = null` und Limits. Fachlich an SpreadsheetML gebunden, keine öffentliche generische XML-/DTSX-API; nicht als SSIS-Abhängigkeit missbrauchen. |
| [Tabellenklon](../Architecture/TABLE_CLONE_TRIGGER_CONTRACT.md) | Bestehender Codegenerator mit AST-gebundenem Identifier-Rewriting für seinen freigegebenen Scope | Liefert ein Architekturbeispiel für Trennung von Parser und semantischem Verbraucher. Kein allgemeiner SELECT-Generator oder SSIS-Translator. |
| [SSIS-Worker-Vormerkung](NEXT_DEVELOPMENT_WAVES_2026-10-04.md#spätere-ssis-erweiterung--ausdrücklich-außerhalb-dieser-welle) | Separater späterer Queue-Provider | Paketaufruf/Workerbetrieb ist kein Duplikat der hier gewünschten lokalen Datenflussübersetzung. |

Die gezielte Suche in `Modules`, `Documentation`, `Backlog`, `.ai/BACKLOG.md`
und `.ai/ROADMAP.md` ergab keinen vorhandenen DTSX-/ISPAC-Reader und keinen
SSIS-zu-T-SQL-Debug-Generator. Der persönliche Brainstorm wurde gelesen:
Datei-/ZIP-/XLSX-Ideen sind angrenzende Hinweise, enthalten aber keinen
entsprechenden SSIS-Funktionsvertrag. Keine Änderungen an diesen Originalideen.

Die [Projektmatrix](../../.ai/PROJECT_CONTEXT.md) umfasst **SQL Server 2019,
2022 und 2025**, Windows und Linux modulabhängig. Der gemeinsame SQL-Dialekt
soll zunächst 2019 / CL150 verwenden; 2022/CL160 und 2025/CL170 werden explizit
geprüft. Azure und ältere Engineversionen erhalten keine automatische Zusage.
**Paketformatversion und SQL-Zielversion sind getrennte Größen.** Microsoft
beschreibt moderne DTSX-Formate in [MS-DTSX2](https://learn.microsoft.com/en-us/openspecs/sql_data_portability/ms-dtsx2/39efc022-1b2b-4538-8656-d147845d9135).
Konkrete Format-/Komponentenvarianten müssen über Fixtures freigegeben werden.

## Technische Varianten und Empfehlung

| Variante | Vorteile | Grenzen / Bewertung für dieses Vorhaben |
|---|---|---|
| T-SQL XML/XQuery | Native XML-Zerlegung, keine neue Assembly, SQL-nahe Ausgabe | Für Inventar und kleine bekannte Formatprofile brauchbar. Graphauflösung, versionierte Lineage, SSIS-Ausdrucksgrammatik und sichere SQL-Konstruktion würden große eigene T-SQL-Parser erfordern. Keine empfohlene alleinige Implementierung des vollen Debug-Umfangs. |
| Lokales C#/.NET, reines XML | Typisierte Graphen, eigene Ausdrucks-ASTs, Ressourcenbudgets und gut testbare Generatorstufen; ohne installierte SSIS-Komponenten | **Empfohlener kanonischer Kern.** Offline-Host zuerst qualifizieren; Framework-Ziel und ScriptDom-Assets explizit pinnen. Ein lokal ausführbarer Toolbelt-Host kann T-SQL auch für Linux-Server erzeugen, ohne dort CLR zu installieren. Keine Datenbankverbindung zur Generation erforderlich. |
| C# mit ManagedDTS/SSIS-Objektmodell | Reichhaltiges Modell bekannter Komponenten und Projektinformationen | Microsofts [Programmierbeispiel](https://learn.microsoft.com/en-us/sql/integration-services/run-manage-packages-programmatically/loading-and-running-a-local-package-programmatically?view=sql-server-ver16) benötigt `Microsoft.SqlServer.ManagedDTS`; Load und Execute sind verschiedene Operationen. Objektmodell-/Pipeline-/Custom-Komponenten, installierte Versionen, Provider, Lizenzierung und Ladeverhalten sind zusätzliche Voraussetzungen. Nicht mit reinem XML-Lesen gleichsetzen; kein Ausführen, Validieren oder Instanziieren unbekannten Paketcodes. Allenfalls isolierter späterer Importadapter. |
| SQL CLR über denselben C#-Kern | Direkte SQL-Toolbelt-Schnittstelle; Bytes hinein, Erklärung/SQL als Daten heraus | Optionale USP ist fachlich zulässig. Reines begrenztes XML könnte für `SAFE` qualifiziert werden; das ist keine Zusage für den Gesamtgenerator. Die Wiederverwendung des vorhandenen ScriptDom-CLR-Providers macht den entsprechenden Pfad Windows-only/`UNSAFE`. Keine Linux-Sicherheitsprüfung weglassen. |

Der C#-Vorteil ist hier Ausdrucks- und Graphkomplexität, kein bereits gemessener
Geschwindigkeitsgewinn. Ein Offline-Host vermeidet Eingabeverarbeitung und
Compilerabhängigkeiten im SQL-Server-Prozess. Eine zusätzliche CLR-Fassade
rechtfertigt sich durch SQL-integrierte Bedienung; gemeinsame Fachlogik wird
nicht dupliziert. Ob externe Kernbibliothek und CLR-Host denselben Build nutzen
können, ist im Dependency-Spike zu prüfen, nicht durch ein geratenes TFM festzulegen.

Nach [Microsoft](https://learn.microsoft.com/en-us/sql/relational-databases/clr-integration/common-language-runtime-clr-integration-programming-concepts?view=sql-server-ver17)
verwendet SQL CLR .NET Framework, nicht .NET Core/5+, und Linux unterstützt kein
`EXTERNAL_ACCESS`/`UNSAFE`. Die [Toolbelt-CLR-Regeln](../Architecture/CLR_SECURITY_AND_PORTABILITY.md)
verlangen technische Begründung, exakte Releasebindung und unverändertes
`clr strict security`. `SAFE` ersetzt keine Prüfung vertrauenswürdiger Binaries;
Microsoft beschreibt die [Grenzen des CAS-Sicherheitsmodells](https://learn.microsoft.com/en-us/sql/relational-databases/clr-integration/database-objects/clr-integration-programming-model-restrictions?view=sql-server-ver17).

Ein späteres SQL-Modul muss [Modell](../Architecture/MODULE_AND_DEPENDENCY_MODEL.md)
und [Deploymentvertrag](../Architecture/DEPLOYMENT_MODEL.md) erfüllen:
Manifest, versionierte Dependencies, Preflight vor Mutation, kein automatisches
Nachinstallieren/Vertrauen, Kollisionsschutz, bekannte Upgradepfade,
Release-Objektmanifest, Consumerprüfung und Uninstall nur eigener Objekte.
Ein SQL-CLR-Einstieg muss Help, ResultTable und Berechtigungen kapseln; die
internen CLR-Bindings erhalten keine eigenständige zweite Fachimplementierung.
Installation des Tools und das **generierte Debug-Skript** haben verschiedene
Lifecyclegrenzen: Das Debug-Skript installiert nichts.

## Einlesen und fehlender Kontext

DTSX-Bytes sind die primäre Eingabe. XML wird namespacebewusst anhand expliziter
Formatprofile gelesen; kein bloßes globales Suchen nach Komponentennamen.
`componentClassID`, Version und Struktur identifizieren den Adapter. Referenzen
werden über IDs, nicht Anzeigenamen, aufgelöst. Doppelte/dangling IDs,
unbekannte Versionen und unvollständige Metadaten erhalten Diagnosen.

Der Eingang prüft Bytegröße vor Dekodierung, BOM/Encoding, XML-Tiefe,
Element-/Attribut-/Textlängen und kumulative Komponenten-/Spalten-/Kantenlimits.
DTD, externe Entities, XInclude, Netzwerkauflösung und nachgeladene Schemas
bleiben aus. Eigene bekannte Schemata sind kein Anlass, Paketcode zu laden.
ZIP-/XML-Bomben, Pfadtraversal und doppelte Entry-Namen sind auch für ISPAC zu
begrenzen; kein Entpacken in beliebige Dateipfade.

Optionale Ergänzungen sind Projektparameter, `.conmgr`, Manifest, `.dtproj`,
Konfiguration und explizite Laufzeitbindings, gegebenenfalls aus einem ISPAC.
Der Zusatzadapter liefert diese Informationen an denselben Resolver; keine
automatische SSISDB-, Registry-, Umgebungs- oder Netzwerkabfrage. Ein ISPAC
enthält nicht automatisch alle tatsächlich zur Laufzeit verwendeten Werte.
Verschlüsselte oder ausgelassene sensible Teile bleiben fehlender Kontext.
Keine Entschlüsselungs-, Passwort- oder externe Uploadfunktion in diesem Slice.

Für Variablen/Parameter werden Scope, Namespace, Typ, Default, Ausdruck,
Herkunft und effektives explizites Binding getrennt gespeichert. Gleiche Namen
in verschiedenen Containern bleiben verschieden. Aufruferspezifische Overrides
gelten nur für den gewählten Debug-Fall und werden als Annahme ausgewiesen.
Unaufgelöste SQL-Command-Variablen, Tabellen-/Connection-Ausdrücke,
Script-Zuweisungen und Loopwerte sperren den betroffenen ausführbaren Slice.
Ein konkreter Iterationswert darf als ausdrücklich gewähltes Szenario dienen;
der Generator simuliert keine unbekannten vorangehenden Iterationen.

Die [OLE-DB-Quellenverträge](https://learn.microsoft.com/en-us/sql/integration-services/data-flow/ole-db-custom-properties?view=sql-server-ver17)
enthalten unterschiedliche AccessModes und ParameterMappings. Parameter werden
nach tatsächlicher Providersemantik gebunden, bei `?` gegebenenfalls ordinal;
SSIS-Variablen sind keine direkt einsetzbaren SQL-Variablen.
Auch eine [OLE-DB-Quelle](https://learn.microsoft.com/en-us/sql/integration-services/data-flow/ole-db-source?view=sql-server-ver17)
kann `EXEC` enthalten. Der Komponentenname „Source“ beweist daher keine Lesesicherheit.
Werte werden typisierte SQL-Parameter; Identifier werden getrennt validiert und
gequotet. Zusammengebauter SQL-Text muss nach vollständiger Auflösung erneut
geparst und geprüft werden. Keine Ersetzung durch Regex oder Textkonkatenation.

### JSON-Vorlage aus dem Paket und Rückgabe bearbeiteter Werte

Benutzervorschlag vom 2026-10-16: Die Funktion soll aus dem übergebenen DTSX
selbst eine JSON-Struktur der möglichen Variablen erzeugen. Der Benutzer ändert
Werte und gibt dieselbe Struktur zurück. **Diese Rundreise ist die empfohlene
Bedienung des bereits vorgesehenen `@Bindings`-Parameters.** Es wird keine zweite
manuell zu pflegende Parameterliste verlangt. Dies ergänzt den Entwurf, noch
keine implementierte API.

Zwei logische Operationen sollen denselben Import-/Resolverkern verwenden:

1. `bindings-template`: DTSX und optionalen Projektkontext übergeben; genau ein
   `BindingsTemplate`-Artefakt mit gültigem JSON ausgeben, dazu gegebenenfalls
   gesonderte Diagnoseartefakte im bestehenden einen Resultset. Kein SQL oder
   Paket ausführen. Der JSON-Text lässt sich unverändert kopieren/speichern.
2. `explain`: Dasselbe Paket und die bearbeitete Vorlage als `@Bindings`
   übergeben; Werte gegen das erneut eingelesene Paket prüfen, abhängige
   Ausdrücke soweit unterstützt auflösen und den gewählten Debug-Slice erzeugen.

Empfohlene Struktur: ein einfach bearbeitbarer `values`-Bereich und ein
beschreibender `availableInputs`-Bereich. Statische, ungeschützte Literaldefaults
ohne erkennbaren relevanten späteren Schreibzugriff werden in `values` vorbelegt.
Bei diesen Einträgen ändert der Benutzer lediglich
den Wert. Metadaten wie Typ oder Scope müssen nicht von Hand nachgetragen werden.
Ein schematischer, vollständig synthetischer Ausschnitt:

```json
{
  "schemaVersion": 1,
  "values": {
    "Package/Variables[User::FromDate]": "2026-01-01T00:00:00",
    "Package/Variables[User::BatchSize]": 1000
  },
  "availableInputs": [
    {
      "key": "Package/Variables[User::FromDate]",
      "kind": "variable",
      "scope": "Package",
      "name": "User::FromDate",
      "ssisType": "DateTime",
      "defaultValue": "2026-01-01T00:00:00",
      "valueOrigin": "design_literal",
      "requiredForSelectedFlow": true
    },
    {
      "key": "Package/Variables[User::BatchSize]",
      "kind": "variable",
      "scope": "Package",
      "name": "User::BatchSize",
      "ssisType": "Int32",
      "defaultValue": 1000,
      "valueOrigin": "design_literal",
      "requiredForSelectedFlow": false
    }
  ]
}
```

Das Beispiel zeigt noch keine endgültige JSON-Spezifikation. Die vollständige
Vorlage erhält zusätzlich eine Bindung an Paketinhalt, aufgelösten
Projektkontext und Importprofil; diese Bindung ist keine Ausführungsfreigabe.
Die tatsächlichen `key`-Werte erzeugt der Resolver eindeutig und opak anhand
gebundener Objekt-/Scopeidentitäten; die lesbaren Beispielpfade ersetzen keine
Kollisions-/Escapingregeln. Gleichnamige `User::FromDate` in Package und
Sequence-Container bleiben verschiedene Einträge. Namen und Referenzen werden
case-sensitive gebunden. Der Aufrufer muss Schlüssel nicht selbst konstruieren.

Der Umfang der Vorlage ist **alle im Paket erkannten Deklarationen plus
referenzierte Eingaben**, mit Kennzeichnung ihrer Verwendung im ausgewählten
Zielfluss. Dazu gehören Package-/Container-Variablen sowie erkennbare Package-
und Project-Parameter. Nur referenzierte Systemwerte müssen als Kontextbedarf
ergänzt werden; kein Anspruch, dass eine einzelne DTSX alle denkbaren Runtime-
oder Projektwerte enthält. Fehlender Projektkontext bleibt sichtbar. Eine
gefilterte Ansicht darf die relevanten Eingaben hervorheben, keine tatsächlich
benötigten Abhängigkeiten verbergen.

[Microsofts Variablenvertrag](https://learn.microsoft.com/en-us/sql/integration-services/integration-services-ssis-variables?view=sql-server-ver17)
unterscheidet Namespace/Scope sowie Wert und `EvaluateAsExpression`.
Daraus folgen für die vorgeschlagene JSON-Rundreise diese Regeln:

| Fall | Behandlung in Vorlage und Rückgabe |
|---|---|
| Statischer Literaldefault | In `values` vorbelegen, ursprünglichen Wert/Herkunft daneben erklären. Zurückgegebene Werte definieren den ausdrücklichen Debug-Fall. |
| Kein Eintrag in `values` | Kein expliziter Override. Aufgelösten Default/Ausdruck verwenden; bleibt der Wert für den Slice erforderlich und unbekannt, `missing_context`. |
| JSON `null`, Leerstring, false, 0 | Explizite unterschiedliche Werte. NULL nur bei einem dafür zugelassenen SSIS-/Debugtyp akzeptieren, sonst Typfehler; niemals fehlend mit NULL verwechseln. |
| `EvaluateAsExpression` / abhängige Variable | Ausdruck und Dependencies ausgeben, nur rein unterstützte Ausdrücke auflösen. Keinen gespeicherten/angezeigten Altwert automatisch in `values` als gültigen Runtimewert übernehmen. Änderung einer Eingabe berechnet abhängige Werte neu. Ein expliziter Wert für die berechnete Variable friert sie als gekennzeichnete pragmatische Szenarioannahme ein; Originalausdruck bleibt sichtbar. |
| Script-, Execute-SQL-, Loop- oder Taskzuweisung | Designliteral ist nicht automatisch der Zustand am gewählten Prüfpunkt. Sichtbaren Kontextbedarf am gewählten Data Flow/Stadium melden; ein explizites Szenariobinding gilt nur für diesen Zustand. Unbekannte Zuweisungslogik wird dadurch nicht übersetzt. |
| System-/Read-only-Wert | Keine Änderung am SSIS-Paket behaupten. Wenn für die Simulation erforderlich, einen ausdrücklich gekennzeichneten Debug-Kontextwert zulassen; sonst informative Metadaten. Unverändert kopierte Metadaten allein setzen keinen Systemwert. |
| Sensitive/verschlüsselte oder als Secret erkannte Inhalte | Keine automatische Default-/Wertausgabe. Status/fehlenden Kontext ausweisen; Connection-Credentials werden zur Offline-Generation nicht benötigt. Ein Debug-Fall kann geeignete synthetische Ersatzwerte verwenden; keine Secrets in SQL-/JSON-/Diagnoseexport übernehmen. |
| Project-Parameter / Deploymentwerte | Typ und belegten Designdefault erklären; fehlenden Projekt-/Deploymentkontext sichtbar lassen. `requiredForSelectedFlow` ist eine eigene Debugabhängigkeit, nicht das SSIS-Required-Flag. |

Microsoft unterscheidet bei [Package-/Project-Parametern](https://learn.microsoft.com/en-us/sql/integration-services/integration-services-ssis-package-and-project-parameters?view=sql-server-ver17)
Design-, Server- und Executionwerte. Unser Resolver liest keine SSISDB und
behauptet deshalb keinen tatsächlichen Deployment-/Executionwert aus dem DTSX.
Seine Priorität lautet: expliziter JSON-Szenariowert vor ausdrücklich geliefertem
aufgelöstem Kontext vor belegtem Designwert/unterstütztem Ausdruck. Herkunft und
fehlende Ausführungskontexte bleiben sichtbar. Insbesondere ist ein Required-
Parameter mit Designdefault keine Bestätigung eines gültigen deployed SSIS-Laufs.
[Property Expressions](https://learn.microsoft.com/en-us/sql/integration-services/expressions/use-property-expressions-in-packages?view=sql-server-ver17)
können wiederum von veränderlichen Runtimewerten abhängen; diese Vorlage ist ein
Debug-Szenario, keine Aufzeichnung eines realen Paketlaufs.

Bei Rückgabe bleiben Paket/Projektmodell die Typ-/Scopeautorität:
`availableInputs` dient der Bedienung, Änderungen daran verändern keinen
Variablentyp und keine Rechte. Unbekannte Schlüssel, doppelte JSON-Properties
oder Bindings, widersprüchliche Typen, nicht unterstützte Schemaversionen,
veraltete Paket-/Kontextbindung und benötigte unresolved Werte werden vor
SQL-Generation diagnostiziert. Kein stilles Zuordnen einer alten Vorlage zu
einem geänderten Paket; bei Drift neue Vorlage ausgeben und explizite Anpassung
verlangen. Ohne `@Bindings` bleiben belegte Paketdefaults/Expressions nutzbar;
fehlender notwendiger Kontext wird dadurch nicht übersprungen.

Zahlen werden gegen den im Paket gebundenen Typ exakt geparst, ohne Umweg über
Gleitkomma. Für Dezimalwerte und große 64-Bit-Ganzzahlen empfiehlt die Vorlage
verlustfreie Zeichenfolgen; Datum/Zeit mit festem sprachunabhängigem Format und
ohne erfundene Zeitzone, Boolesche Werte als JSON-Boolean. Object-/Recordset- oder
sonstige nicht einfach skalare Variablen erhalten zunächst keine erfundene
Skalarkonvertierung; betroffenen Kontext begrenzt ausweisen/blockieren.

**Vom Benutzer am 2026-10-16 bestätigte Darstellungsanforderung:** Die
bearbeitbaren skalaren Szenariowerte stehen am Anfang des generierten T-SQL
als typisierte `DECLARE`-Anweisungen mit sichtbaren Initialwerten. Die zugehörigen
CTEs verwenden diese Variablen; die Eingabewerte werden nicht zusätzlich an
verschiedenen Stellen der Datenflusslogik fest eincodiert. JSON ist die bequeme
Übergabe an den Generator; zum Ändern der Werte im erzeugten Skript ist weder
erneute JSON-Bearbeitung noch erneuter Generatoraufruf erforderlich.
Dies bestätigt die Darstellung im Plan, keine Produktimplementierung.

Vollständiges synthetisches Minimalbeispiel ohne Cache:

```tsql
-- Bearbeitbare Werte aus dem gewählten Debug-Szenario:
DECLARE @User_MinAmount decimal(18,2) = 100.00;

;WITH mains AS
(
    SELECT v.SaleId, CAST(v.Amount AS decimal(18,2)) AS Amount
    FROM (VALUES (1,75.00), (2,150.00)) AS v(SaleId,Amount)
),
filtered AS
(
    SELECT SaleId,Amount FROM mains WHERE Amount >= @User_MinAmount
)
SELECT SaleId,Amount FROM filtered;
-- Zum Prüfen das letzte SELECT durch SELECT * FROM mains; ersetzen.
```

Ein kleiner beschrifteter Werteblock enthält die für den jeweiligen Slice
benötigten Eingaben, ihre SQL-Typen und die Zuordnung zum ursprünglichen
SSIS-Scope/Variablennamen. Kollidierende Namen aus verschiedenen Containern
werden eindeutig abgebildet. Berechnete Variablen bleiben berechnete Ausdrücke;
nur ein ausdrücklich gewählter Szenariooverride wird als bearbeitbarer Wert
eingefroren und entsprechend gekennzeichnet. Literale werden typgerecht
formatiert/gequotet und mit dem vollständigen Skript erneut geprüft.

**Jeder eigenständig markierbare Prüfblock** enthält seinen Werteblock und die
vollständige benötigte WITH-Kette im selben Batch. Kein `GO` dazwischen;
separat ausgeführte DECLAREs leben nicht in einem späteren Batch weiter. Der
Benutzer führt zum Stufentest deshalb Deklarationen und CTE-Kette gemeinsam aus
und tauscht nur das abschließende SELECT. Die eigenständigen StageSql-Artefakte
enthalten diese Teile bereits zusammenhängend.

Cacheabhängigkeiten gelten auch bei **direkten Änderungen an den DECLARE-
Initialwerten**, nicht nur nach JSON-Änderung. Ein Lookup-/Stufencache, dessen
Inhalt von einem geänderten Wert abhängt, muss vor dem nächsten Stufentest neu
aufgebaut werden. Der Entwurf sieht dafür einen klar markierten eigenen
Vorbereitungs-/Neuaufbaublock und einen Abgleich der relevanten aktuellen
Werte mit dem eigenen Cachezustand vor; ein veralteter Cache wird nicht still
weiterverwendet. Gleichbleibende Lookup-Eingaben dürfen denselben einmal
gewählten Referenzstand für mehrere Prüfungen behalten. Bei unklarer Ownership
oder fehlendem Cachezustand keine vorbestehende Temp-Tabelle überschreiben.
SQL-Command-/Identifierwerte bleiben unter der gesonderten AST-/Namensprüfung
und werden nicht zu einem Textinjektionsweg.

## Internes Modell und verständliche Darstellung

Der Entwurf verwendet drei getrennte Ebenen:

1. **Paketmodell:** Container, Executables, Disabled-Zustände, Constraints,
   Parameter/Variablen, Verbindungen als logische Bindings und benötigter
   Projektkontext. Control Flow erklärt mögliche Aufrufbedingungen, er verbindet
   keine unabhängigen Data Flows zu einem erfundenen UNION.
2. **Datenflussgraph:** Komponenten, Input-/Output-Ports, Paths und explizite
   Spaltenzuordnungen. Ein Output ist eine eigene Relation. Vom gewählten
   Zielport rückwärts wird der erforderliche Teilgraph bestimmt; nur dieser
   erhält einen ausführbaren SQL-Slice. Zyklen/fehlende Kanten werden diagnostiziert.
3. **Relationales Modell:** Source, Project, UnionAll, LookupOne, Join, Filter,
   Aggregate, Deduplicate und Branch. Typisierte Expressions enthalten
   Originaltext, SSIS-AST, SQL-AST und Spaltenversionen. Rendering erzeugt CTEs,
   Unterabfragen oder APPLY aus diesem Modell und keine ungeprüften SQL-Fragmente.

Jede Spaltenversion hat eine modellinterne Identität mit Paket-/Data-Flow-/Port-
und Lineage-Kontext, Name, Ordinal, SSIS-Typ, SQL-Typ, Länge, Präzision/Scale,
Codepage/Collation und Nullability. Überschreiben erzeugt eine neue Version;
Namensgleichheit ist keine Herkunft. Destination-Metadaten und
`externalMetadataColumnId` gehören in die Auflösung. Zusätzlich zur
**Wertherkunft** werden **Zeilenabhängigkeiten** erfasst: Join, Split und Filter
können eine Zielzeile bestimmen, ohne einen projizierten Wert zu liefern.

Ausdrücke werden gegen ihre kanonischen Lineage-/Variablenreferenzen gebunden.
`FriendlyExpression` dient der Erklärung, nicht als alleinige Wahrheit bei
abweichendem `Expression` oder nicht auflösbaren IDs; solche Widersprüche werden
diagnostiziert statt durch Namensvermutungen verdeckt.

| Erklärungsartefakt | Inhalt |
|---|---|
| Workflow | Container/Task → Komponenten → benannte Ports/Paths → Ziel; Bedingungen und unaufgelöste Control-Flow-Voraussetzungen daneben |
| Formeln | SSIS-Originalausdruck, gebundene Eingaben/Variablen, lesbarer SQL-Ausdruck, Typ- und Fehlerannahmen |
| Spaltenherkunft | Zielspalte/Ordinal → Spaltenversion → Ausdruck → konkrete Source-/Lookupspalten; zusätzlich Pfadprädikate |
| SQL-Zuordnung | Stufenalias und SQL-Zeilen/Spannen → Komponenten-/Path-/Column-ID; stabile modellinterne Kennungen für diesen Import |
| Abdeckungsbericht | Alle erkannten Komponenten und alle offenen/unsupported Komponenten; Bewertung je Stufe und Zielfluss statt eines irreführenden Gesamtprozentsatzes |

Jede Interpretation erhält unabhängig von der Sicherheitsprüfung genau eine
Klasse: `translated` (für das definierte Profil hergeleitet), `pragmatic`
(ausdrückliche Annahme/Abweichung), `missing_context` oder `unsupported`.
`translated` ist kein empirischer SSIS-Gleichwertigkeitsnachweis.
Zusätzlich werden `complete`/`partial`, `safety_pass`/`safety_blocked` und die
betroffenen Nachfahren ausgewiesen. Eine unbekannte Script-Komponente bleibt
im Workflow; ihre Nachfahren erhalten kein ausführbares Ersatz-SELECT mit
erfundenen Werten. Ein vollständig verstandener Vorgänger-Slice bleibt prüfbar.

## Komponentenmatrix für den ersten Ausbau

Dies ist eine vorgeschlagene Unterstützungsfolge, keine implementierte Matrix.

| Komponente / Kontext | Übersetzungsregel | Grenzen und sichtbare Interpretation |
|---|---|---|
| SQL-Server-Source, Tabelle/View/SELECT | Explizite Projektion; SQL-Parameter und deklarierte Metadaten | Parser plus Schreibgrenze; View-/Funktionsdependencies separat binden. Fremddialekt, EXEC oder unresolved SQL kein ausführbarer Source-Slice. |
| Flat File, Excel, andere DB-Provider | Metadaten und fehlende Datenquelle erklären | Erster Slice kein automatisches OPENROWSET/Provider-Laden. Später explizite typisierte lokale Ersatzrelation als `pragmatic` möglich. |
| Union All | Nur vorhandene Inputs/Paths vereinigen, je Input explizites Outputmapping; fehlende Zuordnung als typisiertes NULL | Duplikate erhalten; keine namensbasierte Spaltenvermutung oder Zusammenführung unabhängiger Tasks. [Microsoft](https://learn.microsoft.com/sql/integration-services/data-flow/transformations/union-all-transformation). |
| Derived Column | Projektion/APPLY, eigene Version für ersetzte Spalte; alle Formeln einer Komponente gegen deren Eingangsstand | Originalwert beim Überschreiben innerhalb derselben Komponente erhalten, erst nächste Komponente liest neuen Wert. [Microsoft](https://learn.microsoft.com/en-us/sql/integration-services/data-flow/transformations/derived-column-transformation-editor). |
| Data Conversion / SSIS-Ausdrücke | Eigener typisierter Ausdrucksparser; begrenzte Operator-/Funktionsliste; explizite CASTs und Fehlerregeln | `ISNULL` in SSIS ist ein Prädikat, kein T-SQL-Ersatzwertaufruf. `?:`, `!`, Strings, NULLs, Überläufe, Codepages, Datumsformate, Scale und Abschneiden einzeln prüfen; TRY_CONVERT nicht als stiller Ersatz für Fehler. |
| Lookup | Referenzabfrage, alle Join-Ausdrücke, Ausgabemapping; immer LookupOne mit ROW_NUMBER und Filter 1 | Doppelschlüssel zulässig. Auswahl, Pfad und Vergleichsprofil dokumentieren; siehe unten. |
| Conditional Split | Ein geordnetes CASE erzeugt BranchId; Ausgang filtert genau diese ID, Default als ELSE | Erster wahrer Ausgang gewinnt. Keine unabhängigen Filter für überlappende Bedingungen. Fehler-/NULL-Disposition gesondert; siehe unten. |
| Merge Join | Deklarierte Schlüssel und INNER/LEFT/FULL; Duplikatmultiplizität erhalten | **Keine Lookup-Deduplizierung auf allgemeine Joins übertragen.** Sort-/Vergleichseigenschaften und NULL-Regeln prüfen. |
| Merge | Zwei tatsächlich verbundene Inputs relational zusammenführen | Mengeninhalt und Reihenfolge unterscheiden. Erforderliche Reihenfolge/Windowsvergleich nicht durch beliebiges UNION oder verlorenes ORDER BY als exakt ausgeben. [Microsoft](https://learn.microsoft.com/en-us/sql/integration-services/data-flow/transformations/merge-transformation?view=sql-server-ver17). |
| Aggregate | Gruppierung und einzelne Aggregate/Outputs mit expliziten Typen | COUNT(*)/COUNT(col)/COUNT(DISTINCT) unterscheiden; Überlauf-/Ausgabetypen und Stringvergleich prüfen. [Microsoft](https://learn.microsoft.com/sql/integration-services/data-flow/transformations/aggregate-transformation). |
| Sort / Deduplizierung | Ordnung als Metadatum; finale Debugsortierung bei Bedarf; bei EliminateDuplicates Partition nach **Sortschlüsseln/Vergleichsregeln** | Nicht blind DISTINCT über alle Spalten. Nichtschlüsselwerte benötigen Auswahlregel; kein identischer SSIS-Survivor versprechen. GUID-/Stringsortierung kann abweichen. [Microsoft](https://learn.microsoft.com/en-nz/SQL/integration-services/data-flow/transformations/sort-transformation?view=sql-server-2016). |
| Multicast | Gleicher Vorgänger als Input mehrerer Branches; jeder Zielfluss bleibt separat | Keine implizite Zeilenvervielfachung durch Zusammen-UNION aller Ziele. Bei volatiler Wiederverwendung optional eigene Temp-Materialisierung. |
| Destination | Endprojektion in Mappingreihenfolge mit expliziten Aliasen und dokumentierten Typen | Kein INSERT/MERGE. Identity/Defaults/Trigger/Constraints des Zielschreibens werden nicht nachgebildet; nicht gelieferte Zielspalten ausweisen. |
| Execute SQL / OLE DB Command / Prozeduraufruf | Als Kontext/Blocker erklären | Keine Übernahme in ausführbare Vorbereitung. Auch vermeintlich lesende Prozeduren sind im ersten Profil nicht freigegeben. |
| Scripts, Custom-/Drittanbieter, Fuzzy, SCD, unerkannte Transformation | Rohstruktur begrenzt und redigiert erklären, betroffene Nachfahren sperren | Kein Pass-through, kein ausgelassener Schritt, keine leere Relation als Ersatz. Je eigener Adapter später einzeln besprechen. |
| Loops, Events, Transaktionen, dynamische vorgelagerte Aufgaben | Voraussetzungen/fehlendes Szenario im Control Flow sichtbar | Erster Umfang ist ein expliziter Datenzustand/Szenario, keine vollständige Laufzeitemulation. |

Die SSIS-Ausdruckssprache braucht einen eigenen Parser; ScriptDom verarbeitet
T-SQL. Eine überprüfbare erste Teilmenge umfasst Spalten-/Parameterreferenzen,
typisierte Literale, einfache Arithmetik und Vergleiche, explizite NULL-Tests,
ausgewählte Konvertierungen und bedingte Ausdrücke. Potenziell fehlerhafte oder
nicht total definierte Ausdrücke dürfen durch SQL-Optimierer-Umsortierung nicht
als SSIS-Fehlerreihenfolge versprochen werden. Bei fehlender Belegbarkeit:
Stufe blockieren oder konkret genehmigte pragmatische Interpretation ausweisen.

### Split-Priorität und NULL

[Conditional Split](https://learn.microsoft.com/en-us/sql/integration-services/data-flow/transformations/conditional-split-transformation?view=sql-server-ver17)
wertet Ausgänge in konfigurierter Reihenfolge aus; eine Zeile geht nur an den
ersten zutreffenden Ausgang. Ein CASE mit einem einmal bestimmten BranchId
macht diese Priorität verständlich. Reihenfolge aus Metadaten lesen, nicht aus
Alphabet oder zufälliger XML-Reihenfolge. Fehlende/mehrdeutige Reihenfolge ist
fehlender Kontext.

Ein SQL-UNKNOWN darf nicht stillschweigend in den Default fallen. Microsoft
führt für [NULL-Ergebnisse des Split-Ausdrucks](https://learn.microsoft.com/en-us/dotnet/api/microsoft.sqlserver.dts.runtime.hresults.dts_e_txsplitstatic_expressionevaluatedtonull?view=sqlserver-2019)
einen Fehler samt möglicher Ignore-/Redirect-Disposition auf. Das Profil muss
deshalb Booleschergebnis und Fehler-/NULL-Zustand unterscheiden. Zunächst nur
nachweislich totale Bedingungen exakt übersetzen; andernfalls Fehlerpfad
modellieren oder die Stufe sperren. Eine ausdrücklich gewählte NULL→False-
Interpretation ist `pragmatic`, sofern nicht die konkrete Disposition sie belegt.
SQL-CASE garantiert keine allgemeine SSIS-Auswertungs-/Fehlerlaufzeit für seine
Unterausdrücke. Das synthetische Beispiel benutzt totale Bedingungen.

## Lookups: eine Referenzzeile je vollständigem Schlüssel

Die feste Projektanforderung lautet: **Jeder übersetzte Lookup** verwendet
`ROW_NUMBER() OVER (PARTITION BY <alle wirksamen Referenzschlüssel/-ausdrücke>
ORDER BY <Auswahl>)`; ausschließlich Nummer 1 wird gejoint. Zusammengesetzte
Schlüssel und sämtliche im Join verwendeten Normalisierungen, Typen und
Collations gehören identisch in die Partitionierung. Andernfalls kann der Join
trotz ROW_NUMBER wieder mehrere Treffer liefern. Unterschiedliche
Vergleichsprofile dürfen denselben Cache nicht teilen.

Eine fachlich gelieferte Sortierung wird verwendet. Ist sie nicht eindeutig,
werden verbleibende Ties als nicht deterministisch ausgewiesen; einen stabilen
Tie-Breaker darf der Generator nur aus begründetem Kontext ergänzen. Fehlt eine
Reihenfolge, ist `ORDER BY (SELECT NULL)` der vorgeschlagene pragmatische Default.
Die Wahl ist ausdrücklich beliebig, nicht reproduzierbar über Läufe und **keine
Reproduktion des von SSIS zuerst gewählten Treffers**. Microsoft beschreibt die
[Nichtdeterminismusgrenzen von ROW_NUMBER](https://learn.microsoft.com/en-us/sql/t-sql/functions/row-number-transact-sql?view=sql-server-ver17).
Lookup-Duplikate sind kein Ablehnungsgrund; Warnung und optional separat
ausführbares Duplikat-SELECT machen sie untersuchbar.

Die [SSIS-Lookup-Dokumentation](https://learn.microsoft.com/sql/integration-services/data-flow/transformations/lookup-transformation)
beschreibt zusammengesetzte Joins, ersten Treffer und Unterschiede zwischen
Full Cache und datenbankseitigen Vergleichen. Daraus folgt keine Gleichheit mit
unserer bewussten Auswahlregel. Der Debug-Generator entscheidet den Join über
den **gewählten Output und die Disposition**, nicht allein über Cachemodus:

| Gewählter Datenpfad | SQL-Darstellung |
|---|---|
| Ausschließlich Match | INNER JOIN auf LookupOne |
| Weiterlauf einschließlich ignorierter No-Matches | LEFT JOIN; NULL-/Ersatzwerte ausschließlich aus belegtem Mapping |
| Expliziter No-Match-Ausgang | LEFT JOIN und Filter auf fehlenden eigenen, nicht-nullbaren Matchmarker; alternativ äquivalenter Anti-Join |
| Match und No-Match zu verschiedenen Zielen | Eigenes SELECT je Ausgang; Cache gemeinsam möglich |
| Fail Component bei No-Match | Match-SELECT nur als solche Teilansicht; fehlende Zeilen in separatem Prüf-Slice sichtbar, keine stille Interpretation „Fehler = verwerfen“ |

Ein nullable Payloadwert ist kein zuverlässiger Matchtest. Der Generator fügt
referenzseitig beispielsweise `CAST(1 AS bit) AS LookupHit` hinzu. Keine
zusätzliche Gleichsetzung von NULL-Schlüsseln über COALESCE/Sentinel. Das erste
SQL-Vergleichsprofil verwendet normale SQL-NULL-Gleichheit und benennt dies als
gewählte Interpretation; andere SSIS-/Providerfälle benötigen konkrete Fixtures.

### Konsistenz innerhalb eines Debug-Laufs

CTEs sind keine zugesicherte Materialisierung. Mehrfache Verwendung einer CTE
mit beliebiger Auswahl kann andere Referenzzeilen lesen/auswählen, insbesondere
über mehrere Prüf-SELECTs. Wiederverwendete oder beliebig deduplizierte Lookups
werden deshalb standardmäßig **einmal ausgewählt und in einer eigenen lokalen
Temp-Tabelle festgehalten**, bevor die Prüf-SELECTs starten. Kein zweites Ranking
pro Branch. Derselbe Cache bleibt für alle Stufen dieses Laufes bestehen.

Ein Cache wird anhand logischer Connectionbindung, aufgelöster Referenzabfrage,
Parameterwerte, Schlüssel-/Vergleichsprofil und Auswahlregel identifiziert;
kein Credential oder Connection String wird dafür ausgegeben. Nur semantisch
identische Lookupdefinitionen teilen die Auswahl. Zwei unterschiedliche
SSIS-Lookups mit gleicher Tabelle dürfen getrennte Caches benötigen.
Ein diagnostischer Duplikatcount kann bei der einmaligen Aufnahme ermittelt
werden; erneutes Lesen einer veränderlichen Quelle ist kein gleichzeitiger
Beweis für den ursprünglichen Cache.

Diese Materialisierung friert die gewählte Referenz für den Debug-Lauf ein.
Sie emuliert weder zeitabhängige Partial-/No-Cache-Nachladevorgänge noch einen
gemeinsamen Snapshot aller Quellen. Veränderte Bindings oder bewusstes Neuladen
beginnen einen neuen Lauf. Ohne unterstützte Quelle einer Cache-Datei bleibt
der Lookup unaufgelöst; kein automatisches Lesen fremder Dateien.

Full-Cache-Vergleiche können sich bei Groß-/Kleinschreibung, Leerzeichen und
numerischen Typen vom SQL-Vergleich unterscheiden. [SSIS-Stringvergleiche](https://learn.microsoft.com/en-us/sql/integration-services/data-flow/comparing-string-data?view=sql-server-ver17)
enthalten zudem Locale-/Vergleichsflags. Deshalb pro Lookup explizites Profil
und Diagnose: SQL-Collation ist pragmatischer Standard, keine Full-Cache-Parität.
BIN2 allein garantiert insbesondere keine gleichartige Behandlung nachgestellter
Leerzeichen. Bei einem später belegten längensensitiven Profil gehören etwa
Längen-/Byteausdrücke sowohl in JOIN als auch PARTITION; keine pauschalen
UPPER-/TRIM-Korrekturen. Temp-Spaltencollation explizit setzen statt unbeabsichtigt
TempDB-Collation zu übernehmen. Auch [Merge-/Merge-Join-Sortierung](https://learn.microsoft.com/en-us/sql/integration-services/data-flow/transformations/sort-data-for-the-merge-and-merge-join-transformations?view=sql-server-ver17)
hat eigene Vergleichsanforderungen.

## Debug-Stufen und einzeln ausführbare Abschnitte

Die CTE-Kette ist die bevorzugte Lesedarstellung. Jede Stufe entspricht einem
fachlichen Schritt oder Output, nicht einer zufälligen Optimizeroperation:

```sql
WITH mains AS (...),
     calculated AS (... FROM mains),
     lookup1 AS (...),
     main_lookup1 AS (... FROM calculated LEFT JOIN lookup1 ON ...),
     routed AS (... FROM main_lookup1),
     split_high AS (... FROM routed WHERE BranchId = N'High')
SELECT ... FROM split_high;
-- Zum Eingrenzen das letzte SELECT ersetzen:
-- SELECT * FROM main_lookup1;
```

Dieses Schema ist Pseudocode, kein ausführbares Beispiel. Das vollständige
synthetische Beispiel folgt unten. Die Alternative mit Temp-Tabellen für jede
Stufe wäre für den Standard zu schwergewichtig; sie bleibt ein optionaler
Debugmodus, wenn das bewusste Festhalten von Zwischenergebnissen gebraucht wird.

Der Generator soll ergänzend je Stufe einen **vollständigen Prüfblock** erzeugen:
alle transitiv benötigten CTE-Vorgänger plus `SELECT ... FROM <Stufe>` und eine
Liste erforderlicher Temp-Vorbereitungen. Damit lässt sich ein Abschnitt direkt
markieren und ausführen. **Eine CTE gilt nur für das unmittelbar folgende
Statement.** Ein isoliertes `SELECT * FROM calculated` nach einem schon
ausgeführten WITH-Block funktioniert nicht. Deshalb keine losen SELECTs ohne
erneute CTE-Kette ausgeben. Nicht benötigte Nachfolger gehören nicht in den Slice.

| Prüfpunkt | Sinnvolle Beobachtung |
|---|---|
| Einzelquelle / `mains` | Eingangswerte, Quellkennung, Unionmapping und erhaltene Duplikate |
| `calculated` | Eingangsversion und Ergebnis nebeneinander; explizite Typen/Konvertierungen |
| `lookup1` | Ausgewählte Referenz pro vollständigem Schlüssel; gesonderte Duplikatansicht |
| `main_lookup1` | Vor-/Nach-Lookup, Matchmarker und NULL-Payload getrennt |
| `routed` | BranchId, Priorität und gegebenenfalls Bedingungsergebnisse |
| Einzelner Split-/Zielport | Genau dessen Zeilen und Spaltenmapping |

Diagnostische Hilfsspalten sind im Prüf-Slice erlaubt und gekennzeichnet, in
der Zielprojektion standardmäßig entfernt. Namen werden lesbar aus Komponenten
abgeleitet, nach Kollisionsprüfung gequotet und bei Bedarf ergänzt; die
Zuordnung enthält immer die Original-ID. Ein zusätzlicher begrenzter Preview-
SELECT darf TOP mit explizitem Limit anbieten, wird aber als **Stichprobe**
gekennzeichnet; kein stilles TOP in der eigentlichen Datenlogik.

Wiederholte CTE-Abfragen lesen Quellen erneut. Wer dieselben Eingangszeilen über
mehrere Prüfungen benötigt, kann einen ausdrücklich gewählten Stand in eigenen
`#...`-Tabellen materialisieren. Große Materialisierung/TempDB-Kosten sind dabei
sichtbar; es entsteht keine spontane SSIS-Laufzeit. Stufenmaterialisierung
erhält Typen, NULLs und Collation und muss selbst dieselbe Schreibgrenzenprüfung
bestehen. Cachevorbereitung, Stufen-Slices und Cleanup sind separat beschriftet;
Cleanup erst nach den gewünschten Prüfungen, kein Neuladen zwischen den Slices.

## Belastbare Prüfung der Grenze gegen persistente Änderungen

**Erklärungstext und ausführbares SQL sind unterschiedliche Artefakte.** Ein
unbekanntes Fragment darf im Bericht erscheinen, aber niemals als ausführbarer
Kommentarplatzhalter mit fehlender Logik in einem „fertigen“ Zielfluss.
Die Prüfung ist eine neu zu entwickelnde Funktion des Translators; die
vorhandenen Parser-TVFs allein liefern diesen Nachweis nicht.

Vorgeschlagene Prüfkette, für Endskript, jede Vorbereitung und jeden Prüf-Slice:

1. Paketinhalt ausschließlich als Daten einlesen. Kein `Execute`, `Validate`,
   dtexec, Task-/Script-/Custom-Assembly-Laden, Verbindungstest oder SQL-Preview.
2. Gebundene Quell-/Referenzabfragen in ein konservatives T-SQL-AST-Profil
   überführen. Alle Statements und Batches prüfen, keine Prüfung nur des ersten
   SELECT. Syntaxfehler, nicht verstandene AST-Knoten und Ressourcenüberschreitung
   sperren ausführbare Ausgabe.
3. Code ausschließlich aus geprüften relationalen Knoten und erlaubten
   Ausdrücken erzeugen. Zielnamen sind Projektionsmetadaten; niemals DML-Ziele.
4. Den **final gerenderten Text** erneut offline mit dem passenden SQL-Dialekt
   parsen. Jede Statementart, alle Unterabfragen, CTEs, Tabellen-/Funktionsaufrufe,
   Namen und DML-Ziele rekursiv binden. Kein Regex-Schlüsselwortfilter.
5. Nur SELECT, eigene rein skalare DECLAREs für geprüfte Szenariowerte und
   ausdrücklich erzeugte Operationen auf registrierten eigenen lokalen
   Temp-Tabellen erlauben. Deklarationen enthalten ausschließlich geprüfte
   skalare Typen und Literale; keine Table-Variablen oder ungebundenen Aufrufe.
   Erster Slice für Temp-Operationen möglichst nur CREATE TABLE,
   INSERT ... SELECT und DROP TABLE; weitere erlaubte Temp-Bearbeitung nur über
   bekannte Generatorformen. Ein `#`-Namenspräfix allein belegt keine Ownership.
   DML-Targets durch Alias/CTE auflösen; mehrteilige, globale oder fremde Ziele
   abweisen. Keine Trigger, UDF-Defaults, computed columns, Fremd-FKs oder andere
   Seiteneffektträger an erzeugten Temp-Tabellen.
6. Explizit sperren: persistente INSERT/UPDATE/DELETE/MERGE/TRUNCATE und DDL,
   SELECT INTO nicht eigener Temp-Ziele, EXEC/INSERT EXEC, dynamisches SQL,
   NEXT VALUE FOR, DBCC, USE, Rechte-/Server-/Datenbankänderungen, Transaktions-
   steuerung aus Paketen, SQLCMD-Directives/Includes und nicht freigegebene SET-
   oder Hintformen. Auch in „Source SQL“ oder einem Lookup sind diese verboten.
7. Remote-Passthrough wie OPENQUERY/OPENROWSET, Linked Server, externe Tabellen,
   unbekannte CLR-/UDF-Aufrufe und nicht gebundene Synonyme sperren. Ein SELECT
   ist nicht automatisch seiteneffektfrei. Views/Funktionen nur mit vollständig
   prüfbaren transitiven Definitionen; bei fehlender Metadatensicht kein PASS.
   Die notwendige Objekt-/Dependencybeschreibung wird explizit lokal zugeliefert,
   nicht durch Ausführen der Abfrage ermittelt. In einem kleinen Erstprofil
   dürfen Views/UDFs insgesamt blockiert bleiben.
8. Prüfergebnis an exakten SQL-Text, Dialekt, Policy-/Generatorversion und
   aufgelöste Objektbindungen binden. Änderungen an Text/Bindings/Dependencies
   invalidieren die Aussage. Offline unbekannte Katalogzustände bleiben offen;
   ein Hinweis „sicher“ darf diese Lücke nicht überdecken.

Die Prüfung beschreibt die erzeugten Befehle und bekannten aufgerufenen
Definitionen, keine garantierte Unveränderlichkeit einer später fremd geänderten
Datenbank. Ein späterer Ausführungsmodus müsste unmittelbar vorher erneut
binden und mit vorhandenen minimalen Leserechten arbeiten. Ein solcher Executor
ist **nicht** Teil dieser Funktion. Rollback oder Parse-only-Serveroptionen
ersetzen keine Prüfung und rechtfertigen keine Probeausführung extrahierten SQLs.

Eigene Temp-Namen sind pro Lauf eindeutig und kollisionsgeprüft. Vorbestehende
Tabellen werden nicht gelöscht/übernommen. Cleanup betrifft ausschließlich nach
erfolgreicher Erzeugung registrierte eigene Objekte. Auch optionale Fehler-
und Diagnostic-Ausgaben benutzen keine persistenten Logtabellen. Paketinhalt,
SQL, Pfade und Bindings können vertraulich sein: keine automatischen Logs,
Telemetrie, Cloud-/LLM-Aufrufe oder Speicherung im Repository. Secrets werden
auch im Debug nicht aktiv ausgegeben; ausschließlich lokale Verarbeitung.

## Synthetisches Beispiel mit prüfbaren CTE-Stufen

**Nur dokumentarisch; nicht ausgeführt und kein implementierter Generator.**
Die Quellen und Referenzen sind vollständig synthetische VALUES-Relationen.
Beide Quellen sind im angenommenen Paket tatsächlich an `Union1` angeschlossen.
Zielfluss `TargetHigh` nutzt den High-Ausgang. Für den Lookup ist ausdrücklich
die fachliche Auswahl `Priority DESC, ReferenceId ASC` vorgegeben; dies ist
keine aus SSIS erfundene Reihenfolge. Der Cache enthält beide Schlüsselfelder.

```sql
-- Vorbereitung einmal pro Debug-Lauf. Vorhandene Tabelle niemals übernehmen.
IF OBJECT_ID(N'tempdb..#tbx_SsisDebug_Example_Lookup', N'U') IS NOT NULL
    THROW 50000, N'Debug-Tempname bereits belegt; neuen Laufnamen verwenden.', 1;

CREATE TABLE #tbx_SsisDebug_Example_Lookup
(
    RegionId       int          NOT NULL,
    CustomerKey    int          NOT NULL,
    CustomerLabel  nvarchar(40) COLLATE Latin1_General_100_BIN2 NULL,
    LookupHit      bit          NOT NULL
);

;WITH lookup_raw AS
(
    SELECT v.RegionId, v.CustomerKey, v.CustomerLabel,
           v.Priority, v.ReferenceId
    FROM (VALUES
        (1, 10, CAST(N'Contoso A' AS nvarchar(40)), 2, 101),
        (1, 10, CAST(N'Contoso B' AS nvarchar(40)), 1, 102),
        (1, 20, CAST(NULL AS nvarchar(40)),        1, 103),
        (2, 10, CAST(N'Fabrikam' AS nvarchar(40)), 1, 104)
    ) AS v(RegionId, CustomerKey, CustomerLabel, Priority, ReferenceId)
),
lookup_ranked AS
(
    SELECT RegionId, CustomerKey, CustomerLabel,
           ROW_NUMBER() OVER
           (
               PARTITION BY RegionId, CustomerKey
               ORDER BY Priority DESC, ReferenceId ASC
           ) AS RowNumber
    FROM lookup_raw
)
INSERT INTO #tbx_SsisDebug_Example_Lookup
    (RegionId, CustomerKey, CustomerLabel, LookupHit)
SELECT RegionId, CustomerKey, CustomerLabel, CAST(1 AS bit)
FROM lookup_ranked
WHERE RowNumber = 1;

-- Ein zusammenhängender Zielfluss; CTE-Namen sind zugleich Prüfpunkte.
;WITH main_source1 AS                          -- Source1
(
    SELECT v.SaleId, v.RegionId, v.CustomerKey, v.Quantity,
           CAST(v.UnitPrice AS decimal(12,2)) AS UnitPrice
    FROM (VALUES (1,1,10,2,75.00), (2,1,20,1,20.00))
         AS v(SaleId,RegionId,CustomerKey,Quantity,UnitPrice)
),
main_source2 AS                                -- Source2
(
    SELECT v.SaleId, v.RegionId, v.CustomerKey, v.Quantity,
           CAST(v.UnitPrice AS decimal(12,2)) AS UnitPrice
    FROM (VALUES (3,1,10,1,125.00), (4,1,99,1,10.00), (5,1,20,1,-5.00))
         AS v(SaleId,RegionId,CustomerKey,Quantity,UnitPrice)
),
mains AS                                       -- Union1: echte Path-Zusammenführung
(
    SELECT SaleId,RegionId,CustomerKey,Quantity,UnitPrice FROM main_source1
    UNION ALL
    SELECT SaleId,RegionId,CustomerKey,Quantity,UnitPrice FROM main_source2
),
calculated AS                                  -- Derived1: neuer Spaltenstand
(
    SELECT SaleId,RegionId,CustomerKey,Quantity,UnitPrice,
           CAST(Quantity * UnitPrice AS decimal(18,2)) AS NetAmount
    FROM mains
),
lookup1 AS                                     -- Lookup1: einmal ausgewählter Stand
(
    SELECT RegionId,CustomerKey,CustomerLabel,LookupHit
    FROM #tbx_SsisDebug_Example_Lookup AS cachedLookup WITH (NOLOCK)
),
main_lookup1 AS                                -- Lookup1: Ignore-/Weiterlaufpfad
(
    SELECT m.SaleId,m.RegionId,m.CustomerKey,m.Quantity,m.UnitPrice,m.NetAmount,
           l.CustomerLabel,l.LookupHit
    FROM calculated AS m
    LEFT JOIN lookup1 AS l
        ON l.RegionId = m.RegionId AND l.CustomerKey = m.CustomerKey
),
routed AS                                      -- Split1: erster wahrer Ausgang
(
    SELECT SaleId,RegionId,CustomerKey,NetAmount,CustomerLabel,LookupHit,
           CASE
               WHEN LookupHit IS NULL THEN N'Missing' -- Priorität 1
               WHEN NetAmount >= 100   THEN N'High'    -- Priorität 2
               WHEN NetAmount >= 0     THEN N'Standard'-- Priorität 3
               ELSE N'Rejected'                        -- Defaultausgang
           END AS BranchId
    FROM main_lookup1
),
split_high AS                                  -- Split1.High → TargetHigh
(
    SELECT SaleId,CustomerLabel,NetAmount
    FROM routed
    WHERE BranchId = N'High'
)
SELECT SaleId        AS TargetSaleId,           -- TargetHigh.Mapping[1]
       CustomerLabel AS TargetCustomerLabel,    -- TargetHigh.Mapping[2]
       NetAmount     AS TargetNetAmount         -- TargetHigh.Mapping[3]
FROM split_high;

-- Cleanup separat erst nach allen gewünschten Prüfungen ausführen:
-- DROP TABLE #tbx_SsisDebug_Example_Lookup;
```

Die Beispieltabelle bleibt absichtlich bis zum separat markierten Cleanup oder
Sitzungsende bestehen. Ein generierter Lauf verwendet einen kollisionsgeprüften
eigenen Namen. Es gibt keine globale Temp-Tabelle und kein persistentes Ziel.

Zum Prüfen die letzte SELECT-Anweisung durch beispielsweise
`SELECT * FROM main_lookup1;` oder `SELECT * FROM routed;` ersetzen und die
dazugehörige WITH-Kette erneut ausführen; Vorbereitung und Cleanup dabei nicht
erneut markieren. Für einen eigenständig ausgegebenen Source-/Calculation-Slice
entfernt der Generator nicht benötigte Nachfolger. Der reine Cacheprüfpunkt
`SELECT * FROM #tbx_SsisDebug_Example_Lookup WITH (NOLOCK);` ist nach der Vorbereitung direkt
ausführbar. In diesem Auftrag wurde keiner dieser Blöcke ausgeführt.

Aus den synthetischen Werten rechnerisch erwartete Branches, **keine Runtime-
Evidence**: SaleId 1 und 3 → High (150.00/125.00), 2 → Standard (20.00),
4 → Missing, 5 → Rejected. 1 und 3 erfüllen auch die dritte Bedingung, bleiben
wegen der Priorität ausschließlich High. Die NULL-Beschriftung für Schlüssel
(1,20) ist ein Treffer; der Marker verhindert Verwechslung mit No-Match.
Für andere verbundene Zielports entsteht je eine eigene Projektion über deren
Branch; keine willkürliche Zusammenfassung der Ziele.

| Zielspalte | Wertherkunft | Zeilen-/Pfadabhängigkeit |
|---|---|---|
| TargetSaleId | Source1/Source2.SaleId → Union1 → TargetHigh.Mapping[1] | Tatsächlicher Unionpfad und Split1.High |
| TargetCustomerLabel | Lookup1.CustomerLabel nach Auswahl für (RegionId,CustomerKey) | LEFT JOIN; Trefferwahl; Splitpriorität |
| TargetNetAmount | Derived1: Quantity × UnitPrice → decimal(18,2) | Beide Sources; High vor Standard; kein persistenter INSERT |

## Öffentliche Schnittstelle – ausdrücklich nur Entwurf

Vorgeschlagene Modulbezeichnung: `toolbelt.tsql.ssis-debug`; mögliche SQL-Fassade
`toolbelt_tsql.USP_ExplainSsisDataFlow`. Namen, konkrete Typ-/Ressourcenlimits,
Plattformumfang und Berechtigungen sind vor Implementierung einzeln zu besprechen.
Die USP analysiert/erzeugt Text; sie kapselt **nicht** den erzeugten ETL-Ablauf.

| Eingabeentwurf | Bedeutung |
|---|---|
| `@Operation varchar(32) = 'explain'` | Entwurfsoperationen `bindings-template` (bearbeitbare JSON-Vorlage erzeugen) und `explain` (mit optional zurückgegebener Vorlage analysieren); gemeinsamer Parser-/Resolverkern |
| `@PackageBytes varbinary(max) = NULL` | Eine begrenzte DTSX-Datei; Encodingprofil vor XML-Verarbeitung prüfen, keine Dateipfade/Connection Strings erforderlich |
| `@ProjectContext nvarchar(max) = NULL` | Versioniertes JSON mit explizit gelieferten Projektinformationen und optional prüfbaren Source-Dependencies; keine Credentials |
| `@Bindings nvarchar(max) = NULL` | Zurückgegebene/bearbeitete [JSON-Vorlage](#json-vorlage-aus-dem-paket-und-rückgabe-bearbeiteter-werte) mit `values`, Scope-/Typmetadaten und Paket-/Kontextbindung; fehlend von explizitem NULL unterscheiden |
| `@TargetFlow nvarchar(4000) = NULL` | Konkreter Zielport oder Inventar aller Zielflüsse; keine stillschweigende Auswahl bei Mehrdeutigkeit |
| `@InspectStage nvarchar(4000) = NULL` | Gewählter Prüfpunkt; NULL liefert Endfluss plus Stufenverzeichnis. Prüfblock enthält seinen vollständigen Vorgängergraphen |
| `@LookupPolicies nvarchar(max) = NULL` | Auswahl-/Vergleichsprofile je Lookup; kein frei ungeprüfter ORDER-BY-Text |
| `@TSqlVersion smallint = 150` | Expliziter Zieldialekt; 150/160/170 nach nachgewiesenem Profil |
| Ressourcenprofil | Harte endliche Eingabe-, Graph-, Ausdrucks-, AST-, Ausgabe- und Laufzeitbudgets; Werte und Fehlerpriorität noch zu qualifizieren, kein „unlimited“-NULL |
| Standardtail | `@ResultTable sysname = NULL, @KeepData bit = 0, @Debug tinyint = 0, @Hilfe bit = 0` |

Ein lokaler .NET-Host bekommt äquivalente Eingaben aus ausdrücklich gewählten
lokalen Dateien/Bytes und liefert dieselben Artefakte. Er startet weder SQL noch
SSIS und lädt keine Pakete zu Diensten hoch. Keine `Execute`-Option im Entwurf.

Die Fassade liefert gemäß [USP-Vertrag](../Standards/USP_CONTRACT.md) **ein**
fachliches Resultset: ein geordnetes Artefaktverzeichnis, nicht mehrere
abweichende Resultsets für SQL, Graph und Diagnosen. Entwurfsfelder:
`ArtifactKind varchar(32)`, `TargetFlowId nvarchar(4000)`,
`StageId nvarchar(4000)`, `Ordinal int`, `ComponentId nvarchar(4000)`,
`EvidenceClass varchar(24)`, `Severity varchar(16)`,
`DiagnosticCode varchar(64)`, `IsExecutable bit`, `Content nvarchar(max)`,
`DetailsJson nvarchar(max)`. Nullability, Collation und Maximallängen sind noch
festzulegen. Ordnungsfelder sind Teil der Ausgabe; Tabellen garantieren keine
Reihenfolge. Artefaktarten: BindingsTemplate, Workflow, StageIndex, PreparationSql, StageSql,
TargetSql, CleanupSql, ColumnLineage und Diagnostic. Vorbereitungsabhängigkeiten
und Interpretation sind maschinenlesbar, nicht bloß Kommentare.

`IsExecutable` gilt nur für vollständig geprüfte SQL-Artefakte mit erfüllten
deklarierten Voraussetzungen. Ein StageSql mit Temp-Abhängigkeit ist als solcher
gekennzeichnet; „einzeln ausführbar“ bedeutet vollständiger CTE-Slice **nach**
angegebener Vorbereitung. Bei unbekannten Source-Dependencies bleibt es false.
Ein partielles Ergebnis ist nützlich, enthält aber kein als vollständig
ausführbar markiertes Zielflussartefakt. Unabhängige sichere Vorgängerstufen
können separat ausgegeben werden.

Vorgeschlagene Diagnosen: unresolved_binding, unsupported_component,
ambiguous_path, invalid_lineage, arbitrary_lookup_selection,
lookup_comparison_deviation, split_null_disposition, unsafe_statement,
unresolved_dependency, resource_limit und partial_target.
`@Debug` betrifft nur Generator-Messages; fachlicher Diagnosebericht und
generiertes SQL sind reguläre Funktionsergebnisse. Hilfe validiert keine
fachlichen Inputs und verändert keine ResultTable. `@ResultTable` nutzt nur
die bereits vorhandene lokale Temp-Tabelle gemäß Standardvertrag; keine
generische INSERT-EXEC-Komposition oder persistente Ergebnisablage.

## Vorhandene Lösungen: tatsächliche Zielpassung

Primärquellen am 2026-10-16 geprüft. Anbieterbehauptungen sind keine Tests.
Kein Paket-/Projektinhalt wurde an einen Dienst übertragen; keiner der
untersuchten SSIS-Konverter installiert, importiert oder ausgeführt und kein
Fremdcode übernommen. Der bereits vorhandene gepinnte ScriptDom wurde separat
nur zur lokalen Syntaxprüfung des synthetischen Beispiels verwendet.

| Lösung / geprüfte Primärquelle | Tatsächlich belegtes Ziel | Bewertung |
|---|---|---|
| [Microsoft ScriptDOM](https://github.com/microsoft/SqlScriptDOM) | T-SQL-Parser und AST-Bibliothek | Geeigneter vorhandener Syntaxbaustein, kein DTSX-/SSIS-Translator. Pin und konkrete Hostassets prüfen. |
| [data_dp_ssis2sp](https://pypi.org/project/data_dp_ssis2sp/0.12.29/) | Konkreter Python-Konverter zu T-SQL, CTEs und INSERT je Ziel; optionale Prozedur-/Deploymentpfade | Näher am Ziel als Dokumentationswerkzeuge. Version 0.12.29 anhand PyPI-JSON und SHA256-verifiziertem Wheel **nur als Quelltext** geprüft: generator.py, transforms/lookup.py, transforms/conditional_split.py. Der untersuchte Lookup erzeugt Referenz-CTE plus JOIN ohne gefordertes ROW_NUMBER; fehlende Schlüssel können als gewarntes Pass-through fortgesetzt werden, Split-Übersetzungsfehler als falsches Prädikat. Deshalb keine unmittelbare Übernahme. Schreibgrenze, Auswahl-/NULL-Regeln und Fail-closed-Verhalten benötigen eigene Anpassung/Qualifikation. MIT laut Metadaten, Python >=3.11; keine Runtime-/Lizenzfreigabe für Aufnahme. |
| [Lakebridge / BladeBridge SSIS](https://databrickslabs.github.io/lakebridge/docs/transpile/source_systems/ssis/) | Dokumentiertes experimentelles Ziel Databricks-Notebooks, SparkSQL/Python | Erfüllt die Microsoft-T-SQL-Zielarchitektur nicht. Nicht als Toolbelt-Generator einsetzen. |
| [ApexSQL Doc](https://knowledgebase.apexsql.com/how-to-document-sql-server-integration-services-ssis-using-apexsql-doc/) | Paket-/Flowdokumentation in Dokumentformaten | Hilft beim Verständnis; die geprüfte Herstellerseite belegt keinen ausführbaren T-SQL-Debug-Translator. Ältere Seitenangaben sind keine aktuelle Versionskompatibilitätszusage. |
| [csharp-dessist](https://github.com/tspence/csharp-dessist) | DTSX in ausführbare C#-Projekte | Anderes Ergebnis und Laufzeitmodell; kein unmittelbarer T-SQL-SELECT-Generator. Aktuelle Formatreife nicht nachgewiesen. |
| [ssis-to-dbt](https://github.com/wiederMatan/ssis-to-dbt) | dbt-Modelle und Beziehungen | Zielsystem entspricht nicht diesem Auftrag; kein unmittelbar geeigneter T-SQL-Debugvertrag. |

Prüfbindung für die reine Wheel-Lektüre:
`data_dp_ssis2sp-0.12.29-py3-none-any.whl`, SHA256
`88b828871ca0e61eeec4a923feb6db99c89a4f593d6f3b162b1999f7dd698fb2`.
Dies ist ein öffentlicher Distributionhash, **kein Assembly-Trusthash eines
Labziels**. Die Untersuchung beweist konkrete Vertragslücken, keine vollständige
Code-/Securityprüfung. Neuere Releases sind neu zu bewerten. Bei späterer
Übernahme gelten die [Drittanbieterregeln](../Standards/THIRD_PARTY_AND_SOURCE_POLICY.md)
zu Lizenz, Herkunft, Security, Wartung und Exit. Die Empfehlung eigener kleiner
Adapter beruht auf den konkreten Debug-/Sicherheitsverträgen, nicht auf der
Behauptung, es gebe überhaupt keinen T-SQL-Konverter.

## Fokussierter Validierungsplan – noch nicht ausgeführt

| Prüffeld | Synthetische Fälle / entscheidendes Oracle |
|---|---|
| XML/Projektimport | Bekannte DTSX-Profile; Namespacevarianten, doppelte/dangling IDs, Encoding, verschlüsselte Teile, fehlende .conmgr/Parameter, manipulierte XML-/ZIP-Tiefe und Limits; keine Netzwerk-/Codeausführung |
| JSON-Template-Rundreise | Paket → Vorlage → nur Werte ändern → erneut binden; gleichnamige Variablen in verschiedenen Scopes, Defaults versus Runtimezuweisung, Expression-Neuberechnung, expliziter Override, NULL/fehlend/Leerstring/false/0, exakte Decimal/Int64/Datumswerte, fehlender Projektkontext, sensitive Defaults, doppelte/unbekannte Keys, veraltete Paketbindung; Typ-/Scopemetadaten nicht als Autorität akzeptieren |
| Graph/Lineage | Zwei unabhängige Data Flow Tasks bleiben getrennt; nur echter Unionport vereinigt; Multicast bleibt mehrere Outputs; umbenannte/überschriebene und gleichnamige Spalten, Port-/Zielmapping nach IDs und Ordinal |
| Lookup-Duplikate | Ein-/mehrspaltige Schlüssel; Joinnormalisierung = Partitionnormalisierung; 0/1/viele Referenzen; pro Input maximal ein Lookup-Treffer; nullable Payload; keine verlorenen echten Matches |
| Lookup-Auswahl/Cache | Fachliche Ordnung mit und ohne Ties; beliebiger Default erzeugt Warnung; keine behauptete konkrete beliebige Zeile; einmal gewählte Cachezeile über mehrere Slices/Branches gleich; unterschiedliche Bindings/Collations teilen nicht irrtümlich |
| Split | Überlappende Bedingungen, erste gewinnt; Default; NULL-/Fehler-Disposition, unbekannte Priorität; jede Zeile höchstens einmal im normalen Split; Fail-Komponente wird nicht stillschweigend Filter |
| Expressions/Typen | Ursprungswert bei Derived-Overwrite, mehrere Formeln derselben Komponente, Folgekomponente liest neue Version; Dezimal-/Integergrenzen, NULL, Stringcodepages, Culture/Datum, Konvertierungs-/Abschneidefehler |
| Join/Aggregate/Sort | Allgemeiner Join behält n:m, Lookup begrenzt; Gruppierungs-/NULL-Counts; Deduplikation nur wirklicher Sortschlüssel, erhaltene Payload, explizite Reihenfolgen-/Vergleichsabweichung |
| Zielprojektion | Exakte Anzahl/Ordnung/Alias/Typ/Nullability, keine Hilfsspalten; Identity/Default nicht erfunden; nicht gemappte Spalten sichtbar |
| Einzelne Debug-Stufen | Für jede Stufe vollständige transitive CTE-Abhängigkeiten und Temp-Voraussetzungen; direkt ausführbarer Block nach Vorbereitung; keine unbekannten Nachfolger; Cache bleibt über Prüf-SELECTs identisch; Cleanup getrennt |
| Bindings an Prüf-Stufen | Bearbeitbare Werte stehen als typisierte DECLAREs am Anfang; Deklarationen und CTE-Kette ohne GO gemeinsam ausführbar. Direkte Initialwertänderung ohne JSON-/Generatoraufruf wirkt an jedem gewählten Prüfpunkt; geänderte JSON- oder DECLARE-Werte invalidieren abhängige Lookup-/Stufencaches, unveränderte Lookup-Eingaben behalten denselben Referenzstand; kein gemischter Szenariostand. |
| Schreibgrenze positiv | Reines SELECT sowie ausschließlich eigene CREATE/INSERT/SELECT/DROP-Tempformen; jedes finale Artefakt inklusive Preview und Cache geprüft |
| Schreibgrenze negativ | Mehrere Batches; SELECT INTO persistent; DML über CTE/Alias, EXEC in Source, INSERT EXEC, dynamisches SQL, NEXT VALUE FOR, DBCC, DDL/GRANT, SQLCMD-Include, OPENQUERY/OPENROWSET, unbekannte UDF/CLR/View/Synonyme, globale/fremde Tempziele; keine ausführbare Ausgabe |
| Parser-Evasion | Kommentare/Literale mit Schlüsselwörtern sind keine Befehle; quoted Identifier, geschachtelte Abfragen und ungültige/neue AST-Knoten; Limitüberschreitung vor teurer Arbeit, kein ungeprüfter Fallback |
| Katalog-/Rechtegrenzen | Fehlende Sicht/Dependencydrift verhindert safety_pass; eingeschränkte vorhandene Rechte, keine Rechtevergabe; keine package-induced Verbindung/SQL-Ausführung beim Analysieren |
| Toolbelt/API/Lifecycle | Help-only, ein Resultset, ResultTable/KeepData/Debug; Clean/Repeat/echte Upgrades/Consumer/Kollision/Uninstall, local/central; CLR-Trust getrennt und explizit |

Zunächst reine Offline-Tests für Parser, Graph, Typen, Generator und
AST-Allowlist. Danach freigegebene synthetische SQL-Proben auf schema-validen,
explizit gewählten Labzielen; Testaufbau und sein eigener persistenter
Fixturebereich bleiben vom zu prüfenden schreibfreien Debug-Skript getrennt.
Persistente Testobjekte vor/nach Ausführung vergleichen; externe Seiteneffekte
durch Negativprüfungen und verbotene Bindungen ausschließen, nicht nur durch
einen Katalogsnapshot. Laufzeitvergleich mit SSIS nur später in gesondert
freigegebener, isolierter synthetischer Umgebung und für exakt erklärte Profile.
Keine realen Pakete/Daten oder Runtimeausgaben als Repository-Evidence.

Die Prüfmatrix bewertet SQL Server 2019/2022/2025 und Windows/Linux je tatsächlich
unterschiedlichem Engine-/Providerpfad, außerdem local/central bei SQL-Fassade.
Kein unnötiger Vollmatrixlauf für jede Dokumentkorrektur. Die CLR-/Linuxgrenze
bleibt sichtbar. Runtime, echte SSIS-Differentialfälle, Minimalrechte, Ressourcen-
und Plattformqualifikation sind hier sämtlich **`not executed`**.

## Kleine Umsetzungsschritte und getrennte spätere Funktionen

Jeder Schritt setzt die vorherige konkrete Funktionsbesprechung und
anschließende ausdrückliche Implementierungsfreigabe voraus. Diese Reihenfolge
ist keine Freigabe und ändert keine bestehende Entwicklungspriorisierung.

1. Eingabe-/Ausgabe-, Debug-Stufen-, Sicherheits- und Grenzvertrag besprechen;
   zunächst bekannte SQL-Source, echter Union All, numerische Berechnung,
   LookupOne, totaler Split und Destination-Mapping als kleinen Slice wählen.
2. Offline-Import und sichtbaren Workflow/Lineage erstellen; unknown/missing
   vollständig melden, bevor SQL-Generation behauptet wird.
3. Reines C#-IR und SSIS-Ausdrucksteilmenge qualifizieren; gemeinsame CTE-Kette,
   Endprojektion und eigenständige Prüf-Slices generieren. Keine Ausführung.
4. Offline-AST-Allowlist inklusive Source-/Dependencygrenze und negativer
   Bypassfälle; Cache-/Ownershipvertrag; **ohne bestandenen Safety-Gate keine
   ausführbare Markierung**, auch wenn das SQL syntaktisch korrekt ist.
5. Synthetische SQL- und ausgewählte SSIS-Profilvergleiche erst nach eigener
   Testfreigabe; danach über optionale CLR-Fassade und deren Lifecycle entscheiden.
6. Weitere Komponenten/Ausdrücke einzeln erweitern; keine 100-%-Äquivalenzzusage.

Die [Toolbelt-Vormerkungen](../../Backlog/TOOLBELT_CANDIDATES.md#ssis-dtsx-debug-select--vormerkung-ohne-finale-tc-referenz)
trennen die Debugfunktion und zwei spätere Erweiterungen:

| Spätere Funktion | Voraussetzungen, offene Entscheidungen und Nachweise |
|---|---|
| Parametrisierte USP-Kapselung | Einen geeigneten **bereits geprüften** Ablauf als Stored Procedure erzeugen, ein Aufruf, explizite Parametertypen/-defaults und Ziel-/Stufenauswahl. Entscheidung über Definitionserzeugung versus gesonderte Installation, Resultsetvertrag, Temp-Scope, Rechte, Lifecycle und Revalidierung. Debug-Lesegrenze zunächst erhalten. CREATE PROCEDURE ist persistent und gehört ausdrücklich nicht in das Debug-Skript. |
| SSIS-gleiche USP im definierten Umfang | Eigener schreibender ETL-Vertrag für Quellen/Ziele, Transaktionen, Fehler-/NULL-/Typ-/Vergleichsregeln, Duplikate, Identitäten/Defaults/Trigger, Wiederholung, Parallelität und gegebenenfalls weiteren Runtimeumfang. Eigene Schreib-/Ausführungsfreigabe, Rechte und Rollback-/Idempotenznachweise; Differentialtests gegen SSIS für exakt versionierte Profile. Nur belegte Teilgleichwertigkeit behaupten; keine allgemeine SSIS-Ersetzung. |

Für diese Vormerkungen wird keine nächste TC-/AP-Sequenznummer geraten.
[DEC-2026-028](../Architecture/DECISIONS.md#dec-2026-028-foundation-14-und-bestandsschutz-für-projektidentitäten)
erhält bestehende Referenzen und verlangt sichere Vergabe; eine entsprechende
Registration Authority ist in den geprüften Projektquellen nicht ausgewiesen.
Die benannten Vormerkungen bleiben auffindbar, ohne neue Referenzfamilie,
Allocator oder Implementierungsfreigabe einzuführen.

## Prüfstand dieses Analyseauftrags

Am 2026-10-16 tatsächlich erfolgt: lokale Quellen-/Manifest-/Vertragslektüre,
gezielte Duplikatsuche, aktuelle Primärquellenrecherche sowie reine
Quelltextinspektion des oben gebundenen öffentlichen Wheels ohne Installation
oder Ausführung. Das belegt Quellenbefunde und Entwurfsbegründungen, keine
Implementierung oder Laufzeitgleichheit. Der synthetische SQL-Block wurde aus
dem beschriebenen Modell entworfen, nicht aus einem realen Paket extrahiert.

Die abgeschlossenen lokalen Prüfungen vom 2026-10-16:

| Befehl / Methode | Scope und Ergebnis | Grenze |
|---|---|---|
| `python -B -` mit dem vorhandenen `Tests/Documentation/validate_documentation.py`, Working-tree-Pfadliste aus `git diff --name-only HEAD` plus `git ls-files --others --exclude-standard` an dessen Change-Impact-Einstieg | Vier geänderte Dokumente; vorhandene Schutz-, Status-, Manifest- und ausgewählte Konsistenz-/Linkprüfungen erfolgreich | Arbeitsbaumprüfung; kein Commit-/Head-CI-Nachweis. Der Validator selbst wurde nicht geändert. |
| PowerShell: exakten SHA512-Pin des vorhandenen ScriptDom prüfen, `Add-Type -Path` auf dessen DLL, zweiten SQL-Fence dieser Datei mit `TSql150Parser(true).Parse` parsen | Vollständiges synthetisches Beispiel: null Syntaxfehler im SQL150-Dialekt; AST enthält IF, CREATE TABLE, INSERT und SELECT | Ausschließlich Offline-Syntax, keine Bindungs-, Safety-, SQL-Runtime- oder SSIS-Parität; noch kein implementierter Sicherheitsprüfer. |
| Ergänzung JSON-Rundreise: `python -B -`, JSON-Fence mit `json.loads` lesen und eindeutige Beispielschlüssel in `values`/`availableInputs` abgleichen | Synthetischer JSON-Ausschnitt gültig, Beispielschlüssel stimmen überein; Dokumentations-Impactprüfung nach der Entwurfsergänzung erneut erfolgreich | Kein implementierter Template-/Resolverkern und kein End-to-End-Rundreisenachweis; geplante Contract-Fälle bleiben `not executed`. |
| Benutzerbestätigung DECLARE: den neuen `tsql`-Fence mit dem exakt gepinnten ScriptDom/TSql150Parser offline parsen; vorhandenen Dokumentationsvalidator mit den zwei betroffenen Working-tree-Pfaden ausführen | Neues synthetisches DECLARE-/CTE-Minimalbeispiel ohne Syntaxfehler; Dokumentations-Impactprüfung erfolgreich | Keine SQL-Ausführung oder implementierte Cacheinvalidierung; unverändertes größeres SQL-Beispiel nicht erneut geprüft. |
| Lokaler Python-Abgleich von Markdown-Fragmentlinks gegen Überschriften der referenzierten Dateien | Lokale Heading-Anker der vier Dokumente erfolgreich geprüft | Kein Verfügbarkeitsversprechen für externe URLs. |
| `git diff --check` und Durchsicht der vier geänderten Dokumente | Whitespace-/Diff- und Datenschutzprüfung ohne Befund; nur neue Research-/Planungsinhalte | Eigenprüfung, keine unabhängige Runtimequalifikation. |
| Konkretisierung V1: vorhandener Dokumentationsvalidator mit fünf betroffenen Arbeitsbaumdateien; JSON-/Link-/UTF-8-/Whitespaceprüfung | Vertrag und verlinkte Research-/Backlog-Inhalte konsistent; 44 vorhandene Modulmanifeste im inkrementellen Prüfpfad | Nur Dokumentation; keine implementierte API oder unabhängige Sicherheitsprüfung. |
| Ergänzung NOLOCK: vollständiges synthetisches Beispiel erneut mit exakt gepinntem ScriptDom für SQL150 parsen, aktuellen Quellen-Vorfilter offline auf denselben Text anwenden | Syntax gültig; Vorfilter lehnt bei Atom 513 mit `TBX_TSQLPARSE_PREPARSE_COMPLEXITY_LIMIT` ab | Negativer Machbarkeitsbefund für die bisherige öffentliche API, kein Releasebinary-/Runtime-PASS. Der V1-Vertrag schlägt deshalb einen getrennten begrenzten Einstieg mit gemeinsamem Vorfilter und neu zu qualifizierenden Provider-/Consumerpatches vor. |

Der dokumentierte Validatoraufruf wurde im Prozess mit der vollständigen
Working-tree-Liste anstelle der standardmäßigen Commit-Differenz gespeist;
`main()` und die Prüforakel blieben unverändert. Dies schließt das neue,
noch nicht versionierte Research-Dokument ein. Ein bloßer Vergleich HEAD→HEAD
ohne diese Liste wäre kein Nachweis für die Änderung.

Der Umfang umfasst die Machbarkeitsanalyse, den auf Benutzerauftrag konkretisierten
V1-Vertrag und verlinkte Backlog-Vormerkungen; ein Bearbeiter, keine weitere
Entwicklungswelle. Keine Lab-, Paket-, ETL- oder Debug-SQL-Ausführung; keine
Trust-, Infrastruktur- oder Produktcodeänderung.
