# Maschinenlesbare Usage-Skills für Toolbelt-Objekte

**Status 2026-11-21.** Der integrierte Katalog umfasst 257 überprüfte Skills.
Die kanonischen Markdownquellen speisen SQL-Sicht, DDL und Prozedurhilfe.
[PR #630](https://github.com/gecompat/SQL_Server_Toolbelt/pull/630) dokumentiert
den unabhängigen Review, grüne Head- und Main-CI und die native Abnahme auf
Windows SQL Server 2025 CU8, CL170, lokal. Dort bestanden Erst- und
Wiederholungsinstallation, 257 exakte Unicode-Katalogvergleiche, vier frühe
Hilfeaufrufe, 19 Funktionsgrenzfälle und der frische Abschlussaudit. Der
Katalogabruf ist für die Installationsanmeldung in diesem Profil belegt.

Workflow und Leserechte stehen in der
[Anleitung zur Skill-View](../Modules/toolbelt.metadata.capability-catalog/Documentation/VW_ObjectUsageSkills.md).
Der gemeinsame Installationsstand steht im [Deploymentauftrag](UNIFIED_DEPLOYMENT.md).
Die folgenden Abschnitte halten den ursprünglichen Auftrag vom 2026-11-20
und die Befunde bis zur Integration fest.

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

Der ursprünglich untersuchte Propertyzweig von `TVF_JsonPathExistsStatus`
verglich den OPENJSON-Key ausschließlich über BIN2-Gleichheit, ohne zusätzliche
Längengleichheit. Der
[Microsoft-Vertrag](https://learn.microsoft.com/en-us/sql/t-sql/language-elements/string-comparison-assignment?view=sql-server-ver17)
beschreibt die Leerzeichenauffüllung bei SQL-Zeichenkettengleichheit. Daraus
ergibt sich ein konkreter Quellverdacht für die Verwechslung eines JSON-Keys
mit derselben Zeichenfolge und abschließendem Leerzeichen. Eine native
Gegenprobe wurde nicht ausgeführt; kein beobachtetes API-FAIL behaupten.

Aktueller Quellstand: Beide Matchzweige verlangen zusätzlich identische
UTF16-Bytelänge. Die rohe Quoting-/Tiefenprüfung verwendet literale binäre
ASCII-Strukturzeichen. Beide Skills sind am korrigierten Quellcode geprüft;
positive/negative native API-Gegenfälle sind vorbereitet, aber noch nicht
ausgeführt. Der Fix wird separat von unveränderten Quellen geprüft und erbt
keine alten Runtime-Nachweise. Geschlossene native Grenzen bleiben erhalten.

### Quellbefund URI-Decoder, 2026-11-20

Die Skillprüfung hat einen offenen Auswertungspfad in
`TVF_UriComponentDecodeStatus` gefunden: Die Hexkonstruktion verwendet rohe
Nicht-ASCII-Codepunkte ohne vorherige Nibble-Begrenzung. Beispielsweise führt
Codepunkt 256 rechnerisch zu einem fehlenden ersten Hexzeichen und einem
einzelnen zweiten Zeichen. Der anschließende normale Binary-CONVERT besitzt
keinen eigenen TRY-/Guardpfad. Die vorhandene Nicht-ASCII-Validierung soll
Code 10 liefern, ist aber keine ausdrücklich vorangestellte prozedurale
Rückkehr vor dieser Konstruktion.

Eine tatsächliche historische API-Ausnahme wird ohne native Auswertung nicht
behauptet. Der aktuelle Quellstand kehrt bei Nicht-ASCII-Rohinput prozedural mit
Code 10 zurück, bevor Hex-/Binary-CTEs ausgeführt werden. Die drei Skills sind
am korrigierten Quellcode geprüft. Die native Gegenprobe stand zu diesem
Zeitpunkt noch aus. Ihr späterer Nachweis ist im Abschlussstatus oben verlinkt.

### Vollständige Quellabdeckung vor der nativen Abnahme, 2026-11-21

Alle 257 katalogisierten Objekte einschließlich der neuen View besitzen jetzt
geprüfte kanonische Skillquellen; keine fehlenden Dateien oder Entwürfe.
Identifier verwenden konsistente UTF16-Einheiten, binäre Delimiter und
längengenaue Leerheitsprüfung. Bei Trim ist die NUL-Probe an dieselbe
Installationscollation wie Zeichenvergleich und Ausgabe gebunden. Zusammen
mit URI/JSON sind dies fünf gezielt geänderte Funktionsdateien in vier
Modulen. Diese Zwischenstufe belegte die Quellen, die nativen Gegenproben
folgten in der oben verlinkten Abnahme. Der strikte Wiederverwendungsmodus
behandelt sie als geänderte Fachquellen.

Die konstante View ist in das Objektinventar und den gemeinsamen Builder für
Gesamt- und Teilinstaller integriert. Die weiteren damaligen Abschlussgates
umfassten die API-/Help-Projektionen, die native Abnahme, unabhängigen Review,
Head-/Main-CI und den Releasebau.

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
