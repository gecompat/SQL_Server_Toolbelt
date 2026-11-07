# Table Clone 4.1.1: aktueller Trigger-Consumer

Am 2026-11-07 bestanden die beiden unveränderten Trigger-Fixtures des aktuellen
Consumers auf allen sechs unterstützten Windows-/CL-Paaren lokal und direkt
zentral: **sechs Gesamtfälle, zwölf Kontexte, 24 vollständige Fixture-Ausführungen
und sechs frische unabhängige Audits**. Alle zwölf eigenen Datenbanken und
zwölf eigenen Trusteinträge sind entfernt. Drei eigene CLR-Konfigurationsscopes
sind wiederhergestellt. Ergebnis: **PASS_FOR_DECLARED_CURRENT_WINDOWS_TRIGGER_SCOPE**.

| Ausgewähltes SQL-Ziel | Compatibility Levels | Modi | Kontexte |
|---|---|---|---:|
| Windows 2019/CU32 | 150 | lokal/direkt zentral | 2 |
| Windows 2022/CU26 | 150, 160 | lokal/direkt zentral | 4 |
| Windows 2025/CU8 | 150, 160, 170 | lokal/direkt zentral | 6 |

Windows-Clienthost, vorhandene administrative Lab-Anmeldung. Direkt zentral
bezeichnet SameDB-Nutzung. Trigger-Opt-in ist Windows-only; daraus entsteht
keine Linux-Triggerzusage oder neue Netzwerk-/CrossDB-Identität.

## Konkrete Ursache und aktuelle Quellenbindung

Table Clone prüfte noch den Providerhash eines früheren Parser-2.0.1-Builds.
Der aktuelle, separat qualifizierte Parser hat dieselbe Modulversion und
einen anderen Providerhash. Vor der Änderung wurden alle 20 Produktquellen
des aktuellen Parsernachweises, die fünf Quell- und fünf Deploymentpins des
Release-Manifests, beide tatsächlichen DLLs und die vier ursprünglichen
nativen Artefaktpins geprüft. Sie stimmen überein. Der vorhandene vollständige
Frameworknachweis bindet dasselbe Artefaktpaar. Kein neuer Parserbuild.

