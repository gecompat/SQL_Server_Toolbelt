# Entscheidungsvorlagen für die nächsten Entwicklungswellen

Stand: 2026-10-04, Codex. Queue-Worker 2: `ready for development` nach
nachfolgend dokumentierter Einzelfreigabe; weitere Wellen: `proposed`.
Runtime-Nachweis der neuen Wellen: `not executed`.
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
Die konkrete Queue-Steuerung wurde in der ergänzenden Besprechung freigegeben;
die Details der anderen Wellen bleiben unten als neue Vorschläge gekennzeichnet.

Nachtrag 2026-10-04, Codex: Der Benutzer bestätigte den ausdrücklich aktivierten
verwalteten Betrieb einschließlich Ablehnung direkter unverwalteter
USP_ClaimWork-Aufrufe mit „ja, freigegeben“. Der claimfreie Übergang und das
unveränderte Verhalten vor Aktivierung gehören zur gestellten und bestätigten
Frage. Diese konkrete Grenze ist damit freigegeben und nicht erneut abzufragen.
Die übrigen neuen API-/Providerdetails werden dadurch nicht pauschal genehmigt.

## Queue-Worker 2

### Bestätigte Anforderungen

Umsetzungsfreigabe 2026-10-04 nach ergänzender Vertragsbesprechung:
zentrale SQL-Steuerung mit getrennten APIs und Versionsvergleich;
konfigurierbare Registrierungsintervalle mit 15/60 Sekunden als Default;
kontrollierter Übergang einschließlich ausdrücklich angeforderter
Deaktivierung ohne aktive/ungeklärte Claims oder Reservierungen.
Intervalländerungen gelten nur für neue Generationen; registrierte
Generationen behalten ihre Werte. Der Benutzer beauftragte anschließend
ausdrücklich die autonome Umsetzung „wie von dir vorgeschlagen“.

Sofortstopp ist separat vom Drain bestätigt: einzelne konkrete Verarbeitung
mit Claim-Generation oder mehrere/alle Worker. Stop-/Hold-Disposition vor
Abbruch dauerhaft sichern; alle automatischen Wiederanlaufpfade ausschließen.
Erst bestätigtes Ende und Rollback erlauben Slotfreigabe; unklar bleibt gesperrt.
Commit gewinnt bedeutet Erfolg, nicht nachträglich fingierter Rollback.
Nach bestätigtem Abbruch bleibt der Auftrag bis zur expliziten Wiederfreigabe
erkennbar zurückgehalten; neuer Versuch durch jeden geeigneten Worker,
Historie erhalten und korrigierter registrierter Handler neu geprüft.
Einzelstopp sperrt nur den Auftrag; Workergruppen-/Gesamtstopp sperrt auch
neue Starts bis zur ausdrücklichen Reaktivierung. Keine Raw-SQL-Erweiterung.
Providerbezogener Abbruch und Konsistenznachweis bleiben getrennt;
keine externen Effekte pauschal durch SQL-Transaktionen als rückgängig behaupten.

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

### Freigegebene Steuerungs- und Ownership-Richtung

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
Konfigurierbarer Registrierungsheartbeat mit Default 15 Sekunden und
Nichterreichbarkeit mit Default 60 Sekunden, SQL-UTC als Zeitquelle.
Registrierte Generationen behalten ihre Intervalle; Konfigurationsänderungen
gelten für neue Generationen. Bereits abgelaufene Generation wird nicht wiederbelebt.
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

Nach ergänzender Besprechung ebenfalls freigegeben: kontrollierte Deaktivierung
sperrt zuerst neue Starts, lässt Arbeit enden und wird nur ohne belegte oder
ungeklärte Reservierungen/Claims abgeschlossen; keine automatische Rückkehr
zum alten Pfad. Diese spätere Freigabe erweitert die frühere Opt-in-Bestätigung.

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

1. Queue: autonome Umsetzung der bestätigten zentralen Steuerungs-/Claim-APIs,
   Versionsprüfung, konfigurierbaren Intervalle mit Defaults 15/60 und
   generationserhaltenden Änderungen. Managed-Opt-in, Legacy-Claim-Gate,
   kontrollierte Deaktivierung und Sofortstopp mit Hold/explicit release sind
   einzeln bestätigt und nicht erneut abzufragen. Technische Fencing-/
   Recoverybeweise konkretisieren; UNKNOWN niemals durch Bestätigung allein
   freigeben. Weitere fachliche Vertragsausweitung bleibt separat.
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

## Technische Vorprüfung 2026-10-05

Der erneute Benutzerauftrag verlangt autonome Entwicklung und Analyse bis zum
ausdrücklichen Stopp oder bis ohne konkreten Benutzerinput keine sinnvolle
autorisierte Arbeit möglich ist. Eine ausstehende Sourceentscheidung beendet
deshalb keine unabhängige Vorprüfung. Die folgenden Empfehlungen ergänzen die
bestehenden Vorschläge; sie behaupten weder eine neue Funktions-/Providerfreigabe
noch eine implementierte öffentliche API. Frühere Zustimmungen bleiben gültig.

### CSV: Transport, vollständige Prüfung und Ressourcen

