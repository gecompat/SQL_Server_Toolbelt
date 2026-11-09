# JSON Schema: früher Caller-Guard bei XACT_ABORT ON

Am 2026-11-09 bestanden **vier neue negative Sessionfälle und ein frischer
unabhängiger Audit** auf Windows SQL2025/CU8, CL170, Functional. Ergebnis:
**PASS_FOR_DECLARED_JSON_SCHEMA_XACT_ABORT_ON_SCOPE**. Die einzige eigene
Testdatenbank ist entfernt; Konfiguration und Assemblytrust sind unverändert.
Keine Produkt-/Manifest-/Statusänderung.

## Neuer Input und bestehende Nachweise

Der [vorhandene Caller-Nachweis](json-schema-caller-transaction-qualification.json)
prüft XACT_ABORT OFF/NOCOUNT OFF, Deploy bei fehlendem Schema und Uninstall bei
installiertem Schema mit vorhandenen Abhängigkeiten. Er bleibt unverändert.
Hier sind **keine Toolbelt-Module oder Benutzerassemblies installiert**:

| Öffentliches Skript | XACT_ABORT | NOCOUNT | Module vor/nach Guard |
|---|---|---|---|
| Deploy, Argument DeploymentMode=local | ON | OFF | abwesend |
| Deploy, Argument DeploymentMode=local | ON | ON | abwesend |
| Uninstall, Argument ConfirmNoExternalConsumers=1 | ON | OFF | abwesend |
| Uninstall, Argument ConfirmNoExternalConsumers=1 | ON | ON | abwesend |

QUOTED_IDENTIFIER ist ON, IMPLICIT_TRANSACTIONS OFF. Keine Installation oder
positive Lifecyclekontrolle; kein installierter Uninstall-ON-, Core-/Schema-
Lifecycle- oder vollständiger Sessionmatrixnachweis. Der frühe Guard muss vor
allen nachfolgenden Voraussetzungen und SET-Anweisungen stoppen.

## Originalquelle und Orakel

[Adapter](../../Tests/Release/Invoke-JsonSchemaXactAbortLab.ps1) und
[Fixture](../../Tests/Release/Runtime/JsonSchema.XactAbort.Contract.ps1) liefen aus
[d0285912](https://github.com/gecompat/SQL_Server_Toolbelt/commit/d0285912a1b11477f4f98d18e8120bddc53eee93).
Die vollständigen öffentlichen Texte werden mit den kanonischen Include-/
Variablenfunktionen expandiert und exakt gegen die privaten Skriptbytes geprüft.
Keine vorgeschaltete Standalone-Exportwache oder nachgebauter SQL-Guard.
AssemblyBits referenzieren nur die unveränderte
[qualifizierte Paket-DLL](JSON-SCHEMA-PACKAGE-QUALIFICATION.json); sie wird nicht
geladen. Kein Build, Trusteintrag oder CLR-Konfigurationsschritt.

Das r35-Caller-/Savepointorakel sowie r33-Katalog-/Observerfunktionen werden
quellgebunden als Funktionen wiederverwendet, keine OFF/OFF-Gesamtadapter.
Tatsächliche Sessionbits sind vor jedem Fall geprüft und privat gebunden.
Jeder Fall etabliert eine gesunde Callertransaktion mit festem Wertverlauf
100→200→Savepoint→300. Erwartet ist exakt50000/State1/Class16 mit
`JSON_SCHEMA_CALLER_TRANSACTION: aktive Callertransaktion ausgeschlossen.`
Dieselbe offene Sitzung bleibt gesund bei @@TRANCOUNT=1/XACT_STATE()=1;
sämtliche beobachteten Optionen, Modul-/Rechte-/Principal-Snapshot und Wert300
bleiben erhalten. Savepointrollback ergibt200, voller Callerrollback100 und
neutrale Sitzung. Eine getrennte Verbindung beobachtet aktive Usertransaktion
und anschließende Ruhe, ohne Application Locks. Alle vier Originalreceipts bestehen.

## Endlicher Rahmen und unabhängiger Abschluss

Ausdrücklicher autonomer Restqualifikationsauftrag, vor Admission begrenzt:
ein Verantwortlicher ohne Agents; **ein Lauf und ein reservierter frischer
Audit, höchstens zwei Ziel-/Auditaufrufe, eine eigene DB und 45 Minuten,
keine Wiederholung**. Beide Aufrufe innerhalb der Frist bestanden; 2/2 Aufrufe
und 1/1 DB-Reservierung sind verbraucht und geschlossen. Alte Grenzen, Fehler
und Originalberichte bleiben unverändert.

Schema-validierter Functional-Vertrag, exaktes READY-Ziel, tatsächliche Ziel-/
CL-Prüfung, Verschlüsselung und unveränderter expliziter Trustwert. Vorhandene
administrative SQL-Anmeldung über Windows-Client; keine GUI-/Windows-Login-,
Linux-/CrossDB-Identitäts- oder authentifizierte TLS-Abnahme. Keine neuen Rechte/
Identitäten, Owner-/Server-/Lab-/Datei-I/O-Änderungen.

Der separate Audit bindet finales Journal, tatsächliches Ziel, DB-Abwesenheit,
gesamte unveränderte Konfiguration/Assemblytrust und Eingabepins. Ein privater
Nachprüfer bestätigt vier Profile mit tatsächlichen Optionsbits, Witnessverlauf,
Originalreceipts, Audit und Quellenbindungen. DB-Entfernung verlangt eigene
Identität/Erstellungszeit/Ownermarker. Private Originale und Quellkapseln bleiben erhalten.

Sieben [verbindungslose Gegenproben](../../Tests/Release/test_json_schema_xact_abort_lab_contract.py)
prüfen Zulassung, Ziel/Modus/Frist, Method-/Includepins sowie die Ablehnung einer
umgehashten Fremd-DLL und eines umgehashten gekürzten SQL-Skripts. Kanonischer
Preflight bestanden; Tests zentral registriert. Übrige Lifecycle-/Session-/
Owner-/Drift-/Lock-/Rechte-/Ressourcen-/Recoverypflichten bleiben separat.
Keine weitere SQL-Welle, Modulgesamtabnahme, Veröffentlichung oder Tags.
