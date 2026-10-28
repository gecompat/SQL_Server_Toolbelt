"""Bindet ausschließlich den dokumentierten DDL-Hilfekommentar-Übergang."""
from __future__ import annotations

import hashlib
from io import BytesIO
import json
from pathlib import Path
import zipfile


RECORD_PATH = "Releases/1.0.0/base64-ddl-help-transition.json"
BASELINE_REPORT_PATH = "Releases/1.0.0/conversion-caller-qualification.json"
BASELINE_ARCHIVE_PATH = (
    "Releases/1.0.0/Artifacts/SQL-Server-Toolbelt-1.0.0-candidate-source.zip"
)
BASELINE_PREFIX = "SQL-Server-Toolbelt-1.0.0-candidate-source/"
BASELINE_REPORT_SHA256 = "45852b68adb0815c14e014f368e3235d072ffd6951a768e8eafcba7ca589c63f"
BASELINE_ARCHIVE_SHA256 = "333a7d6ceb2a36523ea642ac1dd5a78b5fc86b8aaa25998db14c8ea035f068e6"
BASELINE_ARCHIVE_SIZE = 27274364
SOURCE_PATHS = (
    "Modules/toolbelt.conversion.base64/Source/TVF_Base64Encode.sql",
    "Modules/toolbelt.conversion.base64/Source/TVF_Base64Decode.sql",
    "Modules/toolbelt.conversion.base64/Source/SVF_Base64Encode.sql",
    "Modules/toolbelt.conversion.base64/Source/SVF_Base64Decode.sql",
)
BASELINE_SOURCE_SHA256 = {
    "Modules/toolbelt.conversion.base64/Source/TVF_Base64Encode.sql":
        "2dae80de048c0af34147d783211627ba695436187f5d36b547770c08e1f6b6eb",
    "Modules/toolbelt.conversion.base64/Source/TVF_Base64Decode.sql":
        "5464db5a1916b2626b9c0c244e91b7963649ddebdaaa80be1ec72ae6ab1dd98b",
    "Modules/toolbelt.conversion.base64/Source/SVF_Base64Encode.sql":
        "a1a984b12e01b35d03af4a37380af63dca70b856e3fb98e8a78715a42e43dafd",
    "Modules/toolbelt.conversion.base64/Source/SVF_Base64Decode.sql":
        "f5d014fe26a384c45d63a3ef67ca8df1cd0b9099c7074625f7ae72e411e3faf5",
}
CURRENT_SOURCE_SHA256 = {
    "Modules/toolbelt.conversion.base64/Source/TVF_Base64Encode.sql":
        "bea0a7a3f21a94ea747b73fcd79e9697ed0dfc87021e565adf0de773a7d7766f",
    "Modules/toolbelt.conversion.base64/Source/TVF_Base64Decode.sql":
        "13a08d4186de4536653a63bf253dbdda01f1e843004275d479bd4584e2d5f51b",
    "Modules/toolbelt.conversion.base64/Source/SVF_Base64Encode.sql":
        "8085e4077790aa4b08562122a35cfe836d5a04824b2b4e0615efe62c92deaf2b",
    "Modules/toolbelt.conversion.base64/Source/SVF_Base64Decode.sql":
        "e97eb5844ea98307151d91b942c4a3613b14cc394728a0c0cec6e8bf038bdc80",
}

def _utf8(text: str) -> bytes:
    return text.encode("utf-8")


