#!/usr/bin/env python3
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

print("Console Message statische Vertragsprüfung: erfolgreich")
