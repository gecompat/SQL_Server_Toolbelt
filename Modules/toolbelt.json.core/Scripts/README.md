# JSON-Binaryinputs und historische Nachweiswerkzeuge

`New-JsonClosureRelease.ps1` erzeugt aktuelle DLL-/Buildmanifest-Eingaben aus
bereits qualifizierten passenden Bytes. Die SQL-Installation erfolgt danach
über [Build-Install](../../../Deployment/README.md); der Binarypackager
liefert keine Deploy-/Uninstall-Templates.

`New-KnownJsonClosure.ps1` und `Expand-JsonClosureSql.ps1` bleiben Originalwerkzeuge
für die historischen Known-Artifact-/SQLCMD-Nachweise. Ihre ursprünglichen
Quellen und Lifecycle-Dateien stehen im
[festen Vorgänger](https://github.com/gecompat/SQL_Server_Toolbelt/tree/2fbe8e3e86f370b22ad2ce9f9716d971072a052b/Modules/toolbelt.json.core).
Sie sind kein aktueller Installationsweg und schreiben keine neue aktuelle
Qualifikation. Die dokumentierten Originalpins werden nicht auf den neuen
markerfreien Deploymentvertrag umgebogen.
