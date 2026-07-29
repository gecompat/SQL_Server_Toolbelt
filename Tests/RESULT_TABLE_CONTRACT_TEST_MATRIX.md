# ResultTable-Contract-Testmatrix

## Status

| Feld | Wert |
|---|---|
| Spezifikation | `AP-2026-002` |
| Implementierung | `AP-2026-003` |
| Modul | `toolbelt.core.result-table` |
| Objekt | `toolbelt_core.USP_PrepareResultTable` |
| Testcode | statischer Validator, Runtime-/Lifecycle-Verträge sowie zusätzliche Collation-, 1024-Spalten-, Transaktions-, Multi-Session- und Performance-Workloads implementiert und unter Linux ausgeführt |
| Runtime-Status | `partially validated` |

Diese Matrix bleibt das verbindliche Validierungsinventar. Die erste Linux-Welle ist ausgeführt; offene Kombinationen behalten ihren eigenen Status `not executed`.

## 1. Evidenz je Ausführung

Für jede tatsächlich ausgeführte Matrixkombination sind mindestens festzuhalten:

- Test-ID;
- SQL-Server-Version und Build;
- Betriebssystem;
- Compatibility Level;
- lokaler oder zentraler Deployment-Modus;
- relevante Datenbank- und TempDB-Collations in anonymisierter oder synthetischer Form;
- Befehl oder Workflow;
- Ergebnis;
- Ausführungsdatum;
- bekannte Einschränkungen.

Reale Runtime-Ausgaben, reale Servernamen und andere schutzwürdige Informationen werden nicht in das Repository übernommen.

## 2. Grundmatrix

| Dimension | Werte |
|---|---|
| SQL Server | 2019, 2022, 2025 |
| Betriebssystem | Windows, Linux |
| Deployment | lokal, zentral |
| Zieltable | leer, mit Daten |
| Schema | passend, abweichend |
| `@KeepData` | `0`, `1` |
| Collation | case-insensitive, case-sensitive, BIN2; unterschiedliche User-DB-/Toolbelt-/TempDB-Collations |

Eine Kombination darf nur mit dokumentierter Begründung als `not applicable` ausgewiesen werden.

### Erste GitHub-hosted Validierungswelle

Die pfadbezogene Action `.github/workflows/result-table-runtime.yml` verwendet ausschließlich GitHub-hosted Linux-Runner:

- SQL Server 2019: vollständiger vorhandener Runtime-Contract sowie Deploy-, Wiederholungs-, zentrale Nutzungs-, Kollisions-, Schema-Wiederverwendungs- und Uninstall-Pfade;
- SQL Server 2022 und 2025: reduzierter Compatibility-Smoke, Deploy-Wiederholung und Uninstall;
- keine Remote- oder self-hosted Runner;
- flüchtig generiertes und maskiertes Testkennwort;
- ausschließlich synthetische Datenbank-, Objekt- und Testwerte.

Diese erste Welle ändert die deklarierte Windows-Unterstützung nicht. Windows bleibt bis zu einer tatsächlichen separaten Ausführung `not executed`. Auch ein grüner Workflow setzt den Modulstatus erst dann auf `validated`, wenn alle für den deklarierten Support verpflichtenden Matrixpunkte nachweislich abgedeckt sind.

Ausführung am 2026-07-29:

- [finaler GitHub Actions Run 30447442638](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30447442638): erfolgreich;
- SQL Server 2019 Linux: vorhandene Vollsuite erfolgreich;
- SQL Server 2022 und 2025 Linux: Kompatibilitätssuiten erfolgreich;
- statischer Vertrag: erfolgreich;
- Gesamtstatus: `partially validated`.

### Zweite GitHub-hosted Validierungswelle

Die zweite Welle erweitert denselben pfadbezogenen Linux-Workflow:

- SQL Server 2019, 2022 und 2025 führen jeweils die vollständige vorhandene
  Contract-, Lifecycle-, zentrale und Uninstall-Suite aus;
- explizite CI-, CS-, BIN2- und UTF-8-Spaltencollations;
- zentrale Installation mit unterschiedlichen Toolbelt- und
  Consumer-Datenbankcollations sowie dreiteiliger Schemaquelle;
