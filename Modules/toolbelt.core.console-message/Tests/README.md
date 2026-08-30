# Tests – Console Message

V0a-Evidenz 2026-08-29: `local: Tests/CI/run-lab-local.ps1` belegt
ausschließlich den im Modulmanifest genannten physischen Linux-Scope; offene
Windows- und modulspezifische Fälle bleiben unberührt.

Alle Testpayloads sind synthetisch.

`ConsoleMessage.Contract.sql` prüft API, Help, NULL-/Leertext und beide
Provider. `ConsoleOutput.Contract.sql` erzeugt erfassbare Anfangs-, Mittel-,
End-, Prozent-, Supplementary-Character- und Zeilenmarker.
`Lifecycle.Contract.sql` und `Central.Contract.sql` prüfen Deploymentmarker
und dreiteilige Nutzung.

Aktueller Runtime-Status: `partially validated`.

[W2c-Runtime 30573135975](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30573135975)
war auf SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170
erfolgreich.

Der vollständige Adapter ist seit 2026-08-29 zusätzlich auf physischen
SQL-Server-2019-, 2022- und 2025-Linux-Zielen erfolgreich. Windows-Läufe sowie
unterschiedliche Clients und Treiber bleiben getrennte Pflichtprüfungen.

Der Project-Adapter-Pilot ADP-008 ist am 2026-08-30 mit SQL Server 2025 Linux
getrennt unter Docker und Podman erfolgreich
(`local: SQL_Server_Lab Project Adapter 0.1`). Beide Läufe installierten das
Modul, führten das versionsgleiche Update aus, validierten Modulmarker,
öffentliche Signatur und Help-Vertrag und entfernten anschließend die
markergebundene Adapterdatenbank sowie die scopegebundenen Lab-Ressourcen.
Der Nachweis erweitert weder den offenen Windows- noch den Client-/Treiber-
Scope und ändert deshalb den Status `partially validated` nicht.
