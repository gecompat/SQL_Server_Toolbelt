# Aktueller Abgleich: geschlossene Teilumfänge und echte Restqualifikation

Stand 2026-11-16. Diese Übersicht ordnet spätere Nachweise vor älteren
Offen-Formulierungen ein. Sie ersetzt keine Originalausführung, erweitert
keine Freigabe und ist kein Gesamtfreigaberecord. Die [45-Modul-Übersicht](../../Tests/README.md#modulspezifische-testmatrizen)
und jeweilige Modulmatrix bestimmen die tatsächlich zugesagten Pflichten.
Lokale nicht integrierte Vertragsentwürfe sind keine Implementierungsfreigabe.

## Geschlossene Teilumfänge nicht erneut testen

| Alte pauschale Offen-Angabe | Späterer maßgeblicher Nachweis |
|---|---|
| XLSX: reale Archiv-/Part-/Summen-/Partanzahl-Grenzen und aktuelles Paket fehlen | [192 native Grenzaufrufe auf 24 Routen, zwölf frische Audits und fokussiertes Paket](XLSX-NATIVE-PACKAGE-QUALIFICATION.md). Blattanzahl und SST haben ihre eigenen unveränderten Nachweise. Keine Heapmessung daraus ableiten. |
| XLSX: die benannten übrigen Typ-/Anzeige-Fixtures fehlen | [74 neue vollständige Fixture-Ausführungen, elf frische Audits](XLSX-CELL-API-REST-QUALIFICATION.md); nur die dort ausdrücklich benannten disjunkten Ziel-/Modusprofile. |
| XLSX: die benannten übrigen Typ-/Anzeige-Clientmetadaten fehlen | [37 neue Originalhelfer-Ausführungen mit 95 Readerfällen und elf frischen Fallaudits](XLSX-CELL-CLIENT-REST-QUALIFICATION.md). Der ursprüngliche Callback-Fehler und sein eigener Audit bleiben erhalten; Katalognullability und andere Client-/Consumerprofile bleiben separat. |
| XLSX: genuine 1.0 auf heutigen 1.2-Build fehlt | [24 aktuelle Upgrade-Routen, 48 Metadatenhelfer und 13 frische Audits](XLSX-GENUINE10-REST-QUALIFICATION.md). Originale 1.0-Sources und zwei unabhängige bytegleiche Builds; keine Versionmarkerfälschung. Genuine 1.1 und andere Fehler-/Consumerprofile bleiben getrennt. |
| XLSX: genuine 1.1 auf heutigen 1.2-Build fehlt | [24 aktuelle Upgrade-Routen, 48 Metadatenhelfer und zwölf frische Audits](XLSX-GENUINE11-REST-QUALIFICATION.md). Originale 1.1-Sources und zwei unabhängige bytegleiche Builds; ausgeführte CRLF-Testquellen zusätzlich exakt erhalten. Übrige Consumer-/Lifecycle-/Ownerprofile bleiben getrennt. |
| XLSX: direkte Zell-/Raw-Callerrechte sind pauschal ungetestet | [Zellrechte](XLSX-CELL-CALLER-QUALIFICATION.md), [Raw-Rechte](XLSX-RAW-CALLER-PROFILE.md) und [Metadatenpflege](XLSX-METADATA-UPDATE.md). Andere Owner und echte gemappte CrossDB-Identitäten bleiben getrennt. |
| Aggregate: vier große Entrygrenzen und Linux SQL2025/CL170 blockiert | [Aktuelle Timeoutkorrektur: 96 native Profile auf 24 Kontexten](JSON-AGGREGATE-NATIVE-TIMEOUT-FIX-QUALIFICATION.md). Alte fehlgeschlagene Koordinatoren bleiben fehlgeschlagen. Keine vollständige neue ZIP-Matrix daraus ableiten. |
| Table Clone: W1/W2, Planner-/Executor-Grundrechte, SQLCMD-Abbruch und bekannte Vorgänger fehlen allgemein | [W1/W2](TABLE-CLONE-W1-W2-QUALIFICATION.md), [Planner](TABLE-CLONE-PLANNER-RIGHTS-QUALIFICATION.md), [Executor-Grundprofil](TABLE-CLONE-EXECUTOR-RIGHTS-QUALIFICATION.md), [SQLCMD](TABLE-CLONE-SQLCMD-CALLER-QUALIFICATION.md), [V1](TABLE-CLONE-GENUINE-V1-LIFECYCLE-QUALIFICATION.md) und [fünf bekannte Zwischenversionen](TABLE-CLONE-KNOWN-PREDECESSORS-QUALIFICATION.md). Erweiterte Rechte und andere Fehlerstellen bleiben getrennt. |
| SSIS: frische aktuelle ZIP-/SSMS-Abnahme fehlt allgemein | [Aktueller ZIP-/SSMS-Gesamtfall](SSIS-CURRENT-ZIP-SSMS-QUALIFICATION.md) mit getrennt gebundenen strikten TLS-/Sicherheitsnachweisen. SQL-Anmeldung bei TLS wird nicht zu kombinierter Windows-/TLS-Identität. |
| Regex: Capture-Gate, physische R2b-Ziele und große Capture-Ausgabe pauschal offen | [Datierter aktueller Abgleich](RELEASE-GATES.md#regex-aktueller-nachweisabgleich-vom-2026-11-06). Die [originale 16-MiB-Capture-Ausgabegrenze](REGEX-CAPTURE-BOUNDARY-STATUS.md) ist auf allen 24 Routen einschließlich großem Opt-in belegt. Die ausdrücklich angenommene Restrisikogrenze bleibt erhalten; keine erfundene Ursachenklärung oder Timeoutgarantie. |

## Noch eigenständig zu qualifizieren

- **XLSX:** übrige Vorgänger-/Consumer-/Lifecycle-, Kollisions-/Owner-/
  Visibility- und übrige Client-/Consumerprofile; Heap-/Parallelitätsmessungen nur für
  tatsächlich zugesagte Aussagen. Keine erneute pauschale Vollgrößenmatrix.
- **JSON:** übrige direkte CLR-/Assembly-ACL-/Owner-, echte Netzwerk-/CrossDB-,
  Linux-Clienthost-, Ressourcen-/Parallelitäts-/Recoveryfälle. Die aktuelle
  Aggregatekorrektur hat keinen vollständigen neuen Paketmatrixnachweis erzeugt.
- **Table Clone:** erweiterte Copy-/Trigger-/Executor-Rechte einschließlich
  FK-/ResultTable-Kontexten, unbelegte Consumer-/Namespace-/Sicherheitsfälle,
  zusätzliche Recoverystellen und Linux-Clienthost.
- **Regex und weitere Datenpfadmodule:** konkret zugesagte, noch unbelegte
  CrossDB-Identitäten, Ressourcen-/Parallelitäts-/Recoveryfälle; bereits belegte
  große SQL-Capture-Ausgabe nicht wiederholen; optionale Durchsatzmessung separat.
- **Datei-/ZIP-Module:** Windows-Caller-/NTFS-ACL-/I/O-Profile, File-Content-
  Schema-/Owner-/ACLdrift und aktive Mutationsabbrüche sowie noch deklarierte
  ZIP-Ziel-/Lifecycle-/Identitätsprofile. Bereits belegte Grenzfälle bleiben zu.
- **Work Queue/Worker:** zugesagter vollständiger Providerlauf und noch
  unbelegte Provider-/Identitäts-/Host-/Transportprofile. SQL-Managed- und
  Terminalhistorienbelege werden nicht als FullProduct ausgegeben.

Vor jeder neuen Welle den einzelnen Restfall aus der kanonischen Matrix mit
Source-/Fixture-/Rechtebindung und einem endlichen gemeinsamen Rahmen auswählen.
Ein Kategoriename allein ordnet keine beliebigen Experimente an. Neue Rechte,
Infrastrukturänderungen und neue Fachfunktionen behalten ihre konkreten Gates;
geschlossene alte Laufbudgets werden nicht erneuert. Fehlende Voraussetzungen
blockieren nur den betroffenen Fall, nicht unabhängig ausführbare Restarbeit.
Nicht veröffentlichen oder taggen.
