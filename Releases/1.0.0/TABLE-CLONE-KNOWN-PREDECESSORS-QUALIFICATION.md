# Table Clone 4.1.1: direkte bekannte Vorgänger

Vorbereiteter Nachweisvertrag vom 2026-11-07; native Matrix **not executed**.
Die 13 Offlinegegenproben des
[Treibers](../../Tests/Release/Invoke-TableCloneKnownPredecessorsLab.ps1)
bestehen. Dieser Zwischenstand behauptet keinen nativen PASS.

Geprüft werden die echten öffentlichen Versionen 2.0.0, 3.0.0, 3.1.0,
4.0.0 und 4.1.0: aktuelle Deinstallation des Originals, später
Upgradefehler mit vollständigem Rollback und direktes Upgrade auf 4.1.1.
Die Originale bestehen aus 29 unveränderten öffentlichen Git-Blobs mit
Version, Provenienz und bekannten Signaturen. Der Treiber bindet deren
exakte Bytes sowie die vollständig expandierten aktuellen Lifecycle-Texte.
Originalinstallation und Bereinigung zwischen Versionen sind Testaufbau.

Vorgesehen sind zwölf Windows-/Linux-Engine-/Compatibility-Level-Paare,
jeweils lokal und direkt zentral: SQL 2019 CL150, SQL 2022 CL150/160 und
SQL 2025 CL150/160/170. Windows-Ziele verwenden CU32/CU26/CU8, Linux
den explizit ausgewählten bereiten latest-Stand. Windows ist der Clienthost;
die vorhandene administrative SQL-Anmeldung dient ausschließlich funktionalen
Tests mit Verschlüsselung und unverändertem explizitem Trustwert.

Der gemeinsame Rahmen umfasst höchstens 28 Lauf-/Auditaufrufe, 28 eigene
Datenbankreservierungen und 60 Minuten. Ein frischer unabhängiger Audit
prüft nach jedem Lauf dessen finales Journal, Datenbankentfernung und
unveränderte Serverkonfiguration/Trust. Keine Wiederholung bestandener Profile,
keine neuen Rechte, Identitäten, CLR-, Server- oder Infrastrukturänderungen.
Bereits gültige V1-, Funktions-, Client- und Rechtebelege bleiben getrennt.
Keine Modulgesamtfreigabe, Veröffentlichung oder Tags.