- Umbau auf und von exakt 1024 Spalten;
- erfolgreiche Caller-Transaktion und Abbruch vor Mutation in einer
  uncommittable Transaktion;
- reproduzierbarer synthetischer Workload für No-Mutation, `TRUNCATE` und
  kleinen Schemaumbau.

Ausführung am 2026-07-29:

- [GitHub Actions Run 30456207934](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30456207934): erfolgreich;
- SQL Server 2019, 2022 und 2025 Linux: jeweils vollständige vorhandene Suite
  erfolgreich;
- explizite CI-, CS-, BIN2- und UTF-8-Spaltencollations erfolgreich;
- zentrale Installation mit unterschiedlicher Toolbelt-/Consumer-Collation
  und dreiteiliger Schemaquelle erfolgreich;
- Umbau auf und von exakt 1024 Spalten erfolgreich;
- Caller-Transaktion sowie Abbruch vor Mutation in uncommittable Transaktion
  erfolgreich;
- synthetischer No-Mutation-/`TRUNCATE`-/Schemaumbau-Workload erfolgreich;
- Gesamtstatus bleibt `partially validated`.

### Dritte GitHub-hosted Validierungswelle

Die dritte Welle ergänzt vier gleichzeitig laufende echte `sqlcmd`-Sitzungen.
Jede Sitzung verwendet identische logische Namen für ihre lokalen Temp-Tabellen,
wechselt 24-mal zwischen zwei Shapes und prüft Objektidentität, eigene
synthetische Daten sowie vollständige Isolation.

Ausführung am 2026-07-29:

- [GitHub Actions Run 30459004717](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30459004717): erfolgreich;
- statischer Vertrag sowie SQL Server 2019, 2022 und 2025 Linux: erfolgreich;
- vier parallele Sessions je SQL-Server-Version: erfolgreich;
- gleichnamige lokale ResultTable- und Helper-Tabellen blieben
  sitzungsisoliert;
- Gesamtstatus bleibt `partially validated`.

Windows, echter Savepoint-Rollback nach einem natürlichen Enginefehler und
eine plattformübergreifend vergleichbare Performance-Baseline bleiben offen.

Eine DDL-Trigger-Injektion wurde als Recovery-Harness verworfen: Der Trigger
verändert selbst die Transaktionssemantik der zu prüfenden DDL-Anweisung und
liefert deshalb keinen belastbaren Nachweis für den natürlichen
Procedure-Fehlerpfad. Ein echter Savepoint-Rollback nach einem deterministischen
Enginefehler bleibt `not executed`, bis ein nicht invasiver Fehlerpfad
reproduzierbar verfügbar ist.

## 3. Statische Vertragsprüfungen

| ID | Prüfung | Erwartung |
|---|---|---|
| `RT-S-001` | Objektname | exakt `toolbelt_core.USP_PrepareResultTable` |
| `RT-S-002` | Parameternamen | exakt `@ResultTableToAlter`, `@LikeTable`, `@KeepData`, `@Debug`, `@Hilfe` |
| `RT-S-003` | Parameterreihenfolge | entspricht der Modulspezifikation |
| `RT-S-004` | technische Defaults | `NULL`, `NULL`, `0`, `0`, `0` |
| `RT-S-005` | Datentypen | `sysname`, `nvarchar(776)`, `bit`, `tinyint`, `bit` |
| `RT-S-006` | Resultsets | kein fachliches Resultset bei `@Hilfe = 0` |
| `RT-S-007` | Help-Contract | vollständige Pflicht-Sections einschließlich deklarativem `RESULT_COLUMN`-Eintrag |
| `RT-S-008` | Error-Range | Procedure-Vertragsfehler ausschließlich `51020` bis `51029`; Lifecycle-Fehler `51030` bis `51039` |
| `RT-S-009` | dynamische Identifier | alle Identifier mit `QUOTENAME`; keine direkte Benutzereingabe in DDL |
| `RT-S-010` | Metadatenzugriff | Ziel-Temp-Table einmalig mit `OBJECT_ID`; Folgezugriffe über `object_id` |
| `RT-S-011` | Catalog Views | präzise Filter und geeignete read-only Zugriffe gemäß T-SQL-Standard |
| `RT-S-012` | Temp-Namen | keine generischen internen Namen; reservierter Präfix `#tbx_` |
| `RT-S-013` | Error Handling | `TRY/CATCH` nur an fachlichen und transaktionalen Grenzen; Fehler mit `THROW` |
| `RT-S-014` | kanonische Logik | keine zweite Schemavergleichs- oder DDL-Implementierung in Wrappern |
| `RT-S-015` | Dokumentation | Modul-, Objekt-, Help-, Lifecycle-, Limitations- und Quellenartefakte konsistent |
| `RT-S-016` | Datenschutz | keine realen Personen-, Firmen-, Infrastruktur-, Runtime- oder Secret-Daten |
| `RT-S-017` | DDL-Vertrag | kein öffentlicher `@CreateStmt`-Parameter in Version `1.0.0`; kein ungeprüftes fremdes DDL |
| `RT-S-018` | Namenssemantik | Metadatennamen werden mit dokumentierter invariant-binärer Semantik verglichen |
| `RT-S-019` | Sessionzustand | Procedure verändert keine dauerhaften Caller-SET-Optionen |
| `RT-S-020` | Ownership Marker | Schema- und Procedure-Extended-Properties sind im Install-/Upgrade-/Uninstall-Vertrag konsistent |

