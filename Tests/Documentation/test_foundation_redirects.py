"""Synthetische urllib-Redirecttests; keine Sockets, DNS, Provisionierung oder CLI."""
import ast
import contextlib
import hashlib
import http.client
import io
import json
import re
import socket
import subprocess
import types
import unittest
import urllib.error
import urllib.parse
import urllib.request
import urllib.response
from decimal import Decimal
from email.message import Message
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / ".ai/foundation/ai_provisioning/host_preparation.py"
BASE = "a16c22ce53f91779b803893f34d17f69bbabc20f"
ORIGIN = "https://contoso.example"
START = ORIGIN + "/start"
OTHER = "https://fabrikam.example/forbidden"
BODY = b"synthetic"
STATUSES = (301, 302, 303, 307, 308)
SCENARIOS = 0
PROVENANCE_FILES = 0


def isolated_source():
    # Nur diese echten Definitionen kompilieren: keine Modulinitialisierung,
    # Import-CLI, Konfiguration, Doctor-/Provisionierungs- oder Installerpfade.
    names = {"PreparationError", "validated_source_uri", "file_digest",
             "_matches_planned_https_origin", "_OriginBoundRedirectHandler",
             "_open_planned_https", "download", "fetch_bytes"}
    tree = ast.parse(SOURCE.read_text(encoding="utf-8"))
    selected = [node for node in tree.body
                if isinstance(node, (ast.FunctionDef, ast.ClassDef)) and node.name in names]
    if {node.name for node in selected} != names:
        raise AssertionError("SYNTHETIC_SOURCE_DEFINITION_MISSING")
    future = ast.ImportFrom(module="__future__", names=[ast.alias(name="annotations")], level=0)
    module = ast.fix_missing_locations(ast.Module(body=[future] + selected, type_ignores=[]))
    namespace = {"urllib": urllib, "Path": Path, "Decimal": Decimal,
                 "hashlib": hashlib, "SHA256_PREFIX": "sha256:"}
    exec(compile(module, "synthetic-host-preparation-definitions", "exec"), namespace)
    return namespace


class TrackedBody(io.BytesIO):
    def __init__(self, body, close_failure=False):
        super().__init__(body)
        self.reads = 0
        self.close_failure = close_failure

    def read(self, *args):
        self.reads += 1
        return super().read(*args)

    def close(self):
        was_closed = self.closed
        super().close()
        if self.close_failure and not was_closed:
            raise OSError("SYNTHETIC_CLOSE_FAILURE")


def transport_key(url):
    return urllib.parse.urlsplit(url)._replace(fragment="").geturl()


class FakeHTTPSHandler(urllib.request.HTTPSHandler):
    def __init__(self, routes):
        # TLS-Kontext/CA-Laden ist für den ersetzten Transport unnötig.
        urllib.request.AbstractHTTPHandler.__init__(self)
        self.routes = routes
        self.contacts = []
        self.bodies = []

    def https_open(self, request):
        url = transport_key(request.full_url)
        self.contacts.append((url, request.timeout))
        if url not in self.routes:
            raise AssertionError("SYNTHETIC_FORBIDDEN_TRANSPORT_DISPATCH")
        status, values, body, close_failure = self.routes[url]
        headers = Message()
        for key, value in values.items():
            headers[key] = value
        stream = TrackedBody(body, close_failure)
        self.bodies.append(stream)
        response = urllib.response.addinfourl(stream, headers, request.full_url, status)
        response.msg = "Synthetic"
        return response


class MemoryDestination:
    """Path-Oberfläche ohne Dateien; ein verweigerter Download darf nichts mutieren."""
    def __init__(self):
        self.parent = self
        self.calls = []
        self.data = b""

    def mkdir(self, **kwargs):
        self.calls.append("mkdir")

    def open(self, mode):
        self.calls.append(mode)
        if mode == "rb":
            return io.BytesIO(self.data)
        if mode != "wb":
            raise AssertionError("SYNTHETIC_PATH_MODE")
        owner = self

        class Output(io.BytesIO):
            def fileno(self):
                return 17

            def close(self):
                if not self.closed:
                    owner.data = self.getvalue()
                super().close()

        return Output()

    def unlink(self, **kwargs):
        self.calls.append("unlink")
        self.data = b""


