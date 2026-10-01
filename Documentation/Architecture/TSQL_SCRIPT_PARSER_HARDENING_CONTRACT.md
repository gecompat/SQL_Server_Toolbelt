# T-SQL Script Parser: Vertrag zur begrenzten Härtung

## Status, Freigabe und Scope

Dieser Vertrag konkretisiert vor der Source-Änderung die einzeln freigegebene Parser-Härtung und Syntaxqualifikation aus [.ai/BACKLOG.md](../../.ai/BACKLOG.md). Das bisherige Moduldesign bleibt die Basis; für die geplante Major-Version **2.0.0** ersetzt dieser Vertrag dessen Aussagen zu unbeschränkten Eingaben, Default-Tiefe, partiellem AST und garantiertem Schutz vor Prozessabstürzen. Die Qualifikation ist geplant; das Aufzeichnen dieses Vertrags führt sie nicht aus. Historische 1.0.0-Evidenz qualifiziert 2.0.0 nicht.

Die Welle umfasst ausschließlich die vorhandenen `toolbelt_tsql.TVF_ParseScriptNodes`, `TVF_ParseScriptNodeProperties`, `TVF_TokenizeScript` und `TVF_ParseScriptErrors` sowie gekoppelte Build-, Lifecycle-, Dokumentations- und Testartefakte. Namen, Namen/Reihenfolge/Typen der fünf Parameter und Ergebnisschemas bleiben erhalten. Neue öffentliche SQL-Objekte, Trigger-Rewriting, Referenzauflösung, externe Ausführungsprovider, Dependency-Upgrades und erweiterte Plattformzusagen sind ausgeschlossen. Nicht registrierte experimentelle Helper gehören nicht zur Welle.

Der Provider bleibt .NET Framework 4.8; das Modul bleibt Windows-only, `UNSAFE`, für SQL Server 2019, 2022 und 2025. Linux ist kein alternativer Test- oder Runtime-Pfad. Dieser Vertrag erteilt keine Rechte und aktiviert weder automatische Trust-Registrierung noch eine Lockerung von Strict Security oder `TRUSTWORTHY`.

## Parameter und eindeutige Fehlerpriorität

Alle vier Einstiegspunkte verwenden dieselbe Parametervalidierung und denselben Rohtext-Wächter. `@SqlText IS NULL` liefert vor der Prüfung anderer Parameter eine leere Ergebnismenge; das bisherige Verhalten bei NULL-Text bleibt erhalten. Andernfalls gilt: Version, Parameter für Byte-Limit, Parameter für Tiefe, tatsächliche Eingabegröße, Rohtextprüfung, lexikalische Prüfung, gegebenenfalls Parsing, Ausgabeprüfung. Der frühere Fehler gewinnt; ein späterer Syntaxfehler verdeckt keinen vorherigen Grenzfehler.

| Parameter | Verhalten in 2.0.0 |
|---|---|
| `@TSqlVersion` | SQL-Default und NULL: 160. Ausschließlich 80, 90, 100, 110, 120, 130, 140, 150, 160 und 170 sind zulässig. Kein Fallback für unbekannte Werte. |
| `@QuotedIdentifiers` | SQL-Default und NULL: true. Beide expliziten Boolean-Werte werden geprüft. |
| `@MaxInputBytes` | SQL-Default und NULL: 2.097.152. Expliziter Bereich 1..2.097.152; kein unbeschränkter NULL-Pfad. UTF-16-Codeeinheiten mal zwei mit breiter, überlaufgeprüfter Arithmetik vor Konvertierung/Kopie zählen. |
| `@MaxNestingDepth` | SQL-Default und NULL: 100. Expliziter Bereich 1..256. AST-Wurzeltiefe ist null. Die aktive Rohtext-Strukturgrenze ist `min(32, angeforderte Tiefe)`. |

Jede TVF validiert den Tiefenparameter. Nodes und Properties prüfen nach erfolgreichem Parsing die AST-Tiefe durch iterative Traversierung. Errors prüft bei erfolgreichem Parsing ebenfalls die Fragmenttiefe, bevor die leere Diagnosemenge zurückgegeben wird. Bei Syntaxfehlern liefert Errors begrenzte Diagnosen, ohne den partiellen AST als nutzbare Ausgabe zu behandeln. Tokenize arbeitet ausschließlich lexikalisch: Seine Tiefenprüfung betrifft den Rohtext-Strukturwächter, keine AST-Tiefe. Beide Prüfungen sind verschieden; ein im Rohtext zulässiger Ausdruck kann die angeforderte AST-Tiefe überschreiten.