## 4. Help- und Parametervertrag

| ID | Test | Erwartung |
|---|---|---|
| `RT-H-001` | `EXEC ... @Hilfe = 1` ohne weitere Parameter | genau ein Help-Resultset, kein Fehler |
| `RT-H-002` | `@Hilfe = 1` mit ungültigem `@ResultTableToAlter` | Help wird ausgegeben; Zielparameter wird nicht geprüft |
| `RT-H-003` | `@Hilfe = 1` mit ungültigem `@LikeTable` | Help wird ausgegeben; Quelle wird nicht geprüft |
| `RT-H-004` | `@Hilfe = 1, @Debug = 255` | keine Debug-Message |
| `RT-H-005` | Help-Spalten | Name, Reihenfolge, Datentyp und Nullability entsprechen `USP_CONTRACT.md` |
| `RT-H-006` | Help-Sections | `DESCRIPTION`, alle `PARAMETER`, deklaratives `RESULT_COLUMN`, mindestens ein `EXAMPLE` |
| `RT-H-007` | Help-Inhalt | Parameterdatentypen, Defaults, Pflichtkennzeichnung und Fehlernummern vollständig |
| `RT-H-008` | Help-Seiteneffekte | vorhandene Zieltable bleibt strukturell und inhaltlich unverändert |

## 5. Zielnamen und Sichtbarkeit

| ID | Test | Erwartung |
|---|---|---|
| `RT-N-001` | `@ResultTableToAlter = NULL` | `51020` |
| `RT-N-002` | permanenter Tabellenname | `51020` |
| `RT-N-003` | globaler Temp-Name `##Result` | `51020` |
| `RT-N-004` | mehrteiliger Temp-Name | `51020` |
| `RT-N-005` | reservierter interner Präfix `#tbx_` in beliebiger Groß-/Kleinschreibung | `51020` |
| `RT-N-006` | Name länger als 116 Zeichen | `51020` |
| `RT-N-007` | zulässiger Name, Tabelle fehlt | `51021` |
| `RT-N-008` | zulässiger Name mit delimitierbarem Zeichen | sichere Auflösung oder dokumentierter Validierungsfehler; keine Injection |
| `RT-N-009` | gleichnamige Temp-Tabellen unterschiedlicher Sessions | jede Session verändert ausschließlich ihr eigenes Objekt |
| `RT-N-010` | verschachtelter Aufruf mit sichtbarer äußerer Temp-Tabelle | Ziel wird korrekt gefunden |

## 6. Referenztabellen

