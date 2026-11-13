# Core und Schema: zehn Registrierungs-Textmatrizen

Stand 2026-11-13: **PASS_FOR_DECLARED_TEN_POINT_MATRIX**. Die ausgewählten
zehn Matrizen bestehen mit 2.208 eindeutigen öffentlichen Lifecycle-Profilen
in 24 lokalen beziehungsweise direkt zentralen Windows-/Linux-Kontexten.
Alle zwölf Erstläufe und zwölf frischen unabhängigen Abschlussaudits sind PASS.
Kein nativer Fehlversuch oder Retry. Produktquellen und Binaries bleiben
unverändert; dies ist keine vollständige Modul- oder Releasequalifikation.

## Auswahl der echten Lücken

Der Benutzer beauftragte die nächsten zehn freigegebenen Qualifikationspunkte
mit Wiederverwendung gültiger Nachweise. Die
[typisierten Werte und Parameternamen](JSON-TYPED-VALUES-PARAMETER-NAMES-QUALIFICATION.md),
[fehlenden Marker](JSON-MARKER-ABSENCE-VISIBILITY-QUALIFICATION.md) und
[bisherigen Dependency-Wertkontexte](JSON-DEPENDENCY-VALUE-CONTEXTS-QUALIFICATION.md)
bleiben unverändert in ihren ursprünglichen Scopes gültig.

Die bisherige Objekt-Ownership-Abweisung mit `ContosoInvalidOwnership`
belegt nicht die hier erstmals geprüften, nahe am gültigen Text liegenden
Werte. Ebenso werden die früheren DB-NULL-/Löschungs-/Altversions- und
Großschreibungs-/Gegenmodusfälle nicht erneut ausgeführt. Die aktuelle
Auswahl enthält vier DB-Registrierungsmatrizen und sechs Matrizen für die
drei Ownership-Properties an beiden vorhandenen Schema-Slots:

| Punkt | Neue Eingaben | Mutationen pro Modus | Öffentliche Profile bestanden/geplant |
|---|---|---|---|
| 1 | Core-DB-Version: kurz, vierte Komponente, negative Komponente, Integerüberlauf, führende Null, nachgestelltes Leerzeichen | 6 | 288/288 |
| 2 | Schema-DB-Version: dieselben sechs Formgrenzen relativ zur aktuellen Schema-Version | 6 | 288/288 |
| 3 | Core-DB-Modus: leer, nachgestelltes/vorangestelltes Leerzeichen, unbekannter Wert | 4 | 192/192 |
| 4 | Schema-DB-Modus: dieselben vier Formgrenzen | 4 | 192/192 |
| 5 | Objekt-ModuleId: Großschreibung | 2 | 96/96 |
| 6 | Objekt-ModuleId: nachgestelltes/vorangestelltes Leerzeichen | 4 | 192/192 |
| 7 | Objekt-ModuleVersion: führende Null beziehungsweise vierte Komponente | 4 | 192/192 |
| 8 | Objekt-ModuleVersion: nachgestelltes/vorangestelltes Leerzeichen | 4 | 192/192 |
| 9 | Objekt-DeploymentMode: Großschreibung beziehungsweise Gegenmodus | 4 | 192/192 |
| 10 | Objekt-DeploymentMode: leer, nachgestelltes/vorangestelltes Leerzeichen, unbekannter Wert | 8 | 384/384 |

Die Objektfälle betreffen jeweils `toolbelt_json.USP_ValidateJsonSchema`
und `toolbelt_json.FT_ValidateJsonSchemaInternal`. Pro Modus werden genau
46 einzelne Property-Mutationen geprüft, jede durch den originalen öffentlichen
Deploy und Uninstall: 92 Profile pro Modus, 184 pro Engine-/CL-Paar.
Davon sind insgesamt 480 direkte Core- und 1.728 direkte Schema-Einstiege.

Die Core-Versionseingaben sind `1.0`, `1.0.0.0`, `1.0.-1`,
`2147483648.0.0`, `01.0.0` und `1.0.0 ` mit Leerzeichen.
Für Schema sind es `1.0`, `1.0.1.0`, `1.0.-1`, `2147483648.0.0`,
`01.0.1` und `1.0.1 ` mit Leerzeichen. Die aktuellen gültigen Modulversionen
werden nicht verändert. Objektversionen verwenden `01.0.1`, `1.0.1.0`,
`1.0.1 ` beziehungsweise ` 1.0.1`. Der unbekannte Moduswert ist `contoso`.
Jede Case-/Whitespace-Abweichung muss tatsächlich andere Rohbytes besitzen;
ein unverändert gebliebener Wert ist kein negativer Test.

## Physische Zielmatrix

| Plattform | Engine/Patch | CL | Ergebnis lokal und direkt zentral |
|---|---|---|---|
| Windows | SQL 2019/CU32 | 150 | 184 Profile, frischer Audit PASS |
| Windows | SQL 2022/CU26 | 150, 160 | je 184 Profile, je frischer Audit PASS |
| Windows | SQL 2025/CU8 | 150, 160, 170 | je 184 Profile, je frischer Audit PASS |
| Linux | SQL 2019/latest | 150 | 184 Profile, frischer Audit PASS |
| Linux | SQL 2022/latest | 150, 160 | je 184 Profile, je frischer Audit PASS |
| Linux | SQL 2025/latest | 150, 160, 170 | je 184 Profile, je frischer Audit PASS |

Die Ziele sind explizit ausgewählt, schema-validiert und READY; tatsächliche
Engine, Plattform und CL werden geprüft. Der unveränderte Functional-Transport
belegt keine authentifizierte TLS-, Windows-, GUI- oder SQLCMD-CLI-Anmeldung.

