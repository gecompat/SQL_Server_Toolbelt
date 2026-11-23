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

Der [Usage-Skill](../../../Metadata/UsageSkills/toolbelt_metadata/VW_ModuleCapabilities.md)
enthält den vollständigen aktuellen Vertrag und steht auch als Kommentar in der
kanonischen DDL. Es gibt keine Aufrufparameter oder `@Hilfe` für diese View.
Die separat beauftragte konstante `toolbelt_metadata.VW_ObjectUsageSkills`
liefert Beschreibungen bekannter Objekte und führt diese Sichtbarkeitsfilterung
nicht durch. Ein Skill ist kein Installationsnachweis.

<a id="historischer-marker-vertrag-bis-2026-11-19"></a>
[Archivierter Marker-Vertrag](../../../Documentation/History/OBJECT_USAGE_EVIDENCE.md#historischer-marker-vertrag-bis-2026-11-19)
