---
name: "toolbelt-metadata-module-capabilities"
description: "Zeigt sichtbare bekannte Modulschnittstellenkandidaten; Version und Deployment-Modus bleiben NULL, MetadataStatus bleibt incomplete."
skill_format_version: "1.0"
module_id: "toolbelt.metadata.capability-catalog"
schema_name: "toolbelt_metadata"
object_name: "VW_ModuleCapabilities"
object_type: "VW"
database_role: "toolbelt"
is_internal: false
parameters: []
source_paths: ["Modules/toolbelt.metadata.capability-catalog/Source/VW_ModuleCapabilities.sql", "Scripts/Install/New-MarkerlessCapabilities.py", "Scripts/Install/markerless_manifest.py"]
review_status: "verified"
source_module_version: "1.0.0"
---

# VW_ModuleCapabilities

## Zweck und Einsatzfälle

Sichtbare bekannte Toolbelt-Schnittstellenkandidaten der aktuellen Datenbank anzeigen. Ein einziges passendes sichtbares Objekt oder eine deklarierte Assembly genügt für eine Modulzeile. Keine Versions-, Herkunfts-, Vollständigkeits-, Gesundheits- oder Qualifikationsfeststellung. Nicht mit der konstanten Usage-Skill-View verwechseln: diese View prüft zur Laufzeit Katalogsichtbarkeit, der Skillkatalog beschreibt bekannte Nutzungsverträge unabhängig von Installation.

## Voraussetzungen

Installierte markerfreie View auf SQL2019/2022/2025 Windows/Linux, lokal oder zentral mit dem zulässigen Compatibility Level. Keine Runtime-Modulabhängigkeit und kein CLR-Aufruf. Der Generator liest beim Offlinebuild alle module.yaml-Dateien deterministisch und erzeugt feste Kandidatentupel ModuleId/qualifizierter Name/zulässige SQL-Objekttypen. Assemblies aus expliziten Deklarationen; bei einem Modul ohne Objekte Fallback auf dessen deklarierten CLR-Assemblynamen. Toolbelt-Assemblyalias tlblt_, bereits tlblt-Namen erhalten; private ScriptDom-Alias tlblt.Microsoft.SqlServer.TransactSql.ScriptDom. Unbekannte Manifestformen/Objekttypen oder Assemblyaliasformen brechen den Build ab, keine automatische Runtime-Discovery.

## Parameter und Zugriff

Keine SQL-Aufrufparameter, Defaults oder OUTPUT-Parameter. SELECT mit WHERE/ORDER BY auf dem Resultset; aus anderer Datenbank gegebenenfalls dreiteilig ContosoToolbelt.toolbelt_metadata.VW_ModuleCapabilities bei vorhandener Datenbankzuordnung und passenden Rechten. Die Abfrage beschreibt stets die Datenbank der View, nicht automatisch die konsumierende Datenbank oder andere Server.

## Ergebnisse

Vier Spalten in Reihenfolge: ModuleId sysname (aus fester Manifest-ID), ModuleVersion nvarchar(4000) immer NULL, DeploymentMode nvarchar(4000) immer NULL, MetadataStatus varchar(16) immer incomplete. DISTINCT ModuleId ergibt höchstens eine Zeile je Modul unter der wirksamen SQL-Kollation. Keine sichtbare passende Schnittstelle: keine Modulzeile, keine separate Fehlzeile. Ausgabereihenfolge nur durch konsumierendes ORDER BY. Nullability der nativen Clientmetadaten wird hier nicht behauptet. Die Laufzeitwerte enthalten keine verifizierte Versions-/Installationsinformation.

## Aufrufbeispiele

```sql
SELECT ModuleId,ModuleVersion,DeploymentMode,MetadataStatus
FROM toolbelt_metadata.VW_ModuleCapabilities
ORDER BY ModuleId;

SELECT ModuleId,MetadataStatus
FROM ContosoToolbelt.toolbelt_metadata.VW_ModuleCapabilities
WHERE ModuleId=N'toolbelt.metadata.identifier';
-- Eine Zeile bedeutet nur: mindestens ein sichtbarer namens-/typgleicher Kandidat.
```

## Rechte

SELECT auf die View; bei dreiteiligem Zugriff zusätzlich vorhandener Datenbankzugriff und gültige Zuordnung. Normale Metadata Visibility bleibt wirksam. Die View fordert keine zusätzlichen serverweiten Sichtbarkeitsrechte an, vergibt keine Rechte und wechselt keine Identität. Fehlende Metadatensichtbarkeit kann eine Modulzeile ausblenden. Sichtbarkeit ist kein Nachweis eines Ausführungsrechts auf die gefundenen Objekte.

## Ressourcenbedarf

Eine feste VALUES-Kandidatenmenge aus den Manifesten und zwei katalogbezogene EXISTS-Pfade über sys.objects/sys.assemblies, danach DISTINCT. Keine Fachdatenscans, CLR-, Datei-, Netzwerk- oder LLM-Aufrufe, kein Runtime-Zugriff auf Manifestdateien. Aufwand hängt von Kandidaten-/Katalogumfang und SQL-Plan ab; keine implementierte Zeit-, CPU-, Speicher- oder Ausgabebytequote. SQL-Ressourcen-/Timeoutfehler bleiben möglich.

## Nebenwirkungen

Reines SELECT ohne DML, DDL, eigene Transaktionen, Sessionkonfiguration, Deploymentlog oder Extended Properties. Für Nicht-Assemblies wird OBJECT_ID des festen qualifizierten Namens in der Viewdatenbank mit sys.objects und erlaubtem Typ abgeglichen: USP P/PC, TVF IF/TF/FT, SVF FN/FS, CLR-USP PC, CLR-TVF FT, CLR-SVF FS, CLR-Aggregat AF, View V, Tabelle U. Synonyme SN werden nicht als diese Typen anerkannt. Assemblies müssen in sys.assemblies per varbinary(256)-Namensgleichheit passen, ohne Casefold/SQL-Paddinggleichheit; normale Objektauflösung unterliegt hingegen der Datenbankkollation. Keine Inhalts-/Signatur-/Assemblyhash-/Owner-/Modusprüfung. Eine unvollständige oder fremde namensgleiche Installation kann deshalb erscheinen.

## Fehlerbehandlung

Keine fachlichen Statuscodes für fehlende/unsichtbare Kandidaten und kein THROW in der View; solche Kandidaten fehlen im Resultset. MetadataStatus ist immer incomplete, nicht invalid oder valid. Fehlender SELECT-/Datenbankzugriff oder technische Enginefehler werden unverändert von SQL Server gemeldet. Der Offlinegenerator hat getrennte Validierungsfehler und --check meldet Quellabweichung; diese sind keine SQL-Aufruffehler.

## Aussagegrenzen

Quellgeprüfter aktueller markerfreier Vertrag. Historische Marker-/Minimalrechte-/Lifecycle-Nachweise qualifizieren ausschließlich ihre ursprünglichen Definitionen. Keine neue native aktuelle View-/Clientmetadaten-/Sichtbarkeits-/Installerabnahme behaupten. Weder Autorisierungs-, Ownership-, Upgrade- noch Dependencygate. Vollständige Objekte, Signaturen, Berechtigungen, Paketbindung und fachliche Nutzbarkeit separat prüfen. Die rein konstante VW_ObjectUsageSkills ist eine andere Oberfläche; ein Skillkatalogeintrag attestiert ebenfalls keine Installation oder Rechte.
