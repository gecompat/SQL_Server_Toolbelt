# Entscheidungsvorlagen für die nächsten Entwicklungswellen

Stand: 2026-10-04, Codex. Status: `proposed`, Entscheidungsvorbereitung.
Keine neue Source, Assembly, Installation oder Runtime-Qualifikation.
Bestätigte Anforderungen bleiben gültig; neue Details sind separat markiert.
Ein Merge dieser Vorlage bestätigt deren Dokumentation, nicht automatisch die
Implementierung der vorgeschlagenen Objekte oder Provider.

## Auftrag, Herkunft und Priorität

Der Benutzer beauftragte nach dem sauberen Merge der bisherigen Wellen die
Besprechung weiterer Funktionen und anschließend die konkrete Ausarbeitung.
Der persönliche [Ideenpool](../../Backlog/personal_Backlog_Bainstorm.md) wurde
zuerst berücksichtigt. Seine providerübergreifende Orchestrierungsidee passt
zur Queue-Fortsetzung; Datei-/XLSX-Ideen begründen keinen neuen Dateiprovider.
Vorhandene Research-Referenzen werden wiederverwendet, keine IDs neu erfunden.

| Priorität | Vorhandene Referenz | Welle | Bestätigter Umfang |
|---|---|---|---|
| 1 | TC-2026-015 / TC-2026-046 | Queue-Worker 2 | Externer Provider bleibt; später Agent/Broker ohne duplizierte Queue; Dauerbetrieb, Registrierung, dynamische Parallelität und kontrollierter Neustart |
| 2 | RI-2026-109 | CSV | In-memory-Unicode, konfigurierbarer Separator, optionale Kopfzeile, Textzellen, ausdrücklich vereinbarte NULL-Regel |
| 3 | RI-2026-041 | JSON Pointer | Lesen und Existenz, Missing/JSON-null/SQL-NULL unterscheiden; kein Patch |
| 4 | RI-2026-076 | Safe Cast | bigint, decimal, date, datetime2, bit, uniqueidentifier; ISO-Datumsformate und strukturierte Fehler |
| 5 | RI-2026-048 | JSON Schema | Dokument und Schema explizit, strukturierte Fehler, keine externen Referenzdownloads oder Datenänderung |

Die Zustimmung „Dein Vorschlag passt“ zu CSV wurde durch die anschließende
NULL-Nachfrage nicht widerrufen. NULL-Token und Quoting wurden zusätzlich
bestätigt. Queue-Vorschläge zur Steuerung, Recovery, Neustart und Handlerzulassung
wurden ausdrücklich angenommen. Die spätere dynamische Parallelitätskorrektur
ersetzt ausschließlich die vorgeschlagene feste Acht-Slot-Obergrenze.
Konkrete APIs, Provider und zusätzliche Grenzen unten bleiben neue Vorschläge.

Nachtrag 2026-10-04, Codex: Der Benutzer bestätigte den ausdrücklich aktivierten
verwalteten Betrieb einschließlich Ablehnung direkter unverwalteter
USP_ClaimWork-Aufrufe mit „ja, freigegeben“. Der claimfreie Übergang und das
unveränderte Verhalten vor Aktivierung gehören zur gestellten und bestätigten
Frage. Diese konkrete Grenze ist damit freigegeben und nicht erneut abzufragen.
Die übrigen neuen API-/Providerdetails werden dadurch nicht pauschal genehmigt.

## Queue-Worker 2

### Bestätigte Anforderungen

Der [erste Worker](../Architecture/EXTERNAL_QUEUE_WORKER_CONTRACT.md) bleibt
der ausführende Provider. Work Types, Claimgenerationen, Lease, Retry,
Cancellation und atomarer Handler-/Complete-Abschluss werden wiederverwendet.
Kein Raw SQL, Hostscript, KILL, neues beliebiges Handlerresultset oder externer
Seiteneffekt. Agent/Broker, SSIS und Dienst-/Jobinstallation werden nicht implementiert.

### Spätere SSIS-Erweiterung – ausdrücklich außerhalb dieser Welle

