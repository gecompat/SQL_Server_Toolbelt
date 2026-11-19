# Release- und Installationssatz v1.0.0-rc.3

Dieses Verzeichnis enthält die gebundene neue Lieferung. Einstieg sind die
[Kurzanleitung](../../RC3-INSTALL.md) und die [Releasehinweise](../../RC3.md).
Die ZIPs und Prüfsummen werden unverändert auch als
[GitHub-Release-Assets](https://github.com/gecompat/SQL_Server_Toolbelt/releases/tag/v1.0.0-rc.3)
bereitgestellt. Ihre genaue Quellbindung steht in `BUILD-RECEIPT.json`.

| Datei | Zweck |
|---|---|
| `SQL-Server-Toolbelt-v1.0.0-rc.3-Install.zip` und `.sha256` | Ein-Aufruf-Installer mit vollständiger lokaler SQL-Basis und Anleitung. |
| `SQL-Server-Toolbelt-v1.0.0-rc.3-source.zip` und `.sha256` | Exakter Quellkandidat einschließlich Installerquellen und Dokumentation. |
| `START-HERE.md` | Kurzanleitung als einzelnes Release-Asset. |
| `BUILD-RECEIPT.json` | Build-/Nachweisbindungen und Umfang der Offline-Wiederverwendung. |
| `SHA256SUMS.txt` | Prüfsummen der sechs übrigen Lieferdateien. |

Nach dem Entpacken des Installationssatzes die enthaltene `START-HERE.md`
verwenden. Die Basis-ZIP im Unterverzeichnis nicht zusätzlich entpacken.
Die fertigen ZIPs bleiben in Git, sind aus späteren Quell-Exports jedoch
ausgeschlossen. Downloadlinks zu Assets stehen in den Releasehinweisen.
