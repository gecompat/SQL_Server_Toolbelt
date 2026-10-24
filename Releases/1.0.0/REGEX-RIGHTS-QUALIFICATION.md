# Regex-Skalarfunktionen mit minimalen Datenbankrechten aufrufen

Stand 2026-10-24. Alle sechs öffentlichen Regex-Skalarfunktionen benötigen
`EXECUTE` auf der jeweiligen Funktion. Die drei T-SQL-Fassaden verwenden
ihre internen CLR-Kerne über die bestehende Ownership Chain; der Fachcaller
erhält keine direkten Coregrants. Für die öffentlichen Regex-TVFs gilt
weiterhin `SELECT`.

Die Administration kann einem bereits vorhandenen Datenbankkonto gezielt
beispielsweise dieses Recht erteilen:

```sql
GRANT EXECUTE ON OBJECT::toolbelt_string.SVF_RegexReplaceGroups TO ContosoCaller;
```

`ContosoCaller` ist ein Platzhalter für ein vorhandenes freigegebenes Konto.
Die Modulinstallation legt keine solchen Konten an und vergibt keine
automatischen Fachcallerrechte. Die Korrektur betrifft die bisher falschen
Rechteangaben in Manifest, Objektseiten und SQL-Headern. Öffentliche APIs,
Parameter, Rückgaben, CLR-Code und Sicherheitsbudgets ändern sich nicht.

## Tatsächlich geprüfter Umfang

Der bestehende API-Harness führte
`Tests/Release/Runtime/Regex.Scalar.Rights.sql` in eigenen temporären
Datenbanken aus. Ein eigener Benutzer ohne Login erhielt ausschließlich
die jeweils geprüften Objektgrants. Es wurden keine Rollen- oder Schemagrants,
Server- oder Loginrechte und keine Grants auf interne CLR-Kerne vergeben.

| Phase | Erwarteter und beobachteter Zustand |
|---|---|
| Keine Grants | Alle sechs öffentlichen Aufrufe werden mit SQL229 abgewiesen. |
| Nur REFERENCES | Alle sechs öffentlichen Aufrufe werden weiterhin mit SQL229 abgewiesen. |
| REFERENCES entzogen, EXECUTE erteilt | Alle sechs Funktionen liefern ihre festen Wert-/Byteorakel; die effektiven REFERENCES-Rechte sind 0. |
| EXECUTE entzogen | Die sechs öffentlichen Aufrufe werden wieder mit SQL229 abgewiesen. |

Direkte Aufrufe der drei internen Skalar-Kerne werden in allen vier Phasen
mit SQL229 abgewiesen. Die Matrix umfasst Windows und Linux, SQL2019 CL150,
SQL2022 CL150/160 und SQL2025 CL150/160/170: zwölf tatsächliche Fälle,
jeweils lokal und im direkt geöffneten zentralen Datenbankkontext. Insgesamt
wurden 144 feste Wertorakel und 720 strikte Rechteabweisungen ausgeführt.

Zwei bewusst fehlerhafte Testvarianten prüfen die Orakel selbst: ein falscher
Erwartungswert und zusätzlich behaltene REFERENCES-Rechte müssen scheitern.
Beide wurden mit SQL52094 abgewiesen und vollständig bereinigt. Sie zählen
nicht als erfolgreiche Funktionsfälle. Der anschließende unabhängige Audit
bestätigte Cleanup und Inputpins aller vierzehn Fälle sowie die Wiederherstellung
der drei temporären CLR-Konfigurationsscopes.

Die [maschinenlesbare Projektion](regex-scalar-rights-qualification.json)
bindet die sechs APIs, Quellen, Fälle, Grenzen und tatsächlichen Ergebnisse.
Der eigene Nutzer wird nach jedem Fixture entfernt; die Datenbank- und
Trustbereinigung prüft der vorhandene Harness unabhängig. Journale,
Labidentitäten und Rohlogs bleiben lokal.

## Historische Nachweise und neue Paketbasis

Die alte Rechtebeschreibung wird korrigiert, historische Ausführungsberichte
bleiben erhalten. Der [gebundene Quellvergleich](runtime-source-equivalence.json)
erlaubt ausschließlich die bekannte Dokumentationskorrektur: fünf exakt
festgelegte SQL-Headerkommentare, die Rechtebeschreibung und den begrenzten
Manifestnachtrag sowie die zugehörigen Markdown-Seiten. Alle ausführbaren
SQL-, CLR-, Deployment- und Workerquellen bleiben erhalten. Ein Versions-,
Objekt-, Dependency- oder sonstiger Codewechsel wird abgewiesen.

Beide Produktbäume lassen sich über den öffentlichen Main-Vorstand und die
mitgelieferten Quellbundles unabhängig rekonstruieren. Der bestehende
Release-Test prüft die konkreten Änderungen erneut statt eine pauschale
Anwendbarkeit zu behaupten. Der erneute Doppelbuild aller zwölf Projekte
liefert identische Binaries. Die neu erzeugten rohen Paket-SQL-Dateien erhalten
ihren eigenen nativen Paketnachweis; grüne ältere Paketläufe werden nicht
nachträglich als Ausführung der neuen Dateien bezeichnet.

## Weitere Grenzen

Ein Benutzer ohne Login im direkt geöffneten zentralen Datenbankkontext ist
kein Nachweis einer getrennten Loginidentität mit CrossDB-Nutzermapping.
Dieser Scope sowie weitere Ressourcen-, Parallelitäts-, Host-Recovery- und
Clientfälle bleiben separat. Der Bericht erweitert keine Modul-, Provider-
oder Supportfreigabe. [Releasegates](RELEASE-GATES.md), unveröffentlichter
Status und separate Veröffentlichungsfreigabe bleiben bestehen.
