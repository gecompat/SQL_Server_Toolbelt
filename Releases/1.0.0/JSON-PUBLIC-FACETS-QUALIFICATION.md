# JSON Schema: zwanzig öffentliche Parametergrenzen

Stand 2026-11-13: **PASS_FOR_DECLARED_TWENTY_POINT_MATRIX**. Die ausgewählten
zwanzig Parameter-Typ-/Längenfälle bestehen jeweils in 24 lokalen beziehungsweise
direkt zentralen Windows-/Linux-Kontexten über beide öffentlichen Lifecycle-
Einstiege: 960 eindeutige neue Profile. Alle zwölf Erstkoordinatoren und zwölf
frischen unabhängigen Abschlussaudits sind PASS. Kein nativer Fehlversuch oder
Retry, keine Produkt-/Binäränderung und keine vollständige Modulqualifikation.

## Auswahl und Wiederverwendung

Der Benutzer beauftragte ausdrücklich die nächsten zwanzig bereits freigegebenen
Qualifikationspunkte, Wiederverwendung gültiger Nachweise und Tests ausschließlich
echter Lücken. Hier sind die zwanzig Punkte als konkrete neue Parameter-
Deklarationsgrenzen benannt; jeder Punkt wird in allen 24 Kontexten geprüft.
Es handelt sich nicht um zwanzig neue Funktionen oder eine Erweiterung des
öffentlichen Produktvertrags.

Die [bisherigen öffentlichen Signaturformen](JSON-SIGNATURE-SHAPE-QUALIFICATION.md),
[Parameternamen und typisierten Werte](JSON-TYPED-VALUES-PARAMETER-NAMES-QUALIFICATION.md)
und [internen CLR-Facetten](JSON-CLR-FACETS-QUALIFICATION.md) bleiben unverändert
in ihren ursprünglichen Scopes gültig. Bereits geprüfte kurze Längen, frühere
Typabweichungen, Alias-/OUTPUT-/Arity-/Ordinal-/Namensfälle werden nicht erneut
ausgeführt. Ein öffentlicher USP-Parameter ist dabei ein anderer Slot als
der getrennt geprüfte interne CLR-Parameter.

## Die zwanzig tatsächlich geprüften Punkte

Jede Zeile bedeutet eine einzelne ersetzte Parameterdeklaration bei ansonsten
unverändertem Namen, Ordinal, Defaultliteral und Prozedurinhalt. Pro Zeile
bestehen 48 öffentliche Profile: 24 Kontexte mal Deploy und Uninstall.

| Punkt | Parameter | Ursprüngliche Deklaration | Neue negative Fixture | Profile bestanden/geplant |
|---|---|---|---|---|
| 1 | Json | nvarchar(max) | nchar(4000) | 48/48 |
| 2 | Schema | nvarchar(max) | nchar(4000) | 48/48 |
| 3 | Profile | varchar(32) | char(32) | 48/48 |
| 4 | Profile | varchar(32) | nvarchar(32) | 48/48 |
| 5 | Profile | varchar(32) | varchar(33) | 48/48 |
| 6 | Profile | varchar(32) | varchar(max) | 48/48 |
| 7 | MaxDocumentBytes | bigint | decimal(19,0) | 48/48 |
| 8 | MaxSchemaBytes | bigint | decimal(19,0) | 48/48 |
| 9 | MaxEvaluationSteps | bigint | decimal(19,0) | 48/48 |
| 10 | MaxDepth | int | bigint | 48/48 |
| 11 | MaxErrors | int | bigint | 48/48 |
| 12 | Debug | tinyint | int | 48/48 |
| 13 | KeepData | bit | int | 48/48 |
| 14 | Hilfe | bit | int | 48/48 |
| 15 | ResultTable | sysname | nvarchar(129) | 48/48 |
| 16 | ResultTable | sysname | nchar(128) | 48/48 |
| 17 | Json | nvarchar(max) | nvarchar(1) | 48/48 |
| 18 | Schema | nvarchar(max) | nvarchar(1) | 48/48 |
| 19 | Profile | varchar(32) | varchar(1) | 48/48 |
| 20 | ResultTable | sysname | nvarchar(1) | 48/48 |

Die drei decimal-Fälle prüfen ausdrücklich auch Precision 19, Scale 0 und
die tatsächliche Kataloglänge 9. Bei den sysname-Abweichungen sind der Wechsel
vom eingebauten Alias und die neue Typ-/Längenform gemeinsam ausgewählt;
das ist kein isolierter Nachweis nur eines einzelnen Guardprädikats.
Defaultliterale bleiben im gespeicherten SQL erhalten. Ein daraus entstehendes
anderes Default-Konvertierungsverhalten der negativen Fixture wird nicht
fachlich ausgeführt oder als neuer Produktvertrag qualifiziert.

## Physische Matrix

| Plattform | Engine/Patch | CL | Ergebnis lokal und direkt zentral |
|---|---|---|---|
| Windows | SQL 2019/CU32 | 150 | 80 Profile, frischer Audit PASS |
| Windows | SQL 2022/CU26 | 150, 160 | je 80 Profile, je frischer Audit PASS |
| Windows | SQL 2025/CU8 | 150, 160, 170 | je 80 Profile, je frischer Audit PASS |
| Linux | SQL 2019/latest | 150 | 80 Profile, frischer Audit PASS |
| Linux | SQL 2022/latest | 150, 160 | je 80 Profile, je frischer Audit PASS |
| Linux | SQL 2025/latest | 150, 160, 170 | je 80 Profile, je frischer Audit PASS |

