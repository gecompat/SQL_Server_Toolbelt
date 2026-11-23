# Die passende Toolbelt-Funktion finden

Wähle die Aufgabe und öffne den passenden Einstieg. Die Objektseite beschreibt
die erforderlichen Module und Rechte, den Aufruf und die Interpretation des
Ergebnisses. Für weitere Objekte derselben Familie suche nach deren Namen in der
[SQL-Objektreferenz](Reference/README.md).

## Zeichenketten, Konvertierung und Vergleich

| Aufgabe | Funktion und Abgrenzung |
|---|---|
| Text an einzelnen Trennzeichen aufteilen | [Split Characters](../Modules/toolbelt.string.split-characters/Documentation/TVF_SplitByCharacters.md) behandelt die übergebenen Zeichen einzeln. Für mehrstellige Trenner, Quotes und Escape-Sequenzen eignet sich [Split Advanced](../Modules/toolbelt.string.split-advanced/Documentation/TVF_SplitAdvanced.md). |
| Strukturierte CSV-Daten verarbeiten | [CSV lesen](../Modules/toolbelt.file.csv-memory/Documentation/USP_ParseCsv.md) und [CSV schreiben](../Modules/toolbelt.file.csv-memory/Documentation/USP_WriteCsv.md) arbeiten mit ganzen Datensätzen im Speicher. |
| Zeichen links, rechts oder beidseitig entfernen | [Directional Trim](../Modules/toolbelt.string.directional-trim/Documentation/TVF_TrimDirectionalNvarchar.md) arbeitet an den Rändern des Texts. |
| Muster suchen, ersetzen und zerlegen | [Regex](../Modules/toolbelt.string.regex/Documentation/REGEX_FUNCTIONS.md) bietet Prädikat, Trefferpositionen, Gruppen, Ersetzung und Split. Für wörtliche Trenner ist eine Split-Funktion einfacher. |
| Zwei Texte nach Schreibähnlichkeit vergleichen | [Levenshtein](../Modules/toolbelt.string.edit-distance/Documentation/TVF_LevenshteinDistance.md) zählt Editierschritte, [OSA](../Modules/toolbelt.string.edit-distance/Documentation/TVF_OsaDistance.md) berücksichtigt benachbarte Vertauschungen und [Jaro-Winkler](../Modules/toolbelt.string.edit-distance/Documentation/TVF_JaroWinklerSimilarity.md) bewertet Ähnlichkeit mit Präfixgewichtung. [Textpaare](../Modules/toolbelt.string.text-pairs/Documentation/USP_CompareTextPairs.md) verarbeitet vorgegebene Paare gesammelt. |
| Namen nach Aussprache zuordnen | [Kölner Phonetik](../Modules/toolbelt.string.phonetic/Documentation/TVF_ColognePhonetic.md) eignet sich für deutschsprachige Namen. [Double Metaphone](../Modules/toolbelt.string.phonetic/Documentation/TVF_DoubleMetaphone.md) liefert primäre und alternative Lautschlüssel. Ein passender Schlüssel ist ein Suchkriterium. |
| Bytes für einen Texttransport kodieren | [Base64 und Base64URL](../Modules/toolbelt.conversion.base64/Documentation/TVF_Base64Encode.md) kodieren Bytes. Die [Decode-Statusfunktion](../Modules/toolbelt.conversion.base64/Documentation/TVF_Base64DecodeStatus.md) erklärt fehlerhafte Eingaben. |
| Einzelne URI-Komponenten kodieren | [URI Component](../Modules/toolbelt.conversion.uri-component/Documentation/TVF_UriComponentEncode.md) kodiert eine Komponente. URL-Pfade und Queryparameter vorher in ihre Bestandteile trennen. |
| Ganzzahl in einer anderen Basis schreiben oder lesen | [Integer Base](../Modules/toolbelt.conversion.integer-base/Documentation/TVF_IntegerToBase.md) wandelt Zahlendarstellungen um. |
| Texteingaben streng typisieren und Fehler erkennen | [Safe Casts](../Modules/toolbelt.conversion.safe-cast/Documentation/TVF_TryCastDecimal.md) prüfen dokumentierte Eingabeformate. Die Referenz führt auch zu Datum, Datum/Uhrzeit, Ganzzahl, Bit und GUID. |
| Bits aus einer `bigint`-Maske lesen oder setzen | [Bit Operations](../Modules/toolbelt.binary.bit-operations/Documentation/TVF_GetBitBigInt.md) bietet Get/Set, Shift und BitCount. |
| Softwareversionen nach SemVer vergleichen und sortieren | [Semantic Version](../Modules/toolbelt.validation.semantic-version/Documentation/TVF_ParseSemanticVersion.md) prüft die Syntax. [CompareSemanticVersion](../Modules/toolbelt.validation.semantic-version/Documentation/TVF_CompareSemanticVersion.md) vergleicht die Reihenfolge nach SemVer. |

