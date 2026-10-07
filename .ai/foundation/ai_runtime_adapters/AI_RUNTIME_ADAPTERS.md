# AI runtime reference adapters

Status: OPTIONAL REFERENCE CAPABILITY

This capability implements `foundation-ai-adapter-jsonl/v1` over newline-delimited stdio. Every request contains only `protocol`, `request_id`, `operation`, and `arguments`; operations are `probe`, `catalog`, `invoke`, `cancel`, and optional `provision`. Results contain control metadata only. Invocation payloads move through explicitly allowlisted files, and generated content is written to an output handle rather than stdout.

`reference_adapters.py` supports three replaceable paths:

- Ollama native HTTP, split into distinct local and cloud-tag provider fragments;
- OpenAI-compatible HTTP for LM Studio, llama.cpp, LocalAI, vLLM, and compatible services;
- configured command/stdio programs using argv arrays, whole-argument substitutions, `shell=False`, and an exact environment-name allowlist.

Each process has bounded timeouts, structured error classes, a circuit breaker, cancel semantics, health TTLs, and content-free responses. HTTP redirects are refused so credentials cannot cross origin. Endpoint trust is explicit: loopback is `UNKNOWN` unless configuration supplies host-boundary evidence; a product name is never boundary evidence. Ollama names ending in a cloud marker always enter a separate `REMOTE` fragment and require explicit remote invocation authority.

## Gezielte Toolbelt-Responsegrenze2026-10-07

Die gemeinsamen HttpAdapter-Pfade begrenzen ihre Probe-, Catalog- und
Invoke-Antworten auf exakt16MiB gelesene Bodybytes. Sie lesen höchstens64KiB
je Aufruf und insgesamt höchstens Ceiling+1 Byte. Kurze Reads sind kein EOF;
ein Content-Length-Header erhöht die Bytegrenze nicht. Bei Überschreitung
wird die Antwort vor JSON-Parsing und Outputmutation geschlossen. Die
Ablehnung meldet `PROTOCOL` / `HTTP_RESPONSE_TOO_LARGE` mit `retryable=false`; ein dabei
auftretender Schließfehler verdeckt die Größenabwehr nicht. EOF bei weiterhin
positiver HTTPResponse-Restlänge liefert `HTTP_RESPONSE_INCOMPLETE` derselben
nicht wiederholbaren PROTOCOL-Klasse, bevor parsebares Teil-JSON akzeptiert
werden könnte. Probe übernimmt den Code in den bisherigen
UNAVAILABLE-Healthstatus; Catalog und Invoke
verwenden beim JSONL-Server den vorhandenen ProtocolServer-Fehler-/
Circuitbreakerpfad; direkte Konfigurations-/MCP-Aufrufe besitzen diesen
Breaker nicht.

Dies ist eine neue feste technische Transportgrenze ohne Configknopf:
Auch fachlich legitime größere Antworten werden abgewiesen. Die Grenze
belegt kein Heap-, JSON-Tiefen-, Gesamtzeit- oder Produktionsbudget. Der
Commandadapter, Request-/Inputhandles, Rechte, Endpoint-/Remoteautorität,
Timeouts, Redirectabwehr und Runtimekonfiguration bleiben unverändert.
Sourceversion1.19.0 und Originalprovenienz bleiben erhalten; Source und diese
gekoppelte Dokumentation sind gezielte `INTENTIONAL_OVERRIDE`-Dateien.
Die Änderung aktiviert keine Runtime und behebt keine Pfad-TOCTOU-Grenze.
Diese erste Änderung schützte den getrennten Discovery-Probe noch nicht;
die folgende Wartung erweitert denselben Reader auf diesen Verbraucher.

## Gezielte Toolbelt-Discoverywartung2026-10-07

`runtime_configuration.py::_probe_candidate` verwendet jetzt denselben
16MiB-/64KiB-Reader vor JSON-Parsing. Overflow, unvollständige Übertragung,
ungültiges JSON oder Encoding liefern den bestehenden `UNAVAILABLE`-Vorschlag
mit `version=None`; es wird kein Fehlerpayload ergänzt. Auch legitime größere
Versionsantworten werden abgewiesen. Der lokale Opener verwendet das bestehende
`NoRedirect`: sämtliche Redirects, einschließlich relativer Ziele, bleiben
ungefolgt. HTTPError-Antworten werden ohne Bodyread geschlossen; dabei auftretende
Schließfehler ändern den Vorschlagsstatus nicht. Kein globaler Opener wird gesetzt.

