# Table Clone 4.1.1: genuiner V1-Lifecycle

Am 2026-11-07 bestand die gezielte aktuelle Lifecycle-Profilmatrix für den
echten öffentlichen V1-Vorgänger auf zwölf Windows-/Linux-Engine-/CL-Paaren
lokal und direkt zentral: **24 Kontexte und 240 eindeutig belegte Profile**.
Ergebnis: **PASS_FOR_DECLARED_GENUINE_V1_PROFILE_MATRIX_WITH_REUSE**.

Dabei sind **elf vollständige Fälle und ein Fall mit gebundener
Teilwiederverwendung** zu unterscheiden. Für diesen einen Fall werden vier
bereits bestandene lokale Profile aus dem ursprünglichen Fehllauf mit sechs
neuen lokalen und zehn neuen zentralen Profilen verbunden. Die beiden alten
Gesamtkoordinatoren bleiben **FAILED_CLEANED**. Keine Behauptung von zwölf
vollständig bestandenen Originalkoordinatoren oder einer Modulgesamtfreigabe.

| Ausgewähltes SQL-Ziel | Compatibility Levels | Modi | Kontexte |
|---|---|---|---:|
| Windows 2019/CU32 | 150 | lokal/direkt zentral | 2 |
| Windows 2022/CU26 | 150, 160 | lokal/direkt zentral | 4 |
| Windows 2025/CU8 | 150, 160, 170 | lokal/direkt zentral | 6 |
| Linux 2019/latest | 150 | lokal/direkt zentral | 2 |
| Linux 2022/latest | 150, 160 | lokal/direkt zentral | 4 |
| Linux 2025/latest | 150, 160, 170 | lokal/direkt zentral | 6 |

Windows bezeichnet den Clienthost mit System.Data.SqlClient und der vorhandenen
administrativen SQL-Lab-Anmeldung; Linux in der Tabelle bezeichnet das SQL-Ziel.
Functional mit erforderlicher Verschlüsselung und unverändertem explizitem
Trustwert. Kein Linux-Clienthost, keine Windows-SSPI-/GUI- oder authentifizierte
TLS-Abnahme und keine neue CrossDB-Identität.

## Echte Quellen statt zurückversioniertem Installer

