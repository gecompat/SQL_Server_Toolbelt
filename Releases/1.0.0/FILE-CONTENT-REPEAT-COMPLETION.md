# File Content: befüllte Repeat-Matrix abgeschlossen

Die ausdrücklich freigegebene korrigierte Restwelle bestand am 2026-11-08
für **File Content 1.0.0 mit ResultTable 1.0.0**: neun vollständige Läufe,
**18 lokale/direkt zentrale Kontexte, 36 vollständige SQL-Fixtures und neun
frische unabhängige Windows-Clientaudits**. Alle 18 eigenen Datenbanken sind
entfernt. Ergebnis: **PASS_FOR_DECLARED_FILE_CONTENT_REPEAT_SCOPE**.
Die Gesamtqualifikation des Moduls bleibt `partially validated`, `unreleased`.

## Neue Ausführungen und wiederverwendete Fälle

| SQL-Ziel | Neue Compatibility Levels | Modi | Neue Kontexte |
|---|---|---|---:|
| Windows 2019/CU32 | 150 | lokal/direkt zentral | 2 |
| Windows 2022/CU26 | 150, 160 | lokal/direkt zentral | 4 |
| Windows 2025/CU8 | 150, 160, 170 | lokal/direkt zentral | 6 |
| Linux 2022/latest | 150 | lokal/direkt zentral | 2 |
| Linux 2025/latest | 150, 160 | lokal/direkt zentral | 4 |

Die drei Linux-Default-CL-Paare 2019/150, 2022/160 und 2025/170 bleiben
aus [Main-CI 41110007002](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/41110007002)
wiederverwendet. Alle 23 im [vorherigen Bindungsbericht](FILE-CONTENT-REPEAT-QUALIFICATION.md)
genannten Eingabedateien wurden vor der neuen Statuspflege erneut als identisch
bestätigt. Zusammen sind **zwölf Engine-/CL-Paare und 24 Repeat-Kontexte**
belegt: 18 neu und sechs früher ausgeführte. Das ist kein neuer Zwölf-Fälle-Lauf;
die alten CI-Fälle erhalten keine nachträglich erfundenen frischen Lab-Audits.

Die einzige anschließende Manifeständerung setzt Windows von `not executed`
auf `partially validated` für den jetzt bestandenen Lifecycle-Teilumfang.
SQL-Produktquellen, Parameter, Version und Provider bleiben unverändert.
Der alte Manifestpin wird nicht umgeschrieben; seine Originalbytes liegen in
der privaten Quellkapsel. Der Nachprüfer erlaubt ausschließlich diesen exakt
bestimmten Statuswechsel, keine sonstige Quelldrift.

## Unveränderte Orakel und nun native Korrekturbestätigung

Der [qualifizierte Adapter](../../Tests/Release/Invoke-FileContentRepeatLab.ps1)
lief mit dem Quellenstand
[d72641ff](https://github.com/gecompat/SQL_Server_Toolbelt/commit/d72641ffe5c70dc0c74e9f0586501a51420f7e4b).
Jeder Kontext führte die vollständigen Originale
[RepeatCurrent.Contract.sql](../../Modules/toolbelt.file.content/Tests/Runtime/RepeatCurrent.Contract.sql)
und [Lifecycle.Contract.sql](../../Modules/toolbelt.file.content/Tests/Runtime/Lifecycle.Contract.sql)
aus. Die erste Fixture bindet ihre originalen Capture-/Assert-Includes und
zwei echte versionsgleiche Deploys. Somit liefen **36 echte Repeat-Deploys**.

Vier synthetische Allowlist-Zeilen prüfen exakte UTF-16-Bytes, NULLs,
aktive/inaktive Zustände und feste Auditzeiten. Die gelöschte höchste Identity,
der nächste reguläre Insert, Objekt-/Schemaidentitäten, Spalten, Indizes,
Constraints, Trigger, vorhandene Permissions und Annotationen bleiben erhalten.
Nur die kanonische Tabellenbeschreibung wird gezielt erneuert. Keine
nichtleeren Benutzergrants und keine Datei-I/O-Fixture werden daraus abgeleitet.

Nach jeder Fixture bestätigt der Adapter den neutralen Transaktionszustand.
Die nun vor dem Guard journalisierten vollständigen Definitionen-Hashzeilen
stimmen in allen **18 Vor-/Nachpaaren exakt überein**; 36 beendete Fixtures
sind einzeln quittiert. Damit ist die zuvor nur offline korrigierte
EOF-/Include-Behandlung für diesen Gesamtfall jetzt auch nativ bestätigt.
Der strikte Definitionsvergleich blieb erhalten.

Die neun separaten Auditprozesse binden das genaue finale Originaljournal,
die tatsächliche Zielversion, DB-Abwesenheit, unveränderte gesamte
Serverkonfiguration und Assemblytrust sowie alle Eingabepins. Zwei private
Nachprüfungen bestätigten die Originalaudits, Kontexte, Fortschrittszeugen,
Definitionszeilen und Quellenbindungen. Rohdaten bleiben außerhalb Git.

## Endlicher Rahmen und unveränderte Grenzen

Die neue ausdrückliche Freigabe öffnete eine eigene Welle: neun
geplante Producer-/Auditpaare, höchstens **22 Aufrufe und 22 DB-Reservierungen**
einschließlich maximal zweier gezielt geänderter Adapterfälle, insgesamt
45 Minuten ab Start. Tatsächlich bestanden alle neun Fälle beim ersten
Versuch: **18 Aufrufe, 18 Reservierungen, null Korrekturfälle** innerhalb
der ursprünglichen Frist. Die Welle und alle unbenutzten Restplätze sind geschlossen.

Der frühere No-Retry-Versuch bleibt unverändert **FAILED_CLEANED** mit zwei
verbrauchten Aufrufen/zwei Reservierungen, einer entfernten DB und frischem
PASS-Audit. Er wird weder umetikettiert noch erneut als Gesamtfall gezählt.
Beide getrennten Wellen verbrauchten zusammen 20 Aufrufe/Reservierungen und
entfernten 19 tatsächlich angelegte eigene DBs. Ihre getrennten Grenzen bleiben
erhalten; die neuen Erfolge löschen keine Fehlerhistorie.

Vorhandene administrative Lab-Anmeldung, Windows-Client und Functional-Transport
mit erforderlicher Verschlüsselung und explizitem Trustwert. Keine neuen Rechte,
Benutzer, CLR-Assemblies, Trusteinträge, Serveroptionen oder Labressourcen.
Keine authentifizierte TLS-, Linux-Clienthost-, nichtleere ACL-, Minimalrechte-,
vollständige Drift-/Migrations-/Ressourcen- oder Windows-Dateiproviderabnahme.
Echte Datei-I/O bleibt gemäß Modulvertrag optional und plattformabhängig.
Kein allgemeiner Host-/Hardinterrupt-Cleanup-PASS. Keine Veröffentlichung oder Tags.
