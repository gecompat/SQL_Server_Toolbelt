# Gemeinsamen Installer verwenden

Dieses Modul deklariert seinen Installationsbuilder im Manifest. Source-Dateien
und deklarierte Objekte werden in den gemeinsamen markerfreien Kern aufgenommen.
Keine eigene Deploy-/Uninstall-Implementierung, keine Extended Properties und
kein SQLCMD-Template anlegen. Fehlende Objekte ergänzen, bestehende nicht ersetzen.

Die ursprünglichen Lifecyclevorlagen bleiben im
[historischen Quellstand](https://github.com/gecompat/SQL_Server_Toolbelt/tree/2fbe8e3e86f370b22ad2ce9f9716d971072a052b/Templates/Module/Deployment)
erhalten. Neue Fachobjekte benötigen weiterhin ihre ausdrückliche Implementierungsfreigabe.