INSERTIONS = {
    SOURCE_PATHS[0]: (
        (
            _utf8(
                "    /* DDL-Hilfe: Codiert varbinary(max) als Base64/Base64URL.\n"
                "       Parameter: @Value varbinary(max), NULL erlaubt; @UrlSafe bit = 0,\n"
                "       NULL entspricht 0. Höchstens 16777216 Eingabebytes; darüber Status LIMIT.\n"
                "       Ergebnis: genau eine Zeile (EncodedValue varchar(max), Status varchar(16));\n"
                "       Status ist SQL_NULL, LIMIT oder OK. Für den Aufruf ist SELECT erforderlich.\n"
                "       Beispiel: SELECT * FROM toolbelt_conversion.TVF_Base64EncodeStatus(0xCAFECAFE,0);\n"
                "       Erwartet: EncodedValue='yv7K/g==', Status='OK'. */\n"
            ),
            b"    IF @Value IS NULL BEGIN INSERT @Result VALUES(NULL,'SQL_NULL'); RETURN; END;\n",
            "TVF_Base64EncodeStatus",
        ),
        (
            _utf8(
                "/* DDL-Hilfe: Liefert eine Base64-Wertzeile für Binärdaten.\n"
                "   Parameter: @Value varbinary(max), NULL erlaubt; @UrlSafe bit = 0,\n"
                "   NULL entspricht 0. Höchstens 16777216 Eingabebytes; bei Überschreitung NULL.\n"
                "   Ergebnis: EncodedValue varchar(max), genau eine Zeile; bei Größen-LIMIT NULL.\n"
                "   Für den Aufruf ist SELECT erforderlich.\n"
                "   Beispiel: SELECT EncodedValue FROM toolbelt_conversion.TVF_Base64Encode(0xCAFECAFE,0);\n"
                "   Erwartet: yv7K/g==. */\n"
            ),
            b"(SELECT EncodedValue FROM toolbelt_conversion.TVF_Base64EncodeStatus(@Value,@UrlSafe));\n",
            "TVF_Base64Encode",
        ),
    ),
    SOURCE_PATHS[1]: (
        (
            _utf8(
                "    /* DDL-Hilfe: Decodiert Base64/Base64URL und meldet den festen Status.\n"
                "       Parameter: @Value varchar(max), NULL erlaubt; Space, Tab, CR und LF werden\n"
                "       ignoriert. Eingabe höchstens 25165824 Bytes, Ergebnis höchstens 16777216.\n"
                "       Ergebnis: genau eine Zeile (DecodedValue varbinary(max), Status varchar(16));\n"
                "       Status ist SQL_NULL, LIMIT, INVALID oder OK. Für den Aufruf ist SELECT erforderlich.\n"
                "       Beispiel: SELECT * FROM toolbelt_conversion.TVF_Base64DecodeStatus('yv7K_g');\n"
                "       Erwartet: DecodedValue=0xCAFECAFE, Status='OK'. */\n"
            ),
            b"    IF @Value IS NULL BEGIN INSERT @Result VALUES(NULL,'SQL_NULL'); RETURN; END;\n",
            "TVF_Base64DecodeStatus",
        ),
        (
            _utf8(
                "/* DDL-Hilfe: Decodiert eine Base64/Base64URL-Wertzeile; ungültige Eingabe\n"
                "   löst einen SQL-Engine-Konvertierungsfehler aus.\n"
                "   Parameter: @Value varchar(max), NULL erlaubt; Space, Tab, CR und LF werden\n"
                "   ignoriert. Eingabe höchstens 25165824 Bytes, decodierte Ausgabe höchstens 16777216.\n"
                "   Ergebnis: DecodedValue varbinary(max), genau eine Zeile; bei Größen-LIMIT NULL.\n"
                "   Für den Aufruf ist SELECT erforderlich.\n"
                "   Beispiel: SELECT DecodedValue FROM toolbelt_conversion.TVF_Base64Decode('yv7K_g');\n"
                "   Erwartet: 0xCAFECAFE. */\n"
            ),
            b"(SELECT DecodedValue=CASE WHEN Status='INVALID'\n",
            "TVF_Base64Decode",
        ),
    ),
    SOURCE_PATHS[2]: (
        (
            _utf8(
                "    /* DDL-Hilfe: Codiert einen einzelnen Binärwert als Base64/Base64URL.\n"
                "       Parameter: @Value varbinary(max), NULL erlaubt; @UrlSafe bit = 0,\n"
                "       NULL entspricht 0. Grenze 16777216 Eingabebytes; darüber NULL.\n"
                "       Rückgabe: varchar(max), NULL bleibt NULL; EXECUTE erforderlich.\n"
                "       Beispiel: SELECT toolbelt_conversion.SVF_Base64Encode(0xCAFECAFE, 0);\n"
                "       Erwartet: yv7K/g==. Für Mengen die TVF verwenden. */\n"
            ),
            b"    DECLARE @EncodedValue varchar(max);\n",
            "SVF_Base64Encode",
        ),
    ),
    SOURCE_PATHS[3]: (
        (
            _utf8(
                "    /* DDL-Hilfe: Decodiert einen einzelnen Base64/Base64URL-Wert.\n"
                "       Parameter: @Value varchar(max), NULL erlaubt; Space, Tab, CR und LF\n"
                "       werden ignoriert. Eingabegrenze 25165824 Bytes, Ausgabegrenze 16777216.\n"
                "       Rückgabe: varbinary(max), NULL bleibt NULL; bei Größenüberschreitung NULL;\n"
                "       ungültige Eingabe löst einen SQL-Engine-Konvertierungsfehler aus.\n"
                "       EXECUTE erforderlich.\n"
                "       Beispiel: SELECT toolbelt_conversion.SVF_Base64Decode('yv7K_g');\n"
                "       Erwartet: 0xCAFECAFE. Für Mengen die TVF verwenden. */\n"
            ),
            b"    DECLARE @DecodedValue varbinary(max);\n",
            "SVF_Base64Decode",
        ),
    ),
}


