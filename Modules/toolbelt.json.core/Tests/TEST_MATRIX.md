# Shared Core – Abnahmematrix

Aktueller [physischer Ergänzungsnachweis2026-11-06](../../../Releases/1.0.0/JSON-SCHEMA-MISSING-TARGETS-QUALIFICATION.md):
Core wird mit seinem bestehenden Schema-Consumer auf acht weiteren physischen
Ziel-/CL-Paaren jeweils lokal/direkt zentral installiert, wiederholt und
deinstalliert. Core-Consumer-Abweisung, Erhalt bei Schema-Uninstall und eigener
Cleanup bestehen. Das sind16 neue Kontexte mit acht frischen Audits; kein
Constructor-Migrations-, vollständiger Owner-/Drift-/Lock- oder Modulgesamtfall.
Die nachfolgende ältere Tabelle bleibt in ihrem damaligen Scope erhalten.

| Bereich | Nachweis | Zustand |
|---|---|---|
| Budget und Tokenpolicy | 10 Budgetfälle, 37 Tokenfälle/95 Assertions | bestanden offline |
| Eigene IL und Negativfixtures | Geschlossene Bindungen; acht verbotene Fixtureklassen | bestanden offline |
| Buildidentität | Drei kanonische MSBuild-Projekte bytegleich | bestanden offline |
| Paketierung | Framing, Source-/Binarypins, Coreverweise | bestanden offline |
| Lifecycle-Syntax | Deploy/Uninstall in ScriptDom150/160/170 | bestanden offline |
| SQL Server2019/2022/2025, Windows/Linux | SAFE-Laden, Coreunsichtbarkeit, gemeinsame Owner | Linux2019 CL150 und Windows2025 CU8 CL150/160/170 local/central bestanden; weitere Ziele offen |
| Lifecycle | local/central, Repeat, Verbraucher-Abweisung, Erhalt nach Consumer-DROP | beide Ziele bestanden; Drift-/Owner-/Lockvollmatrix offen |
| Constructors1.2→1.3 | Atomare Neuerstellung eigener CLR-Slots, fünf Procedureidentitäten/Rechte erhalten, post-DROP-Rollback und zusätzliche Annotation abgewiesen | beide Ziele local/central bestanden; ALTER-Versuch6282 fehlgeschlagen |