| ID | Test | Erwartung |
|---|---|---|
| `RT-L-001` | `@LikeTable = NULL` | `51022` |
| `RT-L-002` | lokale Helper-Temp-Tabelle | Schema wird gelesen |
| `RT-L-003` | zweiteilige reguläre Tabelle | Schema wird in der Installationsdatenbank gelesen |
| `RT-L-004` | dreiteilige reguläre Tabelle | Schema wird in der angegebenen Datenbank gelesen |
| `RT-L-005` | einteilige reguläre Tabelle | `51022` |
| `RT-L-006` | vierteiliger Name | `51022` |
| `RT-L-007` | View | `51023` |
| `RT-L-008` | Synonym | `51023` |
| `RT-L-009` | globale Temp-Tabelle | `51023` |
| `RT-L-010` | Quelle fehlt | `51023` |
| `RT-L-011` | fehlende Metadatensichtbarkeit | verständlicher Fehler ohne Rechteausweitung |
| `RT-L-012` | Target und LikeTable sind dasselbe lokale Temp-Objekt | `51022` vor jeder Mutation |
| `RT-L-013` | Collation-unterschiedliche Quelldatenbank | Metadaten werden ohne Collation-Conflict gelesen |
| `RT-L-014` | delimitierte Namen mit Leerzeichen, Punkt oder schließender Klammer | sicher geparst und mit `QUOTENAME` neu aufgebaut |

## 7. Unterstützte und nicht unterstützte Spaltenformen

| ID | Test | Erwartung |
|---|---|---|
| `RT-T-001` | `int`, `bigint`, `smallint`, `tinyint`, `bit` | exakte Typen |
| `RT-T-002` | `decimal(p,s)`, `numeric(p,s)`, `money`, `smallmoney` | Precision und Scale korrekt |
| `RT-T-003` | `float(n)`, `real` | Precision korrekt |
| `RT-T-004` | `date`, `time(s)`, `datetime2(s)`, `datetimeoffset(s)`, `datetime`, `smalldatetime` | Typ und Scale korrekt |
| `RT-T-005` | `char`, `varchar`, `varchar(max)` | Länge und Collation korrekt |
| `RT-T-006` | `nchar`, `nvarchar`, `nvarchar(max)` | Byte-/Zeichenlänge und Collation korrekt |
| `RT-T-007` | `binary`, `varbinary`, `varbinary(max)` | Länge korrekt |
| `RT-T-008` | `uniqueidentifier`, `sql_variant`, `xml` | exakte unterstützte Form |
| `RT-T-009` | Alias Type | Normalisierung auf zugrunde liegenden Systemtyp |
| `RT-T-010` | typisiertes XML | Normalisierung auf untypisiertes `xml` |
| `RT-T-011` | `hierarchyid`, `geometry`, `geography` | erhalten, sofern Zielversion unterstützt |
| `RT-T-012` | `rowversion`/`timestamp` als Quelle | `51024` vor Mutation |
| `RT-T-013` | Identity-Spalte als Quelle | `51024` vor Mutation |
| `RT-T-014` | computed column als Quelle | `51024` vor Mutation |
| `RT-T-015` | hidden/generated-always/column-set-Spalte | `51024` vor Mutation |
| `RT-T-016` | benutzerdefinierter CLR Type | `51024` vor Mutation |
| `RT-T-017` | gemischte `varchar`-/`nvarchar`-Spalten | keine automatische Typkonvertierung |
| `RT-T-018` | nullable und not nullable | Nullability exakt erhalten |
| `RT-T-019` | verschlüsselte Spalte | `51024` vor Mutation |
| `RT-T-020` | Legacy-LOB `text`, `ntext`, `image` | `51024` vor Mutation |
| `RT-T-021` | nicht freigegebener neuer Systemtyp, beispielsweise nativer JSON- oder Vector-Typ | `51024` bis zu einer versionierten Contract-Erweiterung |
| `RT-T-022` | Sparse-Spalte ohne Column Set | Werteshape wird kontrolliert als nicht-sparse Spalte normalisiert und dokumentiert |

## 8. Schema-Gleichheit

| ID | Abweichung | Erwartung |
|---|---|---|
| `RT-E-001` | vollständig identisch | keine DDL-Operation |
| `RT-E-002` | andere Spaltenanzahl | Schema gilt als abweichend |
| `RT-E-003` | andere Reihenfolge | Schema gilt als abweichend |
| `RT-E-004` | anderer Spaltenname | Schema gilt als abweichend |
| `RT-E-005` | anderer Datentyp | Schema gilt als abweichend |
| `RT-E-006` | andere Länge | Schema gilt als abweichend |
| `RT-E-007` | andere Precision/Scale | Schema gilt als abweichend |
| `RT-E-008` | andere Nullability | Schema gilt als abweichend |
| `RT-E-009` | andere Collation | Schema gilt als abweichend |
| `RT-E-010` | Ziel besitzt Identity/computed/rowversion | Schema gilt als nicht einfügbar und abweichend |
| `RT-E-011` | Schema passt, zusätzliche Nonclustered Indizes | Schema gilt als passend; Indizes bleiben bestehen |
| `RT-E-012` | Schema passt, Check/Unique Constraint | Schema gilt als passend; Constraint bleibt bestehen |
| `RT-E-013` | Spaltennamen unterscheiden sich nur in Case oder Akzent | invariant-binärer Vergleich erkennt die Abweichung |

