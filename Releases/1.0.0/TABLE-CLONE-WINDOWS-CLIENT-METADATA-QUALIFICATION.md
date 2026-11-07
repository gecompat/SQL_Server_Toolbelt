# Table Clone 4.1.1: Windows-Client-Metadaten

Am 2026-11-07 bestand der kanonische direkte Clientreader des aktuellen
Table-Clone-Vertrags auf zwölf Engine-/CL-Paaren lokal und direkt zentral:
**zwölf Gesamtfälle, 24 Kontexte, 24 vollständige Clientfixture-Ausführungen
und zwölf frische unabhängige Audits**. Alle 24 eigenen Datenbanken sind
entfernt. Ergebnis: **PASS_FOR_DECLARED_WINDOWS_CLIENT_METADATA_SCOPE**.

| Ausgewähltes SQL-Ziel | Compatibility Levels | Modi | Kontexte |
|---|---|---|---:|
| Windows 2019/CU32 | 150 | lokal/direkt zentral | 2 |
| Windows 2022/CU26 | 150, 160 | lokal/direkt zentral | 4 |
| Windows 2025/CU8 | 150, 160, 170 | lokal/direkt zentral | 6 |
| Linux 2019/latest | 150 | lokal/direkt zentral | 2 |
| Linux 2022/latest | 150, 160 | lokal/direkt zentral | 4 |
| Linux 2025/latest | 150, 160, 170 | lokal/direkt zentral | 6 |

Die Prüfprozesse liefen auf einem **Windows-Clienthost** mit dem vorhandenen
System.Data.SqlClient und der bestehenden administrativen SQL-Lab-Anmeldung.
Linux in dieser Tabelle bezeichnet das SQL-Ziel und qualifiziert keinen
Linux-Clientprozess. Direkt zentral bedeutet Nutzung der Installationsdatenbank;
keine neue Netzwerk-/CrossDB-Identität oder Windows-/SSMS-Anmeldeabnahme.

## Konkrete veraltete Erwartung

Die bisherige [kanonische Clientfixture](../../Modules/toolbelt.metadata.table-clone/Tests/Runtime/SelectMetadata.Contract.ps1)
erwartete zwölf Help-Parameter. Der aktuelle öffentliche Planner besitzt
dreizehn Parameter und liefert dieselben dreizehn kanonischen Help-Zeilen.
Die Korrektur ändert ausschließlich diese eine Zahl im Testorakel. Keine
Produkt-SQL-, API-, Provider-, Schema-, Rechte- oder Quotenänderung.

