"""Erzeugt den gebundenen, dateifreien SSIS-T-SQL-Installationsbatch."""
from __future__ import annotations

import hashlib
import io
import json
import os
from pathlib import Path, PurePosixPath
import re
import stat
import zipfile

ROOT = Path(__file__).resolve().parents[2]
PACKAGE = Path("Modules/toolbelt.tsql.ssis-debug/InstallPackages/SSIS-Debug-1.0.0-Install-Windows.zip")
PACKAGE_SIDECAR = Path(str(PACKAGE) + ".sha256")
PACKAGE_QUALIFICATION = Path("Modules/toolbelt.tsql.ssis-debug/Tests/Qualification/LookupRoles.InstallPackage.20261025.json")
PACKAGE_QUALIFICATION_SHA256 = "6FBF48508A1F13BB9F629353BBCE8908DC729C9AD2E7779B3C689DBFB62A692F"
OUTPUT = Path("Releases/1.0.0/SSIS-INSTALL-TSQL.sql")
GUIDE = Path("Releases/1.0.0/SSIS-INSTALL-TSQL.md")
PROVENANCE = Path("Releases/1.0.0/ssis-standalone-installer.json")
LICENSE_COPY = Path("Releases/1.0.0/SSIS-INSTALL-TSQL-LICENSE.md")
SCRIPTDOM_NOTICE = Path("Releases/1.0.0/ThirdParty/ScriptDom-180.117.0")
MAX_PACKAGE_BYTES = 64 * 1024 * 1024
MAX_UNCOMPRESSED_BYTES = 128 * 1024 * 1024

ARCHIVE_ROOT = "SSIS-Debug-1.0.0-Install-Windows/"
RESULT_DEPLOY = "Modules/toolbelt.core.result-table/Deployment/Deploy.sql"
PARSER_DEPLOY = "Modules/toolbelt.tsql.script-parser/Artifacts/Deploy.WithAssembly.sql"
SSIS_DEPLOY = "Modules/toolbelt.tsql.ssis-debug/Artifacts/Deploy.WithAssembly.sql"
DLLS = {
    "parser": "Modules/toolbelt.tsql.script-parser/Artifacts/Toolbelt.Tsql.ScriptParser.dll",
    "scriptdom": "Modules/toolbelt.tsql.script-parser/Artifacts/Microsoft.SqlServer.TransactSql.ScriptDom.dll",
    "ssis": "Modules/toolbelt.tsql.ssis-debug/Artifacts/Toolbelt.Tsql.SsisDebug.dll",
}
TRUST_MANIFESTS = {
    "parser": "Modules/toolbelt.tsql.script-parser/Artifacts/Toolbelt.Tsql.ScriptParser.trust-manifest.json",
    "ssis": "Modules/toolbelt.tsql.ssis-debug/Artifacts/Toolbelt.Tsql.SsisDebug.trust-manifest.json",
}
INCLUDE_ALLOWLIST = {
    RESULT_DEPLOY: {
        "../Source/SchemaTrustPreflight.sql": "Modules/toolbelt.core.result-table/Source/SchemaTrustPreflight.sql",
        "../Source/USP_PrepareResultTable.sql": "Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql",
    }
}


def sha(data: bytes, algorithm: str = "sha256") -> str:
    return hashlib.new(algorithm, data).hexdigest().upper()


def safe_zip(zf: zipfile.ZipFile) -> dict[str, zipfile.ZipInfo]:
    entries: dict[str, zipfile.ZipInfo] = {}
    for info in zf.infolist():
        name = info.filename
        path = PurePosixPath(name)
        mode = info.external_attr >> 16
        if (name in entries or name.startswith("/") or "\\" in name or
                any(part in ("", ".", "..") for part in path.parts) or
                stat.S_ISLNK(mode) or (mode and not (stat.S_ISREG(mode) or stat.S_ISDIR(mode)))):
            raise ValueError("PACKAGE_ENTRY_UNSAFE")
        entries[name] = info
    return entries


def regular_input_size(path: Path) -> int:
    metadata = path.lstat()
    reparse_attribute = getattr(stat, "FILE_ATTRIBUTE_REPARSE_POINT", 0x400)
    if not stat.S_ISREG(metadata.st_mode) or getattr(metadata, "st_file_attributes", 0) & reparse_attribute:
        raise ValueError("PACKAGE_INPUT_NOT_REGULAR")
    return metadata.st_size


def read_regular_bounded(path: Path, maximum: int) -> bytes:
    expected_size = regular_input_size(path)
    if expected_size > maximum:
        raise ValueError("PACKAGE_INPUT_SIZE_LIMIT")
    with path.open("rb") as stream:
        opened = os.fstat(stream.fileno())
        if (not stat.S_ISREG(opened.st_mode) or opened.st_size != expected_size or
                getattr(opened, "st_file_attributes", 0) & getattr(stat, "FILE_ATTRIBUTE_REPARSE_POINT", 0x400)):
            raise ValueError("PACKAGE_INPUT_CHANGED_DURING_OPEN")
        data = stream.read(maximum + 1)
    if len(data) != expected_size or len(data) > maximum:
        raise ValueError("PACKAGE_INPUT_CHANGED_DURING_READ")
    return data


