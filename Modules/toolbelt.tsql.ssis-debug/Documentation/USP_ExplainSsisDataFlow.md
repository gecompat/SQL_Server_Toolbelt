# toolbelt_tsql.USP_ExplainSsisDataFlow

Die Prozedur akzeptiert vollständiges DTSX als `@PackageXml nvarchar(max)`
oder alternativ `@PackageBytes varbinary(max)`, niemals beide. Der normale
Aufruf benötigt keine Binding-Vorlage:

```sql
EXEC toolbelt_tsql.USP_ExplainSsisDataFlow @PackageXml=@DtsxXml;
EXEC toolbelt_tsql.USP_ExplainSsisDataFlow @PackageXml=@DtsxXml,
  @StartValues=N'{"User::SourceFloor":5}';
```

Die [Kurzanleitung](SimpleInstallation.md) erklärt Installation, Trustwege,
Connection-Expressions, Startwerte und Ergebnisdeutung. Standardmäßig erzeugt
`@CatalogMode='package'` einen ungeprüften Entwurf ohne Quellkatalogabfragen.
`IsComplete` ist keine Katalog-/Ausführungsfreigabe. Für die nachfolgenden
streng gebundenen Abläufe ausdrücklich `@CatalogMode='catalog'` übergeben.
Die editierbare Schema-2-Vorlage bleibt eine Option für komplexe Bindungen;
Paket-/Kontexthashes und `availableInputs` bleiben dabei unverändert.
Sensitive Eingaben werden nicht exportiert.

## Geprüften Zielpfad als Prozedur wiederverwenden

Erzeuge die Definition im Katalogkontext der späteren Installation. Die
Ziel-ID kommt aus der vorhandenen Analyse. Wähle einen vollständig gebundenen
Pfad von einer gewöhnlichen SQL-Tabelle über genau eine Derived Column bis zur
SQL-Zielprojektion in derselben Datenbank.

```sql
EXEC toolbelt_tsql.USP_ExplainSsisDataFlow
    @PackageBytes = @PackageBytes,
    @Bindings = @Bindings,
    @CatalogBindings = @CatalogBindings,
    @TargetFlow = 'f0001',
    @Operation = 'procedure-definition',
    @ProcedureSchema = N'ContosoDebug',
    @ProcedureName = N'USP_Synthetic';
```

Prüfe `ProcedureManifest` und `ProcedureDefinition` gemeinsam. Das Manifest
enthält den SHA-256 der Definition als UTF-8, gebundene Quellen, die fachlichen
Parameter mit Herkunft und das geordnete Spaltenschema. `IsExecutable=0`
kennzeichnet die gesondert zu installierende DDL. Bei einer Diagnose ohne
Definition kann der vorhandene Explain-Aufruf den Blocker weiter eingrenzen.

Führe die geprüfte Definition als eigenen `CREATE PROCEDURE`-Batch in der
gebundenen Datenbank und im vorhandenen dedizierten Debug-Schema aus. Ein
gleichnamiges Objekt lässt die Erstinstallation scheitern. Halte Manifest,
installierte Moduldefinition aus `sys.sql_modules`, Objekt-ID und Objektname
im Installationsnachweis fest. Prüfe vor einem `ALTER PROCEDURE` oder
`DROP PROCEDURE` den erwarteten Altstand und die Ownership anhand dieses
Nachweises. Erfasse nach erfolgreichem ALTER den neuen Katalogstand. Eine
identische Version braucht keine DDL. Vergib für eine inkompatible Signatur
einen neuen Namen.
Toolbelt-Deploy und -Uninstall verwalten die erzeugte Prozedur nicht.

Die Hilfe zeigt die tatsächlichen Parameternamen und Typen. In der synthetischen
Fixture sind `@v0001` und `@v0003` die Eingaben für Filter und Offset. Werte
für andere Abläufe stehen im jeweiligen Manifest.

```sql
EXEC ContosoDebug.USP_Synthetic @Hilfe = 1;
EXEC ContosoDebug.USP_Synthetic @v0001 = 150, @v0003 = 7;
```

Der fachliche Aufruf liefert ein Resultset mit den Namen, SQL-Typen und der
Nullbarkeit aus dem Manifest, auch bei null Zeilen. Die Zeilenreihenfolge
ist offen. `@ResultTable` leitet die Projektion mit der üblichen
`@KeepData`-Semantik in eine vorhandene lokale Temp-Tabelle. `@Debug` schreibt
Status in Messages. Führe den fachlichen Aufruf außerhalb offener oder
impliziter Transaktionen aus.

