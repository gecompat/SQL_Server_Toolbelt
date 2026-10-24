# ResultTable-/Error-Envelope-Callerrechte: begrenzte Qualifikation

Stand 2026-10-24. Die korrigierte Callerrechteprüfung hat zwölf physische
Windows-/Linux-Ziel-/CL-Fälle lokal und direkt zentral bestanden. Der
[aktuelle maschinenlesbare Nachweis](table-envelope-rights-qualification.json)
bindet diese Ausführung und ihre Abschlussaudits. Produktcode, Modulversionen,
Paket-SQL-/DLL-Bytes und bestehende Modulstatus bleiben unverändert.
Dies ist keine vollständige Modul- oder Releasefreigabe.

## Geprüfter Umfang und Ergebnis

Der bestehende `Tests/Release/Invoke-ApiQualificationLab.ps1` führte den
gepinnten endlichen Runset mit der Gruppe `table-envelope-rights` und
`qualificationScope=api-boundaries` aus. Pro Fall lief die Fixture
`Tests/Release/Runtime/ResultTable.ErrorEnvelope.Rights.sql` im lokalen und
im direkt geöffneten zentralen Datenbankkontext: SQL2019 CL150,
SQL2022 CL150/160 und SQL2025 CL150/160/170, jeweils auf Windows und Linux.

Die fünf Callerprofile verwenden ausschließlich eigene synthetische
Testdatenbanken, einen Benutzer ohne Login und einzelne Objektrechte:

| Profil | Geprüfter Vertrag |
|---|---|
| Helper mit eigener Temp-Referenz | EXECUTE; stabile Temp-Identität, genaue logische Spaltenmetadaten, Replace und KeepData, unveränderte Quelldaten |
| Helper mit regulärer Referenz | EXECUTE und objektweises VIEW DEFINITION; Schema sichtbar, Quell-SELECT mit SQL229 gesperrt |
| Helper ohne Referenz-Metadatensicht | EXECUTE; SQL51023, Zielidentität, Schema und Daten atomar erhalten |
| Direktes Error Envelope | EXECUTE auf CaptureErrorEnvelope; feste Werte und 14-Spalten-Zeile im INSERT-EXEC-Kontext |
| Envelope als ResultTable | EXECUTE auf CaptureErrorEnvelope und PrepareResultTable; feste Zeilen, stabile Temp-Identität und KeepData |

Alle 120 Profilszenarien bestanden: 96 positive Wertprofile und 24 erwartete
atomare Metadatenabweisungen. Dazu kamen 360 strikte SQL229-Abweisungen bei
fehlenden, unpassenden oder wieder entzogenen Rechten. Rollen-, Schema-,
datenbankweite und Servergrants wurden nicht verwendet. Ein echtes
Lowpriv-CrossDB-Loginmapping wurde nicht geprüft.

Erst nach der bestandenen korrigierten Linux2019/CL150-Baseline wurde eine
absichtlich falsche Spaltenbreite geprüft. Sie wurde mit SQL52096 verworfen
und vollständig bereinigt (`FAILED_CLEANED`); sie ist kein positiver API-Fall.
Der frühere Zusatzrecht-Guard wurde auf seinen unveränderten Ausführungspfad
gebunden und nicht bloß zur Statusauffrischung wiederholt.

Die Arbeitsgrenze von 300 Sekunden, Cleanupdeadline von 360 Sekunden und
äußere Watchdoggrenze von 400 Sekunden blieben bestehen. Functional verwendete
`Encrypt=True` und den ausdrücklichen Lab-Trustwert ohne Fallback.
Eine authentifizierte TLS-Verbindung wird damit nicht belegt.

## Historische Testfehler und ihre Korrektur

