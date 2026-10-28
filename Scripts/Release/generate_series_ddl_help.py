"""Bindet ausschließlich die drei Kommentarergänzungen an historische Series-Quellen."""
from __future__ import annotations

from io import BytesIO
import hashlib
import json
from pathlib import Path, PurePosixPath
import stat
import zipfile


RECORD_PATH = "Releases/1.0.0/generate-series-ddl-help-transition.json"
RECORD_SHA256 = "13856a65a1c8bb8d16f789de7914f12c45c52eb3a7f79b1fdd3057cf90ebbbe8"
ARCHIVE_PATH = "Releases/1.0.0/Artifacts/SQL-Server-Toolbelt-1.0.0-candidate-source.zip"
ARCHIVE_PREFIX = "SQL-Server-Toolbelt-1.0.0-candidate-source/"
ARCHIVE_SHA256 = "333a7d6ceb2a36523ea642ac1dd5a78b5fc86b8aaa25998db14c8ea035f068e6"
ARCHIVE_SIZE = 27274364
SOURCE_PATHS = (
    "Modules/toolbelt.core.generate-series/Source/TVF_GenerateSeriesBigInt.sql",
    "Modules/toolbelt.core.generate-series/Source/TVF_GenerateSeriesInt.sql",
)
BASELINE_SOURCE_SHA256 = {
    SOURCE_PATHS[0]: "99d9090c2cd50edc23b8137bfa3d9ef863c1bf4fa5e1ebd952c1da1722770dd1",
    SOURCE_PATHS[1]: "44d8723199f44a22e58e43a3fa4c2e6002420fa03c58210ed16a0bf1ff9d1a3d",
}
BASELINE_REPORTS = {
    "Releases/1.0.0/conversion-caller-qualification.json":
        "45852b68adb0815c14e014f368e3235d072ffd6951a768e8eafcba7ca589c63f",
    "Releases/1.0.0/series-date-caller-qualification.json":
        "d1e8104ba569beec8ef11713e48b2a6735d2533184e1390f1095d06188a64974",
    "Releases/1.0.0/utility-caller-qualification.json":
        "e2c0c840b41c6961db810db0c21e2ecf104be2e732366f9cbf5986e2d492577b",
}
CURRENT_SOURCE_SHA256 = {
    SOURCE_PATHS[0]: "1a95881ccabd5fab68dccb9b2615c4ff4afacd01df8f7a76d5a6c58b51115797",
    SOURCE_PATHS[1]: "2f0e261820fd215c2080b883b71187c611b51c348b22ac7794fd0801eafe66ff",
}
INSERTIONS = {
    SOURCE_PATHS[0]: (
        (
            "    /*\n"
            "     * DDL-Hilfe: Erzeugt eine portable bigint-Reihe ohne internes Zeilenlimit.\n"
            "     * Parameter: @Start bigint NULL, @Stop bigint NULL, @Step bigint NULL\n"
            "     * (Default NULL). NULL oder DEFAULT für @Step wählt +1 bei Start <= Stop,\n"
            "     * sonst -1. Der Start ist enthalten; Stop nur, wenn die Schrittfolge ihn\n"
            "     * erreicht. Eine falsche Schrittrichtung oder NULL bei Start/Stop ergibt\n"
            "     * keine Zeile. Schritt 0 bleibt der\n"
            "     * unveränderte Enginefehler, auch wenn eine Grenze NULL ist. Eine\n"
            "     * Zeilenzahl außerhalb bigint löst Engine-Overflow statt Kürzung aus.\n"
            "     * Ergebnis: Value bigint; keine Reihenfolge ohne ORDER BY. Für SELECT-\n"
            "     * Aufrufe ist SELECT auf der Funktion erforderlich.\n"
            "     * Beispiel: SELECT Value FROM toolbelt_core.TVF_GenerateSeriesBigInt\n"
            "     * (CONVERT(bigint,10),CONVERT(bigint,1),CONVERT(bigint,-4)) ORDER BY Value DESC;\n"
            "     * Erwartete Werte: 10, 6, 2.\n"
            "     */\n",
            "    /*\n     * Die binäre Stapelung stellt 2^64 logische Quellzeilen bereit. TOP\n",
            "TVF_GenerateSeriesBigInt",
        ),
        (
            "    /*\n"
            "     * DDL-Hilfe: Liefert Werte oder eine begrenzte Statuszeile für nicht\n"
            "     * vertrauenswürdige\n"
            "     * Aufrufe. Parameter: @Start bigint NULL, @Stop bigint NULL,\n"
            "     * @Step bigint NULL (Default NULL; Richtung automatisch). NULL bei Start\n"
            "     * oder Stop hat Vorrang und ergibt (NULL,SQL_NULL,NULL). Schritt 0 ergibt\n"
            "     * (NULL,INVALID,NULL); falsche Richtung ergibt (NULL,EMPTY,0). Mehr als\n"
            "     * 1000000 angeforderte Werte ergibt (NULL,LIMIT,exakte RequestedRows).\n"
            "     * Gültige Werte ergeben je eine Zeile mit Status=OK und der Gesamtzahl.\n"
            "     * Ergebnis: Value bigint NULL, Status varchar(16),\n"
            "     * RequestedRows decimal(38,0) NULL; keine Reihenfolge ohne ORDER BY.\n"
            "     * Für SELECT-Aufrufe ist SELECT auf der Funktion erforderlich.\n"
            "     * Beispiel: SELECT Value,Status,RequestedRows\n"
            "     * FROM toolbelt_core.TVF_GenerateSeriesBigIntStatus(1,5,2)\n"
            "     * ORDER BY Value;\n"
            "     * Erwartet: (1,OK,3), (3,OK,3), (5,OK,3).\n"
            "     */\n",
            "    IF @Start IS NULL OR @Stop IS NULL\n",
            "TVF_GenerateSeriesBigIntStatus",
        ),
    ),
    SOURCE_PATHS[1]: (
        (
            "    /*\n"
            "     * DDL-Hilfe: Erzeugt eine typstabile int-Reihe ohne internes Zeilenlimit.\n"
            "     * Parameter: @Start int NULL, @Stop int NULL, @Step int NULL\n"
            "     * (Default NULL). NULL oder DEFAULT für @Step wählt +1 bei Start <= Stop,\n"
            "     * sonst -1. Der Start ist enthalten; Stop nur, wenn die Schrittfolge ihn\n"
            "     * erreicht. Eine falsche Schrittrichtung oder NULL bei Start/Stop ergibt\n"
            "     * keine Zeile. Schritt 0 bleibt der\n"
            "     * unveränderte Enginefehler, auch wenn eine Grenze NULL ist. Sehr große\n"
            "     * gültige Reihen werden nicht gekürzt und können erhebliche Ressourcen\n"
            "     * beanspruchen. Ergebnis: Value int; keine Reihenfolge ohne ORDER BY.\n"
            "     * Für SELECT-Aufrufe ist SELECT auf der Funktion erforderlich.\n"
            "     * Beispiel: SELECT Value FROM toolbelt_core.TVF_GenerateSeriesInt(2,10,3)\n"
            "     * ORDER BY Value;\n"
            "     * Erwartete Werte: 2, 5, 8.\n"
            "     */\n",
            "    /*\n     * Die gesamte Reihenlogik liegt im bigint-Kern.",
            "TVF_GenerateSeriesInt",
        ),
    ),
}
RECORD_KEYS = {
    "schema_version", "date", "status", "native_requalification_claimed",
    "current_head_ci_required", "publication_authorized", "scope",
    "archive", "baseline_reports_sha256", "sources", "comment_insertions",
}


