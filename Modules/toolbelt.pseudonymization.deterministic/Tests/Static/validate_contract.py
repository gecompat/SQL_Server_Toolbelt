"""Statische Vertragsguards; kein SQL-Runtime-/Deploymentnachweis."""
from pathlib import Path
import re
from reference_vectors import run

MODULE = Path(__file__).resolve().parents[2]
SOURCES = MODULE / "Source"


def main():
    names = ["TVF_DeterministicIntegerBytes", "TVF_DeterministicRangeCore", "TVF_DeterministicRange", "TVF_DeterministicDateShift"]
    for name in names:
        text = (SOURCES / (name + ".sql")).read_text(encoding="utf-8")
        assert re.search(r"RETURNS TABLE\s+AS\s+RETURN\s*\(", text)
        assert "RETURNS @" not in text.upper()
        assert "SVF_" not in text and "EXTERNAL NAME" not in text.upper()
        assert all(value not in text.upper() for value in ["RAND(", "NEWID(", "GETDATE(", "CRYPT_GEN_RANDOM("])
    core = (SOURCES / "TVF_DeterministicRangeCore.sql").read_text(encoding="utf-8")
    facade = (SOURCES / "TVF_DeterministicRange.sql").read_text(encoding="utf-8")
    encoder = (SOURCES / "TVF_DeterministicIntegerBytes.sql").read_text(encoding="utf-8")
    assert core.count("HASHBYTES('SHA2_256'") == 1
    assert "highDigit.n * 16 + lowDigit.n" in core and "(15)" in core
    assert "ORDER BY counter.Attempt" in core and "TOP (1)" in core
    assert "18446744073709551616) % safe.Span" in core
    assert "DATALENGTH(@Key) > 8000" in core
    assert "WHEN @Key IS NULL THEN 0" in core
    assert "ISNULL(CONVERT(int, CASE" in core
    assert "0x54425844524E4731, 0," in facade
    assert "@Seed           bigint = 0" in facade
    # Framing hängt nicht von nativer SQL-Integer-Binary-Repräsentation ab.
    assert "CONVERT(binary(4)" not in core and "CONVERT(binary(8)" not in core
    assert encoder.count("SUBSTRING('0123456789ABCDEF'") == 16
    assert "CONVERT(binary(8)," in encoder and ", 2)" in encoder
    date = (SOURCES / "TVF_DeterministicDateShift.sql").read_text(encoding="utf-8")
    assert date.count("CROSS APPLY [toolbelt_pseudonymization].[TVF_DeterministicRange]") == 1
    assert "HASHBYTES(" not in date and "3652058" in date
    facade_lookup = (SOURCES / "USP_DeterministicLookup.sql").read_text(encoding="utf-8")
    lookup = (SOURCES / "USP_DeterministicLookupCore.sql").read_text(encoding="utf-8")
    assert facade_lookup.index("IF @Hilfe = 1") < facade_lookup.index("THROW 54000")
    assert "CREATE TABLE #tbx_" not in facade_lookup
    assert facade_lookup.index("THROW 54009") < facade_lookup.index("EXEC toolbelt_pseudonymization.USP_DeterministicLookupCore")
    assert "0x544258444C4B5031,@LookupVersion" in lookup
    assert "CREATE TABLE #tbx_DeterministicLookup_Input" in lookup
    assert "CROSS APPLY toolbelt_pseudonymization.TVF_DeterministicRangeCore\n" in lookup
    assert "EXECUTE AS" not in lookup.upper() and "GRANT " not in lookup.upper()
    assert "SAVE TRANSACTION @Savepoint; SET @SavepointSet = 1" in lookup
    assert "@SavepointSet = 1 AND XACT_STATE() = 1" in lookup
    assert lookup.index("IF @ResultBytes >") < lookup.index("EXEC toolbelt_core.USP_PrepareResultTable")
    assert "INSERT EXEC" not in lookup.upper() and "INSERT ... EXEC" not in lookup.upper()
    assert "@MaxInputRows int = 10000" in facade_lookup and "@MaxResultBytes bigint = 16777216" in facade_lookup
    assert re.search(r"@ResultTable sysname = NULL\s*, @KeepData bit = 0\s*, @Debug tinyint = 0\s*, @Hilfe bit = 0", facade_lookup)
    for file in (MODULE / "Deployment").glob("*.sql"):
        text = file.read_text(encoding="utf-8")
        assert not re.search(r"\b539\d{2}\b", text)
        if file.name != "ReleaseManifest.sql":
            assert "sp_getapplock" in text and "CONVERT(varbinary(max),@Version)" in text
            assert "OBJECT_ID(N'toolbelt_pseudonymization.'+QUOTENAME" in text
            assert text.index("RAISERROR(N'DETERMINISTIC_LIFECYCLE_CALLER_TRANSACTION:") < text.index("SET XACT_ABORT ON") < text.index(":r ReleaseManifest.sql")
    for document in (MODULE / "Documentation").glob("*.md"):
        assert not re.search(r"\b539\d{2}\b", document.read_text(encoding="utf-8"))
    for expected in ["README.md", "Tests/README.md", "Tests/CONTRACT_TEST_MATRIX.md", "Tests/Runtime/Lifecycle.Contract.sql", "Tests/Runtime/Central.Contract.sql", "Tests/Runtime/Lookup.Boundaries.sql", "Tests/Runtime/SelectMetadata.Contract.ps1"]:
        assert (MODULE / expected).is_file(), expected
    run()
    print("PASS: Familien-Source-/Lifecycle-Staticguards; kein SQL-Runtime-Nachweis")


if __name__ == "__main__":
    main()