class Base64HelpTransitionError(ValueError):
    """Meldet eine Abweichung von der eng gebundenen Quellprojektion."""


def _sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _require(condition: bool, message: str) -> None:
    if not condition:
        raise Base64HelpTransitionError(message)


def _validated_archive_bytes(root: Path, archive_bytes: bytes | None = None) -> bytes:
    """Prüft Größe und festen Hash vor ZIP-Parsing; gibt denselben geprüften Snapshot zurück."""
    archive_path = root / BASELINE_ARCHIVE_PATH
    if archive_bytes is None:
        size = archive_path.stat().st_size
        _require(size == BASELINE_ARCHIVE_SIZE, "BASE64_HELP_ARCHIVE_SIZE")
        with archive_path.open("rb") as stream:
            archive_bytes = stream.read(BASELINE_ARCHIVE_SIZE + 1)
    _require(len(archive_bytes) == BASELINE_ARCHIVE_SIZE
             and _sha256(archive_bytes) == BASELINE_ARCHIVE_SHA256,
             "BASE64_HELP_BASELINE_ARCHIVE")
    sidecar = Path(str(archive_path) + ".sha256").read_text(encoding="ascii").split()
    _require(sidecar == [BASELINE_ARCHIVE_SHA256, archive_path.name],
             "BASE64_HELP_BASELINE_SIDECAR")
    return archive_bytes


def _insert_exact(source: bytes, block: bytes, anchor: bytes, label: str) -> bytes:
    _require(source.count(anchor) == 1, f"BASE64_HELP_ANCHOR:{label}")
    return source.replace(anchor, block + anchor, 1)


def _expected_current(path: str, historical: bytes) -> bytes:
    _require(path in INSERTIONS, "BASE64_HELP_PATH")
    expected = historical
    for block, anchor, label in INSERTIONS[path]:
        expected = _insert_exact(expected, block, anchor, label)
    return expected


def _expected_insertions() -> set[str]:
    return {
        f"{path}#{label}"
        for path, insertions in INSERTIONS.items()
        for _block, _anchor, label in insertions
    }


def _validate_record(record: dict) -> None:
    _require(set(record) == {
        "schema_version", "date", "scope", "publication_authorized",
        "native_requalification_claimed", "baseline_report", "baseline_archive",
        "sources", "comment_insertions",
    }, "BASE64_HELP_RECORD_KEYS")
    _require(record["schema_version"] == "toolbelt-base64-ddl-help-transition/v1"
             and record["date"] == "2026-10-28"
             and record["scope"] == "SOURCE_DELTA_ONLY"
             and record["publication_authorized"] is False
             and record["native_requalification_claimed"] is False,
             "BASE64_HELP_RECORD_SCOPE")
    _require(set(record["sources"]) == set(SOURCE_PATHS)
             and set(record["comment_insertions"]) == _expected_insertions()
             and len(record["comment_insertions"]) == len(_expected_insertions()),
             "BASE64_HELP_RECORD_PATHS")


