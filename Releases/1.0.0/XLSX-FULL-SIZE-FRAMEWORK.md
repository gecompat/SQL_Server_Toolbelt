# XLSX-Grenzworkbooks in Originalgröße

Am 2026-11-16 bestanden acht synthetische Grenzworkbooks gegen die unveränderten
DLLs des [qualifizierten SST-Quellkandidaten](XLSX-SST-BUDGET-CORRECTION.md).
Die [Evidenz](XLSX-FULL-SIZE-FRAMEWORK.json) bindet Quellen, DLLs, ursprüngliche
Berichte und die vollständigen Fixturebytes. Es gab keinen Produktbuild,
keine Paketänderung und keinen SQL-/Labzugriff.

| Grenze | Positiver Fall | Abweisung | Geprüfter Pfad |
|---|---|---|---|
| Archiv | genau 16 MiB | 16 MiB + 1 Byte | vollständiges gespeichertes ZIP, eine gelesene Zelle |
| Einzelpart | genau 16 MiB | 16 MiB + 1 Byte | selektiertes Worksheet, tatsächlich entpackt, CRC-geprüft und als XML gelesen |
| Summe | genau 64 MiB | 64 MiB + 1 Byte | Archivindex einschließlich vier unselektierter Zusatzparts |
| Partanzahl | genau 256 | 257 | vollständige kanonische OPC-Archive, eine gelesene Zelle |

Jeder positive Fall liefert genau `A1 = 42`. Die vier Fehlerfälle prüfen zuerst
die konkrete technische ZIP-Kategorie am Readerkern und danach den öffentlichen
Status-TVF-Einstieg `ReadCells` samt `FillCells`. Dort erscheint genau eine
Statuszeile mit Fehlernummer 51520 und ausschließlich NULL-Nutzdatenfeldern:
`TBX_XLSX_ARCHIVE_LIMIT` für die Archivüberschreitung, andernfalls vertragsgemäß
`TBX_XLSX_CONTAINER_INVALID`. Kein partielles Zellergebnis wird als Erfolg gezählt.
Alle öffentlichen Größen-, Ratio-, Allokations- und Zeitlimits bleiben unverändert.

Die Python-Komposition erzeugt echte Payloads und reguläre ZIP-Strukturen; sie
verändert keine Längen- oder CRC-Deklaration nachträglich. Ein unabhängiger
Standard-ZIP-Reader entpackt jeden Part vollständig, vergleicht seine Bytes und
prüft CRC, Ratio sowie alle jeweils nicht überschrittenen Grenzen. Der
64-MiB-Fall belegt die Archivsumme, keine vollständige Materialisierung dieser
vier Zusatzparts im XLSX-Reader und keinen gemessenen Speicherpeak.

## Wiederholen und Ergebnis prüfen

Voraussetzungen sind Windows, PowerShell 7, Python und eine vorhandene
.NET-Framework-4.8-Compiler-/Referenztoolchain. Im Repositoryroot:

```powershell
./Tests/Release/Invoke-XlsxFullSizeFramework.ps1 -OutputDirectory .runtime/xlsx-full-size-check
python -B -m unittest discover -s Tests/Release -p test_xlsx_full_size_framework.py
```

Das Ausgabeziel muss neu sein. Der Runner prüft den bestehenden Kandidaten und
die aktuellen Produktquellen, kompiliert ausschließlich den separaten Harness
und bindet die DLL-/Fixturebytes vor und nach der Ausführung. Compiler und
Unterprozesse haben eigene endliche Grenzen; der Runner ist auf zehn Minuten
begrenzt. `PASS XLSX FULL SIZE FRAMEWORK 8` bestätigt genau die acht Fälle.
Private Originalkanäle, Toolpins und Prozessbelege bleiben im Ausgabeziel.
Bei Abweichung bleibt der Lauf fehlgeschlagen; bestehende Ergebnisse werden
nicht überschrieben. Vor dem erfolgreichen Lauf scheiterten einmal die lokale
Python-Auswahl und einmal die Harnesskompilierung. Beide Befunde bleiben privat
erhalten und werden in der Evidenz getrennt gezählt; kein Produktfehler wurde
daraus abgeleitet.

## Geltungsbereich und verbleibende Lücken

Dies ist Framework-4.8-Evidenz für den Readerkern und den tatsächlichen
öffentlichen CLR-Status-TVF-Einstieg. Die sechs Offlineprüfungen sichern
Quellen-/DLL-Bindung, vollständige feste Grenzpaare und die Abweisung unzulässiger
Aufwertungen; die bestehende Dokumentations-CI führt sie ebenfalls aus.
SQL-Hosting, Deployment, Minimalrechte, authentifiziertes TLS, Peak-RAM und
Produktionskapazität wurden in dieser Welle nicht geprüft. Insbesondere ersetzt
dies keine native SQL-Matrix dieser acht Workbooks.

Die bereits bestandene native 32/33-Blattmatrix und die native
50.000/50.001-SST-Matrix wurden nicht wiederholt. Die SST-Korrektur gilt weiterhin
für ihren separaten Kandidaten, nicht für die ältere DLL im Installationspaket.
Historische Nachweise bleiben unverändert. Paketpflege und erforderliche
Nachweise für neue Paketbytes bleiben eigene Releasegates. Modulstatus bleibt
`partially validated`, Releasezustand `unreleased`; keine Veröffentlichung oder Tags.

Die quellengebundene historische Testmatrix bleibt ebenfalls bytegleich.
Ihre alte Sammelzeile „Vollgröße übriger Caps: not executed“ ist durch diesen
Bericht und die beiden nativen Blatt-/SST-Berichte differenziert ersetzt;
der aktuelle Einstieg steht im [Modul-README](../../Modules/toolbelt.file.xlsx-memory/README.md#vertrag-und-grenzen).
