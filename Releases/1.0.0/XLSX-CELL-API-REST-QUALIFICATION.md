# XLSX: fehlende Typ-/Anzeige-Fixtures auf den unterstützten SQL-Zielen

Stand 2026-11-16: `PASS_FOR_DECLARED_SCOPE`. Die vier unveränderten öffentlichen
Fixtures `Types.Contract.sql`, `Types.Safety.sql`, `Display.Contract.sql` und
`Display.Safety.sql` bestehen auf den acht zuvor nicht vollständig belegten
Engine-/CL-Paaren, jeweils lokal und direkt zentral. Eine getrennte disjunkte
Welle ergänzt ausschließlich Anzeige auf Windows SQL2025/CU8 CL150/160
lokal/zentral und CL170 zentral. Der bereits belegte lokale CL170-Pfad wird
nicht wiederholt. [Maschinenlesbare Originalbindungen](XLSX-CELL-API-REST-QUALIFICATION.json).

| Neue Ausführung | Ziele | Fixture-Ausführungen | Frische Audits |
|---|---|---:|---:|
| Typ und Anzeige | Linux SQL2022/latest CL150/160, SQL2025/latest CL150/160/170; Windows SQL2019/CU32 CL150, SQL2022/CU26 CL150/160; jeweils lokal/zentral | 64 | 8 |
| Nur Anzeige | Windows SQL2025/CU8 CL150/160 lokal/zentral, CL170 ausschließlich zentral | 10 | 3 |

Die Originalfixtures prüfen feste vollständige Werte und Statusprioritäten:
Zahlen-/Temporal-/Bool-Typisierung, Echo-/NULL-Verhalten, endliche Grammatik,
UTF-16 und Eingabelimits sowie zehn Anzeigeformate, drei Kulturen,
Rundung, Kalendergrenzen und begrenzte Ausgabe. Ein erfolgreicher SQL-Aufruf
allein genügt nicht; alle enthaltenen Vergleichs-/Zeilen-/NULL-Orakel müssen
ohne Fehler enden. Dies ist kein neuer Clientmetadaten- oder Workbook-Grenzlauf.

## Paket, Sicherheit und Bereinigung

Verwendet wurde das unveränderte [aktuelle fokussierte XLSX-Paket](XLSX-NATIVE-PACKAGE-QUALIFICATION.md).
Die exakten Paket-SQL-Bytes werden über den bereits qualifizierten SqlClient-
Adapter ausgeführt, die beiden vorhandenen DLLs vor und nach Repeat mit ihrer
tatsächlichen SAFE-Bindung geprüft. Pro neuem Modus eigene Datenbank,
Erst-/Wiederholungsinstallation, neue Sitzung, vier beziehungsweise zwei
Originalfixtures, unveränderte Definitionen und neutraler Callerzustand,
danach Uninstall und UninstallAbsent. Diese Lifecycle-Aufrufe sind notwendiger
Setup-/Abbau des neuen API-Scopes, keine neue vollständige Kollisionsmatrix.

Alle 21 tatsächlich angelegten eigenen Datenbanken wurden entfernt. Elf
separate neue Auditprozesse binden jeweils das exakte finale private Journal
und prüfen DB-Abwesenheit, eigenen Assemblytrust und vollständige relevante
Konfigurationswiederherstellung. Vorbestehende und fremde Zustände bleiben
erhalten. Keine Rechte, Principals, Produkt-SQL-/CLR-Quellen oder Labressourcen
wurden angelegt oder geändert; exakter eigener Assemblytrust und notwendige
CLR-Konfiguration folgen ausschließlich dem bestehenden Entwicklungsvertrag.
Rohjournale, Verbindungsdaten und tatsächliche Instanzwerte bleiben privat.

## Endliche Wellen und Fehlerwahrheit

Die erste Welle ist mit 16 von höchstens 20 Lauf-/Auditaufrufen und 16
DB-Reservierungen geschlossen. Ihr erster Controlleraufruf stoppte vor jedem
Dispatch an einem doppelt vorbereiteten `completed_keys`-Feld. Dieser Fehler
und der ursprüngliche Budgetinput bleiben erhalten. Die private Initialisierung
wurde korrigiert; es gab keinen fehlgeschlagenen nativen Datenfall und keine
SQL-Wiederholung. Die acht folgenden Gesamtläufe und Audits bestanden.

Erst danach erhielt die disjunkte Windows-Anzeigewelle einen separaten Rahmen
von sechs Aufrufen und sechs DB-Reservierungen. Alle sechs Aufrufe wurden
verbraucht; fünf DBs tatsächlich angelegt und entfernt. Beide ursprünglichen
60-Minuten-Fenster wurden eingehalten und bleiben geschlossen. Ungenutzte
Reserve der ersten Welle wurde weder übertragen noch als neue Autorität benutzt.
Beide ausgeführten Methodenversionen bleiben mit ihren ursprünglichen
Git-Quellen gebunden; spätere Adapterpflege schreibt diese Ausführung nicht um.

## Was damit nicht mehr offen ist

Die oben konkret benannten fehlenden Typ-/Anzeige-Fixtures sind belegt.
Ältere pauschale Ziel-/Format- oder Minimalrechte-Offenzeilen sind keine neue
Testwarteschlange: Die getrennten [Zell-SELECT-Profile](XLSX-CELL-CALLER-QUALIFICATION.md)
und [Raw-Callerprofile](XLSX-RAW-CALLER-PROFILE.md) behalten ihren exakten Umfang.
Diese Welle vergibt keine Rechte und macht aus den früheren Einzelwertproben
keine neue vollständige Rechte-/Formatkombination. Auch die acht
[Vollgrößenfälle und Paketpflege](XLSX-NATIVE-PACKAGE-QUALIFICATION.md) bleiben
geschlossen; ihre grünen Workbookaufrufe wurden nicht wiederholt.

Genuine Upgrades und Consumerkomposition, vollständige Kollisions-/Owner-/
Visibilityprofile, andere Identitäten, Clientmetadaten, Peak-Heap und
Produktionskapazität bleiben eigene Nachweise. Functional mit dem expliziten
Labtrust ist keine authentifizierte TLS-Abnahme. Kein Gesamtmodul-PASS,
Statuswechsel, Veröffentlichung oder Tag. Modul bleibt teilweise validiert
und unveröffentlicht. Der [aktuelle Restabgleich](CURRENT-QUALIFICATION-REST.md)
trennt diese Grenzen von historischen Offen-Einträgen.

Reproduzierbare reine Integritätsprüfung ohne SQL:

```text
python Scripts/Release/validate_xlsx_cell_api_rest.py
```
