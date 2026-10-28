"""Bindet drei DDL-Hilfekommentare an ihre archivierten Date-Spine-Quellen."""
from __future__ import annotations

from io import BytesIO
import hashlib
import json
from pathlib import Path
import stat
import zipfile


RECORD_PATH = "Releases/1.0.0/date-spine-ddl-help-transition.json"
RECORD_SHA256 = "bd0ad9073f7cbd20e86c983c7f28c02ffc445b0944c2cf6ffc6e0d2e627ce5cb"
ARCHIVE_PATH = "Releases/1.0.0/Artifacts/SQL-Server-Toolbelt-1.0.0-candidate-source.zip"
ARCHIVE_PREFIX = "SQL-Server-Toolbelt-1.0.0-candidate-source/"
ARCHIVE_SHA256 = "333a7d6ceb2a36523ea642ac1dd5a78b5fc86b8aaa25998db14c8ea035f068e6"
ARCHIVE_SIZE = 27274364
REPORT_PATH = "Releases/1.0.0/series-date-caller-qualification.json"
REPORT_SHA256 = "d1e8104ba569beec8ef11713e48b2a6735d2533184e1390f1095d06188a64974"
CORE_PATH = "Modules/toolbelt.datetime.date-spine/Source/TVF_DateSpineCore.sql"
CORE_SHA256 = "39898bc83c9c198113b539f69cc0485d3157d7358420e1f3dda53a0165fb42b6"
SOURCE_PATHS = (
    "Modules/toolbelt.datetime.date-spine/Source/TVF_DateSpineDay.sql",
    "Modules/toolbelt.datetime.date-spine/Source/TVF_DateSpineIsoWeek.sql",
    "Modules/toolbelt.datetime.date-spine/Source/TVF_DateSpineMonth.sql",
)
BASELINE_SOURCE_SHA256 = {
    SOURCE_PATHS[0]: "50ce950301627e93bb741f34a56133d3806552d9075a7e2228b60c04cbb5b6f4",
    SOURCE_PATHS[1]: "cca24cdcbd8f1fba1d63e7b368d612f9b67c2ce89a1b04413e0a23e3da7a6bb1",
    SOURCE_PATHS[2]: "6843046c4f45470d73a5470aeabbcf14b9d8e9098bb99175e1e49493c6de032e",
}
CURRENT_SOURCE_SHA256 = {
    SOURCE_PATHS[0]: "6f9c577bf010297bdbbb6d9afb4561295ff825d004391d34e160007f1e273b33",
    SOURCE_PATHS[1]: "356b77355a9deaf10195db8bc4857d7b09f6d6afd44fef23d7cc32c2896a0c38",
    SOURCE_PATHS[2]: "1bef5ca7920abaf27f8aed5184938f7dcaba328dcdba3123164cc894a420a9c5",
}
INSERTIONS = {
    SOURCE_PATHS[0]: (
        "    /*\n"
        "     * DDL-Hilfe: Liefert jeden Kalendertag, der den halboffenen Bereich\n"
        "     * [@RangeStart,@RangeEndExclusive) schneidet. Pflichtparameter:\n"
        "     * @RangeStart date und @RangeEndExclusive date; beide ohne Default.\n"
        "     * NULL, gleiche oder umgekehrte\n"
        "     * Grenzen liefern keine Zeilen. Das Resultset ist Ordinal int\n"
        "     * (nullfrei, ab 0) und PeriodStart date (nullfrei, Tagesanfang).\n"
        "     * Für eine Reihenfolge ist ORDER BY Ordinal erforderlich. Für SELECT-\n"
        "     * Aufrufe wird SELECT auf der Funktion benötigt.\n"
        "     * Beispiel: SELECT Ordinal,PeriodStart\n"
        "     * FROM toolbelt_datetime.TVF_DateSpineDay('20260227','20260303')\n"
        "     * ORDER BY Ordinal;\n"
        "     * Erwartet: (0,2026-02-27),(1,2026-02-28),(2,2026-03-01),(3,2026-03-02).\n"
        "     */\n",
        "    SELECT spine.Ordinal, spine.PeriodStart\n",
        "TVF_DateSpineDay",
    ),
    SOURCE_PATHS[1]: (
        "    /*\n"
        "     * DDL-Hilfe: Liefert ISO-Wochen, die den halboffenen Bereich\n"
        "     * [@RangeStart,@RangeEndExclusive) schneiden. Pflichtparameter:\n"
        "     * @RangeStart date und @RangeEndExclusive date; beide ohne Default.\n"
        "     * NULL, gleiche oder umgekehrte\n"
        "     * Grenzen liefern keine Zeilen. PeriodStart ist der Montag der\n"
        "     * geschnittenen ISO-Woche und kann vor @RangeStart liegen; DATEFIRST hat\n"
        "     * keinen Einfluss. Das Resultset ist Ordinal int (nullfrei, ab 0) und\n"
        "     * PeriodStart date (nullfrei). Für Reihenfolge ORDER BY Ordinal verwenden.\n"
        "     * Für SELECT-Aufrufe wird SELECT auf der Funktion benötigt.\n"
        "     * Beispiel: SELECT Ordinal,PeriodStart\n"
        "     * FROM toolbelt_datetime.TVF_DateSpineIsoWeek('20251231','20260108')\n"
        "     * ORDER BY Ordinal;\n"
        "     * Erwartet: (0,2025-12-29),(1,2026-01-05).\n"
        "     */\n",
        "    SELECT spine.Ordinal, spine.PeriodStart\n",
        "TVF_DateSpineIsoWeek",
    ),
    SOURCE_PATHS[2]: (
        "    /*\n"
        "     * DDL-Hilfe: Liefert Kalendermonate, die den halboffenen Bereich\n"
        "     * [@RangeStart,@RangeEndExclusive) schneiden. Pflichtparameter:\n"
        "     * @RangeStart date und @RangeEndExclusive date; beide ohne Default.\n"
        "     * NULL, gleiche oder umgekehrte\n"
        "     * Grenzen liefern keine Zeilen. PeriodStart ist der Monatserste\n"
        "     * des geschnittenen Monats und kann vor @RangeStart liegen. Das Resultset\n"
        "     * ist Ordinal int (nullfrei, ab 0) und PeriodStart date (nullfrei).\n"
        "     * Für Reihenfolge ORDER BY Ordinal verwenden. Für SELECT-Aufrufe wird\n"
        "     * SELECT auf der Funktion benötigt.\n"
        "     * Beispiel: SELECT Ordinal,PeriodStart\n"
        "     * FROM toolbelt_datetime.TVF_DateSpineMonth('20260115','20260402')\n"
        "     * ORDER BY Ordinal;\n"
        "     * Erwartet: (0,2026-01-01),(1,2026-02-01),(2,2026-03-01),(3,2026-04-01).\n"
        "     */\n",
        "    SELECT spine.Ordinal, spine.PeriodStart\n",
        "TVF_DateSpineMonth",
    ),
}
RECORD_KEYS = {
    "schema_version", "date", "status", "native_requalification_claimed",
    "current_head_ci_required", "publication_authorized", "scope", "archive",
    "baseline_report_sha256", "core_source_sha256", "sources", "comment_insertions",
}


