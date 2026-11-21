# Maßgebliche Usage-Skillquellen

Je katalogisiertem Toolbelt-Objekt steht hier eine redaktionelle Markdown-Datei
unter seinem Schema. Schemafreie Assemblies liegen im Verzeichnis `_assemblies`;
dies ist kein SQL-Schema, ihr Frontmatter enthält `schema_name: ""`.
Das Frontmatter enthält JSON-kompatible YAML-Werte, damit
Unicode, Defaults, boolesche Angaben und Parameterlisten ohne zusätzliche
Runtimebibliothek eindeutig gelesen werden. Die Abschnitte sind im
[Vertrag](../../Backlog/OBJECT_USAGE_SKILLS.md) festgelegt.

Die Dateien enthalten quellgeprüfte Prototypen und ausdrücklich ungeprüfte
Migrationsentwürfe aus den bisherigen öffentlichen Beschreibungen. Maßgeblich
ist jeweils `review_status`; `draft` darf nicht ausgeliefert werden. Unbekannte
Parametersemantik bleibt im Entwurf ausdrücklich ungeklärt. Die Dateien
belegen noch keine vollständige Umsetzung oder native Integration.

Das aktuelle vollständige Inventar wird aus den Moduldeklarationen ermittelt,
einschließlich technischer Assemblies, bisher fehlender Filesystem-Helfer und
der freigegebenen neuen View. Fehlende oder ungeprüfte Quellen werden vom
Generator zurückgewiesen und nicht als fertige Beschreibungen ausgegeben.

```powershell
python -B -m unittest discover -s Tests/Metadata
python -B Scripts/Metadata/generate_usage_skills.py
```

Der zweite Aufruf muss bis zur vollständigen Abdeckung fehlschlagen und erzeugt
keinen Teilinstaller. `--output` schreibt erst nach vollständiger Abnahme eine
neue SQL-Datei. Bestehende Dateien werden nicht überschrieben.

Die ersten quellgeprüften Inline-TVFs enthalten ihren vollständigen Skill bereits
zwischen `OBJECT_USAGE_SKILL:BEGIN` und `OBJECT_USAGE_SKILL:END` in der DDL.
Der Adapter `project_inline_function` in
[usage_skills.py](../../Scripts/Metadata/usage_skills.py) fügt ausschließlich
passive Zeilenkommentare nach `AS` ein. Das schützt auch SQL-Beispiele mit `GO`,
Anführungszeichen oder Blockkommentarzeichen vor einer Ausführung. Die Prüfungen
lesen den Originaltext verlustfrei zurück und vergleichen den verbleibenden
Fachtext weiterhin mit seiner historischen Quelle. Dateien mit mehreren
Funktionen erhalten getrennte Kommentare innerhalb der jeweiligen Definition;
Einfügereihenfolge und Rücklesen bleiben deterministisch. Marker innerhalb von
SQL-Stringliteralen gelten als Daten und werden nicht als DDL-Kommentare entfernt.
Für Multistatement- und skalare Funktionen verwendet `project_function_ddl`
denselben Skilltransport. Dies qualifiziert keine neue Hilfeausgabe oder Installation.

Für vorhandene CLR-Bridges mit `IF OBJECT_ID(...) IS NULL` und einem konstanten
`EXEC sys.sp_executesql N'CREATE FUNCTION ... AS EXTERNAL NAME ...;'` wird der
Skill innerhalb der tatsächlich ausgeführten DDL eingebettet. Guardname und
Funktionsidentität müssen übereinstimmen; Verkettungen, gemischte direkte/
dynamische Definitionen und unpassende Bindungen werden nicht als Projektion
akzeptiert. SQL-Quoting und vollständiger Unicode bleiben beim Einbetten und
Rücklesen erhalten. Andere SQL-Literale mit Beispielmarkierungen bleiben Daten.
Die Vergleichsprüfung entfernt ausschließlich den eigenen bytegleichen
kanonischen Kommentar; Methoden-/Guard-/Fachänderungen bleiben sichtbar.

`project_relation_ddl` bettet die geprüften View-/Tabellenskills ebenfalls
innerhalb ihrer Definition ein. Der gemeinsame Builder übernimmt technische
Assembly-Skills in die erzeugte CREATE-ASSEMBLY-DDL. Sein Quellenmanifest bindet
den verwendeten Renderer und genau die konsumierten Assembly-Skilldateien;
andere redaktionelle Entwürfe werden dadurch nicht zu Buildinputs oder zu
qualifizierten Produktbeschreibungen.

`render_help_resultset` erzeugt das zusätzliche konstante Resultset mit genau
vier Spalten. Die ersten beiden T-SQL-Prozeduren `USP_PrepareResultTable` und
`USP_SecondSessionProbe` liefern es im vorhandenen positiven Hilfezweig direkt
vor `RETURN 0`. Die bisherige Hilfe bleibt erhalten. SQL-Layout darf mehrzeilige
Markdown-Literale nicht durch zusätzliche Einrückung verändern. Diese Eigenschaft
wird unabhängig vom DDL-Kommentar durch Rücklesen der SQL-Literale geprüft.

