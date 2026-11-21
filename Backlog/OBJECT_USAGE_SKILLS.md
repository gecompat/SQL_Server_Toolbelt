# Maschinenlesbare Usage-Skills für Toolbelt-Objekte

Status: Benutzerauftrag und Freigabe der zusätzlichen rein lesenden View vom
2026-11-20. Der anschließend bereitgestellte Analyze-Plan wird als gemeinsamer
Usage-Skill-Vertrag übernommen. Dieser Umfang ergänzt den fortbestehenden
[Deploymentauftrag](UNIFIED_DEPLOYMENT.md). Keine Veröffentlichung, Tags oder
Änderung der laufenden Key18-Installation.

## Maßgebliche Quelle und vollständiger Umfang

Je katalogisiertem Objekt genau eine redaktionell gepflegte Markdown-Datei mit
versioniertem YAML-Frontmatter unter `Metadata/UsageSkills`. Alle öffentlichen,
internen und technischen Objekte sowie die neue View einschließen. Tabellen
beschreiben den vorgesehenen Lese-/Schreibweg; interne Helfer nennen passende
öffentliche Einstiege. Fehlende persistente Source-Objekte vor der Abnahme
inventarisieren. Die zunächst fehlenden elf Filesystem-Helfer sind inzwischen
im Modulobjektinventar erfasst; alle 22 Objekte dieses Moduls besitzen geprüfte
Skillquellen. Neue Skill-/Hilfefunktionalität benötigt weiterhin eigene Abnahme.
Assemblies und schemafreie Objekte erhalten eine eindeutige dokumentierte
Identität statt eines erfundenen Schemas.

Frontmatter: eindeutige Identität aus Datenbankrolle/Schema/Name, Objekttyp,
interne/öffentliche Verwendung, Kurzbeschreibung und Formatversion. Abschnitte:
Zweck/Einsatzfälle, Voraussetzungen, sämtliche Parameter, Ergebnisse, Beispiele,
Rechte, Ressourcen, Nebenwirkungen, Fehlerbehandlung und Aussagegrenzen.
Parameter enthalten Typ/Richtung, Eingabeform, Pflicht, tatsächlichen Default,
NULL-/Leerregeln, Bereiche und sämtliche festen Optionen mit Bedeutung.
Aussagen gegen tatsächliche Implementierung prüfen. Vorhandene Registry und
Dokumentation sind Bootstrap-/Abgleichquellen, keine zweite redaktionelle
Source of Truth. Abgeleitete API-/Help-Projektionen an die Skillquelle koppeln.

## Drei übereinstimmende Darstellungen

Quellstand 2026-11-21: Alle vier Table-Clone-Prozeduren besitzen geprüfte
Skillquellen, identische DDL-Kommentare und frühe zusätzliche Skillresultsets.
Vorschau, hashgebundener Executor und Datenkopie sind nach Rechten, Mutation,
Transaktionen, Budgets und interner COPY_FK-Grenze getrennt beschrieben. Eine
veraltete 4.1.0-Angabe im Hashvertrag wurde an die bereits vorhandene
4.1.1-Implementierung und Clientableitung angeglichen; Hashbytes/Fachpfade
bleiben unverändert. Der Offlineinstaller nimmt nur exakt quellgebundene
Skillprojektionen von seiner Property-Nutzungsprüfung aus; zusätzlicher
SQL-Zugriff außerhalb dieser Texte bleibt gesperrt. Neue native Hilfe- und
Gesamtinstallerabnahme ist dadurch nicht nachgewiesen.

Quellstand 2026-11-21: Öffentliche und interne SSIS-Prozedur besitzen eigene
geprüfte Skillquellen. Der Vertragsgenerator erzeugt daraus DDL und frühen
Skillresultset; beim CLR-Einstieg ergänzt er den vorhandenen Help-Konstantenbatch
mit einem LF-stabil escapten SELECT. Die neun technisch erforderlichen LOBs
und der Analysepfad bleiben unverändert. Paketentwurf ohne Quellkatalog,
optionale Katalogabnahme und spätere manuelle Ausführung sind ausdrücklich
getrennt. Kompilierte Help-Konstanten sind offline prüfbar; neue native
SQL-Pipe-/Callerzustands-/Installerabnahme bleibt separat erforderlich.