## Zahlenreihen, Datum und Zeit

| Aufgabe | Funktion und Abgrenzung |
|---|---|
| Ganze Zahlen als Zeilen ausgeben | [Generate Series](../Modules/toolbelt.core.generate-series/Documentation/TVF_GenerateSeriesBigInt.md) erzeugt eine begrenzte Reihe mit Schrittweite. |
| Kalendertage, ISO-Wochen oder Monate als Zeilen erzeugen | [Date Spine](../Modules/toolbelt.datetime.date-spine/Documentation/TVF_DateSpineDay.md) erzeugt Kalenderzeilen für Berichte, auch für Zeiträume ohne vorhandene Fakten. |
| Einen Zeitwert kürzen | [Truncate](../Modules/toolbelt.datetime.truncate/Documentation/TVF_TruncateDateTime2.md) setzt ihn auf den Anfang der gewählten Kalender- oder Zeiteinheit. |
| Einen Zeitwert benutzerdefinierten Intervallen zuordnen | [Bucket](../Modules/toolbelt.datetime.bucket/Documentation/TVF_DateBucketDateTime2.md) verwendet eine Intervallbreite und einen Ursprung. |
| Eine Zeitspanne in Kalendereinheiten aufteilen | [Calendar Difference](../Modules/toolbelt.datetime.calendar-difference/Documentation/TVF_CalendarDifference.md) beschreibt eine Kalenderdifferenz. |

## JSON, CSV, XLSX, ZIP und Dateien

