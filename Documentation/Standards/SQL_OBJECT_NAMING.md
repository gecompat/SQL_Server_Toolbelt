# SQL-Objekt-Namenskonventionen

## Präfixe

| Objekttyp | Präfix | Beispiel |
|---|---|---|
| Stored Procedure | `USP_` | `USP_StringSplit` |
| Inline TVF | `TVF_` | `TVF_DateRange` |
| Multi-statement TVF | `TVF_` | `TVF_ParseJson` |
| Scalar-valued Function | `SVF_` | `SVF_TrimExtended` |
| View | `VW_` | `VW_ModuleStatus` |

## Schemas

Schemas folgen dem Muster `toolbelt_<category>`:

| Schema | Kategorie |
|---|---|
| `toolbelt_core` | Kernfunktionen |
| `toolbelt_string` | String-Verarbeitung |
| `toolbelt_datetime` | Datum- und Zeitfunktionen |
| `toolbelt_conversion` | Typkonvertierungen |
| `toolbelt_validation` | Validierungsfunktionen |
| `toolbelt_json` | JSON-Verarbeitung |
| `toolbelt_xml` | XML-Verarbeitung |
| `toolbelt_metadata` | Metadatenabfragen |
| `toolbelt_security` | Sicherheitsfunktionen |

**Verboten:** Allgemeine oder potenziell kollidierende Schemanamen wie `string`, `time`, `io`, `json`, `xml`.

## Sprache

Öffentliche Identifier sind englisch. Interne Hilfsobjekte können deutsch benannt sein, sofern konsistent.

## Keyword-Prüfung

Neue Namen müssen gegen aktuelle und zukünftige T-SQL-Keywords geprüft werden. Öffentliche Objekte dürfen keine eckigen Klammern (`[` `]`) benötigen.

## Offene Entscheidungen

Für folgende Objekttypen existiert noch keine Namenskonvention:
- Tabellen
- Synonyme
- Assemblies
- Trigger
- Sequences
- Types

Keine Konvention erfinden. Bei erstem Bedarf: Benutzer fragen und in `Documentation/Architecture/DECISIONS.md` dokumentieren (DEC-2026-003).

## Vollständiges Beispiel

```sql
-- Schema: toolbelt_string
-- Objekt:  TVF_SplitString
-- Aufruf:  SELECT * FROM toolbelt_string.TVF_SplitString(N'a,b,c', N',')
```
