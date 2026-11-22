# Lokalen DTSX-Datenfluss als CTE-Kette nachvollziehen

Der Standard `@CatalogMode=N'package'` erzeugt einen lokalen SQL-Entwurf aus
dem DTSX. Die Erzeugung benötigt weder eine Verbindung zum Quellsystem noch
Zugriff auf dessen Systemkatalog. Source-/Lookup-SELECTs, Resultsetspalten,
Berechnungen und Variablen stammen aus dem Paket. Es wird dabei nichts ausgeführt.

## Aufrufen und schrittweise prüfen

```sql
DECLARE @DtsxXml nvarchar(max)=N'<hier vollständiges DTSX-XML einsetzen>';
EXEC toolbelt_tsql.USP_ExplainSsisDataFlow @PackageXml=@DtsxXml;
```

Das vollständige Skript steht in `ArtifactKind=DebugScript`. Es beginnt mit
bearbeitbaren `DECLARE`-Variablen; Kommentare nennen die zugehörigen Paketnamen.
`@StartValues` kann diese Werte schon beim Erzeugen als typisiertes JSON setzen.
Anschließend besitzt jeder übersetzte Schritt eine benannte CTE mit Kommentar
zur ursprünglichen Komponente. `StageIndex` erklärt Eltern und Spalten-Lineage.
Im abschließenden SELECT lässt sich die gewünschte CTE auswählen, um den
Zwischenstand zu betrachten. `@InspectStage=N'all'` liefert getrennte Stufenskripte.

Connection-Expressions für `ConnectionString`, `InitialCatalog` und `ServerName`
werden lokal aus auflösbaren Werten zusammengesetzt. Widersprüchliche dynamische
Angaben werden abgewiesen. Benötigt die Connection echte Laufzeitwerte, behält
der Paketentwurf die ursprünglichen SQL-Objektnamen bei und weist ausdrücklich
auf den lokalen Caller-Kontext hin. Alternativ die gewünschten Werte oder
`@CatalogBindings` vorgeben; eine fehlende Identität wird nicht als geprüft behauptet.

Wird dagegen der eigentliche SQL-Text aus einem Laufzeitwert zusammengesetzt,
muss dieser beim Erzeugen feststehen. Eine fehlende Ausführungs-GUID wird nicht
erfunden. Für ein ausdrücklich gewähltes lokales Debug-Szenario beispielsweise:

```sql
EXEC toolbelt_tsql.USP_ExplainSsisDataFlow
    @PackageXml=@DtsxXml,
    @StartValues=N'{"System::ExecutionInstanceGUID":"00000000-0000-0000-0000-000000000001","User::TagID":20260101}';
```

Die Namen müssen im konkreten Paket vorhanden sein. Mehrdeutige Namen benötigen
den vollständigen Scope. Sensitive Werte bleiben ausgeschlossen.

## Quellen und Prozeduren

SQL-Quellen verwenden den im DTSX enthaltenen SELECT. Joins und TVFs benötigen
für diesen Entwurf keine erfundenen Basistabellen-Metadaten. Die deklarierte
Ergebnisstruktur genügt für die Datenflussprojektion. Ein ausschließlich aus
konstantem Text bestehendes `EXEC('SELECT ...')` wird statisch ausgepackt und
erneut als SELECT geprüft; beliebige SQL-Batches werden dadurch nicht zugelassen.

Ist die Quelle eine Prozedur, beschreibt das Paket deren Resultset, aber nicht
den Prozedurcode. Ein vorhandenes `WITH RESULT SETS` wird für `INSERT EXEC`
entfernt, weil SQL Server diese Kombination nicht zulässt; das DTSX-Schema
bestimmt die lokale Zieltabelle. Andere EXEC-Optionen bleiben ausgeschlossen.
Das erzeugte Skript legt eine lokale `#tbx_SsisDebug_P_...`-
Tabelle mit diesem Schema an und befüllt sie durch `INSERT ... EXEC`. Erst wenn
der Benutzer dieses Skript manuell ausführt, wird die ursprüngliche Prozedur
aufgerufen. Deren Berechnungen werden nicht erfunden oder als CTE ausgegeben.

Bei einer Lookup-Prozedur wird zuerst der bisherige Datenfluss in einer
zusätzlichen lokalen Inputtabelle materialisiert. Danach folgt das Referenz-
Resultset. Die weitere CTE-Kette verwendet diese festgehaltenen Datenstände.
Die ursprünglichen Prozedurargumente bleiben erhalten; ein zusätzlicher
Tabellennamenparameter wird nicht stillschweigend erfunden. Eine Prozedur,
die eine bestimmte Caller-Tabelle erwartet, muss diesen eigenen Vertrag erfüllen.

Die Hilfstabellen sind ausschließlich lokale `#`-Tabellen, keine globalen `##`-
Tabellen. Vorhandene gleichnamige Tabellen werden nicht überschrieben. Der
generierte Ablauf entfernt selbst angelegte Tabellen nach Erfolg und im
gewöhnlichen Fehlerpfad. Keine Abnahme harter Unterbrechung oder eines
doomed Caller-Transactions daraus ableiten. Verschachteltes `INSERT EXEC`,
abweichende/mehrere Prozedurresultsets und unbekannte Prozedurseiteneffekte
werden erst beim manuellen Ausführen sichtbar; sie sind ohne Definition nicht geprüft.

