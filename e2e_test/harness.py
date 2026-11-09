"""Verified against Google ARTEMIS remote SDK at the commit below.

Importing this module never starts a daemon or submits a model request.
"""
from __future__ import annotations
import asyncio
from dataclasses import dataclass, field
from datetime import datetime, timezone
import json
import re
from pathlib import Path
import time
from typing import Any, Mapping
from urllib.parse import urlparse
from uuid import uuid4

ARTEMIS_COMMIT = "351ca8422f7b5b54e80a9c1ce03a222e02415b6b"
PACKAGE = "vn.edu.fpt.vetalife"


def verify_sdk_pin(direct_url: str | None) -> None:
    metadata = json.loads(direct_url or '{}')
    if metadata.get('vcs_info', {}).get('commit_id') != ARTEMIS_COMMIT:
        raise ValueError('Installed artemis-client must match the pinned Git commit')


@dataclass(frozen=True)
class Case:
    id: str
    mode: str
    actions: str
    expected: Mapping[str, bool | int | str]
    setup: str = "profile"
    prerequisites: tuple[str, ...] = ()
    analytics_event: str | None = None


def validate_endpoint(value: str) -> str:
    endpoint = urlparse(value)
    if endpoint.scheme not in {"http", "https"} or not endpoint.hostname:
        raise ValueError("ARTEMIS_BASE_URL must be HTTP(S)")
    if endpoint.username or endpoint.password or endpoint.query or endpoint.fragment:
        raise ValueError("Use ARTEMIS_TOKEN separately from the endpoint")
    if endpoint.hostname not in {"localhost", "127.0.0.1", "::1"} and endpoint.scheme != "https":
        raise ValueError("Nonlocal ARTEMIS endpoints require HTTPS")
    return value.rstrip("/")


def parse_observed(output: Any) -> dict[str, Any]:
    if isinstance(output, str):
        output = output.strip()
        if output.startswith("```json\n") and output.endswith("```"):
            output = output[8:-3].strip()
        output = json.loads(output)
    if not isinstance(output, dict) or not isinstance(output.get("observed"), dict):
        raise AssertionError("ARTEMIS must return an observed JSON object")
    return output["observed"]


def assert_observed(actual: Mapping[str, Any], expected: Mapping[str, Any]) -> None:
    for key, value in expected.items():
        if key not in actual or type(actual[key]) is not type(value) or actual[key] != value:
            # Do not echo unexpected values which might contain user content.
            raise AssertionError(f"Observed field {key!r} differs or has wrong type")


def analytics_event_seen(lines: list[str], event: str) -> bool:
    name = re.compile(r'(?<!\w)' + re.escape(event) + r'(?!\w)')
    tag = re.compile(r'\b(?:FA|FA-SVC|FirebaseAnalytics)\b')
    return any(name.search(line) and tag.search(line) for line in lines)


def summarize(records: list[dict[str, Any]]) -> dict[str, Any]:
    grouped: dict[str, list[dict[str, Any]]] = {}
    for record in records:
        grouped.setdefault(record["case"], []).append(record)
    summary = {}
    for case, runs in grouped.items():
        executed = [r for r in runs if r["outcome"] != "skipped"]
        passed = sum(r["outcome"] == "passed" for r in runs)
        summary[case] = {
            "attempts": len(runs), "passed": passed,
            "failed": sum(r["outcome"] == "failed" for r in runs),
            "skipped": len(runs) - len(executed),
            "pass_rate": passed / len(executed) if executed else None,
            "mean_seconds": sum(r.get("seconds", 0) for r in executed) / len(executed) if executed else None,
            "needs_investigation": any(r["outcome"] != "passed" for r in runs),
        }
    return summary


@dataclass
class Runner:
    client: Any
    device_serial: str
    account_alias: str
    directory: Path
    timeout: float = 600
    analytics_log: Path | None = None
    records: list[dict[str, Any]] = field(default_factory=list)

    def run(self, case: Case, repetition: int) -> None:
        asyncio.run(self._run(case, repetition))

    async def _run(self, case: Case, repetition: int) -> None:
        started = time.monotonic()
        record: dict[str, Any] = {
            "case": case.id, "repetition": repetition, "outcome": "failed",
            "sdk_commit": ARTEMIS_COMMIT,
            "started_utc": datetime.now(timezone.utc).isoformat(), "expected": dict(case.expected),
        }
        handle = None
        terminal = False
        offset = self.analytics_log.stat().st_size if case.analytics_event and self.analytics_log else 0
        try:
            if case.mode == "preview":
                setup = (
                    "Establish a clean PREVIEW welcome screen by signing out through the home "
                    "profile menu if needed. Never clear another app's data. "
                )
                if case.setup == "profile":
                    setup += (
                        "Complete onboarding with synthetic name 'ARTEMIS Test', birth date "
                        "01/01/2000, 60 kg, 170 cm and goal 'Ghi lại bữa ăn'. Stop at home. "
                    )
            else:
                setup = (
                    f"Use only the dedicated preconfigured account alias {self.account_alias!r}. "
                    "Never type passwords, create accounts, change billing, or send notifications. "
                    "If preconditions are missing report the failure without inventing data. "
                )
            goal = (
                f"Open VetaLife Android package {PACKAGE}. " + setup + case.actions
                + " Report only device observations in JSON {\"observed\": {...}}. Never "
                "include account identifiers, tokens, passwords or unrelated personal content."
            )
            schema = {key: type(value).__name__ for key, value in case.expected.items()}
            handle = await self.client.submit(
                goal, profile="flash", device_serial=self.device_serial,
                expected_output="JSON observed fields/types: " + json.dumps(schema),
                enable_outputter=True,
            )
            record["trace_id"] = handle.task_id
            result = await self.client.wait_for_task(handle.task_id, timeout=self.timeout)
            terminal = result.done
            record["status"] = result.status
            if not result.succeeded:
                raise AssertionError("ARTEMIS task failed; inspect its daemon trace")
            observed = parse_observed(result.output)
            assert_observed(observed, case.expected)
            record["observed"] = {key: observed[key] for key in case.expected}
            if case.analytics_event:
                if self.analytics_log is None:
                    raise AssertionError("A live captured Logcat file is required")
                deadline = time.monotonic() + 5
                found = False
                while not found and time.monotonic() < deadline:
                    with self.analytics_log.open("rb") as log:
                        log.seek(offset)
                        lines = log.read().decode("utf-8", errors="replace").splitlines()
                    found = analytics_event_seen(lines, case.analytics_event)
                    if not found:
                        await asyncio.sleep(.25)
                if not found:
                    raise AssertionError("Analytics event absent from new Logcat lines")
                record["analytics"] = {"event": case.analytics_event, "new_logcat_lines_verified": True}
            record["outcome"] = "passed"
        except BaseException as error:
            record["error_type"] = type(error).__name__
            raise
        finally:
            if handle is not None and not terminal:
                try:
                    await self.client.stop(handle.task_id)
                except Exception:
                    record["stop_unconfirmed"] = True
            record["seconds"] = round(time.monotonic() - started, 3)
            self.records.append(record)
            self.directory.mkdir(parents=True, exist_ok=True)
            path = self.directory / f"{case.id}-run{repetition}-{uuid4().hex[:8]}.json"
            path.write_text(json.dumps(record, ensure_ascii=False, indent=2), encoding="utf-8")
