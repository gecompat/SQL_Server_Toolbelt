# Constructor-Upgrade mit nichtleeren USP-Berechtigungen

Stand 2026-11-08: **PASS_FOR_DECLARED_NONEMPTY_CONSTRUCTOR_ACL_SCOPE**.
Die anschließend ausdrücklich freigegebene korrigierte Matrix bestand mit
zwölf vollständigen Läufen, 24 lokalen/direkt zentralen Kontexten und zwölf
frischen unabhängigen Abschlussaudits. Erhalten sind 120 Prozeduridentitäten
und 96 Objektgrants über Rollback, echtes 1.2→1.3-Upgrade und Repeat.
Alle 24 eigenen Testbenutzer und Datenbanken sind entfernt. Kein neuer
nativer Fehler oder Retry. Beide früheren Fehlläufe bleiben unverändert
FAILED_CLEANED; ihre Cleanup-PASS werden nicht zu Gesamt-PASS aufgewertet.
Dies ist die erklärte Metadaten-/ACL-Erhaltungsabnahme, keine Modulgesamtfreigabe.

## Konkreter Prüfumfang

Der [Testtreiber](../../Tests/Release/Invoke-JsonConstructorsAclLab.ps1) und
das [enge Profil](../../Tests/Release/JsonConstructors.AclUpgrade.ps1) prüfen
den Erhalt beim Upgrade der echten bekannten Constructor-Version 1.2.0
auf den aktuellen Vertrag 1.3.0. Windows SQL 2019/CU32, 2022/CU26, 2025/CU8 und Linux SQL
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

## Zweiter Fehlversuch am 2026-11-08, vor der Sitzungskorrektur

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

Der folgende Absatz beschreibt den damaligen Abschlussstand dieses Fehlversuchs;
die danach neu freigegebene erfolgreiche Matrix ist im nächsten Abschnitt belegt.

