#!/usr/bin/env python3
import json
import subprocess
import tempfile
from pathlib import Path

root = Path(__file__).resolve().parents[2]
required = (
    "Source/USP_WriteConsoleMessage.sql",
    "Deployment/Deploy.sql",
    "Deployment/Uninstall.sql",
    "Examples/ConsoleMessage.sql",
    "README.md",
    "Documentation/USP_WriteConsoleMessage.md",
    "Tests/CONSOLE_MESSAGE_CONTRACT_TEST_MATRIX.md",
    "Tests/README.md",
    "Tests/Runtime/ConsoleMessage.Contract.sql",
    "Tests/Runtime/ConsoleOutput.Contract.sql",
    "Tests/Runtime/Lifecycle.Contract.sql",
    "Tests/Runtime/Central.Contract.sql",
    "TestLab/ProjectAdapter/adapter.json",
    "TestLab/ProjectAdapter/Build-AdapterSql.ps1",
    "TestLab/ProjectAdapter/Invoke-OnExistingLab.ps1",
    "TestLab/ProjectAdapter/README.md",
    "TestLab/ProjectAdapter/sql/preflight.sql",
    "TestLab/ProjectAdapter/sql/install.sql",
    "TestLab/ProjectAdapter/sql/update.sql",
    "TestLab/ProjectAdapter/sql/validate.sql",
    "TestLab/ProjectAdapter/sql/cleanup.sql",
    "module.yaml",
)
missing = [path for path in required if not (root / path).is_file()]
if missing:
    raise SystemExit("Fehlende Artefakte: " + ", ".join(missing))

source = (root / "Source/USP_WriteConsoleMessage.sql").read_text("utf-8")
for marker in (
    "CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_WriteConsoleMessage]",
    "@Message   nvarchar(max) = NULL",
    "@Immediate bit           = 0",
    "@Debug     tinyint       = 0",
    "@Hilfe     bit           = 0",
    "Latin1_General_100_BIN2",
    "BETWEEN 55296 AND 56319",
    "BETWEEN 56320 AND 57343",
    "THEN 2000 ELSE 4000",
    "RAISERROR (N'%s', 0, 1, @Chunk) WITH NOWAIT",
    "PRINT @Chunk",
    "RETURN 0",
):
    if marker not in source:
        raise SystemExit(f"Console-Message-Vertragsmarker fehlt: {marker}")

if "SELECT @Message" in source:
    raise SystemExit("Die Console-Procedure darf kein Payload-Resultset erzeugen.")

runner = root.parents[1] / "Tests/CI/run-w2c-linux.sh"
if not runner.is_file():
    raise SystemExit("W2c-CI-Runner fehlt.")

runner_text = runner.read_text("utf-8")
if 'LC_ALL=C grep -Fq "${marker}"' not in runner_text:
    raise SystemExit(
        "Die W2c-Markerprüfung muss für Supplementary Characters "
        "byteorientiert unter LC_ALL=C laufen."
    )

adapter_root = root / "TestLab" / "ProjectAdapter"
adapter = json.loads((adapter_root / "adapter.json").read_text("utf-8"))
if adapter.get("adapterContractVersion") != "0.1":
    raise SystemExit("Der Project Adapter muss den Vertragsstand 0.1 verwenden.")
if adapter.get("projectId") != "sql-server-toolbelt-console-message":
    raise SystemExit("Die stabile Project-Adapter-Identität stimmt nicht.")
if adapter.get("supportedSqlVersions") != ["2019", "2022", "2025"]:
    raise SystemExit("Die Project-Adapter-SQL-Versionsmatrix stimmt nicht.")

entrypoints = adapter.get("entrypoints", {})
if set(entrypoints) != {"preflight", "install", "update", "validate", "cleanup"}:
    raise SystemExit("Der Project Adapter muss alle fünf Lifecycle-Entrypoints besitzen.")
for name, relative in entrypoints.items():
    relative_path = Path(relative)
    if relative_path.is_absolute() or ".." in relative_path.parts:
        raise SystemExit(f"Unsicherer Adapterpfad für {name}: {relative}")
    path = adapter_root / relative_path
    if not path.is_file():
        raise SystemExit(f"Adapter-Entrypoint fehlt: {relative}")
    text = path.read_text("utf-8")
    for forbidden in (":On Error", ":r ", "$(DeploymentMode)", "$(ConfirmNoExternalConsumers)"):
        if forbidden in text:
            raise SystemExit(
                f"Adapter-Entrypoint {relative} enthält SQLCMD-only Inhalt: {forbidden}"
            )

project_runner = (adapter_root / "Invoke-OnExistingLab.ps1").read_text("utf-8")
for forbidden in ("New-SqlServerLab", "Remove-SqlServerLab", "Repair-SqlServerLab"):
    if forbidden in project_runner:
        raise SystemExit(
            "Der Toolbelt-Adapter darf keine Lab-Infrastruktur verwalten: "
            + forbidden
        )

with tempfile.TemporaryDirectory(prefix="toolbelt-adp-008-") as temporary:
    generated = Path(temporary)
    build = subprocess.run(
        (
            "pwsh",
            "-NoProfile",
            "-File",
            str(adapter_root / "Build-AdapterSql.ps1"),
            "-RepositoryRoot",
            str(root.parents[1]),
            "-OutputDirectory",
            str(generated),
        ),
        cwd=root.parents[1],
        check=False,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    if build.returncode != 0:
        raise SystemExit(
            "Project-Adapter-Generator fehlgeschlagen:\n"
            + build.stdout
            + build.stderr
        )
    for filename in ("install.sql", "update.sql", "cleanup.sql"):
        committed = adapter_root / "sql" / filename
        expected = generated / filename
        if committed.read_bytes() != expected.read_bytes():
            raise SystemExit(
                f"Der versionierte Adapter-Entrypoint {filename} ist nicht kanonisch erzeugt."
            )

print("Console Message statische Vertragsprüfung: erfolgreich")