Benutzerauftrag 2026-10-04: SSIS-Workerpakete sollen später Queue-Aufträge
übernehmen können, die T-SQL ausführen oder andere SSIS-Pakete mit expliziten
Parametern starten. Das erweitert die Ausführungsrichtung von SQL Server auf
SQL Server und SSIS, nicht den aktuellen Handlervertrag.
SSIS als Worker-Provider und SSIS-Pakete als zugelassene Auftragstypen sind
getrennte künftige Verträge. Gemeinsamer Admission-/Statuskern bleibt wiederverwendbar;
providerbezogene Start-/Abschluss-/Cancellation-/Recoveryadapter sind separat.
Ein Paketstart ist kein nachgewiesener Paketabschluss. Die bisherige atomare
SQL-Handler-/Complete-Transaktion wird nicht pauschal auf Paketläufe oder
externe Seiteneffekte übertragen. Keine SSIS-Source, Installation, Paket-
Registrierung oder Ausführungsfreigabe in der aktuellen Welle.

Gesamtbudget pro Installations-/Queue-Datenbank; alle Supervisoren und spätere
Provider teilen es. Erhöhung erlaubt neue Starts, Reduktion lässt aktive Arbeit
enden und blockiert neue Starts bis unter die neue Grenze. Budget 0 bedeutet
Pause der Admission, nicht Ende der Heartbeats. Supervisoren haben zusätzliche
eigene Kapazitätsgrenzen. Sichere Defaults und kleine explizite Lab-Budgets;
keine automatische Ableitung aus CPU-Zahl oder Runtimeinventar.

### Neue konkrete Steuerungs- und Ownership-Vorschläge

Eigenes T-SQL-Modul `toolbelt.core.worker-control` als Lifecycle-Einheit,
abhängig von der vorhandenen Queue. Globale Konfiguration mit
`MaxConcurrentExecutions int`, zulässig 0..2147483647, Default 1.
Keine Acht-Slot-Grenze; dieser Integerbereich ist keine Kapazitätszusage.
Neue Supervisorregistrierung erhöht niemals das Gesamtbudget.
Kapazität wird als Admissiongrenze gelesen, Ressourcen werden bedarfsweise
für tatsächlich gestartete Arbeit angelegt, nicht vorab für das ganze Budget.

Vorgeschlagene öffentliche Oberflächen im Schema `toolbelt_core`:

| Objekt | Fachliche Parameter in Reihenfolge | Ausgabe |
|---|---|---|
| USP_SetWorkerConcurrency | MaxConcurrentExecutions int=NULL; ExpectedConfigVersion binary(8)=NULL | ConfigVersion binary(8), MaxConcurrentExecutions int, OccupiedSlots bigint |
| USP_RegisterWorker | WorkerId uniqueidentifier=NULL; Capacity int=NULL | WorkerId uniqueidentifier, WorkerGeneration bigint, WorkerToken uniqueidentifier, ConfigVersion binary(8) |
| USP_HeartbeatWorker | WorkerId uniqueidentifier=NULL; WorkerGeneration bigint=NULL; WorkerToken uniqueidentifier=NULL | Kein fachliches Resultset |
| USP_SetWorkerState | WorkerId uniqueidentifier=NULL; WorkerGeneration bigint=NULL; RequestedState varchar(16)=NULL | WorkerId uniqueidentifier, WorkerGeneration bigint, State varchar(16) |
| USP_ClaimWorkerWork | WorkerId uniqueidentifier=NULL; WorkerGeneration bigint=NULL; WorkerToken uniqueidentifier=NULL | Bisherige acht Claimfelder plus SlotReservationId uniqueidentifier |
| USP_CloseWorker | WorkerId uniqueidentifier=NULL; WorkerGeneration bigint=NULL; WorkerToken uniqueidentifier=NULL | Kein fachliches Resultset |
| VW_WorkerStatus | Keine | WorkerId, Generation, ProviderKind, State, Capacity, LastHeartbeatAtUtc, OccupiedSlots; keine Tokens oder Verbindungsdaten |