## 9. `@KeepData`-Matrix

| ID | Ausgangslage | Wert | Erwartung |
|---|---|---:|---|
| `RT-K-001` | leer, Schema passt | `0` | keine Daten- oder Schemaänderung |
| `RT-K-002` | leer, Schema passt | `1` | keine Daten- oder Schemaänderung |
| `RT-K-003` | leer, Schema weicht ab | `0` | Schema wird angepasst |
| `RT-K-004` | leer, Schema weicht ab | `1` | Schema wird angepasst |
| `RT-K-005` | Daten vorhanden, Schema passt | `0` | Daten werden entfernt, Schema bleibt |
| `RT-K-006` | Daten vorhanden, Schema passt | `1` | Daten bleiben erhalten |
| `RT-K-007` | Daten vorhanden, Schema weicht ab | `0` | Daten werden entfernt, Schema wird angepasst |
| `RT-K-008` | Daten vorhanden, Schema weicht ab | `1` | `51025`, Tabelle vollständig unverändert |
| `RT-K-009` | beliebiger Dummyspaltenname/-typ, leer | `0` | vollständige Anpassung auf Referenzschema |
| `RT-K-010` | beliebiger Dummyspaltenname/-typ, Daten vorhanden | `0` | Replace-Semantik und vollständige Anpassung |
| `RT-K-011` | passendes Schema, `TRUNCATE` zulässig | `0` | `TRUNCATE` darf verwendet und bei Debug ausgewiesen werden |
| `RT-K-012` | passendes Schema, `TRUNCATE` schlägt unerwartet fehl | `0` | kein `DELETE`-Fallback; eigene Mutation zurückrollen und ursprünglichen Engine-Fehler weitergeben |

## 10. Indizes, Constraints und Dependencies

| ID | Ausgangslage | Erwartung |
|---|---|---|
| `RT-D-001` | passendes Schema mit Nonclustered Index | kein Drop; Procedure erfolgreich |
| `RT-D-002` | passendes Schema mit Unique Index, spätere Duplikate | Vorbereitung erfolgreich; fachlicher Insert erhält tatsächlichen Unique-Fehler |
| `RT-D-003` | abweichendes Schema mit Index auf alter Spalte | `51026`, keine Mutation |
| `RT-D-004` | abweichendes Schema mit Primary Key | `51026`, keine Mutation |
| `RT-D-005` | abweichendes Schema mit Unique Constraint | `51026`, keine Mutation |
| `RT-D-006` | abweichendes Schema mit Check Constraint | `51026`, keine Mutation |
| `RT-D-007` | abweichendes Schema mit Default Constraint | `51026`, keine Mutation |
| `RT-D-008` | abweichendes Schema mit computed column | `51026`, keine Mutation |
| `RT-D-009` | abweichendes Schema mit DML-Trigger | `51026`, keine Mutation |
| `RT-D-010` | abweichendes Schema mit user-created statistics | `51026`, keine Mutation |
| `RT-D-011` | mehrere Blocker | Fehlermeldung nennt mindestens ersten Blocker und notwendige Änderung; keine Mutation |

## 11. DDL und Spaltenreihenfolge

| ID | Test | Erwartung |
|---|---|---|
| `RT-A-001` | Ein-Spalten-Dummy auf Mehrspalten-Schema | Zielspalten exakt in Referenzreihenfolge |
| `RT-A-002` | Mehrspalten-Dummy auf Ein-Spalten-Schema | nur Zielspalte verbleibt |
| `RT-A-003` | vollständig andere Namen und Typen | exaktes Zielschema |
| `RT-A-004` | Anchor-Namenskollision durch vorhandene Spalte | Invocation-spezifischer alternativer Anchor-Name |
| `RT-A-005` | DDL-Fehler nach begonnener Mutation | vollständiges Rollback auf Ausgangszustand, soweit Transaktion committable |
| `RT-A-006` | Zieltable bleibt nach erfolgreicher Procedure im Aufrufer-Scope sichtbar | `SELECT` auf Zieltable funktioniert |
| `RT-A-007` | Zieltable wird nicht gedroppt/recreated | Objektidentität bleibt innerhalb des Aufrufs erhalten |
| `RT-A-008` | Quell- oder Zieltable besitzt 1024 Spalten | geteilter Anchor-Umbau überschreitet zu keinem Zeitpunkt das SQL-Server-Spaltenlimit |