def read_inputs() -> tuple[dict[str, bytes], dict[str, str], dict[str, str], str]:
    package_path = ROOT / PACKAGE
    package_size = regular_input_size(package_path)
    if package_size <= 0 or package_size > MAX_PACKAGE_BYTES:
        raise ValueError("PACKAGE_SIZE_LIMIT")
    package_bytes = read_regular_bounded(package_path, MAX_PACKAGE_BYTES)
    if len(package_bytes) != package_size:
        raise ValueError("PACKAGE_CHANGED_DURING_READ")
    package_hash = sha(package_bytes)
    qualification_path = ROOT / PACKAGE_QUALIFICATION
    qualification_bytes = read_regular_bounded(qualification_path, 1024 * 1024)
    if sha(qualification_bytes) != PACKAGE_QUALIFICATION_SHA256:
        raise ValueError("PACKAGE_QUALIFICATION_SOURCE_DRIFT")
    qualification = json.loads(qualification_bytes)
    sidecar_path = ROOT / PACKAGE_SIDECAR
    sidecar = read_regular_bounded(sidecar_path, 256).decode("ascii", errors="strict").split()[0].upper()
    if (package_hash.lower() != qualification.get("package_sha256") or
            package_hash != sidecar or qualification.get("result") != "PASS" or
            qualification.get("publication_authorized") is not False):
        raise ValueError("QUALIFIED_PACKAGE_BINDING_INVALID")
    with zipfile.ZipFile(io.BytesIO(package_bytes)) as zf:
        entries = safe_zip(zf)
        if sum(info.file_size for info in entries.values()) > MAX_UNCOMPRESSED_BYTES:
            raise ValueError("PACKAGE_EXPANDED_SIZE_LIMIT")
        prefix = ARCHIVE_ROOT
        manifest_name = prefix + "PACKAGE-MANIFEST.json"
        sums_name = prefix + "SHA256SUMS.txt"
        if manifest_name not in entries or sums_name not in entries:
            raise ValueError("PACKAGE_MANIFEST_MISSING")
        manifest = json.loads(zf.read(manifest_name))
        if sorted((item["id"], item["version"]) for item in manifest["modules"]) != sorted([
            ("toolbelt.core.result-table", "1.0.0"),
            ("toolbelt.tsql.script-parser", "2.0.1"),
            ("toolbelt.tsql.ssis-debug", "1.0.0"),
        ]):
            raise ValueError("PACKAGE_MODULE_SET_INVALID")
        manifest_files = {item["path"]: item for item in manifest["files"]}
        if len(manifest_files) != len(manifest["files"]):
            raise ValueError("PACKAGE_MANIFEST_DUPLICATE")
        required = {
            RESULT_DEPLOY,
            "Modules/toolbelt.core.result-table/Source/SchemaTrustPreflight.sql",
            "Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql",
            PARSER_DEPLOY, SSIS_DEPLOY,
            *DLLS.values(), *TRUST_MANIFESTS.values(),
            "LICENSE.md",
            "ThirdParty/ScriptDom-180.117.0/LICENSE",
            "ThirdParty/ScriptDom-180.117.0/NOTICE.txt",
            "ThirdParty/ScriptDom-180.117.0/ORIGIN.txt",
            "ThirdParty/ScriptDom-180.117.0/package.nuspec",
            "ThirdParty/ScriptDom-180.117.0/README.md",
        }
        sha_lines = {}
        for line in zf.read(sums_name).decode("utf-8", errors="strict").splitlines():
            match = re.fullmatch(r"([0-9A-Fa-f]{64})  (.+)", line)
            if match:
                if match.group(2) in sha_lines:
                    raise ValueError("PACKAGE_SUMS_DUPLICATE")
                sha_lines[match.group(2)] = match.group(1).upper()
        payloads: dict[str, bytes] = {}
        source_hashes: dict[str, str] = {}
        for rel in sorted(required):
            entry = prefix + rel
            if entry not in entries:
                raise ValueError("PACKAGE_REQUIRED_ENTRY_MISSING")
            data = zf.read(entry)
            source_hashes[rel] = sha(data)
            manifest_item = manifest_files.get(rel)
            if (manifest_item is None or manifest_item.get("bytes") != len(data) or
                    manifest_item.get("sha256", "").upper() != source_hashes[rel] or
                    sha_lines.get(rel) != source_hashes[rel]):
                raise ValueError("PACKAGE_INPUT_HASH_INVALID")
            payloads[rel] = data
        for key, rel in DLLS.items():
            payloads[key + "_dll"] = payloads.pop(rel)
        for key, rel in TRUST_MANIFESTS.items():
            payloads[key + "_trust"] = payloads.pop(rel)
        return payloads, source_hashes, {item["path"]: item["sha256"].upper() for item in manifest["files"]}, package_hash


def decode_sql(data: bytes) -> str:
    text = data.decode("utf-8", errors="strict")
    if "\r" in text.replace("\r\n", ""):
        raise ValueError("SOURCE_BARE_CR")
    return text.replace("\r\n", "\n")


def expand_fixed_includes(rel: str, text: str, payloads: dict[str, bytes]) -> str:
    allow = INCLUDE_ALLOWLIST.get(rel, {})
    seen: list[str] = []

    def replace(match: re.Match[str]) -> str:
        include = match.group(1).strip()
        target = allow.get(include)
        if target is None or include in seen:
            raise ValueError("UNAPPROVED_SQL_INCLUDE")
        seen.append(include)
        return decode_sql(payloads[target])

    expanded = re.sub(r"(?m)^:r[ \t]+([^\n]+)[ \t]*$", replace, text)
    if set(seen) != set(allow):
        raise ValueError("SQL_INCLUDE_SET_INVALID")
    return expanded


def scan_sql_line(line: str, state: dict[str, object]) -> bool:
    state["line_comment"] = False
    i = 0
    has_variable = False
    while i < len(line):
        if state["line_comment"]:
            break
        quote = state["quote"]
        if quote is not None:
            if quote in ("'", '"') and line[i] == quote:
                if i + 1 < len(line) and line[i + 1] == quote:
                    i += 2
                    continue
                state["quote"] = None
            elif quote == "[" and line[i] == "]":
                if i + 1 < len(line) and line[i + 1] == "]":
                    i += 2
                    continue
                state["quote"] = None
            i += 1
            continue
        if state["block_depth"]:
            if line.startswith("/*", i):
                state["block_depth"] += 1
                i += 2
            elif line.startswith("*/", i):
                state["block_depth"] -= 1
                i += 2
            else:
                i += 1
            continue
        if line.startswith("--", i):
            state["line_comment"] = True
            break
        if line.startswith("/*", i):
            state["block_depth"] += 1
            i += 2
        elif line.startswith("$(", i):
            has_variable = True
            i += 2
        elif line[i] == "'":
            state["quote"] = "'"
            i += 1
        elif line[i] == '"':
            state["quote"] = '"'
            i += 1
        elif line[i] == "[":
            state["quote"] = "["
            i += 1
        else:
            i += 1
    return has_variable


