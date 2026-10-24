# Nachweiszuordnung aller 45 Module

Diese Zuordnung verknüpft den eingefrorenen Releasekandidaten mit den
kanonischen `validation_evidence`-Einträgen der Modulmanifeste und den
[zusätzlichen API-/Grenzprüfungen](API-QUALIFICATION.md). Die originale
Beschreibung jedes Nachweises begrenzt seinen Scope; ein aktueller grüner
Pakettest ersetzt sie nicht. Kein Modul wird hierdurch hochgestuft.

Tabelle und JSON-Projektion bewahren die zusätzliche Welle vom 2026-10-23.
Spätere Nachprüfungen werden darunter getrennt zugeordnet. Insbesondere ist
das damalige Capture-Timeout-Gate inzwischen für die gebundene DLL mit
[ausdrücklich akzeptiertem Restrisiko angenommen](CAPTURE-RELEASE-ACCEPTANCE.md);
die historischen partiellen Aufrufe bleiben unverändert.

[evidence-map.json](evidence-map.json) bindet die kanonischen Git-/LF-Bytes aller 45 Manifeste,
vorhandene Nachweisanzahl/-daten, zusätzliche Fixture-IDs und die
Quelländerungen seit der letzten Manifestpflege. Deren Commit ist ein
Vergleichssnapshot und **kein erfundener Ausführungscommit**. Solche Deltas
lösen eine fachliche Prüfung aus; sie erklären nicht automatisch sämtliche
alten Nachweise für ungültig. Die ausgelieferten Produktquellen und
qualifizierten SQL-/DLL-Payloads wurden vor der neuen Labwelle verglichen.

