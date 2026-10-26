# Nachweiszuordnung aller 45 Module

[ZIP-Callerrechte](ZIP-CALLER-PROFILE.md): drei vorhandene öffentliche
Listing-/Extraktions-/Writer-USPs, zwölf lokale/direkt zentrale Ziel-/CL-Fälle,
432 Rechtezustände, 864 API-Routen, 192 positive feste Ergebniszeilen und
2.808 strikte SQL-229-Abweisungen. Eine frühere v1-Shape-Fixtureabweichung
bleibt getrennt erhalten; zwölf Matrixfälle und beide Kontrollen wurden
abschließend auditiert.

[XLSX-Raw-Callerrechte](XLSX-RAW-CALLER-PROFILE.md): zwei bestehende Rohleser-USPs, zwölf lokale/direkt zentrale Windows-/Linux-Ziel-/CL-Fälle, 336 Rechtemaskenzustände, 672 API-Routen und 720 feste Ergebniszeilen. Ein ursprünglicher Probe-Arityfehler bleibt getrennt von zwölf bestandenen Fällen und zwei gezielt abgewiesenen Kontrollen; 15 frische Abschlussaudits bestanden.

[XLSX-Manifest- und Paketpflege](XLSX-METADATA-UPDATE.md) bindet die Raw- und Zell-Callerrechte aus den unveränderten Berichten an das Modulmanifest und den bestehenden CLR-Satz. SQL- und DLL-Payloads bleiben bytegleich; der Modulstatus bleibt unverändert.

[XLSX-Zell-Callerrechte](XLSX-CELL-CALLER-QUALIFICATION.md): zwei öffentliche TVFs mit einzelnem SELECT auf zwölf lokalen/direkt zentralen Windows-/Linux-Ziel-/CL-Fällen.48 positive Profile,672 SQL229-Abweisungen und144 feste Ergebniszeilenorakel; Raw-Reader, volle Typ-/Client-/Ressourcen- und Releasegates bleiben separat.

[CSV-Manifest- und Paketpflege](CSV-METADATA-UPDATE.md): die in PR450 belegten getrennten Parser-/Writer-/ResultTable-Rechte werden exakt übernommen. Historische Ausführungspins bleiben erhalten; ausführbare SQL-/DLL-Payloads und weitere Releasegrenzen bleiben unverändert.

[CSV-Callerrechte](CSV-CALLER-PROFILE.md): getrennte Parser-/Writer-/ResultTable-Objektrechte, zwölf lokale/direkt zentrale Ziel-/CL-Fälle, 384 Rechtezustände, 504 feste Ergebniszeilenorakel und frische eigene Bereinigungsprüfungen. Manifest-/Paketpflege und weitere Releasegates bleiben separat.

Aktuelle [Caller-Metadatenbindung](CALLER-METADATA-UPDATE.md): sechs präzisierte
Manifeste; ursprüngliche native Ausführungspins bleiben unverändert.

[Textpaar-Callerrechte](TEXT-PAIRS-CALLER-QUALIFICATION.md): ein EXECUTE-Grant, drei Algorithmen, zwölf lokale/direkt zentrale Ziel-/CL-Fälle, 24 positive Profile und 216 SQL229-Abweisungen. 1008 feste Zeilenorakel und eigene Bereinigung sind belegt; weitergehende Gates bleiben separat.

[JSON-Schema-Callerrechte](JSON-SCHEMA-CALLER-PROFILE.md): drei einzelne Objektrechte, zwölf lokale/direkt zentrale Ziel-/CL-Fälle, 168 Rechtezustände und 240 feste Fachfälle. Neuer Labtreiber und SQL-Fixture; keine Produkt- oder Paketänderung. Die [gebundene Metadatenkorrektur](CALLER-METADATA-UPDATE.md) übernimmt diese Rechte jetzt in Manifest und Paket.

Die [SSIS-Qualifikation vom 2026-10-25](SSIS-LOOKUP-QUALIFICATION.md) ergänzt
zwölf explizite Windows-Engine-/CL-/Modusfälle, den finalen Installationssatz und
je sechs neue Windows-Fälle für CLR- und Gesamtpaket. Historische Manifest-/API-
Snapshots werden aus ihrer gebundenen früheren Lieferung gelesen. Unveränderte
Linux-Payloads behalten ihre ursprünglichen Nachweise; keine neue Linux-Ausführung
und keine automatische Modul- oder Gesamtfreigabe.

