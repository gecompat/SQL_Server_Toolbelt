# SSIS-Debug installieren und verwenden

## Heutige Neuinstallation

SSIS-Debug benötigt SQL Server auf Windows und aktiviertes CLR. Wähle beim
[gemeinsamen Installer](../../../INSTALL.md) Windows lokal oder Windows
zentral. Für eine Installation nur der DTSX-Funktion eignet sich die
[einzelne SQL-Datei mit ihren Abhängigkeiten](SimpleInstallation.md).
Der Installer ergänzt fehlende Objekte. Bei bereits installierten früheren
Definitionen gilt der beschriebene [Wechsel auf einen neuen Stand](../../../INSTALL.md#auf-einen-neuen-stand-wechseln).

## Einen Datenfluss ansehen

Das vollständige DTSX-XML als `nvarchar(max)` binden oder die Originalbytes
als `@PackageBytes` übergeben. Verwende jeweils genau eine der beiden Formen.

```sql
DECLARE @DtsxXml nvarchar(max) = N'<vollständiges DTSX-XML>';
EXEC toolbelt_tsql.USP_ExplainSsisDataFlow @PackageXml = @DtsxXml;
```

Als T-SQL-Literal müssen einfache Anführungszeichen im XML verdoppelt werden.
Für Anwendungen eignet sich ein gebundener Parameter. Die Prozedur erzeugt
SQL. Sie öffnet keine DTSX-Datei und führt weder das Paket noch das Debug-SQL
aus. Der Standard `@CatalogMode=N'package'` liest die Informationen aus dem
Paket. Für eine ausdrücklich kataloggebundene Prüfung verwende
`@CatalogMode=N'catalog'` und die passenden Katalogzuordnungen und Rechte.

Beginne mit der [CTE-Anleitung](LocalCteDebug.md) für Startwerte, Dummy-Quellen,
Zwischenschritte und Lookup-Fehlzeilen. `StageIndex` hilft bei der Auswahl einer
Stufe. Bei einem unvollständigen Ziel geben `DetailsJson` und die Teilpläne
Aufschluss über fehlende Informationen. Prüfe `IsExecutable` und die enthaltenen
Quellobjekte, bevor du ein Skript manuell ausführst.

## Zentrale Installation und Consumer-Datenbank

Installiere das Modul und seine Abhängigkeiten zusammen in der zentralen
Datenbank. Für den Aufruf in einer anderen Datenbank derselben Instanz verwende
zum Beispiel `EXEC [ContosoToolbelt].toolbelt_tsql.USP_ExplainSsisDataFlow`
mit den oben gezeigten Eingaben. Die Anmeldung benötigt Zugriff auf die
zentrale Datenbank und `EXECUTE` auf die Prozedur. Im Katalogmodus kommen
die im Vertrag genannten Rechte zur Sicht auf Quellmetadaten hinzu.

Ausführung und Erzeugung sind eigene Schritte. Prüfe vor dem Ausführen, welche
Quellen das Skript aus der Sitzung verwendet und welche Rechte dafür gelten.
Gerade bei Prozedurquellen können beim manuellen Ausführen die Seiteneffekte
der Quellprozedur eintreten. Die [Objektreferenz](USP_ExplainSsisDataFlow.md)
beschreibt Artefakte, Argumente und die Voraussetzungen für die wiederverwendbare
Prozedurdefinition.

## Parameter ermitteln, bearbeiten und zurückgeben

Für einfache Fälle genügen Paketdefaults oder `@StartValues` als JSON. Bei
komplexer Projektbindung liefert `@Operation=N'bindings-template'` die
vorhandenen Eingabeschlüssel und Entwurfswerte. Bearbeite `values` mit den
angegebenen JSON-Typen und übergib die vollständige Vorlage als `@Bindings`.
Bei einem anderen `@ProjectContext` zuerst eine neue Vorlage erzeugen.
Sensitive Werte sind vom Eingabevertrag ausgeschlossen.

## Grenzen direkt als SQL-Parameter

Die `@Max...`-Parameter sind benannte SQL-Parameter. Prüfe Defaults,
konfigurierbare Grenzen und feste Schutzgrenzen in der
[Objektreferenz](USP_ExplainSsisDataFlow.md). Die installierte Kurz- und
Vollhilfe ist mit `EXEC toolbelt_tsql.USP_ExplainSsisDataFlow @Hilfe=1;`
abrufbar.

<a id="prozedurdefinition-v1-installieren"></a>
<a id="installation-der-bisherigen-paketstände"></a>
[Archiv früherer SSIS-Installationsstände](../../../Documentation/History/SSIS_INSTALLATION_ARCHIVE.md)
