"""Offline-Regressionen für Testauswahl und erhaltene Schutzgrenzen."""

from __future__ import annotations

import io
import re
import unittest
from pathlib import Path

import validate_documentation as validator


ROOT = Path(__file__).resolve().parents[2]


def workflow_paths(text: str) -> list[list[str]]:
    """Liest die einfachen Blocklisten des geprüften Workflowformats."""
    groups = []
    for match in re.finditer(
        r"^    paths:\n((?:      (?:- .+|#.*)\n|\n)+)", text, re.MULTILINE
    ):
        groups.append([
            line.removeprefix("      - ").strip().strip("\"'")
            for line in match.group(1).splitlines() if line.startswith("      - ")
        ])
    return groups


def glob_matches(path: str, pattern: str) -> bool:
    """Nur die verwendete GitHub-Teilmenge: *, ** und optionales **/."""
    expression = ""
    index = 0
    while index < len(pattern):
        if pattern.startswith("**/", index):
            expression += "(?:.*/)?"
            index += 3
        elif pattern.startswith("**", index):
            expression += ".*"
            index += 2
        elif pattern[index] == "*":
            expression += "[^/]*"
            index += 1
        else:
            expression += re.escape(pattern[index])
            index += 1
    return re.fullmatch(expression, path) is not None


def triggered(path: str, patterns: list[str]) -> bool:
    selected = False
    for pattern in patterns:
        negative = pattern.startswith("!")
        if glob_matches(path, pattern[1:] if negative else pattern):
            selected = not negative
    return selected


class ChangeImpactTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        _, cls.packages, cls.global_paths = validator.parse_repo_map()

    def select(self, *paths: str, force_all: bool = False):
        return validator.selected_checks(list(paths), self.packages, self.global_paths, force_all)

    def test_process_and_foundation_edits_do_not_select_module_validators(self):
        for path in ("AGENTS.md", ".ai/WORKING_RULES.md",
                     ".ai/foundation/FOUNDATION_RULESET.md",
                     ".ai/foundation/VALIDATION_POLICY.md",
                     "Documentation/Standards/AI_COST_AND_QUALITY_PROCESSING_POLICY.md"):
            with self.subTest(path=path):
                checks, _, full = self.select(path)
                self.assertFalse(full)
                self.assertIn("markdown_links", checks)
                self.assertFalse(any(check.endswith("_static") for check in checks))

    def test_changed_module_contracts_keep_their_checks(self):
        for module, check in (("toolbelt.conversion.safe-cast", "safe_cast_static"),
                              ("toolbelt.json.pointer", "json_pointer_static")):
            for leaf in ("Source/Fixture.sql", "Tests/Runtime/Fixture.sql", "module.yaml"):
                checks, _, full = self.select(f"Modules/{module}/{leaf}")
                self.assertFalse(full)
                self.assertIn(check, checks)

    def test_shared_dependencies_keep_all_registered_consumers(self):
        checks, _, full = self.select("Tests/CI/test_owned_container_cleanup.py")
        self.assertFalse(full)
        self.assertTrue({"safe_cast_static", "json_pointer_static", "table_clone_static"} <= checks)

    def test_unknown_executable_input_falls_back_to_full_audit(self):
        checks, _, full = self.select("NewConsumer/unknown.py")
        self.assertTrue(full)
        self.assertIn("safe_cast_static", checks)
        self.assertIn("foundation_host_redirects", checks)

    def test_global_contracts_and_explicit_audits_remain_complete(self):
        expected = set().union(*(set(package["checks"]) for package in self.packages.values()))
        for path in self.global_paths:
            checks, _, full = self.select(path)
            self.assertTrue(full, path)
            self.assertEqual(checks, expected, path)
        self.assertEqual(self.select(force_all=True)[0], expected)

    def test_project_validation_is_separate_from_validator_selftests(self):
        checks, _, _ = self.select("Modules/toolbelt.conversion.safe-cast/module.yaml")
        self.assertIn("public_api_catalog", checks)
        self.assertNotIn("public_api_catalog_selftests", checks)
        self.assertNotIn("publication_contract", checks)
        self.assertIn("public_api_catalog_selftests", self.select("Tests/Documentation/generate_api_catalog.py")[0])
        self.assertIn("publication_contract", self.select("Tests/Documentation/publication.py")[0])

    def test_documentation_job_does_not_repeat_suite_validators(self):
        text = (ROOT / ".github/workflows/documentation-consistency.yml").read_text(encoding="utf-8")
        self.assertIn("Tests/Documentation/validate_documentation.py", text)
        for module in ("toolbelt.conversion.safe-cast", "toolbelt.json.pointer"):
            self.assertNotIn(f"Modules/{module}/Tests/Static/validate_contract.py", text)

    def test_broad_workflow_filters_exclude_only_known_documentation(self):
        workflow_count = 0
        for workflow in sorted((ROOT / ".github/workflows").glob("*.yml")):
            text = workflow.read_text(encoding="utf-8")
            for patterns in workflow_paths(text):
                modules = [p[:-3] for p in patterns if re.fullmatch(r"Modules/[^/]+/\*\*", p)]
                if not modules:
                    continue
                workflow_count += 1
                # Der bestehende Filesystem-Build besitzt keinen manuellen
                # Trigger; alle anderen betroffenen Workflows behalten ihn.
                if workflow.name == "windows-filesystem-build.yml":
                    self.assertNotIn("workflow_dispatch:", text)
                else:
                    self.assertIn("workflow_dispatch:", text)
                for module in modules:
                    for leaf in ("README.md", "CHANGELOG.md", "Documentation/Object.md",
                                 "Tests/README.md", "Tests/Runtime/NATIVE_EVIDENCE.md"):
                        self.assertFalse(triggered(f"{module}/{leaf}", patterns), (workflow.name, leaf))
                    for leaf in ("Source/Fixture.sql", "Deployment/Deploy.sql", "Clr/Fixture.cs",
                                 "Tests/Static/validate_contract.py", "Tests/Runtime/Fixture.sql",
                                 "Scripts/generate.py", "module.yaml", "UnknownFutureInput.bin"):
                        self.assertTrue(triggered(f"{module}/{leaf}", patterns), (workflow.name, leaf))
                # Gemeinsame Abhängigkeiten und externe Fachverträge bleiben positiv.
                for pattern in patterns:
                    if not pattern.startswith(("Modules/", "!")):
                        sample = pattern.replace("**", "Source").replace("*", "Fixture")
                        self.assertTrue(triggered(sample, patterns), (workflow.name, pattern))
        self.assertGreaterEqual(workflow_count, 14)

    def test_general_decision_append_does_not_trigger_runtime(self):
        for workflow in (ROOT / ".github/workflows").glob("*.yml"):
            for patterns in workflow_paths(workflow.read_text(encoding="utf-8")):
                self.assertFalse(triggered("Documentation/Architecture/DECISIONS.md", patterns), workflow.name)

    def test_glob_subset_preserves_order_and_directory_boundaries(self):
        self.assertFalse(glob_matches("Modules/a/b/README.md", "Modules/*/README.md"))
        self.assertTrue(glob_matches("Modules/a/Tests/README.md", "Modules/*/Tests/**/*.md"))
        self.assertTrue(triggered("Source/a.sql", ["Source/**", "!Source/**", "Source/a.sql"]))

    def test_push_does_not_duplicate_the_pull_request_branch_check(self):
        for workflow in (ROOT / ".github/workflows").glob("*.yml"):
            text = workflow.read_text(encoding="utf-8")
            if "  pull_request:" not in text:
                continue
            push = re.search(r"^  push:\n((?:    .*\n|\n)+)", text, re.MULTILINE)
            if push is not None:
                self.assertRegex(push.group(1), r"(?m)^    branches:", workflow.name)


if __name__ == "__main__":
    result = unittest.TextTestRunner(stream=io.StringIO()).run(
        unittest.defaultTestLoader.loadTestsFromTestCase(ChangeImpactTests)
    )
    if result.wasSuccessful():
        print(f"PASS CHANGE_IMPACT_TESTS TESTS={result.testsRun}")
    else:
        names = sorted({test.id().split(".")[-1] for test, _ in result.failures + result.errors})
        print(f"FAILED CHANGE_IMPACT_TESTS TESTS={result.testsRun} FAILED_METHODS={','.join(names)}")
    raise SystemExit(0 if result.wasSuccessful() else 1)
