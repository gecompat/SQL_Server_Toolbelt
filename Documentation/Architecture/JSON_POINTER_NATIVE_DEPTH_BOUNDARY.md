# JSON Pointer – native Tiefengrenze, freigegebene Prioritätsänderung

Stand: 2026-10-05. RelatedReference: RI-2026-041.
Nach Vorlage dieses konkreten Angebots antwortete der Benutzer ausdrücklich
„Diese Prioritätsänderung freigegeben“. Damit ergänzt die hier beschriebene
eng begrenzte Änderung den [Vertrag](JSON_POINTER_CONTRACT.md).
Die Implementierungsfreigabe für die Pointer-Funktion bleibt bestehen;
keine zusätzliche API-, Provider- oder Releasefreigabe.

## Tatsächliche Grenze

Der erste begrenzte native Adapter auf SQL2019 Linux/latest CL150 bestand
Deployment, Repeat und das Contract-Fixture. Safety scheiterte mit
SQL13606/state1. Der zweite Lauf mit ausschließlich failure-path-Diagnostik
isolierte Safetyfall41 (gültiges JSON mit129 verschachtelten Arrays);
SQL55591/state41 bezeichnet dort den diagnostisch identifizierten Fall,
keinen fachlichen Funktionsstatus und keinen erfolgreichen Sicherheitsnachweis.

Separate reine SELECT-Proben bestätigten auf derselben Engine:

| Synthetischer Input | Native ISJSON-Prüfung |
|---|---|
| 128 offene Arrays um0 | 1 |
| 129 offene Arrays um0 | technischer SQL13606/state1 |
| 129 offene Arrays um0 plus zusätzliche schließende Klammer | technischer SQL13606/state1 |

Reproduzierbare rein synthetische Einzelproben, jeweils als eigener Batch
ausführen; die beiden129er-Proben sind erwartete technische Fehlläufe:

```sql
SELECT ISJSON(REPLICATE(CONVERT(nvarchar(max),N'['),128)+N'0'+REPLICATE(CONVERT(nvarchar(max),N']'),128));
GO
SELECT ISJSON(REPLICATE(CONVERT(nvarchar(max),N'['),129)+N'0'+REPLICATE(CONVERT(nvarchar(max),N']'),129));
GO
SELECT ISJSON(REPLICATE(CONVERT(nvarchar(max),N'['),129)+N'0'+REPLICATE(CONVERT(nvarchar(max),N']'),130));
GO
```

Beide Adapter endeten FAILED_CLEANED. Neue unabhängige Verbindungen bestätigten
jeweils die Abwesenheit der eigenen Testdatenbank, unveränderte eingefrorene
Inputs und Nullscope für Konfiguration, Rechte und Trust. Private Journale,
Endpunkte und originale Runtimekanäle bleiben außerhalb des Repositorys.
Keine vollständige API-/Client-/Lifecyclequalifikation aus diesen Fehlläufen.

Die anschließend separat ausgeführten Lifecycle-Scope-Adapter bestanden auf
Linux2019/latest CL150 und Windows2025/exaktCU8 CL170, jeweils local/central/
Consumer,15 echte direkte Clientreader und42 Lifecyclefälle. Eigene Bereinigung,
Fixturewiederherstellung und Inputpins wurden frisch unabhängig bestätigt.
Contract/Safety wurden in diesem Scope ausdrücklich nicht ausgeführt; diese
Teilqualifikation ersetzt die notwendige vollständige API-/Safetyabnahme nicht.

ISJSON kann deshalb bei über128 offenen Containern nicht vorab die vollständige
Syntax klassifizieren. Eine T-SQL-Function besitzt kein TRY/CATCH für diesen
Enginefehler. Aufteilen oder syntaktisches Reduzieren vor Nativevalidation
würde eine zusätzliche vollständige JSON-Grammatik erfordern. Die unabhängige
Source- und Autorisierungsprüfung bestätigt diese Vertragsgrenze.

## Konkret freigegebene Änderung

Alle Parameter, Defaults, Ergebnisfelder und Statuscodes bleiben gleich.
Nach SQLNULL/Budgets/Input-/Pointerlimits und vollständiger Pointerprüfung
läuft eine escape-aware Strukturbeobachtung über das Originaldokument:
außerhalb von Strings erhöhen `[`/`{` den offenen Containerzähler, `]`/`}`
senken ihn bis mindestens0; eine schließende Klammer bei0 belässt ihn bei0.
Der Zähler kann somit durch fehlerhafte führende Schließklammern nicht negativ
werden und spätere Öffnungen verdecken. Quote-/Escapezustand wird berücksichtigt.
Sobald der Zähler128
überschreitet, liefert die Funktion INVALID/DEPTH_LIMIT **vor** ISJSON.
Das gilt auch für ansonsten fehlerhafte Eingaben. Diese Beobachtung ist eine
Schutzgrenze, keine Aussage über die JSON-Gültigkeit oder passende Klammerarten.

Wenn die beobachtete strukturelle Tiefe höchstens128 bleibt, validiert weiterhin
der native Parser die vollständige Grammatik, bevor das caller-seitig abgesenkte
MaxDepth und danach Dokument-Unicode geprüft werden. Bei MaxDepth1 und einem
fehlerhaften, strukturell nur zweistufigen Dokument bleibt JSON_SYNTAX vorrangig.

Der künstliche Scalarwrapper wird ebenfalls geschützt: `{`/`[` als erstes
nicht-Whitespace-Zeichen verwenden ausschließlich direkte Containerprüfung;
ein ungültiger Container fällt nicht in den Wrapperpfad. Scalar-Kandidaten
mit außerhalb von Strings vorkommenden Containern werden als JSON_SYNTAX
abgewiesen, bevor der künstliche Wrapper eine zusätzliche Tiefenebene erzeugt.
Die native Grammatikautorität für tatsächlich zulässige Kandidaten bleibt gleich.

Zusätzliche feste Oracles: gültige129er-Tiefe, fehlerhafte129er-Tiefe,
fehlerhafte niedrigere Tiefe vor abgesenktem MaxDepth, Klammern/Escapes innerhalb
von Strings, eine unpassende führende Schließklammer vor129 Öffnungen und
malformed/multi-root-Inputs mit tiefen Containern im Wrapperpfad.
Danach werden Source/Deployment/Fixtures neu eingefroren und die beiden bereits
ausgewählten nativen Zielkontexte erneut qualifiziert.

Die Alternative, die ursprüngliche Priorität auch oberhalb128 beizubehalten,
benötigt eine neue Parserarchitektur und eine getrennte Provider-/Scopebesprechung.
Ein technischer Parserfehler darf nicht stillschweigend als erfolgreicher
einzeiliger Vertragsnachweis behandelt werden.

## Umsetzung und getrennte Abschlussprüfung

Der ausdrücklich freigegebene Guard-/Wrapperstand besteht anschließend die
vollständigen begrenzten Adapter auf Linux2019/latest CL150 und Windows2025/
exaktCU8 CL170: je local/central/Consumer,3072 feste Contract-/Safety-APPLY-
Oracles,15 direkte Clientreader und42 Lifecyclefälle. Neue unabhängige
Verbindungen bestätigen je drei eigeneDBs abwesend, exakte Marker-/Fremdslot-/
Dependencywiederherstellung und alle Inputpins; keine Konfigurations-/Rechte-/
Truständerungen. Die früheren Fehlläufe und Lifecycle-only-Scopes bleiben
getrennt. Weitere physische Ziele, Minimalrechte und Maximalworkload/Heap
bleiben offen; kein Release und kein Ersatz für exakte Head-CI.