## Wächter vor ScriptDom

Ein iterativer Rohtextscanner für UTF-16 muss erfolgreich abschließen, **bevor irgendein ScriptDom-Aufruf von `GetTokenStream` oder `Parse` erfolgt**, auch vor dem Lexing von Kommentaren. Seine Zustände sind gewöhnlicher Text, einfach zitierte Literale, doppelt zitierter Text, geklammerte Identifier, Zeilenkommentare und verschachtelte Blockkommentare. Verdoppelte einfache/doppelte Anführungszeichen und schließende eckige Klammern verbleiben in der jeweiligen zitierten Einheit. Nur im gewöhnlichen Text öffnen Anführungszeichen oder eckige Klammern eine undurchsichtige zitierte Einheit. Innerhalb von Kommentaren bleiben sie vollständig gezählter Kommentartext. Kommentare und zitierter Inhalt dürfen keine scheinbaren Strukturschlüsselwörter beitragen.

Nicht geschlossene zitierte Einheiten oder Kommentare verbrauchen den Rest im jeweiligen Zustand und bleiben der regulären lexikalischen beziehungsweise Parser-Diagnose überlassen, sofern keine frühere Wächtergrenze überschritten wird. Eine nicht geschlossene zitierte Einheit kostet weiterhin je ein Atom und eine Rohtexteinheit; ihr Inhalt bleibt durch das Eingabelimit von 2 MiB begrenzt.

Die folgenden Grenzen sind Qualifikationskandidaten. Vor SQL-Aufrufen müssen sie das isolierte Qualifikations-Gate bestehen:

| Zähler | Kandidat und Zählregel |
|---|---|
| Signifikante Rohtextatome | 512 kumulativ über das gesamte Skript. Ein Wortlauf besteht aus aufeinanderfolgenden Unicode-Buchstaben, kombinierenden Zeichen, Unterstrichen sowie nachfolgenden Dezimalziffern. Ein bei einer Dezimalziffer beginnender Zahlenlauf enthält ausschließlich aufeinanderfolgende Dezimalziffern; Punkt, Vorzeichen und Exponentbuchstaben werden separat behandelt. Eine zitierte Literal-/Identifier-Einheit zählt als ein Atom. Jede übrige Nicht-Trivia-Codeeinheit, einschließlich Operatoren und Satzzeichen, zählt einzeln. Konservatives Aufteilen ist zulässig; Unterzählen ist ausgeschlossen. |
| Rohtexteinheiten | 8.192 kumulativ: Jede UTF-16-Codeeinheit außerhalb undurchsichtiger zitierter Literale/Identifier kostet eins, einschließlich unzitierter Wörter, Operatoren, Whitespace und sämtlicher Kommentarzeichen/Begrenzer. Jede undurchsichtige zitierte Einheit kostet eins. Damit werden lange unzitierte oder kommentarlastige Skripte bewusst vor dem Lexing abgelehnt. |
| Aktive Strukturverschachtelung | `min(32, angeforderte Tiefe)`, gemeinsam für runde Klammern und konservativ erkannte unzitierte `CASE`-/`BEGIN`-Öffnungen. Schließende Konstrukte reduzieren ausschließlich die aktive Tiefe, niemals kumulative Zähler. `BEGIN TRANSACTION` darf konservativ als Öffnung zählen. |
| Verschachtelte Blockkommentare | 16 gleichzeitig offene Kommentarebenen. |
| ScriptDom-Tokenstrom | 8.192 Tokens einschließlich Trivia und EOF, unabhängig nach dem Lexing und vor Parsing oder Tokenausgabe geprüft. |

### Vorgeschalteter Kandidatennachweis vom 2026-10-02

Der private Offline-Runner `Invoke-Qualification.ps1` hat nach unabhängiger Codeprüfung und erneutem Orchestrator-Aufruf **82 begrenzte .NET-Framework-Kindprozesse erfolgreich geprüft**. Geprüft wurden das oben definierte Rohtextprofil, die exakte unten angegebene Dependency und die Parser 150/160/170 auf bewusst kleinem konfiguriertem Threadstack. Grenzablehnungen erreichten weder Konstruktor noch Lexer oder Parser. Zahlen-/Exponentläufe, Sonderzeichen, kombinierende Zeichen und die Fehlerpriorität an Kommentar-Begrenzern wurden ausdrücklich geprüft. Fingerprints von Source, Harness und Dependency werden vor dem Lauf verifiziert; Prozessfehler, Timeout oder fehlende Ausgabe sind Fehler.