Der Writer muss die caller-lokale Zellmenge zuerst typgenau prüfen und in einen
privaten geordneten Snapshot übernehmen. Ein SQL-Tabellentyp ist kein direkter
CLR-Transport: Microsoft schließt dessen Übergabe an Managed-Routinen im
SQL-Server-Prozess aus. Ebenso wird eine CLR-TVF inkrementell konsumiert;
direkte Ausgabe wäre daher kein Beweis gegen einen späten Parserfehler.
[CLR-TVF- und TVP-Vertrag](https://learn.microsoft.com/en-us/sql/relational-databases/clr-integration-database-objects-user-defined-functions/clr-table-valued-functions?view=sql-server-ver17)

Empfehlung innerhalb des vorgeschlagenen eigenen Providers: ein kanonischer
per-cell-Quotingkern mit internem skalarem Transport und vollständiger
T-SQL-Zusammensetzung aus dem Snapshot. Alternativ ist ein begrenztes
Binary-Envelope möglich; dessen Metadaten und Kopien brauchen ein eigenes
internes Budget. Keine implizite Context Connection, kein beliebiger SQL-Text
und keine zusätzliche öffentliche Helper-API. Die tatsächliche Wahl und ihre
Build-/IL-/SQL-Nachweise gehören zum Vor-Source-Vertrag.

Parserausgabe vollständig privat konsumieren und Form-/Ressourcenprüfung
abschließen, bevor ein öffentliches SELECT oder eine ResultTable-Mutation
beginnt. Vorbereitung und Insert verwenden den bestehenden
[Transaktionsvertrag](../Architecture/DECISIONS.md#dec-2026-016-savepoint-fähiger-transaktionsvertrag-und-zentrale-verwendbarkeit).
Abnahme umfasst späte Quote-/Budgetfehler und einen erst beim Zielinsert
fehlschlagenden Constraint; Caller-Transaktion und bestehende Zielwerte bleiben
gemäß dem geltenden USP-Vertrag erhalten.

Vorgeschlagene präzise Zählweise: MaxRows zählt DATA-Records; HEADER zählt
gegen MaxCells und besitzt dieselbe Spaltenzahl. Header-only ergibt DataRows0.
Vor LOB-Kopien zuerst Zell-/Recordzahl prüfen. Writer-Outputcharge umfasst
UTF-16-Werte, Quoteverdoppelungen, Quotehüllen, Separatoren und Recordabschlüsse;
alle Additionen vor Allokation auf Überlauf und Grenzen prüfen. Eine Million
leere Zellen benötigt weiterhin Zeilen-/Metadatenspeicher: 16MiB Text ist keine
16MiB-Heapzusage. NULL-Tokenvergleich benötigt gleiche Länge und exakte
Codeeinheiten; SQL-Vergleichspadding darf Text nicht zu NULL machen.

Der vorgeschlagene Scanner hat FieldStart-, Unquoted-, Quoted- und AfterQuote-
Zustände. Synthetische Abnahmefälle: leerer Input, `""`, `,`, `a,`, `"a"x`,
`a"b`, Quoted-CR/LF, CRLF, EOF im offenen Quote, Token als quoted Text,
Token mit trailing spaces und unterschiedlich breite Records. Leere Felder
und Quoteverdoppelung folgen der [RFC-4180-Grammatik](https://www.rfc-editor.org/info/rfc4180/);
Separatorwahl, LF und NULL-Token bleiben der ausdrücklich beschriebene Dialekt.
Eine zusätzliche Ablehnung von NUL oder ungepaarten Surrogaten in Zellwerten
ist bisher nicht festgelegt und wird nicht stillschweigend eingeführt.

### JSON Pointer: sichere Engine-Nutzung

SQL2019 besitzt den neueren ISJSON-Typconstraint noch nicht. Für Scalarroots
ist ein künstlicher Arraywrapper mit zusätzlichem Nachweis genau eines Elements
prüfbar; allein ISJSON würde auch die ungültige Dokumentfolge `1,2` in `[1,2]`
verpackt akzeptieren. Originalbudget vor dem Wrapping prüfen, die künstliche
Containerstufe nicht zur Dokumenttiefe zählen.
[ISJSON-Version und Rückgabevertrag](https://learn.microsoft.com/en-us/sql/t-sql/functions/isjson-transact-sql?view=sql-server-ver17)

Erst nach sicherem vollständigem Syntaxpreflight OPENJSON verwenden. Eine
selektive Pfadauflösung ersetzt keinen Scan aller Dokumentzweige für Tiefe und
eine gegebenenfalls vereinbarte Unicode-Regel. Ein begrenzter lexikalischer
Scan berücksichtigt Strings, Escapes und rohe beziehungsweise escaped
Surrogatpaare; ein Providerwechsel ist daraus nicht bewiesen. Die relationale
Alternative ist vor einer MSTVF gemäß T-SQL-Regeln zu prüfen.

OPENJSON-Defaultwerte vermeiden JSON_VALUE-Längengrenzen; passende doppelte
Keys werden nach Escape-Decoding gezählt. Exakter Keyvergleich braucht BIN2
und gleiche DATALENGTH. Dokumentkeys über4000 Einheiten werden im geprüften
Enginekontext gekürzt. Der vorgeschlagene vollständige Pointerdeckel4000
begrenzt wegen des Slash jedes adressierende Token auf höchstens3999 Einheiten;
Tilde-Decoding verlängert es nicht. Zusammen mit dem Längenvergleich verhindert
dies in den unten geprüften Trunkierungsfällen einen falschen Präfixtreffer.
Keine zusätzliche globale Dokumentkeygrenze aus dieser Teilprüfung ableiten.
[OPENJSON-Metadaten und Fragmentverarbeitung](https://learn.microsoft.com/en-us/sql/t-sql/functions/openjson-transact-sql?view=sql-server-ver15)

Arrayindexlexik erst bei einem tatsächlichen Array anwenden: `01`, `x` und `-`
können Objektkeys sein. Ein beliebig großer syntaktisch gültiger Dezimalindex
kann gegen die begrenzte Arraykardinalität geprüft werden; bigint-Überlauf
allein ist kein Pointer-Syntaxfehler. Noch konkret vorzulegen: Status für
Weiterlaufen durch Scalar/null und ungültige Arrayindexform, Rootdepth und
Unicode-Regel. RFC6901 überlässt die Fehlerfolgen der Anwendung.
[RFC6901](https://www.rfc-editor.org/rfc/rfc6901),
[RFC8259: Unicode-Grenzen](https://www.rfc-editor.org/rfc/rfc8259#section-8.2)

### Safe Cast: Lexik vor nativer Konversion

Jeder Konversionsausdruck muss auch bei früher Optimizer-Auswertung sicher
sein; ausschließlich TRY_CONVERT auf die sechs zulässigen Zieltypen verwenden.
Lexik und Verlustfreiheit separat prüfen. CASE/CTE/APPLY sind keine allgemeine
Barriere gegen gefährliche Konversionen.
[TRY_CONVERT](https://learn.microsoft.com/en-us/sql/t-sql/functions/try-convert-transact-sql?view=sql-server-ver17),
[CASE-Auswertungsgrenzen](https://learn.microsoft.com/en-us/sql/t-sql/language-elements/case-transact-sql?view=sql-server-ver17)

Decimal38/18 hat höchstens20 Ganzzahlstellen; vor Konversion signifikante
Ziffern und den Nachkommarest prüfen. Native Skalenreduktion kann runden.
19. Nachkommastelle0 gegenüber1, 21 signifikante Ganzzahlstellen, negative0
und kombinierter Bereichs-/Verlustfehler sind getrennte Abnahmefälle.
GUID benötigt exakt36 Zeichen und feste Bindestrich-/Hexpositionen; native
Konversion allein qualifiziert die vorgeschlagene strenge Form nicht.
Für `99999999999999999999.9999999999999999991` ist OUT_OF_RANGE vor LOSSY
der vorgeschlagene Abnahmeausgang: die Ganzzahllänge allein erkennt die
Überschreitung des exakten Decimal-Maximalwerts nicht.
[decimal/numeric](https://learn.microsoft.com/en-us/sql/t-sql/data-types/decimal-and-numeric-transact-sql?view=sql-server-ver17)

Empfehlung zur noch offenen Fehlerpriorität: SQL_NULL, ungültiges Budget,
LIMIT, EMPTY, Lexik, exakter Bereich, LOSSY, OK. Negative/NULL/0/über8192
liegende Budgets benötigen einen eigenen stabilen Parametercode. Diese Tabelle
ist vorgeschlagen, kein eingefrorener öffentlicher Vertrag. Kalenderfehler,
Bit2, Whitespace/NUL und überlange GUIDs erhalten explizite Fixtures.

### JSON Schema: begrenzter exakter Evaluationskern

System.Numerics gehört nicht zur automatisch unterstützten SQL-CLR-
Bibliotheksliste. Ein BigInteger-basierter Kern ist dadurch weder automatisch
SAFE noch auf Linux qualifiziert; eine zusätzliche Assembly wäre eine eigene
Dependency-/Trustgrenze. Für die bereits vorgeschlagenen Zahlenkeywords ist
ein Vergleich von Vorzeichen, signifikanten Dezimalziffern und Exponent ohne
materialisierte Zehnerpotenzen eine prüfbare eigene Alternative.
[Unterstützte Frameworkbibliotheken](https://learn.microsoft.com/en-us/sql/relational-databases/clr-integration/database-objects/supported-net-framework-libraries?view=sql-server-ver17)

Abnahme: mathematische Integerwerte `1`, `1.0`, `1e0`; große positive/negative
Exponenten und begrenzte Exponentziffernverarbeitung. Kein float- oder
decimal-Ersatz für beliebig große JSON-Zahlen.
[Draft2020-12 Validation](https://json-schema.org/draft/2020-12/json-schema-validation)

Lokale Referenzen benötigen URI-Fragment-Decoding vor Pointer-Decoding,
erkannte Schemaorte als Ziele und explizite Behandlung von $id/$anchor/
$vocabulary. $ref-Geschwister bleiben wirksam. Referenzzyklen über kombinierte
Subschema-/Referenzkanten prüfen; DAGs nicht vollständig expandieren.
Zusammengehörige Fixtures: prefixItems/items, additionalProperties desselben
Schemaobjekts und Referenz plus zusätzliche lokale Bedingung.
[Draft2020-12 Core](https://json-schema.org/draft/2020-12/json-schema-core)

Ein Evaluationsbudget muss zusätzlich Parsing, Duplicateprüfung, vollständigen
Schema-Preflight, Referenzauflösung, Vergleiche und Diagnosepfade abdecken.
Slice-/Indexdarstellung und expliziter Stack sind Entwurfsempfehlungen, keine
Heapqualifikation. Noch konkret festzulegen: Unicode-Regel, Schema-/Dokument-
Fehlerpriorität, nicht auflösbare Referenz, MaxErrors0 und SUMMARY/ErrorOrdinal.
Fehlendes vollständiges Urteil bleibt LIMIT/IsValidNULL.

### Tatsächlich ausgeführte Vor-Source-Characterization

Befehl: `pwsh -NoProfile -File Tests/Research/characterize-next-wave-json.ps1`.
Datum:2026-10-05. Scope: elf synthetische lesende Engineproben auf dem nach
Schema-Validierung ausdrücklich gewählten SQL2019 Linux/latest mit geprüftem
Major15 und aktuellem CL150. Der Runner verwendet kanonische Discovery und
Readiness-Auswahl; kein Providerfallback. SQL-Anmeldung und die im Zusatzprompt
geforderten Inventarabfragen wurden durchgeführt, Ergebnisse nicht gespeichert.
Keine Datenbank-/Objekt-/Konfigurations-, Rechte- oder Truständerung.
[Reproduzierbarer Runner](../../Tests/Research/characterize-next-wave-json.ps1)

Alle elf Assertions bestanden: Scalarwrapper, notwendige Rootkardinalität,
SQL-Padding, escaped Duplicatekeys, 4000-/4001-Keygrenze, escaped unpaired
Surrogate, Decimal-Rundung, GUID-Suffix sowie Langkeys mit Surrogatpaar/NUL
an der Trunkierungsgrenze. Die letzten zwei Fälle erzeugten unter BIN2 plus
Längengleichheit keinen kurzen Präfixtreffer. Das ist begrenzte Engineevidenz;
die vorgeschlagenen öffentlichen APIs existieren weiterhin nicht. Andere
Collations, Ziele, vollständige Parser-/Optimizer-/Budget- und Performancefälle
sind `not executed`. CLR-/API-Qualifikation wird dadurch nicht behauptet.
## Fortschreibung 2026-10-05 – CSV-Umsetzung

Der Benutzer antwortete auf den konkret vorgelegten CSV-Scope mit dem Auftrag
zur autonomen Weiterentwicklung und dem Hinweis auf die abgeschlossene
Besprechung. Diese scoped Fortsetzung ist als funktionsbezogene Freigabe in
[BACKLOG](../../.ai/BACKLOG.md) dokumentiert. Der
[kanonische CSV-Vertrag](../Architecture/CSV_MEMORY_CONTRACT.md) ersetzt für
diese beiden USPs die historische Bewertung eines offenen CSV-Sourcegates.
Die vorangehenden Vorschläge und technischen Vorprüfungen bleiben als Historie
erhalten; daraus entsteht keine Freigabe anderer Funktionskandidaten.

## Entscheidungsvorbereitung nach CSV-Merge 2026-10-05

CSV ist in [PR169](https://github.com/gecompat/SQL_Server_Toolbelt/pull/169)
mit fünf erfolgreichen Checks am exakten Head gemergt. Die folgende Ausarbeitung
schließt offene Entwurfsfragen der vorhandenen RI-2026-041/076/048. Status:
`proposed`; keine neuen SQL-Objekte, keine Providerfreigabe und keine Runtime-
Qualifikation der vorgeschlagenen Objekte/Provider. Die spätere lesende
Engine-Charakterisierung bleibt getrennt. Angenommene Richtungen bleiben erhalten.

### JSON Pointer: bevorzugte konkrete Restentscheidungen

Die vier vorgeschlagenen Ergebnisfelder und genau eine Ergebniszeile bleiben
erhalten. Tabelle und Fehlerpriorität sind vorgeschlagene Toolbelt-Semantik.

| Fall | Bevorzugter Vorschlag |
|---|---|
| Leerer Pointer | Root auflösen: Scalar FOUND, JSON-null JSON_NULL |
| Weiterlaufen durch Scalar/null | MISSING; JSON_NULL nur bei erfolgreich aufgelöstem terminalem null |
| Arraytoken mit ungültiger Indexlexik | INVALID/ARRAY_INDEX; nur im Arraykontext, Objektkeys bleiben unverändert |
| Arraytoken `-` oder gültiger Index außerhalb des Arrays | MISSING; auch syntaktisch gültige Indizes oberhalb bigint |
| Mehrere passende decodierte Objektkeys | INVALID/DUPLICATE_KEY; unbeteiligte Duplikate allein verhindern keine Auflösung |
| Dokumenttiefe | Gleichzeitig offene Object-/Arraycontainer: Scalarroot0, Containerroot1; künstlicher Wrapper zählt nicht |
| Unicode | Ungepaarte Surrogate in vollständigem Dokument oder Pointer abweisen; gültige Paare und escaped NUL zulassen, keine Normalisierung |
| Budgets | 16MiB Input,4000 UTF16-Pointereinheiten,128 Containertiefe; konfigurierbare Input-/Tiefenwerte ausschließlich positiv und absenkbar |

Fehlerpriorität: SQL_NULL, ungültige Parameter, Input-/Pointerlimit,
Pointersyntax/-Unicode, vollständige JSON-Syntax, Dokumenttiefe/-Unicode,
Auflösung. Nach erfolgreicher Syntaxprüfung besitzt das Tiefenlimit Vorrang
vor Dokument-Unicodefehlern. Vorgeschlagene Codes: PARAMETER, INPUT_LIMIT,
POINTER_LIMIT, POINTER_SYNTAX, JSON_SYNTAX, DEPTH_LIMIT, UNICODE,
DUPLICATE_KEY, ARRAY_INDEX. INVALID liefert NULL in JsonType/Value; MISSING
und SQL_NULL erhalten keinen ErrorCode. Object-/Arraywerte sind gültiger
JSON-Text ohne Formatierungstreuezusage, Zahlen bleiben unveränderte Literale.

[RFC6901](https://www.rfc-editor.org/rfc/rfc6901) begründet kontextbezogene
Tokenauswertung und exakte decodierte Keys; die Statuszuordnung ist eine eigene
Entscheidung. [RFC8259 §8.2](https://www.rfc-editor.org/rfc/rfc8259#section-8.2)
beschreibt Probleme ungepaarter Surrogate, obwohl die Grammatik solche Escapes
zulässt. Die vorgeschlagene Abweisung ist eine ausdrückliche Einschränkung.

Bevorzugte Implementierungsrichtung: iterative T-SQL-MSTVF mit begründetem
Ausnahmefall gegenüber Inline-TVFs. Rekursive CTEs bringen eigene
Rekursions-/Abfragegrenzen; eine fixe Join-Kette vervielfacht Logik und löst die
globale Syntax-/Unicodeprüfung nicht. Eine gleichwertige Inline-Lösung ist
damit noch nicht widerlegt. Vor Source ist der kanonische Scan-/Traversalpfad
ohne Parserkopie festzulegen und die Ausnahme am konkreten Design zu begründen.
[CTE-Grenzen](https://learn.microsoft.com/en-us/sql/t-sql/queries/with-common-table-expression-transact-sql),
[UDF-Grenzen](https://learn.microsoft.com/en-us/sql/relational-databases/user-defined-functions/create-user-defined-functions-database-engine).

OPENJSON erst nach vollständigem Syntaxpreflight auf gültigen Containern
aufrufen; kein TRY/CATCH in der UDF. BIN2 plus DATALENGTH bleibt der
Keyvergleich, keine neue globale Keygrenze aus den elf historischen Proben.
16MiB und128 Ebenen begrenzen Input und Tiefe, qualifizieren aber noch keine
Arbeitsmenge oder APPLY-Performance bei wiederholten Fragmentkopien. Diese
Machbarkeit bleibt ein technischer Vor-Source-Schritt ohne öffentliche API.
[OPENJSON](https://learn.microsoft.com/en-us/sql/t-sql/functions/openjson-transact-sql).

### Safe Cast: exakte Decimalgrenze und Fehlerpriorität

Sechs vorgeschlagene echte Inline-TVFs, Zieltypen, feste Decimal38/18-Form,
Datetime2(7), strikte ASCII-/ISO-Lexik und8192-Byte-Deckel bleiben unverändert.
Bevorzugte Fehlerpriorität: SQL_NULL, PARAMETER bei ungültigem Budget, LIMIT,
EMPTY, INVALID_FORMAT, OUT_OF_RANGE, LOSSY, OK. Parameterfehler liefern
den zusätzlichen vorgeschlagenen Status INVALID_ARGUMENT mit ErrorCode PARAMETER;
damit wird das bisherige Sieben-Status-Proposal ausdrücklich erweitert. Keine originale
Enginefehlermeldung und kein Input-Echo. Die endgültige Freigabe muss diese
zusätzliche Zuordnung ausdrücklich umfassen.

Für Decimal wird nach Lexikprüfung der vorzeichenfreie Betrag vor LOSSY exakt
gegen den Maximalbetrag verglichen. Führende Ganzzahlnullen zählen nicht;
über20 signifikante Ganzzahlstellen sind außerhalb, unter20 innerhalb.
Bei20 Stellen überschreitet nur dieser Restfall den Maximalbetrag: Ganzzahl
ist20 Neunen, erste18 Nachkommastellen nach Rechtsauffüllen mit Nullen sind18
Neunen und mindestens eine spätere Nachkommastelle ist nichtnull.
Erst nach Bereichsbeweis werden nichtnull verworfene Nachkommastellen als LOSSY
klassifiziert; zusätzliche Nullstellen dürfen vor TRY_CONVERT entfallen.
Positive/negative Beträge verwenden dieselbe Grenze, negative Null bleibt Null.

| Synthetischer Eingang für decimal(38,18) | Vorgeschlagenes Ergebnis |
|---|---|
| `99999999999999999999.9999999999999999990` und negatives Pendant | OK, zusätzliche Nullstelle exakt entfernbar |
| `99999999999999999999.9999999999999999991` und negatives Pendant | OUT_OF_RANGE, auch bei nativer Rückrundung |
| `99999999999999999998.9999999999999999991` | LOSSY, innerhalb des exakten Bereichs |

[Microsoft decimal/numeric](https://learn.microsoft.com/en-us/sql/t-sql/data-types/decimal-and-numeric-transact-sql?view=sql-server-ver17)
dokumentiert native Skalenreduktion durch Rundung. Der Betragvergleich ist
eine eigene Entwurfsschlussfolgerung und noch kein getesteter Inline-Kern.
TRY_CONVERT ausschließlich auf zulässige Typen bleibt auch bei vorgezogener
Optimizer-Auswertung sicher; CASE ist keine allgemeine Auswertungsbarriere.

### JSON Schema: Referenzen, vollständiges Urteil und Unicode

Die vorgeschlagene USP und das sichtbare Profil `toolbelt-2020-12-v1` bleiben
erhalten. Bevorzugt wird weiterhin ein eigener begrenzter SAFE-Kern ohne
Drittanbieter, Netzwerk oder automatische Work-Type-Integration; Auswahl und
Assembly-/Trustvertrag benötigen ihre eigene Freigabe. Kein voller Draftvalidator.

V1 akzeptiert ausschließlich lokale Fragmentreferenzen `#` und `#/...`.
Fragmentform vor Decoding feststellen; leere oder mit Slash beginnende
Pointerform nach strikt einmaligem Percent-/UTF8-Decoding prüfen, danach
`~1`/`~0`. Damit ist beispielsweise `#%2F$defs%2Fx` weiterhin lokal zulässig.
Nur bekannte Schemaorte mit Boolean-/Objectschemas sind Referenzziele;
nicht auflösbare oder andere Ziele ergeben INVALID_SCHEMA. `$id`, `$anchor`,
`$dynamic*` und `$vocabulary` werden im eingeschränkten Profil UNSUPPORTED.

Schemaorte einmal indexieren; Containment- und Referenzkanten gemeinsam prüfen.
Zyklen bereits beim vollständigen Schema-Preflight abweisen, auch in ungenutzten
`$defs`; DAGs nicht expandieren. Bei `$ref` gelten Ziel und lokale Geschwister.
[Draft2020-12 Core](https://json-schema.org/draft/2020-12/json-schema-core)
begründet Referenzauflösung und Geschwistersemantik; Zyklenverbot und der
engere Fragmentumfang sind eigene V1-Einschränkungen.

Bevorzugte Priorität bei gültigen Parametern: SQL_NULL, vollständiger
Schema-Syntax-/Profilpreflight, vollständiger Dokument-Syntax-/Profilpreflight,
Evaluation. LIMIT kann jeden begonnenen Arbeitsschritt abbrechen und liefert
immer IsValid=NULL, auch nach bereits gefundenen Instanzverletzungen.
Lone Surrogates sind UNSUPPORTED/UNPAIRED_SURROGATE mit IsValid=NULL;
wohlgeformte Paare zählen als ein UnicodeScalar, Identität bleibt ordinal.
Die Abweisung ist eine Einschränkung, keine allgemeine JSON-Grammatikregel.
[RFC8259 §8.2](https://www.rfc-editor.org/rfc/rfc8259#section-8.2),
[Validation Stringlänge](https://json-schema.org/draft/2020-12/json-schema-validation#section-6.3.1).

Ein globaler geprüft addierter Arbeitszähler umfasst gescannte Einheiten,
Duplicate-Vergleiche einschließlich Hashkollisionen, Schema-/Keywordbesuche,
Graph-/Referenzarbeit, Zahl-/Exponentziffern, Evaluation und Diagnosepfadaufbau.
MaxErrors begrenzt ausschließlich gespeicherte Diagnosen. Vorschlag:
MaxErrors0 zulassen, SUMMARY mit ErrorOrdinal0, gespeicherte Fehler1..N;
unterdrückte Verletzungen setzen ErrorsTruncated=1, Evaluation läuft weiter.
Kein frühzeitiges IsValid=0 als Ersatz für ein vollständiges Profilurteil.

### Noch benötigte Eingabe und unabhängige Arbeit

Diese Ausarbeitung ersetzt die offenen Entwurfsfragen durch konkrete bevorzugte
Vorschläge. Sie erfindet weder eine Einzelfreigabe noch SQL-/CLR-Machbarkeit.
Nächste funktionsbezogene Freigabe: zunächst Pointer oder die sechs Safe-Cast-
TVFs mit den oben genannten Outputs, Lexik-/Fehler- und Providerdetails.
Das Schema-Profil bleibt getrennt. Technische Vorprüfung, Kollisions-/Reuse-
Analyse und Entwurfsreview dürfen bis dahin autonom weitergehen.

### Konkreter Reuse-Befund vor einer Providerwahl

Der vorhandene [`AgfCore.cs`](../../Modules/toolbelt.json.constructors/Clr/AgfCore.cs)
in Constructors1.2 enthält bereits Number-, String-, Escape-, Whitespace- und
Containerlexik. ScanJson akzeptiert dort ausschließlich Containerroots;
AGF begrenzt auf127 Frames, Legacy reserviert abhängig von der gesamten
Inputlänge. Decoded-Unicodeprüfung ist ein eigener Schritt. Der Ergebnisvertrag
enthält Fehleroffset/Tiefe, aber keine Tokenindizes, decodierten Keys,
Duplicateprüfung oder globalen Arbeitszähler. Das sind gelesene Sourcebefunde,
keine neuen Runtime-Ergebnisse.

Die angenommenen Constructor-/AGF-Verträge bleiben erhalten. Ihre Scanner-
Policies können nicht unverändert als Pointer-/Schema-Policies gelten.
[DEC-2026-033](../Architecture/DECISIONS.md#dec-2026-033-gemeinsamer-safe-json-kern-und-gebundener-achtteiliger-lifecycle)
begrenzt die vorhandene Providerfreigabe auf Constructors1.2; neue Bindings,
gemeinsame Infrastruktur oder geänderte Binarybytes folgen daraus nicht.

Bevorzugte zu prüfende Reuse-Richtung: genau ein kanonischer interner Scanner
mit expliziter Root-/Tiefen-/Diagnosepolicy, optionalen Tokenspans und
Arbeitszähler; unveränderte Constructoradapter erhalten ihre bisherige
Priorität und127-Grenze. Resolver und Schemavalidator hätten eigene fachliche
Adapter. Physische Assembly-/Dependencygrenze und migrationssichere
Bereitstellung sind noch vor Providerfreigabe festzulegen. Kein Copy/Paste der
Lexik in eine zweite handgeschriebene T-SQL- oder CLR-Grammatik.

Native ISJSON/OPENJSON bleibt eine begründbar separate Enginealternative.
Der vorherige T-SQL-MSTVF-Vorschlag ist deshalb ausdrücklich bedingt:
Vor-Source-Design muss vollständige Syntax-/Unicode-/Budgetprüfung und
Wiederverwendung kohärent lösen. Kein ungeprüfter Wechsel zu CLR und keine
nachträgliche Freigabe aus einer allgemeinen Portabilitätsbehauptung.
Die Prüfung hat einen konkreten Integrationspunkt gefunden; sie rechtfertigt
keine Änderung der historischen freigegebenen Hashregistry.

### Zusätzliche tatsächlich ausgeführte Decimal-Charakterisierung

Am2026-10-05 bestand
`pwsh -NoProfile -File Tests/Research/characterize-next-wave-json.ps1 -ProbeSet decimal-range`
mit sechs neuen synthetischen lesenden Assertions auf dem schema-validierten,
explizit ausgewählten Linux2019/latest-Ziel mit geprüftem Major15/CL150.
Root-Watchdog120s, Exit0, vollständige Ausgabekanäle und leeres Stderr.
Keine Datenbank-/Objekt-/Konfigurations-, Rechte- oder Truständerung.
Der unveränderte Standard `json-baseline` wurde nicht erneut ausgeführt;
seine elf historischen Assertions bleiben ein getrennter früherer Nachweis.

Bestätigt: zusätzliche Nullstelle am positiven Maximalwert bleibt exakt;
zusätzliche nichtnull19.Nachkommastelle1 am positiven/negativen Maximalbetrag
wird nativ zurück in den Bereich gerundet. Ein entsprechender innerhalb
liegender Betrag wird ebenfalls gerundet. Rundungssprung über den Maximalwert
und21-stellige Ganzzahl liefern mit TRY_CONVERT SQL-NULL. Native Konversion
allein kann damit OUT_OF_RANGE und LOSSY nicht wie vorgeschlagen unterscheiden.
Die exakte vorgelagerte Betragsklassifikation ist weiter ein Entwurf, keine
implementierte oder qualifizierte Safe-Cast-TVF. Weitere Ziele, Optimizer-/APPLY-
Kontexte und ein eigener Kern sind `not executed`.

## Weiterführende Designprüfung 2026-10-05 – begrenzter Schema-Zahlenkern

RelatedReference: `RI-2026-048`. Status `proposed`; reine Quellen-/Designprüfung,
keine neue öffentliche Funktion, Assembly, Providerwahl oder Runtimequalifikation.
Die sechs Safe-Cast-TVFs sind inzwischen separat freigegeben und in
[PR171](https://github.com/gecompat/SQL_Server_Toolbelt/pull/171) umgesetzt;
deren Freigabe erweitert diesen Schema-Scope nicht.

Der [Core-Datenmodellvertrag](https://json-schema.org/draft/2020-12/json-schema-core#section-4.2.1)
verwendet beliebig genaue Dezimalwerte; die
[Integer-Semantik](https://json-schema.org/draft/2020-12/json-schema-validation#section-6.1.1)
bezieht sich auf den mathematischen Wert. Die folgende eigene algorithmische
Schlussfolgerung bietet eine prüfbare Richtung ohne BigInteger-Abhängigkeit,
float/decimal-Ersatz oder materialisierte Zehnerpotenzen:

- Nichtnullwerte als `sign × D × 10^q` darstellen: aus der Mantisse führende und
  abschließende Nullziffern entfernen; `q = explicitExponent - fractionDigits +
  removedTrailingZeros`. `D` bleibt eine logische Ziffernspanne ohne Dezimalpunkt.
- Den Exponenten als normalisierte vorzeichenbehaftete Dezimalziffern behalten.
  Nur durch die Inputlänge begrenzte Offsets mit exakter Ziffernarithmetik
  addieren. Scratchlänge höchstens `max(exponentDigits, offsetDigits) + 1`;
  nicht auf einen nativen Integerbereich oder künstliche Unendlichkeit kürzen.
- Vorzeichen, dann `q + length(D)`, dann gleichlange virtuelle Mantissen mit
  rechts ergänzten Nullziffern vergleichen. Nur bis zur längeren tatsächlichen
  Mantisse laufen; bei negativen Werten die Betragsordnung umkehren.
- Null besitzt einen mathematischen Wert einschließlich `-0` und `0e999…`;
  dessen Exponent wird trotzdem syntaktisch vollständig geprüft und budgetiert.
  Ein Nichtnullwert ist genau bei `q >= 0` Integer. `1`, `1.0`, `1e0` und
  `100e-2` müssen deshalb für `type: integer` gleich behandelt werden.

Vorzeichen-/Exponent-/Mantissengrenzen und lange gemeinsame Ziffernpräfixe
sind künftige Abnahmefälle, keine bereits ausgeführten Kernprüfungen.
`enum`, `const` und `multipleOf` bleiben im vorgeschlagenen V1 `UNSUPPORTED`.
Eine mögliche spätere Zahlengleichheit erweitert die aktuelle Keywordliste nicht.

Arbeitskosten vor der jeweiligen Arbeit/Allokation abbuchen: gescannte UTF16-
Einheiten, Ziffernoperationen, Keyhashes und Kollisionsvergleiche, Keywordbesuche,
Graphkanten, Referenzdecoding, Evaluation und Diagnosepfadaufbau. Erst
`cost > remaining` prüfen; keine überlaufgefährdete Addition als Gate.
Hashes grenzen Kandidaten ein, decodierte ordinale Gleichheit entscheidet
Duplicatekeys. Beispielsweise sind `"a"` und `"\u0061"` derselbe Key.

Die bestehenden vorgeschlagenen Ceilings bleiben unabhängig: 16MiB UTF16
entsprechen bis zu 8388608 Einheiten. Eine Million Default-Arbeitsschritte kann
ein solches Dokument nicht einmal vollständig scannen. Dieser rechnerische
Befund verlangt `LIMIT/IsValid=NULL`, keine stille Defaultänderung oder
Ausnahme von der Scanabrechnung. `MaxErrors` begrenzt weiterhin nur Diagnosen.

Vollständiger Schema-Preflight prüft auch die Form unterstützter Keywords:
Count-/Längengrenzen sind mathematische nichtnegative Integer, auch oberhalb
nativer Integerbereiche; widersprüchliche numerische Grenzen machen ein Schema
unerfüllbar, nicht syntaktisch ungültig.
[Validation](https://json-schema.org/draft/2020-12/json-schema-validation#section-6)
und [Array-Applicators](https://json-schema.org/draft/2020-12/json-schema-core#section-10.3.1)
begründen außerdem das nichtleere `prefixItems`-Array und `items` nach dem
zugehörigen Präfix. Referenzgeschwister bleiben gemäß dem vorhandenen Vorschlag
wirksam. Quellen am 2026-10-05 erneut gelesen; keine zusätzliche SQL-Prüfung.

Der vorhandene Constructor-Scanner bleibt ein Reuse-Anknüpfungspunkt, besitzt
aber weiterhin keine Schema-Tokenindizes, Duplicateprüfung oder globale
Arbeitsabrechnung. Physische gemeinsame Kernel-/Assemblygrenze, Migration,
Trust und die konkrete USP benötigen eine eigene anschließende Freigabe.

## Weiterführende Designprüfung 2026-10-05 – nativer Pointer-Pfad

RelatedReference: `RI-2026-041`. Bevorzugte Richtung bleibt eine einzelne
T-SQL-MSTVF mit den bereits vorgeschlagenen vier Ergebnisfeldern, Statuscodes,
Fehlerprioritäten und Input-/Pointer-/Tiefenbudgets. Keine neue Sourcefreigabe,
keine CLR-Änderung und keine Runtimequalifikation der vorgeschlagenen API.

Die eigene Designschlussfolgerung trennt native JSON-Grammatik von zusätzlicher
Toolbelt-Policy: `ISJSON` prüft Syntax, ein kanonischer vorwärts laufender
Policywalker prüft ausschließlich Quotes/Escapes, decodierte UTF16-Einheiten
und offene Containertiefe. Er implementiert keine zweite Number-/Member-/
Separatorgrammatik. Vor Wrapperkopien Inputbudgets prüfen. Object-/Arrayroots
direkt validieren; nur Scalarroots in einen max-typisierten Arraywrapper setzen
und genau ein Element verlangen. Dadurch zählt der künstliche Wrapper nicht
gegen die Dokumenttiefe. Der neuere VALUE-Typconstraint ist keine SQL2019-Basis.
[ISJSON](https://learn.microsoft.com/en-us/sql/t-sql/functions/isjson-transact-sql)

Nach erfolgreicher Syntaxprüfung das vollständige Original unter expliziter
non-SC-Collation in begrenzten Chunks durchlaufen, einschließlich unselektierter
Keys und Strings. Raw- und escaped Surrogate im selben decodierten Strom paaren;
escaped NUL erlauben. Unicodefehler merken und die Tiefenprüfung fortsetzen,
damit die vorgeschlagene DEPTH_LIMIT-vor-UNICODE-Priorität erhalten bleibt.
Diese Policy ist strenger als die JSON-Grammatik, die ungepaarte Escapes zulässt.
[RFC8259 §8.2](https://www.rfc-editor.org/rfc/rfc8259#section-8.2)

`OPENJSON` erhält ausschließlich bereits validierte Container. Den lokalen
Parseroperand mit gültigem JSON initialisieren und erst in einem getrennten
erfolgreichen Validierungszweig ersetzen. Keine WHERE-/CASE-Auswertungsbarriere
behaupten. Pro Traversalschritt in einem Default-Schema-OPENJSON-Statement
Trefferzahl/Typ/Wert aggregieren, keine gesamte Geschwistermenge in einer
Tabellenvariable materialisieren. Engineinterne Materialisierung ist dadurch
nicht ausgeschlossen. Objectkeys weiterhin BIN2 plus DATALENGTH vergleichen.
[UDF-Grenzen](https://learn.microsoft.com/en-us/sql/relational-databases/user-defined-functions/create-user-defined-functions-database-engine)
schließen TRY/CATCH aus; das begründet die vorgelagerten gültigen Operanden.

Aus höchstens 4000 UTF16-Einheiten des vollständigen Pointers folgen höchstens
3999 Einheiten je decodiertem Token. Ein auf 4000 Einheiten ausgegebener langer
OPENJSON-Key ist deshalb mit einem adressierbaren Token nicht längengleich.
Das ist eine Schlussfolgerung aus der vorgeschlagenen Pointergrenze und der
getrennten historischen Langkey-Charakterisierung, keine globale Keygrenze oder
neue Laufzeitprüfung. Arrayindexlexik nur im Arraykontext prüfen; beliebig große
gültige Indizes liefern MISSING. Pointertokens mit dem begrenzten Unitwalker
decodieren: `REPLACE` besitzt eine dokumentierte char(0)-Einschränkung.
[OPENJSON](https://learn.microsoft.com/en-us/sql/t-sql/functions/openjson-transact-sql),
[REPLACE](https://learn.microsoft.com/en-us/sql/t-sql/functions/replace-transact-sql),
[RFC6901](https://www.rfc-editor.org/rfc/rfc6901)

Die MSTVF-Ausnahme wird durch sequentiellen Unicodezustand, deterministische
Phasenpriorität und abhängige Traversalschritte mit Duplicate-Aggregation
begründet. Eine äquivalente Inline-Lösung bleibt ungezeigt, nicht widerlegt.
Ein Constructor-CLR-Reuse würde neue Policies/Bindings und eigene Assembly-/
Migrations-/Trustverträge benötigen; der native Pfad lässt dessen Kern bestehen.

Inputgröße und Tiefe begrenzen den eigenen Scan und die Traversalschritte.
Wiederholtes Fragmentparsing/-kopieren kann nominell dennoch Arbeit proportional
zu Dokumentgröße mal Tiefe benötigen. Engineheap, Dauer und APPLY-Performance
sind damit nicht qualifiziert. Native Parser-Tiefengrenzen, exakte Erhaltung
aller Zahlenliterale und maximale Input-/Tiefenworkloads gehören in die begrenzte
spätere Abnahme. Kein neues Arbeitsbudget oder Performanceversprechen eingeführt.

### Getrennte tatsächlich ausgeführte Pointer-Engineproben

Am 2026-10-05 bestand
`pwsh -NoProfile -File Tests/Research/characterize-next-wave-json.ps1 -ProbeSet pointer-policy`
mit sechs neuen synthetischen lesenden Assertions auf dem schema-validierten,
explizit ausgewählten Linux2019/latest-Ziel; Major15 und CL150 im Lauf geprüft.
Der eigene Parent-Watchdog war auf120s begrenzt: tatsächlicher Exit0, vollständige
Kanäle, kein Timeout und leeres Stderr. Kein Objekt-, Datenbank-, Konfigurations-,
Rechte- oder Trustscope; keine Ressourcen angelegt. Die früheren elf JSON- und
sechs Decimalproben wurden nicht wiederholt und behalten getrennte Evidenz.

Bestätigt im engen Fixtureumfang: BIN2 plus DATALENGTH unterscheidet gleichlange
Keys mit NUL an verschiedenen Positionen; raw/escaped Surrogate beider
Paarungsrichtungen werden zu exakt denselben UTF16-Bytes decodiert. Die beiden
Zahlenliterale `1e1000000` und `-0.000e-999` bleiben in Default-OPENJSON byteexakt
erhalten. ISJSON akzeptiert den direkt geprüften Arraycontainer mit128 offenen
Ebenen. Das ist keine allgemeine Parser-Tiefengrenze, keine vollständige
Zahlenliteral-/Unicodequalifikation und kein getesteter Policywalker oder
Pointerresolver. Weitere Ziele, Maximalworkloads und API-/Lifecycle-/Client-
Qualifikation sind weiterhin `not executed`.
