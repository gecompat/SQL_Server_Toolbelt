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

## Nachweise wiederverwenden

Der [Offlinevalidator](../../../../Scripts/Release/validate_ssis_administrative_trust.py)
bindet native Methode, aktuellen Guard und den unveränderten Binaryursprung.
26 Gegenproben, darunter tatsächlich ausgeführte `ValidateOnly`-Manipulationen,
laufen im bestehenden SSIS-CI-Job; keine neue SQL-/Lab-Matrix wird in CI gestartet.

Der ältere Snapshotnachweis behält seine Originalpins und sein unverändertes
Installationspaket. Ausschließlich sein später geänderter administrativer
Input wird aus genau diesem hashgebundenen historischen ZIP gelesen; der
heutige Guard benötigt daneben diese eigene native Abnahme. Unbekannte
Quelländerungen oder andere Pfade werden nicht akzeptiert. Die übrigen
Snapshotmethoden, Generator-/Binary-/Paketbindungen und alten Reports bleiben
unverändert. Daraus entsteht kein behaupteter neuer Snapshotlauf.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-11-01`
- Nachweis: `local: Tests/InstallerTrust/Invoke-LabTrust.ps1 auf drei bestehenden Windows-Labzielen und unabhängige Audits`
- Scope: Öffentlicher administrativer SSIS-Trustschritt für den unveränderten aktuellen Binary auf SQL2019/CU32, SQL2022/CU26 und SQL2025/CU8: je 18 Assertions, 54 insgesamt, fehlender Eintrag und Wiederholung, NULL/Leerwert/Überlänge vor Mutation und bestehender eingeschränkter Guest-Kontext. Keine Netzwerk-Lowpriv-Anmeldung behauptet. Eigene Einträge entfernt, andere Trusteinträge und Konfiguration unverändert; drei finale unabhängige Audits PASS. Ein Vor-SQL-Adapterfehler, zwei bereinigte Fehlerfälle und drei frühere positive Fälle bleiben getrennt; alle acht tatsächlich ausgeführten Audits bestanden, insgesamt 17 Ziel-/Auditaufrufe. 26 Offlineprüfungen binden Quellen, Herkunft und Vor-SQL-Guards im bestehenden SSIS-Job. Ursprünglicher Snapshotinput für den später geänderten administrativen Guard wird ausschließlich aus seinem unveränderten hashgebundenen ZIP anerkannt, übrige Methoden/Binaries/Reports bleiben unverändert. Volle Windows-Anmeldung des Installers, PrepareServer, SSMS-Transport und harte Unterbrechung bleiben getrennt. Keine Veröffentlichung.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
