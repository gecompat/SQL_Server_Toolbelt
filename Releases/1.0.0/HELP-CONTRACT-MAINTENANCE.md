# Hilfe- und ResultTable-Korrekturen

Die Korrektur betrifft vierzehn bestehende Prozeduren und zwei bestehende
XLSX-Zell-TVFs. Neue fachliche SQL-Objekte entstehen dadurch nicht.

| Bereich | Verbesserungen |
|---|---|
| Execution Cancellation | Einheitliches Help-Resultset für `USP_RequestExecutionCancellation` |
| Work Queue | Vollständige Parameter und funktionale Beispiele für Policy-Enqueue, Barrier-Enqueue, Retry und Dead-Letter-Requeue; eigene Barrier-Hilfe |
| File Content | Hilfe ohne Dateipfad; ResultTable-Routing für Binary- und Textdateien |
| XLSX | Funktionale Beispiele der beiden öffentlichen Prozeduren; Kommentare der beiden Zell-TVFs innerhalb ihres gespeicherten DDL |
| Interne Kerne | Hilfe für Event-Log, Second-Session-Dispatch/-Probe, Table-Clone und Deterministic-Lookup; passende funktionale Beispiele beziehungsweise Aufruf über die öffentliche Fassade |

`@Hilfe = 1` liefert das gemeinsame Help-Resultset vor fachlicher Validierung,
Dateizugriff, Queue-Änderung und ResultTable-Vorbereitung. Infrastruktur ohne
fachliches Resultset erhält keinen bedeutungslosen ResultTable-Parameter.
OUTPUT-Werte werden in der Hilfe als Parameter beschrieben.

Die fünf ausdrücklich freigegebenen ResultTable-Routen sind
`USP_LoadBinaryFile`, `USP_LoadTextFile`, `USP_EnqueueWorkWithPolicy`,
`USP_RequeueDeadLetter` und der delegierende `USP_EnqueueBarrierWork`.
Sie verwenden den bestehenden kanonischen Helper und dieselben Resultspalten
wie der SELECT-Pfad. Das Ziel muss eine vorhandene lokale Temp-Tabelle sein.
`@KeepData = 0` ersetzt, `1` hängt an. Der Preflight erfolgt vor Dateizugriff
beziehungsweise Queue-DML. Fehler rollen eigene Änderungen zurück und
übernehmen keine vollständige Callertransaktion.

Bei den FileContent-Prozeduren endet die Signatur jetzt verbindlich mit
`@ResultTable, @KeepData, @Debug, @Hilfe`. Bisherige positionsgebundene
Debug-/Hilfe-Aufrufe auf benannte Parameter umstellen. Die gekoppelten
[Binary-](../../Modules/toolbelt.file.content/Documentation/USP_LoadBinaryFile.md)
und [Textdatei-Anleitungen](../../Modules/toolbelt.file.content/Documentation/USP_LoadTextFile.md)
beschreiben Voraussetzungen, Rechte, Fehler und Beispiele.

Die TVF-Hilfe lässt sich mit vorhandener Metadatensicht direkt erkunden:

```sql
SELECT OBJECT_DEFINITION(OBJECT_ID(N'toolbelt_file.TVF_InterpretXlsxCell'));
SELECT OBJECT_DEFINITION(OBJECT_ID(N'toolbelt_file.TVF_FormatXlsxCell'));
```

Die sechs öffentlichen Base64-Funktionen enthalten ebenfalls Zweck-, Parameter-,
Rückgabe- und Beispielhinweise im gespeicherten DDL. Ihr enger, archivgebundener
Quellübergang ist im [Base64-DDL-Hilferecord](base64-ddl-help-transition.json)
beschrieben; dieser ergänzt die Kommentare, ohne frühere Ausführungsnachweise
umzudatieren oder eine neue vollständige native Abnahme zu behaupten.

Die drei öffentlichen Generate-Series-Funktionen enthalten Zweck, Parameter,
Grenzverhalten und ausführbare Beispiele ebenfalls innerhalb ihrer gespeicherten
DDL-Definitionen. Der [Generate-Series-DDL-Hilferecord](generate-series-ddl-help-transition.json)
bindet ausschließlich diese Kommentarergänzungen an die unveränderten
historischen Quellen und Callerberichte; die bestehende CI prüft die aktuelle
gespeicherte DDL-Hilfe.

Die drei öffentlichen Date-Spine-TVFs enthalten ebenfalls Zweck, erforderliche
Bereichsparameter, Randverhalten, Rückgabespalten und geordnete Beispiele im
gespeicherten DDL. Ihr [Date-Spine-DDL-Hilferecord](date-spine-ddl-help-transition.json)
bindet nur diese drei Kommentarergänzungen und erhält den direkten Core-Pin
sowie den bisherigen Callerbericht unverändert.

Der [Quellübergangsrecord](help-contract-source-delta.json) bindet die
betroffenen aktuellen Dateien getrennt von den unveränderten früheren
Ausführungsnachweisen. Das [öffentliche Vorgängerarchiv](Artifacts/Help-Contract-Baseline.zip)
enthält ausschließlich die entsprechenden Quellen aus dem früheren
öffentlichen Projektstand und die unveränderte Lizenz. Der Record belegt
den Quellübergang, keine neue vollständige native API-Abnahme. Die aktuellen
Modulprüfungen und Head-CI bleiben erforderlich; alte Ergebnisse werden
nicht auf geänderte Quellen umdatiert.

Die [CLR-Paketpflege](CLR-MAINTENANCE.md) qualifiziert separat ihren
begrenzten XLSX-Installations-/Hilfe-/SST-Delta. Modulstatus und fehlende
Veröffentlichungsfreigabe bleiben bestehen; SSIS bleibt außerhalb dieser Korrektur.
