# {{ModuleName}}

**Modul-ID:** `{{ModuleId}}`  
**Version:** `{{Version}}`  
**Status:** `proposed`

## Zweck

{{Fachliche Beschreibung des Moduls und der geschlossenen SQL-Server-Lücke.}}

## Öffentliche Objekte

| Objekt | Typ | Schema | Zweck |
|---|---|---|---|
| `{{ObjectName}}` | `{{USP/TVF/SVF/VW}}` | `toolbelt_{{category}}` | {{Kurzbeschreibung}} |

## Abhängigkeiten

| Modul | Mindestversion | Installationsort | Begründung |
|---|---|---|---|
| – | – | – | keine |

## Deployment

| Modus | Status | Hinweise |
|---|---|---|
| lokal | `not executed` | {{Hinweise}} |
| zentral | `not executed` | {{Hinweise}} |
| Cross-database | `not executed` | {{Hinweise oder begründetes not applicable}} |

## Plattformen

| Plattform | Status |
|---|---|
| SQL Server 2019 Windows | `not executed` |
| SQL Server 2022 Windows | `not executed` |
| SQL Server 2025 Windows | `not executed` |
| SQL Server 2019 Linux | `not executed` |
| SQL Server 2022 Linux | `not executed` |
| SQL Server 2025 Linux | `not executed` |

## Deployment

```sql
:r .\Deployment\Deploy.sql
```

{{DeploymentMode, Installationshinweise, unterstützte Vorgängerreleases und erforderliche Rechte.}}

## Collation- und Datentypvertrag

{{Caller- oder invariant semantics, verwendete String-Typen und bekannte Grenzen.}}

## Dokumentation

- Moduldetails: `Documentation/Module.md`
- Öffentliche Objekte: `Documentation/`
- Beispiele: `Examples/`
- Tests: `Tests/`

## Einschränkungen

{{Bekannte Einschränkungen und nicht unterstützte Kombinationen.}}

## Teststatus

Kein Test gilt ohne tatsächliche Ausführung als `validated`.
