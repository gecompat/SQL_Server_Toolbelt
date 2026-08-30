#!/usr/bin/env python3
"""Inkrementelle Dokumentations- und Konsistenzprüfung.

Die Prüfung verwendet ausschließlich die Python-Standardbibliothek. Im
Normalbetrieb bestimmt sie den Scope aus dem Git-Diff und den in
`.ai/repo_map.yaml` registrierten Impact-Paketen. Ein vollständiger Audit wird
nur mit `--all` oder bei Änderungen an Governance und Validator ausgeführt.
"""

from __future__ import annotations

import argparse
import fnmatch
import hashlib
import os
import re
import subprocess
import sys
from pathlib import Path


# Unter Windows erben Python-Unterprozesse sonst häufig die lokale OEM-/ANSI-
# Codepage, während dieser Validator UTF-8 erwartet.
os.environ.setdefault("PYTHONIOENCODING", "utf-8")


REPOSITORY_ROOT = Path(__file__).resolve().parents[2]
REPO_MAP = REPOSITORY_ROOT / ".ai" / "repo_map.yaml"
README = REPOSITORY_ROOT / "README.md"
MODULES_README = REPOSITORY_ROOT / "Modules" / "README.md"
BRAINSTORM = "Backlog/personal_Backlog_Bainstorm.md"
GENERATED_BADGE = "MODULE_STATUS_BADGE"
GENERATED_TABLE = "MODULE_STATUS_TABLE"
CURRENT_STATUS_FILES = (
    "README.md",
    "CHANGELOG.md",
    "Modules/README.md",
    "Tests/README.md",
    ".ai/PROJECT_CONTEXT.md",
    ".ai/ROADMAP.md",
    ".ai/BACKLOG.md",
    "Backlog/TOOLBELT_CANDIDATE_IMPLEMENTATION_PLAN.md",
    "Backlog/TOOLBELT_RESEARCH_PRIORITIES.md",
)

# Geschützte Inhalte dürfen nur nach ausdrücklicher Freigabe gemeinsam mit
# diesen Baselines geändert werden.
PROTECTED_SHA256 = {
    "LICENSE.md": "b513a23d5ca4484aa6f1ce78179da5a90edc3bf7929eb5cd5c726c8c08ca6ecd",
    "README.md::license-prefix": "f6c7bc408f055e9421514e0e80b3c0585845a36ff6cc2658108de3835066d0d8",
}

ALLOWED_IMPLEMENTATION_STATUS = {
    "proposed",
    "researched",
    "planned",
    "implemented",
    "deprecated",
    "unsupported",
}
ALLOWED_VALIDATION_STATUS = {
    "validated",
    "partially validated",
    "not executed",
    "not applicable",
    "failed",
}
ALLOWED_RELEASE_STATUS = {
    "unreleased",
    "preview",
    "released",
    "deprecated",
    "withdrawn",
}


class ValidationError(AssertionError):
    """Meldet eine belastbare Konsistenzabweichung."""


def read(path: Path) -> str:
    if not path.is_file():
        raise ValidationError(
            f"Pflichtartefakt fehlt: {path.relative_to(REPOSITORY_ROOT)}"
        )
    return path.read_text(encoding="utf-8")