Ein Fehler beim Berechnen oder Materialisieren stoppt den gesamten erzeugten
Batch vor jeder ResultTable-Vorbereitung. Der Aufrufer erhält den ursprünglichen
SQL-Fehler. Vorbereitung und Schreiben der ResultTable liegen gemeinsam in
einer eigenen Transaktion; auch ein späterer Constraintfehler erhält vorhandene
Daten und Indizes. Aufrufgebundene interne Temps verlassen den dynamischen
Scope nicht. Diese Fehleratomarität verlangt eine neu erzeugte Definition aus
dem korrigierten Build; bereits installierte frühere Definitionen ändern sich
durch ein Toolbelt-Update nicht automatisch.

Fachliche Eingaben sind nicht sensitive, nicht NULL-fähige Szenariowerte vom
Typ `int`, `bigint` oder `decimal(p,s)`. Strukturelle Abhängigkeiten bleiben
gebunden. Das Profil schließt unter anderem Lookup, Cross-DB, berechnete
Quellspalten und RLS-Quellen aus. Bei Schema- oder Objektänderung prüfe den
Ablauf erneut und erzeuge eine neue Definition. Der Aufrufer braucht
`EXECUTE`, `SELECT` auf den verwendeten Quelldaten, `VIEW DEFINITION` in
der gebundenen Datenbank und Lesesicht auf die Sicherheitsprädikate.
Für die ResultTable-Option benötigt er auch Zugriff auf den kanonischen
Helper `toolbelt_core.USP_PrepareResultTable`.

