# Table Clone 4.1.1: aktuelle W1-/W2-Zielmatrix

Am 2026-11-07 bestanden sieben unveränderte W1-/W2-Fixtures auf zwölf
Engine-/CL-Paaren jeweils lokal und direkt zentral: **24 Kontexte und
168 vollständige Fixture-Ausführungen**. Zwölf Gesamtfälle bestanden nach
einer gezielten Adapterkorrektur; der erste native Gesamtfehler bleibt
`FAILED_CLEANED`. Insgesamt bestanden **13 frische unabhängige Audits**.
Alle **25 tatsächlich angelegten eigenen Datenbanken** sind entfernt.
Ergebnis: **PASS_FOR_DECLARED_CURRENT_W1_W2_SCOPE**.

| Ausgewähltes SQL-Ziel | Compatibility Levels | Modi | Kontexte |
|---|---|---|---:|
| Windows 2019/CU32 | 150 | lokal/direkt zentral | 2 |
| Windows 2022/CU26 | 150, 160 | lokal/direkt zentral | 4 |
| Windows 2025/CU8 | 150, 160, 170 | lokal/direkt zentral | 6 |
| Linux 2019/latest | 150 | lokal/direkt zentral | 2 |
| Linux 2022/latest | 150, 160 | lokal/direkt zentral | 4 |
| Linux 2025/latest | 150, 160, 170 | lokal/direkt zentral | 6 |

Windows-Clienthost, vorhandene administrative Lab-Anmeldung. Direkt zentral
bezeichnet SameDB-Nutzung; keine neue Netzwerk-/CrossDB-Identität.

## Tatsächlich ausgeführte Originalfixtures

Der [enge Treiber](../../Tests/Release/Invoke-TableCloneWavesLab.ps1) führt
pro Kontext diese sieben Originale vollständig und in dieser Reihenfolge aus:

1. [Wave1.Contract.sql](../../Modules/toolbelt.metadata.table-clone/Tests/Runtime/Wave1.Contract.sql)
2. [Wave1.DateTimeOffset.sql](../../Modules/toolbelt.metadata.table-clone/Tests/Runtime/Wave1.DateTimeOffset.sql)
3. [Wave1.Bytes.sql](../../Modules/toolbelt.metadata.table-clone/Tests/Runtime/Wave1.Bytes.sql)
4. [Wave1.PermissionPredicate.sql](../../Modules/toolbelt.metadata.table-clone/Tests/Runtime/Wave1.PermissionPredicate.sql)
5. [Wave2.Contract.sql](../../Modules/toolbelt.metadata.table-clone/Tests/Runtime/Wave2.Contract.sql)
6. [Wave2.Safety.sql](../../Modules/toolbelt.metadata.table-clone/Tests/Runtime/Wave2.Safety.sql)
7. [Wave2.Caps.sql](../../Modules/toolbelt.metadata.table-clone/Tests/Runtime/Wave2.Caps.sql)

Die vorhandenen Orakel umfassen insbesondere die synthetischen Datentyp-/
DateTimeOffset-, Byte-, Map-, Mehrtabellen- und Safetyfälle sowie die in den
Fixtures explizit beschriebenen Quotenfälle mit 200 Properties, Map64/65,
1024 Spalten und der globalen Objektmenge. Es werden ausschließlich die
tatsächlich enthaltenen API-Grenzaufrufe qualifiziert; serverseitig verhinderte
1025te Spalten oder andere fehlende öffentliche Branches werden nicht erfunden.
168 zählt vollständige Fixture-Ausführungen, keine Zahl einzelner Assertions.

Die Predicate-Fixture ersetzt vorübergehend das Berechtigungsprädikat der
eigenen installierten internen Prozedur durch feste Gegenwerte und prüft die
exakte Wiederherstellung ihrer Definition und Eigenschaften. Das bleibt eine
Predicate-Gegenprobe unter Admin und ist **kein tatsächlicher Lowpriv-Caller**.
Nach jeder Fixture verlangt der Adapter einen neutralen Transaktionszustand;
vor und nach jedem Kontext müssen die Produktdefinitionen identisch sein.

ResultTable 1.0.0 und Table Clone 4.1.1 bilden die gesamte Exportclosure.
Version-/Modusmarker, tatsächliches CL und das Fehlen von Benutzerassemblies
werden nativ geprüft. Tatsächliche Ziel-Major-/Plattform-/Softwareversionen
bleiben privat und werden im frischen Audit erneut gebunden. Vollständige
Konfigurations-/Trustsnapshots und sämtliche gepinnten Inputs bleiben erhalten.

## Erhaltener Erstfehler und geänderte Adaptereingabe