def split_go(text: str, expected: int) -> list[str]:
    lines = text.split("\n")
    boundaries: list[int] = []
    state: dict[str, object] = {"quote": None, "block_depth": 0, "line_comment": False}
    for index, line in enumerate(lines):
        state["line_comment"] = False
        if (state["quote"] is None and state["block_depth"] == 0 and
                not state["line_comment"] and re.fullmatch(r"[ \t]*GO[ \t]*", line, re.IGNORECASE)):
            boundaries.append(index)
            continue
        scan_sql_line(line, state)
    if state["quote"] is not None or state["block_depth"] != 0:
        raise ValueError("SQL_LEXICAL_STATE_INVALID")
    if len(boundaries) != expected:
        raise ValueError("SQL_BATCH_BOUNDARIES_INVALID")
    result: list[str] = []
    start = 0
    for boundary in boundaries:
        result.append("\n".join(lines[start:boundary]).strip("\n"))
        start = boundary + 1
    result.append("\n".join(lines[start:]).strip("\n"))
    return result


def remove_sqlcmd_header(text: str) -> str:
    lines = text.split("\n")
    first_content = next((i for i, line in enumerate(lines) if line.strip()), None)
    if first_content is not None and re.fullmatch(r"[ \t]*:On Error exit[ \t]*", lines[first_content], re.IGNORECASE):
        del lines[first_content]
    result = "\n".join(lines)
    state: dict[str, object] = {"quote": None, "block_depth": 0, "line_comment": False}
    for line in result.split("\n"):
        state["line_comment"] = False
        plain = state["quote"] is None and state["block_depth"] == 0 and not state["line_comment"]
        if (plain and re.match(r"^[ \t]*:(?:r|setvar|On Error)\b", line, re.IGNORECASE)) or scan_sql_line(line, state):
            raise ValueError("SQLCMD_SYNTAX_REMAINS")
    if state["quote"] is not None or state["block_depth"] != 0:
        raise ValueError("SQL_LEXICAL_STATE_INVALID")
    return result


def escaped_sql_literal(text: str) -> str:
    return text.replace("'", "''")


def emit_string_builder(variable: str, text: str, indent: str = "") -> list[str]:
    # Kleine Literale bleiben unter der T-SQL-Literalgrenze; ein CAST im
    # Ausdruck verhindert, dass Zwischenwerte auf nvarchar(4000) gekürzt werden.
    chunks: list[str] = []
    current = ""
    for character in text:
        token = "''" if character == "'" else character
        if len(current) + len(token) > 1800:
            chunks.append(current)
            current = ""
        current += token
    if current or not chunks:
        chunks.append(current)
    lines = [f"{indent}DECLARE {variable} nvarchar(max) = N'';"]
    for offset in range(0, len(chunks), 20):
        group = chunks[offset:offset + 20]
        terms = [f"CAST(N'{group[0]}' AS nvarchar(max))"]
        terms.extend(f"N'{part}'" for part in group[1:])
        lines.append(f"{indent}SET {variable} = {variable} + " + " + ".join(terms) + ";")
    return lines


def append_license_comment(lines: list[str], label: str, data: bytes) -> None:
    text = decode_sql(data)
    if not text.endswith("\n"):
        raise ValueError("LICENSE_TERMINATOR_INVALID")
    lines.append(f"-- BEGIN LICENSE TEXT: {label}")
    lines.extend("-- " + line for line in text[:-1].split("\n"))
    lines.append(f"-- END LICENSE TEXT: {label}")


def emit_binary_initializer(variable: str, binary: bytes, indent: str = "") -> list[str]:
    # Kleine Gruppen vermeiden einen riesigen Konstantenausdruck im Parser.
    # Der erste Term jeder Gruppe ist explizit varbinary(max).
    chunks = [binary[offset:offset + 4000] for offset in range(0, len(binary), 4000)]
    if not chunks:
        raise ValueError("EMPTY_EMBEDDED_BINARY")
    lines = [f"{indent}DECLARE {variable} varbinary(max) = CONVERT(varbinary(max),0x);"]
    for offset in range(0, len(chunks), 20):
        group = chunks[offset:offset + 20]
        terms = [f"CAST(0x{group[0].hex().upper()} AS varbinary(max))"]
        terms.extend(f"0x{chunk.hex().upper()}" for chunk in group[1:])
        lines.append(f"{indent}SET {variable} = {variable} + " + " + ".join(terms) + ";")
    return lines


def validate_binary_initializer(variable: str, lines: list[str], expected: bytes | None = None) -> bytes:
    if not lines or lines[0] != f"DECLARE {variable} varbinary(max) = CONVERT(varbinary(max),0x);":
        raise ValueError("BINARY_INITIALIZER_SCOPE_INVALID")
    chunks: list[str] = []
    prefix = f"SET {variable} = {variable} + CAST(0x"
    for line in lines[1:]:
        if "\r" in line or "\n" in line or not line.startswith(prefix) or not line.endswith(";"):
            raise ValueError("BINARY_INITIALIZER_GROUP_INVALID")
        expression = line[len(prefix):-1]
        first, separator, rest = expression.partition(" AS varbinary(max))")
        if not separator or not re.fullmatch(r"[0-9A-F]+", first):
            raise ValueError("BINARY_INITIALIZER_GROUP_INVALID")
        literal_groups = [first]
        if rest:
            matches = re.findall(r" \+ 0x([0-9A-F]+)", rest)
            expected_rest = "".join(f" + 0x{chunk}" for chunk in matches)
            if rest != expected_rest:
                raise ValueError("BINARY_INITIALIZER_GROUP_INVALID")
            literal_groups.extend(matches)
        if not literal_groups or len(literal_groups) > 20:
            raise ValueError("BINARY_INITIALIZER_GROUP_INVALID")
        chunks.extend(literal_groups)
        if any(len(chunk) > 8000 or len(chunk) % 2 for chunk in literal_groups):
            raise ValueError("BINARY_INITIALIZER_CHUNK_INVALID")
    if not chunks:
        raise ValueError("BINARY_INITIALIZER_EMPTY")
    value = bytes.fromhex("".join(chunks))
    if expected is not None and value != expected:
        raise ValueError("BINARY_INITIALIZER_BYTES_MISMATCH")
    return value


