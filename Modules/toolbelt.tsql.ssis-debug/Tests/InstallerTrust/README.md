# Administrativen SSIS-Trustschritt prüfen

Dieser Bereich qualifiziert ausschließlich das getrennte öffentliche
`Deployment/Add-TrustedAssembly.sql` für den bereits freigegebenen aktuellen
SSIS-Binary. Er ergänzt die [fachliche Prüfmatrix](../README.md); er installiert
keine Module und verändert keine Labressourcen, Serverkonfiguration oder Rechte.
Die vollständige Windows-Anmeldung des Installers und das Beispiel
`PrepareServer.sql` bleiben eigene Prüfungen.

## Voraussetzungen und Ablauf

`Invoke-LabTrust.ps1` benötigt PowerShell 7.5, den schema-validierten bestehenden
Labvertrag und genau die expliziten READY-Ziele Windows SQL2019/CU32,
SQL2022/CU26 und SQL2025/CU8. Vor jedem SQL-Zugriff werden Vertrag, Ziel,
Quelldateien und der aus dem vorhandenen Parameter-Help-Paket extrahierte
Binary geprüft. Ein neu versiegelter Plan kann keinen anderen Binary
autorisieren: der Runner prüft dessen Ursprung unabhängig gegen die fest
gebundene öffentliche Funktionsabnahme. Credentials bleiben im Speicher.

1. Einen neuen privaten Plan erzeugen, beispielsweise mit `-Mode Prepare
   -PlanPath .runtime/trust-check/plan.private.json`. Der Modus öffnet keine
   SQL-Verbindung und überschreibt keinen vorhandenen Plan.
2. Den Plan-SHA256 ermitteln und mit `-Mode Qualify`, `-ExpectedPlanSha256` und
   `-ValidateOnly` prüfen. Dieser Modus benötigt weder Labzugriff noch eine
   SQL-Verbindung.
3. Jeden der drei Fälle einzeln mit `-CaseIndex 0`, `1` oder `2` und einem neuen
   privaten `-JournalPath` ausführen. Der echte Preflight prüft Windows,
   Engine/CU, vorhandenen sysadmin und aktive CLR Strict Security. Eine fehlende
   Trustzeile und fehlende Assemblyverbraucher sind Voraussetzung der Fälle.
4. Nach jedem beendeten Fall `-Mode Audit` mit demselben Plan und dem exakten
   `-ExpectedJournalSha256` aufrufen. Der Audit öffnet eine unabhängige Verbindung
   und vergleicht Trust- und Konfigurationszustand mit dem Vorzustand.

Ein vorhandener Konfigurationslease wird respektiert. Nur ein selbst erzeugter,
unverändert gebundener und nicht mehr verwendeter Trusteintrag wird entfernt.
Ownershipdrift oder unbekannter Ausgang enden als `RECOVERY_REQUIRED`; dann
keine abhängigen Tests starten. Originaljournale und Fehler bleiben privat.
Die öffentlichen Records enthalten keine Runtime-Trusthashes, Beschreibungen,
Endpunkte, Credentials oder Rohlogs.

## Orakel und Ergebnis

Vor dem ersten Eintrag prüft ein bestehender datenbankbezogener Guest-Kontext
seine fehlende Serverautorität und dass er keinen Trusteintrag erzeugt. Das ist
kein separater Lowpriv-Netzwerklogin. Danach folgen der öffentliche administrative
Opt-in des exakten freigegebenen Hashs, dessen Wiederholung mit unverändertem
Descriptor sowie leere, NULL- und überlange Literale. Jeder ungültige Wert muss
vor einer Truständerung mit dem öffentlichen Fehler 50000 scheitern. Der
überlange Testwert beginnt ausschließlich mit dem bereits genehmigten Hash;
kein unbekannter Hash darf jemals Trust erhalten.

`PASS_CLEANED` allein ersetzt keinen unabhängigen Audit. Erst der Aggregatrecord
[AdministrativeTrust.Windows.20261101.json](../Qualification/AdministrativeTrust.Windows.20261101.json)
bindet drei erfolgreiche Fälle mit je 18 Assertions und drei frischen Audits.
Die ursprünglichen Adapter-/Guardfehler und die erste erfolgreiche Methodenversion
bleiben getrennte Historie; die finale Abnahme zählt 54 Assertions.