## Flatfiles, Verzweigungen und Berechnungen

Auf ausdrücklichen Benutzerwunsch ist eine Flatfile-Quelle eine angenommene
Dummyzeile mit `CAST(NULL AS <DTSX-Typ>)` je Spalte. Sie liest keine Datei.
Die Quelle ist als solche kommentiert; für ein lokales Szenario können an
dieser Stelle konkrete Beispielwerte eingesetzt werden. Ein explizit
vorgegebener relationaler Flatfile-Bestand bleibt weiterhin nutzbar.

Multicast reicht den jeweiligen Eingangsstand durch. Union All ignoriert
unverbundene Reserveeingänge ohne Spalten, aber keine benötigten Mappings.
Der Conditional-Split-Defaultzweig benötigt keine eigene EvaluationOrder.
Die Vorschau zeigt NULL-Bedingungen. Ist ein Lookup auf Abbruch bei fehlendem
Treffer eingestellt, erscheint im `StageIndex` die Stufe `lookup_misses_…`
mit der Komponenten-ID des Lookups. `@InspectStage=N'all'` liefert ihren
SQL-Block als `StageSql`. Alternativ die `TargetFlowId` und `StageId` aus
dieser Zeile als `@TargetFlow` und `@InspectStage` erneut übergeben.

Der Block liefert die ursprünglichen Eingabespalten genau der Zeilen, für die
der Lookup unter den Vergleichsregeln der Vorschau keinen Treffer findet.
Er verwendet denselben Vergleich wie der Trefferpfad, einschließlich der
Längenprüfung für Full-Cache-Textschlüssel. Das Zielskript zeigt weiterhin
den Trefferpfad. Die Fehlzeilenstufe löst keinen SSIS-Paketabbruch aus.
Ohne explizite Auswahlregel bleibt die Wahl unter gleichen Referenzschlüsseln
beliebig.

Bei Full-Cache-Lookups vergleicht der Paketmodus Textschlüssel unter BIN2
einschließlich ihrer Byte-Länge. Nachgestellte Leerzeichen unterscheiden so
Schlüssel sowohl beim Zuordnen als auch beim Gruppieren von Referenzzeilen.
Die Längenprüfung ergänzt den Vergleich der bereits in den DTSX-Schlüsseltyp
konvertierten Werte. Duplikate mit identischem Schlüssel folgen der
konfigurierten Auswahlregel.

Unpivot folgt den im Paket zugeordneten PivotKey-/DestinationColumn-Werten.
Reine NULL-Gruppen werden ausgelassen; bei vollständig NULL-Eingaben bleibt
eine Vorschauzeile. Microsoft beschreibt für SSIS ebenfalls Besonderheiten
bei ausschließlich NULL-Werten; dies ist keine Behauptung vollständiger
[SSIS-Runtime-Parität](https://learn.microsoft.com/en-us/sql/integration-services/data-flow/transformations/unpivot-transformation).

DTSX-Typen steuern notwendige CASTs und Dummyspalten, ohne zusätzliche
Server-Typnachweise zu verlangen. Die Ergänzungen umfassen unter anderem
UPPER, ROUND mit konstanten Stellen, kalenderunabhängige DATEPART-Felder und
GETDATE ohne Argument. GETDATE wird erst beim manuellen SQL-Lauf ausgewertet.
`DT_I1` erzwingt auch für nicht konstante Integerwerte -128..127; eine bloße
Konvertierung nach smallint würde größere Werte fälschlich akzeptieren.

## Bedeutung der Ergebnisse

`IsComplete=1` bedeutet, dass der gewählte Datenflusspfad unter den ausgewiesenen
Annahmen vollständig übersetzt wurde. `IsExecutable` bleibt im Paketmodus
false und `SafetyStatus=not_checked`: keine Objekt-/RLS-/Rechte-/Collation-
oder SSIS-Cache-/Fehlerparität am Ziel behaupten. Originale SELECTs und
Prozeduraufrufe brauchen beim tatsächlichen Ausführen entsprechende lokale
Datenobjekte und Rechte; deren Daten stehen nicht als Zeilen im DTSX.

Ohne Datenfluss liefert ein Paket `no_dataflow` und eine Workflowinventur,
keine erfundene CTE. Nicht unterstützte oder widersprüchliche Komponenten
bleiben mit Erstursache in Diagnostic/StageIndex sichtbar.

Einzelquellen behalten die bisherigen Parsergrenzen. Für die Komposition
bereits übersetzter Fragmente gelten getrennte endliche Grenzen: höchstens
512 CTEs, 131072 Atome, 262144 Tokens, 32768 Operatoren, AST-Tiefe 256,
1048576 Walkknoten, 4194304 Walkproperties und 1024 SELECT-Projektionen; die bestehende Größen- und
übrige Ressourcenbegrenzung bleibt bestehen. Beide Parserprofile haben
getrennte Cachekeys; eine akzeptierte Komposition umgeht keine Quellprüfung.

Der optionale Modus `catalog` behält die strengere lesende Katalogabnahme
und den materialisierten Planvertrag. Historische Nachweise bleiben an ihre
ursprünglichen Artefakte gebunden. Eine erfolgreiche Offline-Erzeugung ist
kein Nachweis, dass privates Paket-SQL oder dessen Prozeduren ausgeführt wurden.