| Modul / kanonische Nachweise | Kanal | Bisherige Einträge | Zusätzliche Fixtures / Ergebnis | Quellvergleich seit letzter Manifestpflege |
|---|---|---:|---:|---|
| [archive.zip-files](../../Modules/toolbelt.archive.zip-files/module.yaml) | preview | 1 | keine neue API-Prüfung; Voraussetzungen separat | Delta; Datei-/Identitätsnachweis offen |
| [archive.zip-memory](../../Modules/toolbelt.archive.zip-memory/module.yaml) | preview | 7 | 5; ausgewählte Fixtures bestanden | keine kanonische Runtimeänderung |
| [binary.bit-operations](../../Modules/toolbelt.binary.bit-operations/module.yaml) | stable | 4 | 2; ausgewählte Fixtures bestanden | keine kanonische Runtimeänderung |
| [conversion.base64](../../Modules/toolbelt.conversion.base64/module.yaml) | stable | 9 | 2; ausgewählte Fixtures bestanden | keine kanonische Runtimeänderung |
| [conversion.integer-base](../../Modules/toolbelt.conversion.integer-base/module.yaml) | stable | 6 | 2; ausgewählte Fixtures bestanden | keine kanonische Runtimeänderung |
| [conversion.safe-cast](../../Modules/toolbelt.conversion.safe-cast/module.yaml) | preview | 5 | volle Matrix im bisherigen Scope wiederverwendet | keine kanonische Runtimeänderung |
| [conversion.uri-component](../../Modules/toolbelt.conversion.uri-component/module.yaml) | stable | 6 | 2; ausgewählte Fixtures bestanden | keine kanonische Runtimeänderung |
| [core.console-message](../../Modules/toolbelt.core.console-message/module.yaml) | stable | 6 | 2; ausgewählte Fixtures bestanden | keine kanonische Runtimeänderung |
| [core.error-envelope](../../Modules/toolbelt.core.error-envelope/module.yaml) | stable | 4 | 2; ausgewählte Fixtures bestanden | keine kanonische Runtimeänderung |
| [core.event-log](../../Modules/toolbelt.core.event-log/module.yaml) | preview | 4 | keine neue API-Prüfung; Voraussetzungen separat | Delta; Lifecycle geprüft, API-Voraussetzungen separat |
| [core.execution-cancel](../../Modules/toolbelt.core.execution-cancel/module.yaml) | preview | 3 | 2; ausgewählte Fixtures bestanden | Delta; ausgewählte Fixtures nativ geprüft |
| [core.execution-context](../../Modules/toolbelt.core.execution-context/module.yaml) | stable | 4 | 2; ausgewählte Fixtures bestanden; [fünf isolierte Objektrechte](EXECUTION-CONTEXT-RIGHTS-QUALIFICATION.md) separat | keine kanonische Runtimeänderung; lokaler/direkt zentraler Rechtetest bestanden |
| [core.generate-series](../../Modules/toolbelt.core.generate-series/module.yaml) | stable | 8 | 2; ausgewählte Fixtures bestanden | keine kanonische Runtimeänderung |
| [core.result-table](../../Modules/toolbelt.core.result-table/module.yaml) | stable | 9 | 2; ausgewählte Fixtures bestanden | keine kanonische Runtimeänderung |
| [core.second-session](../../Modules/toolbelt.core.second-session/module.yaml) | preview | 6 | keine neue API-Prüfung; Voraussetzungen separat | Delta; Datei-/Identitätsnachweis offen |
| [core.work-queue](../../Modules/toolbelt.core.work-queue/module.yaml) | preview | 6 | 1; ausgewählte Fixtures bestanden | Delta; ausgewählte Fixtures nativ geprüft |
| [core.work-type](../../Modules/toolbelt.core.work-type/module.yaml) | preview | 5 | 2; ausgewählte Fixtures bestanden | keine kanonische Runtimeänderung |
| [core.worker-control](../../Modules/toolbelt.core.worker-control/module.yaml) | preview | 4 | 1; ausgewählte Fixtures bestanden | keine kanonische Runtimeänderung |
| [datetime.bucket](../../Modules/toolbelt.datetime.bucket/module.yaml) | stable | 4 | 2; ausgewählte Fixtures bestanden | keine kanonische Runtimeänderung |
| [datetime.calendar-difference](../../Modules/toolbelt.datetime.calendar-difference/module.yaml) | stable | 5 | 2; ausgewählte Fixtures bestanden | keine kanonische Runtimeänderung |
| [datetime.date-spine](../../Modules/toolbelt.datetime.date-spine/module.yaml) | stable | 4 | 2; ausgewählte Fixtures bestanden | keine kanonische Runtimeänderung |
| [datetime.truncate](../../Modules/toolbelt.datetime.truncate/module.yaml) | stable | 4 | 2; ausgewählte Fixtures bestanden | keine kanonische Runtimeänderung |
| [file.content](../../Modules/toolbelt.file.content/module.yaml) | preview | 3 | keine neue API-Prüfung; Voraussetzungen separat | Delta; Datei-/Identitätsnachweis offen |
| [file.csv-memory](../../Modules/toolbelt.file.csv-memory/module.yaml) | preview | 72 | 40; ausgewählte Fixtures bestanden | keine kanonische Runtimeänderung |
| [file.xlsx-memory](../../Modules/toolbelt.file.xlsx-memory/module.yaml) | preview | 12 | 10; ausgewählte Fixtures bestanden | keine kanonische Runtimeänderung |
| [filesystem.windows](../../Modules/toolbelt.filesystem.windows/module.yaml) | preview | 9 | keine neue API-Prüfung; Voraussetzungen separat | keine kanonische Runtimeänderung |
| [json.constructors](../../Modules/toolbelt.json.constructors/module.yaml) | preview | 10 | 9; ausgewählte Fixtures bestanden | Delta; ausgewählte Fixtures nativ geprüft |
| [json.core](../../Modules/toolbelt.json.core/module.yaml) | preview | 3 | keine eigene SQL-API; Consumer geprüft | keine kanonische Runtimeänderung |
| [json.path-exists](../../Modules/toolbelt.json.path-exists/module.yaml) | stable | 5 | 2; ausgewählte Fixtures bestanden | keine kanonische Runtimeänderung |
| [json.pointer](../../Modules/toolbelt.json.pointer/module.yaml) | preview | 6 | volle Matrix im bisherigen Scope wiederverwendet | keine kanonische Runtimeänderung |
| [json.schema](../../Modules/toolbelt.json.schema/module.yaml) | preview | 10 | 3; ausgewählte Fixtures bestanden | keine kanonische Runtimeänderung |
| [metadata.capability-catalog](../../Modules/toolbelt.metadata.capability-catalog/module.yaml) | stable | 4 | 2; ausgewählte Fixtures bestanden | keine kanonische Runtimeänderung |
| [metadata.identifier](../../Modules/toolbelt.metadata.identifier/module.yaml) | stable | 5 | 2; ausgewählte Fixtures bestanden | keine kanonische Runtimeänderung |
| [metadata.table-clone](../../Modules/toolbelt.metadata.table-clone/module.yaml) | preview | 10 | 14; ausgewählte Fixtures bestanden | keine kanonische Runtimeänderung |
| [pseudonymization.deterministic](../../Modules/toolbelt.pseudonymization.deterministic/module.yaml) | preview | 4 | 9; ausgewählte Fixtures bestanden | keine kanonische Runtimeänderung |
| [string.directional-trim](../../Modules/toolbelt.string.directional-trim/module.yaml) | stable | 5 | 2; ausgewählte Fixtures bestanden | keine kanonische Runtimeänderung |
| [string.edit-distance](../../Modules/toolbelt.string.edit-distance/module.yaml) | preview | 3 | 5; ausgewählte Fixtures bestanden | Delta; ausgewählte Fixtures nativ geprüft |
| [string.phonetic](../../Modules/toolbelt.string.phonetic/module.yaml) | preview | 3 | 3; ausgewählte Fixtures bestanden | keine kanonische Runtimeänderung |
| [string.regex](../../Modules/toolbelt.string.regex/module.yaml) | preview | 7 | 8 historische Fixtures partiell; [Timeout-Nachprüfung](REGEX-TIMEOUT-QUALIFICATION.md) und [Skalarrechte](REGEX-RIGHTS-QUALIFICATION.md) separat | Literal-Replace-Grenzen und sechs Skalarrechte bestanden; Capture-Releasegate begrenzt angenommen, weitere Modulabnahme offen |
| [string.split-advanced](../../Modules/toolbelt.string.split-advanced/module.yaml) | preview | 3 | 4; ausgewählte Fixtures bestanden | keine kanonische Runtimeänderung |
| [string.split-characters](../../Modules/toolbelt.string.split-characters/module.yaml) | stable | 6 | 2; ausgewählte Fixtures bestanden | keine kanonische Runtimeänderung |
| [string.text-pairs](../../Modules/toolbelt.string.text-pairs/module.yaml) | preview | 2 | 5; ausgewählte Fixtures bestanden | keine kanonische Runtimeänderung |
| [tsql.script-parser](../../Modules/toolbelt.tsql.script-parser/module.yaml) | preview | 10 | 4; ausgewählte Fixtures bestanden | keine kanonische Runtimeänderung |
| [tsql.ssis-debug](../../Modules/toolbelt.tsql.ssis-debug/module.yaml) | preview | 4 | 2; ausgewählte Fixtures bestanden | keine kanonische Runtimeänderung |
| [validation.semantic-version](../../Modules/toolbelt.validation.semantic-version/module.yaml) | stable | 6 | 2; ausgewählte Fixtures bestanden | keine kanonische Runtimeänderung |

