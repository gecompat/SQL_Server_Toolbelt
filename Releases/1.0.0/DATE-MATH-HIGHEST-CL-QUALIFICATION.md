# Date-Math-Callerprofile: sechs ausgewählte höchste CL

Aktueller Nachfolger: [vollständige additive CL-Ergänzung](DATE-MATH-CL-COMPLETION.md). Der folgende Text beschreibt den unveränderten früheren Teilstand.

Stand 2026-10-25, vierte vorab geplante Welle des dritten endlichen Rahmens.
**Ausgewählter Scope bestanden; keine volle CL-Matrixqualifikation.** Vier
öffentliche DateBucket-/CalendarDifference-TVFs bestehen mit je einem SELECT
auf sechs physischen Versions-/Plattformkombinationen lokal/direkt zentral.
Sechs niedrigere CL-Kombinationen bleiben ausdrücklich `not executed`.
Produkt-SQL, Manifeste, Modulstatus und Pakete bleiben unverändert, unveröffentlicht.

## Bewusst begrenzte Matrix

| Plattform | Neu geprüft | Weiter offen für diese Callerfixture |
|---|---|---|
| Linux | SQL2019/CL150,SQL2022/CL160,SQL2025/CL170 | SQL2022/CL150,SQL2025/CL150/160 |
| Windows | SQL2019/CL150,SQL2022/CL160,SQL2025/CL170 | SQL2022/CL150,SQL2025/CL150/160 |

Diese zusätzliche Welle wurde nach Abschlussplanung der drei vollständigen
Callerwellen eigenständig mit genau diesem Teilscope festgelegt. Deren zwölf
Fälle und Kontrollpflichten bleiben vollständig erhalten. Aus den sechs neuen
Fällen wird weder ein Lauf der übrigen CLs noch eine allgemeine Gleichwertigkeit
abgeleitet. Die offene Ergänzung verlangt eigene tatsächlich ausgeführte Fälle;
vorhandene Kontrollen/Nachweise dürfen nur bei belegbar passender Bindung
wiederverwendet werden. Der stündliche Heartbeat startet nach Rahmenabschluss
keine fünfte Entwicklungswelle.

## Einzelrechte und tatsächliche Orakel

Die Closure besteht aus ResultTable1.0.0,DateBucket1.0.0 und CalendarDifference1.0.0.
Die feste `DateMath.FunctionCases.sql` nutzt den unveränderten
[gemeinsamen Rechteablauf](../../Tests/Release/README.md#native-funktions-callerrechte-prüfen).

| API mit je einem SELECT | Ausgewähltes Orakel |
|---|---|
| TVF_DateBucketDate | typisierter Monatsbucket mit explizitem Ursprung;NULL-/ungültige Breitenflags |
| TVF_DateBucketDateTime2 | Zweistundenbucket ab festem Tagesursprung;NULL-/Breitenflags |
| TVF_DateBucketDateTimeOffset | Zweistundenbucket mit erhaltenem Offset;NULL-/Breitenflags |
| TVF_CalendarDifference | genaue Jahre/Monate/Tage,Vorzeichenumkehr,NULL und geklammerter Schalttags-Jahrestag |

TVFs müssen jeweils exakt eine Zeile mit den erwarteten Werten/Flags liefern.
Der eigene Benutzer ohne Login erhält nur das einzelne Objektrecht. Fehlendes,
entzogenes,die drei anderen öffentlichen APIs,der interne DateBucketCore und
der ResultTable-Helper müssen genau SQL229 liefern. Breite Rollen-,Schema-
und datenbankweite Rechte entfallen; interne Ownershipketten brauchen keine
direkten Core-/Helpergrants. REFERENCES/DDL,gebrochene Ownershipketten und echte
CrossDB-Identitätsmappings sind hier nicht qualifiziert.

## Ergebnisse und Bereinigung

Sechs positive Fälle mit zwei Kontexten ergeben48 Einzelgrantprofile und336
strikte SQL229-Abweisungen. Ein falscher Bucket-Festwert und zusätzliches
direktes Core-Recht wurden aus den erwarteten Gründen verworfen; beide bleiben
FAILED_CLEANED. Alle acht aktuellen Versuche bestanden unabhängige Input-/
Abwesenheitsaudits. Frische Audits nach dem letzten Verbraucher bestätigen
alle14 eigenen Datenbanknamen als abwesend. Eigene Principals/Fixturezustände
sind entfernt;keine Serverkonfigurations-,Login-,CLR-/Trust- oder fremden Änderungen.

Die [JSON-Projektion](date-math-highest-cl-qualification.json) verwendet ausdrücklich
`PASS_SELECTED_SCOPE` und `full_target_cl_matrix_qualified=false`. Sie nennt
sechs bestandene und sechs nicht ausgeführte Fälle getrennt,alle tatsächlichen
Source-/Treiber-/Exportbytes,die Komposition und Fallzahlen. Ein eigener
Regressionstest hält diese Trennung fest;die bisherigen zwölfteiligen
Callerberichtstests bleiben unverändert streng.

## Verbleibende Gates

Zuerst sind die sechs genannten niedrigeren CL-Callerfälle zu ergänzen. Frühere
volle Fach-/Client-/Lifecycle-/Ressourcennachweise behalten ihre jeweilige
Bindung und werden hier nicht pauschal wiederholt oder erweitert. Echte
Lowpriv-CrossDB-Mappings,authentifiziertes TLS und die übrigen
[Releasegates](RELEASE-GATES.md) bleiben separat. Functional verwendet
Verschlüsselung und den expliziten schema-validen Lab-Trustwert ohne Fallback.
Keine Veröffentlichung und keine Statusaufwertung;private Journale bleiben lokal.
