#!/usr/bin/env python3
"""Ollama Cloud discovery and official time-dependent pricing adapter."""

from __future__ import annotations

import html
import json
import os
import re
import urllib.error
import urllib.request
from datetime import timedelta
from decimal import Decimal
from html.parser import HTMLParser
from typing import Any
from urllib.parse import urlsplit

from model_router import (
    CONTRACT,
    TIERS,
    RouterError,
    decimal_value,
    digest,
    isoformat,
    utc_now,
    validate_catalog,
    validate_router_defaults,
)


PROVIDER = "ollama-cloud"
ADAPTER = "ollama-cloud/v1"
MAX_RESPONSE_BYTES = 5 * 1024 * 1024
PROFILE_FIELDS = {
    "assessment",
    "capabilities",
    "context_window",
    "quality_prior",
    "supported_tiers",
    "reasoning_efforts",
    "latency_seconds_prior",
}


class SafeRedirectHandler(urllib.request.HTTPRedirectHandler):
    """Never forward a bearer credential across an origin boundary."""

    def redirect_request(self, req, fp, code, msg, headers, newurl):  # type: ignore[no-untyped-def]
        if req.has_header("Authorization"):
            old = urlsplit(req.full_url)
            new = urlsplit(newurl)
            if (old.scheme.lower(), old.hostname, old.port) != (new.scheme.lower(), new.hostname, new.port):
                raise RouterError("refusing to forward OLLAMA_API_KEY across an HTTP redirect")
        return super().redirect_request(req, fp, code, msg, headers, newurl)


class PricingPageParser(HTMLParser):
    """Extract text tables while retaining the closest preceding h2/h3 label."""

    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.heading_tag: str | None = None
        self.heading_parts: list[str] = []
        self.current_heading = ""
        self.in_table = False
        self.in_row = False
        self.cell_tag: str | None = None
        self.cell_parts: list[str] = []
        self.current_row: list[str] = []
        self.current_rows: list[list[str]] = []
        self.tables: list[dict[str, Any]] = []
        self.all_text: list[str] = []
        self.pricing_section_depth = 0

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        if tag == "section":
            if self.pricing_section_depth:
                self.pricing_section_depth += 1
            elif dict(attrs).get("id") == "model-pricing":
                self.pricing_section_depth = 1
            return
        if not self.pricing_section_depth:
            return
        if tag in {"h2", "h3"}:
            self.heading_tag = tag
            self.heading_parts = []
        elif tag == "table":
            self.in_table = True
            self.current_rows = []
        elif tag == "tr" and self.in_table:
            self.in_row = True
            self.current_row = []
        elif tag in {"th", "td"} and self.in_row:
            self.cell_tag = tag
            self.cell_parts = []

    def handle_data(self, data: str) -> None:
        if not self.pricing_section_depth:
            return
        normalized = " ".join(data.split())
        if not normalized:
            return
        self.all_text.append(normalized)
        if self.heading_tag:
            self.heading_parts.append(normalized)
        if self.cell_tag:
            self.cell_parts.append(normalized)

    def handle_endtag(self, tag: str) -> None:
        if tag == "section" and self.pricing_section_depth:
            self.pricing_section_depth -= 1
            return
        if not self.pricing_section_depth:
            return
        if tag == self.heading_tag:
            self.current_heading = " ".join(self.heading_parts)
            self.heading_tag = None
        elif tag == self.cell_tag:
            self.current_row.append(" ".join(self.cell_parts))
            self.cell_tag = None
        elif tag == "tr" and self.in_row:
            if self.current_row:
                self.current_rows.append(self.current_row)
            self.in_row = False
        elif tag == "table" and self.in_table:
            self.tables.append({"heading": self.current_heading, "rows": self.current_rows})
            self.in_table = False


def _money(value: str, *, optional: bool = False) -> float | None:
    normalized = html.unescape(value).strip()
    if normalized in {"", "-", "—", "n/a", "N/A"}:
        if optional:
            return None
        raise RouterError(f"required Ollama price is missing: {value!r}")
    match = re.fullmatch(r"\$\s*([0-9]+(?:\.[0-9]+)?)", normalized)
    if not match:
        raise RouterError(f"unrecognized Ollama price: {value!r}")
    return float(match.group(1))