## 12. Transaktionen und Fehler

| ID | Test | Erwartung |
|---|---|---|
| `RT-X-001` | kein Caller-Transaction, erfolgreiche Mutation | eigene Transaktion committed |
| `RT-X-002` | kein Caller-Transaction, DDL-Fehler | eigene Transaktion vollständig gerollbackt |
| `RT-X-003` | bestehende committable Transaktion, Erfolg | Caller-Transaktion bleibt offen; nur Savepoint verwendet |
| `RT-X-004` | bestehende committable Transaktion, Fehler | Rollback zum Savepoint; frühere Caller-Änderungen bleiben erhalten |
| `RT-X-005` | bestehende uncommittable Transaktion | `51028` oder Originalfehler; kein fälschlicher Commit/Rollback der Caller-Transaktion |
| `RT-X-006` | Validierungsfehler vor Mutation | `@@TRANCOUNT` und Tabellenzustand unverändert |
| `RT-X-007` | Engine-Fehler | ursprüngliche Fehlernummer/-meldung bleibt erkennbar |
| `RT-X-008` | Caller-SET-Optionen vor/nach Aufruf | keine dauerhafte Veränderung durch die Procedure |
| `RT-X-009` | rekursive/nested Mutationen mit Savepoints | Invocation-spezifische Savepoint-Namen kollidieren nicht |

## 13. Debug und Datenschutz

| ID | Test | Erwartung |
|---|---|---|
| `RT-G-001` | `@Debug = 0` | keine Debug-Message |
| `RT-G-002` | `@Debug = 1` | nur Hauptschritte |
| `RT-G-003` | `@Debug = 2` | Entscheidungen, Objekt-IDs, Zeilenzahl und Schemaentscheidung |
| `RT-G-004` | `@Debug = 3` | normalisierte Metadaten und generiertes DDL als Messages |
| `RT-G-005` | `@Debug = 255` | maximaler Trace, weiterhin kein zusätzliches Resultset |
| `RT-G-006` | vertrauliche synthetische Parameterwerte | dürfen diagnostisch erscheinen |
| `RT-G-007` | als Secret klassifizierter synthetischer Wert | wird nicht aktiv wiederholt |
| `RT-G-008` | Debug in Help-Modus | keine Debug-Message |
| `RT-G-009` | `@Debug = 4` und `254` | jeweils mindestens derselbe Detailumfang wie Stufe `3` |

## 14. Verschachtelung und Rekursion

| ID | Test | Erwartung |
|---|---|---|
| `RT-R-001` | Parent-USP erzeugt Zieltable, Child-USP bereitet und befüllt sie | Ergebnis im Parent weiterverarbeitbar |
| `RT-R-002` | drei verschachtelte USP-Ebenen | kein `INSERT ... EXEC`; alle Zieltabellen korrekt |
| `RT-R-003` | rekursiver Aufruf derselben fachlichen USP | Schema-Helper wird bei passendem Shape wiederverwendet; nur Erzeuger droppt |
| `RT-R-004` | verschiedene USPs mit eigenen Helper-Namen | keine logische Temp-Table-Kollision |
| `RT-R-005` | zwei Sessions mit gleichen logischen Namen | vollständige Isolation |
| `RT-R-006` | parallele MARS-Manipulation derselben Zieltable | ausdrücklich `unsupported`; Test dokumentiert die Grenze, kein Erfolg versprochen |
| `RT-R-007` | vorhandene routinenspezifische Helper-Tabelle mit falschem Shape | keine stille Wiederverwendung; verständlicher Fehler vor ResultTable-Mutation |

## 15. Deployment und Plattform

