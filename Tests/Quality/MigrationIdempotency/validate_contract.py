from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
CONTRACT = ROOT / "Tests/Quality/MigrationIdempotency/MigrationIdempotency.Contract.sql"
CAPTURE = ROOT / "Tests/Quality/MigrationIdempotency/CaptureSnapshot.sql"
POST_UNINSTALL = ROOT / "Tests/Quality/MigrationIdempotency/PostUninstall.Contract.sql"
RUNNER = ROOT / "Tests/CI/run-q1-migration-idempotency.sh"
DESIGN = ROOT / "Documentation/Architecture/MIGRATION_IDEMPOTENCY_VERIFIER_DESIGN.md"


def require(text: str, needle: str, source: Path) -> None:
    if needle not in text:
        raise AssertionError(f"{source}: erwarteter Vertragsbaustein fehlt: {needle}")


for path in (CONTRACT, CAPTURE, POST_UNINSTALL, RUNNER, DESIGN):
    if not path.is_file():
        raise AssertionError(f"Pflichtartefakt fehlt: {path}")

contract = CONTRACT.read_text(encoding="utf-8")
capture = CAPTURE.read_text(encoding="utf-8")
post_uninstall = POST_UNINSTALL.read_text(encoding="utf-8")
runner = RUNNER.read_text(encoding="utf-8")
design = DESIGN.read_text(encoding="utf-8")

for needle in (
    ":r $(DeployScriptPath)",
    ":r $(CaptureSnapshotPath)",
    "SnapshotOrdinal",
    "Wiederholungsdeployment erzeugte Katalogdrift",
    "benötigt eine isolierte leere Testdatenbank",
    "objects.type NOT IN ('FN', 'IF', 'TF', 'P', 'V')",
):
    require(contract, needle, CONTRACT)

for needle in (
    "sys.sql_modules",
    "sys.columns",
    "sys.parameters",
    "sys.extended_properties",
    "sys.database_permissions",
):
    require(capture, needle, CAPTURE)

for needle in (
    "trap cleanup EXIT",
    "MigrationIdempotency.Contract.sql",
    "CaptureSnapshotPath",
    "PostUninstall.Contract.sql",
    "Q1_RUNNER_FIRST_UNINSTALL_DONE",
    "Q1_RUNNER_SECOND_UNINSTALL_DONE",
    "toolbelt.core.generate-series",
    "DROP DATABASE",
):
    require(runner, needle, RUNNER)

for needle in ("wiederholte Uninstall", "Toolbelt-Objekte", "$(ModuleId)"):
    require(post_uninstall, needle, POST_UNINSTALL)

for needle in (
    "dependency-frei",
    "zustandslosen T-SQL",
    "keine öffentliche SQL-Schnittstelle",
    "Uninstall",
):
    require(design, needle, DESIGN)

if "password" in (contract + capture).lower():
    raise AssertionError("SQL-Contract darf keine Credential-Verarbeitung enthalten.")

print("Q1 Migration-Idempotency-Verifier Static Contract: erfolgreich")