Quellstand 2026-11-21: Auch die zehn katalogisierten XLSX-Objekte besitzen jetzt
geprüfte Skillquellen. Workbook-/Rohzellenlesen, Typinterpretation und Anzeige
sind ausdrücklich getrennt; öffentliche NULL-Binary-Priorität, interne
Limitprüfung, partweise CRC-Aussage, gezählter Speichercharge und endliche
Anzeigeformate sind beschrieben. Die neun aufrufbaren Objekte enthalten ihre
DDL-Projektion, die drei Prozeduren zusätzlich den frühen Skillresultset.
Fachpfade bleiben unverändert. Dies schließt die neue native Hilfe-, Unicode-,
Callerzustands-, Rechte- und Installerabnahme nicht ein und eröffnet keine
Wiederholung historischer Testwellen.

1. Prozeduren: bisherige Hilfe erhalten und genau ein zusätzliches Skill-
   Resultset mit `SkillFormatVersion`, `SchemaName`, `ObjectName` und
   `SkillMarkdown nvarchar(max)` liefern. Dies ersetzt ausdrücklich den zuvor
   erwogenen Toolbelt-Sonderweg einer USAGE_SKILL-Zeile im alten Help-Resultset.
   Fehlender Hilfeschalter: abschließend optional `@Hilfe bit=0`; Pflichtparameter
   bleiben Pflichtparameter. Rückkehr vor Fachprüfungen/-abfragen/-mutationen;
   notwendige OUTPUT-Initialisierung erhalten, Normalpfad unverändert lassen.
2. Jede kanonische DDL enthält denselben vollständigen Skill im eindeutig
   markierten Kommentar. CLR-/Tabellenkommentare sind nicht als aus SQL-Server-
   Moduldefinitionen rekonstruierbar zu behaupten.
3. `toolbelt_metadata.VW_ObjectUsageSkills`: genau acht Spalten in Reihenfolge
   `SchemaName`, `ObjectName`, `ObjectType`, `DatabaseRole`, `IsInternal`,
   `Description`, `SkillFormatVersion`, `SkillMarkdown`. Eine Zeile je Identität.
   Reine generierte Konstanten, keine Laufzeit-Katalog-/Fachdatenabfragen,
   Metadatentabellen, Extended Properties, dynamische Analyse oder LLM-Abhängigkeit.
   Die Einträge beschreiben bekannte Objekte; keine Installations-, Definitions-
   oder Rechteattestation. Beschreibungsdaten erteilen keine Ausführungsautorität.

Die zuerst vorgesehene Sichtbarkeitsfilterung entfällt zugunsten desselben
konstanten Vertrags wie Analyze. Gesamt-/Teilprofile und aufeinanderfolgende
Teilinstallationen ausdrücklich mit create-only vereinbaren; bestehende oder
fremde Objekte nicht still überschreiben. Datenbankrollen projektrichtig
festlegen; Analyze-Snapshotrollen nicht ungeprüft übernehmen.

### Festlegung für Gesamt- und Teilinstallationen

Der freigegebene Skillkatalog wird für einen Quellstand einmal vollständig
erzeugt. Alle Gesamt-/Teilprofile desselben Quellstands erhalten denselben
bekannten Objektkatalog, einschließlich der Skills nicht ausgewählter Module.
Plattform, Voraussetzungen und öffentliche/interne Verwendung stehen im Skill;
ein Katalogeintrag bleibt ausdrücklich keine Installationsbehauptung. Damit
entsteht bei nacheinander installierten Teilmodulen desselben Builds keine
unvollständige erste Teilmenge und keine nachträgliche Merge-/Registrylogik.

Der Katalog folgt ebenfalls create-only: eine vorhandene Sicht wird weder
überschrieben noch erweitert. Bei unterschiedlichen Quellständen aktualisiert
eine weitere Teilinstallation keinen älteren Katalog. Für einen aktuellen
Gesamtkatalog sind eine frische Installation oder eine separat kontrollierte
manuelle Aktualisierung erforderlich; kein automatisches DROP/ALTER und keine
Übernahme fremder Definitionen. Neue Builder-/Inventar-/Installerintegration
erst nach vollständiger Quellenabdeckung; bis dahin keine Teilfreigabe der
Produktview und kein Versand von Entwürfen.