class SeriesHelpTransitionError(ValueError):
    """Meldet eine Abweichung von der eng gebundenen Quellprojektion."""


def _sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _require(condition: bool, message: str) -> None:
    if not condition:
        raise SeriesHelpTransitionError(message)


def source_paths(root: Path) -> tuple[str, ...]:
    """Liefert nur die zwei exakt freigegebenen Quellpfade."""
    return SOURCE_PATHS


def _record(root: Path) -> dict:
    record_path = root / RECORD_PATH
    record_bytes = record_path.read_bytes()
    _require(_sha256(record_bytes) == RECORD_SHA256, "SERIES_HELP_RECORD_HASH")
    record = json.loads(record_bytes.decode("utf-8"))
    _require(isinstance(record, dict) and set(record) == RECORD_KEYS,
             "SERIES_HELP_RECORD_FIELDS")
    _require(record["schema_version"] == "toolbelt-generate-series-ddl-help/v1"
             and record["date"] == "2026-10-28"
             and record["status"] == "SOURCE_DELTA_ONLY"
             and record["native_requalification_claimed"] is False
             and record["current_head_ci_required"] is True
             and record["publication_authorized"] is False
             and record["scope"] == "Three existing Generate Series DDL help comment insertions only",
             "SERIES_HELP_RECORD_SCOPE")
    _require(record["archive"] == {"path": ARCHIVE_PATH, "sha256": ARCHIVE_SHA256,
                                   "size_bytes": ARCHIVE_SIZE}
             and record["baseline_reports_sha256"] == BASELINE_REPORTS,
             "SERIES_HELP_RECORD_BASELINE")
    expected_insertions = {
        f"{path}#{label}"
        for path, insertions in INSERTIONS.items()
        for _block, _anchor, label in insertions
    }
    _require(record["comment_insertions"] == sorted(expected_insertions),
             "SERIES_HELP_RECORD_INSERTIONS")
    sources = record["sources"]
    _require(isinstance(sources, dict) and set(sources) == set(SOURCE_PATHS),
             "SERIES_HELP_RECORD_PATHS")
    for path in SOURCE_PATHS:
        entry = sources[path]
        _require(isinstance(entry, dict) and set(entry) == {"baseline_sha256", "current_sha256"}
                 and entry["baseline_sha256"] == BASELINE_SOURCE_SHA256[path]
                 and entry["current_sha256"] == CURRENT_SOURCE_SHA256[path],
                 "SERIES_HELP_RECORD_SOURCE")
    return record