def _table_prices(table: dict[str, Any]) -> dict[str, dict[str, float | None]]:
    rows = table.get("rows", [])
    if not rows or [cell.lower() for cell in rows[0]] != ["model", "input", "cached input", "output"]:
        raise RouterError(f"Ollama pricing table under {table.get('heading')!r} has an unexpected header")
    prices: dict[str, dict[str, float | None]] = {}
    for row in rows[1:]:
        if len(row) != 4 or not row[0]:
            raise RouterError(f"Ollama pricing table under {table.get('heading')!r} has an invalid row")
        if row[0] in prices:
            raise RouterError(f"Ollama pricing table contains duplicate model {row[0]!r}")
        prices[row[0]] = {
            "input": _money(row[1]),
            "cached_input": _money(row[2], optional=True),
            "output": _money(row[3]),
        }
    if not prices:
        raise RouterError(f"Ollama pricing table under {table.get('heading')!r} is empty")
    return prices


def parse_pricing_page(raw_html: str) -> dict[str, Any]:
    parser = PricingPageParser()
    parser.feed(raw_html)
    normal_tables = [table for table in parser.tables if table["heading"].strip().lower() == "model pricing"]
    peak_tables = [table for table in parser.tables if table["heading"].strip().lower() == "peak pricing"]
    if len(normal_tables) != 1:
        raise RouterError("Ollama pricing page must contain exactly one Model pricing table")
    if len(peak_tables) > 1:
        raise RouterError("Ollama pricing page contains multiple Peak pricing tables")
    visible = " ".join(parser.all_text)
    if "prices are per million tokens" not in visible.lower():
        raise RouterError("Ollama pricing page token-price unit could not be verified")
    base = _table_prices(normal_tables[0])
    peak = _table_prices(peak_tables[0]) if peak_tables else {}
    schedule: dict[str, Any] | None = None
    if peak:
        match = re.search(
            r"Peak pricing applies between\s+((?:[01][0-9]|2[0-3]):[0-5][0-9])\s+and\s+"
            r"((?:[01][0-9]|2[0-3]):[0-5][0-9])\s+UTC,\s+Monday to Friday",
            visible,
            re.IGNORECASE,
        )
        if not match:
            raise RouterError("Ollama peak prices were found but the UTC schedule could not be parsed")
        schedule = {
            "id": "official-peak",
            "priority": 100,
            "days_utc": [0, 1, 2, 3, 4],
            "start_utc": match.group(1),
            "end_utc": match.group(2),
        }
        unknown = sorted(set(peak) - set(base))
        if unknown:
            raise RouterError(f"Ollama peak table contains models absent from base pricing: {', '.join(unknown)}")
    return {"base": base, "peak": peak, "peak_schedule": schedule}


def parse_model_list(raw_json: str) -> list[dict[str, Any]]:
    try:
        payload = json.loads(raw_json)
    except json.JSONDecodeError as exc:
        raise RouterError(f"Ollama model endpoint returned invalid JSON: {exc}") from exc
    models = payload.get("models") if isinstance(payload, dict) else None
    if not isinstance(models, list) or not models:
        raise RouterError("Ollama model endpoint returned no models")
    normalized: list[dict[str, Any]] = []
    seen: set[str] = set()
    for item in models:
        if not isinstance(item, dict):
            raise RouterError("Ollama model endpoint returned a non-object model")
        model_id = item.get("model") or item.get("name")
        if not isinstance(model_id, str) or not model_id or model_id in seen:
            raise RouterError("Ollama model endpoint returned a missing or duplicate model identifier")
        seen.add(model_id)
        normalized.append(
            {
                "model_id": model_id,
                "digest": item.get("digest"),
                "modified_at": item.get("modified_at"),
                "details": item.get("details") if isinstance(item.get("details"), dict) else {},
            }
        )
    return sorted(normalized, key=lambda row: row["model_id"])