Der eingefrorene Kandidaten-Source-Fingerprint (SHA-256) ist `AFEECCE14DD18B6E20EEEBC0EC5F0A8E431095B1C032D117F93F88D933DA9A12`. Private Ausführungspfade und Runtime-Ausgaben bleiben außerhalb des Repositories. Dieser Nachweis schließt ausschließlich das **vor Source-Änderung geforderte Kandidaten-Gate**. Er qualifiziert weder die integrierten vier TVFs noch AST-/Ausgabequoten, den vollständigen Syntaxkorpus, Deployment oder Live-SQL; deren Nachweise bleiben `not executed`. Der integrierte Provider muss vor Live-SQL erneut isoliert geprüft werden.

Weder Atom- noch Rohtexteinheitenzähler werden bei Semikolon, `GO`, Komma, `END`, Boolean-Operator oder Batchgrenze zurückgesetzt. Jedes Atom wird gezählt; eine unvollständige Liste möglicherweise rekursiver Grammatikschlüsselwörter wird vermieden. Damit werden flache unäre, boolesche, arithmetische, Mengenoperations-, Join-, Prädikat- und Kontrollflussketten kumulativ begrenzt. Die bewusste Ablehnung ansonsten gültiger Skripte ist zulässig. Das Eingabelimit begrenzt das Scannen zitierter Inhalte, auch wenn ein langes Literal nur ein Atom kostet. Das Tokenlimit nach dem Lexing ist eine Nachbedingung; es behauptet keine entsprechende Obergrenze für intern bereits allokierte ScriptDom-Objekte.

Die erste von links nach rechts überschrittene Rohtextgrenze gewinnt. Am selben Offset werden zuerst Atom/Rohtexteinheiten, dann Strukturtiefe, dann Kommentartiefe geprüft. Alle verwenden denselben stabilen Komplexitätspräfix; private Tests unterscheiden die internen Zähler. Exceptions müssen weder Offset noch Eingabefragment wiedergeben. Der Scanner ersetzt keine T-SQL-Grammatik und behauptet nicht, alle T-SQL-Eingaben anzunehmen.

## Parsing und atomare begrenzte Ausgaben

Tokenize gewinnt und validiert den lexikalischen Strom ohne AST-Parsing. Bei lexikalischen Fehlern entstehen keine Tokenzeilen. Grammatikfehlerhafter Text mit gültigem lexikalischem Strom darf vollständige Tokens liefern. Bei Nodes, Properties und Errors gehen Lexing und dessen Grenzen `Parse` voraus. Syntaxfehler ergeben null Nodes-/Properties-Zeilen; Errors liefert die strukturierten ScriptDom-Diagnosen mit den bestehenden Spaltenbedeutungen. Ein partieller AST wird niemals als erfolgreiche Ausgabe offengelegt.

Jede TVF materialisiert, prüft und akzeptiert ihr vollständiges Ergebnis vor der ersten ausgegebenen Zeile. Eine späte Grenzverletzung löst eine Exception aus und liefert keine Teilmenge. Gemeinsame iterative AST-Traversierung gewährleistet zusammenpassende Knotenordinale zwischen Nodes und Properties bei gleichen Argumenten und gepinnter Dependency. Dauerhafte Node-IDs über Dependency-Versionen werden nicht zugesagt. Eigenschaftsreihenfolge und skalare Formatierung müssen deterministisch und kulturunabhängig sein.

| Ausgabe | Maximale Zeilen |
|---|---:|
| Nodes | 32.768 |
| Properties | 131.072 |
| Tokens | 8.192 |
| Errors | 256 |

Zusätzlich gilt je Aufruf eine konservative Ausgabeverrechnung von 16.777.216 Bytes: UTF-16-Bytes sämtlicher ausgegebener Textfelder plus 128 Bytes je Zeile für feste Felder und Verwaltung. Das ist eine Verrechnungsgrenze, keine gemessene Heap-Obergrenze. Additionen verwenden breite Arithmetik. Bestehende Textspalten mit fester Breite werden vor der Ausgabe geprüft; Diagnosen dürfen nicht stillschweigend auf `nvarchar(4000)` oder andere Schemabreiten gekürzt werden. Es entsteht kein neuer Ausgabegrenzenparameter.