def replace_single_binary(text: str, binary: bytes, parameter: str) -> str:
    literal = "0x" + binary.hex().upper()
    if text.count(literal) != 1:
        raise ValueError("EMBEDDED_BINARY_SOURCE_BINDING_INVALID")
    return text.replace(literal, parameter)


def get_hashes(payloads: dict[str, bytes]) -> dict[str, str]:
    parser_manifest = json.loads(payloads["parser_trust"])
    ssis_manifest = json.loads(payloads["ssis_trust"])
    checks = {
        "Parser": (payloads["parser_dll"], parser_manifest.get("sha512")),
        "ScriptDom": (payloads["scriptdom_dll"], parser_manifest.get("scriptDomSha512")),
        "Ssis": (payloads["ssis_dll"], ssis_manifest.get("sha512")),
    }
    result: dict[str, str] = {}
    for name, (data, expected) in checks.items():
        actual = sha(data, "sha512")
        if actual != (expected or "").upper():
            raise ValueError("QUALIFIED_DLL_HASH_INVALID")
        result[name] = actual
    if (ssis_manifest.get("moduleId") != "toolbelt.tsql.ssis-debug" or
            ssis_manifest.get("moduleVersion") != "1.0.0" or
            parser_manifest.get("moduleId") != "toolbelt.tsql.script-parser" or
            parser_manifest.get("moduleVersion") != "2.0.1"):
        raise ValueError("DLL_TRUST_MANIFEST_INVALID")
    return result


def validate_result_table_temp_scope(first_batch: str, final_batch: str, stage: str, outer_call: str) -> None:
    temp_tables = ("#tbx_ResultTableReleaseObjects", "#tbx_ResultTableDeployState")
    outer_parameters = (
        "@ResultTableProcedure nvarchar(max), @RequestedDeploymentMode nvarchar(16), "
        "@ResultTableAnsi nvarchar(max), @ResultTableQuotedIdentifier nvarchar(max), "
        "@ResultTableFinalize nvarchar(max)"
    )
    outer_arguments = (
        "@ResultTableProcedure=@ResultTableProcedure, @RequestedDeploymentMode=@DeploymentMode, "
        "@ResultTableAnsi=@ResultTableAnsi, @ResultTableQuotedIdentifier=@ResultTableQuotedIdentifier, "
        "@ResultTableFinalize=@ResultTableFinalize"
    )
    calls = (
        "EXEC sys.sp_executesql @ResultTableAnsi;",
        "EXEC sys.sp_executesql @ResultTableQuotedIdentifier;",
        "EXEC sys.sp_executesql N'SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; EXEC sys.sp_executesql @ddl;'",
        "EXEC sys.sp_executesql @ResultTableFinalize;",
    )
    positions = [stage.find(call) for call in calls]
    if (not all(f"CREATE TABLE {name}" in first_batch for name in temp_tables) or
            "#tbx_ResultTableDeployState" not in final_batch or
            "BEGIN TRANSACTION;" not in first_batch or
            final_batch.count("COMMIT TRANSACTION;") != 1 or
            final_batch.count("ROLLBACK TRANSACTION;") != 1 or
            stage.count("COMMIT TRANSACTION;") != 1 or
            stage.count("ROLLBACK TRANSACTION;") != 2 or
            stage.find("COMMIT TRANSACTION;") < positions[-1] or
            not stage.startswith("BEGIN TRY\n") or
            "BEGIN CATCH\n    IF XACT_STATE() <> 0\n    BEGIN\n        ROLLBACK TRANSACTION;\n    END;\n    THROW;\nEND CATCH;" not in stage or
            outer_parameters not in outer_call or outer_arguments not in outer_call or
            any(stage.count(call) != 1 for call in calls) or
            positions != sorted(positions)):
        raise ValueError("RESULT_TABLE_TEMP_SCOPE_INVALID")


def move_result_table_transaction_control(finalizer: str) -> str:
    commit = "    COMMIT TRANSACTION;"
    rollback = "    IF XACT_STATE() <> 0\n    BEGIN\n        ROLLBACK TRANSACTION;\n    END;"
    if finalizer.count(commit) != 1 or finalizer.count(rollback) != 1:
        raise ValueError("RESULT_TABLE_FINALIZER_TRANSACTION_LAYOUT_INVALID")
    result = finalizer.replace(commit, "", 1).replace(rollback, "", 1)
    if result.count("COMMIT TRANSACTION;") or result.count("ROLLBACK TRANSACTION;") != 0:
        raise ValueError("RESULT_TABLE_FINALIZER_TRANSACTION_LAYOUT_INVALID")
    return result


def move_parser_transaction_control(finalizer: str) -> str:
    commit = "    COMMIT TRANSACTION;"
    rollback = "    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;"
    if finalizer.count(commit) != 1 or finalizer.count(rollback) != 1:
        raise ValueError("PARSER_FINALIZER_TRANSACTION_LAYOUT_INVALID")
    result = finalizer.replace(commit, "", 1).replace(rollback, "", 1)
    if "COMMIT TRANSACTION;" in result or "ROLLBACK TRANSACTION;" in result:
        raise ValueError("PARSER_FINALIZER_TRANSACTION_LAYOUT_INVALID")
    return result


