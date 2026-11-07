# Table Clone 4.1.1: begrenzte Planner-Minimalrechte

Am 2026-11-07 bestand die einzeln freigegebene Planner-Rechtematrix auf zwölf
Windows-/Linux-Engine-/CL-Paaren lokal und direkt zentral: **zwölf vollständige
Fälle, 24 Kontexte, 24 vollständige Rechtefixtures und zwölf frische Audits**.
Ergebnis: **PASS_FOR_DECLARED_PLANNER_FIVE_RIGHTS_SCOPE**.
Alle 24 synthetischen Benutzer und alle 24 eigenen Testdatenbanken sind entfernt.

| Ausgewähltes SQL-Ziel | Compatibility Levels | Modi | Kontexte |
|---|---|---|---:|
| Windows 2019/CU32 | 150 | lokal/direkt zentral | 2 |
| Windows 2022/CU26 | 150, 160 | lokal/direkt zentral | 4 |
| Windows 2025/CU8 | 150, 160, 170 | lokal/direkt zentral | 6 |
| Linux 2019/latest | 150 | lokal/direkt zentral | 2 |
| Linux 2022/latest | 150, 160 | lokal/direkt zentral | 4 |
| Linux 2025/latest | 150, 160, 170 | lokal/direkt zentral | 6 |

Windows ist der Clienthost mit System.Data.SqlClient. Die administrative
Lab-Anmeldung führt nur Vorbereitung, Installation und eigene Bereinigung aus.
Die eigentlichen Planner-Aufrufe laufen unter dem synthetischen Datenbankbenutzer
**ohne Login**, nach tatsächlicher Impersonation und Nichtbesitzerprüfung.
Linux in der Tabelle bezeichnet das SQL-Ziel. Kein Linux-Clienthost, keine
Windows-SSPI-/GUI-/Netzwerkanmeldung oder neue CrossDB-Identität.

## Besprochene und ausdrücklich freigegebene fünf Rechte

