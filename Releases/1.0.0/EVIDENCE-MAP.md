# Nachweiszuordnung aller 45 Module

Diese Zuordnung verknüpft den eingefrorenen Releasekandidaten mit den
kanonischen `validation_evidence`-Einträgen der Modulmanifeste und den
[zusätzlichen API-/Grenzprüfungen](API-QUALIFICATION.md). Die originale
Beschreibung jedes Nachweises begrenzt seinen Scope; ein aktueller grüner
Pakettest ersetzt sie nicht. Kein Modul wird hierdurch hochgestuft.

[evidence-map.json](evidence-map.json) bindet die kanonischen Git-/LF-Bytes aller 45 Manifeste,
vorhandene Nachweisanzahl/-daten, zusätzliche Fixture-IDs und die
Quelländerungen seit der letzten Manifestpflege. Deren Commit ist ein
Vergleichssnapshot und **kein erfundener Ausführungscommit**. Solche Deltas
lösen eine fachliche Prüfung aus; sie erklären nicht automatisch sämtliche
alten Nachweise für ungültig. Die ausgelieferten Produktquellen und
qualifizierten SQL-/DLL-Payloads wurden vor der neuen Labwelle verglichen.

| Modul / kanonische Nachweise | Kanal | Bisherige Einträge | Zusätzliche Fixturedefinitionen | Quellvergleich seit letzter Manifestpflege |
|---|---|---:|---:|---|
| [archive.zip-files](../../Modules/toolbelt.archive.zip-files/module.yaml) | preview | 1 | Voraussetzungen separat | Delta zu prüfen; siehe JSON |
| [archive.zip-memory](../../Modules/toolbelt.archive.zip-memory/module.yaml) | preview | 7 | 5 | keine kanonische Runtimeänderung |
| [binary.bit-operations](../../Modules/toolbelt.binary.bit-operations/module.yaml) | stable | 4 | 2 | keine kanonische Runtimeänderung |
| [conversion.base64](../../Modules/toolbelt.conversion.base64/module.yaml) | stable | 9 | 2 | keine kanonische Runtimeänderung |
| [conversion.integer-base](../../Modules/toolbelt.conversion.integer-base/module.yaml) | stable | 6 | 2 | keine kanonische Runtimeänderung |
| [conversion.safe-cast](../../Modules/toolbelt.conversion.safe-cast/module.yaml) | preview | 5 | volle Matrix wiederverwendet | keine kanonische Runtimeänderung |
| [conversion.uri-component](../../Modules/toolbelt.conversion.uri-component/module.yaml) | stable | 6 | 2 | keine kanonische Runtimeänderung |
| [core.console-message](../../Modules/toolbelt.core.console-message/module.yaml) | stable | 6 | 2 | keine kanonische Runtimeänderung |
| [core.error-envelope](../../Modules/toolbelt.core.error-envelope/module.yaml) | stable | 4 | 2 | keine kanonische Runtimeänderung |
| [core.event-log](../../Modules/toolbelt.core.event-log/module.yaml) | preview | 4 | Voraussetzungen separat | Delta zu prüfen; siehe JSON |
| [core.execution-cancel](../../Modules/toolbelt.core.execution-cancel/module.yaml) | preview | 3 | 1 | Delta zu prüfen; siehe JSON |
| [core.execution-context](../../Modules/toolbelt.core.execution-context/module.yaml) | stable | 4 | 2 | keine kanonische Runtimeänderung |
| [core.generate-series](../../Modules/toolbelt.core.generate-series/module.yaml) | stable | 8 | 2 | keine kanonische Runtimeänderung |
| [core.result-table](../../Modules/toolbelt.core.result-table/module.yaml) | stable | 9 | 2 | keine kanonische Runtimeänderung |
| [core.second-session](../../Modules/toolbelt.core.second-session/module.yaml) | preview | 6 | Voraussetzungen separat | Delta zu prüfen; siehe JSON |
| [core.work-queue](../../Modules/toolbelt.core.work-queue/module.yaml) | preview | 6 | 1 | Delta zu prüfen; siehe JSON |
| [core.work-type](../../Modules/toolbelt.core.work-type/module.yaml) | preview | 5 | 2 | keine kanonische Runtimeänderung |
| [core.worker-control](../../Modules/toolbelt.core.worker-control/module.yaml) | preview | 4 | 1 | keine kanonische Runtimeänderung |
| [datetime.bucket](../../Modules/toolbelt.datetime.bucket/module.yaml) | stable | 4 | 2 | keine kanonische Runtimeänderung |
| [datetime.calendar-difference](../../Modules/toolbelt.datetime.calendar-difference/module.yaml) | stable | 5 | 2 | keine kanonische Runtimeänderung |
| [datetime.date-spine](../../Modules/toolbelt.datetime.date-spine/module.yaml) | stable | 4 | 2 | keine kanonische Runtimeänderung |
| [datetime.truncate](../../Modules/toolbelt.datetime.truncate/module.yaml) | stable | 4 | 2 | keine kanonische Runtimeänderung |
| [file.content](../../Modules/toolbelt.file.content/module.yaml) | preview | 3 | Voraussetzungen separat | Delta zu prüfen; siehe JSON |
| [file.csv-memory](../../Modules/toolbelt.file.csv-memory/module.yaml) | preview | 72 | 40 | keine kanonische Runtimeänderung |
| [file.xlsx-memory](../../Modules/toolbelt.file.xlsx-memory/module.yaml) | preview | 12 | 10 | keine kanonische Runtimeänderung |
| [filesystem.windows](../../Modules/toolbelt.filesystem.windows/module.yaml) | preview | 9 | Voraussetzungen separat | keine kanonische Runtimeänderung |
| [json.constructors](../../Modules/toolbelt.json.constructors/module.yaml) | preview | 10 | 9 | Delta zu prüfen; siehe JSON |
| [json.core](../../Modules/toolbelt.json.core/module.yaml) | preview | 3 | keine SQL-API; technische Dependency | keine kanonische Runtimeänderung |
| [json.path-exists](../../Modules/toolbelt.json.path-exists/module.yaml) | stable | 5 | 2 | keine kanonische Runtimeänderung |
| [json.pointer](../../Modules/toolbelt.json.pointer/module.yaml) | preview | 6 | volle Matrix wiederverwendet | keine kanonische Runtimeänderung |
| [json.schema](../../Modules/toolbelt.json.schema/module.yaml) | preview | 10 | 3 | keine kanonische Runtimeänderung |
| [metadata.capability-catalog](../../Modules/toolbelt.metadata.capability-catalog/module.yaml) | stable | 4 | 2 | keine kanonische Runtimeänderung |
| [metadata.identifier](../../Modules/toolbelt.metadata.identifier/module.yaml) | stable | 5 | 2 | keine kanonische Runtimeänderung |
| [metadata.table-clone](../../Modules/toolbelt.metadata.table-clone/module.yaml) | preview | 10 | 14 | keine kanonische Runtimeänderung |
| [pseudonymization.deterministic](../../Modules/toolbelt.pseudonymization.deterministic/module.yaml) | preview | 4 | 9 | keine kanonische Runtimeänderung |
| [string.directional-trim](../../Modules/toolbelt.string.directional-trim/module.yaml) | stable | 5 | 2 | keine kanonische Runtimeänderung |
| [string.edit-distance](../../Modules/toolbelt.string.edit-distance/module.yaml) | preview | 3 | 5 | Delta zu prüfen; siehe JSON |
| [string.phonetic](../../Modules/toolbelt.string.phonetic/module.yaml) | preview | 3 | 3 | keine kanonische Runtimeänderung |
| [string.regex](../../Modules/toolbelt.string.regex/module.yaml) | preview | 5 | 8 | Delta zu prüfen; siehe JSON |
| [string.split-advanced](../../Modules/toolbelt.string.split-advanced/module.yaml) | preview | 3 | 4 | keine kanonische Runtimeänderung |
| [string.split-characters](../../Modules/toolbelt.string.split-characters/module.yaml) | stable | 6 | 2 | keine kanonische Runtimeänderung |
| [string.text-pairs](../../Modules/toolbelt.string.text-pairs/module.yaml) | preview | 2 | 5 | keine kanonische Runtimeänderung |
| [tsql.script-parser](../../Modules/toolbelt.tsql.script-parser/module.yaml) | preview | 10 | 4 | keine kanonische Runtimeänderung |
| [tsql.ssis-debug](../../Modules/toolbelt.tsql.ssis-debug/module.yaml) | preview | 4 | 2 | keine kanonische Runtimeänderung |
| [validation.semantic-version](../../Modules/toolbelt.validation.semantic-version/module.yaml) | stable | 6 | 2 | keine kanonische Runtimeänderung |

