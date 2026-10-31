# Releasepakete und Vorbereitung

Dieser Bereich enthält die überprüfbare Vorbereitung benannter Projektversionen.
Die Projektversion bündelt Module mit eigenen Versionsnummern und getrennten
Validierungs- und Veröffentlichungsstatuswerten.

## Projektentwicklungssnapshot v1.0.0-rc.1 verwenden

Der [GitHub-Vorabrelease](https://github.com/gecompat/SQL_Server_Toolbelt/releases/tag/v1.0.0-rc.1)
enthält den geprüften Quellkandidaten, den aktuellen Parameter-Help-Installer,
Release Notes und Prüfsummen. Er ist ein Projekt-Snapshot für Tests und
veröffentlicht keine unterstützten Modulversionen. Alle Modulmanifeste bleiben
`unreleased`; die GitHub-Kennzeichnung als Vorabrelease ersetzt keine fachliche
Pflichtqualifikation.

Zuerst die ZIP-Prüfsumme kontrollieren und START-HERE.md im gewählten Paket
lesen. Die [Installationsanleitung](1.0.0/PARAMETER-HELP.md) führt durch die
Neuinstallation in einer leeren, ausdrücklich ausgewählten Testdatenbank.
Der [Veröffentlichungsnachweis](1.0.0/RC1-PUBLICATION.json) ist aus den tatsächlich
bestätigten GitHub-Release-/Tagdaten abgeleitet und nennt Quellcommit,
Veröffentlichungszeit, Assets und SHA256-Prüfsummen. Er ist kein
publication_record einer Modulversion. Die Statusfelder in den eingefrorenen
Paketen beschreiben deren Vorbereitungszeitpunkt; der aktuelle Projektstatus
steht in diesem Nachweis.

## v1.0.0 vorbereiten oder prüfen

Die [Abnahme der 19 stabilen Kandidaten](1.0.0/STABLE19-ACCEPTANCE.md) prüft
aktuelle Integration, anwendbare Fachnachweise und verbleibende Freigabegrenzen.
Der größere 45-Modul-Zielumfang und die RC-Veröffentlichung bleiben getrennt.

Der [aktuelle Quellkandidat](1.0.0/CURRENT-CANDIDATE.md) bindet den heutigen
versionierten Stand und den separat geprüften Parameter-Help-Installer.
Seine Anleitung erklärt Bau, Prüfung und die weiterhin offenen Releasegates.

Die [Vorbereitung für v1.0.0](1.0.0/README.md) umfasst alle 45 implementierten
Module, eine [Freigabematrix](1.0.0/FREIGABEMATRIX.md) und einen eingefrorenen
Quellpaket-Kandidaten mit zusätzlichen SQL-Exports für die stabilen Kandidaten.
Diese historischen Vorbereitungsnachweise sind von der obigen
Projekt-Snapshot-Veröffentlichung getrennt. Ihre weiterhin offenen Gates
betreffen die spätere unterstützte Modulveröffentlichung; alle Modulmanifeste
bleiben `unreleased`.

Für den Bau gelten die vorhandenen [Veröffentlichungsregeln](../Documentation/Architecture/MODULE_AND_DEPENDENCY_MODEL.md#öffentlicher-veröffentlichungsnachweis).
Ein Paket oder grüner CI-Lauf ersetzt keine konkrete Veröffentlichungsfreigabe.
