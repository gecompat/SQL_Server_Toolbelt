# Tests – Console Message

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

Physische SQL-Server-2019-/2022- und Windows-Läufe sowie unterschiedliche
Clients und Treiber bleiben getrennte Pflichtprüfungen.
