#!/usr/bin/env python3
"""Temporärer Runner für die einmalige Repository-Statussynchronisierung."""

from __future__ import annotations

import re
from pathlib import Path


WORKFLOW = Path(".github/workflows/temp-sync-repository-status.yml")


def replace_regex(
    path: Path,
    pattern: str,
    replacement: str,
    *,
    flags: int = 0,
) -> None:
    text = path.read_text(encoding="utf-8")
    updated, changes = re.subn(
        pattern,
        lambda _match: replacement,
        text,
        count=1,
        flags=flags,
    )
    if changes != 1:
        raise RuntimeError(f"{path}: erwarteter Transformationsblock fehlt: {pattern}")
    path.write_text(updated, encoding="utf-8", newline="\n")


def patch_file_content_runtime() -> None:
    source = Path("Modules/toolbelt.file.content/Source/USP_LoadTextFile.sql")

    header_read = """    -- BOM-Heuristik und exakte Dateigröße über denselben SINGLE_BLOB-Lesezugriff.
    SET @Sql = N'SELECT TOP (1)'
               + N' @Header = SUBSTRING(BulkColumn, 1, 4),'
               + N' @BytesRead = DATALENGTH(BulkColumn)'
               + N' FROM OPENROWSET(BULK '
               + QUOTENAME(@FilePath, N'''')
               + N', SINGLE_BLOB) AS x;';

    BEGIN TRY
        EXEC sys.sp_executesql
              @stmt = @Sql
            , @params = N'@Header varbinary(4) OUTPUT, @BytesRead bigint OUTPUT'
            , @Header = @Header OUTPUT
            , @BytesRead = @BytesRead OUTPUT;"""
    replace_regex(
        source,
        r"    -- BOM-Heuristik über die ersten 4 Bytes\.\n"
        r"    SET @Sql = .*?"
        r"            , @Header = @Header OUTPUT;",
        header_read,
        flags=re.DOTALL,
    )

    bom_logic = """    IF @MaxBytes IS NOT NULL AND @BytesRead > @MaxBytes
    BEGIN
        SELECT
              CAST(NULL AS nvarchar(max)) AS Content
            , @BytesRead                  AS BytesRead
            , NULL                        AS EncodingDetected
            , CAST(0 AS bit)              AS BomPresent
            , CAST(0 AS bit)              AS IsValid
            , 51323                       AS ValidationCode
            , N'Datei überschreitet @MaxBytes.' AS ValidationMessage;
        RETURN 0;
    END;

    -- Vierbyteige BOMs müssen vor den zweibyteigen Präfixen geprüft werden.
    IF @Header = 0xFFFE0000 OR @Header = 0x0000FEFF
    BEGIN
        SELECT
              CAST(NULL AS nvarchar(max)) AS Content
            , @BytesRead                  AS BytesRead
            , CASE @Header
                  WHEN 0xFFFE0000 THEN N'UTF-32-LE'
                  ELSE N'UTF-32-BE'
              END                         AS EncodingDetected
            , CAST(1 AS bit)              AS BomPresent
            , CAST(0 AS bit)              AS IsValid
            , 51325                       AS ValidationCode
            , N'UTF-32 wird nicht unterstützt.' AS ValidationMessage;
        RETURN 0;
    END
    ELSE IF SUBSTRING(@Header, 1, 3) = 0xEFBBBF
    BEGIN
        SET @EncodingDetected = N'UTF-8';
        SET @BomPresent = 1;
    END
    ELSE IF SUBSTRING(@Header, 1, 2) = 0xFFFE
    BEGIN
        SET @EncodingDetected = N'UTF-16-LE';
        SET @BomPresent = 1;
    END
    ELSE IF SUBSTRING(@Header, 1, 2) = 0xFEFF
    BEGIN
        SELECT
              CAST(NULL AS nvarchar(max)) AS Content
            , @BytesRead                  AS BytesRead
            , N'UTF-16-BE'                AS EncodingDetected
            , CAST(1 AS bit)              AS BomPresent
            , CAST(0 AS bit)              AS IsValid
            , 51325                       AS ValidationCode
            , N'UTF-16-BE wird nicht unterstützt.' AS ValidationMessage;
        RETURN 0;
    END
    ELSE
    BEGIN
        SET @EncodingDetected = @FallbackEncoding;
        SET @BomPresent = 0;
    END;

    /*"""
    replace_regex(
        source,
        r"    IF @Header = 0xEFBBBF\n.*?    END;\n\n    /\*",
        bom_logic,
        flags=re.DOTALL,
    )

    replace_regex(
        source,
        r"\n        SET @BytesRead = DATALENGTH\(@Content\) \* 2; -- NCHAR = 2 Byte pro Codeunit\n\n"
        r"        IF @MaxBytes IS NOT NULL AND @BytesRead > @MaxBytes\n"
        r"        BEGIN\n.*?        END;\n\n        SELECT",
        "\n        SELECT",
        flags=re.DOTALL,
    )

    contract = Path(
        "Modules/toolbelt.file.content/Tests/Runtime/FileContent.Contract.sql"
    )
    text = contract.read_text(encoding="utf-8")
    old_root = (
        "DECLARE @FixtureRoot nvarchar(4000) = "
        "N'/workspace/Modules/toolbelt.file.content/Tests/Runtime/fixtures';"
    )
    if old_root not in text:
        raise RuntimeError("FileContent.Contract.sql: FixtureRoot-Ausgangswert fehlt.")
    text = text.replace(
        old_root,
        "DECLARE @FixtureRoot nvarchar(4000) = N'$(FixtureRoot)';",
        1,
    )
    text = text.replace(
        "WHERE IsValid = 1 AND EncodingDetected = N'UTF-8' AND BomPresent = 1",
        "WHERE IsValid = 1 AND EncodingDetected = N'UTF-8' AND BomPresent = 1 AND BytesRead = 43",
        1,
    )
    text = text.replace(
        "WHERE IsValid = 1 AND EncodingDetected = N'Windows-1252' AND BomPresent = 0",
        "WHERE IsValid = 1 AND EncodingDetected = N'Windows-1252' AND BomPresent = 0 AND BytesRead = 26",
        1,
    )
    text = text.replace(
        "WHERE IsValid = 1 AND EncodingDetected = N'UTF-16-LE' AND BomPresent = 1",
        "WHERE IsValid = 1 AND EncodingDetected = N'UTF-16-LE' AND BomPresent = 1 AND BytesRead = 76\n"
        "         AND Content LIKE N'%UTF-16-LE korrigiert.%'",
        1,
    )
    marker = "PRINT N'File Content Contract-Test: erfolgreich';"
    negative_tests = """DELETE FROM @TextResult;

SET @FixturePath = @FixtureRoot + N'/utf16be-bom.txt';
INSERT INTO @TextResult
EXEC toolbelt_file.USP_LoadTextFile @FilePath = @FixturePath;

IF NOT EXISTS
   (
       SELECT 1 FROM @TextResult
       WHERE IsValid = 0 AND EncodingDetected = N'UTF-16-BE'
         AND BomPresent = 1 AND ValidationCode = 51325 AND BytesRead > 0
   )
    THROW 52936, N'UTF-16-BE-BOM wurde nicht kontrolliert abgelehnt.', 1;

DELETE FROM @TextResult;

SET @FixturePath = @FixtureRoot + N'/utf32le-bom.txt';
INSERT INTO @TextResult
EXEC toolbelt_file.USP_LoadTextFile @FilePath = @FixturePath;

IF NOT EXISTS
   (
       SELECT 1 FROM @TextResult
       WHERE IsValid = 0 AND EncodingDetected = N'UTF-32-LE'
         AND BomPresent = 1 AND ValidationCode = 51325 AND BytesRead > 0
   )
    THROW 52936, N'UTF-32-LE-BOM wurde nicht korrekt erkannt.', 1;

DELETE FROM @TextResult;

SET @FixturePath = @FixtureRoot + N'/utf32be-bom.txt';
INSERT INTO @TextResult
EXEC toolbelt_file.USP_LoadTextFile @FilePath = @FixturePath;

IF NOT EXISTS
   (
       SELECT 1 FROM @TextResult
       WHERE IsValid = 0 AND EncodingDetected = N'UTF-32-BE'
         AND BomPresent = 1 AND ValidationCode = 51325 AND BytesRead > 0
   )
    THROW 52936, N'UTF-32-BE-BOM wurde nicht korrekt erkannt.', 1;

PRINT N'File Content Contract-Test: erfolgreich';"""
    if marker not in text:
        raise RuntimeError("FileContent.Contract.sql: Abschlussmarker fehlt.")
    text = text.replace(marker, negative_tests, 1)
    contract.write_text(text, encoding="utf-8", newline="\n")

    runner = Path("Tests/CI/run-file-content-linux.sh")
    shell = runner.read_text(encoding="utf-8")
    setup_marker = 'echo "::add-mask::${sa_password}"\n\n'
    fixture_setup = r'''echo "::add-mask::${sa_password}"

workspace="${GITHUB_WORKSPACE:-$(pwd)}"
fixture_root="${workspace}/.runtime/file-content-fixtures"
rm -rf "${fixture_root}"
mkdir -p "${fixture_root}"
python3 - "${fixture_root}" <<'PY'
import codecs
import sys
from pathlib import Path

root = Path(sys.argv[1])
(root / "utf8-bom.txt").write_bytes(
    codecs.BOM_UTF8 + "Hallo, Welt!\r\nDies ist ein UTF-8-Test.\r\n".encode("utf-8")
)
(root / "ansi.txt").write_bytes("Hallo, Welt!\r\nANSI-Test.\r\n".encode("cp1252"))
(root / "utf16le-bom.txt").write_bytes(
    codecs.BOM_UTF16_LE
    + "Hallo, Welt!\r\nUTF-16-LE korrigiert.\r\n".encode("utf-16-le")
)
(root / "utf16be-bom.txt").write_bytes(
    codecs.BOM_UTF16_BE + "UTF-16-BE-Test".encode("utf-16-be")
)
(root / "utf32le-bom.txt").write_bytes(
    codecs.BOM_UTF32_LE + "UTF-32-LE-Test".encode("utf-32-le")
)
(root / "utf32be-bom.txt").write_bytes(
    codecs.BOM_UTF32_BE + "UTF-32-BE-Test".encode("utf-32-be")
)
(root / "sample.bin").write_bytes(bytes((0x00, 0x01, 0x02, 0xFF, 0xFE, 0x10, 0x20)))
PY

'''
    if setup_marker not in shell:
        raise RuntimeError("run-file-content-linux.sh: Setup-Marker fehlt.")
    shell = shell.replace(setup_marker, fixture_setup, 1)
    shell = shell.replace(
        "VALUES (N'/workspace/Modules/toolbelt.file.content/Tests/Runtime/fixtures', N'Runtime-Test-Fixtures');",
        "VALUES (N'/workspace/.runtime/file-content-fixtures', N'Runtime-Test-Fixtures');",
        1,
    )
    shell = shell.replace(
        'FileContent.Contract.sql -v CompatibilityLevel="${level}"',
        'FileContent.Contract.sql -v CompatibilityLevel="${level}" '
        'FixtureRoot="/workspace/.runtime/file-content-fixtures"',
        1,
    )
    runner.write_text(shell, encoding="utf-8", newline="\n")

    fixture_dir = Path(
        "Modules/toolbelt.file.content/Tests/Runtime/fixtures"
    )
    for fixture in fixture_dir.glob("*"):
        if fixture.is_file():
            fixture.unlink()

    attributes = Path(".gitattributes")
    attr_text = attributes.read_text(encoding="utf-8")
    attr_text = re.sub(
        r"\n# Runtime-Test-Fixtures für toolbelt\.file\.content.*?"
        r"Modules/toolbelt\.file\.content/Tests/Runtime/fixtures/\*    binary\n?",
        "\n",
        attr_text,
        flags=re.DOTALL,
    )
    attributes.write_text(attr_text.rstrip() + "\n", encoding="utf-8", newline="\n")

    tests_readme = Path("Modules/toolbelt.file.content/Tests/README.md")
    readme_text = tests_readme.read_text(encoding="utf-8").rstrip()
    fixture_note = (
        "Die binären Runtime-Fixtures werden durch "
        "`Tests/CI/run-file-content-linux.sh` deterministisch und bytegenau "
        "unter `.runtime/file-content-fixtures` erzeugt. Sie werden nicht in Git gespeichert."
    )
    if fixture_note not in readme_text:
        readme_text += "\n\n" + fixture_note
    tests_readme.write_text(readme_text + "\n", encoding="utf-8", newline="\n")


