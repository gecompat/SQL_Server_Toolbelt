# Modul- und Abhängigkeitsmodell

## Modul-Definition

Ein Modul ist eine eigenständige Lifecycle-, Deployment- und Dokumentationseinheit in SQL Server Toolbelt. Es kann eine zentrale Funktion oder mehrere zusammengehörige Objekte enthalten.

## Modulstruktur

Jedes Modul enthält mindestens:
- Manifest (geplant: `module.yaml`): Modul-ID, Version, Status, Plattformen, Schemas, Dependencies, Rechte
- Installationsskript (`Install.sql`)
- Upgradeskript (`Upgrade.sql`)
- Deinstallationsskript (`Uninstall.sql`)
- Dokumentation für jedes öffentliche Objekt
- Dokumentation für interne Hilfsobjekte

## Abhängigkeiten

- Module dürfen versionierte Abhängigkeiten auf andere Module besitzen.
- Vor der ersten Mutation: Preflight prüft alle Abhängigkeiten.
- Fehlende oder ungeeignete Abhängigkeit → klare Meldung und vollständiger Abbruch.
- Keine automatische Nachinstallation von Abhängigkeiten.
- Keine Abhängigkeitszyklen erlaubt.

## Kanonische Implementierung

Wiederverwendete Fachlogik existiert genau einmal in der kanonischen Implementierung. Wrapper, alternative Ausgabeformen und Synonyme verwenden stets diese kanonische Implementierung; keine divergierenden Kopien.

## Schemas

Schemas folgen dem Muster `toolbelt_<category>`. Erlaubte Beispiele:
- `toolbelt_core`
- `toolbelt_string`
- `toolbelt_datetime`
- `toolbelt_conversion`
- `toolbelt_validation`
- `toolbelt_json`
- `toolbelt_xml`
- `toolbelt_metadata`
- `toolbelt_security`

## Manifest-Felder (geplant, mindestens)

Ein Modul-Manifest soll später enthalten:
- Modul-ID und Version
- Status (`proposed`, `implemented`, `validated`, usw.)
- Unterstützte SQL-Server-Versionen
- Betriebssysteme (Windows, Linux)
- Deployment-Modi (lokal, zentral)
- Schemas und Objekte
- Dependencies (Modul, Mindestversion)
- Erforderliche Rechte
- Collation-Vertrag
- Resultset-Verträge
- Lifecycle-Artefakte (Install, Upgrade, Uninstall)
- Tests und Validierungsstatus

## Statuswerte

| Status | Bedeutung |
|---|---|
| `proposed` | Idee, kein Code |
| `researched` | Recherchiert, kein Code |
| `planned` | Arbeitspaket erstellt |
| `implemented` | Code vorhanden, kein Runtime-Nachweis |
| `validated` | Tatsächlich ausgeführte Prüfungen erfolgreich |
| `experimental` | Funktionsfähig, nicht vollständig validiert |
| `deprecated` | Veraltet, wird entfernt |
| `unsupported` | Nicht unterstützte Konfiguration |
| `not executed` | Test/Prüfung nicht ausgeführt |
| `not applicable` | Nicht anwendbar |
| `curiosity` | Theoretische Überlegung |