def _read_url(url: str, *, timeout_seconds: float, bearer_token: str | None = None) -> str:
    headers = {"Accept": "application/json,text/html", "User-Agent": "ai-model-router/1"}
    if bearer_token:
        headers["Authorization"] = "Bearer " + bearer_token
    request = urllib.request.Request(url, headers=headers)
    try:
        opener = urllib.request.build_opener(SafeRedirectHandler())
        with opener.open(request, timeout=timeout_seconds) as response:
            content_length = response.headers.get("Content-Length")
            if content_length and int(content_length) > MAX_RESPONSE_BYTES:
                raise RouterError(f"response exceeds {MAX_RESPONSE_BYTES} bytes: {url}")
            data = response.read(MAX_RESPONSE_BYTES + 1)
            if len(data) > MAX_RESPONSE_BYTES:
                raise RouterError(f"response exceeds {MAX_RESPONSE_BYTES} bytes: {url}")
            charset = response.headers.get_content_charset() or "utf-8"
            return data.decode(charset)
    except urllib.error.HTTPError as exc:
        raise RouterError(f"Ollama endpoint returned HTTP {exc.code}: {url}") from exc
    except urllib.error.URLError as exc:
        raise RouterError(f"Ollama endpoint unavailable: {url}: {exc.reason}") from exc
    except UnicodeDecodeError as exc:
        raise RouterError(f"Ollama endpoint returned unsupported text encoding: {url}") from exc


def pricing_key_for(model_id: str, price_keys: set[str]) -> str | None:
    normalized = model_id
    for suffix in (":cloud", "-cloud"):
        if normalized.endswith(suffix):
            normalized = normalized[: -len(suffix)]
    if normalized in price_keys:
        return normalized
    matches = [key for key in price_keys if normalized.startswith(key + ":")]
    return max(matches, key=len) if matches else None


def validate_profiles_document(profiles: dict[str, Any]) -> None:
    allowed_root = {"schema_version", "router_defaults", "profiles"}
    if not isinstance(profiles, dict) or set(profiles) - allowed_root or profiles.get("schema_version") != 1:
        raise RouterError("profile overlay must be a schema_version=1 object with known fields")
    if "router_defaults" in profiles:
        validate_router_defaults(profiles["router_defaults"])
    providers = profiles.get("profiles")
    if not isinstance(providers, dict):
        raise RouterError("profile overlay profiles must be an object")
    for provider_name, provider_profiles in providers.items():
        if not isinstance(provider_name, str) or not provider_name or not isinstance(provider_profiles, dict):
            raise RouterError("profile overlay provider entries must be named objects")
        for model_id, profile in provider_profiles.items():
            if not isinstance(model_id, str) or not model_id or not isinstance(profile, dict):
                raise RouterError(f"profile overlay entry {provider_name}/{model_id!r} must be an object")
            unknown = set(profile) - PROFILE_FIELDS
            if unknown:
                raise RouterError(f"invalid profile fields for {provider_name}/{model_id}: {sorted(unknown)}")
            if "assessment" in profile and profile["assessment"] not in {"ASSESSED", "UNASSESSED", "DISABLED"}:
                raise RouterError(f"invalid assessment profile for {provider_name}/{model_id}")
            for field in ("capabilities", "reasoning_efforts"):
                if field in profile:
                    values = profile[field]
                    if (
                        not isinstance(values, list)
                        or any(not isinstance(item, str) or not item for item in values)
                        or len(values) != len(set(values))
                    ):
                        raise RouterError(f"profile field {field} must be a unique string array for {provider_name}/{model_id}")
            if "supported_tiers" in profile:
                tiers = profile["supported_tiers"]
                if (
                    not isinstance(tiers, list)
                    or any(tier not in TIERS[1:] for tier in tiers)
                    or len(tiers) != len(set(tiers))
                ):
                    raise RouterError(f"profile field supported_tiers is invalid for {provider_name}/{model_id}")
            if "context_window" in profile:
                context = profile["context_window"]
                if context is not None and (
                    isinstance(context, bool) or not isinstance(context, int) or context < 1
                ):
                    raise RouterError(f"context_window must be a positive integer or null for {provider_name}/{model_id}")
            if "quality_prior" in profile:
                priors = profile["quality_prior"]
                if not isinstance(priors, dict):
                    raise RouterError(f"quality_prior must be an object for {provider_name}/{model_id}")
                for task_class, value in priors.items():
                    if not isinstance(task_class, str) or not task_class:
                        raise RouterError(f"quality_prior keys must be non-empty for {provider_name}/{model_id}")
                    probability = decimal_value(
                        value,
                        f"{provider_name}/{model_id}.quality_prior",
                        minimum=Decimal(0),
                    )
                    if probability > 1:
                        raise RouterError(f"quality_prior cannot exceed 1 for {provider_name}/{model_id}")
            if "latency_seconds_prior" in profile:
                decimal_value(
                    profile["latency_seconds_prior"],
                    f"{provider_name}/{model_id}.latency_seconds_prior",
                    minimum=Decimal(0),
                )


