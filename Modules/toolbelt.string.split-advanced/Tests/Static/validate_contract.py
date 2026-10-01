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
    for name in ("TVF_UnquoteToken","USP_SplitAdvanced"):
        require(deploy,(f":r ../Source/{name}.sql",name))
        assert deploy.count(f":r ../Source/{name}.sql")==1
    unquote=(MODULE/"Source/TVF_UnquoteToken.sql").read_text(encoding="utf-8")
    require(unquote,("IsValid bit NOT NULL","IF @Input IS NULL RETURN;",
        "65536","@Length<2","OUTER_PAIR_REQUIRED","UNESCAPED_CLOSING_QUALIFIER",
        "Latin1_General_100_BIN2","@EscapedEnd","@SpanStart"))
    usp=(MODULE/"Source/USP_SplitAdvanced.sql").read_text(encoding="utf-8")
    require(usp,("IF @Hilfe=1","IF @Input IS NULL","DECLARE @Success TABLE",
        "Value nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL",
        "THROW 51680","THROW 51681","USP_PrepareResultTable","SAVE TRANSACTION",
        "XACT_STATE()=1","@OwnTransaction=1 COMMIT","THROW;"))
    assert "INSERT EXEC" not in usp.upper()
    assert usp.count("FROM toolbelt_string.TVF_SplitAdvanced(")==1
    require(uninstall,("AND NOT EXISTS","USP_SplitAdvanced","TVF_UnquoteToken","N'1.1.0'"))
    require(uninstall,("ConfirmNoExternalConsumers","sys.sql_expression_dependencies",
       "Toolbelt.Module.toolbelt.string.split-advanced.Version","sp_getapplock"))
    runtime=(MODULE/"Tests/Runtime/SplitAdvanced.Contract.sql").read_text(encoding="utf-8")
    require(runtime,("CONVERT(varbinary(max),Value)","65537","16385","@Unicode",
        "CROSS APPLY","DANGLING_ESCAPE","UNTERMINATED_QUOTE","NUL_NOT_ALLOWED"))
    runner=(ROOT/"Tests/CI/run-split-advanced-linux.sh").read_text(encoding="utf-8")
    require(runner,("Lifecycle.Contract.sql","Central.Contract.sql","SplitAdvanced.Contract.sql",
       "ConfirmNoExternalConsumers=1","ForeignData","VW_SplitAdvancedConsumer",
       "UnquoteToken.Contract.sql","SplitAdvancedUsp.Contract.sql","toolbelt.core.result-table/Deployment"))
    workflow=(ROOT/".github/workflows/split-advanced-runtime.yml").read_text(encoding="utf-8")
    require(workflow,("run-split-advanced-linux.sh",'"2019"','"2022"','"2025"'))
    for marker in ('"Documentation/Architecture/**"','"Documentation/Standards/**"',
       '"Modules/toolbelt.string.split-advanced/Documentation/**"',
       '"Modules/toolbelt.string.split-advanced/Tests/**/*.md"'):
        assert marker not in workflow, "Documentation must not trigger runtime"
    print("Split-Advanced static contracts: success")
if __name__=="__main__": main()