| ID | Test | Erwartung |
|---|---|---|
| `RT-P-001` | lokale Installation, lokale Helper- und Zieltable | erfolgreich |
| `RT-P-002` | zentrale Installation, Helper- und Zieltable in konsumierender Session | erfolgreich über dreiteiligen Procedure-Aufruf |
| `RT-P-003` | zentrale Installation, dreiteilige reguläre `@LikeTable` | erfolgreich bei ausreichender Metadatensichtbarkeit |
| `RT-P-004` | zentrale Installation ohne Synonym | vollständig funktionsfähig |
| `RT-P-005` | SQL Server 2019 Windows | ausführen |
| `RT-P-006` | SQL Server 2022 Windows | ausführen |
| `RT-P-007` | SQL Server 2025 Windows | ausführen |
| `RT-P-008` | SQL Server 2019 Linux | ausführen, sofern Runner vorhanden |
| `RT-P-009` | SQL Server 2022 Linux | ausführen, sofern Runner vorhanden |
| `RT-P-010` | SQL Server 2025 Linux | ausführen, sofern Runner vorhanden |

## 16. Lifecycle

| ID | Test | Erwartung |
|---|---|---|
| `RT-C-001` | Erstdeployment | Schema/Procedure/Release- und Objektmarker vollständig |
| `RT-C-002` | Wiederholung derselben Version | alle Framework-Objekte erneut deployed; kein Teilzustand |
| `RT-C-003` | vorhandenes unmarkiertes `toolbelt_core`-Schema ohne Zielnamenskollision | Schema kontrolliert wiederverwenden und nicht adoptieren |
| `RT-C-004` | Deployment von bekannter Vorgängerversion | Release-Manifest, Procedure und Extended Properties konsistent |
| `RT-C-005` | Deployment von unbekannter Version | Abbruch vor Mutation |
| `RT-C-006` | Uninstall ohne Dependents | Procedure entfernt; fremde Objekte bleiben |
| `RT-C-007` | Uninstall bei same-database Dependency | Abbruch oder explizite Bestätigung gemäß Lifecycle-Vertrag |
| `RT-C-008` | zentraler Uninstall ohne Bestätigung externer Konsumenten | Abbruch |
| `RT-C-009` | Schema nach Uninstall nicht leer | Schema bleibt erhalten |
| `RT-C-010` | Schema leer und als Toolbelt verwaltet | Schema darf kontrolliert entfernt werden |
| `RT-C-011` | Schema-Extended-Properties | neu angelegtes Schema wird markiert; bestehendes unmarkiertes Schema bleibt unmarkiert |
| `RT-C-012` | Procedure-Extended-Properties | ModuleId, ModuleVersion, ContractVersion und DeploymentMode korrekt gesetzt |
| `RT-C-013` | Source-Hash nach Deploy | gespeicherter Hash entspricht zunächst dem Objekttext und bleibt rein diagnostisch |
| `RT-C-014` | lokal veränderte Framework-Procedure | erneutes Deploy überschreibt sie mit der Release-Source |
| `RT-C-015` | Zielrelease enthält neuen Namen mit vorhandener frameworkfremder Kollision | Abbruch im Preflight vor jeder Mutation |
| `RT-C-016` | bekanntes Vorgängerrelease enthält ein im Ziel weggefallenes Objekt | ausschließlich dieses manifestierte Framework-Objekt entfernen |
| `RT-C-017` | Fehler während Lifecycle-Transaktion | vollständiger Rollback ohne halben Installationsstand |
| `RT-C-018` | paralleles Deploy oder Uninstall desselben Moduls | Application Lock verhindert überlappende Mutation |

## 17. Performance-Messungen

Performance-Ergebnisse sind empirisch und je Plattform getrennt zu dokumentieren.

Mindestens vergleichen:

- passendes Schema ohne DDL;
- Replace nur durch Datenentfernung;
- kleiner Schemaumbau;
- breites Schema mit vielen Spalten;
- Metadatenzugriff bei lokaler und zentraler Installation;
- Auswirkungen vorhandener nicht blockierender Indizes bei passendem Schema.

Metriken:

- CPU;
- Duration;
- logical reads;
- TempDB writes;
- Compile-Anteil;
- Anzahl erzeugter DDL-Statements.

Ein Einzellauf ist kein allgemeingültiger Benchmark.
