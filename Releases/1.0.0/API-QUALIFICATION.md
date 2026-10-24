# API-Nachweise für den Releasekandidaten

Stand 2026-10-23: **74 ausgewählte Ziel-/CL-/Gruppenfälle abgeschlossen;
73 vollständig bestanden, ein Regex-Fall partiell**. Insgesamt sind
3231 Fixtureaufrufe bestanden beziehungsweise nach frischer Bindungsprüfung
übernommen; ein Fixtureaufruf bleibt blockiert. Das ist keine vollständige
Releasefreigabe aller Module. Alle 45 Modulversionen bleiben `unreleased`,
die Kanalaufteilung bleibt 19 stabil/26 Preview.

Der unmittelbare Benutzerauftrag vom 2026-10-23 umfasst Nachweiszuordnung,
ausführbare API-/Grenzprüfungen und einen PR. Öffentliche SQL-Verträge,
Modulversionen, Sicherheitsbudgets und Support-Zielumfang bleiben unverändert.
Veröffentlichung und autonome Weiterentwicklung sind weiterhin nicht freigegeben.

## Spätere Regex-Nachprüfung

Dieser Bericht bewahrt die Ausführung vom 2026-10-23 auf der damaligen
Produktbasis. Die [Nachprüfung vom 2026-10-24](REGEX-TIMEOUT-QUALIFICATION.md)
bindet die korrigierte DLL separat: der ursprüngliche Transformationsabschluss
ist belegt; ein zusätzlicher Capture-Timeout bleibt offen. Die folgenden
historischen Zahlen werden dadurch nicht rückwirkend verändert.
Die spätere [Capture-Abnahme](CAPTURE-RELEASE-ACCEPTANCE.md) nimmt das
historische Timeout-Gate für die unveränderte DLL nach ausdrücklich
freigegebener Abschlussregel mit Restrisiko an. Sie ersetzt weder die
historischen Teilergebnisse noch übrige Modulpflichtfälle.

## Nachweis und genaue Auswahl

Die [Zuordnung aller 45 Module](EVIDENCE-MAP.md) führt zu ihren kanonischen
Manifestnachweisen. [api-qualification.json](api-qualification.json) enthält
die tatsächlichen abstrakten Fälle, Modul-/Fixturezuordnung, bestandene,
übernommene und blockierte Aufrufe, Quellenbindungen und Ergebnisgrenzen.
Eigene DB-/Trustidentitäten, Endpoints, Labvertrag und Rohlogs bleiben privat.
Eine Fixture kann mehrere SQL-Batches und Assertions enthalten; die Anzahl
der Fixtureaufrufe ist keine behauptete Anzahl einzelner SQL-API-Aufrufe.

| Gruppe | Ziel-/CL-Fälle | Ergebnis / zusätzlicher Scope |
|---|---:|---|
| Core | 12 | Bestanden: ausgewählte portable APIs und zentrale Consumer |
| Text | 12 | 11 bestanden, einer partiell wegen Regex-Timeout; direkte Clientmetadaten eingeschlossen |
| Formate | 12 | Bestanden: ausgewählte JSON-/ZIP-/XLSX-APIs einschließlich großer Ergebnisorakel und Metadaten |
| Windows | 6 | Bestanden: Parser/TableClone; SSIS-Funktionsfälle und Metadaten gezielt auf drei fehlenden niedrigeren CLs |
| CSV | 12 | Bestanden: ausgewählte API-/Safety-/Metadaten- und fehlende große Grenzfälle |
| Cancellation-Negativfälle | 12 | Bestanden: strikte Fehler-/Callertransaktionsorakel, jeweils local und central |
| Große Translate-Fälle | 8 | Bestanden: nur die bisher nicht belegten Ziele, jeweils local und central |

Die physische Matrix ist Windows/Linux mit SQL2019 CL150, SQL2022 CL150/160
und SQL2025 CL150/160/170, soweit das Modul die Plattform unterstützt.
Eigene synthetische Datenbanken verwenden die unveränderten qualifizierten
Gesamtpayloads der vier Profile: Windows-local 45 Module, Windows-central 43,
Portable-local/central je 40. Die neue Welle wählt zusätzliche Fixtures für
37 Module aus; daraus folgt keine Prüfung aller APIs dieser 37 Module.

Safe-Cast und JSON Pointer behalten ihre unveränderten vollen physischen
Matrixnachweise vom 2026-10-19. CSV-Millionenzell-/Zeilen-/Spaltengrenzen auf
Linux SQL2019/CL150 und Windows SQL2025/CL170 und vorhandene große Translate-
Nachweise werden in ihrem ursprünglichen Scope wiederverwendet. SSIS ergänzt
Windows SQL2022/CL150 sowie SQL2025/CL150/160. Die frühere volle Paket-
Lifecyclematrix und großen ResultTable-/Base64-/Generate-Series-Prüfungen
bleiben getrennte Nachweise; optionale Laufzeitmessungen sind kein Pflichtgate.