Die ausführbaren Offline-Driver liegen in
[`toolbelt.json.schema/Tests/Framework`](../../toolbelt.json.schema/Tests/Framework/README.md).
Die nativen Teilnachweise und ihre Grenzen stehen in
[`NATIVE_EVIDENCE.md`](../../toolbelt.json.schema/Tests/NATIVE_EVIDENCE.md).
Die Benutzerfreigaben für die qualifizierten Trusthashes sind dokumentiert;
Deploymentskripte ändern Trust weiterhin nicht automatisch.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-05`
- Nachweis: `local: run-json-schema-lab.ps1 Windows CL150/160`
- Scope: Windows2025/exaktCU8 CL150 und CL160 jeweils local/central: Core-/Schema-Scope, Repeat, zwei Consumer-Abweisungen, Coreidentität nach Schema-DROP und eigenes DB-/Trustcleanup bestanden. Frische hashgebundene read-only Dispositionaudits bestanden. Genuine1.2→1.3 separat auf beiden zusätzlichen Windowslevels local/central mit post-DROP-Rollback, Annotationserhalt und frischem Dispositionaudit bestanden. Weitere Ziel-/Rechtematrix offen.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->

## JSON Core: direkte Lifecycle-Sperrmatrix — 2026-11-09

Die [gezielte Ergänzung](../../../Releases/1.0.0/JSON-CORE-APPLOCK-QUALIFICATION.md) belegt die direkte Core-Deploy-/Uninstall-
Sperrabwehr auf zwölf Windows-/Linux-Engine-/CL-Paaren lokal/direkt zentral:
24 Kontexte,48 exakte55627/1/16-Abweisungen unter eigener bestätigter
exklusiver Sitzungssperre,48 erfolgreiche Schritte nach verifizierter Freigabe.
Coreprojektion und lokale/externe Sitzungsneutralität erhalten, kanonischer
Repeat beziehungsweise vollständiger Uninstall geprüft. Vorhandene Schema-
Shared-Lock-Belege bleiben getrennt; keine API-Vollsuiten wiederholt.
Erster Adapterfehler wegen fehlendem SPID-Parameter bleibt FAILED_CLEANED;
Gegenprobe mit echtem Orakel reproduziert ihn, korrigierter Rest vollständig
PASS.26 verbrauchte Aufrufe/DB-Reservierungen im gemeinsamen28/28/45-Minuten-
Rahmen,25 tatsächlich angelegte DBs entfernt,13 frische Audits einschließlich
Fehlversuch. Eigene Trust-/notwendige CLR-Konfigurationsänderungen nach
bestehenden Freigaben vollständig zurückgenommen; fremde Zustände unverändert.
Keine neuen Builds, Produkt-/Manifest-/Statusänderungen, Grants/Principals/
Owner-/Lab-/serverseitige Datei-I/O. Weitere Owner-/ACL-/Drift-/Migrations-/
SET-/Ressourcen-/Recoverypflichten bleiben separat. Private Originale und
Quellkapseln erhalten; keine Veröffentlichung oder Tags.

## JSON Core: fünf direkte Lifecycle-Grenzen — 2026-11-10

Der [neue Teilnachweis](../../../Releases/1.0.0/JSON-CORE-FIVE-BOUNDARIES-QUALIFICATION.md) prüft
Callertransaktionen ohne/mit Core, verwaiste DB-Marker, sechs typisierte
Assembly-Marker und Argument-/Consumer-Bestätigungen. Zwölf Windows-/Linux-
Zielpaare sind lokal/zentral mit 876 eindeutigen Profilen belegt: zehn vollständige
Paare plus zwei gezielte Restläufe, die 28 gültige Originalprofile unverändert
verwenden. Beide ursprünglichen Fehler bleiben FAILED_CLEANED. Vierzehn frische
Audits, 26 eigene DBs entfernt; Konfiguration/Trust im Vorzustand, keine neuen
Rechte/Identitäten. Die unnötigen Rückfragen wurden zurückgenommen: nur echte
Lücken innerhalb derselben unveränderten 28-Aufrufe-/28-DB-/45-Minuten-Grenze,
keine neue Freigabe, Frist oder Welle. Die fünf Punkte sind abgeschlossen;
keine Modulgesamtaufwertung. Alte Sperr-/Consumerbelege nicht wiederholt.
Private Originale erhalten, keine Veröffentlichung.

## Binary-, Registrierungs- und CL-Guards — 2026-11-12

Der [gemeinsame Core-/Schema-Nachweis](../../../Releases/1.0.0/JSON-LIFECYCLE-BINARY-REGISTRATION-QUALIFICATION.md)
schließt fünf Restmatrizen: ungültige Zielbytes beider Deploy-Einstiege,
installierte DB-Version-/Modusdrift bei Deploy/Uninstall und tatsächliche
CL140-Abweisung aller vier Lifecycleeinstiege. 816 eindeutige Profile auf24
lokalen/direkt zentralen Windows-/Linux-Kontexten; zwölf Erstläufe und zwölf
frische unabhängige Audits PASS. Alle24 eigenen DBs/Trusteinträge entfernt,
fünf eigene Konfigurationsänderungen zurückgenommen. CL140 je physischer
Engine/Modus einmal geprüft, keine identischen Wiederholungen bei höheren
Ausgangs-CLs. Zwölf Offlinegegenproben und kanonischer Preflight bestanden.
24/32 Aufrufe und24/32 DB-Reservierungen innerhalb60Minuten geschlossen.
Frühere pauschale Drift-/CL-Offenangaben gelten für genau diese Varianten
nicht mehr; andere Owner-/ACL-/Identitäts-/Recoverypflichten bleiben getrennt.
Historische Abschnitte und generierte Evidenz unverändert; Module weiterhin
partially validated, unreleased. Keine Produkt-/Rechteänderung oder Veröffentlichung.

## Fehlende Marker und Sichtbarkeitsgrenzen — 2026-11-12

Der [gemeinsame Core-/Schema-Nachweis](../../../Releases/1.0.0/JSON-MARKER-ABSENCE-VISIBILITY-QUALIFICATION.md)
schließt die deklarierten missing/null-Matrizen der Assemblymarker, Ownership-
marker an beiden Schema-Slots, direkte/delegierte Core-Sichtbarkeitsabwehr und
die tatsächliche SQL-Engine-Sperre6284 bei verwendeter Schema-Assembly.
1848 eindeutige Profile auf24 lokalen/direkt zentralen Windows-/Linux-Kontexten,
davon76 unverändert übernommen und1772 neu. Ein ursprünglicher Koordinator
bleibt FAILED_CLEANED; zwölf korrigierte Koordinatoren/13 frische Audits PASS.
Die öffentlichen Schema-Guards bei unsichtbarer vollständiger Installation sind
not executed: deren Zustand wird bereits durch die Engine verhindert. Keine
Umdeutung der24 Engineprofile zu48 öffentlichen Lifecycle-Abweisungen.
Alle25 eigenen DBs/26 Trusteinträge entfernt, sechs Konfigurationsscopes
wiederhergestellt;26/32 Aufrufe/DB-Reservierungen innerhalb derselben60Minuten
abgeschlossen, keine Grenzen erneuert oder grünen Profile wiederholt.
Andere Owner-/ACL-/Identitäts-/Recoverypflichten bleiben separat. Historische
und generierte Evidenz unverändert, weiterhin partially validated, unreleased.

## Typisierte Markerwerte, fehlende Registrierung und Parameternamen — 2026-11-13

Die [gemeinsame Fünfpunktmatrix](../../../Releases/1.0.0/JSON-TYPED-VALUES-PARAMETER-NAMES-QUALIFICATION.md)
schließt falsche gleich typisierte/gleich lange Assemblymarkerwerte bei Core
und Schema, gelöschte DB-Version-/Modusregistrierung beider installierter Module
und reine Namensdrift aller zwölf öffentlichen Schema-Parameter. 1344 eindeutige
Profile auf24 lokalen/direkt zentralen Windows-/Linux-Kontexten; zwölf Erstläufe
und zwölf frische Audits PASS. Alle24 eigenen DBs/Trusteinträge entfernt, fünf
Konfigurationsscopes zurückgenommen. Ursprünglicher32/32/60-Minuten-Rahmen mit
24 Aufrufen/DB-Reservierungen geschlossen; kein nativer Fehler oder Retry.
Gültige Typdrift-/NULL-/Fehlmarker-/Signaturtypbelege nicht wiederholt. Typisierte
Originale und ursprüngliche Prozedurdefinitionen exakt wiederhergestellt;
DDL-Zeitstempel der temporären Fixture sind kein behaupteter Restorevertrag.
Weitere Owner-/ACL-/Identitäts-/Recoverypflichten bleiben separat. Historische
und generierte Evidenz unverändert, weiterhin partially validated, unreleased.
