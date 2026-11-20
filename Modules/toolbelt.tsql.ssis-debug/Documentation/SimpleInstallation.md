# DTSX-Debug mit XML und einer SQL-Datei

Dieser Quellstand bietet einen normalen T-SQL-Installer und einen XML-Aufruf.
Die veröffentlichten Vorabreleases bis rc.4 bleiben unverändert; sie besitzen
diesen neuen Vertrag noch nicht. Es wird kein neues Release veröffentlicht.

Für den normalen Debug-Ablauf gilt die Anleitung zur
[lokalen CTE-Kette](LocalCteDebug.md): Variablen am Anfang, Source-/Lookup-SQL
aus dem Paket, angenommene Flatfile-Spalten und lokale #-Tabellen für
Prozedurresultsets. Die Erzeugung öffnet keine Verbindung zum Quellsystem.

## Installationsdatei bauen

Auf einem Windows-Buildhost mit .NET-Framework-4.8-Entwicklungswerkzeugen,
MSBuild, PowerShell 7 und Python 3 die folgenden Befehle vom Repositoryroot
ausführen. `ScriptDomDllPath` bezeichnet das unveränderte net472-Binary aus
Microsofts NuGet-Paket `Microsoft.SqlServer.TransactSql.ScriptDom` 180.117.0.
Ausgabeordner müssen neu sein. Die Resolver erzeugen eine reproduzierbare
private Toolbelt-Kopie; Mono.Cecil ist ausschließlich ein Buildwerkzeug.

```powershell
& Modules/toolbelt.tsql.script-parser/Scripts/New-ClrReleaseArtifacts.ps1 `
  -ScriptDomDllPath C:/BuildInputs/Microsoft.SqlServer.TransactSql.ScriptDom.dll `
  -OutputDirectory .runtime/simple/parser
python Modules/toolbelt.tsql.ssis-debug/Scripts/New-DependencyPins.py .runtime/simple/parser
& Modules/toolbelt.tsql.ssis-debug/Scripts/New-ClrReleaseArtifacts.ps1 `
  -ScriptDomDllPath C:/BuildInputs/Microsoft.SqlServer.TransactSql.ScriptDom.dll `
  -ParserReleaseDirectory .runtime/simple/parser -OutputDirectory .runtime/simple/ssis
python Modules/toolbelt.tsql.ssis-debug/Scripts/New-SimpleInstall.py `
  --ssis-release .runtime/simple/ssis `
  --scriptdom .runtime/simple/parser/tlblt.Microsoft.SqlServer.TransactSql.ScriptDom.dll `
  --output .runtime/simple/Install-SsisDebug.sql
