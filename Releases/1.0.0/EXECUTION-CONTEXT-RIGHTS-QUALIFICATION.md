# Execution Context mit einzelnen Objektrechten aufrufen

Stand 2026-10-24. Alle fünf öffentlichen APIs von
`toolbelt.core.execution-context` sind mit jeweils **genau einem**
Objektrecht auf dem unveränderten Produktstand geprüft:

| API | Für den direkten Aufruf geprüftes Recht |
|---|---|
| `toolbelt_core.USP_BeginExecution` | `EXECUTE` |
| `toolbelt_core.USP_SetExecutionContext` | `EXECUTE` |
| `toolbelt_core.USP_EndExecution` | `EXECUTE` |
| `toolbelt_core.TVF_CurrentExecutionContext` | `SELECT` |
| `toolbelt_core.SVF_CurrentExecutionId` | `EXECUTE` |

Die Administration kann einem vorhandenen freigegebenen Datenbankkonto
gezielt das jeweils benötigte Recht geben, beispielsweise:

```sql
GRANT EXECUTE ON OBJECT::toolbelt_core.SVF_CurrentExecutionId TO ContosoCaller;
```

`ContosoCaller` ist ein Platzhalter. Die Modulinstallation legt keine
Fachcaller an und erteilt ihnen keine automatischen Rechte. Insbesondere
benötigt der direkte Skalaraufruf kein zusätzliches `SELECT` auf der TVF;
die bestehende Ownership Chain bleibt erhalten.

## Tatsächlich geprüfter Umfang

Der vorhandene API-Harness führte die neue feste Fixture
`Tests/Release/Runtime/ExecutionContext.Rights.sql` in eigenen temporären
Datenbanken aus. Ein neu angelegter Benutzer ohne Login erhielt nacheinander
nur das jeweils geprüfte Objektrecht. Es gab keine Rollen-, Schema-,
Datenbank- oder Servergrants und keinen Rechteaufbau für fremde Konten.

Für jedes API wurden drei Phasen geprüft:

1. Ohne Grant muss der direkte Aufruf mit SQL229 scheitern.
2. Mit ausschließlich dem eigenen Objektrecht müssen die festen Wertorakel
   bestehen. Direkte Aufrufe aller vier anderen APIs bleiben mit SQL229 gesperrt.
3. Nach Entzug des Objektrechts muss auch das zuvor erlaubte API wieder
   mit SQL229 scheitern.

Die Wertorakel umfassen Root-/Nested-Begin mit fester Identität und Tiefe,
Correlation-/Actor-/Tenant-Änderung, Clear von Actor und Tenant, verschachteltes
und abschließendes End, die vollständige feste TVF-Zeile sowie skalare
Identität und leeren Context. Die Fixture verlangt anfangs sechs leere
Toolbelt-Sessionkeys und entfernt anschließend ausschließlich diesen eigenen
Sessionzustand und ihren Testbenutzer. Ein vorhandener Context oder Principal
wird nicht übernommen.

Zwölf tatsächliche Fälle bestanden auf Windows und Linux: SQL2019 CL150,
SQL2022 CL150/160 und SQL2025 CL150/160/170, jeweils lokal und im direkt
geöffneten zentralen Datenbankkontext. Das ergibt 120 positive API-Szenarien
und 720 strikte Rechteabweisungen. Die Szenarien enthalten mehrere
Wertprüfungen; die Zahl bezeichnet keine einzelnen SQL-Funktionsaufrufe.

Zwei absichtlich fehlerhafte Fixturevarianten prüfen die Orakel selbst:
eine falsche erwartete Nested-Tiefe und ein zusätzliches fremdes Objektrecht.
Beide wurden mit SQL52095 abgewiesen und vollständig bereinigt. Ihr Zustand
bleibt `FAILED_CLEANED`; sie zählen nicht als erfolgreiche Funktionsfälle.

Alle vierzehn Fälle bestanden anschließend neue unabhängige Cleanup-/Pinaudits.
Die 36 Datenbanknamen der positiven Matrix waren abwesend; alle 132 zugehörigen
Trustzustände waren wiederhergestellt. Die beiden Negativkontrollen wurden
separat geprüft. Nach allen Verbrauchern bestanden weitere Konfigurationsaudits
auf allen sechs ausgewählten physischen Zielscopes. Journale, tatsächliche
Konfigurationswerte und Rohlogs bleiben lokal.

## Quellenbindung und Grenzen

Die [maschinenlesbare Projektion](execution-context-rights-qualification.json)
bindet die fünf Produktquellen, Fixture und kanonischen Harness-/Labadapter
sowie die tatsächlich verwendeten Paket-SQL-Bytes. Diese entsprechen weiterhin
der [bestehenden Gesamtpaketqualifikation](complete-qualification.json).
Keine Produkt-, Modulversions-, Dependency-, SQL-/DLL-Payload- oder
Validierungsstatusänderung war erforderlich. Eine neue unveränderte funktionale
Vollmatrix oder Paket-Lifecyclematrix wurde deshalb nicht gestartet.

Die Arbeit behielt die bestehenden Arbeits-/Cleanup-/Watchdoggrenzen und das
ursprüngliche gemeinsame Restbudget. Functional verwendete erforderliche
Verschlüsselung und den ausdrücklichen Trustwert des schema-validierten
Labvertrags; authentifizierte TLS-Abnahme bleibt separat.

Ein Benutzer ohne Login im direkt geöffneten zentralen Datenbankkontext belegt
kein echtes CrossDB-Loginmapping. Auch Ressourcen-/Parallel-/Recovery- und
Clientgates sowie die Minimalrechte anderer Module bleiben getrennt.
[Releasegates](RELEASE-GATES.md), bestehende Modulverträge und die separate
Veröffentlichungsfreigabe gelten unverändert.
