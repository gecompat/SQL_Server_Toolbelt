# Architekturentscheidungen

Dauerhafte Architektur- und Designentscheidungen werden hier mit stabiler ID dokumentiert.

## Vorlage

```markdown
### DEC-YYYY-NNN: <Titel>

| Feld | Wert |
|---|---|
| ID | DEC-YYYY-NNN |
| Datum | YYYY-MM-DD |
| Status | proposed / accepted / superseded / rejected |
| Begründung | <Warum diese Entscheidung?> |
| Scope | <Betroffene Module, Schemas, Artefakte> |
| Auswirkungen | <Was ändert sich?> |
| Ersetzte Alternativen | <Welche Alternativen wurden verworfen und warum?> |
```

---

## DEC-2026-001: T-SQL als bevorzugte Implementierungssprache

| Feld | Wert |
|---|---|
| ID | DEC-2026-001 |
| Datum | 2026-07-28 |
| Status | accepted |
| Begründung | T-SQL ist nativ für SQL Server, hat keine externen Abhängigkeiten, ist auf allen SQL-Server-Plattformen verfügbar und minimiert Deployment-Komplexität. |
| Scope | Alle Module |
| Auswirkungen | Alternativen (CLR, Python, R, Java) erfordern explizite technische Begründung. |
| Ersetzte Alternativen | CLR-first-Ansatz: erhöhter Deployment-Aufwand, Plattformabhängigkeiten, Trust-Verwaltung. |

---

## DEC-2026-002: Schema-Muster `toolbelt_<category>`

| Feld | Wert |
|---|---|
| ID | DEC-2026-002 |
| Datum | 2026-07-28 |
| Status | accepted |
| Begründung | Kollisionsarme, beschreibende Schemanamen; kein Konflikt mit T-SQL-Keywords; klar identifizierbar als Toolbelt-Objekte. |
| Scope | Alle öffentlichen Schemas |
| Auswirkungen | Schemas wie `string`, `time`, `io`, `json` sind verboten. |
| Ersetzte Alternativen | Einzel-Schema `toolbelt`: zu wenig Differenzierung; generische Namen: Kollisionsrisiko. |

---

## DEC-2026-003: Namenskonventionen für Tabellen, Synonyme, Assemblies, Trigger, Sequences, Types

| Feld | Wert |
|---|---|
| ID | DEC-2026-003 |
| Datum | 2026-07-28 |
| Status | proposed |
| Begründung | Für diese Objekttypen wurde noch keine Namenskonvention festgelegt, da kein konkreter Bedarf besteht. |
| Scope | Tabellen, Synonyme, Assemblies, Trigger, Sequences, Types |
| Auswirkungen | Keine Konvention erfunden; bei erstem Bedarf Benutzer fragen und Entscheidung hier dokumentieren. |
| Ersetzte Alternativen | – |