Die bestehenden Fehlerpräfixe `TBX_TSQLPARSE_INVALID_MAX_BYTES`, `TBX_TSQLPARSE_INPUT_TOO_LARGE` und `TBX_TSQLPARSE_MAX_DEPTH_EXCEEDED` behalten ihre Rollen für Byte-Parameter, Eingabegröße und AST-Tiefe. Hinzu kommen `TBX_TSQLPARSE_INVALID_VERSION`, `TBX_TSQLPARSE_INVALID_MAX_DEPTH`, `TBX_TSQLPARSE_PREPARSE_COMPLEXITY_LIMIT` und `TBX_TSQLPARSE_OUTPUT_LIMIT`. CLR-Fehler erscheinen weiterhin im CLR-Exception-Wrapper von SQL Server, regulär mit Fehler 6522; Clients verwenden den dokumentierten Präfix statt des vollständigen Providermeldungstextes. Meldungen enthalten kein eingereichtes SQL. Lexikalische/Syntaxdiagnosen werden ausschließlich von Errors als Daten geliefert; Tokenize liefert bei lexikalischen Fehlern null Zeilen.

## Exakte Dependency und Qualifikations-Gate

Es ist kein Dependency-Upgrade ausgewählt. Das bestehende Kandidatenbinary ist `Microsoft.SqlServer.TransactSql.ScriptDom, Version=18.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91`, Dateiversion **18.0.56.2**, SHA-512:

```text
24BDEE1CC5296488C3609BB6911DD76935B510F823CAAE4D39E8C45C84D272F3D28E3F6156E1E185C0F81D5812C9100E9C71CBE788966AC477A5B213BCE672D0
```

Build, Release-Erzeugung und Tests müssen dieses exakte Binary ausdrücklich ermitteln und verifizieren. Ein Fallback auf installierte Werkzeuge darf keine andere Version stillschweigend auswählen. Release-Identität, Dependency-Hash, Source-Fingerprint und Wächterprofil müssen zusammenpassen; veraltete Release-Verzeichnisse sind keine Evidenz. Bei fehlendem oder abweichendem Artefakt stoppt die Qualifikation statt ein anderes Paket zu verwenden. Bestehende Attribution und Lizenzevidenz bleiben erhalten.

Vor SQL-Server-Ausführung der gehärteten Einstiegspunkte sind Vertrag und Implementierung unabhängig zu prüfen. Der implementierte Wächter und die exakte Dependency werden in begrenzten, verwerfbaren .NET-Framework-Kindprozessen qualifiziert. Dazu gehört ein Harness mit bewusst kleinem Stack; dessen konfigurierte Grenzen werden privat dokumentiert. Abgelehnte Eingaben dürfen weder Lexer noch Parser erreichen. Jede Grenze wird bei Limit minus eins, Limit und Limit plus eins geprüft: Verschachtelung, flache/gemischte Ketten, verschachtelte Kommentare, Trivia-Fluten, zitierte Schlüsselwortattrappen, verdoppelte Begrenzer, Unicode, unvollständige Konstrukte und Resetversuche über Semikolon/GO/END. AST-Tiefengrenzen werden separat geprüft. Kindprozessabsturz, Timeout oder fehlendes Ergebnis lassen das Gate scheitern; das Fangen von `StackOverflowException` ist kein Schutzkonzept.

Bei Ausgabequoten dürfen private Unit-Harnesses interne, abgesenkte Grenzen injizieren, um atomare Ablehnung reproduzierbar zu prüfen. Diese Evidenz ist ausdrücklich von Prüfungen der tatsächlichen SQL-Vertragsgrenzen zu unterscheiden; sie ersetzt deren Grenzqualifikation nicht und schafft keinen öffentlichen Testparameter.

