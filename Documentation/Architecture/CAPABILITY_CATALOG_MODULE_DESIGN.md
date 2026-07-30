# Moduldesign: Module Capability Catalog

## Status und Freigabe

`TC-2026-023` wurde am 2026-07-30 im V1-Scope von W2c ausdrücklich
freigegeben. Das Modul heißt `toolbelt.metadata.capability-catalog`, Version
`1.0.0`.

## Öffentlicher Vertrag

Einziges persistentes Objekt ist
`toolbelt_metadata.VW_ModuleCapabilities`. Die View liefert:

| Spalte | Typ | Bedeutung |
|---|---|---|
| `ModuleId` | `sysname` | Aus dem Database-level Markernamen extrahierte Modul-ID. |
| `ModuleVersion` | `nvarchar(4000)` | Unverändert als Text projizierter Version-Marker oder `NULL`. |
| `DeploymentMode` | `nvarchar(4000)` | Unverändert als Text projizierter Modus-Marker oder `NULL`. |
| `MetadataStatus` | `varchar(16)` | `valid`, `incomplete` oder `invalid`. |

Die View garantiert ohne konsumierendes `ORDER BY` keine Reihenfolge.

## Marker und Status

V1 liest ausschließlich `sys.extended_properties` der aktuellen Datenbank mit
`class = 0`, `major_id = 0` und `minor_id = 0`:

```text
Toolbelt.Module.<ModuleId>.Version
Toolbelt.Module.<ModuleId>.DeploymentMode
```

`valid` verlangt genau einen kanonisch geschriebenen Marker je Art, eine
kleingeschriebene Modul-ID unter `toolbelt.*`, einen Textwert für beide
Marker, eine stabile dreiteilige Release-Version `MAJOR.MINOR.PATCH` ohne
führende Nullen und `local` oder `central`.

`incomplete` bedeutet, dass für eine erkennbare Modul-ID einer der beiden
Marker fehlt. `invalid` bedeutet unter anderem falsche Marker-Schreibweise,
unzulässige Modul-ID, falschen Datentyp, ungültige Version oder unbekannten
Deployment-Modus. Die vorhandenen Werte bleiben in den Ausgabespalten
sichtbar; Drift wird nicht als gesund dargestellt.

## Architekturgrenzen

- keine persistente Registry und damit keine neue Tabellenkonvention;
- keine Runtime-Abhängigkeit von `module.yaml`;
- keine Objekt-, Provider-, Plattform- oder Dependency-Inventur in V1;
- keine zusätzliche Filter-TVF;
- kein automatischer Reparatur- oder Mutationspfad;
- Metadata Visibility des Aufrufers bleibt wirksam.

Das Modul besitzt keine Runtime-Abhängigkeit zu
`toolbelt.validation.semantic-version`. Die bewusst schmale
Release-Version-Prüfung verhindert eine zyklische Discovery-Abhängigkeit.
Prerelease- und Build-Metadaten sind in V1 für installierte Modulmarker
ungültig.

## Performance und Tests

Die View scannt ausschließlich die kleine Menge der Database-level Extended
Properties. Runtime-Tests prüfen gültige, fehlende, falsch typisierte,
syntaktisch ungültige und falsch geschriebene synthetische Marker, abweichende
Database Collations, Central-Aufruf, Wiederholungsdeployment und Uninstall.

Primärquelle:

- [Microsoft: sys.extended_properties](https://learn.microsoft.com/en-us/sql/relational-databases/system-catalog-views/extended-properties-catalog-views-sys-extended-properties?view=sql-server-ver17)
