# ANSI-Korrektur und getrennte Sicherheitsabnahme

Der aktuelle Entwicklungsquellsatz ergänzt Copy Column um eine Prüfung gegen
die kataloggeprüfte Codepage der aufgelösten Quell-Lineage. Übereinstimmende,
gemeinsam falsche Codepages an XML-Ein- und -Ausgang werden gesperrt. Numerische
und Unicode-Kopien sowie die öffentliche API bleiben unverändert.

Die vorherigen Copy-Column-ZIPs, Records und nativen Ergebnisse bleiben
unverändert. Die [Qualifikationsübersicht](RELEASE-GATES.md#qualifikationsabgleich-nach-copy-column-v1)
prüft sie ausdrücklich an ihrem historischen C7-Quellstand. Sie gelten nicht
als vollständige Abnahme des korrigierten Builds.

## Tatsächlicher Stand

- Der korrigierte CLR-Kandidat wurde reproduzierbar gebaut. Alle 29 begrenzten
  Offline-Frameworkfälle und die gezielten ANSI-Gegenproben für Paketformat 6
  und 8 mit Codepage 1252 und 65001 bestehen.
- Ein erster nativer ANSI-Gesamtlauf endet `FAILED_CLEANED`: Die abschließende
  Zählererwartung des Testadapters berücksichtigte die Assertions des gemeinsamen
  DebugScript-Prüfers nicht. Der separate frische Abschlussaudit ist `PASS`.
  Dieser Gesamtfall bleibt fehlgeschlagen; daraus wird kein Matrix-PASS abgeleitet.
- Die Korrektur zählt vollständig beendete Profile getrennt vom gemeinsamen
  Assertionzähler. Sechs SQL-freie Gegenproben prüfen diese Trennung.
- Die separat freigegebene korrigierte Matrix besteht auf Windows SQL2019/CU32
  CL150 und SQL2025/CU8 CL170, jeweils lokal und zentral: 16 Profile mit
  372 Assertions und vier frischen Abschlussaudits.
  [Quellgebundener Record](../../Modules/toolbelt.tsql.ssis-debug/Tests/Qualification/CopyColumn.SecurityCorrection.20261115.json).
  Der vierte Auditdispatch wurde vor SQL durch einen vorzeitigen Edit einer
  gebundenen Offline-Testdatei gesperrt. Nach exakter Wiederherstellung bestand
  der separat freigegebene frische Audit. Der Dispatchfehler bleibt erhalten.
- Die unabhängige Sicherheitsprüfung akzeptiert die korrigierten Produktquellen,
  die begrenzte TLS-Methode und die gezielte Lab-Kontextauswahl quellseitig:
  [getrennter Reviewrecord](../../Modules/toolbelt.tsql.ssis-debug/Tests/Qualification/Security.CopyColumn.20261115.json).
  Sie ist kein nativer TLS- oder Modul-Gesamtnachweis.
- Der [frische strikte TLS-Gesamtfall](../../Modules/toolbelt.tsql.ssis-debug/Tests/Qualification/Tls.CopyColumn.SecurityCorrection.20261115.json)
  besteht mit dem korrigierten Provider auf Windows SQL2025 RTM, CL170,
  lokal/zentral: 416 Assertions, frischer SQL-Audit und unabhängiger Lab-Audit.
  Der öffentliche Neuaufbau verwendet beide strikten Clientstacks, einen
  signierten V2-Export und dieselben frisch geprüften Bytes vor jedem Open.
  SQL-Anmeldung, `Encrypt=True`, `TrustServerCertificate=False`; keine
  Umdeutung in einen kombinierten Windows-/TLS-Anmeldeweg oder beobachteten
  Wire-Fingerprint.
- Die erste Kontextrevision am bestehenden Register bleibt vor Commit gesperrt.
  Die Registry verlangt frische Bindungen aller aktiven Authorities, auch
  unveränderter Datensätze. Der separat genehmigte isolierte Root verwendet
  ausschließlich eine eigene neue CA/Authority. Eine eigene VM und vier
  Testdatenbanken wurden entfernt, SQL-Konfiguration und Hosttrust
  wiederhergestellt, der eigene verschlüsselte CA-Schlüssel entfernt.
  Fremde Bindungen blieben unverändert; der geschlossene Root bleibt nur
  als privater Originalnachweis erhalten.
- Die zusätzliche isolierte Sicherheitsprüfung fand zwei Setup-/Cleanupfehler.
  Plan-/Bindingbindung und Ende der eigenen Receiverinstanz vor Trustcleanup
  sind korrigiert und unabhängig quellseitig akzeptiert. Dreißig gezielte
  SQL-freie Gegenproben bestehen. Beide ursprünglichen Findings und die
  vorangehenden Fehler bleiben erhalten.

Die [Copy-Column-Anleitung](../../Modules/toolbelt.tsql.ssis-debug/Documentation/CopyColumnV1.md)
erklärt das Verhalten. Die Testadapter
`Invoke-CopyColumnAnsiLab.ps1` und `Invoke-CopyColumnAnsiCases.ps1` prüfen nur
die geänderte ANSI-Grenze auf eigenen Testdatenbanken. Sie vergeben keine
Rechte und verwalten keine Lab-Infrastruktur. Veröffentlichung und Tags sind
nicht autorisiert; der Modulstatus bleibt teilweise validiert.
