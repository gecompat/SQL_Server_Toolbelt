# ZIP: Callerrechte für Listing, Extraktion und Writer

Stand 2026-10-26: Der begrenzte Rechte- und Ausgabewegumfang der drei bereits
freigegebenen öffentlichen ZIP-Memory-USPs 1.4.0 ist geprüft. Die Ergebnisse
gelten für die geprüften lokalen und direkt zentralen Aufrufkontexte. Der
Modulstatus bleibt `partially validated`, der Release `unreleased`; eine
Veröffentlichung oder Tags sind nicht freigegeben.

## Getestete Objektprofile

| API | Direkte Ausgabe | Zusätzliche Rechte für den ResultTable-Aufruf |
|---|---|---|
| `toolbelt_archive.USP_ListZipEntriesFromBinary` | `EXECUTE` auf die USP und `SELECT` auf `toolbelt_archive.TVF_InternalListZipEntriesClr` | `EXECUTE` auf `toolbelt_core.USP_PrepareResultTable` |
| `toolbelt_archive.USP_ExtractZipEntryFromBinary` | `EXECUTE` auf die USP und `SELECT` auf `toolbelt_archive.TVF_InternalExtractZipEntryClr` | `EXECUTE` auf `toolbelt_core.USP_PrepareResultTable` |
| `toolbelt_archive.USP_CreateZipFromEntries` | `EXECUTE` auf die USP, `SELECT` auf `toolbelt_archive.TVF_InternalZipWriterName` und `toolbelt_archive.TVF_InternalZipWriterArchive` sowie `EXECUTE` auf `toolbelt_core.USP_PrepareResultTable` | Im Writerprofil bereits für beide Ausgabewege erforderlich |

Dies sind die eng begrenzten Objektprofile, die in dieser Qualifikation
bestanden. Sie beweisen weder mathematische Minimalität noch, dass keine
anderen Rechteprofile möglich sind. Fehlendes öffentliches `EXECUTE` wird mit
SQL 229 abgewiesen. Bei sichtbarem öffentlichem Objekt, aber fehlender
Abhängigkeit, wurden die quellbelegten Fehler 51329 (Listing/Extraktion) und
51357 (Writer) erwartet. Die ResultTable-Aufrufe wurden getrennt gegen die
Helperrechte geprüft.

## Fixture, Matrix und Ergebnisse

Der Leser erhält ein unabhängig erzeugtes Stored-ZIP mit genau einem
synthetischen Entry `hello.txt`, fünf Bytes `Hello`, CRC32 `F7D18982` und
DOS-Zeit `2020-02-03 04:05:06`. Das Writer-Orakel ist ein eigenständiges festes
121-Byte-ZIP mit demselben Namen, Payload, CRC und Stored-Verfahren, aber
Writerzeit `1980-01-01 00:00:00`. Die Reader- und Writer-Goldens werden nicht
voneinander abgeleitet. Direkte Ausgabe und caller-lokale ResultTable werden
mit denselben festen typisierten Werten verglichen.

Die zwölf ausgewählten Ziel-/Kompatibilitätskombinationen liefen lokal und
direkt zentral, insgesamt 24 Kontexte. Drei APIs mit sechs Rechtezuständen und
beiden Ausgabewegen ergeben 432 Maskenzustände und 864 Routen. Davon waren
192 Routen positiv, 384 wurden mit dem erwarteten Dependencyfehler abgewiesen
und 288 mit SQL 229. Zusätzlich wurden 105 Gegen-API-, interne Provider- und
Helperproben je Kontext strikt mit SQL 229 abgewiesen: weitere 2.520 Proben.
Damit enthält die Matrix 2.808 strikte SQL-229-Abweisungen und 192 feste
Ergebniszeilenorakel.

Zwölf Matrixfälle bestanden. Zwei frische Kontrollen wurden an ihren
vorgesehenen Stellen als `FAILED_CLEANED` abgewiesen: ein absichtlich falsches
festes Writer-Golden mit `ZIP writer fixed 121-byte golden mismatch.` und ein
zusätzliches Schema-SELECT mit `Broad caller role or schema/database
permission detected.` Beide unabhängigen Audits bestanden.

Der erste Pilot mit der ursprünglichen v1-Fixture bleibt als
`FAILED_CLEANED` erhalten. Seine Shapeprüfung verwendete physische
`tempdb.sys.columns.column_id`-Werte als logische Ordinale. Der vorhandene
ResultTable-Helper fügt eine Anchor-Spalte ein und entfernt sie wieder; dadurch
können physische IDs Lücken enthalten. Die korrigierte v2-Fixture nummeriert
die tatsächlichen Spalten logisch nach ihrer physischen Reihenfolge. Goldenwerte
und Produktquellen wurden nicht geändert. Der ursprüngliche v1-Runset- und
Journalinhalt blieb erhalten; das abschließende Audit verwendete eine separate
Projektion mit genau einem remappten Quellpfad und bytegleichem archiviertem
v1-SQL.

Insgesamt gab es 15 native Zielversuche: zwölf bestandene v2-Matrixfälle, zwei
erwartet abgewiesene Kontrollen und den erhaltenen v1-Fixturefehler. Nach allen
Verbrauchern bestanden 15 getrennte abschließende AuditOnly-Läufe. Die
tatsächlichen Journale zeigen 27 von 27 eigenen Datenbanken entfernt und
anschließend abwesend sowie 15 entfernte eigene Trusteinträge; die
Konfiguration wurde wiederhergestellt. Das ist eine Zählung der tatsächlich
journalisierten Ereignisse, keine Zahl eindeutiger Trusthashes.

## Grenzen und Wiederholung

Geprüft wurden nur diese drei öffentlichen APIs und die in der
[maschinenlesbaren Evidenz](zip-caller-profile.json) aufgeführten internen
Abhängigkeiten und Gegenproben. Daraus folgt keine Aussage über alle
ZIP-Endpunkte, fremde Calleridentitäten, authentifiziertes TLS, den gesamten
Modulvertrag oder die Releasefreigabe. Die SQL-/CLR-Produktbytes, das Manifest
und das Releasepaket blieben unverändert; es wurden keine neuen Builds
erstellt. Head- und Main-CI werden getrennt im integrierenden PR nachgewiesen.

Die offline integrierte Composer- und Profilprüfung läuft in der bestehenden
Release-Suite. Es wurden keine neuen CI-Jobs angelegt. Private Zielauswahlen,
Runsets, Journaldetails, Trusthashes, Endpoints und Roh-Ausgaben bleiben lokal.
