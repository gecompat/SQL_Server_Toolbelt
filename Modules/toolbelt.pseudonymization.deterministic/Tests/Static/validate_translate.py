"""Separate Translate-Strukturprüfung; kein SQL-Runtime-/Optimizerbeweis."""
from pathlib import Path
import re
from reference_translate import VECTORS, run

MODULE = Path(__file__).resolve().parents[2]


def main():
    text = (MODULE / "Source/DeterministicTranslate.sql").read_text(encoding="utf-8")
    fixture = (MODULE / "Tests/Runtime/Translate.Contract.sql").read_text(encoding="utf-8")
    assert re.search(r"RETURNS TABLE\s+AS\s+RETURN\s*\(", text)
    assert text.count("CREATE OR ALTER FUNCTION") == 1
    assert "TVF_DeterministicTranslate" in text
    assert not any(word in text.upper() for word in ("RETURNS @", "SVF_", "EXTERNAL NAME", "RAND(", "NEWID(", "CRYPT_GEN_RANDOM(", "PATINDEX(", "REPLACE("))
    assert "0x5442584454524E31" in text
    assert "SUBSTRING(versionBytes.Bytes, 5, 4) + seedBytes.Bytes" in text
    assert "PARTITION BY AlphabetKind ORDER BY Digest, OriginalOrdinal" in text
    assert "WITHIN GROUP (ORDER BY MappingOrdinal)" in text
    assert text.count("[TVF_DeterministicIntegerBytes]") == 4
    assert "DATALENGTH(@Profile) = 16" in text and "DATALENGTH(@Profile) = 10" in text
    assert "CONVERT(varbinary(max), @Profile)" in text
    assert "SeparatorBytes BETWEEN 0 AND 66" in text
    assert "COUNT(DISTINCT CodeUnit)" in text
    assert "WHEN @Value IS NULL THEN 0" in text
    assert "InputBytes <= 16777216" in text
    assert "REPLICATE(CONVERT(nvarchar(max), N'A'), safe.SafeCount)" in text
    assert "LEN(" not in text.upper()
    assert "Latin1_General_100_BIN2" in text
    for version, seed, expected in VECTORS:
        assert expected in fixture
    assert "8388608" in fixture and "1048576" in fixture
    assert "STUFF(@Large,8388608,1,N'-')" in fixture
    print(f"PASS: Translate Struktur/Festvektoren ({run()} Referenzassertions; SQL not executed)")


if __name__ == "__main__":
    main()