## Vollständiger Eingabevertrag

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@PackageBytes` | `varbinary(max)` | `NULL` | Input | Vollständiges DTSX-XML als UTF8-/UTF16-Bytepuffer; alternativ PackageXml verwenden, niemals beide gleichzeitig. Kein Pfad oder Base64-Text. NULL ist bei PackageXml oder Hilfe zulässig; sonst erforderlich. PackageFormatVersion 6/8, kein verschlüsselter Container, DTD, externer Resolver oder XInclude. MaxPackageBytes begrenzt die Rohbytes; XML-Tiefe bleibt absolut 128. Paket und enthaltenes SQL werden nicht ausgeführt. |
| `@Operation` | `varchar(32)` | `N'explain'` | Input | Taxativ, ordinal/case- und whitespace-sensitiv. explain (Default) analysiert die gebundenen Datenflüsse und liefert Workflow, Stufenverzeichnis, Debug-SQL und Diagnosen. bindings-template liefert nur die paket-/kontextgebundene Schema-2-Eingabevorlage zum Bearbeiten unter values und verlangt Bindings=NULL sowie CatalogBindings=NULL. procedure-definition liefert Definition und Manifest für einen geeigneten gebundenen Zielpfad zur gesonderten Installation. Dazu sind TargetFlow, ProcedureSchema und ProcedureName Pflicht und InspectStage muss NULL sein. NULL, leer und andere Schreibweisen sind ungültig. |
| `@ProjectContext` | `nvarchar(max)` | `NULL` | Input | NULL (Default) bedeutet leeren Schema-2-Projektkontext. Sonst JSON-Objekt {"schemaVersion":2,"projectParameters":[...],"connectionManagers":[...]}; beide Arrays optional. Parameterentry: name, ssisType sowie optional designValue, required und sensitive (JSON-Booleans); Connectionentry: refId, name, provider. Provider taxativ sqlserver-oledb oder sqlserver-adonet, beide ordnen vorhandene SQL-Server-Connections zu; keine Connectionstrings/Credentials. Eindeutige Namen/refIds, Projektconnections dürfen Paketconnections nicht überlagern. Typ-/Wertabbildung im Abschnitt SSIS-Eingabetypen der Objektreferenz; unbekannte Typen sind nicht bindbar. Andere Rootkeys, resourceOptions und schemaVersion ungleich 2 ungültig. Feste Kontrollprotokollgrenze 4194304 UTF-16-Bytes zusätzlich zu den gewählten JSON-Limits; beim Zurückgeben der Bindings denselben Kontext verwenden. |
| `@Bindings` | `nvarchar(max)` | `NULL` | Input | NULL (Default) verwendet vorhandene nicht sensitive Designdefaults; benötigte fehlende Laufzeitwerte bleiben als fehlender Kontext sichtbar. Sonst vollständiges von bindings-template zurückgegebenes JSON-Objekt mit schemaVersion=2, profile exakt ssis-debug-components-v2, packageSha256, contextSha256, availableInputs und values. Ausschließlich values nach generierten Eingabekeys bearbeiten; Paket-/Kontexthashes und vollständige Herkunftsmetadaten unverändert zurückgeben. values ist ein Objekt typisierter JSON-Werte: Stringtexte/ISO-Datum/-GUID/-Hex, JSON-Boolean für bit, exakte Zahlen gemäß SSIS-Eingabetypen; JSON-null als SQL-NULL, keine SQL-Ausdrücke. Sensitive/ unbekannte/nicht bindbare Keys abgewiesen. Im Template-Modus ausschließlich NULL; kein leeres Ersatzobjekt und keine Ressourcenoptionen. |
| `@CatalogBindings` | `nvarchar(max)` | `NULL` | Input | NULL (Default) leitet die benötigte Datenbankzuordnung aus Connectionstrings bzw. unterstützten Connectionexpressions im Paket ab. Mehrdeutige/fehlende Projektverbindungen und unterschiedliche Server werden diagnostiziert; keine externe Verbindung. Eine explizite Zuordnung überschreibt die automatische Ableitung. Sonst JSON-Objekt mit schemaVersion 1 oder 2, defaultDatabase als Name, databases als Array eindeutiger erlaubter Same-instance-Datenbanknamen und connections als Objekt {importierteConnectionId:Datenbankname}. Default und jede Zuordnung müssen in databases stehen; Connection-IDs müssen im Paket/Projektkontext vorhanden sein. Version 1 erlaubt nur diese Felder; Version 2 ergänzt flatFileInputs als Objekt (auch {}). Je Flatfileentry: database, schema, object, columns als Mapping importierter Spalten-IDs zu SQL-Spaltennamen; optional rowOrdinalColumn und errorRows als entsprechender Quellobjekt-/Spaltenbeschreiber gemäß Komponentenvertrag. Keine freien SQL-Fragmente, Server-/Credential-/Dateipfade oder automatische Rechte. Template-Modus verlangt NULL; leer/andere Shapes ungültig. |
| `@TargetFlow` | `varchar(64)` | `NULL` | Input | NULL (Default) berücksichtigt alle erkannten Zielflüsse getrennt. Sonst exakte modellinterne TargetFlowId aus der Workflow-/StageIndex-Ausgabe desselben Pakets, maximal varchar(64). Groß-/Kleinschreibung und Whitespace bleiben erhalten. Leer oder unbekannt ist ungültig. Bei procedure-definition ist genau eine vorhandene TargetFlowId erforderlich. |
| `@InspectStage` | `varchar(64)` | `NULL` | Input | Taxativ für Steuerwerte: NULL (Default) liefert Zielskript/Stufenverzeichnis ohne zusätzliche StageSql-Auswahl; all liefert die unterstützten Vorgängerstufen jedes gewählten Ziels. Alternativ eine exakte StageId aus dem StageIndex desselben Pakets; dann ist TargetFlow fachlich erforderlich und die Stufe muss zu dessen Vorgängerpfad gehören. all benötigt keinen expliziten TargetFlow. Kein Trim/Casefold; unbekannte/leere konkrete ID ungültig. Bei procedure-definition ist ausschließlich NULL zulässig. |
| `@LookupPolicies` | `nvarchar(max)` | `NULL` | Input | NULL (Default) bedeutet beliebige, pro relevantem Snapshot einmal materialisierte Trefferauswahl. Sonst exakt JSON-Objekt {"schemaVersion":1,"lookups":{"&lt;Lookup-Komponenten-ID&gt;":{"orderBy":[{"column":"&lt;Referenzspalte&gt;","direction":"asc"}]}}}. IDs müssen existierende Lookupkomponenten adressieren, orderBy nicht leer und ohne doppelte Spalten. direction taxativ asc = aufsteigend oder desc = absteigend, exakt kleingeschrieben. Keine freien ORDER-BY-Ausdrücke; vollständige Sortierbindung erforderlich, Gleichstände erhalten keine erfundene Eindeutigkeit. |
| `@ComparisonCollation` | `sysname` | `NULL` | Input | NULL (Default) verwendet bei Katalogbindung die Collation der expliziten defaultDatabase. Sonst genau ein tatsächlich vom Server unterstützter Collationname als sysname, kein COLLATE-SQL-Fragment; Prüfung gegen sys.fn_helpcollations. Dynamische Serverwertemenge, kein festes erfundenes Inventar: SELECT name FROM sys.fn_helpcollations() zeigt sie. Dient Vergleichs-/Ausdrucksbindung und ändert keine DB-/Spaltencollation; leer/unbekannt ungültig. |
| `@TSqlVersion` | `smallint` | `150` | Input | Taxativ: 150 = SQL-Server-2019-Grammatik (Default), 160 = 2022, 170 = 2025 für die Parser-/Sicherheitsprüfung erzeugten SQLs. Kein automatischer Dialektwechsel/Ablesen der Engineversion. NULL/andere smallint-Werte ungültig. |
| `@MaxPackageBytes` | `bigint` | `134217728` | Input | bigint 0..9223372036854775807, Default 134217728: Rohbytes des DTSX-Pakets. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxXmlCharacters` | `bigint` | `134217728` | Input | bigint 0..9223372036854775807, Default 134217728: vom XML-Reader gezählte Zeichen des Pakets. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxXmlNodes` | `bigint` | `1048576` | Input | bigint 0..9223372036854775807, Default 1048576: gelesene XML-Knoten. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxModelNodes` | `bigint` | `262144` | Input | bigint 0..9223372036854775807, Default 262144: Knoten des importierten Modells. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxModelEdges` | `bigint` | `1048576` | Input | bigint 0..9223372036854775807, Default 1048576: Kanten des importierten Modells. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxComponents` | `bigint` | `4096` | Input | bigint 0..9223372036854775807, Default 4096: SSIS-Komponenten. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxPaths` | `bigint` | `8192` | Input | bigint 0..9223372036854775807, Default 8192: Datenflusskanten/Pfade. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxColumns` | `bigint` | `65536` | Input | bigint 0..9223372036854775807, Default 65536: importierte Spaltenmetadaten. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxInputs` | `bigint` | `8192` | Input | bigint 0..9223372036854775807, Default 8192: entdeckte/gebundene Eingaben. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxJsonDocumentBytes` | `bigint` | `4194304` | Input | bigint 0..9223372036854775807, Default 4194304: UTF-16-Bytes je JSON-Eingabedokument; ProjectContext behält zusätzlich das feste Kontrollprotokolllimit. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxAllJsonBytes` | `bigint` | `8388608` | Input | bigint 0..9223372036854775807, Default 8388608: Summe der UTF-16-Bytes von Bindings, CatalogBindings, LookupPolicies und StartValues, ohne ProjectContext. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxJsonNodes` | `bigint` | `131072` | Input | bigint 0..9223372036854775807, Default 131072: Knoten je begrenzt geparstem JSON-Dokument. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxExpressionBytes` | `bigint` | `4194304` | Input | bigint 0..9223372036854775807, Default 4194304: UTF-16-Bytes eines SSIS-Ausdrucks. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxExpressionTokens` | `bigint` | `262144` | Input | bigint 0..9223372036854775807, Default 262144: Tokens eines SSIS-Ausdrucks. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxExpressionNodes` | `bigint` | `131072` | Input | bigint 0..9223372036854775807, Default 131072: Knoten eines SSIS-Ausdrucks. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxPlanUnits` | `bigint` | `8192` | Input | bigint 0..9223372036854775807, Default 8192: geprüfte Debugplaneinheiten. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxCatalogObjects` | `bigint` | `4096` | Input | bigint 0..9223372036854775807, Default 4096: gebundene Katalogobjekte. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxCatalogQueries` | `bigint` | `4096` | Input | bigint 0..9223372036854775807, Default 4096: Katalogabfragen. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxParserCalls` | `bigint` | `32768` | Input | bigint 0..9223372036854775807, Default 32768: SQL-Parser-/Sicherheitsprüfaufrufe. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxArtifacts` | `bigint` | `65536` | Input | bigint 0..9223372036854775807, Default 65536: erzeugte Ergebnisartefakte. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxDiagnostics` | `bigint` | `16384` | Input | bigint 0..9223372036854775807, Default 16384: erzeugte Diagnosen. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxSqlArtifactBytes` | `bigint` | `2097152` | Input | bigint 0..9223372036854775807, Default 2097152: UTF-16-Bytes je erzeugtem SQL-Artefakt. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxTotalOutputBytes` | `bigint` | `134217728` | Input | bigint 0..9223372036854775807, Default 134217728: UTF-16-Bytes der gezählten Gesamtausgabe. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxAnalysisMilliseconds` | `bigint` | `0` | Input | bigint 0..9223372036854775807, Default 0: Millisekunden kooperatives Analysezeitbudget, keine harte Gesamtwallclock-Garantie. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@ProcedureSchema` | `nvarchar(max)` | `NULL` | Input | Bei procedure-definition Name des vorgesehenen dedizierten Zielschemas. 1 bis 128 ASCII-Zeichen. Das erste ist ein Buchstabe, danach sind Buchstaben, Ziffern und Unterstriche zulässig. Unquotierter Einzelname ohne Trim oder Normalisierung. NULL (Default) ist bei explain und bindings-template erforderlich und bei procedure-definition ungültig. |
| `@ProcedureName` | `nvarchar(max)` | `NULL` | Input | Bei procedure-definition Objektname mit exakt großem Präfix USP_ und mindestens einem Folgezeichen. Bis zu 128 ASCII-Zeichen insgesamt, zulässig sind Buchstaben, Ziffern und Unterstriche. Unquotierter Einzelname ohne Trim oder Normalisierung. NULL (Default) ist bei explain und bindings-template erforderlich und bei procedure-definition ungültig. |
| `@PackageXml` | `nvarchar(max)` | `NULL` | Input | Vollständiges DTSX-XML als Unicode-Text. Genau PackageXml oder PackageBytes übergeben; beide NULL nur für Hilfe. Die XML-Kodierungsdeklaration wird an die intern erzeugten UTF8-Bytes angepasst. Kein Pfad, keine externe XML-Auflösung; MaxPackageBytes gilt für die erzeugten Bytes. Unterstützte Paketprofile und Komponenten bleiben unverändert. |
| `@StartValues` | `nvarchar(max)` | `NULL` | Input | Optionales JSON-Objekt mit einfachen typisierten Startwerten, z.B. {"User::SourceFloor":5}. Schlüssel ist ein eindeutiger Variablen-/Parametername oder der vollständige Scope mit Backslash und Name. Unbekannte oder mehrdeutige Namen, sensitive Werte und unpassende Typen werden abgewiesen. Werte überschreiben Designdefaults und Expressions; nicht zusammen mit Bindings verwenden. NULL nutzt verfügbare nicht-sensitive Paketdefaults. Fehlende strukturrelevante Werte werden diagnostiziert. JSON unterliegt MaxJsonDocumentBytes, MaxAllJsonBytes und MaxJsonNodes. |
| `@CatalogMode` | `varchar(16)` | `N'package'` | Input | Taxativ package (Default) oder catalog. package erzeugt Debugentwürfe anhand der DTSX-Spaltenmetadaten ohne Zugriff auf Quell-Systemkataloge. Keine Prüfung realer Objektarten, Typen, RLS, Serveridentität oder Collation; IsExecutable=false und SafetyStatus=not_checked. Ordinale Namensbindung und BIN2/1252 bzw. explizite UTF8-Codepage sind gekennzeichnete Entwurfsannahmen. Mehrtabellenquellen und fehlende Metadaten benötigen Katalogabnahme. catalog verwendet die vorhandene explizite Katalogprüfung mit deren Metadatenrechten. procedure-definition verlangt catalog. Keine automatische Ausführung von Paket oder SQL und kein Fallback nach Katalogfehlern. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Name 2..116 UTF-16-Einheiten; der vollständige Artefaktsatz wird vor Zielmutation erzeugt. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255, Default 0; NULL wirkt wie 0. 0 still, 1..255 eine redigierte Abschlussmessage mit Artefakt-/SQL-Prüfeinheitenzählern. Kein zusätzliches Resultset und keine Quell-/Secretwerte; der interne ResultTable-Helper wird ausdrücklich mit Debug=0 aufgerufen. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |
<!-- API_PARAMETERS:END -->


## SSIS-Eingabetypen

`ProjectContext.projectParameters[].ssisType` verwendet folgende vollständige
Menge unterstützter Typnamen/Aliase. Typnamen werden invariant kleingeschrieben,
aber nicht getrimmt. Zahlencodes sind Strings wie `"3"`, keine JSON-Zahlen.
`values` und `designValue` enthalten Daten, niemals SQL-Ausdrücke. Die gewählte
SQL-Deklaration steht auch in `availableInputs[].sqlType`.

| `ssisType` – alle unterstützten Aliase | SQL-Abbildung und Datenform |
|---|---|
| `11`, `boolean`, `bool` | `bit`; JSON `true`/`false`, kein String `"true"` und keine Zahl `1`. |
| `16`, `sbyte`, `i1` | `smallint` mit zusätzlicher SByte-Grenze -128..127; Ganzzahl. |
| `2`, `int16`, `i2` | `smallint`; Ganzzahl -32768..32767. |
| `17`, `byte`, `ui1` | `tinyint`; Ganzzahl 0..255. |
| `18`, `uint16`, `ui2` | `int` mit zusätzlicher UInt16-Grenze 0..65535. |
| `3`, `int32`, `i4` | `int`; Ganzzahl -2147483648..2147483647. |
| `19`, `uint32`, `ui4` | `bigint` mit zusätzlicher UInt32-Grenze 0..4294967295. |
| `20`, `int64`, `i8` | `bigint`; vollständiger vorzeichenbehafteter 64-Bit-Bereich, große exakte Werte als Dezimalstring. |
| `21`, `uint64`, `ui8` | `decimal(20,0)` mit UInt64-Grenze 0..18446744073709551615; große Werte als String. |
| `4`, `single`, `r4` | `real`; endlicher numerischer Wert, auch Exponentform, keine NaN-/Infinity-Literale. |
| `5`, `double`, `r8` | `float(53)`; endlicher numerischer Wert, auch Exponentform. |
| `6`, `currency`, `cy` | `decimal(19,4)`; exakter Dezimalstring ohne Exponent, höchstens 15 Ganzzahl- und vier Nachkommastellen. |
| `14`, `decimal`, `numeric` | `decimal(p,s)` gemäß Paketmetadaten; ohne diese `decimal(38,18)`. Exakter Dezimalstring ohne Exponent; keine gerundete JSON-Zahl. |
| `8`, `string`, `wstr` | `nvarchar(n)` bei bekannter Länge 1..4000, sonst `nvarchar(max)`; JSON-String. Im Projektkontext ohne zusätzliche Längenfelder entsteht `max`. |
| `str` | `varchar(n)` bei bekannter Länge 1..8000, sonst `varchar(max)`. Der aktuelle Literalbinder besitzt dafür keinen allgemeinen Textliteralpfad; der Typname allein erlaubt keinen frei bindbaren JSON-String. |
| `7`, `datetime`, `date`, `dbtimestamp` | `datetime2(7)`; ISO-String `YYYY-MM-DDTHH:mm:ss` mit optional bis zu sieben Nachkommastellen. Der Alias `date` bezeichnet hier ebenfalls `datetime2(7)`. |
| `dbtimestamp2` | `datetime2(s)` gemäß Metadaten, s=0..7; ISO-String ohne Präzisionsverlust. |
| `dbdate` | `date`; ISO-String `YYYY-MM-DD`. |
| `dbtime` | `time(0)`; String `HH:mm:ss`. |
| `dbtime2` | `time(s)` gemäß Metadaten, s=0..7; String `HH:mm:ss` mit passenden Nachkommastellen. |
| `72`, `guid` | `uniqueidentifier`; String in Form `00000000-0000-0000-0000-000000000001`, ohne Klammern. |
| `bytes` | `varbinary(n)` bei bekannter Länge 1..8000, sonst `varbinary(max)`; String `"0x"` mit null oder mehr vollständigen Hexbytepaaren. Kein Base64. |

Numerische Eingaben verwenden die ASCII-JSON-Zahlengrammatik ohne führendes
Plus, Randspaces oder führende Nullen. Native JSON-Zahlen für exakte
Ganzzahltypen sind zusätzlich auf ±9007199254740991 beschränkt; außerhalb
davon Strings verwenden. Exakte Decimaltypen verlangen grundsätzlich Strings;
UInt64 besitzt den oben beschriebenen Sonderpfad. Datum/Zeit akzeptiert weder
`Z` noch Offsets; Nachkommastellen über der deklarierten Skala sind nur mit
abschließenden Nullen zulässig. JSON `null` erzeugt ein SQL-NULL-Literal,
berechtigt aber nicht zum Binden sensitiver oder nicht unterstützter Keys.

Die Regeln folgen dem gemeinsamen Literalbinder
[`Types.Sql`/`Types.Literal`](../Clr/PackageModel.cs), keiner allgemeinen
SQL-`CAST`-Konvertierung. Nicht unterstützte Typen bleiben nicht bindbar;
ein Typname belegt noch keinen vollständig übersetzbaren Komponentenpfad.

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#ssis).
