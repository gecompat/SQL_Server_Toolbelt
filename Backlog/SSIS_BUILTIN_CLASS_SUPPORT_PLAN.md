# SSIS built-in Klassenabdeckung und Entwicklungsplan

Stand: 2026-11-13 · Status: Inventur und Erweiterungsplanung; Copy Column V1 ausdrücklich freigegeben und im Source umgesetzt; getrennte Explain-/Prozedurguard-Deltaabnahme bestanden.

## Ziel und belastbare Grenze

Ziel ist die möglichst breite, sauber abgegrenzte Unterstützung der eingebauten SSIS-Paketklassen in den bereits unterstützten DTSX-Formaten. „Vollständig“ bedeutet hier: jede eingebaute Klasse wird erkannt, identifiziert und mit Herkunft/Version diagnostiziert; eine Klasse wird nur dann in Debug-SQL oder eine Prozedur übersetzt, wenn ihre Semantik im Toolbelt-Vertrag implementiert und qualifiziert ist. Unbekannte, benutzerdefinierte, Drittanbieter- oder versionsfremde Klassen bleiben sichtbar und `unsupported`; sie werden niemals stillschweigend als ausführbar behandelt. Microsoft beschreibt ausdrücklich erweiterbare Custom Tasks und Custom Transformations, daher gibt es keinen endlichen universellen Plugin-Katalog.

Der aktuelle SSIS-Debug-Vertrag gilt für die bestehende USP und die unterstützten DTSX-Profile. Die fünf genehmigten Komponenten Derived Column, Conditional Split, Row Count sowie Flat-File-Source und -Destination sind im aktuellen Debugumfang enthalten; der aktuelle 40-Parameter-Build ist laut Prüfmatrix für diesen Vertrag validiert und unveröffentlicht. Die historische V2-Evidenz bleibt an ihre alten Artefakte gebunden. Für diese fünf Komponenten ist keine Umsetzung von vorn zu beginnen oder geschlossene Qualifikation zu wiederholen. Die Freigabe erteilt keine pauschale Genehmigung für SQL-seitige Ausführung externer Effekte, beliebige Tasks oder neue SQL-Objekte.

## Klasseninventur

