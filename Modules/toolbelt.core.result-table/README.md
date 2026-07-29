# Result Table Infrastructure

## Status

| Feld | Wert |
|---|---|
| Modul-ID | `toolbelt.core.result-table` |
| Version | `1.0.0` |
| Implementierung | `implemented` |
| Runtime-Validierung | `not executed` |
| Persistente Objekte | genau `toolbelt_core.USP_PrepareResultTable` |

Die Procedure und alle gekoppelten Source-, Lifecycle-, Dokumentations- und Testartefakte sind implementiert. Der Status `implemented` ist kein Runtime-Nachweis. SQL Server 2019, 2022 und 2025 sowie Windows/Linux und lokale/zentrale Installation bleiben bis zur tatsächlichen Ausführung der Matrix getrennt `not executed`.

## Zweck

Eine Toolbelt-USP kann ihr bekanntes tabellarisches Resultset in eine bereits vom Aufrufer erstellte lokale Temp-Tabelle schreiben. `USP_PrepareResultTable` prüft die Zieltabelle und passt deren Spaltenschema anhand einer vorhandenen Referenztabelle an. Die Procedure schreibt selbst keine fachlichen Resultzeilen.

Die kanonische Spezifikation bleibt [RESULT_TABLE_MODULE_DESIGN.md](../../Documentation/Architecture/RESULT_TABLE_MODULE_DESIGN.md). Der allgemeine USP-Vertrag steht in [USP_CONTRACT.md](../../Documentation/Standards/USP_CONTRACT.md).

## Artefakte

| Pfad | Rolle |
|---|---|
| `Source/USP_PrepareResultTable.sql` | kanonische Procedure-Source |
| `Deployment/Install.sql` | Erstinstallation und kontrollierte Wiederholung |
| `Deployment/Upgrade.sql` | Upgrade-Gate; Version `1.0.0` besitzt noch keinen älteren unterstützten Vorgänger |
| `Deployment/Uninstall.sql` | Dependency-geschützte Entfernung |
| `Documentation/USP_PrepareResultTable.md` | öffentlicher Objektvertrag |
| `Examples/PrepareResultTable.sql` | synthetisches Verwendungsbeispiel |
| `Tests/Static/validate_contract.py` | reproduzierbare statische Vertragsprüfung |
| `Tests/Runtime/USP_PrepareResultTable.Contract.sql` | synthetische Runtime-Contract-Tests |
| `Tests/Runtime/Lifecycle.Contract.sql` | Lifecycle-Prüfungen nach Installation |

## Deployment

Die Lifecycle-Skripte verwenden SQLCMD-Kommandos und binden die kanonische Source mit `:r` ein. Dadurch existiert die Procedure-Implementierung im Repository nur einmal.

Aus dem Verzeichnis `Modules/toolbelt.core.result-table/Deployment`:

```text
sqlcmd -S <server> -d <database> -E -b -i Install.sql -v DeploymentMode=local
```

Zentrale Installation:

```text
sqlcmd -S <server> -d <toolbelt-database> -E -b -i Install.sql -v DeploymentMode=central
```

Deinstallation einer zentralen Installation erfordert die ausdrückliche Betreiberbestätigung:

```text
sqlcmd -S <server> -d <toolbelt-database> -E -b -i Uninstall.sql -v ConfirmNoExternalConsumers=1
```

Die Platzhalter sind absichtlich generisch. Keine Credentials oder realen Infrastrukturwerte werden im Repository gespeichert.

## Wesentliche Grenzen

- Ziel ist ausschließlich eine bereits sichtbare lokale Temp-Tabelle.
- Schemaquelle ist eine lokale Temp-Tabelle oder eine zwei-/dreiteilig benannte reguläre Tabelle.
- Views, Synonyme, Linked Server, permanente Ziele und globale Temp-Tabellen sind nicht unterstützt.
- Ein Schemaumbau entfernt keine Dependencies automatisch.
- Gleichzeitige DDL-Manipulation derselben Zieltable ist nicht unterstützt.
- Frei geliefertes `CREATE TABLE`-DDL wird nicht ausgeführt.

## Quellen

- Microsoft (2026): [CREATE TABLE](https://learn.microsoft.com/en-us/sql/t-sql/statements/create-table-transact-sql?view=sql-server-ver17).
- Microsoft (2026): [sys.columns](https://learn.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-columns-transact-sql?view=sql-server-ver17).
- Microsoft (2026): [sys.types](https://learn.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-types-transact-sql?view=sql-server-ver17).
- Microsoft (2026): [SAVE TRANSACTION](https://learn.microsoft.com/en-us/sql/t-sql/language-elements/save-transaction-transact-sql?view=sql-server-ver17).
