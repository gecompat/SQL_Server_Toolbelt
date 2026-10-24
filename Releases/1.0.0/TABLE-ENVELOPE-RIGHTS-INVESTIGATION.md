# ResultTable-/Error-Envelope-Callerrechte: Testkorrektur, Nachprüfung offen

Stand 2026-10-24. Die zusätzliche Callerrechteprüfung ist **nicht qualifiziert**.
Die neue Testfixture enthielt einen Fehler; die korrigierte Fassung wurde
bisher nur offline syntaktisch geprüft. Produktcode, Modulversionen,
Paket-SQL-/DLL-Bytes und bestehende Modulstatus bleiben unverändert.

## Befund und Korrektur

Die erste positive Fixture scheiterte unter Linux SQL2019/CL150 local mit
SQL52096 im Schemaorakel. Sie verlangte physische `column_id`-Werte 1, 2, 3.
Der bestehende ResultTable-Helper erhält das Tabellenobjekt und ersetzt dessen
Spalten mit `ALTER TABLE ... ADD/DROP`. Dabei werden physische IDs nicht zu
logischen Positionen umnummeriert. Microsoft dokumentiert ausdrücklich,
dass Spalten-IDs nicht fortlaufend sein müssen.
[Microsoft: sys.columns](https://learn.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-columns-transact-sql).

Die Testkorrektur bestimmt die logische Position mit
`ROW_NUMBER() OVER(ORDER BY column_id)`. Identität, Spaltenanzahl, Reihenfolge,
Namen, Typen, Länge, Precision/Scale, NULLbarkeit und Collation bleiben strikte
Orakel. Es wird keine Produktionseigenschaft an einen fehlerhaften Test angepasst.

Der qualifizierte ScriptDom-Pin prüfte anschließend die äußere Fixture,
alle fünf aufgelösten Profile und verschachtelte SQL-Literale für150/160/170:
27 Parses bestanden, ohne SQL auszuführen. Dies ist kein nativer PASS.

Der nächste Baselinelauf passierte die Helperprofile und erreichte einen
weiteren fehlerhaften Testvergleich: Die Erfassung mit `INSERT ... EXEC`
führt die aufgerufene Procedure in der Systemtransaktion des Inserts aus.
Die Fixture erwartet dort jetzt strikt `XactState=1` und `TransactionCount=1`
statt des äußeren 0/0-Zustands. Die ursprünglichen fachlichen Werte bleiben
unverändert. [Primärquelle zum INSERT-EXEC-Kontext](https://www.sommarskog.se/error_handling/Part2.html#INSERTEXEC).
Auch diese Korrektur ist bis zur nächsten nativen Ausführung kein PASS.

## Tatsächliche Versuche und Cleanup

Es gab bisher vier native Versuche, jeweils unter Linux SQL2019/CL150 local:

| Versuch | Tatsächlicher Zustand | Bedeutung |
|---|---|---|
| Absichtlich falsche Breite | `FAILED_CLEANED`, SQL52096 | Kein gültiger unabhängiger Breitennachweis: Auch die unveränderte Baseline scheiterte bereits an der falschen ID-Annahme. |
| Zusätzliches fremdes Metadatenrecht | `FAILED_CLEANED`, SQL52096 | Der erwartete Rechteguard wurde vor Ausführung des Schemaorakels erreicht; historischer begrenzter Kontrollnachweis. |
| Erste Baseline | `FAILED_CLEANED`, SQL52096 | Schemaorakel fehlerhaft; kein vollständig bestandener positiver Fall. |
| Baseline mit logischen Ordinalen | `FAILED_CLEANED`, SQL52096 | Helperprofile bestanden vor dem späteren Fehler: Die direkte Envelope-Erfassung erwartete fälschlich 0/0 im INSERT-EXEC-Systemtransaktionskontext. |

Nach allen vier Versuchen bestätigten zusätzliche unabhängige Cleanup-/Pinaudits
alle zwölf eigenen Datenbanknamen als abwesend und alle 36 Trustzustände als
wiederhergestellt. Die beiden begonnenen Konfigurationsscopes wurden
wiederhergestellt und nochmals unabhängig auditiert. Andere vorbereitete
Zielscopes wurden nicht aktiviert. Originalbytes, Journale und Rohlogs bleiben
lokal; kein Fehlversuch wird als Erfolg umetikettiert.

Die [maschinenlesbare Diagnose](table-envelope-rights-investigation.json)
bindet Original-/Korrekturhashes und die unveränderten Produkt-/Harnessquellen.
Die kompakte alte Shape-Deklaration erlaubt die Rekonstruktion der tatsächlich
fehlgeschlagenen Fixture. Die beiden Änderungen betreffen nur die Shape-Deklaration und ein späteres
Transaktionswert-Literal. Alle anderen Bytes sind gleich. Der frühere Zusatzrecht-Guard ist deshalb getrennt auf seinen
unveränderten Pfad gebunden; er wird nicht als Lauf der korrigierten Baseline
bezeichnet und benötigt keinen bloßen Status-Replay.

## Vollständige Nachprüfung vor Abschluss

Erforderlich sind zwölf korrigierte Windows-/Linux-Ziel-/CL-Fälle:
SQL2019 CL150, SQL2022 CL150/160 und SQL2025 CL150/160/170, jeweils lokal und
im direkt geöffneten zentralen Datenbankkontext. Erst nach bestandener
Baseline ist der gezielt falsche Breitenfall erneut mit den strikten Orakeln
auszuführen. Eigene Cleanup-/Pin- und Konfigurationsaudits bleiben Pflicht.

Die fünf Profile betreffen eigene Temp-Referenzen, objektweise Metadatensicht
ohne Quell-SELECT, atomare Ablehnung fehlender Metadatensicht sowie direkte
und ResultTable-Ausgabe von Error Envelope. Dies umfasst kein echtes
Lowpriv-CrossDB-Loginmapping. Die bestehenden 300/360/400-Sekunden-Grenzen,
Functional-Verschlüsselung und der ausdrückliche Lab-Trustwert bleiben bestehen.

Der ursprüngliche endliche operative Laufrahmen lässt den vollständigen
Restlauf einschließlich nötiger Reserve nicht mehr zu. Deshalb erfolgt kein
weiterer nativer Versuch ohne neue begrenzte Autorität; es gibt keinen Reset.
Dieser Prüfblock und die [Releasegates](RELEASE-GATES.md) bleiben offen.

Vor Veröffentlichung sind außerdem die unterschiedlichen Statusangaben auf
der ResultTable-Objektseite (`partially validated`) und im kanonischen
Modulmanifest (`validated`) mit sauberer Produkt-/Quellenbindung abzugleichen.
Aus diesem fehlerhaften Versuch folgt keine Statusaufwertung oder -abwertung.
