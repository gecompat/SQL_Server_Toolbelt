#!/usr/bin/env python3
"""S2 source/lifecycle/wiring contracts; runtime semantics remain SQL tests."""
from pathlib import Path
import re
MODULE = Path(__file__).resolve().parents[2]
ROOT = MODULE.parents[1]
def require(text, markers):
    for marker in markers:
        assert marker in text, f"Missing contract marker: {marker}"
def main():
    source=(MODULE/"Source/TVF_SplitAdvanced.sql").read_text(encoding="utf-8")
    require(source,("CREATE OR ALTER FUNCTION [toolbelt_string].[TVF_SplitAdvanced]",
      "@Input nvarchar(max)","@SeparatorsJson nvarchar(max)","@Quote nvarchar(max)",
      "@Escape nvarchar(max)","@KeepEmpty bit = 1","IsValid bit NOT NULL",
      "ErrorCode varchar(64) NULL","ErrorPosition bigint NULL","IF @Input IS NULL RETURN;",
      "DATALENGTH(@Input) / 2","Latin1_General_100_BIN2","CONVERT(varbinary(max), Separator)",
      "ROW_NUMBER() OVER (ORDER BY TokenOrdinal)","COALESCE(@KeepEmpty, 1)",
      "65536","16384","@SeparatorCount > 16","@SeparatorLength > 64",
      "DANGLING_ESCAPE","UNTERMINATED_QUOTE","@ErrorPosition = @QuoteStart"))
    for marker in ("THROW","TRY","CATCH","STRING_SPLIT(","sys.all_objects"):
        assert not re.search(r"\b"+re.escape(marker),source,re.I), marker
    deploy=(MODULE/"Deployment/Deploy.sql").read_text(encoding="utf-8")
    uninstall=(MODULE/"Deployment/Uninstall.sql").read_text(encoding="utf-8")
    require(deploy,(":r ../Source/TVF_SplitAdvanced.sql","sp_getapplock","51679","< 150",
       "Toolbelt.Module.toolbelt.string.split-advanced.Version","SourceHash","N'TF'"))
    assert deploy.count(":r ../Source/TVF_SplitAdvanced.sql")==1
    require(uninstall,("ConfirmNoExternalConsumers","sys.sql_expression_dependencies",
       "Toolbelt.Module.toolbelt.string.split-advanced.Version","sp_getapplock"))
    runtime=(MODULE/"Tests/Runtime/SplitAdvanced.Contract.sql").read_text(encoding="utf-8")
    require(runtime,("CONVERT(varbinary(max),Value)","65537","16385","@Unicode",
        "CROSS APPLY","DANGLING_ESCAPE","UNTERMINATED_QUOTE","NUL_NOT_ALLOWED"))
    runner=(ROOT/"Tests/CI/run-split-advanced-linux.sh").read_text(encoding="utf-8")
    require(runner,("Lifecycle.Contract.sql","Central.Contract.sql","SplitAdvanced.Contract.sql",
       "ConfirmNoExternalConsumers=1","ForeignData","VW_SplitAdvancedConsumer"))
    workflow=(ROOT/".github/workflows/split-advanced-runtime.yml").read_text(encoding="utf-8")
    require(workflow,("run-split-advanced-linux.sh",'"2019"','"2022"','"2025"'))
    for marker in ('"Documentation/Architecture/**"','"Documentation/Standards/**"',
       '"Modules/toolbelt.string.split-advanced/Documentation/**"',
       '"Modules/toolbelt.string.split-advanced/Tests/**/*.md"'):
        assert marker not in workflow, "Documentation must not trigger runtime"
    print("Split-Advanced static contracts: success")
if __name__=="__main__": main()
