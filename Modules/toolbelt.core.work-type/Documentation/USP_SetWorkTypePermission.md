# toolbelt_core.USP_SetWorkTypePermission

Verwaltet ausschließlich die ausdrückliche Delegation eines vorhandenen Work
Types an einen vorhandenen Datenbankbenutzer oder eine Datenbankrolle.
Kein SQL-GRANT, keine Rollenzuweisung, kein Handleraufruf und kein Datenresultset.

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkTypeName` | `varchar(128)` | `NULL` | Input | Kanonischer registrierter WorkTypeName als varchar(128), kein SQL-Text oder Handler-Aufruf. Verfügbare Namen über toolbelt_core.VW_WorkTypes ermitteln; der Eintrag muss für diese Operation freigegeben sein. NULL/leer ist im Fachaufruf ungültig. |
| `@Principal` | `sysname` | `NULL` | Input | Vorhandener Datenbankprincipal als unquotierter sysname, nach Datenbank-Namensvergleich. Zulässige sys.database_principals-Typen taxativ: S=SQL-Benutzer, U=Windows-Benutzer, G=Windows-Gruppe, R=Datenbankrolle, E=externer Benutzer, X=externe Gruppe; principal_id darf nicht 0 sein. Kein Serverlogin oder automatisch angelegter Principal; NULL/leer/fehlender Eintrag ist ungültig. |
| `@PermissionName` | `varchar(32)` | `NULL` | Input | Taxativ und binär/case-sensitiv: ENQUEUE erlaubt das Einreihen; CLAIM erlaubt das Beanspruchen von Arbeit; EXECUTE_NEW_SESSION erlaubt den Start über den Second-Session-Provider. Keine weiteren Aktionen und kein implizites UPPER. SQL-Space-Padding ist vom binären Vergleich nicht aufgehoben. Fachlich erforderlich, NULL ungültig. |
| `@PermissionState` | `varchar(8)` | `'ALLOW'` | Input | Taxativ und binär/case-sensitiv: ALLOW legt eine erlaubende lokale Policy an (Default); DENY legt eine verbietende Policy an und gewinnt gegen passende ALLOWs; REMOVE entfernt den Eintrag genau dieser Aktion/Principal-Zuordnung. NULL/andere Werte ungültig. Dies ersetzt keine SQL-Objekt-EXECUTE-Rechte und vergibt keine Serverrechte. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |
<!-- API_PARAMETERS:END -->

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