```

Mit `--mode central` denselben Funktionssatz für eine zentrale Installation
bauen; Standard ist local. Neben der SQL-Datei entsteht das zum Clientweg
gehörende Buildmanifest.

Die fertige Datei enthält Binaries, Schemas und alle drei notwendigen
Prozeduren. Sie benötigt beim Ausführen weder einen Dateipfad auf dem Server
noch SQLCMD, Deploymenttabellen oder Extended Properties. Die vier Parser-TVFs
müssen für diesen SSIS-Aufruf nicht installiert werden.

## Lokal oder zentral installieren

In `Install-SsisDebug.sql` nur die erste Zeile `USE [ContosoToolbelt];` auf die
gewünschte vorhandene Datenbank ändern. Die gesamte Datei in einer normalen
SSMS-Abfrage ausführen. Lokal ist dies die Arbeitsdatenbank, zentral die
gemeinsame Toolbelt-Datenbank. SQL Server 2019/2022/2025 unter Windows und
aktiviertes CLR sind erforderlich. Die SQL-Datei stammt aus demselben Installationskern wie der gemeinsame Satz.
Der Installer aktiviert CLR oder
TRUSTWORTHY nicht und ändert `clr strict security` nicht. Die Engine prüft die
tatsächlich nötigen CREATE-/Schema-/Assemblyrechte; Rechte werden nicht erteilt.

| Weg | Auswahl beim Bauen mit `--trust-mode` | Verhalten |
|---|---|---|
| Automatisch, Standard | `auto` | Bereits TRUSTWORTHY ON: vorhandenen Trust nutzen; sonst exakte Hashregistrierung |
| Selektive Hashfreigabe | `hash` | Binaryvergleich und Registrierung der beiden exakten Hashes; entsprechende Serverrechte erforderlich |
| Vorhandener DB-Trust, mit Integritätsvergleich | `trustworthy-checked` | Erwartete Binaryhashes vergleichen; keine Hashregistrierung |
| Vorhandener DB-Trust, ohne Toolbelt-Hashprüfung | `trustworthy` | Keine Toolbelt-Hashprüfung oder Registryabfrage; Engineautorisierung bleibt bestehen |

Die beiden TRUSTWORTHY-Wege setzen einen entsprechend berechtigten
Datenbankowner und bereits eingerichteten Trust voraus. TRUSTWORTHY erweitert
die Vertrauensgrenze der Datenbank; diesen Weg nur für bewusst vertrauten Code
wählen. Nach einem Fehler erfolgt kein Wechsel des Trustwegs. Buildseitig
werden Herkunft und reproduzierbare Eingaben bei allen Wegen geprüft.

Fehlende Objekte werden angelegt, bestehende nicht überschrieben. Wiederholung
ergänzt fehlende Objekte. Bei den geprüften Wegen werden abweichende vorhandene
Assemblybytes abgewiesen. Dies ist kein In-place-Upgrade: Für einen neuen Build
eine neue eigene Datenbank verwenden oder die eigenen Objekte nach Prüfung
ihrer Verbraucher gezielt entfernen. Kein automatisches Uninstall unbekannter
Objekte oder Trusteinträge; die bisherigen markerbasierten Lifecycle-Skripte
sind für diese Installation nicht geeignet. Nach einem Fehler können zuvor
angelegte Objekte und Hashfreigaben bestehen bleiben; die Fehlermeldung bleibt
erhalten und der folgende Installationsschritt wird abgebrochen.

Die SQL-Assemblynamen sind `tlblt_Tsql_SsisDebug` und
`tlblt.Microsoft.SqlServer.TransactSql.ScriptDom`. Letztere hat auch eine eigene
CLR-Identität; ein SQL-Alias allein würde abweichende Microsoft-Versionen nicht
isolieren. Die private Kopie ist keine von Microsoft signierte Assembly.
Fremde Assemblies werden nicht übernommen oder verändert.

## DTSX übergeben

```sql
DECLARE @DtsxXml nvarchar(max)=N'<vollständiges DTSX-XML>';
EXEC toolbelt_tsql.USP_ExplainSsisDataFlow @PackageXml=@DtsxXml;
```

Beim Einfügen als T-SQL-Literal enthaltene einfache Anführungszeichen
verdoppeln; Anwendungen sollten einen `nvarchar(max)`-Parameter binden.
Alternativ `@PackageBytes` mit den Originalbytes verwenden, niemals beide.
Paketdefaults genügen, soweit sie alle erforderlichen Werte bestimmen.
Abweichende Startwerte sind optional:

```sql
EXEC toolbelt_tsql.USP_ExplainSsisDataFlow
  @PackageXml=@DtsxXml,
  @StartValues=N'{"User::SourceFloor":5,"User::Offset":2}';
-- Zentral aus einer anderen Datenbank, nach entsprechender Zugriffsfreigabe:
EXEC [ContosoToolbelt].toolbelt_tsql.USP_ExplainSsisDataFlow
  @PackageXml=@DtsxXml;
