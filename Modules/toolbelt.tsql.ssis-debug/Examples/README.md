# Vollständiges SSMS-Beispiel

[`SsmsDebugWalkthrough.sql`](SsmsDebugWalkthrough.sql) demonstriert den gesamten
Debug-Ablauf mit der vorhandenen synthetischen
[`synthetic-8.dtsx`](../Tests/Fixtures/synthetic-8.dtsx). Das Paket verbindet
zwei Sources über Union All, berechnet `Adjusted`, ergänzt einen Lookup und
verteilt die Zeilen über Conditional Split auf High und Default. Die Fixture
bleibt im Testverzeichnis die gemeinsame Quelle für Beispiel und Tests.

Die [Installationsanleitung mit SQL- und PowerShell-Skripten](Installation/README.md)
zeigt die Voraussetzungen einschließlich Parser, ResultTable und Assembly-Trust.

## Aktuelle API-Parameter

Der aktuelle Entwicklungsvertrag verwendet `bindings-template` direkt und
akzeptiert Limits als benannte SQL-Parameter. Die bestehende
`SsmsDebugWalkthrough.sql`-Datei und die historischen Installationspakete sind
an ältere Builds gebunden; sie qualifizieren diese neue Signatur nicht. Mit
einem Build des aktuellen Vertrags sehen die Aufrufe so aus:

```sql
-- Vorlage erzeugen; die zurückgegebenen values bearbeiten.
EXEC toolbelt_tsql.USP_ExplainSsisDataFlow
    @PackageBytes = @PackageBytes,
    @Operation = 'bindings-template';

-- Dieselbe Vorlage zurückgeben; 0 hebt nur dieses konfigurierbare Limit auf.
EXEC toolbelt_tsql.USP_ExplainSsisDataFlow
    @PackageBytes = @PackageBytes,
    @Bindings = @Bindings,
    @MaxExpressionBytes = 0;
```

Andere Limits werden mit den jeweiligen `@Max...`-Parametern gesetzt.
Ressourcenoptionen gehören nicht in `@ProjectContext` oder `@Bindings`.

## Voraussetzungen und Start

1. Eine eigene Testdatenbank `ContosoSsisDebug` auf Windows SQL Server
   2019, 2022 oder 2025 verwenden. SSIS-Debug 1.0.0, Parser 2.0.1 und Result
   Table müssen dort installiert sein. Bei einem anderen Datenbanknamen die
   `USE`-Zeile des Beispiels anpassen; das Katalogmapping übernimmt `DB_NAME()`.
2. `synthetic-8.dtsx` unverändert nach `C:\Contoso\synthetic-8.dtsx` auf den
   SQL-Server-Rechner kopieren oder den BULK-Dateipfad im Script anpassen.
   `OPENROWSET(..., SINGLE_BLOB)` liest serverseitig. Die erforderlichen
   Datei-/BULK-Leserechte müssen bereits vorhanden sein; der CLR-Provider
   selbst erhält ausschließlich die ursprünglichen Paketbytes.
3. Vorhandene EXECUTE-/Metadatenrechte für die Analyse und SELECT auf die
   Demotabellen für die späteren Prüfblöcke verwenden. Ohne offene Transaktion
   und mit `IMPLICIT_TRANSACTIONS OFF` arbeiten.
4. Die nummerierten Abschnitte im selben SSMS-Abfragefenster nacheinander
   ausführen. Abschnitt 0 legt drei eigene `dbo.Synthetic*`-Tabellen mit
   synthetischen Zeilen an und weist vorhandene Namensbelegungen zurück.
   Diesen Setupabschnitt nur einmal ausführen; spätere Arbeitsschritte lassen
   sich getrennt wiederholen. Das Beispiel verwaltet keine Datenbank, Rechte,
   Serveroptionen oder Assembly-Trusteinträge.

## Ablauf

| Abschnitt | Ergebnis |
|---|---|
| 0 | Eigene Demotabellen und reproduzierbare Quelldaten |
| 1 | DTSX-Originalbytes sowie explizites Same-instance-Connectionmapping in einer sitzungslokalen Temp-Tabelle |
| 2 | `bindings-template`, vollständiges JSON und Eingabeverzeichnis mit Schlüssel, Name, Scope und Typ |
| 3 | Nur `User::Threshold` im Scope `Package` per `JSON_MODIFY` von 100 auf die JSON-Zahl 150 ändern |
| 4 | Vollständiges JSON an `explain` zurückgeben; mit `@InspectStage='all'` Stufenverzeichnis und alle unterstützten Prüfblöcke erzeugen |
| 5 | High-Ziel und Derived-Stufe aus dem Verzeichnis bestimmen und gezielt über `@TargetFlow`/`@InspectStage` erneut anfordern |
| 6 | Ausführbare `StageSql`-/`TargetSql`-Blöcke zur manuellen Ausführung anzeigen |
| 7 | Passende `CleanupSql`-Blöcke anzeigen; optionale Demodatenbereinigung bleibt auskommentiert |