Qualifikation ist empirisch für das exakte Binary, den Korpus und die Runtime-Konfiguration. Endliche Eingabe-/Wächter-/Ausgabezähler beweisen nicht ScriptDoms Stackverhalten für jede angenommene Eingabe und garantieren weder maximale Laufzeit noch physischen Speicherverbrauch. Unerwartete Grammatikrekursion bleibt ein Restrisiko. Falls Evidenz es verlangt, wird der Annahmebereich reduziert und die Änderung vor Live-SQL-Tests dokumentiert; betroffene Qualifikation wird wiederholt. Gewöhnliche Smoke-Tests rechtfertigen keine Erweiterung der Grenzen. Microsoft dokumentiert die [Parse-Überladungen](https://learn.microsoft.com/en-us/dotnet/api/microsoft.sqlserver.transactsql.scriptdom.tsqlparser.parse?view=sql-transactsql-161); die Hostauswirkungen von [StackOverflowException](https://learn.microsoft.com/en-us/dotnet/api/system.stackoverflowexception?view=netframework-4.8.1) begründen das vorgelagerte Gate.

## Syntax- und Lifecycle-Abnahme

Der repräsentative, versionierte Korpus umfasst SELECT/CTE/Subquery/JOIN/APPLY/Mengenoperationen; INSERT/UPDATE/DELETE/MERGE; ALTER/CREATE/DROP von Tabellen/Constraints/Indizes; Prozeduren/Funktionen/gewöhnliche DML-Trigger; Transaktionen/Savepoints/TRY-CATCH; sowie ausschließlich geparste Security-Statements. Batches, Kommentare, Quoting-Flags, Unicode-/UTF-16-Positionen, versionsspezifische positive/negative Syntax für 150/160/170 und ausdrückliche Smoke-Abdeckung der Legacy-Konstruktoren gehören dazu. Erwartete Knoten-/Eigenschaftswerte, Elternbeziehungen, exakte Offsets, Token-Roundtrips und Diagnosepositionen werden geprüft, nicht bloß eine nicht leere Ausgabe. Ein erfolgreicher Korpus ist repräsentative Qualifikation, keine vollständige Syntaxabdeckung.

Major 2.0.0 dokumentiert bewusste Inkompatibilitäten: endliche NULL-Grenzen, Ablehnung unbekannter Versionen, konservative Rohtextablehnungen, kein partieller AST, ausschließlich lexikalisches Tokenize, atomare begrenzte Ausgabe und einheitliche Parameterprüfung. Manifest, Objekt-Help, Beispiele, Versions-/Hashmetadaten des Release-Generators und Upgrade-Dokumentation werden gekoppelt gepflegt. Lokale/zentrale Installation, Upgrade 1.0.0 auf 2.0.0, Wiederholung, Kollisionen und Uninstall werden geprüft. Exakte Dependency und fremde Schemas/Assemblies/Objekte bleiben erhalten; nur marker-eigene unterstützte Versionen dürfen aktualisiert oder entfernt werden. Unbekannte installierte Versionen führen vor jeder Mutation zum Abbruch.

Install/Upgrade/Uninstall müssen eine vorhandene Caller-Transaktion **vor SET-Änderungen und jeder Mutation** ablehnen. Dafür werden ein nicht doomendes `RAISERROR` und unmittelbares `RETURN` verwendet: kein `THROW` unter geerbtem `XACT_ABORT`, kein Rollback fremder Arbeit und keine Änderung vorgemerkter Sessionoptionen auf diesem Ablehnungspfad. Die vorhandene interne Ownership für Deployment-Transaktion/Applock bleibt erhalten. Fehlertests belegen erhaltene Caller-Arbeit, Transaktionszähler/-zustand und SET-Optionen sowie mutationsfreie Fehler bei fremden Objekten oder unbekannten Versionen.

Statische/Contract-Prüfungen und isolierte Qualifikation gehen Live-Tests voraus. Für diese Welle sind risikobasiert **Windows SQL Server 2019 und 2025** über den vorhandenen schema-validierten Lab-Vertrag ausgewählt. Windows SQL Server 2022 bleibt separat **nicht ausgeführt/offen**, sofern kein zusätzlicher begründeter Testbedarf ausgewählt wird; die Zielmatrix wird damit nicht verkleinert. Geprüft werden saubere Installation, lokale/zentrale Nutzung, Upgrade, Wiederholung, Grenzen/Fehler/Atomarität, Dependency-Kollisionen, Ownership und vorhandene minimale Rechte ohne Rechtevergabe. Infrastruktur-Lücken werden getrennt von fehlgeschlagenen Assertions gemeldet. Dieser Vertrag behauptet keine Live-Ausführung, kein Release, keine Trust-Mutation und keine neue finale Entscheidungs-ID.