Der [Methodenstand `a9665206`](https://github.com/gecompat/SQL_Server_Toolbelt/commit/a9665206851c1111029992236ae6cae6890d0cb5)
ersetzt im bestehenden `IncludeTriggers=1`-Gate ausschließlich das eine
Hashliteral. Parser 2.0.1, ScriptDom 18.0.117.0, exakte Assembly-/TVF-Bindings,
Version-/Modusmarker und sämtliche übrigen Ablehnungen bleiben erhalten.
Der [aktuelle Vertrag](../../Documentation/Architecture/TABLE_CLONE_TRIGGER_CONTRACT.md)
führt den exakten statischen Dependency-Pin. Frühere Binärpaare und ihre
historischen Nachweise werden nicht umgedeutet. Es gibt keinen Legacy-Fallback
und keine automatische Parserinstallation durch den Produkt-Consumer.

## Tatsächlich ausgeführte Originale

Der [begrenzte Treiber](../../Tests/Release/Invoke-TableCloneTriggerLab.ps1)
installiert ResultTable 1.0.0, den bekannten Parser 2.0.1 mit seinem bekannten
ScriptDom und Table Clone 4.1.1 in eigenen temporären Datenbanken. Die kanonische
Parser-Installation ersetzt ausschließlich ihre drei vorhandenen
DeploymentMode-Platzhalter durch den jeweiligen Modus. Alle anderen Bytes
bleiben identisch zum gepinnten Releaseartefakt.

Pro Kontext werden vollständig und genau einmal ausgeführt:

1. [Trigger.Contract.sql](../../Modules/toolbelt.metadata.table-clone/Tests/Runtime/Trigger.Contract.sql):
   synthetische Unicode-/Kommentar-/Literal-/Mapping-/CTE-/Aliasfälle,
   Header-/Zielumschreibung, Zustände und tatsächliche DML-Orakel der erzeugten
   AFTER-/INSTEAD-OF-Trigger.
2. [Trigger.Safety.sql](../../Modules/toolbelt.metadata.table-clone/Tests/Runtime/Trigger.Safety.sql):
   die darin enthaltenen konservativen Ablehnungen und Kollisionsfälle samt
   Callerzustand und unverändertem ResultTable-Sentinel.

24 zählt vollständige Fixture-Ausführungen, keine erfundene Zahl einzelner
Assertions. Zusätzliche unsichtbare oder mehrdeutige Bindungen unter einem
echten eingeschränkten Caller werden durch diese Admin-Fixtures nicht belegt.
Die Originale weisen diese Grenze ausdrücklich aus. Der Produkt-Planner
führt weiterhin keinen erzeugten Plan aus; die Testfixture führt ihre eigenen
synthetischen DDL-/DML-Orakel aus.

Tatsächliches CL, Ziel-Major-/Plattform-/Softwarebindung, drei installierte
Modulversionen und Modi sowie die beiden Assemblies werden geprüft. Nach
jeder Fixture ist die Sitzung transaktionsneutral; die Produktdefinitionen
bleiben zwischen Beginn und Ende des Kontexts identisch.

## Begrenzung, Wiederherstellung und unabhängige Abnahme

Vor erstem SQL galten gemeinsam höchstens **16 Ziel-/Auditaufrufe,
16 eigene DB-Reservierungen und 60 Minuten**. Tatsächlich benötigt wurden
**zwölf Aufrufe und zwölf Reservierungen**, ohne native Korrektur oder
Wiederholung. Alle ungenutzten Plätze sind geschlossen. Producer und Audit
haben jeweils eine eigene Prozessgrenze von 400 Sekunden und getrennte
4-MiB-Kanäle; vor weiterer Zulassung bleiben 15 Minuten Reserve.

Der unveränderte bestehende CLR-Konfigurationshelfer prüft strikte Sicherheit,
ausstehende Änderungen und fremde Verbraucher vor einer nötigen Aktivierung.
Nur der eigene unveränderte Scope darf danach wiederhergestellt werden.
Die exakten bekannten Trusteinträge erhalten vollständige private
Ownership-Fingerprints und Verbraucherprüfungen. Fremde Einträge oder Drift
werden nicht überschrieben. Nach Entfernung aller eigenen DB-Verbraucher
werden ausschließlich eigene unveränderte Einträge entfernt.

Jeder separate frische Audit bindet den exakten finalen Originaljournalhash,
DB-Abwesenheit, tatsächliches Ziel, alle Inputpins und den vollständigen
ursprünglichen Konfigurations-/Trustzustand. Der unabhängige lokale Nachprüfer
bestätigt alle sechs erfolgreichen Fälle, zwölf Kontexte, 24 Fixture-Abschlüsse,
sechs Audits, zwölf DB-Entfernungen, zwölf Trust-Entfernungen und drei
Konfigurationswiederherstellungen. Kein Native-Fehllauf wird aufgewertet.

Zwölf öffentliche verbindungslose Admission-/Scope-/Quellengegenproben und
zwölf private Gegenproben am echten Releaseartefakt bestanden. Letztere
prüfen insbesondere falsche Versionen/Pins/Permission-Sets, fehlende
Quellenbindung und falsche Modusauflösung. Ein erster SQL-freier Entwurf
erwartete irrtümlich nur einen Modus-Platzhalter; die gepinnte kanonische
Quelle enthält drei. Die Korrektur und beide ursprünglichen Testlogs bleiben
privat erhalten. Parser150 für die drei betroffenen SQL-Inputs und die
gekoppelte Modulstatik bestanden ebenfalls.

Beide vorgesehenen vollständigen lokalen Audits endeten mit genau einem
Fehler im neuen Offlineadapter: zuerst bei impliziter lokaler Dekodierung,
danach bei bloß expliziter UTF-8-Dekodierung einer anders kodierten
PowerShell-Ausgabe. Beide Full-Logs bleiben fehlgeschlagene Nachweise. Die
Korrektur legt nun im gestarteten PowerShell-Prozess die Ausgabe und in Python
die Leseseite ausdrücklich und strikt auf UTF-8 fest. Alle zwölf betroffenen
Offlineprüfungen bestanden danach einschließlich der gezielt erzwungenen
Windows-Start-Codepages 850 und 1252. Sämtliche ursprünglichen Testquellen und
Fehllogs bleiben erhalten. Der erforderliche Gesamtaudit wird innerhalb des
bereits begrenzten CI-Rahmens am tatsächlichen aktuellen PR-Head ausgeführt;
ein dritter lokaler Full-Lauf wurde nicht gestartet. Der native Produkt-/
Treiberstand und seine Audits bleiben unverändert bestanden; keine native
Wiederholung.

## Wiederverwendung und getrennte Restpunkte

Die einzige Produktänderung liegt im vorhandenen, bei Option 0 unerreichbaren
Trigger-Gate. Eine Gegenprobe rekonstruiert nach Rückersetzung genau dieses
einen Literals den vollständigen normalisierten SQL-Quellhash des vorherigen
Main. Der übrige Core, öffentliche Fassaden, Executor, Copy, Lifecycle und
alle Originalfixtures bleiben unverändert. Deshalb werden die gültigen
[Copy-Zielnachweise](TABLE-CLONE-COPY-TARGET-QUALIFICATION.md),
[Planner-/Executor-Nachweise](TABLE-CLONE-PLANNER-EXECUTOR-QUALIFICATION.md) und
[W1-/W2-Nachweise](TABLE-CLONE-W1-W2-QUALIFICATION.md) für Option 0 mit dieser
ausdrücklich geprüften Quellenäquivalenz wiederverwendet. Ihre ursprünglichen
Rohhashes werden nicht als identisch zum neuen Core ausgegeben. Keine grüne
Option-0-Labwelle wurde gestartet. Die erforderliche Head-/Main-CI prüft den
betroffenen aktuellen Quellenstand separat.

Keine neuen Rechte, Principals, Ownerübertragungen, Lab-, Zertifikats- oder
Truststoreänderungen. Alle Originaljournale, Rohlogs, Konfigurationswerte,
Trustfingerprints und realen Identitäten bleiben privat. Funktionale
Verschlüsselung mit explizitem Labtrust qualifiziert keine authentifizierte
TLS-Verbindung. Echte weitere Minimalrechte, zusätzliche Client-/CrossDB-
Identitäten, genuine aktuelle Upgrade-/Uninstall-/Recoveryfälle und die
Modulgesamtfreigabe bleiben getrennt. Status weiterhin teilweise validiert
und unveröffentlicht; keine Veröffentlichung oder Tags.