Alle USPs mit fachlichem Resultset erhalten den unveränderten Standardtail
`ResultTable sysname=NULL, KeepData bit=0, Debug tinyint=0, Hilfe bit=0`.
Die anderen erhalten `Debug tinyint=0, Hilfe bit=0`. Fachliche NULL-Defaults
sind außerhalb Hilfe keine stillschweigende Zulassung. Ergebnisnullability:
die neuen genannten Felder NOT NULL; die bestehende Claimform bleibt
unverändert, insbesondere PayloadJson nvarchar(max) NULL für NONE-Handler.
Ein leerer Claim liefert keine Claimzeile.
ExpectedConfigVersion ist zum Ändern erforderlich; veraltete Version blockiert.
RegisterWorker ist nur für den implementierten EXTERNAL-Provider verfügbar;
spätere Provider werden explizit zugelassen, nicht bloß über einen freien String.
Capacity ist eine positive Integergrenze. Laufzeitänderung der lokalen Capacity
wird zusätzlich über USP_SetWorkerCapacity mit WorkerId, WorkerGeneration,
Capacity und ExpectedConfigVersion vorgeschlagen; dieselbe Drain-Semantik.

Registrierung bindet die technische Worker-ID/Generation an den vorhandenen
Callerprincipal; Tokens werden ausschließlich privat an den zuständigen
Worker geliefert. Öffentliche Statussicht enthält keine Hostnamen, Principals,
Pfade, Payloads oder Tokens. Steuer- und Dispatchrechte sind getrennt;
vorhandene Berechtigungen werden geprüft, niemals automatisch erteilt.
ADMIN-Steuerung verlangt keinen fremden WorkerToken, aber explizite Steuerrechte.

Zustände ACTIVE, PAUSED, DRAINING, UNREACHABLE und CLOSED betreffen nur
Supervisoren, nicht die vorhandene WorkItem-Zustandsmaschine. ACTIVE erlaubt
Admission; PAUSED erlaubt spätere Reaktivierung; DRAINING wird erst nach
nachgewiesenem Ende aller eigenen Slots geschlossen. Vorschlag:
Registrierungsheartbeat 15 Sekunden, Nichterreichbarkeit nach 60 Sekunden,
SQL-UTC als Zeitquelle. Bereits abgelaufene Generation wird nicht wiederbelebt.
Neue Generation nach Neustart übernimmt keine alten Claims oder Reservierungen.

### Atomare Admission und Übergang alter Caller – neue Vertragsgrenze

Eine rein lokale Slotprüfung genügt nicht. Reservierung und Queueclaim müssen
unter einer gemeinsamen kurzen SQL-Transaktion entweder beide wirksam werden
oder beide ausbleiben; Scheduler-/Admissionlocks besitzen eine feste Reihenfolge.
Die kanonische Claimauswahl wird extrahiert/reverwendet, nicht kopiert.
Ein Slot zählt ab Admission bis zum nachgewiesenen Ende bzw. zur ausdrücklich
geprüften Recovery, einschließlich unbekannter Ausgänge. Budgetsenkung darf
OccupiedSlots vorübergehend über dem neuen Budget lassen, aber nie neue Starts.

Einzeln freigegeben am 2026-10-04: Opt-in für verwalteten Betrieb. Solange er nicht aktiviert ist,
bleibt der alte direkte USP_ClaimWork-Vertrag bestehen. Aktivierung verlangt
einen nachgewiesen claimfreien Übergang; danach lehnt direkter unverwalteter
Claim ab. Andernfalls wäre die globale Garantie umgehbar.
Diese zusätzliche öffentliche Queue-/Upgradegrenze ist damit bestätigt;
die technische Ausarbeitung bleibt an die übrigen konkreten API-/Ownership-
und Recoveryverträge gebunden. Keine rückwirkende Änderung des laufenden Systems.

Weiterhin vorgeschlagen: Deaktivierung nur ohne belegte Reservierungen/Claims;
keine automatische Rückkehr zum alten Pfad. Diese Deaktivierungsbedingungen
sind nicht Bestandteil der oben bestätigten Freigabe.

Ausfall/Leaseablauf allein beweist nicht Handlerende. Keine automatische
Slotfreigabe aufgrund Registrierungs- oder WorkItem-Leaseablaufs; UNKNOWN zählt
weiter. Explizite Recovery muss alte Ausführung und ihren Commit-Ausgang klären;
vor Source benötigt dieser Recoverypfad einen eigenen Beweis-/APIvertrag.
Eine bloße Confirm-Option oder Session-ID ist kein ausreichender Beweis.
Uninstall/Upgrade schützt aktive/ungeklärte Registrierung und persistente Daten.
Kein automatisches Löschen, Claimübernehmen oder Slotfreigeben.

