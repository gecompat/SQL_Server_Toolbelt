# SSIS Data Flow Debug SELECT


## Aktuelle Installation

Den [modulbezogenen Buildplan](Deployment/README.md) oder den
[gemeinsamen Installer](../../Deployment/ONE-CALL-INSTALL.md) verwenden.
Beide führen auf denselben markerfreien create-only-Kern: normale SQL-Datei,
kein SQLCMD-Modus, keine Deployment-Extended-Properties. Der aktuelle SQL-Assemblyname ist `tlblt_Tsql_SsisDebug`.
Die bisherigen Versions-/Lifecycleangaben weiter unten und ihre damaligen
Assemblynamen bleiben an die ursprünglichen Artefakte gebunden. Sie sind kein
aktueller Upgrade-/Uninstallweg und keine neue native Installerabnahme.


Dieses Modul erzeugt aus DTSX-XML SQL-Debugentwürfe für unterstützte
SQL-Server-Datenflüsse. Ein XML-Aufruf verwendet Paketdefaults und löst
Connection-Expressions auf. Es ist keine vollständige SSIS-Runtime und führt
weder Pakete noch erzeugte Abfragen automatisch aus.

## Installation und erster Datenflusspfad

Für den neuen markerfreien Quellstand den [gemeinsamen SQL-Installer](../../Scripts/Install/README.md) verwenden. Die folgenden modulspezifischen Lifecycle-Befehle gehören zum bisherigen markerbasierten Weg und sind kein Upgrade oder Uninstall für diesen Funktionssatz.

Der aktuelle Quellstand nimmt vollständiges DTSX als `@PackageXml` entgegen.
Paketdefaults, Startwerte und Connection-Expressions werden lokal aufgelöst.
Die [Kurzanleitung](Documentation/SimpleInstallation.md) führt vom normalen
SQL-Installer ohne SQLCMD bis zum XML-Aufruf, lokal oder zentral. Sie erklärt
auch die drei Trustwege und Wiederholung ohne Extended Properties.

```sql
EXEC toolbelt_tsql.USP_ExplainSsisDataFlow @PackageXml=@DtsxXml;
```

Standard ist `CatalogMode=package`: ein Debugentwurf ohne Quellkatalogzugriff,
mit `SafetyStatus=not_checked` und `IsExecutable=0`. Vor manueller Ausführung
prüfen. `CatalogMode=catalog` ergänzt reale Metadatenprüfung; die ausführliche
[API-Referenz](Documentation/USP_ExplainSsisDataFlow.md) beschreibt deren Rechte
und die weiterhin verfügbare Binding-Vorlage. Paket und SQL werden während der
Analyse niemals ausgeführt.

Die veröffentlichten Vorabreleases bis rc.4 und deren gemeinsame Installer
bleiben unverändert. Sie enthalten diesen neuen Vertrag noch nicht. Die
markerbasierten Lifecycle-Skripte sind kein Upgrade-/Uninstallweg für die neue
markerlose Installation. Details dazu stehen in der Kurzanleitung.

| Ich möchte … | Nächste Seite |
|---|---|
| Installieren, XML übergeben und Debug-SQL lesen | [Kurzanleitung](Documentation/SimpleInstallation.md) |
| Parameter, Resultsets und Fehler verstehen | [API-Referenz](Documentation/USP_ExplainSsisDataFlow.md) |
| Komponenten und Grenzen nachschlagen | [Fachvertrag](../../Documentation/Architecture/SSIS_CURRENT_API_CONTRACT.md) |
| Neutrales Modell außerhalb SQL Servers exportieren | [Modellhost](Exchange/README.md) |
| Historische und neue Nachweise unterscheiden | [Prüfübersicht](Tests/README.md) |

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-11-16`
- Nachweis: `local: frische SecurityCorrected-ZIP-Matrix und sichtbarer Windows-/SSMS-Gesamtfall`
- Scope: PASS_FOR_DECLARED_SCOPE: zwoelf Windows2019CU32/2022CU26/2025CU8-CL-/Moduskontexte mit15204Assertions und zwoelf frischen finaljournalgebundenen Audits. Derselbe korrigierte Provider besteht den eigenstaendigen sichtbaren Windows-/SSMS-Gesamtfall mit17Checks, echter184441-Zeichen-Unicodekopie, nativer51001SQLCMD-Stopprobe und Phase2-Receipt; separaterWindowsauditPASS. Insgesamt26Lauf-/Auditaufrufe,25DBs und12synthetischeLogins entfernt, kein nativerFehler/Retry. Gueltige Framework-/ANSI-/TLS-/Sicherheitsbelege wiederverwendet, historischeArchive/Records unveraendert. Kein Windows-/TLS-Identitaetsunion-, Linux-Host- oder Modulgesamt-PASS, keineVeroeffentlichung.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->

Der optionale externe [Begleittransport fÃ¼r native Objektkennungen](Exchange/README.md#native-objektkennungen-als-begleittransport)
verwendet denselben Paketkern. Er liefert GUIDs fÃ¼r eine separat zu belegende
Analyze-Korrelation und enthÃ¤lt weder einen Logdecoder noch ein Laufzeiturteil.
