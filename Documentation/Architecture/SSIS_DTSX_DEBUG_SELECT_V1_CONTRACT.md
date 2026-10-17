# SSIS-/DTSX-Debug-SELECT – V1-Vertrag zur Freigabe

Stand: 2026-10-17 · Autor: Codex · Vertragsfassung: 1.0.
Status: **am 2026-10-16 ausdrücklich zur Implementierung freigegeben;
implementiert; native Nachweise und verbleibende Gates siehe
[Modulprüfmatrix](../../Modules/toolbelt.tsql.ssis-debug/Tests/README.md)**.

Benutzerfreigabe nach Vertragsbesprechung: „Ja, ich gebe den V1-Vertrag
einschließlich UNSAFE-Assembly und der begrenzten Parser-/Dependency-Anpassungen
frei. Setze ihn mit den vereinbarten Tests um.“ Die in Abschnitt 13 verlangten
unabhängigen Sicherheits- und Offlinegates bleiben vor dem Laden des neuen
SQL-Einstiegs verbindlich. Keine Merge-/Releasefreigabe.

Dieser konkrete Vorschlag führt die [Machbarkeitsanalyse](../Research/SSIS_DTSX_DEBUG_SELECT_FEASIBILITY.md)
und die anschließend besprochenen Entscheidungen zusammen. Für V1 ersetzt er
deren vorläufige Schnittstellen-, Provider- und Umfangsvorschläge. Er ändert
keine übergeordneten Toolbelt-Verträge und erteilt sich keine Freigabe selbst.
Keine neue TC-/AP-/DEC-Sequenz wird geraten (`DEC-2026-028`).

Der geplante Arbeitsablauf in SSMS:

1. DTSX als Binärparameter bereitstellen und mit `@Operation = 'bindings-template'`
   die vollständige JSON-Vorlage anfordern. Die USP selbst liest keine Datei.
2. Nur die Werte der Vorlage bearbeiten und sie mit `@Operation = 'explain'`
   als `@Bindings` zurückgeben; erlaubte Debugdatenbanken explizit zuordnen.
3. Zielfluss und Stufe aus dem Ergebnis wählen. Das ausgegebene T-SQL in SSMS
   öffnen, die anfänglichen DECLARE-Werte ändern und den vollständigen Prüfblock
   oder die WITH-Kette mit einem SELECT auf die gewünschte CTE ausführen.

## 1. Bestätigte Anforderungen und Freigabegrenze

Am 2026-10-16 hat der Benutzer folgende Entscheidungen für die Ausarbeitung
bestätigt: direkter Aufruf aus T-SQL/SSMS, vorgeschlagener erster
Komponentenumfang, Pakete aus Visual Studio 2012 bis 2026, pragmatische
SQL-Server-Vergleichssemantik und rein lesende Katalogprüfung. Zuvor bestätigt:
JSON-Vorlage aus DTSX erzeugen, Werte zurückgeben, bearbeitbare typisierte
DECLAREs am Skriptanfang und einzeln ausführbare CTE-Prüfstufen.

Zusatz desselben Tages: **`WITH (NOLOCK)` an allen lesenden Objektreferenzen,
an denen SQL Server diesen Hint unterstützt.** Dies gilt auch für Lookup- und
Katalogabfragen; die Konsequenzen sind Bestandteil dieses Vertrags.

Eine spätere ausdrückliche Freigabe dieses Vertrags autorisiert die Entwicklung
genau dieser Debugfunktion samt gekoppelten Modul-/Build-/Lifecycle-/Testartefakten
und der in Abschnitt 2 begrenzten Parser-/Consumer-Anpassung.
Nicht enthalten: schreibende ETL-Zielverarbeitung, erzeugte Ablauf-USPs,
SSIS-Runtime-Nachbau, ISPAC-Import, externe Dienste, neue Infrastruktur,
Produktionsausführung oder pauschale Rechte-/Truständerungen. Native Tests
verwenden nur gesondert ausdrücklich gewählte schema-valide Labziele nach
`AGENTS.md`; Lab-Infrastruktur bleibt außerhalb des Moduls.

## 2. Modul, Technik und Plattformen

| Gegenstand | V1-Vorschlag |
|---|---|
| Modul / geplantes erstes Release | `toolbelt.tsql.ssis-debug` / `1.0.0`, zunächst `unreleased` |
| Neue öffentliche Schnittstelle | Genau `toolbelt_tsql.USP_ExplainSsisDataFlow`; eine USP mit zwei Operationen |
| Interne Ausführung | Dünne T-SQL-Fassade für Help/Standardvertrag; interne CLR-USP mit demselben fachlichen Kern und dokumentiertem USP-Vertrag; keine öffentliche SVF/TVF |
| Neue Assembly | SQL-Name `Toolbelt_Tsql_SsisDebug`, Datei `Toolbelt.Tsql.SsisDebug.dll`, .NET Framework 4.8, ausdrücklich vorgeschlagenes `UNSAFE` wegen direkter ScriptDom-Abhängigkeit; Windows-only |
| SSIS-Kern | Begrenztes XML-Lesen, eigener typisierter SSIS-Ausdrucksparser, Komponenten-/Port-/Spaltenmodell, relationaler Generator; keine ManagedDTS-/SSIS-SDK-Abhängigkeit |
| SQL-Parser | Direkte typisierte AST-Verarbeitung mit dem bereits durch `toolbelt.tsql.script-parser` bereitgestellten ScriptDom-Binary; Paket 180.117.0 / Datei 18.0.117.0 und exakt dessen kanonischer SHA2-512-Pin. Kein zweiter Binary-Deploy und keine neue ScriptDom-Version |
| Parseranbindung | Ein eigener begrenzter Einstieg ausschließlich im neuen Debugkern, mit Vorfilter vor jedem ScriptDom-Lexer-/Parseraufruf und rekursiver AST-Allowlist. Kein SQL-Ausführen, keine Umgehung über Teilprüfungen des finalen Batches und kein dauerhafter AST-Cache |
| Gekoppelter Parserpatch | Vorgeschlagen `toolbelt.tsql.script-parser` 2.0.1: kanonischen Vorfilter als gemeinsam eingebundene Quelle parametrisierbar machen; die vier vorhandenen TVFs behalten exakt ihr bisheriges Grenz-/Fehler-/Resultatprofil. Dependency im neuen Modul exakt auf den tatsächlich qualifizierten 2.0.1-Release binden |
| Bestehender Parserconsumer | `toolbelt.metadata.table-clone` benötigt wegen seiner exakten Parserversions-/Binarybindung einen gekoppelten Patch, vorgeschlagen 4.1.1: nur Dependency-/Pin-/Qualifikationsanpassung, keine neue Fachfunktion oder Ausweitung des Trigger-Opt-ins |
| JSON | Native ISJSON/OPENJSON über festen lokalen Adapter, Größen-/Tiefenprüfung und Duplicate-Key-Prüfung; kein neues JSON-Paket |
| ResultTable | `toolbelt.core.result-table` mindestens 1.0.0, gleiche Installationsdatenbank; kanonischer Helper, keine Kopie |
| Generatorhost | SQL Server 2019, 2022, 2025 auf Windows; lokaler und zentraler Deploy-Modus |
| Generierter Dialekt | 150 als Default; 160 und 170 explizit wählbar. Keine automatische Verwendung neuer Enginefunktionen |
| Linux | Generator wegen direkter `UNSAFE`-Abhängigkeit nicht unterstützt. Das erzeugte SQL verwendet portable Enginekonstrukte; Linux-Ausführung ist erst nach gesonderter Qualifikation belegt |

**Grund der gekoppelten Änderung:** Die reine Offline-Syntaxprüfung des
synthetischen Forschungsbeispiels mit NOLOCK war erfolgreich. Der aktuelle
Vorfilter aus `PreparseGuard.cs` wies denselben Text bei Atom 513 mit
`TBX_TSQLPARSE_PREPARSE_COMPLEXITY_LIMIT` ab. Bereits dieses Beispiel passt
also nicht durch die öffentliche 512-Atome-API. Das ist ein lokaler Quellenbefund,
kein SQL-Runtime- oder Releasebinary-Nachweis. Den bestehenden Schutz pauschal
anzuheben oder den fertigen Batch ungeprüft auszugeben ist keine V1-Lösung.

