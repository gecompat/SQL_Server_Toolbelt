# toolbelt_metadata.VW_ObjectUsageSkills

Die View liefert die vollständigen Usage-Skills der im Quellstand bekannten
Toolbelt-Objekte. Eine KI kann zuerst passende Kurzbeschreibungen suchen und
danach die vollständige Gebrauchsanweisung eines Objekts lesen. Die View enthält
auch ihre eigene Beschreibung sowie interne Objekte und Assemblies.

| Spalte | SQL-Typ | Bedeutung |
|---|---|---|
| `SchemaName` | `sysname` | Schema; bei schemafreien Assemblies leer. |
| `ObjectName` | `sysname` | Eindeutiger Objektname innerhalb der Rolle und des Schemas. |
| `ObjectType` | `varchar(60)` | Deklarierte Objektart, beispielsweise `USP`, `TVF` oder `ASSEMBLY`. |
| `DatabaseRole` | `nvarchar(128)` | Logische Projekt-Datenbankrolle, kein tatsächlicher Datenbankname. |
| `IsInternal` | `bit` | Kennzeichnung interner Helfer. Deren Skills nennen öffentliche Einstiege. |
| `Description` | `nvarchar(4000)` | Kurzbeschreibung für die Auswahl. |
| `SkillFormatVersion` | `varchar(16)` | Version des Skillformats. |
| `SkillMarkdown` | `nvarchar(max)` | Vollständiger Skill einschließlich YAML-Frontmatter. |

## Finden und anschließend gezielt lesen

```sql
SELECT SchemaName,ObjectName,ObjectType,DatabaseRole,Description
FROM toolbelt_metadata.VW_ObjectUsageSkills
WHERE IsInternal=0 AND Description LIKE N'%DTSX%'
ORDER BY DatabaseRole,SchemaName,ObjectName;

SELECT SkillFormatVersion,SkillMarkdown
FROM toolbelt_metadata.VW_ObjectUsageSkills
WHERE DatabaseRole=N'toolbelt'
  AND SchemaName=N'toolbelt_tsql'
  AND ObjectName=N'USP_ExplainSsisDataFlow';
```

Bei zentraler Installation kann die View über einen dreiteiligen Namen wie
`[ContosoToolbelt].toolbelt_metadata.VW_ObjectUsageSkills` gelesen werden.
Erforderlich ist vorhandenes `SELECT` auf die View. Rechte auf die beschriebenen
Objekte sind für diese Abfrage nicht erforderlich und werden dadurch nicht
erteilt. Vor einer späteren fachlichen Ausführung gelten deren eigene Verträge.

## Aussage und Installation

Die Daten sind generierte Konstanten aus den
[kanonischen Markdownquellen](../../../Metadata/UsageSkills/README.md).
Gesamt- und Teilinstaller desselben Quellstands enthalten denselben bekannten
Katalog. Ein Eintrag bestätigt weder die Installation eines Objekts noch dessen
aktuelle Definition, Qualifikation oder ausreichende Aufruferrechte. Eine
fehlende Zeile beweist keine Nichtinstallation. Für tatsächlich sichtbare
Schnittstellenkandidaten gibt es separat
[VW_ModuleCapabilities](VW_ModuleCapabilities.md).

Der Installer ergänzt eine fehlende View und erhält eine bereits vorhandene
Definition. Nach Änderungen am Katalog sind eine frische Installation oder eine
gesondert kontrollierte manuelle Aktualisierung erforderlich. Eine weitere
Teilinstallation führt kein automatisches Merge, DROP oder ALTER des Katalogs
aus. Es gibt weder Metadatentabelle noch Extended Properties oder Analyseaufrufe.

Lange Texte werden serverseitig als `nvarchar(max)` geliefert. Anzeige- und
Exportgrenzen des Clients separat einstellen; abgeschnittene Bildschirmtexte
sind kein vollständiger Skill.
