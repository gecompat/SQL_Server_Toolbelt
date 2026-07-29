# Moduldesign Base64 und Base64URL

## Status und Freigabe

| Feld | Wert |
|---|---|
| Kandidat | `TC-2026-012` |
| Modul | `toolbelt.conversion.base64` |
| Version | `1.0.0` |
| Vertrag besprochen | 2026-07-29 |
| Implementierung freigegeben | 2026-07-29 durch ausdrückliches `.` des Benutzers |
| Provider | T-SQL/XML |

## Zweck und Grenze

Das Modul stellt eine versionsübergreifend identische Base64-Oberfläche für
SQL Server 2019, 2022 und 2025 bereit. Es codiert ausschließlich Binärdaten und
decodiert ausschließlich Base64-Text. String-Encoding, Datei-I/O,
Verschlüsselung, Integritätsprüfung und automatische Inhaltsausführung liegen
außerhalb des Scopes.

## Öffentlicher Vertrag

```text
SVF_Base64Encode(@Value varbinary(max), @UrlSafe bit = 0) -> varchar(max)
SVF_Base64Decode(@Value varchar(max))                     -> varbinary(max)
```

- `NULL` bleibt `NULL`.
- Standard-Base64 wird mit Padding erzeugt.
- Base64URL wird mit `-` und `_` und ohne Padding erzeugt.
- Decode akzeptiert beide Alphabete, optionales Padding und Space, Tab, CR und
  LF.
- Es gibt keine implizite Konvertierung von `varchar` oder `nvarchar` in Bytes.
- Ungültige Eingaben erzeugen unverändert den Provider-/Enginefehler.

## Providerentscheidung

Die erste Version verwendet die XML-Funktion `xs:base64Binary`. Sie ist auf
allen Zielversionen verfügbar und benötigt weder CLR noch externe
Abhängigkeiten. Decode kanonisiert Base64URL zu Standard-Base64, entfernt
ausschließlich die vier freigegebenen Whitespace-Zeichen und ergänzt fehlendes
Padding. Ein Rest von eins sowie sonstige Formatfehler werden nicht maskiert.

SQL CLR bleibt eine mögliche spätere Provideralternative, wird aber erst bei
einem reproduzierbaren Performancevorteil und nach eigener Security-,
Deployment- und Plattformentscheidung aufgenommen.

## Fehlervertrag

Scalar UDFs unterstützen kein geeignetes `TRY...CATCH`/`THROW`-Mapping für
stabile Toolbelt-Fehler. Die native SQL-Server-2025-Fehlernummer `9803` wird
nicht imitiert. Der T-SQL/XML-Provider lehnt ungültige Eingaben mit seinem
unveränderten Enginefehler ab.

## Abhängigkeit und Phase-2-Gate

Das Modul hängt weder fachlich noch technisch von
`toolbelt.core.result-table` ab. Das frühere pauschale Phase-2-Gate wird daher
durch ein scopebezogenes Qualitäts-Gate ersetzt:

1. Vertrag, Alternativen, Risiken und Scope der konkreten Funktion wurden
   besprochen.
2. Die funktionsbezogene Implementierungsfreigabe liegt vor.
3. Das Modul besitzt eigene vollständige Source-, Dokumentations-, Manifest-,
   Lifecycle-, statische und Runtime-Contract-Artefakte.
4. Statuswerte spiegeln ausschließlich tatsächlich ausgeführte Evidenz.
5. Gemeinsame Infrastruktur darf nur verwendet werden, wenn deren benötigter
   Vertrag ausreichend validiert ist.

Diese Regel senkt keine Qualitätsanforderung; sie verhindert lediglich eine
fachlich unbegründete Kopplung unabhängiger Module.

## Größen- und Performancegrenze

Die `max`-Typen sind der Datentypvertrag. Der synchrone XML-Provider
materialisiert Ein- und Ausgabe und kann erheblichen Speicher- und CPU-Aufwand
verursachen. Ein erfolgreicher Grenzwerttest ist kein allgemeiner
Produktionsbenchmark. Große LOBs und set-basierte Massenaufrufe benötigen eine
eigene Messung mit repräsentativen synthetischen oder freigegebenen Daten.

## Primärquellen

- [BASE64_ENCODE (Transact-SQL)](https://learn.microsoft.com/en-us/sql/t-sql/functions/base64-encode-transact-sql?view=sql-server-ver17)
- [BASE64_DECODE (Transact-SQL)](https://learn.microsoft.com/en-us/sql/t-sql/functions/base64-decode-transact-sql?view=sql-server-ver17)
- [value() method (xml data type)](https://learn.microsoft.com/en-us/sql/t-sql/xml/value-method-xml-data-type?view=sql-server-ver17)
- [RFC 4648: Base-N Encodings](https://www.rfc-editor.org/rfc/rfc4648)