def _profile_for(profiles: dict[str, Any] | None, model_id: str, price_key: str | None) -> dict[str, Any]:
    if profiles is None:
        return {}
    if profiles.get("schema_version") != 1:
        raise RouterError("profile overlay must use schema_version=1")
    by_provider = profiles.get("profiles", {}).get(PROVIDER, {})
    if not isinstance(by_provider, dict):
        raise RouterError(f"profile overlay profiles.{PROVIDER} must be an object")
    profile = by_provider.get(model_id)
    if profile is None and price_key:
        profile = by_provider.get(price_key)
    if profile is None:
        return {}
    if not isinstance(profile, dict) or set(profile) - PROFILE_FIELDS:
        raise RouterError(f"invalid profile fields for {model_id}")
    return profile


def _preserved_profile(previous: dict[str, Any] | None, model_id: str) -> dict[str, Any]:
    if not previous:
        return {}
    try:
        old = previous["providers"][PROVIDER]["models"][model_id]
    except (KeyError, TypeError):
        return {}
    return {key: old[key] for key in PROFILE_FIELDS if key in old}


def _apply_profile(model: dict[str, Any], profile: dict[str, Any]) -> None:
    model.update(profile)


def sync_ollama_catalog(
    *,
    model_url: str,
    pricing_url: str,
    timeout_seconds: float,
    ttl_hours: int,
    previous: dict[str, Any] | None = None,
    profiles: dict[str, Any] | None = None,
) -> dict[str, Any]:
    if timeout_seconds <= 0 or ttl_hours <= 0:
        raise RouterError("sync timeout and TTL must be positive")
    if previous is not None:
        validate_catalog(previous)
    if profiles is not None:
        validate_profiles_document(profiles)
    for label, source_url in (("model", model_url), ("pricing", pricing_url)):
        parsed = urlsplit(source_url)
        if (
            parsed.scheme.lower() != "https"
            or not parsed.hostname
            or parsed.username is not None
            or parsed.password is not None
            or parsed.query
            or parsed.fragment
        ):
            raise RouterError(f"{label} source URL must be credential-free HTTPS without query or fragment")
    token = os.environ.get("OLLAMA_API_KEY")
    parsed_model_url = urlsplit(model_url)
    if token and (parsed_model_url.scheme.lower() != "https" or (parsed_model_url.hostname or "").lower() != "ollama.com"):
        raise RouterError("OLLAMA_API_KEY may be sent only to the official HTTPS ollama.com model endpoint")
    models = parse_model_list(_read_url(model_url, timeout_seconds=timeout_seconds, bearer_token=token))
    prices = parse_pricing_page(_read_url(pricing_url, timeout_seconds=timeout_seconds))
    price_keys = set(prices["base"])
    provider_models: dict[str, Any] = {}
    matched_price_keys: set[str] = set()
    for discovered in models:
        model_id = discovered["model_id"]
        price_key = pricing_key_for(model_id, price_keys)
        if price_key:
            matched_price_keys.add(price_key)
            base = prices["base"][price_key]
            schedules: list[dict[str, Any]] = []
            if price_key in prices["peak"]:
                schedules.append({**prices["peak_schedule"], "rates": prices["peak"][price_key]})
            pricing = {
                "currency": "USD",
                "unit_tokens": 1_000_000,
                "base": base,
                "schedules": schedules,
            }
            availability = "AVAILABLE"
        else:
            pricing = None
            availability = "MISSING_PRICE"
        model = {
            "model_id": model_id,
            "pricing_key": price_key,
            "availability": availability,
            "assessment": "UNASSESSED",
            "capabilities": ["text"],
            "context_window": None,
            "quality_prior": {"*": 0.5},
            "supported_tiers": ["ECONOMICAL", "BALANCED", "FRONTIER"],
            "reasoning_efforts": ["low"],
            "latency_seconds_prior": 0,
            "pricing": pricing,
            "provider_metadata": {
                "digest": discovered.get("digest"),
                "modified_at": discovered.get("modified_at"),
                "details": discovered.get("details", {}),
            },
        }
        _apply_profile(model, _preserved_profile(previous, model_id))
        _apply_profile(model, _profile_for(profiles, model_id, price_key))
        provider_models[model_id] = model

    for price_key in sorted(price_keys - matched_price_keys):
        model = {
            "model_id": price_key,
            "pricing_key": price_key,
            "availability": "PRICED_NOT_DISCOVERED",
            "assessment": "UNASSESSED",
            "capabilities": ["text"],
            "context_window": None,
            "quality_prior": {"*": 0.5},
            "supported_tiers": ["ECONOMICAL", "BALANCED", "FRONTIER"],
            "reasoning_efforts": ["low"],
            "latency_seconds_prior": 0,
            "pricing": {
                "currency": "USD",
                "unit_tokens": 1_000_000,
                "base": prices["base"][price_key],
                "schedules": (
                    [{**prices["peak_schedule"], "rates": prices["peak"][price_key]}]
                    if price_key in prices["peak"]
                    else []
                ),
            },
            "provider_metadata": {},
        }
        _apply_profile(model, _preserved_profile(previous, price_key))
        _apply_profile(model, _profile_for(profiles, price_key, price_key))
        provider_models[price_key] = model

    previous_models: set[str] = set()
    if previous:
        prior_rows = previous.get("providers", {}).get(PROVIDER, {}).get("models", {})
        previous_models = {
            model_id
            for model_id, row in prior_rows.items()
            if isinstance(row, dict) and row.get("availability") != "PRICED_NOT_DISCOVERED"
        }
    current_discovered = {row["model_id"] for row in models}
    router_defaults = {
        "tier_quality_floors": {"ECONOMICAL": 0.45, "BALANCED": 0.65, "FRONTIER": 0.82},
        "quality_prior_strength": 4,
        "minimum_evaluation_trials": 3,
        "daily_evaluation_budget_usd": 1.0,
        "failure_cost_usd": 0.0,
        "latency_value_usd_per_second": 0.0,
        "switching_cost_usd": 0.0,
    }
    if profiles and isinstance(profiles.get("router_defaults"), dict):
        router_defaults.update(profiles["router_defaults"])
    price_material = {
        "base": prices["base"],
        "peak": prices["peak"],
        "peak_schedule": prices["peak_schedule"],
    }
    now = utc_now()
    catalog = {
        "schema_version": 1,
        "contract": CONTRACT,
        "generated_at": isoformat(now),
        "valid_until": isoformat(now + timedelta(hours=ttl_hours)),
        "pricing_epoch": digest(price_material),
        "catalog_epoch": "pending",
        "router_defaults": router_defaults,
        "providers": {
            PROVIDER: {
                "adapter": ADAPTER,
                "remote": True,
                "source_urls": {"models": model_url, "pricing": pricing_url},
                "models": provider_models,
            }
        },
        "new_models": sorted(current_discovered - previous_models),
        "removed_models": sorted(previous_models - current_discovered),
    }
    catalog["catalog_epoch"] = digest(
        {"router_defaults": router_defaults, "providers": catalog["providers"], "pricing_epoch": catalog["pricing_epoch"]}
    )
    validate_catalog(catalog)
    return catalog
