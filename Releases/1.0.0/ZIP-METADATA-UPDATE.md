# ZIP-Callerrechte: Manifest- und Paketbindung

Die ZIP-Callerqualifikation belegt für Listen und Extraktion jeweils das öffentliche `EXECUTE` zusammen mit `SELECT` auf der passenden internen TVF. Der caller-lokale `@ResultTable`-Pfad benötigt zusätzlich `EXECUTE` auf `toolbelt_core.USP_PrepareResultTable`. Der Writer benötigt sein öffentliches `EXECUTE`, `SELECT` auf beide internen Writer-TVFs und Helper-`EXECUTE` für beide Ausgaberouten.

Das Modulmanifest übernimmt ausschließlich diese vorhandenen Objektprofile. Die Änderung ergänzt weder Rechte noch Rollen und ändert keine SQL-, CLR- oder DLL-Bytes. Der ZIP-Bericht bleibt unverändert und behält seine ursprünglichen nativen Source- und Package-Pins; [zip-metadata-update.json](zip-metadata-update.json) bindet den alten Pin an den öffentlichen Vorgängerstand, das e89-Produktarchiv und den aktuellen Metadatenstand.

Die CLR-Paketprojektion wird über das bereits geprüfte XLSX-Paket zusammengesetzt. SQL-/DLL-Payloads bleiben bytegleich. Der Modulauslieferungsstatus bleibt `partially validated`, der Release bleibt `unreleased`, und Veröffentlichung ist nicht autorisiert.