| Familie | Eingebaute Klassen / Kandidaten | Plan und Supportstufe |
|---|---|---|
| Paketstruktur | Package, TaskHost, Sequence, For Loop, Foreach Loop, Event Handler, Precedence Constraint | Struktur, Reihenfolge, Scopes und Bedingungen für alle unterstützten XML-Profile inventarisieren. Container-/Constraint-Semantik stufenweise in Planmodell abbilden. Schleifen zuerst als Struktur/Iteration mit gebundenen Werten, keine ungeprüfte SQL-Ausführung. |
| Datenfluss | Data Flow Task/Pipeline; Quellen, Transformationen, Ziele | Pipeline-Graph, Ports, Lineage, Typen und Verbindungen für alle Klassen erfassen. SQL-Übersetzung bleibt pro Klasse und Konfiguration explizit allowlisted. |
| Bereits validierte Transformationen | Derived Column, Conditional Split, Row Count | Im aktuellen Debugvertrag enthalten. Keine Umsetzung von vorn und keine Wiederholung geschlossener Qualifikation. |
| Flat-File | Flat-File Source, Flat-File Destination | Bereits genehmigt: Metadaten, Eingaben und relationale Ersatzquellen/-ziele gemäß Vertrag; keine echte Datei-I/O-Behauptung. |
| Copy Column V1 | Native Copy Column | Am 2026-11-13 konkret besprochen und freigegeben. Eine zusätzliche aliasierte Debugprojektion, keine Mutation; Source umgesetzt; Deltaabnahme bestanden, Liefer-/Client-/Transportgates separat. Vertragsdetails in `SSIS_CURRENT_API_CONTRACT.md`. |
| Weitere Row-Transformationen | Audit, Character Map, Copy Column, Data Conversion, Export Column, Import Column, OLE DB Command, Script Component | Zuerst Metadateninventar. SQL-seitig übersetzbar priorisieren: Copy Column, Data Conversion, Character Map, Audit (nur deterministische/gebundene Felder). Datei-I/O, beliebiger SQL pro Zeile und Script bleiben Diagnose/unsupported bis gesonderter Vertrag und Berechtigungs-/Nebenwirkungsmodell vorliegen. |
| Weitere Rowset-Transformationen | Aggregate, Sort, Percentage Sampling, Row Sampling, Pivot, Unpivot | Einzelverträge für NULL-/Kollations-/Sortier-/Stichproben-/Pivotsemantik; deterministische SQL-Kandidaten nach Komponentensemantik qualifizieren. Zufalls-/Laufzeitverhalten nur mit reproduzierbarem Seed/Vertrag. |
| Split/Join/Lookup | Multicast, Union All, Merge, Merge Join, Lookup, Cache Transform, Balanced Data Distributor | Relationale Kandidaten: Multicast, Union All, Merge Join, Lookup mit vollständiger Cache-/No-match-/Fehlersemantik. Buffer-/Thread-/Cache-Dateiverhalten nicht als bloßes SQL umdeuten. |
| BI / unscharfe Verarbeitung | Slowly Changing Dimension, Fuzzy Grouping, Fuzzy Lookup, Term Extraction, Term Lookup, Data Mining Query, DQS Cleansing | Metadaten und Abhängigkeiten vollständig melden; externe Modelle, Wissensdatenbanken und nichtdeterministische Algorithmen bleiben zunächst unsupported. Je Klasse prüfen, ob eine explizite relationale Entsprechung mit gleichem Vertrag existiert. |
| Eingebaute Quellen/Ziele | OLE DB, ADO.NET, Flat File, Excel, XML, Raw File, ODBC und weitere installierte Provider | Provider- und Versionsinventar; zuerst SQL-Server-OLE-DB/ADO.NET sowie bereits genehmigtes Flat File. Andere Provider nur bei expliziter Metadaten-/Typ-/Kontextbindung; keine Credential- oder Verbindungsausführung bei Analyse. |
| Control-Flow-Tasks | Execute SQL, Data Flow, File System, FTP, XML, Web Service, Send Mail, Execute Process, Execute Package, Script, WMI, Analysis Services, Maintenance Plan und weitere Built-ins | Vollständige Identität/Properties/Verbindungen/Abhängigkeiten diagnostizieren. Rein lesende und deterministisch modellierbare SQL-Teilmengen separat planen. Prozess-, Netzwerk-, Datei-, Mail-, SSIS-Ausführungs- und Admin-Nebenwirkungen niemals während Analyse ausführen; sie sind keine automatische Debug-SQL-Übersetzung. |
| Erweiterbarkeit | Drittanbieter-Connectoren, Custom Tasks/Components/Enumerators/Connection Manager | Unbekannte CreationName/ClassID mit exakter Herkunft ausgeben; keine automatische Aktivierung oder Assemblyladung. Ein Adapter benötigt eigene explizite Spezifikation, Rechte- und Sicherheitsprüfung. |

Der Microsoft-Transformationskatalog führt die eingebauten Transformationsfamilien und Einzelklassen auf; der Control-Flow besteht aus Containern, Tasks und Precedence Constraints, einschließlich Event-Handler-Abläufen. Quellen, Transformationen und Ziele bilden die drei Datenflusskomponententypen. Die oben aufgeführten Kandidaten werden pro tatsächlich unterstütztem Paketprofil und Klassen-/Komponentenversion verifiziert; die Dokumentationskataloge allein gelten nicht als technische Qualifikation.

## Lieferreihenfolge

