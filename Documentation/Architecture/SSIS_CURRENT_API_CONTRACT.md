# Aktueller SSIS-Debug-Vertrag

Stand: 2026-10-29. Vom Benutzer direkt beauftragt und umgesetzt. Die getrennten
aktuellen Binary-, Paket- und Installer-Nachweise stehen in der
[Prüfmatrix](../../Modules/toolbelt.tsql.ssis-debug/Tests/README.md).
Head-/Main-CI und Integration bleiben eigene Gates. Unveröffentlicht.

Dieser Vertrag ersetzt die Toolbelt-V1-Kompatibilitäts- und Opt-in-Klauseln des
[bisherigen Komponentenvertrags](SSIS_COMPONENTS_V2_CONTRACT.md). Dessen fachliche
Komponenten-, Typ-, SQL-Sicherheits- und Bereinigungsverträge gelten weiter.
Die projektweite Entwicklungsregel steht in
[PROJECT_RULES.md](../../.ai/PROJECT_RULES.md#entwicklungsverträge-ohne-legacy-zwang).

## Zweck und öffentlicher Ablauf

`USP_ExplainSsisDataFlow @PackageBytes = @b` verwendet unmittelbar den aktuellen
Komponentenumfang einschließlich Row Count, Flatfile-Metadaten, typisierter
Ausdrücke und langer Pläne. Kein V1-Profil und kein V2-Opt-in sind erforderlich.
Die normale Operation bleibt `explain`; `bindings-template` liefert die aktuelle
editierbare Parameter-Vorlage. Ein `-v2`-Alias wird nicht zur Kompatibilität
mitgeführt. Die ausdrücklich unterstützten DTSX-Paketformate bleiben erhalten.

Die Vorlage enthält Paket-/Kontextbindung, das vollständige Eingabeverzeichnis
und editierbare `values`. Paketparameter, Variablen und bereitgestellte
Projektparameter werden typisiert entdeckt. Vorhandene nicht sensitive Defaults
werden als Designwerte vorbelegt; bekannte Laufzeitzuweisungen und deren Herkunft
bleiben sichtbar. Ein Designwert wird nicht als tatsächlich beobachteter
Laufzeitwert ausgegeben. Sensitive Werte werden nicht automatisch übernommen.
Der Benutzer übergibt die bearbeitete Vorlage als `@Bindings` zurück. Weitere
Datenbank-/Quellzuordnungen bleiben fachliche Kontextdaten, keine Limitoptionen.

## Ressourcen über SQL-Parameter

Konfigurierbare Ressourcen werden ausschließlich durch benannte `bigint`-
SQL-Parameter vor dem bestehenden Common-Tail bereitgestellt. Je Parameter gilt:
positiv = Obergrenze, `0` = für diesen konfigurierbaren Zähler unbegrenzt,
negativ oder `NULL` = verständlicher Parameterfehler. Die Standardwerte sind die
bisherigen großen Komponentenbudgets; die Analysezeit ist standardmäßig offen,
damit eine vollständige Analyse nicht am alten 30-Sekunden-Entwicklungsprofil
abbricht. Caller-/Test-Timeouts und Abbruchmöglichkeiten bleiben wirksam.

| Parameter | Einheit | Default |
|---|---|---:|
| `@MaxPackageBytes` | Bytes | 134217728 |
| `@MaxXmlCharacters` | Zeichen | 134217728 |
| `@MaxXmlNodes` | Knoten | 1048576 |
| `@MaxModelNodes` | Knoten | 262144 |
| `@MaxModelEdges` | Kanten | 1048576 |
| `@MaxComponents` | Komponenten | 4096 |
| `@MaxPaths` | Pfade | 8192 |
| `@MaxColumns` | Spaltenmetadaten | 65536 |
| `@MaxInputs` | Eingaben | 8192 |
| `@MaxJsonDocumentBytes` | UTF-16-Bytes je Datendokument | 4194304 |
| `@MaxAllJsonBytes` | UTF-16-Bytes der Datendokumente | 8388608 |
| `@MaxJsonNodes` | Knoten | 131072 |
| `@MaxExpressionBytes` | UTF-16-Bytes | 4194304 |
| `@MaxExpressionTokens` | Tokens | 262144 |
| `@MaxExpressionNodes` | Knoten | 131072 |
| `@MaxPlanUnits` | Einheiten | 8192 |
| `@MaxCatalogObjects` | Objekte | 4096 |
| `@MaxCatalogQueries` | Abfragen | 4096 |
| `@MaxParserCalls` | Parseraufrufe | 32768 |
| `@MaxArtifacts` | Ergebnisartefakte | 65536 |
| `@MaxDiagnostics` | Diagnosen | 16384 |
| `@MaxSqlArtifactBytes` | UTF-16-Bytes je SQL-Artefakt | 2097152 |
| `@MaxTotalOutputBytes` | UTF-16-Bytes der Gesamtausgabe | 134217728 |
| `@MaxAnalysisMilliseconds` | Millisekunden | 0 |

`resourceOptions` im Eingabekontext wird mit Hinweis auf die SQL-Parameter
abgewiesen. Das editierbare Parameter-JSON enthält keine Ressourcensteuerung.
Feststehende SQL-Parser-/AST-, Tiefen-, Protokoll-, Rechte- und Ownershipgrenzen
werden nicht durch `0` aufgehoben. Ressourcenmetadaten dürfen als ausschließlich
lesbare Ergebnisdetails ausgegeben werden.

## Vollständiger Pfad, Zuweisungen und Debug-SQL

Alle Paketpfade und Vorgängerbeziehungen werden auch bei blockierter Übersetzung
ausgewiesen. Eine Kaskadenmeldung nennt die ursprüngliche blockierende Stufe,
die konkrete Ursache und die benötigte Eingabe; sie ersetzt die Erstursache
nicht durch eine bloße weitere Stufennummer.

Laufzeitzuweisungen werden an nachweisbare Variablen, deren Scope und ihre
Zuweisungsstellen gebunden. Die Existenz irgendeines Script-, Schleifen- oder
ExecuteSQL-Tasks markiert nicht pauschal alle Variablen als verändert. Unbekannte
Schreibeffekte werden ausdrücklich als unbekannt bezeichnet. Relevante Defaults,
Ausdrücke und vom Benutzer gesetzte Debugwerte bleiben unterscheidbar.

Ein direkt auffindbares `DebugScript`-Artefakt bietet pro vollständig auflösbarem
Ziel den gesamten benötigten Vorbereitungs-/Plan-/Projektions-/Bereinigungsablauf.
Die vorhandenen Einzeleinheiten und ihre Sicherheitsprüfungen bleiben erhalten.
Ein SSMS-Script darf die erforderlichen Batches mit `GO` trennen; es behauptet
keine globale Atomarität. Die reine T-SQL-Installerdatei benötigt weiterhin kein
`GO`, keine SQLCMD-Direktiven und keine externen Dateien zur Ausführung.

Fehlt echter Laufzeitkontext, bleibt der gesamte Strukturpfad sichtbar. Die
Ausgabe nennt die fehlenden Werte und zeigt verfügbare vollständige Teilpläne;
unbekannter Command-Text wird nicht erfunden und unvollständiger SQL-Code nicht
als ausführbar bezeichnet. Ein optionales diagnostisches Script ist dann klar
unvollständig und nicht ausführbar. Kein Script-/SSIS-Task wird zur Analyse
ausgeführt; keine zusätzlichen Datei-, Netzwerk-, Katalog- oder Serverrechte.

## Abnahme und Lieferungen

Hilfe und Beispiele zeigen unmittelbar den Standardaufruf, das Erzeugen und
Zurückgeben der Parameter-Vorlage sowie benannte Limits. Tests prüfen Typen,
Defaults, den Common-Tail, alle Parameterfehler, `0`, explizite Grenzfälle,
Default-/Zuweisungsherkunft, Erstursachen und vollständige Debug-Batchreihenfolge.
Private Referenzpakete werden nur privat offline analysiert; öffentliche
Reproduktionen sind synthetisch. Neue DLL-/Paket-/Installerbytes erhalten eigene
Nachweise. Historische Ausführungen werden nicht umgedeutet. Aktuelle Head- und
Main-CI sind eigene Gates. Keine Veröffentlichung oder Tags.
