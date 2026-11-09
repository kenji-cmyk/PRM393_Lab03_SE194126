"""Explicit opt-in and honest three-run ARTEMIS evidence."""
import asyncio
from datetime import datetime, timezone
import json
from importlib.metadata import distribution
import os
from pathlib import Path
from uuid import uuid4

import pytest
from .harness import Runner, summarize, validate_endpoint, verify_sdk_pin
from .cases import CASES

SESSION = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ') + '-' + uuid4().hex[:8]
EVIDENCE = Path(__file__).resolve().parents[1] / 'evidence' / 'artemis' / 'runs' / SESSION
REPORTS = []


@pytest.fixture(params=[1, 2, 3], ids=lambda value: f'run{value}')
def repetition(request):
    return request.param


@pytest.fixture(scope='session')
def artemis_runner():
    if os.environ.get('RUN_ARTEMIS') != '1':
        pytest.skip('RUN_ARTEMIS=1 absent; no device or model request performed')
    if os.environ.get('ARTEMIS_ALLOW_TEST_RESET') != '1':
        pytest.skip('Dedicated test session requires ARTEMIS_ALLOW_TEST_RESET=1')
    endpoint = os.environ.get('ARTEMIS_BASE_URL')
    serial = os.environ.get('ARTEMIS_DEVICE_SERIAL')
    if not endpoint or not serial:
        pytest.skip('ARTEMIS_BASE_URL and ARTEMIS_DEVICE_SERIAL required')
    if os.environ.get('ARTEMIS_TEST_MODE') not in {'preview', 'cloud'}:
        pytest.fail('Explicit ARTEMIS_TEST_MODE=preview or cloud required')
    try:
        from artemis_client import ArtemisClient
    except ImportError:
        pytest.fail('Install pinned SDK: pip install -e ./e2e_test[live]')
    try:
        verify_sdk_pin(distribution('artemis-client').read_text('direct_url.json'))
    except (ValueError, TypeError):
        pytest.fail('Installed artemis-client is not the pinned Git SDK; reinstall the live extra')
    client = ArtemisClient(validate_endpoint(endpoint), token=os.environ.get('ARTEMIS_TOKEN'), request_timeout=15)
    devices = asyncio.run(client.list_devices())
    if not any(d.serial == serial and not d.busy and d.state == 'device' for d in devices):
        pytest.fail('Configured device unavailable, unauthorized or busy')
    log = os.environ.get('ARTEMIS_ANALYTICS_LOG')
    return Runner(client, serial, os.environ.get('ARTEMIS_TEST_ACCOUNT_ALIAS', 'dedicated test account'),
                  EVIDENCE, timeout=float(os.environ.get('ARTEMIS_TASK_TIMEOUT', '600')),
                  analytics_log=Path(log) if log else None)


@pytest.fixture
def run_case(artemis_runner, repetition):
    def run(case):
        if os.environ.get('ARTEMIS_TEST_MODE') != case.mode:
            pytest.skip(f'{case.id} requires {case.mode} build')
        missing = [name for name in case.prerequisites if not os.environ.get(name)]
        if missing:
            pytest.skip('Missing case prerequisite(s): ' + ', '.join(missing))
        artemis_runner.run(case, repetition)
    return run


def pytest_runtest_logreport(report):
    if 'test_harness.py' in report.nodeid:
        return
    if report.when == 'call' or (report.when == 'setup' and report.outcome != 'passed'):
        case_id = next((key for key in CASES if key in report.nodeid), None)
        if case_id is None and 'test_flow_navigation' in report.nodeid:
            case_id = 'NAV-01'
        REPORTS.append({'case': case_id or report.nodeid.split('[')[0], 'nodeid': report.nodeid,
                        'outcome': report.outcome, 'seconds': round(report.duration, 3)})


def pytest_sessionfinish(session, exitstatus):
    EVIDENCE.mkdir(parents=True, exist_ok=True)
    (EVIDENCE / 'pytest-summary.json').write_text(json.dumps({
        'session': SESSION, 'live_opt_in': os.environ.get('RUN_ARTEMIS') == '1',
        'pytest_exit_status': int(exitstatus), 'results': REPORTS,
        'by_case': summarize(REPORTS),
        'note': 'Skipped runs are not passes; no device evidence for skipped cases.',
    }, indent=2), encoding='utf-8')