Die Einbindung in alle weiteren frühen Hilfezweige und die vollständige
View-/Installerintegration sind noch offen. Ein bestandener Offline- oder
Syntaxtest ist kein nativer Hilfe- oder Gesamtinstallationsnachweis. Historische
Fachbelege werden ausschließlich für den exakt verglichenen verbleibenden
Fachpfad genutzt, niemals zur Abnahme der neuen Hilfeausgabe.

Auch das [CSV-Modul](../../Modules/toolbelt.file.csv-memory/README.md) besitzt
jetzt vollständige quellgeprüfte Verträge für seine beiden öffentlichen
Prozeduren, drei internen CLR-Funktionen und die Assembly. Die Prozeduren
liefern den zusätzlichen Skill im frühen Hilfezweig. Die internen Funktionen
tragen ihn als DDL-Kommentar: Parserfehler sind eine Sentinelzeile,
Messfehler negative Codes; der Quoter wirft Exceptions und setzt einen
vollständigen Budgetpreflight voraus. Diese Transporte dürfen nicht
gegeneinander ausgetauscht werden.

Der [Capability-Skill](toolbelt_metadata/VW_ModuleCapabilities.md) beschreibt
eine andere Oberfläche als den hier erzeugten Skillkatalog: Die Capability-View
liest `sys.objects` und `sys.assemblies`, um sichtbare namens-/typgleiche
Kandidaten zu zeigen. Ihre Version und ihr Modus bleiben NULL. Der konstante
Skillkatalog liefert Nutzungsverträge unabhängig von der Installation. Keine
der beiden Views attestiert vorhandene Aufruferrechte.

Kompakte Tabellen mit Spalten auf derselben Zeile wie die öffnende Klammer
nutzen für ihren Skill die bereits vorhandene Zeilengrenze zwischen Tabellenname
und Spaltenliste. Der Adapter ergänzt keine Formatierungsbytes: Nach Entfernen
des exakt quellgebundenen Kommentars muss die ursprüngliche Definition
bytegleich vorliegen. Der Skill bleibt im eigenen CREATE-TABLE-Kopf; ein zum
Nachbarn oder hinter die Definition verschobener Kommentar wird abgewiesen.

Bei bestehenden kompakten Hilfezweigen darf auch `RETURN 0;` nach dem alten
Help-SELECT in derselben Zeile stehen. Der Adapter fügt die neue Skillzeile
nach dem alten Resultset und vor diesem RETURN ein. Eine eigene kompakte
Layoutmarkierung bindet die zusätzlich nötige Zeilengrenze; beim Entfernen der
Projektion werden beide exakt entfernt. Ein anderer Hilfezweig, fehlende
Statementgrenzen oder verwaiste Layoutmarker werden nicht normalisiert.

Bei gruppierten Prozeduren bindet der Hilfeadapter die ausgewählte Identität
an ihren eigenen `GO`-Batch. Benachbarte Hilfezweige und lokale CREATE-TABLE-
Anweisungen im Fachpfad werden nicht als neue Prozedurdeklaration behandelt.
Kommentar und Hilfe müssen zur gleichen Prozedur gehören; verwaiste Marker
außerhalb einer Prozedur oder ein zum Nachbarn verschobener Skill werden
zurückgewiesen. Die Prüfung einer bisherigen Dateisystem-Deklaration ist
ausschließlich ein Parsernachweis und keine Freigabe von Dateioperationen.

Die beiden internen Dateisystem-Helfer `USP_InternalEmitHelp` und
`USP_InternalRouteResult` besitzen jetzt einen abschließenden optionalen
`@Hilfe bit=0`. Ihr neuer früher Hilfezweig liefert nur den eigenen Skill und
kehrt vor dem bisherigen Helferpfad zurück. Bestehende Pflichtargumente bleiben
Pflichtargumente. Vorhandene Parameter und Normalpfad werden exakt erhalten;
die Erweiterung wird separat von unveränderter Fachlogik geprüft. Der Adapter
lehnt OUTPUT-Parameter ohne eigenen Initialisierungsvertrag ab. Bei mehreren
Helfern werden auch identische Parameterergänzungen ausschließlich innerhalb
der jeweiligen Prozedur entfernt oder regeneriert. Die native Hilfeabnahme
und die Hilfe der neun CLR-Einstiege stehen weiterhin aus.

Für CLR-Prozeduren erzeugt
[clr_usage_skills.py](../../Scripts/Metadata/clr_usage_skills.py) denselben
vierkolumnigen Vertrag als konstante C#-Daten. Gewöhnliche escapte Stringliterale
erhalten LF und Supplementary-Zeichen unabhängig von Checkout-Zeilenenden;
`SkillMarkdown` verwendet `SqlMetaData.Max`. Die Record-Factory ist ohne
SQL-Kontext prüfbar. Erst die getrennte Send-Methode verwendet die SQL-CLR-Pipe.
Die Moduldatei wird nur nach vollständiger geprüfter Abdeckung aller deklarierten
CLR-Prozeduren erzeugt und überschreibt keine bestehende Datei. Dieser Renderer
ist in die neun Dateisystem-Methoden integriert. Deren abschließender optionaler
`@Hilfe bit=0` wird als `SqlBoolean` gebunden; 1 sendet den konstanten Skill vor
der ersten Fachprüfung, 0 oder NULL führt den bisherigen Fachpfad aus. Vorhandene
Pflichtargumente bleiben Pflichtargumente. Ein Offline-Recordtest qualifiziert
weder den nativen SQL-Binder noch die Ausgabe innerhalb von SQL Server.