def build_result_table_stage(first_batch: str, finalizer: str) -> str:
    if "COMMIT TRANSACTION;" in finalizer or "ROLLBACK TRANSACTION;" in finalizer:
        raise ValueError("RESULT_TABLE_FINALIZER_TRANSACTION_SCOPE_INVALID")
    calls = "\n".join((
        "EXEC sys.sp_executesql @ResultTableAnsi;",
        "EXEC sys.sp_executesql @ResultTableQuotedIdentifier;",
        "EXEC sys.sp_executesql N'SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; EXEC sys.sp_executesql @ddl;', N'@ddl nvarchar(max)', @ddl=@ResultTableProcedure;",
        "EXEC sys.sp_executesql @ResultTableFinalize;",
        "COMMIT TRANSACTION;",
    ))
    return "\n".join((
        "BEGIN TRY",
        first_batch.rstrip(),
        calls,
        "END TRY",
        "BEGIN CATCH",
        "    IF XACT_STATE() <> 0",
        "    BEGIN",
        "        ROLLBACK TRANSACTION;",
        "    END;",
        "    THROW;",
        "END CATCH;",
    )) + "\n"


def build_parser_stage(prefix: str, function_calls: list[str], finalizer: str) -> str:
    if "COMMIT TRANSACTION;" in finalizer or "ROLLBACK TRANSACTION;" in finalizer:
        raise ValueError("PARSER_FINALIZER_TRANSACTION_SCOPE_INVALID")
    body = "\n".join((prefix.rstrip(), *function_calls,
                       "EXEC sys.sp_executesql @ParserFinalize, N'@RequestedDeploymentMode nvarchar(16)', @RequestedDeploymentMode=@RequestedDeploymentMode;",
                       "COMMIT TRANSACTION;"))
    return "\n".join((
        "BEGIN TRY",
        body,
        "END TRY",
        "BEGIN CATCH",
        "    IF XACT_STATE() <> 0",
        "    BEGIN",
        "        ROLLBACK TRANSACTION;",
        "    END;",
        "    THROW;",
        "END CATCH;",
    )) + "\n"


def validate_parser_transaction_scope(prefix: str, finalizer: str, stage: str) -> None:
    finalize_call = "EXEC sys.sp_executesql @ParserFinalize, N'@RequestedDeploymentMode nvarchar(16)', @RequestedDeploymentMode=@RequestedDeploymentMode;"
    begin = "BEGIN TRANSACTION;"
    commit = "COMMIT TRANSACTION;"
    rollback = "IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;"
    if (prefix.count(begin) != 1 or finalizer.count(commit) != 1 or finalizer.count(rollback) != 1 or
            stage.count(finalize_call) != 1 or stage.count(commit) != 1 or stage.count("ROLLBACK TRANSACTION;") != 2 or stage.find(commit) < stage.find(finalize_call) or
            "BEGIN TRY\n" + prefix.rstrip() not in stage or
            "BEGIN CATCH\n    IF XACT_STATE() <> 0\n    BEGIN\n        ROLLBACK TRANSACTION;\n    END;\n    THROW;\nEND CATCH;" not in stage):
        raise ValueError("PARSER_TRANSACTION_SCOPE_INVALID")


def validate_installer_guards(sql: bytes) -> None:
    text = sql.decode("utf-8", errors="strict")
    caller_guard = (
        "IF @@TRANCOUNT <> 0 OR (@@OPTIONS & 2) <> 0\nBEGIN\n"
        "    RAISERROR(N'TBX_SSIS_INSTALL_SESSION: Frische Sitzung ohne Callertransaktion erforderlich.',16,1);\n"
        "    RETURN;\nEND;"
    )
    temp_guard = (
        "IF OBJECT_ID(N'tempdb..#tbx_ResultTableReleaseObjects') IS NOT NULL OR "
        "OBJECT_ID(N'tempdb..#tbx_ResultTableDeployState') IS NOT NULL\nBEGIN\n"
        "    RAISERROR(N'TBX_SSIS_INSTALL_TEMP_SCOPE: Reservierte ResultTable-Tempnamen sind bereits belegt.',16,1);\n"
        "    RETURN;\nEND;"
    )
    required = (
        caller_guard,
        "IF @DeploymentMode IS NULL OR @DeploymentMode NOT IN (N'local',N'central')",
        "IF @ParserDll IS NULL OR @ScriptDomDll IS NULL OR @SsisDll IS NULL OR HASHBYTES(N'SHA2_512', @ParserDll)",
        "IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;",
    )
    if (any(token not in text for token in required) or text.count(caller_guard) != 1 or text.count(temp_guard) != 1 or
            text.index(caller_guard) > text.index("SET NOCOUNT ON;") or
            text.index(caller_guard) > text.index(temp_guard) or
            text.index(temp_guard) > text.index("SET NOCOUNT ON;") or
            text.index(caller_guard) > text.index("SET XACT_ABORT ON;") or
            "TBX_SSIS_INSTALL_SESSION: Frische Sitzung ohne Callertransaktion erforderlich.', 1" in text):
        raise ValueError("INSTALLER_GUARD_CONTRACT_INVALID")