Dauerbetrieb als expliziter RunMode CONTINUOUS neben BOUNDED. In CONTINUOUS
wird nach leerem Claim weiter gepollt; Stop/Drain bleibt kooperativ. In BOUNDED
bleiben vorhandene Laufgrenzen erhalten. Konfigurationsänderungen werden vor
jeder Admission wirksam geprüft; keine lokal zwischengespeicherte Überbuchung.
Lange synchrone Commits dürfen andere Heartbeats nicht verdeckt stoppen;
benötigt einen isolierten Provider-Ausführungspfad und eigenen Fault-Nachweis.
Die bestehenden acht Slots sind historische Welle-1-Grenze, kein Welle-2-Limit.

Abnahme: zwei Supervisoren unter kleinem globalen Budget; Erhöhung/Reduktion/0
während langer Handler; konkurrierende Updates und Claims; alte Caller im
Opt-in/Legacy-Modus; verlorene Generation, ungeklärter Commit, Drain/Neustart;
Rechte-/Sichtschutz und datenwahrendes Upgrade/Uninstall. Größere Budgetwerte
offline prüfen, nicht entsprechend viele Handler auf kleinen Labzielen starten.
Agent/Broker können denselben Admissionkern nutzen; ihre Start-/Transaktions-
und Sicherheitsadapter erfordern später eigene Qualifikation.
[Broker-Aktivierung](https://learn.microsoft.com/en-us/sql/t-sql/statements/alter-queue-transact-sql?view=sql-server-ver17)
hat eine eigene Readergrenze und ersetzt keine providerübergreifende Admission.

## CSV – konkrete neue API- und Provider-Vorschläge

Bestätigt: ein konfigurierbarer Separator, optionale Kopfzeile, Unicode-Text
im Speicher und Textwerte; kein automatisches Casting, Datei-I/O oder Streaming.
NULL-Token optional; unquoted exakter Token ist SQL-NULL, quoted Token ist Text.
Leeres Feld/quoted leer ist leerer Text. Kein Trimmen. Writer quoted wörtliche
Tokenwerte; bei ausgeschaltetem Token weist er SQL-NULL zurück.

Vorschlag `toolbelt.file.csv-memory`, eigene portable SAFE-Assembly ohne
Drittanbieterpakete, ein kanonischer Scanner/Writer. T-SQL als Alternative
vermeidet Trust, macht zustandsbehaftete Quote-/Zeilenanalyse bei großen Texten
aber aufwendiger; keine gemessene Performanceüberlegenheit wird behauptet.
CLR-Auswahl benötigt eigene Freigabe, Framework-/IL-/SQL-Nachweise und exakte
Hash-/Trust-Opt-in-Verträge. Kein Ausbau des XLSX- oder ZIP-Providers.

Vorgeschlagene APIs im Schema `toolbelt_file`:

- USP_ParseCsv: Text nvarchar(max)=NULL, Separator nvarchar(2)=N',',
  HasHeader bit=0, NullToken nvarchar(128)=NULL, MaxRows bigint=100000,
  MaxColumns int=1024, MaxCells bigint=1000000, MaxInputBytes bigint=16777216,
  danach der unveränderte ResultTable-/KeepData-/Debug-/Hilfe-Standardtail.
- USP_WriteCsv: CellsTable sysname=NULL, Separator nvarchar(2)=N',',
  HasHeader bit=0, NullToken nvarchar(128)=NULL, LineEnding varchar(4)='CRLF',
  MaxRows bigint=100000, MaxColumns int=1024, MaxCells bigint=1000000,
  MaxValueBytes bigint=16777216, MaxOutputBytes bigint=16777216,
  danach derselbe Standardtail.

Neue Obergrenzen sind die genannten Defaults, je Aufruf nur absenkbar.
Parser zählt UTF-16-DATALENGTH einschließlich Kopfzeile; Writer begrenzt
zusätzlich den Snapshot seiner Eingabezellen und die vollständige Ausgabe.
Zellenbudget umfasst HEADER und DATA. SQL-NULL als ganzer Parsertext ist
Argumentfehler, nicht leere Datei. Leerer Text liefert null Zellen; einzelner
Zeilenumbruch einen leeren Einspaltenrecord, Abschlusszeilenumbruch keinen
zusätzlichen Record. Keine Kommentare oder übersprungenen Leerzeilen.

Ein gemeinsames ResultTable-kompatibles Zellresultset:
RowKind varchar(6) NOT NULL (HEADER/DATA), RowOrdinal bigint NOT NULL
(HEADER=0, DATA ab1), ColumnOrdinal int NOT NULL (ab1), Value nvarchar(max) NULL.
Damit bleibt es bei einem fachlichen Resultset; Kopfzeile ist separat markiert.
Writer liest dieselbe rechteckige vier-spaltige caller-lokale Temp-Form,
Snapshot vor Ausgabe. Ordinals vollständig/positiv ohne Lücken/Duplikate;
Kopfzeile vollständig oder abwesend entsprechend HasHeader. Headerwerte sind
Text, NULL-Token gilt nur für DATA; leere/doppelte Headernamen bleiben erhalten.
Writerresultat: CsvText nvarchar(max) NOT NULL, DataRows bigint NOT NULL,
ColumnCount int NOT NULL; leere Zellmenge ohne Header ergibt leeren Text/0/0.

Separator exakt ein UTF-16-Zeichen, weder Quote, CR/LF, NUL noch Surrogate.
Quote fest U+0022, Verdoppelung als Escape; CRLF/LF als Recordgrenze akzeptiert,
einzelnes unquoted CR ungültig. Writer CRLF oder LF, Default CRLF, mit finalem
Recordabschluss für nichtleere Ausgabe. Quoted CR/LF bleibt Teil des Werts.
Whitespace nach schließendem Quote ist Fehler, nicht implizites Trimmen.
NullToken 1..128 UTF-16-Einheiten, ohne Separator/Quote/CR/LF/NUL und unpaired
Surrogate; byteexakter Vergleich einschließlich trailing spaces.
Fehlerhafte Quotes/Form/Budgets führen vor Ausgabe oder ResultTable-Mutation
zum vollständigen Abbruch. Kein Teil-PASS, keine automatische Formkorrektur.

Abnahme: Parse/Write-Roundtrip für Token/NULL/leer/Quote/Separator/Unicode,
Header/CRLF/LF/embedded breaks, rechteckige Fehlerfälle, Limits und atomare
ResultTable-Ausgabe, Clientmetadaten und Lifecycle. Keine neue volle Versionsmatrix.
[RFC 4180](https://www.rfc-editor.org/rfc/rfc4180) ist Referenz für CSV-Quoting;
Separatorwahl, LF und NULL-Token sind ausdrücklich Toolbelt-Dialekt.

## JSON Pointer – konkrete Vorschläge

RI-2026-041; Lesen/Existenz ist bestätigt. Empfehlung reines T-SQL mit
OPENJSON auf SQL Server2019+, CL150+, ohne neue Assembly.
TVF_ResolveJsonPointer im Schema toolbelt_json: Json nvarchar(max),
Pointer nvarchar(max), MaxInputBytes bigint=16777216, MaxDepth int=128.
Genau eine Zeile: Status varchar(16) NOT NULL, JsonType varchar(8) NULL,
Value nvarchar(max) NULL, ErrorCode varchar(32) NULL. Kein eigener SVF-Wrapper.

FOUND, MISSING, JSON_NULL, SQL_NULL oder INVALID; diese detaillierte Statusform
ist neuer Vorschlag. Value liefert decodierten String, Zahlenliteral,
true/false oder JSON-Text für Object/Array; bei Missing/null/Invalid SQL-NULL.
Type unterscheidet STRING/NUMBER/BOOLEAN/OBJECT/ARRAY/NULL und ist bei
FOUND/JSON_NULL vorhanden. Status ist maßgeblich, kein NULL-only-Fehlervertrag.

[RFC 6901](https://www.rfc-editor.org/rfc/rfc6901): Stringform, kein URIfragment
oder SQL-JSON-Path; leerer Pointer adressiert die Wurzel. Escape ~1 vor ~0
decodieren, sonstiges ~ ist ungültig. Objektkeys exakt Unicode, ohne
Collationfaltung/Normalisierung; leeres Keytoken erlaubt. Arrays nur0 oder
positive Dezimalindizes ohne führende Nullen; '-' liefert MISSING, kein Append.
Pointergrenze 4000 UTF-16-Einheiten, Dokumenttiefe128. SQL-NULL in einem Input
ergibt SQL_NULL vor weiteren Prüfungen; sonst vollständige Syntaxprüfung.
Ungültiges JSON/Pointer oder Budgetüberschreitung ist INVALID mit stabilem Code.
Passende doppelte Objektkeys ergeben INVALID; kein first/last wins.
Top-level scalars sind zu unterstützen, nicht durch ISJSON ohne Typconstraint
falsch abzulehnen. Unicode-/Engine-Parsergrenzen vor Source konkret prüfen.

Abnahme: RFC-Beispiele, Escapes/leer/0/führendeNullen/'-', case/trailing spaces,
Duplicatekey, Scalarroot und Missing/null; Clientmetadata, Budgets/Lifecycle.
Kein JSON Patch, Schreibzugriff oder ungeprüfte Standardkonformitätszusage.

## Safe Cast – konkrete Vorschläge

RI-2026-076; sechs Zieltypen/ISO-Formate bestätigt. Empfehlung sechs echte
inline-T-SQL-TVFs im Schema toolbelt_conversion: TVF_TryCastBigInt,
TVF_TryCastDecimal, TVF_TryCastDate, TVF_TryCastDateTime2, TVF_TryCastBit,
TVF_TryCastUniqueIdentifier. Je Text nvarchar(max), MaxInputBytes int=8192.
Neue feste Decimalform decimal(38,18); datetime2(7). Dynamische Präzision/Skala
würde den statisch typisierten Output verändern und gehört nicht in diese API.
Resultat je genau eine Zeile: Value im Zieltyp NULL, Status varchar(16) NOT NULL,
ErrorCode varchar(32) NULL. Kein Input-Echo, keine originale Enginefehlermeldung.

Vorgeschlagene Statuswerte OK, SQL_NULL, EMPTY, INVALID_FORMAT, OUT_OF_RANGE,
LOSSY und LIMIT. Fehler liefern Value=NULL, OK einen typisierten Wert;
SQL_NULL liefert keinen Fehlercode. Kein stilles Runden/Abschneiden/Ersetzen.
SQL-NULL ist vor Argumentprüfung SQL_NULL; leere Zeichenfolge EMPTY, Whitespace
INVALID_FORMAT. Bigint optional ASCII-Vorzeichen plus Ziffern; Decimal zusätzlich
Punkt mit Ziffern davor/dahinter. Kein Exponent, Locale, Tausendertrenner oder Trim.
Nichtnull Nachkommastellen jenseits Skala18 sind LOSSY; überzählige Nullstellen
dürfen exakt entfallen. Datum YYYY-MM-DD; datetime2 YYYY-MM-DDTHH:mm:ss mit
optional1..7 Nachkommastellen, keine Zeitzone/implizite Offsetentfernung.
Bit nur0/1; GUID kanonisch36 Hex-/Bindestrichzeichen, upper/lower zulässig,
keine Braces oder Trunkierung. Lexikalisch gültige Werte außerhalb des Ziel-
Wertebereichs ergeben OUT_OF_RANGE. Parameter/Budgets werden ohne gefährliche
vorzeitige CONVERT-Auswertung geprüft; SQL-Optimizerverhalten gehört zur Abnahme.

Abnahme: lexical-vs-native-Konversionsabweichung, Min/Max, Verlustgrenzen,
Language/DATEFORMAT/Collations, TVF im APPLY, Outputtypen und Lifecycle.
Die strikte Lexik und festen Decimal-/Datumdetails sind noch freizugeben.

## JSON Schema – Draft, Umfang und Providerentscheidung

RI-2026-048 ist bereits vorhanden. Bestätigt sind explizites Schema/Dokument,
strukturierte Pfade/Codes, kein Netzwerk-$ref, keine Defaults/Coercion und
keine automatische Integration in Work-Type-Registrierung.
Empfehlung erster Scope: ausdrücklich begrenztes Profil mit Draft-2020-12-
Semantik für unterstützte Keywords, keine vollständige Draftkonformitätszusage.
Das Profil ist eine Toolbelt-Einschränkung und muss im Ergebnis sichtbar sein.

Neue API toolbelt_json.USP_ValidateJsonSchema: Json nvarchar(max)=NULL,
Schema nvarchar(max)=NULL, Profile varchar(32)='toolbelt-2020-12-v1',
MaxDocumentBytes bigint=16777216, MaxSchemaBytes bigint=1048576,
MaxDepth int=128, MaxEvaluationSteps bigint=1000000, MaxErrors int=100,
danach der unveränderte ResultTable-/KeepData-/Debug-/Hilfe-Standardtail.
Das Resultset enthält eine SUMMARY-Zeile und0..MaxErrors ERROR-Zeilen mit
RowKind varchar(8), ErrorOrdinal int, Status varchar(24), Profile varchar(32),
IsValid bit NULL, DocumentPointer nvarchar(max) NULL,
SchemaPointer nvarchar(max) NULL, Keyword nvarchar(128) NULL,
ErrorCode varchar(32) NULL, ErrorsTruncated bit; RowKind/Ordinal/Status/Profile/
ErrorsTruncated NOT NULL. Kein Payload-/Werteecho. SUMMARY zuerst nur über
explizite Sortierung; Status und Profil sind je Zeile konsistent.

IsValid=1 nur nach vollständig erfolgreicher Evaluation im angegebenen Profil;
0 nur bei bewiesener Datenverletzung, sonst NULL. Status VALID/INVALID_INSTANCE,
INVALID_SCHEMA/INVALID_JSON/UNSUPPORTED/LIMIT/SQL_NULL. Fehlergrenze beschränkt
Diagnostik, niemals stillschweigend Validierung; ErrorsTruncated macht Kürzung
sichtbar. Evaluationbudget ohne vollständiges Urteil liefert LIMIT/NULL.
Profile/default/Parameterfehler werfen vor ResultTable-Mutation; Dokument-/
Schemafachfehler sind Status. Help umgeht alle fachlichen Eingaben.

Neuer V1-Vorschlag: Boolean-Schemas; $schema für den festgelegten Draft,
$defs und nichtrekursive lokale Fragment-$ref; type, required, properties,
additionalProperties, items, prefixItems, min/maxItems, min/maxProperties,
min/maxLength sowie numerische minimum/maximum/exclusiveMinimum/exclusiveMaximum.
title/description/$comment als erlaubte Annotationen ohne Datenänderung.
Keywordprüfung erfolgt nur an Schemaorten, nicht an Propertynamen oder Textwerten.
Das vollständige Schema wird vor Instanzprüfung auf Syntax/Profil geprüft,
auch unerreichte Subschemas. Nicht unterstützte Keywords, Referenzzyklen,
externe refs, andere Drafts, format, pattern, uniqueItems, multipleOf,
enum/const, allOf/anyOf/oneOf/not, if/then/else, unevaluated* und dynamic refs
liefern UNSUPPORTED statt eines scheinbaren PASS. Fehlendes $schema wird nur
durch das explizite Profile interpretiert, nicht heuristisch erraten.

Duplicatekeys in Dokument/Schema werden abgelehnt; Unicode-Länge zählt Scalars,
Zahlenvergleiche sind exakt dezimal, nicht float(53). Dies sind erhebliche
Provideranforderungen. Keine Ableitung eines fertigen Providers aus bestehenden
JSON-USPs oder aus einer allgemeinen .NET-Framework-Kompatibilitätsangabe.

| Alternative | Primärquellenbefund / Bewertung | Empfehlung |
|---|---|---|
| Eigener begrenzter SAFE-CLR-Kern | Keine neue Drittanbieterabhängigkeit, aber eigener exakter JSON-/Zahlen-/Profilvalidator und zusätzlicher Trust-/Assemblyvertrag nötig; keine Laufzeitmachbarkeit geprüft | Für V1-Profil bevorzugte zu prüfende Option, separat freizugeben |
| T-SQL-Profil | Kein CLR, dafür Scalar-Länge/JSON-Parser/Zahlengenauigkeit und vollständige bounded Evaluation schwierig; keine Performancebelege | Alternative, vor Source Machbarkeit entscheiden |
| JsonSchema.Net | [Projektdatei](https://github.com/json-everything/json-everything/blob/master/src/JsonSchema/JsonSchema.csproj) nennt netstandard2.0 und weitere Targets sowie Paket-EULA; [README](https://github.com/json-everything/json-everything#project-funding--sponsorship) unterscheidet Bedingungen für Binärpakete | Kein SQL-CLR-/SAFE-Nachweis; exakte Version, Paket-/Source-Rechte und Dependencyclosure ungeklärt, nicht ausgewählt |
| Newtonsoft.Json.Schema | [Lizenz](https://github.com/JamesNK/Newtonsoft.Json.Schema/blob/master/LICENSE.md) AGPL oder kommerziell; [Projektdatei](https://github.com/JamesNK/Newtonsoft.Json.Schema/blob/master/Src/Newtonsoft.Json.Schema/Newtonsoft.Json.Schema.csproj) mit Frameworktargets | Kein geprüfter Lizenz-/Redistributions-/SAFE-Vertrag, nicht ausgewählt |
| Externer Validator | Eigene Runtime-/Datentransfer-/Handlergrenze, nicht durch bisherigen Worker freigegeben | Separate spätere Welle |

[Core](https://json-schema.org/draft/2020-12/json-schema-core) und
[Validation](https://json-schema.org/draft/2020-12/json-schema-validation)
wurden am2026-10-04 gelesen. Unbekannte Keywords als UNSUPPORTED sind die
ausdrückliche strenge Toolbelt-Profilregel; keine Behauptung, der Standard
fordere generell deren Ablehnung. format als Annotation und format als Assertion
sind zu unterscheiden; V1 unterstützt beides nicht und meldet das explizit.
Keine Bibliothek heruntergeladen, kopiert, installiert oder qualifiziert.

Abnahme: positive/negative Fälle je unterstütztem Keyword, kompletter
Unsupported-Preflight, ref-/Zyklus-/Depth-/Evaluation-/Fehlergrenzen, exakte
große Zahlen/Unicode, keine Datenänderung oder Netzwerkauflösung,
ResultTableatomik, Clientmetadaten und Lifecycle. Voller Draft und Work-Type-
Integration bleiben eigene Vertragswellen, kein „später still einschalten“.

## Noch zu entscheiden und nächster Schritt

1. Queue: konkrete neue Steuerungs-/Claim-APIs, Versionsvergleich und
   15/60-Sekunden-Registrierungstiming. Managed-Opt-in und Legacy-Claim-Gate
   sind seit dem Nachtrag einzeln bestätigt und nicht erneut abzufragen.
   Recoverybeweis/-API separat konkretisieren, bevor Recovery implementiert wird.
2. CSV: eigene SAFE-Assembly, genau zwei USPs, markierte Headerzeilen und die
   vorgeschlagenen Größen-/Zellenobergrenzen.
3. JSON Pointer/Safe Cast: genaue TVF-Outputs, strikte Lexik, Decimal38/18,
   Grenzen und Statusdetails. T-SQL ist Empfehlung, keine bereits gebaute API.
4. JSON Schema: begrenztes V1-Profil oder umfassendere Draftanforderung;
   Providerprüfung/-freigabe vor Source. Diese Wahl ist keine erneute Frage
   zur bereits bestätigten grundsätzlichen Schema-Prüfung.

Jede implementierte Welle bleibt eigener Branch/PR mit unabhängiger Prüfung,
betroffenem Lab-Scope und exakter Head-CI. Erfolgreiche bestehende Prüfungen
werden bei unverändertem Scope nicht pauschal wiederholt. In dieser
Entscheidungsvorbereitung sind SQL-/CLR-Runtime-Tests `not applicable`;
alle vorgeschlagenen neuen Funktionen haben Runtime-Nachweis `not executed`.
