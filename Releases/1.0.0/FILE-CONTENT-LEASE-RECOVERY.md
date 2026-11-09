# File Content: Wiederaufnahme nach Verlust der AppLock-Haltersitzung

Stand 2026-11-09: **PASS_FOR_DECLARED_IDLE_LEASE_RECOVERY_SCOPE** auf
Windows SQL Server2025/CU8, CL170, lokal und direkt zentral. Vier vollständige
Fälle und ein frischer unabhängiger Abschlussaudit bestanden. Beide eigenen
Testdatenbanken sind entfernt; Serverkonfiguration und Assemblytrust unverändert.
Dies ergänzt die [reguläre AppLock-Freigabe](FILE-CONTENT-APPLOCK-QUALIFICATION.md).

## Geprüfter Ablauf

| Modus | Öffentlicher Schritt nach Sitzungsverlust | Ergebnis |
|---|---|---|
| local | Deploy | kanonischer Modulkatalog unverändert |
| local | Uninstall | eigenes Modul und Marker entfernt |
| central | Deploy | kanonischer Modulkatalog unverändert |
| central | Uninstall | eigenes Modul und Marker entfernt |

Eine getrennte unpooled SQL-Verbindung hält jeweils die exakte File-Content-
Sperrressource exklusiv mit Session-Ownership. Die Sitzung ist allein vom
Testlauf erzeugt, ruhend und ohne Benutzertransaktion oder Datenänderung.
Connection-ID, eigener zufälliger Context-Tag, Datenbank-ID und getrennte SPID
binden die letzte serverseitige Prüfung. Fremde Identität, aktive Requests,
offene Transaktionen oder die eigene Kontrollsitzung verhindern das Beenden.
Nur diese eigene Haltersitzung wird mit KILL beendet.

Die ursprüngliche Verbindung muss verschwunden und die exakte Exklusivsperre
wieder verfügbar sein. Danach läuft das unveränderte öffentliche Deploy-
beziehungsweise Uninstall-Skript. Der ResultTable-Katalog bleibt erhalten.
Das bestehende externe Orakel prüft keine offenen Benutzertransaktionen oder
Application Locks; getrennte lokale Zustands- und SPID-Proben bestätigen die
weiter offene, neutrale Arbeitssitzung. Die vier vollständigen Originalreceipts
und ein unabhängiger deterministischer Prüfer bestätigen diese Bedingungen.

Der [Treiber](../../Tests/Release/Invoke-FileContentLeaseRecoveryLab.ps1) bindet
den schema-validierten Labvertrag, exakte Zielwahl, kanonische Exporte,
Produktquellen und Helfer. Die
[Fixture](../../Tests/Release/Runtime/FileContent.LeaseRecovery.Contract.ps1)
verwendet nur ausgewählte vorhandene Katalog-/Absenz-/Sperrhalter- und
externe Sitzungsorakel als Funktionen. Keine grünen API-/Repeat-/Lifecycle-
Vollsuiten werden erneut ausgeführt. Ein repräsentatives Ziel ist hier der
deklarierte Scope; keine zusätzliche physische Matrix wird behauptet.

```powershell
pwsh -NoProfile -File Tests/Release/Invoke-FileContentLeaseRecoveryLab.ps1 -RunsetPath $RunsetPath -CaseIndex 0
pwsh -NoProfile -File Tests/Release/Invoke-FileContentLeaseRecoveryLab.ps1 -RunsetPath $RunsetPath -CaseIndex 0 -AuditOnly
python -B Tests/Release/test_file_content_lease_recovery_lab_contract.py
```

Ein neuer nativer Lauf braucht weiterhin eigene konkrete endliche Autorität
und neue private Originaljournale. Ein `-ValidateOnly` prüft ohne Labimport
oder SQL-Zugriff. Dreizehn Offlinegegenproben bestehen: Authority-/Frist-/Ziel-/
Modus-/Pinabweichungen, verbotene Rechte-/Serveroperationen, eigene getrennte
SPID-Grenzen, Unterschied zwischen Statement- und Benutzertransaktion sowie
Abweisung von externen Transaktions-/Sperrlecks und Observerfehlern.

## Erhaltene Fehlerhistorie und Grenzen

| Abgegrenzte Welle | Methodencommit | Tatsächliches Ergebnis |
|---|---|---|
| ursprüngliche zwei Aufrufe | `2ca5950c703e2879fca2e9d1e5982016fb7f5f40` | FAILED_CLEANED vor erster Sperre; frischer Cleanup-Audit PASS |
| freigegebene Diagnose-/Restwelle, drei Aufrufe | `828bdb08a75e1ff5bd446f0d09e21c71809dcbbe` | FAILED_CLEANED nach erstem Sitzungsende und erfolgreichem Deploy/Katalogvergleich; frischer Cleanup-Audit PASS |
| freigegebener korrigierter Gesamtfall, zwei Aufrufe | `0f08069c07197c408acc34b2870ca8b3ff79db2b` | COMPLETE, vier vollständige Fälle und frischer Audit PASS |

Die erste Identitätsprüfung hatte den während einer lesenden DMV-Abfrage
beobachteten Statementzustand mit einer Benutzertransaktion verwechselt. Der
zusätzlich freigegebene reine Lesevergleich grenzte dies ein. Die korrigierte
Klassifizierung lässt weiterhin keine Benutzertransaktion zu. Die zweite
Nachprüfung verwendete Transaction-Owner bei APPLOCK_MODE ohne notwendige
Benutzertransaktion. Jetzt werden die bereits qualifizierten externen und
vor dem SELECT isoliert aufgenommenen Zustandsorakel wiederverwendet.
Der zuvor gescheiterte Gesamtfall wurde wegen dieser geänderten Nachprüfung
im ausdrücklich freigegebenen korrigierten Lauf erneut ausgeführt.

Alle drei Grenzen sind geschlossen: **sieben Ziel-/Auditaufrufe**, darin ein
reiner Diagnoseaufruf und drei frische Audits; sechs DB-Reservierungen,
vier tatsächlich angelegte und entfernte eigene Datenbanken. Jede Welle
behält ihren eigenen vorab festgelegten 45-Minuten-Rahmen. Keine Grenze oder
Fehlerhistorie wurde zurückgesetzt. Die beiden fehlgeschlagenen Koordinatoren
werden nicht nachträglich aufgewertet. Private Originale und Quellkapseln
bleiben außerhalb Git.

Functional verwendet die notwendige Verschlüsselung und den expliziten
Lab-Trustwert. Keine Rechte, Principals, Owner, CLR-/Trust-/Serveroptionen
oder Labressourcen wurden verändert; keine serverseitige Datei-I/O. Keine aktive Mutation wurde
unterbrochen. Clientprozess-/TDS-/OS-/VM-/Koordinatorverlust, echte
Lowpriv-CrossDB-Identitäten, Minimalrechte und weitere Recovery-/Provider-/
Ressourcenpflichten sind damit nicht qualifiziert. Modulstatus und Produkt-
SQL bleiben unverändert. Keine Veröffentlichung oder Tags.