[CLR-String-Callerrechte](CLR-STRING-CALLER-QUALIFICATION.md): fünf vorhandene Phonetic-/Edit-Distance-TVFs, zwölf lokale/direkt zentrale Ziel-/CL-Fälle,120 positive Profile und1440 SQL229-Abweisungen. Entwickelt wurden Labtreiber, Sicherheitsprüfungen und feste SQL-Fixtures. Eigener Trust und notwendige Testkonfiguration sind unabhängig als bereinigt bestätigt; Produktquellen und Modulstatus bleiben unverändert.
Die [Event-Log-Callerprofile](EVENT-LOG-CALLER-QUALIFICATION.md) ergänzen View und zwei lokale Retention-APIs auf zwölf lokalen/direkt zentralen Ziel-/CL-Fällen: 72 Einzelgrantprofile, 648 SQL229-Abweisungen und exakter Rollback-Zeilenvergleich. Producer/RPC und weitere Modulpflichten bleiben separat.

Die [Providerview-Callerrechte](PROVIDER-CALLER-QUALIFICATION.md) ergänzen zwölf lokale/direkt zentrale Ziel-/CL-Fälle mit einem SELECT und rein synthetischem deaktiviertem Datensatz. Reale Linked-Server-Konfiguration, Loginmapping, RPC und neue Sessions bleiben separat.

Die jüngeren Callerberichte ergänzen diese historische Modulzuordnung:
[JSON-Pfade](JSON-PATH-CALLER-QUALIFICATION.md),
[Konsolenausgabe](CONSOLE-CALLER-QUALIFICATION.md),
[Capability-Katalog](CATALOG-CALLER-QUALIFICATION.md) und
[JSON Pointer](POINTER-CALLER-QUALIFICATION.md). Ihre jeweils zwölf lokalen/direkt
zentralen Ziel-/CL-Fälle und engen Rechteprofile sind getrennt gebunden. Sie
ersetzen weder die ursprüngliche JSON-Projektion noch übrige API-/Lifecycle-,
Client-, Ressourcen-, Identitäts- oder Veröffentlichungsgates.

Die [eigenständige Stable-SQL-Lieferform](STABLE-SQL-INSTALL.md) bindet ihre
beiden SQL-Dateien bytegleich an die vorhandene native Paketqualifikation.
Die neue ZIP-Verpackung ist offline geprüft; weitergehende API-/Modul-, GUI-
und Identitätsabnahmen werden daraus nicht abgeleitet.

Diese Zuordnung verknüpft den eingefrorenen Releasekandidaten mit den
kanonischen `validation_evidence`-Einträgen der Modulmanifeste und den
[zusätzlichen API-/Grenzprüfungen](API-QUALIFICATION.md). Die originale
Beschreibung jedes Nachweises begrenzt seinen Scope; ein aktueller grüner
Pakettest ersetzt sie nicht. Kein Modul wird hierdurch hochgestuft.

Die [ursprünglichen Split-Advanced-Callerrechte](SPLIT-ADVANCED-RIGHTS-QUALIFICATION.md)
umfassen sechs physische Ziele bei höchstem CL. Der
[CL-Abschluss vom 2026-10-25](SPLIT-ADVANCED-CL-COMPLETION.md) ergänzt sechs
niedrigere CL-Fälle bei identischen Ausführungsinputs; zusammen zwölf
lokale/direkt zentrale Ziel-/CL-Kombinationen genau dieser Callerprofile.

Die [Queue-Frontend-Callerrechte vom 2026-10-25](QUEUE-FRONTEND-RIGHTS-QUALIFICATION.md)
ergänzen fünf Einzelgrants und einen Legacyproducer mit zusätzlicher
Handler-Metadatensicht. Die [Worker-Callerrechte](QUEUE-WORKER-RIGHTS-QUALIFICATION.md)
fügen sieben Worker-APIs und die befüllte Blockerview auf zwölf lokalen/direkt
zentralen Ziel-/CL-Kombinationen hinzu. Provider-/Managed-/Ausgabevarianten
und frühere Policyfälle behalten ihren eigenen Scope.

Die [zusätzliche Geo-SQL-Matrix](GEO-MISSING-TARGETS-QUALIFICATION.md) ergänzt
acht bisher fehlende Ziel-/CL-Kombinationen lokal/direkt zentral mit unveränderten
Geo-/Safety-/SQL-Metadatenverträgen. Sie erweitert weder historische
Client-/Lifecycle-Abnahmen noch den Modulstatus oder die Veröffentlichung.

Die [Konvertierungs-Callerprofile](CONVERSION-CALLER-QUALIFICATION.md) ergänzen
16 öffentliche Base64-/IntegerBase-/URI-Funktionen einschließlich Status-TVFs
und Scalarwrappern: zwölf lokale/direkt zentrale Ziel-/CL-Fälle mit einzelnen
SELECT-/EXECUTE-Grants. Veraltete pauschale Manifestlabels bleiben ausdrücklich
als getrennte Metadaten-/Paketlücke dokumentiert; keine Statusaufwertung.