Der [Methodenstand `8a8b8883`](https://github.com/gecompat/SQL_Server_Toolbelt/commit/8a8b88835291a00f62eb12fb109c8fb5bc4d4b68)
bindet den korrigierten Reader und den engen
[Clienttreiber](../../Tests/Release/Invoke-TableCloneClientLab.ps1).
Eine neue Admission-Gegenprobe weist die ursprüngliche Zwölf-Erwartung vor
jedem SQL-Zugriff ab und akzeptiert die aktuelle Dreizehn-Erwartung anhand
der tatsächlichen kanonischen Parameterordinale. Der ursprüngliche
verbindungslose Befund und seine Gegenprobe bleiben privat erhalten.

Der bestehende normale Linux-CI-Treiber ruft diesen PowerShell-Reader nur
unter `TBX_SQL_TARGET=lab` auf. Sein Runner-Pfad führte ihn nicht aus.
Frühere grüne Runner-CI wird deshalb nicht als aktueller direkter
Clientnachweis verwendet. Diese neue physische Matrix hat ihre eigenen
Zielbindungen, tatsächlichen Readeraufrufe und Abschlussaudits.

## Tatsächlich ausgeführte Fixture

Pro Kontext wurde die korrigierte kanonische Fixture vollständig und genau
einmal in einer eigenen Clientverbindung ausgeführt. Ihre vorhandenen
Orakel prüfen insbesondere:

- `GetSchemaTable`, vier exakte Plannamen/-typen, Längen und NOT-NULL-Metadaten;
- acht geordnete Planzeilen mit sieben festen SET-Zeilen und einer TABLE-Zeile,
  ein einziges Resultset und korrektes Reader-Ende;
- zwölf Help-Spalten, dreizehn Parameterzeilen, erforderliche Help-Sektionen,
  frühes Help-Bypass-Verhalten und keine Help-InfoMessages;
- ResultTable-Routing ohne zusätzliches SELECT-Resultset;
- die exakten frühen Caller-Transaktionsguards aus Deploy und Uninstall,
  jeweils mit beiden XACT_ABORT-Modi, unverändertem Marker, Tempdaten und
  gesundem Callerzustand.

24 zählt vollständige Clientfixture-Ausführungen, keine Zahl einzelner
Assertions. Die vier Guardfragmentprüfungen je Kontext sind **keine vollständige
SQLCMD-Include-/Batchabbruchprobe** und kein genuiner Upgrade-/Uninstalllauf.
Diese weitergehenden Lifecycle-Pflichten bleiben getrennt.

Nur ResultTable 1.0.0 und Table Clone 4.1.1 wurden aus den kanonischen
Exports installiert. Tatsächliches CL, Ziel-Major/-Plattform/-Softwareversion,
beide Modulversionen und Modi sowie das Fehlen von Benutzerassemblies werden
geprüft. Jede Sitzung ist anschließend transaktionsneutral, die installierten
Produktdefinitionen bleiben identisch. Alle eigenen Clientumgebungsvariablen
werden ausschließlich im Prozess verwendet und danach exakt wiederhergestellt;
der Nachweis speichert nur das Ergebnis dieser Wiederherstellungsprüfung.

## Quellen, Grenzen und frische Audits

Die Quellen des kanonischen Readers, der Fassade, des Lifecycle, der TLS-,
Deployment- und Transporthelfer sowie Labvertrag, Schema, Prompt und Hostexecutable
sind gepinnt. Credentials und Connection Strings bleiben im Prozess;
keine Übergabe als Kommandoargument, kein Schreiben oder Protokollieren.
Ein unerwarteter qualifizierter TLS-Prozesskontext blockiert die Admission,
statt die verlangte Transportbindung zu verbergen oder herabzusetzen.
Der vorhandene Transporthelper übernimmt den expliziten Functional-Trustwert.
Die Prüfung ist keine authentifizierte TLS-Abnahme.

Vor erster SQL-Zulassung galten gemeinsam **28 Ziel-/Auditaufrufe,
28 eigene DB-Reservierungen und 60 Minuten**. Tatsächlich benötigt wurden
**24 Aufrufe und 24 Reservierungen**, ohne Korrektur oder native Wiederholung.
Alle ungenutzten Plätze sind geschlossen. Producer und Audit besitzen
jeweils eine eigene Prozessgrenze von 400 Sekunden und getrennte
4-MiB-Kanäle; vor weiterer Zulassung bleiben 15 Minuten Reserve.

Jeder frische separate Audit bindet den exakten finalen Originaljournalhash,
Abwesenheit der eigenen DBs, tatsächliches Ziel, alle Inputpins und den
vollständigen ursprünglichen Konfigurations-/Trustzustand. Der unabhängige
Nachprüfer bestätigt alle zwölf Gesamtfälle, 24 Kontexte, 24 vollständige
Readerabschlüsse und zwölf Audits. Alle 24 tatsächlich angelegten eigenen
Datenbanken sind entfernt. Keine Rechte, Benutzer, Assemblies, Serveroptionen,
Trusteinträge oder Lab-Infrastruktur wurden geändert.

Elf öffentliche verbindungslose Admission-/Scope-/Metadaten-/TLS-Pin-Gegenproben
bestanden vor Native-Zulassung. Sie verwenden bereits den ausdrücklich
UTF-8-gebundenen PowerShell-Ausgabe-/Python-Lesetransport aus dem vorherigen
Paket. Keine Wiederholung der dort erhaltenen Codepagefehler. Die dazugehörigen
Transportkommentare sind ohne Verhaltensänderung auf Deutsch gepflegt.

## Wiederverwendung und getrennte Restpunkte

Produkt-SQL und die Original-SQL-Fixtures sind unverändert. Die gültigen
[Copy-](TABLE-CLONE-COPY-TARGET-QUALIFICATION.md),
[Planner-/Executor-](TABLE-CLONE-PLANNER-EXECUTOR-QUALIFICATION.md),
[W1-/W2-](TABLE-CLONE-W1-W2-QUALIFICATION.md) und
[aktuellen Trigger-Nachweise](TABLE-CLONE-TRIGGER-CURRENT-QUALIFICATION.md)
bleiben erhalten; ihre bereits grünen nativen Fachmatrizen wurden nicht
erneut ausgeführt. Historische Clientstände werden nicht zum aktuellen
Reader-PASS aufgewertet.

Echte zusätzliche Minimalrechte, Linux-Clienthost, weitere Provider-/CrossDB-
Identitäten, vollständiger SQLCMD-Abbruch, genuine aktuelle Upgrade-/Uninstall-
und Recoveryfälle sowie die Modulgesamtfreigabe bleiben getrennt. Private
Originaljournale, Rohlogs, tatsächliche Runtimewerte und Identitäten bleiben
außerhalb Git erhalten. Modulstatus weiterhin teilweise validiert und
unveröffentlicht. Keine Veröffentlichung oder Tags.