Der erste Methodensnapshot
[`38b75745`](https://github.com/gecompat/SQL_Server_Toolbelt/commit/38b7574504c1321906c5160e66625ea5aa2bac62)
stoppte auf Windows 2019/CL150 lokal in der Predicate-Fixture: Der zuvor
verwendete gemeinsame Batchtrenner ließ mit `\s*` nach `GO` Zeilenumbrüche zu
und nahm dadurch die erste Kommentarzeile der folgenden Prozedurdefinition
als Kommentar des Trenners weg. Die strikte Originalfixture wies diesen
unbekannten Definitionspräfix korrekt ab.

Der Gesamtfall bleibt `FAILED_CLEANED` mit null vollständig bestandenen Modi.
Sein eigener frischer Audit bestätigt DB-Abwesenheit, unveränderten Server-
zustand, Pins und den finalen Originaljournalhash; `originalRunPassed=false`.
Teilweise vorher durchlaufene Fixtures dieses Versuchs werden nicht zusätzlich
in die 168 erfolgreichen Fixture-Ausführungen eingerechnet.

Der korrigierte Methodensnapshot
[`4ae53e8a`](https://github.com/gecompat/SQL_Server_Toolbelt/commit/4ae53e8a2ac6786b0d214b14b1315b9a246c9c81)
verwendet einen eigenen engen Trenner, der nur horizontale Leerzeichen vor
und nach `GO` zulässt. Vollständige Folgekommentare und Definitionspräfixe
bleiben dadurch erhalten. Produktquellen, Originalfixtures und gemeinsamer
Batchhelfer wurden nicht geändert. Die tatsächlichen bereitgestellten
SQL-Batchrahmen und installierten Definitionshashes bilden geänderte Inputs;
die gezielte Korrektur verwendet eigene neue Journale/Datenbanken.

Die Gegenprobe reproduziert den Verlust mit beiden echten ursprünglichen
Exporten und erhält deren vollständigen kanonischen Präfix mit dem neuen
Trenner. LF-/CRLF-, Inlinekommentar- und Direktiventests bestehen. Ein zusätzlicher
Fehler des Offline-Testschreibers erzeugte unter Windows zunächst doppelte CR;
die Gegenproben schreiben seitdem die tatsächlich beabsichtigten Bytes.
Auch diese ursprünglichen Offlinefehler bleiben privat erhalten.

## Unveränderte gemeinsame Frist und Steuerungsreparatur

Vor erster Zulassung galten **28 Ziel-/Auditaufrufe, 28 DB-Reservierungen und
90 Minuten**, einschließlich höchstens zwei gezielter geänderter Adapterfälle.
Der größere Zeitrahmen berücksichtigt die sieben begrenzten Quotenfixtures.
Jeder Producer/Audit bleibt auf 400 Sekunden, getrennte 4-MiB-Kanäle und eigene
Prozessbereinigung begrenzt; vor nächster Zulassung bleiben 15 Minuten Reserve.

Die erste korrigierte Zulassung dispatchte zunächst kein SQL: Die lokale
Steuerung wandelte beim JSON-Lesen die ISO-Frist automatisch in `DateTime` um
und interpretierte deren anschließende Textkonvertierung kulturabhängig als
abgelaufen. Der tatsächliche UTC-Zeitpunkt lag weiterhin innerhalb der
ursprünglichen 90 Minuten. Die Diagnose und unveränderte UTC-Prüfung unter
`de-AT` und `en-US` reproduzieren beziehungsweise beheben genau diesen Fehler.

Eine eng geprüfte einmalige Reparatur setzte dieselbe bereits zugelassene
Korrektur vor deren erstem SQL-Dispatch fort. Sie verlangte den erhaltenen
Erstfehler samt Hashaudit, fehlendes neues Falljournal, weiterhin gültige
Originalfrist und unveränderte Zähler. Originalbudget und noch unbenutztes
Runset wurden vor der Reparatur zusätzlich unverändert gesichert und gehasht.
Beginn und Ende blieben dieselben UTC-Zeitpunkte; nur die ursprüngliche
ISO-Textdarstellung wurde wiederverwendet. Kein Zeit- oder Zählerreset.

Der unabhängige Nachprüfer bestätigt **26 Aufrufe, 26 DB-Reservierungen,
25 entfernte tatsächliche Datenbanken, eine korrigierte native Fallzulassung,
einen erhaltenen nativen Fehlversuch und 13 frische Audits**. Er bindet alle
Originaljournale, privaten Quellkapseln und beide gesicherten Steuerungsinputs
sowie die unveränderte 90-Minuten-Frist. Alle Restplätze sind geschlossen.

## Wiederverwendung und getrennte Grenzen

Der frühere [CI-Lauf 41110006735](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/41110006735)
mit drei erfolgreichen Linux-Jobs und drei bestätigten Containerbereinigungen
bleibt erhalten. Produkt-, Fixture-, ResultTable-, Workflow- und Treiberquellen
sind gegenüber seinem Stand unverändert. Seine damaligen Images und lokalen
CL-Schleifen sowie die zentralen/defaulten Pfade werden ausschließlich als
Originalscope geführt, nicht als heutige physische Labziele oder neuer CU-Beleg.
Die neue physische Matrix oben hat ihre eigenen Zielbindungen und Audits.

Die getrennte [Vier-Fixture-Matrix](TABLE-CLONE-PLANNER-EXECUTOR-QUALIFICATION.md)
und die [Copy-Zielnachweise](TABLE-CLONE-COPY-TARGET-QUALIFICATION.md) werden
wiederverwendet und wurden nicht erneut ausgeführt. Dreizehn verbindungslose
[Admission-/Scope-/Batchgegenproben](../../Tests/Release/test_table_clone_waves_contract.py)
und Parser150 für alle sieben Originalfixtures ergänzen die Native-Ergebnisse.

Keine Rechte oder Benutzer, CLR-/Trusteinträge, Serveroptionen oder
Lab-Infrastruktur wurden verändert. Eigene temporäre Datenbanken bilden den
Änderungsscope. Rohlogs, Endpoints, reale Laufzeitwerte und private Identitäten
bleiben außerhalb Git. Trigger mit Parser, echte weitere Minimalrechte,
Netzwerk-/CrossDB-/zusätzliche Clientprofile, genuine Upgrade-/Uninstall- und
umfassende Recovery-/Modulabnahme bleiben getrennt. Functional-Verschlüsselung
mit explizitem Labtrust ist keine authentifizierte TLS-Abnahme. Produkt-SQL,
Manifest, Paket und teilweise validierter/unveröffentlichter Status bleiben
unverändert. Keine Veröffentlichung oder Tags.