class DateSpineHelpTransitionError(ValueError):
    """Meldet eine Abweichung von der engen Date-Spine-Quellprojektion."""


def _sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _require(condition: bool, message: str) -> None:
    if not condition:
        raise DateSpineHelpTransitionError(message)


def source_paths(root: Path) -> tuple[str, ...]:
    """Liefert ausschließlich die drei freigegebenen Wrapperquellen."""
    return SOURCE_PATHS


def _record(root: Path) -> dict:
    data = (root / RECORD_PATH).read_bytes()
    _require(_sha256(data) == RECORD_SHA256, "DATE_SPINE_HELP_RECORD_HASH")
    record = json.loads(data.decode("utf-8"))
    _require(isinstance(record, dict) and set(record) == RECORD_KEYS,
             "DATE_SPINE_HELP_RECORD_FIELDS")
    _require(record["schema_version"] == "toolbelt-date-spine-ddl-help/v1"
             and record["date"] == "2026-10-28"
             and record["status"] == "SOURCE_DELTA_ONLY"
             and record["native_requalification_claimed"] is False
             and record["current_head_ci_required"] is True
             and record["publication_authorized"] is False
             and record["scope"] == "Three saved DateSpine DDL help comment insertions only",
             "DATE_SPINE_HELP_RECORD_SCOPE")
    _require(record["archive"] == {"path": ARCHIVE_PATH, "sha256": ARCHIVE_SHA256,
                                   "size_bytes": ARCHIVE_SIZE}
             and record["baseline_report_sha256"] == {REPORT_PATH: REPORT_SHA256}
             and record["core_source_sha256"] == {"path": CORE_PATH, "sha256": CORE_SHA256},
             "DATE_SPINE_HELP_RECORD_BASELINE")
    insertions = sorted(f"{path}#{INSERTIONS[path][2]}" for path in SOURCE_PATHS)
    _require(record["comment_insertions"] == insertions, "DATE_SPINE_HELP_RECORD_INSERTIONS")
    sources = record["sources"]
    _require(isinstance(sources, dict) and set(sources) == set(SOURCE_PATHS),
             "DATE_SPINE_HELP_RECORD_PATHS")
    for path in SOURCE_PATHS:
        entry = sources[path]
        _require(isinstance(entry, dict) and set(entry) == {"baseline_sha256", "current_sha256"}
                 and entry["baseline_sha256"] == BASELINE_SOURCE_SHA256[path]
                 and entry["current_sha256"] == CURRENT_SOURCE_SHA256[path],
                 "DATE_SPINE_HELP_RECORD_SOURCE")
    return record