```

`StartValues` ist eine JSON-Namens-/Wertzuordnung mit typisierten JSON-Werten;
kein Binding-Template notwendig. Namen müssen eindeutig sein; bei mehreren
Scopes `Scope\Name` als JSON-Key verwenden (Backslash im JSON verdoppeln).
Keine sensitiven Eingaben. Nicht zugleich `Bindings` übergeben.
`bindings-template` bleibt für komplexe explizite Zuordnungen verfügbar und
verlangt `StartValues=NULL`.

Connection-Manager und ihre unterstützten `ConnectionString`-Expressions liefern die
Datenbankzuordnung. Der Resolver öffnet keine externe Verbindung und exportiert
keine Connectionstrings. Unterschiedliche Serverangaben verlangen eine
explizite Zuordnung. Andere Property-Expressions werden abgewiesen statt ignoriert. Fehlende Projektconnections/-parameter müssen über den
dokumentierten Projekt-/Katalogkontext ergänzt werden. Serveridentität wird
aus dem Paket nicht bewiesen.

Der begrenzte Ausdrucksresolver unterstützt Literale, Variablenreferenzen,
arithmetische/Vergleichsoperatoren, `?:`, `&&`, `||`, Casts `DT_WSTR`, `DT_I4`,
`DT_I8` sowie UPPER, LOWER, LTRIM, RTRIM, TRIM, LEN und REPLACE. Unbekannte,
zyklische, mehrdeutige oder fehlende strukturbestimmende Werte liefern eine
Diagnose statt erfundener Ergebnisse. Ein noch fehlender einfacher Laufzeitwert
erscheint als typisierte NULL-Deklaration mit TODO im SQL-Variablenblock.

## Ergebnis prüfen und bewusst ausführen

`DebugScript` enthält den zusammenhängenden SQL-Entwurf, `TargetSql` eine
Zielprojektion. `IsComplete=1` bedeutet vollständig erzeugt. Im Standardmodus
`@CatalogMode='package'` bleiben `SafetyStatus='not_checked'` und
`IsExecutable=0`: Reale Objekte, RLS, Typen und Collation sind nicht geprüft.
Spalten stammen aus den im DTSX deklarierten Source-/Lookup-Resultsets.
Auch Joins, TVFs und Prozedurresultsets werden ohne erfundene Basistabellen-
Metadaten verarbeitet. Flatfiles liefern angenommene Dummyzeilen. Der
[CTE-Ablauf](LocalCteDebug.md) erklärt lokale Prozedurmaterialisierung,
erforderliche SQL-Strukturwerte und Grenzen.
Ordinale Namen, BIN2 und Codepage 1252 beziehungsweise explizite UTF8-Codepage
sind Entwurfsannahmen. Den vollständigen Inhalt vor manueller Ausführung
prüfen, richtige Datenbank und benötigte Datenrechte wählen. Die Analyse selbst
führt weder Paket noch erzeugtes SQL aus. Der manuell ausgeführte Entwurf
kann Originalprozeduren aufrufen; deren unbekannte Seiteneffekte werden nicht
als lesend garantiert. NOLOCK kann unbestätigte, fehlende
oder doppelte Zeilen liefern.

```sql
EXEC toolbelt_tsql.USP_ExplainSsisDataFlow
  @PackageXml=@DtsxXml, @CatalogMode='catalog';
```

Der strengere Weg benötigt die in der [API-Referenz](USP_ExplainSsisDataFlow.md)
beschriebenen Metadatenrechte auf die ausgewählten Datenbanken. Die Erzeugung
einer wiederverwendbaren Prozedurdefinition verlangt diesen Modus weiterhin.
Für den normalen Paketmodus genügt API-EXECUTE; `ResultTable` und die spätere
SQL-Ausführung haben gesonderte Rechteanforderungen. Keine pauschale
sysadmin-Anforderung an den Anwender der API.

Die [Prüfübersicht](../Tests/README.md) trennt die neuen gezielten Nachweise
von älteren Release- und Gesamtqualifikationen. Die Vereinfachung begründet
keine vollständige SSIS-Runtimeparität oder neue TLS-/GUI-Abnahme.
