# SSIS-Komponenten-V2 – Erweiterungsvertrag, Variante A

Stand: 2026-10-28 · Autor: Codex.
Status: **nach Besprechung ausdrücklich zur Implementierung freigegeben;
Implementierung und Qualifikation noch offen; unveröffentlicht**.

Benutzerfreigabe: „Ich gebe den V2-Vertrag mit Variante A frei. Setze ihn im
vorgeschlagenen Rahmen autonom mit Luna um. Heartbeat 1h, Konsolen verborgen,
grüne PRs mergen und Main-CI prüfen. Nicht veröffentlichen.“

Ausdrückliche Ergänzung desselben Tages: Das Ressourcenprofil muss mindestens
das Zehnfache des privat benannten Referenzpakets tragen. Anschließend beauftragt:
„oder parametrisiere die Grenzen (auch \"unendlich\" nach oben offen)“.
Die nachstehende Ressourcenparametrisierung ersetzt deshalb die zuvor
vorgeschlagenen festen V2-Mengengrenzen. Der gemeinsame endliche Arbeitsrahmen
wird dadurch weder verlängert noch zurückgesetzt.

Dieser Vertrag erweitert den [V1-Vertrag](SSIS_DTSX_DEBUG_SELECT_V1_CONTRACT.md)
gezielt. V1-Aufrufe, Parameterpositionen, Resultspalten, Sicherheitsprüfungen und
historische Lieferungen/Nachweise bleiben erhalten. Freigegeben sind die unten
genannten Fachänderungen einschließlich ihrer gekoppelten Build-, Deployment-,
Dokumentations-, Test- und Lieferartefakte. Die Freigabe umfasst keine
Veröffentlichung, Tags oder Änderungen fremder Arbeitsstände.

## Zweck und Abnahme

Native Derived Column, Conditional Split, Row Count sowie Flat-File-Source und
-Destination werden innerhalb der konkret qualifizierten Profile vollständig
modelliert: Identität, Versionsherkunft, Ports, Spalten, Abhängigkeiten,
Wert-/Zeilenherkunft, Diagnosen und passende SQL-Debugstufen. Erkennung allein
ist kein Nachweis einer korrekten Übersetzung. Aus fehlenden Daten oder
unbekannten Varianten entsteht kein erfundener vollständiger Datenfluss.

Die benutzerseitigen DTSX-Pakete und daraus gewonnene Einzelmetadaten bleiben
privat. Öffentlich versionierte Fixtures sind synthetisch. Eine erneuerte
private Analyse grenzt Metadatenabdeckung, Ausdrückebdeckung, tatsächlich
bereitgestellten Kontext und ausführbare Stufen getrennt ab.

## Schnittstelle und gemeinsame Implementierung

- Dieselbe öffentliche USP und dieselben Parameterpositionen/Resultspalten wie
  V1; keine neue öffentliche SQL-Funktion oder ResultTable-Implementierung.
- Die zusätzliche Operation `bindings-template-v2` erzeugt eine Vorlage mit
  `schemaVersion: 2` und `profile: "ssis-debug-components-v2"`. Die vorhandene
  Operation `explain` verarbeitet dieses explizite Profil. Die alte Operation
  `bindings-template`, ihr V1-JSON und der V1-Ausführungspfad bleiben erhalten.
- V2-Bindings behalten die bekannten Werte-/Eingabe- und Paket-/Kontexthashfelder;
  Hashbildung bindet zusätzlich das tatsächliche Profil. Keine Migration durch
  bloßen Austausch einer Versionszahl. Falsche Profile, gemischte Schemata,
  doppelte/unbekannte Felder und veraltete Kontextbindungen werden abgewiesen.
- `CatalogBindings` Version 2 erweitert die bisherigen Datenbank-/Connection-
  Felder um die unten definierte `flatFileInputs`-Zuordnung. Version 1 bleibt
  unverändert gültig für V1. Keine freien SQL-, Server- oder Credentialfelder.
- Ressourcenoptionen werden über das bereits vorhandene `@ProjectContext`
  bereitgestellt: Version 2 erlaubt zusätzlich `resourceOptions` nach dem
  nachstehenden Vertrag. Es entsteht kein neuer SQL-Parameter; bestehende
  Positionen und der verbindliche Common-Tail bleiben vollständig erhalten.
  Ein solcher expliziter V2-Kontext wählt bei `explain` V2; ohne `@Bindings`
  werden die zulässigen V2-Designdefaults verwendet. V1-Bindings mit V2-Kontext
  oder die alte `bindings-template`-Operation mit V2-Kontext werden abgewiesen.
  V2 ohne explizite Ressourcenoptionen verwendet das neue Defaultprofil.
- Neutraler Export erhält einen expliziten versionierten V2-Modus und das
  dazugehörige Schema. Bestehende Exportaufrufe und V1-Schemas bleiben erhalten.
  Identitäten bleiben an dieselben Originalbytes und die dokumentierte
  Identitätsbildung gebunden; keine Zuordnung allein über Anzeigenamen.
- Versionsauflösung, Profilprüfung und Herkunftsmodell werden kanonisch geteilt.
  SQL-CLR und externer Host dürfen dieselben Komponenten nicht unterschiedlich
  einstufen. Host-/CLR-Parität ist ein eigenes Gate.
- `@Hilfe`, funktionale Beispiele, Fehler-/ResultTable-Vertrag und benötigte
  DDL-Kommentare werden mitgeführt. Neue Lieferbytes werden getrennt
  qualifiziert; bestehende Installationspakete und Originalpins bleiben erhalten.

## Versionsauflösung

Microsofts `PipelineComponentType` definiert für ein fehlendes `version` den
Default **0**. Das ist von der Versionsangabe des Pipeline-Tasks zu unterscheiden.

- Fehlend: explizit erfasster Schema-Default 0 des erkannten DTSX-Profils.
- Explizit: gültigen Integer unverändert übernehmen und als explizit kennzeichnen.
- Leer, ungültig oder überlaufend: Metadatenfehler; niemals als fehlend/0 behandeln.
- Negative oder nicht qualifizierte Versionen: nachvollziehbar ablehnen.
- Originalangabe, Vorhandensein, effektiver Wert und Herkunft bleiben getrennt.
- Zulassung nur als belegte Kombination aus Paketprofil, Class-ID/Alias,
  effektiver Version und relevanter Port-/Propertystruktur. Kein globaler
  „fehlend bedeutet aktuellste Version“-Fallback und keine Reparatur der DTSX.

Für die neuen Profile sind insbesondere Derived/Split mit Schema-Default 0,
Row Count mit Schema-Default 0, Flat File Source Version 1 und Flat File
Destination mit Schema-Default 0 zu qualifizieren. Bestehende qualifizierte
explizite V1-Varianten bleiben als eigene Varianten erhalten. Andere Varianten
erhalten durch diese Liste keine automatische Freigabe.

## Ausdrücke, Derived Column und Conditional Split

Zusätzlich zum vorhandenen V1-Ausdrucksumfang werden typisierte `NULL(...)`,
`TRIM`, `LTRIM`, `RTRIM`, `LEN`, `SUBSTRING`, `REPLACE` und explizite `DT_STR`-
Konvertierungen implementiert. Benötigte skalare Castfamilien umfassen
`DT_I1`, `DT_UI1`, `DT_I2`, `DT_I4`, `DT_I8`, `DT_NUMERIC`, `DT_WSTR`, `DT_STR`,
`DT_DBDATE`, `DT_DBTIMESTAMP` und `DT_BOOL`.

- Typableitung, Länge/Präzision/Skala, Codepage, NULL und Fehlerannahmen sind
  Teil des Ergebnisses. Kein automatischer gleichnamiger SQL-Funktionsersatz.
- SSIS-`LEN` zählt nachgestellte Leerzeichen; gewöhnliches SQL-`LEN` genügt nicht.
  Text-/Bytezählung, Mehrbyte-/Unicodefälle und NULL werden fest qualifiziert.
- Trim-Funktionen behandeln U+0020; Tab, CR/LF oder weitere Unicode-Leerzeichen
  werden nicht still mitentfernt. SUBSTRING-Indizes und REPLACE-Vergleiche folgen
  dem festgelegten typisierten Profil.
- `DT_STR` bindet seine explizite Codepage und Bytebreite. Keine Ableitung aus
  einer zufälligen Caller-Collation. Nicht qualifizierte Codepage-/Typkombinationen
  blockieren. Konvertierung, Rundung und Abschneiden sind ausdrücklich sichtbar;
  kein Maskieren durch unangefordertes TRY_CAST oder erfundene Ersatzwerte.
- Stringausdrücke rechnen innerhalb des Ausdrucks mit DT_WSTR; ein DT_STR-
  Returncast an der Wurzel ist von der durch SSIS beschriebenen inneren
  WSTR-Konvertierung zu unterscheiden. Ein inneres unkonvertiertes
  `NULL(DT_STR,...)` wird nicht still als gültiger VARCHAR-Wert übernommen.
  Explizite Casts dürfen gemäß belegter SSIS-Semantik abschneiden: DT_STR zählt
  Bytes, DT_WSTR Bytepaare. Dies ist von unbeabsichtigtem Konvertierungsverlust
  zu unterscheiden. Expliziter Boolean-zu-Integer-Cast verwendet in V2
  TRUE = -1 und FALSE = 0; SQLs direkte bit-zu-int-Abbildung genügt nicht.
- Neue/überschriebene Derived-Spalten erhalten getrennte Versionen. Alle Ausdrücke
  derselben Komponente lesen denselben Eingangsstand.
- Beim bedingten Operator `condition ? yes : no` ergibt eine NULL-Bedingung
  ein typisiertes NULL-Ergebnis. Nur der ausgewählte Zweig wird ausgewertet;
  eine Zerlegung darf Fehler in nicht ausgewählten Zweigen nicht auslösen.
  Dies ist keine zusätzliche Kurzschlusszusage für `&&` oder `||`.
  Deren dreiwertige Ergebnisse werden qualifiziert; die Fehlerreihenfolge
  potenziell fehlschlagender Terme bleibt eine ausdrücklich ausgewiesene
  pragmatische Grenze. Ohne Beleg werden solche Fehler nicht durch eine
  angebliche SSIS-Kurzschlussoptimierung maskiert.
- Conditional Split erhält die belegte Reihenfolge, ersten wahren Ausgang und
  Default-Ausgang. NULL-/Error-/Redirect-Semantik wird nicht als normaler
  Default-Filter umgedeutet. Fehlerreihenfolge der gesamten SSIS-Runtime bleibt
  außerhalb der ursprünglichen pragmatischen Debugzusage.

## Row Count

- Genau den qualifizierten synchronen Input-/Outputpfad ohne zusätzliche
  Nutzdatenspalten, Filter, Duplikatentfernung oder Sortierung weiterreichen.
- Zielvariable nach Identität, Namespace, Scope, Schreibbarkeit und geeignetem
  Integer-Typ binden. Fehlende, mehrdeutige oder unzulässige Ziele diagnostizieren.
- Die Zuweisung ist ein Laufzeiteffekt **nach dem letzten Datensatz**. Kein
  vorgezogener aktualisierter Wert innerhalb desselben Data Flows und kein
  vermeintlich gültiger alter cached value.
- Separater typisierter `COUNT_BIG`-Debugschritt am gebundenen Stufenstand;
  Wertebereich des Variablentyps prüfen. Keine tatsächliche SSIS-Variable ändern.
- Zählung und Hauptprojektion beziehen sich auf denselben materialisierten
  Debugstand, sofern zusammengehörige Ergebnisse verlangt werden. Keine
  Snapshot-Gleichheit aus unabhängigen NOLOCK-Auswertungen behaupten.

## Flatfiles – ausdrücklich Variante A

Das Modul analysiert die Dateikonfiguration, liest oder schreibt aber keine
Datei und parst keine übergebenen Dateibytes. Die Datenquelle für SQL-Debug ist
ein ausdrücklich bereitgestellter relationaler Zeilenbestand **nach** dem
Dateilesen/-parsen. Dies ist eine deklarierte pragmatische Ersatzquelle und
kein Nachweis einer tatsächlichen Dateieinlesung oder Byte-/Fehlerparität.

`CatalogBindings` Version 2 enthält `flatFileInputs` als Objekt, dessen Schlüssel
die importierte Connection-ID ist. Jeder Eintrag deklariert:

- `database`, `schema`, `object`: erlaubtes lokales relationales Quellobjekt;
- `columns`: eindeutige Zuordnung importierter Spaltenidentitäten zu SQL-Spalten;
- optional `rowOrdinalColumn`: ausdrücklich gelieferte Originalreihenfolge,
  wenn diese benötigt wird; keine erfundene Dateizeilennummer;
- optional `errorRows`: eigener Quellobjekt-/Spaltenbeschreiber nach demselben
  Vertrag für einen tatsächlich benötigten Fehlerausgang.

Alle Datenbanken stehen in der expliziten Allowlist. Vor SQL-Ausgabe gelten
die bestehenden Katalog-, Typ-, Dependency-, Identifier-, Rechte- und
NOLOCK-Prüfungen. Keine freien SQL-Fragmente, Synonym-/Linked-Server-Umgehung
oder Berechtigungserweiterung. Fehlende Mappings/Typen/Datenquellen liefern
`missing_context`; insbesondere keine leere Dummyquelle für Fehlerausgänge.
Virtuelle Dateinamenspalten benötigen ebenfalls einen expliziten Wert-/Spalten-
Ursprung. Datenprüfungen erfolgen im erzeugten Debugplan, nicht durch
unangekündigtes Lesen fachlicher Zeilen während der Metadatenanalyse.

Modelliert werden Delimited, Fixed Width und Ragged Right einschließlich
Encoding/Codepage, Locale, Separatoren, Textqualifizierer, Header/Skip-Zeilen,
Spaltenbreiten/-typen, RetainNulls, FastParse, Binärformat und Dispositionen.
Properties ohne simulierte Runtimewirkung bleiben als solche gekennzeichnet.

Für Flatfileziele entstehen die zu schreibende Spaltenprojektion, tatsächliches
Mapping und Ordinal sowie Format-, Header- und Append-/Overwrite-Metadaten.
Es gibt keine Zieldatei-DML, Serialisierung oder tatsächliche Append-/Overwrite-
Ausführung. Andere Fileprovider oder ein In-Memory-Dateiparser benötigen einen
eigenen konkreten Vertrag und Freigabe.

## Lange Ausdrücke und Datenflüsse

Die bisherigen V1-Grenzen werden nicht gelockert. V2 erhält eine zentrale,
unveränderliche und pro Aufruf ausdrücklich weitergereichte Ressourcenpolicy.
Keine globale/Thread-ambient Policy und keine Änderung eines anderen Aufrufs.

Beispiel für ausdrücklich angefordertes V2 ohne anwendungsseitige Mengencaps:

```sql
EXEC toolbelt_tsql.USP_ExplainSsisDataFlow
    @PackageBytes = @PackageBytes,
    @ProjectContext = N'{"schemaVersion":2,"resourceOptions":{
        "schemaVersion":1,"preset":"unlimited"}}';
```

Die vorhandenen optionalen `projectParameters`/`connectionManagers` können im
V2-Kontext weiterhin deklariert werden. Die Ressourcenpolicy wird separat
normalisiert und gehasht; sie ist keine Änderung fachlicher Bindings oder
deren Paket-/Projektkontextidentität.

`resourceOptions` erlaubt ausschließlich `schemaVersion: 1`, optional `preset`
(`large10x` als Default oder `unlimited`) und optional `limits` als Objekt.
Jede unten benannte Mengengrenze kann durch eine positive exakte Int64-Ganzzahl
oder die Zeichenfolge `unlimited` überschrieben werden. Null, 0, negative,
gebrochene, überlaufende, doppelte und unbekannte Werte/Keys sind Fehler.
Ein Override darf ein unbegrenztes Preset wieder gezielt begrenzen.

Die Defaults sind bewusst größer als die privat gemessenen zehnfachen
Eingabe-/Struktur-/Ausdrucksmengen; reale Paketnamen, Inhalte und Messinventare
bleiben außerhalb Git. Die SQL-NVARCHAR-zu-VARBINARY-UTF16-Darstellung wird bei
der Referenzkapazität mitberücksichtigt.

| `limits`-Schlüssel | Default `large10x` |
|---|---:|
| `packageBytes` | 134.217.728 |
| `jsonDocumentBytes` / `allJsonBytes` / `jsonNodes` | 4.194.304 / 8.388.608 / 131.072 |
| `xmlCharacters` / `xmlNodes` | 134.217.728 / 1.048.576 |
| `modelNodes` / `modelEdges` | 262.144 / 1.048.576 |
| `components` / `paths` / `columns` / `inputs` | 4.096 / 8.192 / 65.536 / 8.192 |
| `expressionBytes` (UTF-16) | 4.194.304 |
| `expressionTokens` / `expressionNodes` | 262.144 / 131.072 |
| `planUnits` | 8.192 |
| `catalogObjects` / `catalogQueries` / `parserCalls` | 4.096 / 4.096 / 32.768 |
| `artifacts` / `diagnostics` | 65.536 / 16.384 |
| `sqlArtifactBytes` / `totalOutputBytes` (UTF-16) | 2.097.152 / 134.217.728 |
| `analysisMilliseconds` | 30.000 |

Materialisierte Pläne benötigen zusätzliche Zwischenstufen sowie mehrere
Parserprüfungen je Stufe einschließlich Bereinigung. Die Plan-/Parserzähler
berücksichtigen diesen Kontrollaufwand zusätzlich zur Komponentenmenge;
die festen Schutzgrenzen einer einzelnen SQL-Prüfeinheit bleiben unverändert.

`unlimited` deaktiviert die betreffenden anwendungsseitigen Mengencaps
beziehungsweise den kooperativen Analysetimer. Es verspricht keinen unendlichen
Speicher: CLR-/SQL-Typgrößen, verfügbare Ressourcen und vom Caller gesetzte
Abbruch-/Statement-Timeouts gelten weiterhin. Die festen Schutzprüfungen für
gültiges XML/JSON, DTD-/Resolver-Verbot, Rekursion/Nesting und zulässiges SQL,
Ownership und Berechtigungen bleiben wirksam. Die Hilfe unterscheidet diese
Protokoll-/Safetygrenzen ausdrücklich von konfigurierbaren Mengencaps;
insbesondere XML-Tiefe 128, JSON-Tiefe 32 und Ausdruckstiefe 64 bleiben bestehen.
Der Ressourcen-Kontrollumschlag selbst ist endlich und strikt validiert.
Für die sichere Policyauflösung ist `@ProjectContext` als Bootstrap-Kontroll-
umschlag fest auf 4 MiB UTF-16 begrenzt, sein `resourceOptions`-Teil auf 16 KiB.
Diese ausdrücklich ausgewiesene `controlProtocolBytes`-Grenze ist unabhängig
von den konfigurierbaren Daten-JSON-Zählern. Große V2-Binding-/Catalog-JSONs
werden erst nach Policyauflösung geparst und nativ geprüft; ein entsprechend
großes Binding benötigt deshalb den expliziten ProjectContext-V2-Opt-in.
Andere V2-Daten- oder Ausgabewege behalten keine versteckte V1-Mengenkappe.

Effektive Werte, ausdrücklich unbegrenzte Zähler und Policyherkunft werden in
V2-Metadaten ausgegeben. Eine Grenzdiagnose nennt Profil, Zähler, beobachteten
Wert und effektives Maximum statt nur einer generischen „V1-Grenze“.

Graphverarbeitung erfolgt iterativ und zyklensicher innerhalb dieser Grenzen.
Lange Flüsse/Ausdrücke werden nur semantikerhaltend in begrenzte Prüfabschnitte
zerlegt. Originalausdruck, gebundene Referenzen und Zwischenwerte bleiben
nachvollziehbar. Keine ungeprüfte Textsubstitution oder Änderung von
NULL-/Branch-/Spaltenversionssemantik.

Jeder ausgegebene ausführbare Abschnitt durchläuft die vollständige bisherige
SQL-Vorfilter-/AST-/Safetyprüfung. Zusätzlich muss ein begrenzter Planprüfer
die **gesamte** Reihenfolge, Inputs/Outputs, Hashbindung, Typen, Budgets und
temporäre Ownership prüfen; nur Einzelstücke zu prüfen genügt nicht. Keine
persistenten Writes oder generische dynamische EXEC-Freigabe. Eigene #Temp-
Zwischenstände sind explizit, kollisionsgeschützt und sicher bereinigbar.
Fehlende Vorbereitung, fremder Zustand oder Drift blockieren abhängige Schritte.

Defaults und Overrides sind vor nativem Laden durch adversariale Offline- und
Grenzprüfungen sowie unabhängige Sicherheitsprüfung zu qualifizieren. Für
`unlimited` werden die deaktivierten Mengenzähler mit endlichen Testdaten
nachgewiesen; äußere Prozess-/SQL-Watchdogs und der Arbeitsrahmen bleiben in
Tests endlich. Es findet kein tatsächlich unbegrenzter Lab-/Lastlauf statt.
Zehnfache synthetische Referenzformen prüfen ausdrücklich Skalierung und
Ausführungskosten; bloß größere Konstanten ohne tragfähige Algorithmen genügen
nicht. Nicht tragfähige Schutz-/Betriebsgrenzen werden konkret gemeldet.

## Prüf- und Lieferfolge

1. Versions-/Profilauflösung und Ausdruckssemantik mit V1-Regression und
   CLR-/Hostparität; Zwischenstand als Teilabdeckung kennzeichnen.
2. Row Count, Flatfilemodell und erlaubte relationale Ersatzquellen;
   positive/negative Typ-, Kontext-, Rechte-, Fremdobjekt- und Injectionfälle.
3. Lange Pläne und Grenzen, gekoppelte versionierte Lieferung/Installer sowie
   erneuerte private Berichte und getrennte Qualifikation der neuen Bytes.

Für jede relevante Grenze gelten kleiner/exakt/größer und feste typisierte
Sollwerte. V1-Resultsets, ResultTable, Help-first, lokale/zentrale Installation,
Repeat-/Upgrade-/Consumer-/Ownershipverträge und sichere Bereinigung bleiben
betroffene Pflichtgates. Native Tests verwenden ausschließlich synthetische
Daten auf ausdrücklich ausgewählten schema-validierten Functional-Labzielen.
AuthenticatedTls bleibt ohne eigenen Nachweis `not executed`.

Ein Luna-Implementierer, Root prüft Vertrag/Sicherheit/Integration. Der vom
Benutzer genehmigte gemeinsame endliche Rahmen umfasst sechs Stunden, drei PRs
und 72 native Zielversuche einschließlich Fehlversuchen, Nachfolgern, separaten
Audits und tatsächlicher SQL-CI. Checkpoint nach 4,5 Stunden; keine neue Welle
danach. Am harten Limit nur autorisierte Safety/Bereinigung. Verbrauch und
Originalzeiten stehen privat, Kosten/Tokens sind unbekannt. Der 1h-Heartbeat
ist ausschließlich Leerlaufsicherung und endet mit Stopp/Abschluss.

Lokale Konsolen bleiben verborgen. Relevante geänderte Prüfungen lokal;
Pflichtprüfungen am exakten PR-Head, regulärer PR-Merge und tatsächliche Main-CI.
Keine Veröffentlichung, Tags, direkten Main-/Force-Pushes, Labverwaltung oder
Übernahme fremder Arbeiten. Unveränderte grüne Prüfungen werden nicht ohne
neuen Bindungs-/Gategrund wiederholt.

Der Verarbeitungsaufwand folgt den geänderten Abhängigkeiten: reine
Translator-/Planrenderer-Korrekturen lösen die betroffenen V2-Orakel aus;
Änderungen des gemeinsamen Modellkerns zusätzlich die Host-/CLR-Parität.
V1-Safetyänderungen verlangen die betroffenen V1-Gegenproben. Der vollständige
Pflichtsatz läuft am stabilen Kandidaten und auf dessen CI-Head. Die zwei
Releasebuilds sind zum Nachweis der Byte-Reproduzierbarkeit erforderlich;
historische unveränderte ZIPs werden über ihren ursprünglichen Hash gebunden.
Die drei fachlich gekoppelten Entwicklungsschritte bilden einen gemeinsamen
PR statt dreier wiederholter Paket-/CI-Qualifikationen. Es gibt einen
Luna-Implementierer und einen Root-Vertrags-/Sicherheitsreview, keine zusätzliche
Reviewkette. Rohdiagnosen und Laufzeitmesswerte bleiben privat; öffentliche
Nachweise enthalten synthetische Orakel und den tatsächlichen Prüfumfang.

## Quellen

- [Microsoft: PipelineComponentType und version-Default](https://learn.microsoft.com/en-us/openspecs/sql_data_portability/ms-dtsx2/2eebf166-6241-40c8-b1ba-08471da62fb4)
- [Microsoft: Row Count und Zuweisungszeitpunkt](https://learn.microsoft.com/en-us/sql/integration-services/data-flow/transformations/row-count-transformation)
- [Microsoft: SSIS-LEN](https://learn.microsoft.com/en-us/sql/integration-services/expressions/len-ssis-expression)
- [Microsoft: SSIS-TRIM](https://learn.microsoft.com/en-us/sql/integration-services/expressions/trim-ssis-expression)
- [Microsoft: Ausdruckstypen, innere Stringkonvertierung und Boolean](https://learn.microsoft.com/en-us/sql/integration-services/expressions/integration-services-data-types-in-expressions)
- [Microsoft: Cast und explizites Abschneiden](https://learn.microsoft.com/en-us/sql/integration-services/expressions/cast-ssis-expression)
- [Microsoft: SUBSTRING](https://learn.microsoft.com/en-us/sql/integration-services/expressions/substring-ssis-expression)
- [Microsoft: REPLACE](https://learn.microsoft.com/en-us/sql/integration-services/expressions/replace-ssis-expression)
- [Microsoft: Bedingter Operator, NULL und Zweigauswertung](https://learn.microsoft.com/en-us/sql/integration-services/expressions/conditional-ssis-expression)
- [Microsoft: Flat File Source](https://learn.microsoft.com/en-us/sql/integration-services/data-flow/flat-file-source)
- [Microsoft: Flat File Connection Manager](https://learn.microsoft.com/en-us/sql/integration-services/connection-manager/flat-file-connection-manager)
- [Microsoft: Flat File Destination](https://learn.microsoft.com/en-us/sql/integration-services/data-flow/flat-file-destination)