## Was sich aus der Zuordnung ergibt

Safe-Cast und JSON Pointer behalten ihre bereits ausgeführten vollständigen
physischen API-/Metadaten-/Lifecycle-Matrizen vom 2026-10-19. Die drei großen
Lastnachweise für ResultTable, Base64 und Generate Series und die volle
Paket-Lifecyclematrix bleiben getrennt gebunden. Optionale Laufzeitmessungen
sind kein Pflichtgate.

Die zusätzliche Welle ist mit 73 vollständigen und einem partiellen Fall
abgeschlossen. Die Ergebnisangaben beziehen sich ausschließlich auf die
ausgewählten Fixtures; die kanonischen Manifeststatus bleiben unverändert.

Bei CSV sind die Millionenzell-, Zeilen- und Spaltengrenzen auf zwei Zielen
bereits belegt; die pauschale Aussage „alle großen Grenzen offen“ wäre
falsch. Weitere Ziele und der gemeinsame Default-Bytefall wurden gezielt
ergänzt und bestanden. Der historische Regex-Teilnachweis bleibt erhalten.
Die [aktuelle Nachprüfung](REGEX-TIMEOUT-QUALIFICATION.md) belegt die
Literal-Replace-Korrektur und den ursprünglichen Transformationsabschluss
auf der neuen DLL. Das historische Capture-Timeout-Gate wurde anschließend
für die gebundene DLL mit ausdrücklich akzeptiertem Restrisiko
[begrenzt angenommen](CAPTURE-RELEASE-ACCEPTANCE.md); neue Minimalrechte lokal/
direkt zentral sind dort separat belegt. Die historische Projektion bleibt
unverändert; keine vollständige Regex-Modulfreigabe.
EventLog-/Edit-Distance-Deploymentänderungen haben bereits die getrennte
Paket-Lifecycleabnahme bestanden.

Die zusätzliche [Execution-Context-Rechteprüfung](EXECUTION-CONTEXT-RIGHTS-QUALIFICATION.md)
belegt alle fünf öffentlichen APIs mit jeweils einem einzelnen Objektrecht
auf zwölf Ziel-/CL-Kombinationen, lokal und direkt zentral. Sie verändert
keinen kanonischen Manifeststatus und ersetzt kein CrossDB-Identitätsmapping.

Die übrigen externen Voraussetzungen und die tatsächlichen Ergebnisse stehen
im [API-Bericht](API-QUALIFICATION.md#verbleibende-voraussetzungen) und im
[Release-Gatebericht](RELEASE-GATES.md#was-vor-veröffentlichung-offen-bleibt).
Die Modulmanifeste bleiben die Quelle für modulspezifische Pflichtfälle.

JSON Core exportiert keine eigenen SQL-Objekte. Seine native API-Einbindung
erfolgt über Constructors und Schema; eigene Assembly-/Lifecycle- und
Frameworknachweise bleiben separat im Modulmanifest verzeichnet.
