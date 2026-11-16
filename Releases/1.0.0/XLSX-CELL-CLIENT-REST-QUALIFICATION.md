# XLSX: fehlende native Typ-/Anzeige-Clientmetadaten

Stand 2026-11-16: `PASS_FOR_DECLARED_SCOPE`. Die unveränderten öffentlichen
`Types.Metadata.ps1` und `Display.Metadata.ps1` bestehen im Windows-SqlClient-
Prozess gegen acht zusätzliche Windows-/Linux-Engine-/CL-Paare lokal/direkt
zentral. Auf Windows SQL2025/CU8 werden nur die zuvor nicht belegten
Anzeigeprofile CL150/160 lokal/zentral und CL170 zentral ergänzt.
[Originalquellen und bereinigte Ergebnisse](XLSX-CELL-CLIENT-REST-QUALIFICATION.json).

| Neue Ausführung | Helferaufrufe | Geprüfte Readerfälle |
|---|---:|---:|
| Linux SQL2022/latest CL150/160 und SQL2025/latest CL150/160/170; Windows SQL2019/CU32 CL150 und SQL2022/CU26 CL150/160; beide APIs lokal/zentral | 32 | 80 |
| Windows SQL2025/CU8: nur Anzeige CL150/160 lokal/zentral und CL170 zentral | 5 | 15 |

Die Typprüfung verlangt alle 14 Spaltennamen und SQL-Datentypen, genau eine
Default-NULL-Zeile sowie den exakten `SqlDecimal`-Wert 1e-38 mit Precision/Scale38
und allen vier Datenwörtern. Anzeige prüft zwei Spalten, Default-NULL und Status,
einen Zahlenfall sowie vollständige `SqlChars`-Länge32733. Jeder Reader muss
ohne weitere Zeile oder Zusatzresultset enden. Katalog-Nullability wird dadurch
ausdrücklich nicht qualifiziert. Frühere grüne Typ-/Anzeige-Clientprofile auf
den ausgewählten alten Zielen wurden nicht wiederholt.

## Ein korrigierter Testadapterfall, keine Produktkorrektur

Der erste native Versuch bleibt `FAILED_CLEANED`: Der dynamische Timeoutcallback
verlor im separat aufgerufenen Metadatenskript den `$script:`-Kontext. Er endete
vor dem ersten vollständigen Metadatenprofil. Seine eine Datenbank wurde entfernt,
der unmittelbar reservierte separate Audit bestand und bindet sein finales Journal.
Originalquellen, Fehler und zwei verbrauchte Aufrufe bleiben erhalten.

Der korrigierte Adapter bestimmt die kanonische Restzeit vor dem Kindskript und
bindet sie mit der vorhandenen monotonen Stopwatch in abgeschlossenen Callbacks.
Das auf höchstens45Sekunden begrenzte Helferfenster darf weder pro Command noch
pro Read neu starten; das gemeinsame ursprüngliche Arbeitsbudget bleibt zusätzlich
wirksam. Bei Ablauf wird der Readercommand abgebrochen. Eine echte SQL-freie
Gegenprobe startet den Callback in einem frischen Kind-Skriptscope mit absichtlich
fehlenden Scriptvariablen. Eine zweite prüft Ablauf und Cancel; echte aus dem
Adapter gelesene Selektorausdrücke prüfen drei disjunkte Kontextprofile.

Der einzelne vorab eingeplante Korrekturfall wurde innerhalb des unveränderten
24-Aufrufe-/24-DB-Reservierungen-/60-Minuten-Rahmens ausgeführt. Elf korrigierte
Gesamtläufe und ihre elf separaten frischen Abschlussaudits bestanden. Insgesamt
24 Aufrufe einschließlich ursprünglichem Fehleraudit, 22 tatsächlich angelegte
und entfernte eigene Datenbanken; alle Plätze und das ursprüngliche Zeitfenster
sind geschlossen. Kein weiteres SQL und keine neue Wiederholung dieser Welle.

## Wiederverwendung und tatsächliche Grenzen

Verwendet wurden dieselben unveränderten DLLs und das aktuelle
[fokussierte XLSX-Paket](XLSX-NATIVE-PACKAGE-QUALIFICATION.md). Beide SAFE-Bindungen,
Engine/Windows-CU/CL, Erst-/Repeatinstallation und neutraler Caller werden vor
den neuen Prüfungen bestätigt. Danach folgen unveränderte Definitionen,
Uninstall/UninstallAbsent und eigene DB-/Trust-/Konfigurationsbereinigung.
Jeder Audit bindet das finale Journal und prüft frisch die Abwesenheit und
Wiederherstellung eigener Zustände. Fremde und vorbestehende Verbraucher bleiben
erhalten. Keine Produkt-SQL-/CLR-, Rechte-, Principal- oder Labänderungen.

Die [neuen SQL-Zellfixtures](XLSX-CELL-API-REST-QUALIFICATION.md),
Raw-/Zell-Callerrechte, SST- und Vollgrößengrenzen werden in ihren getrennten
Umfängen wiederverwendet und nicht erneut ausgeführt. Gegen Windows und Linux
getestete SQL-Engines sind kein externer Linux-Clienthost. Es gibt keine neue
CrossDB-Login-, Katalognullability-, genuine Upgrade-, Heap-/Kapazitäts-,
authentifizierte TLS- oder Gesamtmodulqualifikation. Teilweise validiert und
unveröffentlicht; keine Veröffentlichung oder Tags.

Reproduzierbare Integritätsprüfung ohne SQL:

```text
python Scripts/Release/validate_xlsx_cell_client_rest.py
```
