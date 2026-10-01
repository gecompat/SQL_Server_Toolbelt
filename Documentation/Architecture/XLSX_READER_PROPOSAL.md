# Vorschlag: XLSX-Reader (`TC-2026-045`)

## Bedingte Implementierungsfreigabe vom 2026-10-01

Nach den unten erhaltenen historischen Researchständen hat der Benutzer die
beiden konkret besprochenen APIs `toolbelt_file.USP_ListXlsxWorksheets` und
`toolbelt_file.USP_ReadXlsxWorksheetCells` samt Binary-/Sparse-/Raw-/Text-/
Formel-/Cache- und Ressourcenvertrag ausdrücklich bedingt freigegeben.
Die durable Freigabe steht im ersten aktiven Abschnitt von
[BACKLOG.md](../../.ai/BACKLOG.md). Öffentliche Bindings bleiben an erfolgreiche
SAFE-/Memory-only-Qualifizierung gebunden; kein SDK, Worker, Datei-/Netzwerkzugriff
oder Rechteausweitung ist damit genehmigt.

Der praktische [Qualifizierungsspike](../../Spikes/XlsxMemory/README.md)
implementiert einen eigenen begrenzten XML-Kern mit einer technischen Fassade
des vorhandenen kanonischen ZIP-Parsers. Framework-Harness, adversariale
partiell vertraute Sandbox und eigene IL/API-Allowlist sind im dort exakt
beschriebenen Scope erfolgreich. Der tatsächliche interne SAFE-Hostnachweis
ist auf SQL Server 2019 Linux und SQL Server 2025 Windows erfolgreich; nach
diesem Gate entstanden die beiden freigegebenen öffentlichen Reader-USPs im
Modul toolbelt.file.xlsx-memory. Öffentliche Vertrags-, Metadaten- und
Lifecyclequalifizierung erfolgte getrennt vom begrenzten Gate. Der abschließende
identische Adapter auf Linux 2019/latest und Windows 2025/CU8 ist am 2026-10-02
erfolgreich, einschließlich Caller-Safety- und Help-Metadatenfixes. Die
nachfolgenden Vorfreigabeaussagen bleiben als historische Entscheidungsgrundlage
erhalten und ersetzen diesen datierten Aktivierungsnachtrag nicht.

## Historischer Researchstatus vor der bedingten Implementierungsfreigabe

`TC-2026-045` bleibt Research. Dieses Dokument bereitet die spätere
Funktionsbesprechung vor. Es autorisiert weder einen Dateizugriff noch einen
Provider, ein SQL-Objekt oder die Verarbeitung eines realen Workbooks.

Nachtrag 2026-10-01: Der Benutzer hat inzwischen ausschließlich den
begrenzten Provider-Spike freigegeben. Dies ersetzt die zuvor fehlende
Spike-Autorisierung, nicht die weiterhin ausstehende Freigabe einer
öffentlichen Readerimplementierung. Der Spike untersucht SDK-/Dependency-/
Lizenzkette, Memory-only-Verarbeitung, SAFE-Eignung und Plattformgrenzen mit
synthetischen Minimalworkbooks; keine neuen öffentlichen SQL-Objekte,
Hochprivilegierung, Datei-/Netzwerkzugriff des Workbook-Providers oder
impliziter externer Fallback. Öffentliche Quellenrecherche bleibt zulässig;
sie ist kein Workbook-Providerzugriff.

## Nutzerentscheidung und verpflichtender Folgescope vom 2026-10-01

Der Benutzer hat den begrenzten Binary-/Raw-/Text-/Cache-Scope als erste
Richtung bestätigt. Anzeigeformat, Styles, Culture und Datumsbehandlung
müssen als spätere Erweiterung dauerhaft im Backlog geführt werden. Das ist
eine Scope-Entscheidung, keine Freigabe des noch offenen Providers, konkreter
Reader-Signaturen oder einer Implementierung.