Die bisherige Loopbackauswahl, `probe=False`, Vorschlagsfelder, Timeouts und
Bestätigungsgrenzen bleiben erhalten. Dies aktiviert keinen Client, speichert
keine Konfiguration und verleiht keine Netzwerk-, Credential- oder Datenautorität.
Die initiale Kandidatenvalidierung und DNS-/Proxy-/Hostvertrauensgrenzen werden
hierdurch nicht allgemein qualifiziert. Heap, JSON-Tiefe, Gesamtzeit und Pfad-TOCTOU
bleiben eigenständige offene Grenzen. Originalversion1.19.0 und Auswahl bleiben
erhalten; der Konfigurationsclient und diese gekoppelte Dokumentation erhalten
gezielte Targetoverrides, keinen Upstream- oder Cloudscan-Abschlussstatus.

## Gezielte Toolbelt-Discovery-Originprüfung2026-10-07

Vor Vorschlag und Transport akzeptiert Discovery ausschließlich einen
credential-freien HTTP(S)-Origin. Ein einzelner abschließender Slash wird
entfernt; die bestehende HTTP-Ergänzung für schemafreie OLLAMA_HOST-Werte
bleibt erhalten. Andere Schemes, Userinfo einschließlich leerem Userinfo,
API-Pfade, Query-/Fragmentdelimiter, Backslashes, C0-/C1-Steuerzeichen und
Whitespace werden abgewiesen. Ports müssen gültig und ungleich0 sein;
leere Portangaben, kodierte Authorities und fehlerhafte IPv6-/Authorityformen
werden ebenfalls vor Requesterzeugung abgewiesen. Kein DNS-Read ist Teil
dieser syntaktischen Prüfung.

Ein ungültiger Kandidat liefert dieselben Vorschlagsfelder mit
`state=INVALID_ENDPOINT`, `endpoint=None`, `checked_at=None` und `version=None`.
Der eingegebene Kandidat wird nicht wiedergegeben. Er verhindert den
nachfolgenden sicheren Standardvorschlag nicht. Auch der direkte private
Versionsprobe prüft den Origin vor Requesterzeugung. Gültige Origins behalten
ihre bisherige Loopbackauswahl: nur localhost,127.0.0.1 und::1 sind automatisch
probefähig. Andere Origins bleiben bei angefordertem Probe
`AUTHORIZATION_REQUIRED`; `probe=False` bleibt vollständig kontaktfrei.
Vorschlagsstatus und Bestätigungsfelder erteilen weiterhin keine Autorität.

Die strengere Syntaxgrenze betrifft ausschließlich Discovery, nicht die
Validierung gespeicherter Verbindungen. DNS-/Proxy-/Hostvertrauen, Heap,
JSON-Tiefe, Gesamtzeit und Pfad-TOCTOU bleiben getrennte offene Grenzen.
Diese Wartung aktiviert keine Runtime, speichert keine Konfiguration und
ändert weder Provider noch Foundationversion oder den historischen Cloudscan.

Resource-price refresh is independent of model invocation. Cache conforming `foundation-resource-cost-evidence/v1` records outside Git, query a given source at most once per 24 hours (normally less often according to its TTL), and prefer deterministic primary sources or local measurement. AI-assisted source discovery is optional and cannot turn an unverified estimate into routable money evidence.

Configuration is target/runtime data. Store it outside the repository when it contains endpoint, host path, or credential environment details. Credentials are read only from explicitly allowlisted environment names and never emitted; they require HTTPS unless a loopback endpoint has separate explicit host-boundary evidence. `network_authorized`, general and remote data classes, read roots, write roots, remote-model authority, and asserted boundary must all be configured; no default grants them. Command executables use absolute paths and an exact argv/environment. Handle roots restrict what the adapter passes to the child but are not an operating-system sandbox: configure only trusted programs and apply target-owned process isolation when ambient user permissions are too broad.

## Easy external configuration

`runtime_configuration.py` implements the optional `foundation-ai-runtime-configuration/v1` store. With no subcommand it starts a question/answer assistant. On first use it checks only safe loopback Ollama defaults read-only, shows the detected or unverified proposal, and lets the operator test, save, go back, or abort:

```text
python .ai/foundation/ai_runtime_adapters/runtime_configuration.py
python .ai/foundation/ai_runtime_adapters/runtime_configuration.py status
python .ai/foundation/ai_runtime_adapters/runtime_configuration.py configure
python .ai/foundation/ai_runtime_adapters/runtime_configuration.py list
python .ai/foundation/ai_runtime_adapters/runtime_configuration.py probe CONNECTION_ID
python .ai/foundation/ai_runtime_adapters/runtime_configuration.py catalog CONNECTION_ID
python .ai/foundation/ai_runtime_adapters/runtime_configuration.py rollback
```

Named connections accept any credential-free HTTP(S) origin such as `http://127.0.0.1:11434`, `http://ollama-host:11434`, or `https://models.example:8443`. The assistant asks for the execution boundary independently; it never equates a hostname, loopback response, or product name with local model execution. Existing entries retain their values as editable defaults. Saves are atomic, keep one exact hash-bound rollback record, and reject runtime state inside a Git worktree. A malformed connection is isolated from valid connections.

The default state directory is `%USERPROFILE%/.ai-repository-foundation/ai-runtime-adapters` on Windows, `~/Library/Application Support/AIRepositoryFoundation/ai-runtime-adapters` on macOS, and `$XDG_STATE_HOME/ai-repository-foundation/ai-runtime-adapters` or `~/.local/state/...` on Linux. The Windows location deliberately avoids `LOCALAPPDATA`, which packaged clients may virtualize differently, so Codex, IDEs, terminals, and MCP hosts resolve one user-level configuration. `AI_RUNTIME_ADAPTER_HOME` selects another absolute external directory.

Credential choices are:

- `NONE`, normally correct for an unprotected local Ollama endpoint;
- `ENVIRONMENT`, which references one existing environment name;
- `DOTENV_REFERENCE`, which stores only an absolute file path, key name, and the name exported to the adapter process.

For example, an external file containing `OLLAMA=...` can be referenced by its absolute path, key `OLLAMA`, and export name `OLLAMA_API_KEY`. The token value is never copied into the runtime configuration, repository, stdout, catalog, or MCP response. This mapping is scoped to adapter calls; the separate model-router `sync-ollama` command still reads `OLLAMA_API_KEY` from its own process environment.

## Runtime MCP bridge and model choice

Start the stdio MCP bridge with either command:

```text
python .ai/foundation/ai_runtime_adapters/runtime_configuration.py mcp
python .ai/foundation/ai_runtime_adapters/runtime_mcp.py --config PATH_OUTSIDE_REPOSITORY
```

It starts even with no runtime configured. `runtime_configuration_status` then returns `CONFIGURATION_REQUIRED`, safe unverified proposals, and the exact wizard command instead of crashing. `runtime_discover`, `runtime_probe`, and `runtime_catalog` are read-only. `runtime_invoke` accepts a connection, operation id, data class, external input/output handles, and an explicit model; a `PINNED` connection may supply its configured model. `ROUTER` and `MANUAL` never guess when the caller omitted the model.

The existing `ai-model-router` MCP remains decision-only. A capable client can call it first and pass the returned concrete model to `runtime_invoke`. A client without automatic chaining receives the existing privacy-safe manual handoff/model-choice prompt. Ollama `:cloud`/`-cloud` models remain `REMOTE` and need both connection-level allowance and `remote_authorized=true` on the invocation.

Generated output stays in the configured output handle. MCP returns only status, hashes, byte count, selection origin, and requested/actual model metadata. `ACTUAL_MODEL_ATTESTED` requires matching model metadata from the runtime response; absent metadata is `REQUESTED_NOT_ATTESTED`, and a mismatch is explicit.

Run one adapter process:

```text
python .ai/foundation/ai_runtime_adapters/reference_adapters.py ollama --config PATH_OUTSIDE_REPOSITORY
python .ai/foundation/ai_runtime_adapters/reference_adapters.py openai-compatible --config PATH_OUTSIDE_REPOSITORY
python .ai/foundation/ai_runtime_adapters/reference_adapters.py command --config PATH_OUTSIDE_REPOSITORY
```

The protocol and policy are language-neutral. Python is only the optional reference implementation. Catalog entries initially report unknown model quality/context/resources unless a separately governed profile or measured evidence supplies them; discovery alone never creates routable quality evidence.