Die erste positive Fixture scheiterte unter Linux SQL2019/CL150 local mit
SQL52096 im Schemaorakel. Sie verlangte physische `column_id`-Werte 1, 2, 3.
Der bestehende ResultTable-Helper erhält das Tabellenobjekt und ersetzt dessen
Spalten mit `ALTER TABLE ... ADD/DROP`. Dabei werden physische IDs nicht zu
logischen Positionen umnummeriert. Microsoft dokumentiert, dass Spalten-IDs
nicht fortlaufend sein müssen.
[Microsoft: sys.columns](https://learn.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-columns-transact-sql).

Das korrigierte Testorakel bestimmt die logische Position mit
`ROW_NUMBER() OVER(ORDER BY column_id)`. Identität, Spaltenanzahl, Reihenfolge,
Namen, Typen, Länge, Precision/Scale, NULLbarkeit und Collation bleiben strikt.
Der qualifizierte ScriptDom-Pin prüfte die äußere Fixture, alle fünf aufgelösten
Profile und verschachtelte SQL-Literale für150/160/170: 27 Parses bestanden.
Diese Offlineprüfung war für sich kein nativer Nachweis.

Der nächste Baselinelauf passierte die Helperprofile und erreichte einen
zweiten fehlerhaften Testvergleich: Die Erfassung mit `INSERT ... EXEC`
führt die Procedure in der Systemtransaktion des Inserts aus. Die Fixture
erwartet dort jetzt exakt `XactState=1` und `TransactionCount=1` statt des
äußeren 0/0-Zustands. Die fachlichen Werte bleiben unverändert.
[Primärquelle zum INSERT-EXEC-Kontext](https://www.sommarskog.se/error_handling/Part2.html#INSERTEXEC).
Die oben beschriebene vollständige Matrix lief anschließend mit beiden
korrigierten Testannahmen; der Produktcode wurde nicht angepasst.

| Früherer Versuch, jeweils Linux SQL2019/CL150 local | Tatsächlicher Zustand und Grenze |
|---|---|
| Absichtlich falsche Breite | `FAILED_CLEANED`, SQL52096; kein unabhängiger Breitennachweis, da auch die damalige Baseline an der falschen ID-Annahme scheiterte |
| Zusätzliches fremdes Metadatenrecht | `FAILED_CLEANED`, SQL52096; erwarteter Rechteguard vor Ausführung des Schemaorakels, begrenzter historischer Kontrollnachweis |
| Erste Baseline | `FAILED_CLEANED`, SQL52096; Schemaorakel fehlerhaft, kein vollständig bestandener positiver Fall |
| Baseline mit logischen Ordinalen | `FAILED_CLEANED`, SQL52096; Helperprofile vor späterem falschen 0/0-Vergleich bestanden, kein vollständig bestandener positiver Fall |

Die [historische Diagnose](table-envelope-rights-investigation.json) bewahrt
diese vier tatsächlichen Fehlversuche und den damaligen Stand vor der
korrigierten Nachprüfung. Original-/Zwischen-/Korrekturhashes und die alte
Shape-Deklaration erlauben die Rekonstruktion der fehlgeschlagenen Fixture.
Nur die Shape-Deklaration und ein späteres Transaktionswert-Literal änderten
sich. Der frühere Zusatzrecht-Guard liegt vor Ausführung beider geänderten
SQL-Fragmente; seine begrenzte Anwendbarkeit ist getrennt gebunden. Er wird
nicht als Lauf der korrigierten Fixture bezeichnet.

## Abschlussaudits und verbleibende Grenzen

Dreizehn frische unabhängige Cleanup-/Pinaudits bestätigten die zwölf aktuellen
positiven Fälle und die neue Breitenkontrolle. Vier zusätzliche Reaudits
prüften die alten Eingabebytes und deren Cleanup getrennt. Insgesamt sind alle
51 eigenen Datenbanknamen abwesend und alle 177 geprüften Trustzustände
wiederhergestellt. Alle sechs aktivierten Konfigurationsscopes der korrigierten
Matrix wurden wiederhergestellt und nochmals unabhängig auditiert; die beiden
früher begonnenen Scopes waren bereits jeweils separat wiederhergestellt.
Originalbytes, Journale und Rohlogs bleiben lokal. Fehlversuche bleiben Fehler.

Die [Releasegates](RELEASE-GATES.md#was-vor-veröffentlichung-offen-bleibt)
führen die übrigen Modul-, Identitäts-, Ressourcen-, Recovery- und Clientfälle.
Vor Veröffentlichung sind außerdem die unterschiedlichen Statusangaben auf
der ResultTable-Objektseite (`partially validated`) und im kanonischen
Modulmanifest (`validated`) mit sauberer Produkt-/Quellenbindung abzugleichen.
Diese separate Dokumentationspflege liegt beim Modulverantwortlichen und wird
vor Veröffentlichung fällig. Dieser Rechtebeleg ändert keinen Modulstatus.
