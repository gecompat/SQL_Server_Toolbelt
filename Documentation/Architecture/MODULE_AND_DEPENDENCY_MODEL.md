# Modul- und Abhängigkeitsmodell

## Moduldefinition

Ein Modul ist eine eigenständige Lifecycle-, Deployment- und Dokumentationseinheit. Es kann eine einzelne zentrale Funktion oder mehrere fachlich zusammengehörige Objekte enthalten.

Eine besonders grundlegende Capability darf selbst ein Modul bilden und von anderen Modulen verwendet werden.

## Mindestbestandteile

Jedes Modul enthält mindestens:

- `module.yaml` als Manifest;
- ein parametergesteuertes Deploy- und ein Uninstall-Skript;
- kanonische Source-Artefakte;
- eigene Dokumentation für jedes öffentliche SQL-Objekt;
- Dokumentation interner Hilfsobjekte;
- synthetische Beispiele;
- statische und Runtime-Testartefakte;
- Primärquellen und bekannte Einschränkungen.

## Abhängigkeiten

- Abhängigkeiten deklarieren Modul-ID, Mindestversion und Installationsort.
- Der vollständige Preflight erfolgt vor der ersten Mutation.
- Fehlende oder ungeeignete Abhängigkeit führt zu klarer Meldung und vollständigem Abbruch.
- Fehlende Module werden nicht automatisch nachinstalliert.
- Zyklen sind unzulässig.
- Eine Dependency wird nicht durch kopierte Objekte ersetzt.

## Kanonische Implementierung

Wiederverwendete Fachlogik existiert genau einmal. Öffentliche Wrapper, alternative Provider, Synonyme und Ausgabeformen verwenden diesen kanonischen Kern. Eine zweite Fachimplementierung ist nur zulässig, wenn sie als eigener Provider denselben öffentlichen Vertrag erfüllt und technisch begründet ist.

## Schemas

Öffentliche Objekte verwenden `toolbelt_<category>`. Ein Modul kann mehrere Schemas verwenden, wenn dies fachlich erforderlich und im Manifest dokumentiert ist.

## Manifestfelder

Mindestens:

- Modul-ID, Name, Version und Status;
- unterstützte SQL-Server-Versionen und Compatibility Levels;
- Windows-/Linux- und Provider-Matrix;
- Deployment-Modi und Capability-Kennzeichnungen;
- verwendete Schemas und öffentliche/interne Objekte;
- Dependencies mit Ort und Mindestversion;
- Berechtigungen;
- Collation- und Datentypvertrag;
- Resultset- und Help-Verträge;
- CLR-`PERMISSION_SET` und Trust-Anforderungen, falls relevant;
- Lifecycle-Artefakte;
- versionierte Release-Objektmanifeste und tatsächlicher Installationsstand;
- Tests und tatsächlicher Validierungsstatus.

## Status

| Status | Bedeutung |
|---|---|
| `proposed` | Idee ohne Code |
| `researched` | recherchiert, noch nicht freigegeben |
| `planned` | freigegebenes Arbeitspaket |
| `implemented` | Code und statische Verträge vorhanden |
| `validated` | relevante Prüfungen tatsächlich erfolgreich ausgeführt |
| `experimental` | funktionsfähig, nicht vollständig validiert |
| `deprecated` | zur Ablösung vorgesehen |
| `unsupported` | bewusst nicht unterstützt |
| `not executed` | Prüfung nicht ausgeführt |
| `not applicable` | im konkreten Scope nicht anwendbar und begründet |
| `curiosity` | theoretische Idee ohne Implementierungszusage |
