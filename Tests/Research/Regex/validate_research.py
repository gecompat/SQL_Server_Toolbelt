from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[3]
RESEARCH = ROOT / "Documentation" / "Research" / "REGEX_SEMANTICS_PROVIDER_SPIKE.md"
TEST_ROOT = ROOT / "Tests" / "Research" / "Regex"


def require(text: str, markers: tuple[str, ...], label: str) -> None:
    missing = [marker for marker in markers if marker not in text]
    if missing:
        raise SystemExit(f"{label}: Marker fehlen: {', '.join(missing)}")


research = RESEARCH.read_text(encoding="utf-8")
require(
    research,
    (
        "kein Provider nachgewiesen",
        "kein Modul, kein Deployment und keine öffentliche Runtime-API",
        "REGEXP_LIKE",
        "REGEXP_INSTR",
        "REGEXP_COUNT",
        "System.Text.RegularExpressions",
        "RE2.Managed",
        "keine Dependency aufgenommen",
        "ausdrücklich nicht freigegeben",
    ),
    "Research-Dokument",
)

sql = "\n".join(
    path.read_text(encoding="utf-8")
    for path in TEST_ROOT.glob("*.sql")
)
if re.search(
    r"\bCREATE\s+(?:OR\s+ALTER\s+)?(?:FUNCTION|PROCEDURE|ASSEMBLY|VIEW)\b",
    sql,
    flags=re.IGNORECASE,
):
    raise SystemExit("R1a darf keine Runtime-Objekte definieren.")

require(
    sql,
    (
        "REGEXP_LIKE",
        "REGEXP_INSTR",
        "REGEXP_COUNT",
        "CompatibilityLevel",
        "(a)\\1",
        "a(?=b)",
        "a{1001}",
    ),
    "SQL-Testvektoren",
)

dotnet = (TEST_ROOT / "DotNet48Semantics.cs").read_text(encoding="utf-8")
require(
    dotnet,
    (
        "RegexOptions.CultureInvariant",
        "RegexOptions.ECMAScript",
        "TimeSpan.FromMilliseconds(250)",
        '"ascii-word", "final-newline"',
        '"dot-singleline", "final-newline"',
    ),
    ".NET-Framework-Testvektoren",
)

for forbidden in (
    ROOT / "Modules" / "toolbelt.string.regex",
    ROOT / "Modules" / "toolbelt.string.regexp",
):
    if forbidden.exists():
        raise SystemExit(f"R1a hat unerwartet ein Modul erzeugt: {forbidden.name}")

print("R1a Regex-Research-Vertrag: erfolgreich")