def run_git(*arguments: str) -> str:
    result = subprocess.run(
        ("git", "-C", str(REPOSITORY_ROOT), *arguments),
        check=False,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    if result.returncode != 0:
        raise ValidationError(
            f"Git-Aufruf fehlgeschlagen: git {' '.join(arguments)}\n"
            f"{result.stderr.strip()}"
        )
    return result.stdout


def sha256(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


def yaml_unquote(value: str) -> str:
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
        return value[1:-1]
    return value


def top_scalar(text: str, key: str) -> str:
    match = re.search(
        rf"^{re.escape(key)}:\s*(.+?)\s*$",
        text,
        re.MULTILINE,
    )
    if match is None:
        raise ValidationError(f"Manifestfeld fehlt: {key}")
    return yaml_unquote(match.group(1))


def top_list(text: str, key: str) -> list[str]:
    lines = text.splitlines()
    marker = f"{key}:"
    for index, line in enumerate(lines):
        if line == marker:
            values: list[str] = []
            for candidate in lines[index + 1 :]:
                if candidate and not candidate.startswith(" "):
                    break
                match = re.match(r"^\s{2}-\s+(.+?)\s*$", candidate)
                if match:
                    values.append(yaml_unquote(match.group(1)))
            return values
    raise ValidationError(f"Manifestliste fehlt: {key}")


def section_values(text: str, section: str) -> dict[str, str | list[str]]:
    """Liest den bewusst einfachen Map/List-Teil eines Modulmanifests."""

    lines = text.splitlines()
    marker = f"{section}:"
    for index, line in enumerate(lines):
        if line != marker:
            continue
        values: dict[str, str | list[str]] = {}
        current_list: str | None = None
        for candidate in lines[index + 1 :]:
            if candidate and not candidate.startswith(" "):
                break
            scalar_match = re.match(r"^\s{2}([A-Za-z0-9_]+):\s*(.*?)\s*$", candidate)
            if scalar_match:
                key, raw_value = scalar_match.groups()
                if raw_value:
                    values[key] = yaml_unquote(raw_value)
                    current_list = None
                else:
                    values[key] = []
                    current_list = key
                continue
            list_match = re.match(r"^\s{4}-\s+(.+?)\s*$", candidate)
            if list_match and current_list:
                target = values[current_list]
                if isinstance(target, list):
                    target.append(yaml_unquote(list_match.group(1)))
        return values
    raise ValidationError(f"Manifestabschnitt fehlt: {section}")


def parse_repo_map() -> tuple[list[str], dict[str, dict[str, list[str]]], list[str]]:
    """Liest Registry und Change-Impact-Pakete aus dem eingeschränkten YAML-Format."""

    text = read(REPO_MAP)
    lines = text.splitlines()

    manifests: list[str] = []
    registry_index = lines.index("module_registry:")
    for candidate in lines[registry_index + 1 :]:
        if candidate and not candidate.startswith(" "):
            break
        match = re.match(r"^\s{4}-\s+(.+?)\s*$", candidate)
        if match:
            manifests.append(yaml_unquote(match.group(1)))
    if not manifests:
        raise ValidationError("Die Modulregistry enthält kein Manifest.")

    impact_index = lines.index("change_impact:")
    packages_index = next(
        index
        for index in range(impact_index + 1, len(lines))
        if lines[index] == "  packages:"
    )

    full_audit_paths: list[str] = []
    in_full_audit = False
    for candidate in lines[impact_index + 1 : packages_index]:
        if candidate == "  full_audit_paths:":
            in_full_audit = True
            continue
        if in_full_audit:
            match = re.match(r"^\s{4}-\s+(.+?)\s*$", candidate)
            if match:
                full_audit_paths.append(yaml_unquote(match.group(1)))

    packages: dict[str, dict[str, list[str]]] = {}
    current_package: str | None = None
    current_field: str | None = None
    for candidate in lines[packages_index + 1 :]:
        if candidate and not candidate.startswith(" "):
            break
        package_match = re.match(r"^\s{4}([A-Za-z0-9_-]+):\s*$", candidate)
        if package_match:
            current_package = package_match.group(1)
            packages[current_package] = {"paths": [], "checks": []}
            current_field = None
            continue
        field_match = re.match(r"^\s{6}(paths|checks):\s*$", candidate)
        if field_match and current_package:
            current_field = field_match.group(1)
            continue
        value_match = re.match(r"^\s{8}-\s+(.+?)\s*$", candidate)
        if value_match and current_package and current_field:
            packages[current_package][current_field].append(
                yaml_unquote(value_match.group(1))
            )

    if not full_audit_paths or not packages:
        raise ValidationError("Change-Impact-Registry ist unvollständig.")
    for name, package in packages.items():
        if not package["paths"] or not package["checks"]:
            raise ValidationError(f"Impact-Paket ist unvollständig: {name}")
    return manifests, packages, full_audit_paths



def validate_module_registry(manifest_paths: list[str]) -> None:
    """Vergleicht die explizite Registry mit allen vorhandenen Modulmanifesten."""

    discovered = sorted(
        path.relative_to(REPOSITORY_ROOT).as_posix()
        for path in (REPOSITORY_ROOT / "Modules").glob("*/module.yaml")
    )
    registered = sorted(manifest_paths)
    missing = sorted(set(discovered) - set(registered))
    stale = sorted(set(registered) - set(discovered))
    if missing or stale:
        raise ValidationError(
  "Modulregistry und Dateisystem weichen voneinander ab: "
  f"nicht registriert={missing}, ohne Manifest={stale}"
        )

def changed_paths(base: str, head: str) -> list[str]:
    output = run_git("diff", "--name-only", "--diff-filter=ACMRD", base, head)
    return sorted({line.strip() for line in output.splitlines() if line.strip()})


def selected_checks(
    changed: list[str],
    packages: dict[str, dict[str, list[str]]],
    full_audit_paths: list[str],
    force_all: bool,
) -> tuple[set[str], list[str], bool]:
    full_audit = force_all or any(path in full_audit_paths for path in changed)
    selected: list[str] = []
    checks: set[str] = set()
    for name, package in packages.items():
        if full_audit or any(
            fnmatch.fnmatch(path, pattern)
            for path in changed
            for pattern in package["paths"]
        ):
            selected.append(name)
            checks.update(package["checks"])
    return checks, selected, full_audit


def load_modules(manifest_paths: list[str]) -> list[dict[str, object]]:
    modules: list[dict[str, object]] = []
    for manifest_path in manifest_paths:
        path = REPOSITORY_ROOT / manifest_path
        text = read(path)
        documentation = section_values(text, "documentation")
        contracts = section_values(text, "contracts")
        module_root = path.parent

        module = {
            "manifest_path": manifest_path,
            "root": module_root,
            "id": top_scalar(text, "module_id"),
            "name": top_scalar(text, "module_name"),
            "version": top_scalar(text, "version"),
            "implementation_status": top_scalar(text, "implementation_status"),
            "validation_status": top_scalar(text, "validation_status"),
            "release_status": top_scalar(text, "release_status"),
            "versions": top_list(text, "sql_server_versions"),
            "schemas": top_list(text, "schemas"),
            "documentation": documentation,
            "contracts": contracts,
            "evidence_workflows": re.findall(
                r'^\s{4}workflow:\s*"([^"]+)"\s*$',
                text,
                re.MULTILINE,
            ),
        }
        modules.append(module)
    return modules


def validate_manifests(modules: list[dict[str, object]]) -> None:
    seen_ids: set[str] = set()
    for module in modules:
        module_id = str(module["id"])
        if module_id in seen_ids:
            raise ValidationError(f"Doppelte Modul-ID: {module_id}")
        seen_ids.add(module_id)

        if module["implementation_status"] not in ALLOWED_IMPLEMENTATION_STATUS:
            raise ValidationError(
                f"{module_id}: ungültiger implementation_status "
                f"{module['implementation_status']}"
            )
        if module["validation_status"] not in ALLOWED_VALIDATION_STATUS:
            raise ValidationError(
                f"{module_id}: ungültiger validation_status "
                f"{module['validation_status']}"
            )
        if module["release_status"] not in ALLOWED_RELEASE_STATUS:
            raise ValidationError(
                f"{module_id}: ungültiger release_status "
                f"{module['release_status']}"
            )

        documentation = module["documentation"]
        assert isinstance(documentation, dict)
        required_documentation_keys = {
            "module",
            "public_objects",
            "architecture",
            "test_matrix",
            "evidence",
        }
        missing = required_documentation_keys - documentation.keys()
        if missing:
            raise ValidationError(
                f"{module_id}: Dokumentationskopplung fehlt: {sorted(missing)}"
            )
        contracts = module["contracts"]
        assert isinstance(contracts, dict)
        for contract in ("usp", "deployment", "validation"):
            if not contracts.get(contract):
                raise ValidationError(
                    f"{module_id}: Contract-Version fehlt: {contract}"
                )

        module_root = module["root"]
        assert isinstance(module_root, Path)
        for value in documentation.values():
            paths = value if isinstance(value, list) else [value]
            for relative in paths:
                target = (module_root / str(relative)).resolve()
                try:
                    target.relative_to(REPOSITORY_ROOT)
                except ValueError as error:
                    raise ValidationError(
                        f"{module_id}: Pfad verlässt das Repository: {relative}"
                    ) from error
                if not target.exists():
                    raise ValidationError(
                        f"{module_id}: gekoppeltes Artefakt fehlt: {relative}"
                    )

        evidence_workflows = module["evidence_workflows"]
        assert isinstance(evidence_workflows, list)
        if not evidence_workflows:
            if module["validation_status"] in {"not executed", "not applicable"}:
                continue
            raise ValidationError(f"{module_id}: Validierungsevidenz fehlt.")
        current_evidence = evidence_workflows[-1]
        for key in ("module", "test_matrix", "evidence"):
            values = documentation[key]
            paths = values if isinstance(values, list) else [values]
            for relative in paths:
                target = (module_root / str(relative)).resolve()
                if current_evidence not in read(target):
                    raise ValidationError(
                        f"{module_id}: aktuelle Evidenz fehlt in {relative}"
                    )


def validate_derived_backlog_status(modules: list[dict[str, object]]) -> None:
    backlog = read(REPOSITORY_ROOT / ".ai" / "BACKLOG.md")
    module_by_id = {str(module["id"]): module for module in modules}
    sections = re.split(r"(?=^### AP-\d{4}-\d{3}:)", backlog, flags=re.MULTILINE)
    for section in sections:
        heading = re.match(r"^### (AP-\d{4}-\d{3}):", section)
        if heading is None or "abgeleitet aus `module.yaml`" not in section:
            continue
        scope_match = re.search(r"^\| Scope \| (.*?) \|$", section, re.MULTILINE)
        if scope_match is None:
            raise ValidationError(
                f"{heading.group(1)}: abgeleitete Statuszeilen ohne Scope"
            )
        scoped_modules = [
            module
            for module_id, module in module_by_id.items()
            if module_id in scope_match.group(1)
        ]
        if not scoped_modules:
            raise ValidationError(
                f"{heading.group(1)}: kein registriertes Modul im Scope"
            )
        for module in scoped_modules:
            expected = (
                ("Implementation Status", module["implementation_status"]),
                ("Validation Status", module["validation_status"]),
                ("Release Status", module["release_status"]),
            )
            for label, value in expected:
                pattern = (
                    rf"\|\s*{re.escape(label)}\s*\|\s*`{re.escape(str(value))}`"
                    rf"\s*[–-]\s*abgeleitet aus `module\.yaml`\s*\|"
                )
                if re.search(pattern, section) is None:
                    raise ValidationError(
                        f"{heading.group(1)}/{module['id']}: abgeleiteter "
                        f"Backlog-Status ist veraltet: {label}"
                    )


def status_badge(modules: list[dict[str, object]]) -> str:
    implemented = sum(
        module["implementation_status"] == "implemented" for module in modules
    )
    partial = sum(
        module["validation_status"] == "partially validated" for module in modules
    )
    module_label = "Modul" if implemented == 1 else "Module"
    label = (
        f"{implemented}%20{module_label}%20implementiert%20%7C%20"
        f"{partial}%20teilweise%20validiert"
    )
    alt = (
        f"Status: {implemented} {module_label} implementiert – "
        f"{partial} teilweise validiert"
    )
    return (
        f"[![{alt}](https://img.shields.io/badge/Status-{label}-yellow)]"
        f"(./Modules/README.md)"
    )


def status_table(modules: list[dict[str, object]]) -> str:
    rows = [
        "| Modul-ID | Name | Version | Schema | Implementierung | Validierung | Release | SQL Server |",
        "|---|---|---:|---|---|---|---|---|",
    ]
    for module in sorted(modules, key=lambda item: str(item["id"])):
        rows.append(
            "| `{id}` | {name} | `{version}` | `{schema}` | `{implementation}` | "
            "`{validation}` | `{release}` | {versions} |".format(
                id=module["id"],
                name=module["name"],
                version=module["version"],
                schema=", ".join(str(value) for value in module["schemas"]),
                implementation=module["implementation_status"],
                validation=module["validation_status"],
                release=module["release_status"],
                versions=", ".join(str(value) for value in module["versions"]),
            )
        )
    return "\n".join(rows)


def replace_generated_block(text: str, name: str, generated: str) -> str:
    begin = f"<!-- BEGIN GENERATED:{name} -->"
    end = f"<!-- END GENERATED:{name} -->"
    pattern = re.compile(
        rf"{re.escape(begin)}\n.*?\n{re.escape(end)}",
        re.DOTALL,
    )
    replacement = f"{begin}\n{generated}\n{end}"
    if pattern.search(text) is None:
        raise ValidationError(f"Generated-Marker fehlt: {name}")
    return pattern.sub(replacement, text, count=1)


def validate_generated_status(
    modules: list[dict[str, object]], write_changes: bool
) -> None:
    targets = (
        (README, GENERATED_BADGE, status_badge(modules)),
        (MODULES_README, GENERATED_TABLE, status_table(modules)),
    )
    for path, name, generated in targets:
        current = read(path)
        expected = replace_generated_block(current, name, generated)
        if current == expected:
            continue
        if write_changes:
            path.write_text(expected, encoding="utf-8", newline="\n")
        else:
            raise ValidationError(
                f"Generierter Status ist veraltet: {path.relative_to(REPOSITORY_ROOT)}; "
                "mit --write aktualisieren."
            )


def markdown_files_for_scope(
    changed: list[str],
    modules: list[dict[str, object]],
    full_audit: bool,
) -> list[Path]:
    if full_audit:
        return sorted(
            path
            for path in REPOSITORY_ROOT.rglob("*.md")
            if ".git" not in path.parts
        )

    files = {
        REPOSITORY_ROOT / path
        for path in changed
        if path.lower().endswith(".md") and (REPOSITORY_ROOT / path).is_file()
    }
    for module in modules:
        documentation = module["documentation"]
        module_root = module["root"]
        assert isinstance(documentation, dict)
        assert isinstance(module_root, Path)
        for value in documentation.values():
            paths = value if isinstance(value, list) else [value]
            files.update(
                (module_root / str(relative)).resolve()
                for relative in paths
                if str(relative).lower().endswith(".md")
            )
    return sorted(files)


def validate_markdown_links(paths: list[Path]) -> None:
    link_pattern = re.compile(r"!?\[[^\]]*]\(([^)]+)\)")
    failures: list[str] = []
    for path in paths:
        text = read(path)
        for raw_target in link_pattern.findall(text):
            target = raw_target.strip().split(maxsplit=1)[0].strip("<>")
            if (
                not target
                or target.startswith(("#", "http://", "https://", "mailto:"))
            ):
                continue
            relative = target.split("#", 1)[0]
            if not relative:
                continue
            resolved = (path.parent / relative).resolve()
            if not resolved.exists():
                failures.append(
                    f"{path.relative_to(REPOSITORY_ROOT)} -> {relative}"
                )
    if failures:
        raise ValidationError(
            "Ungültige lokale Markdown-Links:\n- " + "\n- ".join(failures)
        )


def validate_brainstorm_history(base: str | None, head: str) -> None:
    path = REPOSITORY_ROOT / BRAINSTORM
    text = read(path)
    lines = text.splitlines()
    for index, line in enumerate(lines):
        if not line.startswith("~~"):
            continue
        following = "\n".join(lines[index + 1 : index + 5])
        if re.search(
            r"Änderungsvermerk\s+\d{4}-\d{2}-\d{2},\s*[^:]+:\s*\S+",
            following,
        ) is None:
            raise ValidationError(
                f"{BRAINSTORM}:{index + 1}: Durchstreichung ohne datierten "
                "Änderungsvermerk mit Autor und Begründung."
            )

    if base is None:
        return
    diff = run_git("diff", "--unified=0", base, head, "--", BRAINSTORM)
    removed = [
        line[1:]
        for line in diff.splitlines()
        if line.startswith("-") and not line.startswith("---") and line[1:].strip()
    ]
    added = [
        line[1:]
        for line in diff.splitlines()
        if line.startswith("+") and not line.startswith("+++") and line[1:].strip()
    ]
    for line in removed:
        if f"~~{line}~~" not in added:
            raise ValidationError(
                f"{BRAINSTORM}: vorhandene Zeile wurde gelöscht oder still geändert: "
                f"{line[:100]}"
            )
    if removed and not any(
        re.search(
            r"Änderungsvermerk\s+\d{4}-\d{2}-\d{2},\s*[^:]+:\s*\S+",
            line,
        )
        for line in added
    ):
        raise ValidationError(
            f"{BRAINSTORM}: Durchstreichung ohne neuen Änderungsvermerk."
        )


def validate_protected_content() -> None:
    license_hash = sha256(read(REPOSITORY_ROOT / "LICENSE.md"))
    if license_hash != PROTECTED_SHA256["LICENSE.md"]:
        raise ValidationError(
            "LICENSE.md weicht von der freigegebenen geschützten Baseline ab."
        )
    readme = read(README)
    marker = "# SQL Server Toolbelt"
    if marker not in readme:
        raise ValidationError("README-Lizenzblock kann nicht abgegrenzt werden.")
    prefix = readme.split(marker, 1)[0]
    if sha256(prefix) != PROTECTED_SHA256["README.md::license-prefix"]:
        raise ValidationError(
            "Der geschützte Lizenzblock am Anfang der README wurde verändert."
        )


def validate_status_truth(modules: list[dict[str, object]]) -> None:
    stale_patterns = {
        "README.md": r"Runtime nicht ausgeführt",
        "SECURITY.md": r"noch nicht zur Runtime validiert",
        "Documentation/Standards/USP_CONTRACT.md": (
            r"gemeinsame Runtime-Infrastruktur wird erst"
        ),
    }
    for relative, pattern in stale_patterns.items():
        if re.search(pattern, read(REPOSITORY_ROOT / relative), re.IGNORECASE):
            raise ValidationError(f"Veraltete Statusaussage in {relative}: {pattern}")

    implemented = sum(
        module["implementation_status"] == "implemented" for module in modules
    )
    partially_validated = sum(
        module["validation_status"] == "partially validated" for module in modules
    )
    not_executed = sum(
        module["validation_status"] == "not executed" for module in modules
    )
    expected_claim = f"{implemented} Module sind implementiert"
    count_pattern = re.compile(
        r"\b(\d+)\s+Module\s+sind\s+implementiert\b",
        re.MULTILINE,
    )
    for relative in CURRENT_STATUS_FILES:
        text = read(REPOSITORY_ROOT / relative)
        claims = [int(value) for value in count_pattern.findall(text)]
        if not claims:
            raise ValidationError(
                f"Aktuelle Modulzahl fehlt in {relative}: {expected_claim}"
            )
        mismatches = sorted({value for value in claims if value != implemented})
        if mismatches:
            raise ValidationError(
                f"Veraltete Modulzahl in {relative}: {mismatches}; "
                f"Manifest-Realität: {implemented}"
            )

        partial_claims = [
            int(value)
            for value in re.findall(
                r"\b(\d+)\s+sind\s+`partially validated`", text
            )
        ]
        partial_claims.extend(
            int(value)
            for value in re.findall(
                r"Status:\s*\d+\s+Module?\s+implementiert\s+[–-]\s*"
                r"(\d+)\s+teilweise validiert",
                text,
            )
        )
        if any(value != partially_validated for value in partial_claims):
            raise ValidationError(
                f"Veraltete partially-validated-Summe in {relative}; "
                f"Manifest-Realität: {partially_validated}"
            )

        not_executed_claims = [
            int(value)
            for value in re.findall(
                r"\b(\d+)\s+(?:Module\s+)?(?:ist|sind)\s+`not executed`", text
            )
        ]
        if re.search(r"\bein Modul ist\s+`not executed`", text):
            not_executed_claims.append(1)
        if any(value != not_executed for value in not_executed_claims):
            raise ValidationError(
                f"Veraltete not-executed-Summe in {relative}; "
                f"Manifest-Realität: {not_executed}"
            )


def validate_unique_planning_ids() -> None:
    checks = (
        (".ai/BACKLOG.md", r"^### (AP-\d{4}-\d{3}):"),
        (".ai/ROADMAP.md", r"^### (Phase\s+\d+(?:\.\d+)*)\s+[–-]"),
    )
    for relative, pattern in checks:
        identifiers = re.findall(
            pattern,
            read(REPOSITORY_ROOT / relative),
            re.MULTILINE,
        )
        duplicates = sorted(
            identifier
            for identifier in set(identifiers)
            if identifiers.count(identifier) > 1
        )
        if duplicates:
            raise ValidationError(
                f"Doppelte Planungs-IDs in {relative}: {duplicates}"
            )


def candidate_statuses() -> dict[str, str]:
    text = read(REPOSITORY_ROOT / "Backlog" / "TOOLBELT_CANDIDATES.md")
    statuses: dict[str, str] = {}
    for section in re.split(r"^## ", text, flags=re.MULTILINE)[1:]:
        heading = section.splitlines()[0]
        candidate_match = re.match(r"(TC-\d{4}-\d{3}):", heading)
        if candidate_match is None:
            continue
        status_match = re.search(
            r"^\| \*\*Status\*\* \| (.*?) \|$",
            section,
            re.MULTILINE,
        )
        if status_match is None:
            raise ValidationError(
                f"Kandidatenstatus fehlt: {candidate_match.group(1)}"
            )
        statuses[candidate_match.group(1)] = status_match.group(1).strip()
    if not statuses:
        raise ValidationError("Keine formalen Toolbelt-Kandidaten gefunden.")
    return statuses


def validate_inventory_truth(modules: list[dict[str, object]]) -> None:
    module_ids = {str(module["id"]) for module in modules}

    readme_ids = set(
        re.findall(
            r"\]\(\./Modules/(toolbelt\.[^/]+)/README\.md\)",
            read(README),
        )
    )
    if readme_ids != module_ids:
        raise ValidationError(
            "README-Modulinventar weicht von der Manifest-Registry ab: "
            f"fehlend={sorted(module_ids - readme_ids)}, "
            f"zusätzlich={sorted(readme_ids - module_ids)}"
        )

    tests_text = read(REPOSITORY_ROOT / "Tests" / "README.md")
    tests_section = tests_text.split("## Modulspezifische Testmatrizen", 1)[-1]
    tests_section = tests_section.split("\n## ", 1)[0]
    test_ids = set(
        re.findall(r"^\| `(toolbelt\.[^`]+)` \|", tests_section, re.MULTILINE)
    )
    if test_ids != module_ids:
        raise ValidationError(
            "Testmatrix-Inventar weicht von der Manifest-Registry ab: "
            f"fehlend={sorted(module_ids - test_ids)}, "
            f"zusätzlich={sorted(test_ids - module_ids)}"
        )

    statuses = candidate_statuses()
    implemented_candidates = {
        candidate
        for candidate, status in statuses.items()
        if status.startswith("`implemented`")
    }
    plan_text = read(
        REPOSITORY_ROOT
        / "Backlog"
        / "TOOLBELT_CANDIDATE_IMPLEMENTATION_PLAN.md"
    )
    plan_section = plan_text.split("### Bereits implementierte Module", 1)[-1]
    plan_section = plan_section.split("\n### ", 1)[0]
    planned_candidates = set(
        re.findall(r"^\| `(TC-\d{4}-\d{3})` \|", plan_section, re.MULTILINE)
    )
    if planned_candidates != implemented_candidates:
        raise ValidationError(
            "Implementiertes Kandidateninventar im Plan ist veraltet: "
            f"fehlend={sorted(implemented_candidates - planned_candidates)}, "
            f"zusätzlich={sorted(planned_candidates - implemented_candidates)}"
        )

    proposed_section = plan_text.split(
        "### Portable Fach- und Compatibility-Module", 1
    )[-1]
    proposed_section = proposed_section.split("\n### ", 1)[0]
    proposed_candidates = set(
        re.findall(r"^\| `(TC-\d{4}-\d{3})` \|", proposed_section, re.MULTILINE)
    )
    duplicated_candidates = proposed_candidates & implemented_candidates
    if duplicated_candidates:
        raise ValidationError(
            "Implementierte Kandidaten stehen weiterhin im vorgeschlagenen "
            f"Compatibility-Inventar: {sorted(duplicated_candidates)}"
        )

    inbox_text = read(
        REPOSITORY_ROOT / "Backlog" / "TOOLBELT_RESEARCH_INBOX.md"
    )
    inbox_section = inbox_text.split(
        "## Formalisierte und freigegebene Einträge", 1
    )[-1]
    inbox_section = inbox_section.split("\n## ", 1)[0]
    for candidate, status in re.findall(
        r"^\| `RI-\d{4}-\d{3}` \| `(TC-\d{4}-\d{3})`.*? \| (.*?) \|$",
        inbox_section,
        re.MULTILINE,
    ):
        expected = statuses.get(candidate)
        if expected is None:
            raise ValidationError(
                f"Research-Inbox verweist auf unbekannten Kandidaten: {candidate}"
            )
        if status.strip() != expected:
            raise ValidationError(
                f"Research-Inbox-Status ist veraltet: {candidate}: "
                f"{status.strip()} statt {expected}"
            )


def validate_runtime_workflow_scope() -> None:
    workflow = read(
        REPOSITORY_ROOT / ".github" / "workflows" / "result-table-runtime.yml"
    )
    prohibited = (
        '"Documentation/Architecture/**"',
        '"Documentation/Standards/**"',
        '"Tests/RESULT_TABLE_CONTRACT_TEST_MATRIX.md"',
    )
    for marker in prohibited:
        if marker in workflow:
            raise ValidationError(
                f"Runtime-Vollmatrix wird durch reine Dokumentation ausgelöst: {marker}"
            )


def validate_base64_runtime_workflow_scope() -> None:
    workflow = read(
        REPOSITORY_ROOT / ".github" / "workflows" / "base64-runtime.yml"
    )
    prohibited = (
        '"Documentation/Architecture/**"',
        '"Documentation/Standards/**"',
        '"Modules/toolbelt.conversion.base64/Documentation/**"',
        '"Modules/toolbelt.conversion.base64/Tests/**/*.md"',
    )
    for marker in prohibited:
        if marker in workflow:
            raise ValidationError(
                "Base64-Runtime-Matrix wird durch reine Dokumentation "
                f"ausgelöst: {marker}"
            )


def validate_generate_series_runtime_workflow_scope() -> None:
    workflow = read(
        REPOSITORY_ROOT
        / ".github"
        / "workflows"
        / "generate-series-runtime.yml"
    )
    prohibited = (
        '"Documentation/Architecture/**"',
        '"Documentation/Standards/**"',
        '"Modules/toolbelt.core.generate-series/Documentation/**"',
        '"Modules/toolbelt.core.generate-series/Tests/**/*.md"',
    )
    for marker in prohibited:
        if marker in workflow:
            raise ValidationError(
                "Generate-Series-Runtime-Matrix wird durch reine "
                f"Dokumentation ausgelöst: {marker}"
            )


def validate_identifier_runtime_workflow_scope() -> None:
    workflow = read(
        REPOSITORY_ROOT / ".github" / "workflows" / "identifier-runtime.yml"
    )
    prohibited = (
        '"Documentation/Architecture/**"',
        '"Documentation/Standards/**"',
        '"Modules/toolbelt.metadata.identifier/Documentation/**"',
        '"Modules/toolbelt.metadata.identifier/Tests/**/*.md"',
    )
    for marker in prohibited:
        if marker in workflow:
            raise ValidationError(
                "Identifier-Runtime-Matrix wird durch reine Dokumentation "
                f"ausgelöst: {marker}"
            )


def validate_split_characters_runtime_workflow_scope() -> None:
    workflow = read(
        REPOSITORY_ROOT
        / ".github"
        / "workflows"
        / "split-characters-runtime.yml"
    )
    prohibited = (
        '"Documentation/Architecture/**"',
        '"Documentation/Standards/**"',
        '"Modules/toolbelt.string.split-characters/Documentation/**"',
        '"Modules/toolbelt.string.split-characters/Tests/**/*.md"',
    )
    for marker in prohibited:
        if marker in workflow:
            raise ValidationError(
                "Split-Characters-Runtime-Matrix wird durch reine "
                f"Dokumentation ausgelöst: {marker}"
            )


def validate_semantic_version_runtime_workflow_scope() -> None:
    workflow = read(
        REPOSITORY_ROOT / ".github" / "workflows" / "semantic-version-runtime.yml"
    )
    for marker in (
        '"Documentation/Architecture/**"',
        '"Documentation/Standards/**"',
        '"Modules/toolbelt.validation.semantic-version/Documentation/**"',
        '"Modules/toolbelt.validation.semantic-version/Tests/**/*.md"',
    ):
        if marker in workflow:
            raise ValidationError(
                "Semantic-Version-Runtime wird durch reine Dokumentation "
                f"ausgelöst: {marker}"
            )


def validate_integer_base_runtime_workflow_scope() -> None:
    workflow = read(
        REPOSITORY_ROOT / ".github" / "workflows" / "integer-base-runtime.yml"
    )
    for marker in (
        '"Documentation/Architecture/**"',
        '"Documentation/Standards/**"',
        '"Modules/toolbelt.conversion.integer-base/Documentation/**"',
        '"Modules/toolbelt.conversion.integer-base/Tests/**/*.md"',
    ):
        if marker in workflow:
            raise ValidationError(
                "Integer-Base-Runtime wird durch reine Dokumentation "
                f"ausgelöst: {marker}"
            )


def validate_w1_runtime_workflow_scope() -> None:
    workflow = read(
        REPOSITORY_ROOT / ".github" / "workflows" / "w1-portable-runtime.yml"
    )
    for marker in (
        '"Documentation/Architecture/**"',
        '"Documentation/Standards/**"',
        '"Modules/toolbelt.datetime.calendar-difference/**"',
        '"Modules/toolbelt.string.directional-trim/**"',
        '"Modules/toolbelt.conversion.uri-component/**"',
    ):
        if marker in workflow:
            raise ValidationError(
                "W1-Runtime wird durch reine Dokumentation ausgelöst: "
                f"{marker}"
            )


def validate_w2a_runtime_workflow_scope() -> None:
    workflow = read(
        REPOSITORY_ROOT / ".github" / "workflows" / "w2a-portable-runtime.yml"
    )
    for marker in (
        '"Documentation/Architecture/**"',
        '"Documentation/Standards/**"',
        '"Modules/toolbelt.datetime.truncate/**"',
        '"Modules/toolbelt.datetime.bucket/**"',
        '"Modules/toolbelt.binary.bit-operations/**"',
    ):
        if marker in workflow:
            raise ValidationError(
                "W2a-Runtime wird durch reine Dokumentation ausgelöst: "
                f"{marker}"
            )


def validate_date_spine_runtime_workflow_scope() -> None:
    workflow = read(
        REPOSITORY_ROOT / ".github" / "workflows" / "date-spine-runtime.yml"
    )
    for marker in (
        '"Documentation/Architecture/**"',
        '"Documentation/Standards/**"',
        '"Modules/toolbelt.datetime.date-spine/Documentation/**"',
        '"Modules/toolbelt.datetime.date-spine/Tests/**/*.md"',
    ):
        if marker in workflow:
            raise ValidationError(
                "Date-Spine-Runtime wird durch reine Dokumentation "
                f"ausgelöst: {marker}"
            )


def validate_regex_research_workflow_scope() -> None:
    workflow = read(
        REPOSITORY_ROOT / ".github" / "workflows" / "regex-provider-spike.yml"
    )
    for marker in (
        '"Documentation/Research/**"',
        '"Documentation/Research/REGEX_SEMANTICS_PROVIDER_SPIKE.md"',
        '"Tests/Research/Regex/**"',
        '"Tests/Research/Regex/*.md"',
    ):
        if marker in workflow:
            raise ValidationError(
                "Regex-Provider-Spike-Runtime wird durch reine Dokumentation "
                f"ausgelöst: {marker}"
            )


def validate_regex_runtime_workflow_scope() -> None:
    workflow = read(
        REPOSITORY_ROOT / ".github" / "workflows" / "regex-runtime.yml"
    )
    for marker in (
        '"Documentation/Architecture/**"',
        '"Documentation/Research/**"',
        '"Modules/toolbelt.string.regex/Documentation/**"',
        '"Modules/toolbelt.string.regex/Tests/**/*.md"',
    ):
        if marker in workflow:
            raise ValidationError(
                "Regex-Runtime wird durch reine Dokumentation ausgelöst: "
                f"{marker}"
            )


def validate_w2b_json_path_runtime_workflow_scope() -> None:
    workflow = read(
        REPOSITORY_ROOT
        / ".github"
        / "workflows"
        / "w2b-json-path-runtime.yml"
    )
    for marker in (
        '"Documentation/Architecture/**"',
        '"Documentation/Standards/**"',
        '"Modules/toolbelt.json.path-exists/**"',
        '"Modules/toolbelt.json.path-exists/Documentation/**"',
        '"Modules/toolbelt.json.path-exists/Tests/**/*.md"',
    ):
        if marker in workflow:
            raise ValidationError(
                "W2b-JSON-Path-Runtime wird durch reine Dokumentation "
                f"ausgelöst: {marker}"
            )


def validate_w2c_runtime_workflow_scope() -> None:
    workflow = read(
        REPOSITORY_ROOT / ".github" / "workflows" / "w2c-runtime.yml"
    )
    for marker in (
        '"Documentation/Architecture/**"',
        '"Documentation/Standards/**"',
        '"Modules/toolbelt.core.console-message/**"',
        '"Modules/toolbelt.metadata.capability-catalog/**"',
        '"Modules/toolbelt.core.console-message/Documentation/**"',
        '"Modules/toolbelt.metadata.capability-catalog/Documentation/**"',
        '"Modules/toolbelt.core.console-message/Tests/**/*.md"',
        '"Modules/toolbelt.metadata.capability-catalog/Tests/**/*.md"',
    ):
        if marker in workflow:
            raise ValidationError(
                "W2c-Runtime wird durch reine Dokumentation ausgelöst: "
                f"{marker}"
            )


def run_result_table_static() -> None:
    script = (
        REPOSITORY_ROOT
        / "Modules"
        / "toolbelt.core.result-table"
        / "Tests"
        / "Static"
        / "validate_contract.py"
    )
    result = subprocess.run(
        (sys.executable, str(script)),
        cwd=REPOSITORY_ROOT,
        check=False,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    if result.returncode != 0:
        raise ValidationError(
            "Modulspezifische statische Prüfung fehlgeschlagen:\n"
            f"{result.stdout}{result.stderr}"
        )


def run_base64_static() -> None:
    script = (
        REPOSITORY_ROOT
        / "Modules"
        / "toolbelt.conversion.base64"
        / "Tests"
        / "Static"
        / "validate_contract.py"
    )
    result = subprocess.run(
        (sys.executable, str(script)),
        cwd=REPOSITORY_ROOT,
        check=False,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    if result.returncode != 0:
        raise ValidationError(
            "Statische Base64-Prüfung fehlgeschlagen:\n"
            f"{result.stdout}{result.stderr}"
        )


def run_generate_series_static() -> None:
    script = (
        REPOSITORY_ROOT
        / "Modules"
        / "toolbelt.core.generate-series"
        / "Tests"
        / "Static"
        / "validate_contract.py"
    )
    result = subprocess.run(
        (sys.executable, str(script)),
        cwd=REPOSITORY_ROOT,
        check=False,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    if result.returncode != 0:
        raise ValidationError(
            "Statische Generate-Series-Prüfung fehlgeschlagen:\n"
            f"{result.stdout}{result.stderr}"
        )


def run_date_spine_static() -> None:
    script = (
        REPOSITORY_ROOT
        / "Modules"
        / "toolbelt.datetime.date-spine"
        / "Tests"
        / "Static"
        / "validate_contract.py"
    )
    result = subprocess.run(
        (sys.executable, str(script)),
        cwd=REPOSITORY_ROOT,
        check=False,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    if result.returncode != 0:
        raise ValidationError(
            "Statische Date-Spine-Prüfung fehlgeschlagen:\n"
            f"{result.stdout}{result.stderr}"
        )


def run_regex_research_static() -> None:
    script = (
        REPOSITORY_ROOT
        / "Tests"
        / "Research"
        / "Regex"
        / "validate_research.py"
    )
    result = subprocess.run(
        (sys.executable, str(script)),
        cwd=REPOSITORY_ROOT,
        check=False,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    if result.returncode != 0:
        raise ValidationError(
            "Statische Regex-Research-Prüfung fehlgeschlagen:\n"
            f"{result.stdout}{result.stderr}"
        )


def run_regex_static() -> None:
    script = (
        REPOSITORY_ROOT
        / "Modules"
        / "toolbelt.string.regex"
        / "Tests"
        / "Static"
        / "validate_contract.py"
    )
    result = subprocess.run(
        (sys.executable, str(script)),
        cwd=REPOSITORY_ROOT,
        check=False,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    if result.returncode != 0:
        raise ValidationError(
            "Statische Regex-Prüfung fehlgeschlagen:\n"
            f"{result.stdout}{result.stderr}"
        )


def run_identifier_static() -> None:
    script = (
        REPOSITORY_ROOT
        / "Modules"
        / "toolbelt.metadata.identifier"
        / "Tests"
        / "Static"
        / "validate_contract.py"
    )
    result = subprocess.run(
        (sys.executable, str(script)),
        cwd=REPOSITORY_ROOT,
        check=False,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    if result.returncode != 0:
        raise ValidationError(
            "Statische Identifier-Prüfung fehlgeschlagen:\n"
            f"{result.stdout}{result.stderr}"
        )


def run_split_characters_static() -> None:
    script = (
        REPOSITORY_ROOT
        / "Modules"
        / "toolbelt.string.split-characters"
        / "Tests"
        / "Static"
        / "validate_contract.py"
    )
    result = subprocess.run(
        (sys.executable, str(script)),
        cwd=REPOSITORY_ROOT,
        check=False,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    if result.returncode != 0:
        raise ValidationError(
            "Statische Split-Characters-Prüfung fehlgeschlagen:\n"
            f"{result.stdout}{result.stderr}"
        )


def run_semantic_version_static() -> None:
    script = (
        REPOSITORY_ROOT / "Modules" / "toolbelt.validation.semantic-version"
        / "Tests" / "Static" / "validate_contract.py"
    )
    result = subprocess.run(
        (sys.executable, str(script)),
        cwd=REPOSITORY_ROOT,
        check=False,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    if result.returncode != 0:
        raise ValidationError(
            "Statische Semantic-Version-Prüfung fehlgeschlagen:\n"
            f"{result.stdout}{result.stderr}"
        )


def run_integer_base_static() -> None:
    script = (
        REPOSITORY_ROOT / "Modules" / "toolbelt.conversion.integer-base"
        / "Tests" / "Static" / "validate_contract.py"
    )
    result = subprocess.run(
        (sys.executable, str(script)),
        cwd=REPOSITORY_ROOT,
        check=False,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    if result.returncode != 0:
        raise ValidationError(
            "Statische Integer-Base-Prüfung fehlgeschlagen:\n"
            f"{result.stdout}{result.stderr}"
        )


def run_json_path_exists_static() -> None:
    script = (
        REPOSITORY_ROOT / "Modules" / "toolbelt.json.path-exists"
        / "Tests" / "Static" / "validate_contract.py"
    )
    result = subprocess.run(
        (sys.executable, str(script)),
        cwd=REPOSITORY_ROOT,
        check=False,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    if result.returncode != 0:
        raise ValidationError(
            "Statische JSON-Path-Prüfung fehlgeschlagen:\n"
            f"{result.stdout}{result.stderr}"
        )


def run_console_message_static() -> None:
    script = (
        REPOSITORY_ROOT / "Modules" / "toolbelt.core.console-message"
        / "Tests" / "Static" / "validate_contract.py"
    )
    result = subprocess.run(
        (sys.executable, str(script)),
        cwd=REPOSITORY_ROOT,
        check=False,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    if result.returncode != 0:
        raise ValidationError(
            "Statische Console-Message-Prüfung fehlgeschlagen:\n"
            f"{result.stdout}{result.stderr}"
        )


def run_capability_catalog_static() -> None:
    script = (
        REPOSITORY_ROOT / "Modules" / "toolbelt.metadata.capability-catalog"
        / "Tests" / "Static" / "validate_contract.py"
    )
    result = subprocess.run(
        (sys.executable, str(script)),
        cwd=REPOSITORY_ROOT,
        check=False,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    if result.returncode != 0:
        raise ValidationError(
            "Statische Capability-Catalog-Prüfung fehlgeschlagen:\n"
            f"{result.stdout}{result.stderr}"
        )


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--base", help="Git-Basisref für die Impact-Ermittlung")
    parser.add_argument("--head", default="HEAD", help="Git-Zielref")
    parser.add_argument(
        "--all",
        action="store_true",
        help="Vollständigen Baseline-/Release-Audit ausführen",
    )
    parser.add_argument(
        "--write",
        action="store_true",
        help="Generierte Statusabschnitte aktualisieren",
    )
    return parser.parse_args()


def main() -> int:
    arguments = parse_arguments()
    if not arguments.all and not arguments.base:
        raise ValidationError("Entweder --base oder --all ist erforderlich.")

    manifests, packages, full_audit_paths = parse_repo_map()
    validate_module_registry(manifests)
    zero_base = bool(arguments.base) and not arguments.base.strip("0")
    changed = (
        []
        if arguments.all or zero_base
        else changed_paths(arguments.base, arguments.head)
    )
    checks, selected, full_audit = selected_checks(
        changed,
        packages,
        full_audit_paths,
        arguments.all or zero_base,
    )
    modules = load_modules(manifests)

    # Kleine unveränderliche Basisschutzprüfungen laufen immer.
    validate_protected_content()
    validate_status_truth(modules)
    validate_unique_planning_ids()
    validate_manifests(modules)
    validate_derived_backlog_status(modules)
    validate_inventory_truth(modules)

    if "generated_status" in checks:
        validate_generated_status(modules, arguments.write)
    if "markdown_links" in checks:
        validate_markdown_links(
            markdown_files_for_scope(changed, modules, full_audit)
        )
    if "brainstorm_history" in checks:
        validate_brainstorm_history(arguments.base, arguments.head)
    if "runtime_workflow_scope" in checks:
        validate_runtime_workflow_scope()
    if "result_table_static" in checks:
        run_result_table_static()
    if "base64_runtime_workflow_scope" in checks:
        validate_base64_runtime_workflow_scope()
    if "base64_static" in checks:
        run_base64_static()
    if "generate_series_runtime_workflow_scope" in checks:
        validate_generate_series_runtime_workflow_scope()
    if "generate_series_static" in checks:
        run_generate_series_static()
    if "date_spine_runtime_workflow_scope" in checks:
        validate_date_spine_runtime_workflow_scope()
    if "date_spine_static" in checks:
        run_date_spine_static()
    if "regex_research_workflow_scope" in checks:
        validate_regex_research_workflow_scope()
    if "regex_research_static" in checks:
        run_regex_research_static()
    if "regex_runtime_workflow_scope" in checks:
        validate_regex_runtime_workflow_scope()
    if "regex_static" in checks:
        run_regex_static()
    if "identifier_runtime_workflow_scope" in checks:
        validate_identifier_runtime_workflow_scope()
    if "identifier_static" in checks:
        run_identifier_static()
    if "split_characters_runtime_workflow_scope" in checks:
        validate_split_characters_runtime_workflow_scope()
    if "split_characters_static" in checks:
        run_split_characters_static()
    if "semantic_version_runtime_workflow_scope" in checks:
        validate_semantic_version_runtime_workflow_scope()
    if "semantic_version_static" in checks:
        run_semantic_version_static()
    if "integer_base_runtime_workflow_scope" in checks:
        validate_integer_base_runtime_workflow_scope()
    if "integer_base_static" in checks:
        run_integer_base_static()
    if "w1_runtime_workflow_scope" in checks:
        validate_w1_runtime_workflow_scope()
    if "w2a_runtime_workflow_scope" in checks:
        validate_w2a_runtime_workflow_scope()
    if "w2b_json_path_runtime_workflow_scope" in checks:
        validate_w2b_json_path_runtime_workflow_scope()
    if "json_path_exists_static" in checks:
        run_json_path_exists_static()
    if "w2c_runtime_workflow_scope" in checks:
        validate_w2c_runtime_workflow_scope()
    if "console_message_static" in checks:
        run_console_message_static()
    if "capability_catalog_static" in checks:
        run_capability_catalog_static()

    print("Dokumentations- und Konsistenzprüfung: erfolgreich")
    print(f"Modulmanifeste: {len(modules)}")
    print(
        "Prüfmodus: "
        + ("vollständiger Audit" if full_audit else "inkrementeller Change-Impact")
    )
    print("Impact-Pakete: " + (", ".join(selected) if selected else "keine"))
    print(f"Geänderte Pfade: {len(changed)}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except ValidationError as error:
        print(f"Dokumentations- und Konsistenzprüfung: FEHLER: {error}", file=sys.stderr)
        raise SystemExit(1)