Der [Methodenstand `6c717d31`](https://github.com/gecompat/SQL_Server_Toolbelt/commit/6c717d31ff3de2f1f7aeacd1f17c915f624c2533)
bindet den [begrenzten Treiber](../../Tests/Release/Invoke-TableCloneGenuineLab.ps1).
Die fünf unveränderten V1-Dateien werden mit dem vorhandenen
[Originalextraktor](../../Modules/toolbelt.metadata.table-clone/Deployment/New-LegacyTestArtifacts.ps1)
aus dem öffentlichen Commit `fdafa8038e4d5240dd727096f144c8d5fd884117`
gewonnen. Zulassung und unabhängiger Nachprüfer vergleichen tatsächliche
Originalbytes, SHA256, Version, Dateimenge und Provenienz. Keine Umbenennung
der aktuellen Source zu einem historischen Stand.

Sechs vollständige Lifecycle-Texte für beide Modi werden aus den kanonischen
Include-Bäumen abgeleitet und bei der Zulassung erneut exakt verglichen.
Alle tatsächlich gelesenen Baumknoten benötigen eigene Pins. Die anfänglichen
Exporte installieren ausschließlich ResultTable 1.0.0; der zu qualifizierende
Clone-Lifecycle erfolgt danach über die gesondert gebundenen Originaltexte.
Ein fehlender Pin des Originalextraktors wurde vor jeder SQL-Zulassung erkannt
und im privaten Vorbereiter ergänzt; null native Aufrufe oder DBs dieses Befunds.

## Zehn Profile je Kontext

1. Synthetischer später Installationsfehler im sauberen Zustand mit vollständigem Rollback.
2. Installation des echten V1-Originals.
3. Entfernung dieses V1-Standes mit dem aktuellen Uninstaller.
4. Erneute Originalinstallation als Ausgangspunkt des Upgrades.
5. Synthetischer später Fehler im V1-Upgrade mit vollständigem Rollback.
6. Tatsächliches V1 → 4.1.1-Upgrade.
7. Gleichversioniges aktuelles Wiederholungsdeployment ohne Zustandsdrift.
8. Synthetischer später Fehler im aktuellen Reinstall mit vollständigem Rollback.
9. Aktuelle Deinstallation.
10. Wiederholte Deinstallation ohne Zustandsdrift.

Die drei Fehlertexte werden ausschließlich über den eindeutigen Anker vor
COMMIT im aktuellen Originaltext abgeleitet. Erwartet sind SQL 54932/State 1,
ein neutraler Transaktionszustand und identische Vor-/Nach-Snapshots von
Moduldefinitionen, Schemaidentität/-owner sowie Modul-/Objekt-/Schemaproperties.
Die Eingriffsstelle wird bereits vor SQL geprüft. Keine Produktdatei geändert.
Jedes Profil bindet den kanonischen und den tatsächlich ausgeführten Texthash;
der unabhängige Nachprüfer rekonstruiert die exakten Fehlertexte bytegenau.

Bekannte Release-/Mode-Marker und Signaturanzahlen werden geprüft: V1 besitzt
zwei Prozeduren mit je neun Parametern, aktuell vier mit 13/14/14/9 Parametern.
Die Typkennung aus `char(2)` wird vor dem exakten Clientvergleich normalisiert.
Bei Entfernung müssen alle Clone-Objekte und beide Modulmarker fehlen. Die
ResultTable-Abhängigkeit einschließlich Definitionen, Owner und Properties
bleibt durch sämtliche Schritte identisch. Alle Sitzungen sind transaktionsneutral.

## Erhaltene Fehler und nachprüfbare Wiederverwendung

Der erste Gesamtfall scheiterte nach vier grünen lokalen Profilen am
Upgrade-Rollback. Der damalige Adapter ersetzte die ursprüngliche SQL-Diagnose
durch eine Kategorie; die tatsächliche erste SQL-Fehlernummer ist deshalb nicht
nachträglich belegt. Eigene DB entfernt, frischer Audit PASS mit
`originalRunPassed=false`; der Fehllauf bleibt unverändert.

Der [gebundene Restadapter `412fd357`](https://github.com/gecompat/SQL_Server_Toolbelt/commit/412fd3574973f556d620842733f7b4cd219a7d36)
behält diese vier Profile und ihre exakten Journal-/Audit-/Runsethashes.
Eine neue eigene DB wird als ausdrücklich nicht als Qualifikationsprofil gewertetes Setup aus dem echten
V1 rekonstruiert. Nur die fehlenden sechs lokalen Profile sowie der bislang
ungeprüfte zentrale Kontext dürfen laufen. Rewind der Frist, andere Prefixe,
Promotion des alten Koordinators oder geänderte Produkt-/Inputbindungen werden
abgewiesen. Das neue Receipt trennt `declaredRunPassed` vom ursprünglichen
`originalRunPassed`; ein gebundener Restlauf gilt nicht als neuer vollständiger
Originalgesamtfall. Gegenproben prüfen insbesondere Originalfehler, vier
exakte Profilnamen, Bereinigung, Eingabehashes, Kontext und disjunkte Auswahl.

Auch dieser erste Restlauf ist FAILED_CLEANED, mit **null neuen grünen Profilen**
und frischem Audit PASS. Seine zusätzliche private Diagnose belegt SQL 2714:
Der unveränderte V1-Installer hält temporäre Tabellen mit benanntem Primary Key
bis zum Sitzungsende. Die im Testadapter offen gehaltene V1-Sitzung kollidierte
mit der separaten aktuellen Upgrade-Probe. Daraus wird keine fehlende
Produktfunktion oder ursprüngliche Fehlernummer abgeleitet.

Der [korrigierte Sitzungsadapter `8aed0f7e`](https://github.com/gecompat/SQL_Server_Toolbelt/commit/8aed0f7ed6f715297ad892d5d752a53d14a4df1d)
führt Legacy-Installation, Reinstallation und das nicht als Qualifikationsprofil gewertete Restlauf-Setup
jeweils in einer eigenen, anschließend geschlossenen Sitzung aus, entsprechend
dem bereits vorhandenen historischen Adapter. Er löscht keine fremden Temps,
ändert keine historischen SQL-Dateien und benötigt keine neuen Rechte.
Die Gegenprobe prüft die Schließung bei Erfolg und Exception. Danach bestanden
nur die fehlenden Profile; kein einziges der vier alten grünen Profile wurde
wiederholt. Der unabhängige Nachprüfer verlangt alle 240 Profiltupel exakt
einmal und verhindert eine Aufwertung der beiden alten Gesamtfälle.

## Grenzen, Bereinigung und getrennte Restpunkte

Vor dem ersten SQL-Zugriff galten gemeinsam **28 Ziel-/Auditaufrufe,
28 eigene DB-Reservierungen und 60 Minuten**, maximal zwei geänderte
Adapterfortsetzungen. Tatsächlich verbraucht: **28 Aufrufe/Reservierungen,
26 angelegte eigene DBs entfernt und 14 frische Audits**. Frist und Zähler
blieben über beide erhaltenen Fehler, gebundene Restzulassung und endgültige
Sitzungskorrektur identisch. Alle Grenzen und ungenutzten Zulassungen sind
jetzt geschlossen; keine automatische weitere Wiederholung.

Producer und Audit sind je auf 400 Sekunden und getrennte 4-MiB-Kanäle
begrenzt; die Admission hält 15 Minuten Reserve. Jeder unabhängige frische
Audit bindet den exakten finalen Originaljournalhash, DB-Abwesenheit, tatsächliches
Ziel, alle Quellen und den vollständigen ursprünglichen Konfigurations-/Trustzustand.
Keine Rechte, Principals, Assemblies, Serveroptionen, Trusteinträge oder
Lab-Infrastruktur geändert. Credentials bleiben im Prozess; private Rohlogs,
Identitäten und reale Runtimewerte bleiben außerhalb Git.

18 öffentliche Offlinegegenproben, zwölf private Gegenproben der tatsächlichen
Teilbindungen, die disjunkte Profilauswahl, bytegleiche .NET-/Python-Texthashes
und die tatsächlichen Zulassungsprüfungen bestanden. Die gültigen
[Planner-/Executor-](TABLE-CLONE-PLANNER-EXECUTOR-QUALIFICATION.md),
[W1-/W2-](TABLE-CLONE-W1-W2-QUALIFICATION.md),
[Copy-](TABLE-CLONE-COPY-TARGET-QUALIFICATION.md),
[Trigger-](TABLE-CLONE-TRIGGER-CURRENT-QUALIFICATION.md),
[Clientreader-](TABLE-CLONE-WINDOWS-CLIENT-METADATA-QUALIFICATION.md) und
[SQLCMD-Abbruchnachweise](TABLE-CLONE-SQLCMD-CALLER-QUALIFICATION.md) werden
wiederverwendet. Historische Berichte bleiben unverändert und behalten ihren Scope.

Der hier pauschal offene genuine V1-/aktuelle Uninstall-/Repeat-/Rollback-Scope
ist damit als Profilmatrix geschlossen. Andere genuine Zwischenversionen,
weitere Kollisions-/Dependency-/Visibility-/Recoverypflichten, echte zusätzliche
Minimalrechte-/Clientidentitäten und die Modulgesamtfreigabe bleiben separat.
Teilweise validiert und unveröffentlicht. Keine Veröffentlichung oder Tags.