def refused_network(*args, **kwargs):
    raise AssertionError("SYNTHETIC_NETWORK_FALLBACK_FORBIDDEN")


@contextlib.contextmanager
def offline_transport(fake):
    real_build = urllib.request.build_opener

    def build(*handlers):
        # Echter Opener/Redirect/ErrorProcessor; ausschließlich der HTTPS-
        # Transport ist synthetisch. Kein Environment-Proxy wird ausgewertet.
        return real_build(urllib.request.ProxyHandler({}), fake, *handlers)

    with contextlib.ExitStack() as stack:
        for target in ("socket.socket", "socket.create_connection", "socket.getaddrinfo",
                       "urllib.request.urlopen", "urllib.request.HTTPHandler.http_open",
                       "urllib.request.HTTPSHandler.https_open", "urllib.request.FTPHandler.ftp_open",
                       "urllib.request.FileHandler.file_open", "http.client.HTTPSConnection.connect",
                       "http.client.HTTPConnection.connect"):
            stack.enter_context(patch(target, side_effect=refused_network))
        stack.enter_context(patch("urllib.request.build_opener", side_effect=build))
        yield


class RedirectTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.subject = isolated_source()

    def exercise(self, consumer, routes, contacts, *, source=START, rejected=False,
                 expected_code=None, limit_error=False):
        global SCENARIOS
        SCENARIOS += 1
        fake = FakeHTTPSHandler(routes)
        destination = MemoryDestination()
        fsync = []
        self.subject["os"] = types.SimpleNamespace(fsync=lambda fd: fsync.append(fd))
        with offline_transport(fake):
            error = None
            try:
                if consumer == "download":
                    action = {"source": source, "network_destination": "contoso.example",
                              "download_mb": 0.001,
                              "verification_sha256": "sha256:" + hashlib.sha256(BODY).hexdigest()}
                    result = self.subject["download"](action, destination, 7.25)
                    self.assertEqual(result, len(BODY))
                    self.assertEqual(destination.data, BODY)
                    self.assertEqual(destination.calls, ["mkdir", "wb", "rb"])
                    self.assertEqual(fsync, [17])
                else:
                    self.assertEqual(self.subject["fetch_bytes"](source, 7.25), BODY)
                    self.assertEqual(destination.calls, [])
            except (self.subject["PreparationError"], urllib.error.HTTPError) as exc:
                error = exc
                if limit_error:
                    cause = exc.__cause__ if isinstance(exc, self.subject["PreparationError"]) else exc
                    self.assertIsInstance(cause, urllib.error.HTTPError)
                    # Der unveränderte stdlib-Limitfehler besitzt noch die
                    # Antwort. Nur der Test schließt sie; keine Produktbehauptung.
                    cause.close()
                else:
                    self.assertIsInstance(exc, self.subject["PreparationError"])
                    self.assertEqual(exc.code, expected_code or
                                     ("PROVISION_REDIRECT_REFUSED" if consumer == "download"
                                      else "COST_SOURCE_REDIRECT_REFUSED"))
                    self.assertEqual(exc.error_class, "PERMISSION" if expected_code is None else "CONTRACT")
            self.assertEqual(error is not None, rejected or limit_error)
        self.assertEqual(fake.contacts, [(url, 7.25) for url in contacts])
        self.assertTrue(all(body.closed for body in fake.bodies))
        if rejected or limit_error:
            self.assertEqual(destination.calls, [])
            self.assertEqual(fsync, [])
        if rejected and fake.bodies:
            self.assertEqual(fake.bodies[-1].reads, 0)
        return fake

    def test_allowed_redirects_all_statuses_both_consumers(self):
        variants = (
            ("/next", ORIGIN + "/next"),
            ("next", ORIGIN + "/next"),
            ("https://contoso.example:443/next", "https://contoso.example:443/next"),
            ("/next?part=2#segment", ORIGIN + "/next?part=2"),
        )
        for consumer in ("download", "fetch"):
            self.exercise(consumer, {START: (200, {}, BODY, False)}, [START])
            for status in STATUSES:
                for location, final in variants:
                    with self.subTest(consumer=consumer, status=status, location=location):
                        self.exercise(consumer, {START: (status, {"Location": location}, b"redirect", False),
                                                final: (200, {}, BODY, False)}, [START, final])
                middle, final = ORIGIN + "/middle", ORIGIN + "/final"
                self.exercise(consumer, {START: (status, {"Location": "/middle"}, b"redirect", False),
                                        middle: (status, {"Location": "/final"}, b"redirect", False),
                                        final: (200, {}, BODY, False)}, [START, middle, final])

    def test_denied_redirects_all_statuses_both_consumers(self):
        locations = (OTHER, "https://contoso.example:444/next", "http://contoso.example/next",
                     "ftp://contoso.example/next", "file:///Contoso/synthetic",
                     "data:text/plain,synthetic", "https://synthetic@contoso.example/next",
                     "https://contoso.example:invalid/next", "https://[malformed/next")
        for consumer in ("download", "fetch"):
            for status in STATUSES:
                for location in locations:
                    with self.subTest(consumer=consumer, status=status, location=location):
                        self.exercise(consumer, {START: (status, {"Location": location}, b"unread", False)},
                                      [START], rejected=True)

    def test_cross_origin_second_hop_and_return_never_contacted(self):
        for consumer in ("download", "fetch"):
            for status in STATUSES:
                middle = ORIGIN + "/middle"
                self.exercise(consumer, {START: (status, {"Location": middle}, b"redirect", False),
                                        middle: (status, {"Location": OTHER}, b"unread", False),
                                        OTHER: (status, {"Location": START}, b"forbidden", False)},
                              [START, middle], rejected=True)

    def test_uri_header_fallback_and_close_error_priority(self):
        final = ORIGIN + "/next"
        for consumer in ("download", "fetch"):
            for status in STATUSES:
                self.exercise(consumer, {START: (status, {"URI": "/next"}, b"redirect", False),
                                        final: (200, {}, BODY, False)}, [START, final])
                self.exercise(consumer, {START: (status, {"URI": OTHER}, b"unread", False)},
                              [START], rejected=True)
                self.exercise(consumer, {START: (status, {"Location": OTHER}, b"unread", True)},
                              [START], rejected=True)

    def test_standard_redirect_limits_remain(self):
        for consumer in ("download", "fetch"):
            repetitions = urllib.request.HTTPRedirectHandler.max_repeats + 1
            self.exercise(consumer, {START: (302, {"Location": START}, b"redirect", False)},
                          [START] * repetitions, limit_error=True)
            count = urllib.request.HTTPRedirectHandler.max_redirections + 1
            urls = [ORIGIN + "/hop-" + str(i) for i in range(count + 1)]
            routes = {url: (302, {"Location": urls[i + 1]}, b"redirect", False)
                      for i, url in enumerate(urls[:-1])}
            self.exercise(consumer, routes, urls[:-1], source=urls[0], limit_error=True)

    def test_original_source_validation_precedes_transport(self):
        sources = ("http://contoso.example/start", "ftp://contoso.example/start",
                   "https://contoso.example:444/start", "https://contoso.example:invalid/start",
                   "https://synthetic@contoso.example/start", "https:///missing-host",
                   START + "?query=synthetic", START + "#fragment")
        for consumer in ("download", "fetch"):
            for source in sources:
                with self.subTest(consumer=consumer, source=source):
                    self.exercise(consumer, {}, [], source=source, rejected=True,
                                  expected_code="INVALID_SOURCE_URI")

    def test_unguarded_standard_opener_negative_control(self):
        final = ORIGIN + "/returned"
        routes = {START: (302, {"Location": OTHER}, b"redirect", False),
                  OTHER: (302, {"Location": final}, b"redirect", False),
                  final: (200, {}, BODY, False)}
        fake = FakeHTTPSHandler(routes)
        # Negativer Witnesscontrol: derselbe echte stdlib-Opener ohne Origin-
        # Handler kontaktiert den synthetischen Fremdhost und kehrt zurück.
        with offline_transport(fake):
            with urllib.request.build_opener().open(urllib.request.Request(START), timeout=7.25) as response:
                self.assertEqual(response.read(), BODY)
        self.assertEqual(fake.contacts, [(START, 7.25), (OTHER, 7.25), (final, 7.25)])
        self.assertTrue(all(body.closed for body in fake.bodies))
        for consumer in ("download", "fetch"):
            self.exercise(consumer, routes, [START], rejected=True)