Die [Series-/Datums-Callerprofile](SERIES-DATE-CALLER-QUALIFICATION.md) ergänzen
neun öffentliche GenerateSeries-/DateSpine-/Truncate-TVFs einschließlich der
begrenzten Series-Status-API. Zwölf lokale/direkt zentrale Ziel-/CL-Fälle belegen
je ein SELECT; interne Core-/Helperrechte und andere APIs bleiben getrennt.
Keine Erweiterung alter Last-/Client-/Lifecycle- oder CrossDB-Nachweise.

Die [Utility-Callerprofile](UTILITY-CALLER-QUALIFICATION.md) ergänzen16 öffentliche
Bit-/Trim-/Split-/Identifier-/SemVer-Funktionen mit getrennten SELECT-/EXECUTE-
Grants auf zwölf lokalen/direkt zentralen Ziel-/CL-Kombinationen. Opake Sort Keys
werden nach ihrem Ordnungsvertrag geprüft; breite Rechte bleiben ausgeschlossen.
Andere API-/Ressourcen-/Lifecycle- und Paket-/Metadatengates bleiben separat.

Die [ausgewählten Date-Math-Callerprofile](DATE-MATH-HIGHEST-CL-QUALIFICATION.md)
belegen vier TVFs auf Windows/Linux SQL2019/CL150,SQL2022/CL160 undSQL2025/CL170
lokal/direkt zentral als historischen Teilscope. Die [additive Ergänzung](DATE-MATH-CL-COMPLETION.md)
schließt inzwischen die sechs niedrigeren CL-Fälle mit identischen Inputs; die
Caller-Matrix umfasst zwölf Fälle. Weitere Modulpflichten und Status bleiben separat.

Die [Pseudonymisierungs-Callerrechte vom 2026-10-25](DETERMINISTIC-RIGHTS-QUALIFICATION.md)
ergänzen fünf isolierte API-Grants und einen gesonderten Lookup-/Helperpfad
lokal/direkt zentral auf zwölf Ziel-/CL-Kombinationen; keine volle Modulabnahme.

Die [Cancellation-Callerrechte vom 2026-10-25](CANCELLATION-RIGHTS-QUALIFICATION.md)
ergänzen drei isolierte API-Profile lokal/direkt zentral auf zwölf Ziel-/CL-
Kombinationen. Historische Vollmatrizen, Manifest-Snapshots und weitere
Quoten-/Lifecycle-/Recoverygates behalten ihren eigenen Scope.

Die [Safe-Cast-Callerrechte vom 2026-10-25](SAFE-CAST-RIGHTS-QUALIFICATION.md)
ergänzen für die sechs TVFs zwölf lokale/direkt zentrale Ziel-/CL-Fälle mit
genau einem SELECT und sieben festen Datenorakeln je positivem Profil.
Historische Manifest-Snapshots und Paketnachweise bleiben unverändert.

Der [Queue-Autorisierungsvertrag vom 2026-10-25](QUEUE-AUTHORIZATION-QUALIFICATION.md)
ergänzt auf zwölf Ziel-/CL-Kombinationen lokal/direkt zentral die Producer-,
Handler-, DENY-/Idempotenz- und Callertransaktionsprofile. Vollständige isolierte
API-Minimalrechte und externe Worker-/Recoveryfälle bleiben offen.

Die [Work-Type-Rechtequalifikation vom 2026-10-25](WORK-TYPE-RIGHTS-QUALIFICATION.md)
ergänzt sechs öffentliche Callerprofile auf zwölf Ziel-/CL-Kombinationen lokal
und direkt zentral. Sie verändert weder den historischen Manifest-Snapshot
noch die Paketbytes oder Modulstatuswerte.

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

Die zusätzliche [ResultTable-/Error-Envelope-Callerprüfung](TABLE-ENVELOPE-RIGHTS-INVESTIGATION.md)
belegt fünf enge Callerprofile auf zwölf Ziel-/CL-Kombinationen lokal und direkt
zentral: 120 Profilszenarien und 360 strikte Rechteabweisungen. Die aktuelle
[Qualifikation](table-envelope-rights-qualification.json) und vier historische
bereinigte Fehlversuche bleiben getrennt. Bestehende Modulnachweise behalten
ihren ursprünglichen Scope; keine CrossDB-Identitäts- oder Vollfreigabe.

JSON Core exportiert keine eigenen SQL-Objekte. Seine native API-Einbindung
erfolgt über Constructors und Schema; eigene Assembly-/Lifecycle- und
Frameworknachweise bleiben separat im Modulmanifest verzeichnet.