## Was sich aus der Zuordnung ergibt

Safe-Cast und JSON Pointer behalten ihre bereits ausgeführten vollständigen
physischen API-/Metadaten-/Lifecycle-Matrizen vom 2026-10-19. Die drei großen
Lastnachweise für ResultTable, Base64 und Generate Series und die volle
Paket-Lifecyclematrix bleiben getrennt gebunden. Optionale Laufzeitmessungen
sind kein Pflichtgate.

Bei CSV sind die Millionenzell-, Zeilen- und Spaltengrenzen auf zwei Zielen
bereits belegt; die pauschale Aussage „alle großen Grenzen offen“ wäre
falsch. Weitere Ziele und der gemeinsame Default-Bytefall sind gezielt in
der neuen Liste ausgewählt. Bei Regex gab es seit dem älteren Manifest-
Snapshot Runtimeänderungen; die vorhandenen Frameworktests allein ersetzen
daher keine native Bindung der zusätzlichen API-/Metadaten-/Grenzfälle.
EventLog-/Edit-Distance-Deploymentänderungen haben bereits die getrennte
Paket-Lifecycleabnahme bestanden.

Die übrigen externen Voraussetzungen und die tatsächlichen Ergebnisse stehen
im [API-Bericht](API-QUALIFICATION.md#verbleibende-voraussetzungen) und im
[Release-Gatebericht](RELEASE-GATES.md#was-vor-veröffentlichung-offen-bleibt).
Die Modulmanifeste bleiben die Quelle für modulspezifische Pflichtfälle.

JSON Core exportiert keine eigenen SQL-Objekte. Seine native APIeinbindung
erfolgt über Constructors und Schema; eigene Assembly-/Lifecycle- und
Frameworknachweise bleiben separat im Modulmanifest verzeichnet.
