# SSIS Data Flow Debug SELECT

Dieses Modul erzeugt aus DTSX-Paketbytes eine bearbeitbare JSON-Bindungsvorlage
und lesende Debug-Skripte fÃ¼r unterstÃ¼tzte SQL-Server-DatenflÃ¼sse. Es hilft,
einen ausgewÃ¤hlten Datenflusspfad zu erklÃ¤ren und seine Abfrage nachvollziehbar
zu prÃ¼fen. Es ist keine vollstÃ¤ndige SSIS-Runtime; beliebige Paketklassen oder
Schreib-/AusfÃ¼hrungspfade werden nicht pauschal unterstÃ¼tzt.

## Installation und erster Datenflusspfad

1. FÃ¼r Neuinstallation den [gemeinsamen aktuellen Installer](../../INSTALL.md)
   mit einem Windows-Profil wÃ¤hlen. Das Modul benÃ¶tigt SQL Server unter Windows,
   CLR, die exakte Parser-/ScriptDom-Dependency und bewusst eingerichteten Trust.
   Das Portable-Profil enthÃ¤lt den SQL-SSIS-Provider nicht.
2. Die [API-Anleitung](Documentation/USP_ExplainSsisDataFlow.md) erklÃ¤rt den
   vollstÃ¤ndigen synthetischen Aufruf: DTSX-Bytes bereitstellen, mit
   `bindings-template` die JSON-Vorlage erzeugen, Quellen/Ziele bewusst binden
   und mit `explain` den gewÃ¤hlten Pfad prÃ¼fen. Parameter, feste Werte,
   Ergebnisse und Fehler stehen dort; `@Hilfe=1` ergÃ¤nzt die installierte Hilfe.
3. Das Ergebnis anhand des aufgelÃ¶sten Zielpfads und seiner Diagnosen beurteilen.
   Nur ein unterstÃ¼tzter vollstÃ¤ndig auflÃ¶sbarer Pfad liefert den vorgesehenen
   `DebugScript`-Umfang. SQL vor bewusster AusfÃ¼hrung prÃ¼fen; ein Modell oder
   Scripttext ist noch keine erfolgte SSIS-PaketausfÃ¼hrung.
4. FÃ¼r Wiederverwendung des freigegebenen Derived-Column-Pfads den
   [typisierten Prozedurvertrag](Documentation/USP_ExplainSsisDataFlow.md#geprÃ¼ften-zielpfad-als-prozedur-wiederverwenden)
   beachten. Copy Column hat [eigene Grenzen und Beispiele](Documentation/CopyColumnV1.md)
   und erweitert nicht automatisch den Prozedurdefinitionsumfang.

| Ich mÃ¶chte â€¦ | NÃ¤chste Seite |
|---|---|
| Bindungen, Parameter, Resultsets und Fehler verstehen | [Ã–ffentliche API](Documentation/USP_ExplainSsisDataFlow.md) |
| Komponenten und Ressourcenlimits nachschlagen | [Aktueller Fachvertrag](../../Documentation/Architecture/SSIS_CURRENT_API_CONTRACT.md) |
| Das neutrale Modell auÃŸerhalb SQL Servers exportieren | [Windows-/Linux-Modellhost](Exchange/README.md) â€” eigener Hostvertrag, kein Linux-SQL-CLR-Provider |
| Eine bestehende Installation Ã¤ndern oder entfernen | [Modul-Lifecycle und Deployment](../../Documentation/Architecture/MODULE_AND_DEPENDENCY_MODEL.md) |
| Nachweise und nicht geprÃ¼fte UmfÃ¤nge beurteilen | [PrÃ¼fÃ¼bersicht](Tests/README.md) |
| Ein frÃ¼heres Standalone-Paket nachvollziehen | [Gebundene Einzelpakete](InstallPackages/README.md) |

## Nachweisgrenzen und historische Lieferungen

Der gemeinsame Installer besitzt eine [eigene Installationsabnahme](../../Releases/1.0.0/CURRENT-INSTALL-QUALIFICATION.md).
Sie qualifiziert seine Komposition und Hilfe, nicht alle ursprÃ¼nglichen
GUI-/TLS-/SicherheitsfÃ¤lle fÃ¼r neue Providerbytes. Die frÃ¼heren Standalone-ZIPs
und Records bleiben an ihre Originalbinaries gebunden. Der
[historische Modulleitfaden](../../Documentation/History/SSIS_MODULE_GUIDE_2026-11-17.md)
erhÃ¤lt die bisherigen ausfÃ¼hrlichen Build- und Abnahmenotizen. Das Modul bleibt
teilweise validiert und unverÃ¶ffentlicht. Bei Installationsfehlern zuerst die
[FehlerklÃ¤rung](../../INSTALL.md#wenn-etwas-nicht-funktioniert) lesen; bei
Pfad-/Komponentenproblemen zur API-Diagnose und zum Fachvertrag zurÃ¼ckgehen.

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
