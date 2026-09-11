# Vorschlag: Gate für externe Capabilities (`TC-2026-025` bis `027`)

## Status

PowerShell-Host-Automation, Python-Capabilities und REST-Requests bleiben
Research. Dieses Dokument bereitet gemeinsame Freigabe- und
Sicherheitsvoraussetzungen vor. Es autorisiert keinen Netzwerkzugriff, keine
Host-Ausführung, keine Credentials und kein öffentliches SQL-Objekt.

## Grundsatz

Eine externe Capability ist kein allgemeines Script- oder Request-API. Jede
spätere Capability ist ein einzeln registrierter Work Type mit festem Zweck,
typisierten Parametern, explizitem Ergebnisvertrag und einem geprüften
Provider. Freier PowerShell-/Python-Text, beliebige URLs, dynamische Imports,
Paketinstallation, Header oder Credentialwerte aus Procedure-Parametern sind
ausgeschlossen.

`xp_cmdshell`, OLE-Automation sowie SQL-CLR mit `EXTERNAL_ACCESS` oder
`UNSAFE` sind keine Standardprovider. Sie werden nicht durch dieses Dokument
zugelassen.

## Freigabedossier je Capability

Vor der Implementierung muss die Funktionsbesprechung für jede Capability
mindestens diese Informationen festlegen:

| Bereich | Erforderliche Entscheidung |
|---|---|
| Zweck und Daten | Fachlicher Zweck, Datenklassifikation, erlaubte Eingabefelder und ausgeschlossene Datenklassen. |
| Provider und Identität | Konkreter Provider, Service-/Proxy-Identität, minimal erforderliche Rechte und Plattform-/Installationsvoraussetzungen. |
| Ziel | Registrierter Work Type oder kanonische HTTPS-Endpoint-Allowlist einschließlich Methode, Port und Redirect-Regel. |
| Vertrag | Versionsgebundenes Parameterschema, maximale Größen, Ergebnis-/Fehlerform, Content-Type und keine freien Script-/Headerfelder. |
| Laufzeit | Synchronous/asynchronous, Timeout, Cancellation, Parallelitätslimit und Verhalten unter Caller-Transaktionen. |
| Wiederholung | Retry-Klassen, Idempotency-Key und die Wirkung einer möglichen Doppelzustellung. |
| Secrets und Audit | Referenz auf eine externe Secret-Verwaltung; Redaction-Regeln; Auditmetadaten ohne Payload, Secrets oder Antwortinhalt. |
| Betrieb | Owner, Versionierung, Deaktivierung, Rollback und ein kontrollierter Testmodus mit synthetischen Daten. |

Fehlt eine dieser Entscheidungen, bleibt die Capability nicht registrierbar.

## Gemeinsame sichere Laufzeitform

Eine spätere Ausführung soll einen serialisierten, allowlisted Auftrag an den
registrierten Provider übergeben. Der Provider erhält nur das validierte
Parameterschema und gibt einen begrenzten, typisierten Erfolgs- oder Fehlerwert
zurück. Request-/Response-Payloads und Prozessausgaben werden nicht als
Toolbelt-Diagnose gespeichert. Eine Correlation-ID darf die Ausführung
verknüpfen, ohne sensible Inhalte preiszugeben.

REST erfordert HTTPS, feste Endpoint-Allowlist, keine Redirect-Umgehung,
Request-/Response-Limits, Content-Type-Prüfung und Schutz vor SSRF. PowerShell
und Python brauchen zusätzlich eine statische Capability-Bindung; die
ausführbare Datei, das Modul und die Runtimeversion werden durch die
Deploymentartefakte festgelegt, nicht durch Aufrufparameter. Lang laufende
Aufrufe dürfen keine offenen fachlichen Sperren halten.

## Reihenfolge

1. **REST-Grundvertrag (`TC-2026-027`)** mit genau einer später gewählten,
   synthetisch testbaren HTTPS-Capability und ohne generische URL-Eingabe.
2. **Python (`TC-2026-026`)** nur für einen datenorientierten, von
   Host-Automation getrennten Work Type mit festem Package- und
   Runtimevertrag.
3. **PowerShell (`TC-2026-025`)** zuletzt und nur für eine konkrete,
   hochprivilegierte Betriebsaufgabe mit gesondert geprüfter Identität.

KI- und Chat-Capabilities bleiben nachgelagert: Sie benötigen zusätzlich eine
Datenübertragungs-, Modell-, Kosten- und Output-Validierungsentscheidung und
werden durch dieses Gate nicht freigegeben.

## Tests und Entscheidungspunkt

Tests verwenden ausschließlich lokale oder explizit synthetische Ziele und
Payloads. Sie prüfen Allowlist-Verstöße, Schemafehler, Limits, Timeout,
Cancellation, Retry-/Idempotenzverhalten, Redaction, deaktivierte Capability,
Providerfehler und Windows-/Linux-Deployment. Reale Endpoints, Credentials,
Hostinventar oder Antworten sind keine Testartefakte.

Vor einer Implementierungsfreigabe wird für den ausgewählten Kandidaten ein
vollständiges Freigabedossier beschlossen. Danach folgen konkrete Signatur,
Provider und Testmatrix als Funktionsvertrag; diese Grundlage ersetzt keine
funktionsbezogene Freigabe.

## Quellen

- [Microsoft: sp_invoke_external_rest_endpoint](https://learn.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-invoke-external-rest-endpoint-transact-sql?view=sql-server-ver17)
- [Microsoft: SQL Server Agent PowerShell](https://learn.microsoft.com/en-us/powershell/sql-server/run-windows-powershell-steps-in-sql-server-agent?view=sqlserver-ps)
- [Microsoft: sp_execute_external_script](https://learn.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-execute-external-script-transact-sql?view=sql-server-ver17)
- [bestehende Candidates](../../Backlog/TOOLBELT_CANDIDATES.md#tc-2026-025-kontrollierte-powershell-host-automation)