Der gemeinsame Scanner wird einmal kanonisch gepflegt und als gemeinsame
Buildquelle eingebunden, nicht für SSIS kopiert. Der bisherige Parserwrapper
verwendet weiterhin sein unverändertes Profil; nur der neue interne Einstieg
nutzt das in Abschnitt 11 begrenzte und separat zu qualifizierende Profil.
Die Ausgliederung verändert den Providerbuild: neue reproduzierbare Hashpins,
echte Upgrade-/Consumerregression und unabhängige Prüfung sind erforderlich.
Kein alter Nachweis qualifiziert automatisch das neue Binary.

Der Parser-Lifecycle muss den zusätzlichen direkten ScriptDom-Consumer eng
gebunden an dessen eigene Marker und exakte Releaseidentität erkennen.
Unbekannte Consumer bleiben gesperrt; Parser-/ScriptDom-Uninstall bleibt bei
installiertem SSIS-Modul blockiert. Ein späterer ScriptDom-Wechsel benötigt
erneute gemeinsame Qualifikation. Keine allgemeine Lockerung des Fremdschutzes.

Die neue CLR-Assembly benutzt nur die Context Connection für feste
Toolbelt-/JSON-/Katalogabfragen, keine eigene Netzwerkverbindung, Dateien,
Umgebungsvariablen, Registry oder Workerthreads. Der fachliche Kern bleibt
offline testbar; keine zweite Fachimplementierung als CLI in V1.
`UNSAFE` ist hier eine ausdrückliche Providerentscheidung zur Freigabe,
keine automatische Server-/Trustfreigabe. Strict Security bleibt aktiv,
kein `TRUSTWORTHY ON`, keine Rechtevergabe oder automatische Trustregistrierung.

## 3. DTSX- und Versionsumfang