V1-Text bedeutet aufgelösten Shared-/Inline-String-Inhalt, keine formatierte
Excel-Anzeige. Numerischer Rohtext, Formeltext und vorhandener gespeicherter
Cachewert bleiben getrennt. Die spätere Erweiterung muss Styles und
Number-Formats, explizite Culture, 1900-/1904-Modus einschließlich des
historischen 1900-Schaltjahrsonderfalls sowie typisierte Datums-/Zeit- und
Dauerwerte besprechen. Sie ist verpflichtender Folgescope unter
`TC-2026-045`, aber nicht stillschweigend Bestandteil von V1.

## Empfohlene erste Grenze

V1 soll ein **datenbankseitig übergebenes XLSX-Binary** lesen und ein
normalisiertes, typisiertes Zellresultat zurückgeben. Ein Pfadparameter,
Freigabezugriff, Upload, Excel-Automation, VBA-/Makroausführung, externe
Beziehungen und ein Writer gehören nicht zum Scope.

Das Resultset enthält für jede vorhandene Zelle mindestens Sheet-Ordinal,
Sheet-Name, Zeilen- und Spaltenordinal, gespeicherten Zelltyp, Rohwert und
aufgelösten Stringtext sowie getrennten Formeltext und Cachewert. Damit bleibt die Ergebnisform unabhängig von einer
arbeitsmappenspezifischen Spaltenstruktur. Die Anwendung einer fachlichen
Tabelle, automatische Header-Erkennung und Datentypinferenz erfolgen erst
in späteren, getrennten Importverträgen.

## Unterstützte und ausgeschlossene Inhalte

| V1 unterstützt | V1 schließt aus |
|---|---|
| `.xlsx`-Open-XML-Container, sichtbare und ausgeblendete Worksheets, Shared Strings, Inline Strings, Boolean, numerische und Error-Zellwerte | `.xls`, `.xlsb`, `.xlsm`, Makros, ActiveX, externe Datenverbindungen und alle Ausführung von Workbook-Inhalten |
| gespeicherter Formeltext und gegebenenfalls gespeicherter Cachewert, klar getrennt | Formelberechnung, Recalculation, automatische Interpretation fehlender Cachewerte |
| 1900-/1904-Datumsmodus als Workbook-Metadatum | automatische Datums-/Zeitumrechnung ohne Stil- und Culturevertrag |
| explizite Ressourcen- und Containerlimits | Streamingzusagen, unbeschränkte Dateien oder unbeschränkte Shared-String-Tabellen |

Ein ausgeblendetes Sheet ist Metadatum, keine Sicherheitsgrenze. Makro- oder
Beziehungsinhalte werden nicht ausgeführt, aufgelöst oder als vertrauenswürdig
behandelt. Das Input-Binary bleibt untrusted und wird weder in Tests noch in
Diagnoseausgaben mit seinem Inhalt protokolliert.

## Providerentscheidung

Ein direktes T-SQL-Parsing von ZIP und Open XML wäre für Shared Strings,
Worksheet-Relationships, Formeln und Containerlimits zu fehleranfällig. Der
bevorzugte spätere Weg ist ein plattformfähiger, bewusst begrenzter Open-XML-
Provider hinter einem eigenen Deployment- und Berechtigungsvertrag. Der
vorhandene ZIP-Memory-Slice kann als interne Vorarbeit dienen, ersetzt jedoch
keine vollständige Open-XML-Semantik.

Der Provider darf keine Datei-, Netzwerk-, Prozess- oder Office-Automation
benötigen. Seine genaue Form (SQL CLR mit zulässigen Abhängigkeiten oder ein
kontrollierter externer Worker) wird erst nach Prüfung von Runtime,
Lizenz, Trust, Secret-Grenzen und Windows-/Linux-Deployment entschieden.

## Grenzen und Testmatrix

### Konkreter praktischer Spikeplan zur Besprechung

