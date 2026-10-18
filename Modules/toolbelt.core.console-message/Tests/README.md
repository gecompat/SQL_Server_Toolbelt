# Tests – Console Message

Nachqualifikation 2026-10-19: Der vollständige aktuelle Moduladapter bestand auf SQL Server 2019/2022/2025 unter Windows und Linux. Zusätzliche ADO.NET- und ODBC/sqlcmd-Prüfungen decken den Client-/Treiber-Gate im bestehenden Enginevertrag ab. Runtime: `validated`; Release: `unreleased`. Die folgenden datierten älteren Abschnitte beschreiben ihren damaligen Stand. Details: [V0c-Gatebericht](../../../Tests/V0C_RELEASE_GATE_STATUS.md).

## Clientprüfung 2026-10-19

`Tests/CI/run-console-clients-lab.ps1` prüft mit PowerShell 7 und dem
installierten `System.Data.SqlClient` die tatsächlichen `InfoMessage`-Frames.
Auf SQL Server 2019/2022/2025 unter Linux latest und Windows mit den bereiten
CUs waren vollständiger Payload, Reihenfolge, Prozentzeichen, CRLF,
nachgestellte Leerzeichen, Surrogatpaare an Chunkgrenzen, beide Provider,
1-MiB-Grenze, Ablehnung vor erster Ausgabe und Help ohne Payload erfolgreich.
Eigene synthetische Datenbanken wurden entfernt und ihre Abwesenheit geprüft.

```powershell
./Tests/CI/run-console-clients-lab.ps1
```

Der Adapter verwendet ausschließlich schema-validierte, explizit ausgewählte
Labziele und `TestPurpose=Functional`. Er startet keine Labressourcen und
ändert keine Serverkonfiguration. Es werden nur abstrahierte Ergebnisse
ausgegeben. `ConsoleClient.Contract.ps1 -Connection $Connection` kann auch
direkt mit einer geöffneten ADO.NET-Verbindung zu einem installierten Modul
ausgeführt werden.

Die NOWAIT-Probe erfasst, ob der Marker vor Abschluss des Clientbefehls
beobachtet wird. Im abgeschlossenen Sechs-Ziel-Lauf war dies jeweils der
Fall; ein früherer Einzellauf lieferte keine solche vorzeitige Beobachtung.
Daraus wird weder eine Pufferungsursache noch eine allgemeine Latenzzusage abgeleitet.
Die bestehende W2c-Suite prüft zusätzlich die Ausgabemarker mit ODBC/sqlcmd.
Die zusätzliche Client-/Treiberprüfung ist damit für ADO.NET und ODBC/sqlcmd
abgedeckt. Eine visuelle SSMS-Prüfung wurde nicht ausgeführt; optische
Formatierung liegt gemäß bestehendem Vertrag außerhalb der Enginezusage.
Siehe [V0c-Rest-Gates](../../../Tests/V0C_RELEASE_GATE_STATUS.md).

Plattform-Evidenz 2026-09-01: `local: Tests/CI/run-lab-local.ps1` war auf physischen SQL-Server-2019-, 2022- und 2025-Zielen unter Windows base und Linux latest erfolgreich; zusätzliche Client-/Treiber-, Buffering- und Framing-Evidenz war damals offen. Der damalige Modulstatus war `partially validated`. Dieser Nachweis ersetzt frühere offene Windows-Aussagen; datierte ältere Einträge bleiben historische Evidenz.

V0a-Evidenz 2026-08-29: `local: Tests/CI/run-lab-local.ps1` belegt
ausschließlich den im Modulmanifest genannten physischen Linux-Scope; offene
Windows- und modulspezifische Fälle bleiben unberührt.

Alle Testpayloads sind synthetisch.

`ConsoleMessage.Contract.sql` prüft API, Help, NULL-/Leertext und beide
Provider. `ConsoleOutput.Contract.sql` erzeugt erfassbare Anfangs-, Mittel-,
End-, Prozent-, Supplementary-Character- und Zeilenmarker.
`Lifecycle.Contract.sql` und `Central.Contract.sql` prüfen Deploymentmarker
und dreiteilige Nutzung.

Aktueller Runtime-Status: `validated`.

[W2c-Runtime 30573135975](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30573135975)
war auf SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170
erfolgreich.

Der vollständige Adapter ist seit 2026-08-29 zusätzlich auf physischen
SQL-Server-2019-, 2022- und 2025-Linux-Zielen erfolgreich. Die Windows-Matrix und die zusätzlichen ADO.NET-/ODBC-Prüfungen sind
seit der Nachqualifikation vom 2026-10-19 belegt.

Der Project-Adapter-Pilot ADP-008 ist am 2026-08-30 mit SQL Server 2025 Linux
getrennt unter Docker und Podman erfolgreich
(`local: SQL_Server_Lab Project Adapter 0.1`). Beide Läufe installierten das
Modul, führten das versionsgleiche Update aus, validierten Modulmarker,
öffentliche Signatur und Help-Vertrag und entfernten anschließend die
markergebundene Adapterdatenbank sowie die scopegebundenen Lab-Ressourcen.
Der Nachweis erweitert weder den offenen Windows- noch den Client-/Treiber-
Scope und ändert deshalb den Status `partially validated` nicht.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-19`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Physische SQL Server 2019/2022/2025 unter Windows mit freigegebenen CU-Äquivalenten zu base und Linux latest; vollständiger lokaler/zentraler Moduladapter, versionsabhängige CL150/160/170, Lifecycle und Uninstall; Security-Grenzen und ODBC/sqlcmd-Ausgabe; zusätzlich run-console-clients-lab.ps1 mit ADO.NET-Frames, Unicode, atomarer Ablehnung und NOWAIT-Beobachtung auf allen sechs Zielen
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
