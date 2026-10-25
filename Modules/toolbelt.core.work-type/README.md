# Work Type Catalog

Vollständige Plattform-Evidenz 2026-09-01: `local: Tests/CI/run-lab-local.ps1` belegt den erfolgreichen Moduladapter auf physischen SQL-Server-2019-, 2022- und 2025-Zielen unter Windows base und Linux latest. Dieser Nachweis ersetzt frühere offene oder `not executed`-Aussagen; datierte ältere Einträge bleiben als historische Evidenz erhalten.

## Status

`toolbelt.core.work-type` Version `1.2.0` ist implementiert und teilweise validiert. Die neue Policy wurde auf Linux SQL Server 2019 nativ geprüft; historische 1.1.0-Plattformnachweise sind keine neue Policyqualifikation.

Die [zusätzliche Rechtequalifikation vom 2026-10-25](../../Releases/1.0.0/WORK-TYPE-RIGHTS-QUALIFICATION.md)
prüft alle sechs öffentlichen APIs lokal und direkt zentral auf Windows/Linux
SQL2019/2022/2025 mit den unterstützten CLs. Sie belegt abgegrenzte Caller-,
Handler- und Policyrechte; weitergehende Rollen-/Lifecycle-/CrossDB-Verträge
und vollständige Releasequalifikation bleiben separat.

## Zweck

Das Modul registriert ausschließlich vorhandene Stored Procedures als benannte Work Types. Es akzeptiert und speichert keinen frei ausführbaren SQL-Text.

Der persistente Katalog hält Handler, ParameterMode, deklarativen JSON-Payloadvertrag, Default-Timeout, Idempotenzhinweis, Enabled-Zustand, Auditwerte und `rowversion`. Direkte DML auf die interne Tabelle ist kein öffentlicher Vertrag.

Version `1.1.0` ergänzt die kontrollierte Entfernung eines deaktivierten Work Types. `USP_RemoveWorkType` verlangt ausdrücklich `@AllowDelete = 1`, unterstützt eine optionale `rowversion`-Prüfung, arbeitet in Caller-Transaktionen mit einem Modul-Savepoint und lehnt Änderungen bei `XACT_STATE() = -1` ab. Ein aktiver Work Type kann nicht direkt gelöscht werden.

## Öffentliche Objekte

- `toolbelt_core.VW_WorkTypes`
- `toolbelt_core.USP_RegisterWorkType`
- `toolbelt_core.USP_DisableWorkType`
- `toolbelt_core.USP_RemoveWorkType`
- `toolbelt_core.USP_ResolveWorkType`
- `toolbelt_core.USP_SetWorkTypePermission`

Registrierung, Änderung, Deaktivierung und Entfernung sind administrative Vorgänge. Ein registrierender Principal muss `EXECUTE` auf die Zielprocedure besitzen. Ausführungsprovider erhalten einen getrennten Berechtigungs- und Ausführungsvertrag.

Basis-Evidenz Version `1.0.0`: https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30703339193

Removal-Evidenz Version `1.1.0`: https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/31016136937

Der vollständige Moduladapter war am 2026-08-29 auf physischen
SQL-Server-2019-, 2022- und 2025-Linux-Zielen erfolgreich.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-09-01`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Physische SQL-Server-2019-, 2022- und 2025-Ziele unter Windows base und Linux latest; vollständiger W4-Moduladapter mit lokalem und zentralem Deployment, Transaktions-, Konkurrenz-, Lifecycle- und Uninstall-Tests
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->

## Freigegebene Security-Härtung 2026-10-15

Katalogversion 1.2.0 ergänzt die leere WorkTypePermission-Tabelle, die interne
inline TVF_WorkTypeAuthorization und die Verwaltungs-USP
[USP_SetWorkTypePermission](Documentation/USP_SetWorkTypePermission.md).
ALLOW/DENY binden Work-Type-RowVersion und Principal-ID/SID/Erstellungszeit.
Aktuelle DBtoken einschließlich Rollen entscheiden, DENY zuerst. Ohne ALLOW
wird auch dbo abgewiesen. Nach Änderungen ist explizite Neukonfiguration nötig.
Deployment übernimmt keine alten Rechte und erzeugt keine Policyeinträge.

Der [freigegebene Vertrag](../../Documentation/Architecture/SECURITY_HARDENING_2026_10.md)
beschreibt Scope, Migration und Grenzen. Historische Plattformnachweise gelten
weiter ausschließlich für ihre datierten Quellen.