Ergänzung 2026-10-01: ausschließlich Plan, heute keine neue Harness-/
Providerimplementierung oder Runtimeprüfung. Vorgeschlagen: noch zu erstellender
isolierter Non-SQL-Harness auf der vorhandenen .NET-Framework-4.8-/C#-7.3-Toolchain
mit synthetischen Bytearrays und
MemoryStreams, einmaligem Archivindex und begrenzten Partstreams. Vorhandenen
ZIP-Kern qualifizieren, keine zweite ZIP-Parserkopie. Ein Harness-Erfolg
beweist weder SQL-CLR-SAFE noch Linux- oder SQL-Deploymentfähigkeit.

Fixtures: Stored/Deflate, Shared-/Inline-/Rich-Text, Unicode, sparse Zellen
und explizite Emptywerte, Boolean/Error, Formeltext mit vorhandenem,
fehlendem oder leerem Cache, hidden Sheets und 1900/1904-Metadaten.
Negativfälle: CRC/Headerfehler, doppelte Parts/Zellkoordinaten,
Relationships-/Stringreferenzfehler, externe/makrohaltige/verschlüsselte/
ZIP64-Inhalte, DTD/XML-Fehler. Je Limit boundary-1/exact/+1 sowie
ZIP-Bombs/many Parts, Wiederholung und konkurrierende Aufrufe.

Bestehende vorgeschlagene Größen-/Part-/Sheet-/Zell-/Shared-String-/XML-
Limits bleiben unverändert. Zusätzlich vorgeschlagen: 128 MiB gezählte
Allokationen (kein Nachweis totaler Peak-Memory), 5 Sekunden kooperatives
Parserbudget und 15 Sekunden Harness-Watchdog, keine SQL-Wallclockzusage.
Beobachtung von Datei/Temp/Isolated Storage/Netzwerk/Prozesszugriff nur mit
vorhandenen Werkzeugen ohne Installation/Rechteausweitung; Setup außerhalb
des Messfensters. Fehlende/unklare Beobachtung ist INCONCLUSIVE, nicht
Memory-only-PASS. Provider selbst benötigt keinen solchen Zugriff.