| Aufgabe | Funktion und Abgrenzung |
|---|---|
| Einen RFC-6901-JSON-Pointer auflösen | [JSON Pointer](../Modules/toolbelt.json.pointer/Documentation/TVF_ResolveJsonPointer.md) navigiert zu dem per Pointer adressierten Element. |
| Prüfen, ob ein SQL-JSON-Pfad vorhanden ist | [JSON Path Exists](../Modules/toolbelt.json.path-exists/Documentation/TVF_JsonPathExistsStatus.md) verwendet die dokumentierte Pfadsyntax und liefert Statusinformationen. |
| JSON-Arrays und -Objekte erzeugen | [JSON Constructors](../Modules/toolbelt.json.constructors/Documentation/JSON_AGGREGATES.md) bietet Aggregate und Prozeduren für Zeilen und Gruppen. `toolbelt.json.core` ist eine gemeinsame Installationsabhängigkeit ohne öffentlichen Aufruf. |
| JSON gegen Regeln prüfen | [JSON Schema](../Modules/toolbelt.json.schema/Documentation/USP_ValidateJsonSchema.md) validiert gegen die dokumentierte Schema-Teilmenge und liefert Fehlerdetails. |
| Eine XLSX-Datei aus Bytes auswerten | [Arbeitsblätter auflisten](../Modules/toolbelt.file.xlsx-memory/Documentation/USP_ListXlsxWorksheets.md), [Zellen lesen](../Modules/toolbelt.file.xlsx-memory/Documentation/USP_ReadXlsxWorksheetCells.md) und bei Bedarf [Zellwerte interpretieren](../Modules/toolbelt.file.xlsx-memory/Documentation/TVF_InterpretXlsxCell.md). Eingabe ist das XLSX-Binary. |
| ZIP-Inhalt im Speicher auflisten, lesen oder erstellen | [ZIP-Einträge auflisten](../Modules/toolbelt.archive.zip-memory/Documentation/USP_ListZipEntriesFromBinary.md), [einzelnen Eintrag lesen](../Modules/toolbelt.archive.zip-memory/Documentation/USP_ExtractZipEntryFromBinary.md) oder [Archiv erstellen](../Modules/toolbelt.archive.zip-memory/Documentation/USP_CreateZipFromEntries.md). |
| ZIP auf dem Windows-Dateisystem schreiben oder auspacken | [ZIP-Dateifassaden](../Modules/toolbelt.archive.zip-files/Documentation/USP_ExtractZipArchiveToDirectory.md) verwenden einen eingerichteten Zielroot. Wähle bei Bedarf [Einzel-Entry](../Modules/toolbelt.archive.zip-files/Documentation/USP_ExtractZipEntryToFile.md) oder [Datei-Writer](../Modules/toolbelt.archive.zip-files/Documentation/USP_CreateZipFileFromEntries.md). Überschreiben erfordert die im Vertrag beschriebene exklusive Schreibhoheit. |
| Eine Datei über SQL als Text oder Bytes laden | [File Content](../Modules/toolbelt.file.content/Documentation/USP_LoadBinaryFile.md) und [Text laden](../Modules/toolbelt.file.content/Documentation/USP_LoadTextFile.md) arbeiten mit konfigurierten Roots. Das Dateisystem und die Berechtigungen des SQL-Servers sind maßgeblich. |
| Dateien und Verzeichnisse auf Windows verwalten | [Windows Filesystem](../Modules/toolbelt.filesystem.windows/Documentation/WINDOWS_FILESYSTEM_PROCEDURES.md) deckt Verzeichnisse, stückweises Lesen, Schreiben, Entfernen und Umkodieren ab. Identität und Rechte gelten je Root. |

## SQL-Entwicklung und Datenaufbereitung

| Aufgabe | Funktion und Abgrenzung |
|---|---|
| Mehrteilige SQL-Bezeichner zerlegen oder quotieren | [Identifier](../Modules/toolbelt.metadata.identifier/Documentation/TVF_ParseMultipartName.md) zerlegt Namen. [QuoteMultipartName](../Modules/toolbelt.metadata.identifier/Documentation/SVF_QuoteMultipartName.md) gibt einen passend quotierten Namen zurück. |
| SQL-Texte tokenisieren oder syntaktisch untersuchen | [T-SQL Parser](../Modules/toolbelt.tsql.script-parser/Documentation/TVF_ParseScriptNodes.md) liefert Syntaxknoten, [TokenizeScript](../Modules/toolbelt.tsql.script-parser/Documentation/TVF_TokenizeScript.md) Tokens und [ParseScriptErrors](../Modules/toolbelt.tsql.script-parser/Documentation/TVF_ParseScriptErrors.md) Syntaxfehler. |
| DTSX-Datenflüsse nachvollziehen | [SSIS Debug SQL](../Modules/toolbelt.tsql.ssis-debug/Documentation/LocalCteDebug.md) erzeugt SQL aus Paketmetadaten. Startwerte, Stufen, Dummyquellen und manuelle Ausführung werden dort erklärt. |
| Tabellendefinition prüfen, nachbauen oder Daten kopieren | [Clone planen](../Modules/toolbelt.metadata.table-clone/Documentation/USP_ScriptTableClone.md), [Plan ausführen](../Modules/toolbelt.metadata.table-clone/Documentation/USP_ExecuteTableClone.md) und [Daten kopieren](../Modules/toolbelt.metadata.table-clone/Documentation/USP_CopyTableCloneData.md) sind getrennte Schritte mit eigenen Rechten. |
| Prozedurergebnisse in einer Tabelle aufnehmen | [Result Table](../Modules/toolbelt.core.result-table/Documentation/USP_PrepareResultTable.md) prüft und bereitet das Ziel gemäß dem vereinbarten Schema vor. |
| Wiederholbare synthetische Werte ableiten | [Deterministic Range](../Modules/toolbelt.pseudonymization.deterministic/Documentation/TVF_DeterministicRange.md) und [Lookup](../Modules/toolbelt.pseudonymization.deterministic/Documentation/USP_DeterministicLookup.md) ordnen Werte reproduzierbar zu. Die Referenz umfasst auch Zeichenersetzung, Datumsverschiebung und Geo-Jitter. |
| Toolbelt-Fähigkeiten und Objektverträge lesen | [Module Capabilities](../Modules/toolbelt.metadata.capability-catalog/Documentation/VW_ModuleCapabilities.md) beschreibt Module. [Object Usage Skills](../Modules/toolbelt.metadata.capability-catalog/Documentation/VW_ObjectUsageSkills.md) liefert Anleitungen zu einzelnen Objekten. |

