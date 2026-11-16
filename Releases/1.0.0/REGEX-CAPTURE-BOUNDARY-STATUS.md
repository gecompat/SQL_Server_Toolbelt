# Regex: große Capture-Ausgabe ist bereits nativ belegt

Stand 2026-11-16: Die alte pauschale Aussage „16-MiB-Capture-Outputgrenze in SQL
noch nicht ausgeführt“ ist überholt. Dies ist ein Abgleich vorhandener
Originalnachweise, kein neuer SQL-Lauf und keine neue Produktkorrektur.

Die unveränderte [native Regex-Matrix](regex-timeout-qualification.json)
weist `Captures.Metadata.ps1` auf allen zwölf Windows-/Linux-Engine-/CL-Paaren
als bestanden aus, jeweils lokal und direkt zentral: SQL2019 CL150,
SQL2022 CL150/160 und SQL2025 CL150/160/170. Die Fixturedefinition enthält
ausdrücklich `large=true`; der tatsächlich ausgeführte Treiber im originalen
Quellbundle übergibt `IncludeLargeBoundary=true`. Alle 24 Metadatenrouten und
ihre unabhängigen Cleanup-/Pin-Audits sind im Originalrecord belegt. Der dortige
`PARTIAL`-Fall betrifft ausschließlich eine andere lokale Capture-Vertragsfixture;
er wird weder umgeschrieben noch als Größenfehler akzeptiert.

## Tatsächliches Grenzorakel

Eine benannte Capture, nicht Zeilenexplosion oder Capture-History:
`GroupName` enthält 128 UTF-16-Codeeinheiten, `Value` im großen positiven Fall
8.388.480. Zusammen sind das genau 16.777.216 Bytes. Der Originalreader verlangt
den exakten Gruppennamen, die vollständige Value-Länge und Matchlänge, genau
eine Zeile und kein weiteres Resultset. Eine zusätzliche UTF-16-Codeeinheit
überschreitet die Grenze um **zwei Bytes**; erwartet wird der tatsächliche
Fehler `TBX_REGEX_OUTPUT_TOO_LARGE` ohne erste verwertbare Zeile.
Der Standardfall mit 2 MiB ist im selben Originalhelfer getrennt enthalten.
Diese Aussagen sind keine neuen Durchsatz-, Peak-Heap- oder Schedulingzusagen.

## Quellen- und Artefaktbindung

Die reine [Integritätsprüfung](../../Scripts/Release/regex_capture_boundary_status.py)
prüft Originalmatrix, großes Opt-in, beide Kontexte je Ziel und ursprüngliche
Auditflags. Sie verwendet den vorhandenen lokalen Bundle-Rekonstruktor, um
die damals ausgeführten Methoden-/Fixturebytes zu prüfen; kein Remote und kein SQL.
Die gelieferte Regex-DLL wird exakt gegen die [angenommene Abnahme](capture-release-acceptance.json)
geprüft. Aktuelle Capture-CLR-/Projektquellen werden separat verglichen.
Der einzige SQL-Dateiunterschied ist der bereits separat gebundene
EXECUTE-Rechtekommentar der anderen Scalarfunktion; die präzise vorhandene
[Quellenäquivalenz](runtime-source-equivalence.json) bleibt unverändert.
Es gibt keine neue allgemeine Hash- oder Kommentar-Ausnahme.

```text
python Scripts/Release/regex_capture_boundary_status.py
```

Die Prüfung meldet 24 vorhandene Routen, null neue native Aufrufe und die
aktuelle Quellenanwendbarkeit getrennt. Alte FAIL/PARTIAL bleiben erhalten;
die angenommene Restrisikogrenze ist keine Ursachenklärung oder Garantie
timeoutfreier Ausführung. Echte Lowpriv-CrossDB-Identitäten, andere konkrete
Ressourcen-/Parallelitäts-/Recoveryfälle und die weiterhin nicht ausgeführte
SQL-100k-Durchsatzmessung bleiben getrennt. Keine Gesamtmodulaufwertung,
Veröffentlichung oder Tags. Kein grüner SQL-Test wurde wiederholt.