Die neue Welle ist **STOPPED_NO_NEW_ADMISSIONS**, ohne Wiederholung und
ohne Übertragung ihrer unbenutzten Restplätze. Die alte Welle vom 2026-11-07
bleibt zusätzlich unverändert geschlossen. Für die noch fehlenden zwölf
nativen Gesamtfälle und zwölf Audits ist eine neue konkrete endliche
Freigabe nötig; eine bestandene Cleanup-, Offline- oder CI-Prüfung ersetzt
diese native Abnahme nicht. Tatsächliche Head-/Main-CI der Methodenintegration
werden getrennt in [PR #553](https://github.com/gecompat/SQL_Server_Toolbelt/pull/553)
nachgewiesen. Keine Modulgesamtfreigabe.

## Abschließende ausdrücklich freigegebene Matrix vom 2026-11-08

Die zusätzliche konkrete Freigabe umfasste zwölf Läufe und zwölf separate
frische Audits, höchstens 24 zusätzliche Ziel-/Auditaufrufe, 24 eigene
Datenbanken und 45 Minuten ab neuem Start, keine weitere Wiederholung.
Die beiden alten Wellen wurden nicht neu gestartet: neuer Controller,
neue eigene Datenbanken und unveränderte alte Fehler, Zähler, Audits
und Originaljournale.

Ausgeführter Build:
[67f40998](https://github.com/gecompat/SQL_Server_Toolbelt/commit/67f409981fbe4a524011ebb94f81e5df720f3611),
die regulär integrierte Korrektur aus
[PR #553](https://github.com/gecompat/SQL_Server_Toolbelt/pull/553).
Vor Start waren die tatsächliche finale Head-CI und die lokale betroffene
Prüfung mit 491 Release-Tests, 18 Kandidatentests und 45 Modulmanifesten grün.
Auch die tatsächliche Main-PUSH-CI der Methodenintegration bestand.
Bekannte drei DLLs, 22 genuine historische Sourcepins, aktuelle Helfer,
exakte Exportclosure, Labvertrag/-schema/-prompt, Regeln, neue Autorität
und ursprüngliche Quellenkapseln waren frisch gebunden. Alle vier
Objektrechte sind die bereits genehmigten Rechte; keine neue Rechteklasse.

| Ausgewähltes SQL-Ziel | Compatibility Levels | Modi | Kontexte |
|---|---|---|---:|
| Windows 2019/CU32 | 150 | lokal/direkt zentral | 2 |
| Windows 2022/CU26 | 150, 160 | lokal/direkt zentral | 4 |
| Windows 2025/CU8 | 150, 160, 170 | lokal/direkt zentral | 6 |
| Linux 2019/latest | 150 | lokal/direkt zentral | 2 |
| Linux 2022/latest | 150, 160 | lokal/direkt zentral | 4 |
| Linux 2025/latest | 150, 160, 170 | lokal/direkt zentral | 6 |

Windows ist der Clienthost mit System.Data.SqlClient und vorhandener
administrativer SQL-Lab-Anmeldung. Linux bezeichnet das SQL-Ziel.
Funktionale Abnahme mit erforderlicher Verschlüsselung und unverändertem
explizitem Trustwert; keine neue Windows-SSPI-/GUI-/Serveridentitätsabnahme.

Je Kontext wurden die vollständigen fünf Prozeduridentitäten einschließlich
expliziter/effektiver Owner, alle vier ACL-Tupel einschließlich Grantor und
die Benutzeridentität mit SID/Erstellungszeit verglichen. Die Bestände sind
nach dem kontrollierten post-DROP-Fehler 53691, dem tatsächlichen genuinen
1.2→1.3-Upgrade und dem Wiederholungsdeployment exakt identisch.
Der gesonderte Rollbacksnapshot erhält CLR-Slots, Assembly-/Corebindung
und vollständige relevante Properties. Der installierte aktuelle Stand,
SAFE-Berechtigung und die aktuelle Core-Referenz sind zusätzlich geprüft.
Keine erneute allgemeine API-/Quoten-/Caller- oder Schema-Consumer-Matrix.

Ergebnis: **zwölf vollständige erfolgreiche Originalkoordinatoren**,
24 erhaltene Rollback-/Upgrade-/Repeatprofile je Phase, 120 erhaltene
Prozeduridentitäten und 96 erhaltene Objektgrants. Alle 96 eigenen Grants
wurden anschließend ausdrücklich widerrufen, alle 24 eigenen Benutzer und
Datenbanken entfernt. Die zwölf frischen separaten Audits binden die
finalen unveränderten Originaljournale, Datenbankabwesenheit, tatsächliches
SQL-Ziel, wiederhergestellte Konfiguration/Trust und sämtliche Inputpins.
Verbrauch der neuen Welle: **24/24 Aufrufe und 24/24 DB-Reservierungen**,
innerhalb der neuen 45-Minuten-Grenze; null native Fehler/Retry, alle Slots geschlossen.

Der unabhängige Nachprüfer kontrolliert zusätzlich die exakten Namen/IDs
der vier öffentlichen Zielprozeduren, Objektklasse, minor_id=0, Grantee und
Grantzustand sowie die vollständigen Vor-/Nach-Tupel. Seine erste rein lokale
Auswertung erwartete einen ungepolsterten Berechtigungscode.
Die [Katalogspalte type ist char(4)](https://learn.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-database-permissions-transact-sql);
der ergänzende Nachprüfer verlangt deshalb exakt den EXECUTE-Code EX mit
zwei ASCII-Leerzeichen. Ausschließlich dieses eine Prädikat wurde korrigiert
und per Rückvergleich auf unveränderten Restcode geprüft. Originalprüfer,
gescheiterte Auswertung und gepinnte Originaldaten bleiben unverändert.
Der ergänzende Nachprüfer besteht vollständig. Keine neue SQL-Verbindung,
kein Native-Retry, keine pauschale Whitespace-Normalisierung oder Änderung
von Journalen, Audithashes, ACLs oder sonstigen Prüfbedingungen.

In den drei getrennten Wellen bleiben damit zwei fehlgeschlagene
Originalfälle und zwölf bestandene Originalfälle mit insgesamt 14 frischen
Audits erhalten. Die beiden Fehlfälle verbrauchten zusammen vier frühere
Aufrufe/Reservierungen und zwei tatsächlich angelegte eigene Datenbanken;
sie sind keine bestandenen Kontexte der neuen Matrix. Ihre Grenzen werden
weder zurückgesetzt noch mit den 24 neuen Aufrufen verrechnet.
Tatsächliche Head-/Main-CI dieses Nachweisintegrationsstands sind separate
Integrationsgates; Ergebnisse stehen im zugehörigen Nachweis-PR.

## Getrennte Grenzen

Direkte CLR-/Assembly-ACLs, absichtlich andere Owner, Netzwerk-/CrossDB-
Identitäten, Linux-Clienthost, weitere Lifecycle-/Ressourcen-/Recoveryprofile
und vollständige Modulabnahme bleiben separat. Frühere Genuine-Migrations-,
Clientmetadaten- und Minimalrechtenachweise werden nicht wiederholt oder
pauschal aufgewertet. Produkt-SQL, Assemblies, Manifeste, Pakete und der
teilweise validierte, unveröffentlichte Modulstatus bleiben unverändert.
Keine Veröffentlichung oder Tags.