Der öffentliche Guard prüft jetzt zuerst als `varbinary(max)` und weist auch
NULL selbst zurück. Erst danach entsteht `varbinary(64)` für die Systemprozedur.
Damit kann eine Zuweisung überlange Werte nicht vor der Längenprüfung kürzen.
Die [Microsoft-Dokumentation](https://learn.microsoft.com/en-us/sql/t-sql/data-types/binary-and-varbinary-transact-sql)
beschreibt diese Konvertierung; die
[Systemprozedur](https://learn.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sys-sp-add-trusted-assembly-transact-sql)
benötigt sysadmin oder CONTROL SERVER. Der Runner verwendet ausschließlich
bereits vorhandene Rechte und vergibt keine.

## Integration des Importadapters

Die Windows-CI verlangt beim isolierten Import den kanonischen Variablennamen
für den Repositoryroot. Nach den nativen Läufen wurde ausschließlich vor dem
Dot-Import ein wertgleicher `$repoRoot`-Alias ergänzt. Die ursprünglichen
Native-Pins bleiben erhalten. Der Validator rekonstruiert die ausgeführten
Bytes durch genau diese eine umkehrbare Textänderung; jede weitere Änderung
wird abgewiesen. Die SQL-/Rechte-/Cleanupfunktionen bleiben bytegleich.
Die echte kalte Importprüfung und alle `ValidateOnly`-Gegenproben bestanden
auch nach dieser Integration. Es wird kein zusätzlicher SQL-Lauf behauptet.

## Nachweise wiederverwenden

Der [Offlinevalidator](../../../../Scripts/Release/validate_ssis_administrative_trust.py)
bindet native Methode, aktuellen Guard und den unveränderten Binaryursprung.
27 Gegenproben, darunter tatsächlich ausgeführte `ValidateOnly`-Manipulationen,
laufen im bestehenden SSIS-CI-Job; keine neue SQL-/Lab-Matrix wird in CI gestartet.

Der ältere Snapshotnachweis behält seine Originalpins und sein unverändertes
Installationspaket. Ausschließlich sein später geänderter administrativer
Input wird aus genau diesem hashgebundenen historischen ZIP gelesen; der
heutige Guard benötigt daneben diese eigene native Abnahme. Unbekannte
Quelländerungen oder andere Pfade werden nicht akzeptiert. Die übrigen
Snapshotmethoden, Generator-/Binary-/Paketbindungen und alten Reports bleiben
unverändert. Daraus entsteht kein behaupteter neuer Snapshotlauf.

Dieselbe begrenzte Anerkennung gilt für die administrative Buildmetadatenzeile
im unveränderten Help-Paket. Der Kandidatenbuilder prüft sie ausschließlich
gegen seine übergebenen versionierten Git-Bytes einschließlich des aktuellen
nativen Trustrecords, nicht gegen einen möglicherweise abweichenden Arbeitsbaum.
Andere Buildquellen und Modulprofile bleiben exakt gebunden.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-11-01`
- Nachweis: `local: öffentlicher Windows-Installer und CLI/API auf SQL2025/CU8, CL150; frischer Windows-Audit`
- Scope: NTLM mit vorhandenen sysadmin-Rechten, öffentliche PrepareServer-Vorbereitung und Install-Local-Erst-/Wiederholungsinstallation, unveränderter Trust bei Wiederholung, aktuelle38-Parameter-API und vollständige DebugScript-Ausführung mit zwei Ergebniszeilen. Zehn Assertions für diesen begrenzten Teilumfang und exakte eigene Wiederherstellung; frischer Windows-Abschlussaudit PASS. Der anschließende sichtbare SSMS-Handshake scheiterte vor der ersten GUI-Abfrage; der Gesamtkoordinator bleibt FAILED_CLEANED. Separate Source-/Scope-Gegenproben verhindern eine Aufwertung zum GUI-PASS. Lab-Hostclientquellen entsprechen dem gemergten PR859; ursprüngliches importiertes Labmodul und ausgeführte Bytes bleiben getrennt gebunden. Frühere Fehler/Abbruchzustände und Audits erhalten. Windows-/SSMS-Scripttransport bleibt offen; keine Veröffentlichung.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