Die Visual-Studio-Spanne beantwortet die gewünschte Herkunft. Sie ist keine
eindeutige Paketformatversion: Das SSIS-Ziel und gespeicherte
Komponenten-/Formatmetadaten sind zusätzlich maßgeblich. Microsoft beschreibt
die DTSX2-Profile **2012/01** und **2014/01** samt Produktzuordnung bis SQL Server
2025. V1 nimmt beide in den geplanten Qualifikationsumfang auf.
[MS-DTSX2-Produktverhalten](https://learn.microsoft.com/en-us/openspecs/sql_data_portability/ms-dtsx2/9bdd3365-7a0e-471b-8c5a-00d2bba465cd).
Die aktuelle Microsoft-SSIS-Erweiterung nennt auch Visual Studio 2026 und
unterschiedliche TargetServerVersion-Werte.
[Microsoft Marketplace](https://marketplace.visualstudio.com/items?itemName=SSIS.MicrosoftDataToolsIntegrationServices).

- Ein XML-DTSX pro Aufruf, UTF-8 oder UTF-16 mit konsistenter Encodingdeklaration;
  kein implizites Raten anderer Codepages. Größenprüfung vor Dekodierung.
- Namespacebewusste Erkennung beider Profile; Adapter anhand tatsächlicher
  Class-ID, Komponentenmetadaten und Struktur, nicht anhand des Anzeigenamens.
- Implementierung registriert unterstützte Alias-/Versionsvarianten mit
  synthetischen Fixtures für beide Profile. Format erkannt bedeutet nicht,
  dass jede Script-/Drittanbieter- oder neuere Komponentenvariante übersetzbar ist.
- Unbekannte Profile: Bericht und Diagnose `unsupported_package_format`, kein
  ausführbares SQL. Unbekannte Komponenten: lokaler Blocker, kein Pass-through.
- Kein DTD, externer Resolver, XInclude, fremdes Schema, Binär-/Scriptladen,
  Paketupgrade oder Paket-Validate/Execute. Verschlüsselte/ausgelassene Teile
  bleiben fehlender Kontext; keine Entschlüsselungsfunktion.
- Project-Parameter und externe Connection-Definitionen optional über das unten
  definierte JSON. Keine automatische Suche nach `.dtproj`, `.conmgr`, Registry,
  SSISDB oder Umgebungen. ISPAC und alte DTS-/DTSX1-Formate außerhalb V1.

Das ist ein **Supportziel mit offenen Tests**, keine Zusage „alle mit VS 2012
bis 2026 erstellten Pakete sind vollständig konvertierbar“. Einzelne tatsächliche
Paketvarianten dürfen später als zusätzliche synthetische Regressionen ergänzt
werden, ohne reale Pakete oder vertrauliche Metadaten zu versionieren.

## 4. Öffentliche Parameter, Defaults und Aufrufverhalten

Nachstehende Reihenfolge und Typen sind Teil der vorgeschlagenen API.
Fachliche Pflichtparameter erhalten für den Help-Aufruf technische Defaults.

| Parameter | SQL-Typ / Default | Vertrag |
|---|---|---|
| `@PackageBytes` | `varbinary(max) = NULL` | Bei fachlicher Ausführung erforderlich; genau ein DTSX. Dateizugriff ist kein Bestandteil dieser USP |
| `@Operation` | `varchar(32) = 'explain'` | Exakt `bindings-template` oder `explain`; NULL/andere Werte ungültig |
| `@ProjectContext` | `nvarchar(max) = NULL` | Optionales JSON-Schema 1 für externen Projektkontext |
| `@Bindings` | `nvarchar(max) = NULL` | Bearbeitete generierte Vorlage; bei `bindings-template` muss NULL gelten |
| `@CatalogBindings` | `nvarchar(max) = NULL` | Explizite Zuordnung zu erlaubten Datenbanken derselben Instanz. Template-Modus benutzt keinen Fachkatalog und verlangt hierfür NULL |
| `@TargetFlow` | `varchar(64) = NULL` | Vom Modell ausgegebene Zielfluss-ID; NULL berücksichtigt alle Ziele getrennt |
| `@InspectStage` | `varchar(64) = NULL` | NULL: Ziel-SQL und Stufenverzeichnis; konkrete ID: vollständiger Prüfblock; `all`: alle gültigen Prüfblöcke innerhalb des Ausgabebudgets. Eine konkrete Stufe verlangt einen konkreten Zielfluss |
| `@LookupPolicies` | `nvarchar(max) = NULL` | Optionale geprüfte Auswahlreihenfolge je Lookup; keine freien SQL-Fragmente |
| `@ComparisonCollation` | `sysname = NULL` | NULL: Collation der expliziten `defaultDatabase` aus CatalogBindings; expliziter Wert muss bekannte unterstützte Collation sein. Benötigter Vergleich ohne auflösbares Profil blockiert die Stufe |
| `@TSqlVersion` | `smallint = 150` | Exakt 150, 160 oder 170; NULL/andere Werte ungültig |
| `@ResultTable` | `sysname = NULL` | Nur vorhandene lokale Temp-Tabelle nach Standardvertrag |
| `@KeepData` | `bit = 0` | Replace/Append gemäß Standardvertrag; keine Sondersemantik |
| `@Debug` | `tinyint = 0` | Nur Generator-Messages; 0 still, 1 Ablauf, 2 Entscheidungen/Zähler, 3 redigierte Detailmetadaten, 255 interner redigierter Trace; übrige Werte bis zur Definition wie Stufe 3 |
| `@Hilfe` | `bit = 0` | 1 liefert ausschließlich standardisierte Hilfe, ignoriert fachliche Inputs und ResultTable/KeepData/Debug |

Ein bekannter, aber nicht übersetzbarer Zielfluss liefert Diagnosen und bekannte
Vorgängerstufen. Eine unbekannte ausgewählte Ziel-/Stufen-ID ist ein Eingabefehler.
Ein global unbrauchbarer Input, eine Grenzüberschreitung oder beschädigte
Vorlagenbindung führt vor Ausgabe/ResultTable-Mutation zum Fehler. Kein
stillschweigender Default für falsch geschriebene IDs oder Operationen.

## 5. JSON-Verträge und typisierte Werte

Alle JSON-Dokumente sind Objekte mit `schemaVersion: 1`. Schlüsselvergleich ist
ordinal/case-sensitive. Doppelte Properties, unbekannte Felder, falsche Typen
und widersprüchliche Deklarationen sind Fehler. NULL des SQL-Parameters ist
kein leeres JSON-Objekt und kein expliziter Variablen-NULL-Wert.

| Dokument | Erlaubte Struktur |
|---|---|
| ProjectContext | `schemaVersion`; optional `projectParameters` als Array aus `name` (String), `ssisType` (String), optional `designValue`, `required`/`sensitive` (Boolean, Default false); optional `connectionManagers` als Array aus `refId`, `name`, `provider` (`sqlserver-oledb`/`sqlserver-adonet`). Keine Credentials/Connection Strings/Endpoints. Doppelte Namen/IDs im selben Scope sind Fehler |
| CatalogBindings | `schemaVersion`, `defaultDatabase` (String), `databases` (eindeutiges Array von Datenbanknamen), `connections` (Objekt: importierte Connection-ID → Datenbankname). Default und alle Mappingziele müssen in `databases` liegen. Kein Server-/Login-/ConnectionString-Feld |
| LookupPolicies | `schemaVersion`, `lookups` (Objekt: Modell-Lookup-ID → Objekt mit `orderBy`-Array aus `{ "column": "<gebundene Referenzspalten-ID>", "direction": "asc" oder "desc" }`). Kein Text-ORDER-BY. NULL oder fehlender Lookup: unten definierter beliebiger Default |
| Bindings | `schemaVersion`, `profile` exakt `ssis-debug-v1`, `packageSha256` und `contextSha256` (je 64 Hexzeichen), `values` (Objekt), `availableInputs` (Array). Andere Profile/Schema-Versionen sind Fehler |

Die generierte Vorlage enthält alle erkannten Variablen-/Parameterdeklarationen
und referenzierten System-/fehlenden Kontexteinträge. Ihre innerhalb dieser
Paketbindung eindeutigen Schlüssel, etwa `v0001`, sind **modellinterne**, keine
neuen dauerhaften Projektreferenzen. Variable plus Namespace plus Scope bleibt
eindeutig; gleicher Anzeigename in zwei Containern ergibt zwei Schlüssel.

Jeder availableInputs-Eintrag enthält `key`, `kind` (variable/package-parameter/
project-parameter/system/context), `scope`, `name`, `ssisType`, `sqlType` (String
oder NULL), `defaultAvailable` (Boolean), `defaultValue`, `expression` (String
oder NULL), `valueOrigin`, `requiredForSelectedFlow`, `sensitive` und `state`
(literal/derived/needs-value/unsupported/redacted). Alle beschriebenen Felder
werden ausgegeben; NULL ist bei nicht anwendbaren Metadaten ausdrücklich möglich.
Paket/Projektkontext bleibt die Autorität. Fehlende Pflichtfelder oder geänderte
Identitäts-/Typmetadaten (key/kind/scope/name/ssisType/sqlType) werden abgewiesen.
Abgeleitete Informationsfelder wie requiredForSelectedFlow und state werden für
die aktuelle Auswahl neu bestimmt und niemals als Eingabewahrheit verwendet.
Die Ziel-/Stufenauswahl kann deshalb mit derselben Paketvorlage geändert werden.
Der Benutzer bearbeitet `values`.

Beispiel nur des bearbeitbaren Bereichs einer synthetischen Vorlage:

```json
{
  "values": {
    "v0001": "2026-01-01T00:00:00.0000000",
    "v0002": "100.00",
    "v0003": true
  }
}
```

Dieser Ausschnitt ist nicht das vollständige Bindings-Dokument. Die vollständige
Vorlage liefert die Funktion, einschließlich Typ-/Scopebeschreibung und Hashes.
`packageSha256` bindet Originalbytes; `contextSha256` bindet kanonisch sortierten,
typisierten Projektkontext und Importprofil. Layout-/Keyreihenfolge im JSON ist
unerheblich. Ein anderes Paket oder Kontext verlangt eine neue Vorlage; keine
stille Migration anhand gleicher Namen. Nicht benötigte verfügbare Eingaben
dürfen unverändert enthalten bleiben; `values` darf nur bekannte bindbare Keys
enthalten. Sensitive Eingaben erhalten keine exportierten Defaults/Expressions
mit Secrets und keine Secretwerte im generierten SQL.

Wertpriorität: explizites `values[key]` vor explizit geliefertem Kontext vor
belegtem Designliteral/unterstütztem Ausdruck. Fehlender Key verwendet diesen
Fallback. JSON-null ist für einen unterstützten skalaren SQL-Debugwert ein
expliziter NULL-Wert; lässt dessen SSIS-Ursprung NULL nicht zu, ist dieser
Override als pragmatisches Debug-Szenario gekennzeichnet. Er ersetzt keinen
fehlenden Typ oder unbekannten Runtimewert. Leerstring, false und 0 bleiben
eigene Werte.
Statische ungeschützte Literale ohne relevante bekannte spätere Zuweisung
werden vorbelegt. Derived-/Runtimewerte werden nicht aus einem alten cached
value erfunden. System-/Read-only-Overrides und Overrides berechneter Werte
sind ausdrücklich als `pragmatic` markierte Debug-Szenarien, keine Paketänderung.
Unbekannte Script-/Loop-Zuweisungen bleiben fehlender Kontext am Prüfpunkt.

### Skalare Typen und Ausdrucksteilmenge

| Typfamilie | SQL / Wertdarstellung |
|---|---|
| Boolean; signierte/unsignierte Integer bis 64 Bit | bit; kleinster exakt ausreichender SQL-Integer, UInt64 decimal(20,0); exakte Bereichsprüfung. Vorlage verwendet für Integer Dezimalstrings; JSON-Zahlen nur ganzzahlig und im Bereich ±9.007.199.254.740.991 zulässig, nie über double parsen |
| Decimal/DT_NUMERIC; Currency | decimal(p,s), 1 ≤ p ≤ 38, 0 ≤ s ≤ p; skalare Decimal-Variablen ohne p/s im begrenzten Profil decimal(38,18), außerhalb dessen expliziter Bindingfehler; Currency decimal(19,4); JSON-Dezimalstring, keine stillschweigende Rundung beim Binding |
| Single/Double | real/float(53); finite Werte, kein NaN/Infinity; approximative Arithmetik sichtbar |
| Unicode-/ANSI-Text | nvarchar/varchar mit tatsächlicher Länge beziehungsweise max bei unbeschränkter skalarer Variable; Codepage/Collation belegen, keine stille verlustbehaftete Konvertierung |
| Date/Time/Timestamp | date/time(s)/datetime2(s) gemäß präzisem Pakettyp, s bis 7; DateTime-Variable datetime2(7); ISO-Text, keine erfundene Zeitzone oder Culture |
| GUID / einfache Bytewerte | uniqueidentifier / varbinary(n/max), exakt validierte kanonische GUID-/Hexdarstellung |
| Object/Recordset/CLR-UDT und unerkannte Typen | Kein erfundener skalarer Ersatz; benötigte Stufe unsupported/missing_context |

V1-Ausdrucksgrammatik: gebundene Spalten-/Variablen-/Parameterreferenzen,
typisierte Literale, Klammern, unary Plus/Minus, numerische Addition,
Subtraktion, Multiplikation, Division und Modulo, Vergleiche,
`&&`, `||`, `!`, `?:`, `ISNULL`, `REPLACENULL`, Textverkettung und explizite
Konvertierungen zwischen den zugelassenen skalaren Typen. Weitere SSIS-Funktionen
sind zunächst unsupported; keine gleichnamige automatische SQL-Ersetzung.
SSIS-`ISNULL(x)` bedeutet NULL-Test, nicht T-SQL-ISNULL-Ersatzwertfunktion.
Originalausdruck, gebundene Versionen, SQL-Ausdruck und Typ-/NULL-/Fehlerannahmen
bleiben zugeordnet. SQL-CAST-Fehler/Überläufe dürfen beim manuellen Debuglauf
auftreten; keine SSIS-Fehlerreihenfolge oder allgemeine Row-Error-Parität zusagen.

## 6. V1-Komponenten und Pfadsemantik

| Komponente | Festgelegter erster Umfang |
|---|---|
| OLE DB / ADO.NET SQL-Server-Source | Tabelle, View oder genau eine statische/aufgelöste SELECT-Abfrage; OLE-DB-? ordinal und ADO.NET-Parameter nach tatsächlichem Mapping binden. EXEC/prozedurale Source-Skripte gesperrt |
| Union All | Nur tatsächlich verbundene Inputs, explizites ordinales Outputmapping, typisierte NULLs für fehlende Zuordnung; Duplikate erhalten; unabhängige Data Flow Tasks getrennt |
| Derived Column / Data Conversion | Obige Teilmenge; Überschreiben erzeugt neue Spaltenversion. Alle Ausdrücke derselben Komponente lesen den gemeinsamen Eingangsstand |
| Lookup | Immer ROW_NUMBER über sämtliche wirksamen Referenzschlüssel/-ausdrücke und ausschließlich Nummer 1; keine Join-Vervielfachung. Auswahl und Cache nach Abschnitt 7 |
| Conditional Split | Metadatenreihenfolge, erster wahrer Ausgang, eindeutige BranchId, Default-ELSE. Kein Bündel unabhängiger Filter |
| Destination | Eine Endprojektion je tatsächlichem Zielport, Originalmapping/Ordinal/Alias/Typ sichtbar. Keine Ziel-DML, Identity-/Default-/Triggerausführung |

Lookup-Match nutzt INNER JOIN; Weiterlauf mit ignorierten No-Matches LEFT JOIN;
expliziter No-Match-Ausgang LEFT JOIN plus fehlender eigener nicht-nullbarer
Matchmarker. Nullable Lookup-Payload ist kein Matchtest. Fail-Component-Zustände
werden nicht stillschweigend als Wegfiltern übersetzt: mögliche Fehlerpfade
werden erklärt und sperren den davon abhängigen vollständigen Zielfluss, soweit
sie im V1-Profil nicht ausgeschlossen/ausdrücklich modelliert sind. Match-/
Vorgängeransichten bleiben als solche untersuchbar.

Split-Bedingungen müssen im jeweiligen Profil total definiert sein oder eine
belegte Ignore-NULL-Disposition besitzen. Mögliche NULL-/Fehlerzustände mit
nicht unterstützter Fail-/Redirect-Disposition sperren die betroffene Stufe;
vorangehende Spalten-/Bedingungsansichten bleiben verfügbar. SQL-UNKNOWN wird
nicht heimlich zum Default. Unbekannte oder widersprüchliche Priorität blockiert.

Merge/Merge Join, Aggregate, Sort-/Deduplicate-Transformation, Multicast,
Flat File/Excel/Fremdprovider, Script-/Custom-Komponenten, Execute SQL,
OLE DB Command, vollständige Loops/Events/Transaktionen sind kein übersetzter
V1-Komponentenumfang. Der Workflow zeigt sie; nur abhängige Nachfahren werden
gesperrt. Bereits im lesenden Source-SELECT stehende JOIN/GROUP-BY-Konstrukte
sind davon verschieden: sie dürfen erhalten bleiben, wenn sie vollständig im
SQL-AST-/Typ-/Dependencyprofil liegen. Für diesen SQL-Leseteil werden SELECT,
Projektionen/CASE, WHERE, JOIN, UNION ALL, GROUP BY/HAVING, TOP/ORDER BY und
gebundene Unterabfragen/CTEs zugelassen. Intrinsische Funktionen in V1:
CAST/CONVERT, ISNULL/COALESCE/NULLIF, ABS/CEILING/FLOOR/ROUND,
UPPER/LOWER/LTRIM/RTRIM/SUBSTRING/LEN/DATALENGTH, DATEADD/DATEDIFF/DATEFROMPARTS,
COUNT/COUNT_BIG/SUM/AVG/MIN/MAX und ROW_NUMBER. Unbekannte Aufrufe sind keine
automatisch sicheren Builtins. Die eigene Guardsyntax hat eine getrennte feste
Liste etwa für OBJECT_ID und HASHBYTES; sie erweitert nicht den Quellvertrag.
Keine automatische Port-/Pfaderfindung.

Jede Stufe trägt `translated`, `pragmatic`, `missing_context` oder `unsupported`.
Wertherkunft und Zeilenabhängigkeit werden getrennt abgebildet. Ein fremder
unabhängiger Data Flow blockiert keine vollständige unterstützte Zielprojektion.

## 7. Lookupauswahl, Vergleich und NOLOCK

Eine belegte fachliche Reihenfolge wird verwendet, einschließlich mehrspaltiger
Schlüssel. Sonst exakt `ORDER BY (SELECT NULL)` und Diagnose
`arbitrary_lookup_selection`. Nicht eindeutige fachliche Ordnung bleibt bei
Ties nicht deterministisch; kein unangeforderter Tie-Breaker. Kein Versprechen,
den von SSIS zuerst gefundenen Treffer zu reproduzieren.

JOIN und PARTITION verwenden identische normalisierte Schlüsseltypen/-ausdrücke
und explizite Vergleichscollation. Normale SQL-NULL-Gleichheit, keine automatischen
UPPER-/TRIM-/Sentineländerungen. SQL- versus Full-Cache-Vergleich ist als
pragmatisches Profil sichtbar, einschließlich Groß-/Kleinschreibung, Leerzeichen,
Codepage und numerischer Typen. Temp-Spalten erhalten explizite Collation.

### Verbindliches NOLOCK-Profil

- Alle direkten lesenden Tabellen-/Viewreferenzen in Quellen, Lookup-SQL,
  zugelassenen Unterabfragen und den eigenen Temp-Lesepfaden erhalten
  `AS <Alias> WITH (NOLOCK)`, soweit der gebundene Objekttyp dies unterstützt.
  Feste Katalogabfragen benutzen den Hint an unterstützten Systemviews ebenso.
- Behandlung am AST/gebundenen Objekt, kein pauschales Text-REPLACE. Bereits
  vorhandenes NOLOCK nicht doppelt setzen, READUNCOMMITTED zu NOLOCK vereinheitlichen.
- Vorhandene Isolation-/Granularitäts-/Sperrhints, die dem Profil widersprechen
  (etwa HOLDLOCK, UPDLOCK, XLOCK, READCOMMITTEDLOCK, ROWLOCK, TABLOCK), entfernen
  und mit `locking_hint_replaced` berichten. READPAST ebenfalls entfernen:
  bewusstes Überspringen gesperrter Zeilen ist eine andere Datenlogik und wird
  als zusätzliche pragmatische Abweichung ausgewiesen. Unverstandene Hintkombination
  blockiert die Stufe statt ungeprüften SQL-Text auszugeben.
- Keine Hints an DML-Ziele, VALUES-Konstruktoren oder Stellen ohne unterstützte
  Hintsyntax; an CTE-/Unterabfragealiasen keine zusätzliche pauschale Hintschicht,
  stattdessen deren eigentliche lesende Objekte bearbeiten. Nicht sicher
  behandelbare Objekttypen, etwa spezielle Memory-Optimized-/Providerpfade,
  werden diagnostiziert, nicht durch einen unzulässigen Hint „unterstützt“.
- View-/Funktionsdefinitionen werden nicht persistent geändert. Die Prüfung
  darf nicht behaupten, dass ein äußerer Hint alle versteckten Funktionszugriffe
  abdeckt. Zulässige Viewzugriffe, reine skalare Ausdrücke und nicht behandelbare
  transitive Zugriffe werden im Bericht unterschieden.
- Jeder davon betroffene Datenpfad erhält `nolock_read_uncommitted` und eine
  sichtbare pragmatische Bewertung. NOLOCK erlaubt unbestätigte, fehlende oder
  doppelt gelesene Zeilen und verhindert Sch-S-/Sch-M-Blockierung nicht generell.
  Kein versprochener gemeinsamer Snapshot, keine garantierte Sperrfreiheit.

Diese Grenzen sind in [Microsofts Table-Hint-Vertrag](https://learn.microsoft.com/en-us/sql/t-sql/queries/hints-transact-sql-table?view=sql-server-ver17)
beschrieben. Der Benutzer hat den Standard zum parallelen Debuggen eines
laufenden Pakets ausdrücklich gewählt. Die Debugfunktion ändert keine
Datenbank-Isolationsoption und startet keine Quelle zur Generierungszeit.

Jeder Lookup wird vor Wiederverwendung einmal dedupliziert in einer eigenen
lokalen Temp-Tabelle materialisiert. Auch der beliebige Default bleibt dadurch
innerhalb dieses Cachelaufs gleich. Source-/Referenzdaten können beim Lesen
parallel verändert sein; eingefroren wird die tatsächlich aufgenommene Auswahl,
keine nachträglich rekonstruierte SSIS-Sicht. Ein gesonderter Duplikat-Prüfblock
liest gegebenenfalls erneut und ist dann kein zeitgleicher Beweis des Cacheinputs.

## 8. Lesende Katalogprüfung und Schreibgrenze

Die Freigabe wird als **explizit zugeordnete Same-instance-Katalogprüfung**
konkretisiert. Keine automatisch aus Paket-Connection-Strings aufgebauten
Verbindungen und keine Verbindung zu einem anderen Server. Verbindungen im
Paket sind logische IDs; CatalogBindings legt den bewussten Debugkontext fest.
Eine abweichende Zuordnung bleibt als `connection_binding` im Bericht sichtbar.

Zulässige eigene Abfragen lesen ausschließlich benötigte Systemmetadaten,
insbesondere sys.databases, sys.schemas, sys.objects, sys.tables, sys.views,
sys.columns, sys.types, sys.computed_columns, sys.sql_modules,
sys.sql_expression_dependencies, sys.synonyms sowie Sicherheitsprädikat-/
Assembly-Metadaten und bekannte Collations. SQL-Text dieser Abfragen ist fest;
Datenbankidentifier werden erst nach Allowlist-/Existenzprüfung gequotet,
Suchwerte sind Parameter. Kein aus DTSX übernommenes CommandText als Befehl.

Ausführung als CALLER, ohne Owner-Impersonation/Rechteerweiterung. V1 verlangt
vorhandenes CONNECT und ausreichende vollständige VIEW-DEFINITION-Sicht in
jeder betroffenen erlaubten Datenbank; tatsächliche Minimalrechte werden
qualifiziert, nicht gewährt. Fehlende Sicht ist kein Beleg für fehlende
Dependencies. [Microsoft: Metadata Visibility](https://learn.microsoft.com/en-us/sql/relational-databases/security/metadata-visibility-configuration?view=sql-server-ver17).

Bindung umfasst sämtliche tatsächlichen Tabellen-/Spalten-/Aliasreferenzen.
Views und lokale Synonyme werden rekursiv aufgelöst. T-SQL-Inline-TVFs und reine
skalare Ein-RETURN-Ausdrücke dürfen nach Parameter-/Typ-/ASTprüfung zugelassen
werden; prozedurale/multistatement Funktionen, unbekannte CLR-Funktionen/UDTs,
Remote-/externe Objekte und verschlüsselte Definitionen bleiben gesperrt.
Ausgewählte computed columns sowie wirksame Row-Level-Security-Prädikate gehören
ebenfalls in die Dependencyprüfung; ein basaler Tabellenname allein reicht nicht.
Cross-database-Referenzen benötigen eine erlaubte und vollständig aufgelöste
Zieldatenbank. `referenced_id IS NULL` ist kein PASS; maßgeblich sind zusätzlich
gebundene AST-Referenzen. [Microsoft: SQL Dependencies](https://learn.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-sql-expression-dependencies-transact-sql?view=sql-server-ver17).

Vor und nach der Sammlung Objektidentitäten, relevante Spalten-/Typ-/
Definitionsstände und Beziehungen vergleichen; bei Drift oder inkonsistentem
NOLOCK-Metadatenbild safety_blocked, kein automatischer endloser Retry. Dies ist
eine zeitgebundene Bestandsprüfung, keine Sperre gegen spätere fremde DDL.
Ausgabe bindet Objekt-/Definitionsfingerprints in lokale Artefaktmetadaten.
Keine realen Fingerprints/Definitionen als Repository-Evidence übernehmen.

**Nicht erlaubt beim Analysieren:** Source-/Lookup-/Execute-SQL-Befehle,
SELECT TOP(0), Vorschau, FMTONLY, SHOWPLAN oder describe-first-result-set für
eingereichten Paket-SQL, Prozedur-/Funktionsausführung, SSIS-Validate/Execute.
Typen aus Paket und gebundenem AST/Katalog herleiten und vergleichen; wenn das
nicht reicht, die betroffene Stufe als fehlenden Kontext ausweisen.

Alle übernommenen Quell-/Referenzabfragen und alle finalen ausführbaren
SQL-Artefakte bestehen die rekursive AST-Allowlist. V1 erlaubt gebundene SELECTs,
eigene skalare DECLAREs mit geprüften Literalen, geprüfte IF/THROW-/TRY/CATCH-
Guards und ausschließlich eigene CREATE TABLE / INSERT ... SELECT / DROP TABLE-
Tempformen. Jeder schreibende Zielname ist gebunden, nicht nur auf `#` geprüft.
Keine globalen Temps, Fremd-Temps, Table-Variablen, Temp-Trigger/-UDF-Defaults,
persistente DML/DDL, EXEC/INSERT EXEC, dynamisches Quell-SQL, NEXT VALUE FOR,
DBCC, Rechte-/Serveränderungen, SQLCMD-Includes oder Remote-Passthrough.
Unbekannte AST-Knoten und Syntax-/Parser-/Grenzfehler sperren ausführbare Ausgabe.

## 9. DECLAREs, CTE-Prüfstufen und Cache-Lebensdauer

TargetSql und StageSql sind jeweils zusammenhängende ausführbare Batches mit:

1. Klar markiertem bearbeitbarem Werteblock, alle benötigten Szenariowerte als
   typisierte DECLAREs. Danach technische Konstanten/Guards, erkennbar getrennt.
2. Vollständiger Vorbereitung/Prüfung der benötigten eigenen Lookup-Caches.
   Ein StageSql benötigt keine zuvor ausgeführte unvollständige WITH-Kette.
3. Benannten CTEs des transitiven Vorgängergraphen, etwa mains, calculated,
   lookup1, main_lookup1, routed und split_high.
4. Genau einem fachlichen SELECT für den gewählten Prüfpunkt beziehungsweise
   die Zielprojektion. Kein GO zwischen Deklarationen und WITH/SELECT.

Direkte Initialwertänderung im erzeugten T-SQL genügt; kein erneuter Generator-
oder JSON-Aufruf nötig. Scopekollisionen ergeben eindeutige SQL-Variablennamen.
Der Bericht ordnet jeden Namen seiner ursprünglichen Eingabe zu. Zur manuellen
Fehlereingrenzung kann das letzte SELECT gegen SELECT aus einer Vorgängerstufe
getauscht werden. Einzeln ausgegebene StageSql enthalten bereits nur ihre nötigen
Vorgänger. Diagnostische Hilfsspalten sind gekennzeichnet und fehlen im Zielmapping.

Eigene Temp-Namen enthalten einen Generierungs-/Lauftoken und bleiben unter
SQL-Server-Namensgrenzen. Dieser Token wird deterministisch aus Paket, effektivem
Bindings-/Projekt-/Katalog-/Lookup-/Vergleichs-/Dialektprofil abgeleitet;
Ziel-/Stufenauswahl allein ändert ihn nicht. So können nachträglich angeforderte
Stufen desselben Szenarios in derselben Sitzung denselben Lookupstand verwenden.
Neue JSON-Szenariowerte ergeben einen neuen Lauf; Cleanup des bisherigen Laufs
bleibt mit dessen bereits ausgegebenem CleanupSql möglich. Direkte Änderungen
an DECLARE-Literalen nutzen die unten beschriebene lokale Cacheinvalidierung.
Cachezustand, Schema und Ownershipmarker liegen nur
in eigenen lokalen Temp-Tabellen derselben Sitzung. Marker sind Kollisionsschutz,
keine Sicherheitsgrenze gegen absichtliche Manipulation derselben Sitzung.

- Beide Objekte fehlen: Cache plus Zustandsmarker neu erstellen.
- Eindeutig eigene, unveränderte Struktur und gleiche relevante Eingabewerte:
  bestehenden Referenzstand wiederverwenden.
- Eindeutig eigener Zustand, aber andere relevante DECLARE-Werte, Abfrage-,
  Vergleichs- oder Auswahlregel: nur betroffene eigene Cache-/Zustandstabellen
  kontrolliert neu aufbauen, vor dem finalen SELECT.
- Fehlende/abweichende Marker, Fremdobjekt oder unklarer Teilzustand: Abbruch;
  nichts Fremdes löschen. Neue Erstellung im laufenden Block lokal verfolgen,
  bei Fehler nur sicher selbst erzeugte Objekte bereinigen. Harte Unterbrechung
  ist kein Cleanup-PASS; unklarer Zustand verlangt einen neuen Lauf/klare Bereinigung.

Der Vergleich relevanter Werte verwendet typisierte, null- und längensichere
Binärserialisierung mit Typ-/Ordinal-/Längenmarkern, gegebenenfalls SHA2-256;
keine kollisionsanfällige Stringverkettung/SQL-Textgleichheit mit ignorierten
Leerzeichen. Ein nur für den Split geänderter Schwellenwert lädt keinen
unabhängigen Lookup neu. Geänderte Quelldaten allein erzwingen bewusst keinen
Reload: der Debug-Lauf hält seine Auswahl fest. CleanupSql erlaubt explizites
Zurücksetzen, danach initialisiert der nächste Prüfblock neu.

CleanupSql wird separat ausgegeben und entfernt nur passende eigene Objekte;
standardmäßig bleiben Caches bis zum gewählten Cleanup oder Sitzungsende.
Erzeugen/Neuaufbauen/Cleanup ist nur bei `@@TRANCOUNT = 0` und
IMPLICIT_TRANSACTIONS OFF zulässig; andernfalls vorher neutral abbrechen. Kein fremder
COMMIT/ROLLBACK und keine Änderung von Server-/Datenbankoptionen. Laufzeitfehler
der gelesenen Daten werden nicht durch Dummywerte oder leere Rowsets versteckt.

PreparationSql ist eine zusätzliche Cache-Prüfansicht, keine zwingende manuelle
Vorbedingung vor einem vollständig ausgegebenen StageSql/TargetSql. Alle drei
Ausgabeformen verwenden dieselbe kanonische Rendererlogik.

## 10. Ergebnisschema, Fehler und Standardvertrag

Genau ein fachliches Resultset als Artefaktverzeichnis. Sämtliche Zeichenfelder
verwenden explizit Latin1_General_100_BIN2; Content/Details sind Unicode. Eine
ResultTable übernimmt exakt dieses Schema gemäß [USP-Vertrag](../Standards/USP_CONTRACT.md).

| Spalte | Typ | NULL |
|---|---|---|
| ArtifactKind | varchar(32) | nein |
| TargetFlowId / StageId | jeweils varchar(64) | ja |
| Ordinal | int, globale Ausgabereihenfolge | nein |
| ComponentId | nvarchar(4000) | ja |
| EvidenceClass | varchar(24) | nein |
| Severity / DiagnosticCode | varchar(16) / varchar(64) | ja |
| IsComplete | bit | nein |
| SafetyStatus | varchar(24) | nein |
| IsExecutable | bit | nein |
| Content | nvarchar(max) | nein |
| DetailsJson | nvarchar(max), gültiges JSON falls gesetzt | ja |

ArtifactKind: BindingsTemplate, Workflow, StageIndex, PreparationSql, StageSql,
TargetSql, CleanupSql, ColumnLineage, Diagnostic. EvidenceClass: translated,
pragmatic, missing_context, unsupported; reine Beschreibungsartefakte descriptive.
SafetyStatus: not_applicable, not_checked, passed, blocked. Severity: info,
warning, error oder NULL für reine Inhalte. Artefakte ohne vollständigen
benötigten Pfad oder ohne bestandene Sicherheitsprüfung sind nicht ausführbar.
Pragmatische, ausdrücklich erklärte Profile können ausführbar sein; sie werden
dadurch nicht zu SSIS-Äquivalenznachweisen. IsExecutable beschreibt die
Vollständigkeit und bestandene Profil-/Safetyprüfung im gebundenen Kontext,
keinen bereits ausgeführten Lauf oder garantierte Datenleserechte eines später
anderen Ausführers. Unbekannte Nachfolger erhalten keine
ausführbaren Platzhalter. Alle Ausgabe-/Budgetprüfungen vor erster Ergebniszeile
beziehungsweise Mutation der übergebenen ResultTable.

Globale Parameter-/Format-/Ressourcen-/Templatefehler: öffentliche Fassade mit
THROW 50000 und stabilem `TBX_SSISDBG_...`-Präfix; keinen neuen Nummernbereich
raten. CLR-Wrappingfehler geordnet in diesen Vertrag übersetzen, Originalursache
ohne Secret-/SQL-Echo erhalten. Lokale fachliche Blocker sind Diagnosezeilen,
damit unabhängige gültige Ziele erhalten bleiben. Stabile Diagnosecodes:
unsupported_package_format, unsupported_component, unsupported_expression,
unresolved_binding, invalid_lineage, ambiguous_path, invalid_template,
catalog_visibility, catalog_drift, unresolved_dependency, unsafe_statement,
arbitrary_lookup_selection, lookup_comparison_deviation, split_null_disposition,
nolock_read_uncommitted, locking_hint_replaced, hint_not_supported,
cache_context_changed, cache_ownership, resource_limit, partial_target.

Hilfe vor fachlicher Validierung, kein Debug oder Kataloglesen im Help-Modus.
Standardtail und ein Resultset unverändert. Gesunde Caller-Transaktion bei der
reinen Analyse erhalten, keinen fremden COMMIT/ROLLBACK; doomed Zustand vor
fachlicher Arbeit mit neutralem Fehler abweisen. ResultTable-/KeepData-Fälle
inklusive Schemaanpassung, Append, Dummyspalte und blockierenden Dependencies
über den vorhandenen Standard prüfen. Keine unbeabsichtigten CLR-Resultsets.

## 11. Endliche Ressourcen und ehrliche Grenzen

Festes Profil `ssis-debug-v1`; NULL bedeutet nirgends unbegrenzt.

| Grenze | V1-Maximum |
|---|---:|
| DTSX-Originalbytes | 16.777.216 |
| Ein JSON-Dokument / alle JSON-Inputs zusammen | 4.194.304 / 8.388.608 UTF-16-Bytes |
| XML-/JSON-Tiefe | 128 / 32 |
| Komponenten / Paths / Spalten / Eingaben | 512 / 2.048 / 8.192 / 2.048 je Import |
| Einzelner SSIS-Ausdruck / Ausdruckstiefe | 16.384 UTF-16-Bytes / 64 |
| Eindeutige SQL-Prüfeinheiten / Katalogobjekte / Dependencytiefe | 128 / 256 / 16 |
| SQL-Prüfeinheit / SQL-AST-Tiefe | 2.097.152 UTF-16-Bytes / 100; zusätzlich das unten genannte Vorfilterprofil |
| Katalogabfragen / ScriptDom-Parseraufrufe | 128 / 128 je Aufruf; identische SQL-Einheiten im Aufruf wiederverwenden |
| Artefakte / Diagnosen | 10.000 / 1.000; Überschreitung ist Fehler, keine stille Kürzung |
| SQL je Artefakt / gesamte Content-/Details-Ausgabe | 2.097.152 / 8.388.608 verrechnete UTF-16-Bytes |
| Kooperatives Analyse-Arbeitsbudget | 30 Sekunden, regelmäßig geprüft; kein harter SQL-/Heap-/Prozess-Watchdog |
| Rekursion bei Pipelinevorgängern / Variablenabhängigkeiten | 32 / 16; engere Implementierungsgrenzen vor rekursiver Arbeit |

Für den **neuen internen SSIS-Einstieg** wird folgendes zu qualifizierendes
Vorfilterprofil vorgeschlagen: höchstens 4.096 Atome, 65.536 Rohtexteinheiten
nach der kanonischen Scannerzählung, aktive Struktur bis 32 und verschachtelte
Kommentare bis 16. Zusätzlich konservativ höchstens 256 Operatorvorkommen
außerhalb von Kommentaren/Bezeichnern/Literalen, einschließlich arithmetischer
und Vergleichszeichen sowie AND/OR/NOT; Mehrzeichensequenzen dürfen strenger
gezählt werden. Zusätzlich höchstens 64 Mengenoperatoren. Kein neuer Guardzweig
wird ungeprüft als sicher vorausgesetzt.

Nach dem Parser zusätzlich höchstens 65.536 Tokens, 65.536 besuchte AST-Knoten,
262.144 inspizierte AST-Eigenschaften, 32 CTEs je Batch und 256 Ausdrücke je
Projektions-/Werteliste. Erschöpfte Grenzen liefern keine teilweise sichere
Ausgabe. Das vollständige finale Skript muss alle Grenzen bestehen, nicht nur
seine einzeln geprüften Quellfragmente. Die Graphobergrenzen versprechen deshalb
kein ausführbares SQL für jeden Graphen innerhalb dieser Grenzen.

Diese Werte sind **Entwurfsobergrenzen, kein Sicherheitsnachweis**. Vor einem
Laden oder Aufruf des neuen SQL-Einstiegs sind die gemeinsamen Vorfilter und
das neue Profil mit adversarialen, isolierten kleinen Framework-Stacks und
äußeren Watchdogs unabhängig zu qualifizieren. Crash, Stackoverflow, Timeout
oder unvollständige Kanäle sind Fehler. Ein unsicherer Grenzwert wird enger
gesetzt und im Vertrag berichtigt; eine Vergrößerung verlangt einen neuen
konkreten Härtungs-/Freigabevertrag. Die vier bisherigen Parser-TVFs behalten
auch im Patchprofil exakt ihre 512-Atome-/8.192-Rohtexteinheiten-Grenzen und
bisherigen Struktur-/Kommentar-/Ausgabegrenzen.

Budgetprüfungen vor teuren Kopien, vor Parseraufrufen und vor Ausgabe. Ein
blockierter SQL-Katalogzugriff kann erst durch Engine-/Clientabbruch zurückkehren;
das kooperative Budget garantiert keine harte Antwortzeit. Keine Behauptung,
dass Grenzzähler physische Heap-/Stack-/TempDB-Kapazität vollständig begrenzen.
Qualifikation benutzt private äußere Watchdogs und begrenzte Offlinekindprozesse;
keine neuen eigenen Threads oder Infrastruktur als vermeintliche SQL-CLR-Lösung.

## 12. Installation, Updates, Uninstall und Datenschutz

Manifest enthält alle drei Statusdimensionen, Dependencies, Names/Bindings,
Schema/Resultset/Help, den ausdrücklichen CLR-UNSAFE-/Trustvertrag und das Windows-only
Gesamtprofil. Lokaler und zentraler Modus verwenden dieselbe Implementierung;
das fachliche Datenbankmapping kommt immer explizit aus CatalogBindings, nicht
aus einer geratenen Caller-DB bei dreiteiligem Aufruf.

Preflight prüft vorhandene Rechte, Engine/CL/OS, konsistent installierte
Dependencies, exakte neue Parser-/Consumer-/ScriptDom-Releasepins und freigegebenes
eigenes Binary, bevor DDL beginnt. Der gekoppelte Parser-/Consumerpatch wird
als eigenes reproduzierbares Releaseartefakt gebaut und qualifiziert; der
SSIS-Installer verändert diese Module nicht implizit. Kein Nachinstallieren,
kein Kopieren fremder Assemblies und keine automatische Änderung von Trust.
Geplante Reihenfolge: qualifizierter Parserpatch, gekoppelter Consumerpatch,
danach SSIS-Modul. Zwischen Parser- und Consumerpatch darf der bestehende
Table-Clone-Trigger-Opt-in wegen des exakten Pins vorübergehend ablehnen;
keine Pinumgehung oder Zusage unterbrechungsfreier Updates. Vorhandene
triggerfreie Table-Clone-Pfade erhalten keine neue Parserpflicht.
Install/Repeat/
Upgrade/Uninstall mit eigener kurzer Transaktion/Application Lock nach
Deploymentvertrag; unbekannte installierte Versionen und Namenskollisionen
abweisen. V1 hat keine erfundene Vorgängerversion, keinen Rückwärtsupgradepfad.

Uninstall entfernt nur marker-eigene V1-Objekte, respektiert Consumer und
Dependencies und entfernt weder den gemeinsamen Parser noch seine ScriptDom-
Assembly. Hash-Trust bleibt separater administrativer Vorgang. Neue Metadaten-
oder Logtabellen für Paketinhalt sind nicht Teil des Moduls; generische
Toolbelt-Lifecyclemarker folgen dem vorhandenen Modell.

Verarbeitung lokal in SQL Server, keine Uploads/Telemetrie oder automatische
Dateiablage. Workflow, SQL, Bindings und Katalogdefinitionen können vertraulich
sein und werden nur als ausdrücklich angeforderte lokale Funktionsergebnisse
ausgegeben. Secrets nie aktiv ausgeben. Repository, PR, Tests und Hilfe erhalten
nur synthetische Beispiele und öffentliche Produktquellen, keine realen Pakete,
Endpoints, Definitionen, Hashes von Runtimekontext oder Originaldaten.

## 13. Abnahme, Reihenfolge und Nachweisstatus

Die folgenden Fälle definieren den vereinbarten Prüfvertrag. Ihr aktueller
Ausführungsstand steht in der [Modulprüfmatrix](../../Modules/toolbelt.tsql.ssis-debug/Tests/README.md).
Nur ihre tatsächliche Erfüllung qualifiziert den jeweils genannten Teilumfang;
die Existenz von Testdateien oder Beispiel-SQL ist kein PASS.

| Gate | Entscheidende Nachweise |
|---|---|
| Import / Profile | Beide DTSX2-Profile, native Alias-/Komponentenvarianten, Verschachtelung, ID-/Namespace-/Encodingfehler, unbekannte Klassen, fehlender Projektkontext, Grenzen je minus eins/exakt/plus eins |
| JSON / DECLARE | Unverändert zurückgegebene Vorlage; nur Werte ändern; Scopeshadowing; exakte Typen/NULL/false/0/Decimal/Int64; veralteter Hash, doppelte/unbekannte Keys, Metadatenmanipulation, Sensitive-Redaction; direkte DECLARE-Änderung ohne Generator |
| Komponenten | Mehrere Quellen → echtes Union All → Berechnung/Overwrite → Lookup → priorisierter Split → genaue Zielprojektion; unbekannte Nachfolger sperren, bekannte Vorstufen separat ausführbar |
| Lookup / Cache | Composite Keys, 0/1/viele Treffer, nullable Payload, beliebige Wahl ohne behaupteten Solltreffer; fachliche Sortierung mit Ties; zwei Prüfungen gleicher Cachezeile; relevante Parameteränderung baut nur eigenen betroffenen Cache neu; irrelevante Schwelle erhält Auswahl |
| NOLOCK | AST-basierter Hint an allen unterstützten Lesereferenzen, auch verschachtelt/Lookup/Katalog/Temp; Alias-/Hintkonflikte, keine unzulässigen Konstruktor-/Schreibzielhints; parallele synthetische DML demonstriert ausdrücklich Dirty-Read-Grenze; Sch-M-Fall verspricht keine Sperrfreiheit |
| Katalog / Safety | Same-instance-Allowlist, Callerrechte/local/central, fehlende Sicht, Drift, Views/Computed/RLS/Functions, lokale/remote Synonyme, Cross-DB-NULL-IDs; keinerlei Ausführung von Paket-SQL; alle negativen persistenten DML/DDL-/EXEC-/Remote-/SQLCMD-/Sequenzfälle abweisen |
| Parser / Ressourcen | Exakter ScriptDom-Pin, neuer qualifizierter Providerbuild; altes TVF-Profil unverändert und neues begrenztes Profil separat nachgewiesen; vollständiger finaler Batch, Kommentare/GO/Literale/Operatorfolgen, isolierte Offlinefehler/Stack/Timeout/Cleanup. Unabhängige Vertrags-/Kernprüfung und Offlinequalifikation vor Laden/Aufruf des neuen SQL-Einstiegs nach Parser-Härtungsvertrag |
| Öffentlicher Vertrag | Genau eine neue öffentliche USP; Parametertypen/-defaults/-reihenfolge, Help-only, ein Resultset, Standardtail, ResultTable/KeepData, Fehlersignale, Outputatomarität, Collation und Caller-TX/SET-Erhalt |
| Lifecycle / Plattform | Clean/Repeat/Uninstall/Repeat; echter Parser-2.0.0→2.0.1- und gekoppelter Consumerpatch-Upgrade; unveränderte Table-Clone-Triggerfunktion; Dependency-/Fremdobjekt-/Consumer-Schutz auch bei gemeinsamem ScriptDom und unterschiedlichen Installationsreihenfolgen. Windows SQL2019/2022/2025 local/central nach Risikopfaden, CL150/160/170 soweit Engine verfügbar. Linux-Generator explizit nicht unterstützt |

Entwicklungsfolge: (1) gemeinsame Vorfilterquelle und begrenztes neues Profil
mit unveränderter Legacyregression, (2) offline Import/JSON/Graph und Komponenten-/
Ausdruckskern, (3) sichere SQL-/Katalogadapter und NOLOCK-Renderer,
(4) DECLARE-/CTE-/Cache-Artefakte und negative Safetytests,
(5) unabhängige Sicherheitsprüfung und begrenzte Frameworkqualifikation,
(6) ausdrücklich ausgewählte synthetische native Modul-/Lifecycle-/Debugskripttests.
Die Abnahme muss auch mindestens einen vollständigen kleinen Zielfluss
**mit Cache-Guards innerhalb des tatsächlich qualifizierten neuen Parserprofils**
erfolgreich nachweisen; scheitert dies, kein Implementierungs- oder
Qualifikations-PASS durch Weglassen der Prüfung.

Keine umfassende SSIS-Runtime oder vollständige Engine-/Versionsgleichwertigkeit
als V1-Abnahmekriterium erfinden. Empirischer SSIS-Vergleich, falls benötigt,
bleibt ein gesondert ausdrücklich ausgewählter synthetischer Testumfang.
Native Testressourcen nach dem Labvertrag auswählen; blockiertes Ziel stoppt
keine unabhängige Offlineentwicklung. Der ursprüngliche Vertragsauftrag allein
autorisierte keine Labverbindungen oder Installationen. Die anschließende
Implementierungs- und Testfreigabe ist am Dokumentanfang festgehalten.

Ein Implementierungsverantwortlicher, ein kohärenter Featureumfang; keine
automatische zweite Entwicklungswelle. Bereits grüne Prüfungen nur bei geänderten
betroffenen Inputs oder Pflichtfrische wiederholen. Dokumentationsänderung löst
keine fachfremde Runtime-Vollmatrix aus. Unabhängige Sicherheitsprüfung bleibt
ein eigener Gate mit separat ausgewiesenem Nachweis.

## 14. Freigabegegenstand und getrennte Folgeschritte

Zur Freigabe steht dieser öffentliche und fachliche V1-Vertrag einschließlich
oben genannter technischer Grenzen und des zwingenden NOLOCK-Debugprofils,
der neuen Windows-/UNSAFE-Assembly sowie des eng begrenzten Parser-2.0.1- und
Table-Clone-4.1.1-Consumerpatchs. Keine bestehenden öffentlichen Parsergrenzen
werden erweitert. Die gemeinsame ScriptDom-Version bleibt unverändert.
Eine Bestätigung autorisiert weder automatischen Merge/Release noch einen
ausführenden ETL-Provider. Die spätere parametrisierte Ablauf-USP und die
weitergehende SSIS-gleiche schreibende USP bleiben getrennte
[Backlog-Vormerkungen](../../Backlog/TOOLBELT_CANDIDATES.md#ssis-dtsx-debug-select--vormerkung-ohne-finale-tc-referenz).
Neue Komponenten, ISPAC, Remote-Katalogprovider, weitergehende Ausdrucksfunktionen
und größere Parsergrenzen benötigen ihren jeweils konkreten Folgevertrag.

Für diesen Entwurf tatsächlich ausgeführt: lokale Quellen-/Vertragsprüfung und
aktuelle Primärquellenrecherche am 2026-10-16. Das synthetische SQL-Beispiel mit
NOLOCK besteht den Offline-Syntaxparse mit dem exakt gepinnten ScriptDom für
SQL150; der bestehende Quellen-Vorfilter lehnt es bei Atom 513 ab. Dieser
negative Befund begründet den vorgeschlagenen getrennten Einstieg und ist kein
Parser-/Runtime-PASS. Der vorhandene Dokumentationsvalidator wurde mit den fünf
betroffenen Arbeitsbaumdateien am unveränderten Change-Impact-Prüfeinstieg
ausgeführt: erfolgreich, einschließlich der 44 vorhandenen Modulmanifeste.
Die Change-Pfadliste wurde nur im lokalen Prüfprozess gesetzt, damit neue und
uncommittete Dokumente tatsächlich erfasst werden; Prüforakel unverändert.
JSON-Beispiele, lokale Links samt Überschriftenankern, UTF-8, Whitespace und
Durchsicht auf unzulässige Inhalte ebenfalls geprüft. Kein Commit-/Head-CI-
oder unabhängiger Sicherheitsnachweis des damaligen Entwurfsstands.

Implementierungsnachtrag 2026-10-16: Die anschließende ausdrückliche Freigabe
steht am Dokumentanfang. Produktquellen, Modulmanifest und reproduzierbarer
Framework-Build sind nun vorhanden. Aktuelle Prüfungen und verbleibende
Integrationsgates stehen in [der Modulprüfmatrix](../../Modules/toolbelt.tsql.ssis-debug/Tests/README.md).
Die begrenzte eigenständige Coreprüfung bleibt ein Pflichtgate vor jedem
SQL-Laden. Klarstellung vom 2026-10-16: Für diese Funktion ist keine Prüfung
der Serverzertifikate erforderlich. Fachtests verwenden `TestPurpose=Functional`
und übernehmen den expliziten booleschen Trustwert des schema-validierten
Labvertrags bei weiterhin erforderlicher Verschlüsselung. Eine fehlende
authentifizierte TLS-Abnahme blockiert diese Fachtests nicht. Sie bleibt
separat `not executed`; kein automatischer Trust-Fallback und keine Änderung
an Labressourcen, Zertifikaten oder Truststores ist damit autorisiert.