def _validated_archive_bytes(root: Path, archive_bytes: bytes | None = None) -> bytes:
    archive_path = root / ARCHIVE_PATH
    _require(archive_path.is_file() and not archive_path.is_symlink(),
             "SERIES_HELP_ARCHIVE_FILE")
    _require(archive_path.stat().st_size == ARCHIVE_SIZE, "SERIES_HELP_ARCHIVE_SIZE")
    if archive_bytes is None:
        with archive_path.open("rb") as stream:
            archive_bytes = stream.read(ARCHIVE_SIZE + 1)
    _require(len(archive_bytes) == ARCHIVE_SIZE and _sha256(archive_bytes) == ARCHIVE_SHA256,
             "SERIES_HELP_ARCHIVE_HASH")
    sidecar_path = Path(str(archive_path) + ".sha256")
    sidecar = sidecar_path.read_text(encoding="ascii").split()
    _require(sidecar == [ARCHIVE_SHA256, archive_path.name], "SERIES_HELP_ARCHIVE_SIDECAR")
    return archive_bytes


def _expected_current(path: str, old: bytes) -> bytes:
    _require(path in INSERTIONS, "SERIES_HELP_PATH")
    expected = old
    for block_text, anchor_text, label in INSERTIONS[path]:
        block = block_text.encode("utf-8")
        anchor = anchor_text.encode("utf-8")
        _require(expected.count(anchor) == 1, f"SERIES_HELP_ANCHOR:{label}")
        expected = expected.replace(anchor, block + anchor, 1)
    return expected


def validate_transition(root: Path, historical: dict[str, bytes], current: dict[str, bytes],
                        *, archive_bytes: bytes | None = None) -> None:
    """Prüft Archiv, drei historische Reports und ausschließlich drei DDL-Kommentarblöcke."""
    root = Path(root).resolve(strict=True)
    _record(root)
    _require(set(historical) == set(SOURCE_PATHS) and set(current) == set(SOURCE_PATHS),
             "SERIES_HELP_SOURCE_SET")
    archive_bytes = _validated_archive_bytes(root, archive_bytes)
    for report_path, expected_hash in BASELINE_REPORTS.items():
        report_bytes = (root / report_path).read_bytes()
        _require(_sha256(report_bytes) == expected_hash, "SERIES_HELP_REPORT_HASH")
        report = json.loads(report_bytes.decode("utf-8"))
        pins = report.get("source_sha256")
        module_pins = {path: pins.get(path) for path in SOURCE_PATHS} if isinstance(pins, dict) else None
        _require(module_pins == BASELINE_SOURCE_SHA256,
                 "SERIES_HELP_REPORT_SOURCE_PINS")
    with zipfile.ZipFile(BytesIO(archive_bytes)) as archive:
        for path in SOURCE_PATHS:
            entry_name = ARCHIVE_PREFIX + path
            entries = [entry for entry in archive.infolist() if entry.filename == entry_name]
            _require(len(entries) == 1 and not entries[0].is_dir(),
                     "SERIES_HELP_ARCHIVE_ENTRY")
            mode = (entries[0].external_attr >> 16) & 0o170000
            _require(mode in (0, stat.S_IFREG) and not entries[0].flag_bits & 0x1,
                     "SERIES_HELP_ARCHIVE_ENTRY_TYPE")
            old = historical[path]
            _require(_sha256(old) == BASELINE_SOURCE_SHA256[path]
                     and _sha256(archive.read(entries[0])) == BASELINE_SOURCE_SHA256[path],
                     "SERIES_HELP_ARCHIVE_SOURCE_HASH")
            _require(_sha256(current[path]) == CURRENT_SOURCE_SHA256[path]
                     and _expected_current(path, old) == current[path],
                     "SERIES_HELP_CURRENT_PROJECTION")


def validate_historical_source(root: Path, path: str, executed_digest: str) -> bytes:
    """Liefert archivierte Vorbytes nach vollständiger Prüfung des exakten Übergangs."""
    _require(path in SOURCE_PATHS and executed_digest == BASELINE_SOURCE_SHA256.get(path),
             "SERIES_HELP_HISTORICAL_PIN")
    root = Path(root).resolve(strict=True)
    archive_bytes = _validated_archive_bytes(root)
    with zipfile.ZipFile(BytesIO(archive_bytes)) as archive:
        historical = {source: archive.read(ARCHIVE_PREFIX + source) for source in SOURCE_PATHS}
    current = {source: (root / source).read_bytes() for source in SOURCE_PATHS}
    validate_transition(root, historical, current, archive_bytes=archive_bytes)
    return historical[path]