Die neun internen Dateisystem-CLR-Einstiege besitzen inzwischen eigene
quellgeprüfte Skills und vollständige Kommentare vor ihrem jeweiligen
`AS EXTERNAL NAME`. Der Projektor bindet jeden Kommentar an genau diese
Prozedur; verschobene, doppelte oder geänderte Texte werden zurückgewiesen.
Der eigene Hilfeschalter wird separat und ausdrücklich ergänzt; der verbleibende
Fachtext wird bytegenau mit dem ursprünglichen Stand verglichen. Die
Rohschnittstellen beschreiben ausdrücklich ihre eigenen Grenzen, beispielsweise die fehlenden
festen oberen Löschbudgets im Unterschied zum Listing.

Auch alle neun öffentlichen Dateisystem-Prozeduren enthalten ihre geprüften
Skillkommentare und liefern den unveränderten Skill als zusätzliches Resultset
nach ihrer bisherigen Standardhilfe. Die Hilfe kehrt vor Provider und
ResultTable-Routing zurück. Parameter, Defaults, Normalpfad und bisherige
Hilfe bleiben erhalten. Die Beschreibungen unterscheiden ausdrücklich zwischen
SQL-/TempDB-Ergebnissen und nicht durch SQL-ROLLBACK rücknehmbaren Dateieffekten.
Eine native Abnahme der neuen zusätzlichen Ausgabe steht weiterhin aus.

Der gesonderte Windows-.NET-Transporttest verwendet nur zwei Prozedurprototypen
und zusätzlichen synthetischen Unicode-Text. Neues privates Verzeichnis wählen:

```powershell
python -B Tests/Metadata/test_clr_usage_skills.py --prepare-clr-record-fixture .runtime/clr-record-check
$probe = (Resolve-Path .runtime/clr-record-check).Path
$compiler = Join-Path $env:WINDIR 'Microsoft.NET/Framework64/v4.0.30319/csc.exe'
$argsForCompiler = @('/nologo', '/r:System.Data.dll', ('/out:' + (Join-Path $probe 'Probe.exe')),
    (Join-Path $probe 'Generated.cs'), (Resolve-Path Tests/Metadata/ClrUsageSkillRecordHarness.cs).Path)
& $compiler @argsForCompiler
if ($LASTEXITCODE -ne 0) { throw 'CLR_RECORD_COMPILE_FAILED' }
& (Join-Path $probe 'Probe.exe') (Join-Path $probe 'Expected.md')
if ($LASTEXITCODE -ne 0) { throw 'CLR_RECORD_TEST_FAILED' }
```

Geprüft werden Record-Metadaten, vollständiger Unicode-/LF-Inhalt und die
Ablehnung unbekannter Objekte. Die SQL-Pipe und der Dateisystemprovider werden
nicht aufgerufen; dieser Test ersetzt keine native SQL-CLR-Abnahme.

Für einen zusätzlichen In-memory-Vergleich aller neun tatsächlichen internen
Dateisystem-Skills kann die Vorbereitung stattdessen mit
`--prepare-clr-module-fixture` und einem neuen privaten Verzeichnis erfolgen.
Kompiliere dessen `Generated.cs` mit demselben Harness und rufe das Programm mit
`--module-fixture <Verzeichnis>` auf. Es vergleicht alle neun vollständigen
Recordtexte mit den kanonischen Quellen, ohne Provider oder SQL-Pipe aufzurufen.

Der ergänzende [ClrProviderUsageSkillHarness.cs](../../Tests/Metadata/ClrProviderUsageSkillHarness.cs) prüft die tatsächlich gebaute
Assembly: optionale Signaturen, die neun vollständigen Recordtexte und frühe
Hilfe bei typgültigen, fachlich ungültigen Eingaben. Die 0-/NULL-Gegenpfade
scheitern gezielt vor SQL-/Root-/Dateizugriff. Beim Hilfeweg wird außerhalb von
SQL Server die erwartete fehlende SQL-Pipe festgestellt; dies ist ausdrücklich
kein nativer Pipe-PASS. Diese Offlineprüfung benötigt keine Rootkonfiguration
oder Rechtevergabe und führt keine Dateioperationen aus.

Skilltexte beschreiben bekannte Quellen. Sie attestieren weder Installation,
identische vorhandene Definitionen noch Aufruferrechte und erteilen keine
Ausführungsautorität. Private Pakete, Serverdaten, Zugangsdaten und echte
Runtimeausgaben gehören nicht in diese Dateien.