def render(payloads: dict[str, bytes], hashes: dict[str, str]) -> bytes:
    result_text = expand_fixed_includes(RESULT_DEPLOY, decode_sql(payloads[RESULT_DEPLOY]), payloads)
    result_text = remove_sqlcmd_header(result_text.replace("N'$(DeploymentMode)'", "@RequestedDeploymentMode"))
    result_batches = split_go(result_text, 5)
    if result_batches[-1].strip():
        raise ValueError("RESULT_TABLE_TRAILING_BATCH_UNEXPECTED")
    if len(result_batches) != 6 or not re.search(r"(?im)^\s*SET ANSI_NULLS ON;\s*$", result_batches[1]) or not re.search(r"(?im)^\s*SET QUOTED_IDENTIFIER ON;\s*$", result_batches[2]) or not re.search(r"(?is)^\s*CREATE OR ALTER PROCEDURE\b", result_batches[3]):
        raise ValueError("RESULT_TABLE_BATCH_LAYOUT_INVALID")
    result_finalize = move_result_table_transaction_control(result_batches[4])
    result_main = build_result_table_stage(result_batches[0], result_finalize)
    result_ansi, result_quoted, result_proc = result_batches[1:4]
    result_outer_call = "EXEC sys.sp_executesql @ResultTableStage, N'@ResultTableProcedure nvarchar(max), @RequestedDeploymentMode nvarchar(16), @ResultTableAnsi nvarchar(max), @ResultTableQuotedIdentifier nvarchar(max), @ResultTableFinalize nvarchar(max)', @ResultTableProcedure=@ResultTableProcedure, @RequestedDeploymentMode=@DeploymentMode, @ResultTableAnsi=@ResultTableAnsi, @ResultTableQuotedIdentifier=@ResultTableQuotedIdentifier, @ResultTableFinalize=@ResultTableFinalize;"
    validate_result_table_temp_scope(result_batches[0], result_batches[4], result_main, result_outer_call)

    parser_text = decode_sql(payloads[PARSER_DEPLOY]).replace("N'$(DeploymentMode)'", "@RequestedDeploymentMode")
    parser_text = remove_sqlcmd_header(parser_text)
    parser_text = replace_single_binary(parser_text, payloads["parser_dll"], "@ParserDll")
    parser_text = replace_single_binary(parser_text, payloads["scriptdom_dll"], "@ScriptDomDll")
    parser_batches = split_go(parser_text, 14)
    if len(parser_batches) != 15 or parser_batches[-1].strip():
        raise ValueError("PARSER_BATCH_LAYOUT_INVALID")
    function_indexes = [i for i, batch in enumerate(parser_batches) if re.search(r"(?is)^\s*CREATE FUNCTION\b", batch)]
    if len(function_indexes) != 4 or function_indexes != [3, 6, 9, 12]:
        raise ValueError("PARSER_FUNCTION_BATCH_LAYOUT_INVALID")
    parser_prefix = parser_batches[0]
    parser_final = move_parser_transaction_control(parser_batches[13])
    function_calls = []
    for index in function_indexes:
        function_sql = parser_batches[index].strip()
        function_calls.extend([
            "SET ANSI_NULLS ON;",
            "SET QUOTED_IDENTIFIER ON;",
            "EXEC sys.sp_executesql N'" + escaped_sql_literal(function_sql) + "';",
        ])
    parser_main = build_parser_stage(parser_prefix, function_calls, parser_final)
    validate_parser_transaction_scope(parser_batches[0], parser_batches[13], parser_main)

    ssis_text = decode_sql(payloads[SSIS_DEPLOY]).replace("N'$(DeploymentMode)'", "@RequestedDeploymentMode")
    ssis_text = remove_sqlcmd_header(ssis_text)
    ssis_text = replace_single_binary(ssis_text, payloads["ssis_dll"], "@SsisDll")
    if re.search(r"(?m)^\s*GO\s*$", ssis_text, re.IGNORECASE):
        raise ValueError("SSIS_DEPLOY_BATCH_BOUNDARY_UNEXPECTED")

    lines = [
        "/*",
        "  Toolbelt SSIS-Debug 1.0.0 – eigenständiger T-SQL-Installer.",
        "  Installiert nur in die bereits ausgewählte aktuelle Datenbank.",
        "  Keine SQLCMD-Direktiven, GO-Batchtrenner oder Laufzeit-Dateipfade.",
        "  Die exakten qualifizierten DLLs sind je einmal eingebettet.",
        "  Lizenz- und Herkunftshinweise: SSIS-INSTALL-TSQL-LICENSE.md.",
        "  Dieser Batch erzeugt keine SSISDB-/SSIS-Katalogobjekte oder externen Exporte.",
        "*/",
    ]
    append_license_comment(lines, "Toolbelt LICENSE.md", payloads["LICENSE.md"])
    append_license_comment(lines, "Microsoft ScriptDom LICENSE", payloads["ThirdParty/ScriptDom-180.117.0/LICENSE"])
    append_license_comment(lines, "Microsoft ScriptDom and ANTLR NOTICE", payloads["ThirdParty/ScriptDom-180.117.0/NOTICE.txt"])
    lines.extend([
        "IF @@TRANCOUNT <> 0 OR (@@OPTIONS & 2) <> 0",
        "BEGIN",
        "    RAISERROR(N'TBX_SSIS_INSTALL_SESSION: Frische Sitzung ohne Callertransaktion erforderlich.',16,1);",
        "    RETURN;",
        "END;",
        "IF OBJECT_ID(N'tempdb..#tbx_ResultTableReleaseObjects') IS NOT NULL OR OBJECT_ID(N'tempdb..#tbx_ResultTableDeployState') IS NOT NULL",
        "BEGIN",
        "    RAISERROR(N'TBX_SSIS_INSTALL_TEMP_SCOPE: Reservierte ResultTable-Tempnamen sind bereits belegt.',16,1);",
        "    RETURN;",
        "END;",
        "SET NOCOUNT ON;",
        "SET XACT_ABORT ON;",
        "DECLARE @DeploymentMode nvarchar(16)=N'local'; -- Zulässig sind local oder central.",
        "SET @DeploymentMode=LOWER(@DeploymentMode);",
        "IF @DeploymentMode IS NULL OR @DeploymentMode NOT IN (N'local',N'central') THROW 50000, N'TBX_SSIS_INSTALL_MODE: DeploymentMode muss local oder central sein.', 1;",
        "IF DB_ID() IS NULL OR DB_ID() <= 4 OR DB_NAME() IS NULL",
        "    THROW 50000, N'TBX_SSIS_INSTALL_DATABASE: Zuerst eine eigene Installationsdatenbank auswählen.', 1;",
        "IF TRY_CONVERT(int, SERVERPROPERTY(N'ProductMajorVersion')) IS NULL",
        "   OR TRY_CONVERT(int, SERVERPROPERTY(N'ProductMajorVersion')) NOT IN (15, 16, 17)",
        "   OR NOT EXISTS (SELECT 1 FROM sys.dm_os_host_info WITH (NOLOCK) WHERE host_platform = N'Windows')",
        "    THROW 50000, N'TBX_SSIS_INSTALL_PLATFORM: Windows SQL Server 2019/2022/2025 erforderlich.', 1;",
        "IF (SELECT compatibility_level FROM sys.databases WITH (NOLOCK) WHERE database_id = DB_ID()) IS NULL",
        "   OR (SELECT compatibility_level FROM sys.databases WITH (NOLOCK) WHERE database_id = DB_ID()) NOT IN (150, 160, 170)",
        "    THROW 50000, N'TBX_SSIS_INSTALL_COMPAT: Kompatibilitätslevel 150, 160 oder 170 erforderlich.', 1;",
        "IF NOT EXISTS (SELECT 1 FROM sys.configurations WITH (NOLOCK) WHERE name=N'clr enabled' AND value_in_use=1)",
        "   OR NOT EXISTS (SELECT 1 FROM sys.configurations WITH (NOLOCK) WHERE name=N'clr strict security' AND value_in_use=1)",
        "    THROW 50000, N'TBX_SSIS_INSTALL_CLR: CLR muss aktiviert sein und Strict Security eingeschaltet bleiben.', 1;",
        "DECLARE @RegisterAssemblyTrust bit = 0; -- Nur bewusst auf 1 setzen, wenn die exakten Paket-Hashes serverweit vertraut werden sollen.",
    ])
    for variable, key in (("@ParserDll", "parser_dll"),
                          ("@ScriptDomDll", "scriptdom_dll"),
                          ("@SsisDll", "ssis_dll")):
        initializer = emit_binary_initializer(variable, payloads[key])
        validate_binary_initializer(variable, initializer, payloads[key])
        lines.extend(initializer)
    lines.extend([
        f"IF @ParserDll IS NULL OR @ScriptDomDll IS NULL OR @SsisDll IS NULL OR HASHBYTES(N'SHA2_512', @ParserDll) <> 0x{hashes['Parser']} OR HASHBYTES(N'SHA2_512', @ScriptDomDll) <> 0x{hashes['ScriptDom']} OR HASHBYTES(N'SHA2_512', @SsisDll) <> 0x{hashes['Ssis']}",
        "    THROW 50000, N'TBX_SSIS_INSTALL_BINARY: Eingebettete qualifizierte DLL stimmt nicht mit ihrem festgelegten Hash überein.', 1;",
        "IF @RegisterAssemblyTrust IS NULL",
        "    THROW 50000, N'TBX_SSIS_INSTALL_TRUST_OPTION: Trust-Opt-in muss 0 oder 1 sein.', 1;",
        "IF @RegisterAssemblyTrust=1 AND ISNULL(IS_SRVROLEMEMBER(N'sysadmin'),0)<>1",
        "    THROW 50000, N'TBX_SSIS_INSTALL_TRUST_PERMISSION: Exakter Assembly-Trust erfordert vorhandene sysadmin-Berechtigung.', 1;",
        "IF @RegisterAssemblyTrust=0 AND (",
        f"    NOT EXISTS(SELECT 1 FROM sys.trusted_assemblies WITH (NOLOCK) WHERE hash=0x{hashes['Parser']}) OR",
        f"    NOT EXISTS(SELECT 1 FROM sys.trusted_assemblies WITH (NOLOCK) WHERE hash=0x{hashes['ScriptDom']}) OR",
        f"    NOT EXISTS(SELECT 1 FROM sys.trusted_assemblies WITH (NOLOCK) WHERE hash=0x{hashes['Ssis']}))",
        "    THROW 50000, N'TBX_SSIS_INSTALL_TRUST_MISSING: Exakte DLL-Hashes fehlen im Assembly-Trust; nur bewusstes @RegisterAssemblyTrust=1 kann sie ergänzen.', 1;",
        "DECLARE @InstallerStage nvarchar(128)=N'PRECHECK';",
        "BEGIN TRY",
        "    IF @RegisterAssemblyTrust=1",
        "    BEGIN",
        "        SET @InstallerStage=N'EXACT_ASSEMBLY_TRUST';",
        f"        IF NOT EXISTS(SELECT 1 FROM sys.trusted_assemblies WITH (NOLOCK) WHERE hash=0x{hashes['Parser']}) EXEC master.sys.sp_add_trusted_assembly @hash=0x{hashes['Parser']}, @description=N'Toolbelt Script Parser 2.0.1';",
        f"        IF NOT EXISTS(SELECT 1 FROM sys.trusted_assemblies WITH (NOLOCK) WHERE hash=0x{hashes['ScriptDom']}) EXEC master.sys.sp_add_trusted_assembly @hash=0x{hashes['ScriptDom']}, @description=N'Microsoft ScriptDom 180.117.0';",
        f"        IF NOT EXISTS(SELECT 1 FROM sys.trusted_assemblies WITH (NOLOCK) WHERE hash=0x{hashes['Ssis']}) EXEC master.sys.sp_add_trusted_assembly @hash=0x{hashes['Ssis']}, @description=N'Toolbelt SSIS-Debug 1.0.0';",
        "    END;",
        "    SET @InstallerStage=N'RESULT_TABLE_1_0_0';",
    ])
    lines.extend(emit_string_builder("@ResultTableStage", result_main, "    "))
    lines.extend(emit_string_builder("@ResultTableAnsi", result_ansi, "    "))
    lines.extend(emit_string_builder("@ResultTableQuotedIdentifier", result_quoted, "    "))
    lines.extend(emit_string_builder("@ResultTableProcedure", result_proc, "    "))
    lines.extend(emit_string_builder("@ResultTableFinalize", result_finalize, "    "))
    lines.extend([
        "    " + result_outer_call,
        "    SET @InstallerStage=N'SCRIPT_PARSER_2_0_1_AND_SCRIPTDOM_180_117_0';",
    ])
    lines.extend(emit_string_builder("@ParserFinalize", parser_final, "    "))
    lines.extend(emit_string_builder("@ParserStage", parser_main, "    "))
    lines.append("    EXEC sys.sp_executesql @ParserStage, N'@ParserDll varbinary(max), @ScriptDomDll varbinary(max), @RequestedDeploymentMode nvarchar(16), @ParserFinalize nvarchar(max)', @ParserDll=@ParserDll, @ScriptDomDll=@ScriptDomDll, @RequestedDeploymentMode=@DeploymentMode, @ParserFinalize=@ParserFinalize;")
    lines.append("    SET @InstallerStage=N'SSIS_DEBUG_1_0_0';")
    lines.extend(emit_string_builder("@SsisDeployment", ssis_text, "    "))
    lines.append("    EXEC sys.sp_executesql @SsisDeployment, N'@SsisDll varbinary(max), @RequestedDeploymentMode nvarchar(16)', @SsisDll=@SsisDll, @RequestedDeploymentMode=@DeploymentMode;")
    lines.extend([
        "    SELECT N'SSIS_TSQL_INSTALL_COMPLETED' AS InstallerStatus, DB_NAME() AS TargetDatabase,",
        "           N'toolbelt.core.result-table 1.0.0; toolbelt.tsql.script-parser 2.0.1; toolbelt.tsql.ssis-debug 1.0.0' AS InstalledModules;",
        "END TRY",
        "BEGIN CATCH",
        "    DECLARE @InstallerError nvarchar(2048)=ERROR_MESSAGE();",
        "    DECLARE @InstallerNumber int=ERROR_NUMBER();",
        "    PRINT N'SSIS_TSQL_INSTALL_FAILED stage=' + @InstallerStage + N'; error=' + CONVERT(nvarchar(12),@InstallerNumber) + N'; ' + LEFT(@InstallerError,1600);",
        "    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;",
        "    THROW;",
        "END CATCH;",
        "",
    ])
    sql = "\n".join(lines).encode("utf-8")
    if re.search(rb"(?m)^\s*GO\s*$", sql, re.IGNORECASE) or re.search(rb"(?m)^\s*:(?:r|setvar|On Error)\b|\$\(", sql, re.IGNORECASE):
        raise ValueError("NON_TSQL_DIRECTIVE_REMAINS")
    for variable, binary in (("@ParserDll", payloads["parser_dll"]),
                             ("@ScriptDomDll", payloads["scriptdom_dll"]),
                             ("@SsisDll", payloads["ssis_dll"])):
        initializer = "\n".join(emit_binary_initializer(variable, binary)).encode("ascii")
        if sql.count(initializer) != 1:
            raise ValueError("DLL_NOT_EMBEDDED_EXACTLY_ONCE")
    validate_installer_guards(sql)
    return sql