def _archive_bytes(root: Path, archive_bytes: bytes | None = None) -> bytes:
    path = root / ARCHIVE_PATH
    _require(path.is_file() and not path.is_symlink(), "DATE_SPINE_HELP_ARCHIVE_FILE")
    _require(path.stat().st_size == ARCHIVE_SIZE, "DATE_SPINE_HELP_ARCHIVE_SIZE")
    if archive_bytes is None:
        with path.open("rb") as stream:
            archive_bytes = stream.read(ARCHIVE_SIZE + 1)
    _require(len(archive_bytes) == ARCHIVE_SIZE and _sha256(archive_bytes) == ARCHIVE_SHA256,
             "DATE_SPINE_HELP_ARCHIVE_HASH")
    sidecar = Path(str(path) + ".sha256").read_text(encoding="ascii").split()
    _require(sidecar == [ARCHIVE_SHA256, path.name], "DATE_SPINE_HELP_ARCHIVE_SIDECAR")
    return archive_bytes


def _expected_current(path: str, historical: bytes) -> bytes:
    _require(path in INSERTIONS, "DATE_SPINE_HELP_PATH")
    block, anchor, _label = INSERTIONS[path]
    anchor_bytes = anchor.encode("utf-8")
    _require(historical.count(anchor_bytes) == 1, "DATE_SPINE_HELP_ANCHOR")
    return historical.replace(anchor_bytes, block.encode("utf-8") + anchor_bytes, 1)


def validate_transition(root: Path, historical: dict[str, bytes], current: dict[str, bytes],
                        *, archive_bytes: bytes | None = None) -> None:
    """Prüft die unveränderten Report-/Core-Pins und nur drei DDL-Kommentar-Inserts."""
    root = Path(root).resolve(strict=True)
    _record(root)
    _require(set(historical) == set(SOURCE_PATHS) and set(current) == set(SOURCE_PATHS),
             "DATE_SPINE_HELP_SOURCE_SET")
    archive_bytes = _archive_bytes(root, archive_bytes)
    report_bytes = (root / REPORT_PATH).read_bytes()
    _require(_sha256(report_bytes) == REPORT_SHA256, "DATE_SPINE_HELP_REPORT_HASH")
    report = json.loads(report_bytes.decode("utf-8"))
    pins = report.get("source_sha256")
    _require(isinstance(pins, dict)
             and {path: pins.get(path) for path in SOURCE_PATHS} == BASELINE_SOURCE_SHA256
             and pins.get(CORE_PATH) == CORE_SHA256,
             "DATE_SPINE_HELP_REPORT_SOURCE_PINS")
    core_now = (root / CORE_PATH).read_bytes()
    _require(_sha256(core_now) == CORE_SHA256, "DATE_SPINE_HELP_CORE_CURRENT")
    with zipfile.ZipFile(BytesIO(archive_bytes)) as archive:
        core_entry = ARCHIVE_PREFIX + CORE_PATH
        entries = [item for item in archive.infolist() if item.filename == core_entry]
        _require(len(entries) == 1 and not entries[0].is_dir(), "DATE_SPINE_HELP_CORE_ENTRY")
        mode = (entries[0].external_attr >> 16) & 0o170000
        _require(mode in (0, stat.S_IFREG) and not entries[0].flag_bits & 0x1
                 and _sha256(archive.read(entries[0])) == CORE_SHA256,
                 "DATE_SPINE_HELP_CORE_ARCHIVE")
        for path in SOURCE_PATHS:
            entry_name = ARCHIVE_PREFIX + path
            found = [item for item in archive.infolist() if item.filename == entry_name]
            _require(len(found) == 1 and not found[0].is_dir(),
                     "DATE_SPINE_HELP_ARCHIVE_ENTRY")
            mode = (found[0].external_attr >> 16) & 0o170000
            _require(mode in (0, stat.S_IFREG) and not found[0].flag_bits & 0x1,
                     "DATE_SPINE_HELP_ARCHIVE_ENTRY_TYPE")
            old = historical[path]
            _require(_sha256(old) == BASELINE_SOURCE_SHA256[path]
                     and _sha256(archive.read(found[0])) == BASELINE_SOURCE_SHA256[path],
                     "DATE_SPINE_HELP_ARCHIVE_SOURCE_HASH")
            _require(_sha256(current[path]) == CURRENT_SOURCE_SHA256[path]
                     and _expected_current(path, old) == current[path],
                     "DATE_SPINE_HELP_CURRENT_PROJECTION")


def validate_historical_source(root: Path, path: str, executed_digest: str) -> bytes:
    """Gibt archivierte Vorbytes nur nach Prüfung des kompletten Übergangs zurück."""
    _require(path in SOURCE_PATHS and executed_digest == BASELINE_SOURCE_SHA256.get(path),
             "DATE_SPINE_HELP_HISTORICAL_PIN")
    root = Path(root).resolve(strict=True)
    archive_bytes = _archive_bytes(root)
    with zipfile.ZipFile(BytesIO(archive_bytes)) as archive:
        historical = {source: archive.read(ARCHIVE_PREFIX + source) for source in SOURCE_PATHS}
    current = {source: (root / source).read_bytes() for source in SOURCE_PATHS}
    validate_transition(root, historical, current, archive_bytes=archive_bytes)
    return historical[path]