def main() -> int:
    workflow = WORKFLOW.read_text(encoding="utf-8")
    match = re.search(
        r"python3 - <<'PY'\n(?P<script>.*?)\n          PY\n",
        workflow,
        flags=re.DOTALL,
    )
    if match is None:
        raise RuntimeError("Eingebettetes Synchronisierungsskript wurde nicht gefunden.")

    script = "\n".join(
        line[10:] if line.startswith("          ") else line
        for line in match.group("script").splitlines()
    )

    script = script.replace(
        r'field_pattern = rf"^\| \*\*{re.escape(field)}\*\* \|.*?\|$"',
        r'field_pattern = rf"^\| \*\*{re.escape(field)}\*\* \|.*$"',
    )

    inbox_lines = [
        "# Research-Inbox erhält die tatsächlich formalisierten Providerstände.",
        'inbox = "Backlog/TOOLBELT_RESEARCH_INBOX.md"',
        "text = load(inbox)",
        "rows = (",
        '    ("RI-2026-113", "TC-2026-034", "ZIP-Archive kontrolliert extrahieren und erzeugen", status_034),',
        '    ("RI-2026-107", "TC-2026-037", "Kontrolliertes Lesen und Schreiben von Text- und Binärdateien", status_037),',
        '    ("RI-2026-108", "TC-2026-038", "Kontrolliertes Directory Listing", status_038),',
        ")",
        'insertion_marker = "\\n## Bereits vorhandene Kandidaten – zusätzliche Fundstellen\\n"',
        "for research_id, candidate, title, status in rows:",
        '    row = f"| `{research_id}` | `{candidate}` – {title} | {status} |"',
        '    pattern = rf"^\\| `{re.escape(research_id)}` \\| `{re.escape(candidate)}`.*$"',
        "    if re.search(pattern, text, flags=re.MULTILINE):",
        "        text = re.sub(pattern, row, text, count=1, flags=re.MULTILINE)",
        "    else:",
        "        if insertion_marker not in text:",
        '            raise RuntimeError("Research-Inbox-Einfügemarke fehlt.")',
        '        text = text.replace(insertion_marker, "\\n" + row + insertion_marker, 1)',
        "save(inbox, text)",
        "",
    ]
    inbox_replacement = "\n".join(inbox_lines)
    script, changes = re.subn(
        r"# Research-Inbox muss exakt.*?save\(inbox, text\)\n",
        lambda _match: inbox_replacement,
        script,
        count=1,
        flags=re.DOTALL,
    )
    if changes != 1:
        raise RuntimeError("Research-Inbox-Transformationsblock wurde nicht gefunden.")

    exec(compile(script, str(WORKFLOW), "exec"), {"__name__": "__main__"})
    patch_file_content_runtime()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
