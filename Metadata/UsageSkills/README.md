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
ist noch nicht in die neun Dateisystem-Methoden integriert; ein Offline-Recordtest
qualifiziert weder deren neue Signatur noch die Ausgabe innerhalb von SQL Server.

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

Skilltexte beschreiben bekannte Quellen. Sie attestieren weder Installation,
identische vorhandene Definitionen noch Aufruferrechte und erteilen keine
Ausführungsautorität. Private Pakete, Serverdaten, Zugangsdaten und echte
Runtimeausgaben gehören nicht in diese Dateien.