1. **Inventar- und Diagnosevollständigkeit:** Paketprofilmatrix, Task-/Container-/Handler-/Constraint-IDs, ComponentClassID, CreationName, Komponentenversion, Connection Manager, Variablen-/Parameterzuweisungen, Ports und Lineage. Unbekannte Klassen liefern eigene Diagnose und blockieren nur abhängige Pfade.
2. **Bestand schützen:** den aktuellen 40-Parameter-Vertrag, Debug-Ausgabe, Installationsbytes und Nachweise unverändert lassen; nur bei geänderter gemeinsamer Abhängigkeit die konkret erforderlichen Folgetore ausführen.
3. **Relationale Kerntransformationen:** pro Klasse Vertrag und Tests spezifizieren; Reihenfolge: Copy Column, Data Conversion, Character Map, Multicast, Union All, Aggregate, Sort, Merge Join, Lookup, Pivot/Unpivot, Conditional Split-Erweiterungen. Erste V1-Slices liefern erklärtes/debugfähiges SQL. Kein neuer SQL-Funktionsentrypoint, solange das bestehende Ergebnis-/Artifactmodell genügt.
4. **Control Flow:** Container, Verzweigungen, Schleifen und Event Handler zunächst vollständig diagnostizieren und modellieren. Prozeduren bleiben auf vollständige Datenfluss-Pfade begrenzt. Zuweisungsanalyse bleibt nur so präzise wie statisch nachweisbar; unbekannte Effekte dürfen keine falsche Ausführbarkeit erzeugen.
5. **Lokaler Transformationshost:** spätere Stufe nach SQL-Debugübersetzungen; eigener Architektur- und Vertragsvorschlag für Eingabe-/Ausgabemodell, Prozessisolation, Ressourcenlimits, Erweiterbarkeit, Datenresidenz, Identität, Fehler/Teilerfolge und unterstützte OS/Runtime. Kein eingebetteter SSIS-Runtime-Ersatz und keine automatische Paket-/Script-Ausführung ohne separaten Scope.
6. **Provider und I/O-Klassen:** pro Provider/Task ein sicherer Diagnosevertrag; Datei-/Netzwerk-/Prozess-/Administrationsoperationen bleiben Analyse-only, solange kein eigener Ausführungsmechanismus samt expliziter Freigabe und Identitäts-/Rechtemodell festgelegt ist.
7. **BI-, Script- und Custom-Klassen:** vollständige, stabile `unsupported`-Diagnostik. Nur fachlich identische, überprüfbare SQL-Entsprechungen werden als spätere Einzelverträge vorgeschlagen.

Jeder Implementierungsslice erhält eigene Resultate für `recognized`, `modeled`, `translated`, `executable` und `unsupported`, jeweils mit Ursache/Abhängigkeit. Ein oberer Gesamtstatus darf diese Ebenen nicht zusammenwerfen. Keine Behauptung „SSIS vollständig ausführbar“; Ziel ist vollständige Erkennung des Built-in-Katalogs für die unterstützten Profile und kontrolliert wachsender Übersetzungsumfang.

## Benutzerentscheidungen vom 2026-11-13

Diese Festlegungen bestimmen die Reihenfolge, ersetzen aber nicht die funktionsbezogene Vertragsbesprechung und Implementierungsfreigabe für neue Klassen:

1. Neue Transformationen stufenweise: zuerst Debug-SQL-Teilstrecken, später zusätzlich ein lokaler Transformationshost.
2. Control Flow zunächst vollständig diagnostizieren; Prozeduren nur für vollständige Datenfluss-Pfade.
3. Erstumfang: SQL-Server-Built-ins in den unterstützten DTSX-Profilen; Azure-SSIS-spezifische Klassen und Drittanbieter bleiben separat.

## Abgeschlossener Funktionsvertrag: Copy Column V1

