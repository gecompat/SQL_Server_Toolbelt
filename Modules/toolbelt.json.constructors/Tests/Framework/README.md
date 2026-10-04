# Offline-Produktqualifikation

`ProductHarness.cs`, `BridgeGoldens.tsv` und `Test-ProductIL.ps1` übernehmen
bytegleich die unabhängig qualifizierten synthetischen Proben. Sie verwenden
keinen SQL-Server und kein CLR-Context-Connection. Der CLR-Kern wird durch
das Frameworkprojekt gebaut; neue Binarybytes werden nicht automatisch als
bekannte Releases übernommen.

`Invoke-Framework.ps1` benötigt explizit das bekannte Produktbinary, einen
vorhandenen C#-Compiler, das .NET-Framework-4.8-Referenzverzeichnis, Windows
PowerShell5.1 für Reflection/IL und einen frischen privaten Outputpfad.
Aufrufhost ist PowerShell7. Compiler und IL haben je15 Sekunden, vier
Harnesskinder je45 Sekunden. Der vorhandene OwnedProcess-Helper begrenzt
beide Live-Ausgabekanäle separat auf4 MiB und beendet/entsorgt eigene Kinder
bei Fehlern mit endlichen Cleanup-/Drainfristen. Dies ist keine harte globale
Wallclockzusage.

Alle Source-/Tool-/Reference-/DLLpins werden nach den Phasen geprüft.
Nur exakte vollständige Quiet-/PASS-Ausgaben erlauben COMPLETE; Fehler
werden nicht zu erfolgreichen fachlichen Rows umgedeutet. Private Receipts
und Captures bleiben außerhalb des Repositorys. Historische Offlineevidenz
ist kein tatsächlicher Lauf dieses neuen Repositoryrunners.
