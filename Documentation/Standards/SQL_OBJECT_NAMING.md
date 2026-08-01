# SQL-Objekt-Namenskonventionen

## Präfixe

| Objekttyp | Präfix | Beispiel |
|---|---|---|
| Stored Procedure | `USP_` | `USP_PrepareResultTable` |
| Inline Table-valued Function | `TVF_` | `TVF_DateRange` |
| Multi-statement Table-valued Function | `TVF_` | `TVF_ParseDocument` |
| Scalar-valued Function | `SVF_` | `SVF_TrimExtended` |
| View | `VW_` | `VW_ModuleStatus` |

Nach dem Präfix folgt ein verständlicher `CamelCase`-Name.

## Fachliche Schemas

Schemas folgen `toolbelt_<category>`, beispielsweise:

- `toolbelt_core`
- `toolbelt_string`
- `toolbelt_datetime`
- `toolbelt_conversion`
- `toolbelt_validation`
- `toolbelt_json`
- `toolbelt_xml`
- `toolbelt_metadata`
- `toolbelt_security`

Unzulässig sind allgemeine oder potenziell kollidierende Schemas wie `string`, `time`, `io`, `json` oder `xml`.

## Interne lokale Temp-Objekte

Interne lokale Temp-Tabellen verwenden den reservierten Präfix `#tbx_` und danach eine verständliche englische Kennzeichnung für Modul, Routine und Rolle.

Beispiele:

```text
#tbx_Core_PrepareResultTable_Metadata
#tbx_String_Split_ResultShape
```

Regeln:

- generische Namen wie `#Temp`, `#Result`, `#Help` oder `#Schema` sind unzulässig;
- dynamisch erzeugte Arbeitsobjekte erhalten zusätzlich einen Invocation-spezifischen Suffix;
- eine routinenspezifische, unveränderliche Schema-Helper-Tabelle darf bei Rekursion wiederverwendet werden;
- nur der tatsächliche Erzeuger entfernt eine wiederverwendete Helper-Tabelle;
- Benutzer dürfen den reservierten Präfix `#tbx_` nicht als `@ResultTable` beziehungsweise `@ResultTableToAlter` verwenden;
- lokale Temp-Tabellennamen bleiben einschließlich Präfix und Suffix innerhalb des SQL-Server-Limits.

Diese Regel gilt nur für interne lokale Temp-Objekte.

## Persistente Tabellen, Constraints und Indizes

Persistente Tabellen verwenden im fachlichen `toolbelt_<category>`-Schema einen verständlichen singulären `CamelCase`-Namen ohne Typpräfix.

Beispiel:

```text
toolbelt_core.WorkType
```

Verbindliche Präfixe für abhängige Objekte:

| Objekttyp | Präfix | Beispiel |
|---|---|---|
| Primary Key | `PK_` | `PK_WorkType` |
| Unique Constraint | `UQ_` | `UQ_WorkType_WorkTypeName` |
| Foreign Key | `FK_` | `FK_WorkItem_WorkType` |
| Check Constraint | `CK_` | `CK_WorkType_ParameterMode` |
| Default Constraint | `DF_` | `DF_WorkType_IsEnabled` |
| regulärer Index | `IX_` | `IX_WorkType_IsEnabled_WorkTypeName` |

Spalten sind englisch und `CamelCase`. Systemgenerierte Constraintnamen sind unzulässig. Eine persistente Tabelle ist standardmäßig ein internes Modulobjekt; ein öffentlicher Tabellenzugriff muss im Manifest ausdrücklich deklariert werden.

## Sprache und Eindeutigkeit

Öffentliche und interne technische Identifier sind englisch. Dies gilt insbesondere für Schema-, Objekt-, Parameter-, Spalten-, Variablen-, Klassen- und Methodennamen.

Kommentare und technische Dokumentation sind deutsch. Etablierte englische Fachbegriffe bleiben englisch.

Namen dürfen sich nicht nur durch Groß-/Kleinschreibung, Akzente oder eine bestimmte Collation unterscheiden.

## Reservierte Wörter

Neue Schema-, Objekt- und Spaltennamen werden gegen aktuelle reservierte Wörter und dokumentierte Future Keywords geprüft. Ein öffentlicher Name darf keine eckigen Klammern benötigen, um regulär verwendbar zu sein.

Vermeide unspezifische Verb-Namen wie `Read`, wenn ein präziser Name wie `LoadTextFile` oder `ParseTimestamp` die Semantik besser beschreibt.

## Offene persistente Objekttypen

Für folgende persistente Objekttypen besteht noch keine Konvention:

- Synonyme
- Assemblies
- Trigger
- Sequences
- Types

Beim ersten tatsächlichen Bedarf eines weiterhin offenen Objekttyps ist die Konvention als Architekturentscheidung festzuhalten. Keine Präfixe spekulativ erfinden.
