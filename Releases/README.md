# Releasepakete und Vorbereitung

Dieser Bereich enthält die überprüfbare Vorbereitung benannter Projektversionen.
Die Projektversion bündelt Module mit eigenen Versionsnummern und getrennten
Validierungs- und Veröffentlichungsstatuswerten.

## v1.0.0 vorbereiten oder prüfen

Der [aktuelle Quellkandidat](1.0.0/CURRENT-CANDIDATE.md) bindet den heutigen
versionierten Stand und den separat geprüften Parameter-Help-Installer.
Seine Anleitung erklärt Bau, Prüfung und die weiterhin offenen Releasegates.

Die [Vorbereitung für v1.0.0](1.0.0/README.md) umfasst alle 45 implementierten
Module, eine [Freigabematrix](1.0.0/FREIGABEMATRIX.md) und einen eingefrorenen
Quellpaket-Kandidaten mit zusätzlichen SQL-Exports für die stabilen Kandidaten.
Es gibt noch keine Veröffentlichung. Die Kennzeichnungen stabil/Preview sind
Vorschläge für den Release-Review; alle Modulmanifeste bleiben `unreleased`.

Für den Bau gelten die vorhandenen [Veröffentlichungsregeln](../Documentation/Architecture/MODULE_AND_DEPENDENCY_MODEL.md#öffentlicher-veröffentlichungsnachweis).
Ein Paket oder grüner CI-Lauf ersetzt keine konkrete Veröffentlichungsfreigabe.
