# toolbelt_metadata.VW_ModuleCapabilities

**Typ:** View
**Status:** `implemented`; Runtime `not executed`

## Zweck

Projiziert Toolbelt-Modulmarker aus `sys.extended_properties` der aktuellen
Datenbank und weist Drift als `incomplete` oder `invalid` aus.

## Spalten

| Ordinal | Spalte | Typ | Nullable | Beschreibung |
|---:|---|---|---:|---|
| 1 | `ModuleId` | `sysname` | nein | Aus dem Markernamen extrahierte Modul-ID. |
| 2 | `ModuleVersion` | `nvarchar(4000)` | ja | Vorhandener Version-Marker; bei fehlendem Marker `NULL`. |
| 3 | `DeploymentMode` | `nvarchar(4000)` | ja | Vorhandener Modus-Marker; bei fehlendem Marker `NULL`. |
| 4 | `MetadataStatus` | `varchar(16)` | nein | `valid`, `incomplete` oder `invalid`. |

## Verwendung

```sql
SELECT
      ModuleId
    , ModuleVersion
    , DeploymentMode
    , MetadataStatus
FROM toolbelt_metadata.VW_ModuleCapabilities
ORDER BY ModuleId;
```

Die View garantiert ohne konsumierendes `ORDER BY` keine Reihenfolge.

## Validierungsregeln

`valid` verlangt kanonische Database-level Marker, eine kleingeschriebene
`toolbelt.*`-ID, Textwerte, eine dreiteilige stabile Release-Version ohne
führende Nullen und `local` oder `central`.

Ein fehlender Partner-Marker ergibt `incomplete`. Mehrfache, falsch
geschriebene, falsch typisierte oder syntaktisch ungültige Marker ergeben
`invalid`. Vorhandene Markerwerte bleiben in den Spalten sichtbar.

## Rechte, Performance und Grenzen

Erforderlich ist `SELECT` auf der View. Die normale SQL-Server-Metadata-
Visibility bleibt wirksam. Die View liest nur Database-level Extended
Properties der aktuellen Datenbank und mutiert nichts.

Nicht enthalten sind Objektinventar, Provider, Plattformen, Dependencies,
Supportmatrix, automatische Reparatur, Filter-TVF und persistente Registry.
Prerelease- und Build-Versionen sind in V1 ungültige installierte Marker.
