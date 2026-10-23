# API-Nachweise für den Releasekandidaten

Der Benutzer hat am 2026-10-23 die Nachweiszuordnung und die im vorhandenen
Lab ausführbaren API- und Grenzfälle beauftragt. Öffentliche SQL-Verträge,
Modulversionen und Support-Zielumfang bleiben bestehen. Veröffentlichung
und autonome Weiterentwicklung sind weiterhin nicht freigegeben.

Die [Zuordnung aller 45 Module](EVIDENCE-MAP.md) führt zu den kanonischen
Manifestnachweisen und trennt sie von dieser zusätzlichen Prüfwelle.
Die [feste Testliste](../../Tests/Release/api-qualification-spec.json) enthält
164 vorhandene beziehungsweise ergänzende Fixturedefinitionen. Ihre
Ausführung, Eingrenzung und Grenzen beschreibt
[Tests/Release](../../Tests/Release/README.md#api--und-grenzqualifikation).

## Abgegrenzte zusätzliche Prüfung

Geplant sind 54 Abläufe in fünf Gruppen: Core, Text, Formate und CSV jeweils
auf zwölf physischen Ziel-/CL-Kombinationen; Parser/TableClone/SSIS auf den
sechs Windows-Kombinationen. Acht getrennte große Translate-Abläufe ergänzen
nur die noch nicht belegten Ziele. SQL Server 2019 mit CL150, 2022 mit CL150/160 und
2025 mit CL150/160/170; jeweils Windows/Linux, soweit unterstützt. Jeder
Ablauf verwendet eigene synthetische Datenbanken und das unveränderte,
bereits qualifizierte Installationspayload, mit lokaler und zentraler
Installation sowie kanonischen zentralen Consumerfällen.

Safe-Cast und JSON Pointer besitzen bereits volle physische Matrixnachweise.
Sie werden nicht zur Statusauffrischung wiederholt. Auch die CSV-
Millionenzellgrenze und die realen Zeilen-/Spaltengrenzen sind bereits auf
Linux SQL2019/CL150 und Windows SQL2025/CL170 belegt. Diese konkreten
Grenzfixtures werden nur auf den übrigen Zielen ergänzt. Bei SSIS werden
die fehlenden niedrigeren CLs ergänzt. Frühere erfolgreiche Paket-Lifecycle-
und große ResultTable-/Base64-/Generate-Series-Prüfungen bleiben eigenständige
Nachweise. Diese API-Welle ist kein neuer Lifecycle-, Rechte- oder Heaptest.

Die neue CSV-Defaultfixture prüft mit unabhängigen vollständigen Byteorakeln
die gemeinsame 16-MiB-Grenze: cap minus sechs Rohbytes ergibt exakt cap
Ausgabebytes; cap und cap plus zwei Rohbytes werden ohne Quell-/Zielmutation
abgelehnt. Omitted/explicit DEFAULT und Replace/Append werden getrennt
geprüft. Snapshot- und Outputguard melden beide 55303/State1. Eine isolierte
erfolgreiche CSV-Ausgabe mit genau cap Rohbytes ist unter derselben
Ausgabedecke wegen Separator/CRLF unmöglich; eine getrennte beobachtbare
Guardpriorität wird nicht behauptet.

## Ergebnis und Bindung

Noch kein abgeschlossener Erfolgslauf dieser neuen Welle. Drei bereinigt
fehlgeschlagene Adapterversuche bleiben in der Historie erhalten. Die privaten
Runsets binden Paket, kanonisch gestagte Testquellen, relative Helfer,
synthetische XLSX-Fixtures, Labvertrag/Schema/Zusatzprompt und die Runner.
Fachtests verwenden Functional, Encrypt=True und den expliziten booleschen
Lab-Trustwert; kein Transportfallback. Eigene DB-/Trustidentitäten und
temporäre CLR-Konfiguration bleiben ausschließlich in privaten Journalen.

Vor dem ersten Eingriff wurden 54 Fälle, höchstens 90 gemeinsame Versuche
und 36000 Sekunden festgeschrieben. Ein geänderter relevanter Input und ein
konkreter Befund sind Voraussetzung für weitere Versuche. Der ursprüngliche
Budgetstart bleibt erhalten. Ordentliche Arbeit/Cleanup/äußerer Watchdog
sind 300/360/400 Sekunden, bei den großen CSV-Fixtures 960/1200/1240;
zusätzlich werden 90 Sekunden für den unabhängigen Audit reserviert.

Der erste Corelauf scheiterte an der fehlenden expliziten dbo-Testpolicy
der alten Queue-Fachfixture. Cleanup und unabhängiger Audit waren erfolgreich.
Der Adapter bindet nun die dafür vorhandene kanonische
`WorkTypeAuthorization.Fixture.sql` ein. Sie gilt ausschließlich für die
eigene disposable Datenbank und ist kein Deploymentinclude. Es werden
keine Logins, SQL-Rechte oder Anwendungsprincipals angelegt oder verändert.
Der fehlgeschlagene Lauf bleibt als solcher erhalten. Ein weiterer
Adapterlauf benutzte die explizit lokale Capability-Fixture fälschlich im
zentralen Modus; sie wird nun nur lokal ausgeführt. Der kanonische zentrale
Capability-Test prüft weiterhin ausdrücklich den central-Marker. Produkt-
SQL, DLLs und feste Fehler-/Erhaltungsorakel wurden nicht geändert.

## Verbleibende Voraussetzungen

| Gate | Betroffener Scope / nächste Voraussetzung |
|---|---|
| Echte Minimalrechte | Alle beanspruchten Rechteverträge: bereitgestellte getrennte Principals und negative Rechtefälle oder separat freigegebener enger Security-Testaufbau. Die dbo-Fachfixture qualifiziert dies nicht. |
| Serverdateien und Identitäten | ZIP-Files, File-Content und Filesystem-Windows: eigene synthetische serverseitige Dateien, Caller-/ServiceAccount-, NTFS-/Reparse-/Zugriffsfixtures mit geklärter Ownership. |
| Zweite Session / EventLog | Vorkonfigurierter administrierter Provider; direkte API-, Rollback- und Sessionunabhängigkeit müssen darüber geprüft werden. Paketinstallation allein genügt nicht. |
| Worker und harte Recovery | Passende Worker-/Providerhosts und kontrollierter echter Transport-/Hostverlust; keine harte Unterbrechung laufender Mutationen als Ersatz. |
| Weitere Ressourcen-/Parallelverträge | Modulspezifische Heap-/Parallel-/Recoveryfälle bleiben offen, soweit nicht durch einen konkreten vorhandenen Nachweis belegt. Die drei optionalen Laufzeitmessungen sind kein Gate. |
| Endanwender-Clients | Manuelle SSMS-GUI und nativer optionaler ODBC-PowerShell-Helfer. Direkte SqlClient-Metadaten qualifizieren diese Wege nicht. |
| Authentifizierte TLS | Separater Identitätsnachweis; kein pauschaler Blocker unabhängiger Fachtests. |
| Veröffentlichung | Finales Paket und aktuelle Head-CI, vollständige Pflichtnachweise je zugesagter Kombination sowie ausdrücklicher Veröffentlichungsauftrag. Kein Tag oder Release aus diesem Auftrag. |

Ein Verantwortlicher, ein PR, keine Delegation und keine weiteren Wellen.
Kosten-/Tokenmessung: UNKNOWN. Die autonome Verarbeitung bleibt pausiert.