## Neue strikte Grenzzeugen

Die zusätzliche [CSV-Defaultfixture](../../Tests/Release/Runtime/DefaultSnapshotCeiling.sql)
prüft die gemeinsame 16-MiB-Grenze mit vollständigen Byteorakeln:
cap minus sechs Rohbytes ergibt exakt cap Ausgabebytes; cap und cap plus
zwei Rohbytes werden ohne Quell-/Zielmutation abgelehnt. Omitted/explicit
DEFAULT und Replace/Append sind getrennt geprüft. Beide Guards melden
55303/State1. Eine erfolgreiche Ausgabe mit genau cap Rohbytes ist unter
derselben Ausgabedecke wegen Separator/CRLF unmöglich; eine isoliert
beobachtbare Guardpriorität wird nicht behauptet. Die beiden Direct-SELECT-
Suiten verwenden ihre kanonischen Clientorakel für alle acht Phasen,
einschließlich erwartetem Fehler ohne vorzeitiges Resultset.

Die alte Cancellation-Fixture konnte eigene Assertions als erwartete Fehler
akzeptieren und verwendete einen unzuverlässigen Temp-Tabellen-FK-Zeugen.
Die zusätzliche [strikte Fixture](../../Tests/Release/Runtime/Cancellation.StrictErrors.sql)
prüft 52601/52600 exakt und beweist mit einem echten FK-Fehler547 eine doomed
Callertransaktion. Sie verlangt den unveränderten Callerzustand ohne neuen
Cancellationeintrag. Eine Garantie, dass eine aktive Callertransaktion nach
dem vorhandenen XACT_ABORT-ON-Guard committable bleibt, ist kein öffentlicher
Vertrag und wird nicht als Orakel erfunden.

Für SSIS wird ausschließlich der genau begrenzte Principal-/Rechteblock
aus einer privaten kanonischen V1-Fixtureableitung ausgelassen. Sonstige
funktionale Assertions bleiben bytegleich. NOLOCK-Zeugen, tatsächlicher
zentraler Consumer und Ausführung des generierten SQL sind eingeschlossen.
Dies qualifiziert keine SSIS-Minimalrechte und behauptet keinen neuen
vollständigen Securitylauf der kanonischen Fullsuite.

## Offener tatsächlicher Fachbefund

`toolbelt.string.regex:Transformations.Contract.sql` wurde unter
**Linux SQL2022/CL150, local** durch einen unerwarteten intrinsischen
`TBX_REGEX_TIMEOUT`/SQL6522 nicht vollständig abgeschlossen. Damit fehlt
der vollständige positive Grenznachweis dieser Fixture in genau diesem
Kontext. Die anderen elf Textkombinationen bestanden vollständig.
Der Timeout wird weder als PASS noch als TLS-/Clientproblem eingeordnet.
Die vorhandenen Regex-Sicherheitsbudgets wurden nicht erhöht.

Nächster Schritt ist eine eng abgegrenzte Diagnose des konkreten Aufrufs
gegen den bestehenden Vertrag; erst ein konkreter Befund mit geändertem
relevantem Input begründet eine erneute Prüfung. Aus der Einzelbeobachtung
wird kein pauschaler Produktfehler oder allgemeiner Erfolg abgeleitet.
Der Gesamtfall und die Regex-Zuordnung bleiben ausdrücklich partiell.

## Methoden, Korrekturen und Bereinigung

