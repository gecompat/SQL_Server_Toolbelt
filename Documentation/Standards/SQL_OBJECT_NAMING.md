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

## Sprache und Eindeutigkeit

Öffentliche und interne technische Identifier sind englisch. Dies gilt insbesondere für Schema-, Objekt-, Parameter-, Spalten-, Variablen-, Klassen- und Methodennamen.

Kommentare und technische Dokumentation sind deutsch. Etablierte englische Fachbegriffe bleiben englisch.

Namen dürfen sich nicht nur durch Groß-/Kleinschreibung, Akzente oder eine bestimmte Collation unterscheiden.

## Reservierte Wörter

Neue Schema-, Objekt- und Spaltennamen werden gegen aktuelle reservierte Wörter und dokumentierte Future Keywords geprüft. Ein öffentlicher Name darf keine eckigen Klammern benötigen, um regulär verwendbar zu sein.

Vermeide unspezifische Verb-Namen wie `Read`, wenn ein präziser Name wie `LoadTextFile` oder `ParseTimestamp` die Semantik besser beschreibt.

## Offene Objekttypen

Für folgende Objekttypen besteht noch keine Konvention:

- Tabellen
- Synonyme
- Assemblies
- Trigger
- Sequences
- Types

Beim ersten tatsächlichen Bedarf ist der Benutzer zu fragen und `DEC-2026-003` zu aktualisieren oder zu ersetzen. Keine Präfixe spekulativ erfinden.
