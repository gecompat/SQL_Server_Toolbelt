# Windows-Terminalhistorie nach Fehlerabschluss

Am 2026-11-06 bestand ein neu ausdrücklich freigegebener Gesamtlauf auf
Windows SQL Server2025/CU8, CL170, lokal. Der unveränderte öffentliche
`Workers/ExternalQueue/Tests/Runtime/Invoke-Contract.ps1 -ManagedSqlOnly`
verwendete seinen tatsächlichen Terminalhistorienverbraucher. Der private
gebundene Adapter ergänzt Ziel-/Uhr-/Journalbindung und die vorhandene endliche
Cleanup-Quieszenzprüfung; der vollständige öffentliche Cleanup-Identitätsguard
und sämtliche Runtime-Orakel bleiben erhalten.

Die [maschinenlesbare Projektion](worker-terminal-history-windows-qualification.json)
bindet den tatsächlichen Quellstand `8a0b0ac1`,168 öffentliche Code-/Methodeninputs
und den begrenzten Ausführungsumfang. Die privaten Originale von Controller,
gebundenem Adapter, ausgewähltem Labvertrag, Plan, Journal, Cleanupfakten und
Abschlussaudit bleiben separat erhalten. Der öffentliche Validator prüft
Quellen und Behauptungskonsistenz; er authentifiziert nicht eigenständig diese
privaten Ausführungsbeobachtungen und führt keinen neuen SQL-Test aus.

## Tatsächlich bestandener Umfang

- Echter Rollback von Handler-Witness und Testwirkung; erst der terminale
  Fehlerabschluss gibt den belegten Slot frei.
- Zwei Reconcile-Aufrufe erhalten die vollständige Reservation; ein doppelter
  Fehlerabschluss wird abgewiesen.
- Requeue und Folgeclaim derselben Arbeit bleiben vom historischen Versuch
  getrennt. Die alte Reservation erhält keine aktuelle Holdversion.
- Veraltete Reconcile-Autorität wird ohne Zustandsänderung abgewiesen;
  der ungebundene Folgeclaim endet über Stop/Reconcile gehalten.
- Der übergeordnete Managed-SQL-Gesamtlauf und der Terminalhistorienverbraucher
  liefern ihre beiden festen Witnesses jeweils genau einmal. Prepare, Lauf
  und frischer separater Audit haben Exit0; Originaljournal ohne primären
  oder sekundären Fehler.
- Audit über eine neue Verbindung bestätigt die eigene Datenbank als abwesend,
  unveränderte fremde Konfiguration, Trust-, Principal- und CLR-Verbraucher,
  die Inputpins und die exakte Bindung an finalen Plan, Originaljournal und
  Cleanupfakten. Die letzte Quieszenzaufnahme ist gültig.

Die zusätzliche Autorität umfasste maximal3 Ziel-/Auditaufrufe, eine eigene
Datenbank und45 Minuten ab unverändertem Originalstart. Tatsächlich verbraucht:
Readonly-Prepare, genau ein Lauf und genau ein reservierter frischer Audit;
3/3 Aufrufe und1/1 Datenbankreservierung sind geschlossen. Kein Retry und keine
weitere SQL-Welle. Der Abschluss lag innerhalb der Originalfrist. Es gab keine
neuen SQL-Rechte, Server-/CLR-/Truständerungen oder Lab-Infrastrukturaktionen.

## Historie und verbleibende Grenzen

Der frühere Windows-SQL208-Versuch aus [PR523](https://github.com/gecompat/SQL_Server_Toolbelt/pull/523)
bleibt fehlgeschlagen und separat bereinigt; sein alter3/3-Rahmen bleibt
unverändert geschlossen. Die damaligen Linux-CI-Erfolge bleiben bei ihrem
ursprünglichen Scope. Der neue Windows-PASS wertet weder den alten
Windowsfehler noch die drei früheren fehlgeschlagenen CI-Heads auf.

`ManagedSqlOnly` führt keinen externen Provider-Gesamtfall aus: Providerfälle0,
`full_product_qualified=false`. Andere Engine-/CL-/Deploymentkombinationen,
Lowpriv-/CrossDB-Identitäten, Windows-Clientanmeldung, authentifiziertes TLS,
Host-/Transportverlust und unbeaufsichtigter Dauerbetrieb sind hier nicht
qualifiziert. Die kanonische [Worker-Testanleitung](../../Workers/ExternalQueue/Tests/README.md#terminalhistorie-nach-fehlerabschluss-und-folgeclaim)
und die [Worker-Control-Matrix](../../Modules/toolbelt.core.worker-control/Tests/WORKER_CONTROL_CONTRACT_TEST_MATRIX.md)
führen die weiteren Umfänge. Modulstatus, Produkt und Paket bleiben unverändert;
keine Veröffentlichung oder Tags.

## Quellenprüfung ohne SQL

`python -B Scripts/Release/worker_terminal_qualification.py` bindet die Pins
zuerst an den Original-Gitbaum und vergleicht die heutigen Quellen getrennt.
Ein späterer Quelldrift löscht die Originalausführung nicht und wird nicht als
neue native Qualifikation ausgegeben. Die ursprünglichen Gitobjekte müssen
lokal vorhanden sein; keine Netzwerkbeschaffung oder Normalisierung.

Die [Gegenproben](../../Tests/Release/test_worker_terminal_qualification.py)
verhindern unter anderem fehlende Witnesses/Audits, einen grünen Audit über
einem fehlgeschlagenen Lauf, falsche Zahlen-/Booltypen, falsche Originalpins,
Provider-/Identitäts-/Plattformaufwertung und das Umschreiben alter Fehler.
Sie laufen im vorhandenen Releasecheck. Ein Verantwortlicher, ein PR,
keine Agenten oder neuen CI-Jobs. Nach der geschlossenen nativen Welle folgen
nur die erforderlichen statischen Head-/Mainprüfungen; kein grüner Nativfall
wird allein für eine Statusauffrischung wiederholt.
