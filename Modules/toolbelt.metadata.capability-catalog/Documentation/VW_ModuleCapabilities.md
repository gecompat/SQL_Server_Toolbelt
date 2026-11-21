# toolbelt_metadata.VW_ModuleCapabilities

Die View zeigt sichtbare bekannte Toolbelt-Schnittstellenkandidaten der aktuellen Datenbank. Sie verwendet weder Extended Properties noch eine Registry. Ein namensgleiches Objekt beweist keine vollständige Installation, Herkunft oder Version.

| Spalte | Typ | Bedeutung |
|---|---|---|
| `ModuleId` | `sysname` | Kandidat mit mindestens einer sichtbaren bekannten Schnittstelle beziehungsweise Assembly. |
| `ModuleVersion` | `nvarchar(4000)` | Immer NULL; aus Namen nicht zuverlässig ableitbar. |
| `DeploymentMode` | `nvarchar(4000)` | Immer NULL; kein Installationsmodus wird erfunden. |
| `MetadataStatus` | `varchar(16)` | Immer `incomplete`; kein Gesundheits- oder Qualifikationsnachweis. |

```sql
SELECT ModuleId,ModuleVersion,DeploymentMode,MetadataStatus
FROM toolbelt_metadata.VW_ModuleCapabilities ORDER BY ModuleId;
```

`SELECT` auf der View und die normale Metadata Visibility gelten unverändert. Unsichtbare Objekte können Kandidaten ausblenden; es werden keine Rechte vergeben. Die View mutiert nichts und garantiert ohne ORDER BY keine Reihenfolge. Sie darf weder als Ownership- noch als Upgrade-/Autorisierungsgate dienen. Die feste Kandidatenprojektion wird aus den Modulmanifesten erzeugt; zur Laufzeit werden nur `sys.objects` und `sys.assemblies` gelesen.

Der aktuelle markerfreie Vertrag ist noch nicht nativ vollständig qualifiziert. Frühere Markerläufe qualifizieren ausschließlich die nachfolgend erhaltene alte Definition.

Der [Usage-Skill](../../../Metadata/UsageSkills/toolbelt_metadata/VW_ModuleCapabilities.md)
enthält den vollständigen aktuellen Vertrag und steht auch als Kommentar in der
kanonischen DDL. Es gibt keine Aufrufparameter oder `@Hilfe` für diese View.
Die separat beauftragte konstante `toolbelt_metadata.VW_ObjectUsageSkills`
liefert Beschreibungen bekannter Objekte und führt diese Sichtbarkeitsfilterung
nicht durch. Ein Skill ist kein Installationsnachweis.

## Historischer Marker-Vertrag bis 2026-11-19

# toolbelt_metadata.VW_ModuleCapabilities

**Typ:** View
**Status:** `implemented`; Runtime `validated`

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

Die [W2c-Runtime
30573135975](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30573135975)
belegt den View-Vertrag auf SQL Server 2025 Linux mit Compatibility Levels
150, 160 und 170. Physische Zielversions-, Windows- und eingeschränkte
Metadata-Visibility-Läufe bleiben offen.
