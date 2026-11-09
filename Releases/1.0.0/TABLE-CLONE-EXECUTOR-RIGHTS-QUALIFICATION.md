# Table Clone Executor: begrenztes reales Anmelde- und Rechteprofil

Stand 2026-11-09: **PASS_FOR_DECLARED_BASIC_EXECUTOR_RIGHTS_MATRIX**.
Zwölf aktuelle Engine-/CL-Paare lokal und direkt zentral: 24 Kontexte,
144 Prüfprofile, zwölf erfolgreiche Gesamtläufe und zwölf frische unabhängige
Windows-Client-Abschlussaudits. Keine erneute Planner-/Executor-Vollsuite.

| Plattform | Engine/Patch | Compatibility Levels | Modi je CL |
|---|---|---|---|
| Windows | SQL2019/CU32 | 150 | local, central |
| Windows | SQL2022/CU26 | 150,160 | local, central |
| Windows | SQL2025/CU8 | 150,160,170 | local, central |
| Linux | SQL2019/latest | 150 | local, central |
| Linux | SQL2022/latest | 150,160 | local, central |
| Linux | SQL2025/latest | 150,160,170 | local, central |

## Konkrete Identität und ausdrückliche Rechteausnahme

Der Benutzer genehmigte den vorbereiteten einzelnen Executor-Umfang ausdrücklich
mit „Diesen begrenzten Umfang freigeben“. Die frühere Planner-Ausnahme ersetzt
diese Freigabe nicht. Je Lauf werden genau ein eigener temporärer SQL-Login
mit vorab gebundener zufälliger SID und zwei gleichnamige gemappte Benutzer
in zwei eigenen Testdatenbanken verwendet. Kennwort ausschließlich im Speicher;
keine bestehenden Identitäten oder Serverrollen geändert.

Der Login erhält ausschließlich serverweites `VIEW ANY DEFINITION` zusätzlich
zum normalen `CONNECT SQL`. Dies ist eine bewusst genehmigte Metadatensicht,
kein Profil ohne Serverrechte. Jede eigene DB erhält genau sechs Grants:

- `CONNECT` auf die DB;
- `EXECUTE` nur auf `toolbelt_metadata.USP_ExecuteTableClone`;
- `VIEW DEFINITION` auf die DB;
- `SELECT` nur auf `sys.sql_expression_dependencies`;
- `CREATE TABLE` auf die DB;
- `ALTER` nur auf das eigene synthetische Schema `ContosoCloneTarget`.

Ein echtes frisches SQL-/TCP-Login wird anhand SPID, zufälligem Context-Tag,
SID, ursprünglicher SID, DB-Identität, Authentifizierung und Transport von einer
unabhängigen administrativen Sitzung bestätigt. Login-/Benutzername und
SID-Mapping stimmen; `sysadmin`, `db_owner`, DB-`CONTROL` und `CONTROL SERVER`
sind nicht effektiv. Die Grantprüfung vergleicht Kardinalität, Berechtigungsname,
Klasse, konkretes Objekt-/Schema-Ziel und Grantzustand.

## Sechs Profile pro Kontext

1. CONNECT ohne Executor-EXECUTE: echte Abweisung229.
2. Executor-EXECUTE und Metadatensicht ohne Ziel-DDL-Rechte: Abweisung53932;
   kein Zielobjekt angelegt.
3. Genau die sechs DB-Rechte: unveränderter öffentlicher Executor erstellt
   die einfache neue Tabelle erfolgreich. Der übergebene Hash bindet den
   vollständigen kanonischen Plan, Optionen und Installations-DB-Identität
   nach Hashprotokoll v1; Resultset enthält passenden Hash und genau eine
   erstellte Tabelle/ein ausgeführtes fachliches Statement. Caller-TX bleibt leer.
4. Direkter SELECT auf die synthetischen Quelldaten: Abweisung229.
5. Direkter ResultTable-Helper-Aufruf: Abweisung229.
6. Effektiv widerrufenes Executor-EXECUTE: erneute Abweisung229.

Der administrative Nachcheck bestätigt unveränderte zwei synthetische
Quellzeilen, leeres Ziel mit genau der erwarteten int-Spalte und unveränderte
Produktdefinitionen. Beide Modi sind direkte Aufrufe in ihrer jeweiligen
Installations-DB; kein zusätzlicher CrossDB-Consumer wird behauptet.

## Herkunft, Grenzen und Abschluss

Geprüfter Methodencommit:
`0470ecf4e253541a1855788900d9b024bd422962`.
Der [Treiber](../../Tests/Release/Invoke-TableCloneExecutorRightsLab.ps1)
bindet schema-validierten Functional-Labvertrag, exakte READY-Auswahl, aktuelle
Produktquellen und vollständige kanonische Exporte für ResultTable 1.0.0 und
TableClone 4.1.1. Die [Fixture](../../Tests/Release/Runtime/TableClone.ExecutorRights.Contract.ps1)
verwendet die etablierten SID-/Ownership-/Consumer-Prüfungen mit eigener eng
begrenzter Rechteausnahme. Neun [Offlineprüfungen](../../Tests/Release/test_table_clone_executor_rights_contract.py)
belegen Admission, Booleanfreigaben, Frist-/Matrix-/Pinabwehr, konkrete Grantziele,
Identitätsdrift und Hashgleichheit mit dem originalen Clientbeispiel. Ein vor
SQL entdeckter Array-/Stringfehler des neuen Grantorakels wurde durch eine
Gegenprobe korrigiert; kein nativer Fehlversuch und keine Wiederholung.

Die gemeinsame Welle ist geschlossen: **24 von maximal 28 Ziel-/Auditaufrufen,
24 von maximal 28 DB- und zwölf von maximal 14 Login-Reservierungen innerhalb
derselben 45 Minuten**, ohne zusätzlichen Adapterfall. Zwölf frische Audits binden
jeweils das exakte endgültige Journal und prüfen DB-/Login-/SID-Mapping-Abwesenheit
sowie unveränderte vollständige Serverkonfiguration und Assemblytrust. Eigene
aktive Sessions werden geschlossen; fremde SID-Consumer, Rechte oder
Identitätsdrift blockieren Cleanup. Server-Metadatenrecht wird widerrufen und
der identitätsgebundene Login entfernt. Private Originale, Eingabepins und
Quellkapseln bleiben außerhalb Git erhalten. Ungenutzte Reserve geschlossen.

Keine CLR-/Konfigurations-/Trust-/Owner-/Lab-/Hoständerungen, keine neuen Builds
oder Produktobjekte. Der Transport ist Functional mit dem expliziten Lab-Trustwert;
dieser Test ist keine authentifizierte TLS-Abnahme. Grundprofil ohne FKs,
Checks, Defaults, berechnete Spalten, Trigger oder Datenkopie. Copy-/Trigger-
Rechte, FK-REFERENCES, alternative ResultTable-Ausgabe, weitere Identitäts- und
Recoverypfade sowie vollständige Produktqualifikation bleiben eigenständig.
Keine Statusaufwertung des teilweise validierten Gesamtmoduls, Veröffentlichung
oder Tags. Historische Originalnachweise bleiben unverändert.
