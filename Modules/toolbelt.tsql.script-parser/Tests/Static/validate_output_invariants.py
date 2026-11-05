"""Source-bound review guard; does not claim general C# verification or a native API run."""
import hashlib
import re
from pathlib import Path

REVIEWED_SOURCE = "F74488C0E657E886CA4AD1E86FFE96463AE3CADCF1E90989819E8697C8A8F2CF"
PROVIDER = Path(__file__).resolve().parents[2] / "Clr/ScriptParserProvider.cs"


def validate(text: str) -> None:
    required = (
        "new OutputBudget(kind == OutputKind.Nodes ? 32768 : kind == OutputKind.Properties ? 131072 : kind == OutputKind.Tokens ? 8192 : 256, 16777216)",
        "long next = checked(bytes + 128L);",
        "next = checked(next + value.Length * 2L)",
        "if (rows >= rowLimit || next > byteLimit) throw new InvalidOperationException",
        "rows++; bytes = next;",
        "var rows = new List<object>();",
    )
    if any(part not in text for part in required) or "yield return" in text:
        raise ValueError("OUTPUT_INVARIANT_ACCOUNTING_OR_BUFFERING")
    if len(re.findall(r"\brows\.Add\(", text)) != 4:
        raise ValueError("OUTPUT_INVARIANT_UNREVIEWED_EMISSION")
    for arguments, row in (
        ("type, value", "ScriptTokenRow"),
        ("message", "ScriptErrorRow"),
        ("type, item.Property", "AstNodeRow"),
        ("property.Name, propertyKind, formatted", "AstPropertyRow"),
    ):
        pattern = re.escape("budget.Add(" + arguments + ");") + r"\s*rows\.Add\(new " + row + r"\("
        if not re.search(pattern, text):
            raise ValueError("OUTPUT_INVARIANT_UNGUARDED_EMISSION")
    for kind in ("Nodes", "Properties", "Tokens", "Errors"):
        if not re.search(r"return BuildResult\([^;]+OutputKind\." + kind + r"\);", text):
            raise ValueError("OUTPUT_INVARIANT_PUBLIC_BUFFERING")
    # The exact reviewed body closes gaps a lexical guard alone cannot reason about.
    if hashlib.sha256(text.encode("utf-8")).hexdigest().upper() != REVIEWED_SOURCE:
        raise ValueError("OUTPUT_INVARIANT_SOURCE_REVIEW_REQUIRED")


def selftest() -> None:
    source = PROVIDER.read_text(encoding="utf-8")
    validate(source)
    mutants = (
        source.replace("budget.Add(type, value);", ""),
        source.replace("rows >= rowLimit", "rows > rowLimit"),
        source.replace("next > byteLimit", "next >= byteLimit"),
        source.replace("value.Length * 2L", "value.Length"),
        source.replace("rows++; bytes = next;", "rows++;"),
        source.replace("var rows = new List<object>();", "yield return null; var rows = new List<object>();"),
        source + "\n// Unreviewed source change.\n",
    )
    for mutant in mutants:
        try:
            validate(mutant)
        except ValueError:
            continue
        raise AssertionError("OUTPUT_INVARIANT_MUTANT_ACCEPTED")
    print("OUTPUT_INVARIANTS_PASS 1 reviewed source, 7 rejected mutants; no native claim")


if __name__ == "__main__":
    selftest()