## Sitzungen, Hintergrundarbeit und Meldungen

| Aufgabe | Funktion und Abgrenzung |
|---|---|
| Einen Ablauf mit einer Ausführungs-ID verknüpfen | [Execution Context](../Modules/toolbelt.core.execution-context/Documentation/EXECUTION_CONTEXT_OBJECTS.md) verwaltet den Kontext in der Sitzung. |
| Einen laufenden Handler kooperativ stoppen | [Execution Cancellation](../Modules/toolbelt.core.execution-cancel/Documentation/EXECUTION_CANCELLATION_OBJECTS.md) signalisiert den Abbruch. Der Handler prüft das Signal und reagiert darauf. |
| Ein Ereignis außerhalb des Caller-Rollbacks aufzeichnen | [Event Log](../Modules/toolbelt.core.event-log/Documentation/USP_WriteEvent.md) verwendet den beschriebenen separaten Sitzungsweg. [Events lesen](../Modules/toolbelt.core.event-log/Documentation/VW_Events.md) und Aufbewahrung beachten. |
| Nachrichten im SQL-Client anzeigen | [Console Message](../Modules/toolbelt.core.console-message/Documentation/USP_WriteConsoleMessage.md) formatiert Meldungen für den Client. Dauerhafte Ereignisse gehören ins Event Log. |
| Angaben zu einem gefangenen SQL-Fehler strukturieren | [Error Envelope](../Modules/toolbelt.core.error-envelope/Documentation/USP_CaptureErrorEnvelope.md) erfasst Fehlerinformationen für die weitere Behandlung. |
| Zugelassene Handler registrieren und berechtigen | [Work Type](../Modules/toolbelt.core.work-type/Documentation/WORK_TYPE_OBJECTS.md) definiert ausführbare Auftragsarten und deren Rechte. |
| Einen registrierten Handler in einer anderen SQL-Sitzung aufrufen | [Second Session](../Modules/toolbelt.core.second-session/Documentation/USP_ExecuteWorkTypeInNewSession.md) verwendet einen eingerichteten Provider mit eigenem Berechtigungsvertrag. |
| Arbeit transaktional einreihen und abarbeiten | [Work Queue](../Modules/toolbelt.core.work-queue/Documentation/USAGE.md) erklärt Enqueue, Claims, Leases, Retry, Dead Letter und Barriers. |
| Worker-Kapazität, Ausführung und Wiederanlauf steuern | [Worker Control](../Modules/toolbelt.core.worker-control/Documentation/USP_EnableManagedWorkers.md) ergänzt die Queue um [Managedbetrieb, Parallelität, Stop und Wiederfreigabe](../Workers/ExternalQueue/USAGE.md). |

[Zur Bedienerdokumentation](README.md) · [Installation](../INSTALL.md)
