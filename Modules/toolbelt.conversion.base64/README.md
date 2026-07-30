# Base64 and Base64URL Conversion

**Modul-ID:** `toolbelt.conversion.base64`

**Version:** `1.1.0`

**Implementierung:** `implemented`

**Validierung:** `partially validated`

**Release:** `unreleased`

## Zweck

Das Modul schließt auf SQL Server 2019 und 2022 die erst mit SQL Server 2025
nativ verfügbare Base64-Lücke. Es bietet eine portable T-SQL/XML-
Implementierung mit derselben öffentlichen Oberfläche auf allen drei
unterstützten Hauptversionen.

## Öffentliche Objekte

| Objekt | Typ | Schema | Zweck |
|---|---|---|---|
| `TVF_Base64Encode` | inline TVF | `toolbelt_conversion` | kanonischer relationaler Encode-Kern |
| `TVF_Base64Decode` | inline TVF | `toolbelt_conversion` | kanonischer relationaler Decode-Kern |
| `SVF_Base64Encode` | `SVF` | `toolbelt_conversion` | `varbinary(max)` als Base64 oder Base64URL codieren |
| `SVF_Base64Decode` | `SVF` | `toolbelt_conversion` | Base64 oder Base64URL als `varbinary(max)` decodieren |

## Vertrag

- `NULL` ergibt `NULL`.
- Standard-Base64 enthält kanonisches Padding.
- Base64URL verwendet `-` und `_` und enthält kein Padding.
- Decode akzeptiert beide RFC-4648-Alphabete sowie fehlendes Padding.
- Decode ignoriert ausschließlich Space, Tab, CR und LF.
- Zeichenketten werden nicht implizit in Binärdaten umgewandelt.
- Ungültige Eingaben liefern unverändert den Fehler des T-SQL/XML-Providers.
- Base64 ist eine Codierung, keine Verschlüsselung und kein Integritätsschutz.

Der optionale UDF-Parameter `@UrlSafe` besitzt den Default `0`. T-SQL verlangt
bei Scalar UDFs dennoch ein Argument; für den Defaultpfad kann `DEFAULT`
übergeben werden.

## Abhängigkeiten

Das Modul hat keine Abhängigkeit zu anderen Toolbelt-Modulen. Die
scopebezogene Qualitätsregel erlaubt deshalb die Implementierung unabhängig
vom noch teilweise validierten ResultTable-Modul. Eigene Source-, Lifecycle-,
Contract- und Dokumentationsprüfungen bleiben vollständig verpflichtend.

## Deployment

Aus `Deployment/` im SQLCMD-Modus:

```sql
:setvar DeploymentMode local
:r .\Deploy.sql
```

`DeploymentMode` unterstützt `local` und `central`. Bei zentraler Installation
werden die Funktionen mit dreiteiligem Namen aufgerufen; Synonyme sind nicht
erforderlich.

## Performance und Größen

Der XML-Provider verarbeitet Werte synchron. Für mengenorientierte Aufrufe
sind die inline TVFs über `CROSS APPLY` oder `OUTER APPLY` zu bevorzugen; die
SVFs bleiben Convenience-APIs und versprechen kein Scalar-UDF-Inlining. Die
`max`-Typen definieren die SQL-Schnittstelle, nicht eine
unbegrenzte praktische Größen- oder Performancegarantie. Set-basierte
Massenaufrufe und große LOBs sind vor produktivem Einsatz mit repräsentativen,
nicht vertraulichen Daten zu messen.

## Plattform- und Teststatus

Der portable Provider enthält keine bekannte Betriebssystemabhängigkeit.
Der
[Base64-Runtime-Lauf 30493304673](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30493304673)
war auf SQL Server 2025 unter Linux mit Compatibility Levels 150, 160 und 170
erfolgreich. Geprüft wurden RFC-4648-/Base64URL-Vektoren, Fehlerfälle,
synthetische Größen bis 1 MiB, Wiederholungsdeployment, Fremdobjekt-Kollision,
lokale und zentrale Nutzung sowie Uninstall. Physische
SQL-Server-2019-/2022- und Windows-Läufe bleiben bis zur gezielten
Releasevalidierung `not executed`; der Modulstatus ist deshalb nur
`partially validated`.

## Dokumentation

- [Moduldesign](../../Documentation/Architecture/BASE64_MODULE_DESIGN.md)
- [TVF_Base64Encode](./Documentation/TVF_Base64Encode.md)
- [TVF_Base64Decode](./Documentation/TVF_Base64Decode.md)
- [SVF_Base64Encode](./Documentation/SVF_Base64Encode.md)
- [SVF_Base64Decode](./Documentation/SVF_Base64Decode.md)
- [Contract-Testmatrix](./Tests/BASE64_CONTRACT_TEST_MATRIX.md)
- [Test-Evidenz](./Tests/README.md)