class ProvenanceTests(unittest.TestCase):
    def test_exact_base_identity_and_installed_hashes(self):
        global PROVENANCE_FILES
        record = json.loads((ROOT / ".ai/foundation/installation-provenance.json").read_text(encoding="utf-8"))
        # Ausschließlich begrenzter read-only Gitzugriff auf den festen Base;
        # weder Produkt-CLI noch Provisionierungs-/Netzwerkkonfiguration laden.
        original = subprocess.run(["git", "-C", str(ROOT), "show",
                                   BASE + ":.ai/foundation/installation-provenance.json"],
                                  capture_output=True, check=True, timeout=2)
        baseline = json.loads(original.stdout.decode("utf-8", errors="strict"))
        # Preserve selection and authority; version/manifest intentionally upgrade.
        for key in ("schema_version", "contract", "source_repository", "selection"):
            self.assertEqual(record[key], baseline[key])
        expected = {"schema_version": 1, "contract": "foundation-installation-provenance/v1",
                    "ruleset_version": "1.21.0",
                    "source_repository": "https://github.com/gecompat/AI_Repository_Foundation",
                    "source_commit": "d720db4f2f0d043756a958d5195d0e62090b1c8f",
                    "source_manifest_sha256": "5c4268140ba8cb6c3c38ce42cdd1ebecd8d5c3db23309bb90c77bc8b38ebf2f6"}
        for key, value in expected.items():
            self.assertEqual(record[key], value)
        self.assertRegex(record["recorded_at"], r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$")
        self.assertEqual(record["selection"], {
            "adapters": ["claude-code", "gemini", "github-copilot"],
            "capabilities": ["ai-client-integration", "ai-executor", "ai-orchestrator", "ai-provisioning",
                             "ai-runtime-adapters", "ai-work", "artifact-registration-clients", "model-router", "rule-context-cache"]})
        rows = sorted(record["files"], key=lambda row: row["target"])
        self.assertEqual(len(rows), 105)
        self.assertEqual(len({row["target"] for row in rows}), 105)
        changed = {".ai/foundation/ai_provisioning/host_preparation.py",
                   ".ai/foundation/ai_provisioning/AI_PROVISIONING.md",
                   ".ai/foundation/ai_runtime_adapters/reference_adapters.py",
                   ".ai/foundation/ai_runtime_adapters/AI_RUNTIME_ADAPTERS.md",
                   ".ai/foundation/ai_runtime_adapters/runtime_configuration.py"}
        old_rows = {row["target"]: row for row in baseline["files"]}
        new = {".ai/foundation/PROCESSING_EFFICIENCY_POLICY.md",
               ".ai/foundation/FOUNDATION_REFERENCE.md",
               ".ai/foundation/runtime/processing_efficiency.py",
               ".ai/foundation/schemas/processing-budget-request.schema.json"}
        upgraded = {"AGENTS.md", ".ai/foundation/FOUNDATION_RULESET.md",
                    ".ai/foundation/SEMANTIC_INTEGRATION_POLICY.md",
                    ".ai/foundation/PROJECT_RULES.md",
                    ".ai/foundation/RULE_CONTEXT_CACHE_POLICY.md",
                    ".ai/foundation/AI_WORK_ORCHESTRATION_POLICY.md",
                    ".ai/foundation/feature_catalog.json", ".ai/foundation/WORKING_RULES.md",
                    ".ai/foundation/VALIDATION_POLICY.md", ".ai/foundation/repo_map.yaml"}
        self.assertEqual(set(old_rows) | new, {row["target"] for row in rows})
        reasons = {
            ".ai/foundation/ai_provisioning/host_preparation.py":
                "Toolbelt-Securitywartung2026-10-07: jeden Redirect vor Dispatch an ursprünglichen HTTPS-Host/Port443 binden, Same-origin-Verhalten und übrige Budgets erhalten.",
            ".ai/foundation/ai_provisioning/AI_PROVISIONING.md":
                "Gekoppelte Dokumentation des gezielten Toolbelt-Redirect-Securityoverrides; keine neue Ausführungsautorität oder Foundationversion.",
            ".ai/foundation/ai_runtime_adapters/reference_adapters.py":
                "Toolbelt-Securitywartung2026-10-07: HttpAdapter-Antworten vor JSON und Outputmutation auf16MiB begrenzen, Kurzreads und positive Restlänge prüfen, strukturierte Ablehnung vor Closefehlern erhalten.",
            ".ai/foundation/ai_runtime_adapters/AI_RUNTIME_ADAPTERS.md":
                "Gekoppelte Dokumentation von HttpAdapter-/Discovery-Responsegrenzen, Redirectverweigerung und Discovery-Originprüfung; DNS/Proxy/Hostvertrauen, TOCTOU, Heap und Gesamtzeit bleiben separat, keine Runtimeaktivierung oder Foundationversion.",
            ".ai/foundation/ai_runtime_adapters/runtime_configuration.py":
                "Toolbelt-Securitywartung2026-10-07: Discovery nutzt16MiB-Reader und NoRedirect; vor Vorschlag/Transport credential-freien HTTP(S)-Origin prüfen, ungültige Kandidaten ohne Inputecho vom Default isolieren; Transportfehler bleiben UNAVAILABLE.",
        }

        def projection(fields, entries):
            text = "\n".join("|".join(str(row[key]) if row[key] is not None else "" for key in fields)
                             for row in entries)
            return hashlib.sha256(text.encode("utf-8")).hexdigest()

        fields = ("source", "target", "kind", "merge", "source_sha256")
        # Current manifest projection is bound to the exact 1.21 source above.
        # The old security baseline and all unrelated rows remain protected.
        self.assertEqual(projection(fields, rows),
                         "249dffe06dac617ce48202f676e0d5d7060ca3f2f31f9861398fc1e3ff59c0df")
        self.assertEqual(projection(fields + ("installed_sha256", "integration_state", "reason"),
                                    [row for row in rows if row["target"] not in changed]),
                         "452c73339246812225c4faa77dca89ce5ef5793d7bece1d998740c60b4160b4a")
        for row in rows:
            if row["target"] not in changed | upgraded | new:
                self.assertEqual(row, old_rows[row["target"]])
            elif row["target"] in changed:
                excluded = {"installed_sha256", "integration_state", "reason"}
                self.assertEqual({key: value for key, value in row.items() if key not in excluded},
                                 {key: value for key, value in old_rows[row["target"]].items() if key not in excluded})
                self.assertEqual(row["reason"], reasons[row["target"]])
            path = ROOT / row["target"]
            self.assertTrue(path.resolve().is_relative_to(ROOT.resolve()))
            if not row["target"].startswith(".ai/foundation/"):
                self.assertIn(row["target"], {"AGENTS.md", "CLAUDE.md", "GEMINI.md", ".github/copilot-instructions.md"})
            raw = path.read_bytes()
            logical = raw.decode("utf-8", errors="strict").replace("\r\n", "\n").encode("utf-8")
            self.assertEqual(hashlib.sha256(logical).hexdigest(), row["installed_sha256"], row["target"])
            if row["target"] in changed:
                self.assertEqual(row["integration_state"], "INTENTIONAL_OVERRIDE")
                self.assertTrue(row["reason"])
                self.assertNotEqual(row["installed_sha256"], row["source_sha256"])
        PROVENANCE_FILES = len(rows)


if __name__ == "__main__":
    # Nur feste synthetische Zähler öffentlich ausgeben; keine Tracebacks oder
    # Host-/Konfigurationswerte. Fehler bleiben am Exitcode und Testnamen sichtbar.
    suite = unittest.defaultTestLoader.loadTestsFromModule(__import__(__name__))
    result = unittest.TextTestRunner(stream=io.StringIO()).run(suite)
    if result.wasSuccessful():
        print(f"PASS FOUNDATION_REDIRECT_TESTS TESTS={result.testsRun} TRANSPORT_SCENARIOS={SCENARIOS} PROVENANCE_FILES={PROVENANCE_FILES}")
    else:
        names = sorted({test.id().split(".")[-1].split(" ")[0] for test, detail in result.failures + result.errors})
        print(f"FAILED FOUNDATION_REDIRECT_TESTS TESTS={result.testsRun} FAILED_METHODS={','.join(names)}")
    raise SystemExit(0 if result.wasSuccessful() else 1)