def main() -> int:
    payloads, source_hashes, package_manifest_hashes, package_hash = read_inputs()
    hashes = get_hashes(payloads)
    sql = render(payloads, hashes)
    (ROOT / OUTPUT).write_bytes(sql)
    (ROOT / LICENSE_COPY).write_bytes(payloads["LICENSE.md"])
    notice_root = ROOT / SCRIPTDOM_NOTICE
    notice_root.mkdir(parents=True, exist_ok=True)
    for rel in (
        "ThirdParty/ScriptDom-180.117.0/LICENSE",
        "ThirdParty/ScriptDom-180.117.0/NOTICE.txt",
        "ThirdParty/ScriptDom-180.117.0/ORIGIN.txt",
        "ThirdParty/ScriptDom-180.117.0/package.nuspec",
        "ThirdParty/ScriptDom-180.117.0/README.md",
    ):
        (notice_root / Path(rel).name).write_bytes(payloads[rel])
    provenance = {
        "schema_version": "1.0",
        "kind": "standalone_tsql_installer_derivation",
        "publication_authorized": False,
        "scope": {
            "modules": [
                {"id": "toolbelt.core.result-table", "version": "1.0.0"},
                {"id": "toolbelt.tsql.script-parser", "version": "2.0.1"},
                {"id": "toolbelt.tsql.ssis-debug", "version": "1.0.0"},
            ],
            "target": "current_user_selected_database_only",
            "dlls": "three_exact_package_bound_dlls_embedded_once_each",
            "external_file_access": False,
            "sqlcmd_required_at_runtime": False,
            "new_builds": False,
        },
        "source_package": {
            "path": PACKAGE.as_posix(),
            "sha256": package_hash,
            "qualification": PACKAGE_QUALIFICATION.as_posix(),
            "qualification_sha256": PACKAGE_QUALIFICATION_SHA256,
            "qualification_result": "PASS",
        },
        "source_entries": {
            rel: {"sha256": source_hashes[rel], "package_manifest_sha256": package_manifest_hashes[rel]}
            for rel in sorted(source_hashes)
        },
        "dll_sha512": hashes,
        "output": {"path": OUTPUT.as_posix(), "sha256": sha(sql), "bytes": len(sql)},
        "limits": [
            "SQL Server Windows 2019/2022/2025 and compatibility 150/160/170",
            "CLR enabled and clr strict security enabled; no configuration changes",
            "Current database only; database creation and SSISDB/catalog functions are outside scope",
            "Exact server-level assembly trust is opt-in; default does not add trust",
            "Per-module stages retain their existing transaction boundaries; earlier successful stages remain on a later-stage failure",
            "DTSX package analysis and reporting are separate from this SQL CLR installer",
        ],
    }
    (ROOT / PROVENANCE).write_text(json.dumps(provenance, indent=2, ensure_ascii=False) + "\n", encoding="utf-8", newline="\n")
    print(f"generated {OUTPUT.as_posix()} bytes={len(sql)} sha256={sha(sql)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