## Methode und exakte Abweisung

Die [neue Fixture](../../Tests/Release/Runtime/JsonLifecycle.RegistrationText.Contract.ps1)
ist ausschließlich dem versionierten Scope `json-lifecycle-registration-text/v1`
des [vorhandenen Runners](../../Tests/Release/Invoke-JsonLifecycleBinaryRegistrationLab.ps1)
zugeordnet. Sie installiert die unveränderte kanonische ResultTable-/Core-
Baseline und Schema. Alle negativen Aufrufe verwenden die originalen
öffentlichen Deploy-/Uninstall-Exporte, keine verkürzten Guards oder
Ersatzimplementierungen. Paket-/Quell-/Compiler-/Projekt-/Registry- sowie
SHA256-/SHA512-Bindung der bekannten Core-/Schema-Binaries werden geprüft.

Die zehn ursprünglichen Properties werden als `sql_variant` in einer
Caller-Temp-Tabelle erfasst: vier DB-Registrierungen und je drei Properties
an den zwei Schema-Slots. Vor jeder Mutation muss genau ein ursprünglicher
Eintrag nach Klasse, Objektidentität und Namen auflösbar sein. Unbekannte
Specs, Properties, Slots, Varianten und Modi sind ausgeschlossen.

Der öffentliche Core-Deploy und die Core-Versionsfälle des Uninstall müssen
genau Fehler 55623, State 1, Severity 16 mit dem Text zur fehlenden kohärenten
bekannten technischen SAFE-Assembly liefern. Der Core-Modus-Uninstall liefert
denselben Code mit dem Text zum inkohärenten installierten Modus.
Für Schema-DB-Fälle sind es 55633/State 1/Severity 16 und der Text zum
unbekannten/inkohärenten Releasezustand; der Schema-Modus-Uninstall verlangt
den Text zum inkohärenten installierten Modus. Alle Objektfälle verlangen
55633/State 1/Severity 16 mit dem unveränderten objektgenauen Ownershiptext.
Andere Fehler oder ein erfolgreicher beschädigter Lifecycle-Aufruf sind kein PASS.

Vor und nach jeder Abweisung muss der vollständige beschädigte Snapshot
identisch bleiben. Vor dem Restore wird dies erneut geprüft; anschließend
muss der ursprüngliche Gesamtsnapshot exakt passen. Die Rückstellung übernimmt
den ursprünglichen `sql_variant` und damit Wert, Typ und Längenfacetten.
Die negativen Textmutationen selbst behaupten keine unveränderte Typfacette.

Die etablierten Snapshots erfassen Moduldefinitionen, CLR-Bindings,
Objekt-/Assemblyidentitäten, Owner, Rechte, Principals, Rollenmitgliedschaften,
typisierte Rohproperties und relevante Core-/Schema-Metadaten. Unabhängige
Sitzungs-/AppLock-Orakel prüfen Transaktionsneutralität. Erst nach allen
Restores folgen die kanonischen Schema- und Core-Uninstaller zum Cleanup;
daraus wird kein neuer vollständiger API-/Migrations-/Uninstallvertrag abgeleitet.

## Validierung und endlicher Abschluss

Methodenstand `15515673`: zwei neue
[Offlinegegenproben](../../Tests/Release/test_json_registration_text_lab_contract.py)
und zwei betroffene bisherige Gegenproben bestehen. Sie prüfen die konkrete
Fixtureauswahl, erforderliche Pins, exakte 92 Keys und zehn Gruppen,
Parameterrouting, unterschiedliche Fehlertexte je Einstieg, Abweisung
unselektierter Properties/Modi/CLs und Restore-/Mutationsgrenzen.
Der quellgebundene kanonische `-ValidateOnly`-Preflight ist PASS.
Die neue Suite ergänzt den bestehenden Releasevalidator; keine zusätzlichen
CI-Jobs oder Trigger. Head- und tatsächliche Main-PUSH-CI bleiben Integrationsgates.

Ein Verantwortlicher, keine Agenten. Der gemeinsame vorab gewählte Rahmen
von 32 Ziel-/Auditaufrufen, 32 DB-Reservierungen und 60 Minuten ist mit
**24/32 Aufrufen und 24/32 DB-Reservierungen** innerhalb der ursprünglichen
Frist geschlossen. Unbenutzte Reserve bleibt geschlossen. Alle 24 eigenen
Datenbanken und 24 eigenen Releasehash-Trusteinträge sind entfernt;
fünf eigene Konfigurationsänderungen sind zurückgenommen.
Keine neuen Rechte, Principals, Owner, unbekannten Binaries, Serverneustarts,
Labressourcen oder Zertifikats-/Truststoreänderungen. Notwendiger eigener
CLR-Parameter-/Hashtrustscope verwendet die bestehende Root-Freigabe mit
Journal, Ownership-/Verbraucherprüfung und Wiederherstellung.

Eine getrennte private Auswertung rekonstruiert alle 2.208 Profilkeys ohne
Lücke oder Duplikat und prüft finale Journal-/Auditbindung, Ressourcenabwesenheit,
Quellenkapseln, aktuelle Produktpins und gemeinsame Frist. Private Originale
und historische Fehler anderer Wellen bleiben unverändert erhalten.
Core und Schema bleiben **partially validated, unreleased**; andere Rechte-,
Identitäts-, Binding-, Recovery- und Ressourcenpflichten bleiben separat.
Keine Veröffentlichung oder Tags.