SDK-Vergleich erst in später begrenzter Beschaffung: exaktes NuGet-
Katalogpaket, packageHashAlgorithm/hash/size, SHA-512-Nupkg-Verifikation,
net46-DLL-Einzelhashes und transitive Assemblyreferenzen. Heute kein Download
und keine ermittelten Paket-/DLL-Hashes.
[NuGet-Katalogvertrag](https://learn.microsoft.com/en-us/nuget/api/catalog-resource).
Ein späterer SQL-CLR-Qualifizierungsscope beginnt risikobasiert auf 2019
Linux/2025 Windows mit unveränderter strict security, ohne Hochprivilegierung.

Zur späteren Readerbesprechung empfohlen, nicht freigegeben: getrennte
Worksheetliste (SheetOrdinal/Name/Visibility/Date1904) und Zellen je
gewähltem Sheet (Row/Column/StoredType, ValuePresent/Raw/Text,
FormulaPresent/Text/Kind/SharedFormulaIndex, CachePresent/Value).
Nur vorhandene sparse Zellen; keine Shared-Formula-Expansion, Styles/
Anzeigeformat-/Datumsumrechnung oder Formelberechnung. Namen, finale
Signaturen/Resulttypen und Fehler bleiben öffentliche Vertragsvorschläge.

### Quellengeprüfter Providervergleich vom 2026-10-01

Der freigegebene read-only Quellenreview ist abgeschlossen; es wurden keine
Pakete installiert, SQL-Objekte erzeugt oder Runtime-/Labtests ausgeführt.
Vergleichskandidat ist exakt `DocumentFormat.OpenXml 3.5.1` mit bewusst
gepinntem `DocumentFormat.OpenXml.Framework 3.5.1`. Die NuGet-Metadaten
weisen net46-Assets aus, die .NET Framework 4.8 bedienen können; der SDK
deklariert Framework mindestens 3.5.1. Für dessen .NET-Framework-Assets sind
keine zusätzlichen NuGet-Dependencies aufgeführt; das beweist keine
vollständige SQL-CLR-Assemblykette. Der netstandard-Pfad verlangt dagegen
`System.IO.Packaging >= 8.0.1`. Die MIT-Lizenz verlangt bei späterer
Distribution den zugehörigen Notice; die Repository-Rootlizenz wird nicht
verändert.

Die gepinnte README nennt weiterhin `IsolatedStorageException` unter .NET
Framework bei unzureichender AppDomain-Evidence. Das ist ein Risiko, kein
Nachweis zwangsläufigen Diskspills im hier gewünschten Read-only-Binarypfad.
Der offizielle Workaround mit Tempdatei, neuer AppDomain und veränderter
Evidence passt nicht zum angestrebten Memory-only-/SAFE-Vertrag.
Microsofts SQL-CLR-Liste unterstützt unter anderem `System`, `System.Data`
und `System.Xml`; andere Assemblies benötigen Registrierung und
Securityreview. Trustfreigabe beweist weder SAFE-Eignung noch Linuxfähigkeit.

Der [bestehende ZIP-Kern](../../Modules/toolbelt.archive.zip-memory/Clr/ZipEntryProvider.cs)
zielt auf .NET Framework 4.8 und verwendet `System`/`System.Data`.
Er liest einen seekbaren `SqlBytes.Stream` direkt; nur für nichtseekbare
Streams erstellt er eine vollständige Archivkopie. Extrahierte Payload wird
im MemoryStream materialisiert und durch `ToArray` kopiert. Deshalb weder
pauschale Vollarchivkopie noch copy-free XLSX-Verarbeitung behaupten.

Research-Empfehlung, keine endgültige Providerentscheidung: einen begrenzten
internen ZIP-/XML-Kern als portablen Kandidaten qualifizieren, Archivindex
einmal aufbauen und Parts über begrenzte Streams lesen. Das reduziert
potenzielle SDK-/Packaging-Abhängigkeiten, übernimmt aber eigene OPC-/
Relationship-/Open-XML-Semantik und Wartungsrisiken. XML-DTD ist zu verbieten,
Resolver zu deaktivieren; Tiefen-, Text-, Zell-, Shared-String-, Part- und
Summenlimits sind vor unbeschränkter Materialisierung durchzusetzen.
Externe Beziehungen werden nicht aufgelöst; kein externer Worker entsteht
automatisch aus fehlender SAFE-Evidenz.

Kleinster nächster Schritt innerhalb der Spikevorbereitung: den begrenzten
ZIP-/XML-Prüfplan und exakte Dependency-/Lizenz-/Hashliste der SDK-Alternative
gegen den Binary-only-Scope festhalten. Noch fehlend sind tatsächliche
Assembly-/SAFE-/Plattformqualifizierung, Nachweis ohne Dateizugriff sowie
Peak-Memory- und Parallelaufrufgrenzen. SQL-CLR-Deployment-/Runtimeversuche
benötigen einen getrennt begrenzten Folgescope; öffentliche Readerobjekte
bleiben ausdrücklich unfreigegeben.

Ein begrenzter Provider-Spike soll zuerst die konkrete SDK-Version,
Dependency-/Lizenzkette, Memory-only-Verarbeitung und erforderliche
Assemblyrechte prüfen. Die offiziellen SDK-Hinweise nennen mögliche
Isolated-Storage-Probleme unter .NET Framework; `SAFE` und Verarbeitung ohne
Diskspill sind deshalb nachzuweisen, nicht vorauszusetzen. Keine
Hochprivilegierung oder externer Fallback entsteht automatisch aus dem Spike.
Öffentliche SQL-Objekte und Labtests gehören nicht zu dieser vorbereitenden
Dokumentationswelle.

Ungemessene V1-Prüfgrenzen zur Besprechung: 16 MiB komprimiert, 64 MiB
insgesamt dekomprimiert, 16 MiB je Part, 256 ZIP-Parts, 32 Worksheets,
100.000 vorhandene Zellen, 50.000 Shared Strings mit insgesamt 8 MiB
dekodiertem Text und XML-Tiefe 64. Eine Container-Ratio von 200 ist nur ein
Vorschlag; sie kann gültige, stark repetitive Workbooks ausschließen.
Die Zahlen sind keine Runtime-, Streaming- oder Performancezusage.

Vor der Implementierung werden maximale komprimierte und dekomprimierte
Containergröße, maximale Worksheets, Zellen, Zeilen, Spalten und
Shared-Strings festgelegt. Die Verarbeitung muss Limits vor vollständiger
Materialisierung durchsetzen und ZIP-/XML-Bomben als stabile Fehler
zurückweisen.

Tests verwenden ausschließlich selbst erzeugte Minimalworkbooks. Sie decken
Shared/Inline Strings, Unicode, leere und fehlende Zellen, Boolean, Zahlen,
Fehlerwerte, Formeltext mit/ohne Cache, 1900/1904-Metadaten, versteckte
Sheets, unzulässige Beziehungen, beschädigte ZIP-/XML-Strukturen und jedes
Ressourcenlimit ab. Nach Providerwahl folgen Deployment, Wiederholung,
Kollision, Lifecycle und die lokalen SQL_Server_Lab-Ziele für 2019, 2022 und
2025 unter Windows und Linux. Ein CU wird nur bei patchgebundenem Verhalten
gezielt gewählt.

## Entscheidungspunkt

Vor einer Implementierungsfreigabe wird der V1-Schnitt bestätigt oder
geändert: Binary-only-Eingabe und ein normalisiertes Zellresultat ohne
Formelausführung, Dateizugriff oder Typinferenz. Danach können Signatur,
Resultset-Schema, Limits, Errorvertrag und Provider als konkrete Funktion
besprochen und freigegeben werden.

## Quellen

Quellen des abgeschlossenen read-only Vergleichs vom 2026-10-01:

- [Open XML SDK 3.5.1: NuGet-Targets und Dependencies](https://www.nuget.org/packages/DocumentFormat.OpenXml/3.5.1).
- [Open XML Framework 3.5.1: NuGet-Targets und Dependencies](https://www.nuget.org/packages/DocumentFormat.OpenXml.Framework/3.5.1).
- [Gepinnte MIT-Lizenz v3.5.1](https://raw.githubusercontent.com/dotnet/Open-XML-SDK/v3.5.1/LICENSE).
- [Gepinnte README v3.5.1: bekannte Probleme](https://raw.githubusercontent.com/dotnet/Open-XML-SDK/v3.5.1/README.md).
- [Offizieller Isolated-Storage-Workaround v3.5.1](https://raw.githubusercontent.com/dotnet/Open-XML-SDK/v3.5.1/samples/IsolatedStorageExceptionWorkaround/Program.cs).
- [Microsoft: unterstützte .NET-Framework-Bibliotheken für SQL CLR](https://learn.microsoft.com/en-us/sql/relational-databases/clr-integration/database-objects/supported-net-framework-libraries?view=sql-server-ver17).

- [Offizielles Open-XML-SDK: bekannte Probleme](https://github.com/dotnet/Open-XML-SDK#known-issues) – am 2026-10-01 geprüft; kein SQL-CLR-/SAFE-Nachweis.
- [Microsoft: Open XML SDK](https://learn.microsoft.com/en-us/office/open-xml/open-xml-sdk)
- [Microsoft: MS-XLSX](https://learn.microsoft.com/en-us/openspecs/office_standards/ms-xlsx/2c5dee00-eff2-4b22-92b6-0738acd4475e)
- [bestehender Candidate](../../Backlog/TOOLBELT_CANDIDATES.md#tc-2026-045-xlsx-dateien-direkt-lesen)