Reproduzierbare Vorbereitung und Aufruf stehen in
[Tests/Release](../../Tests/Release/README.md#api--und-grenzqualifikation).
Die feste Liste umfasst 165 Fixturedefinitionen. Jedes eingefrorene Runset
bindet Payload, kanonisch gestagte Testquellen, Kompositionshelfer,
synthetische XLSX-Fixtures, Labvertrag/Schema/Zusatzprompt und Methodenbytes.
Produkt-SQL/DLLs wurden gegen die bereits nativ qualifizierten
[damaligen Gesamtpayloads](https://github.com/gecompat/SQL_Server_Toolbelt/blob/466d0ca6b52636da715a3c40dcce8ea121606df6/Releases/1.0.0/complete-qualification.json) und den
[damaligen Produktsnapshot](https://github.com/gecompat/SQL_Server_Toolbelt/blob/466d0ca6b52636da715a3c40dcce8ea121606df6/Releases/1.0.0/product-source.json) verglichen und nicht geändert.
Methodenrevisionen sind im Gitverlauf und in den tatsächlichen privaten
Runsets erhalten; die öffentliche Projektion nennt die öffentlichen
Methodenhashes der akzeptierten vollständigen/partiellen Fälle. Historische
Bindungen übernommener Präfixe bleiben in den privaten Carry-Runsets erhalten.
Ein Manifestpflegecommit ist weiterhin nur
ein Vergleichssnapshot, kein erfundener historischer Ausführungscommit.

Konkrete Adapterbefunde wurden vor Fortsetzung korrigiert: fehlende
kanonische dbo-Queue-Testpolicy, lokaler Capability-Test im zentralen Modus,
eigene verbleibende SqlClient-Pools, scriptübergreifende Budgetcallbacks,
ausgelassener SSIS-Consumerparameter, erwartete CSV-Direct-SELECT-Fehler und
zu enge aggregierte Harnessfristen. Der erste strikte Cancellation-Entwurf
forderte eine nicht dokumentierte Committable-Garantie; nur dieses
unbegründete Testorakel wurde korrigiert. Ein Carry-Preflight wies außerdem
JSON-Keyreihenfolge fälschlich als semantische Änderung ab; vor Mutation
wurde die kanonische Bindung korrigiert. Alte Fehler und bereinigte
Teilversuche bleiben erhalten. Bereits bestandene unabhängige Fixturepräfixe
wurden nur nach frischer Cleanup-, Kontext- und Byteprüfung übernommen.

Die ursprüngliche gemeinsame Grenze von 90 Versuchen/36000 Sekunden blieb
über alle Revisionen erhalten; tatsächlich verbraucht: 86 Case-/Recoveryversuche.
Jede Revision hatte einen endlichen Plan, eigene Besitzmarker und private
Restorejournale. Innere Arbeits-/Cleanupfristen, äußerer Prozesswatchdog
und unabhängiger Cleanup-/Pinaudit bleiben getrennt. Die gezielte
SqlClient-Pool-Reconciliation prüfte Eigentümerschaft vor Entfernung;
laufende mutierende Tests wurden nicht zur Fehlerbehebung hart abgebrochen.

Alle 252 eigenen historischen Datenbanknamen sind im frischen separaten
Gesamtaudit abwesend; 66 unterschiedliche zielgebundene Trustzustände sind
wiederhergestellt beziehungsweise unverändert erhalten. Temporäre eigene
CLR-Konfiguration wurde nach allen Verbrauchern wiederhergestellt und
separat auditiert. Keine Logins, Rechte, Labressourcen, Truststores,
`clr strict security` oder `TRUSTWORTHY` wurden geändert.
Fachtests verwendeten `TestPurpose=Functional`, `Encrypt=True` und den
expliziten booleschen Lab-Trustwert, ohne Transportfallback.

## Verbleibende Voraussetzungen

| Gate | Noch erforderlicher Scope / Voraussetzung |
|---|---|
| Regex-Grenznachweis | Historischer Transformationsabschluss in der [Nachprüfung](REGEX-TIMEOUT-QUALIFICATION.md) auf der korrigierten DLL belegt; zusätzlicher Capture-Teilnachweis dort weiterhin offen. |
| Echte Minimalrechte | Getrennte passende Principals und negative Rechtefälle oder separat freigegebener enger Security-Testaufbau. Dbo-Fachfixtures qualifizieren dies nicht. |
| Serverdateien und Identitäten | ZIP-Files, File-Content und Filesystem-Windows: eigene synthetische serverseitige Dateien, Caller-/ServiceAccount-, NTFS-/Reparse-/Zugriffsfixtures mit geklärter Ownership. |
| Zweite Session / EventLog | Vorkonfigurierter administrierter Provider; direkte API-, Rollback- und Sessionunabhängigkeitsfälle darüber. Paketinstallation allein genügt nicht. |
| Worker und harte Recovery | Passende Worker-/Providerhosts und kontrollierter echter Transport-/Hostverlust; keine harte Unterbrechung laufender Mutationen als Ersatz. |
| Weitere Modulpflichtfälle | Unbelegte API-, Client-, Upgrade-, Heap-/Parallel-/Recoveryfälle bleiben je Modulmanifest offen; ausgewählte grüne Fixtures ersetzen sie nicht. |
| Endanwender-Clients | Manuelle SSMS-GUI und nativer optionaler ODBC-PowerShell-Helfer bleiben `not executed`; direkte SqlClient-Metadaten qualifizieren diese Wege nicht. |
| Authentifizierte TLS | Separater Identitätsnachweis, hier `not executed`; kein pauschaler Blocker unabhängiger Fachtests. |
| Veröffentlichung | Endgültiger Paket-/Head-CI-Nachweis, vollständige Pflichtqualifikation jeder zugesagten Kombination und ausdrücklicher Veröffentlichungsauftrag. Kein Tag/Release aus diesem Auftrag. |

Ein Verantwortlicher, ein PR, keine Delegation oder weitere Welle.
Kosten-/Tokenmessung: UNKNOWN. Die autonome Verarbeitung bleibt pausiert.
