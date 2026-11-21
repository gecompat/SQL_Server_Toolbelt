# Second Session


## Aktuelle Installation

Den [modulbezogenen Buildplan](Deployment/README.md) oder den
[gemeinsamen Installer](../../Deployment/ONE-CALL-INSTALL.md) verwenden.
Beide führen auf denselben markerfreien create-only-Kern: normale SQL-Datei,
kein SQLCMD-Modus, keine Deployment-Extended-Properties.
Die bisherigen Versions-/Lifecycleangaben weiter unten und ihre damaligen
Assemblynamen bleiben an die ursprünglichen Artefakte gebunden. Sie sind kein
aktueller Upgrade-/Uninstallweg und keine neue native Installerabnahme.


Aktuelle [Callerrechte](../../Releases/1.0.0/PROVIDER-CALLER-QUALIFICATION.md): getrennte Objektrechte auf zwölf Ziel-/CL-Kombinationen lokal/direkt zentral. Weitere Funktions-, Client-, Lifecycle- und Ressourcengates sowie Modulstatus bleiben separat.

## Status

`toolbelt.core.second-session` Version `1.1.0` ist implementiert und teilweise
validiert. Historische Moduladapter bestanden auf Windows-/Linux-Zielen;
sie qualifizieren ausschließlich ihre damaligen Artefakte. Die neue
Usage-Skill-/Installerintegration ist damit nicht nativ abgenommen.

Die manuelle Windows-Validierung über `System.Data.SqlClient` war am 2026-08-04 auf SQL Server 2025 erfolgreich; sie umfasste lokale und zentrale Bereitstellung, den Collation-übergreifenden Abgleich mit `master.sys.servers`, Provider-Probe, Contract-, Concurrency-, Central- und Lifecycle-Tests sowie geschützten und vollständigen Uninstall.

## Zweck

Das Modul führt einen registrierten Work Type synchron in einer getrennten SQL-Server-Session aus. Dadurch kann ein Remote-Commit einen späteren Rollback oder einen bereits uncommittable Zustand der Caller-Transaktion überleben.

Die öffentliche Oberfläche akzeptiert ausschließlich einen Namen aus `toolbelt.core.work-type` und optional eine JSON-Objekt-Payload. Raw SQL, Batch-Text und frei zusammengesetzte Commands sind ausgeschlossen.

## Providervertrag

Der Linked Server wird administrativ außerhalb des Moduls angelegt. Er muss:

- auf dieselbe SQL-Server-Instanz zurückführen;
- `rpc out = true` verwenden;
- `remote proc transaction promotion = false` verwenden;
- ein explizit administriertes Login-Mapping besitzen.

Das Modul speichert nur den Linked-Server-Namen. Credentials und Login-Mappings werden weder erzeugt noch gespeichert oder entfernt.

Die Konfigurationsprobe vergleicht sichtbare Flags, zurückgegebenen
Datenbanknamen und abweichende SPID. Sie ersetzt keine administrative Prüfung,
dass das Ziel tatsächlich dieselbe SQLinstanz ist, und keinen TLS-Nachweis.

## Work-Type-Signaturen

- `NONE`: Handler ohne Parameter.
- `JSON_PAYLOAD`: exakt `@PayloadJson nvarchar(max)` als einziger Parameter.

Nur für den kanonisch gebundenen Event-Log-Handler gilt die eng geprüfte
Ausnahme mit zweitem `@Hilfe bit`, das der Dispatcher explizit auf 0 setzt.
Dies ist keine allgemeine Zulassung weiterer optionaler Handlerparameter.

Handler-Resultsets werden mit `WITH RESULT SETS NONE` abgelehnt. Der Remote-Dispatcher führt den Handler in einer eigenen Transaktion aus und überträgt Execution-ID, Correlation-ID, Actor und Tenant in den Remote-`SESSION_CONTEXT`.

## Uncommittable Caller

Die Standardausgabe ist auch bei `XACT_STATE() = -1` zulässig, weil die lokale Procedure nur liest und den nicht promovierten RPC ausführt. `@ResultTable` wird in diesem Zustand abgelehnt, da lokale Tabellenänderungen den Vertrag verletzen würden.

Provider-Spike-Evidenz: https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30703841095

Version `1.1.0` ergänzt `@SuppressResult = 1` für erfolgreiche Infrastrukturaufrufe ohne lokales Resultset. Die Option ist insbesondere für rollback-unabhängige Side-Effect-Handler vorgesehen und kann nicht mit `@ResultTable` kombiniert werden.

Der Dispatcher-Returncode wird auf Erfolg geprüft. Ein nichtzero
`HandlerReturnCode` allein löst hingegen keinen automatischen THROW/Rollback aus;
bei unterdrückter Ausgabe bleibt er ohne Ergebniszeile. Unerwartete SQL-Fehler
bleiben sichtbar. Remote-Commit und spätere Ausgabe sind nicht atomar gekoppelt:
Transport-, Cleanup- oder Routingfehler können bereits persistente Handlerwirkung
hinterlassen. Gleiche Kontext-IDs verhindern keine Duplikate bei Wiederholung.

Alle sechs Objekte besitzen vollständige quellgeprüfte
[Usage-Skills](../../Metadata/UsageSkills/README.md) in ihrer ausgelieferten DDL.
Die vier Prozeduren liefern sie über `@Hilfe=1` nach der bisherigen Standardhilfe.
Beim Dispatcher bleiben dabei alle vier OUTPUT-Eingangswerte unverändert.
Die neue Hilfeprojektion ist offline geprüft, nicht neu nativ qualifiziert.

Evidenz Version `1.1.0`: https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/31018284410

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-08`
- Nachweis: `https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37693379887`
- Scope: Commit 32ee260e413b8de7f9b2046ffdc11618b0afd69b: zwei echte befüllte 1.1.0-Repeats lokal/zentral auf Linux2019/150,2022/160,2025/170 mit genau einem deaktivierten synthetischen loopback-Eintrag; alle acht Spalten einschließlich unterschiedlicher Auditzeiten, Unicode-/Padding-Autoren und Rowversionbytes sowie ausgewählter Katalog, vorhandene Permissions und eigene Annotationen/MS_Description erhalten. Keine RPC-/Configure-USP-Aufrufe im neuen Tabellenrepeat. Bestehende API-/Provider-/Rollback-/Parallelitäts-/Consumer-/Uninstallfälle und eigene CI-Bereinigung bestanden; abhängige W5b-Suite37693379826 ebenfalls SUCCESS am selben Head. Neue Windows-Repeats, weitere Repeat-CLs, nichtleere Benutzergrants, echte Minimalrechte, historische Übergänge und Hard-Interrupt-Recovery bleiben offen.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->

## Freigegebene Security-Härtung 2026-10-15

Lokaler und direkter Remoteeinstieg verlangen EXECUTE_NEW_SESSION im jeweiligen
echten DBtoken; der Remoteprincipal benötigt weiterhin Handler-EXECUTE.
Actor/Tenant ersetzen keine Autorisierung. Die Payload ist beiderseits vor
JSONarbeit und RPC auf 1048576 UTF-16-Bytes begrenzt (51628); fehlende Autorität
ergibt 51629. Lokal kommt Work-Type-/Autoritäts-/Payloadprüfung vor Providerprüfung.
Zuerst Katalog 1.2.0 installieren und beiderseitige Delegation explizit konfigurieren.

Der [freigegebene Vertrag](../../Documentation/Architecture/SECURITY_HARDENING_2026_10.md)
beschreibt Scope, Migration und Grenzen. Historische Plattformnachweise gelten
weiter ausschließlich für ihre datierten Quellen.