Nur `values` im vollständig zurückgegebenen JSON bearbeiten. Hashes und
`availableInputs` erhalten ihre Paket-/Kontextbindung. Die Demo ermittelt den
Werteschlüssel über Name und Scope; gleiche Variablennamen in unterschiedlichen
Containern sind damit unterscheidbar. Die `DECLARE`s eines Prüfblocks umfassen
nur die dort tatsächlich benötigten Eingaben.

## Stufen und direkte DECLARE-Änderung

Den vollständigen `Content` einer ausführbaren `StageSql`- oder `TargetSql`-Zeile
direkt in dasselbe SSMS-Abfragefenster kopieren, vollständig markieren und
ausführen. SSMS muss den gesamten Zelleninhalt übertragen; die Ausgabe enthält
zusätzlich `SqlBytes` zur Längenkontrolle. `PRINT` ist für lange SQL-Inhalte
ungeeignet. Alle DECLAREs, Guards, Cachevorbereitungen, Vorgänger-CTEs und der
abschließende SELECT gehören zum Block. `PreparationSql` muss nicht vorher
gesondert ausgeführt werden.

Vor der erzeugenden Abfrage in deren `Query Options > Results > Grid` die
Option `Retain CR/LF on copy or save` aktivieren und unter `Maximum Characters
Retrieved > Non XML data` einen ausreichend großen Wert wählen. In SSMS22
ist hier `2000000` einstellbar. Die im Test beobachtete Einstellung von
`65535` Zeichen schnitt längere Zellen ab; ohne CR/LF-Erhalt werden außerdem
SQL-Kommentare und Batchzeilen zusammengezogen. Nach einer Optionsänderung die
erzeugende Abfrage erneut ausführen und ausschließlich deren neue Zelle
kopieren. Reicht die maximal einstellbare Grenze für den Inhalt nicht aus,
diese Gridkopie nicht ausführen. Eine sichtbare letzte Zeile allein beweist
keinen vollständigen Transport; Länge und Hash müssen zum aktuellen Artefakt
passen. Die [SQL-freie Kopierprüfung der Qualifikationsmethode](../Tests/WindowsClientRecovery/README.md#kopierprüfung-vor-der-ausführung)
erläutert die strikte UTF16/LF-Prüfung.

Die `GO`-Trennungen im Beispiel liegen zwischen dessen Steuerabschnitten.
Innerhalb eines generierten Prüfblocks kein `GO` ergänzen. Eine CTE gilt nur
für das unmittelbar folgende Statement. Für einen anderen Prüfpunkt den
vollständigen zugehörigen `StageSql`-Block wählen. Alternativ lässt sich dessen
letzter SELECT auf eine enthaltene Vorgänger-CTE umstellen; interne Spaltennamen
werden in `StageIndex.DetailsJson` und `ColumnLineage` zugeordnet.

Im High-TargetSql der unveränderten Demo steht `DECLARE @v0004 int = 150;`.
Diesen Initialwert auf `80` ändern und den vollständigen Block erneut ausführen.
Dafür sind kein neuer Generatoraufruf und keine JSON-Änderung erforderlich.

| Prüfpunkt bei SourceFloor=0 und Offset=1 | Erwartete Zeilen |
|---|---:|
| SourceA / SourceB | 3 / 2 |
| Union / Derived / Lookup | jeweils 5 |
| High / Default mit Threshold=150 | 1 / 4 |
| High / Default mit Threshold=80 | 3 / 2 |

Die berechneten `Adjusted`-Werte sind 101, 21, 201, 81 und 31; die Reihenfolge
der Ergebnisausgabe ist ohne ORDER BY nicht festgelegt. Die explizite
Lookup-Policy wählt für `(KeyA,KeyB)=(1,10)` den höheren Score 9.

Lookupauswahlen bleiben in derselben Sitzung festgehalten. Eine reine Änderung
der Split-Schwelle lädt den unabhängigen Lookup nicht neu. Für einen frischen
Lookupstand das passende ausgegebene `CleanupSql` ausführen; danach initialisiert
der nächste Prüfblock den Cache erneut. Unterstützte Lesereferenzen verwenden
`WITH (NOLOCK)`: unbestätigte, fehlende oder doppelt gelesene Zeilen sind möglich,
Schemasperren bleiben möglich.

## Eigenes Paket verwenden

Dateipfad und Connection-IDs im Katalogmapping sowie Variablen-/Stufenauswahl
an das eigene Paket anpassen. Nur ausdrücklich erlaubte Datenbanken derselben
Instanz zuordnen. Benötigte Projektparameter und Projektconnections über
denselben `@ProjectContext` sowohl beim Vorlagen- als auch beim Analyseaufruf
übergeben; Credentials und Connection Strings gehören nicht in die JSONs.

Der [öffentliche Aufrufvertrag](../Documentation/USP_ExplainSsisDataFlow.md) und
der [aktuelle API-Vertrag](../../../Documentation/Architecture/SSIS_CURRENT_API_CONTRACT.md)
begrenzen die unterstützten Komponenten und Ausdrücke. Die Analyse führt kein
Paket und keine Quellabfrage aus; erst die manuell gestarteten Prüfblöcke lesen
die Daten. Das Beispiel ist keine SSIS-Laufzeitausführung.
