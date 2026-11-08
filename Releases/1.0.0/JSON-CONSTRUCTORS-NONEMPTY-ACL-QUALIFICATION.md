# Constructor-Upgrade mit nichtleeren USP-Berechtigungen

Stand 2026-11-08: **NATIVE_NOT_QUALIFIED**. Auch die erneut ausdrücklich
freigegebene Welle stoppte vor Testbenutzer und Rechtevergabe; ihr separater
frischer Abschlussaudit bestand. Die Sitzungsbeobachtung des Testadapters
ist korrigiert und verbindungslos geprüft, nativ noch nicht bestätigt.
Beide fehlgeschlagenen Originalfälle bleiben `FAILED_CLEANED`.
Bestehende grüne API-, Caller- und Migrationsnachweise behalten ihren Scope.

## Konkreter Prüfumfang

Der [Testtreiber](../../Tests/Release/Invoke-JsonConstructorsAclLab.ps1) und
das [enge Profil](../../Tests/Release/JsonConstructors.AclUpgrade.ps1) sollen
die echte bekannte Constructor-Version 1.2.0 auf den aktuellen Vertrag 1.3.0
heben. Windows SQL 2019/CU32, 2022/CU26, 2025/CU8 und Linux SQL
2019/2022/2025 werden über alle unterstützten Compatibility Levels jeweils
lokal und direkt zentral ausgewählt: zwölf Engine-/CL-Paare, 24 Kontexte.
Direkt zentral ist SameDB-Nutzung; Clienthost ist Windows.

Die [synthetische Fixture](../../Tests/Release/Runtime/JsonConstructors.AclSetup.sql)
verwendet ausschließlich die bereits einzeln genehmigten vier Objektgrants:
EXECUTE auf `USP_JsonArray`, `USP_JsonObject`, `USP_JsonArraysByGroup` und
`USP_JsonObjectsByGroup`. Der eigene Benutzer `ContosoJsonCaller` wird ohne
Login ausschließlich in der eigenen temporären Datenbank angelegt.
Zusätzliche Helper-, Schema-, Assembly-, Server- oder Ownerrechte gehören
nicht zum Profil.

Verglichen werden fünf Prozeduridentitäten einschließlich expliziter und
effektiver Owner, die vollständigen vier Berechtigungstupel einschließlich
Grantor und die Identität des Testbenutzers mit SID und Erstellungszeit.
Der gleiche Bestand muss nach einem kontrollierten Fehler nach dem eigenen
CLR-DROP, nach dem echten Upgrade und nach einem Wiederholungsdeploy erhalten
sein. Ein leerer, teilweiser oder zusätzlicher ACL-Bestand zählt nicht als
Nachweis. Vollständige Vor-/Nach-Tupel bleiben privat; der öffentliche Bericht
enthält ausschließlich Prüfumfang und aggregierte Ergebnisse.

Die vier eigenen Grants werden widerrufen und der eigene Benutzer entfernt.
Danach folgt die identitätsgebundene Datenbankbereinigung, keine zusätzliche
Uninstall-Qualifikation. Keine erneute große API-/Quoten-/Schema-Consumer-Matrix.

## Erster nativer Versuch und unveränderter Fehler