Die Einzelziele sind schema-validiert, explizit ausgewählt und READY.
Tatsächliche Engine, Plattform und CL werden geprüft. Der unveränderte
Functional-Transport belegt keine authentifizierte TLS-/Windows-/GUI-/CLI-Anmeldung.

## Quelle, tatsächliche Facetten und exakter Restore

Der [vorhandene Runner](../../Tests/Release/Invoke-JsonLifecycleBinaryRegistrationLab.ps1)
wählt die [neue Fixture](../../Tests/Release/Runtime/JsonLifecycle.PublicFacets.Contract.ps1)
nur für `json-lifecycle-public-facets/v1`. Qualifizierte bekannte Core-/Schema-
Paketbinaries, Quell-/Projekt-/Compiler-/Registry-/SHA256-/SHA512-Bindungen und
kanonische Original-Includebäume bleiben erforderlich. Die negativen Aufrufe
verwenden die unveränderten originalen öffentlichen Deploy-/Uninstall-Scripts.
Keine Ersatzguards oder unbekannten Binaries.

Die Fixture installiert die kanonische Baseline und stabilisiert die bestehende
CREATE/ALTER-Katalogrepräsentation vor dem ersten Snapshot. Sie erfasst die
ursprüngliche vollständige Prozedurdefinition und alle zwölf Parameter.
Die bereits qualifizierte gemeinsame Headertransformation ersetzt ausschließlich
den ausgewählten Parameter-Typtoken vor `AS BEGIN`. Der fachliche Inhalt und
die übrigen Deklarationen einschließlich Defaults bleiben erhalten.

Vor jedem öffentlichen Guardaufruf wird der tatsächliche Katalog vollständig
verglichen: parameter_id, Name, system_type_id, user_type_id, max_length,
Precision, Scale und OUTPUT. Nur die für diese eine Deklaration ausgewählten
Typ-/Längen-/Precision-/Scale-Facetten dürfen abweichen. Nicht eingetretene oder
zusätzliche Änderungen führen zum Abbruch, nicht zu einem erfolgreichen Profil.

Beide öffentlichen Lifecycle-Einstiege müssen genau Fehler 55633, State 1,
Severity 16 mit dem unveränderten Text zur inkohärenten öffentlichen
Parametersignatur liefern. Ein anderer Fehler oder ein erfolgreicher Lifecycle-
Aufruf ist kein PASS. Der vollständige beschädigte Zustand muss nach jedem
Aufruf identisch bleiben; externe Sitzungs-/Transaktions-/AppLock-Orakel bestehen.

Vor Restore wird derselbe beschädigte Snapshot erneut geprüft. Danach wird die
vollständige ursprüngliche Prozedurdefinition mit dem vorhandenen kanonischen
CREATE/ALTER-Helper zurückgestellt; der ursprüngliche Gesamtsnapshot muss exakt
passen. Er enthält Moduldefinitionen, Parameter-/CLR-Metadaten, Objekt-/Assembly-
identitäten, Owner, Rechte, Principals, Rollenmitgliedschaften, typisierte
Properties und Core-Projektion. Es werden keine neuen Types, Rechte, Principals
oder Owner angelegt. Die veränderte öffentliche API wird nicht fachlich aufgerufen.

## Prüfungen und endlicher Abschluss

Methodenstand `298f8be0`: zwei neue
[Offlinegegenproben](../../Tests/Release/test_json_public_facets_lab_contract.py),
zwei betroffene bisherige Gegenproben und quellgebundener kanonischer Preflight
sind PASS. Die Gegenproben prüfen genaue Fixture-/Pinauswahl, zwanzig geschlossene
Vektoren mit 40 Keys je Kontext, unveränderten Prozedurinhalt, exakte Header-
Änderung und Ablehnung unveränderter oder zusätzlich veränderter Kataloge sowie
unselektierter Vektoren/CLs. Die neue Suite ergänzt den bestehenden Releasevalidator;
keine zusätzlichen CI-Jobs oder Trigger. Head- und tatsächliche Main-PUSH-CI
bleiben Integrationsgates.

Ein Verantwortlicher, keine Agenten. Derselbe vorab gewählte gemeinsame Rahmen
von 32 Ziel-/Auditaufrufen, 32 DB-Reservierungen und 60 Minuten ist mit
**24/32 Aufrufen und 24/32 DB-Reservierungen** innerhalb der ursprünglichen
Frist geschlossen. Die unbenutzte Reserve bleibt geschlossen. Alle 24 eigenen
Datenbanken und 24 eigenen Releasehash-Trusteinträge sind entfernt; fünf eigene
Konfigurationsänderungen sind zurückgenommen. Notwendige eigene CLR-Konfiguration
und bekannter Releasehashtrust verwenden die bestehende Root-Freigabe mit Journal,
Ownership-/Verbraucherprüfung und Wiederherstellung. Keine neuen Labressourcen,
Serverneustarts oder Zertifikats-/Truststoreänderungen.

Eine getrennte private Auswertung rekonstruiert alle 960 Profilkeys ohne
Lücken oder Duplikate, jeweils 48 pro Punkt. Sie prüft finale Journal-/Audit-
Bindungen, Ressourcenabwesenheit, Quellenkapseln, aktuelle Produktpins und die
gemeinsame Frist. Private Originale und aktive unabhängige Arbeit bleiben erhalten.
Schema bleibt **partially validated, unreleased**. Andere Rechte-, Identitäts-,
Binding-, Recovery- und Ressourcenpflichten bleiben separat. Keine Veröffentlichung
oder Tags.