Der Benutzer hat die temporäre Identität und genau die folgenden Rechte nach
konkreter Besprechung am 2026-11-07 einzeln freigegeben. Die Autorität ist im
[Backlog](../../.ai/BACKLOG.md#table-clone-begrenzte-planner-testrechte--freigabe-2026-11-07)
festgehalten. Alle Grants/Revoke-Schritte betreffen ausschließlich diese neue
Identität in eigenen synthetischen Testdatenbanken:

| Berechtigung | Ziel |
|---|---|
| EXECUTE | `toolbelt_metadata.USP_ScriptTableClone` |
| EXECUTE | `toolbelt_core.USP_PrepareResultTable` |
| VIEW DEFINITION | synthetische Quelltabelle |
| VIEW DEFINITION | Schema dbo |
| VIEW DEFINITION | eigene Testdatenbank |

Die drei Sichtbarkeitsscopes werden in verschiedenen Phasen gezielt vergeben
und widerrufen, damit vollständige und unvollständige Metadatensicht getrennt
beobachtet werden. Fünf bezeichnet unterschiedliche freigegebene Rechteziele,
keinen mathematischen Beweis, dass sämtliche fünf in jeder positiven Phase
zugleich notwendig sind. Kein Grant auf den internen Kern, keine Rolle,
kein Serverrecht, keine Änderung bestehender Identitäten oder Datenbanken.

## Tatsächlich ausgeführte Rechtefixture

Der [Methodenstand `e307b41c`](https://github.com/gecompat/SQL_Server_Toolbelt/commit/e307b41cbb8aa61c0aedb82514b5ff41d7112a72)
bindet den [begrenzten Adapter](../../Tests/Release/Invoke-TableClonePlannerRightsLab.ps1)
und die unveränderte kanonische
[`MinimumRights.Contract.sql`](../../Modules/toolbelt.metadata.table-clone/Tests/Runtime/MinimumRights.Contract.sql).
Die ursprünglichen Fachorakel werden vollständig ausgeführt:

- acht geordnete Planzeilen unter der tatsächlichen eingeschränkten Identität;
  der Planner erzeugt keine persistente Zieltabelle;
- nach Entzug der Sichtbarkeit Fehler 53901;
- eine tatsächlich unsichtbare synthetische incoming-FK-Quelle, Fehler 53901
  bei unvollständiger Sicht und unveränderte acht Ausgabezeilen;
- nach gezielter vollständiger Sichtbarkeit derselbe incoming FK mit Fehler 53903;
- eigene Quelle, verstecktes Testschema und Testbenutzer anschließend entfernt.

Genau vor dem ersten positiven öffentlichen Aufruf ergänzt der Adapter einen
über den eindeutigen vollständigen Zeilenanker gebundenen Gegencheck. Dieser
prüft den tatsächlichen Benutzer, fehlende db_owner-Mitgliedschaft und fehlendes
CONTROL auf die eigene Datenbank. Ein **direkter** Aufruf des internen Kerns
mit `@Hilfe=1` muss unter genau dieser Identität mit SQL 229 scheitern.
Danach besteht der öffentliche Planner-Aufruf über die vorgesehene Aufrufkette.
Die ursprüngliche Fixture bleibt unverändert; kanonische und tatsächlich
abgeleitete Ausführungsbytes sind getrennt gepinnt und nachgeprüft.

Vor SQL-Zulassung sind die boolesche Einzelrechtefreigabe, der exakte Benutzer
und die geordnete Fünferliste erforderlich. Die Fixtureprüfung weist zusätzliche
Grants, Rollen, fremde Identitätsoperationen, Server-/Datenbank-/Truständerungen
und dynamisch zusätzlich eingeschobene GRANT-Anweisungen ab. Die vollständige
Originalfixture wird nicht durch einen bloßen Predicate- oder Admin-Test ersetzt.

## Quellen, Zustandsgrenzen und frische Audits

Nur ResultTable 1.0.0 und Table Clone 4.1.1 werden aus den kanonischen Exports
installiert. Tatsächliche Zielversion/-plattform, CL, Modulstände und Modi sowie
das Fehlen von Benutzerassemblies werden geprüft. Der Benutzer existiert vor
jeder Fixture nicht. Nachher fehlen Benutzer, synthetische Quelle/Zielobjekte
und verborgenes Testschema; Caller-Identität und Transaktionszustand sind
wiederhergestellt, Produktdefinitionen identisch.

Jeder vollständige Fixtureabschluss wird sofort mit Modus und den exakten
kanonischen/ausgeführten Texthashes ins private Journal geschrieben. Auch ein
späterer Fehler im Cleanup- oder Callerzeugen würde deshalb eine vollständige
Fallwiederholung blockieren. Keine bereits grüne Fixture oder Kontextwiederholung.

Vor erstem Zugriff galten gemeinsam **28 Ziel-/Auditaufrufe,
28 eigene DB-Reservierungen und 60 Minuten**. Tatsächlich verbraucht wurden
**24 Aufrufe/Reservierungen**, ohne native Fehler, Korrektur oder Wiederholung.
Alle verbleibenden Plätze sind geschlossen. Producer/Audit sind jeweils auf
400 Sekunden und getrennte 4-MiB-Ausgabekanäle begrenzt; die Admission hält
15 Minuten Reserve. Die einzelne Fixture bleibt innerhalb der gemeinsamen
SQL-/Cleanup-Fristen.

Alle zwölf frischen unabhängigen Audits binden den exakten finalen Journalhash,
Abwesenheit der eigenen DBs, tatsächliche Ziele, sämtliche Quellen-/Helper-/
Export-/Labvertrags-/Schema-/Prompt-/Authority-/Planpins sowie den vollständigen
ursprünglichen Konfigurations-/Trustzustand. Der unabhängige Nachprüfer bestätigt
zwölf Gesamtfälle, 24 vollständige Fixtures und alle Identitäts-/Cleanupzeugen.
24 neue Benutzer wurden ausschließlich temporär in eigenen DBs angelegt;
keine Rechte außerhalb dieser DBs, keine verbleibenden Benutzer, Serverrechte,
Assemblies, Serveroptionen, Trusteinträge oder Lab-Infrastrukturänderungen.
Credentials und reale Runtime-/SID-/Zielwerte bleiben privat außerhalb Git.

13 öffentliche Offlinegegenproben und neun zusätzliche verbindungslose
Scope-/Identitäts-/Server-Negativfälle bestanden. Der private Vorbereiter wurde
vor jeder SQL-Zulassung von skalarer auf ausdrücklich arraygebundene Behandlung
der einzelnen Fixture korrigiert; ursprünglicher Fehler erhalten, null native
Aufrufe/DBs. Die tatsächliche korrigierte Zulassungsprüfung bestand vor dem Lauf.

Die Tests verwenden die erforderliche Verschlüsselung und den expliziten
Functional-Trustwert des schema-validierten Labvertrags. Diese Rechtematrix ist
keine authentifizierte TLS-Abnahme. Der direkt zentrale Modus nutzt dieselbe
Installationsdatenbank und qualifiziert keine neue Netzwerk-/CrossDB-Identität.

## Wiederverwendung und getrennte Restpunkte

Produkt-SQL, Originalfixtures und gemeinsame Helper sind unverändert.
Gültige [Planner-/Executor-](TABLE-CLONE-PLANNER-EXECUTOR-QUALIFICATION.md),
[W1-/W2-](TABLE-CLONE-W1-W2-QUALIFICATION.md),
[Copy-](TABLE-CLONE-COPY-TARGET-QUALIFICATION.md),
[Trigger-](TABLE-CLONE-TRIGGER-CURRENT-QUALIFICATION.md),
[Clientreader-](TABLE-CLONE-WINDOWS-CLIENT-METADATA-QUALIFICATION.md),
[SQLCMD-](TABLE-CLONE-SQLCMD-CALLER-QUALIFICATION.md) und
[genuine V1-Lifecycle-Nachweise](TABLE-CLONE-GENUINE-V1-LIFECYCLE-QUALIFICATION.md)
bleiben gültig in ihrem jeweiligen Scope. Ihre grünen nativen Fachmatrizen wurden
nicht erneut ausgeführt. Historische Rechteberichte werden nicht umgedeutet.

Der pauschal offene aktuelle Planner-Fünfrechtescope ist damit geschlossen.
Executor-/Copy-/Trigger-Rechte, weitere Clients/Identitäten, andere genuine
Zwischenversionen, übrige Lifecycle-/Recoverypflichten und Modulgesamtfreigabe
bleiben getrennt. Teilweise validiert und unveröffentlicht. Keine Veröffentlichung
oder Tags.