## Abnahme und Integration

### Quellbefund JSON-Path-Keyvergleich, 2026-11-21

Der Propertyzweig von `TVF_JsonPathExistsStatus` vergleicht den OPENJSON-Key
mit dem Pfadtoken ausschließlich über BIN2-Gleichheit. Eine zusätzliche
Längengleichheit ist nicht vorhanden. Der
[Microsoft-Vertrag](https://learn.microsoft.com/en-us/sql/t-sql/language-elements/string-comparison-assignment?view=sql-server-ver17)
beschreibt die Leerzeichenauffüllung bei SQL-Zeichenkettengleichheit. Daraus
ergibt sich ein konkreter Quellverdacht für die Verwechslung eines JSON-Keys
mit derselben Zeichenfolge und abschließendem Leerzeichen. Eine native
Gegenprobe wurde nicht ausgeführt; kein beobachtetes API-FAIL behaupten.

Beide JSON-Path-Skills bleiben Entwürfe. Vor ihrer Abnahme sind der gepaddete
Vergleich, eine notwendige Längenabsicherung und passende positive/negative
API-Gegenfälle zu klären. Ein fachlicher Fix darf weder als passiver Kommentar
normalisiert noch mit alten unveränderten Runtime-Nachweisen qualifiziert
werden. Bestehende Grenzen und Native-Freigaben bleiben erhalten; unabhängige
Skillverträge weiter bearbeiten.

### Quellbefund URI-Decoder, 2026-11-20

Die Skillprüfung hat einen offenen Auswertungspfad in
`TVF_UriComponentDecodeStatus` gefunden: Die Hexkonstruktion verwendet rohe
Nicht-ASCII-Codepunkte ohne vorherige Nibble-Begrenzung. Beispielsweise führt
Codepunkt 256 rechnerisch zu einem fehlenden ersten Hexzeichen und einem
einzelnen zweiten Zeichen. Der anschließende normale Binary-CONVERT besitzt
keinen eigenen TRY-/Guardpfad. Die vorhandene Nicht-ASCII-Validierung soll
Code 10 liefern, ist aber keine ausdrücklich vorangestellte prozedurale
Rückkehr vor dieser Konstruktion.

Eine tatsächliche API-Ausnahme wird ohne native Auswertung nicht behauptet.
Die drei Decoder-Skills bleiben Entwürfe, bis Auswertbarkeit und notwendige
Absicherung geklärt sind. Ein späterer Fix darf nicht als unveränderter
Fachpfad normalisiert oder durch historische Nachweise qualifiziert werden.
Unabhängige Skills und unveränderte Fachpfade werden weiter bearbeitet.

Zuerst öffentlicher USP, interner Helfer, Funktion, View und Tabelle als geprüfte
Prototypen; anschließend vollständige Inventarabdeckung. Identitäten, Frontmatter,
Parameterverträge, Links, Gleichheit Skill/DDL/Hilfe/View, SQL-Quoting und lange
ungekürzte Unicode-Ausgabe einschließlich Drift-/Manipulationsgegenproben prüfen.
Installer, Generatoren, Inventare, Abhängigkeiten und Artefakte gemeinsam pflegen.

Unveränderte Fachpfade und historische Nachweise nur bei tatsächlich passender
Bindung wiederverwenden. Der neue Hilfe-/Skillvertrag erbt kein Gesamt-PASS alter
Artefakte. Erforderliche neue native Tests erhalten vor Start eigene konkrete
endliche Autorität und Grenzen; keine Wiederholung alter grüner Matrices/TLS.
Vollständige Ausgabe, frühe Hilfe bei ungültigen Fachargumenten, Pflichtparameter,
Caller-Zustand und Ausbleiben von Fachnebenwirkungen als neue Orakel vorsehen.
Bestehende geschlossene Budgets bleiben erhalten.

Ein Implementierungsverantwortlicher. Erforderliche unabhängige Abnahme nach
Projektvertrag mit konkret begrenztem Scope, keine ungefragte Delegation.
Regulärer grüner PR-/Main-CI-Abschluss, Branchcleanup und gebaute aktuelle
Distribution erst nach vollständiger Abnahme des gesamten erweiterten Auftrags.
