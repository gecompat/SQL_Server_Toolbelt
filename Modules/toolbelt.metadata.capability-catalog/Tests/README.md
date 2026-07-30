# Tests – Module Capability Catalog

Alle zusätzlichen Extended Properties verwenden synthetische Modul-IDs und
werden im Runtime-Contract wieder entfernt.

`ModuleCapabilities.Contract.sql` prüft gültige, unvollständige, ungültige,
falsch typisierte, falsch geschriebene und nicht datenbankweite Marker.
`Lifecycle.Contract.sql` und `Central.Contract.sql` prüfen Objektart,
Modulmarker und dreiteilige Nutzung.

Aktueller Runtime-Status: `partially validated`.

[W2c-Runtime 30573135975](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30573135975)
war auf SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170
erfolgreich.

Physische SQL-Server-2019-/2022- und Windows-Läufe sowie eingeschränkte
Metadata-Visibility bleiben getrennte Pflichtprüfungen.
