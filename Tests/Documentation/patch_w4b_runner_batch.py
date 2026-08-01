#!/usr/bin/env python3
"""Trennt den temporären Uninstall-Test in gültige T-SQL-Batches."""

from pathlib import Path

path = Path("Tests/CI/run-w4b-work-type-linux.sh")
text = path.read_text(encoding="utf-8")
old = (
    'run_query "${local_db}" "CREATE OR ALTER PROCEDURE toolbelt_core.USP_TestUninstall '
    "AS BEGIN SET NOCOUNT ON; END; EXEC toolbelt_core.USP_RegisterWorkType "
    "@WorkTypeName='test.uninstall', @HandlerSchema=N'toolbelt_core', "
    "@HandlerProcedure=N'USP_TestUninstall';" + '"\n'
)
new = (
    'run_query "${local_db}" "CREATE OR ALTER PROCEDURE toolbelt_core.USP_TestUninstall '
    'AS BEGIN SET NOCOUNT ON; END;"\n'
    'run_query "${local_db}" "EXEC toolbelt_core.USP_RegisterWorkType '
    "@WorkTypeName='test.uninstall', @HandlerSchema=N'toolbelt_core', "
    "@HandlerProcedure=N'USP_TestUninstall';" + '"\n'
)
count = text.count(old)
if count != 1:
    raise RuntimeError(f"Uninstall-Testbatch: erwartet genau einen Treffer, gefunden {count}")
path.write_text(text.replace(old, new, 1), encoding="utf-8", newline="\n")