Ausgeführter Methodensnapshot:
[`1912778f`](https://github.com/gecompat/SQL_Server_Toolbelt/commit/1912778ff08c5c1a719684b2a50eb7ce379e83b4).
Der vorbereitete Rahmen enthielt zwölf Läufe mit zwölf reservierten Audits,
maximal 24 Ziel-/Auditaufrufe, 24 eigene DB-Reservierungen und 45 Minuten;
keine Wiederholung. Bereits der erste Lauf stoppte vor der Rechtevergabe.

Der private Testadapter hatte nur den JSON-Core exportiert. Dessen Manifest
hat keine ResultTable-Abhängigkeit; die zusätzlich benötigte ResultTable
wurde deshalb nicht implizit mitinstalliert. Der echte historische Constructor
wies die fehlende registrierte Dependency ab. Das ist ein Testadapterfehler
und kein Nachweis einer fehlerhaften Produktmigration.

Verbraucht sind zwei Ziel-/Auditaufrufe und zwei DB-Reservierungen; tatsächlich
wurde eine eigene Datenbank angelegt und wieder entfernt. Keine Testidentität,
keiner der vier Objektgrants und kein bestandener ACL-Gesamtfall. Der frische
unabhängige Audit bestätigt DB-Abwesenheit, wiederhergestellte Konfiguration
und Trust, unveränderte Pins und den exakten finalen Originaljournalhash.
Sein Cleanup-PASS wertet `FAILED_CLEANED` ausdrücklich nicht zum Gesamt-PASS auf.
Die Welle und ihre unbenutzten Restplätze bleiben geschlossen.

## Abhängigkeitskorrektur und Gegenproben vom 2026-11-07

Der korrigierte Adapter exportiert ausdrücklich **ResultTable und Core**.
Vor Labimport oder SQL verlangt der Treiber beide kanonischen Modulabschnitte
in dieser Reihenfolge, aufgelöste Direktiven und genau einen kontrollierten
Rollback-Anker je aktuellem Constructor-Export. Das erlaubte `:On Error Exit`
wird wie im bestehenden Batchausführer behandelt. Nach Basisinstallation
werden beide registrierten Versionen und der ResultTable-Helper erneut geprüft.

Die echte unvollständige Originaldatei wird jetzt bereits verbindungslos
abgewiesen. Beide korrigierten kanonischen Exporte bestehen den tatsächlichen
`ValidateOnly`-Vorcheck mit den drei bekannten Assemblies und den unveränderten
22 Quellpins des echten historischen Artefakts. Dies ist noch kein nativer
Upgrade-, Rollback- oder ACL-Erhaltungsnachweis.

Elf [Offlinegegenproben](../../Tests/Release/test_constructor_acl_contract.py)
bestehen: boolesche Freigaben, Fristen, spätere Ziel-/Modusabweichungen,
kanonische Fixture, Artefaktrollen, vollständige Exportclosure und Fehleranker,
nichtleere Snapshots sowie sichtbare Grantor-/Owner-/Callerdrift. Die
Setup-Fixture und sieben Snapshot-/Cleanup-SQL-Literale bestehen Parser150.

Vor einer neuen nativen Zulassung bleiben erforderlich: neue endliche
Freigabe, unveränderte gepinnte Eingaben und echte unabhängige Abschlussaudits.
Vorhandene CLR-Konfigurations-/Trustfreigaben werden nur mit den bestehenden
Ownership-, Consumer-, Wiederherstellungs- und Driftprüfungen verwendet.
Jeder Producer/Audit bleibt auf 400 Sekunden und getrennte 4-MiB-Kanäle
begrenzt; vor dem nächsten Fall bleiben mindestens 15 Minuten Reserve.

## Erneut freigegebene Welle vom 2026-11-08

Der Benutzer gab ausdrücklich höchstens 24 Ziel-/Auditaufrufe, 24 eigene
Testdatenbanken und 45 Minuten frei. Die vorbereitete No-Retry-Zulassung
blieb erhalten. Der tatsächliche Build war
[`3e5e02f9`](https://github.com/gecompat/SQL_Server_Toolbelt/commit/3e5e02f97e1d320440a93b4cb4c7349db9f7be34);
die ACL-Methode und relevanten Produktquellen waren gegenüber der integrierten
Abhängigkeitskorrektur unverändert. Reale Lab-ValidateOnly-Zulassung und
elf vorhandene Offlinegegenproben bestanden vor jedem SQL-Zugriff.

Bereits Windows SQL2019/CU32 CL150 lokal stoppte im Fresh-Caller-Vorcheck
mit SQL-Fehlertext „Fresh own Constructor caller required.“. Die echte
historische Installation war zuvor geprüft; `CREATE USER` und alle vier
Grants wurden nicht erreicht. Keine bestandenen ACL-Kontexte oder
Gesamtfälle. Der neue Fall verbrauchte **zwei Aufrufe und zwei Reservierungen**;
die **eine tatsächlich angelegte eigene Datenbank** ist entfernt.
Sein frischer separater Audit bindet das unveränderte finale Journal,
DB-Abwesenheit, wiederhergestellte Konfiguration/Trust und ursprüngliche Pins.
Der unabhängige Nachprüfer bestätigt zusätzlich ursprüngliche Git-Bytes und
Quellenkapseln der später korrigierten drei Methodendateien. Rohdaten bleiben privat.

Der kombinierte Vorcheck vermischte `USER_ID` und `XACT_STATE()` in einem
Prädikat. Dieselbe interne Katalog-Autocommit-Falle war im
[Caller-Nachweis](JSON-CONSTRUCTORS-CALLER-QUALIFICATION.md#erhaltene-fehler-und-grenzen)
bereits beobachtet und durch
[`2ef5fb41`](https://github.com/gecompat/SQL_Server_Toolbelt/commit/2ef5fb41d92ed4a420dc0f544dd43fca00bcf060)
behoben worden. Im neuen Journal sind die drei Einzelwerte des abgebrochenen
Prädikats nicht erfasst; daraus wird weder eine tatsächlich offene
Caller-Transaktion noch ein bereits vorhandener Testbenutzer abgeleitet.

Die enge Adapterkorrektur erfasst `@@TRANCOUNT` und `XACT_STATE()` bei Einstieg
und Cleanup zuerst skalar, bevor der Katalogzugriff erfolgt. Die Forderung
nach neutraler Sitzung und der Schutz vorhandener Benutzer bleiben unverändert.
Keine nachträgliche Transaktionsbereinigung, kein Entfernen fremder Benutzer,
keine zusätzlichen Rechte und keine Änderung am Constructor-Produkt.
Ein künftiger Entryfehler nennt die zuvor erfassten beiden Zustandswerte
und die Testbenutzerpräsenz ausschließlich im privaten Fehlerjournal.

**14 Offlinegegenproben** bestehen. Die drei neuen Gegenproben verwerfen
gemischte Katalog-/Sitzungsausdrücke, bloß kommentierte oder zu spät erfasste
Werte sowie entfernte/konstant ersetzte Zustandsprüfungen. Ein separater
typisierter SQL150-AST-Vergleich erkennt beide ursprünglichen unsicheren
Prädikate und akzeptiert die beiden korrigierten Formen, jeweils syntaktisch
gültig. Das sind vier verbindungslose AST-Fälle, keine native SQL-Ausführung.

Die neue Welle ist **STOPPED_NO_NEW_ADMISSIONS**, ohne Wiederholung und
ohne Übertragung ihrer unbenutzten Restplätze. Die alte Welle vom 2026-11-07
bleibt zusätzlich unverändert geschlossen. Für die noch fehlenden zwölf
nativen Gesamtfälle und zwölf Audits ist eine neue konkrete endliche
Freigabe nötig; eine bestandene Cleanup-, Offline- oder CI-Prüfung ersetzt
diese native Abnahme nicht. Tatsächliche Head-/Main-CI der Methodenintegration
werden getrennt in [PR #553](https://github.com/gecompat/SQL_Server_Toolbelt/pull/553)
nachgewiesen. Keine Modulgesamtfreigabe.

## Getrennte Grenzen

Direkte CLR-/Assembly-ACLs, absichtlich andere Owner, Netzwerk-/CrossDB-
Identitäten, Linux-Clienthost, weitere Lifecycle-/Ressourcen-/Recoveryprofile
und vollständige Modulabnahme bleiben separat. Frühere Genuine-Migrations-,
Clientmetadaten- und Minimalrechtenachweise werden nicht wiederholt oder
pauschal aufgewertet. Produkt-SQL, Assemblies, Manifeste, Pakete und der
teilweise validierte, unveröffentlichte Modulstatus bleiben unverändert.
Keine Veröffentlichung oder Tags.
