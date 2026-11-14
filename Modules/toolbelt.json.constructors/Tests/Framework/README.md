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

## Aktuelle Run-Transportgegenproben

`RunTransportHarness.cs` ist Teil des bestehenden gemeinsamen
`Invoke-SourceQualification.ps1`-Laufs. Der zusätzliche Compilerprozess hat die
bestehende 15-Sekunden-Grenze; der eine neue Harnessprozess höchstens 60 Sekunden.
Er transportiert Array/Object mit beiden Profilen nach jeder Eingabe bis zum
Profilmaximum und prüft anschließend genau einen weiteren gültigen Eintrag.
Er vergleicht Fallbacks mit dem vollständig materialisierten allgemeinen Codec,
prüft Clone/Merge, COUNT-/PROFILE-Priorität, alle einzelnen Bitänderungen und
Abschneidepositionen des 64-Byte-Runframes sowie neu gehashte ungültige Felder.
Zufällige Callbackreihenfolgen prüfen zusätzlich begrenzte Bitmapframes,
Runlängen, Popcount, Normalisierung und unabhängige Bitmaps nach Clone.
Das sind Offlineprüfungen. Native SQL-Aufrufe und Bereinigungsaudits bleiben
separate Gates; ein verworfener SQL-Aufruf wird dadurch nicht zum PASS.

Der zusätzliche Compiler-/Harnessaufruf wird ausschließlich im bereits gewählten
Framework-Sourcegate ausgeführt. Kein zweiter Planner, Reviewagent, externer
Dienst, neuer Workflow oder flächiger SQL-Wiederholungslauf wird eingeführt.

Der zusätzliche LargeSpan-Teil setzt den höchsten gültigen Testordinal zuerst
und transportiert danach jeden weiteren Prefix innerhalb der maximalen Spanne.
Damit wird die komprimierte Darstellung über die vollständige Entrygrenze
geprüft, ohne eine günstige aufsteigende Callbackreihenfolge vorauszusetzen.
Die Byte-Run-Deskriptoren bleiben dabei live komprimiert; Case-Witness und
Compiler-/IL-/Projektbytebindung bleiben getrennte Prüfungen.
