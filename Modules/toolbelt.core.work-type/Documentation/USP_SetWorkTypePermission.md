# toolbelt_core.USP_SetWorkTypePermission

Verwaltet ausschließlich die ausdrückliche Delegation eines vorhandenen Work
Types an einen vorhandenen Datenbankbenutzer oder eine Datenbankrolle.
Kein SQL-GRANT, keine Rollenzuweisung, kein Handleraufruf und kein Datenresultset.

| Parameter | Typ | Default | Vertrag |
|---|---|---|---|
| @WorkTypeName | varchar(128) | NULL | Fachlich erforderlich; vorhandener kanonischer Name. |
| @Principal | sysname | NULL | Fachlich erforderlich; vorhandener DBprincipal. |
| @PermissionName | varchar(32) | NULL | ENQUEUE, CLAIM oder EXECUTE_NEW_SESSION. |
| @PermissionState | varchar(8) | ALLOW | ALLOW, DENY oder REMOVE. |
| @Debug | tinyint | 0 | Nur nicht sensible Message. |
| @Hilfe | bit | 0 | Standardisiertes Help-Resultset ohne Seiteneffekt. |

Rückgabe 0 bei Erfolg. Fehler 51590 Parameter, 51591 fehlendes CONTROL auf
WorkTypePermission, 51592 fehlender Principal, 51593 fehlender Work Type,
51594 uncommittable Caller. Normale Callertransaktionen verwenden einen
Savepoint; die Procedure committet ausschließlich ihre eigene Transaktion.

EXECUTE allein erlaubt keine Policyänderung. Zusätzlich ist CONTROL auf
der Policytabelle erforderlich. Der Betreiber vergibt Rechte separat.
ALLOW und DENY binden den aktuellen Work-Type-RowVersion-Stand und die
Principal-ID/SID/Erstellungszeit. Nach Work-Type-Änderung ist eine erneute
ausdrückliche Konfiguration nötig. REMOVE entfernt genau den bezeichneten
Eintrag. Wiederholung von ALLOW/DENY erneuert die Bindung idempotent.

Die interne inline TVF `TVF_WorkTypeAuthorization` liefert genau eine bit-Spalte
IsAllowed; wirksame DBtoken einschließlich Rollen werden ausgewertet. Ein
gültiges DENY überstimmt ALLOW. Ohne gültiges ALLOW wird abgewiesen, auch dbo.
Actor, Tenant, ORIGINAL_LOGIN-Text und Clientangaben verleihen keine Autorität.

```sql
EXEC toolbelt_core.USP_SetWorkTypePermission
    @WorkTypeName='demo.noop', @Principal=N'ContosoProducer',
    @PermissionName='ENQUEUE', @PermissionState='ALLOW';
```

Migration von 1.1.0: zuerst Katalog 1.2.0 installieren, dann Rechte explizit
konfigurieren und abhängige Queue-/Second-Session-Module aktualisieren.
Es gibt weder öffentliche Defaultfreigaben noch automatische Übernahme alter
EXECUTE-Rechte. Erst-/Wiederholungsdeployment erzeugen keine Policyeinträge.
SQL Server 2019/2022/2025 unter Windows/Linux, lokale und zentrale Kataloge;
zentrale Nutzung wertet den tatsächlichen DBtoken im jeweiligen Katalog aus.
Neue Runtime-/Lifecyclequalifikation steht bis zu ihrer protokollierten
Ausführung aus; historische 1.1.0-Nachweise qualifizieren diese Policy nicht.