- **Zweck:** eine bereits vorhandene Eingabespalte unter einem neuen SSIS-Ausgabespaltennamen in derselben Zeile bereitstellen.
- **Öffentlicher Effekt:** nur ein zusätzlicher relationaler Debug-Stage/Plan in der bestehenden SSIS-`explain`-Ausgabe; keine neue USP, kein Datenbankmutator, keine Datei-/Netzwerk-I/O. Bei Freigabe ist die erwartete Umsetzung `inputColumn AS outputColumn` im stage SQL unter den bestehenden Identifier-/Lineage-/Typregeln.
- **V1-Profil:** native eingebaute Copy-Column-Transformation in unterstützten DTSX-Profilen; konfigurierte Kopien werden in Reihenfolge ausgegeben. Quelleingabe bleibt erhalten. Jede Kopie bindet an eine eindeutige Input-Lineage-ID; Output-Lineage und SSIS-Typ/NULL-/Collationmetadaten stammen aus dem Paketmodell. SQL-NULL, Wert und Typ werden nicht konvertiert.
- **Abweisung:** doppelte/fehlende Lineage, unauflösbare Quelle, doppelte/konfligierende Output-Identität, unbekannte Komponentenversion oder unerwartete Eingabe-/Portform blockiert den betroffenen Pfad mit konkreter Diagnose; nie stillschweigend Spalten erzeugen/überschreiben.
- **Alternativen:** nur Metadaten diagnostizieren (sicher, aber unnötig eng bei einfacher relationaler Identität); oder gleich lokale Host-Ausführung einbeziehen (zu großer, anderer Daten-/Laufzeitvertrag). Empfohlener erster Slice ist Debug-SQL; lokale Ausführung folgt als eigene Stufe.
- **Risiken/Abnahme:** SQL-Aliasreihenfolge und Case-/Collationregeln, Alias-Kollisionen, leere/mehrfache Kopiermappings, unbekannte Versionen, Downstream-Lineage und unveränderte Quellspalte mit synthetischen Fixtures gegen SSIS-oracle vergleichen. Resultat als `recognized`, `translated`, `complete` und `executable` getrennt klassifizieren; Debug-SQLs bestehende Executable-Regel beibehalten.
- **Benutzerfreigabe 2026-11-13:** „Ja, Copy Column V1 freigeben.“ Die Freigabe umfasst genau diesen Slice; Source implementiert; Build und [Deltaabnahme](../Releases/1.0.0/SSIS-COPY-COLUMN-V1-QUALIFICATION.md) bestanden. Vollständige neue Liefer-/Client-/Transportabnahmen bleiben separat.

## Quellen und Repository-Verträge

- [Aktueller SSIS-Debug-Vertrag](../Documentation/Architecture/SSIS_CURRENT_API_CONTRACT.md)
- [SSIS-Komponentenvertrag](../Documentation/Architecture/SSIS_COMPONENTS_V2_CONTRACT.md)
- [Microsoft: Integration Services Tasks](https://learn.microsoft.com/en-us/sql/integration-services/control-flow/integration-services-tasks?view=sql-server-ver16)
- [Microsoft: Control Flow](https://learn.microsoft.com/en-us/sql/integration-services/control-flow/control-flow?view=sql-server-ver17)
- [Microsoft: Precedence Constraints](https://learn.microsoft.com/en-us/sql/integration-services/control-flow/precedence-constraints?view=sql-server-ver17)
- [Microsoft: Integration Services Transformations](https://learn.microsoft.com/en-us/sql/integration-services/data-flow/transformations/integration-services-transformations?view=sql-server-ver17)
- [Microsoft: Transformation Custom Properties](https://learn.microsoft.com/en-us/sql/integration-services/data-flow/transformations/transformation-custom-properties?view=sql-server-ver17)
- [Microsoft: Data Flow](https://learn.microsoft.com/en-us/sql/integration-services/data-flow/data-flow?view=sql-server-ver17)
- [Microsoft: File System Task](https://learn.microsoft.com/en-us/sql/integration-services/control-flow/file-system-task)