def validate_transition(root: Path, report: dict, historical: dict[str, bytes],
                        current: dict[str, bytes], *,
                        archive_bytes: bytes | None = None) -> None:
    """Prüft die vier unveränderten Ausführungspins plus sechs Kommentar-Inserts."""
    root = Path(root).resolve(strict=True)
    record_path = root / RECORD_PATH
    record_bytes = record_path.read_bytes()
    record = json.loads(record_bytes)
    _validate_record(record)

    report_path = root / BASELINE_REPORT_PATH
    _require(record["baseline_report"] == {
        "path": BASELINE_REPORT_PATH,
        "sha256": BASELINE_REPORT_SHA256,
    } and _sha256(report_path.read_bytes()) == BASELINE_REPORT_SHA256,
             "BASE64_HELP_BASELINE_REPORT")
    report_bytes = report_path.read_bytes()
    _require(report == json.loads(report_bytes), "BASE64_HELP_REPORT_OBJECT")
    archive_path = root / BASELINE_ARCHIVE_PATH
    archive_bytes = _validated_archive_bytes(root, archive_bytes)
    _require(record["baseline_archive"] == {
        "path": BASELINE_ARCHIVE_PATH,
        "sha256": BASELINE_ARCHIVE_SHA256,
    },
             "BASE64_HELP_BASELINE_ARCHIVE")

    source_record = record["sources"]
    _require(set(source_record) == set(SOURCE_PATHS)
             and set(historical) >= set(SOURCE_PATHS)
             and set(current) >= set(SOURCE_PATHS)
             and set(report.get("source_sha256", {})) >= set(SOURCE_PATHS)
             and {p for p in report["source_sha256"]
                  if p.startswith("Modules/toolbelt.conversion.base64/Source/")} == set(SOURCE_PATHS),
             "BASE64_HELP_SOURCE_SET")
    with zipfile.ZipFile(BytesIO(archive_bytes)) as archive:
        names = archive.namelist()
        for path in SOURCE_PATHS:
            old = historical[path]
            old_sha = report["source_sha256"][path]
            _require(old_sha == BASELINE_SOURCE_SHA256[path],
                     f"BASE64_HELP_BASELINE_PIN:{path}")
            prefix_path = BASELINE_PREFIX + path
            _require(names.count(prefix_path) == 1
                     and _sha256(archive.read(prefix_path)) == old_sha
                     and _sha256(old) == old_sha,
                     f"BASE64_HELP_ARCHIVE_SOURCE:{path}")
            entry = source_record[path]
            _require(set(entry) == {"baseline_sha256", "current_sha256"}
                     and entry["baseline_sha256"] == old_sha
                     and entry["current_sha256"] == CURRENT_SOURCE_SHA256[path]
                     and _sha256(current[path]) == entry["current_sha256"]
                     and _expected_current(path, old) == current[path],
                     f"BASE64_HELP_TRANSITION:{path}")

def validate_historical_source(root: Path, path: str, executed_digest: str) -> bytes:
    """Liefert nur den exakt archivierten Vorzustand nach vollständiger Übergangsprüfung."""
    _require(path in SOURCE_PATHS and executed_digest == BASELINE_SOURCE_SHA256.get(path),
             "BASE64_HELP_HISTORICAL_PIN")
    root = Path(root).resolve(strict=True)
    report = json.loads((root / BASELINE_REPORT_PATH).read_bytes())
    archive_bytes = _validated_archive_bytes(root)
    with zipfile.ZipFile(BytesIO(archive_bytes)) as archive:
        historical = {
            source: archive.read(BASELINE_PREFIX + source)
            for source in SOURCE_PATHS
        }
    current = {source: (root / source).read_bytes() for source in SOURCE_PATHS}
    validate_transition(root, report, historical, current, archive_bytes=archive_bytes)
    return historical[path]
