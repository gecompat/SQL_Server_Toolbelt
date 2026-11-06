# JSON-Constructor: Caller auf Linux-SQL-Zielen

Am 2026-11-06 bestanden die vier vorhandenen Constructor-USPs unter einem
synthetischen Datenbankbenutzer ohne Login auf Linux SQL2019/latest CL150,
SQL2022/latest CL150/160 und SQL2025/latest CL150/160/170, jeweils lokal und
direkt zentral. Das sind zwölf Kontexte,144 positive API-/Routenprofile und
144 erwartete SQL229-Abweisungen. Sechs Gesamtläufe und sechs frische separate
Abschlussaudits bestanden. Ergebnis: **PASS_FOR_DECLARED_SCOPE**.

Die Verbindung entstand über den vorhandenen Windows-Prüfhost; Linux bezeichnet
die geprüfte SQL-Server-Plattform, keinen neu qualifizierten Linux-Clienthost.
Die vorhandene administrative Lab-Anmeldung führt EXECUTE AS USER aus;
Netzwerklogin und tatsächliches CrossDB-Identitätsmapping sind nicht geprüft.

## Wiederverwendeter Vertrag und neue Methode

Das [Windows-Callerprofil](JSON-CONSTRUCTORS-CALLER-QUALIFICATION.md) und seine
historischen Originale bleiben unverändert. Wiederverwendet werden genau die
bereits ausdrücklich freigegebenen sechs Objektrechte: vier öffentliche
USP-EXECUTE-Grants sowie VIEW DEFINITION und EXECUTE auf dem ResultTable-Helper.
Kein Login und keine Rollen-, Schema-, Datenbank- oder Serverrechte werden
vergeben; bestehende Identitäten bleiben unverändert. Der Testbenutzer und
seine Temp-Tabellen gehören ausschließlich zum eigenen markierten DB-Scope.
Das erlaubte Profil behauptet nicht die Notwendigkeit jedes Grants auf jedem Pfad.

Der [Treiber](../../Tests/Release/Invoke-JsonConstructorsCallerLab.ps1) verlangt
`-Platform linux` und sechs exakt geordnete latest-Kontexte. Default bleibt
das getrennte Windows-CU-Profil. Plattformmischung, Patchausweichwahl und Drift
eines späteren Runsetkontexts werden vor Labimport/SQL abgewiesen. Der private
Runset bindet die frische schema-validierte Lab-Auswahl und tatsächliche Bytes
der Methoden, unveränderten kanonischen Exporte und zwei bekannten SAFE-DLLs.
Es wurde kein neuer Produktbuild erzeugt.

Ausgeführte Methode:
[`d3fcaacc`](https://github.com/gecompat/SQL_Server_Toolbelt/commit/d3fcaacc37a8875e2d29225393983bec9fd09013).
Die SQL-Rechte-/Wert-/Metadaten-/Sitzungsorakel sind gegenüber der erfolgreichen
korrigierten Windows-Methode unverändert. Geprüft sind beide Directresult-
Rechteprofile, ResultTable im sechsrechtigen Profil, feste binäre JSON-Werte,
einfache/gruppierte ResultTable-Spalten, interne Abweisungen und gezielte
öffentliche EXECUTE-Widerrufe. Der neutrale Sitzungszustand wird separat vom
Katalogzugriff und nochmals durch einen eigenen Clientaufruf beobachtet.

## Abschluss und Grenzen

Ein neuer endlicher Rahmen wurde unter dem fortbestehenden autonomen Auftrag
erst nach erfolgreicher tatsächlicher Main-CI von PR530 zugelassen. Er umfasste
zwölf Ziel-/Auditaufrufe, zwölf eigene DBs und45 Minuten ohne Wiederholung.
Alle12/12 Aufrufe und12/12 DBs sind innerhalb der unveränderten Originalfrist
geschlossen, ohne Fehlversuch. Jede eigene DB ist entfernt; der protokollierte
eigene Trust-/CLR-Konfigurationsumfang ist wiederhergestellt. Der neue
Auditprozess verwendet eine neue Verbindung und bindet den unveränderten
finalen Originaljournalhash. Methodenpins wurden nachgeprüft.

Zwölf tatsächliche Offlinegegenproben bestehen, einschließlich gültigem Linux-
Profil, gemischten späteren Plattform-/Patchkontexten und exakt45-minütiger,
aber bereits abgelaufener Frist. Die zehn bestehenden Testmethoden bleiben
erhalten; zwei weitere ergänzen den Linuxprofilumfang im vorhandenen Runner.
Kein neuer Workflowjob oder zusätzlicher Reviewagent. Die nativen grünen
Windows-Fälle wurden nicht wiederholt und ihre18 geschlossenen Aufrufe sowie
drei ursprünglichen FAILED_CLEANED bleiben unverändert.

Functional übernimmt Verschlüsselung und den expliziten Trustwert des
Labvertrags; keine authentifizierte TLS-Abnahme. Aggregate, direkte
Clientmetadaten, andere Owner, echte CrossDB-Identitäten, weitere Datei-/
Host-/Recovery- und Kapazitätsverträge sowie vollständige Modul-/Releaseabnahme
bleiben separat. Modulstatus bleibt teilweise validiert und unveröffentlicht.
Private Runsets, Journale und Rohlogs bleiben außerhalb Git; keine
Veröffentlichung oder Tags.
